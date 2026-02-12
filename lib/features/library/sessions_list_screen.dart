// lib/features/library/session_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../../models/play_context.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../shared/widgets/session_card.dart';
import '../player/audio_player_screen.dart';
import '../../core/responsive/breakpoints.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_filter_service.dart';
import '../../core/constants/app_icons.dart';
import '../../shared/widgets/auto_marquee_text.dart';

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
  // All Sessions pagination
  List<Map<String, dynamic>> _allSessions = [];
  DocumentSnapshot? _lastAllDocument;
  bool _hasMoreAllSessions = true;
  bool _isLoadingAllSessions = false;
  int _allSessionsRecursiveCount = 0;

  // Category Sessions pagination
  List<Map<String, dynamic>> _categorySessions = [];
  DocumentSnapshot? _lastCategoryDocument;
  bool _hasMoreCategorySessions = true;
  bool _isLoadingCategorySessions = false;
  int _categorySessionsRecursiveCount = 0;

  // Gender filter
  String _selectedGenderFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.isShowingAllSessions) {
      _loadInitialAllSessions();
    } else {
      _loadInitialCategorySessions();
    }
  }

  @override
  void didUpdateWidget(SessionsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset pagination when widget updates (e.g. language change)
    debugPrint('🔄 [SessionsListScreen] Widget updated, resetting pagination');

    // Reset state
    setState(() {
      _allSessions = [];
      _lastAllDocument = null;
      _hasMoreAllSessions = true;

      _categorySessions = [];
      _lastCategoryDocument = null;
      _hasMoreCategorySessions = true;
    });

    // Reload sessions based on current mode
    if (widget.isShowingAllSessions) {
      _loadInitialAllSessions();
    } else {
      _loadInitialCategorySessions();
    }
  }

  // 🆕 ========== ALL SESSIONS PAGINATION ==========
  Future<void> _loadInitialAllSessions() async {
    setState(() {
      _allSessions = [];
      _lastAllDocument = null;
      _hasMoreAllSessions = true;
    });

    await _loadMoreAllSessions();
  }

  Future<void> _loadMoreAllSessions() async {
    if (_isLoadingAllSessions || !_hasMoreAllSessions) {
      debugPrint('⏸️ [All Sessions Pagination] Already loading or no more');
      return;
    }

    // 🆕 Prevent infinite loop
    if (_allSessionsRecursiveCount > 10) {
      debugPrint('⚠️ [All Sessions] Max recursive calls reached, stopping');
      setState(() {
        _hasMoreAllSessions = false;
        _isLoadingAllSessions = false;
      });
      _allSessionsRecursiveCount = 0;
      return;
    }

    setState(() => _isLoadingAllSessions = true);

    try {
      debugPrint('📥 [All Sessions Pagination] Loading sessions...');

      Query query = FirebaseFirestore.instance
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .limit(20);

      if (_lastAllDocument != null) {
        query = query.startAfter([_lastAllDocument!['createdAt']]);
        debugPrint('📄 [All Sessions] Starting after: ${_lastAllDocument!.id}');
      }

      final snapshot = await query.get();
      debugPrint('📦 [All Sessions] Fetched ${snapshot.docs.length} sessions');

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreAllSessions = false;
          _isLoadingAllSessions = false;
        });
        _allSessionsRecursiveCount = 0; // 🆕 Reset
        debugPrint('🏁 [All Sessions] No more sessions');
        return;
      }

      // Apply language filter
      final filtered =
          await SessionFilterService.filterSessionsByLanguageAndGender(
        snapshot.docs,
        _selectedGenderFilter,
      );
      debugPrint('🌍 [All Sessions] After filter: ${filtered.length}');

      // 🆕 AUTO-RECURSIVE: If all filtered and more docs exist
      if (filtered.isEmpty && snapshot.docs.length == 20) {
        debugPrint(
            '⚠️ [All Sessions] All filtered out, auto-loading more... (attempt ${_allSessionsRecursiveCount + 1}/10)');
        _lastAllDocument = snapshot.docs.last;
        _allSessionsRecursiveCount++; // 🆕 Increment
        setState(() => _isLoadingAllSessions = false);
        await _loadMoreAllSessions(); // 🆕 Recursive call
        return;
      }

      // 🆕 Reset counter on success
      _allSessionsRecursiveCount = 0;

      setState(() {
        _allSessions.addAll(filtered);
        _lastAllDocument = snapshot.docs.last;
        _hasMoreAllSessions = snapshot.docs.length == 20;
        _isLoadingAllSessions = false;
      });

      debugPrint('✅ [All Sessions] Total: ${_allSessions.length}');
    } catch (e) {
      debugPrint('❌ [All Sessions] Error: $e');
      _allSessionsRecursiveCount = 0; // 🆕 Reset on error
      setState(() => _isLoadingAllSessions = false);
    }
  }

