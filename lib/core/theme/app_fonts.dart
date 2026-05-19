import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised font helpers — Manrope for UI, JetBrains Mono for code.
///
/// Call sites pass in style overrides (size, weight, color, etc.) and get back
/// a [TextStyle] with the correct font family wired up via `google_fonts`.
class AppFonts {
  AppFonts._();

  // ── Default static helpers (backward-compatible) ──

  /// UI / body text in Manrope.
  static TextStyle ui({TextStyle? textStyle}) =>
      GoogleFonts.manrope(textStyle: textStyle);

  /// Code / monospace text in JetBrains Mono.
  static TextStyle code({TextStyle? textStyle}) =>
      GoogleFonts.jetBrainsMono(textStyle: textStyle);

  /// Convenience overload for the common shape — direct style fields without
  /// having to wrap them in a `TextStyle(...)` first.
  static TextStyle codeStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Color? backgroundColor,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    backgroundColor: backgroundColor,
    height: height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );

  /// Apply Manrope to every entry in [base] — used by the app theme.
  static TextTheme manropeTextTheme(TextTheme base) =>
      GoogleFonts.manropeTextTheme(base);

  // ── Dynamic helpers for user-selected fonts ──

  /// UI text style using the given font family (Google Fonts or system).
  static TextStyle uiDynamic(String family, {TextStyle? textStyle}) {
    if (GoogleFonts.asMap().containsKey(family)) {
      return GoogleFonts.getFont(family, textStyle: textStyle);
    }
    return (textStyle ?? const TextStyle()).copyWith(fontFamily: family);
  }

  /// Code text style using the given font family (Google Fonts or system).
  static TextStyle codeDynamic(String family, {TextStyle? textStyle}) {
    if (GoogleFonts.asMap().containsKey(family)) {
      return GoogleFonts.getFont(family, textStyle: textStyle);
    }
    return (textStyle ?? const TextStyle()).copyWith(fontFamily: family);
  }

  /// Code style dynamic.
  static TextStyle codeStyleDynamic(
    String family, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Color? backgroundColor,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) {
    if (GoogleFonts.asMap().containsKey(family)) {
      return GoogleFonts.getFont(
        family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        backgroundColor: backgroundColor,
        height: height,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
      );
    }
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      backgroundColor: backgroundColor,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );
  }

  /// Apply any Google Font family to a TextTheme.
  static TextTheme textThemeFor(String family, TextTheme base) =>
      GoogleFonts.getTextTheme(family, base);

  /// Load a system font from a file path and register it with Flutter's
  /// [FontLoader]. Returns true if successful.
  static Future<bool> loadSystemFont(String family, String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return false;
    }

    final bytes = await file.readAsBytes();
    final fontLoader = FontLoader(family);
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
    return true;
  }
}

