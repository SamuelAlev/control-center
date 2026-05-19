import 'package:cc_domain/features/dispatch/domain/isolation/path_lock_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PathLockManager', () {
    test('acquires a free path immediately', () async {
      final m = PathLockManager();
      final handle = await m.acquire('/repo', 'task1');
      expect(handle.taskId, 'task1');
      expect(m.isHeld('/repo'), isTrue);
      expect(m.holderOf('/repo'), 'task1');
    });

    test('parks a contended path and reports the holder via onWait', () async {
      final m = PathLockManager();
      final first = await m.acquire('/repo', 'task1');

      String? observedHolder;
      var secondAcquired = false;
      final pending = m
          .acquire(
            '/repo',
            'task2',
            onWait: (holder) => observedHolder = holder,
          )
          .then((h) {
            secondAcquired = true;
            return h;
          });

      // task2 is parked behind task1.
      await Future<void>.delayed(Duration.zero);
      expect(observedHolder, 'task1');
      expect(secondAcquired, isFalse);
      expect(m.holderOf('/repo'), 'task1');

      // Releasing task1 hands the path to task2.
      first.release();
      final second = await pending;
      expect(secondAcquired, isTrue);
      expect(second.taskId, 'task2');
      expect(m.holderOf('/repo'), 'task2');
    });

    test('frees the path entirely when no waiters remain', () async {
      final m = PathLockManager();
      final handle = await m.acquire('/repo', 'task1');
      handle.release();
      expect(m.isHeld('/repo'), isFalse);
      expect(m.holderOf('/repo'), isNull);
    });

    test('hands waiters the path in FIFO order', () async {
      final m = PathLockManager();
      final first = await m.acquire('/repo', 'task1');
      final order = <String>[];
      final w2 = m.acquire('/repo', 'task2').then((h) {
        order.add('task2');
        return h;
      });
      final w3 = m.acquire('/repo', 'task3').then((h) {
        order.add('task3');
        return h;
      });

      first.release();
      final h2 = await w2;
      h2.release();
      await w3;
      expect(order, ['task2', 'task3']);
    });

    test('different paths never block each other', () async {
      final m = PathLockManager();
      await m.acquire('/a', 'task1');
      final b = await m.acquire('/b', 'task2');
      expect(b.taskId, 'task2');
      expect(m.holderOf('/a'), 'task1');
      expect(m.holderOf('/b'), 'task2');
    });
  });
}
