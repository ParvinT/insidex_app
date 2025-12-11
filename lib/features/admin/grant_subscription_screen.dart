// lib/features/admin/grant_subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/subscription_constants.dart';
import '../../core/responsive/breakpoints.dart';
import '../../models/subscription_model.dart';
import '../../providers/subscription_provider.dart';
import '../../l10n/app_localizations.dart';

class GrantSubscriptionScreen extends StatefulWidget {
  const GrantSubscriptionScreen({super.key});

  @override
  State<GrantSubscriptionScreen> createState() =>
      _GrantSubscriptionScreenState();
}

class _GrantSubscriptionScreenState extends State<GrantSubscriptionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isGranting = false;
  String? _errorMessage;
  Map<String, dynamic>? _foundUser;
  String? _foundUserId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an email or UID';
        _foundUser = null;
        _foundUserId = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundUser = null;
      _foundUserId = null;
    });

    try {
      QuerySnapshot? result;

      
      // Check if query looks like an email
      if (query.contains('@')) {
        // Search by email - try multiple variations
        final emailVariations = [
          query, // Original
          query.toLowerCase(), // lowercase
          query.trim(), // trimmed
          query.toLowerCase().trim(), // lowercase + trimmed
        ];

        for (final emailVariant in emailVariations) {
          result = await _firestore
              .collection('users')
              .where('email', isEqualTo: emailVariant)
              .limit(1)
              .get();

          if (result!.docs.isNotEmpty) break;
        }
      } else {
        // Search by UID - direct document access
        final doc = await _firestore.collection('users').doc(query).get();

        if (doc.exists) {
          setState(() {
            _foundUser = doc.data();
            _foundUserId = doc.id;
            _isSearching = false;
          });
          return;
        }
      }

      if (result != null && result.docs.isNotEmpty) {
        setState(() {
          _foundUser = result!.docs.first.data() as Map<String, dynamic>;
          _foundUserId = result.docs.first.id;
        });
      } else {
        setState(() {
          _errorMessage = 'User not found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _grantSubscription(SubscriptionTier tier, int days) async {
    if (_foundUserId == null) return;

    setState(() => _isGranting = true);

    try {
      final subscriptionProvider = context.read<SubscriptionProvider>();

      final success = await subscriptionProvider.grantSubscription(
        userId: _foundUserId!,
        tier: tier,
        durationDays: days,
        period: days >= 365
            ? SubscriptionPeriod.yearly
            : SubscriptionPeriod.monthly,
      );

      if (success && mounted) {
        // Refresh user data
        await _searchUser();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully granted ${tier.displayName} for $days days',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to grant subscription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGranting = false);
      }
    }
  }

  Future<void> _revokeSubscription() async {
    if (_foundUserId == null) return;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Subscription'),
        content: const Text(
          'Are you sure you want to revoke this user\'s subscription? '
          'They will lose access to premium features immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isGranting = true);

    try {
      final subscriptionProvider = context.read<SubscriptionProvider>();

      final success =
          await subscriptionProvider.revokeSubscription(_foundUserId!);

      if (success && mounted) {
        // Refresh user data
        await _searchUser();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription revoked successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to revoke subscription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGranting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final isDesktop = width >= Breakpoints.desktopMin;

    final horizontalPadding = isDesktop ? 40.w : (isTablet ? 30.w : 20.w);
    final maxContentWidth =
        isDesktop ? 700.0 : (isTablet ? 600.0 : double.infinity);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Grant Subscription',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 20.h,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Section
                _buildSearchSection(isTablet),

                SizedBox(height: 24.h),

                // Error Message
                if (_errorMessage != null) _buildErrorMessage(),

                // User Info Card
                if (_foundUser != null) ...[
                  _buildUserInfoCard(isTablet),
                  SizedBox(height: 24.h),
                  _buildSubscriptionOptions(isTablet),
                ],

                // Empty State
                if (_foundUser == null &&
                    _errorMessage == null &&
                    !_isSearching)
                  _buildEmptyState(isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder),
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
            'Search User',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter user email address or UID',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'email@example.com or user-uid',
                    hintStyle: GoogleFonts.inter(
                      fontSize: isTablet ? 15.sp : 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: isTablet ? 24.sp : 22.sp,
                    ),
                    filled: true,
                    fillColor: AppColors.greyLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: isTablet ? 16.h : 14.h,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 15.sp : 14.sp,
                    color: AppColors.textPrimary,
                  ),
                  onSubmitted: (_) => _searchUser(),
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                height: isTablet ? 52.h : 48.h,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24.w : 20.w),
                    elevation: 0,
                  ),
                  child: _isSearching
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Search',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 15.sp : 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(bool isTablet) {
    final subscription = _foundUser!['subscription'] as Map<String, dynamic>?;
    final subModel = SubscriptionModel.fromMap(subscription);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder),
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
          // Header
          Row(
            children: [
              Container(
                width: isTablet ? 60.w : 50.w,
                height: isTablet ? 60.w : 50.w,
                decoration: BoxDecoration(
                  color: subModel.isActive
                      ? Colors.amber.withValues(alpha: 0.15)
                      : AppColors.greyLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (_foundUser!['name'] as String?)
                            ?.substring(0, 1)
                            .toUpperCase() ??
                        'U',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 24.sp : 20.sp,
                      fontWeight: FontWeight.w700,
                      color: subModel.isActive
                          ? Colors.amber.shade700
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _foundUser!['name'] ?? 'Unknown User',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 18.sp : 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _foundUser!['email'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 14.sp : 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Admin badge
              if (_foundUser!['isAdmin'] == true)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    'ADMIN',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 16.h),

          // UID (copyable)
          _buildInfoRow(
            'UID',
            _foundUserId ?? '',
            isTablet,
            showCopy: true,
          ),

          SizedBox(height: 12.h),
          Divider(color: AppColors.greyBorder.withValues(alpha: 0.5)),
          SizedBox(height: 12.h),

          // Subscription Info
          Text(
            'Current Subscription',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 16.sp : 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),

          _buildSubscriptionInfoRow(
            'Tier',
            subModel.tier.displayName,
            isTablet,
            valueColor: subModel.isActive ? Colors.amber.shade700 : null,
          ),
          SizedBox(height: 8.h),
          _buildSubscriptionInfoRow(
            'Status',
            subModel.status.value.toUpperCase(),
            isTablet,
            valueColor: _getStatusColor(subModel.status),
          ),
          SizedBox(height: 8.h),
          _buildSubscriptionInfoRow(
            'Source',
            subModel.source.value,
            isTablet,
          ),
          if (subModel.expiryDate != null) ...[
            SizedBox(height: 8.h),
            _buildSubscriptionInfoRow(
              'Expires',
              _formatDate(subModel.expiryDate!),
              isTablet,
              valueColor: subModel.isExpired ? Colors.red : Colors.green,
            ),
          ],
          if (subModel.isInTrial && subModel.trialEndDate != null) ...[
            SizedBox(height: 8.h),
            _buildSubscriptionInfoRow(
              'Trial Ends',
              _formatDate(subModel.trialEndDate!),
              isTablet,
              valueColor: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isTablet,
      {bool showCopy = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isTablet ? 80.w : 60.w,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showCopy)
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UID copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              Icons.copy,
              size: isTablet ? 20.sp : 18.sp,
              color: AppColors.textSecondary,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.all(4.w),
          ),
      ],
    );
  }

  Widget _buildSubscriptionInfoRow(String label, String value, bool isTablet,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14.sp : 13.sp,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: valueColor != null
              ? BoxDecoration(
                  color: valueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                )
              : null,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionOptions(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder),
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
            'Grant Subscription',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select a plan to grant to this user',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),

          // Plan options grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: isTablet ? 2.2 : 1.8,
            children: [
              _buildPlanOption(
                tier: SubscriptionTier.lite,
                days: 30,
                label: 'Lite',
                subtitle: '30 days',
                color: Colors.blue,
                isTablet: isTablet,
              ),
              _buildPlanOption(
                tier: SubscriptionTier.standard,
                days: 30,
                label: 'Standard',
                subtitle: '30 days',
                color: Colors.amber,
                isTablet: isTablet,
              ),
              _buildPlanOption(
                tier: SubscriptionTier.lite,
                days: 365,
                label: 'Lite',
                subtitle: '1 year',
                color: Colors.blue,
                isTablet: isTablet,
              ),
              _buildPlanOption(
                tier: SubscriptionTier.standard,
                days: 365,
                label: 'Standard',
                subtitle: '1 year',
                color: Colors.amber,
                isTablet: isTablet,
              ),
            ],
          ),

          SizedBox(height: 20.h),
          Divider(color: AppColors.greyBorder.withValues(alpha: 0.5)),
          SizedBox(height: 16.h),

          // Revoke button
          SizedBox(
            width: double.infinity,
            height: isTablet ? 52.h : 48.h,
            child: OutlinedButton.icon(
              onPressed: _isGranting ? null : _revokeSubscription,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.remove_circle_outline,
                  size: isTablet ? 22.sp : 20.sp),
              label: Text(
                'Revoke Subscription',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 15.sp : 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required SubscriptionTier tier,
    required int days,
    required String label,
    required String subtitle,
    required Color color,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: _isGranting ? null : () => _grantSubscription(tier, days),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16.w : 12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: _isGranting
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: color,
                    size: isTablet ? 28.sp : 24.sp,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 15.sp : 14.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 13.sp : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40.w : 32.w),
      child: Column(
        children: [
          Icon(
            Icons.person_search,
            size: isTablet ? 80.sp : 64.sp,
            color: AppColors.greyBorder,
          ),
          SizedBox(height: 16.h),
          Text(
            'Search for a user',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter an email address or UID to find a user\nand manage their subscription',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.trial:
        return Colors.blue;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.cancelled:
        return Colors.orange;
      case SubscriptionStatus.gracePeriod:
        return Colors.amber;
      case SubscriptionStatus.none:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
