import 'package:control_center/shared/widgets/command_fuzzy.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 19 §1: the ⌘K omnibox ranks from a warm in-memory index. These cover
/// the fuzzy scorer's correctness and the <50ms first-results budget.
void main() {
  group('fuzzyScore', () {
    test('subsequence matches, non-subsequence does not', () {
      expect(fuzzyScore('gpr', 'Go to pull requests'), isNotNull);
      expect(fuzzyScore('xyz', 'Go to pull requests'), isNull);
    });

    test('empty query matches everything with score 0', () {
      expect(fuzzyScore('', 'anything'), 0);
    });

    test('prefix / word-boundary hits outrank scattered hits', () {
      final prefix = fuzzyScore('pull', 'Pull requests')!;
      final scattered = fuzzyScore('pull', 'Popular useful links list')!;
      expect(prefix, greaterThan(scattered));
    });

    test('contiguous run outranks split match', () {
      final contiguous = fuzzyScore('merge', 'Merge pull request')!;
      final split = fuzzyScore('merge', 'Manage repository edge cases')!;
      expect(contiguous, greaterThan(split));
    });
  });

  group('rankCommands', () {
    String text(String s) => s;
    double never(String _) => double.infinity;

    test('filters out non-matches and orders best-first', () {
      final out = rankCommands<String>(
        'pr',
        ['Pull requests', 'Dashboard', 'Print report', 'Pipelines'],
        textOf: text,
        recencyOf: never,
      );
      expect(out, contains('Pull requests'));
      expect(out, contains('Print report'));
      expect(out, isNot(contains('Dashboard')));
      // "Pull requests" (p…r at word boundaries) beats "Print report".
      expect(out.first, 'Pull requests');
    });

    test('empty query orders by recency then original order', () {
      final recency = {'B': 0.0, 'A': 1.0};
      final out = rankCommands<String>(
        '',
        ['A', 'B', 'C'],
        textOf: text,
        recencyOf: (s) => recency[s] ?? double.infinity,
      );
      expect(out, ['B', 'A', 'C']);
    });

    test('recency breaks score ties on a query', () {
      // Two identical-scoring candidates; the more-recent one wins.
      final out = rankCommands<String>(
        'go',
        ['Go north', 'Go south'],
        textOf: text,
        recencyOf: (s) => s == 'Go south' ? 0.0 : double.infinity,
      );
      expect(out.first, 'Go south');
    });

    test('ranks a large command index within the 50ms budget', () {
      final commands = [
        for (var i = 0; i < 3000; i++) 'Command number $i action label',
      ];
      final sw = Stopwatch()..start();
      final out = rankCommands<String>(
        'cmd42',
        commands,
        textOf: text,
        recencyOf: never,
      );
      sw.stop();
      // Warm-index ranking must be well under a frame; 50ms is the ceiling.
      expect(sw.elapsedMilliseconds, lessThan(50));
      // Sanity: it still filters correctly.
      expect(out, isNotEmpty);
    });
  });
}
