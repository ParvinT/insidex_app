// lib/features/admin/add_session_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/storage_service.dart';

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

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _introductionTitleController = TextEditingController();
  final _introductionContentController = TextEditingController();

  // Selected values
  String? _selectedCategory;
  List<String> _categories = [];

  // Language selection
  String _selectedLanguage = 'en';

  // Multi-language file uploads
  final Map<String, PlatformFile?> _subliminalAudios = {
    'en': null,
    'tr': null,
    'ru': null,
    'hi': null,
  };

  final Map<String, PlatformFile?> _backgroundImages = {
    'en': null,
    'tr': null,
    'ru': null,
    'hi': null,
  };

  // Loading states
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.sessionToEdit != null) {
      _loadExistingData();
    }
  }

  void _loadCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();

    setState(() {
      _categories =
          snapshot.docs.map((doc) => doc.data()['title'] as String).toList();

      // Default categories if empty
      if (_categories.isEmpty) {
        _categories = ['Sleep', 'Meditation', 'Focus', 'Relaxation'];
      }
    });
  }

  void _loadExistingData() {
    final session = widget.sessionToEdit!;
    _titleController.text = session['title'] ?? '';
    _descriptionController.text = session['description'] ?? '';
    _selectedCategory = session['category'];

    // Load introduction text
    if (session['introduction'] != null) {
      _introductionTitleController.text =
          session['introduction']['title'] ?? '';
      _introductionContentController.text =
          session['introduction']['content'] ?? '';
    }

    // Note: File uploads cannot be loaded from existing session (only URLs available)
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
              const SnackBar(
                content: Text('Audio file too large! Max 500MB allowed'),
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
            content: Text('Error selecting audio: ${e.toString()}'),
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
              const SnackBar(
                content: Text('Image file too large! Max 10MB allowed'),
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
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =================== SAVE SESSION ===================

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Starting upload...';
      _uploadProgress = 0;
    });

    try {
      // Generate unique session ID
      final String sessionId = widget.sessionToEdit?['id'] ??
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';

      debugPrint('====== SAVING SESSION ======');
      debugPrint('Session ID: $sessionId');
      debugPrint('Title: ${_titleController.text}');

      // Upload files with language support
      final Map<String, String> audioUrls = {};
      final Map<String, String> imageUrls = {};
      final Map<String, int> durations = {};

      // Upload subliminal audios for each language
      for (final languageCode in ['en', 'tr', 'ru', 'hi']) {
        final audioFile = _subliminalAudios[languageCode];

        if (audioFile != null) {
          setState(() {
            _uploadStatus = 'Uploading $languageCode subliminal audio...';
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
        }
      }

      // Upload background images for each language
      for (final languageCode in ['en', 'tr', 'ru', 'hi']) {
        final imageFile = _backgroundImages[languageCode];

        if (imageFile != null) {
          setState(() {
            _uploadStatus = 'Uploading $languageCode background image...';
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

          imageUrls[languageCode] = imageUrl;
          debugPrint('✅ $languageCode image uploaded: $imageUrl');
        }
      }

      setState(() {
        _uploadStatus = 'Saving session data...';
        _uploadProgress = 100;
      });

      // Prepare session data with NEW structure
      final sessionData = {
        'id': sessionId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,

        // Multi-language background images
        'backgroundImages': audioUrls.isNotEmpty
            ? imageUrls
            : (widget.sessionToEdit?['backgroundImages'] ?? {}),

        // Introduction (text only)
        'introduction': {
          'title': _introductionTitleController.text.trim(),
          'content': _introductionContentController.text.trim(),
        },

        // Subliminal with multi-language support
        'subliminal': {
          'audioUrls': audioUrls.isNotEmpty
              ? audioUrls
              : (widget.sessionToEdit?['subliminal']?['audioUrls'] ?? {}),
          'durations': durations.isNotEmpty
              ? durations
              : (widget.sessionToEdit?['subliminal']?['durations'] ?? {}),
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
          const SnackBar(
            content: Text('Session saved successfully!'),
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
            content: Text('Error saving session: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =================== BUILD METHODS ===================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.3),
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
                const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
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

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        // Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Session Title',
            hintText: 'Enter session title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),

        SizedBox(height: 16.h),

        // Description
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Enter session description',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),

        SizedBox(height: 16.h),

        // Category Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildIntroductionSection() {
    return Column(
      children: [
        TextFormField(
          controller: _introductionTitleController,
          decoration: InputDecoration(
            labelText: 'Introduction Title',
            hintText: 'Welcome to...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _introductionContentController,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: 'Introduction Content',
            hintText: 'This session will help you...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ],
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
        children: ['en', 'tr', 'ru', 'hi'].map((lang) {
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
                            color: Colors.black.withOpacity(0.05),
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
                        ? AppColors.primaryGold
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasFile ? AppColors.primaryGold : AppColors.greyBorder,
            width: hasFile ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
          color:
              hasFile ? AppColors.primaryGold.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.primaryGold.withOpacity(0.1)
                    : AppColors.greyLight,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color:
                    hasFile ? AppColors.primaryGold : AppColors.textSecondary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (languageCode != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            languageCode.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.add_circle_outline,
              color: hasFile ? AppColors.primaryGold : AppColors.textSecondary,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sessionToEdit != null ? 'Edit Session' : 'Add New Session',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveSession,
              icon: const Icon(Icons.save, color: AppColors.primaryGold),
              label: Text(
                'Save',
                style: GoogleFonts.inter(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload Progress
              if (_uploadProgress > 0) _buildUploadProgress(),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              _buildBasicInfoSection(),

              SizedBox(height: 32.h),

              // Introduction (Text Only)
              _buildSectionTitle('Introduction'),
              _buildIntroductionSection(),

              SizedBox(height: 32.h),

              // Language Tabs
              _buildSectionTitle('Language & Media Files'),
              _buildLanguageTabs(),

              SizedBox(height: 16.h),

              // Subliminal Audio for selected language
              _buildFileUploadCard(
                title: 'Subliminal Audio',
                subtitle: _subliminalAudios[_selectedLanguage] != null
                    ? _subliminalAudios[_selectedLanguage]!.name
                    : 'No file selected for $_selectedLanguage',
                icon: Icons.music_note,
                onTap: () => _pickSubliminalAudioForLanguage(_selectedLanguage),
                hasFile: _subliminalAudios[_selectedLanguage] != null,
                languageCode: _selectedLanguage,
              ),

              SizedBox(height: 16.h),

              // Background Image for selected language
              _buildFileUploadCard(
                title: 'Background Image',
                subtitle: _backgroundImages[_selectedLanguage] != null
                    ? _backgroundImages[_selectedLanguage]!.name
                    : 'No file selected for $_selectedLanguage',
                icon: Icons.image,
                onTap: () => _pickBackgroundImageForLanguage(_selectedLanguage),
                hasFile: _backgroundImages[_selectedLanguage] != null,
                languageCode: _selectedLanguage,
              ),

              SizedBox(height: 32.h),

              // Info Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Upload audio and images for each language (EN, TR, RU, HI). Users will see content in their selected language.',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _introductionTitleController.dispose();
    _introductionContentController.dispose();
    super.dispose();
  }
}
