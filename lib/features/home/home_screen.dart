import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_scaffold.dart';
import '../../core/responsive/context_ext.dart';
import '../../features/library/categories_screen.dart';
import '../../features/playlist/playlist_screen.dart';
import '../profile/profile_screen.dart';
import '../../shared/widgets/menu_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Menu state
  bool _isMenuOpen = false;
  void _toggleMenu() => setState(() => _isMenuOpen = !_isMenuOpen);

  // Drag states (All & Playlist)
  bool _isDraggingAll = false;
  double _dragAll = 0.0;
  bool _readyAll = false;

  bool _isDraggingPl = false;
  double _dragPl = 0.0;
  bool _readyPl = false;

  final double _dragThreshold = 60.0;

  late final AnimationController _pulseAll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final AnimationController _pulsePl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseAll.dispose();
    _pulsePl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    // Referans 844; tablette sabit değerler daha stabil
    final refH = 844.0;
    final s = (context.h / refH).clamp(0.85, 1.15);

    final double headerH = isTablet ? 280.0 : (240.0 * s).clamp(200.0, 260.0);
    final double cardH = isTablet ? 210.0 : (200.0 * s).clamp(160.0, 220.0);

    double topAll = headerH - (cardH * 0.35);
    double topPlaylist = topAll + (cardH * 0.60) + 8.0;

    final double baseBarH =
        isTablet ? 64.0 : (context.isCompactH ? 56.0 : 60.0);
    final double maxY = context.h - baseBarH - 16.0;
    final double bottomOfPlaylist = topPlaylist + cardH;

    if (bottomOfPlaylist > maxY) {
      final shiftUp = bottomOfPlaylist - maxY;
      topAll = (topAll - shiftUp).clamp(12.0, headerH - (cardH * 0.25));
      topPlaylist = (topPlaylist - shiftUp).clamp(topAll + 8.0, maxY - cardH);
    }

    return ResponsiveScaffold(
      appBar: null,
      body: Stack(
        children: [
          // background
          Positioned.fill(child: _buildBackground()),
          // content
          _buildPlaylistCard(top: topPlaylist, height: cardH),
          _buildAllSubliminalsCard(top: topAll, height: cardH),
          _buildHeader(height: headerH),
          // overlay
          if (_isMenuOpen)
            Positioned.fill(
              child: MenuOverlay(onClose: _toggleMenu),
            ),
        ],
      ),
      bottomNav: _buildBottomNavContent(),
    );
  }

  // ---------- UI parts ----------
  Widget _buildHeader({required double height}) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          // yatay .w, dikey .h kullan
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Only logo (no text title as requested)
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    height: 28.h,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                        AppColors.textPrimary, BlendMode.srcIn),
                  ),
                  const Spacer(),
                  _buildHeaderButton('Menu', true),
                ],
              ),
              const Spacer(),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllSubliminalsCard(
      {required double top, required double height}) {
    final progress = (_dragAll / _dragThreshold).clamp(0.0, 1.0);

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CategoriesScreen()));
        },
        onVerticalDragStart: (_) => setState(() => _isDraggingAll = true),
        onVerticalDragUpdate: (d) {
          setState(() {
            _dragAll = (_dragAll + d.delta.dy).clamp(0.0, _dragThreshold);
            final wasReady = _readyAll;
            _readyAll = _dragAll >= _dragThreshold;
            if (_readyAll && !wasReady) HapticFeedback.lightImpact();
          });
        },
        onVerticalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0.0;
          if (_readyAll || v > 500) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()));
          }
          setState(() {
            _isDraggingAll = false;
            _readyAll = false;
            _dragAll = 0.0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()..scale(_isDraggingAll ? 0.97 : 1.0),
          decoration: BoxDecoration(
            color: _readyAll ? AppColors.textPrimary : const Color(0xFFCCCBCB),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: _readyAll
                    ? AppColors.textPrimary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: _isDraggingAll ? 25 : 20,
                offset: Offset(0, _isDraggingAll ? 12 : 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 20.w,
                bottom: 20.h,
                child: Text(
                  'All Subliminals',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _readyAll ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Positioned(
                bottom: 8.h,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(
                              parent: _pulseAll, curve: Curves.easeInOut)),
                      child: Icon(
                        _readyAll ? Icons.lock_open : Icons.keyboard_arrow_down,
                        color: _readyAll
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textPrimary.withOpacity(0.5),
                        size: 20.sp,
                      ),
                    ),
                    Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3.r),
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
      ),
    );
  }

  Widget _buildPlaylistCard({required double top, required double height}) {
    final progress = (_dragPl / _dragThreshold).clamp(0.0, 1.0);

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() => _isDraggingPl = true),
        onVerticalDragUpdate: (d) {
          setState(() {
            _dragPl = (_dragPl + d.delta.dy).clamp(0.0, _dragThreshold);
            final wasReady = _readyPl;
            _readyPl = _dragPl >= _dragThreshold;
            if (_readyPl && !wasReady) HapticFeedback.lightImpact();
          });
        },
        onVerticalDragEnd: (details) async {
          final v = details.primaryVelocity ?? 0.0;
          if (_readyPl || v > 500) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlaylistScreen()));
          }
          setState(() {
            _isDraggingPl = false;
            _readyPl = false;
            _dragPl = 0.0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()..scale(_isDraggingPl ? 0.97 : 1.0),
          decoration: BoxDecoration(
            color: _readyPl ? AppColors.textPrimary : const Color(0xFFCCCBCB),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: _readyPl
                    ? AppColors.textPrimary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: _isDraggingPl ? 25 : 15,
                offset: Offset(0, _isDraggingPl ? 12 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 20.w,
                bottom: 20.h,
                child: Text(
                  'Your Playlist',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _readyPl ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Positioned(
                bottom: 8.h,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(
                              parent: _pulsePl, curve: Curves.easeInOut)),
                      child: Icon(
                        _readyPl ? Icons.lock_open : Icons.keyboard_arrow_down,
                        size: 20.sp,
                        color: _readyPl
                            ? Colors.white.withOpacity(0.85)
                            : AppColors.textPrimary.withOpacity(0.5),
                      ),
                    ),
                    Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3.r),
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
      ),
    );
  }

  // Background
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9F9F9), Color(0xFFEFEFEF)],
        ),
      ),
    );
  }

  // Header menu button
  Widget _buildHeaderButton(String text, bool isFilled) {
    return InkWell(
      onTap: _toggleMenu,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isFilled ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: isFilled ? null : Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isFilled ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.menu,
                size: 14.sp, color: isFilled ? Colors.white : Colors.black),
          ],
        ),
      ),
    );
  }

  // Bottom nav content (only content; height/shape is in ResponsiveScaffold)
  Widget _buildBottomNavContent() {
    int current = 0; // TODO: wire with state if needed

    Widget item(IconData icon, String label, int idx, VoidCallback onTap) {
      final selected = current == idx;
      return InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: context.isTablet ? 24 : 22,
                  color: selected ? AppColors.textPrimary : Colors.grey[500]),
              const SizedBox(height: 4),
              SizedBox(
                width: context.isTablet ? 76 : 64,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: context.isTablet ? 11 : 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.textPrimary : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        item(Icons.home_outlined, 'Home', 0, () {}),
        item(Icons.play_circle_outline, 'Playlist', 1, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PlaylistScreen()));
        }),
        item(Icons.chat_bubble_outline, 'AI Chat', 2, () {
          // TODO: navigate to chat
        }),
        item(Icons.person_outline, 'Profile', 3, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }),
      ],
    );
  }
}
