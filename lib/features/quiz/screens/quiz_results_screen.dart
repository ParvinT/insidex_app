// lib/features/quiz/screens/quiz_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
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
          'Your Results',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold))
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

                  // See More button
                  if (_canExpand && !_isExpanded) ...[
                    SizedBox(height: 16.h),
                    _buildSeeMoreButton(isTablet),
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
            AppColors.primaryGold.withOpacity(0.1),
            AppColors.primaryGold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              color: Colors.white,
              size: isTablet ? 28.sp : 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Conditions',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${widget.selectedDiseases.length} ${widget.selectedDiseases.length == 1 ? 'Condition' : 'Conditions'}',
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
              color: AppColors.greyBorder.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disease name with number
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: isTablet ? 32.w : 28.w,
                    height: isTablet ? 32.w : 28.w,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$number',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 14.sp : 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diseaseName,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 18.sp : 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: disease.gender == 'male'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.pink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            disease.gender == 'male' ? 'MALE' : 'FEMALE',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 10.sp : 9.sp,
                              fontWeight: FontWeight.w700,
                              color: disease.gender == 'male'
                                  ? Colors.blue[700]
                                  : Colors.pink[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (cause != null) ...[
                SizedBox(height: 16.h),

                // Divider
                Divider(color: AppColors.greyBorder.withOpacity(0.3)),

                SizedBox(height: 16.h),

                // Why is this caused?
                Text(
                  'Why is this caused?',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Cause content
                Text(
                  cause.getLocalizedContent(currentLanguage),
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 16.h),

                // Recommended session
                Container(
                  padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle,
                        color: AppColors.primaryGold,
                        size: isTablet ? 24.sp : 22.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _getSessionTitle(
                              cause.recommendedSessionId, currentLanguage),
                          builder: (context, snapshot) {
                            final sessionTitle = snapshot.data ??
                                'Session №${cause.sessionNumber}';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recommended Session',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12.sp : 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  sessionTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 15.sp : 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _navigateToSession(cause.recommendedSessionId),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16.w : 14.w,
                            vertical: isTablet ? 10.h : 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Listen',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 13.sp : 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: isTablet ? 20.sp : 18.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'No healing session available for this condition yet.',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 13.sp : 12.sp,
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

  Widget _buildSeeMoreButton(bool isTablet) {
    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = true);
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
            color: AppColors.greyBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'See $_hiddenCount More',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 15.sp : 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textPrimary,
              size: isTablet ? 22.sp : 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  /// Get localized session title for display
  Future<String> _getSessionTitle(String sessionId, String locale) async {
    try {
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) return 'Session';

      final sessionData = {
        'id': sessionId,
        ...sessionDoc.data()!,
      };

      // Get localized content
      final localizedContent =
          SessionLocalizationService.getLocalizedContent(sessionData, locale);

      // Build title with session number
      final sessionNumber = sessionData['sessionNumber'];
      if (sessionNumber != null && localizedContent.title.isNotEmpty) {
        return '№$sessionNumber • ${localizedContent.title}';
      }

      return localizedContent.title.isNotEmpty
          ? localizedContent.title
          : 'Session №$sessionNumber';
    } catch (e) {
      debugPrint('❌ Error getting session title: $e');
      return 'Session';
    }
  }

  Future<void> _navigateToSession(String sessionId) async {
    debugPrint('🎵 [QuizResults] Opening session: $sessionId');

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Loading session...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

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

      // Navigate to audio player
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(sessionData: completeSessionData),
        ),
      );
    } catch (e) {
      debugPrint('❌ [QuizResults] Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open session'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
