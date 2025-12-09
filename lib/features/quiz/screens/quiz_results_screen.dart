// lib/features/quiz/screens/quiz_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../models/disease_model.dart';
import '../../../models/disease_cause_model.dart';
import '../../../services/disease/disease_cause_service.dart';
import '../../../services/language_helper_service.dart';
import '../../../services/session_localization_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../player/audio_player_screen.dart';

class QuizResultsScreen extends StatefulWidget {
  final List<DiseaseModel> selectedDiseases;

  const QuizResultsScreen({
    super.key,
    required this.selectedDiseases,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final DiseaseCauseService _causeService = DiseaseCauseService();

  Map<String, DiseaseCauseModel> _causes = {};
  final Map<String, bool> _expandedCauses = {};
  bool _isLoading = true;
  bool _isExpanded = false;

  // Show first 4-5 items by default
  static const int _initialDisplayCount = 4;

  @override
  void initState() {
    super.initState();
    _loadCauses();
  }

  Future<void> _loadCauses() async {
    setState(() => _isLoading = true);

    try {
      final diseaseIds = widget.selectedDiseases.map((d) => d.id).toList();
      final causes =
          await _causeService.getDiseaseCausesForDiseases(diseaseIds);

      if (mounted) {
        setState(() {
          _causes = causes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading causes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DiseaseModel> get _displayedDiseases {
    if (_isExpanded || widget.selectedDiseases.length <= _initialDisplayCount) {
      return widget.selectedDiseases;
    }
    return widget.selectedDiseases.take(_initialDisplayCount).toList();
  }

  int get _hiddenCount {
    return widget.selectedDiseases.length - _initialDisplayCount;
  }

  bool get _canExpand {
    return widget.selectedDiseases.length > _initialDisplayCount;
  }

  bool _isCauseExpanded(String diseaseId) {
    return _expandedCauses[diseaseId] ?? false;
  }

  void _toggleCauseExpansion(String diseaseId) {
    setState(() {
      _expandedCauses[diseaseId] = !(_expandedCauses[diseaseId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).yourResults,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(isTablet),

                  SizedBox(height: 24.h),

                  // Results list
                  ..._displayedDiseases.asMap().entries.map((entry) {
                    final index = entry.key;
                    final disease = entry.value;
                    return _buildDiseaseResultCard(
                        disease, index + 1, isTablet);
                  }),

                  // See More / See Less button
                  if (_canExpand) ...[
                    SizedBox(height: 16.h),
                    _buildExpandToggleButton(isTablet),
                  ],

                  SizedBox(height: 24.h),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.textPrimary.withValues(alpha: 0.1),
            AppColors.textPrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 102.w : 96.w,
            height: isTablet ? 102.w : 96.w,
            padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
            child: Lottie.asset(
              AppIcons.getUiAnimationPath('heartbeat.json'),
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).selectedDiseases,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${widget.selectedDiseases.length} ${widget.selectedDiseases.length == 1 ? AppLocalizations.of(context).disease : AppLocalizations.of(context).diseases}',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 20.sp : 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseResultCard(
      DiseaseModel disease, int number, bool isTablet) {
    final cause = _causes[disease.id];

    return FutureBuilder<String>(
      future: LanguageHelperService.getCurrentLanguage(),
      builder: (context, snapshot) {
        final currentLanguage = snapshot.data ?? 'en';
        final diseaseName = disease.getLocalizedName(currentLanguage);

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.greyBorder.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disease name with number
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number badge
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Container(
                        width: (isTablet ? 26.w : 22.w).clamp(20.0, 28.0),
                        height: (isTablet ? 26.w : 22.w).clamp(20.0, 28.0),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$number',
                          style: GoogleFonts.inter(
                            fontSize:
                                (isTablet ? 11.sp : 10.sp).clamp(9.0, 12.0),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Disease name
                          Text(
                            diseaseName,
                            style: GoogleFonts.inter(
                              fontSize:
                                  (isTablet ? 13.sp : 12.sp).clamp(11.0, 14.0),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          // Gender badge
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: disease.gender == 'male'
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.pink.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                disease.gender == 'male'
                                    ? AppLocalizations.of(context)
                                        .male
                                        .toUpperCase()
                                    : AppLocalizations.of(context)
                                        .female
                                        .toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize:
                                      (isTablet ? 8.sp : 7.sp).clamp(6.0, 9.0),
                                  fontWeight: FontWeight.w700,
                                  color: disease.gender == 'male'
                                      ? Colors.blue[700]
                                      : Colors.pink[700],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (cause != null) ...[
                SizedBox(height: 16.h),

                // Divider
                Divider(color: AppColors.greyBorder.withValues(alpha: 0.3)),

                SizedBox(height: 16.h),

                // Why is this caused?
                Text(
                  AppLocalizations.of(context).whyIsThisCaused,
                  style: GoogleFonts.inter(
                    fontSize: (isTablet ? 15.sp : 14.sp).clamp(13.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Cause content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cause.getLocalizedContent(currentLanguage),
                      style: GoogleFonts.inter(
                        fontSize: (isTablet ? 13.sp : 12.sp).clamp(11.0, 14.0),
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: _isCauseExpanded(disease.id) ? null : 3,
                      overflow: _isCauseExpanded(disease.id)
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),

                    // See more/less button
                    if (cause.getLocalizedContent(currentLanguage).length >
                        150) ...[
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () => _toggleCauseExpansion(disease.id),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isCauseExpanded(disease.id)
                                  ? AppLocalizations.of(context).seeLess
                                  : AppLocalizations.of(context).seeMore,
                              style: GoogleFonts.inter(
                                fontSize: (isTablet ? 12.sp : 11.sp)
                                    .clamp(10.0, 13.0),
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBackground,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              _isCauseExpanded(disease.id)
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size:
                                  (isTablet ? 18.sp : 16.sp).clamp(14.0, 20.0),
                              color: AppColors.darkBackground,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 16.h),

                // Recommended session
                GestureDetector(
                  onTap: () => _navigateToSession(cause.recommendedSessionId),
                  child: Container(
                    padding: EdgeInsets.all(
                        (isTablet ? 14.w : 12.w).clamp(10.0, 16.0)),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              color: AppColors.textPrimary,
                              size: isTablet ? 24.sp : 22.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: FutureBuilder<String>(
                                future: _getSessionTitle(
                                    cause.recommendedSessionId,
                                    currentLanguage),
                                builder: (context, snapshot) {
                                  final sessionTitle = snapshot.data ??
                                      '${AppLocalizations.of(context).session} №${cause.sessionNumber}';

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)
                                            .recommendedSession,
                                        style: GoogleFonts.inter(
                                          fontSize: (isTablet ? 11.sp : 10.sp)
                                              .clamp(9.0, 12.0),
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        sessionTitle,
                                        style: GoogleFonts.inter(
                                          fontSize: (isTablet ? 14.sp : 13.sp)
                                              .clamp(12.0, 15.0),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    (isTablet ? 14.w : 12.w).clamp(10.0, 16.0),
                                vertical:
                                    (isTablet ? 9.h : 8.h).clamp(7.0, 11.0),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                AppLocalizations.of(context).listen,
                                style: GoogleFonts.inter(
                                  fontSize: (isTablet ? 12.sp : 11.sp)
                                      .clamp(10.0, 13.0),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(
                      (isTablet ? 14.w : 12.w).clamp(10.0, 16.0)),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: (isTablet ? 20.sp : 18.sp).clamp(16.0, 22.0),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .noHealingSessionAvailable,
                          style: GoogleFonts.inter(
                            fontSize:
                                (isTablet ? 12.sp : 11.sp).clamp(10.0, 13.0),
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandToggleButton(bool isTablet) {
    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20.w : 18.w,
          vertical: isTablet ? 14.h : 12.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.greyBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded
                  ? AppLocalizations.of(context).seeLess
                  : AppLocalizations.of(context).seeXMore(_hiddenCount),
              style: GoogleFonts.inter(
                fontSize: (isTablet ? 14.sp : 13.sp).clamp(12.0, 15.0),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textPrimary,
              size: (isTablet ? 20.sp : 18.sp).clamp(16.0, 22.0),
            ),
          ],
        ),
      ),
    );
  }

  /// Get localized session title for display
  Future<String> _getSessionTitle(String sessionId, String locale) async {
    final sessionText = AppLocalizations.of(context).session;
    try {
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) sessionText;

      final sessionData = {
        'id': sessionId,
        ...sessionDoc.data()!,
      };

      // Get localized content
      final localizedContent =
          SessionLocalizationService.getLocalizedContent(sessionData, locale);

      if (localizedContent.title.isNotEmpty) {
        return localizedContent.title;
      }

      return localizedContent.title.isNotEmpty
          ? localizedContent.title
          : sessionText;
    } catch (e) {
      debugPrint('❌ Error getting session title: $e');
      return sessionText;
    }
  }

  Future<void> _navigateToSession(String sessionId) async {
    debugPrint('🎵 [QuizResults] Opening session: $sessionId');

    final navigator = Navigator.of(context);

    try {
      // Fetch session by ID
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found');
      }

      final sessionData = sessionDoc.data();
      if (sessionData == null) {
        throw Exception('Session data is null');
      }

      if (!mounted) return;

      // Get user's current language
      final currentLanguage = await LanguageHelperService.getCurrentLanguage();

      // Prepare session data with localized content
      final rawSessionData = {
        'id': sessionId,
        ...sessionData,
      };

      final completeSessionData =
          SessionLocalizationService.prepareSessionForNavigation(
        rawSessionData,
        currentLanguage,
      );

      debugPrint(
          '✅ [QuizResults] Session loaded: ${completeSessionData['_displayTitle']}');

      if (!mounted) return;

      // Navigate to audio player
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(sessionData: completeSessionData),
        ),
      );
    } catch (e) {
      debugPrint('❌ [QuizResults] Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotOpenSession),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
