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
        // ✅ Get current device token BEFORE transaction
        final currentToken = await getCurrentDeviceToken();
        if (currentToken == null) {
          debugPrint('⚠️ Cannot get current token, skipping update');
          return;
        }

        debugPrint('🔐 Attempting atomic token update...');

        // ✅ Use Firestore Transaction for atomic read+write
        // This prevents race conditions when multiple devices are involved
        await _firestore.runTransaction((transaction) async {
          final userRef = _firestore.collection('users').doc(user.uid);
          final snapshot = await transaction.get(userRef);

          if (!snapshot.exists) {
            debugPrint('❌ User document not found');
            return;
          }

          final data = snapshot.data();
          if (data == null) {
            debugPrint('❌ User data is null');
            return;
          }

          final activeDevice = data['activeDevice'] as Map<String, dynamic>?;

          if (activeDevice == null) {
            debugPrint('⚠️ No active device set, skipping token update');
            return;
          }

          final activeToken = activeDevice['token'] as String?;

          // ✅ CRITICAL CHECK: Only update if current token is still active
          // This prevents Device B from being logged out if Device A's token refreshes
          if (activeToken == currentToken) {
            // Current device is still active, safe to update token
            transaction.update(userRef, {
              'activeDevice.token': newToken,
              'activeDevice.tokenUpdatedAt': FieldValue.serverTimestamp(),
            });
            debugPrint(
                '✅ Token updated atomically: ${newToken.substring(0, 20)}...');
          } else {
            // Current device is no longer active, skip update
            debugPrint(
                '⏭️ Device no longer active (current: ${currentToken.substring(0, 20)}, active: ${activeToken?.substring(0, 20)}), skipping update');
          }
        });

        debugPrint('✅ Token refresh handled successfully');
      } catch (e) {
        debugPrint('❌ Error handling token refresh: $e');
        // Don't rethrow - token refresh failures should not crash the app
      }
    });
  }

  /// Save current device as active device for user
  /// This will trigger logout on any other device
  Future<void> saveActiveDevice(String userId) async {
    String? fcmToken;
    String? platform;

    try {
      // Determine platform first
      platform = Platform.isIOS ? 'ios' : 'android';

      // ✅ iOS CRITICAL: Permission is REQUIRED for device session
      if (Platform.isIOS) {
        debugPrint('🍎 iOS detected - checking notification permission...');

        final hasPermission = await requestNotificationPermission();

        if (!hasPermission) {
          debugPrint('❌ iOS notification permission DENIED');
          debugPrint(
              '⚠️ Device session system requires notification permission');
          debugPrint(
              '💡 User should enable notifications in Settings > Notifications');

          // iOS'ta permission yoksa FCM token null olacak
          // Sistem çalışmaz, devam etmeye gerek yok
          throw Exception(
              'iOS notification permission required for device session security');
        }

        debugPrint('✅ iOS notification permission granted');
      }

      // Get FCM token
      fcmToken = await _messaging.getToken();

      if (fcmToken == null) {
        debugPrint('❌ FCM token is null - cannot save device session');

        if (Platform.isIOS) {
          debugPrint(
              '💡 This usually happens when notification permission is denied on iOS');
        }

        throw Exception('FCM token unavailable');
      }

      debugPrint('🔑 FCM Token obtained: ${fcmToken.substring(0, 20)}...');

      // Update user's active device in Firestore
      await _firestore.collection('users').doc(userId).update({
        'activeDevice': {
          'token': fcmToken,
          'platform': platform,
          'loginAt': FieldValue.serverTimestamp(),
        },
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '✅ Active device saved: $platform - ${fcmToken.substring(0, 20)}...');
      debugPrint('🔐 Multi-device logout system activated');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error while saving device: ${e.code}');
      debugPrint('   Message: ${e.message}');

      // Re-throw to let caller handle
      rethrow;
    } catch (e) {
      debugPrint('❌ Error saving active device: $e');

      // Re-throw to let caller handle
      rethrow;
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

  /// Check if current device is the active device for the user
  ///
  /// Returns true if:
  /// - Current device token matches active device token in Firestore
  /// - No active device is set (legacy user - will auto-initialize)
  ///
  /// Returns false if:
  /// - Current device token is null (permission denied or error)
  /// - Another device is currently active
  Future<bool> isCurrentDeviceActive(String userId) async {
    try {
      final currentToken = await getCurrentDeviceToken();
      if (currentToken == null) {
        debugPrint('⚠️ Current device token is null');
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();

      if (data == null) {
        debugPrint('⚠️ User data not found');
        return false;
      }

      final activeDevice = data['activeDevice'] as Map<String, dynamic>?;

      if (activeDevice == null) {
        // ✅ BACKWARD COMPATIBILITY: Legacy user without activeDevice field
        debugPrint(
            '🔄 Legacy user detected - initializing activeDevice field...');

        try {
          // Auto-initialize activeDevice for legacy users
          await saveActiveDevice(userId);
          debugPrint('✅ activeDevice initialized for legacy user');

          // After initialization, this device is the active one
          return true;
        } catch (e) {
          debugPrint('❌ Failed to initialize activeDevice: $e');

          // If initialization fails, still allow login (fallback)
          // This prevents blocking legacy users if there's an error
          debugPrint('⚠️ Falling back to permissive mode for legacy user');
          return true;
        }
      }

      // Normal flow: check if current token matches active token
      final activeToken = activeDevice['token'] as String?;
      final isActive = currentToken == activeToken;

      if (isActive) {
        debugPrint('✅ Current device is active');
      } else {
        debugPrint('⚠️ Current device is NOT active');
        debugPrint('   Current token: ${currentToken.substring(0, 20)}...');
        debugPrint('   Active token: ${activeToken?.substring(0, 20)}...');
      }

      return isActive;
    } catch (e) {
      debugPrint('❌ Error checking device status: $e');
      return false;
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

  /// Update device token for active device
  ///
  /// ⚠️ DEPRECATED - DO NOT CALL DIRECTLY
  ///
  /// This method has a race condition issue and should not be used.
  /// Token refresh is now handled automatically by initializeTokenRefreshListener()
  /// using Firestore transactions for atomic updates.
  ///
  /// Race condition scenario:
  /// 1. Device A: Token refresh starts
  /// 2. Device B: Logs in (becomes active)
  /// 3. Device A: Checks isActive (outdated cache returns true)
  /// 4. Device A: Updates token (overwrites Device B!)
  /// 5. Result: Device B gets logged out incorrectly
  ///
  /// This method is kept for backward compatibility only.
  /// If you need to manually update token, use a transaction instead.
  ///
  /// @deprecated Use initializeTokenRefreshListener() with transaction

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
}
