// lib/features/playlist/playlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';
import '../player/audio_player_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/session_card.dart';
import '../../services/session_filter_service.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  VoidCallback? _localeListener;

  late TabController _tabController;
  List<Map<String, dynamic>> _myPlaylistSessions = [];
  List<Map<String, dynamic>> _favoriteSessions = [];
  List<Map<String, dynamic>> _recentSessions = [];
  bool _isLoading = false;

  // Drag to reorder
  bool _isReorderMode = false;
  StreamSubscription? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listenToUserData();
    _loadAllPlaylists();
    _listenToLanguageChanges();
  }

  void _listenToLanguageChanges() {
    context.read<LocaleProvider>().addListener(() {
      if (mounted) {
        _loadAllPlaylists();
      }
    });
  }

  @override
  void dispose() {
    if (_localeListener != null) {
      try {
        context.read<LocaleProvider>().removeListener(_localeListener!);
      } catch (e) {
        debugPrint('Error removing locale listener: $e');
      }
    }
    _userDataSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPlaylists() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ [Playlist] User is NULL!');
        setState(() => _isLoading = false);
        return;
      }

      // Load user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // Load My Playlist
        final playlistIds = List<String>.from(
          userData['playlistSessionIds'] ?? [],
        );

        // Load Favorites
        final favoriteIds = List<String>.from(
          userData['favoriteSessionIds'] ?? [],
        );

        // Load Recent (last 10)
        final recentIds = List<String>.from(
          userData['recentSessionIds'] ?? [],
        ).take(10).toList();
        debugPrint('📋 [Playlist] Recent IDs from Firebase: $recentIds');

        // Fetch sessions for each list
        _myPlaylistSessions =
            await _fetchSessions(playlistIds, fieldName: 'playlistSessionIds');
        _favoriteSessions =
            await _fetchSessions(favoriteIds, fieldName: 'favoriteSessionIds');
        _recentSessions =
            await _fetchSessions(recentIds, fieldName: 'recentSessionIds');
        debugPrint(
            '📋 [Playlist] Recent sessions loaded: ${_recentSessions.length}');
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _listenToUserData() {
    final user = _auth.currentUser;
    if (user == null) return;

    _userDataSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists && mounted) {
        final userData = snapshot.data()!;

        // ID listelerini al
        final playlistIds =
            List<String>.from(userData['playlistSessionIds'] ?? []);
        final favoriteIds =
            List<String>.from(userData['favoriteSessionIds'] ?? []);
        final recentIds = List<String>.from(userData['recentSessionIds'] ?? [])
            .take(10)
            .toList();

        // Session'ları yükle
        final myPlaylist =
            await _fetchSessions(playlistIds, fieldName: 'playlistSessionIds');
        final favorites =
            await _fetchSessions(favoriteIds, fieldName: 'favoriteSessionIds');
        final recent =
            await _fetchSessions(recentIds, fieldName: 'recentSessionIds');

        // State'i güncelle
        if (mounted) {
          setState(() {
            _myPlaylistSessions = myPlaylist;
            _favoriteSessions = favorites;
            _recentSessions = recent;
          });
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSessions(
    List<String> sessionIds, {
    String? fieldName,
  }) async {
    debugPrint('🔍 [Playlist] Fetching sessions for IDs: $sessionIds');
    if (sessionIds.isEmpty) {
      debugPrint('⚠️ [Playlist] Session IDs is EMPTY!');
      return [];
    }

    final sessions = <Map<String, dynamic>>[];
    final invalidIds = <String>[];
    for (String sessionId in sessionIds) {
      try {
        final sessionDoc =
            await _firestore.collection('sessions').doc(sessionId).get();

        if (sessionDoc.exists) {
          final data = sessionDoc.data()!;
          data['id'] = sessionDoc.id;
          sessions.add(data);
          debugPrint('✅ [Playlist] Fetched session: ${sessionDoc.id}');
        } else {
          debugPrint('❌ [Playlist] Session NOT FOUND: $sessionId');
          invalidIds.add(sessionId);
        }
      } catch (e) {
        debugPrint('Error fetching session $sessionId: $e');
      }
    }

    if (invalidIds.isNotEmpty && fieldName != null) {
      _cleanupInvalidIds(invalidIds, fieldName);
    }
    debugPrint('📦 [Playlist] Total fetched: ${sessions.length}');
    final filtered = await SessionFilterService.filterFetchedSessions(sessions);
    debugPrint('🔻 [Playlist] After filter: ${filtered.length}'); // EKLE

    return filtered;
  }

  Future<void> _cleanupInvalidIds(
      List<String> invalidIds, String fieldName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        fieldName: FieldValue.arrayRemove(invalidIds),
      });
      debugPrint(
          '🧹 [Playlist] Cleaned up ${invalidIds.length} invalid IDs from $fieldName');
    } catch (e) {
      debugPrint('❌ [Playlist] Error cleaning up invalid IDs: $e');
    }
  }

  Future<void> _addToPlaylist(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final session = _recentSessions.firstWhere(
        (s) => s['id'] == sessionId,
        orElse: () => _favoriteSessions.firstWhere(
          (s) => s['id'] == sessionId,
          orElse: () => {},
        ),
      );

      if (session.isNotEmpty) {
        setState(() {
          _myPlaylistSessions.add(session);
        });
      }

      await _firestore.collection('users').doc(user.uid).update({
        'playlistSessionIds': FieldValue.arrayUnion([sessionId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).addedToPlaylist),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error adding to playlist: $e');

      setState(() {
        _myPlaylistSessions.removeWhere((s) => s['id'] == sessionId);
      });
    }
  }

  Future<void> _removeFromPlaylist(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'playlistSessionIds': FieldValue.arrayRemove([sessionId]),
      });

      setState(() {
        _myPlaylistSessions.removeWhere((s) => s['id'] == sessionId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).removedFromPlaylist),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error removing from playlist: $e');
    }
  }

  Future<void> _toggleFavorite(
    String sessionId,
    bool isCurrentlyFavorite,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      setState(() {
        if (isCurrentlyFavorite) {
          _favoriteSessions.removeWhere((s) => s['id'] == sessionId);
        } else {
          final session = _myPlaylistSessions.firstWhere(
            (s) => s['id'] == sessionId,
            orElse: () => _recentSessions.firstWhere(
              (s) => s['id'] == sessionId,
              orElse: () => {},
            ),
          );
          if (session.isNotEmpty) {
            _favoriteSessions.add(session);
          }
        }
      });

      if (isCurrentlyFavorite) {
        await _firestore.collection('users').doc(user.uid).update({
          'favoriteSessionIds': FieldValue.arrayRemove([sessionId]),
        });
      } else {
        await _firestore.collection('users').doc(user.uid).update({
          'favoriteSessionIds': FieldValue.arrayUnion([sessionId]),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFavorite
                ? AppLocalizations.of(context).removedFromFavorites
                : AppLocalizations.of(context).addedToFavorites,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');

      setState(() {
        if (!isCurrentlyFavorite) {
          _favoriteSessions.removeWhere((s) => s['id'] == sessionId);
        } else {
          final session = _myPlaylistSessions.firstWhere(
            (s) => s['id'] == sessionId,
            orElse: () => _recentSessions.firstWhere(
              (s) => s['id'] == sessionId,
              orElse: () => {},
            ),
          );
          if (session.isNotEmpty) {
            _favoriteSessions.add(session);
          }
        }
      });
    }
  }

  Future<void> _reorderPlaylist(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    setState(() {
      final item = _myPlaylistSessions.removeAt(oldIndex);
      _myPlaylistSessions.insert(newIndex, item);
    });

    // Update order in Firestore
    final user = _auth.currentUser;
    if (user == null) return;

    final newOrder = _myPlaylistSessions.map((s) => s['id']).toList();

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'playlistSessionIds': newOrder,
      });
    } catch (e) {
      debugPrint('Error reordering playlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tab Bar
            _buildTabBar(),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyPlaylist(),
                        _buildFavorites(),
                        _buildRecentlyPlayed(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                    size: 20.sp,
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).myPlaylists,
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 16.h,
                      colorFilter: ColorFilter.mode(
                        AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit/Reorder button (for My Playlist tab)
              if (_tabController.index == 0)
                GestureDetector(
                  onTap: () {
                    setState(() => _isReorderMode = !_isReorderMode);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _isReorderMode
                          ? AppColors.textPrimary
                          : AppColors.greyLight,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _isReorderMode
                          ? AppLocalizations.of(context).done
                          : AppLocalizations.of(context).edit,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: _isReorderMode
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.greyBorder, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _isReorderMode = false;
          });
        },
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.textPrimary,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                  '${AppLocalizations.of(context).myPlaylist} (${_myPlaylistSessions.length})'),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                  '${AppLocalizations.of(context).favorites} (${_favoriteSessions.length})'),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                  '${AppLocalizations.of(context).recent} (${_recentSessions.length})'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.textPrimary),
    );
  }

  Widget _buildMyPlaylist() {
    if (_myPlaylistSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.queue_music,
        title: AppLocalizations.of(context).noSessionsInPlaylist,
        subtitle: AppLocalizations.of(context).addSessionsToPlaylist,
      );
    }

    if (_isReorderMode) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: EdgeInsets.all(20.w),
        itemCount: _myPlaylistSessions.length,
        onReorder: _reorderPlaylist,
        itemBuilder: (context, index) {
          final session = _myPlaylistSessions[index];
          return _buildReorderableSessionCard(
            key: ValueKey(session['id']),
            session: session,
            index: index,
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _myPlaylistSessions.length,
      itemBuilder: (context, index) {
        final session = _myPlaylistSessions[index];
        final isFavorite = _favoriteSessions.any(
          (s) => s['id'] == session['id'],
        );

        return _buildSessionCard(
          session: session,
          index: index + 1,
          isFavorite: isFavorite,
          onRemove: () => _removeFromPlaylist(session['id']),
          onToggleFavorite: () => _toggleFavorite(session['id'], isFavorite),
        );
      },
    );
  }

  Widget _buildFavorites() {
    if (_favoriteSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: AppLocalizations.of(context).noFavoriteSessions,
        subtitle: AppLocalizations.of(context).markSessionsAsFavorite,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _favoriteSessions.length,
      itemBuilder: (context, index) {
        final session = _favoriteSessions[index];

        return _buildSessionCard(
          session: session,
          index: index + 1,
          isFavorite: true,
          showRemoveButton: false,
          onToggleFavorite: () => _toggleFavorite(session['id'], true),
        );
      },
    );
  }

  Widget _buildRecentlyPlayed() {
    if (_recentSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: AppLocalizations.of(context).noRecentSessions,
        subtitle: AppLocalizations.of(context).sessionsWillAppearHere,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _recentSessions.length,
      itemBuilder: (context, index) {
        final session = _recentSessions[index];
        final isFavorite = _favoriteSessions.any(
          (s) => s['id'] == session['id'],
        );
        final isInPlaylist = _myPlaylistSessions.any(
          (s) => s['id'] == session['id'],
        );

        return _buildSessionCard(
          session: session,
          isFavorite: isFavorite,
          showRemoveButton: false,
          showAddToPlaylist: !isInPlaylist,
          onToggleFavorite: () => _toggleFavorite(session['id'], isFavorite),
          onAddToPlaylist: () => _addToPlaylist(session['id']),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 300.h,
          maxWidth: 600.w,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(icon, size: 50.sp, color: AppColors.textSecondary),
                ),
                SizedBox(height: 24.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required Map<String, dynamic> session,
    int? index,
    bool isFavorite = false,
    bool showRemoveButton = true,
    bool showAddToPlaylist = false,
    VoidCallback? onRemove,
    VoidCallback? onToggleFavorite,
    VoidCallback? onAddToPlaylist,
  }) {
    return SessionCard(
      session: session,
      index: index,
      showIndex: index != null,
      isFavorite: isFavorite,
      showFavoriteButton: onToggleFavorite != null,
      showRemoveButton: showRemoveButton && onRemove != null,
      showAddToPlaylist: showAddToPlaylist && onAddToPlaylist != null,
      onToggleFavorite: onToggleFavorite,
      onRemove: onRemove,
      onAddToPlaylist: onAddToPlaylist,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(sessionData: session),
          ),
        );
      },
    );
  }

  Widget _buildReorderableSessionCard({
    required Key key,
    required Map<String, dynamic> session,
    required int index,
  }) {
    final isFavorite = _favoriteSessions.any((s) => s['id'] == session['id']);

    return ReorderableDragStartListener(
      key: key,
      index: index,
      child: SessionCard(
        session: session,
        index: index + 1,
        showIndex: true,
        isFavorite: isFavorite,
        showFavoriteButton: true,
        showRemoveButton: true,
        onToggleFavorite: () => _toggleFavorite(session['id'], isFavorite),
        onRemove: () => _removeFromPlaylist(session['id']),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AudioPlayerScreen(sessionData: session),
            ),
          );
        },
      ),
    );
  }
}
