import 'dart:math' as math;

/// One ranked candidate: its position in the input and its similarity.
class EmbeddingRankHit {
  /// Creates a hit.
  const EmbeddingRankHit({required this.index, required this.score});

  /// Position of the candidate in the list that was ranked.
  final int index;

  /// Cosine similarity to the query, in [-1, 1].
  final double score;

  /// The wire form for the script: `{ index, score }`.
  Map<String, Object?> toJson() => {'index': index, 'score': _round(score)};

  @override
  bool operator ==(Object other) =>
      other is EmbeddingRankHit && other.index == index && other.score == score;

  @override
  int get hashCode => Object.hash(index, score);

  @override
  String toString() => 'EmbeddingRankHit($index, $score)';
}

/// The nearest label for one text.
class EmbeddingClassification {
  /// Creates a classification.
  const EmbeddingClassification({required this.label, required this.score});

  /// Position of the nearest label in the label list.
  final int label;

  /// Cosine similarity between the text and that label.
  final double score;

  /// The wire form for the script: `{ label, score }`.
  Map<String, Object?> toJson() => {'label': label, 'score': _round(score)};

  @override
  bool operator ==(Object other) =>
      other is EmbeddingClassification &&
      other.label == label &&
      other.score == score;

  @override
  int get hashCode => Object.hash(label, score);
}

/// The vector arithmetic behind a script's `models.rank` and
/// `models.classify`, over vectors the on-device embedder produced.
///
/// Pure and deterministic: ties keep input order, so the same vectors always
/// rank the same way.
// ignore: avoid_classes_with_only_static_members
abstract final class EmbeddingRanking {
  /// Cosine similarity of [a] and [b]. Zero when either is a zero vector.
  /// Throws [ArgumentError] when their lengths differ.
  static double cosine(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError.value(
        b.length,
        'b',
        'must have the same length as a (${a.length})',
      );
    }
    var dot = 0.0;
    var na = 0.0;
    var nb = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) {
      return 0;
    }
    return (dot / (math.sqrt(na) * math.sqrt(nb))).clamp(-1.0, 1.0);
  }

  /// [candidates] ranked by similarity to [query], best first, ties in input
  /// order. [top] limits the result; null or anything past the list length
  /// returns every candidate. Throws [ArgumentError] when [top] is negative
  /// or a vector's length differs from the query's.
  static List<EmbeddingRankHit> rank(
    List<double> query,
    List<List<double>> candidates, {
    int? top,
  }) {
    if (top != null && top < 0) {
      throw ArgumentError.value(top, 'top', 'must not be negative');
    }
    final hits = [
      for (var i = 0; i < candidates.length; i++)
        EmbeddingRankHit(index: i, score: cosine(query, candidates[i])),
    ];
    hits.sort((x, y) {
      final byScore = y.score.compareTo(x.score);
      return byScore != 0 ? byScore : x.index.compareTo(y.index);
    });
    return top == null || top >= hits.length ? hits : hits.sublist(0, top);
  }

  /// For every text vector, the nearest of [labels] by cosine similarity;
  /// ties go to the earlier label. Throws [ArgumentError] when [labels] is
  /// empty and there is anything to classify.
  static List<EmbeddingClassification> classify(
    List<List<double>> texts,
    List<List<double>> labels,
  ) {
    if (labels.isEmpty && texts.isNotEmpty) {
      throw ArgumentError.value(labels, 'labels', 'must not be empty');
    }
    final out = <EmbeddingClassification>[];
    for (final text in texts) {
      var best = 0;
      var bestScore = cosine(text, labels[0]);
      for (var j = 1; j < labels.length; j++) {
        final score = cosine(text, labels[j]);
        if (score > bestScore) {
          best = j;
          bestScore = score;
        }
      }
      out.add(EmbeddingClassification(label: best, score: bestScore));
    }
    return out;
  }
}

double _round(double value) => double.parse(value.toStringAsFixed(6));
