// lib/features/admin/notifications/push_notification_direct_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../l10n/app_localizations.dart';

class PushNotificationDirectTab extends StatefulWidget {
  const PushNotificationDirectTab({super.key});

  @override
  State<PushNotificationDirectTab> createState() =>
      _PushNotificationDirectTabState();
}

class _PushNotificationDirectTabState extends State<PushNotificationDirectTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _isSearching = false;
  bool _isSending = false;
  String? _errorMessage;
  Map<String, dynamic>? _foundUser;
  String? _foundUserId;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

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
      final firestore = FirebaseFirestore.instance;
      QuerySnapshot? result;

      if (query.contains('@')) {
        final emailVariations = [
          query,
          query.toLowerCase(),
          query.trim(),
          query.toLowerCase().trim(),
        ];

        for (final emailVariant in emailVariations) {
          result = await firestore
              .collection('users')
              .where('email', isEqualTo: emailVariant)
              .limit(1)
              .get();
          if (result.docs.isNotEmpty) break;
        }
      } else {
        final doc = await firestore.collection('users').doc(query).get();
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
        setState(() => _errorMessage = l10n.adminPremiumUserNotFound);
      }
    } catch (e) {
      setState(
          () => _errorMessage = '${l10n.adminPremiumSearchError}: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _sendDirectNotification() async {
    if (_foundUserId == null) return;
    final l10n = AppLocalizations.of(context);

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminPushTitleBodyRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await FirebaseFirestore.instance.collection('push_notifications').add({
        'titles': {'en': title},
        'bodies': {'en': body},
        'target': {
          'audience': 'individual',
          'userId': _foundUserId,
          'userEmail': _foundUser?['email'] ?? '',
        },
        'notificationType': 'direct',
        'createdBy': user.uid,
        'createdByEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminPushSentSuccess),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Section
          Text(
            l10n.adminPushFindUser,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.adminPushEmailOrUid,
                    hintStyle: GoogleFonts.inter(
                      color: colors.textSecondary.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide:
                          BorderSide(color: colors.textPrimary, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    prefixIcon:
                        Icon(Icons.search, color: colors.textSecondary),
                  ),
                  onSubmitted: (_) => _searchUser(),
                ),
              ),
              SizedBox(width: 10.w),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.textPrimary,
                    foregroundColor: colors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
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
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // Error
          if (_errorMessage != null) ...[
            SizedBox(height: 10.h),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.red,
              ),
            ),
          ],

          // User Info Card + Message Fields
          if (_foundUser != null) ...[
            SizedBox(height: 16.h),
            _buildUserCard(colors, l10n),
            SizedBox(height: 20.h),

            // Message Fields
            Text(
              l10n.adminPushNotificationContent,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: _titleController,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: l10n.title,
                labelStyle: GoogleFonts.inter(color: colors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide:
                      BorderSide(color: colors.textPrimary, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: _bodyController,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: colors.textPrimary,
              ),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.adminPushBody,
                labelStyle: GoogleFonts.inter(color: colors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide:
                      BorderSide(color: colors.textPrimary, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendDirectNotification,
                icon: _isSending
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          color: colors.textOnPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSending
                      ? l10n.adminPushSending
                      : l10n.adminPushSendToUser,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.textPrimary,
                  foregroundColor: colors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  disabledBackgroundColor:
                      colors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppThemeExtension colors, AppLocalizations l10n) {
    final name = _foundUser?['name'] as String? ?? l10n.unknown;
    final email = _foundUser?['email'] as String? ?? '';
    final lang = _foundUser?['preferredLanguage'] as String? ?? 'en';
    final activeDevice =
        _foundUser?['activeDevice'] as Map<String, dynamic>?;
    final hasToken = activeDevice?['token'] != null;
    final platform = activeDevice?['platform'] as String? ?? '-';
    final subscription =
        _foundUser?['subscription'] as Map<String, dynamic>?;
    final tier = subscription?['tier'] as String? ?? 'free';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasToken
              ? Colors.green.withValues(alpha: 0.5)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name & Email
          Row(
            children: [
              Icon(Icons.person, color: colors.textSecondary, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(color: colors.border, height: 1),
          SizedBox(height: 10.h),

          // Info badges
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _buildInfoBadge('🌐 $lang', colors),
              _buildInfoBadge('💎 $tier', colors),
              _buildInfoBadge('📱 $platform', colors),
              _buildInfoBadge(
                hasToken ? '✅ FCM Token' : '❌ No Token',
                colors,
                isError: !hasToken,
              ),
            ],
          ),

          if (!hasToken) ...[
            SizedBox(height: 10.h),
            Text(
              l10n.adminPushNoToken,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text, AppThemeExtension colors,
      {bool isError = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withValues(alpha: 0.1)
            : colors.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: isError ? Colors.red : colors.textPrimary,
        ),
      ),
    );
  }
}