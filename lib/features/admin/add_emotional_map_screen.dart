// lib/features/admin/add_emotional_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_languages.dart';
import '../../models/emotional_map_model.dart';
import '../../models/symptom_model.dart';
import '../../services/emotional_map_service.dart';
import '../../services/symptom_service.dart';

class AddEmotionalMapScreen extends StatefulWidget {
  final EmotionalMapModel? mapToEdit;

  const AddEmotionalMapScreen({
    super.key,
    this.mapToEdit,
  });

  @override
  State<AddEmotionalMapScreen> createState() => _AddEmotionalMapScreenState();
}

class _AddEmotionalMapScreenState extends State<AddEmotionalMapScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final EmotionalMapService _mapService = EmotionalMapService();
  final SymptomService _symptomService = SymptomService();

  late TabController _tabController;

  // Controllers for each language (emotional map content)
  final Map<String, TextEditingController> _contentControllers = {};

  // Session dropdown
  List<Map<String, dynamic>> _sessions = [];
  String? _selectedSessionId;
  int? _selectedSessionNumber;

  // Symptom dropdown
  List<SymptomModel> _symptoms = [];
  String? _selectedSymptomId;

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(
      length: AppLanguages.supportedLanguages.length,
      vsync: this,
    );

    // Initialize controllers for each language
    for (var langCode in AppLanguages.supportedLanguages) {
      _contentControllers[langCode] = TextEditingController();
    }

    // Load data
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      // Load symptoms
      final symptoms = await _symptomService.getAllSymptoms();

      // Load sessions
      final sessionsSnapshot =
          await FirebaseFirestore.instance.collection('sessions').get();

      final sessions = sessionsSnapshot.docs.map((doc) {
        final data = doc.data();

        // Get title from multi-language content
        String title = 'Untitled';

        // Try new structure: content.en.title
        if (data['content'] is Map) {
          final content = data['content'] as Map<String, dynamic>;
          if (content['en'] is Map) {
            final enContent = content['en'] as Map<String, dynamic>;
            title = enContent['title'] ?? 'Untitled';
          }
        }

        // Fallback: old structure (single language)
        if (title == 'Untitled' && data['title'] != null) {
          title = data['title'] as String;
        }

        return {
          'id': doc.id,
          'sessionNumber': data['sessionNumber'], // null olabilir
          'title': title,
        };
      }).toList();

      sessions.sort((a, b) {
        final aNum = a['sessionNumber'];
        final bNum = b['sessionNumber'];

        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        } else if (aNum != null) {
          return -1; // a önce
        } else if (bNum != null) {
          return 1; // b önce
        } else {
          return a['title'].toString().compareTo(b['title'].toString());
        }
      });

      if (mounted) {
        setState(() {
          _symptoms = symptoms;
          _sessions = sessions;
          _isLoadingData = false;
        });

        // Load existing data if editing
        if (widget.mapToEdit != null) {
          _loadExistingData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadExistingData() {
    final map = widget.mapToEdit!;

    // Load content translations
    map.content.forEach((langCode, content) {
      if (_contentControllers.containsKey(langCode)) {
        _contentControllers[langCode]!.text = content;
      }
    });

    // Load symptom
    _selectedSymptomId = map.symptomId;

    // Load session
    _selectedSessionId = map.recommendedSessionId;
    _selectedSessionNumber = map.sessionNumber;

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveEmotionalMap() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedSymptomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a symptom'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a session'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build content map
      final content = <String, String>{};
      _contentControllers.forEach((langCode, controller) {
        if (controller.text.trim().isNotEmpty) {
          content[langCode] = controller.text.trim();
        }
      });

      // Validate: at least English must be filled
      if (!content.containsKey('en') || content['en']!.isEmpty) {
        throw Exception('English content is required');
      }

      // Create emotional map model
      final emotionalMap = EmotionalMapModel(
        id: widget.mapToEdit?.id ?? '',
        symptomId: _selectedSymptomId!,
        content: content,
        recommendedSessionId: _selectedSessionId!,
        sessionNumber: _selectedSessionNumber,
        createdAt: widget.mapToEdit?.createdAt ?? DateTime.now(),
      );

      // Save to Firestore
      bool success;
      if (widget.mapToEdit != null) {
        // Update
        success = await _mapService.updateEmotionalMap(
          widget.mapToEdit!.id,
          emotionalMap,
        );
      } else {
        // Create
        final docId = await _mapService.addEmotionalMap(emotionalMap);
        success = docId != null;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.mapToEdit != null
                    ? 'Emotional map updated successfully'
                    : 'Emotional map created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to save emotional map');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
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
            widget.mapToEdit != null
                ? 'Edit Emotional Map'
                : 'Add Emotional Map',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          widget.mapToEdit != null ? 'Edit Emotional Map' : 'Add Emotional Map',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Tab Bar
            _buildTabBar(),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Symptom Selection
                    _buildSymptomDropdown(),

                    SizedBox(height: 16.h),

                    // Session Selection
                    _buildSessionDropdown(),

                    SizedBox(height: 24.h),

                    // Language-specific content fields
                    _buildLanguageFields(),

                    SizedBox(height: 32.h),

                    // Save Button
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryGold,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primaryGold,
        tabs: AppLanguages.supportedLanguages.map((langCode) {
          return Tab(
            text: AppLanguages.getLabel(langCode),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSymptomDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSymptomId,
      decoration: InputDecoration(
        labelText: 'Symptom',
        hintText: 'Select a symptom',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        prefixIcon: const Icon(Icons.psychology),
      ),
      isExpanded: true,
      items: _symptoms.map((symptom) {
        return DropdownMenuItem<String>(
          value: symptom.id,
          child: Row(
            children: [
              if (symptom.icon.isNotEmpty)
                Text(symptom.icon, style: TextStyle(fontSize: 20.sp)),
              if (symptom.icon.isNotEmpty) SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  symptom.getLocalizedName('en'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedSymptomId = value);
      },
      validator: (value) {
        if (value == null) return 'Please select a symptom';
        return null;
      },
    );
  }

  Widget _buildSessionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSessionId,
      decoration: InputDecoration(
        labelText: 'Recommended Session',
        hintText: 'Select a session',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        prefixIcon: const Icon(Icons.music_note),
      ),
      isExpanded: true,
      items: _sessions.map((session) {
        final sessionNumber = session['sessionNumber'];
        final title = session['title'];

        return DropdownMenuItem<String>(
          value: session['id'],
          child: Text(
            sessionNumber != null ? '№$sessionNumber — $title' : title,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSessionId = value;
          // Find session number
          final session = _sessions.firstWhere(
            (s) => s['id'] == value,
            orElse: () => {},
          );
          _selectedSessionNumber = session['sessionNumber'];
        });
      },
      validator: (value) {
        if (value == null) return 'Please select a session';
        return null;
      },
    );
  }

  Widget _buildLanguageFields() {
    return SizedBox(
      height: 300.h,
      child: TabBarView(
        controller: _tabController,
        children: AppLanguages.supportedLanguages.map((langCode) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: TextFormField(
                controller: _contentControllers[langCode],
                maxLines: 10,
                decoration: InputDecoration(
                  labelText:
                      'Emotional Map Content (${AppLanguages.getName(langCode)})',
                  hintText:
                      'Describe how this symptom affects people and how the session helps...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(top: 12.h, left: 12.w),
                    child: Text(
                      AppLanguages.getFlag(langCode),
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 48.w),
                ),
                validator: (value) {
                  // Only English is required
                  if (langCode == 'en' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'English content is required';
                  }
                  return null;
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveEmotionalMap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.mapToEdit != null
                    ? 'Update Emotional Map'
                    : 'Add Emotional Map',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
