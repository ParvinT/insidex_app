// lib/core/responsive/spacing.dart
import 'context_ext.dart';

double gapXs(c) => c.isTablet ? 10 : 8;
double gapSm(c) => c.isTablet ? 14 : 12;
double gapMd(c) => c.isTablet ? 18 : 16;
double gapLg(c) => c.isTablet ? 24 : 20;
double pageHPad(c) => c.isTablet ? 32 : 16;
