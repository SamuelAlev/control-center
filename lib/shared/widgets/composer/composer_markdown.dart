import 'dart:typed_data';

/// Per-character style flags the composer paints over its raw Markdown.
///
/// The composer is a plain-text field: the prompt is sent as Markdown, so the
/// characters the person typed are the message. These flags only decide how
/// each character LOOKS while typing — a code span reads as code, `**bold**`
/// reads bold — with the delimiters kept and dimmed rather than removed.
/// Hiding them would need a document model, and would put caret offsets, undo,
/// IME composition and history recall out of step with the text.
///
/// This is an input highlighter, not a renderer. Sent messages still go
/// through the shared `cc_markdown` pipeline; nothing here decides what a
/// message means.
abstract final class ComposerMarkdownFlag {
  /// A delimiter (`**`, a backtick run, `#`, `>`, a list bullet, a fence).
  static const int marker = 1 << 0;

  /// Inside an inline code span, delimiters included.
  static const int code = 1 << 1;

  /// Inside a fenced code block, fence lines included.
  static const int block = 1 << 2;

  /// Strong emphasis body.
  static const int bold = 1 << 3;

  /// Emphasis body.
  static const int italic = 1 << 4;

  /// Strikethrough body.
  static const int strike = 1 << 5;

  /// ATX heading text.
  static const int heading = 1 << 6;

  /// Block quote text.
  static const int quote = 1 << 7;

  /// Link text of an inline `[text](url)` link.
  static const int link = 1 << 8;
}

/// A half-open range of the source the scanner must leave untouched.
typedef ComposerOpaqueRange = ({int start, int end});

/// Stands in for opaque and already-claimed characters while the inline
/// passes run: not whitespace and not a delimiter, so emphasis can still wrap
/// around a code span or a file reference without matching inside it.
const int _placeholder = 0xE000;

final RegExp _fenceOpen = RegExp(r'^ {0,3}(`{3,}|~{3,})');
final RegExp _thematicBreak = RegExp(r'^ {0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$');
final RegExp _heading = RegExp(r'^ {0,3}(#{1,6})(?=[ \t]|$)');
final RegExp _quote = RegExp(r'^ {0,3}>[ \t]?');
final RegExp _bullet = RegExp(r'^[ \t]*([-*+]|\d{1,9}[.)])(?=[ \t])');
final RegExp _link = RegExp(r'\[([^\]\n]+)\]\(([^)\s]+)\)');
final RegExp _strong = RegExp(r'(\*\*|__)(?=\S)(.+?)(?<=\S)\1');
final RegExp _strikethrough = RegExp(r'~~(?=\S)(.+?)(?<=\S)~~');
final RegExp _emphasisStar = RegExp(r'\*(?=[^\s*])(.+?)(?<=[^\s*])\*');
final RegExp _emphasisUnderscore = RegExp(r'_(?=[^\s_])(.+?)(?<=[^\s_])_');
final RegExp _wordChar = RegExp(r'\w');

/// Scans [source] and returns one [ComposerMarkdownFlag] word per UTF-16 code
/// unit; zero means plain text.
///
/// Characters inside an [opaque] range keep zero and are never part of a
/// delimiter. The composer passes its `@[file:…]` references here, which have
/// their own pill styling and whose names often contain `_`.
///
/// Inline constructs never span a line break. That is stricter than
/// CommonMark, deliberately: while someone is typing, an unclosed backtick on
/// one line must not turn every later line into code.
Uint16List scanComposerMarkdown(
  String source, {
  Iterable<ComposerOpaqueRange> opaque = const [],
}) {
  final flags = Uint16List(source.length);
  if (source.isEmpty) {
    return flags;
  }
  final blocked = Uint8List(source.length);
  for (final range in opaque) {
    final end = range.end.clamp(0, source.length);
    for (var i = range.start.clamp(0, end); i < end; i++) {
      blocked[i] = 1;
    }
  }

  String? fenceChar;
  var fenceLength = 0;
  var lineStart = 0;
  while (true) {
    var lineEnd = source.indexOf('\n', lineStart);
    if (lineEnd < 0) {
      lineEnd = source.length;
    }
    final line = source.substring(lineStart, lineEnd);

    if (fenceChar != null) {
      _fill(flags, lineStart, lineEnd, ComposerMarkdownFlag.block);
      if (_closesFence(line, fenceChar, fenceLength)) {
        _fill(flags, lineStart, lineEnd, ComposerMarkdownFlag.marker);
        fenceChar = null;
      }
    } else {
      final fence = _fenceOpen.firstMatch(line);
      if (fence != null) {
        final run = fence.group(1)!;
        fenceChar = run[0];
        fenceLength = run.length;
        _fill(
          flags,
          lineStart,
          lineEnd,
          ComposerMarkdownFlag.block | ComposerMarkdownFlag.marker,
        );
      } else {
        _scanLine(source, flags, blocked, lineStart, lineEnd);
      }
    }

    if (lineEnd >= source.length) {
      break;
    }
    lineStart = lineEnd + 1;
  }
  return flags;
}

