/// Reciprocal-rank fusion helper for hybrid search.
///
/// Merges multiple ranked result lists into a single ordering using the
/// classic Cormack/Clarke/Buettcher 2009 formula:
///
///     score(item) = Σᵢ 1 / (k + rankᵢ(item))
///
/// The stub here was rebuilt from scratch after the original
/// implementation was lost; behavior is correct but un-tuned. Callers
/// can pass any object type — equality is used to merge across lists.
List<T> reciprocalRankFusion<T>(
  List<List<T>> rankedLists, {
  int k = 60,
  int? limit,
}) {
  if (rankedLists.isEmpty) {
    return const [];
  }
  final scores = <T, double>{};
  for (final ranks in rankedLists) {
    for (var i = 0; i < ranks.length; i++) {
      final item = ranks[i];
      scores[item] = (scores[item] ?? 0) + 1.0 / (k + i + 1);
    }
  }
  final ordered = scores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final out = ordered.map((e) => e.key).toList();
  if (limit != null && limit >= 0 && out.length > limit) {
    return out.sublist(0, limit);
  }
  return out;
}
