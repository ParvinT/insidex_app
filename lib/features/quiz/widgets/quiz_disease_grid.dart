// lib/features/quiz/widgets/quiz_disease_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../models/disease_model.dart';
import 'disease_card.dart';

class QuizDiseaseGrid extends StatelessWidget {
  final List<DiseaseModel> diseases;
  final Set<String> selectedDiseaseIds;
  final int maxSelection;
  final int currentPage;
  final int itemsPerPage;
  final bool isTablet;
  final PageController pageController;
  final AnimationController staggerController;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onDiseaseToggle;

  const QuizDiseaseGrid({
    super.key,
    required this.diseases,
    required this.selectedDiseaseIds,
    required this.maxSelection,
    required this.currentPage,
    required this.itemsPerPage,
    required this.isTablet,
    required this.pageController,
    required this.staggerController,
    required this.onPageChanged,
    required this.onDiseaseToggle,
  });

  int get _totalPages {
    if (diseases.isEmpty) return 0;
    return (diseases.length / itemsPerPage).ceil();
  }

  bool get _isMaxSelected => selectedDiseaseIds.length >= maxSelection;

  bool _isDiseaseSelected(String diseaseId) {
    return selectedDiseaseIds.contains(diseaseId);
  }

  double _calculateGridHeight(BuildContext context) {
    if (diseases.isEmpty) return 200.h;

    // Calculate items on current page (max 10)
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, diseases.length);
    final itemCount = endIndex - startIndex;

    if (itemCount == 0) return 200.h;

    // 2 columns -> max 5 rows
    final rows = (itemCount / 2).ceil();

    final double itemHeight;
    if (context.isDesktop) {
      itemHeight = 56.h;
    } else if (isTablet) {
      itemHeight = 54.h;
    } else {
      itemHeight = 50.h;
    }

    final spacing = 10.h;
    final topBottomPadding = 16.h;

    final gridHeight =
        (rows * itemHeight) + ((rows - 1) * spacing) + topBottomPadding;

    final double maxHeight;
    if (context.isDesktop) {
      maxHeight = 350.h;
    } else if (isTablet) {
      maxHeight = 300.h;
    } else {
      final screenHeight = context.h;
      if (screenHeight <= 667) {
        maxHeight = 220.h;
      } else if (screenHeight <= 736) {
        maxHeight = 240.h;
      } else if (screenHeight <= 812) {
        maxHeight = 260.h;
      } else {
        maxHeight = 280.h;
      }
    }

    return gridHeight.clamp(100.h, maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Horizontal PageView for disease grid
        SizedBox(
          height: _calculateGridHeight(context),
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: _totalPages,
            itemBuilder: (context, pageIndex) {
              return _buildDiseaseGrid(context, pageIndex);
            },
          ),
        ),
        _buildPaginationControls(context),
        SizedBox(height: 6.h),
      ],
    );
  }

  Widget _buildDiseaseGrid(BuildContext context, int pageIndex) {
    final startIndex = pageIndex * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, diseases.length);

    if (startIndex >= diseases.length) {
      return const SizedBox.shrink();
    }
    final pageDiseases = diseases.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        const crossAxisCount = 2;
        final horizontalPadding = 4.w;
        final crossAxisSpacing = 10.w;

        final totalHorizontalPadding = horizontalPadding * 2;
        final totalSpacing = crossAxisSpacing * (crossAxisCount - 1);
        final itemWidth =
            (availableWidth - totalHorizontalPadding - totalSpacing) /
                crossAxisCount;

        final rows = (pageDiseases.length / crossAxisCount).ceil();
        final mainAxisSpacing = 10.h;

        final verticalPadding = 8.h;
        final totalVerticalPadding = verticalPadding * 2;
        final totalVerticalSpacing = mainAxisSpacing * (rows - 1);

        final availableHeightForItems =
            availableHeight - totalVerticalPadding - totalVerticalSpacing;
        final itemHeight = availableHeightForItems / rows;

        final childAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: pageDiseases.length,
          itemBuilder: (context, index) {
            final disease = pageDiseases[index];
            final isSelected = _isDiseaseSelected(disease.id);
            final isDisabled = _isMaxSelected && !isSelected;

            // Staggered animation for each card
            final startInterval = (index * 0.1).clamp(0.0, 0.6);
            final endInterval = (startInterval + 0.4).clamp(0.0, 1.0);

            final itemAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: staggerController,
              curve: Interval(
                startInterval,
                endInterval,
                curve: Curves.easeOutBack,
              ),
            ));

            return AnimatedBuilder(
              animation: itemAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.5 + (0.5 * itemAnimation.value),
                  child: Opacity(
                    opacity: itemAnimation.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: DiseaseCard(
                disease: disease,
                isSelected: isSelected,
                isDisabled: isDisabled,
                onTap: () => onDiseaseToggle(disease.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    if (_totalPages <= 1) return const SizedBox.shrink();
    final colors = context.colors;

    final double dotSize = isTablet ? 8.0 : 7.0;
    final double spacing = isTablet ? 8.0 : 6.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: SmoothPageIndicator(
        controller: pageController,
        count: _totalPages,
        onDotClicked: (index) => _goToPage(index),
        effect: ScrollingDotsEffect(
          dotHeight: dotSize,
          dotWidth: dotSize,
          activeDotColor: colors.textPrimary,
          dotColor: colors.border.withValues(alpha: 0.4),
          spacing: spacing,
          maxVisibleDots: 7,
          activeDotScale: 1.4,
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
