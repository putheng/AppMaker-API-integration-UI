import 'package:flutter/material.dart';

/// Spacing tokens on a 4px base scale.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard interactive control height (buttons, dropdowns, inputs).
  static const double control = 44;

  /// Default page padding.
  static const EdgeInsets page = EdgeInsets.all(xl);

  /// Default card padding.
  static const EdgeInsets card = EdgeInsets.all(lg);
}

/// Corner radius tokens.
abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Motion tokens.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
}
