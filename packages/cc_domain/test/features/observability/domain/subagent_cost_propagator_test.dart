import 'dart:async';

import 'package:cc_domain/features/observability/domain/subagent_cost_propagator.dart';
import 'package:test/test.dart';

/// A trivial in-memory child-cost store keyed by parent run id, with a
/// deliberate async gap between read and write so an unserialized
/// read-modify-write would interleave and lose updates.
class _InMemoryStore {
  final Map<String, int> _values = <String, int>{};

  int get(String key) => _values[key] ?? 0;

  Future<int> read(String key) async {
    // Yield so a concurrent caller can read the same base value before this one
    // writes — this is the window a lost-update bug would exploit.
    await Future<void>.delayed(Duration.zero);
    return _values[key] ?? 0;
  }

  Future<void> write(String key, int value) async {
    await Future<void>.delayed(Duration.zero);
    _values[key] = value;
  }
}

void main() {
  late _InMemoryStore store;
  late SubagentCostPropagator propagator;

  setUp(() {
    store = _InMemoryStore();
    propagator = SubagentCostPropagator(
      readChildCostCents: store.read,
      writeChildCostCents: store.write,
    );
  });

  test('serializes N concurrent propagations to the same parent (no lost '
      'updates)', () async {
    const deltas = [1, 2, 4, 8, 16, 32, 64, 128];
    expect(deltas.reduce((a, b) => a + b), 255);

    // Fire all eight concurrently against the same key. Without the per-key
    // lock the async read/write gap would let several reads see the same base
    // and clobber each other; the exact sum proves every delta landed.
    await Future.wait(deltas.map((d) => propagator.propagate('parent', d)));

    expect(store.get('parent'), 255);
  });

  test('repeated concurrent propagations stay exact under load', () async {
    // 50 calls of +1 against one key, all in flight at once.
    await Future.wait(
      List.generate(50, (_) => propagator.propagate('parent', 1)),
    );
    expect(store.get('parent'), 50);
  });

  test('zero amount is a no-op', () async {
    await propagator.propagate('parent', 5);
    await propagator.propagate('parent', 0);
    expect(store.get('parent'), 5);
  });

  test('negative amount is a no-op', () async {
    await propagator.propagate('parent', 5);
    await propagator.propagate('parent', -100);
    expect(store.get('parent'), 5);
  });

  test('a no-op never touches the store', () async {
    var reads = 0;
    var writes = 0;
    final counting = SubagentCostPropagator(
      readChildCostCents: (_) async {
        reads++;
        return 0;
      },
      writeChildCostCents: (_, _) async {
        writes++;
      },
    );
    await counting.propagate('parent', 0);
    await counting.propagate('parent', -7);
    expect(reads, 0);
    expect(writes, 0);
  });

  test('different parent keys do not block each other', () async {
    // Key 'a' read/write is gated on a completer that we hold open; key 'b'
    // must still complete while 'a' is blocked, proving keys run concurrently.
    final gate = Completer<void>();
    final gated = SubagentCostPropagator(
      readChildCostCents: (key) async {
        if (key == 'a') {
          await gate.future;
        }
        return store.get(key);
      },
      writeChildCostCents: store.write,
    );

    final aFuture = gated.propagate('a', 10);
    final bFuture = gated.propagate('b', 20);

    // 'b' completes even though 'a' is still parked on the gate.
    await bFuture;
    expect(store.get('b'), 20);
    expect(store.get('a'), 0);

    // Release 'a' and confirm it finishes too.
    gate.complete();
    await aFuture;
    expect(store.get('a'), 10);
  });

  test(
    'a failing link rejects its own future but does not wedge the chain',
    () async {
      var call = 0;
      final flaky = SubagentCostPropagator(
        readChildCostCents: (key) async {
          call++;
          // The second enqueued call's read throws; the others succeed.
          if (call == 2) {
            throw StateError('boom');
          }
          return store.get(key);
        },
        writeChildCostCents: store.write,
      );

      final first = flaky.propagate('parent', 1);
      final second = flaky.propagate('parent', 2);
      final third = flaky.propagate('parent', 4);

      // Attach all expectations before awaiting so the rejected [second] future's
      // error is observed by its matcher and never surfaces as an unhandled async
      // error in the test zone.
      final firstExpect = expectLater(first, completes);
      final secondExpect = expectLater(second, throwsA(isA<StateError>()));
      final thirdExpect = expectLater(third, completes);
      await Future.wait([firstExpect, secondExpect, thirdExpect]);

      // First (+1) and third (+4) landed; the failed second (+2) did not.
      expect(store.get('parent'), 5);
    },
  );

  test('sequential propagations accumulate correctly', () async {
    await propagator.propagate('parent', 3);
    await propagator.propagate('parent', 7);
    await propagator.propagate('parent', 90);
    expect(store.get('parent'), 100);
  });

  test('lock entry is cleaned up after the chain drains', () async {
    await propagator.propagate('parent', 1);
    // Allow the whenComplete cleanup microtask to run.
    await Future<void>.delayed(Duration.zero);

    // A fresh propagation after the chain drained still works — proving the
    // cleaned-up entry was re-created, not left dangling and the new chain
    // starts from the persisted value.
    await propagator.propagate('parent', 9);
    expect(store.get('parent'), 10);
  });
}
