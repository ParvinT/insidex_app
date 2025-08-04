import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Kategori listesi
  final List<Map<String, dynamic>> _categories = [
    {'title': 'All', 'emoji': '✨', 'count': 150}, // Tüm sessionlar
    {'title': 'Sleep', 'emoji': '😴', 'count': 25},
    {'title': 'Confidence', 'emoji': '💪', 'count': 18},
    {'title': 'Anxiety Relief', 'emoji': '🧘', 'count': 22},
    {'title': 'Energy', 'emoji': '⚡', 'count': 15},
    {'title': 'Focus', 'emoji': '🎯', 'count': 20},
    {'title': 'Health', 'emoji': '❤️', 'count': 30},
    {'title': 'Success', 'emoji': '🏆', 'count': 16},
    {'title': 'Love', 'emoji': '💕', 'count': 12},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Subliminals',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a Category',
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Select from our curated collection',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Categories Grid
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 1.2,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(_categories[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final bool isAllCategory = category['title'] == 'All';

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to category detail
        print('Tapped on ${category['title']}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: isAllCategory
              ? AppColors.primaryGoldLight.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isAllCategory ? AppColors.primaryGold : AppColors.greyBorder,
            width: isAllCategory ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isAllCategory ? 0.08 : 0.05),
              blurRadius: isAllCategory ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(
              category['emoji'],
              style: TextStyle(fontSize: isAllCategory ? 40.sp : 36.sp),
            ),
            SizedBox(height: 12.h),

            // Title
            Text(
              category['title'],
              style: GoogleFonts.inter(
                fontSize: isAllCategory ? 18.sp : 16.sp,
                fontWeight: isAllCategory ? FontWeight.w700 : FontWeight.w600,
                color: isAllCategory
                    ? AppColors.primaryGold
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),

            // Count
            Text(
              '${category['count']} sessions',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: isAllCategory
                    ? AppColors.primaryGold.withOpacity(0.8)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
