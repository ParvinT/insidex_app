// lib/features/library/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'session_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

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
                    'Select a category to explore sessions',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Categories Grid - Firebase'den çekiyoruz
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('categories')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGold,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48.sp,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Error loading categories',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64.sp,
                            color: AppColors.greyMedium,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No categories available',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Please add categories from admin panel',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Firebase'den gelen kategoriler + All kategorisi
                  final categoriesFromFirebase = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'title': data['title'] ?? 'Unnamed',
                      'emoji': data['emoji'] ?? '📁',
                      'count': data['sessionCount'] ?? 0,
                      'sessions': data['sessions'] ?? [],
                    };
                  }).toList();

                  // "All" kategorisini başa ekle
                  final allCategories = [
                    {
                      'id': 'all',
                      'title': 'All',
                      'emoji': '✨',
                      'count': _calculateTotalSessions(categoriesFromFirebase),
                      'sessions': [],
                    },
                    ...categoriesFromFirebase,
                  ];

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: allCategories.length,
                    itemBuilder: (context, index) {
                      final category = allCategories[index];
                      final isAllCategory = category['id'] == 'all';

                      return GestureDetector(
                        onTap: () => _openCategoryDetail(context, category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isAllCategory
                                  ? AppColors.primaryGold
                                  : AppColors.greyBorder,
                              width: isAllCategory ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isAllCategory
                                    ? AppColors.primaryGold.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.03),
                                blurRadius: isAllCategory ? 12 : 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Emoji
                              Container(
                                height: isAllCategory ? 44.sp : 40.sp,
                                width: isAllCategory ? 44.sp : 40.sp,
                                alignment: Alignment.center,
                                child: Text(
                                  category['emoji'],
                                  style: TextStyle(
                                    fontSize: isAllCategory ? 40.sp : 36.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),

                              // Title
                              Text(
                                category['title'],
                                style: GoogleFonts.inter(
                                  fontSize: isAllCategory ? 18.sp : 16.sp,
                                  fontWeight: isAllCategory
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: AppColors.textPrimary,
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
                                      ? AppColors.primaryGold
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toplam session sayısını hesapla
  int _calculateTotalSessions(List<Map<String, dynamic>> categories) {
    int total = 0;
    for (var category in categories) {
      total += (category['count'] as int);
    }
    return total;
  }

  // Kategori detay sayfasına git
  void _openCategoryDetail(
      BuildContext context, Map<String, dynamic> category) {
    if (category['id'] == 'all') {
      // All kategorisi için tüm sessionları göster
      _navigateToAllSessions(context);
    } else {
      // Spesifik kategori için
      _navigateToCategorySessions(context, category);
    }
  }

  void _navigateToAllSessions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySessionsScreen(
          categoryTitle: 'All Sessions',
          categoryEmoji: '✨',
          showAllSessions: true,
        ),
      ),
    );
  }

  void _navigateToCategorySessions(
      BuildContext context, Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySessionsScreen(
          categoryTitle: category['title'],
          categoryEmoji: category['emoji'],
          categoryId: category['id'],
        ),
      ),
    );
  }
}

// Kategori içindeki sessionları gösteren sayfa
class CategorySessionsScreen extends StatelessWidget {
  final String categoryTitle;
  final String categoryEmoji;
  final String? categoryId;
  final bool showAllSessions;

