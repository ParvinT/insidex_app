// lib/services/device_session_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage single device session policy
/// When user logs in from a new device, old device will be logged out
class DeviceSessionService {
  static final DeviceSessionService _instance =
      DeviceSessionService._internal();
  factory DeviceSessionService() => _instance;
  DeviceSessionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String _localTokenKey = 'device_session_token';
  static const String _localLoginTimestampKey = 'device_session_login_time';

  // In-memory cache
  String? _cachedToken;
  int? _loginTimestamp;

  void initializeTokenRefreshListener() {
    debugPrint('🔄 FCM Token Refresh Listener initialized');

    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔑 FCM Token refreshed: ${newToken.substring(0, 20)}...');

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, skipping token update');
        return;
      }

      try {
        final isActive = await isCurrentDeviceActive(user.uid);

        if (isActive) {
          debugPrint('✅ Updating token for active device...');
          await updateDeviceToken(user.uid, newToken);
        } else {
          debugPrint('⏭️ Not active device, skipping');
        }
      } catch (e) {
        debugPrint('❌ Error handling token refresh: $e');
      }
    });
  }

  /// Save current device as active device for user
  /// Returns the saved token for verification
  Future<String?> saveActiveDevice(String userId) async {
    String? fcmToken;
    String? platform;

    try {
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        debugPrint(
            '⚠️ Notification permission denied - device session may not work properly');
      }

      // Get FCM token
      fcmToken = await _messaging.getToken();

      if (fcmToken == null) {
        debugPrint('⚠️ FCM token is null, cannot save device');
        return null;
      }

      platform = Platform.isIOS ? 'ios' : 'android';
      final loginTimestamp = DateTime.now().millisecondsSinceEpoch;

      // ⭐ STEP 1: Save to LOCAL first (immediate)
      await _saveLocalToken(fcmToken);
      await _saveLoginTimestamp(loginTimestamp);
      debugPrint('💾 Token saved to local cache');

      // ⭐ STEP 2: Then save to Firestore
      await _firestore.collection('users').doc(userId).update({
        'activeDevice': {
          'token': fcmToken,
          'platform': platform,
          'loginAt': FieldValue.serverTimestamp(),
          'loginTimestamp': loginTimestamp,
        },
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '✅ Active device saved: $platform - ${fcmToken.substring(0, 20)}...');

      return fcmToken;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        debugPrint('⚠️ Network error, queueing offline update...');
        if (fcmToken != null && platform != null) {
          await _queueOfflineDeviceUpdate(userId, fcmToken, platform);
        }
      } else {
        debugPrint('❌ Firebase error: ${e.code} - ${e.message}');
      }
      return fcmToken;
    } catch (e) {
      debugPrint('❌ Unexpected error saving active device: $e');
      return fcmToken;
    }
  }

  /// Get current device's FCM token
  Future<String?> getCurrentDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('❌ Error getting device token: $e');
      return null;
    }
  }

  /// Check if current device is the active device
  /// Uses local cached token to avoid race conditions
  Future<bool> isCurrentDeviceActive(String userId) async {
    try {
      // ⭐ Use LOCAL token first (faster, no race condition)
      String? currentToken = await getLocalToken();

      // Fallback to FCM if no local token
      if (currentToken == null) {
        currentToken = await getCurrentDeviceToken();
        if (currentToken == null) return false;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();

      if (data == null) return false;

      final activeDevice = data['activeDevice'] as Map<String, dynamic>?;
      if (activeDevice == null) return true; // No active device set yet

      final activeToken = activeDevice['token'] as String?;

      return currentToken == activeToken;
    } catch (e) {
      debugPrint('❌ Error checking device status: $e');
      return true; // ⭐ Return TRUE on error (don't logout on errors)
    }
  }

  /// Send push notification to old device
  /// Note: This requires Cloud Function to actually send the notification
  /// We'll create a notification request in Firestore that Cloud Function will process
  Future<void> sendLogoutNotification(
      String oldDeviceToken, String platform) async {
    try {
      // Create notification request for Cloud Function to process
      await _firestore.collection('notification_queue').add({
        'token': oldDeviceToken,
        'platform': platform,
        'type': 'device_logout',
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('✅ Logout notification queued for old device');
    } catch (e) {
      debugPrint('❌ Error sending logout notification: $e');
    }
  }

  /// Clear active device (on logout)
  Future<void> clearActiveDevice(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'activeDevice': FieldValue.delete(),
      });

      await clearLocalSession();

      debugPrint('✅ Active device cleared');
    } catch (e) {
      debugPrint('❌ Error clearing active device: $e');
    }
  }

  /// Request FCM permission (for iOS mainly)
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  Future<void> updateDeviceToken(String userId, String newToken) async {
    try {
      final isActive = await isCurrentDeviceActive(userId);

      if (!isActive) {
        debugPrint('⚠️ Cannot update token - device is not active');
        return;
      }

      await _firestore.collection('users').doc(userId).update({
        'activeDevice.token': newToken,
        'activeDevice.tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Device token updated: ${newToken.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error updating device token: $e');
    }
  }

  /// Queue device update for offline scenario
  Future<void> _queueOfflineDeviceUpdate(
    String userId,
    String token,
    String platform,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save pending update
      await prefs.setString(
        'pending_device_update',
        jsonEncode({
          'userId': userId,
          'token': token,
          'platform': platform,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      debugPrint('📦 Device update queued for offline retry');
    } catch (e) {
      debugPrint('❌ Error queueing offline update: $e');
    }
  }

  /// Process any pending offline device updates
  Future<void> processPendingDeviceUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUpdate = prefs.getString('pending_device_update');

      if (pendingUpdate == null) {
        debugPrint('✅ No pending device updates');
        return;
      }

      final data = jsonDecode(pendingUpdate) as Map<String, dynamic>;
      final userId = data['userId'] as String;
      final token = data['token'] as String;
      final platform = data['platform'] as String;

      debugPrint('🔄 Processing pending device update...');

      // Try to save again
      await _firestore.collection('users').doc(userId).update({
        'activeDevice': {
          'token': token,
          'platform': platform,
          'loginAt': FieldValue.serverTimestamp(),
        },
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      // Success! Remove from queue
      await prefs.remove('pending_device_update');
      debugPrint('✅ Pending device update processed successfully');
    } on FirebaseException catch (e) {
      debugPrint('⚠️ Still offline, will retry later: ${e.code}');
      // Keep in queue, will retry next time
    } catch (e) {
      debugPrint('❌ Error processing pending update: $e');
      // Remove corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_device_update');
    }
  }

  /// Save token to local storage
  Future<void> _saveLocalToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localTokenKey, token);
  }

  /// Save login timestamp
  Future<void> _saveLoginTimestamp(int timestamp) async {
    _loginTimestamp = timestamp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localLoginTimestampKey, timestamp);
  }

  /// Get local token (memory first, then SharedPreferences)
  Future<String?> getLocalToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_localTokenKey);
    return _cachedToken;
  }

  /// Get login timestamp
  Future<int?> getLoginTimestamp() async {
    if (_loginTimestamp != null) return _loginTimestamp;

    final prefs = await SharedPreferences.getInstance();
    _loginTimestamp = prefs.getInt(_localLoginTimestampKey);
    return _loginTimestamp;
  }

  /// Clear local session data
  Future<void> clearLocalSession() async {
    _cachedToken = null;
    _loginTimestamp = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localTokenKey);
    await prefs.remove(_localLoginTimestampKey);
  }
}
