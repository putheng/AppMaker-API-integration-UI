import 'package:flutter/material.dart';

/// Design system color tokens.
///
/// Professional dark palette: deep blue-tinted neutrals with an
/// indigo primary accent and clear semantic colors.
abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0C10);
  static const Color surface = Color(0xFF12151B);
  static const Color surfaceElevated = Color(0xFF1A1E26);
  static const Color surfaceHover = Color(0xFF20252F);

  // Borders & dividers
  static const Color border = Color(0xFF262B35);
  static const Color borderStrong = Color(0xFF343B48);
  static const Color divider = Color(0xFF1E232C);

  // Brand
  static const Color primary = Color(0xFF6E7CF6);
  static const Color primaryHover = Color(0xFF8591F8);
  static const Color primaryPressed = Color(0xFF5A68E8);
  static const Color primarySubtle = Color(0x1F6E7CF6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFF2F4F8);
  static const Color textSecondary = Color(0xFF9AA3B2);
  static const Color textTertiary = Color(0xFF5C6470);
  static const Color textDisabled = Color(0xFF454C58);

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color successSubtle = Color(0x1F34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningSubtle = Color(0x1FFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color errorSubtle = Color(0x1FF87171);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoSubtle = Color(0x1F60A5FA);

  // Misc
  static const Color scrim = Color(0xB30A0C10);
  static const Color focusRing = Color(0xFF8591F8);

  static const ColorScheme darkScheme = ColorScheme.dark(
    surface: background,
    surfaceContainerLow: surface,
    surfaceContainer: surface,
    surfaceContainerHigh: surfaceElevated,
    surfaceContainerHighest: surfaceHover,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryPressed,
    onPrimaryContainer: onPrimary,
    secondary: info,
    onSecondary: Color(0xFF0A0C10),
    tertiary: success,
    onTertiary: Color(0xFF0A0C10),
    error: error,
    onError: Color(0xFF0A0C10),
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    outline: border,
    outlineVariant: divider,
    scrim: scrim,
  );
}
