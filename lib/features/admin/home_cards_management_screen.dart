// lib/features/admin/home_cards_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/storage_service.dart';
import '../../l10n/app_localizations.dart';

/// Simplified Home Cards Management Screen
/// Admin can only manage images and enable/disable cards
class HomeCardsManagementScreen extends StatefulWidget {
  const HomeCardsManagementScreen({super.key});

  @override
  State<HomeCardsManagementScreen> createState() =>
      _HomeCardsManagementScreenState();
}

class _HomeCardsManagementScreenState extends State<HomeCardsManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Predefined cards with their properties
  List<Map<String, dynamic>> _getPredefinedCards() {
    final l10n = AppLocalizations.of(context);
    return [
      {
        'id': 'all_subliminals',
        'title': l10n.allSubliminals,
        'icon': Icons.music_note,
        'navigateTo': 'categories',
        'description': l10n.browseAllSubliminals,
      },
      {
        'id': 'your_playlist',
        'title': l10n.yourPlaylist,
        'icon': Icons.playlist_play,
        'navigateTo': 'playlist',
        'description': l10n.yourPersonalizedCollection,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCards();
    });
  }

  /// Initialize cards in Firestore if they don't exist
  Future<void> _initializeCards() async {
    try {
      final cards = _getPredefinedCards();
      for (final card in cards) {
        final doc =
            await _firestore.collection('home_cards').doc(card['id']).get();

        if (!doc.exists) {
          // Create card with default values
          await _firestore.collection('home_cards').doc(card['id']).set({
            'enabled': true,
            'images': [],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing cards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final predefinedCards = _getPredefinedCards();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).homeCardsManagement,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20.w),
        itemCount: predefinedCards.length,
        itemBuilder: (context, index) {
          final cardInfo = predefinedCards[index];
          return _buildCardManager(cardInfo);
        },
      ),
    );
  }

  Widget _buildCardManager(Map<String, dynamic> cardInfo) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('home_cards').doc(cardInfo['id']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard(cardInfo, snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return _buildLoadingCard(cardInfo);
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final enabled = data?['enabled'] ?? false;
        final images = List<String>.from(data?['images'] ?? []);

        return Container(
          margin: EdgeInsets.only(bottom: 24.h),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: enabled
                  ? AppColors.primaryGold.withOpacity(0.3)
                  : AppColors.greyBorder,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      cardInfo['icon'],
                      color: AppColors.primaryGold,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardInfo['title'],
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          cardInfo['description'],
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Enable/Disable Switch
                  Column(
                    children: [
                      Switch(
                        value: enabled,
                        onChanged: (value) =>
                            _toggleCard(cardInfo['id'], value),
                        activeColor: AppColors.primaryGold,
                      ),
                      Text(
                        enabled
                            ? AppLocalizations.of(context).active
                            : AppLocalizations.of(context).inactive,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: enabled ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              Divider(color: AppColors.greyBorder.withOpacity(0.5)),
              SizedBox(height: 20.h),

              // Images Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).backgroundImages,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        AppLocalizations.of(context)
                            .imagesRandomRotation(images.length.toString()),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showImageManager(cardInfo['id'], images),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(AppLocalizations.of(context).manage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                    ),
                  ),
                ],
              ),

              if (images.isNotEmpty) ...[
                SizedBox(height: 16.h),
                SizedBox(
                  height: 100.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return _buildImageThumbnail(
                        images[index],
                        cardInfo['id'],
                        index,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageThumbnail(String url, String cardId, int index) {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      width: 100.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.greyBorder),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoadingCard(Map<String, dynamic> cardInfo) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Row(
        children: [
          Icon(cardInfo['icon'], color: AppColors.textSecondary, size: 28.sp),
          SizedBox(width: 16.w),
          Text(
            '${AppLocalizations.of(context).loadingText} ${cardInfo['title']}...',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Map<String, dynamic> cardInfo, String error) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context).errorLoadingCard}: ${cardInfo['title']}',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCard(String cardId, bool enabled) async {
    try {
      await _firestore.collection('home_cards').doc(cardId).update({
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? AppLocalizations.of(context).cardEnabled
                : AppLocalizations.of(context).cardDisabled),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageManager(String cardId, List<String> currentImages) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageManagerScreen(
          cardId: cardId,
          currentImages: currentImages,
        ),
      ),
    );
  }
}

/// Image Manager Screen
class ImageManagerScreen extends StatefulWidget {
  final String cardId;
  final List<String> currentImages;

  const ImageManagerScreen({
    super.key,
    required this.cardId,
    required this.currentImages,
  });

  @override
  State<ImageManagerScreen> createState() => _ImageManagerScreenState();
}

class _ImageManagerScreenState extends State<ImageManagerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.currentImages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).manageImages,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_images.isNotEmpty)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveImages,
              icon: const Icon(Icons.save),
              label: Text(AppLocalizations.of(context).save),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGold,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Banner
                Container(
                  margin: EdgeInsets.all(20.w),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primaryGold.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryGold,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .randomBackgroundImages,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              AppLocalizations.of(context).addImagesInfo,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Upload Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(
                        AppLocalizations.of(context).addImages,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Images Grid
                Expanded(
                  child: _images.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: EdgeInsets.all(20.w),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 16.h,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return _buildImageCard(_images[index], index);
                          },
                        ),
                ),
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
            Icons.photo_library_outlined,
            size: 80.sp,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).noImagesYet,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).addImagesToGetStarted,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
                    color: Colors.black.withOpacity(0.2),
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
              color: Colors.black.withOpacity(0.7),
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

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isLoading = true);

        int successCount = 0;
        int failCount = 0;

        for (final file in result.files) {
          // Upload to Firebase Storage
          final downloadUrl = await StorageService.uploadHomeCardImage(
            cardId: widget.cardId,
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
                '$successCount ${AppLocalizations.of(context).imagesUploaded}' +
                    (failCount > 0
                        ? ', $failCount ${AppLocalizations.of(context).failed}'
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
            content: Text(
                '${AppLocalizations.of(context).errorUploadingImages}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).imageRemoved),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveImages() async {
    if (_images.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseAddAtLeast3Images),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_images.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).maximum10ImagesAllowed),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await _firestore.collection('home_cards').doc(widget.cardId).update({
        'images': _images,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).imagesSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context).errorSavingImages}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
