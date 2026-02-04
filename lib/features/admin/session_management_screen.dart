// lib/features/admin/session_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../services/session_localization_service.dart';
import '../../services/language_helper_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      // Admin panel - get ALL categories (not filtered by language)
      final categories =
          await _categoryService.getAllCategories(forceRefresh: true);

      // Sort by English name for consistency in admin panel
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(AppLocalizations.of(context).deletingSessionAndFiles),
                ],
              ),
              duration: const Duration(seconds: 30),
            ),
          );
        }

        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .delete();
        debugPrint('✅ Session deleted from Firestore: $sessionId');

        await StorageService.deleteSessionFiles(sessionId);
        debugPrint('✅ Session files deleted from Storage: $sessionId');

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context).sessionDeletedSuccessfully),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Error deleting session: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${AppLocalizations.of(context).errorDeletingSession}: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // 🆕 Helper: Get category name from ID
  String _getCategoryName(String? categoryId) {
    final l10n = AppLocalizations.of(context);

    if (categoryId == null || _categories.isEmpty) {
      return l10n.uncategorized;
    }

    try {
      final category = _categories.firstWhere((cat) => cat.id == categoryId);
      return category.getName('en');
    } catch (e) {
      debugPrint('⚠️ Category not found: $categoryId');
      return l10n.uncategorized;
    }
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
              // Refresh categories after returning
              _loadCategories();
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
              },
              onClear: () {
                setState(() => _searchQuery = '');
              },
            ),
          ),
          // Category Filter - Horizontal Scroll
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "All" option
                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: ChoiceChip(
                      label: Text(AppLocalizations.of(context).all),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        setState(() => _selectedCategoryId = null);
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
                        // Toggle: if already selected, deselect (null), else select
                        _selectedCategoryId = isSelected ? null : category.id;
                      });
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

          // Sessions List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategoryId == null
                  ? FirebaseFirestore.instance
                      .collection('sessions')
                      .orderBy('createdAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('sessions')
                      .where('categoryId', isEqualTo: _selectedCategoryId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: colors.textPrimary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64.sp, color: Colors.red),
                        SizedBox(height: 16.h),
                        Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: colors.textPrimary));
                }

                var sessions = snapshot.data!.docs;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  sessions = _adminSearchService.filterSessionsLocally(
                    sessions,
                    _searchQuery,
                  );
                }

                // ✅ Client-side sorting when filtering by category
                if (_selectedCategoryId != null && sessions.isNotEmpty) {
                  sessions = sessions.toList()
                    ..sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;

                      final aTime = aData['createdAt'] as Timestamp?;
                      final bTime = bData['createdAt'] as Timestamp?;

                      if (aTime == null) return 1;
                      if (bTime == null) return -1;

                      return bTime.compareTo(aTime); // descending
                    });
                }

                if (sessions.isEmpty) {
                  return Center(
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
                              : AppLocalizations.of(context).noSessionsFound,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            AppLocalizations.of(context).tryDifferentKeywords,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(20.w),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final sessionDoc = sessions[index];
                    final session = sessionDoc.data() as Map<String, dynamic>;
                    final docId = sessionDoc.id;
                    session['id'] = docId;

                    return FutureBuilder<String>(
                      future: _getDisplayTitle(session),
                      builder: (context, titleSnapshot) {
                        final displayTitle = titleSnapshot.data ??
                            AppLocalizations.of(context).loading;

                        return Card(
                          margin: EdgeInsets.only(bottom: 16.h),
                          color: colors.backgroundPure,
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Session Number Badge
                                    if (session['sessionNumber'] != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.textPrimary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                          border: Border.all(
                                            color: colors.textPrimary
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '№${session['sessionNumber']}',
                                          style: GoogleFonts.inter(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: colors.textSecondary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                        child: Icon(
                                          Icons.music_note,
                                          size: 24.sp,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title
                                          Text(
                                            displayTitle,
                                            style: GoogleFonts.inter(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          // Category Name
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
                                            AppLocalizations.of(context).delete,
                                            style: const TextStyle(
                                                color: Colors.red),
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          // ✅ Navigate to edit screen
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddSessionScreen(
                                                sessionToEdit: {
                                                  ...session,
                                                  'id': docId,
                                                },
                                              ),
                                            ),
                                          );
                                          // Refresh categories after returning
                                          _loadCategories();
                                        } else if (value == 'delete') {
                                          _deleteSession(docId);
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12.h),
                                // Language badges
                                _buildLanguageBadges(session, colors),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Get display title with session number
  Future<String> _getDisplayTitle(Map<String, dynamic> session) async {
    final currentLanguage = await LanguageHelperService.getCurrentLanguage();
    final localizedContent = SessionLocalizationService.getLocalizedContent(
        session, currentLanguage);

    final sessionNumber = session['sessionNumber'];
    if (sessionNumber != null) {
      return '№$sessionNumber — ${localizedContent.title}';
    }

    return localizedContent.title;
  }

  // Build language availability badges
  Widget _buildLanguageBadges(
      Map<String, dynamic> session, AppThemeExtension colors) {
    final availableLanguages =
        SessionLocalizationService.getAvailableLanguages(session);

    if (availableLanguages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: availableLanguages.map((lang) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            lang.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }
}
