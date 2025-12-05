// lib/features/admin/category_images_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../services/storage_service.dart';
import '../../l10n/app_localizations.dart';

class CategoryImagesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryImagesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryImagesScreen> createState() => _CategoryImagesScreenState();
}

class _CategoryImagesScreenState extends State<CategoryImagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final doc = await _firestore
          .collection('categories')
          .doc(widget.categoryId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final images = data?['backgroundImages'];

        if (images is List) {
          setState(() {
            _images = List<String>.from(images);
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading images: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      // Check max limit
      if (_images.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).maximum10ImagesAllowed),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isLoading = true);

        int successCount = 0;
        int failCount = 0;

        for (final file in result.files) {
          // Check if we've hit the limit
          if (_images.length >= 10) {
            failCount += (result.files.length - successCount - failCount);
            break;
          }

          // Upload to Firebase Storage
          final downloadUrl = await StorageService.uploadCategoryImage(
            categoryId: widget.categoryId,
            file: file,
          );

          if (downloadUrl != null) {
            setState(() {
              _images.add(downloadUrl);
            });
            successCount++;
          } else {
            failCount++;
          }
        }

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)
                        .imagesUploadedSuccessfully(successCount) +
                    (failCount > 0
                        ? ', ${AppLocalizations.of(context).imagesFailed(failCount)}'
                        : ''),
              ),
              backgroundColor: successCount > 0 ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorUploadingImages),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    try {
      final imageUrl = _images[index];

      // Delete from Storage
      await StorageService.deleteCategoryImage(imageUrl);

      setState(() {
        _images.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).imageRemoved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error removing image: $e');
    }
  }

  Future<void> _saveImages() async {
    try {
      // Validate: at least 1 image
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).pleaseAddAtLeastOneImage),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Update Firestore
      await _firestore.collection('categories').doc(widget.categoryId).update({
        'backgroundImages': _images,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).imagesSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorSavingImages),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackgroundCard,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).manageImages,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.categoryName,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.textPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).categoryImagesInfo,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Images grid
                Expanded(
                  child:
                      _images.isEmpty ? _buildEmptyState() : _buildImagesGrid(),
                ),

                // Bottom buttons
                _buildBottomButtons(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 80.sp,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).noImagesYet,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).addImagesToGetStarted,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: 1.2,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return _buildImageCard(_images[index], index);
      },
    );
  }

  Widget _buildImageCard(String url, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.greyBorder, width: 2),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Delete Button
        Positioned(
          top: 8.h,
          right: 8.w,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
        ),
        // Index Badge
        Positioned(
          bottom: 8.h,
          left: 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '#${index + 1}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Add Images Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(AppLocalizations.of(context).addImages),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.textPrimary, width: 2),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Save Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _images.isEmpty ? null : _saveImages,
              icon: const Icon(Icons.save),
              label: Text(AppLocalizations.of(context).saveImages),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
