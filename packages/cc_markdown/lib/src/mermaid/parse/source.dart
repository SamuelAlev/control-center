/// Shared mermaid source handling: the pre-pass every dialect parser runs on,
/// plus the small string helpers they all need.
///
/// Pure Dart. Nothing here throws — a malformed source degrades to fewer
/// statements, never to an exception.
library;

/// A mermaid source split into its header keyword and statement lines, with
/// comments, init directives and YAML front matter removed.
class CcMermaidSource {
  /// Creates a [CcMermaidSource].
  const CcMermaidSource({
    required this.header,
    required this.statements,
    this.title,
  });

  /// The first non-empty line, trimmed (e.g. `flowchart LR`) — empty when the
  /// source carries no statements at all.
  final String header;

  /// Statement lines after the header, in source order. Blank lines are gone;
  /// `;`-separated statements are already split; indentation is preserved on
  /// the left so block parsers can still read nesting cues if they want to.
  final List<String> statements;

  /// `title:` from front matter, or null.
  final String? title;
}

final RegExp _frontMatterFence = RegExp(r'^\s*---\s*$');
final RegExp _frontMatterTitle = RegExp(r'''^\s*title\s*:\s*(.*?)\s*$''');
final RegExp _initDirective = RegExp(r'%%\{.*?\}%%');

/// Splits [source] into header + statements, dropping everything mermaid
/// ignores: YAML front matter (keeping its `title`), `%%{init: …}%%`
/// directives, `%%` comments and blank lines.
CcMermaidSource preprocessMermaid(String source) {
  var lines = source.replaceAll('\r\n', '\n').split('\n');

  // YAML front matter: `---` … `---` at the very top. Only `title` is honored;
  // theme/config keys are deliberately ignored (the host app themes diagrams
  // from its own design tokens, so author colors would fight dark mode).
  String? title;
  if (lines.isNotEmpty) {
    var first = 0;
    while (first < lines.length && lines[first].trim().isEmpty) {
      first++;
    }
    if (first < lines.length && _frontMatterFence.hasMatch(lines[first])) {
      var end = first + 1;
      while (end < lines.length && !_frontMatterFence.hasMatch(lines[end])) {
        end++;
      }
      if (end < lines.length) {
        for (var i = first + 1; i < end; i++) {
          final match = _frontMatterTitle.firstMatch(lines[i]);
          if (match != null) {
            title = stripMermaidQuotes(match.group(1)!);
          }
        }
        lines = lines.sublist(end + 1);
      }
    }
  }

  final statements = <String>[];
  var header = '';
  for (final raw in lines) {
    var line = raw.replaceAll(_initDirective, '');
    line = _stripComment(line);
    if (line.trim().isEmpty) {
      continue;
    }
    final parts = _splitStatements(line);
    if (header.isEmpty) {
      // A one-liner (`flowchart TD; A-->B;`) carries its header AND statements
      // on the same line.
      header = parts.first.trim();
      statements.addAll(parts.skip(1));
      continue;
    }
    statements.addAll(parts);
  }
  return CcMermaidSource(header: header, statements: statements, title: title);
}

/// Removes a trailing `%%` comment, ignoring `%%` inside quotes.
String _stripComment(String line) {
  var quote = 0;
  for (var i = 0; i + 1 < line.length; i++) {
    final unit = line.codeUnitAt(i);
    if (unit == 0x22 /* " */ || unit == 0x27 /* ' */ ) {
      if (quote == 0) {
        quote = unit;
      } else if (quote == unit) {
        quote = 0;
      }
      continue;
    }
    if (quote == 0 && unit == 0x25 /* % */ && line.codeUnitAt(i + 1) == 0x25) {
      return line.substring(0, i);
    }
  }
  return line;
}

/// Splits a line on `;` statement separators outside quotes and brackets.
List<String> _splitStatements(String line) {
  if (!line.contains(';')) {
    return [line];
  }
  final out = <String>[];
  final buf = StringBuffer();
  var quote = 0;
  var depth = 0;
  for (var i = 0; i < line.length; i++) {
    final unit = line.codeUnitAt(i);
    if (quote != 0) {
      buf.writeCharCode(unit);
      if (unit == quote) {
        quote = 0;
      }
      continue;
    }
    switch (unit) {
      case 0x22:
      case 0x27:
        quote = unit;
        buf.writeCharCode(unit);
      case 0x5B: // [
      case 0x28: // (
      case 0x7B: // {
        depth++;
        buf.writeCharCode(unit);
      case 0x5D: // ]
      case 0x29: // )
      case 0x7D: // }
        if (depth > 0) {
          depth--;
        }
        buf.writeCharCode(unit);
      case 0x3B: // ;
        if (depth == 0) {
          if (buf.toString().trim().isNotEmpty) {
            out.add(buf.toString());
          }
          buf.clear();
        } else {
          buf.writeCharCode(unit);
        }
      default:
        buf.writeCharCode(unit);
    }
  }
  if (buf.toString().trim().isNotEmpty) {
    out.add(buf.toString());
  }
  return out;
}

