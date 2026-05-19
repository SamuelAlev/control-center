import 'package:cc_domain/core/utils/cancellation_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CancellationTokenSource', () {
    test('token starts uncancelled', () {
      final source = CancellationTokenSource();
      expect(source.token.isCancelled, isFalse);
      expect(source.isCancelled, isFalse);
      expect(source.token.reason, isNull);
      expect(source.token.throwIfCancelled, returnsNormally);
    });

    test('cancel flips the token and carries the reason', () {
      final source = CancellationTokenSource();
      source.cancel('stopped');
      expect(source.token.isCancelled, isTrue);
      expect(source.token.reason, 'stopped');
      expect(source.token.throwIfCancelled, throwsA(isA<CancelledException>()));
    });

    test('cancel is idempotent and keeps the first reason', () {
      final source = CancellationTokenSource();
      source.cancel('first');
      source.cancel('second');
      expect(source.token.reason, 'first');
    });

    test('whenCancelled completes on cancel', () async {
      final source = CancellationTokenSource();
      var fired = false;
      // ignore: unawaited_futures
      source.token.whenCancelled.then((_) => fired = true);
      expect(fired, isFalse);
      source.cancel();
      await pumpEventQueue();
      expect(fired, isTrue);
    });

    test('whenCancelled is already complete when already cancelled', () async {
      final source = CancellationTokenSource();
      source.cancel();
      await source.token.whenCancelled; // must not hang
      expect(source.token.isCancelled, isTrue);
    });
  });

  group('CancellationToken.none', () {
    test('is never cancelled', () {
      expect(CancellationToken.none.isCancelled, isFalse);
      expect(CancellationToken.none.throwIfCancelled, returnsNormally);
    });
  });

  group('CancellationToken.any', () {
    test('is cancelled when any source cancels', () async {
      final a = CancellationTokenSource();
      final b = CancellationTokenSource();
      final combined = CancellationToken.any([a.token, b.token]);
      expect(combined.isCancelled, isFalse);
      b.cancel('b-reason');
      await pumpEventQueue();
      expect(combined.isCancelled, isTrue);
      expect(combined.reason, 'b-reason');
    });

    test('is born cancelled when a source is already cancelled', () {
      final a = CancellationTokenSource()..cancel('already');
      final b = CancellationTokenSource();
      final combined = CancellationToken.any([a.token, b.token]);
      expect(combined.isCancelled, isTrue);
      expect(combined.reason, 'already');
    });
  });
}
