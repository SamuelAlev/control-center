import 'package:flutter/material.dart';

/// Resolved color palette for the diff viewer — addition/deletion backgrounds,
/// status accents, drag-selection highlight, search highlights, comment-thread
/// resolved accent, and the syntax-highlighting palette used by
/// `diff_precompute.dart`.
///
/// The palette tracks the active app brightness via [DiffPalette.of]. Two
/// hand-tuned palettes (Light and Dark) ship at launch — both modeled on
/// GitHub's diff colors. Add more by extending [_lightSyntax] / [_darkSyntax]
/// and the named constants in the constructor below.
@immutable
class DiffPalette {
  /// DiffPalette({.
  const DiffPalette({
    required this.brightness,
    required this.additionBg,
    required this.deletionBg,
    required this.additionAccent,
    required this.deletionAccent,
    required this.modifiedAccent,
    required this.viewedAccent,
    required this.searchMatchBg,
    required this.currentSearchMatchBg,
    required this.dragSelectionBg,
    required this.actionPillBg,
    required this.actionPillFg,
    required this.resolvedThreadAccent,
    required this.syntax,
  });

  /// Looks up the diff palette for the current theme brightness.
  factory DiffPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  /// Looks up the diff palette by an explicit brightness — used by the isolate
  /// precompute pipeline where [BuildContext] isn't available.
  factory DiffPalette.forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? _dark : _light;
  }

  /// Brightness.
  final Brightness brightness;

  /// Row backgrounds.
  final Color additionBg;
  /// Color.
  final Color deletionBg;

  /// Status-dot / chip accents (no transparency).
  final Color additionAccent; // GitHub green
  /// Color.
  final Color deletionAccent; // GitHub red
  /// Color.
  final Color modifiedAccent; // GitHub blue
  /// Color.
  final Color viewedAccent; // matches "modified" — same blue family

  /// Search highlights — fixed bright yellow / orange that pop on both themes.
  final Color searchMatchBg;
  /// Color.
  final Color currentSearchMatchBg;

  /// Range-selection highlight while dragging in the gutter.
  final Color dragSelectionBg;

  /// Floating dark pill used for the hover-only `[💬 + suggest + react]`
  /// affordance and the range-action pill.
  final Color actionPillBg;
  /// Color.
  final Color actionPillFg;

  /// Green check on a resolved comment thread.
  final Color resolvedThreadAccent;

  /// 28-token syntax-highlighting palette used by `highlight.dart` and the
  /// `applyInlineWordDiff` token mutator. Kept as ARGB ints (not [Color]s) so
  /// it can cross the isolate boundary without depending on
  /// `flutter/material`.
  final Map<String, int> syntax;

  static final DiffPalette _light = DiffPalette(
    brightness: Brightness.light,
    additionBg: const Color(0xFF2DA44E).withValues(alpha: 0.08),
    deletionBg: const Color(0xFFCF222E).withValues(alpha: 0.08),
    additionAccent: const Color(0xFF2DA44E),
    deletionAccent: const Color(0xFFCF222E),
    modifiedAccent: const Color(0xFF1F75FE),
    viewedAccent: const Color(0xFF1F75FE),
    searchMatchBg: const Color(0xFFFFD93D),
    currentSearchMatchBg: const Color(0xFFFF8C00),
    dragSelectionBg: const Color(0xFF1F75FE).withValues(alpha: 0.12),
    actionPillBg: const Color(0xFF111111),
    actionPillFg: Colors.white,
    resolvedThreadAccent: const Color(0xFF2DA44E),
    syntax: _lightSyntax,
  );

  static final DiffPalette _dark = DiffPalette(
    brightness: Brightness.dark,
    additionBg: const Color(0xFF2DA44E).withValues(alpha: 0.12),
    deletionBg: const Color(0xFFCF222E).withValues(alpha: 0.12),
    additionAccent: const Color(0xFF2DA44E),
    deletionAccent: const Color(0xFFCF222E),
    modifiedAccent: const Color(0xFF1F75FE),
    viewedAccent: const Color(0xFF1F75FE),
    searchMatchBg: const Color(0xFFFFD93D),
    currentSearchMatchBg: const Color(0xFFFF8C00),
    dragSelectionBg: const Color(0xFF1F75FE).withValues(alpha: 0.16),
    actionPillBg: const Color(0xFF111111),
    actionPillFg: Colors.white,
    resolvedThreadAccent: const Color(0xFF2DA44E),
    syntax: _darkSyntax,
  );
}

const Map<String, int> _lightSyntax = {
  'keyword': 0xFFCF222E,
  'literal': 0xFF0550AE,
  'symbol': 0xFFE36209,
  'name': 0xFF8250DF,
  'string': 0xFF0A3069,
  'subst': 0xFF0A3069,
  'regexp': 0xFF0A3069,
  'number': 0xFF0550AE,
  'comment': 0xFF6E7781,
  'doctag': 0xFF6E7781,
  'meta': 0xFFE36209,
  'type': 0xFFE36209,
  'class': 0xFFE36209,
  'title': 0xFF8250DF,
  'built_in': 0xFFE36209,
  'function': 0xFF8250DF,
  'tag': 0xFF116329,
  'attr': 0xFFE36209,
  'attribute': 0xFFE36209,
  'variable': 0xFF24292F,
  'params': 0xFF24292F,
  'selector-tag': 0xFF116329,
  'selector-id': 0xFF8250DF,
  'selector-class': 0xFF8250DF,
  'addition': 0xFF116329,
  'deletion': 0xFFCF222E,
};

const Map<String, int> _darkSyntax = {
  'keyword': 0xFFFF7B72,
  'literal': 0xFF79C0FF,
  'symbol': 0xFFFFA657,
  'name': 0xFFD2A8FF,
  'string': 0xFFA5D6FF,
  'subst': 0xFFA5D6FF,
  'regexp': 0xFFA5D6FF,
  'number': 0xFF79C0FF,
  'comment': 0xFF8B949E,
  'doctag': 0xFF8B949E,
  'meta': 0xFFFFA657,
  'type': 0xFFFFA657,
  'class': 0xFFFFA657,
  'title': 0xFFD2A8FF,
  'built_in': 0xFFFFA657,
  'function': 0xFFD2A8FF,
  'tag': 0xFF7EE787,
  'attr': 0xFFFFA657,
  'attribute': 0xFFFFA657,
  'variable': 0xFFE6EDF3,
  'params': 0xFFE6EDF3,
  'selector-tag': 0xFF7EE787,
  'selector-id': 0xFFD2A8FF,
  'selector-class': 0xFFD2A8FF,
  'addition': 0xFF7EE787,
  'deletion': 0xFFFF7B72,
};

