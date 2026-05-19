import 'package:meta/meta.dart';

/// A pre-tokenized span within a diff line. ARGB-int color so the value is
/// trivially sendable across isolate boundaries.
@immutable
class DiffToken {
  /// Creates a [DiffToken].
  const DiffToken(this.text, this.colorValue, {this.backgroundColorValue});

  /// Raw text of this token.
  final String text;

  /// ARGB color, or `null` to inherit the base style color.
  final int? colorValue;

  /// ARGB background color, or `null` to inherit the base background.
  final int? backgroundColorValue;
}

/// A diff line carrying its highlighted token list.
@immutable
class DiffLineSpec {
  /// Creates a [DiffLineSpec].
  const DiffLineSpec({
    required this.kind,
    required this.tokens,
    this.oldLine,
    this.newLine,
    this.hunkHeader,
  });

  /// Kind of line (context, addition, deletion, hunk header).
  final DiffLineKind kind;

  /// Pre-tokenized highlight spans.
  final List<DiffToken> tokens;

  /// Pre-image line number, if applicable.
  final int? oldLine;

  /// Post-image line number, if applicable.
  final int? newLine;

  /// Hunk header text (only set for [DiffLineKind.hunkHeader]).
  final String? hunkHeader;
}

/// Kind of a parsed diff line.
enum DiffLineKind {
  /// A `@@ -a,b +c,d @@` hunk header.
  hunkHeader,

  /// Unchanged context line.
  context,

  /// Added line (`+`).
  addition,

  /// Removed line (`-`).
  deletion,

  /// Synthetic row marking a stretch of unchanged lines between hunks
  /// that the diff didn't ship. Rendered as a clickable "↕ N unchanged
  /// lines" affordance; tapping it fetches the file body and splices
  /// the missing lines in as [context] rows. The gap's start lives in
  /// [DiffLine.oldLine] / [DiffLine.newLine] (inclusive), and its end
  /// in [DiffLine.gapOldEnd] / [DiffLine.gapNewEnd] (also inclusive).
  expandGap,
}

/// One line of a parsed unified diff.
class DiffLine {
  /// Creates a [DiffLine].
  const DiffLine({
    required this.kind,
    required this.content,
    this.oldLine,
    this.newLine,
    this.hunkHeader,
    this.gapOldEnd,
    this.gapNewEnd,
  });

  /// Kind of the line.
  final DiffLineKind kind;

  /// Raw text content (without the leading +/- marker for additions/deletions).
  final String content;

  /// Line number in the pre-image, when applicable. For [DiffLineKind.expandGap]
  /// rows this is the (inclusive) START of the missing range.
  final int? oldLine;

  /// Line number in the post-image, when applicable. For [DiffLineKind.expandGap]
  /// rows this is the (inclusive) START of the missing range.
  final int? newLine;

  /// Hunk header text (only set when [kind] is [DiffLineKind.hunkHeader]).
  final String? hunkHeader;

  /// For [DiffLineKind.expandGap], the (inclusive) END line in the pre-image.
  final int? gapOldEnd;

  /// For [DiffLineKind.expandGap], the (inclusive) END line in the post-image.
  final int? gapNewEnd;
}

/// Parses a unified-diff [patch] into a flat list of [DiffLine]s with
/// pre/post line numbers tracked.
List<DiffLine> parseUnifiedDiff(String patch) {
  if (patch.isEmpty) {
    return const [];
  }

  final out = <DiffLine>[];
  final lines = patch.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  int oldLine = 0;
  int newLine = 0;
  for (final raw in lines) {
    if (raw.startsWith('@@')) {
      final match = _hunkHeaderRegex.firstMatch(raw);
      if (match != null) {
        final hunkOldStart = int.parse(match.group(1)!);
        final hunkNewStart = int.parse(match.group(3)!);
        // Gap detection: between the lines we've processed so far and
        // the start of this hunk. `oldLine` / `newLine` carry the next
        // unprocessed line number from the previous hunk (or 0 if no
        // hunk has been seen yet — in that case the file's first
        // unshown line is line 1). Emit a gap marker if there's
        // anything missing.
        final gapStartOld = oldLine == 0 ? 1 : oldLine;
        final gapStartNew = newLine == 0 ? 1 : newLine;
        if (gapStartOld < hunkOldStart) {
          out.add(
            DiffLine(
              kind: DiffLineKind.expandGap,
              content: '',
              oldLine: gapStartOld,
              newLine: gapStartNew,
              gapOldEnd: hunkOldStart - 1,
              gapNewEnd: hunkNewStart - 1,
            ),
          );
        }
        oldLine = hunkOldStart;
        newLine = hunkNewStart;
      }
      out.add(
        DiffLine(kind: DiffLineKind.hunkHeader, content: raw, hunkHeader: raw),
      );
      continue;
    }
    if (raw.isEmpty) {
      out.add(
        DiffLine(
          kind: DiffLineKind.context,
          content: '',
          oldLine: oldLine,
          newLine: newLine,
        ),
      );
      oldLine++;
      newLine++;
      continue;
    }
    final marker = raw[0];
    final body = raw.substring(1);
    switch (marker) {
      case '+':
        out.add(
          DiffLine(
            kind: DiffLineKind.addition,
            content: body,
            newLine: newLine,
          ),
        );
        newLine++;
        break;
      case '-':
        out.add(
          DiffLine(
            kind: DiffLineKind.deletion,
            content: body,
            oldLine: oldLine,
          ),
        );
        oldLine++;
        break;
      case '\\':
        break;
      default:
        out.add(
          DiffLine(
            kind: DiffLineKind.context,
            content: body,
            oldLine: oldLine,
            newLine: newLine,
          ),
        );
        oldLine++;
        newLine++;
    }
  }
  return out;
}

