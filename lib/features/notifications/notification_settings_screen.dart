// lib/features/notifications/notification_settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/context_ext.dart';
import '../../providers/notification_provider.dart';
import 'notification_models.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Check permissions on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().checkPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final isCompact = context.isCompactH;

    // Adaptive sizing
    final double horizontalPadding =
        isDesktop ? 40.w : (isTablet ? 24.w : 16.w);

    final double maxContentWidth =
        isDesktop ? 600 : (isTablet ? 500 : double.infinity);

    final double titleSize =
        isTablet ? 24.sp.clamp(22.0, 26.0) : 20.sp.clamp(18.0, 22.0);

    final double bodyTextSize =
        isTablet ? 14.sp.clamp(13.0, 15.0) : 13.sp.clamp(12.0, 14.0);

    final double sectionTitleSize =
        isTablet ? 16.sp.clamp(15.0, 17.0) : 14.sp.clamp(13.0, 15.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: isTablet ? 64 : 56,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24.sp.clamp(22.0, 26.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    // Permission Warning (if needed)
                    if (!provider.hasPermission) ...[
                      _buildPermissionWarning(context, provider, bodyTextSize),
                      SizedBox(height: 20.h),
                    ],

                    // System Settings Warning (if needed)
                    if (provider.hasPermission &&
                        !provider.systemNotificationsEnabled) ...[
                      _buildSystemSettingsWarning(
                          context, provider, bodyTextSize),
                      SizedBox(height: 20.h),
                    ],

                    // All Notifications Toggle
                    _buildNotificationCard(
                      context: context,
                      title: 'All Notifications',
                      subtitle: 'Master control for all app notifications',
                      icon: Icons.notifications_outlined,
                      value: provider.allNotificationsEnabled,
                      onChanged: provider.hasPermission
                          ? (value) async {
                              await provider.toggleAllNotifications(value);
                            }
                          : null,
                      bodyTextSize: bodyTextSize,
                      sectionTitleSize: sectionTitleSize,
                    ),

                    SizedBox(height: 16.h),

                    // Daily Reminders Section
                    _buildSectionHeader('Daily Reminders', sectionTitleSize),
                    SizedBox(height: 12.h),

                    _buildDailyReminderCard(
                      context: context,
                      provider: provider,
                      bodyTextSize: bodyTextSize,
                      sectionTitleSize: sectionTitleSize,
                      isTablet: isTablet,
                    ),

                    SizedBox(height: 24.h),

                    // Test Notification Button (for debugging)
                    if (provider.allNotificationsEnabled &&
                        provider.hasPermission) ...[
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await provider.sendTestNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification sent! 🔔'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.bug_report_outlined,
                            size: 18.sp,
                            color: AppColors.textLight,
                          ),
                          label: Text(
                            'Send Test Notification',
                            style: GoogleFonts.inter(
                              fontSize: bodyTextSize,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionWarning(
    BuildContext context,
    NotificationProvider provider,
    double textSize,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 32.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12.h),
          Text(
            'Notifications Disabled',
            style: GoogleFonts.inter(
              fontSize: textSize + 2,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enable notifications to receive daily reminders for your wellness routine',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: textSize,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () async {
              final granted = await provider.requestPermission();
              if (mounted && !granted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Please enable notifications in system settings'),
                    action: SnackBarAction(
                      label: 'Open Settings',
                      onPressed: () => provider.openSystemSettings(),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              'Enable Notifications',
              style: GoogleFonts.inter(
                fontSize: textSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsWarning(
    BuildContext context,
    NotificationProvider provider,
    double textSize,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              NotificationConstants.notificationsDisabledInSystem,
              style: GoogleFonts.inter(
                fontSize: textSize,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: provider.openSystemSettings,
            child: Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: textSize,
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double fontSize) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool)? onChanged,
    required double bodyTextSize,
    required double sectionTitleSize,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.greyLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: 24.sp,
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
                    fontSize: sectionTitleSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: bodyTextSize,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Platform-specific switch
          Platform.isIOS
              ? CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primaryGold,
                )
              : Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primaryGold,
                ),
        ],
      ),
    );
  }

  Widget _buildDailyReminderCard({
    required BuildContext context,
    required NotificationProvider provider,
    required double bodyTextSize,
    required double sectionTitleSize,
    required bool isTablet,
  }) {
    final reminder = provider.dailyReminder;
    final enabled = reminder.enabled && provider.allNotificationsEnabled;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toggle Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.greyLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.alarm,
                  color: AppColors.textPrimary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Reminder',
                      style: GoogleFonts.inter(
                        fontSize: sectionTitleSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Get reminded to practice daily',
                      style: GoogleFonts.inter(
                        fontSize: bodyTextSize,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Platform.isIOS
                  ? CupertinoSwitch(
                      value: enabled,
                      onChanged: provider.allNotificationsEnabled
                          ? (value) => provider.toggleDailyReminder(value)
                          : null,
                      activeColor: AppColors.primaryGold,
                    )
                  : Switch(
                      value: enabled,
                      onChanged: provider.allNotificationsEnabled
                          ? (value) => provider.toggleDailyReminder(value)
                          : null,
                      activeColor: AppColors.primaryGold,
                    ),
            ],
          ),

          // Time Selector (shown when enabled)
          if (enabled) ...[
            SizedBox(height: 16.h),
            const Divider(color: AppColors.greyBorder),
            SizedBox(height: 16.h),
            InkWell(
              onTap: () => _showTimePicker(context, provider),
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greyLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reminder Time',
                      style: GoogleFonts.inter(
                        fontSize: bodyTextSize,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          reminder.formattedTime12Hour,
                          style: GoogleFonts.inter(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.access_time,
                          size: 18.sp,
                          color: AppColors.primaryGold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final currentTime =
        TimeOfDay.fromDateTime(provider.dailyReminder.scheduledTime);

    if (Platform.isIOS || context.isTablet) {
      // iOS style or tablet - use modal bottom sheet
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            _buildIOSTimePicker(context, provider, currentTime),
      );
    } else {
      // Android style
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: currentTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryGold,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != currentTime) {
        await provider.updateDailyReminderTime(picked);
      }
    }
  }

  Widget _buildIOSTimePicker(
    BuildContext context,
    NotificationProvider provider,
    TimeOfDay currentTime,
  ) {
    TimeOfDay selectedTime = currentTime;

    return Container(
      height: 320.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  'Select Time',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await provider.updateDailyReminderTime(selectedTime);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Time Picker
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(
                2024,
                1,
                1,
                currentTime.hour,
                currentTime.minute,
              ),
              onDateTimeChanged: (DateTime newDateTime) {
                selectedTime = TimeOfDay.fromDateTime(newDateTime);
              },
            ),
          ),
        ],
      ),
    );
  }
}