// 🆕 ========== CATEGORY SESSIONS PAGINATION ==========
  Future<void> _loadInitialCategorySessions() async {
    setState(() {
      _categorySessions = [];
      _lastCategoryDocument = null;
      _hasMoreCategorySessions = true;
    });

    await _loadMoreCategorySessions();
  }

  Future<void> _loadMoreCategorySessions() async {
    if (_isLoadingCategorySessions || !_hasMoreCategorySessions) {
      debugPrint('⏸️ [Category Pagination] Already loading or no more');
      return;
    }

    // 🆕 Prevent infinite loop
    if (_categorySessionsRecursiveCount > 10) {
      debugPrint('⚠️ [Category] Max recursive calls reached, stopping');
      setState(() {
        _hasMoreCategorySessions = false;
        _isLoadingCategorySessions = false;
      });
      _categorySessionsRecursiveCount = 0;
      return;
    }

    setState(() => _isLoadingCategorySessions = true);

    try {
      debugPrint(
          '📥 [Category Pagination] Loading sessions for ${widget.categoryId}...');

      Query query = FirebaseFirestore.instance
          .collection('sessions')
          .where('categoryId', isEqualTo: widget.categoryId)
          .orderBy('createdAt', descending: true)
          .limit(20);

      if (_lastCategoryDocument != null) {
        query = query.startAfter([_lastCategoryDocument!['createdAt']]);
        debugPrint(
            '📄 [Category] Starting after: ${_lastCategoryDocument!.id}');
      }

      final snapshot = await query.get();
      debugPrint('📦 [Category] Fetched ${snapshot.docs.length} sessions');

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreCategorySessions = false;
          _isLoadingCategorySessions = false;
        });
        _categorySessionsRecursiveCount = 0; // 🆕 Reset
        debugPrint('🏁 [Category] No more sessions');
        return;
      }

      // Apply language filter
      final filtered =
          await SessionFilterService.filterSessionsByLanguageAndGender(
        snapshot.docs,
        _selectedGenderFilter,
      );
      debugPrint('🌍 [Category] After filter: ${filtered.length}');

      // 🆕 AUTO-RECURSIVE: If all filtered and more docs exist
      if (filtered.isEmpty && snapshot.docs.length == 20) {
        debugPrint(
            '⚠️ [Category] All filtered out, auto-loading more... (attempt ${_categorySessionsRecursiveCount + 1}/10)');
        _lastCategoryDocument = snapshot.docs.last;
        _categorySessionsRecursiveCount++; // 🆕 Increment
        setState(() => _isLoadingCategorySessions = false);
        await _loadMoreCategorySessions(); // 🆕 Recursive call
        return;
      }

      // 🆕 Reset counter on success
      _categorySessionsRecursiveCount = 0;

      setState(() {
        _categorySessions.addAll(filtered);
        _lastCategoryDocument = snapshot.docs.last;
        _hasMoreCategorySessions = snapshot.docs.length == 20;
        _isLoadingCategorySessions = false;
      });

      debugPrint('✅ [Category] Total: ${_categorySessions.length}');
    } catch (e) {
      debugPrint('❌ [Category] Error: $e');
      _categorySessionsRecursiveCount = 0; // 🆕 Reset on error
      setState(() => _isLoadingCategorySessions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
    final double ts = mq.textScaler.scale(1.0).clamp(1.0, 1.2);

    final String rightTitleText = widget.isShowingAllSessions
        ? AppLocalizations.of(context).allSubliminals
        : widget.categoryTitle;

    return MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.linear(ts)),
        child: Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            toolbarHeight: toolbarH,
            backgroundColor: colors.background,
            elevation: 0,
            leadingWidth: leadingWidth,
            titleSpacing: isTablet ? 4 : 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colors.textPrimary,
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
                            colors.textPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),

                    // ORTA: Ayraç
                    Container(
                      height: dividerH,
                      width: 1.5,
                      color: colors.textPrimary.withValues(alpha: 0.2),
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                    ),

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
                                  color: colors.textPrimary,
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
                                    child: AutoMarqueeText(
                                      text: rightTitleText,
                                      style: GoogleFonts.inter(
                                        fontSize: (16.sp).clamp(14.0, 18.0),
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
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
          body: Column(
            children: [
              // 🆕 Gender Filter
              _buildGenderFilter(colors),

              Expanded(
                child: widget.isShowingAllSessions
                    ? _buildAllSessionsList()
                    : _buildCategorySessionsList(),
              ),
            ],
          ),
        ));
  }

  // 🆕 ========== ALL SESSIONS LIST ==========
  Widget _buildAllSessionsList() {
    final colors = context.colors;
    // Loading state (ilk yükleme)
    if (_isLoadingAllSessions && _allSessions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colors.textPrimary),
      );
    }

    // Empty state
    if (_allSessions.isEmpty && !_hasMoreAllSessions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64.sp, color: colors.greyLight),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context).noSessionsAvailable,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Sessions list with pagination
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _allSessions.length + (_hasMoreAllSessions ? 1 : 0),
      itemBuilder: (context, index) {
        // See More button at the end
        if (index == _allSessions.length) {
          if (_isLoadingAllSessions) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: CircularProgressIndicator(color: colors.textPrimary),
              ),
            );
          } else {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: ElevatedButton(
                  onPressed: _loadMoreAllSessions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.textPrimary,
                    foregroundColor: colors.background,
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).seeMore,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        // Session item
        final session = _allSessions[index];
        return _buildSessionCard(
          sessionId: session['id'],
          sessionData: session,
          index: index,
        );
      },
    );
  }

