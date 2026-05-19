/// Resolves the 1-indexed column of [symbol] on [line].
///
/// Returns an int on success or a String error. Refusing to guess is the
/// point: a navigation answer about the wrong symbol is worse than no
/// answer, because the model cannot tell it apart from a correct one.
Object resolveSymbolColumn(String content, int line, String? symbol) {
  final lines = content.split('\n');
  if (line < 1 || line > lines.length) {
    return 'Line $line is outside the file (${lines.length} lines).';
  }
  final text = lines[line - 1];
  if (symbol == null || symbol.isEmpty) {
    return 'This action needs `symbol` — the name to resolve on line $line '
        '— so the position is unambiguous. Line $line reads: '
        '${text.trim()}';
  }
  // `name#2` selects the second occurrence on the line.
  var needle = symbol;
  var occurrence = 1;
  final hash = symbol.lastIndexOf('#');
  if (hash > 0) {
    final parsed = int.tryParse(symbol.substring(hash + 1));
    if (parsed != null && parsed > 0) {
      needle = symbol.substring(0, hash);
      occurrence = parsed;
    }
  }
  var index = -1;
  var found = 0;
  var from = 0;
  while (true) {
    final at = text.indexOf(needle, from);
    if (at < 0) {
      break;
    }
    found++;
    if (found == occurrence) {
      index = at;
      break;
    }
    from = at + 1;
  }
  if (index < 0) {
    final lower = text.toLowerCase().indexOf(needle.toLowerCase());
    if (lower >= 0) {
      index = lower;
    } else {
      return 'Could not find "$needle" on line $line. It reads: '
          '${text.trim()}';
    }
  }
  return index + 1;
}