final RegExp _hunkHeaderRegex = RegExp(
  r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',
);

/// Returns the original source line(s) anchored by a review comment, derived
/// from its [diffHunk]. Used to render a before/after view for `suggestion`
/// blocks on server-fetched comments.
///
/// [side] is `LEFT` for pre-image (deletions + context) or `RIGHT` for
/// post-image (additions + context). [startLine] and [endLine] are inclusive
/// 1-based line numbers on that side; for a single-line anchor pass the same
/// value for both.
///
/// Lines outside the hunk are simply not present in the returned text — the
/// hunk that GitHub attaches to a comment normally covers the anchor range
/// plus a few surrounding context lines, so this is enough for the common
/// case.
String originalCodeFromDiffHunk(
  String diffHunk,
  String side,
  int startLine,
  int endLine,
) {
  if (diffHunk.isEmpty) {
    return '';
  }

  if (endLine < startLine) {
    return '';
  }

  final isRight = side.toUpperCase() == 'RIGHT';
  final lines = parseUnifiedDiff(diffHunk);
  final out = <String>[];
  for (final l in lines) {
    final int? lineNumber;
    final bool present;
    if (isRight) {
      present =
          l.kind == DiffLineKind.addition || l.kind == DiffLineKind.context;
      lineNumber = l.newLine;
    } else {
      present =
          l.kind == DiffLineKind.deletion || l.kind == DiffLineKind.context;
      lineNumber = l.oldLine;
    }
    if (!present || lineNumber == null) {
      continue;
    }

    if (lineNumber >= startLine && lineNumber <= endLine) {
      out.add(l.content);
    }
  }
  return out.join('\n');
}

