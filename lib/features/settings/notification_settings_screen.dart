// lib/features/settings/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/notification_service.dart';
import '../../core/responsive/context_ext.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;

  // Notification settings
  bool _notificationsEnabled = false;
  bool _dailyReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _sessionNotifications = true;
  bool _achievementNotifications = true;
  bool _marketingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Check system notification permission
      final enabled = await NotificationService().areNotificationsEnabled();

      // Load user preferences
      final settings = await NotificationService().getNotificationSettings();

      // Parse reminder time
      final timeStr = settings['reminderTime'] ?? '20:00';
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 20;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
          _dailyReminder = settings['dailyReminder'] ?? true;
          _reminderTime = TimeOfDay(hour: hour, minute: minute);
          _sessionNotifications = settings['sessionNotifications'] ?? true;
          _achievementNotifications =
              settings['achievementNotifications'] ?? true;
          _marketingNotifications = settings['marketingNotifications'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleMainToggle(bool value) async {
    if (value) {
      // Request permissions
      final granted = await NotificationService().requestPermissions();

      if (granted) {
        setState(() => _notificationsEnabled = true);

        // Show success notification
        await NotificationService().showNotification(
          title: 'Notifications Enabled! 🎉',
          body: 'You will now receive INSIDEX notifications',
        );

        // Schedule daily reminder if enabled
        if (_dailyReminder) {
          await _scheduleDailyReminder();
        }

        // Save settings
        await _saveSettings();

        _showSnackBar('Notifications enabled successfully!', isSuccess: true);
      } else {
        setState(() => _notificationsEnabled = false);
        _showSnackBar('Please enable notifications in system settings',
            isWarning: true);
      }
    } else {
      // Disable all notifications
      setState(() => _notificationsEnabled = false);
      await NotificationService().cancelAllNotifications();
      await _saveSettings();
      _showSnackBar('Notifications disabled');
    }
  }

  Future<void> _handleDailyReminderToggle(bool value) async {
    if (!_notificationsEnabled) {
      _showSnackBar('Please enable notifications first', isWarning: true);
      return;
    }

    setState(() => _dailyReminder = value);

    if (value) {
      await _scheduleDailyReminder();
      _showSnackBar('Daily reminder enabled');
    } else {
      await NotificationService().cancelDailyReminder();
      _showSnackBar('Daily reminder disabled');
    }

    await _saveSettings();
  }

  Future<void> _scheduleDailyReminder() async {
    await NotificationService().scheduleDailyReminder(
      time: _reminderTime,
      title: 'Time for your daily session 🧘',
      body: 'Take a moment to relax and recharge with INSIDEX',
    );
  }

  Future<void> _selectReminderTime() async {
    if (!_notificationsEnabled || !_dailyReminder) {
      _showSnackBar('Enable daily reminder first', isWarning: true);
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.textPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() => _reminderTime = picked);
      await _scheduleDailyReminder();
      await _saveSettings();
      _showSnackBar('Reminder time updated to ${picked.format(context)}',
          isSuccess: true);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await NotificationService().saveNotificationSettings({
        'enabled': _notificationsEnabled,
        'dailyReminder': _dailyReminder,
        'reminderTime': '${_reminderTime.hour}:${_reminderTime.minute}',
        'sessionNotifications': _sessionNotifications,
        'achievementNotifications': _achievementNotifications,
        'marketingNotifications': _marketingNotifications,
      });
    } catch (e) {
      print('Error saving settings: $e');
    }

    setState(() => _isSaving = false);
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green
            : isWarning
                ? Colors.orange
                : null,
      ),
    );
  }

  Future<void> _testNotification() async {
    if (!_notificationsEnabled) {
      _showSnackBar('Please enable notifications first', isWarning: true);
      return;
    }

    await NotificationService().showNotification(
      title: 'Test Notification 🔔',
      body: 'This is a test notification from INSIDEX',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive helpers
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final horizontalPadding = isDesktop ? 32.w : (isTablet ? 28.w : 24.w);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        toolbarHeight: (isTablet || isDesktop) ? 72 : kToolbarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24.sp.clamp(24.0, 26.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 24.sp.clamp(24.0, 28.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    // Main notification toggle
                    _buildMainToggle(),

                    SizedBox(height: 32.h),

                    // Notification Types Section
                    _buildSectionHeader('Notification Types'),
                    SizedBox(height: 12.h),
                    _buildNotificationTypes(),

                    SizedBox(height: 32.h),

                    // Schedule Section
                    _buildSectionHeader('Schedule'),
                    SizedBox(height: 12.h),
                    _buildScheduleSection(),

                    SizedBox(height: 32.h),

                    // Test Section
                    _buildTestSection(),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainToggle() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _notificationsEnabled
              ? AppColors.primaryGold
              : AppColors.greyBorder,
          width: _notificationsEnabled ? 2 : 1,
        ),
        boxShadow: _notificationsEnabled
            ? [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
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
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _notificationsEnabled
                      ? 'Receiving all notifications'
                      : 'Turn on to receive notifications',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: _handleMainToggle,
            activeColor: AppColors.primaryGold,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.wb_sunny_outlined,
            title: 'Daily Reminders',
            subtitle: 'Get reminded for your daily session',
            value: _dailyReminder,
            enabled: _notificationsEnabled,
            onChanged: _handleDailyReminderToggle,
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.check_circle_outline,
            title: 'Session Notifications',
            subtitle: 'Notifications when you complete sessions',
            value: _sessionNotifications,
            enabled: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _sessionNotifications = value);
              await _saveSettings();
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle: 'Celebrate your milestones',
            value: _achievementNotifications,
            enabled: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _achievementNotifications = value);
              await _saveSettings();
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.campaign_outlined,
            title: 'Updates & Offers',
            subtitle: 'New content and special offers',
            value: _marketingNotifications,
            enabled: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _marketingNotifications = value);
              await _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: ListTile(
        enabled: _notificationsEnabled && _dailyReminder,
        onTap: _selectReminderTime,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 8.h,
        ),
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: (_notificationsEnabled && _dailyReminder)
                ? AppColors.primaryGold.withOpacity(0.1)
                : AppColors.greyLight,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.access_time,
            color: (_notificationsEnabled && _dailyReminder)
                ? AppColors.primaryGold
                : AppColors.textSecondary,
            size: 20.sp,
          ),
        ),
        title: Text(
          'Daily Reminder Time',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: (_notificationsEnabled && _dailyReminder)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        subtitle: Text(
          _reminderTime.format(context),
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Center(
      child: TextButton.icon(
        onPressed: _notificationsEnabled ? _testNotification : null,
        icon: Icon(
          Icons.bug_report_outlined,
          color: _notificationsEnabled
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
        label: Text(
          'Send Test Notification',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: _notificationsEnabled
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primaryGold.withOpacity(0.1)
                  : AppColors.greyLight,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.primaryGold : AppColors.textSecondary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value && enabled,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primaryGold,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.greyLight,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 76.w),
      child: const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.greyBorder,
      ),
    );
  }
}
