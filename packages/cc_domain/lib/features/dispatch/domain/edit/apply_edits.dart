/// In-memory edit application and block resolution.
///
/// [applyEdits] is the pure transform at the heart of the subsystem: it takes
/// a text body and a list of resolved [Edit]s (no [BlockEdit]s) and returns the
/// post-edit text, the first changed line, and any diagnostic warnings. Two
/// conservative repair passes run first ([repairReplacementBoundaries],
/// [repairAfterInsertLandings]) to absorb common model off-by-one mistakes.
///
/// [resolveBlockEdits] is the seam between the deferred [BlockEdit] form and
/// the concrete inserts/deletes [applyEdits] consumes; it calls an injected
/// [BlockResolver] to resolve each block's span.
library;

import 'package:cc_domain/features/dispatch/domain/edit/block_resolver.dart';
import 'package:cc_domain/features/dispatch/domain/edit/edit.dart';

// ===========================================================================
// Warning constants
// ===========================================================================

/// Warning: an `insertAfter` block edit anchored on a structural closer line
/// was lowered to a plain after-anchor insert (the closer ends a block, so
/// inserting after it is exactly what the plain form does).
const String insertAfterBlockCloserLoweredWarning =
    'insertAfterBlockCloserLowered: block insert anchored on a closing '
    'delimiter; applied as a plain insert after that line. Anchor on the line '
    'that opens the construct.';

/// Warning: an `insertAfter` block edit could not be resolved (no resolver, or
/// the resolver returned null) and was lowered to a plain after-anchor insert.
const String insertAfterBlockUnresolvedLoweredWarning =
    'insertAfterBlockUnresolvedLowered: block insert could not resolve a '
    'syntactic block; applied as a plain insert after the anchor line. Verify '
    'the landing line.';

/// Warning prefix for a replacement-boundary repair (a duplicated trailing
/// line just past the range was dropped from the payload).
const String replacementBoundaryRepairWarning =
    'replacementBoundaryRepair: dropped a trailing payload line that '
    'duplicated the file line just past the range.';

/// Warning: an after-anchor insert looks mis-anchored on a structural closer
/// line. The insert is left as authored; re-issue if the landing was wrong.
const String afterInsertLandingSuspectWarning =
    'afterInsertLandingSuspect: an insert is anchored after a closing '
    'delimiter line; left as authored. Verify the landing line.';

/// A line that is nothing but closing delimiters: `}`, `)`, `];`, `})`, `},`,
/// or a bare `end`. Used by both repair passes and block lowering.
final RegExp structuralCloserPattern = RegExp(r'^\s*(?:[)\]}]+[;,]?|end)\s*$');

// ===========================================================================
// applyEdits
// ===========================================================================

/// The result of [applyEdits].
class ApplyResult {
  /// Creates an [ApplyResult].
  const ApplyResult({
    required this.text,
    this.firstChangedLine,
    this.warnings = const [],
  });

  /// The post-edit text body (LF-joined).
  final String text;

  /// The first 1-indexed line that changed, or null for a no-op apply.
  final int? firstChangedLine;

  /// Diagnostic warnings collected by the repair passes.
  final List<String> warnings;
}

