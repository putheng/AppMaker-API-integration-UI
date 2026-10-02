import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the application [ThemeData] from design system tokens.
abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = AppColors.darkScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      textTheme: AppTypography.textTheme,
      visualDensity: VisualDensity.compact,
      dividerColor: AppColors.divider,
      focusColor: AppColors.primarySubtle,
      hoverColor: AppColors.surfaceHover,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSmall,
        shape: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceElevated,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(0, AppSpacing.control),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceElevated,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(0, AppSpacing.control),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(color: AppColors.border),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(0, AppSpacing.control),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          highlightColor: AppColors.surfaceHover,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        labelStyle: AppTypography.labelMedium,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.focusRing, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        labelStyle: AppTypography.labelMedium,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySubtle,
        selectedIconTheme: IconThemeData(color: AppColors.primary, size: 22),
        unselectedIconTheme: IconThemeData(
          color: AppColors.textTertiary,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTypography.bodyMedium,
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.surfaceHover,
          borderRadius: AppRadius.smAll,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.borderStrong),
          ),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.borderStrong),
        radius: Radius.circular(AppRadius.full),
        thickness: WidgetStatePropertyAll(6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceElevated,
        circularTrackColor: AppColors.surfaceElevated,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textSecondary,
          selectedBackgroundColor: AppColors.primarySubtle,
          selectedForegroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          textStyle: AppTypography.labelMedium,
          visualDensity: VisualDensity.compact,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceElevated,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primarySubtle,
        trackHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceElevated,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : AppColors.borderStrong,
        ),
      ),
    );
  }
}