// 🆕 ========== CATEGORY SESSIONS LIST ==========
  Widget _buildCategorySessionsList() {
    final colors = context.colors;
    // Loading state
    if (_isLoadingCategorySessions && _categorySessions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colors.textPrimary),
      );
    }

    // Empty state
    if (_categorySessions.isEmpty && !_hasMoreCategorySessions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64.sp, color: colors.greyLight),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context).noSessionsAvailable,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context).checkBackLater,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Sessions list with pagination
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _categorySessions.length + (_hasMoreCategorySessions ? 1 : 0),
      itemBuilder: (context, index) {
        // See More button at the end
        if (index == _categorySessions.length) {
          if (_isLoadingCategorySessions) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: CircularProgressIndicator(color: colors.textPrimary),
              ),
            );
          } else {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: ElevatedButton(
                  onPressed: _loadMoreCategorySessions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.textPrimary,
                    foregroundColor: colors.background,
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).seeMore,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        // Session item
        final session = _categorySessions[index];
        return _buildSessionCard(
          sessionId: session['id'],
          sessionData: session,
          index: index,
        );
      },
    );
  }

  Widget _buildSessionCard({
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required int index,
  }) {
    return SessionCard(
      session: sessionData,
      onTap: () {
        final completeSessionData = Map<String, dynamic>.from(sessionData);
        completeSessionData['id'] = sessionId;

        final playContext = PlayContext(
          type: widget.isShowingAllSessions
              ? PlayContextType.allSessions
              : PlayContextType.category,
          sourceId: widget.categoryId,
          sourceTitle: widget.categoryTitle,
          sessionList:
              widget.isShowingAllSessions ? _allSessions : _categorySessions,
          currentIndex: index,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              sessionData: completeSessionData,
              playContext: playContext,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderFilter(AppThemeExtension colors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Text(
            '${AppLocalizations.of(context).filterLabel}: ',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                      'all', '🌐 ${AppLocalizations.of(context).all}', colors),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                      'male', '♂ ${AppLocalizations.of(context).male}', colors),
                  SizedBox(width: 8.w),
                  _buildFilterChip('female',
                      '♀ ${AppLocalizations.of(context).female}', colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String value, String label, AppThemeExtension colors) {
    final isSelected = _selectedGenderFilter == value;
    return GestureDetector(
      onTap: () {
        if (_selectedGenderFilter != value) {
          setState(() => _selectedGenderFilter = value);
          // Reload sessions with new filter
          if (widget.isShowingAllSessions) {
            _loadInitialAllSessions();
          } else {
            _loadInitialCategorySessions();
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? colors.textPrimary : colors.greyLight,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? colors.textPrimary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colors.textOnPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
