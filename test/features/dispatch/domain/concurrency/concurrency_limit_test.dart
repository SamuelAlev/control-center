import 'dart:async';

import 'package:cc_domain/core/utils/cancellation_token.dart';
import 'package:cc_domain/features/dispatch/domain/concurrency/concurrency_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapWithConcurrencyLimit', () {
    test('preserves input order in results', () async {
      final items = List<int>.generate(20, (i) => i);

      final result = await mapWithConcurrencyLimit<int, String>(
        items,
        4,
        (item, index, signal) async {
          // Reverse the delay so later items would finish first if order were
          // completion-based; results must still be in input order.
          await Future<void>.delayed(Duration(milliseconds: 20 - item));
          return 'v$item';
        },
      );

      expect(result.aborted, isFalse);
      expect(
        result.results,
        <String>[for (final i in items) 'v$i'],
      );
    });

    test('peak concurrency never exceeds the limit', () async {
      const limit = 3;
      final items = List<int>.generate(30, (i) => i);
      var active = 0;
      var peak = 0;

      final result = await mapWithConcurrencyLimit<int, int>(
        items,
        limit,
        (item, index, signal) async {
          active++;
          if (active > peak) {
            peak = active;
          }
          await Future<void>.delayed(const Duration(milliseconds: 1));
          active--;
          return item * 2;
        },
      );

      expect(result.aborted, isFalse);
      expect(peak, lessThanOrEqualTo(limit));
      expect(peak, greaterThan(1));
      expect(result.results, <int>[for (final i in items) i * 2]);
    });

    test('clamps concurrency to items.length when limit is huge', () async {
      final items = <int>[1, 2, 3];
      var active = 0;
      var peak = 0;

      await mapWithConcurrencyLimit<int, int>(
        items,
        1000,
        (item, index, signal) async {
          active++;
          if (active > peak) {
            peak = active;
          }
          await Future<void>.delayed(const Duration(milliseconds: 1));
          active--;
          return item;
        },
      );

      expect(peak, lessThanOrEqualTo(items.length));
    });

    test('treats concurrency <= 0 as items.length', () async {
      final items = <int>[10, 20, 30, 40];
      final result = await mapWithConcurrencyLimit<int, int>(
        items,
        0,
        (item, index, signal) async => item + index,
      );
      expect(result.results, <int>[10, 21, 32, 43]);
    });

    test('fails fast and rethrows the first error', () async {
      final items = List<int>.generate(10, (i) => i);
      var startedAfterFailure = 0;
      var failed = false;

      Future<int> body(int item, int index, CancellationToken signal) async {
        if (failed) {
          // Count work scheduled after the failure to confirm we stop early.
          startedAfterFailure++;
        }
        if (item == 2) {
          failed = true;
          throw StateError('boom on $item');
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return item;
      }

      await expectLater(
        mapWithConcurrencyLimit<int, int>(items, 2, body),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'boom on 2',
          ),
        ),
      );

      // With a limit of 2 and 10 items, fail-fast must not run all 10.
      expect(startedAfterFailure, lessThan(items.length));
    });

    test('external-signal abort returns aborted:true with partial results',
        () async {
      final items = List<int>.generate(8, (i) => i);
      final source = CancellationTokenSource();
      var completed = 0;

      final future = mapWithConcurrencyLimit<int, int>(
        items,
        2,
        (item, index, signal) async {
          // Cancel externally partway through.
          if (item == 1) {
            source.cancel('stop');
          }
          // Cooperatively honor the combined signal.
          if (signal.isCancelled) {
            throw CancelledException(signal.reason);
          }
          await Future<void>.delayed(const Duration(milliseconds: 2));
          if (signal.isCancelled) {
            throw CancelledException(signal.reason);
          }
          completed++;
          return item;
        },
        signal: source.token,
      );

      final result = await future;

      expect(result.aborted, isTrue);
      // Partial: not every item completed; skipped entries remain null.
      expect(completed, lessThan(items.length));
      expect(result.results.where((e) => e == null), isNotEmpty);
    });

    test('handles an empty input list', () async {
      final result = await mapWithConcurrencyLimit<int, int>(
        <int>[],
        4,
        (item, index, signal) async => item,
      );
      expect(result.results, isEmpty);
      expect(result.aborted, isFalse);
    });

    test('passes a combined signal that fires on sibling failure', () async {
      final items = <int>[0, 1];
      var siblingSawCancellation = false;

      Future<int> body(int item, int index, CancellationToken signal) async {
        if (item == 0) {
          throw StateError('first fails');
        }
        // The surviving sibling should observe the internal cancellation.
        await signal.whenCancelled.timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );
        siblingSawCancellation = signal.isCancelled;
        return item;
      }

      await expectLater(
        mapWithConcurrencyLimit<int, int>(items, 2, body),
        throwsA(isA<StateError>()),
      );
      expect(siblingSawCancellation, isTrue);
    });
  });
}
