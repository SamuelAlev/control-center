import 'dart:convert';

/// The size of [text] in UTF-8 bytes, which is what every code mode cap is
/// measured in: the runner, the protocol and the database all see bytes.
int utf8Length(String text) => utf8.encode(text).length;

/// The longest prefix of [text] whose UTF-8 encoding fits in [maxBytes].
///
/// Cuts on a code point boundary, so the result never ends in half a
/// surrogate pair or a partial multi-byte sequence.
String cutToUtf8Bytes(String text, int maxBytes) {
  if (maxBytes <= 0) {
    return '';
  }
  var bytes = 0;
  var end = 0;
  for (final rune in text.runes) {
    final size = rune < 0x80
        ? 1
        : rune < 0x800
        ? 2
        : rune < 0x10000
        ? 3
        : 4;
    if (bytes + size > maxBytes) {
      break;
    }
    bytes += size;
    end += rune >= 0x10000 ? 2 : 1;
  }
  return text.substring(0, end);
}

/// A cut of [text] at UTF-16 index [at] (clamped to the text) that leaves
/// no half of a surrogate pair on either side: [at], or one less when [at]
/// falls inside a pair. What a head (`text.substring(0, cut)`) of at most
/// [at] units ends on.
int safeCutBefore(String text, int at) {
  final cut = at.clamp(0, text.length);
  return _insidePair(text, cut) ? cut - 1 : cut;
}

/// [safeCutBefore], but one more instead of one less: what a drop of at
/// least [at] units from the start (`text.substring(cut)`) ends on, so a
/// loop that drops until it is under a bound always makes progress.
int safeCutAfter(String text, int at) {
  final cut = at.clamp(0, text.length);
  return _insidePair(text, cut) ? cut + 1 : cut;
}

bool _insidePair(String text, int at) {
  if (at <= 0 || at >= text.length) {
    return false;
  }
  final before = text.codeUnitAt(at - 1);
  final after = text.codeUnitAt(at);
  return before >= 0xD800 &&
      before <= 0xDBFF &&
      after >= 0xDC00 &&
      after <= 0xDFFF;
}

/// Fits [text] into [maxBytes], ending it with a marker that names the
/// original size when anything was cut.
String boundUtf8(String text, int maxBytes) {
  final length = utf8Length(text);
  if (length <= maxBytes) {
    return text;
  }
  final marker = '… [$length bytes, truncated]';
  return '${cutToUtf8Bytes(text, maxBytes - utf8Length(marker))}$marker';
}

/// C0 and C1 control characters, DEL, the line and paragraph separators, and
/// the Unicode bidirectional controls (the Arabic letter mark, the
/// left-to-right and right-to-left marks, the embeddings, overrides and
/// isolates). Text a script or a runner chose is
/// never shown or stored with them: a control character can break a line a
/// reader trusts, and a bidirectional one can make text read in another order
/// than it is stored.
final RegExp _unsafeCharacters = RegExp(
  r'[\x00-\x1f\x7f-\x9f\u061c\u200e\u200f\u2028\u2029\u202a-\u202e'
  r'\u2066-\u2069]',
);

/// Whether [text] holds a character [withoutUnsafeCharacters] replaces.
bool hasUnsafeCharacters(String text) => _unsafeCharacters.hasMatch(text);

/// [text] with every control and bidirectional character (see
/// [_unsafeCharacters]) replaced by a space.
String withoutUnsafeCharacters(String text) =>
    text.replaceAll(_unsafeCharacters, ' ');

/// [text] as one line of at most [maxChars] characters (Unicode scalar
/// values): each run of whitespace, control and bidirectional characters
/// becomes one space, the ends are trimmed, and a longer line is cut at a
/// character boundary and ended with an ellipsis.
String oneLineLabel(String text, int maxChars) {
  final line = withoutUnsafeCharacters(
    text,
  ).replaceAll(RegExp(r'\s+'), ' ').trim();
  final runes = line.runes;
  if (runes.length <= maxChars) {
    return line;
  }
  final kept = String.fromCharCodes(runes.take(maxChars - 1)).trimRight();
  return '$kept…';
}

/// Whether [text] is already what [oneLineLabel] makes of it for [maxChars].
bool isOneLineLabel(String text, int maxChars) =>
    oneLineLabel(text, maxChars) == text;
