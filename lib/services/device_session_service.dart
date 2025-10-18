// lib/services/device_session_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

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

  /// Save current device as active device for user
  /// This will trigger logout on any other device
  Future<void> saveActiveDevice(String userId) async {
    try {
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        debugPrint(
            '⚠️ Notification permission denied - device session may not work properly');
      }
      // Get FCM token
      final fcmToken = await _messaging.getToken();

      if (fcmToken == null) {
        debugPrint('⚠️ FCM token is null, cannot save device');
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';

      // Update user's active device
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
    } catch (e) {
      debugPrint('❌ Error saving active device: $e');
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
  Future<bool> isCurrentDeviceActive(String userId) async {
    try {
      final currentToken = await getCurrentDeviceToken();
      if (currentToken == null) return false;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();

      if (data == null) return false;

      final activeDevice = data['activeDevice'] as Map<String, dynamic>?;
      if (activeDevice == null) return true; // No active device set yet

      final activeToken = activeDevice['token'] as String?;

      return currentToken == activeToken;
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
}
