import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Text styles for widgets that build on `flutter/widgets.dart` only.
///
/// `Theme.of(context).textTheme` is a Material API, and the vendor-isolation
/// ratchet keeps `flutter/material.dart` out of new UI. These are the same
/// roles, resolved from design tokens and [CcFonts] instead — so a widgets-only
/// component gets consistent type without reaching for Material.
///
/// Sizes intentionally match the Material roles the app already uses, so a
/// migrated widget looks unchanged.
abstract final class AppTextStyles {
  const AppTextStyles._();

  /// 11px, tight — badges, axis ticks, captions.
  static TextStyle labelSmall(DesignSystemTokens tokens) => TextStyle(
    fontFamily: CcFonts.uiFamily,
    fontSize: 11,
    height: 1.35,
    color: tokens.textSecondary,
  );

  /// 14px semibold — a section or card title.
  static TextStyle labelLarge(DesignSystemTokens tokens) => TextStyle(
    fontFamily: CcFonts.uiFamily,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: tokens.textPrimary,
  );

  /// 12px — secondary body copy.
  static TextStyle bodySmall(DesignSystemTokens tokens) => TextStyle(
    fontFamily: CcFonts.uiFamily,
    fontSize: 12,
    height: 1.45,
    color: tokens.textPrimary,
  );

  /// 14px — primary body copy.
  static TextStyle bodyMedium(DesignSystemTokens tokens) => TextStyle(
    fontFamily: CcFonts.uiFamily,
    fontSize: 14,
    height: 1.45,
    color: tokens.textPrimary,
  );

  /// 11.5px monospace — code, JSON, identifiers.
  static TextStyle mono(DesignSystemTokens tokens) => TextStyle(
    fontFamily: CcFonts.codeFamily,
    fontSize: 11.5,
    height: 1.4,
    color: tokens.textPrimary,
  );
}
