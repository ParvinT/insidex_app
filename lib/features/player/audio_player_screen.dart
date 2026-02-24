import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' show PlayerState;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'player_state_mixin.dart';
import 'player_audio_mixin.dart';
import 'player_session_mixin.dart';
import 'widgets/player_modals.dart';
import 'widgets/session_info_modal.dart';
import 'widgets/player_widgets.dart';
import 'widgets/player_album_art.dart';
import 'widgets/player_introduction_modal.dart';
import 'widgets/up_next_card.dart';
import '../../models/play_context.dart';
import '../../services/listening_tracker_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/mini_player_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/cache_manager_service.dart';
import '../downloads/widgets/download_button.dart';
import '../../core/themes/app_theme_extension.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionData;
  final PlayContext? playContext;
  const AudioPlayerScreen({super.key, this.sessionData, this.playContext});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        PlayerAudioMixin,
        PlayerSessionMixin
    implements PlayerStateAccessor {
  // =================== STATE VARIABLES ===================

  late final AnimationController _eqController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  final AudioPlayerService _audioService = AudioPlayerService();
  MiniPlayerProvider? _miniPlayerProvider;

  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isInPlaylist = false;
  bool _isLooping = false;
  bool _isTracking = false;
  bool _isDecrypting = false;
  bool _isLoadingAudio = false;
  bool _isPlayingTrack = false;

  String _currentLanguage = 'en';
  String? _audioUrl;
  String? _backgroundImageUrl;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _hasAddedToRecent = false;
  bool _accessGranted = false;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _sleepTimerSub;

  int? _sleepTimerMinutes;
  late Map<String, dynamic> _session;

  // Swipe-to-dismiss state
  double _dismissDragOffset = 0.0;
  bool _isDismissDragging = false;
  final ScrollController _dismissScrollController = ScrollController();

  // =================== PlayerStateAccessor IMPLEMENTATION ===================

  @override
  Map<String, dynamic> get session => _session;
  @override
  set session(Map<String, dynamic> value) => _session = value;
  @override
  String get currentLanguage => _currentLanguage;
  @override
  set currentLanguage(String value) => _currentLanguage = value;
  @override
  String? get audioUrl => _audioUrl;
  @override
  set audioUrl(String? value) => _audioUrl = value;
  @override
  String? get backgroundImageUrl => _backgroundImageUrl;
  @override
  set backgroundImageUrl(String? value) => _backgroundImageUrl = value;
  @override
  Duration get currentPosition => _currentPosition;
  @override
  set currentPosition(Duration value) => _currentPosition = value;
  @override
  Duration get totalDuration => _totalDuration;
  @override
  set totalDuration(Duration value) => _totalDuration = value;
  @override
  bool get isPlaying => _isPlaying;
  @override
  set isPlaying(bool value) => _isPlaying = value;
  @override
  bool get isFavorite => _isFavorite;
  @override
  set isFavorite(bool value) => _isFavorite = value;
  @override
  bool get isInPlaylist => _isInPlaylist;
  @override
  set isInPlaylist(bool value) => _isInPlaylist = value;
  @override
  bool get isLooping => _isLooping;
  @override
  set isLooping(bool value) => _isLooping = value;
  @override
  bool get isTracking => _isTracking;
  @override
  set isTracking(bool value) => _isTracking = value;
  @override
  bool get isDecrypting => _isDecrypting;
  @override
  set isDecrypting(bool value) => _isDecrypting = value;
  @override
  bool get isLoadingAudio => _isLoadingAudio;
  @override
  set isLoadingAudio(bool value) => _isLoadingAudio = value;
  @override
  bool get isPlayingTrack => _isPlayingTrack;
  @override
  set isPlayingTrack(bool value) => _isPlayingTrack = value;
  @override
  bool get hasAddedToRecent => _hasAddedToRecent;
  @override
  set hasAddedToRecent(bool value) => _hasAddedToRecent = value;
  @override
  bool get accessGranted => _accessGranted;
  @override
  set accessGranted(bool value) => _accessGranted = value;
  @override
  int? get sleepTimerMinutes => _sleepTimerMinutes;
  @override
  set sleepTimerMinutes(int? value) => _sleepTimerMinutes = value;
  @override
  bool get isOfflineSession => _session['_isOffline'] == true;
  @override
  AudioPlayerService get audioService => _audioService;
  @override
  MiniPlayerProvider? get miniPlayerProvider => _miniPlayerProvider;
  @override
  AnimationController get eqController => _eqController;
  @override
  StreamSubscription<bool>? get playingSub => _playingSub;
  @override
  set playingSub(StreamSubscription<bool>? value) => _playingSub = value;
  @override
  StreamSubscription<Duration>? get positionSub => _positionSub;
  @override
  set positionSub(StreamSubscription<Duration>? value) => _positionSub = value;
  @override
  StreamSubscription<Duration?>? get durationSub => _durationSub;
  @override
  set durationSub(StreamSubscription<Duration?>? value) => _durationSub = value;
  @override
  StreamSubscription<PlayerState>? get playerStateSub => _playerStateSub;
  @override
  set playerStateSub(StreamSubscription<PlayerState>? value) =>
      _playerStateSub = value;
  @override
  StreamSubscription<int?>? get sleepTimerSub => _sleepTimerSub;
  @override
  set sleepTimerSub(StreamSubscription<int?>? value) => _sleepTimerSub = value;

  // =================== LIFECYCLE ===================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_miniPlayerProvider == null) {
      _miniPlayerProvider = context.read<MiniPlayerProvider>();

      final miniPlayer = _miniPlayerProvider!;
      final currentSessionId = miniPlayer.currentSession?['id'];
      final newSessionId = widget.sessionData?['id'];
      final currentIsOffline = miniPlayer.currentSession?['_isOffline'] == true;
      final newIsOffline = widget.sessionData?['_isOffline'] == true;

      final isSameSession = miniPlayer.hasActiveSession &&
          currentSessionId == newSessionId &&
          currentIsOffline == newIsOffline;

      if (isSameSession && miniPlayer.position > Duration.zero) {
        _currentPosition = miniPlayer.position;
        _totalDuration = miniPlayer.duration;
        _isPlaying = miniPlayer.isPlaying;
        debugPrint(
            '✨ Pre-loaded state for same session: ${_currentPosition.inSeconds}s');
      } else {
        debugPrint('🆕 New session or different type');
      }

      if (widget.playContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _miniPlayerProvider?.setPlayContext(widget.playContext);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _session = widget.sessionData ??
        {
          'title': 'Session',
          'introduction': {
            'title': AppLocalizations.of(context).aboutThisSession,
            'content': '',
          },
          'subliminal': {'audioUrls': {}, 'durations': {}},
          'backgroundImages': {},
        };

    // Wire up mixin callbacks
    onPlayNextSession = () => playNextSession();
    onPlayPreviousSession = () => playPreviousSession();
    onInitializeAudio = () => initializeAudio();
    onSetupStreamListeners = () => setupStreamListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAccessAndInitialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final subscriptionProvider = context.read<SubscriptionProvider>();
    if (subscriptionProvider.canUseBackgroundPlayback) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        debugPrint(
            '⏸️ [AudioPlayer] Free user - pausing audio (app backgrounded)');
        _audioService.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isTracking) {
      ListeningTrackerService.endSession().then((_) {
        debugPrint('Listening session ended and saved');
      });
    }

    cancelStreamSubscriptions();
    _eqController.dispose();
    _dismissScrollController.dispose();
    super.dispose();
  }

  // =================== UI BUILD ===================

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;

        debugPrint('🔙 [AudioPlayer] PopScope triggered');
        _miniPlayerProvider?.setAutoPlayTransitioning(false);

        if (_accessGranted && _miniPlayerProvider != null) {
          debugPrint(
              '🎵 [AudioPlayer] Showing mini player with session: ${_session['title']}');
          _session['_currentLanguage'] = _currentLanguage;
          _session['_backgroundImageUrl'] = _backgroundImageUrl;
          _miniPlayerProvider!.playSession(_session);
          _miniPlayerProvider!.show();
          debugPrint(
              '✅ [AudioPlayer] Mini player visible: ${_miniPlayerProvider!.isVisible}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _miniPlayerProvider?.triggerRefresh();
          });
        } else if (!_accessGranted) {
          debugPrint(
              '🚫 [AudioPlayer] Access not granted - skipping mini player');
        }

        if (_isTracking) {
          ListeningTrackerService.endSession().then((_) {
            debugPrint('Session tracking ended on back press');
          });
        }
      },
      child: AnimatedContainer(
        duration: _isDismissDragging
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _dismissDragOffset, 0),
        child: Scaffold(
          backgroundColor: colors.background,
          body: Stack(
            children: [
              _buildBlurBackground(colors),
              _buildDarkOverlay(),
              _buildMainContent(colors),
              if (_isDecrypting) _buildDecryptingOverlay(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(
          alpha: (_backgroundImageUrl != null &&
                      _backgroundImageUrl!.isNotEmpty) ||
                  (_session['_localImagePath'] != null &&
                      (_session['_localImagePath'] as String).isNotEmpty)
              ? 0.35
              : 0.0,
        ),
      ),
    );
  }

  Widget _buildMainContent(AppThemeExtension colors) {
    return SafeArea(
      child: Column(
        children: [
          PlayerHeader(
            onBack: () => Navigator.pop(context),
            onInfo: () {
              SessionInfoModal.show(context: context, session: _session);
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Widget inner = _buildPlayerBody();
                final bool isSmallPhone =
                    constraints.maxWidth <= 400 || constraints.maxHeight <= 700;
                return _buildDismissableScrollView(
                  constraints: constraints,
                  isSmallPhone: isSmallPhone,
                  child: inner,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayerAlbumArt(
          imageUrl: _backgroundImageUrl,
          localImagePath: _session['_localImagePath'],
          equalizerController: _eqController,
          isPlaying: _isPlaying,
          hasPrevious: _miniPlayerProvider?.hasPrevious ?? false,
          hasNext: _miniPlayerProvider?.hasNext ?? false,
          onSwipePrevious: () => playPreviousSession(),
          onSwipeNext: () => playNextSession(),
          isTransitioning:
              _miniPlayerProvider?.isAutoPlayTransitioning ?? false,
        ),
        SizedBox(height: 40.h),
        PlayerSessionInfo(
          title: _session['_displayTitle'] ??
              _session['_localizedTitle'] ??
              _session['title'] ??
              AppLocalizations.of(context).untitledSession,
          subtitle: AppLocalizations.of(context).subliminalSession,
        ),
        SizedBox(height: 30.h),
        IntroductionButton(
          onTap: () => PlayerIntroductionModal.show(
            context: context,
            session: _session,
          ),
        ),
        SizedBox(height: 30.h),
        PlayerProgressBar(
          position: _currentPosition,
          duration: _totalDuration,
          onSeek: (duration) => _audioService.seek(duration),
        ),
        SizedBox(height: 30.h),
        PlayerPlayControls(
          isPlaying: _isPlaying,
          hasPrevious: _miniPlayerProvider?.hasPrevious ?? false,
          hasNext: _miniPlayerProvider?.hasNext ?? false,
          onPlayPause: togglePlayPause,
          onReplay10: replay10,
          onForward10: forward10,
          onPrevious: () => playPreviousSession(),
          onNext: () => playNextSession(),
        ),
        SizedBox(height: 16.h),
        UpNextCard(currentLanguage: _currentLanguage),
        SizedBox(height: 16.h),
        PlayerBottomActions(
          isLooping: _isLooping,
          isFavorite: _isFavorite,
          isInPlaylist: _isInPlaylist,
          isOffline: isOfflineSession,
          isTimerActive: _sleepTimerMinutes != null,
          onLoop: toggleLoop,
          onFavorite: toggleFavorite,
          onPlaylist: togglePlaylist,
          onTimer: _showSleepTimerModal,
          downloadButton: isOfflineSession
              ? null
              : DownloadButton(
                  session: _session,
                  size: 24.sp,
                  showBackground: false,
                ),
        ),
      ],
    );
  }

  Widget _buildDismissableScrollView({
    required BoxConstraints constraints,
    required bool isSmallPhone,
    required Widget child,
  }) {
    return Listener(
      onPointerMove: (event) {
        if (!_dismissScrollController.hasClients) return;
        final isAtTop = _dismissScrollController.offset <= 0;
        final isGoingDown = event.delta.dy > 0;

        if ((isAtTop && isGoingDown) || _isDismissDragging) {
          setState(() {
            _dismissDragOffset =
                (_dismissDragOffset + event.delta.dy).clamp(0.0, 500.0);
            _isDismissDragging = _dismissDragOffset > 0;
          });
        }
      },
      onPointerUp: (_) {
        if (!_isDismissDragging) return;

        final threshold = MediaQuery.of(context).size.height * 0.15;

        if (_dismissDragOffset > threshold) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _dismissDragOffset = 0.0;
            _isDismissDragging = false;
          });
        }
      },
      child: SingleChildScrollView(
        controller: _dismissScrollController,
        physics:
            _isDismissDragging ? const NeverScrollableScrollPhysics() : null,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Align(
            alignment: isSmallPhone ? Alignment.topCenter : Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildBlurBackground(AppThemeExtension colors) {
    final localImagePath = _session['_localImagePath'] as String?;
    final hasLocalImage = localImagePath != null && localImagePath.isNotEmpty;
    final hasNetworkImage =
        _backgroundImageUrl != null && _backgroundImageUrl!.isNotEmpty;

    if (!hasLocalImage && !hasNetworkImage) {
      return const SizedBox.shrink();
    }

    Widget imageWidget;

    if (hasLocalImage) {
      final file = File(localImagePath);
      imageWidget = FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: colors.background),
            );
          }
          if (hasNetworkImage) {
            return CachedNetworkImage(
              imageUrl: _backgroundImageUrl!,
              cacheManager: AppCacheManager.instance,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: colors.background),
              errorWidget: (_, __, ___) => Container(color: colors.background),
            );
          }
          return Container(color: colors.background);
        },
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: _backgroundImageUrl!,
        cacheManager: AppCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: colors.background),
        errorWidget: (_, __, ___) => Container(color: colors.background),
      );
    }

    return Positioned.fill(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: imageWidget,
      ),
    );
  }

  Widget _buildDecryptingOverlay(AppThemeExtension colors) {
    return Container(
      color: colors.textPrimary.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48.w,
              height: 48.w,
              child: CircularProgressIndicator(
                color: colors.textOnPrimary,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppLocalizations.of(context).preparing,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: colors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerModal() {
    PlayerModals.showSleepTimer(context, _sleepTimerMinutes, _audioService, (
      minutes,
    ) {
      if (mounted) {
        setState(() {
          _sleepTimerMinutes = minutes;

          if (minutes != null && _totalDuration.inSeconds > 0) {
            final timerSeconds = minutes * 60;
            final audioSeconds = _totalDuration.inSeconds;

            if (timerSeconds > audioSeconds && !_isLooping) {
              _isLooping = true;
              debugPrint(
                '🔁 [Timer] Auto-loop enabled (timer: ${minutes}min > audio: ${audioSeconds ~/ 60}min)',
              );
            }
          }
        });
      }
    });
  }
}
