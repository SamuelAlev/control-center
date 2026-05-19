import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:flutter/material.dart';

/// Resolved color palette for the diff viewer — addition/deletion backgrounds,
/// status accents, drag-selection highlight, search highlights, comment-thread
/// resolved accent, and the syntax-highlighting palette used by
/// `diff_precompute.dart`.
///
/// The palette tracks the active app brightness via [DiffPalette.of]. Two
/// hand-tuned palettes (Light and Dark) ship at launch — both modeled on
/// GitHub's diff colors. The syntax-highlighting maps live in
/// `shared/utils/syntax_palette.dart` (shared with the markdown code-block
/// renderer); extend those and the named constants in the constructor below.
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
    syntax: lightSyntaxPalette,
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
    syntax: darkSyntaxPalette,
  );
}
