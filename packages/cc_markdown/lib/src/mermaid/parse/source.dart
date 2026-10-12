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
  /// A quoted label written over several lines stays one statement, its
  /// newline kept as `\n`.
  final List<String> statements;

  /// `title:` from front matter, or null.
  final String? title;
}

final RegExp _frontMatterFence = RegExp(r'^\s*---\s*$');
final RegExp _frontMatterTitle = RegExp(r'''^\s*title\s*:\s*(.*?)\s*$''');

/// Splits [source] into header + statements, dropping everything mermaid
/// ignores: YAML front matter (keeping its `title`), `%%{init: …}%%`
/// directives, `%%` comments and blank lines.
CcMermaidSource preprocessMermaid(String source) {
  var text = source.replaceAll('\r\n', '\n');

  // YAML front matter: `---` … `---` at the very top. Only `title` is honored;
  // theme/config keys are deliberately ignored (the host app themes diagrams
  // from its own design tokens, so author colors would fight dark mode).
  String? title;
  final lines = text.split('\n');
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
      text = lines.sublist(end + 1).join('\n');
    }
  }

  final statements = <String>[];
  var header = '';
  for (final part in _splitStatements(text)) {
    if (header.isEmpty) {
      // A one-liner (`flowchart TD; A-->B;`) carries its header AND statements
      // on the same line.
      header = part.trim();
      continue;
    }
    statements.add(part);
  }
  return CcMermaidSource(header: header, statements: statements, title: title);
}

/// Splits [text] into statements: a top-level `;` or a line break ends one,
/// `%%` starts a comment that runs to the end of its line, and a `%%{ … }%%`
/// directive (which may wrap lines — `init` blocks in the wild do) is dropped.
/// Quotes and brackets protect all of the above.
///
/// A `"`-quoted label still open at a line break continues onto the next line,
/// so a label written over several lines stays one statement with its newline
/// intact. That happens only where a quoted label can start (inside brackets or
/// after a link/label opener) and only while another `"` still lies ahead: a
/// stray, never-closed quote must not swallow the statements below it.
List<String> _splitStatements(String text) {
  final out = <String>[];
  final buf = StringBuffer();
  // Index of the last `"`; a quote open at a newline can only continue while a
  // closing quote is still ahead of it.
  final lastQuote = text.lastIndexOf('"');
  var quote = 0;
  var quoteSpansLines = false;
  var depth = 0;
  var prevNonBlank = 0;

  void flush() {
    if (buf.toString().trim().isNotEmpty) {
      out.add(buf.toString());
    }
    buf.clear();
    // Bracket depth and the last written code unit are statement-scoped, so a
    // statement ending in `]`/`-`/`|` cannot make the *next* statement's quote
    // look like a span-able label opener.
    depth = 0;
    prevNonBlank = 0;
  }

  var i = 0;
  while (i < text.length) {
    final unit = text.codeUnitAt(i);

    if (quote != 0) {
      if (unit == 0x0A /* newline */ ) {
        if (quoteSpansLines && i < lastQuote) {
          buf.writeCharCode(unit);
        } else {
          // A `'`-quoted run and a stray `"` end with their line, so the
          // statements after a malformed one survive.
          quote = 0;
          flush();
        }
      } else {
        buf.writeCharCode(unit);
        if (unit == quote) {
          quote = 0;
        }
      }
      i++;
      continue;
    }

    if (unit == 0x0A /* newline */ ) {
      flush();
      i++;
      continue;
    }
    if (unit == 0x25 /* % */ &&
        i + 1 < text.length &&
        text.codeUnitAt(i + 1) == 0x25) {
      if (i + 2 < text.length && text.codeUnitAt(i + 2) == 0x7B /* { */ ) {
        final close = text.indexOf('}%%', i + 3);
        if (close >= 0) {
          i = close + 3;
          continue;
        }
      }
      // A comment — or an unterminated directive — ends with its line.
      while (i < text.length && text.codeUnitAt(i) != 0x0A) {
        i++;
      }
      continue;
    }

    switch (unit) {
      case 0x22: // "
      case 0x27: // '
        quote = unit;
        // Only a `"` label spans lines, and only where one may start: inside a
        // shape/label bracket, or right after a `|` or link opener.
        quoteSpansLines =
            unit == 0x22 &&
            (depth > 0 ||
                prevNonBlank == 0x7C /* | */ ||
                prevNonBlank == 0x2D /* - */ ||
                prevNonBlank == 0x2E /* . */ ||
                prevNonBlank == 0x3D /* = */ ||
                prevNonBlank == 0x3E /* > */ );
        buf.writeCharCode(unit);
      case 0x5B: // [
      case 0x28: // (
      case 0x7B: // {
        depth++;
        prevNonBlank = unit;
        buf.writeCharCode(unit);
      case 0x5D: // ]
      case 0x29: // )
      case 0x7D: // }
        if (depth > 0) {
          depth--;
        }
        prevNonBlank = unit;
        buf.writeCharCode(unit);
      case 0x3B: // ;
        if (depth == 0) {
          flush();
        } else {
          prevNonBlank = unit;
          buf.writeCharCode(unit);
        }
      default:
        if (unit != 0x20 && unit != 0x09) {
          prevNonBlank = unit;
        }
        buf.writeCharCode(unit);
    }
    i++;
  }
  flush();
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
/// Escapes are decoded last, so text an author escaped (`#lt;b#gt;`,
/// `&lt;br&gt;`) stays visible instead of being taken for markup or a break.
///
/// Returns an empty list for an empty label so callers can fall back to a node
/// id.
List<String> splitMermaidLabel(String? label) {
  if (label == null) {
    return const [];
  }
  // Markup is handled before entities: `#lt;b#gt;`/`&lt;b&gt;` is an author
  // escaping angle brackets so they show as text, so the decoded `<b>` must
  // not be read as an active tag (nor `#lt;br#gt;` as a line break).
  final decoded = decodeMermaidEntities(
    label
        .replaceAll(_breakTag, '\n')
        .replaceAll(_htmlTag, '')
        .replaceAll(r'\n', '\n'),
  );
  final lines = <String>[];
  for (final line in decoded.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      lines.add(trimmed);
    }
  }
  // A label of only whitespace still deserves one (blank) line if the author
  // wrote something quoted, but an empty string means "no label".
  if (lines.isEmpty && decoded.trim().isNotEmpty) {
    lines.add(decoded.trim());
  }
  return lines;
}

