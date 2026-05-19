import 'package:cc_persistence/search/rrf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reciprocalRankFusion', () {
    test('returns empty list for empty input', () async {
      expect(reciprocalRankFusion([]), isEmpty);
    });

    test('returns items from a single list in order', () async {
      final result = reciprocalRankFusion([
        ['a', 'b', 'c'],
      ]);
      expect(result, ['a', 'b', 'c']);
    });

    test('deduplicates items across lists', () async {
      final result = reciprocalRankFusion([
        ['a', 'b', 'c'],
        ['b', 'c', 'd'],
      ]);
      // 'b' and 'c' appear in both lists so they rank higher.
      expect(result.toSet(), {'a', 'b', 'c', 'd'});
      expect(result.length, 4);
      // 'b' appears at rank 1 in both lists → highest score.
      expect(result.first, 'b');
    });

    test('respects limit parameter', () async {
      final result = reciprocalRankFusion(
        [
          ['a', 'b', 'c', 'd', 'e'],
        ],
        limit: 3,
      );
      expect(result, ['a', 'b', 'c']);
    });

    test('limit of 0 returns empty list', () async {
      final result = reciprocalRankFusion(
        [
          ['a', 'b'],
        ],
        limit: 0,
      );
      expect(result, isEmpty);
    });

    test('limit larger than result set returns all items', () async {
      final result = reciprocalRankFusion(
        [
          ['a', 'b'],
        ],
        limit: 100,
      );
      expect(result, ['a', 'b']);
    });

    test('negative limit is ignored (returns all)', () async {
      final result = reciprocalRankFusion(
        [
          ['a', 'b'],
        ],
        limit: -1,
      );
      expect(result, ['a', 'b']);
    });

    test('custom k changes the fusion weighting', () async {
      // With a very small k, rank differences matter more.
      // Item at rank 0 in both lists should dominate.
      final smallK = reciprocalRankFusion(
        [
          ['x', 'a'],
          ['x', 'b'],
        ],
        k: 1,
      );
      expect(smallK.first, 'x');

      // With a very large k, all scores converge toward 2/k.
      // The ordering becomes less meaningful but still deterministic.
      final largeK = reciprocalRankFusion(
        [
          ['x', 'a'],
          ['x', 'b'],
        ],
        k: 1000000,
      );
      expect(largeK.toSet(), {'x', 'a', 'b'});
    });

    test('item appearing in more lists ranks higher', () async {
      final result = reciprocalRankFusion([
        ['a', 'b', 'c'],
        ['b', 'c', 'd'],
        ['c', 'd', 'e'],
      ]);
      // 'c' appears in all 3 lists → highest score.
      expect(result.first, 'c');
      // 'b' and 'd' appear in 2 lists → next tier.
      expect({result[1], result[2]}, {'b', 'd'});
    });

    test('empty inner lists do not affect result', () async {
      final result = reciprocalRankFusion([
        <String>[],
        ['a', 'b'],
        <String>[],
      ]);
      expect(result, ['a', 'b']);
    });

    test('works with integer items', () async {
      final result = reciprocalRankFusion<int>([
        [1, 2, 3],
        [2, 3, 4],
      ]);
      expect(result.toSet(), {1, 2, 3, 4});
      expect(result.first, 2); // appears at rank 0 in both
    });
  });
}
