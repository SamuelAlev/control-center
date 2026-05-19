import 'package:control_center/core/offline/offline_mutation_queue.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemStore implements OfflineQueueStore {
  String? _v;
  @override
  String? load() => _v;
  @override
  void save(String? json) => _v = json;
}

/// PRD 19 §11: bounded, honest, deterministic offline mutation queue.
void main() {
  var clock = 1000;
  int now() => clock++;

  OfflineMutationQueue queue(
    _MemStore store, {
    int maxEntries = 200,
    int maxBytes = 256 * 1024,
  }) => OfflineMutationQueue(
    store: store,
    maxEntries: maxEntries,
    maxBytes: maxBytes,
    now: now,
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

  test('persists across instances (survives a reload) with the same keys', () {
    final store = _MemStore();
    queue(
      store,
    ).enqueue(idempotencyKey: 'k1', op: 'tickets.patch', args: {'t': 1});
    // A fresh queue over the same store restores the pending mutation.
    final reloaded = queue(store);
    expect(reloaded.length, 1);
    expect(reloaded.entries.single.idempotencyKey, 'k1');
    expect(reloaded.entries.single.op, 'tickets.patch');
  });

  test('a fully-flushed queue clears its persistence', () async {
    final store = _MemStore();
    final q = queue(store);
    q.enqueue(idempotencyKey: 'k1', op: 'o', args: const {});
    await q.flush((_) async {});
    expect(store.load(), isNull);
  });
}