/// Apply [edits] to [text] in memory and return the result.
///
/// Pure function — no I/O, no mutation of [edits]. The pipeline is:
///
/// 1. Split [text] into lines on `\n`.
/// 2. Validate every anchor is in bounds (throws [RangeError] otherwise).
/// 3. Run [repairReplacementBoundaries] (drop duplicated trailing payload
///    lines) and [repairAfterInsertLandings] (warn on suspect anchors).
/// 4. Apply anchored edits **bottom-up** (highest line first) so lower indices
///    stay valid, then splice beginning-of-file lines at the top and
///    end-of-file lines at the bottom.
///
/// Throws [StateError] if an unresolved [BlockEdit] reaches the applier (a
/// wiring bug — `resolveBlockEdits` must run first) and [ArgumentError] if a
/// [ReplaceEdit] is present (lower it via `lowerReplaceEdits` first).
ApplyResult applyEdits(String text, List<Edit> edits) {
  if (edits.isEmpty) {
    return ApplyResult(text: text);
  }
  for (final edit in edits) {
    if (edit is BlockEdit) {
      throw StateError(
        'applyEdits received an unresolved BlockEdit; run resolveBlockEdits '
        'first.',
      );
    }
    if (edit is ReplaceEdit) {
      throw ArgumentError(
        'applyEdits received a ReplaceEdit; lower it via lowerReplaceEdits '
        'first.',
      );
    }
  }

  final fileLines = text.split('\n');

  _validateLineBounds(edits, fileLines.length);

  final boundaryRepair = repairReplacementBoundaries(edits, fileLines);
  final landingRepair = repairAfterInsertLandings(
    boundaryRepair.edits,
    fileLines,
  );
  final repaired = landingRepair.edits;
  final warnings = <String>[
    ...boundaryRepair.warnings,
    ...landingRepair.warnings,
  ];

  int? firstChangedLine;
  void trackFirstChanged(int line) {
    if (firstChangedLine == null || line < firstChangedLine!) {
      firstChangedLine = line;
    }
  }

  // Partition into beginning-of-file, end-of-file, and anchor-targeted edits.
  final bofLines = <String>[];
  final eofLines = <String>[];
  // Each entry keeps the original index so within-line order is preserved.
  final anchorEdits = <_IndexedEdit>[];
  for (var i = 0; i < repaired.length; i++) {
    final edit = repaired[i];
    if (edit is InsertEdit && edit.cursor is BeginningOfFileCursor) {
      bofLines.add(edit.text);
    } else if (edit is InsertEdit && edit.cursor is EndOfFileCursor) {
      eofLines.add(edit.text);
    } else {
      anchorEdits.add(_IndexedEdit(edit, i));
    }
  }

  // Bucket anchored edits by their target line.
  final byLine = <int, List<_IndexedEdit>>{};
  for (final entry in anchorEdits) {
    final line = _anchorLineOf(entry.edit);
    (byLine[line] ??= <_IndexedEdit>[]).add(entry);
  }

  // Apply buckets bottom-up so earlier indices stay valid.
  final sortedLines = byLine.keys.toList()..sort((a, b) => b - a);
  for (final line in sortedLines) {
    final bucket = byLine[line]!..sort((a, b) => a.index - b.index);
    final idx = line - 1;
    final currentLine = idx >= 0 && idx < fileLines.length
        ? fileLines[idx]
        : '';

    final beforeInsertLines = <String>[];
    final afterInsertLines = <String>[];
    final replacementLines = <String>[];
    var deleteLine = false;

    for (final entry in bucket) {
      final edit = entry.edit;
      if (edit is InsertEdit && edit.mode == InsertMode.replacement) {
        replacementLines.add(edit.text);
      } else if (edit is InsertEdit && edit.cursor is AfterAnchorCursor) {
        afterInsertLines.add(edit.text);
      } else if (edit is InsertEdit) {
        beforeInsertLines.add(edit.text);
      } else if (edit is DeleteEdit) {
        deleteLine = true;
      }
    }

    if (beforeInsertLines.isEmpty &&
        replacementLines.isEmpty &&
        afterInsertLines.isEmpty &&
        !deleteLine) {
      continue;
    }

    final replacement = deleteLine
        ? [...beforeInsertLines, ...replacementLines, ...afterInsertLines]
        : [
            ...beforeInsertLines,
            ...replacementLines,
            currentLine,
            ...afterInsertLines,
          ];

    fileLines.replaceRange(idx, idx + 1, replacement);
    trackFirstChanged(line);
  }

  if (bofLines.isNotEmpty) {
    _insertAtStart(fileLines, bofLines);
    trackFirstChanged(1);
  }
  final eofChangedLine = _insertAtEnd(fileLines, eofLines);
  if (eofChangedLine != null) {
    trackFirstChanged(eofChangedLine);
  }

  return ApplyResult(
    text: fileLines.join('\n'),
    firstChangedLine: firstChangedLine,
    warnings: warnings,
  );
}

