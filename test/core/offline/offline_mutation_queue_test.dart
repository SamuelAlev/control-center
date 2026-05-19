import 'dart:async';

import 'package:control_center/core/offline/offline_mutation_queue.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemStore implements OfflineQueueStore {
  String? _v;
  @override
  String? load() => _v;
  @override
  Future<void> save(String? json) async => _v = json;
}

/// PRD 19 §11: bounded, honest, deterministic offline mutation queue.
void main() {
  var clock = 1000;
  int now() => clock++;

  OfflineMutationQueue queue(
    _MemStore store, {
    int maxEntries = 200,
    int maxBytes = 256 * 1024,
    int maxAttempts = 5,
    bool Function(Object)? isPermanentFailure,
    void Function(DeadLetteredMutation)? onDeadLetter,
  }) => OfflineMutationQueue(
    store: store,
    maxEntries: maxEntries,
    maxBytes: maxBytes,
    maxAttempts: maxAttempts,
    now: now,
    isPermanentFailure: isPermanentFailure,
    onDeadLetter: onDeadLetter,
  );

  setUp(() => clock = 1000);

  test('enqueue preserves the idempotency key and FIFO order', () {
    final q = queue(_MemStore());
    q.enqueue(idempotencyKey: 'k1', op: 'tickets.patch', args: {'id': 'a'});
    q.enqueue(idempotencyKey: 'k2', op: 'tickets.patch', args: {'id': 'b'});
    expect(q.entries.map((e) => e.idempotencyKey), ['k1', 'k2']);
    expect(q.length, 2);
  });

  test('refuses past the entry cap — never silently drops', () {
    final q = queue(_MemStore(), maxEntries: 2);
    q.enqueue(idempotencyKey: 'k1', op: 'o', args: const {});
    q.enqueue(idempotencyKey: 'k2', op: 'o', args: const {});
    expect(
      () => q.enqueue(idempotencyKey: 'k3', op: 'o', args: const {}),
      throwsA(isA<OfflineQueueFullException>()),
    );
    // The oldest is still there — nothing was dropped to make room.
    expect(q.entries.map((e) => e.idempotencyKey), ['k1', 'k2']);
  });

  test('refuses past the byte cap', () {
    final q = queue(_MemStore(), maxBytes: 120);
    q.enqueue(idempotencyKey: 'k1', op: 'o', args: {'x': 'small'});
    expect(
      () => q.enqueue(idempotencyKey: 'k2', op: 'o', args: {'x': 'a' * 500}),
      throwsA(isA<OfflineQueueFullException>()),
    );
  });

  test('flush applies FIFO and removes each on success', () async {
    final q = queue(_MemStore());
    q.enqueue(idempotencyKey: 'k1', op: 'o', args: const {});
    q.enqueue(idempotencyKey: 'k2', op: 'o', args: const {});
    final applied = <String>[];
    final count = await q.flush((m) async => applied.add(m.idempotencyKey));
    expect(count, 2);
    expect(applied, ['k1', 'k2']);
    expect(q.isNotEmpty, isFalse);
  });

  test('a mid-flush failure stops and preserves the tail in order', () async {
    final q = queue(_MemStore());
    q.enqueue(idempotencyKey: 'k1', op: 'o', args: const {});
    q.enqueue(idempotencyKey: 'k2', op: 'o', args: const {});
    q.enqueue(idempotencyKey: 'k3', op: 'o', args: const {});
    final applied = <String>[];
    final count = await q.flush((m) async {
      if (m.idempotencyKey == 'k2') {
        throw StateError('still offline');
      }
      applied.add(m.idempotencyKey);
    });
    expect(count, 1);
    expect(applied, ['k1']);
    // k2 (the failure) and k3 remain, in order, for the next flush.
    expect(q.entries.map((e) => e.idempotencyKey), ['k2', 'k3']);
  });

  test(
    'persists across instances (survives a reload) with the same keys',
    () async {
      final store = _MemStore();
      final original = queue(store)
        ..enqueue(idempotencyKey: 'k1', op: 'tickets.patch', args: {'t': 1});
      // `persisted` is what makes "queued" mean durable rather than scheduled.
      await original.persisted;
      // A fresh queue over the same store restores the pending mutation.
      final reloaded = queue(store);
      expect(reloaded.length, 1);
      expect(reloaded.entries.single.idempotencyKey, 'k1');
      expect(reloaded.entries.single.op, 'tickets.patch');
    },
  );

  test('a fully-flushed queue clears its persistence', () async {
    final store = _MemStore();
    final q = queue(store);
    q.enqueue(idempotencyKey: 'k1', op: 'o', args: const {});
    await q.flush((_) async {});
    await q.persisted;
    expect(store.load(), isNull);
  });

  test('concurrent flushes never drop an unsent mutation', () async {
    // Regression: two drains both took `_entries.first` and both removed by
    // INDEX, so the second removal deleted the entry after the one it sent.
    final q = queue(_MemStore());
    for (var i = 1; i <= 4; i++) {
      q.enqueue(idempotencyKey: 'k$i', op: 'o', args: const {});
    }
    final sent = <String>[];
    final gate = Completer<void>();
    Future<void> apply(QueuedMutation m) async {
      if (m.idempotencyKey == 'k1') {
        await gate.future; // Hold the first drain mid-apply.
      }
      sent.add(m.idempotencyKey);
    }

    final first = q.flush(apply);
    final second = q.flush(apply); // Fires while the first is parked.
    gate.complete();
    final counts = await Future.wait([first, second]);

    expect(sent, ['k1', 'k2', 'k3', 'k4']);
    expect(counts.reduce((a, b) => a + b), 4);
    expect(q.isNotEmpty, isFalse);
  });

  test(
    'a permanently-rejected entry is dead-lettered, not head-of-line',
    () async {
      final dropped = <DeadLetteredMutation>[];
      final q = queue(
        _MemStore(),
        isPermanentFailure: (e) => e is FormatException,
        onDeadLetter: dropped.add,
      );
      q.enqueue(idempotencyKey: 'k1', op: 'bad', args: const {});
      q.enqueue(idempotencyKey: 'k2', op: 'good', args: const {});
      final applied = <String>[];
      final count = await q.flush((m) async {
        if (m.op == 'bad') {
          throw const FormatException('unknown op');
        }
        applied.add(m.idempotencyKey);
      });

      expect(count, 1);
      expect(applied, ['k2'], reason: 'the tail must not be blocked');
      expect(q.isNotEmpty, isFalse);
      expect(dropped.single.mutation.idempotencyKey, 'k1');
      expect(dropped.single.permanent, isTrue);
      expect(q.deadLettered, hasLength(1));
    },
  );

  test(
    'a transient failure retries until the attempt ceiling, then drops',
    () async {
      final dropped = <DeadLetteredMutation>[];
      final q = queue(_MemStore(), maxAttempts: 3, onDeadLetter: dropped.add);
      q.enqueue(idempotencyKey: 'k1', op: 'o', args: const {});
      q.enqueue(idempotencyKey: 'k2', op: 'o', args: const {});

      Future<void> alwaysFailsFirst(QueuedMutation m) async {
        if (m.idempotencyKey == 'k1') {
          throw StateError('still offline');
        }
      }

      // Attempts 1 and 2 keep it (and block the tail, as designed for transients).
      await q.flush(alwaysFailsFirst);
      expect(q.length, 2);
      expect(q.entries.first.attempts, 1);
      await q.flush(alwaysFailsFirst);
      expect(q.entries.first.attempts, 2);
      // The third exhausts the budget: dropped, and the tail finally flushes.
      await q.flush(alwaysFailsFirst);
      expect(dropped.single.mutation.idempotencyKey, 'k1');
      expect(dropped.single.permanent, isFalse);
      expect(q.isNotEmpty, isFalse);
    },
  );

  test('attempt counts survive a reload', () async {
    final store = _MemStore();
    final q = queue(store);
    q.enqueue(idempotencyKey: 'k1', op: 'o', args: const {});
    await q.flush((_) async => throw StateError('offline'));
    await q.persisted;
    expect(queue(store).entries.single.attempts, 1);
  });
}
