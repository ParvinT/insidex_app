// lib/features/playlist/playlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../library/session_detail_screen.dart';
import '../player/audio_player_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllPlaylists();
  }

  @override
  void dispose() {
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

  Future<List<Map<String, dynamic>>> _fetchSessions(
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return [];

    final sessions = <Map<String, dynamic>>[];
    for (String sessionId in sessionIds) {
      try {
        final sessionDoc = await _firestore
            .collection('sessions')
            .doc(sessionId)
            .get();

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
      await _firestore.collection('users').doc(user.uid).update({
        'playlistSessionIds': FieldValue.arrayUnion([sessionId]),
      });

      // Reload playlist
      await _loadAllPlaylists();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to playlist'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error adding to playlist: $e');
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
        const SnackBar(
          content: Text('Removed from playlist'),
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
      if (isCurrentlyFavorite) {
        await _firestore.collection('users').doc(user.uid).update({
          'favoriteSessionIds': FieldValue.arrayRemove([sessionId]),
        });
      } else {
        await _firestore.collection('users').doc(user.uid).update({
          'favoriteSessionIds': FieldValue.arrayUnion([sessionId]),
        });
      }

      await _loadAllPlaylists();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFavorite
                ? 'Removed from favorites'
                : 'Added to favorites',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
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
                  'My Playlists',
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
          if (_tabController.index == 0) ...[
            GestureDetector(
              onTap: () {
                setState(() => _isReorderMode = !_isReorderMode);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: _isReorderMode
                      ? AppColors.textPrimary
                      : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _isReorderMode ? 'Done' : 'Edit',
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
        ],
      ),
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
              child: Text('My Playlist (${_myPlaylistSessions.length})'),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Favorites (${_favoriteSessions.length})'),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Recent (${_recentSessions.length})'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryGold),
    );
  }

  Widget _buildMyPlaylist() {
    if (_myPlaylistSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.queue_music,
        title: 'No Sessions in Playlist',
        subtitle: 'Add sessions to create your perfect healing journey',
      );
    }

    if (_isReorderMode) {
      return ReorderableListView.builder(
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
        title: 'No Favorite Sessions',
        subtitle: 'Mark sessions as favorite to find them quickly',
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
        title: 'No Recent Sessions',
        subtitle: 'Sessions you play will appear here',
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
    // Calculate duration
    final introDuration = session['intro']?['duration'] ?? 0;
    final subliminalDuration = session['subliminal']?['duration'] ?? 0;
    final totalDuration = introDuration + subliminalDuration;

    return GestureDetector(
      onTap: () {
        // Navigate to player
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
          border: Border.all(color: AppColors.greyBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Index or Emoji
              if (index != null) ...[
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      session['emoji'] ?? '$index',
                      style: TextStyle(
                        fontSize: session['emoji'] != null ? 20.sp : 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
              ],

              // Session Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['title'] ?? 'Untitled Session',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        // Category
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            session['category'] ?? 'General',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Duration
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _formatDuration(totalDuration),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorite button
                  if (onToggleFavorite != null) ...[
                    GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? Colors.red.withOpacity(0.1)
                              : AppColors.greyLight,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18.sp,
                          color: isFavorite
                              ? Colors.red
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],

                  // Add to playlist button
                  if (showAddToPlaylist && onAddToPlaylist != null) ...[
                    GestureDetector(
                      onTap: onAddToPlaylist,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.playlist_add,
                          size: 18.sp,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],

                  // Remove button
                  if (showRemoveButton && onRemove != null) ...[
                    GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.remove_circle_outline,
                          size: 18.sp,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w), // Daha fazla boşluk
                  ],

                  // Play button
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
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
    return Container(
      key: key,
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
                    session['title'] ?? 'Untitled',
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
                    session['category'] ?? 'General',
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
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes > 0
        ? '${hours}h ${remainingMinutes}min'
        : '${hours}h';
  }
}