class _IndexedEdit {
  _IndexedEdit(this.edit, this.index);
  final Edit edit;
  final int index;
}

int _anchorLineOf(Edit edit) {
  if (edit is DeleteEdit) {
    return edit.line;
  }
  if (edit is InsertEdit) {
    return edit.cursor.anchorLine ?? 0;
  }
  return 0;
}

void _validateLineBounds(List<Edit> edits, int lineCount) {
  for (final edit in edits) {
    int? anchor;
    if (edit is DeleteEdit) {
      anchor = edit.line;
    } else if (edit is InsertEdit) {
      anchor = edit.cursor.anchorLine;
    }
    if (anchor == null) {
      continue;
    }
    if (anchor < 1 || anchor > lineCount) {
      throw RangeError(
        'Line $anchor does not exist (file has $lineCount lines).',
      );
    }
  }
}

void _insertAtStart(List<String> fileLines, List<String> lines) {
  if (lines.isEmpty) {
    return;
  }
  // A blank single-line file is the empty string; replace it rather than
  // prepending to a phantom empty line.
  if (fileLines.length == 1 && fileLines[0].isEmpty) {
    fileLines.replaceRange(0, 1, lines);
    return;
  }
  fileLines.insertAll(0, lines);
}

int? _insertAtEnd(List<String> fileLines, List<String> lines) {
  if (lines.isEmpty) {
    return null;
  }
  if (fileLines.length == 1 && fileLines[0].isEmpty) {
    fileLines.replaceRange(0, 1, lines);
    return 1;
  }
  // A newline-terminated file ends in a trailing "" sentinel from split("\n");
  // append before it so the final newline is preserved.
  final hasTrailingNewline =
      fileLines.isNotEmpty && fileLines[fileLines.length - 1].isEmpty;
  final insertIndex = hasTrailingNewline
      ? fileLines.length - 1
      : fileLines.length;
  fileLines.insertAll(insertIndex, lines);
  return insertIndex + 1;
}

// ===========================================================================
// Repair pass 1: replacement boundaries
// ===========================================================================

/// The result of a repair pass: the possibly-rewritten edits and any warnings.
class RepairResult {
  /// Creates a [RepairResult].
  const RepairResult({required this.edits, this.warnings = const []});

  /// The edits after the repair (may be the input unchanged).
  final List<Edit> edits;

  /// Warnings collected when a repair fired.
  final List<String> warnings;
}

/// Repair common off-by-one mistakes in replacement groups.
///
/// Pragmatic version: detects a replacement group (a run of before-anchor
/// replacement inserts at one line followed by the contiguous range deletes for
/// that line) and, when the payload's last line exactly equals the surviving
/// file line just below the deleted range, drops that duplicated trailing line
/// from the payload and emits [replacementBoundaryRepairWarning]. This absorbs
/// the frequent "the body restated the line below the range" mistake without
/// the full delimiter-balance machinery. Edits that are not part of a
/// recognised replacement group pass through untouched.
RepairResult repairReplacementBoundaries(
  List<Edit> edits,
  List<String> fileLines,
) {
  final out = <Edit>[];
  final warnings = <String>[];
  var i = 0;
  while (i < edits.length) {
    final group = _findReplacementGroup(edits, i);
    if (group == null) {
      out.add(edits[i]);
      i++;
      continue;
    }
    // Advance past the whole group.
    i = group.lastIndex + 1;

    var inserts = group.insertIndices.map((idx) => edits[idx]).toList();
    final deletes = group.deleteIndices.map((idx) => edits[idx]).toList();

    // Drop as many duplicated trailing payload lines as exactly match the
    // surviving file lines just below the range.
    var dropped = 0;
    while (inserts.length - dropped >= 1) {
      final payloadIdx = inserts.length - dropped - 1;
      final payloadLine = (inserts[payloadIdx] as InsertEdit).text;
      final fileIdx = group.endLine + dropped; // 0-indexed line below range
      if (fileIdx >= fileLines.length) {
        break;
      }
      if (payloadLine != fileLines[fileIdx]) {
        break;
      }
      dropped++;
    }
    if (dropped > 0) {
      inserts = inserts.sublist(0, inserts.length - dropped);
      warnings.add(replacementBoundaryRepairWarning);
    }
    out
      ..addAll(inserts)
      ..addAll(deletes);
  }
  return RepairResult(edits: out, warnings: warnings);
}

