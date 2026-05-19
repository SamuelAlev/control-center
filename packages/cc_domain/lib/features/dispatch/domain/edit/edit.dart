/// The hashline edit model: the sealed [Edit] union plus the [Section] and
/// [Patch] aggregates that group edits against files.
///
/// Every anchor line in this model is **1-indexed** — line `1` is the first
/// line of the file — to match what a numbered read/search display shows the
/// model. The applier (`applyEdits`) consumes these edits; the patcher
/// (`Patcher`) groups [Section]s under a [Patch] and validates each against the
/// live file via its [Section.fileHash] anchor.
library;

/// How an [InsertEdit] body interacts with the line it lands on.
enum InsertMode {
  /// The body is inserted; the anchor line (if any) is preserved.
  normal,

  /// The body is replacement content for a line that a paired [DeleteEdit]
  /// removes. The applier emits it in place of the deleted line rather than
  /// alongside it.
  replacement,
}

/// What an [BlockEdit] does to its resolved block span.
enum BlockMode {
  /// Replace the whole block span with the payload lines.
  replace,

  /// Delete the whole block span.
  delete,

  /// Insert the payload lines after the block's last line.
  insertAfter,
}

/// Where an [InsertEdit] should land relative to existing content.
///
/// A cursor is one of four positions: the start of the file
/// ([BeginningOfFileCursor]), the end of the file ([EndOfFileCursor]), or
/// before/after a 1-indexed anchor line ([BeforeAnchorCursor] /
/// [AfterAnchorCursor]). Head/tail positions are content-independent, so they
/// survive file drift; anchored positions do not.
sealed class InsertCursor {
  /// Creates an [InsertCursor].
  const InsertCursor();

  /// The 1-indexed anchor line this cursor targets, or null for head/tail.
  int? get anchorLine => null;
}

/// Insert at the very start of the file (before line 1).
class BeginningOfFileCursor extends InsertCursor {
  /// Creates a [BeginningOfFileCursor].
  const BeginningOfFileCursor();

  @override
  bool operator ==(Object other) => other is BeginningOfFileCursor;

  @override
  int get hashCode => (BeginningOfFileCursor).hashCode;
}

/// Insert at the very end of the file (after the last line).
class EndOfFileCursor extends InsertCursor {
  /// Creates an [EndOfFileCursor].
  const EndOfFileCursor();

  @override
  bool operator ==(Object other) => other is EndOfFileCursor;

  @override
  int get hashCode => (EndOfFileCursor).hashCode;
}

/// Insert immediately before the given 1-indexed [line].
class BeforeAnchorCursor extends InsertCursor {
  /// Creates a [BeforeAnchorCursor].
  const BeforeAnchorCursor(this.line);

  /// The 1-indexed line the body is inserted before.
  final int line;

  @override
  int? get anchorLine => line;

  @override
  bool operator ==(Object other) =>
      other is BeforeAnchorCursor && other.line == line;

  @override
  int get hashCode => Object.hash(BeforeAnchorCursor, line);
}

/// Insert immediately after the given 1-indexed [line].
class AfterAnchorCursor extends InsertCursor {
  /// Creates an [AfterAnchorCursor].
  const AfterAnchorCursor(this.line);

  /// The 1-indexed line the body is inserted after.
  final int line;

  @override
  int? get anchorLine => line;

  @override
  bool operator ==(Object other) =>
      other is AfterAnchorCursor && other.line == line;

  @override
  int get hashCode => Object.hash(AfterAnchorCursor, line);
}

/// A single low-level edit consumed by `applyEdits`.
///
/// The union has four shapes. [InsertEdit] and [DeleteEdit] are the primitives
/// the applier acts on directly. [ReplaceEdit] is a convenience that lowers to
/// a before-anchor replacement insert per line plus a delete per consumed line.
/// [BlockEdit] is deferred: its concrete span is unknown until a `BlockResolver`
/// resolves it, so it must be expanded (via `resolveBlockEdits`) before the
/// applier sees it.
sealed class Edit {
  /// Creates an [Edit].
  const Edit();
}

/// Insert [text] at the position named by [cursor].
class InsertEdit extends Edit {
  /// Creates an [InsertEdit].
  const InsertEdit({
    required this.cursor,
    required this.text,
    this.mode = InsertMode.normal,
    this.blockStart,
  });

  /// Where the body lands.
  final InsertCursor cursor;

  /// The single line of body text to insert (no trailing newline).
  final String text;

  /// Whether this is plain insertion or replacement content for a deleted line.
  final InsertMode mode;

  /// When this insert was lowered from an [BlockMode.insertAfter] [BlockEdit],
  /// the resolved block's first line (1-indexed); otherwise null. Reserved for
  /// landing-correction heuristics.
  final int? blockStart;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsertEdit &&
          other.cursor == cursor &&
          other.text == text &&
          other.mode == mode &&
          other.blockStart == blockStart;

  @override
  int get hashCode => Object.hash(cursor, text, mode, blockStart);
}

/// Delete a single 1-indexed [line].
class DeleteEdit extends Edit {
  /// Creates a [DeleteEdit].
  const DeleteEdit({required this.line});

