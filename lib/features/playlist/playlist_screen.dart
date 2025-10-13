// lib/features/playlist/playlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../player/audio_player_screen.dart';
import '../../l10n/app_localizations.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPlaylists() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
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

        // Fetch sessions for each list
        _myPlaylistSessions = await _fetchSessions(playlistIds);
        _favoriteSessions = await _fetchSessions(favoriteIds);
        _recentSessions = await _fetchSessions(recentIds);
      }
    } catch (e) {
      print('Error loading playlists: $e');
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
        final myPlaylist = await _fetchSessions(playlistIds);
        final favorites = await _fetchSessions(favoriteIds);
        final recent = await _fetchSessions(recentIds);

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
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return [];

    final sessions = <Map<String, dynamic>>[];
    for (String sessionId in sessionIds) {
      try {
        final sessionDoc =
            await _firestore.collection('sessions').doc(sessionId).get();

        if (sessionDoc.exists) {
          final data = sessionDoc.data()!;
          data['id'] = sessionDoc.id;
          sessions.add(data);
        }
      } catch (e) {
        print('Error fetching session $sessionId: $e');
      }
    }
    return sessions;
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
      print('Error adding to playlist: $e');

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
      print('Error removing from playlist: $e');
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
      print('Error toggling favorite: $e');

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
      print('Error reordering playlist: $e');
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
                color: Colors.black.withOpacity(0.03),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(sessionData: session),
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
            // Image Section with Actions
            Container(
              height: 180.h,
              child: Stack(
                children: [
                  // Background Image or Gradient
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    child: session['backgroundImage'] != null &&
                            session['backgroundImage'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: session['backgroundImage'],
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
                          )
                        : Container(
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

                  // Dark overlay for better contrast
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  // Play Button
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

                  // Action Buttons (Top Right)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Row(
                      children: [
                        // Favorite Button
                        if (onToggleFavorite != null)
                          _buildActionButton(
                            icon: isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorite ? Colors.redAccent : Colors.white,
                            onTap: onToggleFavorite,
                          ),

                        if (onToggleFavorite != null &&
                            (showRemoveButton || showAddToPlaylist))
                          SizedBox(width: 8.w),

                        // Remove from Playlist
                        if (showRemoveButton && onRemove != null)
                          _buildActionButton(
                            icon: Icons.remove_circle_outline,
                            color: Colors.white,
                            onTap: onRemove,
                          ),

                        // Add to Playlist
                        if (showAddToPlaylist && onAddToPlaylist != null)
                          _buildActionButton(
                            icon: Icons.playlist_add,
                            color: Colors.white,
                            onTap: onAddToPlaylist,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session['title'] ??
                              AppLocalizations.of(context).untitledSession,
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.w),
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
                          session['category'] ??
                              AppLocalizations.of(context).general,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableSessionCard({
    required Key key,
    required Map<String, dynamic> session,
    required int index,
  }) {
    return ReorderableDragStartListener(
      key: key,
      index: index,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.textPrimary, // Siyaha değiştirildi
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Siyah gölge
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Drag handle
              Icon(
                Icons.drag_handle,
                color: AppColors.textPrimary, // Siyah
                size: 24.sp,
              ),
              SizedBox(width: 12.w),

              // Index
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['title'] ?? AppLocalizations.of(context).untitled,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp, // Biraz küçültüldü
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      session['category'] ??
                          AppLocalizations.of(context).general,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12.w), // Ekstra boşluk
              // Remove button
              GestureDetector(
                onTap: () => _removeFromPlaylist(session['id']),
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18.sp,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