class _ReplacementGroup {
  _ReplacementGroup({
    required this.insertIndices,
    required this.deleteIndices,
    required this.startLine,
    required this.endLine,
  });
  final List<int> insertIndices;
  final List<int> deleteIndices;
  final int startLine;
  final int endLine;
  int get lastIndex => deleteIndices.last;
}

/// Detect a replacement group beginning at [start]: a run of before-anchor
/// replacement inserts sharing one anchor line, immediately followed by the
/// contiguous deletes for that same range.
_ReplacementGroup? _findReplacementGroup(List<Edit> edits, int start) {
  final first = edits[start];
  if (first is! InsertEdit ||
      first.mode != InsertMode.replacement ||
      first.cursor is! BeforeAnchorCursor) {
    return null;
  }
  final anchorLine = (first.cursor as BeforeAnchorCursor).line;
  final insertIndices = <int>[];
  var i = start;
  for (; i < edits.length; i++) {
    final edit = edits[i];
    if (edit is! InsertEdit ||
        edit.mode != InsertMode.replacement ||
        edit.cursor is! BeforeAnchorCursor ||
        (edit.cursor as BeforeAnchorCursor).line != anchorLine) {
      break;
    }
    insertIndices.add(i);
  }
  final deleteIndices = <int>[];
  var expectedLine = anchorLine;
  for (; i < edits.length; i++) {
    final edit = edits[i];
    if (edit is! DeleteEdit || edit.line != expectedLine) {
      break;
    }
    deleteIndices.add(i);
    expectedLine++;
  }
  if (deleteIndices.isEmpty) {
    return null;
  }
  return _ReplacementGroup(
    insertIndices: insertIndices,
    deleteIndices: deleteIndices,
    startLine: anchorLine,
    endLine: anchorLine + deleteIndices.length - 1,
  );
}

// ===========================================================================
// Repair pass 2: after-insert landings
// ===========================================================================

/// Flag after-anchor inserts that look mis-anchored, leaving them as authored.
///
/// Conservative version: when an after-anchor insert lands on a line that is a
/// pure structural closer (`}`, `)`, `end`, …) and the inserted body is not
/// itself a closer, the anchor is *suspect* — the model likely meant to insert
/// after the construct's content, not after its closer. The edit is left
/// unchanged (we never silently move it) and [afterInsertLandingSuspectWarning]
/// is collected once. Every other case passes through silently.
RepairResult repairAfterInsertLandings(
  List<Edit> edits,
  List<String> fileLines,
) {
  var warned = false;
  for (final edit in edits) {
    if (edit is! InsertEdit || edit.cursor is! AfterAnchorCursor) {
      continue;
    }
    final line = (edit.cursor as AfterAnchorCursor).line;
    final idx = line - 1;
    if (idx < 0 || idx >= fileLines.length) {
      continue;
    }
    final anchorText = fileLines[idx];
    if (!structuralCloserPattern.hasMatch(anchorText)) {
      continue;
    }
    if (structuralCloserPattern.hasMatch(edit.text)) {
      continue;
    }
    warned = true;
    break;
  }
  return RepairResult(
    edits: edits,
    warnings: warned ? const [afterInsertLandingSuspectWarning] : const [],
  );
}

// ===========================================================================
// resolveBlockEdits
// ===========================================================================

/// The result of [resolveBlockEdits]: the concrete edits and any warnings.
class ResolveBlockResult {
  /// Creates a [ResolveBlockResult].
  const ResolveBlockResult({required this.edits, this.warnings = const []});

  /// The edits with every [BlockEdit] expanded; no [BlockEdit]s remain.
  final List<Edit> edits;

