import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// [DaoPeerAskRepository] against in-memory databases: round trips, the
/// pending reads and counts, the repeat lookup, settling exactly once,
/// retention, the stored-value checks and workspace isolation.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoPeerAskRepository repo;
  late List<String> warnings;
  final t0 = DateTime.utc(2026, 5, 1, 12);
  // Holds no limit: seeding writes past the caps and the repeat check.
  final open = PeerAskInsertLimits(
    duplicateSince: DateTime.utc(9999),
    perAsker: 1 << 20,
    perRecipient: 1 << 20,
  );

  setUp(() async {
    global = createTestGlobalDatabase();
    warnings = [];
    dbs = createTestWorkspaceDatabases(
      global: global,
      onWarn: (_, message) => warnings.add(message),
    );
    repo = DaoPeerAskRepository(dbs, clock: () => t0);
    for (final ws in ['w-1', 'w-2']) {
      await seedTestWorkspace(global, dbs, ws);
      final db = dbs.of(ws);
      await seedParents(
        db,
        agents: ['agent-1', 'agent-2', 'agent-3'],
        spaces: ['sp-1'],
      );
      await seedConversation(db, 'conv-1', spaceId: 'sp-1');
      await seedConversation(db, 'conv-2', spaceId: 'sp-1');
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  PeerAsk ask(
    String id, {
    String workspaceId = 'w-1',
    String asker = 'agent-1',
    String recipient = 'agent-2',
    String conversationId = 'conv-1',
    String questionHash = 'h-1',
    PeerAskStatus status = PeerAskStatus.pending,
    String? dispatchedRunId,
    String? recipientConversationId,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    final created = createdAt ?? t0;
    return PeerAsk(
      id: id,
      workspaceId: workspaceId,
      askerAgentId: asker,
      askerConversationId: conversationId,
      askerSpaceId: 'sp-1',
      recipientAgentId: recipient,
      questionHash: questionHash,
      dispatchedRunId: dispatchedRunId,
      recipientConversationId: recipientConversationId,
      status: status,
      createdAt: created,
      expiresAt: expiresAt ?? created.add(const Duration(hours: 1)),
    );
  }

  Future<void> put(PeerAsk a) async =>
      expect(await repo.insertWithinLimits(a, limits: open), isNull);

  test('times come back as UTC whole seconds', () async {
    final at = DateTime.utc(2026, 5, 1, 12, 0, 7, 123, 456);
    final a = ask(
      'a',
      createdAt: at,
      expiresAt: at.add(const Duration(hours: 1)),
    ).copyWith(promisedAt: at, blockedNoticedAt: at);
    await put(a);
    final read = (await repo.getById('w-1', 'a'))!;
    final whole = DateTime.utc(2026, 5, 1, 12, 0, 7);
    for (final t in [
      read.createdAt,
      read.promisedAt!,
      read.blockedNoticedAt!,
    ]) {
      expect(t.isUtc, isTrue);
      expect(t, whole);
    }
    expect(read.expiresAt.isUtc, isTrue);
    expect(read.expiresAt, whole.add(const Duration(hours: 1)));
    expect(
      await repo.settle(
        'w-1',
        id: 'a',
        status: PeerAskStatus.answered,
        now: at,
      ),
      isTrue,
    );
    final settled = (await repo.getById('w-1', 'a'))!;
    expect(settled.settledAt!.isUtc, isTrue);
    expect(settled.settledAt, whole);
  });

  group('insertWithinLimits (one transaction with the insert)', () {
    PeerAskInsertLimits caps({int perAsker = 10, int perRecipient = 20}) =>
        PeerAskInsertLimits(
          duplicateSince: t0.subtract(const Duration(minutes: 10)),
          perAsker: perAsker,
          perRecipient: perRecipient,
        );

    test('twelve asks in parallel: the asker cap holds at ten', () async {
      final hits = await Future.wait([
        for (var i = 0; i < 12; i++)
          repo.insertWithinLimits(
            ask('a$i', questionHash: 'h$i'),
            limits: caps(),
          ),
      ]);
      expect(hits.where((h) => h == null), hasLength(10));
      expect(
        hits.whereType<PeerAskLimitHit>().map((h) => h.limit),
        everyElement(PeerAskLimit.asker),
      );
      expect(await repo.countPending('w-1', askerAgentId: 'agent-1'), 10);
    });

    test('the recipient cap holds across askers in parallel', () async {
      final hits = await Future.wait([
        for (var i = 0; i < 6; i++)
          repo.insertWithinLimits(
            ask(
              'r$i',
              asker: i.isEven ? 'agent-1' : 'agent-3',
              questionHash: 'h$i',
            ),
            limits: caps(perRecipient: 4),
          ),
      ]);
      expect(hits.where((h) => h == null), hasLength(4));
      expect(
        hits.whereType<PeerAskLimitHit>().map((h) => h.limit),
        everyElement(PeerAskLimit.recipient),
      );
    });

    test(
      'the same question twice in parallel: one ask, one duplicate',
      () async {
        final hits = await Future.wait([
          repo.insertWithinLimits(ask('d1'), limits: caps()),
          repo.insertWithinLimits(ask('d2'), limits: caps()),
        ]);
        expect(hits.where((h) => h == null), hasLength(1));
        final hit = hits.whereType<PeerAskLimitHit>().single;
        expect(hit.limit, PeerAskLimit.duplicate);
        final written = hits.first == null ? 'd1' : 'd2';
        expect(hit.duplicateAskId, written);
        expect(await repo.countPending('w-1'), 1);
      },
    );

    test('a settled ask is no duplicate and holds no cap', () async {
      await put(ask('s1'));
      await repo.settle(
        'w-1',
        id: 's1',
        status: PeerAskStatus.answered,
        now: t0,
      );
      expect(
        await repo.insertWithinLimits(ask('s2'), limits: caps(perAsker: 1)),
        isNull,
      );
    });
  });

  test('every field round-trips', () async {
    final full = PeerAsk(
      id: 'a-1',
      workspaceId: 'w-1',
      kind: PeerAskKind.review,
      mode: PeerAskMode.background,
      askerAgentId: 'agent-1',
      askerRunId: 'run-1',
      askerConversationId: 'conv-1',
      askerSpaceId: 'sp-1',
      recipientAgentId: 'agent-2',
      recipientConversationId: 'conv-2',
      recipientSpaceId: 'sp-1',
      questionMessageId: 'm-1',
      questionHash: 'h',
      dispatchedRunId: 'run-2',
      chain: const ['agent-3', 'agent-1'],
      requestedByUserId: 'user-1',
      createdAt: t0,
      expiresAt: t0.add(const Duration(hours: 1)),
      promisedAt: t0.add(const Duration(minutes: 1)),
      blockedNoticedAt: t0.add(const Duration(minutes: 2)),
      stallNoticedRunId: 'run-2',
    );
    await put(full);
    expect(await repo.getById('w-1', 'a-1'), full);
    expect(await repo.getByDispatchedRun('w-1', 'run-2'), full);
    await expectLater(put(full), throwsA(anything));
  });

  group('setDispatched', () {
    test('records where a pending ask is answered', () async {
      await put(ask('a'));
      expect(
        await repo.setDispatched(
          'w-1',
          id: 'a',
          dispatchedRunId: 'run-7',
          recipientConversationId: 'conv-2',
          recipientSpaceId: 'sp-1',
          questionMessageId: 'm-1',
        ),
        isTrue,
      );
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.dispatchedRunId, 'run-7');
      expect(a.recipientConversationId, 'conv-2');
      expect(a.recipientSpaceId, 'sp-1');
      expect(a.questionMessageId, 'm-1');
      // Null leaves a field as it is.
      expect(
        await repo.setDispatched('w-1', id: 'a', dispatchedRunId: 'run-8'),
        isTrue,
      );
      final again = (await repo.getById('w-1', 'a'))!;
      expect(again.dispatchedRunId, 'run-8');
      expect(again.recipientConversationId, 'conv-2');
      expect(
        () => repo.setDispatched('w-1', id: 'a', dispatchedRunId: ''),
        throwsArgumentError,
      );
    });

    test('never re-opens an ask that settled meanwhile', () async {
      await put(ask('a'));
      // The sweeper settles it between the service's read and its write.
      expect(
        await repo.settle(
          'w-1',
          id: 'a',
          status: PeerAskStatus.expired,
          now: t0,
        ),
        isTrue,
      );
      expect(
        await repo.setDispatched('w-1', id: 'a', dispatchedRunId: 'run-7'),
        isFalse,
      );
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.status, PeerAskStatus.expired);
      expect(a.settledAt, t0);
      expect(a.dispatchedRunId, isNull);
      expect(
        await repo.setDispatched('w-1', id: 'none', dispatchedRunId: 'r'),
        isFalse,
      );
    });
  });

  test('pending reads and counts narrow by every filter', () async {
    await put(ask('a', createdAt: t0));
    await put(
      ask(
        'b',
        recipient: 'agent-3',
        createdAt: t0.add(const Duration(minutes: 1)),
      ),
    );
    await put(
      ask(
        'c',
        asker: 'agent-3',
        recipient: 'agent-2',
        conversationId: 'conv-2',
      ),
    );
    await put(ask('done', status: PeerAskStatus.answered));
    expect((await repo.listPending('w-1')).map((a) => a.id).toSet(), {
      'a',
      'b',
      'c',
    });
    expect(
      (await repo.listPending('w-1', askerAgentId: 'agent-1')).map((a) => a.id),
      ['a', 'b'],
    );
    expect(
      (await repo.listPending(
        'w-1',
        recipientAgentId: 'agent-2',
      )).map((a) => a.id).toSet(),
      {'a', 'c'},
    );
    expect(
      (await repo.listPending(
        'w-1',
        askerConversationId: 'conv-2',
      )).map((a) => a.id),
      ['c'],
    );
    expect(await repo.countPending('w-1'), 3);
    expect(await repo.countPending('w-1', recipientAgentId: 'agent-2'), 2);
    expect(await repo.countPending('w-1', askerAgentId: 'agent-1'), 2);
  });

  test('findPendingDuplicate finds a recent repeat only', () async {
    await put(ask('old', createdAt: t0));
    await put(ask('new', createdAt: t0.add(const Duration(minutes: 8))));
    final hit = await repo.findPendingDuplicate(
      'w-1',
      askerAgentId: 'agent-1',
      recipientAgentId: 'agent-2',
      questionHash: 'h-1',
      since: t0.add(const Duration(minutes: 5)),
    );
    expect(hit?.id, 'new');
    expect(
      await repo.findPendingDuplicate(
        'w-1',
        askerAgentId: 'agent-1',
        recipientAgentId: 'agent-2',
        questionHash: 'other',
        since: t0,
      ),
      isNull,
    );
    expect(
      await repo.findPendingDuplicate(
        'w-1',
        askerAgentId: 'agent-1',
        recipientAgentId: 'agent-2',
        questionHash: 'h-1',
        since: t0.add(const Duration(minutes: 9)),
      ),
      isNull,
    );
  });

  group('settle', () {
    test('only the first settle moves the ask', () async {
      await put(ask('a'));
      final settled = t0.add(const Duration(minutes: 2));
      final results = await Future.wait([
        repo.settle(
          'w-1',
          id: 'a',
          status: PeerAskStatus.answered,
          replyMessageId: 'm-1',
          replyInline: true,
          now: settled,
        ),
        repo.settle(
          'w-1',
          id: 'a',
          status: PeerAskStatus.failed,
          error: 'late',
          now: settled,
        ),
      ]);
      expect(results.where((r) => r), hasLength(1));
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.isPending, isFalse);
      expect(a.settledAt, settled);
      expect(
        await repo.settle(
          'w-1',
          id: 'a',
          status: PeerAskStatus.cancelled,
          now: settled,
        ),
        isFalse,
      );
    });

    test('writes the reply fields', () async {
      await put(ask('a'));
      await repo.settle(
        'w-1',
        id: 'a',
        status: PeerAskStatus.answered,
        replyMessageId: 'm-9',
        replyInline: true,
        now: t0,
      );
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.status, PeerAskStatus.answered);
      expect(a.replyMessageId, 'm-9');
      expect(a.replyInline, isTrue);
    });

    test('refuses pending and an over-long error', () {
      expect(
        () =>
            repo.settle('w-1', id: 'a', status: PeerAskStatus.pending, now: t0),
        throwsArgumentError,
      );
      expect(
        () => repo.settle(
          'w-1',
          id: 'a',
          status: PeerAskStatus.failed,
          error: 'x' * 2001,
          now: t0,
        ),
        throwsArgumentError,
      );
    });
  });

  test('expiry and retention', () async {
    await put(ask('due', expiresAt: t0.add(const Duration(minutes: 1))));
    await put(ask('later', expiresAt: t0.add(const Duration(hours: 2))));
    await put(ask('done', status: PeerAskStatus.answered));
    expect(
      (await repo.listExpired(
        'w-1',
        now: t0.add(const Duration(minutes: 1)),
      )).map((a) => a.id),
      ['due'],
    );
    await repo.settle('w-1', id: 'due', status: PeerAskStatus.expired, now: t0);
    expect(
      await repo.deleteSettledBefore(
        'w-1',
        cutoff: t0.add(const Duration(days: 30)),
      ),
      1,
    );
    expect(await repo.getById('w-1', 'due'), isNull);
    expect(await repo.getById('w-1', 'later'), isNotNull);
    // An answered ask with no settledAt is never deleted by age.
    expect(await repo.getById('w-1', 'done'), isNotNull);
  });

  test('watchForConversation shows asks made from it', () async {
    await put(ask('a'));
    await put(ask('b', conversationId: 'conv-2'));
    expect(
      (await repo.watchForConversation('w-1', 'conv-1').first).map((a) => a.id),
      ['a'],
    );
  });

  test('the stored-value checks refuse unknown values', () async {
    await put(ask('a'));
    final db = dbs.of('w-1');
    for (final set in [
      "status = 'lost'",
      "kind = 'gossip'",
      "mode = 'later'",
      "chain = 'agent-1'",
      "recipient_agent_id = 'agent-1'",
      'expires_at = created_at - 1',
      "error = '${'x' * 2001}'",
    ]) {
      await expectLater(
        db.customStatement("UPDATE peer_asks SET $set WHERE id = 'a'"),
        throwsA(anything),
        reason: set,
      );
    }
  });

  test('an ask goes with its asker', () async {
    await put(ask('a'));
    await dbs
        .of('w-1')
        .customStatement("DELETE FROM agents WHERE id = 'agent-1'");
    expect(await repo.getById('w-1', 'a'), isNull);
  });

  group('once-only markers', () {
    test('only the first caller sets each marker', () async {
      await put(ask('a'));
      final at = t0.add(const Duration(minutes: 5));
      final promised = await Future.wait([
        repo.markPromised('w-1', id: 'a', now: at),
        repo.markPromised(
          'w-1',
          id: 'a',
          now: at.add(const Duration(minutes: 1)),
        ),
      ]);
      expect(promised.where((r) => r), hasLength(1));
      expect(await repo.markBlockedNoticed('w-1', id: 'a', now: at), isTrue);
      expect(await repo.markBlockedNoticed('w-1', id: 'a', now: at), isFalse);
      expect(await repo.markStallNoticed('w-1', id: 'a', runId: 'r-1'), isTrue);
      expect(
        await repo.markStallNoticed('w-1', id: 'a', runId: 'r-2'),
        isFalse,
      );

      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.promisedAt, at);
      expect(a.blockedNoticedAt, at);
      expect(a.stallNoticedRunId, 'r-1');
    });

    test('a settled or missing ask gets no marker', () async {
      await put(ask('a'));
      expect(
        await repo.settle(
          'w-1',
          id: 'a',
          status: PeerAskStatus.answered,
          now: t0,
        ),
        isTrue,
      );
      expect(await repo.markPromised('w-1', id: 'a', now: t0), isFalse);
      expect(await repo.markBlockedNoticed('w-1', id: 'a', now: t0), isFalse);
      expect(await repo.markStallNoticed('w-1', id: 'a', runId: 'r'), isFalse);
      expect(await repo.markPromised('w-1', id: 'none', now: t0), isFalse);
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.promisedAt, isNull);
      expect(a.blockedNoticedAt, isNull);
      expect(a.stallNoticedRunId, isNull);
      expect(
        () => repo.markStallNoticed('w-1', id: 'a', runId: ''),
        throwsArgumentError,
      );
    });

    test('setDispatched never clears a marker', () async {
      await put(ask('a'));
      await repo.markPromised('w-1', id: 'a', now: t0);
      await repo.markStallNoticed('w-1', id: 'a', runId: 'r-1');
      expect(
        await repo.setDispatched('w-1', id: 'a', dispatchedRunId: 'run-9'),
        isTrue,
      );
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.dispatchedRunId, 'run-9');
      expect(a.promisedAt, t0);
      expect(a.stallNoticedRunId, 'r-1');
    });
  });

  test(
    'listPendingForRecipientConversation narrows to one answer thread',
    () async {
      await put(
        ask(
          'late',
          recipientConversationId: 'conv-2',
          createdAt: t0.add(const Duration(minutes: 1)),
        ),
      );
      await put(ask('early', recipientConversationId: 'conv-2'));
      await put(
        ask(
          'elsewhere',
          questionHash: 'h-2',
          recipientConversationId: 'conv-1',
        ),
      );
      await put(
        ask(
          'other-recipient',
          recipient: 'agent-3',
          recipientConversationId: 'conv-2',
        ),
      );
      await put(ask('unrouted', questionHash: 'h-3'));
      await put(
        ask(
          'settled',
          questionHash: 'h-4',
          recipientConversationId: 'conv-2',
          status: PeerAskStatus.answered,
        ),
      );
      final found = await repo.listPendingForRecipientConversation(
        'w-1',
        recipientAgentId: 'agent-2',
        recipientConversationId: 'conv-2',
      );
      expect([for (final a in found) a.id], ['early', 'late']);
    },
  );

  group('refused rows', () {
    /// Breaks a rule only the entity checks: an empty asker space id.
    Future<void> spoil(String id) => dbs
        .of('w-1')
        .customStatement(
          "UPDATE peer_asks SET asker_space_id = '' WHERE id = '$id'",
        );

    test(
      'a refused pending ask is settled as failed and not counted',
      () async {
        await put(ask('good'));
        await put(ask('bad', questionHash: 'h-2'));
        await spoil('bad');
        expect(await repo.countPending('w-1', askerAgentId: 'agent-1'), 1);
        expect(warnings.single, contains('1 open ones settled as failed'));
        final row =
            (await dbs
                    .of('w-1')
                    .customSelect("SELECT * FROM peer_asks WHERE id = 'bad'")
                    .getSingle())
                .data;
        expect(row['status'], 'failed');
        expect(row['error'], 'invalid_row');
        expect(row['settled_at'], isNotNull);
        expect((await repo.listPending('w-1')).map((a) => a.id), ['good']);
      },
    );

    test('a refused expired ask leaves the expiry sweep', () async {
      await put(ask('bad'));
      await spoil('bad');
      expect(
        await repo.listExpired('w-1', now: t0.add(const Duration(days: 2))),
        isEmpty,
      );
      expect(
        await repo.listExpired('w-1', now: t0.add(const Duration(days: 2))),
        isEmpty,
      );
      // Settled by the first sweep, so the second never meets it.
      expect(warnings.single, contains('settled as failed'));
    });
  });

  test('an ask in one workspace is invisible from another', () async {
    await put(
      ask('a', dispatchedRunId: 'run-1', recipientConversationId: 'conv-2'),
    );
    expect(await repo.getById('w-2', 'a'), isNull);
    expect(await repo.getByDispatchedRun('w-2', 'run-1'), isNull);
    expect(await repo.listPending('w-2'), isEmpty);
    expect(await repo.countPending('w-2'), 0);
    expect(
      await repo.settle(
        'w-2',
        id: 'a',
        status: PeerAskStatus.cancelled,
        now: t0,
      ),
      isFalse,
    );
    expect(
      await repo.setDispatched('w-2', id: 'a', dispatchedRunId: 'r'),
      isFalse,
    );
    expect(await repo.markPromised('w-2', id: 'a', now: t0), isFalse);
    expect(await repo.markBlockedNoticed('w-2', id: 'a', now: t0), isFalse);
    expect(await repo.markStallNoticed('w-2', id: 'a', runId: 'r'), isFalse);
    expect(
      await repo.listPendingForRecipientConversation(
        'w-2',
        recipientAgentId: 'agent-2',
        recipientConversationId: 'conv-2',
      ),
      isEmpty,
    );
    final a = (await repo.getById('w-1', 'a'))!;
    expect(a.isPending, isTrue);
    expect(a.promisedAt, isNull);
    expect(a.stallNoticedRunId, isNull);
  });
}
