import 'package:diff_match_patch/diff_match_patch.dart';

/// Kind of a line in a computed diff.
enum DiffLineKind {
  /// Unchanged context line, present in both sides.
  context,

  /// Added line (present only in the new text).
  add,

  /// Removed line (present only in the old text).
  del,
}

/// A single rendered line of a unified diff.
class DiffLine {
  /// Creates a [DiffLine].
  const DiffLine(this.kind, this.text);

  /// Whether the line was added, removed, or unchanged.
  final DiffLineKind kind;

  /// The line text (without trailing newline).
  final String text;
}

/// Result of [computeLineDiff]: the rendered lines plus add/del counts.
class LineDiffResult {
  /// Creates a [LineDiffResult].
  const LineDiffResult(this.lines, this.additions, this.deletions);

  /// The diff lines in order.
  final List<DiffLine> lines;

  /// Number of added lines.
  final int additions;

  /// Number of removed lines.
  final int deletions;
}

/// Computes a line-level diff between [oldText] and [newText] using
/// `diff_match_patch` in line mode.
///
/// Each unique line is mapped to a single code unit so the character-level
/// Myers diff operates on whole lines; the result is decoded back into
/// [DiffLine]s. No semantic cleanup is applied (it would merge across the
/// synthetic line boundaries).
LineDiffResult computeLineDiff(String oldText, String newText) {
  final encoder = _LineEncoder();
  final a = encoder.encode(oldText);
  final b = encoder.encode(newText);

  final dmp = DiffMatchPatch();
  final diffs = dmp.diff(a, b);

  final lines = <DiffLine>[];
  var additions = 0;
  var deletions = 0;

  for (final diff in diffs) {
    final decoded = encoder.decode(diff.text);
    switch (diff.operation) {
      case DIFF_EQUAL:
        for (final l in decoded) {
          lines.add(DiffLine(DiffLineKind.context, l));
        }
      case DIFF_DELETE:
        for (final l in decoded) {
          lines.add(DiffLine(DiffLineKind.del, l));
          deletions++;
        }
      case DIFF_INSERT:
        for (final l in decoded) {
          lines.add(DiffLine(DiffLineKind.add, l));
          additions++;
        }
    }
  }

  return LineDiffResult(lines, additions, deletions);
}

/// Maps unique lines to single code units and back, the standard
/// `diff_match_patch` line-mode encoding.
class _LineEncoder {
  final List<String> _lines = [];
  final Map<String, int> _index = {};

  String encode(String text) {
    if (text.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    // Preserve a trailing empty segment only when the text does not end in a
    // newline; otherwise the final '\n' yields a phantom empty line.
    final segments = text.split('\n');
    final count = (segments.isNotEmpty && segments.last.isEmpty)
        ? segments.length - 1
        : segments.length;
    for (var i = 0; i < count; i++) {
      final line = segments[i];
      var id = _index[line];
      if (id == null) {
        id = _lines.length;
        _lines.add(line);
        _index[line] = id;
      }
      buffer.writeCharCode(id);
    }
    return buffer.toString();
  }

  List<String> decode(String encoded) =>
      [for (final unit in encoded.codeUnits) _lines[unit]];
}
