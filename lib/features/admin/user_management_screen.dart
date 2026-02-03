// lib/features/admin/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/admin_search_bar.dart';
import 'services/admin_search_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<QueryDocumentSnapshot> _users = [];
  bool _isLoading = true;

  // Search
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final AdminSearchService _adminSearchService = AdminSearchService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _users = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  List<QueryDocumentSnapshot> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;

    return _adminSearchService.filterUsersLocally(_users, _searchQuery);
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
          'User Management',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
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

          // User List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUsers,
              child: _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: colors.textPrimary))
                  : _filteredUsers.isEmpty
                      ? _buildEmptyState(colors)
                      : ListView.builder(
                          padding: EdgeInsets.all(20.w),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index].data()
                                as Map<String, dynamic>;

                            return Card(
                              margin: EdgeInsets.only(bottom: 12.h),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: user['isPremium'] == true
                                      ? colors.textPrimary
                                      : colors.greyLight,
                                  child: Text(
                                    user['name']
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        'U',
                                    style: TextStyle(
                                      color: user['isPremium'] == true
                                          ? colors.textOnPrimary
                                          : colors.textPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user['name'] ?? 'Unknown User',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  user['email'] ?? '',
                                  style: GoogleFonts.inter(fontSize: 12.sp),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (user['isPremium'] == true)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.textPrimary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          'PRO',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    SizedBox(width: 8.w),
                                    if (user['isAdmin'] == true)
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.red,
                                        size: 20.sp,
                                      )
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

  Widget _buildEmptyState(AppThemeExtension colors) {
    final isSearching = _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.people_outline,
            size: 80.sp,
            color: colors.greyMedium,
          ),
          SizedBox(height: 16.h),
          Text(
            isSearching
                ? AppLocalizations.of(context).noResultsFound
                : 'No users found',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          if (isSearching) ...[
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
}
