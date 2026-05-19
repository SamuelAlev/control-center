/// One grep hit: the file, its 1-indexed line number (null for
/// files-with-matches output, which carries no line), and the matched line's
/// text (empty for files-with-matches output).
class GrepMatch {
  /// Creates a [GrepMatch].
  const GrepMatch({
    required this.path,
    required this.line,
    required this.content,
  });

  /// File path as the tool printed it (usually workspace-relative).
  final String path;

  /// 1-indexed line number, or null when the output names only the file.
  final int? line;

  /// The matched line's text (already trimmed by most tools).
  final String content;
}

/// Parsed grep/search tool output: the hits in emission order plus an optional
/// trailing note (e.g. the harness's "(N total matches; showing first M)").
class GrepResult {
  /// Creates a [GrepResult].
  const GrepResult({required this.matches, this.note});

  /// The hits, in the order the tool printed them.
  final List<GrepMatch> matches;

  /// A trailing summary line from the tool, if any.
  final String? note;

  /// Distinct file count across [matches], preserving nothing about order.
  int get fileCount => matches.map((m) => m.path).toSet().length;

  /// Ordered (first-seen) file groups for rendering.
  List<({String path, List<GrepMatch> matches})> get groups {
    final order = <String>[];
    final byPath = <String, List<GrepMatch>>{};
    for (final m in matches) {
      final bucket = byPath[m.path];
      if (bucket == null) {
        order.add(m.path);
        byPath[m.path] = [m];
      } else {
        bucket.add(m);
      }
    }
    return [for (final path in order) (path: path, matches: byPath[path]!)];
  }
}

/// Matches `path:line: content` (harness `search`, Claude Grep content mode).
/// The path group is non-greedy so the FIRST `:<digits>:` split wins, keeping
/// Windows drive letters (`C:\foo\bar.dart:12: x`) intact.
final _matchLine = RegExp(r'^(.*?):(\d+):[ \t]?(.*)$');

/// Parses grep-family tool output ([raw]) into a [GrepResult].
///
/// Three shapes are recognized:
/// - content mode: `path:line: text` lines (harness `search` adds a space
///   after the second colon, Claude's Grep does not),
/// - files-with-matches mode: bare path lines,
/// - a trailing parenthesized note, kept separately as [GrepResult.note].
///
/// "No matches" answers and empty output yield an empty result (the widget
/// renders its own empty state).
GrepResult parseGrepOutput(String raw) {
  // The harness's no-hit answer must not parse as one bare-path "match".
  if (raw.trim().toLowerCase().startsWith('no matches')) {
    return const GrepResult(matches: []);
  }
  final matches = <GrepMatch>[];
  String? note;
  for (final line in raw.split('\n')) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) {
      continue;
    }
    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      note = trimmed;
      continue;
    }
    final m = _matchLine.firstMatch(trimmed);
    if (m != null && m.group(1)!.isNotEmpty) {
      matches.add(
        GrepMatch(
          path: m.group(1)!,
          line: int.parse(m.group(2)!),
          content: m.group(3)!,
        ),
      );
      continue;
    }
    // files_with_matches mode: a bare path line.
    matches.add(GrepMatch(path: trimmed, line: null, content: ''));
  }
  return GrepResult(matches: matches, note: note);
}
