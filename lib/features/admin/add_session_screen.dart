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

  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type == 'image' ? FileType.image : FileType.audio,
      );

      if (result != null) {
        setState(() {
          switch (type) {
            case 'image':
              _backgroundImage = result.files.first;
              break;
            case 'intro':
              _introAudio = result.files.first;
              break;
            case 'subliminal':
              _subliminalAudio = result.files.first;
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<String?> _uploadFile(PlatformFile file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');

      final uploadTask =
          kIsWeb ? ref.putData(file.bytes!) : ref.putFile(File(file.path!));

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
          _uploadStatus = 'Uploading ${file.name}...';
        });
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      // Upload files if selected
      String? imageUrl;
      String? introUrl;
      String? subliminalUrl;

      if (_backgroundImage != null) {
        imageUrl = await _uploadFile(_backgroundImage!, 'session_images');
      }

      if (_introAudio != null) {
        introUrl = await _uploadFile(_introAudio!, 'intro_audio');
      }

      if (_subliminalAudio != null) {
        subliminalUrl =
            await _uploadFile(_subliminalAudio!, 'subliminal_audio');
      }

      // Prepare session data
      final sessionData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'emoji': _selectedEmoji,
        'backgroundImage': imageUrl,
        'intro': {
          'title': _introTitleController.text.trim(),
          'description': _introDescriptionController.text.trim(),
          'audioUrl': introUrl,
          'duration': _introDuration,
        },
        'subliminal': {
          'title': _subliminalTitleController.text.trim(),
          'audioUrl': subliminalUrl,
          'duration': _subliminalDuration,
          'affirmations': _affirmationsController.text
              .split('\n')
              .where((line) => line.isNotEmpty)
              .toList(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      if (widget.sessionToEdit != null) {
        // Update existing
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionToEdit!['id'])
            .update(sessionData);
      } else {
        // Create new
        await FirebaseFirestore.instance
            .collection('sessions')
            .add(sessionData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // Create Session Button
              _buildCreateButton(),

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _uploadStatus,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          SizedBox(height: 4.h),
          Text(
            '${(_uploadProgress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        children: [
          // Title Input
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
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
              setState(() => _selectedCategory = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a category';
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        children: [
          _buildFileUploadTile(
            title: 'Background Image',
            subtitle: 'JPG, PNG (Max 5MB)',
            icon: Icons.image,
            file: _backgroundImage,
            onTap: () => _pickFile('image'),
          ),
          SizedBox(height: 12.h),
          _buildFileUploadTile(
            title: 'Introduction Audio',
            subtitle: 'MP3, WAV (Max 50MB)',
            icon: Icons.audiotrack,
            file: _introAudio,
            onTap: () => _pickFile('intro'),
          ),
          SizedBox(height: 12.h),
          _buildFileUploadTile(
            title: 'Subliminal Audio',
            subtitle: 'MP3, WAV (Max 200MB)',
            icon: Icons.music_note,
            file: _subliminalAudio,
            onTap: () => _pickFile('subliminal'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    PlatformFile? file,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: file != null
                ? AppColors.primaryGold.withOpacity(0.3)
                : AppColors.greyBorder,
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
            Icon(
              Icons.cloud_upload_outlined,
              color: file != null
                  ? AppColors.primaryGold
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _introDescriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Introduction Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _introDuration.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration (seconds)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onChanged: (value) {
                    _introDuration = int.tryParse(value) ?? 120;
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                '${(_introDuration / 60).toStringAsFixed(1)} minutes',
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
      padding: EdgeInsets.all(16.w),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _affirmationsController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Affirmations (one per line)',
              hintText: 'Enter affirmations, one per line',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _subliminalDuration.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration (seconds)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onChanged: (value) {
                    _subliminalDuration = int.tryParse(value) ?? 7200;
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                '${(_subliminalDuration / 3600).toStringAsFixed(1)} hours',
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

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Create Session',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
