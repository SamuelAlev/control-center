/// Collapses chronological user-text rows into the composer's recall list.
///
/// Empty rows are skipped and do not break a run. Compacted rows are not
/// recallable, but they do break a run: adjacency is measured against what
/// was actually sent, so a folded row between two identical prompts keeps
/// both (a shell's ignoredups). Consecutive duplicates collapse.
List<String> collapsePromptHistory(
  Iterable<({String content, bool compacted})> chronological,
) {
  final history = <String>[];
  String? previousRaw;
  for (final row in chronological) {
    final content = row.content.trim();
    if (content.isEmpty) {
      continue;
    }
    final duplicate = content == previousRaw;
    previousRaw = content;
    if (row.compacted || duplicate) {
      continue;
    }
    history.add(content);
  }
  return history;
}
