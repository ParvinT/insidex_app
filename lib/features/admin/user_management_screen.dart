// lib/features/admin/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: Text(
          'User Management',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(20.w),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final docId = users[index].id;

              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['isPremium'] == true
                        ? AppColors.primaryGold
                        : AppColors.greyLight,
                    child: Text(
                      user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: user['isPremium'] == true
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  title: Text(
                    user['name'] ?? 'Unknown User',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    user['email'] ?? '',
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user['isPremium'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      SizedBox(width: 8.w),
                      if (user['isAdmin'] == true)
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
