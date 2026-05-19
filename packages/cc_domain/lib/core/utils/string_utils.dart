import 'package:html/parser.dart' as html_parser;

/// Slugify.
String slugify(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

/// Safely decodes HTML entities (e.g. `&amp;`, `&#8216;`, `&lt;`) in [input]
/// without executing any markup. Returns the original string on parse errors.
String decodeHtmlEntities(String input) {
  if (input.isEmpty) {
    return input;
  }
  try {
    final fragment = html_parser.parseFragment(input);
    return fragment.text ?? input;
  } on Object catch (_) {
    return input;
  }
}

/// Default length cap for a [oneLineLabel] — wide enough for a roster line,
/// a registry display name, or a system-prompt field without wrapping.
const int kOneLineLabelMax = 80;

/// Matches any run of whitespace, control characters (`\p{Cc}`, incl. ESC),
/// and format characters (`\p{Cf}`, incl. zero-width separators). `\s` alone
/// misses U+0085 NEL, ANSI escapes, and the zero-width joiners, so we union
/// all three classes.
final RegExp _whitespaceOrControl = RegExp(r'[\p{Cc}\p{Cf}\s]+', unicode: true);

/// Collapses [text] to a single, length-capped line safe for a roster line, a
/// registry display name, or a system-prompt field.
///
/// Every run of whitespace AND control/format characters — including U+0085
/// NEL, ESC/ANSI sequences, and zero-width separators that `\s` misses — is
/// collapsed to a single space, then the result is trimmed and capped at [max]
/// characters. So untrusted text (a spawned agent's role, a peer's activity
/// gist) can neither break the line, inject prompt structure, nor smuggle
/// terminal escapes — every caller is safe without sanitizing at its own site.
///
/// [max] is clamped to at least 1; when truncation happens an ellipsis (`…`)
/// is appended. Length is measured in Unicode code points (runes), not UTF-16
/// code units, so truncation can never split an astral character into a lone
/// surrogate.
String oneLineLabel(String text, {int max = kOneLineLabelMax}) {
  final oneLine = text.replaceAll(_whitespaceOrControl, ' ').trim();
  final cap = max < 1 ? 1 : max;
  final runes = oneLine.runes.toList(growable: false);
  if (runes.length <= cap) {
    return oneLine;
  }
  return '${String.fromCharCodes(runes.take(cap - 1))}…';
}

