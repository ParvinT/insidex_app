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

  // Form Controllers - ORİJİNAL GİBİ
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

  // File uploads - YENİ
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
      _introDuration = session['intro']['duration'] ?? 120;
    }

    if (session['subliminal'] != null) {
      _subliminalTitleController.text = session['subliminal']['title'] ?? '';
      _subliminalDuration = session['subliminal']['duration'] ?? 7200;

      if (session['subliminal']['affirmations'] != null) {
        _affirmationsController.text =
            (session['subliminal']['affirmations'] as List).join('\n');
      }
    }
  }

  // STORAGE UPLOAD FUNCTION - BASİT
  Future<String?> _uploadFile(PlatformFile file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');

      late UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(file.bytes!);
      } else {
        final fileToUpload = File(file.path!);
        uploadTask = ref.putFile(fileToUpload);
      }

      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        setState(() {
          _uploadProgress = progress;
        });
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // FILE PICKER FUNCTIONS
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _backgroundImage = result.files.first;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _pickIntroAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        setState(() {
          _introAudio = result.files.first;
        });
      }
    } catch (e) {
      print('Error picking intro audio: $e');
    }
  }

  Future<void> _pickSubliminalAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        final file = result.files.first;
        final sizeMB = file.size / (1024 * 1024);

        // Size check
        if (sizeMB > 500) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'File too large! Max 500MB. Current: ${sizeMB.toStringAsFixed(2)}MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _subliminalAudio = file;
        });
      }
    } catch (e) {
      print('Error picking subliminal audio: $e');
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Uploading files...';
    });

    try {
      // Upload files
      String? imageUrl;
      String? introUrl;
      String? subliminalUrl;

      if (_backgroundImage != null) {
        setState(() => _uploadStatus = 'Uploading image...');
        imageUrl = await _uploadFile(_backgroundImage!, 'session_images');
      }

      if (_introAudio != null) {
        setState(() => _uploadStatus = 'Uploading introduction...');
        introUrl = await _uploadFile(_introAudio!, 'intro_audio');
      }

      if (_subliminalAudio != null) {
        setState(() => _uploadStatus = 'Uploading subliminal audio...');
        subliminalUrl =
            await _uploadFile(_subliminalAudio!, 'subliminal_audio');
      }

      setState(() => _uploadStatus = 'Saving session...');

      // Prepare session data - ORİJİNAL YAPI
      final sessionData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'emoji': _selectedEmoji,
        'backgroundImage': imageUrl ?? '',
        'intro': {
          'title': _introTitleController.text.trim(),
          'description': _introDescriptionController.text.trim(),
          'audioUrl': introUrl ?? '',
          'duration': _introDuration,
        },
        'subliminal': {
          'title': _subliminalTitleController.text.trim(),
          'audioUrl': subliminalUrl ?? '',
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
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionToEdit!['id'])
            .update(sessionData);
      } else {
        await FirebaseFirestore.instance
            .collection('sessions')
            .add(sessionData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session saved successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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

  // BUILD METHODS - ORİJİNAL TASARIM
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Category
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
        ),

        SizedBox(height: 16.h),

        // Emoji Selector
        Wrap(
          spacing: 8.w,
          children: ['🎵', '🧘', '😴', '🌙', '💆', '🌊'].map((emoji) {
            return GestureDetector(
              onTap: () => setState(() => _selectedEmoji = emoji),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _selectedEmoji == emoji
                      ? AppColors.primaryGold.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _selectedEmoji == emoji
                        ? AppColors.primaryGold
                        : AppColors.greyBorder,
                  ),
                ),
                child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        // Background Image
        ListTile(
          title: Text('Background Image'),
          subtitle: Text(_backgroundImage?.name ?? 'No file selected'),
          trailing: IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: _pickImage,
          ),
        ),

        Divider(),

        // Intro Audio
        ListTile(
          title: Text('Introduction Audio'),
          subtitle: Text(_introAudio != null
              ? '${(_introAudio!.size / (1024 * 1024)).toStringAsFixed(2)} MB'
              : 'No file selected'),
          trailing: IconButton(
            icon: Icon(Icons.audio_file),
            onPressed: _pickIntroAudio,
          ),
        ),

        Divider(),

        // Subliminal Audio
        ListTile(
          title: Text('Subliminal Audio'),
          subtitle: Text(_subliminalAudio != null
              ? '${(_subliminalAudio!.size / (1024 * 1024)).toStringAsFixed(2)} MB'
              : 'No file selected (Max 500MB)'),
          trailing: IconButton(
            icon: Icon(Icons.audio_file),
            onPressed: _pickSubliminalAudio,
          ),
        ),
      ],
    );
  }

  Widget _buildIntroSection() {
    return Column(
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

        // Duration Slider
        Row(
          children: [
            Text('Duration: '),
            Expanded(
              child: Slider(
                value: _introDuration.toDouble(),
                min: 60,
                max: 600,
                divisions: 18,
                label: '${_introDuration ~/ 60} minutes',
                onChanged: (value) {
                  setState(() {
                    _introDuration = value.toInt();
                  });
                },
              ),
            ),
            Text('${_introDuration ~/ 60} min'),
          ],
        ),
      ],
    );
  }

  Widget _buildSubliminalSection() {
    return Column(
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

        // Duration
        Row(
          children: [
            Text('Duration: '),
            Expanded(
              child: Slider(
                value: _subliminalDuration.toDouble(),
                min: 600,
                max: 14400,
                divisions: 46,
                label:
                    '${_subliminalDuration ~/ 3600}h ${(_subliminalDuration % 3600) ~/ 60}m',
                onChanged: (value) {
                  setState(() {
                    _subliminalDuration = value.toInt();
                  });
                },
              ),
            ),
            Text(
                '${_subliminalDuration ~/ 3600}h ${(_subliminalDuration % 3600) ~/ 60}m'),
          ],
        ),

        SizedBox(height: 16.h),

        // Affirmations
        TextFormField(
          controller: _affirmationsController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Affirmations (one per line)',
            hintText: 'I am relaxed\nI am peaceful\nI am calm',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(_uploadStatus),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: _uploadProgress / 100,
            backgroundColor: AppColors.greyLight,
            valueColor: AlwaysStoppedAnimation(AppColors.primaryGold),
          ),
          SizedBox(height: 4.h),
          Text('${_uploadProgress.toInt()}%'),
        ],
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
