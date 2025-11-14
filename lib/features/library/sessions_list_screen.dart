// lib/features/library/session_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/session_card.dart';
import '../player/audio_player_screen.dart';
import '../../core/responsive/breakpoints.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_filter_service.dart';
import '../../core/constants/app_icons.dart';

class SessionsListScreen extends StatefulWidget {
  final String categoryTitle;
  final String? categoryIconName;
  final String? categoryId;
  final bool isShowingAllSessions;

  const SessionsListScreen({
    super.key,
    required this.categoryTitle,
    this.categoryIconName,
    this.categoryId,
    this.isShowingAllSessions = false,
  });

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    final bool isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final bool isDesktop = width >= Breakpoints.desktopMin;

    final double leadingWidth = isTablet ? 64 : 56;
    final double leadingPad = isTablet ? 12 : 8;

    final double toolbarH = isDesktop ? 64.0 : (isTablet ? 60.0 : 40.0);

    final double logoW = isDesktop ? 100.0 : (isTablet ? 88.0 : 68.0);
    final double logoH = toolbarH * 0.70;
    final double dividerH = (logoH * 0.9).clamp(18.0, 36.0);

    // Sadece bu ekranda font şişmesini yumuşat
    final double _ts = mq.textScaleFactor.clamp(1.0, 1.2);

    final String rightTitleText = widget.isShowingAllSessions
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
          titleSpacing: isTablet ? 4 : 0,

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

          
          title: LayoutBuilder(
            builder: (context, c) {
              return Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // SOL: Logo
                  Expanded(
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: logoW,
                        height: logoH,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          AppColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),

                  // ORTA: Ayraç
                  Container(
                    height: dividerH,
                    width: 1.5,
                    color: AppColors.textPrimary.withOpacity(0.2),
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                  ),

                  // SAĞ: Başlık varyantı
                  Expanded(
                    child: Center(
                      child: widget.isShowingAllSessions
                          ? Text(
                              rightTitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: (15.sp).clamp(14.0, 20.0),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon animation
                                if (widget.categoryIconName != null)
                                  SizedBox(
                                    width: 32.w,
                                    height: 32.w,
                                    child: Transform.scale(
                                      scale: 1.2,
                                      child: Lottie.asset(
                                        AppIcons.getAnimationPath(
                                          AppIcons.getIconByName(widget
                                                      .categoryIconName!)?[
                                                  'path'] ??
                                              'meditation.json',
                                        ),
                                        fit: BoxFit.contain,
                                        repeat: true,
                                      ),
                                    ),
                                  ),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    rightTitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
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
            stream: widget.isShowingAllSessions
                ? FirebaseFirestore.instance
                    .collection('sessions')
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('sessions')
                    .where('categoryId', isEqualTo: widget.categoryId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.textPrimary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context).errorLoadingSessions,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              final allDocs = snapshot.data?.docs ?? [];

              // ✅ LANGUAGE FILTER
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: SessionFilterService.filterSessionsByLanguage(allDocs),
                builder: (context, filteredSnapshot) {
                  if (filteredSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.textPrimary),
                    );
                  }

                  final sessions = filteredSnapshot.data ?? [];

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
                                fontSize: 14.sp,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(20.w),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final sessionId = session['id'];

                      return _buildSessionCard(
                        sessionId: sessionId,
                        sessionData: session,
                      );
                    },
                  );
                },
              );
            }),
      ),
    );
  }

  Widget _buildSessionCard({
    required String sessionId,
    required Map<String, dynamic> sessionData,
  }) {
    // Yeni SessionCard widget'ını kullan
    return SessionCard(
      session: sessionData,
      onTap: () {
        // Prepare complete session data with ID
        final completeSessionData = Map<String, dynamic>.from(sessionData);
        completeSessionData['id'] = sessionId;

        // Navigate to audio player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              sessionData: completeSessionData,
            ),
          ),
        );
      },
    );
  }
}
