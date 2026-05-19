/// Shared HTML entity vocabulary: the named entities tolerated in chat/PR
/// bodies plus generic numeric (`&#123;` / `&#x1F;`) decoding. Used by the
/// inline parser (positional, via [namedHtmlEntities]) and the HTML block
/// interpreter (whole-string, via [decodeHtmlEntities]).
library;

/// Common named HTML entities tolerated in chat/PR bodies. Numeric entities
/// are decoded generically.
const Map<String, String> namedHtmlEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'copy': '©',
  'reg': '®',
  'trade': '™',
  'hellip': '…',
  'mdash': '—',
  'ndash': '–',
  'lsquo': '‘',
  'rsquo': '’',
  'ldquo': '“',
  'rdquo': '”',
  'bull': '•',
  'middot': '·',
  'times': '×',
  'darr': '↓',
  'uarr': '↑',
  'rarr': '→',
  'larr': '←',
};

/// Decodes `&name;` / `&#123;` / `&#x1F;` entities in [text]; anything
/// unrecognized stays literal. Never throws.
String decodeHtmlEntities(String text) {
  var amp = text.indexOf('&');
  if (amp == -1) {
    return text;
  }
  final out = StringBuffer();
  var last = 0;
  while (amp != -1) {
    final decoded = decodeHtmlEntityAt(text, amp);
    if (decoded == null) {
      amp = text.indexOf('&', amp + 1);
      continue;
    }
    out
      ..write(text.substring(last, amp))
      ..write(decoded.$1);
    last = amp + decoded.$2;
    amp = text.indexOf('&', last);
  }
  out.write(text.substring(last));
  return out.toString();
}

/// `&name;` / `&#123;` / `&#x1F;` at [pos] → (decoded, consumed) or null.
(String, int)? decodeHtmlEntityAt(String text, int pos) {
  final semi = text.indexOf(';', pos + 1);
  if (semi == -1 || semi - pos > 32) {
    return null;
  }
  final body = text.substring(pos + 1, semi);
  if (body.isEmpty) {
    return null;
  }
  if (body.startsWith('#')) {
    final isHex = body.length > 1 && (body[1] == 'x' || body[1] == 'X');
    final digits = body.substring(isHex ? 2 : 1);
    final value = int.tryParse(digits, radix: isHex ? 16 : 10);
    if (value == null || value <= 0 || value > 0x10FFFF) {
      return null;
    }
    return (String.fromCharCode(value), semi - pos + 1);
  }
  final named = namedHtmlEntities[body];
  if (named == null) {
    return null;
  }
  return (named, semi - pos + 1);
}
