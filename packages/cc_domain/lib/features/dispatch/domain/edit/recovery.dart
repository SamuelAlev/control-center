/// Recovery from a stale section hash.
///
/// When a section's [Section.fileHash] no longer matches the live file, the
/// edit cannot be applied at face value — the line numbers may point at
/// different content than the model saw. [tryRecover] attempts two strategies,
/// in order, against a cached snapshot of the file as it was when the hash was
/// minted:
///
/// 1. **Three-way merge.** Apply the edits onto the snapshot, diff
///    snapshot→applied, and replay that diff onto the live content with strict
///    (`fuzz = 0`) line matching. Recovers from external writes that did not
///    touch the edited region.
/// 2. **Session-chain replay.** When the snapshot and live content have the
///    same line count and every anchor line is byte-identical between them, the
///    edits are replayed directly onto the live content. Recovers an in-session
///    edit chain where a prior edit advanced the hash without moving anchors.
///
/// Returns null when neither strategy applies — the caller then surfaces a hard
/// mismatch and prompts a re-read.
library;

import 'package:cc_domain/features/dispatch/domain/edit/apply_edits.dart';
import 'package:cc_domain/features/dispatch/domain/edit/edit.dart';

/// Warning emitted when the three-way merge strategy recovered the edit.
const String recoveryThreeWayMergeWarning =
    'recoveryThreeWayMerge: the file changed since your read; recovered by '
    'merging your edit onto the current content. Verify the diff matches your '
    'intent.';

/// Warning emitted when the session-chain replay strategy recovered the edit.
const String recoverySessionReplayWarning =
    'recoverySessionReplay: a prior in-session edit advanced the file hash; '
    'recovered by replaying your edits onto the current content. Verify the '
    'diff matches your intent.';

/// The result of a successful [tryRecover].
class RecoveryResult {
  /// Creates a [RecoveryResult].
  const RecoveryResult({required this.text, this.warnings = const []});

  /// The recovered, post-edit text.
  final String text;

  /// Warnings naming which recovery strategy fired.
  final List<String> warnings;
}

/// Attempt to recover an edit whose section hash is stale.
///
/// [previousText] is the cached snapshot the stale hash names; [currentText] is
/// the live file content; [edits] are the resolved edits (no [BlockEdit]s);
/// [anchorLines] are the 1-indexed lines the edits anchor on, used by the
/// session-chain fallback. Returns a [RecoveryResult] on success, or null when
/// the edit cannot be recovered.
RecoveryResult? tryRecover({
  required String previousText,
  required String currentText,
  required List<Edit> edits,
  List<int> anchorLines = const [],
}) {
  // Apply onto the snapshot. A no-op apply means there is nothing to recover.
  ApplyResult appliedToPrevious;
  try {
    appliedToPrevious = applyEdits(previousText, edits);
  } on Object {
    return null;
  }
  if (appliedToPrevious.text == previousText) {
    return null;
  }

  // Strategy 1: three-way merge of (previous -> applied) onto current.
  final merged = _threeWayMerge(
    base: previousText,
    edited: appliedToPrevious.text,
    onto: currentText,
  );
  if (merged != null && merged != currentText) {
    return RecoveryResult(
      text: merged,
      warnings: const [recoveryThreeWayMergeWarning],
    );
  }

  // Strategy 2: session-chain replay onto current.
  if (_sameLineCount(previousText, currentText) &&
      _anchorsIdentical(previousText, currentText, anchorLines)) {
    ApplyResult appliedToCurrent;
    try {
      appliedToCurrent = applyEdits(currentText, edits);
    } on Object {
      return null;
    }
    if (appliedToCurrent.text != currentText) {
      return RecoveryResult(
        text: appliedToCurrent.text,
        warnings: const [recoverySessionReplayWarning],
      );
    }
  }

  return null;
}

bool _sameLineCount(String a, String b) =>
    a.split('\n').length == b.split('\n').length;

bool _anchorsIdentical(String previous, String current, List<int> anchorLines) {
  if (anchorLines.isEmpty) {
    return true;
  }
  final prev = previous.split('\n');
  final curr = current.split('\n');
  for (final line in anchorLines) {
    final idx = line - 1;
    if (idx < 0 || idx >= prev.length || idx >= curr.length) {
      return false;
    }
    if (prev[idx] != curr[idx]) {
      return false;
    }
  }
  return true;
}

// ===========================================================================
// Minimal line-level 3-way merge (fuzz = 0)
// ===========================================================================

/// Merge the change `base -> edited` onto `onto` with strict line matching.
///
/// Computes the line-level diff between [base] and [edited], groups it into
/// context-anchored hunks, then locates each hunk's "old" side (its removed
/// lines plus surrounding context) in [onto]. Every hunk must match exactly and
/// uniquely (`fuzz = 0`), and hunks must not overlap. On any ambiguity or
/// failure to locate, returns null so the caller falls back. Returns the merged
/// text on success.
String? _threeWayMerge({
  required String base,
  required String edited,
  required String onto,
}) {
  final baseLines = base.split('\n');
  final editedLines = edited.split('\n');
  final ontoLines = onto.split('\n');

  final ops = _diffLines(baseLines, editedLines);
  final hunks = _buildHunks(ops);
  if (hunks.isEmpty) {
    return null;
  }

  // Each hunk names a contiguous slice of base lines (`oldLines`) replaced by
  // `newLines`. Locate each `oldLines` slice uniquely in `onto`, then splice.
  // Replacements are gathered as (start, end, newLines) over `onto` indices.
  final replacements = <_OntoReplacement>[];
  for (final hunk in hunks) {
    final located = _locateUnique(ontoLines, hunk.oldLines);
    if (located == null) {
      return null;
    }
    replacements.add(
      _OntoReplacement(
        start: located,
        end: located + hunk.oldLines.length,
        newLines: hunk.newLines,
      ),
    );
  }

  // Reject overlapping replacements (would corrupt the result).
  replacements.sort((a, b) => a.start - b.start);
  for (var i = 1; i < replacements.length; i++) {
    if (replacements[i].start < replacements[i - 1].end) {
      return null;
    }
  }

  // Apply replacements bottom-up so indices stay valid.
  final result = List<String>.of(ontoLines);
  for (final repl in replacements.reversed) {
    result.replaceRange(repl.start, repl.end, repl.newLines);
  }
  return result.join('\n');
}

