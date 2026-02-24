// lib/features/admin/notifications/push_notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../l10n/app_localizations.dart';
import 'push_notification_compose_tab.dart';
import 'push_notification_direct_tab.dart';
import 'push_notification_history_tab.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          l10n.adminPushNotifications,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.textPrimary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.textPrimary,
          labelStyle: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: l10n.adminPushSendNew),
            Tab(text: l10n.adminPushDirect),
            Tab(text: l10n.adminPushHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PushNotificationComposeTab(),
          PushNotificationDirectTab(),
          PushNotificationHistoryTab(),
        ],
      ),
    );
  }
}
