// lib/features/admin/widgets/admin_search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../l10n/app_localizations.dart';

/// Admin Search Bar Widget
///
/// A reusable search bar component designed for admin panel screens.
/// Features:
/// - Debounced search (300ms default) to prevent excessive queries
/// - Clear button when text is present
/// - Consistent styling with admin panel theme
/// - Callback-based architecture for flexibility
///
/// Usage:
/// ```dart
/// AdminSearchBar(
///   hintText: l10n.searchSessions, // or custom hint
///   onSearchChanged: (query) {
///     setState(() => _searchQuery = query);
///   },
///   onClear: () {
///     setState(() => _searchQuery = '');
///   },
/// )
/// ```
class AdminSearchBar extends StatefulWidget {
  /// Hint text displayed when search field is empty
  /// If null, defaults to l10n.searchSessions ("Search...")
  final String? hintText;

  /// Callback fired when search query changes (after debounce)
  final ValueChanged<String>? onSearchChanged;

  /// Callback fired when clear button is pressed
  final VoidCallback? onClear;

  /// Callback fired on each keystroke (no debounce)
  final ValueChanged<String>? onChanged;

  /// Debounce duration in milliseconds (default: 300ms)
  final int debounceDuration;

  /// Whether the search bar is enabled
  final bool enabled;

  /// Optional controller for external control
  final TextEditingController? controller;

  /// Auto focus on mount
  final bool autofocus;

  const AdminSearchBar({
    super.key,
    this.hintText,
    this.onSearchChanged,
    this.onClear,
    this.onChanged,
    this.debounceDuration = 300,
    this.enabled = true,
    this.controller,
    this.autofocus = false,
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Fire immediate callback (no debounce)
    widget.onChanged?.call(_controller.text);

    // Fire debounced callback
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: widget.debounceDuration),
      () {
        widget.onSearchChanged?.call(_controller.text);
      },
    );
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: colors.greyLight,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.inter(
          fontSize: 15.sp,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? l10n.searchSessions,
          hintStyle: GoogleFonts.inter(
            fontSize: 15.sp,
            color: colors.textSecondary.withValues(alpha: 0.7),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 14.w, right: 10.w),
            child: Icon(
              Icons.search_rounded,
              color: colors.textSecondary,
              size: 22.sp,
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 46.w,
            minHeight: 22.h,
          ),
          suffixIcon: _hasText
              ? GestureDetector(
                  onTap: _clearSearch,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 18.sp,
                      ),
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: BoxConstraints(
            minWidth: 40.w,
            minHeight: 32.h,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }
}

/// Admin Search Bar with Result Count
///
/// An extended version that shows the number of results
/// Uses existing localization key: foundResults ("{count} results found")
///
/// Usage:
/// ```dart
/// AdminSearchBarWithCount(
///   hintText: l10n.adminSearchUsers,
///   resultCount: filteredUsers.length,
///   totalCount: allUsers.length,
///   onSearchChanged: (query) => setState(() => _query = query),
/// )
/// ```
class AdminSearchBarWithCount extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClear;
  final int resultCount;
  final int totalCount;
  final bool isSearching;
  final TextEditingController? controller;

  const AdminSearchBarWithCount({
    super.key,
    this.hintText,
    this.onSearchChanged,
    this.onClear,
    required this.resultCount,
    required this.totalCount,
    this.isSearching = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final hasQuery = controller?.text.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSearchBar(
          hintText: hintText,
          onSearchChanged: onSearchChanged,
          onClear: onClear,
          controller: controller,
        ),
        if (hasQuery) ...[
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: isSearching
                ? Row(
                    children: [
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${l10n.search}...',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    // Use existing foundResults key with format
                    l10n.foundResults(resultCount.toString()),
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: colors.textSecondary,
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

/// Compact Admin Search Bar
///
/// A smaller version for tight spaces like AppBar actions
class AdminSearchBarCompact extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClear;
  final double? width;

  const AdminSearchBarCompact({
    super.key,
    this.hintText,
    this.onSearchChanged,
    this.onClear,
    this.width,
  });

  @override
  State<AdminSearchBarCompact> createState() => _AdminSearchBarCompactState();
}

class _AdminSearchBarCompactState extends State<AdminSearchBarCompact> {
  bool _isExpanded = false;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _controller.clear();
        widget.onClear?.call();
        widget.onSearchChanged?.call('');
      }
    });
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 300),
      () {
        widget.onSearchChanged?.call(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? (widget.width ?? 200.w) : 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: _isExpanded ? colors.greyLight : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: _isExpanded
          ? Row(
              children: [
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onTextChanged,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? l10n.searchSessions,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: colors.textSecondary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleExpanded,
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textSecondary,
                    size: 20.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 36.w,
                    minHeight: 36.h,
                  ),
                ),
              ],
            )
          : IconButton(
              onPressed: _toggleExpanded,
              icon: Icon(
                Icons.search_rounded,
                color: colors.textPrimary,
                size: 24.sp,
              ),
              padding: EdgeInsets.zero,
            ),
    );
  }
}
