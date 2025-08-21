// lib/features/admin/add_session_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';

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

  // Durations
  int _introDuration = 120; // 2 minutes default
  int _subliminalDuration = 7200; // 2 hours default

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // If editing, load existing data
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
    });
  }

  void _loadExistingData() {
    final session = widget.sessionToEdit!;
    _titleController.text = session['title'] ?? '';
    _descriptionController.text = session['description'] ?? '';
    _selectedCategory = session['category'];
    _selectedEmoji = session['emoji'] ?? '🎵';

    // Load intro data
    if (session['intro'] != null) {
      _introTitleController.text = session['intro']['title'] ?? '';
      _introDescriptionController.text = session['intro']['description'] ?? '';
      _introDuration = session['intro']['duration'] ?? 120;
    }

    // Load subliminal data
    if (session['subliminal'] != null) {
      _subliminalTitleController.text = session['subliminal']['title'] ?? '';
      _subliminalDuration = session['subliminal']['duration'] ?? 7200;

      if (session['subliminal']['affirmations'] != null) {
        _affirmationsController.text =
            (session['subliminal']['affirmations'] as List).join('\n');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb || MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveSession,
              icon: Icon(Icons.save, color: AppColors.primaryGold),
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

              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              _buildBasicInfoSection(),

              SizedBox(height: 32.h),

              // Media Files Section
              _buildSectionTitle('Media Files'),
              _buildMediaSection(),

              SizedBox(height: 32.h),

              // Introduction Section
              _buildSectionTitle('Introduction Track'),
              _buildIntroSection(),

              SizedBox(height: 32.h),

              // Subliminal Section
              _buildSectionTitle('Subliminal Track'),
              _buildSubliminalSection(),

              SizedBox(height: 40.h),

              // Save Button
              _buildSaveButton(),

              SizedBox(height: 20.h),
            ],
          ),
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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppColors.greyLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          SizedBox(height: 4.h),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Session Title *',
              hintText: 'e.g., Deep Sleep Healing',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
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

          // Category and Emoji
          Row(
            children: [
              // Category Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(width: 16.w),

              // Emoji Picker
              Expanded(
                child: InkWell(
                  onTap: _showEmojiPicker,
                  child: Container(
                    height: 56.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.greyBorder),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedEmoji,
                          style: TextStyle(fontSize: 24.sp),
                        ),
                        Text(
                          'Emoji',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe what this session helps with...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        children: [
          // Background Image
          _buildFileUploadCard(
            title: 'Background Image',
            subtitle: 'Recommended: 1920x1080, JPG/PNG',
            file: _backgroundImage,
            icon: Icons.image,
            onTap: () => _pickFile(FileType.image, (file) {
              setState(() => _backgroundImage = file);
            }),
            onRemove: () => setState(() => _backgroundImage = null),
          ),

          SizedBox(height: 16.h),

          // Introduction Audio
          _buildFileUploadCard(
            title: 'Introduction Audio *',
            subtitle: 'MP3 format, 1-5 minutes recommended',
            file: _introAudio,
            icon: Icons.audiotrack,
            onTap: () => _pickFile(FileType.audio, (file) {
              setState(() => _introAudio = file);
            }),
            onRemove: () => setState(() => _introAudio = null),
          ),

          SizedBox(height: 16.h),

          // Subliminal Audio
          _buildFileUploadCard(
            title: 'Subliminal Audio *',
            subtitle: 'MP3 format, 30min - 2hours recommended',
            file: _subliminalAudio,
            icon: Icons.music_note,
            onTap: () => _pickFile(FileType.audio, (file) {
              setState(() => _subliminalAudio = file);
            }),
            onRemove: () => setState(() => _subliminalAudio = null),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadCard({
    required String title,
    required String subtitle,
    required PlatformFile? file,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return InkWell(
      onTap: file == null ? onTap : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: file != null
              ? AppColors.primaryGold.withOpacity(0.05)
              : AppColors.greyLight,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: file != null
                ? AppColors.primaryGold.withOpacity(0.3)
                : AppColors.greyBorder,
            style: file == null ? BorderStyle.solid : BorderStyle.solid,
            width: file != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: file != null
                    ? AppColors.primaryGold.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                file != null ? Icons.check_circle : icon,
                color: file != null
                    ? AppColors.primaryGold
                    : AppColors.textSecondary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file != null ? file.name : title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    file != null
                        ? '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'
                        : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (file != null)
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: onRemove,
              )
            else
              Icon(
                Icons.upload,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _introTitleController,
            decoration: InputDecoration(
              labelText: 'Introduction Title',
              hintText: 'e.g., Relaxation Introduction',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          TextFormField(
            controller: _introDescriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Introduction Description',
              hintText: 'Brief description of the introduction...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Duration input
          Row(
            children: [
              Text(
                'Duration (seconds):',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 16.w),
              Container(
                width: 100.w,
                child: TextFormField(
                  initialValue: _introDuration.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                  onChanged: (value) {
                    _introDuration = int.tryParse(value) ?? 120;
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '(${(_introDuration / 60).toStringAsFixed(1)} minutes)',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubliminalSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _subliminalTitleController,
            decoration: InputDecoration(
              labelText: 'Subliminal Title',
              hintText: 'e.g., Deep Sleep Subliminals',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          TextFormField(
            controller: _affirmationsController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Affirmations (one per line)',
              hintText:
                  'I am calm and peaceful\nI sleep deeply\nI wake up refreshed',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Duration input
          Row(
            children: [
              Text(
                'Duration (seconds):',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 16.w),
              Container(
                width: 100.w,
                child: TextFormField(
                  initialValue: _subliminalDuration.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                  onChanged: (value) {
                    _subliminalDuration = int.tryParse(value) ?? 7200;
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '(${(_subliminalDuration / 3600).toStringAsFixed(1)} hours)',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.sessionToEdit != null
                    ? 'Update Session'
                    : 'Create Session',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = ['🎵', '😴', '🧘', '💪', '🌙', '⭐', '✨', '🎯', '💫', '🌟'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Emoji'),
        content: Wrap(
          spacing: 16.w,
          runSpacing: 16.h,
          children: emojis.map((emoji) {
            return InkWell(
              onTap: () {
                setState(() => _selectedEmoji = emoji);
                Navigator.pop(context);
              },
              child: Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: _selectedEmoji == emoji
                      ? AppColors.primaryGold.withOpacity(0.2)
                      : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _selectedEmoji == emoji
                        ? AppColors.primaryGold
                        : AppColors.greyBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickFile(FileType type, Function(PlatformFile) onPicked) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: type == FileType.audio ? ['mp3', 'm4a'] : null,
      );

      if (result != null && result.files.isNotEmpty) {
        onPicked(result.files.first);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    if (_introAudio == null || _subliminalAudio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload both audio files'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Generate session ID
      final sessionId = widget.sessionToEdit?['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      String? backgroundImageUrl;
      String? introAudioUrl;
      String? subliminalAudioUrl;

      // Upload background image
      if (_backgroundImage != null) {
        setState(() => _uploadStatus = 'Uploading background image...');
        backgroundImageUrl = await _uploadFile(
          _backgroundImage!,
          'images/sessions/$sessionId/background',
        );
      }

      // Upload intro audio
      setState(() {
        _uploadStatus = 'Uploading introduction audio...';
        _uploadProgress = 0.33;
      });
      introAudioUrl = await _uploadFile(
        _introAudio!,
        'audio/sessions/$sessionId/intro',
      );

      // Upload subliminal audio
      setState(() {
        _uploadStatus = 'Uploading subliminal audio...';
        _uploadProgress = 0.66;
      });
      subliminalAudioUrl = await _uploadFile(
        _subliminalAudio!,
        'audio/sessions/$sessionId/subliminal',
      );

      // Prepare session data
      final sessionData = {
        'id': sessionId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'emoji': _selectedEmoji,
        'backgroundImage':
            backgroundImageUrl ?? widget.sessionToEdit?['backgroundImage'],
        'intro': {
          'title': _introTitleController.text.trim(),
          'description': _introDescriptionController.text.trim(),
          'duration': _introDuration,
          'audioUrl':
              introAudioUrl ?? widget.sessionToEdit?['intro']?['audioUrl'],
        },
        'subliminal': {
          'title': _subliminalTitleController.text.trim(),
          'duration': _subliminalDuration,
          'audioUrl': subliminalAudioUrl ??
              widget.sessionToEdit?['subliminal']?['audioUrl'],
          'affirmations': _affirmationsController.text
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList(),
        },
        'playCount': widget.sessionToEdit?['playCount'] ?? 0,
        'rating': widget.sessionToEdit?['rating'] ?? 0.0,
        'isActive': true,
        'isPremium': false,
        'createdAt':
            widget.sessionToEdit?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      setState(() {
        _uploadStatus = 'Saving session...';
        _uploadProgress = 0.9;
      });

      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .set(sessionData, SetOptions(merge: true));

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Session saved successfully!';
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.sessionToEdit != null
                ? 'Session updated successfully!'
                : 'Session created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _uploadFile(PlatformFile file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);

    if (kIsWeb) {
      // Web upload
      await ref.putData(file.bytes!);
    } else {
      // Mobile upload
      await ref.putFile(File(file.path!));
    }

    return await ref.getDownloadURL();
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
