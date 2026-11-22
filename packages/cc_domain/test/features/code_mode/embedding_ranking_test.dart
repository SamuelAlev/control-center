import 'package:cc_domain/features/code_mode/domain/services/embedding_ranking.dart';
import 'package:test/test.dart';

void main() {
  group('cosine', () {
    test('identical, orthogonal and opposite vectors', () {
      expect(EmbeddingRanking.cosine([1, 0], [2, 0]), closeTo(1, 1e-12));
      expect(EmbeddingRanking.cosine([1, 0], [0, 3]), closeTo(0, 1e-12));
      expect(EmbeddingRanking.cosine([1, 1], [-1, -1]), closeTo(-1, 1e-12));
    });

    test('a zero vector scores zero and lengths must match', () {
      expect(EmbeddingRanking.cosine([0, 0], [1, 2]), 0);
      expect(
        () => EmbeddingRanking.cosine([1, 2], [1, 2, 3]),
        throwsArgumentError,
      );
    });
  });

  group('rank', () {
    test('best first, ties in input order, limited by top', () {
      final hits = EmbeddingRanking.rank(
        [1, 0],
        [
          [0, 1],
          [1, 0],
          [1, 1],
          [2, 0],
        ],
      );
      expect(hits.map((h) => h.index), [1, 3, 2, 0]);
      expect(hits.first.score, closeTo(1, 1e-12));
      expect(
        EmbeddingRanking.rank(
          [1, 0],
          [
            [0, 1],
            [1, 0],
          ],
          top: 1,
        ).single.index,
        1,
      );
      expect(EmbeddingRanking.rank([1, 0], const [], top: 3), isEmpty);
      expect(
        () => EmbeddingRanking.rank([1], const [], top: -1),
        throwsArgumentError,
      );
    });

    test('serialises for the script', () {
      final hit = EmbeddingRanking.rank(
        [1, 0],
        [
          [1, 1],
        ],
      ).single;
      expect(hit.toJson(), {'index': 0, 'score': 0.707107});
    });
  });

  group('classify', () {
    test('picks the nearest label, ties to the earlier one', () {
      final out = EmbeddingRanking.classify(
        [
          [1, 0.1],
          [0.1, 1],
          [1, 1],
        ],
        [
          [1, 0],
          [0, 1],
        ],
      );
      expect(out.map((c) => c.label), [0, 1, 0]);
      expect(out.last.toJson()['label'], 0);
    });

    test('needs labels when there is text', () {
      expect(
        () => EmbeddingRanking.classify([
          [1.0],
        ], const []),
        throwsArgumentError,
      );
      expect(EmbeddingRanking.classify(const [], const []), isEmpty);
    });
  });
}
