import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_row_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Per-frame visual configuration for the unified diff sliver. Cheap to
/// rebuild; the render object diffs it to decide between repaint and relayout.
@immutable
class UnifiedDiffPaintConfig {
  /// Creates a paint config.
  const UnifiedDiffPaintConfig({
    required this.brightness,
    required this.baseStyle,
    required this.gutterBgColor,
    required this.gutterBorderColor,
    required this.expandGapBgColor,
    required this.expandGapBorderColor,
    required this.expandGapTextColor,
    required this.commentHighlightColor,
    required this.commentHighlightActiveColor,
    this.gotoUnderlineColor = const Color(0xFFB0370C),
    required this.revision,
    this.topInset = 0,
    this.overflowMode = DiffOverflowMode.scroll,
    this.searchFile = -1,
    this.searchRawIndex = -1,
    this.splitMode = false,
  });

  /// Active theme brightness (drives colours; baked into cached paragraphs).
  final Brightness brightness;

  /// Base monospace text style.
  final TextStyle baseStyle;

  /// Opaque gutter background.
  final Color gutterBgColor;

  /// Gutter/code divider colour.
  final Color gutterBorderColor;

  /// Expand-gap row colours (the gap rows are widgets now, but the painter
  /// still uses these for any residual fills).
  final Color expandGapBgColor;

  /// Expand-gap border colour.
  final Color expandGapBorderColor;

  /// Expand-gap label colour.
  final Color expandGapTextColor;

  /// Google-Docs-style background drawn over a commented range.
  final Color commentHighlightColor;

  /// Background drawn over the commented range whose thread is focused.
  final Color commentHighlightActiveColor;

  /// Cmd/Ctrl+hover underline for a regexp or identifier span.
  final Color gotoUnderlineColor;

  /// Monotonic counter bumped whenever the document's row layout changes.
  final int revision;

  /// Pixels of viewport-top occupied by a pinned ancestor (the tab strip), so
  /// the sticky header pins just below it instead of behind it.
  final double topInset;

  /// Whether long lines wrap or scroll horizontally.
  final DiffOverflowMode overflowMode;

  /// Current search-match file + raw line index to highlight (-1 = none).
  final int searchFile;

  /// Current search-match raw line index (-1 = none).
  final int searchRawIndex;

  /// Side-by-side (split) rendering: deletions/old-numbers on the left half,
  /// additions/new-numbers on the right, context on both.
  final bool splitMode;
}

/// Gutter width used per side in split mode (one line-number column).
const double kDiffSplitGutterWidth = kDiffGutterPillSlot + 44 + 8;

/// A persistent comment highlight to paint over one display row: the display
/// column span `[startCol, endCol)` (a null [endCol] means "to the row's right
/// edge"), drawn in the active colour when its thread is focused or hovered.
@immutable
class DiffCommentHighlight {
  /// Creates a highlight descriptor.
  const DiffCommentHighlight({
    required this.startCol,
    this.endCol,
    this.active = false,
    this.groupId,
  });

  /// First display column (tabs expanded) of the highlight.
  final int startCol;

  /// Exclusive end display column, or null for "to the right edge".
  final int? endCol;

  /// Whether this row's thread is the focused one (darker highlight).
  final bool active;

  /// Id of the conversation this row belongs to.
  ///
  /// Rows sharing an id light up together on hover and click to the same
  /// thread — which is what makes a seven-row comment read as ONE mark rather
  /// than seven, and what lets a collapsed conversation be reopened from the
  /// code it is about.
  final String? groupId;
}
