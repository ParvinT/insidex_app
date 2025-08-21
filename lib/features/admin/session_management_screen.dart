// lib/features/admin/session_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
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
            icon: Icon(Icons.add_circle, color: AppColors.primaryGold),
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
          Container(
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
                  return Center(child: CircularProgressIndicator());
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

                    return Card(
                      margin: EdgeInsets.only(bottom: 16.h),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
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
                                      Text(
                                        session['title'] ?? 'Untitled',
                                        style: GoogleFonts.inter(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        session['category'] ?? 'Uncategorized',
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
                                    PopupMenuItem(
                                      child: Text('Edit'),
                                      value: 'edit',
                                    ),
                                    PopupMenuItem(
                                      child: Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                      value: 'delete',
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
                            Text(
                              session['description'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Icon(Icons.play_circle,
                                    size: 16.sp,
                                    color: AppColors.textSecondary),
                                SizedBox(width: 4.w),
                                Text(
                                  '${session['playCount'] ?? 0} plays',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Icon(Icons.star,
                                    size: 16.sp, color: Colors.amber),
                                SizedBox(width: 4.w),
                                Text(
                                  '${session['rating'] ?? 0.0}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _deleteSession(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Session'),
        content: Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(docId)
          .delete();
    }
  }
}