bool _closesFence(String line, String char, int length) {
  final trimmed = line.trimRight();
  var i = 0;
  while (i < trimmed.length && i < 4 && trimmed[i] == ' ') {
    i++;
  }
  if (i > 3) {
    return false;
  }
  final run = trimmed.length - i;
  if (run < length) {
    return false;
  }
  for (var j = i; j < trimmed.length; j++) {
    if (trimmed[j] != char) {
      return false;
    }
  }
  return true;
}

void _scanLine(
  String source,
  Uint16List flags,
  Uint8List blocked,
  int lineStart,
  int lineEnd,
) {
  final line = source.substring(lineStart, lineEnd);
  if (_thematicBreak.hasMatch(line)) {
    _fill(flags, lineStart, lineEnd, ComposerMarkdownFlag.marker);
    return;
  }

  var contentStart = lineStart;
  var lineFlag = 0;
  final heading = _heading.firstMatch(line);
  if (heading != null) {
    _fill(
      flags,
      lineStart + heading.start,
      lineStart + heading.end,
      ComposerMarkdownFlag.marker,
    );
    contentStart = lineStart + heading.end;
    lineFlag = ComposerMarkdownFlag.heading;
  } else {
    final quote = _quote.firstMatch(line);
    if (quote != null) {
      _fill(
        flags,
        lineStart + quote.start,
        lineStart + quote.end,
        ComposerMarkdownFlag.marker,
      );
      contentStart = lineStart + quote.end;
      lineFlag = ComposerMarkdownFlag.quote;
    }
    final rest = source.substring(contentStart, lineEnd);
    final bullet = _bullet.firstMatch(rest);
    if (bullet != null) {
      // Dart matches carry no group offsets; the bullet group ends the match
      // (the trailing blank is a lookahead).
      _fill(
        flags,
        contentStart + bullet.end - bullet.group(1)!.length,
        contentStart + bullet.end,
        ComposerMarkdownFlag.marker,
      );
      contentStart += bullet.end;
    }
  }
  if (lineFlag != 0) {
    _fill(flags, contentStart, lineEnd, lineFlag);
  }
  _scanInline(source, flags, blocked, contentStart, lineEnd);
}