final RegExp _breakTag = RegExp(r'<br\s*/?>', caseSensitive: false);
final RegExp _htmlTag = RegExp(
  r'</?(?:b|i|em|strong|u|span|code|p|div)\b[^>]*>',
  caseSensitive: false,
);

/// Splits a mermaid label into display lines: `<br>` tags, literal `\n`
/// escapes and real newlines all break; light HTML formatting tags are
/// stripped (the diagram renderer draws plain runs); entities are decoded.
///
/// Returns an empty list for an empty label so callers can fall back to a node
/// id.
List<String> splitMermaidLabel(String? label) {
  if (label == null) {
    return const [];
  }
  final normalized = decodeMermaidEntities(label)
      .replaceAll(_breakTag, '\n')
      .replaceAll(r'\n', '\n')
      .replaceAll(_htmlTag, '');
  final lines = <String>[];
  for (final line in normalized.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      lines.add(trimmed);
    }
  }
  // A label of only whitespace still deserves one (blank) line if the author
  // wrote something quoted, but an empty string means "no label".
  if (lines.isEmpty && normalized.trim().isNotEmpty) {
    lines.add(normalized.trim());
  }
  return lines;
}

const Map<String, String> _entities = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  '&nbsp;': ' ',
  '#quot;': '"',
  '#35;': '#',
  '#59;': ';',
  '#colon;': ':',
  '#semi;': ';',
  '#lt;': '<',
  '#gt;': '>',
  '#amp;': '&',
  '#39;': "'",
  '&#39;': "'",
  '&#35;': '#',
};

/// Decodes the HTML/mermaid entity escapes mermaid labels use (`#quot;`,
/// `&amp;`, `#35;`, …). Unknown entities pass through untouched.
String decodeMermaidEntities(String input) {
  if (!input.contains('&') && !input.contains('#')) {
    return input;
  }
  var out = input;
  for (final entry in _entities.entries) {
    if (out.contains(entry.key)) {
      out = out.replaceAll(entry.key, entry.value);
    }
  }
  return out;
}

/// Strips one layer of matching `"`, `'`, or backtick quotes, plus surrounding
/// whitespace.
String stripMermaidQuotes(String input) {
  var text = input.trim();
  while (text.length >= 2) {
    final first = text[0];
    final last = text[text.length - 1];
    if ((first == '"' && last == '"') ||
        (first == "'" && last == "'") ||
        (first == '`' && last == '`')) {
      text = text.substring(1, text.length - 1).trim();
      continue;
    }
    break;
  }
  return text;
}

/// Whether [unit] can appear in a bare mermaid identifier.
bool isMermaidIdUnit(int unit) {
  return (unit >= 0x30 && unit <= 0x39) || // 0-9
      (unit >= 0x41 && unit <= 0x5A) || // A-Z
      (unit >= 0x61 && unit <= 0x7A) || // a-z
      unit == 0x5F || // _
      unit == 0x2D || // -
      unit == 0x2E || // .
      unit == 0x2F || // /
      unit == 0x23 || // #
      unit == 0x40 || // @
      unit > 0x7F; // non-ASCII (accented / CJK ids)
}

/// Reads a bare identifier at [start] in [text]; returns the empty string when
/// no identifier character is there.
///
/// A `-` is part of an identifier (`LINE-ITEM`, `my-node`) EXCEPT where it opens
/// a link token — `A-->B`, `A-.->B`, `A--x B` are written without spaces all the
/// time, so a dash followed by `-`, `.`, `>` or the end of the statement ends the
/// identifier instead of extending it.
String readMermaidId(String text, int start) {
  var i = start;
  while (i < text.length) {
    final unit = text.codeUnitAt(i);
    if (!isMermaidIdUnit(unit)) {
      break;
    }
    if (unit == 0x2D /* - */ ) {
      if (i + 1 >= text.length) {
        break;
      }
      final next = text.codeUnitAt(i + 1);
      if (next == 0x2D || next == 0x2E /* . */ || next == 0x3E /* > */ ) {
        break;
      }
    }
    i++;
  }
  return text.substring(start, i);
}

/// Index of the first non-space character at or after [start].
int skipMermaidSpaces(String text, int start) {
  var i = start;
  while (i < text.length) {
    final unit = text.codeUnitAt(i);
    if (unit == 0x20 || unit == 0x09) {
      i++;
      continue;
    }
    break;
  }
  return i;
}

/// Splits a statement's `word rest…` into (first word, remainder).
(String, String) splitFirstWord(String statement) {
  final trimmed = statement.trim();
  final space = trimmed.indexOf(RegExp(r'\s'));
  if (space < 0) {
    return (trimmed, '');
  }
  return (trimmed.substring(0, space), trimmed.substring(space + 1).trim());
}
