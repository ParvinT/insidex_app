// lib/features/quiz/screens/disease_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../models/disease_model.dart';
import '../../../models/disease_cause_model.dart';
import '../../../services/language_helper_service.dart';
import '../services/quiz_service.dart';
import '../../../services/session_localization_service.dart';
import '../widgets/disease_cause_card.dart';
import '../widgets/session_recommendation_card.dart';
import '../../player/audio_player_screen.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final DiseaseModel disease;

  const DiseaseDetailScreen({
    super.key,
    required this.disease,
  });

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  final QuizService _quizService = QuizService();

  bool _isLoading = true;
  DiseaseCauseModel? _cause;
  Map<String, dynamic>? _sessionData;
  bool _hasRecommendation = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    setState(() => _isLoading = true);

    try {
      final recommendation = await _quizService.getDiseaseRecommendation(
        widget.disease.id,
      );

      _cause = recommendation['cause'];
      _hasRecommendation = recommendation['hasRecommendation'] ?? false;

      // Fetch session data if we have a sessionId
      if (_hasRecommendation && recommendation['sessionId'] != null) {
        final sessionDoc = await FirebaseFirestore.instance
            .collection('sessions')
            .doc(recommendation['sessionId'])
            .get();

        if (sessionDoc.exists) {
          // Get user's current language
          final currentLanguage =
              await LanguageHelperService.getCurrentLanguage();

          // Prepare session data with localized content
          final rawSessionData = {
            'id': sessionDoc.id,
            ...sessionDoc.data()!,
          };

          _sessionData = SessionLocalizationService.prepareSessionForNavigation(
            rawSessionData,
            currentLanguage,
          );

          debugPrint(
              '✅ [DiseaseDetail] Session loaded: ${_sessionData!['_displayTitle']}');
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading recommendation: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToSession() async {
    if (_sessionData == null) return;

    // For now, just navigate to player
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioPlayerScreen(
          sessionData: _sessionData!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    final double horizontalPadding =
        isDesktop ? 40.w : (isTablet ? 28.w : 24.w);
    final double titleSize =
        isTablet ? 26.sp.clamp(24.0, 28.0) : 22.sp.clamp(20.0, 24.0);

    return FutureBuilder<String>(
      future: LanguageHelperService.getCurrentLanguage(),
      builder: (context, snapshot) {
        final currentLanguage = snapshot.data ?? 'en';
        final diseaseName = widget.disease.getLocalizedName(currentLanguage);

        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? _buildLoadingState()
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),

                      // Disease Name
                      Center(
                        child: Text(
                          diseaseName,
                          style: GoogleFonts.inter(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Disease Cause Card
                      if (_cause != null) ...[
                        DiseaseCauseCard(
                          causeContent:
                              _cause!.getLocalizedContent(currentLanguage),
                        ),
                        SizedBox(height: 24.h),
                      ],

                      // Session Recommendation
                      if (_hasRecommendation && _sessionData != null) ...[
                        _buildSessionRecommendation(currentLanguage),
                        SizedBox(height: 32.h),
                      ],

                      // No Recommendation Message
                      if (!_hasRecommendation) ...[
                        _buildNoRecommendationCard(isTablet),
                        SizedBox(height: 32.h),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSessionRecommendation(String currentLanguage) {
    // Session title is already prepared in _sessionData['_localizedTitle']
    final sessionTitle = _sessionData!['_localizedTitle'] ?? 'Untitled Session';

    return SessionRecommendationCard(
      sessionNumber: _cause?.sessionNumber,
      sessionTitle: sessionTitle,
      onTap: _navigateToSession,
    );
  }

  Widget _buildNoRecommendationCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: isTablet ? 28.sp : 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'No healing session available for this condition yet. Our team is working on it!',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14.sp : 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/loading.json',
            width: 120.w,
            height: 120.w,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading recommendation...',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
