import 'package:control_center/features/pipelines/domain/services/state_reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StateReducer', () {
    const reducer = StateReducer();

    test('names contains all known reducers', timeout: const Timeout.factor(2), () {
      expect(StateReducer.names, [
        'override',
        'append',
        'mergeLists',
        'mergeMaps',
        'sum',
      ]);
    });

    test('isKnown returns true for valid names', timeout: const Timeout.factor(2), () {
      for (final name in StateReducer.names) {
        expect(reducer.isKnown(name), isTrue, reason: name);
      }
    });

    test('isKnown returns true for null and empty', timeout: const Timeout.factor(2), () {
      expect(reducer.isKnown(null), isTrue);
      expect(reducer.isKnown(''), isTrue);
    });

    test('isKnown returns false for unknown names', timeout: const Timeout.factor(2), () {
      expect(reducer.isKnown('bogus'), isFalse);
      expect(reducer.isKnown('Append'), isFalse); // case sensitive
    });

    test('first write returns incoming regardless of reducer', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('override', null, 5), 5);
      expect(reducer.apply('mergeLists', null, [1]), [1]);
      expect(reducer.apply('mergeMaps', null, {'a': 1}), {'a': 1});
      expect(reducer.apply('sum', null, 10), 10);
    });

    test('first write with append wraps scalar into list', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('append', null, 'x'), ['x']);
      expect(reducer.apply('append', null, 42), [42]);
    });

    test('first write with append passes list through', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('append', null, [1, 2]), [1, 2]);
    });

    test('append accumulates scalar to existing list', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('append', ['a'], 'b');
      expect(result, ['a', 'b']);
    });

    test('append accumulates list to existing list', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('append', ['a'], ['b', 'c']);
      expect(result, ['a', 'b', 'c']);
    });

    test('append wraps existing scalar then appends', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('append', 'x', 'y');
      expect(result, ['x', 'y']);
    });

    test('mergeLists creates flat list from two lists', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('mergeLists', [1, 2], [3, 4]), [1, 2, 3, 4]);
    });

    test('mergeLists wraps scalars', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('mergeLists', 1, 2), [1, 2]);
      expect(reducer.apply('mergeLists', [1], 2), [1, 2]);
      expect(reducer.apply('mergeLists', 1, [2]), [1, 2]);
    });

    test('mergeMaps merges two maps', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('mergeMaps', {'a': 1}, {'b': 2});
      expect(result, {'a': 1, 'b': 2});
    });

    test('mergeMaps overwrites existing keys', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('mergeMaps', {'a': 1}, {'a': 2, 'b': 3});
      expect(result, {'a': 2, 'b': 3});
    });

    test('sum adds two numbers', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('sum', 2, 3), 5);
      expect(reducer.apply('sum', 1.5, 2.5), 4.0);
    });

    test('sum falls back to incoming when not both num', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('sum', 'x', 'y'), 'y');
    });

    test('override replaces existing with incoming', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('override', 'old', 'new'), 'new');
      expect(reducer.apply('override', [1, 2], [3]), [3]);
    });

    test('null reducer behaves as override', timeout: const Timeout.factor(2), () {
      expect(reducer.apply(null, 'old', 'new'), 'new');
    });

    test('empty string reducer behaves as override', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('', 'old', 'new'), 'new');
    });

    test('unknown reducer falls back to override', timeout: const Timeout.factor(2), () {
      // This shouldn't happen if validation works, but verify the default behavior
      expect(reducer.apply('unknown', 'old', 'new'), 'new');
    });
  });

  group('StateReducer — edge cases', () {
    const reducer = StateReducer();

    test('mergeMaps with non-map existing keeps only incoming map', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('mergeMaps', 'not_a_map', {'b': 2});
      expect(result, {'b': 2});
    });

    test('mergeMaps with non-map incoming keeps only existing map', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('mergeMaps', {'a': 1}, 'not_a_map');
      expect(result, {'a': 1});
    });

    test('mergeMaps with both non-map returns empty map', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('mergeMaps', 1, 2);
      expect(result, isEmpty);
    });

    test('mergeMaps with null values in maps merges correctly', timeout: const Timeout.factor(2), () {
      final result = reducer.apply('mergeMaps', {'a': null}, {'b': null});
      expect(result, {'a': null, 'b': null});
    });

    test('mergeLists with empty source lists', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('mergeLists', [], []), isEmpty);
      expect(reducer.apply('mergeLists', [], [1, 2]), [1, 2]);
      expect(reducer.apply('mergeLists', [1, 2], []), [1, 2]);
    });

    test('sum with negative numbers', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('sum', -5, 3), -2);
      expect(reducer.apply('sum', 2, -7), -5);
      expect(reducer.apply('sum', -1, -2), -3);
    });

    test('sum with int and double', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('sum', 3, 2.5), 5.5);
      expect(reducer.apply('sum', 1.5, 2), 3.5);
    });

    test('sum falls back to incoming when existing is not num', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('sum', 'not_num', 5), 5);
    });

    test('append with null values', timeout: const Timeout.factor(2), () {
      expect(reducer.apply('append', ['a'], null), ['a', null]);
      // null existing is a first-write scenario — append wraps scalar in a list.
      expect(reducer.apply('append', null, 'b'), ['b']);
    });
  });
}