  /// Warnings produced while lowering unresolvable insert-after blocks.
  final List<String> warnings;
}

/// Expand every [BlockEdit] in [edits] against [text] using [resolver].
///
/// Fast path: returns [edits] unchanged when there is no [BlockEdit]. For each
/// [BlockEdit], the resolver is asked for the block's span (against [path] for
/// language inference):
///
/// - **Unresolved** (null resolver, or the resolver returns null): an
///   `insertAfter` block lowers to a plain after-anchor insert per payload at
///   the anchor line — emitting [insertAfterBlockCloserLoweredWarning] if the
///   anchor line is a structural closer, else
///   [insertAfterBlockUnresolvedLoweredWarning]. A replace/delete block cannot
///   be lowered safely, so it throws [BlockResolutionException].
/// - **Single-line span** (`startLine == endLine`): treated as a bare
///   statement, not a multi-line construct. `insertAfter` lowers to an
///   after-anchor insert at that line; replace/delete throws
///   [BlockResolutionException].
/// - **Multi-line span**: `insertAfter` becomes after-anchor inserts at
///   `endLine`; replace/delete becomes before-anchor replacement inserts at
///   `startLine` (one per payload) plus a delete for every line in the span.
ResolveBlockResult resolveBlockEdits(
  List<Edit> edits,
  String text,
  String path,
  BlockResolver? resolver,
) {
  final hasBlock = edits.any((e) => e is BlockEdit);
  if (!hasBlock) {
    return ResolveBlockResult(edits: edits);
  }

  List<String>? fileLines;
  List<String> lines() => fileLines ??= text.split('\n');

  final out = <Edit>[];
  final warnings = <String>[];

  for (final edit in edits) {
    if (edit is! BlockEdit) {
      out.add(edit);
      continue;
    }

    final span = resolver?.resolveBlock(
      path: path,
      text: text,
      line: edit.anchorLine,
    );

    if (span == null) {
      if (edit.mode == BlockMode.insertAfter) {
        final idx = edit.anchorLine - 1;
        final anchorText = idx >= 0 && idx < lines().length
            ? lines()[idx]
            : null;
        final isCloser =
            anchorText != null && structuralCloserPattern.hasMatch(anchorText);
        warnings.add(
          isCloser
              ? insertAfterBlockCloserLoweredWarning
              : insertAfterBlockUnresolvedLoweredWarning,
        );
        for (final payload in edit.payloads) {
          out.add(
            InsertEdit(
              cursor: AfterAnchorCursor(edit.anchorLine),
              text: payload,
            ),
          );
        }
        continue;
      }
      throw BlockResolutionException(
        'Could not resolve a syntactic block beginning on line '
        '${edit.anchorLine} for $path. Use an explicit line range instead.',
      );
    }

    if (span.startLine == span.endLine) {
      if (edit.mode == BlockMode.insertAfter) {
        for (final payload in edit.payloads) {
          out.add(
            InsertEdit(
              cursor: AfterAnchorCursor(span.endLine),
              text: payload,
            ),
          );
        }
        continue;
      }
      throw BlockResolutionException(
        'Block on line ${edit.anchorLine} resolved to a single line '
        '(${span.startLine}) — a bare statement, not a multi-line construct. '
        'Use an explicit line range instead.',
      );
    }

    if (edit.mode == BlockMode.insertAfter) {
      for (final payload in edit.payloads) {
        out.add(
          InsertEdit(
            cursor: AfterAnchorCursor(span.endLine),
            text: payload,
            blockStart: span.startLine,
          ),
        );
      }
      continue;
    }

    // replace / delete: replacement inserts at startLine, then range deletes.
    for (final payload in edit.payloads) {
      out.add(
        InsertEdit(
          cursor: BeforeAnchorCursor(span.startLine),
          text: payload,
          mode: InsertMode.replacement,
        ),
      );
    }
    for (var line = span.startLine; line <= span.endLine; line++) {
      out.add(DeleteEdit(line: line));
    }
  }

  return ResolveBlockResult(edits: out, warnings: warnings);
}