  /// The 1-indexed line to delete.
  final int line;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeleteEdit && other.line == line;

  @override
  int get hashCode => Object.hash(DeleteEdit, line);
}

/// Replace the inclusive 1-indexed range `[startLine, endLine]` with [lines].
///
/// A convenience shape: [lowerReplaceEdits] expands one of these into a
/// before-anchor replacement insert per line in [lines] plus a [DeleteEdit] for
/// each line in the range. The applier never sees a [ReplaceEdit] directly.
class ReplaceEdit extends Edit {
  /// Creates a [ReplaceEdit].
  const ReplaceEdit({
    required this.startLine,
    required this.endLine,
    required this.lines,
  });

  /// First line of the replaced range (1-indexed, inclusive).
  final int startLine;

  /// Last line of the replaced range (1-indexed, inclusive).
  final int endLine;

  /// The replacement body lines (each without a trailing newline).
  final List<String> lines;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplaceEdit &&
          other.startLine == startLine &&
          other.endLine == endLine &&
          _listEquals(other.lines, lines);

  @override
  int get hashCode => Object.hash(startLine, endLine, Object.hashAll(lines));
}

/// A deferred block edit anchored on a 1-indexed [anchorLine].
///
/// The concrete line span is unknown at parse time; it is resolved by a
/// `BlockResolver` (injected via the patcher) once the file text and path are
/// available, then expanded into concrete inserts/deletes by `resolveBlockEdits`.
class BlockEdit extends Edit {
  /// Creates a [BlockEdit].
  const BlockEdit({
    required this.mode,
    required this.anchorLine,
    this.payloads = const [],
  });

  /// What the edit does to the resolved span.
  final BlockMode mode;

  /// The 1-indexed line the block op is anchored on (the construct's opener).
  final int anchorLine;

  /// Body lines for replace / insert-after. Empty for delete.
  final List<String> payloads;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockEdit &&
          other.mode == mode &&
          other.anchorLine == anchorLine &&
          _listEquals(other.payloads, payloads);

  @override
  int get hashCode => Object.hash(mode, anchorLine, Object.hashAll(payloads));
}

/// Lower [ReplaceEdit]s into their primitive [InsertEdit] + [DeleteEdit] form.
///
/// Each [ReplaceEdit] becomes one [BeforeAnchorCursor] replacement insert per
/// line in `lines` (anchored on `startLine`), followed by one [DeleteEdit] for
/// every line in `[startLine, endLine]`. This mirrors how a `replace start.=end`
/// hunk decomposes, so the applier's boundary-repair pass can recognise it.
/// Non-replace edits pass through unchanged, preserving order.
List<Edit> lowerReplaceEdits(List<Edit> edits) {
  final out = <Edit>[];
  for (final edit in edits) {
    if (edit is! ReplaceEdit) {
      out.add(edit);
      continue;
    }
    for (final line in edit.lines) {
      out.add(
        InsertEdit(
          cursor: BeforeAnchorCursor(edit.startLine),
          text: line,
          mode: InsertMode.replacement,
        ),
      );
    }
    for (var line = edit.startLine; line <= edit.endLine; line++) {
      out.add(DeleteEdit(line: line));
    }
  }
  return out;
}

/// A single file target: a [path], its 4-hex [fileHash] anchor, and the
/// ordered [edits] to apply against it.
class Section {
  /// Creates a [Section].
  const Section({
    required this.path,
    required this.fileHash,
    required this.edits,
  });

  /// The target file path (as authored).
  final String path;

  /// The 4-hex content-hash anchor naming the file version the edits target.
  final String fileHash;

  /// The ordered edits to apply to [path].
  final List<Edit> edits;

  /// The sorted, de-duplicated 1-indexed anchor lines referenced by [edits].
  ///
  /// Block edits contribute their [BlockEdit.anchorLine]; replace edits
  /// contribute every line in their range; insert/delete contribute their
  /// anchored line (head/tail inserts contribute nothing).
  List<int> collectAnchorLines() {
    final lines = <int>{};
    for (final edit in edits) {
      switch (edit) {
        case InsertEdit(:final cursor):
          final anchor = cursor.anchorLine;
          if (anchor != null) {
            lines.add(anchor);
          }
        case DeleteEdit(:final line):
          lines.add(line);
        case ReplaceEdit(:final startLine, :final endLine):
          for (var line = startLine; line <= endLine; line++) {
            lines.add(line);
          }
        case BlockEdit(:final anchorLine):
          lines.add(anchorLine);
      }
    }
    final sorted = lines.toList()..sort();
    return sorted;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Section &&
          other.path == path &&
          other.fileHash == fileHash &&
          _listEquals(other.edits, edits);

  @override
  int get hashCode => Object.hash(path, fileHash, Object.hashAll(edits));
}

/// A collection of [Section]s applied together as one atomic unit.
class Patch {
  /// Creates a [Patch].
  const Patch({required this.sections});

  /// The sections that make up this patch.
  final List<Section> sections;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Patch && _listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hashAll(sections);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
