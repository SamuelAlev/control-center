/// GFM task-list source helpers: find and toggle `- [ ]` / `- [x]` items in
/// document order, matching what the block parser counts as task items.
///
/// Fenced code (```` ``` ```` / `~~~`) and HTML comments are skipped so a
/// Renovate `<!-- rebase-check -->` marker next to a real checkbox is
/// preserved, while a `- [ ]` inside a ``` example or an HTML comment is not
/// counted. The replacement touches only the inner ` `/`x` character — HTML
/// comments, indentation and the rest of the line stay byte-identical.
library;

/// One GFM task-list checkbox in [markdown], located by the `[` of `[ ]` /
/// `[x]` / `[X]`.
final class MarkdownTaskListItem {
  /// Creates a [MarkdownTaskListItem].
  const MarkdownTaskListItem({
    required this.bracketStart,
    required this.checked,
  });

  /// Index of the opening `[` in the source.
  final int bracketStart;

  /// Whether the box is ticked (`[x]` / `[X]`).
  final bool checked;

  /// Index of the inner ` `/`x`/`X` character.
  int get markStart => bracketStart + 1;
}

/// Returns every task-list checkbox in [markdown] in document order.
List<MarkdownTaskListItem> findMarkdownTaskListItems(String markdown) {
  if (markdown.isEmpty) {
    return const [];
  }
  final masked = _maskIgnoredRegions(markdown);
  final out = <MarkdownTaskListItem>[];
  for (final match in _taskItemRe.allMatches(masked)) {
    final mark = match.group(_markGroup)!;
    out.add(
      MarkdownTaskListItem(
        bracketStart: match.start + match.group(_prefixGroup)!.length,
        checked: mark.toLowerCase() == 'x',
      ),
    );
  }
  return out;
}

/// Toggles the [index]-th task-list checkbox in [markdown] (0-based).
///
/// Checked becomes `[ ]`; unchecked becomes `[x]`. Returns null when [index]
/// is out of range so the caller can no-op instead of writing a no-change
/// body.
String? toggleMarkdownTaskListItem(String markdown, int index) {
  final items = findMarkdownTaskListItems(markdown);
  if (index < 0 || index >= items.length) {
    return null;
  }
  final item = items[index];
  final next = item.checked ? ' ' : 'x';
  return markdown.replaceRange(item.markStart, item.markStart + 1, next);
}

/// Prefix up to (but not including) `[` + the inner mark. Groups:
///  1 = blockquote prefixes + indent + bullet/number + spacing (the prefix)
///  2 = the ` `/`x`/`X` inside the brackets
const int _prefixGroup = 1;
const int _markGroup = 2;

/// A list item whose first content is a GFM task marker.
///
/// Leading blockquote markers (`> `, `>> `) are allowed so a quoted task
/// still counts. Indent is unbounded so nested list items match; fenced
/// examples and HTML comments are stripped first, which is what keeps an
/// indented code-block `- [ ]` inside a fence from counting.
final RegExp _taskItemRe = RegExp(
  r'^((?: {0,3}> ?)*[ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+)\[([ xX])\](?=[ \t])',
  multiLine: true,
);

final RegExp _fenceOpen = RegExp(r'^( {0,3})(`{3,}|~{3,})[ \t]*(.*)$');

/// Replaces fenced-code interiors and HTML comments with spaces (newlines
/// kept) so `^` still lines up with the original and a `- [ ]` in those
/// regions cannot match.
String _maskIgnoredRegions(String source) {
  final chars = source.codeUnits.toList(growable: false);
  void blank(int start, int end) {
    for (var i = start; i < end && i < chars.length; i++) {
      final c = chars[i];
      if (c != 10 && c != 13) {
        chars[i] = 32;
      }
    }
  }

  var i = 0;
  String? fenceChar;
  var fenceLen = 0;
  while (i < source.length) {
    final nl = source.indexOf('\n', i);
    final lineEnd = nl < 0 ? source.length : nl;
    var contentEnd = lineEnd;
    if (contentEnd > i && source.codeUnitAt(contentEnd - 1) == 13) {
      contentEnd--;
    }
    final line = source.substring(i, contentEnd);
    if (fenceChar == null) {
      final open = _fenceOpen.firstMatch(line);
      if (open != null) {
        fenceChar = open.group(2)![0];
        fenceLen = open.group(2)!.length;
      }
    } else {
      final close = _fenceOpen.firstMatch(line);
      if (close != null &&
          close.group(2)![0] == fenceChar &&
          close.group(2)!.length >= fenceLen) {
        fenceChar = null;
        fenceLen = 0;
      } else {
        blank(i, contentEnd);
      }
    }
    i = nl < 0 ? source.length : nl + 1;
  }

  // HTML comments outside fences. Walk the already-partially-blanked buffer
  // so a comment that lived inside a fence (now spaces) cannot match.
  final masked = String.fromCharCodes(chars);
  var search = 0;
  while (true) {
    final start = masked.indexOf('<!--', search);
    if (start < 0) {
      break;
    }
    final end = masked.indexOf('-->', start + 4);
    if (end < 0) {
      blank(start, chars.length);
      break;
    }
    blank(start, end + 3);
    search = end + 3;
  }
  return String.fromCharCodes(chars);
}
