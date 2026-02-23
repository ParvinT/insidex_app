// lib/features/admin/session_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category_model.dart';
import '../../services/category/category_service.dart';
import '../../services/storage_service.dart';
import 'add_session_screen.dart';
import 'widgets/admin_search_bar.dart';
import 'services/admin_search_service.dart';

class SessionManagementScreen extends StatefulWidget {
  const SessionManagementScreen({super.key});

  @override
  State<SessionManagementScreen> createState() =>
      _SessionManagementScreenState();
}

class _SessionManagementScreenState extends State<SessionManagementScreen> {
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  final CategoryService _categoryService = CategoryService();

  // Search
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final AdminSearchService _adminSearchService = AdminSearchService();
  String _selectedGenderFilter = 'all';

  // Pagination
  List<Map<String, dynamic>> _sessions = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSessions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreSessions();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await _categoryService.getAllCategories(forceRefresh: true);

      categories.sort((a, b) {
        final nameA = a.getName('en').toLowerCase();
        final nameB = b.getName('en').toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _categories = categories;
      });

      debugPrint('✅ Loaded ${categories.length} categories for admin panel');
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      setState(() {
        _categories = [];
      });
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _sessions = [];
      _lastDocument = null;
      _hasMore = true;
      _isInitialLoad = true;
    });
    await _loadMoreSessions();
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query;

      if (_searchQuery.isNotEmpty) {
        // Search mode: fetch matching sessions
        final results = await _adminSearchService.searchSessions(_searchQuery);
        setState(() {
          _sessions = results;
          _hasMore = false;
          _isLoading = false;
          _isInitialLoad = false;
        });
        return;
      }

      // Normal mode: paginated query with gender filter
      if (_selectedCategoryId != null && _selectedGenderFilter != 'all') {
        query = FirebaseFirestore.instance
            .collection('sessions')
            .where('categoryId', isEqualTo: _selectedCategoryId)
            .where('gender', isEqualTo: _selectedGenderFilter)
            .orderBy('sessionNumber')
            .limit(_pageSize);
      } else if (_selectedCategoryId != null) {
        query = FirebaseFirestore.instance
            .collection('sessions')
            .where('categoryId', isEqualTo: _selectedCategoryId)
            .orderBy('sessionNumber')
            .limit(_pageSize);
      } else if (_selectedGenderFilter != 'all') {
        query = FirebaseFirestore.instance
            .collection('sessions')
            .where('gender', isEqualTo: _selectedGenderFilter)
            .orderBy('sessionNumber')
            .limit(_pageSize);
      } else {
        query = FirebaseFirestore.instance
            .collection('sessions')
            .orderBy('sessionNumber')
            .limit(_pageSize);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
          _isInitialLoad = false;
        });
        return;
      }

      final newSessions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      final filtered = newSessions;

      setState(() {
        _sessions.addAll(filtered);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading sessions: $e');
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteSession),
        content: Text(AppLocalizations.of(context).deleteSessionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context).delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete storage files
        await StorageService.deleteSessionFiles(sessionId);
        // Delete Firestore document
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .delete();

        setState(() {
          _sessions.removeWhere((s) => s['id'] == sessionId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context).sessionDeletedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getDisplayTitleSync(Map<String, dynamic> session) {
    final sessionNum = session['sessionNumber']?.toString() ?? '';

    // Get current device locale
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final currentLang = locale.languageCode;

    // Try to get title from content
    if (session['content'] is Map) {
      final content = session['content'] as Map<String, dynamic>;
      // Try current language first, then fallback order
      final langOrder = [currentLang, 'en', 'ru', 'tr', 'hi'];
      for (final lang in langOrder) {
        if (content[lang] is Map) {
          final title = (content[lang] as Map)['title']?.toString() ?? '';
          if (title.isNotEmpty) {
            return sessionNum.isNotEmpty ? '#$sessionNum $title' : title;
          }
        }
      }
    }

    // Fallback to old structure
    final oldTitle = session['title']?.toString() ?? 'Untitled';
    return sessionNum.isNotEmpty ? '#$sessionNum $oldTitle' : oldTitle;
  }

  String _getCategoryName(String? categoryId) {
    final l10n = AppLocalizations.of(context);

    if (categoryId == null || _categories.isEmpty) {
      return l10n.uncategorized;
    }

    try {
      final category = _categories.firstWhere((cat) => cat.id == categoryId);
      return category.getName('en');
    } catch (e) {
      return l10n.uncategorized;
    }
  }

  Widget _buildLanguageBadges(
      Map<String, dynamic> session, AppThemeExtension colors) {
    final audioUrls = session['subliminal']?['audioUrls'] as Map?;
    final imageUrls = session['backgroundImages'] as Map?;

    final hasAudio = <String>[];
    final hasImage = <String>[];

    for (final lang in ['en', 'tr', 'ru', 'hi']) {
      if (audioUrls?[lang] != null && audioUrls![lang].toString().isNotEmpty) {
        hasAudio.add(lang);
      }
      if (imageUrls?[lang] != null && imageUrls![lang].toString().isNotEmpty) {
        hasImage.add(lang);
      }
    }

    return Row(
      children: [
        if (hasAudio.isNotEmpty) ...[
          Icon(Icons.audiotrack, size: 14.sp, color: Colors.green),
          SizedBox(width: 4.w),
          Text(
            hasAudio.join(', ').toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 12.w),
        ],
        if (hasImage.isNotEmpty) ...[
          Icon(Icons.image, size: 14.sp, color: Colors.blue),
          SizedBox(width: 4.w),
          Text(
            hasImage.join(', ').toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderChip(
      String value, String label, AppThemeExtension colors) {
    final isSelected = _selectedGenderFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedGenderFilter = selected ? value : 'all';
          });
          _loadSessions();
        },
        backgroundColor: colors.greyLight,
        selectedColor: colors.textPrimary,
        labelStyle: TextStyle(
          color: isSelected ? colors.textOnPrimary : colors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).sessionManagement,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: colors.textPrimary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddSessionScreen()),
              );
              _loadCategories();
              _loadSessions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: AdminSearchBar(
              controller: _searchController,
              onSearchChanged: (query) {
                setState(() => _searchQuery = query);
                _loadSessions();
              },
              onClear: () {
                setState(() => _searchQuery = '');
                _loadSessions();
              },
            ),
          ),

          // Category Filter
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: ChoiceChip(
                      label: Text(AppLocalizations.of(context).all),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        setState(() => _selectedCategoryId = null);
                        _loadSessions();
                      },
                      backgroundColor: colors.greyLight,
                      selectedColor: colors.textPrimary,
                      labelStyle: TextStyle(
                        color: _selectedCategoryId == null
                            ? colors.textOnPrimary
                            : colors.textPrimary,
                      ),
                    ),
                  );
                }

                final category = _categories[index - 1];
                final isSelected = _selectedCategoryId == category.id;

                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: ChoiceChip(
                    label: Text(category.getName('en')),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = isSelected ? null : category.id;
                      });
                      _loadSessions();
                    },
                    backgroundColor: colors.greyLight,
                    selectedColor: colors.textPrimary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colors.textOnPrimary
                          : colors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),

          // Gender Filter
          Container(
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            margin: EdgeInsets.only(bottom: 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGenderChip(
                      'all', '⚥ ${AppLocalizations.of(context).all}', colors),
                  _buildGenderChip(
                      'male', '♂ ${AppLocalizations.of(context).male}', colors),
                  _buildGenderChip('female',
                      '♀ ${AppLocalizations.of(context).female}', colors),
                  _buildGenderChip('both',
                      '⚥ ${AppLocalizations.of(context).genderBoth}', colors),
                ],
              ),
            ),
          ),

          // Session count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            child: Row(
              children: [
                Text(
                  '${_sessions.length} sessions loaded',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_isLoading && !_isInitialLoad)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),

          // Sessions List
          Expanded(
            child: _isInitialLoad
                ? Center(
                    child: CircularProgressIndicator(color: colors.textPrimary))
                : _sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.library_music,
                              size: 64.sp,
                              color: colors.textSecondary,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? AppLocalizations.of(context).noResultsFound
                                  : AppLocalizations.of(context)
                                      .noSessionsFound,
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSessions,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(20.w),
                          itemCount: _sessions.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Loading indicator at bottom
                            if (index == _sessions.length) {
                              return Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              );
                            }

                            final session = _sessions[index];
                            final docId = session['id'] as String;
                            final displayTitle = _getDisplayTitleSync(session);
                            final gender =
                                session['gender'] as String? ?? 'both';

                            return Card(
                              margin: EdgeInsets.only(bottom: 12.h),
                              color: colors.backgroundCard,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                side: BorderSide(
                                    color: colors.border, width: 0.5),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Gender icon
                                        Text(
                                          gender == 'male'
                                              ? '♂'
                                              : gender == 'female'
                                                  ? '♀'
                                                  : '⚥',
                                          style: TextStyle(fontSize: 18.sp),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayTitle,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.textPrimary,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                _getCategoryName(
                                                    session['categoryId']),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.sp,
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text(
                                                  AppLocalizations.of(context)
                                                      .edit),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                AppLocalizations.of(context)
                                                    .delete,
                                                style: const TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddSessionScreen(
                                                    sessionToEdit: session,
                                                  ),
                                                ),
                                              );
                                              _loadCategories();
                                              _loadSessions();
                                            } else if (value == 'delete') {
                                              _deleteSession(docId);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    _buildLanguageBadges(session, colors),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
