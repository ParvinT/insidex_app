// lib/features/admin/admin_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/admin_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _emailController = TextEditingController();
  List<Map<String, dynamic>> _adminList = [];
  bool _isLoading = false;
  int _waitlistCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
    _loadWaitlistCount();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    final admins = await AdminService.getAdminList();
    setState(() {
      _adminList = admins;
      _isLoading = false;
    });
  }

  Future<void> _loadWaitlistCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('waitlist')
        .where('marketingConsent', isEqualTo: true)
        .get();

    setState(() {
      _waitlistCount = snapshot.size;
    });
  }

  Future<void> _addNewAdmin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    // Find user by email
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (users.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).userNotFound(email)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userData = users.docs.first;
    final success = await AdminService.makeUserAdmin(
      userId: userData.id,
      email: email,
    );

    if (success) {
      _emailController.clear();
      _loadAdmins();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).adminAccessGranted(email)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Email sending dialog
  void _showSendEmailDialog() {
    final subjectController = TextEditingController(
      text: '🎉 INSIDEX Premium is Now Available!',
    );
    final titleController = TextEditingController(
      text: 'Premium Launch - Special Offer',
    );
    final messageController = TextEditingController(
      text: 'We are excited to announce that INSIDEX Premium is finally here! '
          'As an early supporter, you get exclusive access at 50% OFF for the first 3 months.',
    );
    final testEmailController = TextEditingController();
    bool sendTest = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            AppLocalizations.of(context).sendPremiumAnnouncement,
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(maxWidth: 400.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .sendToWaitlist(_waitlistCount.toString()),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Subject field
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).emailSubject,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Title field
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).emailTitle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Message field
                  TextField(
                    controller: messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).message,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Test email option
                  CheckboxListTile(
                    value: sendTest,
                    onChanged: (value) {
                      setState(() => sendTest = value ?? false);
                    },
                    title:
                        Text(AppLocalizations.of(context).sendTestEmailFirst),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),

                  if (sendTest) ...[
                    TextField(
                      controller: testEmailController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).testEmail,
                        hintText: 'your@email.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _sendWaitlistEmail(
                  subject: subjectController.text,
                  title: titleController.text,
                  message: messageController.text,
                  sendTest: sendTest,
                  testEmail: sendTest ? testEmailController.text : null,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
              ),
              child: Text(sendTest
                  ? AppLocalizations.of(context).sendTest
                  : AppLocalizations.of(context).sendToAll),
            ),
          ],
        ),
      ),
    );
  }

  // Email sending function
  Future<void> _sendWaitlistEmail({
    required String subject,
    required String title,
    required String message,
    required bool sendTest,
    String? testEmail,
  }) async {
    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPrimary,
        ),
      ),
    );

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendWaitlistAnnouncement');

      final result = await callable.call({
        'subject': subject,
        'title': title,
        'message': message,
        'sendTest': sendTest,
        'testEmail': testEmail,
      });

      // Hide loading
      if (mounted) Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data['message'] ??
              AppLocalizations.of(context).emailSentSuccessfully),
          backgroundColor: Colors.green,
        ),
      );

      // Reload count if sent to all
      if (!sendTest) {
        _loadWaitlistCount();
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context).errorSendingEmail}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).adminManagement,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Campaign Section - NEW!
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.textPrimary.withValues(alpha: 0.1),
                    AppColors.textPrimary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📧 ${AppLocalizations.of(context).premiumWaitlistCampaign}',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '$_waitlistCount ${AppLocalizations.of(context).subscribersWithConsent}',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed:
                            _waitlistCount > 0 ? _showSendEmailDialog : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).send,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Add New Admin Section - EXISTING CODE
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.greyBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).addNewAdmin,
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).userEmail,
                            hintText: AppLocalizations.of(context).enterEmail,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            isDense: true,
                          ),
                          style: GoogleFonts.inter(fontSize: 14.sp),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: _addNewAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).addAdmin,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Admin List - EXISTING CODE
            Text(
              AppLocalizations.of(context).currentAdmins,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ...(_adminList.map((admin) => _buildAdminCard(admin)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.textPrimary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.admin_panel_settings,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin['email'] ?? AppLocalizations.of(context).unknown,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${AppLocalizations.of(context).role}: ${admin['role'] ?? 'admin'}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeAdmin(admin['id']),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAdmin(String adminId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).removeAdminAccess),
        content: Text(AppLocalizations.of(context).removeAdminConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).remove,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminService.removeAdminAccess(adminId);
      if (success) {
        _loadAdmins();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).adminAccessRemoved),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
