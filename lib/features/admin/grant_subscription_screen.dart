// lib/features/admin/grant_subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/themes/app_theme_extension.dart';
import '../../core/responsive/breakpoints.dart';
import '../../l10n/app_localizations.dart';

/// Admin Premium Grant Screen
/// Allows admins to grant/revoke premium access to users
/// Independent of RevenueCat - stored in users/{uid}/adminPremium
class GrantSubscriptionScreen extends StatefulWidget {
  const GrantSubscriptionScreen({super.key});

  @override
  State<GrantSubscriptionScreen> createState() =>
      _GrantSubscriptionScreenState();
}

class _GrantSubscriptionScreenState extends State<GrantSubscriptionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isGranting = false;
  String? _errorMessage;
  Map<String, dynamic>? _foundUser;
  String? _foundUserId;

  // Selected reason for granting premium
  AdminPremiumReason _selectedReason = AdminPremiumReason.vip;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCH USER
  // ============================================================

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (query.isEmpty) {
      setState(() {
        _errorMessage = l10n.adminPremiumEnterEmailOrUid;
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
        // Search by email
        final emailVariations = [
          query,
          query.toLowerCase(),
          query.trim(),
          query.toLowerCase().trim(),
        ];

        for (final emailVariant in emailVariations) {
          result = await _firestore
              .collection('users')
              .where('email', isEqualTo: emailVariant)
              .limit(1)
              .get();

          if (result.docs.isNotEmpty) break;
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
          _errorMessage = l10n.adminPremiumUserNotFound;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.adminPremiumSearchError}: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // ============================================================
  // GRANT ADMIN PREMIUM
  // ============================================================

  Future<void> _grantAdminPremium() async {
    if (_foundUserId == null) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final currentAdmin = _auth.currentUser;

    setState(() => _isGranting = true);

    try {
      await _firestore.collection('users').doc(_foundUserId).update({
        'adminPremium': {
          'enabled': true,
          'tier': 'standard',
          'grantedAt': FieldValue.serverTimestamp(),
          'grantedBy': currentAdmin?.uid ?? 'unknown',
          'grantedByEmail': currentAdmin?.email ?? 'unknown',
          'reason': _selectedReason.value,
        },
      });

      // Refresh user data
      await _searchUser();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.adminPremiumGrantSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.adminPremiumGrantError}: ${e.toString()}'),
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

  // ============================================================
  // REVOKE ADMIN PREMIUM
  // ============================================================

  Future<void> _revokeAdminPremium() async {
    if (_foundUserId == null) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminPremiumRevokeTitle),
        content: Text(l10n.adminPremiumRevokeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isGranting = true);

    try {
      await _firestore.collection('users').doc(_foundUserId).update({
        'adminPremium': {
          'enabled': false,
          'revokedAt': FieldValue.serverTimestamp(),
          'revokedBy': _auth.currentUser?.uid ?? 'unknown',
        },
      });

      // Refresh user data
      await _searchUser();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.adminPremiumRevokeSuccess),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.adminPremiumRevokeError}: ${e.toString()}'),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    final width = MediaQuery.of(context).size.width;
    final isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final isDesktop = width >= Breakpoints.desktopMin;

    final horizontalPadding = isDesktop ? 40.w : (isTablet ? 30.w : 20.w);
    final maxContentWidth =
        isDesktop ? 700.0 : (isTablet ? 600.0 : double.infinity);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.grantSubscription,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
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
                _buildSearchSection(isTablet, colors, l10n),

                SizedBox(height: 24.h),

                // Error Message
                if (_errorMessage != null) _buildErrorMessage(colors),

                // User Info Card
                if (_foundUser != null) ...[
                  _buildUserInfoCard(isTablet, colors, l10n),
                  SizedBox(height: 24.h),
                  _buildAdminPremiumSection(isTablet, colors, l10n),
                ],

                // Empty State
                if (_foundUser == null &&
                    _errorMessage == null &&
                    !_isSearching)
                  _buildEmptyState(isTablet, colors, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UI COMPONENTS
  // ============================================================

  Widget _buildSearchSection(
      bool isTablet, AppThemeExtension colors, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: colors.backgroundPure,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
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
            l10n.adminPremiumSearchUser,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.adminPremiumSearchHint,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.adminPremiumSearchPlaceholder,
                    hintStyle: GoogleFonts.inter(
                      fontSize: isTablet ? 15.sp : 14.sp,
                      color: colors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colors.textSecondary,
                      size: isTablet ? 24.sp : 22.sp,
                    ),
                    filled: true,
                    fillColor: colors.greyLight,
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
                    color: colors.textPrimary,
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
                    backgroundColor: colors.textPrimary,
                    foregroundColor: colors.textOnPrimary,
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
                          child: CircularProgressIndicator(
                            color: colors.textOnPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.search,
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

  Widget _buildErrorMessage(AppThemeExtension colors) {
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

  Widget _buildUserInfoCard(
      bool isTablet, AppThemeExtension colors, AppLocalizations l10n) {
    final adminPremium = _foundUser!['adminPremium'] as Map<String, dynamic>?;
    final hasAdminPremium = adminPremium?['enabled'] == true;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: colors.backgroundPure,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasAdminPremium ? Colors.purple : colors.border,
          width: hasAdminPremium ? 2 : 1,
        ),
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
          // Header
          Row(
            children: [
              Container(
                width: isTablet ? 60.w : 50.w,
                height: isTablet ? 60.w : 50.w,
                decoration: BoxDecoration(
                  color: hasAdminPremium
                      ? Colors.purple.withValues(alpha: 0.15)
                      : colors.greyLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: hasAdminPremium
                      ? Icon(
                          Icons.verified,
                          color: Colors.purple,
                          size: isTablet ? 28.sp : 24.sp,
                        )
                      : Text(
                          (_foundUser!['name'] as String?)
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 24.sp : 20.sp,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _foundUser!['name'] ?? l10n.unknown,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 18.sp : 16.sp,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasAdminPremium) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'VIP',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _foundUser!['email'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 14.sp : 13.sp,
                        color: colors.textSecondary,
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
            colors: colors,
            l10n: l10n,
          ),

          SizedBox(height: 12.h),
          Divider(color: colors.border.withValues(alpha: 0.5)),
          SizedBox(height: 12.h),

          // Subscription Status
          Text(
            l10n.adminPremiumCurrentStatus,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 16.sp : 14.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),

          // Admin Premium Status
          _buildStatusRow(
            l10n.adminPremiumAdminStatus,
            hasAdminPremium ? l10n.active : l10n.adminPremiumInactive,
            hasAdminPremium ? Colors.purple : colors.textSecondary,
            isTablet,
            colors,
          ),

          if (hasAdminPremium && adminPremium != null) ...[
            SizedBox(height: 8.h),
            _buildStatusRow(
              l10n.adminPremiumTier,
              (adminPremium['tier'] as String?)?.toUpperCase() ?? 'STANDARD',
              Colors.amber.shade700,
              isTablet,
              colors,
            ),
            SizedBox(height: 8.h),
            _buildStatusRow(
              l10n.adminPremiumReason,
              _getReasonDisplayName(adminPremium['reason'] as String?, l10n),
              Colors.blue,
              isTablet,
              colors,
            ),
            if (adminPremium['grantedByEmail'] != null) ...[
              SizedBox(height: 8.h),
              _buildStatusRow(
                l10n.adminPremiumGrantedBy,
                adminPremium['grantedByEmail'] as String,
                colors.textSecondary,
                isTablet,
                colors,
              ),
            ],
          ],

          SizedBox(height: 8.h),

          // RevenueCat Status
          _buildStatusRow(
            l10n.adminPremiumStoreStatus,
            _getStoreSubscriptionStatus(l10n),
            _hasStoreSubscription() ? Colors.green : colors.textSecondary,
            isTablet,
            colors,
          ),
        ],
      ),
    );
  }

  bool _hasStoreSubscription() {
    // Check subscription data if available
    final subscription = _foundUser!['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return false;

    final tier = subscription['tier'] as String?;
    final source = subscription['source'] as String?;

    return tier != null && tier != 'free' && source == 'revenuecat';
  }

  String _getStoreSubscriptionStatus(AppLocalizations l10n) {
    final subscription = _foundUser!['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return l10n.adminPremiumNoSubscription;

    final tier = subscription['tier'] as String?;
    final source = subscription['source'] as String?;

    if (tier == null || tier == 'free') {
      return l10n.adminPremiumNoSubscription;
    }

    if (source == 'revenuecat') {
      return tier.toUpperCase();
    }

    return l10n.adminPremiumNoSubscription;
  }

  Widget _buildAdminPremiumSection(
      bool isTablet, AppThemeExtension colors, AppLocalizations l10n) {
    final adminPremium = _foundUser!['adminPremium'] as Map<String, dynamic>?;
    final hasAdminPremium = adminPremium?['enabled'] == true;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: colors.backgroundPure,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
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
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.purple,
                size: isTablet ? 28.sp : 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                l10n.adminPremiumManage,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18.sp : 16.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.adminPremiumManageDesc,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          if (!hasAdminPremium) ...[
            // Reason Selector
            Text(
              l10n.adminPremiumSelectReason,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14.sp : 13.sp,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            _buildReasonSelector(isTablet, colors, l10n),
            SizedBox(height: 20.h),

            // Grant Button
            SizedBox(
              width: double.infinity,
              height: isTablet ? 56.h : 52.h,
              child: ElevatedButton.icon(
                onPressed: _isGranting ? null : _grantAdminPremium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                icon: _isGranting
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.verified, size: isTablet ? 24.sp : 22.sp),
                label: Text(
                  l10n.adminPremiumGrantButton,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16.sp : 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Already has admin premium - show revoke option
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.purple,
                    size: isTablet ? 28.sp : 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminPremiumAlreadyActive,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 15.sp : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          l10n.adminPremiumFullAccess,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 13.sp : 12.sp,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Revoke Button
            SizedBox(
              width: double.infinity,
              height: isTablet ? 52.h : 48.h,
              child: OutlinedButton.icon(
                onPressed: _isGranting ? null : _revokeAdminPremium,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: _isGranting
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.remove_circle_outline,
                        size: isTablet ? 22.sp : 20.sp),
                label: Text(
                  l10n.adminPremiumRevokeButton,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 15.sp : 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonSelector(
      bool isTablet, AppThemeExtension colors, AppLocalizations l10n) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: AdminPremiumReason.values.map((reason) {
        final isSelected = _selectedReason == reason;
        return InkWell(
          onTap: () => setState(() => _selectedReason = reason),
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.purple.withValues(alpha: 0.15)
                  : colors.greyLight,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected ? Colors.purple : colors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reason.icon,
                  size: isTablet ? 18.sp : 16.sp,
                  color: isSelected ? Colors.purple : colors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Text(
                  _getReasonDisplayName(reason.value, l10n),
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.purple : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isTablet, {
    required AppThemeExtension colors,
    required AppLocalizations l10n,
    bool showCopy = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isTablet ? 80.w : 60.w,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
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
                SnackBar(
                  content: Text(l10n.adminPremiumUidCopied),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              Icons.copy,
              size: isTablet ? 20.sp : 18.sp,
              color: colors.textSecondary,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.all(4.w),
          ),
      ],
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    Color valueColor,
    bool isTablet,
    AppThemeExtension colors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14.sp : 13.sp,
            color: colors.textSecondary,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 13.sp : 12.sp,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      bool isTablet, AppThemeExtension colors, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40.w : 32.w),
      child: Column(
        children: [
          Icon(
            Icons.person_search,
            size: isTablet ? 80.sp : 64.sp,
            color: colors.border,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.adminPremiumEmptyTitle,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.adminPremiumEmptyDesc,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getReasonDisplayName(String? reason, AppLocalizations l10n) {
    switch (reason) {
      case 'vip':
        return l10n.adminPremiumReasonVip;
      case 'tester':
        return l10n.adminPremiumReasonTester;
      case 'employee':
        return l10n.adminPremiumReasonEmployee;
      case 'influencer':
        return l10n.adminPremiumReasonInfluencer;
      case 'other':
        return l10n.adminPremiumReasonOther;
      default:
        return reason ?? l10n.unknown;
    }
  }
}

/// Admin Premium Reason enum
enum AdminPremiumReason {
  vip('vip', Icons.star),
  tester('tester', Icons.bug_report),
  employee('employee', Icons.badge),
  influencer('influencer', Icons.campaign),
  other('other', Icons.more_horiz);

  final String value;
  final IconData icon;

  const AdminPremiumReason(this.value, this.icon);
}
