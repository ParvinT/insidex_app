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
  final _introTitleController = TextEditingController();
  final _introDescriptionController = TextEditingController();
  final _subliminalTitleController = TextEditingController();
  final _affirmationsController = TextEditingController();

  // Selected values
  String? _selectedCategory;
  String _selectedEmoji = '🎵';
  List<String> _categories = [];

  // File uploads
  PlatformFile? _backgroundImage;
  PlatformFile? _introAudio;
  PlatformFile? _subliminalAudio;

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
    _selectedEmoji = session['emoji'] ?? '🎵';

    if (session['intro'] != null) {
      _introTitleController.text = session['intro']['title'] ?? '';
      _introDescriptionController.text = session['intro']['description'] ?? '';
    }

    if (session['subliminal'] != null) {
      _subliminalTitleController.text = session['subliminal']['title'] ?? '';

      if (session['subliminal']['affirmations'] != null) {
        _affirmationsController.text =
            (session['subliminal']['affirmations'] as List).join('\n');
      }
    }
  }

  // FILE PICKER FUNCTIONS
  Future<void> _pickImage() async {
    try {
      final file = await StorageService.pickImageFile();
      if (file != null) {
        // Check file size (max 10MB for images)
        if (!StorageService.validateFileSize(file, 10)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image file too large! Max 10MB allowed'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _backgroundImage = file;
        });
        print('Image selected: ${file.name}');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickIntroAudio() async {
    try {
      final file = await StorageService.pickAudioFile();
      if (file != null) {
        // Check file size (max 50MB for intro)
        if (!StorageService.validateFileSize(file, 50)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file too large! Max 50MB allowed'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _introAudio = file;
        });
        print('Intro audio selected: ${file.name}');
      }
    } catch (e) {
      print('Error picking intro audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickSubliminalAudio() async {
    try {
      final file = await StorageService.pickAudioFile();
      if (file != null) {
        // Check file size (max 500MB for subliminal)
        if (!StorageService.validateFileSize(file, 500)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file too large! Max 500MB allowed'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _subliminalAudio = file;
        });
        print('Subliminal audio selected: ${file.name}');
      }
    } catch (e) {
      print('Error picking subliminal audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
      // Generate UNIQUE session ID for each new session
      // Use combination of timestamp and random string
      final String sessionId = widget.sessionToEdit?['id'] ??
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';

      debugPrint('====== SAVING SESSION ======');
      debugPrint('Session ID: $sessionId');
      debugPrint('Title: ${_titleController.text}');

      // Upload files using StorageService
      String? imageUrl;
      String? introUrl;
      String? subliminalUrl;

      // Upload background image
      if (_backgroundImage != null) {
        setState(() {
          _uploadStatus = 'Uploading background image...';
          _uploadProgress = 0;
        });

        imageUrl = await StorageService.uploadImage(
          folder: sessionId,
          file: _backgroundImage!,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress * 100;
            });
          },
        );

        if (imageUrl == null) {
          throw Exception('Failed to upload background image');
        }
        debugPrint('Image uploaded: $imageUrl');
      }

      // Upload intro audio
      if (_introAudio != null) {
        setState(() {
          _uploadStatus = 'Uploading introduction audio...';
          _uploadProgress = 0;
        });

        // Use unique path for each session's intro
        introUrl = await StorageService.uploadAudio(
          sessionId: sessionId, // Use the unique session ID
          file: _introAudio!,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress * 100;
            });
          },
        );

        if (introUrl == null) {
          throw Exception('Failed to upload intro audio');
        }
        debugPrint('Intro audio uploaded: $introUrl');
      }

      // Upload subliminal audio
      if (_subliminalAudio != null) {
        setState(() {
          _uploadStatus = 'Uploading subliminal audio...';
          _uploadProgress = 0;
        });

        // Use unique path for each session's subliminal
        subliminalUrl = await StorageService.uploadAudio(
          sessionId: sessionId, // Use the unique session ID
          file: _subliminalAudio!,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress * 100;
            });
          },
        );

        if (subliminalUrl == null) {
          throw Exception('Failed to upload subliminal audio');
        }
        debugPrint('Subliminal audio uploaded: $subliminalUrl');
      }

      setState(() {
        _uploadStatus = 'Saving session data...';
        _uploadProgress = 100;
      });

      // Prepare session data with CORRECT structure
      final sessionData = {
        'id': sessionId, // Include the ID in the document
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'emoji': _selectedEmoji,
        'backgroundImage':
            imageUrl ?? widget.sessionToEdit?['backgroundImage'] ?? '',
        'intro': {
          'title': _introTitleController.text.trim(),
          'description': _introDescriptionController.text.trim(),
          'audioUrl':
              introUrl ?? widget.sessionToEdit?['intro']?['audioUrl'] ?? '',
          'duration': 0, // Will be calculated from actual audio file
        },
        'subliminal': {
          'title': _subliminalTitleController.text.trim(),
          'audioUrl': subliminalUrl ??
              widget.sessionToEdit?['subliminal']?['audioUrl'] ??
              '',
          'duration': 0, // Will be calculated from actual audio file
          'affirmations': _affirmationsController.text
              .split('\n')
              .where((line) => line.isNotEmpty)
              .toList(),
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
        // Create new session with the generated ID
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId) // Use the same ID as document ID
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

  // BUILD METHODS
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

        SizedBox(height: 16.h),

        // Emoji Selector
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Text(
                  'Select Emoji',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Container(
                height: 50.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      '🎵',
                      '🌙',
                      '💭',
                      '🧘',
                      '🎯',
                      '💡',
                      '⚡',
                      '🌊',
                      '🔮',
                      '✨',
                      '🌟',
                      '💫',
                      '🌈',
                      '🦋',
                      '🌸',
                      '🍃'
                    ].map((emoji) => _buildEmojiOption(emoji)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiOption(String emoji) {
    bool isSelected = _selectedEmoji == emoji;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmoji = emoji;
        });
      },
      child: Container(
        width: 45.w,
        height: 45.w,
        margin: EdgeInsets.only(right: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withOpacity(0.2)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
        ),
      ),
    );
  }

  Widget _buildFileUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasFile,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.primaryGold.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasFile ? AppColors.primaryGold : Colors.grey.shade300,
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.primaryGold.withOpacity(0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: hasFile ? AppColors.primaryGold : Colors.grey,
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
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              color: hasFile ? AppColors.primaryGold : Colors.grey,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
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
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: _uploadProgress / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          SizedBox(height: 4.h),
          Text(
            '${_uploadProgress.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        // Background Image
        _buildFileUploadCard(
          title: 'Background Image',
          subtitle: _backgroundImage != null
              ? _backgroundImage!.name
              : 'No file selected',
          icon: Icons.image,
          onTap: _pickImage,
          hasFile: _backgroundImage != null,
        ),
      ],
    );
  }

  Widget _buildIntroSection() {
    return Column(
      children: [
        // Intro Title
        TextFormField(
          controller: _introTitleController,
          decoration: InputDecoration(
            labelText: 'Introduction Title',
            hintText: 'Enter intro title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Intro Description
        TextFormField(
          controller: _introDescriptionController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Introduction Description',
            hintText: 'Enter intro description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Intro Audio File
        _buildFileUploadCard(
          title: 'Introduction Audio',
          subtitle:
              _introAudio != null ? _introAudio!.name : 'No file selected',
          icon: Icons.audiotrack,
          onTap: _pickIntroAudio,
          hasFile: _introAudio != null,
        ),
      ],
    );
  }

  Widget _buildSubliminalSection() {
    return Column(
      children: [
        // Subliminal Title
        TextFormField(
          controller: _subliminalTitleController,
          decoration: InputDecoration(
            labelText: 'Subliminal Title',
            hintText: 'Enter subliminal title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Subliminal Audio File
        _buildFileUploadCard(
          title: 'Subliminal Audio',
          subtitle: _subliminalAudio != null
              ? _subliminalAudio!.name
              : 'No file selected',
          icon: Icons.music_note,
          onTap: _pickSubliminalAudio,
          hasFile: _subliminalAudio != null,
        ),

        SizedBox(height: 16.h),

        // Affirmations
        TextFormField(
          controller: _affirmationsController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Subliminal Affirmations',
            hintText: 'Enter each affirmation on a new line',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ],
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

              // Media Files
              _buildSectionTitle('Media Files'),
              _buildMediaSection(),

              SizedBox(height: 32.h),

              // Introduction
              _buildSectionTitle('Introduction Track'),
              _buildIntroSection(),

              SizedBox(height: 32.h),

              // Subliminal
              _buildSectionTitle('Subliminal Track'),
              _buildSubliminalSection(),

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
    _introTitleController.dispose();
    _introDescriptionController.dispose();
    _subliminalTitleController.dispose();
    _affirmationsController.dispose();
    super.dispose();
  }
}
