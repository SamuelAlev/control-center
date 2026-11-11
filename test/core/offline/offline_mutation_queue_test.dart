import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/core/offline/offline_mutation_queue.dart';
import 'package:control_center/core/offline/offline_queue_provider.dart';
import 'package:control_center/core/providers/session_scope_provider.dart';
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
  final alice = SessionScope(serverId: 'srv-a', userId: 'alice');

  OfflineMutationQueue queue(
    _MemStore store, {
    SessionScope? scope,
    bool unscoped = false,
    int maxEntries = 200,
    int maxBytes = 256 * 1024,
    int maxAttempts = 5,
    bool Function(Object)? isPermanentFailure,
    String? Function(Object)? signInLaneOf,
    void Function(DeadLetteredMutation)? onDeadLetter,
  }) => OfflineMutationQueue(
    store: store,
    scope: unscoped ? null : scope ?? alice,
    maxEntries: maxEntries,
    maxBytes: maxBytes,
    maxAttempts: maxAttempts,
    now: now,
    isPermanentFailure: isPermanentFailure,
    signInLaneOf: signInLaneOf,
    onDeadLetter: onDeadLetter,
  );

  setUp(() => clock = 1000);

  test('enqueue preserves the idempotency key and FIFO order', () {
    final q = queue(_MemStore());
    q.enqueue(
      workspaceId: 'ws',
      idempotencyKey: 'k1',
      op: 'tickets.patch',
      args: {'id': 'a'},
    );
    q.enqueue(
      workspaceId: 'ws',
      idempotencyKey: 'k2',
      op: 'tickets.patch',
      args: {'id': 'b'},
    );
    expect(q.entries.map((e) => e.idempotencyKey), ['k1', 'k2']);
    expect(q.length, 2);
  });

  test('refuses past the entry cap — never silently drops', () {
    final q = queue(_MemStore(), maxEntries: 2);
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k1', op: 'o', args: const {});
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k2', op: 'o', args: const {});
    expect(
      () => q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k3',
        op: 'o',
        args: const {},
      ),
      throwsA(isA<OfflineQueueFullException>()),
    );
    // The oldest is still there — nothing was dropped to make room.
    expect(q.entries.map((e) => e.idempotencyKey), ['k1', 'k2']);
  });

  test('refuses past the byte cap', () {
    final q = queue(_MemStore(), maxBytes: 120);
    q.enqueue(
      workspaceId: 'ws',
      idempotencyKey: 'k1',
      op: 'o',
      args: {'x': 'small'},
    );
    expect(
      () => q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k2',
        op: 'o',
        args: {'x': 'a' * 500},
      ),
      throwsA(isA<OfflineQueueFullException>()),
    );
  });

  test('flush applies FIFO and removes each on success', () async {
    final q = queue(_MemStore());
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k1', op: 'o', args: const {});
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k2', op: 'o', args: const {});
    final applied = <String>[];
    final count = await q.flush((m) async => applied.add(m.idempotencyKey));
    expect(count, 2);
    expect(applied, ['k1', 'k2']);
    expect(q.isNotEmpty, isFalse);
  });

  test('a mid-flush failure stops and preserves the tail in order', () async {
    final q = queue(_MemStore());
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k1', op: 'o', args: const {});
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k2', op: 'o', args: const {});
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k3', op: 'o', args: const {});
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
        ..enqueue(
          workspaceId: 'ws',
          idempotencyKey: 'k1',
          op: 'tickets.patch',
          args: {'t': 1},
        );
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
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k1', op: 'o', args: const {});
    await q.flush((_) async {});
    await q.persisted;
    expect(store.load(), isNull);
  });

  test('concurrent flushes never drop an unsent mutation', () async {
    // Regression: two drains both took `_entries.first` and both removed by
    // INDEX, so the second removal deleted the entry after the one it sent.
    final q = queue(_MemStore());
    for (var i = 1; i <= 4; i++) {
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k$i',
        op: 'o',
        args: const {},
      );
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
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k1',
        op: 'bad',
        args: const {},
      );
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k2',
        op: 'good',
        args: const {},
      );
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
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k1',
        op: 'o',
        args: const {},
      );
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k2',
        op: 'o',
        args: const {},
      );

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
    q.enqueue(workspaceId: 'ws', idempotencyKey: 'k1', op: 'o', args: const {});
    await q.flush((_) async => throw StateError('offline'));
    await q.persisted;
    expect(queue(store).entries.single.attempts, 1);
  });

  group('needs_sign_in', () {
    RemoteRpcException needsSignIn(String lane) => RemoteRpcException(
      RpcErrorCodes.unauthorized,
      'Sign in to continue',
      {'kind': 'needs_sign_in', 'lane': lane},
    );

    OfflineMutationQueue signInQueue(
      _MemStore store, {
      void Function(DeadLetteredMutation)? onDeadLetter,
    }) => queue(
      store,
      maxAttempts: 2,
      isPermanentFailure: isPermanentFlushFailure,
      signInLaneOf: signInLaneOfFlushFailure,
      onDeadLetter: onDeadLetter,
    );

    test('a mutation refused for a missing sign-in is parked, not '
        'dead-lettered, and the rest still flush', () async {
      final dropped = <DeadLetteredMutation>[];
      final q = signInQueue(_MemStore(), onDeadLetter: dropped.add);
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k1',
        op: 'pr_review.merge',
        args: const {},
      );
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k2',
        op: 'tickets.patch',
        args: const {},
      );

      final sent = <String>[];
      final applied = await q.flush((m) async {
        sent.add(m.idempotencyKey);
        if (m.idempotencyKey == 'k1') {
          throw needsSignIn('github');
        }
      });

      expect(applied, 1);
      expect(sent, ['k1', 'k2']);
      expect(dropped, isEmpty);
      expect(q.entries.single.idempotencyKey, 'k1');
      expect(q.awaitingSignIn.single.awaitingSignIn, 'github');
      expect(q.entries.single.attempts, 0, reason: 'no attempt spent');
      expect(q.hasRunnable, isFalse);

      // Later flushes leave it alone, however many there are.
      sent.clear();
      for (var i = 0; i < 5; i++) {
        await q.flush((m) async => sent.add(m.idempotencyKey));
      }
      expect(sent, isEmpty);
      expect(q.length, 1);
    });

    test('the matching sign-in releases it, another lane does not', () async {
      final q = signInQueue(_MemStore());
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k1',
        op: 'pr_review.merge',
        args: const {},
      );
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k2',
        op: 'linear.comment',
        args: const {},
      );
      await q.flush(
        (m) async =>
            throw needsSignIn(m.idempotencyKey == 'k1' ? 'github' : 'linear'),
      );
      expect(q.awaitingSignIn.map((m) => m.awaitingSignIn), [
        'github',
        'linear',
      ]);

      expect(q.resumeAfterSignIn('gitlab'), 0);
      expect(q.resumeAfterSignIn('github'), 1);
      final sent = <String>[];
      await q.flush((m) async => sent.add(m.idempotencyKey));
      expect(sent, ['k1']);
      expect(q.entries.single.idempotencyKey, 'k2');
      expect(q.entries.single.awaitingSignIn, 'linear');
    });

    test('a parked mutation survives a reload', () async {
      final store = _MemStore();
      final q = signInQueue(store);
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k1',
        op: 'o',
        args: const {},
      );
      await q.flush((_) async => throw needsSignIn('bitbucket'));
      await q.persisted;
      expect(
        signInQueue(store).awaitingSignIn.single.awaitingSignIn,
        'bitbucket',
      );
    });

    test('any other unauthorized refusal is still dead-lettered', () async {
      final dropped = <DeadLetteredMutation>[];
      final q = signInQueue(_MemStore(), onDeadLetter: dropped.add);
      q.enqueue(
        workspaceId: 'ws',
        idempotencyKey: 'k1',
        op: 'o',
        args: const {},
      );
      await q.flush(
        (_) async => throw RemoteRpcException(
          RpcErrorCodes.unauthorized,
          'Not a member of this workspace',
        ),
      );
      expect(q.length, 0);
      expect(dropped.single.permanent, isTrue);
      expect(
        signInLaneOfFlushFailure(
          RemoteRpcException(RpcErrorCodes.unauthorized, 'x', {
            'kind': 'something_else',
          }),
        ),
        isNull,
      );
    });
  });
  group('bound to the session that queued it', () {
    const day = 24 * 60 * 60 * 1000;

    test('each entry is stamped with server, user, workspace and time', () {
      final q = queue(_MemStore());
      final m = q.enqueue(
        workspaceId: 'ws-1',
        idempotencyKey: 'k1',
        op: 'tickets.patch',
        args: {'workspace_id': 'ws-1'},
      );
      expect(m.serverId, 'srv-a');
      expect(m.userId, 'alice');
      expect(m.workspaceId, 'ws-1');
      expect(m.enqueuedAtEpochMs, 1000);
      final json = m.toJson();
      expect(
        [json['srv'], json['usr'], json['ws']],
        ['srv-a', 'alice', 'ws-1'],
      );
    });

    test('refuses a mutation it cannot bind', () {
      expect(
        () => queue(_MemStore(), unscoped: true).enqueue(
          workspaceId: 'ws',
          idempotencyKey: 'k1',
          op: 'o',
          args: const {},
        ),
        throwsA(isA<OfflineQueueUnboundException>()),
      );
      expect(
        () => queue(_MemStore()).enqueue(
          workspaceId: 'ws-1',
          idempotencyKey: 'k1',
          op: 'o',
          args: {'workspace_id': 'ws-2'},
        ),
        throwsA(isA<OfflineQueueUnboundException>()),
      );
    });

    test('another user or server never restores, and the drop is '
        'persisted', () async {
      final dropped = <DeadLetteredMutation>[];
      for (final other in [
        SessionScope(serverId: 'srv-a', userId: 'bob'),
        SessionScope(serverId: 'srv-b', userId: 'alice'),
      ]) {
        final store = _MemStore();
        await (queue(store)..enqueue(
              workspaceId: 'ws',
              idempotencyKey: 'k1',
              op: 'o',
              args: {},
            ))
            .persisted;

        final q = queue(store, scope: other, onDeadLetter: dropped.add);
        expect(q.length, 0);
        expect(await q.flush((_) async => fail('nothing may replay')), 0);
        await q.persisted;
        expect(store.load(), isNull, reason: 'dropped, not kept for later');
      }
      // Another person's change is never reported to this one.
      expect(dropped, isEmpty);
    });

    test('a session with no scope loads nothing and leaves the store '
        'alone', () async {
      final store = _MemStore();
      await (queue(store)..enqueue(
            workspaceId: 'ws',
            idempotencyKey: 'k1',
            op: 'o',
            args: {},
          ))
          .persisted;
      final before = store.load();
      final q = queue(store, unscoped: true);
      expect(q.length, 0);
      expect(await q.flush((_) async => fail('nothing may replay')), 0);
      expect(store.load(), before);
    });

    test('an unbound entry from an older build is dropped', () async {
      final store = _MemStore()
        .._v =
            '[{"k":"k1","op":"o","args":{},"at":1000},'
            '{"k":"k2","op":"o","args":{},"at":1000,'
            '"srv":"srv-a","usr":"alice","ws":"ws"}]';
      final q = queue(store);
      expect(q.entries.map((e) => e.idempotencyKey), ['k2']);
      await q.persisted;
      expect(store.load(), isNot(contains('"k1"')));
    });

    test('an expired mutation is dropped and reported, at restore and at '
        'flush', () async {
      final store = _MemStore();
      final dropped = <DeadLetteredMutation>[];
      final q = queue(store, onDeadLetter: dropped.add)
        ..enqueue(workspaceId: 'ws', idempotencyKey: 'k1', op: 'o', args: {});
      await q.persisted;

      // Still in the queue a day later; the flush drops it unsent.
      clock += day + 1;
      expect(await q.flush((_) async => fail('expired must not replay')), 0);
      expect(q.length, 0);
      expect(dropped.single.permanent, isTrue);
      expect(dropped.single.error, isA<QueuedMutationDiscarded>());

      // Restored after a day: dropped on load.
      final store2 = _MemStore();
      clock = 1000;
      await (queue(store2)..enqueue(
            workspaceId: 'ws',
            idempotencyKey: 'k2',
            op: 'o',
            args: {},
          ))
          .persisted;
      clock += day + 1;
      final restoredDrops = <DeadLetteredMutation>[];
      final reloaded = queue(store2, onDeadLetter: restoredDrops.add);
      expect(reloaded.length, 0);
      expect(restoredDrops.single.mutation.idempotencyKey, 'k2');
    });

    test('resumeAfterSignIn never releases an expired mutation', () async {
      final q = queue(
        _MemStore(),
        isPermanentFailure: isPermanentFlushFailure,
        signInLaneOf: signInLaneOfFlushFailure,
      )..enqueue(workspaceId: 'ws', idempotencyKey: 'k1', op: 'o', args: {});
      await q.flush(
        (_) async => throw RemoteRpcException(
          RpcErrorCodes.unauthorized,
          'sign in',
          {'kind': 'needs_sign_in', 'lane': 'github'},
        ),
      );
      expect(q.awaitingSignIn, hasLength(1));
      clock += day + 1;
      expect(q.resumeAfterSignIn('github'), 0);
      expect(q.length, 0);
    });

    test('clear drops everything unsent (sign-out, server switch)', () async {
      final store = _MemStore();
      final q = queue(store)
        ..enqueue(workspaceId: 'ws', idempotencyKey: 'k1', op: 'o', args: {});
      q.clear();
      await q.persisted;
      expect(store.load(), isNull);
      expect(await q.flush((_) async => fail('nothing may replay')), 0);
    });
  });
}