  const CategorySessionsScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryEmoji,
    this.categoryId,
    this.showAllSessions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120.h,
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 50.w, bottom: 16.h),
                  title: Row(
                    children: [
                      Text(
                        categoryEmoji,
                        style: TextStyle(fontSize: 24.sp),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        categoryTitle,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: StreamBuilder<QuerySnapshot>(
            stream: showAllSessions
                ? FirebaseFirestore.instance
                    .collection('sessions')
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('sessions')
                    .where('category', isEqualTo: categoryTitle)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              // Test için örnek session'lar ekle
              final List<Map<String, dynamic>> testSessions = [
                {
                  'id': 'test-1',
                  'title': 'Deep Sleep Healing',
                  'category': 'Sleep',
                  'emoji': '😴',
                  'duration': '2 hours 2 minutes',
                  'introDuration': '2 minutes',
                  'subliminalDuration': '2 hours',
                  'description':
                      'This powerful sleep session combines gentle healing frequencies with subliminal affirmations designed to promote deep, restorative sleep.',
                  'backgroundGradient': [Color(0xFF1e3c72), Color(0xFF2a5298)],
                  'benefits': [
                    'Fall asleep faster',
                    'Experience deeper sleep cycles',
                    'Wake up feeling refreshed',
                    'Reduce anxiety and stress',
                    'Heal your body during sleep'
                  ],
                  'affirmations': [
                    'I fall asleep easily and naturally',
                    'My body heals and regenerates during sleep',
                    'I wake up feeling refreshed and energized',
                    'Sleep comes to me effortlessly',
                    'My mind is calm and peaceful'
                  ],
                },
                {
                  'id': 'test-2',
                  'title': 'Confidence Boost',
                  'category': 'Confidence',
                  'emoji': '💪',
                  'duration': '1 hour 30 minutes',
                  'introDuration': '3 minutes',
                  'subliminalDuration': '1 hour 27 minutes',
                  'description':
                      'Build unshakeable confidence and self-esteem with this powerful subliminal session.',
                  'backgroundGradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
                  'benefits': [
                    'Increase self-confidence',
                    'Overcome self-doubt',
                    'Develop strong self-esteem',
                    'Feel comfortable in social situations',
                    'Express yourself authentically'
                  ],
                  'affirmations': [
                    'I am confident and self-assured',
                    'I believe in myself and my abilities',
                    'I am worthy of success and happiness',
                    'I express myself with confidence',
                    'I am comfortable being myself'
                  ],
                },
              ];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGold,
                  ),
                );
              }

              // Firebase'den gelen sessionlar
              List<Map<String, dynamic>> firebaseSessions = [];
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                firebaseSessions = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    ...data,
                  };
                }).toList();
              }

              // Test session'ları ve Firebase session'larını birleştir
              final allSessions = [...testSessions];

              // Eğer kategori filtresi varsa uygula
              if (!showAllSessions) {
                allSessions.removeWhere(
                    (session) => session['category'] != categoryTitle);
              }

              // Firebase'den gelen session'ları ekle
              allSessions.addAll(firebaseSessions);

              if (allSessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off,
                        size: 64.sp,
                        color: AppColors.greyMedium,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No sessions available',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Check back later for new content',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(20.w),
                itemCount: allSessions.length,
                itemBuilder: (context, index) {
                  return _buildSessionItem(context, allSessions[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, Map<String, dynamic> session) {
    // Gradient renklerini belirle
    List<Color> gradientColors;
    if (session['backgroundGradient'] != null) {
      gradientColors = (session['backgroundGradient'] as List).map((color) {
        if (color is Color) return color;
        return AppColors.primaryGold;
      }).toList();
    } else {
      gradientColors = [
        AppColors.primaryGold.withOpacity(0.8),
        AppColors.primaryGold,
      ];
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              session['emoji'] ?? '🎵',
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
        ),
        title: Text(
          session['title'] ?? 'Untitled Session',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              session['category'] ?? 'Uncategorized',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppColors.primaryGold,
              ),
            ),
            Text(
              session['duration'] ?? _formatDuration(session),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.play_circle_filled,
          color: AppColors.primaryGold,
          size: 32.sp,
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/session-detail',
            arguments: session,
          );
        },
      ),
    );
  }

  String _formatDuration(Map<String, dynamic> session) {
    // Intro ve subliminal duration'ları topla
    int totalSeconds = 0;

    if (session['intro'] != null && session['intro']['duration'] != null) {
      totalSeconds += (session['intro']['duration'] as int);
    }

    if (session['subliminal'] != null &&
        session['subliminal']['duration'] != null) {
      totalSeconds += (session['subliminal']['duration'] as int);
    }

    if (totalSeconds == 0) {
      return 'Duration not set';
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes != 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    }
  }
}
