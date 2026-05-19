/// The content of a parsed Read-tool output, with the original starting line.
class ParsedReadOutput {
  /// Creates a [ParsedReadOutput].
  const ParsedReadOutput(this.content, this.startLine);

  /// File content with any line-number prefixes stripped.
  final String content;

  /// Line number of the first content line (1 when unknown).
  final int startLine;
}

final _linePrefix = RegExp(r'^\s*(\d+)[\t|:→]\s?(.*)$');

/// Parses a Read-tool [output] that may carry `cat -n`-style line-number
/// prefixes (e.g. `   12→const x = 1`). Strips the prefixes and recovers the
/// starting line number. When the output isn't line-numbered, returns it
/// verbatim with [ParsedReadOutput.startLine] = 1.
ParsedReadOutput parseReadOutput(String output) {
  var text = output;
  // Strip a wrapping <file ...>…</file> envelope if present.
  text = text.replaceFirst(RegExp(r'^\s*<file[^>]*>\n?'), '');
  text = text.replaceFirst(RegExp(r'\n?</file>\s*$'), '');
  // Drop a trailing "(File has more lines…)" style note.
  text = text.replaceFirst(
    RegExp(r'\n+\(.*more lines.*\)\s*$', caseSensitive: false),
    '',
  );

  final lines = text.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  if (lines.isEmpty) {
    return const ParsedReadOutput('', 1);
  }

  var matched = 0;
  int? firstNumber;
  final stripped = <String>[];
  for (final line in lines) {
    final m = _linePrefix.firstMatch(line);
    if (m != null) {
      matched++;
      firstNumber ??= int.tryParse(m.group(1)!);
      stripped.add(m.group(2) ?? '');
    } else {
      stripped.add(line);
    }
  }

  // Only treat as line-numbered when the majority of lines carry a prefix.
  if (matched >= (lines.length / 2).ceil() && firstNumber != null) {
    return ParsedReadOutput(stripped.join('\n'), firstNumber);
  }
  return ParsedReadOutput(text, 1);
}
