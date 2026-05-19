import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:flutter/material.dart';

/// GitHub-fidelity status colors shared by the PR detail's CI/review surfaces:
/// the sidebar checks summary, the diff toolbar's `+`/`−` counts, and the
/// reviewer-state dots.
///
/// These mirror GitHub's learned status color language and are a sanctioned
/// **domain palette** (see DESIGN.md, "Diff viewer") — a deliberate exception
/// to the One Signal Rule because developers read CI and review state in a
/// fixed color vocabulary. They live here, in one place, rather than as hex
/// literals copied across widgets, so the green/red/blue never drift apart.
/// They intentionally match `DiffPalette`'s addition / deletion / modified
/// accents so the diff body and its surrounding chrome agree.
abstract final class ReviewStatusColors {
  const ReviewStatusColors._();

  /// Passing checks, approvals, additions — GitHub green.
  static const Color success = Color(0xFF2DA44E);

  /// Failing checks, requested changes, deletions — GitHub red.
  static const Color failure = Color(0xFFCF222E);

  /// Running / in-progress checks, modified state — GitHub blue.
  static const Color running = Color(0xFF1F75FE);

  /// Cancelled / skipped / neutral conclusions — design-system gray.
  static const Color neutral = DesignSystemPalette.gray500;
}
