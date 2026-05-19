/// Maximal-Marginal-Relevance reranking + token-Jaccard text similarity, ported
/// from oh-my-pi mnemopi `core/mmr.ts`. Suppresses near-duplicate recall so the
/// top-K is topically diverse rather than five paraphrases of one fact.
library;

/// Token-set Jaccard similarity of [a] and [b] in `[0,1]` (lowercased,
/// whitespace-split). Returns 0 when either side is empty.
double jaccardSimilarity(String a, String b) {
  final wordsA = a.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
  final wordsB = b.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
  if (wordsA.isEmpty || wordsB.isEmpty) {
    return 0;
  }
  var intersection = 0;
  for (final w in wordsA) {
    if (wordsB.contains(w)) {
      intersection++;
    }
  }
  return intersection / (wordsA.length + wordsB.length - intersection);
}

/// An item carrying a relevance [score] and the [content] used for diversity.
class MmrItem<T> {
  /// Creates an [MmrItem].
  const MmrItem({required this.value, required this.score, required this.content});

  /// The wrapped value, returned in the reranked order.
  final T value;

  /// Relevance score (higher = more relevant).
  final double score;

  /// Text used to measure similarity against already-selected items.
  final String content;
}

/// MMR rerank: greedily pick the item maximizing
/// `lambda*relevance - (1-lambda)*maxSimilarityToSelected`, ported from
/// mnemopi `mmrRerank`. [lambda] trades relevance (1.0) for diversity (0.0).
List<T> mmrRerank<T>(
  List<MmrItem<T>> items, {
  double lambda = 0.7,
  int topK = 10,
}) {
  final limit = topK < 0 ? 0 : topK;
  if (limit == 0) {
    return <T>[];
  }
  if (items.length <= 1) {
    return items.take(limit).map((i) => i.value).toList();
  }
  final sorted = [...items]..sort((l, r) => r.score.compareTo(l.score));
  final selected = <MmrItem<T>>[sorted.first];
  final remaining = sorted.sublist(1);

  while (remaining.isNotEmpty && selected.length < limit) {
    var bestIdx = 0;
    var bestScore = double.negativeInfinity;
    for (var i = 0; i < remaining.length; i++) {
      final candidate = remaining[i];
      var maxSim = 0.0;
      for (final s in selected) {
        final sim = jaccardSimilarity(candidate.content, s.content);
        if (sim > maxSim) {
          maxSim = sim;
        }
      }
      final mmr = lambda * candidate.score - (1.0 - lambda) * maxSim;
      if (mmr > bestScore) {
        bestScore = mmr;
        bestIdx = i;
      }
    }
    selected.add(remaining.removeAt(bestIdx));
  }
  if (selected.length < limit) {
    selected.addAll(remaining.take(limit - selected.length));
  }
  return selected.map((i) => i.value).toList();
}