import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/subscription_provider.dart';
import '../../../core/constants/subscription_constants.dart';

class ProfileInfoSection extends StatelessWidget {
  final UserProvider userProvider;

  const ProfileInfoSection({
    super.key,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    final userData = userProvider.userData ?? {};
    final createdAt = userData['createdAt']?.toDate() ?? DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    final memberSinceRaw = DateFormat('MMMM y', locale).format(createdAt);

    final memberSince = _capitalizeFirst(memberSinceRaw);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).accountInformation,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(AppLocalizations.of(context).memberSince, memberSince),
          SizedBox(height: 12.h),
          Consumer<SubscriptionProvider>(
            builder: (context, subProvider, _) {
              final tierName = _getTierDisplayName(context, subProvider);
              final isSubscribed = subProvider.isActive;

              return _buildInfoRow(
                AppLocalizations.of(context).accountType,
                tierName,
                isPremium: isSubscribed,
              );
            },
          ),
          if (userProvider.isAdmin) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(AppLocalizations.of(context).role,
                AppLocalizations.of(context).administrator,
                isAdmin: true),
          ],
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildInfoRow(String label, String value,
      {bool isPremium = false, bool isAdmin = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: isPremium || isAdmin
              ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h)
              : null,
          decoration: isPremium || isAdmin
              ? BoxDecoration(
                  color: isAdmin
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppColors.textPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isAdmin ? Colors.red : AppColors.textPrimary,
                  ),
                )
              : null,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight:
                  isPremium || isAdmin ? FontWeight.w600 : FontWeight.w500,
              color: isAdmin
                  ? Colors.red
                  : isPremium
                      ? AppColors.textPrimary
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _getTierDisplayName(
      BuildContext context, SubscriptionProvider provider) {
    if (provider.isInTrial) {
      return '${provider.tier.displayName} (Trial)';
    }

    switch (provider.tier) {
      case SubscriptionTier.free:
        return AppLocalizations.of(context).free;
      case SubscriptionTier.lite:
        return 'Lite';
      case SubscriptionTier.standard:
        return 'Standard';
    }
  }
}