/// Extracts a single file's unified-diff section from a full PR diff text.
///
/// The full diff uses `diff --git a/{path} b/{path}` headers to delimit each
/// file's section. This function locates the section for [filename] and returns
/// the raw unified-diff text (hunk headers, +/- lines, context lines).
///
/// Returns an empty string if the file is not found in the diff, or if the
/// section is a pure rename with no content changes.
String extractFilePatch(String fullDiff, String filename) {
  if (fullDiff.isEmpty || filename.isEmpty) {
    return '';
  }

  // Match `diff --git a/path b/path` — the filename appears after ` b/` or as
  // the sole path for deletions/additions.  We look for both `a/X b/X` and
  // edge cases like `a/X b/Y` (renames).
  const needle = 'diff --git';
  var searchFrom = 0;
  final encoded = filename.replaceAll(r'\', r'\\');

  while (searchFrom < fullDiff.length) {
    final headerStart = fullDiff.indexOf(needle, searchFrom);
    if (headerStart == -1) {
      break;
    }

    // Find end of the header line
    var lineEnd = fullDiff.indexOf('\n', headerStart);
    if (lineEnd == -1) {
      lineEnd = fullDiff.length;
    }

    final headerLine = fullDiff.substring(headerStart, lineEnd);
    // headerLine is like: diff --git a/foo/bar.json b/foo/bar.json
    // For renames:         diff --git a/old_name.json b/new_name.json
    // We check if `b/filename` or `a/filename` matches
    if (headerLine.endsWith(' b/$encoded') ||
        headerLine.contains(' b/$encoded ') ||
        headerLine.contains(' b/$encoded\n') ||
        headerLine.endsWith(' a/$encoded') ||
        headerLine.contains(' a/$encoded ') ||
        headerLine.contains(' a/$encoded\n')) {
      // Found the right section. Find the start of the next file section.
      final nextSection = fullDiff.indexOf(needle, lineEnd + 1);

      // The section spans from after the `diff --git` line to the next
      // `diff --git` (or EOF). Skip git metadata headers (index, ---, +++).
      final sectionEnd = nextSection == -1 ? fullDiff.length : nextSection;
      final section = fullDiff.substring(lineEnd + 1, sectionEnd);

      // Find the first hunk header — everything before it is git metadata
      // (index, --- a/, +++ b/) that parseUnifiedDiff doesn't handle.
      final hunkStart = section.indexOf('@@');
      if (hunkStart == -1) {
        return ''; // Pure rename with no content changes
      }

      // Walk back to the start of the hunk header line
      final patchStart =
          section.lastIndexOf('\n', hunkStart) + 1;
      final patch = section.substring(patchStart);

      // Strip trailing newline if present
      if (patch.endsWith('\n')) {
        return patch.substring(0, patch.length - 1);
      }
      return patch;
    }

    searchFrom = lineEnd + 1;
  }

  return '';
}

/// Extracts patches for **all** files from a full PR diff in a single pass.
///
/// Returns a `Map<filename, patchText>` where each value is the unified-diff
/// section for that file (hunk headers, +/- lines, context lines) with git
/// metadata stripped. Files with pure renames (no content changes) are
/// omitted.
///
/// Using this instead of calling [extractFilePatch] for each file avoids
/// scanning the full diff string N times, which is O(N × diffLength). This
/// single-pass approach is O(diffLength) regardless of file count.
Map<String, String> extractAllFilePatches(String fullDiff) {
  if (fullDiff.isEmpty) {
    return const {};
  }

  const needle = 'diff --git ';
  final result = <String, String>{};

  // The first header may appear at position 0 or after a leading newline.
  var pos = fullDiff.startsWith(needle) ? 0 : fullDiff.indexOf(needle);
  if (pos < 0) {
    return const {};
  }
  // If we found it after a newline, skip the \n.
  if (pos > 0 && fullDiff[pos - 1] == '\n') {
    // Fine — header starts at pos.
  }

  while (pos >= 0 && pos < fullDiff.length) {
    final lineEnd = fullDiff.indexOf('\n', pos);
    if (lineEnd < 0) {
      break;
    }

    final headerLine = fullDiff.substring(pos, lineEnd);
    // headerLine: "diff --git a/X b/Y"
    // Extract the b/ path (post-image filename — matches GitHub's listing).
    final bIdx = headerLine.indexOf(' b/');
    if (bIdx < 0) {
      pos = fullDiff.indexOf(needle, lineEnd + 1);
      if (pos > 0 && fullDiff[pos - 1] != '\n') {
        pos = fullDiff.indexOf(needle, pos + 1);
      }
      continue;
    }
    final bPath = headerLine.substring(bIdx + 3);

    // Find next file section.
    var nextPos = fullDiff.indexOf(needle, lineEnd + 1);
    // Skip false positives where needle appears inside diff content.
    while (nextPos > 0 && fullDiff[nextPos - 1] != '\n') {
      nextPos = fullDiff.indexOf(needle, nextPos + 1);
    }
    final sectionEnd = nextPos < 0 ? fullDiff.length : nextPos;
    final section = fullDiff.substring(lineEnd + 1, sectionEnd);

    // Strip git metadata before first @@ hunk header.
    final hunkStart = section.indexOf('@@');
    if (hunkStart >= 0) {
      final patchStart = section.lastIndexOf('\n', hunkStart) + 1;
      final patch = section.substring(patchStart);
      // Strip trailing newline.
      if (patch.endsWith('\n')) {
        result[bPath] = patch.substring(0, patch.length - 1);
      } else {
        result[bPath] = patch;
      }

      // Also index by the a/ path so rename lookups work.
      final aIdx = headerLine.indexOf(' a/');
      if (aIdx >= 0 && aIdx < bIdx) {
        final aPath = headerLine.substring(aIdx + 3, bIdx);
        if (aPath != bPath && !result.containsKey(aPath)) {
          result[aPath] = result[bPath]!;
        }
      }
    }

    pos = nextPos;
  }

  return result;
}
