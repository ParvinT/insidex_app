// lib/features/admin/session_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../services/session_localization_service.dart';
import '../../services/language_helper_service.dart';
import 'add_session_screen.dart';

class SessionManagementScreen extends StatefulWidget {
  const SessionManagementScreen({super.key});

  @override
  State<SessionManagementScreen> createState() =>
      _SessionManagementScreenState();
}

class _SessionManagementScreenState extends State<SessionManagementScreen> {
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();

    setState(() {
      _categories = ['All'] +
          snapshot.docs.map((doc) => doc.data()['title'] as String).toList();
    });
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: Text(
          'Session Management',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primaryGold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddSessionScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 50.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: AppColors.greyLight,
                    selectedColor: AppColors.primaryGold,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),

          // Sessions List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategory == 'All'
                  ? FirebaseFirestore.instance
                      .collection('sessions')
                      .orderBy('createdAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('sessions')
                      .where('category', isEqualTo: _selectedCategory)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data!.docs;

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_music,
                          size: 64.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No sessions found',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(20.w),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session =
                        sessions[index].data() as Map<String, dynamic>;
                    final docId = sessions[index].id;
                    session['id'] = docId;

                    return FutureBuilder<String>(
                      future: _getDisplayTitle(session),
                      builder: (context, titleSnapshot) {
                        // 🆕 Get display title with session number
                        final displayTitle = titleSnapshot.data ?? 'Loading...';

                        return Card(
                          margin: EdgeInsets.only(bottom: 16.h),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Emoji
                                    Text(
                                      session['emoji'] ?? '🎵',
                                      style: TextStyle(fontSize: 32.sp),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 🆕 Title with session number
                                          Text(
                                            displayTitle,
                                            style: GoogleFonts.inter(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          // Category
                                          Text(
                                            session['category'] ??
                                                'Uncategorized',
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddSessionScreen(
                                                sessionToEdit: {
                                                  ...session,
                                                  'id': docId
                                                },
                                              ),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          _deleteSession(docId);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Description (from localized content)
                                FutureBuilder<String>(
                                  future: _getDisplayDescription(session),
                                  builder: (context, descSnapshot) {
                                    return Text(
                                      descSnapshot.data ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                                SizedBox(height: 12.h),
                                // Language availability badges
                                _buildLanguageBadges(session),
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

  // 🆕 Get display title with session number
  Future<String> _getDisplayTitle(Map<String, dynamic> session) async {
    final currentLanguage = await LanguageHelperService.getCurrentLanguage();
    final localizedContent = SessionLocalizationService.getLocalizedContent(
        session, currentLanguage);

    // Build title with session number if exists
    final sessionNumber = session['sessionNumber'];
    if (sessionNumber != null) {
      return '№$sessionNumber — ${localizedContent.title}';
    }

    return localizedContent.title;
  }

  // 🆕 Get display description
  Future<String> _getDisplayDescription(Map<String, dynamic> session) async {
    final currentLanguage = await LanguageHelperService.getCurrentLanguage();
    final localizedContent = SessionLocalizationService.getLocalizedContent(
        session, currentLanguage);

    return localizedContent.description;
  }

  // 🆕 Build language availability badges
  Widget _buildLanguageBadges(Map<String, dynamic> session) {
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
            color: AppColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: AppColors.primaryGold.withOpacity(0.3),
            ),
          ),
          child: Text(
            lang.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGold,
            ),
          ),
        );
      }).toList(),
    );
  }
}
