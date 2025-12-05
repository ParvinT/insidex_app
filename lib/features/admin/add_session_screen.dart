// lib/features/admin/add_session_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_languages.dart';
import '../../services/storage_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category_model.dart';
import '../../services/category/category_service.dart';
import '../../services/category/category_localization_service.dart';
import 'widgets/multi_language_content_section.dart';
import '../../core/constants/app_icons.dart';

class AddSessionScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionToEdit;

  const AddSessionScreen({
    super.key,
    this.sessionToEdit,
  });

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Session metadata controllers
  final _sessionNumberController = TextEditingController();

  // 🆕 Multi-language content controllers (DYNAMIC)
  late final Map<String, Map<String, TextEditingController>>
      _contentControllers;

  // Selected values
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  final CategoryService _categoryService = CategoryService();

  // Language selection
  String _selectedLanguage = AppLanguages.defaultLanguage; // 🆕

  // 🆕 Multi-language file uploads (DYNAMIC)
  late final Map<String, PlatformFile?> _subliminalAudios;
  late final Map<String, PlatformFile?> _backgroundImages;

  // Loading states
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();

    // 🆕 Initialize controllers dynamically
    _contentControllers = {
      for (final lang in AppLanguages.supportedLanguages)
        lang: {
          'title': TextEditingController(),
          'description': TextEditingController(),
          'introTitle': TextEditingController(),
          'introContent': TextEditingController(),
        }
    };

    // 🆕 Initialize file maps dynamically
    _subliminalAudios = {
      for (final lang in AppLanguages.supportedLanguages) lang: null
    };

    _backgroundImages = {
      for (final lang in AppLanguages.supportedLanguages) lang: null
    };

    _loadCategories().then((_) {
      if (widget.sessionToEdit != null) {
        _loadExistingData();
      }
    });
  }

  @override
  void dispose() {
    // Dispose session metadata controllers
    _sessionNumberController.dispose();

    // Dispose all multi-language content controllers
    for (final langControllers in _contentControllers.values) {
      for (final controller in langControllers.values) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      // ✅ Admin panel - get ALL categories (not filtered)
      final categories = await _categoryService.getAllCategories();

      // Sort by English name
      categories.sort((a, b) {
        final nameA = a.getName('en').toLowerCase();
        final nameB = b.getName('en').toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _categories = categories;
      });

      debugPrint('✅ Loaded ${categories.length} categories for admin');
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      setState(() {
        _categories = [];
      });
    }
  }

  void _loadExistingData() {
    final session = widget.sessionToEdit!;

    // Load session number
    if (session['sessionNumber'] != null) {
      _sessionNumberController.text = session['sessionNumber'].toString();
    }

    // Load category with validation
    final categoryId = session['categoryId'];
    if (categoryId != null) {
      // ✅ Check if category still exists
      final categoryExists = _categories.any((cat) => cat.id == categoryId);
      if (categoryExists) {
        setState(() {
          _selectedCategoryId = categoryId;
        });
        debugPrint('✅ Category found: $categoryId');
      } else {
        setState(() {
          _selectedCategoryId = null;
        });
        debugPrint('⚠️ Category not found: $categoryId - setting to null');

        // Show warning to user
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(AppLocalizations.of(context).originalCategoryDeleted),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    }

    // Load multi-language content
    final contentMap = session['content'] as Map<String, dynamic>?;

    if (contentMap != null && contentMap.isNotEmpty) {
      // NEW STRUCTURE: Multi-language content
      for (final lang in AppLanguages.supportedLanguages) {
        // 🆕
        final langContent = contentMap[lang] as Map<String, dynamic>?;

        if (langContent != null) {
          _contentControllers[lang]!['title']!.text =
              langContent['title'] ?? '';
          _contentControllers[lang]!['description']!.text =
              langContent['description'] ?? '';

          final intro = langContent['introduction'] as Map<String, dynamic>?;
          if (intro != null) {
            _contentControllers[lang]!['introTitle']!.text =
                intro['title'] ?? '';
            _contentControllers[lang]!['introContent']!.text =
                intro['content'] ?? '';
          }
        }
      }
    } else {
      // OLD STRUCTURE: Single language (backward compatibility)
      // Load as English content
      _contentControllers['en']!['title']!.text = session['title'] ?? '';
      _contentControllers['en']!['description']!.text =
          session['description'] ?? '';

      final intro = session['introduction'] as Map<String, dynamic>?;
      if (intro != null) {
        _contentControllers['en']!['introTitle']!.text = intro['title'] ?? '';
        _contentControllers['en']!['introContent']!.text =
            intro['content'] ?? '';
      }

      debugPrint('⚠️ Loading old structure session as EN content');
    }
  }

  // =================== FILE PICKER METHODS ===================

  Future<void> _pickSubliminalAudioForLanguage(String languageCode) async {
    try {
      final file = await StorageService.pickAudioFile();
      if (file != null) {
        // Check file size (max 500MB)
        if (!StorageService.validateFileSize(file, 500)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).audioFileTooLarge),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _subliminalAudios[languageCode] = file;
        });
        debugPrint('Subliminal audio selected for $languageCode: ${file.name}');
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).errorSelectingAudio}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickBackgroundImageForLanguage(String languageCode) async {
    try {
      final file = await StorageService.pickImageFile();
      if (file != null) {
        // Check file size (max 10MB)
        if (!StorageService.validateFileSize(file, 10)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).imageFileTooLarge),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _backgroundImages[languageCode] = file;
        });
        debugPrint('Background image selected for $languageCode: ${file.name}');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).errorSelectingImage}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =================== SAVE SESSION ===================

  Future<void> _saveSession() async {
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseSelectCategory),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final hasAnyTitle = _contentControllers.values
        .any((controllers) => controllers['title']!.text.trim().isNotEmpty);

    if (!hasAnyTitle) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseEnterTitleInOneLang),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Session number uniqueness check
    if (_sessionNumberController.text.isNotEmpty) {
      final sessionNumber = int.parse(_sessionNumberController.text.trim());
      final existingSession = await FirebaseFirestore.instance
          .collection('sessions')
          .where('sessionNumber', isEqualTo: sessionNumber)
          .get();

      // Edit modunda kendi ID'sini skip et
      if (existingSession.docs.isNotEmpty) {
        final existingId = existingSession.docs.first.id;
        if (widget.sessionToEdit == null ||
            existingId != widget.sessionToEdit!['id']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '⚠️ ${AppLocalizations.of(context).sessionNumberAlreadyExists}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = AppLocalizations.of(context).startingUpload;
      _uploadProgress = 0;
    });

    try {
      // Generate unique session ID
      final String sessionId = widget.sessionToEdit?['id'] ??
          FirebaseFirestore.instance.collection('sessions').doc().id;

      debugPrint('====== SAVING SESSION ======');
      debugPrint('Session ID: $sessionId');

      // 🆕 Initialize with existing URLs for edit mode
      final Map<String, String> audioUrls = {};
      final Map<String, String> imageUrls = {};
      final Map<String, int> durations = {};

      // 🆕 Load existing URLs if editing
      if (widget.sessionToEdit != null) {
        debugPrint('📦 Edit mode: Loading existing URLs...');

        // Load existing audio URLs
        final existingAudioUrls = widget.sessionToEdit!['subliminal']
            ?['audioUrls'] as Map<String, dynamic>?;
        if (existingAudioUrls != null) {
          existingAudioUrls.forEach((key, value) {
            audioUrls[key] = value.toString();
            debugPrint('  Loaded audio URL for $key: $value');
          });
        }

        // Load existing image URLs
        final existingImageUrls =
            widget.sessionToEdit!['backgroundImages'] as Map<String, dynamic>?;
        if (existingImageUrls != null) {
          existingImageUrls.forEach((key, value) {
            imageUrls[key] = value.toString();
            debugPrint('  Loaded image URL for $key: $value');
          });
        }

        // Load existing durations
        final existingDurations = widget.sessionToEdit!['subliminal']
            ?['durations'] as Map<String, dynamic>?;
        if (existingDurations != null) {
          existingDurations.forEach((key, value) {
            durations[key] = value is int ? value : 0;
          });
        }

        debugPrint(
            '✅ Existing URLs loaded: Audio(${audioUrls.length}), Images(${imageUrls.length})');
      }

      // 🆕 Upload subliminal audios for each supported language
      for (final languageCode in AppLanguages.supportedLanguages) {
        final audioFile = _subliminalAudios[languageCode];

        if (audioFile != null) {
          setState(() {
            _uploadStatus =
                '${AppLocalizations.of(context).uploadingAudio} ($languageCode)';
            _uploadProgress = 0;
          });

          final audioUrl = await StorageService.uploadAudioWithLanguage(
            sessionId: sessionId,
            languageCode: languageCode,
            file: audioFile,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress * 100;
              });
            },
          );

          if (audioUrl == null) {
            throw Exception('Failed to upload $languageCode audio');
          }

          audioUrls[languageCode] = audioUrl;
          debugPrint('✅ $languageCode audio uploaded: $audioUrl');

          // Try to get duration (will be 0 if not available)
          durations[languageCode] =
              await StorageService.getAudioDuration(audioUrl);
        } else {
          // 🆕 No new file → keep existing URL
          debugPrint(
              'ℹ️ $languageCode audio: No new file, keeping existing URL');
        }
      }

      // 🆕 Upload background images for each supported language
      for (final languageCode in AppLanguages.supportedLanguages) {
        final imageFile = _backgroundImages[languageCode];

        if (imageFile != null) {
          // 🆕 New file uploaded → override old URL
          setState(() {
            _uploadStatus =
                '${AppLocalizations.of(context).uploadingImage} ($languageCode)';
            _uploadProgress = 0;
          });

          final imageUrl = await StorageService.uploadImageWithLanguage(
            sessionId: sessionId,
            languageCode: languageCode,
            file: imageFile,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress * 100;
              });
            },
          );

          if (imageUrl == null) {
            throw Exception('Failed to upload $languageCode image');
          }

          imageUrls[languageCode] = imageUrl; // ← Override with new URL
          debugPrint('✅ $languageCode image uploaded: $imageUrl');
        } else {
          // 🆕 No new file → keep existing URL
          debugPrint(
              'ℹ️ $languageCode image: No new file, keeping existing URL');
        }
      }

      setState(() {
        _uploadStatus = AppLocalizations.of(context).savingSessionData;
        _uploadProgress = 100;
      });

      // 🆕 Build multi-language content (DYNAMIC)
      final content = {
        for (final lang in AppLanguages.supportedLanguages)
          lang: {
            'title': _contentControllers[lang]!['title']!.text.trim(),
            'description':
                _contentControllers[lang]!['description']!.text.trim(),
            'introduction': {
              'title': _contentControllers[lang]!['introTitle']!.text.trim(),
              'content':
                  _contentControllers[lang]!['introContent']!.text.trim(),
            },
          }
      };

      // Prepare session data with NEW structure
      final sessionData = {
        'id': sessionId,

        // Session number
        'sessionNumber': _sessionNumberController.text.isNotEmpty
            ? int.parse(_sessionNumberController.text.trim())
            : null,

        'categoryId': _selectedCategoryId,

        // Multi-language content
        'content': content,

        // Multi-language background images
        'backgroundImages': imageUrls,

        // Subliminal with multi-language support
        'subliminal': {
          'audioUrls': audioUrls,
          'durations': durations,
        },

        'playCount': widget.sessionToEdit?['playCount'] ?? 0,
        'rating': widget.sessionToEdit?['rating'] ?? 0.0,
        'createdAt': widget.sessionToEdit != null
            ? widget.sessionToEdit!['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('Saving to Firestore with data: ${sessionData.keys}');

      // Save to Firestore
      if (widget.sessionToEdit != null) {
        // Update existing session
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionToEdit!['id'])
            .update(sessionData);
        debugPrint('Session updated successfully');
      } else {
        // Create new session
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .set(sessionData);
        debugPrint('Session created successfully with ID: $sessionId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).sessionSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
      setState(() {
        _isLoading = false;
        _uploadStatus = 'Error: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).errorSavingSession}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =================== BUILD METHODS ===================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sessionToEdit != null
              ? AppLocalizations.of(context).editSession
              : AppLocalizations.of(context).addNewSession,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading indicator
                  if (_isLoading) _buildUploadProgress(),

                  // Session Number
                  _buildSectionTitle(
                      AppLocalizations.of(context).sessionNumber),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _sessionNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context).sessionNumberLabel,
                      hintText: AppLocalizations.of(context).sessionNumberHint,
                      helperText:
                          AppLocalizations.of(context).sessionNumberHelper,
                      errorText: null,
                      prefixIcon:
                          Icon(Icons.numbers, color: AppColors.textPrimary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide:
                            BorderSide(color: AppColors.textPrimary, width: 2),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 16.sp),
                  ),

                  SizedBox(height: 24.h),

                  // Category Dropdown
                  _buildSectionTitle(AppLocalizations.of(context).category),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).category,
                      prefixIcon: const Icon(Icons.category,
                          color: AppColors.textPrimary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColors.textPrimary,
                          width: 2,
                        ),
                      ),
                    ),
                    hint:
                        Text(AppLocalizations.of(context).pleaseSelectCategory),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: FutureBuilder<String>(
                          future:
                              CategoryLocalizationService.getLocalizedNameAuto(
                                  category),
                          builder: (context, snapshot) {
                            final name =
                                snapshot.data ?? category.getName('en');
                            return Row(
                              children: [
                                SizedBox(
                                  width: 32.w,
                                  height: 32.w,
                                  child: Lottie.asset(
                                    AppIcons.getAnimationPath(
                                      AppIcons.getIconByName(
                                              category.iconName)?['path'] ??
                                          'meditation.json',
                                    ),
                                    fit: BoxFit.contain,
                                    repeat: true,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(child: Text(name)),
                              ],
                            );
                          },
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)
                            .pleaseSelectCategory;
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 32.h),

                  // Multi-Language Content Section (Widget)
                  MultiLanguageContentSection(
                    contentControllers: _contentControllers,
                    selectedLanguage: _selectedLanguage,
                    onLanguageChanged: (lang) =>
                        setState(() => _selectedLanguage = lang),
                    existingAudioUrls: widget.sessionToEdit?['subliminal']
                        ?['audioUrls'],
                    uploadedAudios: _subliminalAudios,
                  ),

                  SizedBox(height: 32.h),

                  // Audio Upload Section
                  _buildSectionTitle(
                      '🎵 ${AppLocalizations.of(context).audioFiles}'),
                  SizedBox(height: 12.h),
                  _buildLanguageTabs(),
                  SizedBox(height: 16.h),
                  _buildFileUploadCard(
                    title:
                        '${AppLocalizations.of(context).subliminalAudio} ($_selectedLanguage)',
                    subtitle: _subliminalAudios[_selectedLanguage] != null
                        ? _subliminalAudios[_selectedLanguage]!.name
                        : AppLocalizations.of(context).noAudioSelected,
                    icon: Icons.audiotrack,
                    onTap: () =>
                        _pickSubliminalAudioForLanguage(_selectedLanguage),
                    hasFile: _subliminalAudios[_selectedLanguage] != null,
                    languageCode: _selectedLanguage,
                  ),

                  SizedBox(height: 32.h),

                  // Image Upload Section
                  _buildSectionTitle(
                      '🖼️ ${AppLocalizations.of(context).backgroundImages}'),
                  SizedBox(height: 12.h),
                  _buildFileUploadCard(
                    title:
                        '${AppLocalizations.of(context).backgroundImage} ($_selectedLanguage)',
                    subtitle: _backgroundImages[_selectedLanguage] != null
                        ? _backgroundImages[_selectedLanguage]!.name
                        : AppLocalizations.of(context).noImageSelected,
                    icon: Icons.image,
                    onTap: () =>
                        _pickBackgroundImageForLanguage(_selectedLanguage),
                    hasFile: _backgroundImages[_selectedLanguage] != null,
                    languageCode: _selectedLanguage,
                  ),

                  SizedBox(height: 40.h),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        widget.sessionToEdit != null
                            ? AppLocalizations.of(context).updateSession
                            : AppLocalizations.of(context).createSession,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _uploadStatus,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: _uploadProgress / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
          ),
          SizedBox(height: 8.h),
          Text(
            '${_uploadProgress.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTabs() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: AppLanguages.supportedLanguages.map((lang) {
          // 🆕
          final isSelected = _selectedLanguage == lang;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLanguage = lang;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  lang.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasFile,
    String? languageCode,
  }) {
    String displaySubtitle = subtitle;
    bool hasExistingFile = false;

    if (languageCode != null && widget.sessionToEdit != null && !hasFile) {
      // Check for existing audio URL
      if (title.contains('Audio')) {
        final existingUrl =
            widget.sessionToEdit!['subliminal']?['audioUrls']?[languageCode];
        if (existingUrl != null) {
          hasExistingFile = true;
          // Extract filename from URL
          final uri = Uri.parse(existingUrl.toString());
          final filename = uri.pathSegments.last.split('?').first;
          displaySubtitle =
              '✅ ${AppLocalizations.of(context).existing}: $filename';
        }
      }
      // Check for existing image URL
      else if (title.contains('Image')) {
        final existingUrl =
            widget.sessionToEdit!['backgroundImages']?[languageCode];
        if (existingUrl != null) {
          hasExistingFile = true;
          final uri = Uri.parse(existingUrl.toString());
          final filename = uri.pathSegments.last.split('?').first;
          displaySubtitle =
              '✅ ${AppLocalizations.of(context).existing}: $filename';
        }
      }
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: (hasFile || hasExistingFile)
              ? Colors.green.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasFile ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: hasFile ? Colors.green : AppColors.textPrimary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                hasFile ? Icons.check : icon,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    displaySubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.upload_file,
              color: AppColors.textPrimary,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}
