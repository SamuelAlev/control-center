import 'package:cc_domain/core/utils/cancellation_token.dart';
import 'package:cc_domain/features/dispatch/domain/concurrency/semaphore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Semaphore', () {
    test('admits up to max immediately then queues the overflow', () async {
      final sem = Semaphore(2);

      // First two acquires resolve right away.
      await sem.acquire();
      await sem.acquire();
      expect(sem.current, 2);

      // Third acquire must queue (stay pending) until a slot frees.
      var thirdResolved = false;
      final third = sem.acquire().then((_) => thirdResolved = true);
      await pumpEventLoop();
      expect(thirdResolved, isFalse);

      sem.release();
      await third;
      expect(thirdResolved, isTrue);
      expect(sem.current, 2);
    });

    test('release admits the next waiter in FIFO order', () async {
      final sem = Semaphore(1);
      await sem.acquire();

      final order = <int>[];
      final first = sem.acquire().then((_) => order.add(1));
      final second = sem.acquire().then((_) => order.add(2));
      final third = sem.acquire().then((_) => order.add(3));

      await pumpEventLoop();
      expect(order, isEmpty);

      sem.release();
      await first;
      sem.release();
      await second;
      sem.release();
      await third;

      expect(order, <int>[1, 2, 3]);
    });

    test('is unbounded when max <= 0', () async {
      final sem = Semaphore(0);
      expect(sem.isUnbounded, isTrue);
      expect(sem.max, isNull);

      // Many acquires all resolve without any release.
      for (var i = 0; i < 100; i++) {
        await sem.acquire();
      }
      expect(sem.current, 100);
    });

    test('is unbounded for negative max', () async {
      final sem = Semaphore(-5);
      expect(sem.isUnbounded, isTrue);
      var resolved = false;
      await sem.acquire().then((_) => resolved = true);
      expect(resolved, isTrue);
    });

    test('resize up admits queued waiters that now fit', () async {
      final sem = Semaphore(1);
      await sem.acquire();

      var secondResolved = false;
      var thirdResolved = false;
      final second = sem.acquire().then((_) => secondResolved = true);
      final third = sem.acquire().then((_) => thirdResolved = true);

      await pumpEventLoop();
      expect(secondResolved, isFalse);
      expect(thirdResolved, isFalse);

      // Raise ceiling to 3: both queued waiters now fit alongside the holder.
      sem.resize(3);
      await Future.wait(<Future<void>>[second, third]);
      expect(secondResolved, isTrue);
      expect(thirdResolved, isTrue);
      expect(sem.current, 3);
    });

    test('resize down lets in-flight holders drain', () async {
      final sem = Semaphore(3);
      await sem.acquire();
      await sem.acquire();
      await sem.acquire();
      expect(sem.current, 3);

      // Lower ceiling to 1 while 3 are in flight.
      sem.resize(1);
      expect(sem.max, 1);
      expect(sem.current, 3);

      // A new acquire keeps blocking until current falls below the new max.
      var resolved = false;
      final pending = sem.acquire().then((_) => resolved = true);
      await pumpEventLoop();
      expect(resolved, isFalse);

      // Drain: 3 -> 2 -> 1, still at/above ceiling, so no admission yet.
      sem.release();
      await pumpEventLoop();
      expect(resolved, isFalse);
      sem.release();
      await pumpEventLoop();
      expect(resolved, isFalse);

      // 1 -> 0 frees a slot below the ceiling: the waiter is admitted.
      sem.release();
      await pending;
      expect(resolved, isTrue);
    });

    test('acquire on an already-cancelled token throws', () async {
      final sem = Semaphore(1);
      final source = CancellationTokenSource()..cancel('nope');

      await expectLater(
        sem.acquire(source.token),
        throwsA(isA<CancelledException>()),
      );

      // No slot was taken by the rejected acquire.
      expect(sem.current, 0);
    });

    test(
      'a queued waiter cancelled is removed and does not shrink capacity',
      () async {
        final sem = Semaphore(1);
        await sem.acquire();

        // Queue a waiter, then cancel its token while it is still waiting.
        final source = CancellationTokenSource();
        final cancelled = sem.acquire(source.token);
        await pumpEventLoop();

        source.cancel('abandon');
        await expectLater(cancelled, throwsA(isA<CancelledException>()));

        // The original holder releases. Because the abandoned waiter was
        // pulled from the queue, this release frees a real slot rather than
        // resolving a dead waiter, so capacity is intact.
        sem.release();
        await pumpEventLoop();

        // A fresh acquire still succeeds — concurrency was not permanently
        // shrunk by the cancelled waiter.
        var freshResolved = false;
        await sem.acquire().then((_) => freshResolved = true);
        expect(freshResolved, isTrue);
        expect(sem.current, 1);
      },
    );
  });
}

/// Lets queued microtasks/timers run so pending futures settle.
Future<void> pumpEventLoop() => Future<void>.delayed(Duration.zero);
