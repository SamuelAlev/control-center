/// A fence line: up to three spaces, then three or more backticks or tildes.
final RegExp _fenceLine = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');

/// The body of the fenced code block holding [offset] — the text between the
/// opening fence's line and the closing one's, without the newline before the
/// closer — or null when [offset] is not inside a fence's body. A fence left
/// open runs to the end of [text], as it renders.
({int start, int end})? markdownFenceBodyAt(String text, int offset) {
  String? marker;
  var bodyStart = 0;
  var lineStart = 0;
  while (lineStart <= text.length) {
    final newline = text.indexOf('\n', lineStart);
    final lineEnd = newline == -1 ? text.length : newline;
    if (marker == null && lineStart > offset) {
      return null;
    }
    final match = _fenceLine.firstMatch(text.substring(lineStart, lineEnd));
    if (match != null) {
      final run = match.group(1)!;
      final rest = match.group(2)!;
      if (marker == null) {
        // A backtick fence's info string cannot hold a backtick.
        if (run[0] != '`' || !rest.contains('`')) {
          marker = run;
          bodyStart = lineEnd + 1;
        }
      } else if (run[0] == marker[0] &&
          run.length >= marker.length &&
          rest.trim().isEmpty) {
        final bodyEnd = lineStart - 1;
        if (bodyEnd >= bodyStart && offset >= bodyStart && offset <= bodyEnd) {
          return (start: bodyStart, end: bodyEnd);
        }
        marker = null;
      }
    }
    if (newline == -1) {
      break;
    }
    lineStart = newline + 1;
  }
  if (marker != null && bodyStart <= text.length && offset >= bodyStart) {
    return (start: bodyStart, end: text.length);
  }
  return null;
}
