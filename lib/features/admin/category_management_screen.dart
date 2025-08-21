// lib/features/admin/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _categoryController = TextEditingController();
  final _emojiController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: Text(
          'Category Management',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Add Category Section
          Container(
            padding: EdgeInsets.all(20.w),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      hintText: 'Category name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 60.w,
                  child: TextField(
                    controller: _emojiController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '😴',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: _addCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  ),
                  child: Text('Add'),
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .orderBy('order', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(20.w),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category =
                        categories[index].data() as Map<String, dynamic>;
                    final docId = categories[index].id;

                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: ListTile(
                        leading: Text(
                          category['emoji'] ?? '📁',
                          style: TextStyle(fontSize: 24.sp),
                        ),
                        title: Text(
                          category['title'] ?? 'Unnamed',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text('Order: ${category['order'] ?? 0}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(docId),
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

  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty) return;

    final categoriesCount =
        await FirebaseFirestore.instance.collection('categories').count().get();

    await FirebaseFirestore.instance.collection('categories').add({
      'title': _categoryController.text.trim(),
      'emoji': _emojiController.text.isEmpty ? '📁' : _emojiController.text,
      'order': categoriesCount.count,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _categoryController.clear();
    _emojiController.clear();
  }

  Future<void> _deleteCategory(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category'),
        content: Text(
            'Are you sure? This will NOT delete sessions in this category.'),
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
          .collection('categories')
          .doc(docId)
          .delete();
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _emojiController.dispose();
    super.dispose();
  }
}
