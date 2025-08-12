import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'session_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Emoji'leri önceden yüklemek için
  bool _isLoading = true;

  // Kategori listesi
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'All',
      'emoji': '✨',
      'count': 150,
      'sessions': [
        {
          'title': 'Deep Sleep Healing',
          'category': 'Sleep',
          'emoji': '😴',
          'duration': '2 hours 2 minutes',
          'backgroundGradient': [Color(0xFF1e3c72), Color(0xFF2a5298)],
        },
        {
          'title': 'Confidence Boost',
          'category': 'Confidence',
          'emoji': '💪',
          'duration': '1 hour 30 minutes',
          'backgroundGradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
        },
      ]
    },
    {
      'title': 'Sleep',
      'emoji': '😴',
      'count': 25,
      'sessions': [
        {
          'title': 'Deep Sleep Healing',
          'category': 'Sleep',
          'emoji': '😴',
          'duration': '2 hours 2 minutes',
          'introDuration': '2 minutes',
          'subliminalDuration': '2 hours',
          'description':
              'This powerful sleep session combines gentle healing frequencies with subliminal affirmations designed to promote deep, restorative sleep.',
          'benefits': [
            'Promotes deeper sleep cycles',
            'Reduces nighttime anxiety',
            'Enhances natural healing during sleep',
            'Improves morning energy levels'
          ],
          'subliminals': [
            'I sleep deeply and peacefully',
            'My body heals while I rest',
            'I wake up refreshed and energized',
            'Sleep comes naturally to me'
          ],
          'backgroundGradient': [Color(0xFF1e3c72), Color(0xFF2a5298)],
          'playCount': 1247,
          'rating': 4.8,
          'tags': ['Sleep', 'Healing', 'Anxiety Relief', 'Insomnia'],
        },
        {
          'title': 'Lucid Dream Activation',
          'category': 'Sleep',
          'emoji': '🌙',
          'duration': '1 hour 45 minutes',
          'backgroundGradient': [Color(0xFF667eea), Color(0xFF764ba2)],
        },
      ]
    },
    {
      'title': 'Confidence',
      'emoji': '💪',
      'count': 18,
      'sessions': [
        {
          'title': 'Unshakeable Confidence',
          'category': 'Confidence',
          'emoji': '💪',
          'duration': '1 hour 30 minutes',
          'backgroundGradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
        }
      ]
    },
    {'title': 'Anxiety Relief', 'emoji': '🧘', 'count': 22},
    {'title': 'Energy', 'emoji': '⚡', 'count': 15},
    {'title': 'Focus', 'emoji': '🎯', 'count': 20},
    {'title': 'Health', 'emoji': '❤️', 'count': 30},
    {'title': 'Success', 'emoji': '🏆', 'count': 16},
    {'title': 'Love', 'emoji': '💕', 'count': 12},
  ];

  @override
  void initState() {
    super.initState();
    _preloadEmojis();
  }

  // Emoji'leri önceden yükle
  Future<void> _preloadEmojis() async {
    // Kısa bir gecikme ile emoji'lerin yüklenmesini sağla
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
    final bool hasSessions = category.containsKey('sessions');

    return GestureDetector(
      onTap: () {
        if (hasSessions) {
          // Show sessions in this category
          _showSessionsBottomSheet(category);
        } else {
          // Show coming soon or navigate to empty category
          _showComingSoonDialog(category['title']);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isAllCategory
              ? AppColors.textPrimary.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isAllCategory ? AppColors.textPrimary : AppColors.greyBorder,
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
            // Emoji Container - Boyut sabitleme ve fallback ile
            Container(
              height: isAllCategory ? 44.sp : 40.sp,
              width: isAllCategory ? 44.sp : 40.sp,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? Container(
                        width: isAllCategory ? 40.sp : 36.sp,
                        height: isAllCategory ? 40.sp : 36.sp,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      )
                    : Text(
                        category['emoji'],
                        key: ValueKey(category['emoji']),
                        style: TextStyle(
                          fontSize: isAllCategory ? 40.sp : 36.sp,
                          fontFamily: 'NotoColorEmoji', // Emoji font family
                        ),
                      ),
              ),
            ),
            SizedBox(height: 12.h),

            // Title
            Text(
              category['title'],
              style: GoogleFonts.inter(
                fontSize: isAllCategory ? 18.sp : 16.sp,
                fontWeight: isAllCategory ? FontWeight.w700 : FontWeight.w600,
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
                    ? AppColors.textPrimary.withOpacity(0.7)
                    : AppColors.textSecondary,
              ),
            ),

            // Coming soon indicator for categories without sessions
            if (!hasSessions && category['title'] != 'All') ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Coming Soon',
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSessionsBottomSheet(Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.greyBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    // Emoji için sabit boyutlu container
                    Container(
                      width: 28.sp,
                      height: 28.sp,
                      alignment: Alignment.center,
                      child: Text(
                        category['emoji'],
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontFamily: 'NotoColorEmoji',
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${category['title']} Sessions',
                            style: GoogleFonts.inter(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${category['count']} available sessions',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sessions List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: (category['sessions'] as List).length,
                  itemBuilder: (context, index) {
                    final session = (category['sessions'] as List)[index];
                    return _buildSessionItem(session);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
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
            gradient: LinearGradient(
              colors: session['backgroundGradient'] != null
                  ? (session['backgroundGradient'] as List).map((color) {
                      if (color is Color) return color;
                      return const Color(0xFF1e3c72); // Default color
                    }).toList()
                  : [
                      AppColors.greyLight,
                      AppColors.greyMedium,
                    ],
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Container(
              width: 24.sp,
              height: 24.sp,
              alignment: Alignment.center,
              child: Text(
                session['emoji'] ?? '🎵',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontFamily: 'NotoColorEmoji',
                ),
              ),
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
        subtitle: Text(
          session['duration'] ?? 'Duration not specified',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 20.sp,
        ),
        onTap: () {
          // Close bottom sheet
          Navigator.pop(context);

          // Ensure session data has all required fields
          final completeSessionData = {
            ...session,
            'backgroundGradient': session['backgroundGradient'] ??
                [const Color(0xFF1e3c72), const Color(0xFF2a5298)],
          };

          // Navigate to session detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionDetailScreen(
                sessionData: completeSessionData,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComingSoonDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Coming Soon',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '$categoryName sessions are being prepared. Stay tuned for updates!',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
