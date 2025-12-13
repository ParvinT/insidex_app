// lib/features/feedback/feedback_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../l10n/app_localizations.dart';

class FeedbackDialog extends StatefulWidget {
  final bool isBugReport;

  const FeedbackDialog({
    super.key,
    this.isBugReport = false,
  });

  static void show(BuildContext context, {bool isBugReport = false}) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(isBugReport: isBugReport),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedType = 'suggestion';
  int _rating = 4;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
    if (widget.isBugReport) {
      _selectedType = 'bug';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Temiz data hazırla
      final feedbackData = {
        // ZORUNLU ALANLAR (Rules'a uygun)
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),

        // OPSIYONEL ALANLAR
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'rating': _selectedType != 'bug' ? _rating : null,
        'userId': FirebaseAuth.instance.currentUser?.uid,

        // META DATA
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': Theme.of(context).platform.toString(),
          'screenSize':
              '${MediaQuery.of(context).size.width.toInt()}x${MediaQuery.of(context).size.height.toInt()}',
        },
      };

      // Null değerleri temizle
      feedbackData.removeWhere((key, value) => value == null);

      // Firestore'a kaydet
      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).thankYouForFeedback,
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).error}${e.toString()}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Debug için
      debugPrint('Feedback submit error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final Map<String, String> typeLabels = {
      'suggestion': l10n.suggestion,
      'bug': l10n.bugReport,
      'feature_request': l10n.featureRequest,
      'complaint': l10n.complaint,
      'other': l10n.other,
    };
    return Dialog(
      backgroundColor: colors.backgroundElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 400.w,
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isBugReport ? l10n.reportBug : l10n.sendFeedback,
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Selector
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.border),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: l10n.type,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 12.h),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: colors.textPrimary,
                            ),
                            items: typeLabels.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedType = value!);
                            },
                          ),
                        ),

                        // Rating (not for bugs)
                        if (_selectedType != 'bug') ...[
                          SizedBox(height: 20.h),
                          Text(
                            l10n.rateYourExperience,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _rating = index + 1),
                                child: Icon(
                                  index < _rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: colors.textPrimary,
                                  size: 36.sp,
                                ),
                              );
                            }),
                          ),
                        ],

                        SizedBox(height: 20.h),

                        // Title Field
                        TextFormField(
                          controller: _titleController,
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: l10n.title,
                            hintText: l10n.briefSummary,
                            labelStyle: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontSize: 14.sp,
                            ),
                            hintStyle: GoogleFonts.inter(
                              color: colors.textLight,
                              fontSize: 14.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                  color: colors.textPrimary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterTitle;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Message Field
                        TextFormField(
                          controller: _messageController,
                          maxLines: 4,
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: l10n.details,
                            hintText: l10n.tellUsMore,
                            alignLabelWithHint: true,
                            labelStyle: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontSize: 14.sp,
                            ),
                            hintStyle: GoogleFonts.inter(
                              color: colors.textLight,
                              fontSize: 14.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                  color: colors.textPrimary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseDescribeFeedback;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Email Field (optional)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: l10n.emailOptional,
                            hintText: l10n.forFollowUp,
                            labelStyle: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontSize: 14.sp,
                            ),
                            hintStyle: GoogleFonts.inter(
                              color: colors.textLight,
                              fontSize: 14.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                  color: colors.textPrimary, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 65.h,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              color: colors.textOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            l10n.submitFeedback,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: colors.textOnPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