/// Code spans first (nothing inside one is Markdown), then links, then
/// emphasis over a copy where claimed characters read as [_placeholder].
void _scanInline(
  String source,
  Uint16List flags,
  Uint8List blocked,
  int start,
  int end,
) {
  if (start >= end) {
    return;
  }
  final units = List<int>.generate(
    end - start,
    (i) =>
        blocked[start + i] == 1 ? _placeholder : source.codeUnitAt(start + i),
  );

  _scanCodeSpans(units, flags, start);

  var text = String.fromCharCodes(units);
  for (final m in _link.allMatches(text)) {
    // `[` opens the match, so the link text starts one past it.
    final labelStart = m.start + 1;
    final labelEnd = labelStart + m.group(1)!.length;
    _fill(
      flags,
      start + m.start,
      start + labelStart,
      ComposerMarkdownFlag.marker,
    );
    _fill(
      flags,
      start + labelStart,
      start + labelEnd,
      ComposerMarkdownFlag.link,
    );
    _fill(flags, start + labelEnd, start + m.end, ComposerMarkdownFlag.marker);
    // A URL is full of `_` and `*` that are not emphasis.
    _claim(units, labelEnd, m.end);
    _claim(units, m.start, labelStart);
  }

  text = String.fromCharCodes(units);
  for (final m in _strong.allMatches(text)) {
    if (m.group(1) == '__' && !_intrawordSafe(text, m.start, m.end)) {
      continue;
    }
    _delimit(flags, start, m, 2, ComposerMarkdownFlag.bold);
    _claim(units, m.start, m.start + 2);
    _claim(units, m.end - 2, m.end);
  }

  text = String.fromCharCodes(units);
  for (final m in _strikethrough.allMatches(text)) {
    _delimit(flags, start, m, 2, ComposerMarkdownFlag.strike);
    _claim(units, m.start, m.start + 2);
    _claim(units, m.end - 2, m.end);
  }

  text = String.fromCharCodes(units);
  for (final m in _emphasisStar.allMatches(text)) {
    _delimit(flags, start, m, 1, ComposerMarkdownFlag.italic);
  }
  for (final m in _emphasisUnderscore.allMatches(text)) {
    // `snake_case_name` is an identifier, not emphasis.
    if (!_intrawordSafe(text, m.start, m.end)) {
      continue;
    }
    _delimit(flags, start, m, 1, ComposerMarkdownFlag.italic);
  }
}

/// Pairs backtick runs of equal length on the line, marks them, and claims
/// their characters so later passes skip them.
void _scanCodeSpans(List<int> units, Uint16List flags, int offset) {
  const backtick = 0x60;
  var i = 0;
  while (i < units.length) {
    if (units[i] != backtick) {
      i++;
      continue;
    }
    final openStart = i;
    while (i < units.length && units[i] == backtick) {
      i++;
    }
    final runLength = i - openStart;
    var j = i;
    var closeStart = -1;
    while (j < units.length) {
      if (units[j] != backtick) {
        j++;
        continue;
      }
      final candidate = j;
      while (j < units.length && units[j] == backtick) {
        j++;
      }
      if (j - candidate == runLength) {
        closeStart = candidate;
        break;
      }
    }
    if (closeStart < 0 || closeStart == i) {
      // Unclosed (still being typed) or empty: literal backticks.
      continue;
    }
    final closeEnd = closeStart + runLength;
    _fill(
      flags,
      offset + openStart,
      offset + closeEnd,
      ComposerMarkdownFlag.code,
    );
    _fill(flags, offset + openStart, offset + i, ComposerMarkdownFlag.marker);
    _fill(
      flags,
      offset + closeStart,
      offset + closeEnd,
      ComposerMarkdownFlag.marker,
    );
    _claim(units, openStart, closeEnd);
    i = closeEnd;
  }
}

void _delimit(
  Uint16List flags,
  int offset,
  RegExpMatch m,
  int width,
  int body,
) {
  _fill(
    flags,
    offset + m.start,
    offset + m.start + width,
    ComposerMarkdownFlag.marker,
  );
  _fill(flags, offset + m.start + width, offset + m.end - width, body);
  _fill(
    flags,
    offset + m.end - width,
    offset + m.end,
    ComposerMarkdownFlag.marker,
  );
}

/// An underscore delimiter run must not touch a word character outside it.
bool _intrawordSafe(String text, int start, int end) {
  final before = start > 0 && _wordChar.hasMatch(text[start - 1]);
  final after = end < text.length && _wordChar.hasMatch(text[end]);
  return !before && !after;
}

void _claim(List<int> units, int start, int end) {
  for (var i = start; i < end; i++) {
    units[i] = _placeholder;
  }
}

void _fill(Uint16List flags, int start, int end, int flag) {
  for (var i = start; i < end; i++) {
    flags[i] |= flag;
  }
}
