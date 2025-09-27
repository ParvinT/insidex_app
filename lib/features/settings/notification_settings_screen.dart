// lib/features/settings/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/notification/notification_service.dart';
import '../../core/responsive/context_ext.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Loading state
  bool _isLoading = true;

  // Notification settings
  bool _notificationsEnabled = false;
  bool _dailyReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Get saved settings from Firebase
      final settings = await NotificationService().getNotificationSettings();

      debugPrint('Loaded settings from service: $settings');

      // Parse reminder time
      final timeStr = settings['reminderTime'] ?? '20:00';
      debugPrint('Parsing time string: $timeStr');

      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 20;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      debugPrint('Parsed time - Hour: $hour, Minute: $minute');

      if (mounted) {
        setState(() {
          _notificationsEnabled = settings['enabled'] ?? false;
          _dailyReminder = settings['dailyReminder'] ?? false;
          _reminderTime = TimeOfDay(hour: hour, minute: minute);
          _isLoading = false;
        });

        debugPrint(
            'State updated - Reminder time: ${_reminderTime.hour}:${_reminderTime.minute}');

        // If both notifications and daily reminder are enabled, schedule it
        if (_notificationsEnabled && _dailyReminder) {
          await _scheduleDailyReminder();
          debugPrint('Daily reminder scheduled on load');
        }
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleMainToggle(bool value) async {
    if (value) {
      // Request system permissions if needed
      final systemEnabled =
          await NotificationService().areNotificationsEnabled();

      if (!systemEnabled) {
        // Need to request system permission first
        final granted = await NotificationService().requestPermissions();

        if (!granted) {
          // Permission denied at system level
          setState(() => _notificationsEnabled = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please enable notifications in system settings',
                  style: GoogleFonts.inter(fontSize: 14.sp),
                ),
                backgroundColor: Colors.grey[800],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            );
          }
          return;
        }
      }

      // System permission granted, enable notifications
      setState(() => _notificationsEnabled = true);

      // Save to Firebase with current dailyReminder state
      final settings = {
        'enabled': true,
        'dailyReminder': _dailyReminder,
        'reminderTime':
            '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
      };

      debugPrint('Saving main toggle ON: $settings');
      await NotificationService().saveNotificationSettings(settings);

      // Schedule daily reminder if it was enabled
      if (_dailyReminder) {
        await _scheduleDailyReminder();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notifications enabled successfully',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
    } else {
      // Disable notifications - ALSO DISABLE DAILY REMINDER
      setState(() {
        _notificationsEnabled = false;
        _dailyReminder = false; // ÖNEMLİ: Daily reminder'ı da kapat
      });

      // Cancel all scheduled notifications
      await NotificationService().cancelAllNotifications();

      // Save to Firebase - dailyReminder is now false
      final settings = {
        'enabled': false,
        'dailyReminder': false, // KAPATILDI
        'reminderTime':
            '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
      };

      debugPrint('Saving main toggle OFF: $settings');
      await NotificationService().saveNotificationSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All notifications disabled',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDailyReminderToggle(bool value) async {
    if (!_notificationsEnabled) return;

    // Update state first
    setState(() => _dailyReminder = value);

    // Directly save with the new value
    final settings = {
      'enabled': _notificationsEnabled,
      'dailyReminder': value, // Use the new value directly
      'reminderTime':
          '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
    };

    debugPrint('Saving daily reminder toggle: $settings');
    await NotificationService().saveNotificationSettings(settings);

    if (value) {
      // Schedule daily reminder
      await _scheduleDailyReminder();
    } else {
      // Cancel daily reminder
      await NotificationService().cancelDailyReminder();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Daily reminder enabled' : 'Daily reminder disabled',
            style: GoogleFonts.inter(fontSize: 14.sp),
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    }
  }

  Future<void> _scheduleDailyReminder() async {
    debugPrint(
        'Scheduling daily reminder for ${_reminderTime.hour}:${_reminderTime.minute}');

    await NotificationService().scheduleDailyReminder(
      time: _reminderTime,
      title: 'Time for your daily session 🧘',
      body: 'Take a moment to relax and recharge with INSIDEX',
    );
  }

  Future<void> _selectReminderTime() async {
    if (!_notificationsEnabled || !_dailyReminder) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.textPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      // Update state
      setState(() => _reminderTime = picked);

      // Format time string properly
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      // Save to Firebase
      final settings = {
        'enabled': _notificationsEnabled,
        'dailyReminder': _dailyReminder,
        'reminderTime': formattedTime,
      };

      debugPrint('Saving new reminder time: $formattedTime');
      await NotificationService().saveNotificationSettings(settings);

      // Reschedule with new time
      await NotificationService().scheduleDailyReminder(
        time: picked,
        title: 'Time for your daily session 🧘',
        body: 'Take a moment to relax and recharge with INSIDEX',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder time updated to ${picked.format(context)}',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      // Prepare settings object
      final settings = {
        'enabled': _notificationsEnabled,
        'dailyReminder': _dailyReminder,
        'reminderTime':
            '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
      };

      debugPrint('Saving settings to Firebase: $settings');

      await NotificationService().saveNotificationSettings(settings);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> _testNotification() async {
    if (!_notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enable notifications first',
            style: GoogleFonts.inter(fontSize: 14.sp),
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      return;
    }

    await NotificationService().showTestNotification();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive helpers
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final horizontalPadding = isDesktop ? 40.w : (isTablet ? 32.w : 20.w);
    final maxWidth = isDesktop ? 800.0 : (isTablet ? 600.0 : double.infinity);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24.h),

                      // Main toggle card
                      _buildMainToggleCard(),

                      // Show other options only if notifications are enabled
                      if (_notificationsEnabled) ...[
                        SizedBox(height: 32.h),

                        // Daily Reminder Section
                        Text(
                          'Reminder Settings',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 18.sp : 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 16.h),

                        _buildDailyReminderCard(),

                        // Show time selector if daily reminder is enabled
                        if (_dailyReminder) ...[
                          SizedBox(height: 16.h),
                          _buildTimeSelector(),
                        ],

                        SizedBox(height: 32.h),

                        // Test notification button
                        _buildTestButton(),
                      ],

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMainToggleCard() {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _notificationsEnabled
              ? AppColors.primaryGold.withOpacity(0.3)
              : AppColors.greyBorder,
          width: _notificationsEnabled ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _notificationsEnabled
                ? AppColors.primaryGold.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: _notificationsEnabled ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: isTablet ? 56.w : 48.w,
            height: isTablet ? 56.w : 48.w,
            decoration: BoxDecoration(
              color: _notificationsEnabled
                  ? AppColors.primaryGold.withOpacity(0.1)
                  : AppColors.greyLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: _notificationsEnabled
                  ? AppColors.primaryGold
                  : AppColors.textSecondary,
              size: isTablet ? 28.sp : 24.sp,
            ),
          ),
          SizedBox(width: 16.w),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Notifications',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 18.sp : 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _notificationsEnabled
                      ? 'You will receive notifications'
                      : 'Turn on to receive notifications',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Switch
          Switch(
            value: _notificationsEnabled,
            onChanged: _handleMainToggle,
            activeColor: AppColors.primaryGold,
            activeTrackColor: AppColors.primaryGold.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReminderCard() {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: isTablet ? 44.w : 40.w,
            height: isTablet ? 44.w : 40.w,
            decoration: BoxDecoration(
              color: _dailyReminder
                  ? AppColors.primaryGold.withOpacity(0.1)
                  : AppColors.greyLight,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.wb_sunny_outlined,
              color: _dailyReminder
                  ? AppColors.primaryGold
                  : AppColors.textSecondary,
              size: isTablet ? 24.sp : 20.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reminders',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16.sp : 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Get reminded for your daily session',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 13.sp : 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Switch
          Switch(
            value: _dailyReminder,
            onChanged:
                _notificationsEnabled ? _handleDailyReminderToggle : null,
            activeColor: AppColors.primaryGold,
            activeTrackColor: AppColors.primaryGold.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    final isTablet = context.isTablet;

    return InkWell(
      onTap: _selectReminderTime,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.greyBorder),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: isTablet ? 44.w : 40.w,
              height: isTablet ? 44.w : 40.w,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.access_time,
                color: AppColors.textPrimary,
                size: isTablet ? 24.sp : 20.sp,
              ),
            ),
            SizedBox(width: 12.w),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Time',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16.sp : 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _reminderTime.format(context),
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 13.sp : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    final isTablet = context.isTablet;

    return Center(
      child: TextButton.icon(
        onPressed: _testNotification,
        icon: Icon(
          Icons.notifications_outlined,
          size: isTablet ? 20.sp : 18.sp,
        ),
        label: Text(
          'Send Test Notification',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 15.sp : 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }
}
