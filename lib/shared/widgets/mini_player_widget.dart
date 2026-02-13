// lib/shared/widgets/mini_player_widget.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart' show PlayerState, ProcessingState;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auto_marquee_text.dart';
import '../../app.dart';
import '../../providers/mini_player_provider.dart';
import '../../providers/auto_play_provider.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/language_helper_service.dart';
import '../../services/download/download_service.dart';
import '../../services/download/decryption_preloader.dart';
import '../../services/session_localization_service.dart';
import '../../core/responsive/context_ext.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../features/player/audio_player_screen.dart';

/// Mini Player Widget - Spotify/YouTube style
/// Shows at bottom of screen when a session is playing
class MiniPlayerWidget extends StatefulWidget {
  const MiniPlayerWidget({super.key});

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget>
    with TickerProviderStateMixin {
  final AudioPlayerService _audioService = AudioPlayerService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  MiniPlayerProvider? _miniPlayerProvider;

  // Stream subscriptions
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  // Drag state
  double _dragOffset = 0.0;
  bool _isDragging = false;

  //  Smooth position animation
  late AnimationController _positionController;
  double _animatedOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // Slide animation for show/hide
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _positionController.addListener(() {
      setState(() {
        _animatedOffset = _positionController.value;
      });
    });

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Hidden below
      end: Offset.zero, // Visible
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_miniPlayerProvider == null) {
      _miniPlayerProvider = context.read<MiniPlayerProvider>();
      _setupStreamListeners();
    }
  }

  void _setupStreamListeners() {
    // Cancel existing subscriptions
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();

    // Setup new subscriptions with saved provider reference
    _playingSub = _audioService.isPlaying.listen((playing) {
      if (mounted && _miniPlayerProvider != null) {
        _miniPlayerProvider!.setPlayingState(playing);
      }
    });

    _positionSub = _audioService.position.listen((pos) {
      if (mounted && _miniPlayerProvider != null) {
        _miniPlayerProvider!.updatePosition(pos);
      }
    });

    _durationSub = _audioService.duration.listen((dur) {
      if (dur != null && mounted && _miniPlayerProvider != null) {
        _miniPlayerProvider!.updateDuration(dur);
      }
    });

    _playerStateSub = _audioService.playerState.listen((state) {
      if (!mounted || _miniPlayerProvider == null) return;

      // Ignore events if mini player is not visible
      if (!_miniPlayerProvider!.isVisible) return;

      if (state.processingState == ProcessingState.completed) {
        if (_miniPlayerProvider!.hasNext &&
            !_miniPlayerProvider!.isAutoPlayTransitioning) {
          final autoPlay =
              InsidexApp.navigatorKey.currentContext?.read<AutoPlayProvider>();
          if (autoPlay?.isEnabled ?? true) {
            debugPrint('🎵 [MiniPlayer] Session completed - auto-playing next');
            _playNextInMiniPlayer();
          } else {
            debugPrint('⏹️ [MiniPlayer] Auto-play disabled - stopping');
          }
        } else if (!_miniPlayerProvider!.hasNext &&
            !_miniPlayerProvider!.isAutoPlayTransitioning) {
          debugPrint(
              '🎵 [MiniPlayer] Session completed - no next, stopping & dismissing');
          _miniPlayerProvider!.setAutoPlayTransitioning(true);
          _audioService.stop().then((_) {
            if (mounted && _miniPlayerProvider != null) {
              _miniPlayerProvider!.dismiss();
            }
            _miniPlayerProvider!.setAutoPlayTransitioning(false);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _positionController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final miniPlayer = context.watch<MiniPlayerProvider>();
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    // Show/hide animation
    if (miniPlayer.isVisible) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }

    // Don't render if no session
    if (!miniPlayer.hasActiveSession) {
      return const SizedBox.shrink();
    }

    // Responsive sizing
    final double height = isDesktop ? 80.h : (isTablet ? 72.h : 64.h);
    final double maxWidth = isDesktop ? 800.0 : double.infinity;

    final screenHeight = MediaQuery.of(context).size.height;
    final currentOffset =
        _isDragging ? _dragOffset : _animatedOffset * screenHeight;

    return GestureDetector(
      onVerticalDragStart: (_) {
        _positionController.stop();
        setState(() => _isDragging = true);
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
          // 🆕 Full screen range - no clamp limit!
        });
      },
      onVerticalDragEnd: (details) {
        _handleDragEnd(context, details, screenHeight);
      },
      child: Transform.translate(
          offset: Offset(0,
              currentOffset.clamp(-screenHeight * 0.85, screenHeight * 0.85)),
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _buildMiniPlayerContent(
                  context, miniPlayer, height, isTablet),
            ),
          )),
    );
  }

  Widget _buildMiniPlayerContent(
    BuildContext context,
    MiniPlayerProvider miniPlayer,
    double baseHeight,
    bool isTablet,
  ) {
    final colors = context.colors;
    // Calculate height based on expand state
    final double collapsedHeight = baseHeight + 20.h;
    final double expandedHeight = baseHeight + 48.h + 20.h;
    final double currentHeight =
        miniPlayer.isExpanded ? expandedHeight : collapsedHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: currentHeight, // Animated height
      margin: EdgeInsets.only(
        left: isTablet ? 16.w : 8.w,
        right: isTablet ? 16.w : 8.w,
        top: miniPlayer.isAtTop ? MediaQuery.of(context).padding.top + 8.h : 0,
        bottom: miniPlayer.isAtTop ? 0 : 8.h,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundElevated,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: Offset(0, miniPlayer.isAtTop ? 2 : -2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main content row (always visible)
              Flexible(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    children: [
                      // Session image
                      _buildSessionImage(miniPlayer),

                      SizedBox(width: 12.w),

                      // Session title (tappable)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            debugPrint(
                                '🎯 [MiniPlayer] Title GestureDetector triggered');
                            _openFullPlayer(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            alignment: Alignment.centerLeft,
                            child: _buildSessionTitle(miniPlayer),
                          ),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Play/Pause button
                      _buildPlayPauseButton(miniPlayer),

                      SizedBox(width: 8.w),

                      // Close button
                      _buildCloseButton(miniPlayer),

                      SizedBox(width: 4.w),

                      // Expand/Collapse button
                      _buildExpandButton(miniPlayer),
                    ],
                  ),
                ),
              ),

              // Expanded controls (skip buttons) - shown when expanded
              if (miniPlayer.isExpanded)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isDragging && _dragOffset > 0
                      ? (1.0 - (_dragOffset / 200.0)).clamp(0.0, 1.0)
                      : 1.0,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 12.w,
                      right: 12.w,
                      bottom: 8.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Skip backward button
                        _buildSkipButton(
                          icon: Icons.replay_10,
                          onTap: () => _skipBackward(),
                        ),
                        SizedBox(width: 24.w),
                        // Skip forward button
                        _buildSkipButton(
                          icon: Icons.forward_10,
                          onTap: () => _skipForward(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Progress bar
              _buildProgressBar(miniPlayer),
            ],
          ),
        ),
      ),
    );
  }

  /// Session image thumbnail
  Widget _buildSessionImage(MiniPlayerProvider miniPlayer) {
    final colors = context.colors;
    final imageUrl = miniPlayer.sessionImageUrl;
    final localImagePath = miniPlayer.localImagePath;
    final isOffline = miniPlayer.isOfflineSession;

    return GestureDetector(
      onTap: () {
        debugPrint('🎯 [MiniPlayer] Image tapped - opening full player');
        _openFullPlayer(context);
      },
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: colors.greyLight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: _buildImageContent(
            imageUrl: imageUrl,
            localImagePath: localImagePath,
            isOffline: isOffline,
          ),
        ),
      ),
    );
  }

  /// Build image content based on online/offline mode
  Widget _buildImageContent({
    required String? imageUrl,
    required String? localImagePath,
    required bool isOffline,
  }) {
    final colors = context.colors;
    // ✅ OFFLINE MODE - Use local file
    if (isOffline && localImagePath != null && localImagePath.isNotEmpty) {
      final file = File(localImagePath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
            );
          }
          return _buildPlaceholderIcon();
        },
      );
    }

    // ✅ ONLINE MODE - Use network image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: colors.greyLight,
          child: _buildPlaceholderIcon(),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholderIcon(),
      );
    }

    // Fallback
    return _buildPlaceholderIcon();
  }

  /// Placeholder icon for missing images
  Widget _buildPlaceholderIcon() {
    final colors = context.colors;
    return Icon(
      Icons.music_note,
      size: 24.sp,
      color: colors.textSecondary,
    );
  }

  /// Session title with marquee if too long
  Widget _buildSessionTitle(MiniPlayerProvider miniPlayer) {
    return AutoMarqueeText(
      text: miniPlayer.sessionTitle,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: context.colors.textPrimary,
        decoration: TextDecoration.none,
      ),
      velocity: 25.0,
    );
  }

  /// Skip button (forward/backward)
  Widget _buildSkipButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: context.colors.greyMedium,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }

  /// Play/Pause button
  Widget _buildPlayPauseButton(MiniPlayerProvider miniPlayer) {
    return GestureDetector(
      onTap: () => _handlePlayPause(miniPlayer),
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? context.colors.textSecondary
              : context.colors.textPrimary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          miniPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
          color: context.colors.textOnPrimary,
          size: 20.sp,
        ),
      ),
    );
  }

  /// Expand button (shows skip controls)
  Widget _buildExpandButton(MiniPlayerProvider miniPlayer) {
    return GestureDetector(
      onTap: () => _toggleExpanded(miniPlayer),
      child: AnimatedRotation(
        turns: miniPlayer.isExpanded ? 0.5 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: context.colors.greyLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.keyboard_arrow_up,
            size: 18.sp,
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Close button (dismiss mini player)
  Widget _buildCloseButton(MiniPlayerProvider miniPlayer) {
    return GestureDetector(
      onTap: () => _closeMiniPlayer(miniPlayer),
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close,
          size: 16.sp,
          color: Colors.red[700],
        ),
      ),
    );
  }

  /// Progress bar at bottom (also drag zone)
  Widget _buildProgressBar(MiniPlayerProvider miniPlayer) {
    final progress = miniPlayer.progress.clamp(0.0, 1.0);
    final colors = context.colors;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        _handleProgressDragStart(details, miniPlayer);
      },
      onHorizontalDragUpdate: (details) {
        _handleProgressDragUpdate(details, miniPlayer);
      },
      onHorizontalDragEnd: (details) {
        _handleProgressDragEnd(details, miniPlayer);
      },
      onTapUp: (details) {
        _handleProgressTap(details, miniPlayer);
      },
      child: Container(
        height: 20.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        color: Colors.transparent,
        child: Center(
          child: Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              color: colors.greyLight,
            ),
            child: Stack(
              children: [
                // Active track
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final thumbPosition = constraints.maxWidth * progress - 6;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: thumbPosition.clamp(
                                0, constraints.maxWidth - 12),
                            top: -4.5,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.textPrimary,
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.textPrimary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Progress bar drag handlers
  void _handleProgressDragStart(
      DragStartDetails details, MiniPlayerProvider miniPlayer) {
    // Optional: pause during drag
  }

  void _handleProgressDragUpdate(
      DragUpdateDetails details, MiniPlayerProvider miniPlayer) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = details.localPosition;
    final width = box.size.width - 24.w; // padding
    final progress = ((localPosition.dx - 12.w) / width).clamp(0.0, 1.0);

    final newPosition = miniPlayer.duration * progress;
    miniPlayer.updatePosition(newPosition);
  }

  void _handleProgressDragEnd(
      DragEndDetails details, MiniPlayerProvider miniPlayer) async {
    await _audioService.seek(miniPlayer.position);
    debugPrint('🎵 Seeked to ${miniPlayer.position.inSeconds}s');
  }

  void _handleProgressTap(
      TapUpDetails details, MiniPlayerProvider miniPlayer) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = details.localPosition;
    final width = box.size.width - 24.w; // padding
    final progress = ((localPosition.dx - 12.w) / width).clamp(0.0, 1.0);

    final newPosition = miniPlayer.duration * progress;
    miniPlayer.updatePosition(newPosition);
    await _audioService.seek(newPosition);
    debugPrint('🎵 Tapped to ${newPosition.inSeconds}s');
  }

  // =================== ACTIONS ===================

  void _handlePlayPause(MiniPlayerProvider miniPlayer) async {
    if (miniPlayer.isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.play();
    }
  }

  void _toggleExpanded(MiniPlayerProvider miniPlayer) {
    miniPlayer.toggleExpanded();
  }

  void _closeMiniPlayer(MiniPlayerProvider miniPlayer) async {
    // Stop audio and close notification
    await _audioService.stop();
    // Hide and dismiss mini player
    miniPlayer.dismiss();
  }

  void _openFullPlayer(BuildContext context) {
    debugPrint('🎯 [MiniPlayer] Title tapped - opening full player');
    final miniPlayer = _miniPlayerProvider;
    final session = miniPlayer?.currentSession;

    if (session == null) {
      debugPrint('⚠️ No session data available');
      return;
    }

    debugPrint('✅ [MiniPlayer] Session data: ${session['title']}');

    // ✅ Use global navigator key instead of context
    final navigatorState = InsidexApp.navigatorKey.currentState;

    if (navigatorState == null) {
      debugPrint('⚠️ Navigator state is null');
      return;
    }

    // Simple push with animation
    navigatorState.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AudioPlayerScreen(
            sessionData: session,
            playContext: _miniPlayerProvider?.playContext,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up from bottom
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _skipBackward() async {
    final currentPosition = await _audioService.position.first;
    final newPosition = currentPosition - const Duration(seconds: 10);
    await _audioService.seek(
      newPosition.isNegative ? Duration.zero : newPosition,
    );
  }

  // =================== AUTO-PLAY ===================

  Future<void> _playNextInMiniPlayer() async {
    if (_miniPlayerProvider == null ||
        _miniPlayerProvider!.isAutoPlayTransitioning) return;

    _miniPlayerProvider!.setAutoPlayTransitioning(true);

    try {
      final nextSession = _miniPlayerProvider!.playNext();
      if (nextSession == null) {
        debugPrint('⏹️ [MiniPlayer] No next session - queue ended');
        _miniPlayerProvider!.setAutoPlayTransitioning(false);
        return;
      }

      debugPrint('⏭️ [MiniPlayer] Switching to: ${nextSession['title']}');

      final isOffline = nextSession['_isOffline'] == true;

      if (isOffline) {
        await _playNextOffline(nextSession);
      } else {
        await _playNextOnline(nextSession);
      }

      // Add to recent sessions (only for online)
      if (!isOffline) {
        _addToRecentSessions(nextSession);
      }
    } catch (e) {
      debugPrint('❌ [MiniPlayer] Auto-play error: $e');
    } finally {
      _miniPlayerProvider!.setAutoPlayTransitioning(false);
    }
  }

  Future<void> _playNextOnline(Map<String, dynamic> nextSession) async {
    final language = await LanguageHelperService.getCurrentLanguage();

    final localizedContent = SessionLocalizationService.getLocalizedContent(
      nextSession,
      language,
    );

    final audioUrl = LanguageHelperService.getAudioUrl(
      nextSession['subliminal']?['audioUrls'],
      language,
    );

    final imageUrl = LanguageHelperService.getImageUrl(
      nextSession['backgroundImages'],
      language,
    );

    final durationSeconds = LanguageHelperService.getDuration(
      nextSession['subliminal']?['durations'],
      language,
    );

    if (audioUrl.isEmpty) {
      debugPrint('❌ [MiniPlayer] No audio URL for next session, skipping');
      if (_miniPlayerProvider!.hasNext) {
        _miniPlayerProvider!.setAutoPlayTransitioning(false);
        _playNextInMiniPlayer();
        return;
      }
      return;
    }

    final displayTitle = localizedContent.title.isNotEmpty
        ? localizedContent.title
        : nextSession['title'] ?? 'InsideX';

    final updatedSession = Map<String, dynamic>.from(nextSession);
    updatedSession['_localizedTitle'] = displayTitle;
    updatedSession['_displayTitle'] = displayTitle;
    updatedSession['_backgroundImageUrl'] = imageUrl;
    updatedSession['_currentLanguage'] = language;

    _miniPlayerProvider!.playSession(updatedSession);

    await _audioService.stop();
    await Future.delayed(const Duration(milliseconds: 50));
    await _audioService.initialize();
    _setupStreamListeners();

    final resolved = await _audioService.playFromUrl(
      audioUrl,
      title: displayTitle,
      artist: 'InsideX',
      artworkUrl: imageUrl,
      sessionId: nextSession['id'],
      duration: durationSeconds > 0 ? Duration(seconds: durationSeconds) : null,
    );

    if (resolved != null && mounted && _miniPlayerProvider != null) {
      _miniPlayerProvider!.updateDuration(resolved);
    }

    debugPrint('✅ [MiniPlayer] Now playing: $displayTitle');
  }

  Future<void> _playNextOffline(Map<String, dynamic> nextSession) async {
    final sessionId = nextSession['id'] as String?;
    final language = nextSession['_downloadedLanguage'] as String? ?? 'en';
    final displayTitle =
        nextSession['_displayTitle'] ?? nextSession['title'] ?? 'InsideX';
    final localImagePath = nextSession['_localImagePath'] as String?;

    if (sessionId == null) {
      debugPrint('❌ [MiniPlayer] Offline session ID is null, skipping');
      return;
    }

    // Try cache first, then decrypt
    final preloader = DecryptionPreloader();
    String? decryptedPath = preloader.getCachedPath(sessionId);

    if (decryptedPath == null) {
      debugPrint('⏳ [MiniPlayer] Decrypting offline session...');
      final downloadService = DownloadService();
      decryptedPath = await downloadService.getDecryptedAudioPath(
        sessionId,
        language,
      );
    }

    if (decryptedPath == null) {
      debugPrint('❌ [MiniPlayer] Could not decrypt, skipping');
      if (_miniPlayerProvider!.hasNext) {
        _miniPlayerProvider!.setAutoPlayTransitioning(false);
        _playNextInMiniPlayer();
        return;
      }
      return;
    }

    // Update provider
    final updatedSession = Map<String, dynamic>.from(nextSession);
    updatedSession['_displayTitle'] = displayTitle;
    _miniPlayerProvider!.playSession(updatedSession);

    // Play
    await _audioService.stop();
    await Future.delayed(const Duration(milliseconds: 50));
    await _audioService.initialize();
    _setupStreamListeners();

    final durationSeconds = nextSession['_offlineDurationSeconds'] as int? ?? 0;

    final resolved = await _audioService.playFromUrl(
      'file://$decryptedPath',
      title: displayTitle,
      artist: 'InsideX',
      artworkUrl: null,
      localArtworkPath: localImagePath,
      sessionId: sessionId,
      duration: durationSeconds > 0 ? Duration(seconds: durationSeconds) : null,
    );

    if (resolved != null && mounted && _miniPlayerProvider != null) {
      _miniPlayerProvider!.updateDuration(resolved);
    }

    debugPrint('✅ [MiniPlayer] Now playing offline: $displayTitle');
  }

  void _addToRecentSessions(Map<String, dynamic> session) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && session['id'] != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'recentSessionIds': FieldValue.arrayUnion([session['id']]),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('❌ [MiniPlayer] Error adding to recent: $e');
      }
    }
  }

  void _skipForward() async {
    final currentPosition = await _audioService.position.first;
    final duration = await _audioService.duration.first;
    final newPosition = currentPosition + const Duration(seconds: 10);

    if (duration != null && newPosition < duration) {
      await _audioService.seek(newPosition);
    } else if (duration != null) {
      await _audioService.seek(duration);
    }
  }

  void _handleDragEnd(
      BuildContext context, DragEndDetails details, double screenHeight) {
    final provider = _miniPlayerProvider;
    if (provider == null) return;

    final velocity = details.primaryVelocity ?? 0.0;
    final normalizedOffset = _dragOffset / screenHeight;

    // 🆕 Velocity-based decision (fast swipe = immediate action)
    final fastSwipeDown = velocity > 800;
    final fastSwipeUp = velocity < -800;

    // 🆕 Position-based decision (drag threshold)
    final bool shouldMoveUp = normalizedOffset < -0.15 || fastSwipeUp;
    final bool shouldMoveDown = normalizedOffset > 0.15 || fastSwipeDown;
    final bool shouldDismiss =
        normalizedOffset > 0.35 || (fastSwipeDown && !provider.isAtTop);

    setState(() => _isDragging = false);

    // 🆕 Calculate target and animate smoothly
    double targetOffset = 0.0;

    if (shouldDismiss && !provider.isAtTop) {
      // Dismiss with smooth animation
      targetOffset = 1.0; // Slide down fully
      _animateToPosition(targetOffset, onComplete: () async {
        await _audioService.stop();
        provider.dismiss();
        setState(() {
          _dragOffset = 0.0;
          _animatedOffset = 0.0;
        });
      });
    } else if (shouldMoveUp && !provider.isAtTop) {
      // Move to top
      _animateToPosition(0.0, curve: Curves.easeOutBack);
      provider.setAtTop(true);
      setState(() => _dragOffset = 0.0);
    } else if (shouldMoveDown && provider.isAtTop) {
      // Move to bottom
      _animateToPosition(0.0, curve: Curves.easeOutBack);
      provider.setAtTop(false);
      setState(() => _dragOffset = 0.0);
    } else {
      // 🆕 Spring back to original position
      _animateToPosition(0.0, curve: Curves.elasticOut);
      setState(() => _dragOffset = 0.0);
    }
  }

  /// 🆕 Smooth animation helper with spring physics
  void _animateToPosition(double target,
      {Curve curve = Curves.easeOutCubic, VoidCallback? onComplete}) {
    final startValue = _dragOffset / MediaQuery.of(context).size.height;

    _positionController.reset();

    final animation = Tween<double>(
      begin: startValue,
      end: target,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: curve,
    ));

    void listener() {
      setState(() {
        _animatedOffset = animation.value;
      });
    }

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        animation.removeListener(listener);
        _positionController.removeStatusListener(statusListener);
        onComplete?.call();
      }
    }

    animation.addListener(listener);
    _positionController.addStatusListener(statusListener);
    _positionController.forward();
  }
}
