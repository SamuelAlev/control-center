/// What [neutralizeConnectMentions] puts between `@` and a name: a zero-width
/// space, invisible when rendered, which GitHub does not read as part of a
/// mention.
const String connectMentionBreak = '\u200B';

final RegExp _mentionAt = RegExp(r'(?<![A-Za-z0-9_])@(?=[A-Za-z0-9_{])');
final RegExp _encodedAt = RegExp(
  r'&(?:#0*64|#x0*40|commat);',
  caseSensitive: false,
);
final RegExp _fence = RegExp(r'^ {0,3}(`{3,}|~{3,})');
final RegExp _url = RegExp(r'https?://[^\s<>()\[\]]+', caseSensitive: false);

/// [body] with every `@`-mention outside code spans, fenced blocks, and URLs
/// made inert so text posted by the shared Connect GitHub App bot cannot page
/// any user or team (`@org/team`). Idempotent.
String neutralizeConnectMentions(String body) {
  if (!body.contains('@') && !body.contains('&')) {
    return body;
  }
  final out = StringBuffer();
  String? openFence;
  final lines = body.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final fence = _fence.firstMatch(line)?.group(1);
    if (openFence != null) {
      out.write(line);
      if (fence != null &&
          fence[0] == openFence[0] &&
          fence.length >= openFence.length &&
          line.trim() == fence) {
        openFence = null;
      }
    } else if (fence != null) {
      openFence = fence;
      out.write(line);
    } else {
      out.write(_neutralizeOutsideCodeSpans(line));
    }
    if (i < lines.length - 1) {
      out.write('\n');
    }
  }
  return out.toString();
}

/// Formats [body] as an automated Control Center bot review comment on behalf
/// of [login], neutralizing every `@`-mention inside [body].
String attributeConnectBotComment(String login, String body) =>
    '**Control Center** (for @$login): ${neutralizeConnectMentions(body)}';

String _neutralizeOutsideCodeSpans(String line) {
  String plain(String text) => text.splitMapJoin(
    _url,
    onNonMatch: (t) => t
        .replaceAll(_encodedAt, '@$connectMentionBreak')
        .replaceAll(_mentionAt, '@$connectMentionBreak'),
  );
  final out = StringBuffer();
  var cursor = 0;
  var scan = 0;
  while (scan < line.length) {
    final open = line.indexOf('`', scan);
    if (open < 0) {
      break;
    }
    var slashes = 0;
    while (open - slashes > 0 && line[open - slashes - 1] == r'\') {
      slashes++;
    }
    if (slashes.isOdd) {
      scan = open + 1;
      continue;
    }
    var openEnd = open;
    while (openEnd < line.length && line[openEnd] == '`') {
      openEnd++;
    }
    final run = openEnd - open;
    var close = -1;
    var search = openEnd;
    while (search < line.length) {
      final next = line.indexOf('`', search);
      if (next < 0) {
        break;
      }
      var nextEnd = next;
      while (nextEnd < line.length && line[nextEnd] == '`') {
        nextEnd++;
      }
      if (nextEnd - next == run) {
        close = nextEnd;
        break;
      }
      search = nextEnd;
    }
    if (close < 0) {
      scan = openEnd;
      continue;
    }
    out
      ..write(plain(line.substring(cursor, open)))
      ..write(line.substring(open, close));
    cursor = close;
    scan = close;
  }
  out.write(plain(line.substring(cursor)));
  return out.toString();
}
