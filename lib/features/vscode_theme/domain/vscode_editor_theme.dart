import 'package:flutter/widgets.dart';

/// A small, color-scheme-aware editor theme distilled from a VS Code theme, so
/// CC's embedded diff/editor can match the colors a user already reads code in.
///
/// Only the handful of roles CC's diff/code surfaces actually use are kept; the
/// full VS Code token-color list is collapsed into a compact [syntax] map.
@immutable
class VsCodeEditorTheme {
  /// Creates a [VsCodeEditorTheme].
  const VsCodeEditorTheme({
    required this.name,
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.lineNumber,
    required this.addedBackground,
    required this.removedBackground,
    required this.selection,
    this.syntax = const {},
  });

  /// Display name of the imported theme.
  final String name;

  /// Whether the theme is light or dark.
  final Brightness brightness;

  /// Editor background.
  final Color background;

  /// Default editor foreground.
  final Color foreground;

  /// Gutter line-number color.
  final Color lineNumber;

  /// Added-line background (diff insert).
  final Color addedBackground;

  /// Removed-line background (diff delete).
  final Color removedBackground;

  /// Selection background.
  final Color selection;

  /// Compact syntax-role → color map (`keyword`, `string`, `comment`,
  /// `function`, `number`, `type`).
  final Map<String, Color> syntax;

  /// The color for a syntax [role], falling back to [foreground].
  Color syntaxColor(String role) => syntax[role] ?? foreground;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VsCodeEditorTheme &&
          name == other.name &&
          brightness == other.brightness &&
          background == other.background &&
          foreground == other.foreground &&
          lineNumber == other.lineNumber &&
          addedBackground == other.addedBackground &&
          removedBackground == other.removedBackground &&
          selection == other.selection;

  @override
  int get hashCode => Object.hash(
    name,
    brightness,
    background,
    foreground,
    lineNumber,
    addedBackground,
    removedBackground,
    selection,
  );
}
