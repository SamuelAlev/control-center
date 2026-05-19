import 'package:flutter/widgets.dart';

/// Canonical spacing scale (4px base) for consistent vertical and horizontal
/// rhythm across the app.
///
/// Before this existed, spacing was ad-hoc `EdgeInsets`/`SizedBox` literals
/// with a long tail of one-off values. New chrome (sidebar, top bar, cockpit)
/// is built on these tokens; older surfaces migrate opportunistically.
abstract final class AppSpacing {
  const AppSpacing._();

  /// 2px -hairline gaps.
  static const double xxs = 2;

  /// 4px -tight gaps between closely related elements.
  static const double xs = 4;

  /// 8px -default small gap.
  static const double sm = 8;

  /// 12px -default gap between controls.
  static const double md = 12;

  /// 16px -default gap between groups.
  static const double lg = 16;

  /// 24px -section padding / large gap.
  static const double xl = 24;

  /// 32px -between major sections.
  static const double xxl = 32;

  /// 48px -page-level breathing room.
  static const double xxxl = 48;

  /// A vertical gap of [sm].
  static const SizedBox vGapSm = SizedBox(height: sm);

  /// A vertical gap of [md].
  static const SizedBox vGapMd = SizedBox(height: md);

  /// A vertical gap of [lg].
  static const SizedBox vGapLg = SizedBox(height: lg);

  /// A vertical gap of [xl].
  static const SizedBox vGapXl = SizedBox(height: xl);

  /// A horizontal gap of [sm].
  static const SizedBox hGapSm = SizedBox(width: sm);

  /// A horizontal gap of [md].
  static const SizedBox hGapMd = SizedBox(width: md);

  /// A horizontal gap of [lg].
  static const SizedBox hGapLg = SizedBox(width: lg);
}