/// The named entity codes mermaid labels use, keyed without their `&`/`#`
/// frame: the HTML names this engine has always understood plus mermaid's own
/// `#colon;`-style codes. Numeric codes need no entry — `#NN;`, `&#NN;` and
/// `&#xHH;` are decoded generically.
const Map<String, String> _namedEntities = {
  'amp': '&',
  'apos': "'",
  'colon': ':',
  'gt': '>',
  'lt': '<',
  'nbsp': ' ',
  'quot': '"',
  'semi': ';',
};

/// One entity token: an HTML `&name;`, a numeric `#NN;`/`&#NN;`/`&#xHH;`, or a
/// mermaid `#name;`. The `&` is optional on the mermaid forms — that is how
/// `A["#quot;quoted#quot;"]` and `#9829;` are written.
final RegExp _entityToken = RegExp(
  r'&[a-zA-Z][a-zA-Z0-9]*;'
  r'|&?#(?:[xX][0-9a-fA-F]+|[0-9]+);'
  r'|&?#[a-zA-Z][a-zA-Z0-9]*;',
);

/// Decodes the HTML/mermaid entity escapes mermaid labels use (`#quot;`,
/// `&amp;`, `#35;`, `&#x2764;`, …).
///
/// The scan runs once, left to right, and never re-reads what a decode
/// produced: `&amp;lt;` is `&lt;` — an escaped ampersand followed by the
/// literal text `lt;` — not a second decode to `<`. Unknown names pass through
/// untouched, as do codes that are not valid Unicode scalars (`&#0;`,
/// `&#xD800;`, `&#x110000;`), so a label never throws.
String decodeMermaidEntities(String input) {
  if (!input.contains('&') && !input.contains('#')) {
    return input;
  }
  final out = StringBuffer();
  var literal = 0;
  var i = 0;
  while (i < input.length) {
    final unit = input.codeUnitAt(i);
    if (unit != 0x26 /* & */ && unit != 0x23 /* # */ ) {
      i++;
      continue;
    }
    final match = _entityToken.matchAsPrefix(input, i);
    if (match == null) {
      i++;
      continue;
    }
    final decoded = _decodeEntityToken(match.group(0)!);
    if (decoded == null) {
      i = match.end;
      continue;
    }
    out
      ..write(input.substring(literal, i))
      ..write(decoded);
    i = match.end;
    literal = i;
  }
  out.write(input.substring(literal));
  return out.toString();
}

/// Decodes one entity token, or null when it names nothing decodable.
String? _decodeEntityToken(String token) {
  final body = token.substring(token.startsWith('&') ? 1 : 0, token.length - 1);
  if (!body.startsWith('#')) {
    return _namedEntities[body];
  }
  final digits = body.substring(1);
  final hex = digits.startsWith('x') || digits.startsWith('X');
  final codePoint = hex
      ? int.tryParse(digits.substring(1), radix: 16)
      : int.tryParse(digits);
  if (codePoint == null) {
    // `#colon;`/`#semi;` are names mermaid writes behind the same `#`.
    return _namedEntities[digits];
  }
  if (codePoint <= 0 || codePoint > 0x10FFFF) {
    return null;
  }
  if (codePoint >= 0xD800 && codePoint <= 0xDFFF) {
    return null; // A lone surrogate is not a character.
  }
  return String.fromCharCode(codePoint);
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
