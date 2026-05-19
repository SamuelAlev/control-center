import 'dart:async';

import 'package:cc_harness/cancellation.dart';
import 'package:test/test.dart';

/// Covers CancellationTokenSource cancel/notify/isCancelled semantics, the
/// CancellationToken.none sentinel, the CancellationToken.any combinator, and
/// the CancelledException type.
void main() {
  group('CancellationTokenSource cancel/notify', () {
    test('a fresh source is not cancelled', () {
      final source = CancellationTokenSource();
      expect(source.isCancelled, isFalse);
      expect(source.token.isCancelled, isFalse);
      expect(source.token.reason, isNull);
    });

    test('cancel marks the token cancelled and records the reason', () {
      final source = CancellationTokenSource();
      source.cancel('aborted');
      expect(source.isCancelled, isTrue);
      expect(source.token.isCancelled, isTrue);
      expect(source.token.reason, 'aborted');
    });

    test('cancel without a reason leaves reason null', () {
      final source = CancellationTokenSource();
      source.cancel();
      expect(source.token.isCancelled, isTrue);
      expect(source.token.reason, isNull);
    });

    test('cancel is idempotent and keeps the first reason', () {
      final source = CancellationTokenSource();
      source.cancel('first');
      source.cancel('second');
      expect(
        source.token.reason,
        'first',
        reason: 'a second cancel is a no-op',
      );
    });

    test('whenCancelled completes once the token is cancelled', () async {
      final source = CancellationTokenSource();
      var fired = false;
      // ignore: unawaited_futures
      source.token.whenCancelled.then((_) => fired = true);
      await Future<void>.delayed(Duration.zero);
      expect(fired, isFalse, reason: 'not yet cancelled');

      source.cancel();
      await source.token.whenCancelled;
      expect(fired, isTrue);
    });

    test('whenCancelled is already complete for a pre-cancelled token', () {
      final source = CancellationTokenSource();
      source.cancel('done');
      // Already complete — this returns a synchronous Future.value().
      expect(source.token.whenCancelled, completes);
    });

    test('multiple whenCancelled listeners all fire on cancel', () async {
      final source = CancellationTokenSource();
      var count = 0;
      for (var i = 0; i < 3; i++) {
        // ignore: unawaited_futures
        source.token.whenCancelled.then((_) => count++);
      }
      source.cancel();
      await source.token.whenCancelled;
      expect(count, 3);
    });

    test('throwIfCancelled throws when cancelled and is a no-op otherwise', () {
      final active = CancellationTokenSource();
      active.token.throwIfCancelled(); // does not throw

      final cancelled = CancellationTokenSource();
      cancelled.cancel('because');
      expect(
        () => cancelled.token.throwIfCancelled(),
        throwsA(
          isA<CancelledException>().having(
            (e) => e.reason,
            'reason',
            'because',
          ),
        ),
      );
    });
  });

  group('CancellationToken.none', () {
    test('is never cancelled and never reports a reason', () {
      const token = CancellationToken.none;
      expect(token.isCancelled, isFalse);
      expect(token.reason, isNull);
      token.throwIfCancelled(); // a no-op even on the sentinel
    });

    test('whenCancelled never completes', () async {
      const token = CancellationToken.none;
      var fired = false;
      // ignore: unawaited_futures
      token.whenCancelled.then((_) => fired = true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(fired, isFalse);
    });

    test('whenComplete on the never-future still never resolves it', () async {
      const token = CancellationToken.none;
      var sideEffect = false;
      // ignore: unawaited_futures
      token.whenCancelled.whenComplete(() => sideEffect = true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(sideEffect, isFalse);
    });
  });

  group('CancellationToken.any', () {
    test('is born cancelled when any source is already cancelled', () {
      final a = CancellationTokenSource();
      final b = CancellationTokenSource();
      b.cancel('boom');

      final combined = CancellationToken.any([a.token, b.token]);
      expect(combined.isCancelled, isTrue);
      expect(combined.reason, 'boom');
    });

    test('cancels when the first source cancels', () async {
      final a = CancellationTokenSource();
      final b = CancellationTokenSource();
      final combined = CancellationToken.any([a.token, b.token]);
      expect(combined.isCancelled, isFalse);

      a.cancel('first');
      // The propagation is scheduled on the microtask queue.
      await Future<void>.delayed(Duration.zero);
      expect(combined.isCancelled, isTrue);
      expect(combined.reason, 'first');
    });

    test('adopts the reason of whichever source cancels first, once', () async {
      final a = CancellationTokenSource();
      final b = CancellationTokenSource();
      final combined = CancellationToken.any([a.token, b.token]);

      a.cancel('a-reason');
      b.cancel('b-reason');
      await Future<void>.delayed(Duration.zero);

      expect(
        combined.reason,
        'a-reason',
        reason: 'first-to-fire reason wins; cancel is idempotent',
      );
    });

    test('an empty input yields a token that is not yet cancelled', () {
      final combined = CancellationToken.any(const <CancellationToken>[]);
      expect(combined.isCancelled, isFalse);
    });

    test('cancels when the only member cancels late', () async {
      final a = CancellationTokenSource();
      final combined = CancellationToken.any([a.token]);
      a.cancel('late');
      await Future<void>.delayed(Duration.zero);
      expect(combined.isCancelled, isTrue);
    });
  });

  group('CancelledException', () {
    test('a reasonless exception has a plain toString', () {
      const exception = CancelledException();
      expect(exception.reason, isNull);
      expect(exception.toString(), 'CancelledException');
    });

    test('a reason is included in toString', () {
      const exception = CancelledException('because');
      expect(exception.reason, 'because');
      expect(exception.toString(), 'CancelledException: because');
    });
  });
}
