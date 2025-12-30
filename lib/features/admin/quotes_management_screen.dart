// lib/features/admin/quotes_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/themes/app_theme_extension.dart';
import '../../core/responsive/context_ext.dart';
import '../../core/constants/app_languages.dart';
import '../../models/quote_model.dart';
import '../../l10n/app_localizations.dart';

/// Admin screen for managing daily motivational quotes
class QuotesManagementScreen extends StatefulWidget {
  const QuotesManagementScreen({super.key});

  @override
  State<QuotesManagementScreen> createState() => _QuotesManagementScreenState();
}

class _QuotesManagementScreenState extends State<QuotesManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<QuoteModel> _quotes = [];
  bool _isLoading = true;
  int _version = 1;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);

    try {
      final doc =
          await _firestore.collection('app_config').doc('daily_quotes').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final quotesData = data['quotes'] as List<dynamic>? ?? [];
        _version = data['version'] as int? ?? 1;

        _quotes = quotesData
            .map((item) => QuoteModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        // Initialize empty document if not exists
        await _initializeQuotesDocument();
      }
    } catch (e) {
      debugPrint('❌ Error loading quotes: $e');
      _showErrorSnackBar('Error loading quotes: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeQuotesDocument() async {
    try {
      await _firestore.collection('app_config').doc('daily_quotes').set({
        'version': 1,
        'lastUpdated': FieldValue.serverTimestamp(),
        'quotes': [],
      });
      debugPrint('✅ Initialized daily_quotes document');
    } catch (e) {
      debugPrint('❌ Error initializing quotes document: $e');
    }
  }

  Future<void> _saveQuotes() async {
    try {
      await _firestore.collection('app_config').doc('daily_quotes').set({
        'version': _version + 1,
        'lastUpdated': FieldValue.serverTimestamp(),
        'quotes': _quotes.map((q) => q.toMap()).toList(),
      });

      _version++;
      if (mounted) {
        _showSuccessSnackBar(AppLocalizations.of(context).changesSaved);
      }
    } catch (e) {
      debugPrint('❌ Error saving quotes: $e');
      if (mounted) {
        _showErrorSnackBar('Error saving quotes: $e');
      }
    }
  }

  void _addQuote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditQuoteScreen(
          onSave: (quote) {
            setState(() {
              _quotes.add(quote);
            });
            _saveQuotes();
          },
        ),
      ),
    );
  }

  void _editQuote(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditQuoteScreen(
          quoteToEdit: _quotes[index],
          onSave: (quote) {
            setState(() {
              _quotes[index] = quote;
            });
            _saveQuotes();
          },
        ),
      ),
    );
  }

  Future<void> _deleteQuote(int index) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteQuoteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _quotes.removeAt(index);
      });
      await _saveQuotes();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = context.isTablet;
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
          l10n.dailyQuotes,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: colors.textPrimary),
            onPressed: _addQuote,
            tooltip: l10n.addQuote,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.textPrimary),
            )
          : _quotes.isEmpty
              ? _buildEmptyState(colors, isTablet, l10n)
              : _buildQuotesList(colors, isTablet),
    );
  }

  Widget _buildEmptyState(
      AppThemeExtension colors, bool isTablet, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_quote,
            size: isTablet ? 80.sp : 64.sp,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.noQuotesYet,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.addYourFirstQuote,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 12.sp,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _addQuote,
            icon: const Icon(Icons.add),
            label: Text(l10n.addQuote),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.textOnPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesList(AppThemeExtension colors, bool isTablet) {
    final currentLang = Localizations.localeOf(context).languageCode;

    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 24.w : 16.w),
      itemCount: _quotes.length,
      itemBuilder: (context, index) {
        final quote = _quotes[index];
        return _buildQuoteCard(quote, index, colors, isTablet, currentLang);
      },
    );
  }

  Widget _buildQuoteCard(
    QuoteModel quote,
    int index,
    AppThemeExtension colors,
    bool isTablet,
    String currentLang,
  ) {
    final quoteText = quote.getText(currentLang);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(isTablet ? 16.r : 14.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editQuote(index),
          borderRadius: BorderRadius.circular(isTablet ? 16.r : 14.r),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16.w : 14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quote text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: (isTablet ? 20.sp : 18.sp).clamp(16.0, 22.0),
                      color: colors.textSecondary.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quoteText.isNotEmpty ? quoteText : '(No translation)',
                        style: GoogleFonts.inter(
                          fontSize:
                              (isTablet ? 14.sp : 13.sp).clamp(12.0, 16.0),
                          fontStyle: FontStyle.italic,
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Actions
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: colors.textSecondary,
                        size: isTablet ? 22.sp : 20.sp,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editQuote(index);
                        } else if (value == 'delete') {
                          _deleteQuote(index);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 18),
                              SizedBox(width: 8.w),
                              Text(AppLocalizations.of(context).edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8.w),
                              Text(
                                AppLocalizations.of(context).delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Author
                if (quote.author != null && quote.author!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    '— ${quote.author}',
                    style: GoogleFonts.inter(
                      fontSize: (isTablet ? 12.sp : 11.sp).clamp(10.0, 14.0),
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],

                SizedBox(height: 10.h),

                // Tags
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    // Categories
                    ...quote.categories.take(3).map((cat) => _buildTag(
                          cat,
                          colors.textPrimary.withValues(alpha: 0.1),
                          colors.textPrimary,
                          isTablet,
                        )),
                    // Goals
                    ...quote.targetGoals.take(2).map((goal) => _buildTag(
                          goal,
                          Colors.green.withValues(alpha: 0.1),
                          Colors.green,
                          isTablet,
                        )),
                    // Language count
                    _buildTag(
                      '${quote.text.length} ${AppLocalizations.of(context).languages}',
                      Colors.blue.withValues(alpha: 0.1),
                      Colors.blue,
                      isTablet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10.w : 8.w,
        vertical: isTablet ? 4.h : 3.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: (isTablet ? 10.sp : 9.sp).clamp(8.0, 12.0),
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

// =================== ADD/EDIT QUOTE SCREEN ===================

class AddEditQuoteScreen extends StatefulWidget {
  final QuoteModel? quoteToEdit;
  final Function(QuoteModel) onSave;

  const AddEditQuoteScreen({
    super.key,
    this.quoteToEdit,
    required this.onSave,
  });

  @override
  State<AddEditQuoteScreen> createState() => _AddEditQuoteScreenState();
}

class _AddEditQuoteScreenState extends State<AddEditQuoteScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for each language
  late final Map<String, TextEditingController> _textControllers;
  late final TextEditingController _authorController;

  // Selected values
  String _selectedLanguage = 'en';
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedGoals = {};

  // Available options
  final List<String> _availableCategories = [
    'morning',
    'afternoon',
    'evening',
    'night',
    'sleep',
    'motivation',
    'achievement',
    'general',
  ];

  final List<String> _availableGoals = [
    'Health',
    'Confidence',
    'Energy',
    'Better Sleep',
    'Anxiety Relief',
    'Emotional Balance',
  ];

  bool get _isEditing => widget.quoteToEdit != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _textControllers = {
      for (final lang in AppLanguages.supportedLanguages)
        lang: TextEditingController()
    };
    _authorController = TextEditingController();

    // Load existing data if editing
    if (_isEditing) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final quote = widget.quoteToEdit!;

    // Load texts
    quote.text.forEach((lang, text) {
      if (_textControllers.containsKey(lang)) {
        _textControllers[lang]!.text = text;
      }
    });

    // Load author
    _authorController.text = quote.author ?? '';

    // Load categories and goals
    _selectedCategories.addAll(quote.categories);
    _selectedGoals.addAll(quote.targetGoals);
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    _authorController.dispose();
    super.dispose();
  }

  void _saveQuote() {
    if (!_formKey.currentState!.validate()) return;

    // Build text map (only non-empty)
    final textMap = <String, String>{};
    _textControllers.forEach((lang, controller) {
      if (controller.text.trim().isNotEmpty) {
        textMap[lang] = controller.text.trim();
      }
    });

    if (textMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).pleaseEnterAtLeastOneTranslation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quote = QuoteModel(
      id: _isEditing
          ? widget.quoteToEdit!.id
          : 'q${DateTime.now().millisecondsSinceEpoch}',
      text: textMap,
      author: _authorController.text.trim().isNotEmpty
          ? _authorController.text.trim()
          : null,
      categories: _selectedCategories.toList(),
      targetGoals: _selectedGoals.toList(),
    );

    widget.onSave(quote);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = context.isTablet;
    final l10n = AppLocalizations.of(context);

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
          _isEditing ? l10n.editQuote : l10n.addQuote,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveQuote,
            child: Text(
              l10n.save,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16.sp : 14.sp,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24.w : 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language selector
              _buildLanguageSelector(colors, isTablet),

              SizedBox(height: 20.h),

              // Quote text input
              _buildQuoteTextInput(colors, isTablet, l10n),

              SizedBox(height: 20.h),

              // Author input
              _buildAuthorInput(colors, isTablet, l10n),

              SizedBox(height: 24.h),

              // Categories
              _buildCategoriesSection(colors, isTablet, l10n),

              SizedBox(height: 24.h),

              // Target Goals
              _buildGoalsSection(colors, isTablet, l10n),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(AppThemeExtension colors, bool isTablet) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppLanguages.supportedLanguages.map((lang) {
          final isSelected = _selectedLanguage == lang;
          final hasText = _textControllers[lang]?.text.isNotEmpty ?? false;

          return GestureDetector(
            onTap: () => setState(() => _selectedLanguage = lang),
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16.w : 12.w,
                vertical: isTablet ? 10.h : 8.h,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.textPrimary : colors.backgroundCard,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isSelected
                      ? colors.textPrimary
                      : hasText
                          ? Colors.green
                          : colors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLanguages.getName(lang),
                    style: GoogleFonts.inter(
                      fontSize: (isTablet ? 14.sp : 12.sp).clamp(11.0, 15.0),
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colors.textOnPrimary
                          : colors.textPrimary,
                    ),
                  ),
                  if (hasText) ...[
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.check_circle,
                      size: 14.sp,
                      color: isSelected ? colors.textOnPrimary : Colors.green,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuoteTextInput(
      AppThemeExtension colors, bool isTablet, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.quoteText} (${AppLanguages.getName(_selectedLanguage)})',
          style: GoogleFonts.inter(
            fontSize: (isTablet ? 14.sp : 13.sp).clamp(12.0, 16.0),
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _textControllers[_selectedLanguage],
          maxLines: 4,
          style: GoogleFonts.inter(
            fontSize: (isTablet ? 15.sp : 14.sp).clamp(13.0, 17.0),
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: l10n.enterQuoteText,
            hintStyle: GoogleFonts.inter(
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: colors.backgroundCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.textPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorInput(
      AppThemeExtension colors, bool isTablet, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.author} (${l10n.optional})',
          style: GoogleFonts.inter(
            fontSize: (isTablet ? 14.sp : 13.sp).clamp(12.0, 16.0),
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _authorController,
          style: GoogleFonts.inter(
            fontSize: (isTablet ? 15.sp : 14.sp).clamp(13.0, 17.0),
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: l10n.enterAuthorName,
            hintStyle: GoogleFonts.inter(
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: colors.backgroundCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.textPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(
      AppThemeExtension colors, bool isTablet, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.categories,
          style: GoogleFonts.inter(
            fontSize: (isTablet ? 14.sp : 13.sp).clamp(12.0, 16.0),
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          l10n.selectWhenToShowQuote,
          style: GoogleFonts.inter(
            fontSize: (isTablet ? 12.sp : 11.sp).clamp(10.0, 14.0),
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _availableCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategories.remove(category);
                  } else {
                    _selectedCategories.add(category);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14.w : 12.w,
                  vertical: isTablet ? 8.h : 6.h,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? colors.textPrimary : colors.backgroundCard,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? colors.textPrimary : colors.border,
                  ),
                ),
                child: Text(
                  _getCategoryDisplayName(category, l10n),
                  style: GoogleFonts.inter(
                    fontSize: (isTablet ? 13.sp : 12.sp).clamp(11.0, 15.0),
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected ? colors.textOnPrimary : colors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGoalsSection(
      AppThemeExtension colors, bool isTablet, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.targetGoals,
          style: GoogleFonts.inter(
            fontSize: (isTablet ? 14.sp : 13.sp).clamp(12.0, 16.0),
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          l10n.selectMatchingGoals,
          style: GoogleFonts.inter(
            fontSize: (isTablet ? 12.sp : 11.sp).clamp(10.0, 14.0),
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _availableGoals.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGoals.remove(goal);
                  } else {
                    _selectedGoals.add(goal);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14.w : 12.w,
                  vertical: isTablet ? 8.h : 6.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : colors.backgroundCard,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? Colors.green : colors.border,
                  ),
                ),
                child: Text(
                  _getGoalDisplayName(goal, l10n),
                  style: GoogleFonts.inter(
                    fontSize: (isTablet ? 13.sp : 12.sp).clamp(11.0, 15.0),
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : colors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getCategoryDisplayName(String category, AppLocalizations l10n) {
    switch (category) {
      case 'morning':
        return l10n.morning;
      case 'afternoon':
        return l10n.afternoon;
      case 'evening':
        return l10n.evening;
      case 'night':
        return l10n.night;
      case 'sleep':
        return l10n.sleep;
      case 'motivation':
        return l10n.motivation;
      case 'achievement':
        return l10n.achievement;
      case 'general':
        return l10n.general;
      default:
        return category;
    }
  }

  String _getGoalDisplayName(String goal, AppLocalizations l10n) {
    switch (goal) {
      case 'Health':
        return l10n.health;
      case 'Confidence':
        return l10n.confidence;
      case 'Energy':
        return l10n.energy;
      case 'Better Sleep':
        return l10n.betterSleep;
      case 'Anxiety Relief':
        return l10n.anxietyRelief;
      case 'Emotional Balance':
        return l10n.emotionalBalance;
      default:
        return goal;
    }
  }
}
