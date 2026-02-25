// lib/features/admin/notifications/push_notification_compose_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../l10n/app_localizations.dart';

class PushNotificationComposeTab extends StatefulWidget {
  const PushNotificationComposeTab({super.key});

  @override
  State<PushNotificationComposeTab> createState() =>
      _PushNotificationComposeTabState();
}

class _PushNotificationComposeTabState extends State<PushNotificationComposeTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  // Title controllers per language
  final _titleEn = TextEditingController();
  final _titleTr = TextEditingController();
  final _titleRu = TextEditingController();
  final _titleHi = TextEditingController();

  // Body controllers per language
  final _bodyEn = TextEditingController();
  final _bodyTr = TextEditingController();
  final _bodyRu = TextEditingController();
  final _bodyHi = TextEditingController();

  // Target configuration
  String _audience = 'all';
  final Set<String> _selectedLanguages = {};
  final Set<String> _selectedTiers = {};
  final Set<String> _selectedPlatforms = {};

  bool _isSending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _titleEn.dispose();
    _titleTr.dispose();
    _titleRu.dispose();
    _titleHi.dispose();
    _bodyEn.dispose();
    _bodyTr.dispose();
    _bodyRu.dispose();
    _bodyHi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audience Selection
            _buildSectionTitle(l10n.adminPushTargetAudience, colors),
            SizedBox(height: 8.h),
            _buildAudienceSelector(colors, l10n),
            SizedBox(height: 16.h),

            // Conditional filters
            if (_audience == 'language' || _audience == 'custom') ...[
              _buildFilterSection(
                l10n.adminPushLanguages,
                {
                  'en': '🇬🇧 English',
                  'tr': '🇹🇷 Türkçe',
                  'ru': '🇷🇺 Русский',
                  'hi': '🇮🇳 हिन्दी',
                },
                _selectedLanguages,
                colors,
              ),
              SizedBox(height: 12.h),
            ],

            if (_audience == 'tier' || _audience == 'custom') ...[
              _buildFilterSection(
                l10n.adminPushSubscriptionTier,
                {
                  'free': '🆓 Free',
                  'lite': '⭐ Lite',
                  'standard': '👑 Standard',
                },
                _selectedTiers,
                colors,
              ),
              SizedBox(height: 12.h),
            ],

            if (_audience == 'platform' || _audience == 'custom') ...[
              _buildFilterSection(
                l10n.adminPushPlatform,
                {
                  'ios': '🍎 iOS',
                  'android': '🤖 Android',
                },
                _selectedPlatforms,
                colors,
              ),
              SizedBox(height: 12.h),
            ],

            SizedBox(height: 8.h),
            Divider(color: colors.border),
            SizedBox(height: 16.h),

            // Notification Content
            _buildSectionTitle(l10n.adminPushNotificationContent, colors),
            SizedBox(height: 12.h),

            // Dynamic language fields based on audience mode
            ..._buildLanguageFieldsList(colors, l10n),

            SizedBox(height: 24.h),

            // Preview
            _buildPreviewCard(colors, l10n),

            SizedBox(height: 24.h),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.textPrimary,
                  foregroundColor: colors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  disabledBackgroundColor:
                      colors.textPrimary.withValues(alpha: 0.5),
                ),
                child: _isSending
                    ? SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: CircularProgressIndicator(
                          color: colors.textOnPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.adminPushSendNotification,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  /// Whether English is required based on audience mode.
  /// In "By Language" mode, EN is optional (fallback only).
  bool get _isEnRequired => _audience != 'language';

  /// All language definitions with their controllers.
  List<_LanguageFieldConfig> get _allLanguages => [
        _LanguageFieldConfig('en', '🇬🇧', 'English', _titleEn, _bodyEn),
        _LanguageFieldConfig('tr', '🇹🇷', 'Türkçe', _titleTr, _bodyTr),
        _LanguageFieldConfig('ru', '🇷🇺', 'Русский', _titleRu, _bodyRu),
        _LanguageFieldConfig('hi', '🇮🇳', 'हिन्दी', _titleHi, _bodyHi),
      ];

  /// Build language input fields dynamically based on audience mode.
  List<Widget> _buildLanguageFieldsList(
      AppThemeExtension colors, AppLocalizations l10n) {
    final widgets = <Widget>[];
    final isLanguageMode = _audience == 'language';

    for (final lang in _allLanguages) {
      // In "By Language" mode: show EN (optional) + only selected languages
      if (isLanguageMode &&
          lang.code != 'en' &&
          !_selectedLanguages.contains(lang.code)) {
        continue;
      }

      final bool isRequired;
      final String label;

      if (lang.code == 'en') {
        isRequired = _isEnRequired;
        label =
            isRequired ? l10n.adminPushEnglishRequired : 'English (Fallback)';
      } else {
        // In "By Language" mode, selected languages are required
        isRequired = isLanguageMode && _selectedLanguages.contains(lang.code);
        label = isRequired ? '${lang.label} ✱' : lang.label;
      }

      widgets.add(
        _buildLanguageFields(
          flag: lang.flag,
          label: label,
          titleController: lang.titleController,
          bodyController: lang.bodyController,
          isRequired: isRequired,
          colors: colors,
          l10n: l10n,
        ),
      );
      widgets.add(SizedBox(height: 16.h));
    }

    return widgets;
  }

  Widget _buildSectionTitle(String title, AppThemeExtension colors) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildAudienceSelector(
      AppThemeExtension colors, AppLocalizations l10n) {
    final audiences = {
      'all': '📢 ${l10n.adminPushAllUsers}',
      'language': '🌐 ${l10n.adminPushByLanguage}',
      'tier': '💎 ${l10n.adminPushByTier}',
      'platform': '📱 ${l10n.adminPushByPlatform}',
      'custom': '🎯 ${l10n.adminPushCustom}',
    };

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: audiences.entries.map((entry) {
        final isSelected = _audience == entry.key;
        return ChoiceChip(
          label: Text(
            entry.value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? colors.textOnPrimary : colors.textPrimary,
            ),
          ),
          selected: isSelected,
          selectedColor: colors.textPrimary,
          backgroundColor: colors.backgroundCard,
          side: BorderSide(
            color: isSelected ? colors.textPrimary : colors.border,
          ),
          onSelected: (_) {
            setState(() {
              _audience = entry.key;
              if (entry.key == 'all') {
                _selectedLanguages.clear();
                _selectedTiers.clear();
                _selectedPlatforms.clear();
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildFilterSection(
    String title,
    Map<String, String> options,
    Set<String> selected,
    AppThemeExtension colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.entries.map((entry) {
            final isSelected = selected.contains(entry.key);
            return FilterChip(
              label: Text(
                entry.value,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colors.textOnPrimary : colors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: colors.textPrimary,
              backgroundColor: colors.backgroundCard,
              checkmarkColor: colors.textOnPrimary,
              side: BorderSide(
                color: isSelected ? colors.textPrimary : colors.border,
              ),
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selected.add(entry.key);
                  } else {
                    selected.remove(entry.key);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageFields({
    required String flag,
    required String label,
    required TextEditingController titleController,
    required TextEditingController bodyController,
    bool isRequired = false,
    required AppThemeExtension colors,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: TextStyle(fontSize: 18.sp)),
              SizedBox(width: 8.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextFormField(
            controller: titleController,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: l10n.title,
              labelStyle: GoogleFonts.inter(
                fontSize: 13.sp,
                color: colors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: colors.textPrimary, width: 1.5),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.adminPushTitleRequired;
                    }
                    return null;
                  }
                : null,
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: bodyController,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: colors.textPrimary,
            ),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.adminPushBody,
              labelStyle: GoogleFonts.inter(
                fontSize: 13.sp,
                color: colors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: colors.textPrimary, width: 1.5),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.adminPushBodyRequired;
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(AppThemeExtension colors, AppLocalizations l10n) {
    final title = _titleEn.text.isNotEmpty ? _titleEn.text : l10n.title;
    final body = _bodyEn.text.isNotEmpty ? _bodyEn.text : l10n.adminPushBody;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminPushPreview,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: colors.backgroundCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: colors.textPrimary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'now',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: colors.textLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _sendNotification() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    // Validate target selection
    if (_audience == 'language' && _selectedLanguages.isEmpty) {
      _showError(l10n.adminPushSelectLanguage);
      return;
    }
    if (_audience == 'tier' && _selectedTiers.isEmpty) {
      _showError(l10n.adminPushSelectTier);
      return;
    }
    if (_audience == 'platform' && _selectedPlatforms.isEmpty) {
      _showError(l10n.adminPushSelectPlatform);
      return;
    }

    // In "By Language" mode, ensure at least EN or selected languages have content
    if (_audience == 'language') {
      final hasAnyContent = _selectedLanguages.any((lang) {
        final titleCtrl = _getControllerForLang(lang, isTitle: true);
        return titleCtrl?.text.trim().isNotEmpty == true;
      });
      if (!hasAnyContent && _titleEn.text.trim().isEmpty) {
        _showError(l10n.adminPushTitleBodyRequired);
        return;
      }
    }

    // Confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Build titles map (only non-empty)
      final titles = <String, String>{};
      if (_titleEn.text.trim().isNotEmpty) titles['en'] = _titleEn.text.trim();
      if (_titleTr.text.trim().isNotEmpty) titles['tr'] = _titleTr.text.trim();
      if (_titleRu.text.trim().isNotEmpty) titles['ru'] = _titleRu.text.trim();
      if (_titleHi.text.trim().isNotEmpty) titles['hi'] = _titleHi.text.trim();

      // Build bodies map (only non-empty)
      final bodies = <String, String>{};
      if (_bodyEn.text.trim().isNotEmpty) bodies['en'] = _bodyEn.text.trim();
      if (_bodyTr.text.trim().isNotEmpty) bodies['tr'] = _bodyTr.text.trim();
      if (_bodyRu.text.trim().isNotEmpty) bodies['ru'] = _bodyRu.text.trim();
      if (_bodyHi.text.trim().isNotEmpty) bodies['hi'] = _bodyHi.text.trim();

      // Build target
      final target = <String, dynamic>{
        'audience': _audience,
      };

      if (_selectedLanguages.isNotEmpty) {
        target['languages'] = _selectedLanguages.toList();
      }
      if (_selectedTiers.isNotEmpty) {
        target['tiers'] = _selectedTiers.toList();
      }
      if (_selectedPlatforms.isNotEmpty) {
        target['platforms'] = _selectedPlatforms.toList();
      }

      // Write to Firestore — Cloud Function will handle sending
      await FirebaseFirestore.instance.collection('push_notifications').add({
        'titles': titles,
        'bodies': bodies,
        'target': target,
        'notificationType': 'general',
        'createdBy': user.uid,
        'createdByEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.adminPushSentSuccess,
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        _clearForm();
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      if (mounted) {
        _showError('${l10n.error}${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<bool?> _showConfirmationDialog() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final targetDescription = _getTargetDescription(l10n);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          l10n.adminPushSendConfirm,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmRow('Target:', targetDescription, colors),
            SizedBox(height: 8.h),
            _buildConfirmRow('${l10n.title} (EN):', _titleEn.text, colors),
            SizedBox(height: 8.h),
            _buildConfirmRow(
                '${l10n.adminPushBody} (EN):', _bodyEn.text, colors),
            SizedBox(height: 12.h),
            Text(
              l10n.adminPushSendWarning,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: colors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              l10n.send,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(
      String label, String value, AppThemeExtension colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: colors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getTargetDescription(AppLocalizations l10n) {
    switch (_audience) {
      case 'all':
        return l10n.adminPushAllUsers;
      case 'language':
        return '${l10n.adminPushLanguages}: ${_selectedLanguages.join(", ").toUpperCase()}';
      case 'tier':
        return '${l10n.adminPushSubscriptionTier}: ${_selectedTiers.join(", ")}';
      case 'platform':
        return '${l10n.adminPushPlatform}: ${_selectedPlatforms.join(", ")}';
      case 'custom':
        final parts = <String>[];
        if (_selectedLanguages.isNotEmpty) {
          parts.add('Lang: ${_selectedLanguages.join(",")}');
        }
        if (_selectedTiers.isNotEmpty) {
          parts.add('Tier: ${_selectedTiers.join(",")}');
        }
        if (_selectedPlatforms.isNotEmpty) {
          parts.add('Platform: ${_selectedPlatforms.join(",")}');
        }
        return parts.join(' + ');
      default:
        return l10n.adminPushAllUsers;
    }
  }

  void _clearForm() {
    _titleEn.clear();
    _titleTr.clear();
    _titleRu.clear();
    _titleHi.clear();
    _bodyEn.clear();
    _bodyTr.clear();
    _bodyRu.clear();
    _bodyHi.clear();
    setState(() {
      _audience = 'all';
      _selectedLanguages.clear();
      _selectedTiers.clear();
      _selectedPlatforms.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  TextEditingController? _getControllerForLang(String lang,
      {required bool isTitle}) {
    switch (lang) {
      case 'en':
        return isTitle ? _titleEn : _bodyEn;
      case 'tr':
        return isTitle ? _titleTr : _bodyTr;
      case 'ru':
        return isTitle ? _titleRu : _bodyRu;
      case 'hi':
        return isTitle ? _titleHi : _bodyHi;
      default:
        return null;
    }
  }
}

/// Configuration for a language input field group.
class _LanguageFieldConfig {
  final String code;
  final String flag;
  final String label;
  final TextEditingController titleController;
  final TextEditingController bodyController;

  const _LanguageFieldConfig(
    this.code,
    this.flag,
    this.label,
    this.titleController,
    this.bodyController,
  );
}
