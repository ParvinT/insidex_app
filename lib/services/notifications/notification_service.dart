// lib/services/notifications/notification_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../features/notifications/notification_models.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Get local timezone
    final String timeZoneName = await _getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Initialize
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  /// Get local timezone name
  Future<String> _getLocalTimezone() async {
    try {
      // Cihazın timezone'ını otomatik algıla
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      debugPrint('✅ Detected device timezone: $currentTimeZone');
      return currentTimeZone;
    } catch (e) {
      debugPrint('⚠️ Error detecting timezone: $e');
      debugPrint('📍 Falling back to UTC offset detection...');

      // FALLBACK: UTC offset'e göre tahmin et
      try {
        final now = DateTime.now();
        final offset = now.timeZoneOffset.inHours;

        // En yaygın timezone'lar
        final fallbackTimezone = _getTimezoneFromOffset(offset);
        debugPrint(
            '📍 Using fallback timezone: $fallbackTimezone (UTC${offset >= 0 ? '+' : ''}$offset)');
        return fallbackTimezone;
      } catch (fallbackError) {
        debugPrint('❌ Fallback also failed: $fallbackError');
        debugPrint('🌍 Using UTC as last resort');
        return 'UTC';
      }
    }
  }

  String _getTimezoneFromOffset(int offsetHours) {
    switch (offsetHours) {
      case -11:
        return 'Pacific/Midway';
      case -10:
        return 'Pacific/Honolulu';
      case -9:
        return 'America/Anchorage';
      case -8:
        return 'America/Los_Angeles';
      case -7:
        return 'America/Denver';
      case -6:
        return 'America/Chicago';
      case -5:
        return 'America/New_York';
      case -4:
        return 'America/Caracas';
      case -3:
        return 'America/Sao_Paulo';
      case -2:
        return 'Atlantic/South_Georgia';
      case -1:
        return 'Atlantic/Azores';
      case 0:
        return 'Europe/London';
      case 1:
        return 'Europe/Paris';
      case 2:
        return 'Europe/Athens';
      case 3:
        return 'Europe/Istanbul';
      case 4:
        return 'Asia/Dubai';
      case 5:
        return 'Asia/Karachi';
      case 6:
        return 'Asia/Dhaka';
      case 7:
        return 'Asia/Bangkok';
      case 8:
        return 'Asia/Shanghai';
      case 9:
        return 'Asia/Tokyo';
      case 10:
        return 'Australia/Sydney';
      case 11:
        return 'Pacific/Noumea';
      case 12:
        return 'Pacific/Auckland';
      default:
        return 'UTC';
    }
  }

  Future<bool> checkAndRequestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final bool? canScheduleExact =
            await androidPlugin.canScheduleExactNotifications();

        if (canScheduleExact == false) {
          debugPrint('⚠️ Exact alarm permission not granted');

          final bool? granted =
              await androidPlugin.requestExactAlarmsPermission();
          if (granted == true) {
            debugPrint('✅ Exact alarm permission granted');
            return true;
          } else {
            debugPrint('❌ Exact alarm permission denied');
            // Kullanıcıyı ayarlara yönlendir
            await _showAlarmPermissionDialog();
            return false;
          }
        }

        return canScheduleExact ?? true;
      }
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
      return true;
    }

    return true;
  }

  Future<void> _showAlarmPermissionDialog() async {
    debugPrint('💡 User needs to manually enable alarm permission in settings');
    // Burada kullanıcıya bir dialog gösterebilirsiniz
    // openAppSettings() çağırabilirsiniz
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = AndroidFlutterLocalNotificationsPlugin();

    // Daily Reminder Channel
    const dailyChannel = AndroidNotificationChannel(
      NotificationConstants.dailyReminderChannelId,
      NotificationConstants.dailyReminderChannelName,
      description: NotificationConstants.dailyReminderChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // General Channel
    const generalChannel = AndroidNotificationChannel(
      NotificationConstants.generalChannelId,
      NotificationConstants.generalChannelName,
      description: NotificationConstants.generalChannelDesc,
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await androidPlugin.createNotificationChannel(dailyChannel);
    await androidPlugin.createNotificationChannel(generalChannel);
  }

  /// Check if notifications are permitted
  Future<bool> hasPermission() async {
    if (Platform.isIOS) {
      final status = await permission.Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      if (await _isAndroid13OrHigher()) {
        final status = await permission.Permission.notification.status;
        return status.isGranted;
      }
      // For older Android versions, permissions are granted at install
      return true;
    }
    return false;
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        // iOS permissions
        final bool? granted = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return granted ?? false;
      } else if (Platform.isAndroid && await _isAndroid13OrHigher()) {
        // Android 13+ permissions
        final status = await permission.Permission.notification.request();
        return status.isGranted;
      }
      // For older Android, return true
      return true;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  /// Check if system notifications are enabled
  Future<bool> areSystemNotificationsEnabled() async {
    if (Platform.isIOS) {
      final status = await permission.Permission.notification.status;
      return !status.isPermanentlyDenied;
    } else if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await androidPlugin?.areNotificationsEnabled() ?? false;
      return enabled;
    }
    return false;
  }

  /// Open app notification settings
  static Future<void> openAppSettings() async {
    await permission.openAppSettings();
  }

  /// Show a notification immediately
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? NotificationConstants.generalChannelId,
      channelId == NotificationConstants.dailyReminderChannelId
          ? NotificationConstants.dailyReminderChannelName
          : NotificationConstants.generalChannelName,
      channelDescription:
          channelId == NotificationConstants.dailyReminderChannelId
              ? NotificationConstants.dailyReminderChannelDesc
              : NotificationConstants.generalChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to specific screens based on payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Check if Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    // Android 13 is API level 33
    // You might need device_info_plus package for accurate API level check
    // For now, we'll assume newer devices need permission
    return true; // Simplified for this implementation
  }

  // ===== PERMISSION DIALOG SECTION =====
  static const String _permissionShownKey = 'notification_permission_shown';

  /// Check and show permission dialog (to be called from HomeScreen)
  static Future<void> checkAndShowPermissionDialog(BuildContext context) async {
    try {
      // Check if already shown
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool(_permissionShownKey) ?? false;

      if (hasShown) return;

      // Check if already has permission
      final provider = context.read<NotificationProvider>();
      await provider.checkPermissions();

      if (provider.hasPermission) {
        await prefs.setBool(_permissionShownKey, true);
        return;
      }

      // Wait a bit before showing
      await Future.delayed(const Duration(seconds: 2));

      if (!context.mounted) return;

      // Show dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildPermissionDialog(context),
      );
    } catch (e) {
      debugPrint('Error showing permission dialog: $e');
    }
  }

  /// Build the permission dialog widget
  static Widget _buildPermissionDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                size: 40.sp,
                color: AppColors.primaryGold,
              ),
            ),

            SizedBox(height: 20.h),

            // Title
            Text(
              'Stay on Track',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 12.h),

            // Description
            Text(
              'Get daily reminders to maintain your wellness routine and achieve your goals',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            SizedBox(height: 24.h),

            // Buttons
            Row(
              children: [
                // Not Now Button
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(_permissionShownKey, true);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'Not Now',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Enable Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final provider = context.read<NotificationProvider>();
                      final granted = await provider.requestPermission();

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(_permissionShownKey, true);

                      if (context.mounted) {
                        Navigator.pop(context);

                        if (granted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Notifications enabled! 🔔'),
                              backgroundColor: AppColors.primaryGold,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                    child: Text(
                      'Enable',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
