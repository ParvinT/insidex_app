// lib/features/admin/add_disease_cause_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_languages.dart';
import '../../models/disease_cause_model.dart';
import '../../models/disease_model.dart';
import '../../services/disease/disease_cause_service.dart';
import '../../services/disease/disease_service.dart';
import '../../l10n/app_localizations.dart';

class AddDiseaseCauseScreen extends StatefulWidget {
  final DiseaseCauseModel? causeToEdit;

  const AddDiseaseCauseScreen({
    super.key,
    this.causeToEdit,
  });

  @override
  State<AddDiseaseCauseScreen> createState() => _AddDiseaseCauseScreenState();
}

class _AddDiseaseCauseScreenState extends State<AddDiseaseCauseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DiseaseCauseService _causeService = DiseaseCauseService();
  final DiseaseService _diseaseService = DiseaseService();

  late TabController _tabController;

  // Controllers for each language (disease cause content)
  final Map<String, TextEditingController> _contentControllers = {};

  // Session dropdown
  List<Map<String, dynamic>> _sessions = [];
  String? _selectedSessionId;
  int? _selectedSessionNumber;

  // Disease dropdown
  List<DiseaseModel> _diseases = [];
  String? _selectedDiseaseId;

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
      // Load diseases
      final diseases = await _diseaseService.getAllDiseases();

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
          _diseases = diseases;
          _sessions = sessions;
          _isLoadingData = false;
        });

        // Load existing data if editing
        if (widget.causeToEdit != null) {
          _loadExistingData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context).errorLoadingData}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadExistingData() {
    final cause = widget.causeToEdit!;

    // Load content translations
    cause.content.forEach((langCode, content) {
      if (_contentControllers.containsKey(langCode)) {
        _contentControllers[langCode]!.text = content;
      }
    });

    // Load disease
    _selectedDiseaseId = cause.diseaseId;

    // Load session
    _selectedSessionId = cause.recommendedSessionId;
    _selectedSessionNumber = cause.sessionNumber;

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveDiseaseCause() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseFillAllFields),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDiseaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseSelectDisease),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseSelectSession),
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

      // Create disease cause model
      final diseaseCause = DiseaseCauseModel(
        id: widget.causeToEdit?.id ?? '',
        diseaseId: _selectedDiseaseId!,
        content: content,
        recommendedSessionId: _selectedSessionId!,
        sessionNumber: _selectedSessionNumber,
        createdAt: widget.causeToEdit?.createdAt ?? DateTime.now(),
      );

      // Save to Firestore
      bool success;
      if (widget.causeToEdit != null) {
        // Update
        success = await _causeService.updateDiseaseCause(
          widget.causeToEdit!.id,
          diseaseCause,
        );
      } else {
        // Create
        final docId = await _causeService.addDiseaseCause(diseaseCause);
        success = docId != null;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.causeToEdit != null
                    ? AppLocalizations.of(context)
                        .diseaseCauseUpdatedSuccessfully
                    : AppLocalizations.of(context)
                        .diseaseCauseCreatedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to save disease cause');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context).errorSavingData}: $e'),
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
            widget.causeToEdit != null
                ? AppLocalizations.of(context).editDiseaseCause
                : AppLocalizations.of(context).addDiseaseCause,
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
          widget.causeToEdit != null
              ? AppLocalizations.of(context).editDiseaseCause
              : AppLocalizations.of(context).addDiseaseCause,
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
                    // Disease Selection
                    _buildDiseaseDropdown(),

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

  Widget _buildDiseaseDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDiseaseId,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).disease,
        hintText: AppLocalizations.of(context).selectADisease,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        prefixIcon: const Icon(Icons.medical_services),
      ),
      isExpanded: true,
      items: _diseases.map((disease) {
        return DropdownMenuItem<String>(
          value: disease.id,
          child: Row(
            children: [
              // Gender badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: disease.gender == 'male'
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.pink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  disease.gender == 'male' ? 'M' : 'F',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: disease.gender == 'male'
                        ? Colors.blue[700]
                        : Colors.pink[700],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  disease.getLocalizedName('en'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedDiseaseId = value);
      },
      validator: (value) {
        if (value == null)
          return AppLocalizations.of(context).pleaseSelectDisease;
        return null;
      },
    );
  }

  Widget _buildSessionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSessionId,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).recommendedSession,
        hintText: AppLocalizations.of(context).selectASession,
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
        if (value == null)
          return AppLocalizations.of(context).pleaseSelectSession;
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
                      '${AppLocalizations.of(context).diseaseCauseContent} (${AppLanguages.getName(langCode)})',
                  hintText: AppLocalizations.of(context).describeDiseaseHelp,
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
                    return AppLocalizations.of(context).englishContentRequired;
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
        onPressed: _isLoading ? null : _saveDiseaseCause,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.causeToEdit != null
                    ? AppLocalizations.of(context).updateDiseaseCause
                    : AppLocalizations.of(context).addDiseaseCause,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
