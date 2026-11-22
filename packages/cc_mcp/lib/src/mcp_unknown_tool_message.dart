/// Builds a rich "unknown tool" message: names the nearest of the catalogued
/// [names], points at the discovery tools and explains the bare-name/prefix
/// convention — so a wrong name is a one-shot correction, not a dead end.
///
/// [names] are the tools the caller may name: a discovery tool is pointed at
/// only when it is among them. [scripts] is set for a run with `repl`, which
/// is pointed at `searchTools` inside a script instead.
String unknownToolMessage(
  String requested,
  Iterable<String> names, {
  required bool scripts,
}) {
  final wanted = _nameTokens(requested);
  final lowered = requested.toLowerCase();
  final scored = <MapEntry<String, int>>[];
  for (final name in names) {
    var score = _nameTokens(name).where(wanted.contains).length;
    final ln = name.toLowerCase();
    if (ln.contains(lowered) || lowered.contains(ln)) {
      score += 2;
    }
    if (score > 0) {
      scored.add(MapEntry(name, score));
    }
  }
  scored.sort((a, b) => b.value.compareTo(a.value));
  final suggestions = scored.take(5).map((e) => e.key).toList();

  final buf = StringBuffer('Unknown tool: "$requested".');
  if (suggestions.isNotEmpty) {
    buf.write(' Did you mean: ${suggestions.join(', ')}?');
  }
  final has = names.toSet();
  final ways = [
    if (has.contains('search_tool_bm25'))
      'call `search_tool_bm25` to find a tool by intent',
    if (has.contains('list_my_tools'))
      'call `list_my_tools` to see every tool you can call right now',
    if (scripts) 'look it up from a `repl` script with `searchTools(query)`',
  ];
  if (ways.isNotEmpty) {
    final first = ways.first;
    buf.write(
      ' ${first[0].toUpperCase()}${first.substring(1)}'
      '${ways.skip(1).map((w) => ', or $w').join()}.',
    );
  }
  buf.write(
    ' Address tools by their bare name; your client may display them under '
    'a server prefix such as `mcp__control-center__`, and the server '
    'resolves either form.',
  );
  return buf.toString();
}

/// Name-noise tokens dropped before nearest-name matching (the server
/// namespace an over-eager client may bake into the name).
const _nameNoiseTokens = {'mcp', 'control', 'center', 'cc'};

List<String> _nameTokens(String name) {
  final cleaned = name.replaceAll(RegExp('[^A-Za-z0-9]+'), ' ').toLowerCase();
  return cleaned
      .split(' ')
      .where((t) => t.isNotEmpty && !_nameNoiseTokens.contains(t))
      .toList();
}
