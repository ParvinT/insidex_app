// lib/features/library/category_sessions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../player/audio_player_screen.dart';
import '../../core/responsive/breakpoints.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/app_localizations.dart';

class CategorySessionsScreen extends StatefulWidget {
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
  State<CategorySessionsScreen> createState() => _CategorySessionsScreenState();
}

class _CategorySessionsScreenState extends State<CategorySessionsScreen> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    final bool isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final bool isDesktop = width >= Breakpoints.desktopMin;

    final double leadingWidth = isTablet ? 64 : 56;
    final double leadingPad = isTablet ? 12 : 8;

    final double toolbarH = isDesktop ? 64.0 : (isTablet ? 60.0 : 56.0);

    final double logoW = isDesktop ? 120.0 : (isTablet ? 104.0 : 92.0);
    final double logoH = toolbarH * 0.70;
    final double dividerH = (logoH * 0.9).clamp(18.0, 36.0);

    // Sadece bu ekranda font şişmesini yumuşat
    final double _ts = mq.textScaleFactor.clamp(1.0, 1.2);

    final String rightTitleText = widget.showAllSessions
        ? AppLocalizations.of(context).allSubliminals
        : widget.categoryTitle;

    return MediaQuery(
      data: mq.copyWith(textScaleFactor: _ts),
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          toolbarHeight: toolbarH,
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          leadingWidth: leadingWidth,
          titleSpacing: isTablet ? 8 : 4,

          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: (24.sp).clamp(20.0, 28.0),
            ),
            padding: EdgeInsets.only(left: leadingPad),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.pop(context),
          ),

          // Sol: logo | Orta: ayraç | Sağ: başlık (All Subliminals) veya emoji+kategori
          title: LayoutBuilder(
            builder: (context, c) {
              return Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // SOL: Logo
                  SizedBox(
                    width: logoW,
                    height: logoH,
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: logoW,
                      height: logoH,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      colorFilter: ColorFilter.mode(
                        AppColors.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  // ORTA: Ayraç
                  Expanded(
                    child: Center(
                      child: Container(
                        height: dividerH,
                        width: 1.5,
                        color: AppColors.textPrimary.withOpacity(0.2),
                      ),
                    ),
                  ),

                  // SAĞ: Başlık varyantı
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: widget.showAllSessions
                          ? Text(
                              rightTitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: (15.sp).clamp(14.0, 20.0),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.categoryEmoji,
                                  style: TextStyle(
                                    fontSize: (24.sp).clamp(18.0, 28.0),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    rightTitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: (18.sp).clamp(16.0, 22.0),
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ⬇️ Aşağısı senin orijinal akışın
        body: StreamBuilder<QuerySnapshot>(
          stream: widget.showAllSessions
              ? FirebaseFirestore.instance
                  .collection('sessions')
                  .orderBy('createdAt', descending: true)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('sessions')
                  .where('category', isEqualTo: widget.categoryTitle)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              );
            }

            if (snapshot.hasError) {
              print('Error: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      AppLocalizations.of(context).errorLoadingSessions,
                      style: GoogleFonts.inter(
                          fontSize: 16.sp, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${snapshot.error}',
                      style:
                          GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
                    ),
                  ],
                ),
              );
            }

            final sessions = snapshot.data?.docs ?? [];

            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_off,
                        size: 64.sp, color: AppColors.greyLight),
                    SizedBox(height: 16.h),
                    Text(
                      AppLocalizations.of(context).noSessionsAvailable,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      AppLocalizations.of(context).checkBackLater,
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(20.w),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final sessionDoc = sessions[index];
                final session = sessionDoc.data() as Map<String, dynamic>;
                final sessionId = sessionDoc.id;

                return _buildSessionCard(
                  sessionId: sessionId,
                  sessionData: session,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required String sessionId,
    required Map<String, dynamic> sessionData,
  }) {
    return GestureDetector(
      onTap: () {
        // Prepare complete session data for audio player
        final completeSessionData = {
          'id': sessionId,
          ...sessionData,
        };

        // Navigate to Audio Player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(
              sessionData: completeSessionData,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image Section
            Container(
              height: 180.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.textPrimary.withOpacity(0.8),
                    AppColors.textPrimary.withOpacity(0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background Image or Emoji - ESKİSİ GİBİ
                  if (sessionData['backgroundImage'] != null &&
                      sessionData['backgroundImage'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: sessionData['backgroundImage'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.textPrimary.withOpacity(0.8),
                                AppColors.textPrimary.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.textPrimary.withOpacity(0.8),
                                AppColors.textPrimary.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // Resim yoksa sadece gradient göster, emoji yok
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.textPrimary.withOpacity(0.8),
                            AppColors.textPrimary.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),

                  // Play Button Overlay
                  Center(
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 32.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section - SADECE BAŞLIK VE KATEGORİ
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      sessionData['title'] ??
                          AppLocalizations.of(context).untitledSession,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Category Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      sessionData['category'] ??
                          AppLocalizations.of(context).general,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
