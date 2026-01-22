import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme_extension.dart';
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
    final colors = context.colors;
    final userData = userProvider.userData ?? {};
    final createdAt = userData['createdAt']?.toDate() ?? DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    final memberSinceRaw = DateFormat('MMMM y', locale).format(createdAt);

    final memberSince = _capitalizeFirst(memberSinceRaw);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.03),
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
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
              context, AppLocalizations.of(context).memberSince, memberSince),
          SizedBox(height: 12.h),
          Consumer<SubscriptionProvider>(
            builder: (context, subProvider, _) {
              final tierName = _getTierDisplayName(context, subProvider);
              final isSubscribed = subProvider.isActive;

              return _buildInfoRow(
                context,
                AppLocalizations.of(context).accountType,
                tierName,
                isPremium: isSubscribed,
              );
            },
          ),
          if (userProvider.isAdmin) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(context, AppLocalizations.of(context).role,
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

  Widget _buildInfoRow(BuildContext context, String label, String value,
      {bool isPremium = false, bool isAdmin = false}) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isAdmin ? Colors.red : colors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getTierDisplayName(
      BuildContext context, SubscriptionProvider provider) {
    final l10n = AppLocalizations.of(context);

    String tierName;
    switch (provider.tier) {
      case SubscriptionTier.free:
        tierName = l10n.free;
      case SubscriptionTier.lite:
        tierName = l10n.tierLite;
      case SubscriptionTier.standard:
        tierName = l10n.tierStandard;
    }

    if (provider.isInTrial) {
      return l10n.tierWithTrial(tierName);
    }

    return tierName;
  }
}
