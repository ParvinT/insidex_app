// lib/features/admin/notifications/push_notification_history_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../l10n/app_localizations.dart';

class PushNotificationHistoryTab extends StatelessWidget {
  const PushNotificationHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('push_notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: colors.textPrimary,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 48.sp,
                  color: colors.textLight,
                ),
                SizedBox(height: 12.h),
                Text(
                  l10n.adminPushNoHistory,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildHistoryCard(context, data, colors);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    Map<String, dynamic> data,
    AppThemeExtension colors,
  ) {
    final titles = data['titles'] as Map<String, dynamic>? ?? {};
    final bodies = data['bodies'] as Map<String, dynamic>? ?? {};
    final status = data['status'] as String? ?? 'unknown';
    final target = data['target'] as Map<String, dynamic>? ?? {};
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final createdByEmail = data['createdByEmail'] as String? ?? 'Unknown';
    final successCount = data['successCount'] as int? ?? 0;
    final failureCount = data['failureCount'] as int? ?? 0;

    final statusColor = switch (status) {
      'sent' => Colors.green,
      'error' || 'failed' => Colors.red,
      'pending' => Colors.orange,
      _ => colors.textLight,
    };

    final statusIcon = switch (status) {
      'sent' => Icons.check_circle,
      'error' || 'failed' => Icons.error,
      'pending' => Icons.schedule,
      _ => Icons.help_outline,
    };

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (createdAt != null)
                Text(
                  DateFormat('MMM d, HH:mm').format(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: colors.textLight,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),

          // Title
          Text(
            titles['en'] ?? 'No title',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),

          // Body
          Text(
            bodies['en'] ?? 'No body',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: colors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),

          // Footer
          Row(
            children: [
              // Target badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _getTargetLabel(target),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Languages count
              if (titles.length > 1)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${titles.length} langs',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),

              const Spacer(),

              // Success/Failure count
              if (status == 'sent') ...[
                Icon(Icons.check, color: Colors.green, size: 14.sp),
                SizedBox(width: 2.w),
                Text(
                  '$successCount',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (failureCount > 0) ...[
                  SizedBox(width: 8.w),
                  Icon(Icons.close, color: Colors.red, size: 14.sp),
                  SizedBox(width: 2.w),
                  Text(
                    '$failureCount',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],

              // Sent by
              SizedBox(width: 8.w),
              Text(
                createdByEmail.split('@').first,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: colors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTargetLabel(Map<String, dynamic> target) {
    final audience = target['audience'] as String? ?? 'all';
    switch (audience) {
      case 'all':
        return '📢 All';
      case 'language':
        final langs = (target['languages'] as List?)?.join(',') ?? '';
        return '🌐 $langs'.toUpperCase();
      case 'tier':
        final tiers = (target['tiers'] as List?)?.join(',') ?? '';
        return '💎 $tiers';
      case 'platform':
        final platforms = (target['platforms'] as List?)?.join(',') ?? '';
        return '📱 $platforms';
      case 'custom':
        return '🎯 Custom';
      case 'individual':
        final userEmail = target['userEmail'] as String? ?? '';
        return '👤 ${userEmail.split('@').first}';
      default:
        return audience;
    }
  }
}