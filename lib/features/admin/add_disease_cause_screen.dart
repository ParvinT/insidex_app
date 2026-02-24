// lib/features/admin/add_disease_cause_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/constants/app_languages.dart';
import '../../core/responsive/context_ext.dart';
import '../../models/disease_cause_model.dart';
import '../../models/disease_model.dart';
import '../../services/disease/disease_cause_service.dart';
import '../../services/disease/disease_service.dart';
import '../../services/language_helper_service.dart';
import '../../services/session_localization_service.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/searchable_picker_sheet.dart';

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
  String _adminLanguage = 'en';

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

      final adminLanguage = await LanguageHelperService.getCurrentLanguage();
      _adminLanguage = adminLanguage;

      final sessions = sessionsSnapshot.docs.map((doc) {
        final data = doc.data();

        // Get title from multi-language content
        // Get localized title using SessionLocalizationService
        final localizedContent = SessionLocalizationService.getLocalizedContent(
          data,
          adminLanguage,
        );

        final title = localizedContent.title.isNotEmpty
            ? localizedContent.title
            : (data['title'] ?? 'Untitled');

        final sessionNumber = data['sessionNumber'];
        final gender = data['gender'] as String?;

        return {
          'id': doc.id,
          'title': title,
          'sessionNumber': sessionNumber,
          'gender': gender,
          // Store display title for dropdown
          'displayTitle':
              sessionNumber != null ? '№$sessionNumber • $title' : title,
        };
      }).toList();

      // Sort by session number
      sessions.sort((a, b) {
        final numA = a['sessionNumber'] as int?;
        final numB = b['sessionNumber'] as int?;

        if (numA == null && numB == null) return 0;
        if (numA == null) return 1;
        if (numB == null) return -1;

        return numA.compareTo(numB);
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
    for (var controller in _contentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // =================== PICKER METHODS ===================

  String? _getSelectedDiseaseName() {
    if (_selectedDiseaseId == null) return null;
    final disease = _diseases.firstWhere(
      (d) => d.id == _selectedDiseaseId,
      orElse: () => DiseaseModel(
        id: '',
        gender: 'male',
        translations: {'en': 'Unknown'},
      ),
    );
    return disease.getLocalizedName(_adminLanguage);
  }

  String? _getSelectedDiseaseGender() {
    if (_selectedDiseaseId == null) return null;
    final disease = _diseases.firstWhere(
      (d) => d.id == _selectedDiseaseId,
      orElse: () => DiseaseModel(
        id: '',
        gender: 'male',
        translations: {},
      ),
    );
    return disease.gender;
  }

  String? _getSelectedSessionName() {
    if (_selectedSessionId == null) return null;
    final session = _sessions.firstWhere(
      (s) => s['id'] == _selectedSessionId,
      orElse: () => {'displayTitle': 'Unknown'},
    );
    return session['displayTitle'] as String?;
  }

  Future<void> _showDiseasePicker() async {
    final l10n = AppLocalizations.of(context);

    final items = _diseases.map((disease) {
      return PickerItem<String>(
        value: disease.id,
        title: disease.getLocalizedName(_adminLanguage),
        gender: disease.gender,
      );
    }).toList();

    // Sort alphabetically
    items
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final result = await showSearchablePickerSheet<String>(
      context: context,
      title: l10n.selectADisease,
      items: items,
      selectedValue: _selectedDiseaseId,
      searchHint: l10n.search,
      genderFilter: GenderFilterConfig(
        enabled: true,
        allLabel: l10n.all,
        maleLabel: l10n.male,
        femaleLabel: l10n.female,
      ),
    );

    if (result != null) {
      setState(() => _selectedDiseaseId = result);
    }
  }

  Future<void> _showSessionPicker() async {
    final l10n = AppLocalizations.of(context);

    final items = _sessions.map((session) {
      final sessionNumber = session['sessionNumber'] as int?;
      final title = session['title'] as String? ?? 'Untitled';
      final gender = session['gender'] as String?;

      return PickerItem<String>(
        value: session['id'] as String,
        title: sessionNumber != null ? '№$sessionNumber • $title' : title,
        subtitle: gender != null
            ? (gender == 'male' ? l10n.male : l10n.female)
            : null,
        gender: gender,
      );
    }).toList();

    final result = await showSearchablePickerSheet<String>(
      context: context,
      title: l10n.selectASession,
      items: items,
      selectedValue: _selectedSessionId,
      searchHint: l10n.searchSessions,
      genderFilter: GenderFilterConfig(
        enabled: true,
        allLabel: l10n.all,
        maleLabel: l10n.male,
        femaleLabel: l10n.female,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSessionId = result;
        // Find and store session number
        final selectedSession = _sessions.firstWhere(
          (s) => s['id'] == result,
          orElse: () => {},
        );
        _selectedSessionNumber = selectedSession['sessionNumber'] as int?;
      });
    }
  }

  // =================== SAVE METHOD ===================

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
        recommendedSessionId: _selectedSessionId,
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

  // =================== BUILD METHODS ===================

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.causeToEdit != null
                ? AppLocalizations.of(context).editDiseaseCause
                : AppLocalizations.of(context).addDiseaseCause,
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        body:
            Center(child: CircularProgressIndicator(color: colors.textPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.causeToEdit != null
              ? AppLocalizations.of(context).editDiseaseCause
              : AppLocalizations.of(context).addDiseaseCause,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Tab Bar
            _buildTabBar(colors),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disease Selection
                    _buildDiseaseDropdown(colors),

                    SizedBox(height: 16.h),

                    // Session Selection
                    _buildSessionDropdown(colors),

                    SizedBox(height: 24.h),

                    // Language-specific content fields
                    _buildLanguageFields(colors),

                    SizedBox(height: 32.h),

                    // Save Button
                    _buildSaveButton(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppThemeExtension colors) {
    return Container(
      color: colors.background,
      child: TabBar(
        controller: _tabController,
        labelColor: colors.textPrimary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.textPrimary,
        tabs: AppLanguages.supportedLanguages.map((langCode) {
          return Tab(
            text: AppLanguages.getLabel(langCode),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiseaseDropdown(AppThemeExtension colors) {
    return _buildPickerField(
      colors: colors,
      label: AppLocalizations.of(context).disease,
      hint: AppLocalizations.of(context).selectADisease,
      icon: Icons.medical_services,
      value: _getSelectedDiseaseName(),
      selectedGender: _getSelectedDiseaseGender(),
      onTap: _showDiseasePicker,
      isRequired: true,
      isEmpty: _selectedDiseaseId == null,
    );
  }

  Widget _buildSessionDropdown(AppThemeExtension colors) {
    return _buildPickerField(
      colors: colors,
      label: AppLocalizations.of(context).recommendedSession,
      hint: AppLocalizations.of(context).selectASession,
      icon: Icons.music_note,
      value: _getSelectedSessionName(),
      onTap: _showSessionPicker,
      isRequired: false,
      isEmpty: _selectedSessionId == null,
    );
  }

  Widget _buildPickerField({
    required AppThemeExtension colors,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    String? value,
    String? selectedGender,
    bool isRequired = false,
    bool isEmpty = true,
  }) {
    final isTablet = context.isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 15.sp : 14.sp,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isTablet ? 15.sp : 14.sp,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),

        // Picker field
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: isTablet ? 16.h : 14.h,
            ),
            decoration: BoxDecoration(
              color: colors.backgroundElevated,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isEmpty
                    ? colors.border.withValues(alpha: 0.5)
                    : colors.textPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Icon(
                  icon,
                  color: isEmpty ? colors.textSecondary : colors.textPrimary,
                  size: isTablet ? 24.sp : 22.sp,
                ),
                SizedBox(width: 12.w),

                // Gender badge (if applicable)
                if (selectedGender != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: selectedGender == 'male'
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.pink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      selectedGender == 'male' ? Icons.male : Icons.female,
                      size: isTablet ? 16.sp : 14.sp,
                      color:
                          selectedGender == 'male' ? Colors.blue : Colors.pink,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],

                // Value or hint
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16.sp : 15.sp,
                      color:
                          isEmpty ? colors.textSecondary : colors.textPrimary,
                      fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                  size: isTablet ? 26.sp : 24.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageFields(AppThemeExtension colors) {
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

  Widget _buildSaveButton(AppThemeExtension colors) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveDiseaseCause,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.textPrimary,
          foregroundColor: colors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: colors.textOnPrimary)
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
