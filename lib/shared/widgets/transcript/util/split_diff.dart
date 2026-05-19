import 'dart:math' as math;

import 'package:control_center/shared/widgets/transcript/util/line_diff.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

/// A changed character range within one diff line, as `[start, end)` offsets
/// into that line's text.
typedef IntralineRange = (int start, int end);

/// The changed character ranges of a modified line *pair*, per side.
typedef IntralineRanges = ({
  List<IntralineRange> oldRanges,
  List<IntralineRange> newRanges,
});

const IntralineRanges _noIntraline = (
  oldRanges: <IntralineRange>[],
  newRanges: <IntralineRange>[],
);

/// One side of an aligned side-by-side row.
class SplitDiffCell {
  /// Creates a [SplitDiffCell].
  const SplitDiffCell({
    required this.lineIndex,
    required this.text,
    required this.kind,
    this.changed = const <IntralineRange>[],
  });

  /// 0-based index of this line **within its own side's text**, so the caller
  /// can look up precomputed per-line syntax spans for that side.
  final int lineIndex;

  /// The line text (without trailing newline).
  final String text;

  /// [DiffLineKind.context] on both sides, [DiffLineKind.del] on the old side
  /// of a change, [DiffLineKind.add] on the new side.
  final DiffLineKind kind;

  /// Changed character ranges within [text], ascending and non-overlapping.
  /// Empty for context lines and for changes with no legible common substring
  /// (those read better as a whole-line highlight).
  final List<IntralineRange> changed;
}

/// One row of a side-by-side diff. Exactly one cell is null when the change is
/// unbalanced (a pure insertion or deletion); that side renders as a filler so
/// the two panes stay vertically aligned.
class SplitDiffRow {
  /// Creates a [SplitDiffRow].
  const SplitDiffRow({this.left, this.right});

  /// The old-side cell, or null for a filler.
  final SplitDiffCell? left;

  /// The new-side cell, or null for a filler.
  final SplitDiffCell? right;
}

/// Aligns the line diff between [oldText] and [newText] into side-by-side rows.
///
/// Builds on [computeLineDiff], then pairs each changed block's deletions with
/// its additions index-wise (the GitHub split-view alignment): `k` deletions
/// against `k` additions become `k` modified rows, and the surplus on either
/// side becomes rows with a filler opposite it. Paired rows additionally carry
/// character-level [SplitDiffCell.changed] ranges from
/// [computeIntralineRanges], so a one-word edit reads as one word, not a whole
/// replaced line.
List<SplitDiffRow> computeSplitDiff(String oldText, String newText) {
  final lines = computeLineDiff(oldText, newText).lines;
  final rows = <SplitDiffRow>[];
  var oldIndex = 0;
  var newIndex = 0;
  var i = 0;

  while (i < lines.length) {
    if (lines[i].kind == DiffLineKind.context) {
      final text = lines[i].text;
      rows.add(
        SplitDiffRow(
          left: SplitDiffCell(
            lineIndex: oldIndex++,
            text: text,
            kind: DiffLineKind.context,
          ),
          right: SplitDiffCell(
            lineIndex: newIndex++,
            text: text,
            kind: DiffLineKind.context,
          ),
        ),
      );
      i++;
      continue;
    }

    // One changed block: every consecutive del/add, in whatever order
    // diff_match_patch emitted them (it can lead with either).
    final dels = <String>[];
    final adds = <String>[];
    while (i < lines.length && lines[i].kind != DiffLineKind.context) {
      if (lines[i].kind == DiffLineKind.del) {
        dels.add(lines[i].text);
      } else {
        adds.add(lines[i].text);
      }
      i++;
    }

    final pairs = math.max(dels.length, adds.length);
    for (var k = 0; k < pairs; k++) {
      final del = k < dels.length ? dels[k] : null;
      final add = k < adds.length ? adds[k] : null;
      final ranges = (del != null && add != null)
          ? computeIntralineRanges(del, add)
          : _noIntraline;
      rows.add(
        SplitDiffRow(
          left: del == null
              ? null
              : SplitDiffCell(
                  lineIndex: oldIndex++,
                  text: del,
                  kind: DiffLineKind.del,
                  changed: ranges.oldRanges,
                ),
          right: add == null
              ? null
              : SplitDiffCell(
                  lineIndex: newIndex++,
                  text: add,
                  kind: DiffLineKind.add,
                  changed: ranges.newRanges,
                ),
        ),
      );
    }
  }

  return rows;
}

/// Longest line pair that gets a character-level diff. Above this the quadratic
/// term in Myers' diff is not worth paying for a line nobody can read anyway.
const int _maxIntralineChars = 2000;

/// Fraction of *both* lines that may change before intraline highlighting is
/// dropped. Past it the two lines have nothing meaningful in common and the
/// per-character marks read as confetti; a whole-line highlight is clearer.
const double _intralineNoiseFloor = 0.6;

/// Computes the changed character ranges between a paired deletion and addition
/// line, using `diff_match_patch` with semantic cleanup (so the marks land on
/// word-ish boundaries rather than on individual shared letters).
///
/// Returns empty ranges — meaning "highlight the whole line" — when the lines
/// are identical, either is empty, either is longer than [_maxIntralineChars],
/// or the pair is too dissimilar (see [_intralineNoiseFloor]).
IntralineRanges computeIntralineRanges(String oldLine, String newLine) {
  if (oldLine == newLine || oldLine.isEmpty || newLine.isEmpty) {
    return _noIntraline;
  }
  if (oldLine.length > _maxIntralineChars ||
      newLine.length > _maxIntralineChars) {
    return _noIntraline;
  }

  final dmp = DiffMatchPatch();
  final diffs = dmp.diff(oldLine, newLine);
  dmp.diffCleanupSemantic(diffs);

  final oldRanges = <IntralineRange>[];
  final newRanges = <IntralineRange>[];
  var oldPos = 0;
  var newPos = 0;
  var oldChanged = 0;
  var newChanged = 0;

  for (final diff in diffs) {
    final length = diff.text.length;
    switch (diff.operation) {
      case DIFF_EQUAL:
        oldPos += length;
        newPos += length;
      case DIFF_DELETE:
        oldRanges.add((oldPos, oldPos + length));
        oldChanged += length;
        oldPos += length;
      case DIFF_INSERT:
        newRanges.add((newPos, newPos + length));
        newChanged += length;
        newPos += length;
    }
  }

  if (oldChanged > oldLine.length * _intralineNoiseFloor &&
      newChanged > newLine.length * _intralineNoiseFloor) {
    return _noIntraline;
  }
  return (oldRanges: oldRanges, newRanges: newRanges);
}
