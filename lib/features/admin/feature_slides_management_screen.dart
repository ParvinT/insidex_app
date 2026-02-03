// lib/features/admin/feature_slides_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/themes/app_theme_extension.dart';
import '../../models/feature_slide_model.dart';
import '../../l10n/app_localizations.dart';

/// Admin screen for managing feature slideshow
/// - Manage image pool (add/remove images)
/// - Manage pages (title, subtitle in 4 languages)
class FeatureSlidesManagementScreen extends StatefulWidget {
  const FeatureSlidesManagementScreen({super.key});

  @override
  State<FeatureSlidesManagementScreen> createState() =>
      _FeatureSlidesManagementScreenState();
}

class _FeatureSlidesManagementScreenState
    extends State<FeatureSlidesManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late TabController _tabController;

  // Data
  FeatureSlidesData? _data;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final doc =
          await _firestore.collection('app_config').doc('feature_slides').get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _data = FeatureSlidesData.fromMap(doc.data()!);
          _isLoading = false;
        });
      } else {
        // Initialize empty document
        const emptyData = FeatureSlidesData();
        await _firestore
            .collection('app_config')
            .doc('feature_slides')
            .set(emptyData.toMap());

        setState(() {
          _data = emptyData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading feature slides: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (_data == null) return;

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('app_config').doc('feature_slides').update({
        ..._data!.toMap(),
        'version': _data!.version + 1,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).changesSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving feature slides: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // =================== IMAGE MANAGEMENT ===================

  Future<void> _pickAndUploadImages() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isSaving = true);

      final List<String> newUrls = [];

      for (final file in result.files) {
        if (file.path == null) continue;

        final fileName =
            'feature_slides/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

        final ref = _storage.ref().child(fileName);

        await ref.putData(
          file.bytes!,
          SettableMetadata(contentType: 'image/${file.extension ?? 'jpeg'}'),
        );

        final url = await ref.getDownloadURL();
        newUrls.add(url);
      }

      setState(() {
        _data = FeatureSlidesData(
          version: _data!.version,
          images: [..._data!.images, ...newUrls],
          pages: _data!.pages,
        );
      });

      await _saveData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                l10n.imagesUploadedSuccessfully(newUrls.length.toString())),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error uploading images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmDelete),
        content: Text(AppLocalizations.of(context).deleteConfirmationMessage),
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

    if (confirmed != true) return;

    try {
      final imageUrl = _data!.images[index];

      // Delete from Storage
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        debugPrint('⚠️ Could not delete from storage: $e');
      }

      // Remove from list
      final updatedImages = List<String>.from(_data!.images)..removeAt(index);

      setState(() {
        _data = FeatureSlidesData(
          version: _data!.version,
          images: updatedImages,
          pages: _data!.pages,
        );
      });

      await _saveData();
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
    }
  }

  // =================== PAGE MANAGEMENT ===================

  void _showPageEditor({FeatureSlidePageModel? existingPage}) {
    final isEditing = existingPage != null;
    final l10n = AppLocalizations.of(context);

    // Controllers
    final titleControllers = {
      'en': TextEditingController(text: existingPage?.title['en'] ?? ''),
      'tr': TextEditingController(text: existingPage?.title['tr'] ?? ''),
      'ru': TextEditingController(text: existingPage?.title['ru'] ?? ''),
      'hi': TextEditingController(text: existingPage?.title['hi'] ?? ''),
    };

    final subtitleControllers = {
      'en': TextEditingController(text: existingPage?.subtitle['en'] ?? ''),
      'tr': TextEditingController(text: existingPage?.subtitle['tr'] ?? ''),
      'ru': TextEditingController(text: existingPage?.subtitle['ru'] ?? ''),
      'hi': TextEditingController(text: existingPage?.subtitle['hi'] ?? ''),
    };

    final orderController = TextEditingController(
      text: existingPage?.order.toString() ?? '${_data!.pages.length + 1}',
    );

    bool isActive = existingPage?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final colors = context.colors;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        Text(
                          isEditing ? l10n.editQuote : l10n.addQuote,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _savePage(
                              existingPage: existingPage,
                              titleControllers: titleControllers,
                              subtitleControllers: subtitleControllers,
                              order: int.tryParse(orderController.text) ?? 0,
                              isActive: isActive,
                            );
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n.save,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order & Active
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: orderController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n.displayOrder,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Row(
                                children: [
                                  Text(
                                    l10n.enabled,
                                    style: GoogleFonts.inter(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Switch(
                                    value: isActive,
                                    onChanged: (v) =>
                                        setModalState(() => isActive = v),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 24.h),

                          // Title Section
                          Text(
                            AppLocalizations.of(context).title,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ..._buildLanguageFields(titleControllers, colors),

                          SizedBox(height: 24.h),

                          // Subtitle Section
                          Text(
                            l10n.subtitleLabel,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ..._buildLanguageFields(
                            subtitleControllers,
                            colors,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildLanguageFields(
    Map<String, TextEditingController> controllers,
    AppThemeExtension colors, {
    int maxLines = 1,
  }) {
    const languages = [
      ('en', '🇬🇧 English'),
      ('tr', '🇹🇷 Türkçe'),
      ('ru', '🇷🇺 Русский'),
      ('hi', '🇮🇳 हिन्दी'),
    ];

    return languages.map((lang) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: TextField(
          controller: controllers[lang.$1],
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: lang.$2,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: colors.backgroundCard,
          ),
        ),
      );
    }).toList();
  }

  void _savePage({
    FeatureSlidePageModel? existingPage,
    required Map<String, TextEditingController> titleControllers,
    required Map<String, TextEditingController> subtitleControllers,
    required int order,
    required bool isActive,
  }) {
    final newPage = FeatureSlidePageModel(
      id: existingPage?.id ?? 'page_${DateTime.now().millisecondsSinceEpoch}',
      title: {
        'en': titleControllers['en']!.text,
        'tr': titleControllers['tr']!.text,
        'ru': titleControllers['ru']!.text,
        'hi': titleControllers['hi']!.text,
      },
      subtitle: {
        'en': subtitleControllers['en']!.text,
        'tr': subtitleControllers['tr']!.text,
        'ru': subtitleControllers['ru']!.text,
        'hi': subtitleControllers['hi']!.text,
      },
      order: order,
      isActive: isActive,
    );

    setState(() {
      final pages = List<FeatureSlidePageModel>.from(_data!.pages);

      if (existingPage != null) {
        final index = pages.indexWhere((p) => p.id == existingPage.id);
        if (index != -1) pages[index] = newPage;
      } else {
        pages.add(newPage);
      }

      _data = FeatureSlidesData(
        version: _data!.version,
        images: _data!.images,
        pages: pages,
      );
    });

    _saveData();
  }

  Future<void> _deletePage(String pageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmDelete),
        content: Text(AppLocalizations.of(context).deleteConfirmationMessage),
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

    if (confirmed != true) return;

    setState(() {
      final pages = List<FeatureSlidePageModel>.from(_data!.pages)
        ..removeWhere((p) => p.id == pageId);

      _data = FeatureSlidesData(
        version: _data!.version,
        images: _data!.images,
        pages: pages,
      );
    });

    _saveData();
  }

  // =================== BUILD UI ===================

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.featureSlides,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.textPrimary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.textPrimary,
          tabs: [
            Tab(text: l10n.featureSlidesImages),
            Tab(text: l10n.pages),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.textPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildImagesTab(colors),
                _buildPagesTab(colors),
              ],
            ),
    );
  }

  Widget _buildImagesTab(AppThemeExtension colors) {
    final l10n = AppLocalizations.of(context);
    final images = _data?.images ?? [];

    return Column(
      children: [
        // Add button
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _pickAndUploadImages,
              icon: _isSaving
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: Text(l10n.addImages),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.textPrimary,
                foregroundColor: colors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ),

        // Image count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(Icons.photo_library,
                  size: 20.sp, color: colors.textSecondary),
              SizedBox(width: 8.w),
              Text(
                '${images.length} ${l10n.featureSlidesImages}',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Images grid
        Expanded(
          child: images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64.sp,
                        color: colors.textSecondary.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        l10n.noImagesYet,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(16.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 16 / 9,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return _buildImageCard(images[index], index, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildImageCard(String url, int index, AppThemeExtension colors) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => Container(
              color: colors.backgroundCard,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.textSecondary,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: colors.backgroundCard,
              child: Icon(
                Icons.broken_image,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),

        // Delete button
        Positioned(
          top: 8.h,
          right: 8.w,
          child: GestureDetector(
            onTap: () => _deleteImage(index),
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Index badge
        Positioned(
          bottom: 8.h,
          left: 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
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

  Widget _buildPagesTab(AppThemeExtension colors) {
    final l10n = AppLocalizations.of(context);
    final pages = _data?.activePages ?? [];

    return Column(
      children: [
        // Add button
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPageEditor(),
              icon: const Icon(Icons.add),
              label: Text(l10n.addQuote),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.textPrimary,
                foregroundColor: colors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ),

        // Pages list
        Expanded(
          child: pages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 64.sp,
                        color: colors.textSecondary.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        l10n.noQuotesYet,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return _buildPageCard(pages[index], colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPageCard(FeatureSlidePageModel page, AppThemeExtension colors) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: page.isActive
              ? Colors.green.withValues(alpha: 0.5)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Order badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: colors.textPrimary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '#${page.order}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.textOnPrimary,
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // Active badge
              if (page.isActive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    AppLocalizations.of(context).active,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ),

              const Spacer(),

              // Edit button
              IconButton(
                onPressed: () => _showPageEditor(existingPage: page),
                icon: Icon(
                  Icons.edit,
                  size: 20.sp,
                  color: colors.textSecondary,
                ),
              ),

              // Delete button
              IconButton(
                onPressed: () => _deletePage(page.id),
                icon: Icon(
                  Icons.delete_outline,
                  size: 20.sp,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Title (English)
          Text(
            page.getTitle('en'),
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 4.h),

          // Subtitle (English)
          Text(
            page.getSubtitle('en'),
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: colors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
