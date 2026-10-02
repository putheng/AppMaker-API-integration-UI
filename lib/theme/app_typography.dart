import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design system type scale.
///
/// Uses the platform system font with a tight, professional scale
/// suitable for a dense builder/tooling UI.
abstract final class AppTypography {
  static const String fontFamily = 'SF Pro Text';
  static const List<String> fontFamilyFallback = [
    '.SF Pro Text',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
  ];

  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 26,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.textTertiary,
  );

  static const TextStyle code = TextStyle(
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamily: 'SF Mono',
    fontFamilyFallback: ['Menlo', 'Consolas', 'monospace'],
    color: AppColors.textPrimary,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