class _OntoReplacement {
  _OntoReplacement({
    required this.start,
    required this.end,
    required this.newLines,
  });
  final int start;
  final int end;
  final List<String> newLines;
}

/// Find the unique 0-indexed start at which [needle] occurs as a contiguous
/// run in [haystack]. Returns null when there is no match or more than one.
/// An empty [needle] (a pure insertion hunk) never matches uniquely here, so
/// such hunks are filtered out before this is called.
int? _locateUnique(List<String> haystack, List<String> needle) {
  if (needle.isEmpty) {
    return null;
  }
  var found = -1;
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var matches = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      if (found != -1) {
        return null; // ambiguous
      }
      found = i;
    }
  }
  return found == -1 ? null : found;
}

/// One merge hunk: a contiguous slice of base lines ([oldLines]) and the lines
/// that replace them ([newLines]). Both carry one line of surrounding context
/// (when available) so a pure insertion still anchors to a real line.
class _Hunk {
  _Hunk({required this.oldLines, required this.newLines});
  final List<String> oldLines;
  final List<String> newLines;
}

/// A single line-level diff operation.
enum _DiffKind {
  /// Line present in both base and edited.
  equal,

  /// Line removed from base.
  delete,

  /// Line added in edited.
  insert,
}

class _DiffOp {
  _DiffOp(this.kind, this.line);
  final _DiffKind kind;
  final String line;
}

/// Group a flat diff op list into context-anchored hunks.
///
/// Each maximal run of non-equal ops becomes one hunk. One equal line on each
/// side (when present) is folded into the hunk as context so the "old" side is
/// never empty — a pure insertion anchors to its preceding (or following) line.
List<_Hunk> _buildHunks(List<_DiffOp> ops) {
  final hunks = <_Hunk>[];
  var i = 0;
  while (i < ops.length) {
    if (ops[i].kind == _DiffKind.equal) {
      i++;
      continue;
    }
    // Span of a run of changes.
    var j = i;
    while (j < ops.length && ops[j].kind != _DiffKind.equal) {
      j++;
    }
    // Leading context: the equal op just before the run.
    final hasLeading = i > 0 && ops[i - 1].kind == _DiffKind.equal;
    // Trailing context: the equal op just after the run.
    final hasTrailing = j < ops.length && ops[j].kind == _DiffKind.equal;

    final oldLines = <String>[];
    final newLines = <String>[];
    if (hasLeading) {
      oldLines.add(ops[i - 1].line);
      newLines.add(ops[i - 1].line);
    }
    for (var k = i; k < j; k++) {
      final op = ops[k];
      if (op.kind == _DiffKind.delete) {
        oldLines.add(op.line);
      } else if (op.kind == _DiffKind.insert) {
        newLines.add(op.line);
      }
    }
    if (hasTrailing) {
      oldLines.add(ops[j].line);
      newLines.add(ops[j].line);
    }
    hunks.add(_Hunk(oldLines: oldLines, newLines: newLines));
    // Continue after the run; the trailing context op may also lead the next
    // hunk, which is fine — overlap detection in the merge rejects conflicts.
    i = j;
  }
  return hunks;
}

/// Line-level diff via the longest-common-subsequence of [a] and [b].
///
/// Returns a flat op list: equal lines mark shared context, deletes drop a base
/// line, inserts add an edited line. The classic dynamic-programming LCS is
/// adequate here — recovery inputs are single files, and correctness (not
/// minimality of a Myers diff) is what the strict merge relies on.
List<_DiffOp> _diffLines(List<String> a, List<String> b) {
  final n = a.length;
  final m = b.length;
  // lcs[i][j] = LCS length of a[i..] and b[j..].
  final lcs = List.generate(
    n + 1,
    (_) => List<int>.filled(m + 1, 0),
    growable: false,
  );
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      if (a[i] == b[j]) {
        lcs[i][j] = lcs[i + 1][j + 1] + 1;
      } else {
        lcs[i][j] = lcs[i + 1][j] >= lcs[i][j + 1]
            ? lcs[i + 1][j]
            : lcs[i][j + 1];
      }
    }
  }
  final ops = <_DiffOp>[];
  var i = 0;
  var j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      ops.add(_DiffOp(_DiffKind.equal, a[i]));
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      ops.add(_DiffOp(_DiffKind.delete, a[i]));
      i++;
    } else {
      ops.add(_DiffOp(_DiffKind.insert, b[j]));
      j++;
    }
  }
  while (i < n) {
    ops.add(_DiffOp(_DiffKind.delete, a[i]));
    i++;
  }
  while (j < m) {
    ops.add(_DiffOp(_DiffKind.insert, b[j]));
    j++;
  }
  return ops;
}
