import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionInfoModal {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> session,
    required String currentTrack,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            ),
            child: _SessionInfoContent(
              session: session,
              currentTrack: currentTrack,
              animation: animation,
            ),
          ),
        );
      },
    );
  }
}

class _SessionInfoContent extends StatelessWidget {
  final Map<String, dynamic> session;
  final String currentTrack;
  final Animation<double> animation;

  const _SessionInfoContent({
    required this.session,
    required this.currentTrack,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    final modalWidth = isTablet ? screenWidth * 0.6 : screenWidth * 0.9;
    final maxModalWidth = 500.0;
    final modalHeight = screenHeight * 0.75;

    return Center(
      child: Container(
        width: modalWidth > maxModalWidth ? maxModalWidth : modalWidth,
        height: modalHeight,
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSessionTitle(),
                    if (session['description'] != null) _buildDescription(),
                    _buildNowPlayingCard(),
                    if (session['howToListen'] != null ||
                        session['listeningTips'] != null)
                      _buildListeningGuide(),
                    if (session['benefits'] != null &&
                        (session['benefits'] as List).isNotEmpty)
                      _buildBenefits(),
                    if (currentTrack == 'subliminal' &&
                        session['subliminal']?['affirmations'] != null)
                      _buildAffirmations(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Session Details',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.black,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTitle() {
    // Title'ı temizle
    String cleanTitle = (session['title'] ?? 'Untitled Session')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\*\*([^\*]*)\*\*'), '\$1')
        .replaceAll(RegExp(r'__([^_]*)__'), '\$1')
        .replaceAll(RegExp(r'\*([^\*]*)\*'), '\$1')
        .replaceAll(RegExp(r'_([^_]*)_'), '\$1')
        .replaceAll(RegExp(r'<u>([^<]*)</u>'), '\$1')
        .replaceAll(RegExp(r'<mark>([^<]*)</mark>'), '\$1')
        .trim();

    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 16.h),
      child: Text(
        cleanTitle,
        style: GoogleFonts.inter(
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    // Description'ı temizle - HTML/Markdown tag'lerini kaldır
    String cleanDescription = session['description'] ?? '';

    // Basit HTML tag temizleme
    cleanDescription = cleanDescription
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML tags
        .replaceAll(RegExp(r'\*\*([^\*]*)\*\*'), '\$1') // Bold markdown
        .replaceAll(RegExp(r'__([^_]*)__'), '\$1') // Bold markdown
        .replaceAll(RegExp(r'\*([^\*]*)\*'), '\$1') // Italic markdown
        .replaceAll(RegExp(r'_([^_]*)_'), '\$1') // Italic markdown
        .replaceAll(RegExp(r'<u>([^<]*)</u>'), '\$1') // Underline HTML
        .replaceAll(RegExp(r'<mark>([^<]*)</mark>'), '\$1') // Highlight HTML
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ABOUT THIS SESSION',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 1.2,
            decoration: TextDecoration.none, // Alt çizgi yok
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          cleanDescription,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: Colors.grey[800],
            height: 1.6,
            decoration: TextDecoration.none, // Alt çizgi yok
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildNowPlayingCard() {
    final trackData =
        currentTrack == 'intro' ? session['intro'] : session['subliminal'];

    // Track title ve description'ı temizle
    String cleanTrackTitle = (trackData?['title'] ??
            (currentTrack == 'intro' ? 'Introduction' : 'Subliminal'))
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\*\*([^\*]*)\*\*'), '\$1')
        .replaceAll(RegExp(r'__([^_]*)__'), '\$1')
        .replaceAll(RegExp(r'\*([^\*]*)\*'), '\$1')
        .replaceAll(RegExp(r'_([^_]*)_'), '\$1')
        .replaceAll(RegExp(r'<u>([^<]*)</u>'), '\$1')
        .replaceAll(RegExp(r'<mark>([^<]*)</mark>'), '\$1')
        .trim();

    String? cleanTrackDescription;
    if (trackData?['description'] != null) {
      cleanTrackDescription = trackData['description']
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\*\*([^\*]*)\*\*'), '\$1')
          .replaceAll(RegExp(r'__([^_]*)__'), '\$1')
          .replaceAll(RegExp(r'\*([^\*]*)\*'), '\$1')
          .replaceAll(RegExp(r'_([^_]*)_'), '\$1')
          .replaceAll(RegExp(r'<u>([^<]*)</u>'), '\$1')
          .replaceAll(RegExp(r'<mark>([^<]*)</mark>'), '\$1')
          .trim();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOW PLAYING',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  cleanTrackTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (cleanTrackDescription != null)
                  Text(
                    cleanTrackDescription,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningGuide() {
    // Default listening tips if not provided
    final tips = session['listeningTips'] ??
        [
          '2-3 times daily',
          'Safe during rest or sleep',
          'Stay hydrated',
          'Not for use while driving'
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW TO LISTEN',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: (tips as List)
                .map((tip) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 2.h),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 16.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              tip.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildBenefits() {
    final benefits = session['benefits'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BENEFITS',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12.h),
        ...benefits
            .map((benefit) => Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 6.h),
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          benefit.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildAffirmations() {
    final affirmations = session['subliminal']['affirmations'] as List?;
    if (affirmations == null || affirmations.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.black,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'HIDDEN AFFIRMATIONS',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These affirmations are embedded in the subliminal track:',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12.h),
              ...affirmations
                  .take(5)
                  .map((affirmation) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                affirmation.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.grey[800],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              if (affirmations.length > 5)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    '+ ${affirmations.length - 5} more affirmations',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
