import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/features/pr_review/presentation/utils/word_diff.dart'
    show kAdditionWordBgKey, kDeletionWordBgKey;
import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:flutter/material.dart';

/// Resolved color palette for the diff viewer — addition/deletion backgrounds,
/// status accents, drag-selection highlight, search highlights, comment-thread
/// resolved accent and the syntax-highlighting palette used by
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
    required this.additionGutterBg,
    required this.deletionGutterBg,
    required this.additionGutterFg,
    required this.deletionGutterFg,
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

  /// Line-number gutter tint on added rows (GitHub's stronger number-column
  /// tint).
  final Color additionGutterBg;

  /// Line-number gutter tint on removed rows.
  final Color deletionGutterBg;

  /// Line-number text on added rows.
  final Color additionGutterFg;

  /// Line-number text on removed rows.
  final Color deletionGutterFg;

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

  /// The palette slice shipped into the diff worker for `applyInlineWordDiff`:
  /// the `addition`/`deletion` fallback tints plus the [kAdditionWordBgKey] /
  /// [kDeletionWordBgKey] word-emphasis backgrounds (syntax colors themselves
  /// are baked in at tokenize time by the CC shiki theme). Kept as ARGB ints
  /// (not [Color]s) so it crosses the isolate boundary without depending on
  /// `flutter/material`.
  final Map<String, int> syntax;

  // Add/delete backgrounds + accents come from the shared [DiffColors] source
  // so the PR diff, messaging diff and session-review diff stay identical.
  static final DiffColors _lightDiff = DiffColors.forBrightness(
    Brightness.light,
  );
  static final DiffColors _darkDiff = DiffColors.forBrightness(Brightness.dark);

  static final DiffPalette _light = DiffPalette(
    brightness: Brightness.light,
    additionBg: _lightDiff.additionBg,
    deletionBg: _lightDiff.deletionBg,
    additionGutterBg: _lightDiff.additionGutterBg,
    deletionGutterBg: _lightDiff.deletionGutterBg,
    additionGutterFg: _lightDiff.additionGutterFg,
    deletionGutterFg: _lightDiff.deletionGutterFg,
    additionAccent: _lightDiff.additionAccent,
    deletionAccent: _lightDiff.deletionAccent,
    modifiedAccent: const Color(0xFF1F75FE),
    viewedAccent: const Color(0xFF1F75FE),
    searchMatchBg: const Color(0xFFFFD93D),
    currentSearchMatchBg: const Color(0xFFFF8C00),
    dragSelectionBg: const Color(0xFF1F75FE).withValues(alpha: 0.12),
    actionPillBg: const Color(0xFF111111),
    actionPillFg: Colors.white,
    resolvedThreadAccent: const Color(0xFF2DA44E),
    syntax: {
      ...lightSyntaxPalette,
      kAdditionWordBgKey: _lightDiff.additionWordBg.toARGB32(),
      kDeletionWordBgKey: _lightDiff.deletionWordBg.toARGB32(),
    },
  );

  static final DiffPalette _dark = DiffPalette(
    brightness: Brightness.dark,
    additionBg: _darkDiff.additionBg,
    deletionBg: _darkDiff.deletionBg,
    additionGutterBg: _darkDiff.additionGutterBg,
    deletionGutterBg: _darkDiff.deletionGutterBg,
    additionGutterFg: _darkDiff.additionGutterFg,
    deletionGutterFg: _darkDiff.deletionGutterFg,
    additionAccent: _darkDiff.additionAccent,
    deletionAccent: _darkDiff.deletionAccent,
    modifiedAccent: const Color(0xFF1F75FE),
    viewedAccent: const Color(0xFF1F75FE),
    searchMatchBg: const Color(0xFFFFD93D),
    currentSearchMatchBg: const Color(0xFFFF8C00),
    dragSelectionBg: const Color(0xFF1F75FE).withValues(alpha: 0.16),
    actionPillBg: const Color(0xFF111111),
    actionPillFg: Colors.white,
    resolvedThreadAccent: const Color(0xFF2DA44E),
    syntax: {
      ...darkSyntaxPalette,
      kAdditionWordBgKey: _darkDiff.additionWordBg.toARGB32(),
      kDeletionWordBgKey: _darkDiff.deletionWordBg.toARGB32(),
    },
  );
}
