import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// [DaoWakeRepository] against in-memory databases: the dedup insert, the
/// race-safe claim, every conditional state move, the cancel filters, the
/// caps' counts, retention, the stored-value checks and workspace isolation.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWakeRepository repo;
  late List<String> warnings;
  // Local, as drift reads `dateTime()` columns back.
  final t0 = DateTime.utc(2026, 5, 1, 12);

  setUp(() async {
    global = createTestGlobalDatabase();
    warnings = [];
    dbs = createTestWorkspaceDatabases(
      global: global,
      onWarn: (_, message) => warnings.add(message),
    );
    repo = DaoWakeRepository(dbs, clock: () => t0);
    for (final ws in ['w-1', 'w-2']) {
      await seedTestWorkspace(global, dbs, ws);
      final db = dbs.of(ws);
      await seedParents(db, agents: ['agent-1', 'agent-2'], spaces: ['sp-1']);
      await seedConversation(db, 'conv-1', spaceId: 'sp-1');
      await seedConversation(db, 'conv-2', spaceId: 'sp-1');
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Wake wake(
    String id, {
    String workspaceId = 'w-1',
    String conversationId = 'conv-1',
    String agentId = 'agent-1',
    WakeReason reason = WakeReason.goalContinuation,
    String? dedupKey,
    DateTime? notBefore,
    DateTime? expiresAt,
    WakeDetail? detail,
    WakeRunOptions? runOptions,
    String? requestedByUserId,
    List<String> chain = const [],
    WakeState state = WakeState.pending,
    String? stateReason,
    DateTime? createdAt,
  }) => Wake(
    id: id,
    workspaceId: workspaceId,
    spaceId: 'sp-1',
    conversationId: conversationId,
    agentId: agentId,
    reason: reason,
    payload: 'continue $id',
    detail: detail,
    runOptions: runOptions,
    dedupKey: dedupKey ?? 'key:$id',
    notBefore: notBefore ?? t0,
    expiresAt: expiresAt,
    requestedByUserId: requestedByUserId,
    chain: chain,
    state: state,
    stateReason: stateReason,
    createdAt: createdAt ?? t0.subtract(const Duration(minutes: 1)),
  );

  group('insertIfAbsent', () {
    test('writes once per dedup key and round-trips every field', () async {
      final first = wake(
        'wk-1',
        dedupKey: 'goal:g-1:3',
        expiresAt: t0.add(const Duration(hours: 1)),
        detail: WakeDetail(
          goalId: 'g-1',
          ruleId: 'r-1',
          slot: t0,
          eventKind: WakeEventKind.prChecks,
          fields: const {'pr': 12},
        ),
        runOptions: WakeRunOptions(readOnly: true, costCapMicros: 50),
        requestedByUserId: 'user-1',
        chain: const ['agent-2'],
      );
      expect(await repo.insertIfAbsent(first), isTrue);
      expect(
        await repo.insertIfAbsent(wake('wk-2', dedupKey: 'goal:g-1:3')),
        isFalse,
      );
      expect(await repo.getById('w-1', 'wk-2'), isNull);
      expect(await repo.getById('w-1', 'wk-1'), first);
      expect(await repo.getByDedupKey('w-1', 'goal:g-1:3'), first);
    });

    test('times come back in UTC, in the whole seconds stored', () async {
      final at = DateTime.utc(2026, 5, 1, 12, 0, 5, 123, 456);
      final w = wake(
        'wk-utc',
        notBefore: at,
        expiresAt: at.add(const Duration(hours: 1)),
        createdAt: at,
        detail: WakeDetail(ruleId: 'r-1', slot: at),
      );
      expect(w.detail.slot, DateTime.utc(2026, 5, 1, 12, 0, 5));
      expect(await repo.insertIfAbsent(w), isTrue);
      final read = (await repo.getById('w-1', 'wk-utc'))!;
      final whole = DateTime.utc(2026, 5, 1, 12, 0, 5);
      for (final (value, name) in [
        (read.notBefore, 'notBefore'),
        (read.expiresAt!, 'expiresAt'),
        (read.createdAt, 'createdAt'),
        (read.detail.slot!, 'slot'),
      ]) {
        expect(value.isUtc, isTrue, reason: name);
      }
      expect(read.notBefore, whole);
      expect(read.createdAt, whole);
      expect(read.detail.slot, whole);
      expect(read.expiresAt, whole.add(const Duration(hours: 1)));
    });

    test('the same key in another workspace is another wake', () async {
      expect(await repo.insertIfAbsent(wake('wk-1', dedupKey: 'k')), isTrue);
      expect(
        await repo.insertIfAbsent(
          wake('wk-1', workspaceId: 'w-2', dedupKey: 'k'),
        ),
        isTrue,
      );
    });

    test('concurrent inserts of one key write exactly one row', () async {
      final results = await Future.wait([
        for (var i = 0; i < 8; i++)
          repo.insertIfAbsent(wake('wk-$i', dedupKey: 'same')),
      ]);
      expect(results.where((r) => r), hasLength(1));
      expect(await repo.listForConversation('w-1', 'conv-1'), hasLength(1));
    });

    test('every reason, lane and state round-trips', () async {
      var i = 0;
      for (final reason in WakeReason.values) {
        await repo.insertIfAbsent(wake('r-${i++}', reason: reason));
      }
      for (final state in WakeState.values) {
        await repo.insertIfAbsent(
          wake(
            's-${state.wire}',
            state: state,
            stateReason: state == WakeState.pending ? null : 'why',
          ),
        );
      }
      final all = await repo.listForConversation('w-1', 'conv-1');
      expect(all.map((w) => w.reason).toSet(), WakeReason.values.toSet());
      expect(all.map((w) => w.state).toSet(), WakeState.values.toSet());
    });
  });

  group('due reads', () {
    test('listDue returns pending wakes due now, oldest first', () async {
      await repo.insertIfAbsent(
        wake('late', notBefore: t0.add(const Duration(minutes: 5))),
      );
      await repo.insertIfAbsent(
        wake('old', notBefore: t0.subtract(const Duration(minutes: 5))),
      );
      await repo.insertIfAbsent(wake('now'));
      await repo.insertIfAbsent(
        wake(
          'held',
          state: WakeState.held,
          stateReason: 'paused',
          notBefore: t0.subtract(const Duration(hours: 1)),
        ),
      );
      expect((await repo.listDue('w-1', now: t0)).map((w) => w.id), [
        'old',
        'now',
      ]);
      expect(await repo.listDue('w-1', now: t0, limit: 1), hasLength(1));
      expect(
        await repo.earliestPendingNotBefore('w-1'),
        t0.subtract(const Duration(minutes: 5)),
      );
      expect(await repo.earliestPendingNotBefore('w-2'), isNull);
    });

    test('listPendingFor narrows to the conversation and agent', () async {
      await repo.insertIfAbsent(wake('a'));
      await repo.insertIfAbsent(wake('b', agentId: 'agent-2'));
      await repo.insertIfAbsent(wake('c', conversationId: 'conv-2'));
      expect(
        (await repo.listPendingFor(
          'w-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
        )).map((w) => w.id),
        ['a'],
      );
    });

    test('watchForConversation shows pending and held wakes only', () async {
      await repo.insertIfAbsent(wake('p'));
      await repo.insertIfAbsent(
        wake('h', state: WakeState.held, stateReason: 'paused'),
      );
      await repo.insertIfAbsent(wake('d', state: WakeState.delivered));
      final shown = await repo.watchForConversation('w-1', 'conv-1').first;
      expect(shown.map((w) => w.id).toSet(), {'p', 'h'});
    });

    test('listForConversation narrows to states', () async {
      await repo.insertIfAbsent(wake('p'));
      await repo.insertIfAbsent(wake('d', state: WakeState.delivered));
      expect(
        (await repo.listForConversation(
          'w-1',
          'conv-1',
          states: {WakeState.delivered},
        )).map((w) => w.id),
        ['d'],
      );
    });
  });

  group('claim', () {
    test('moves pending wakes and counts the attempt', () async {
      await repo.insertIfAbsent(wake('a'));
      await repo.insertIfAbsent(
        wake('h', state: WakeState.held, stateReason: 'paused'),
      );
      final claimed = await repo.claim(
        'w-1',
        ids: ['a', 'h', 'missing'],
        now: t0,
      );
      expect(claimed, ['a']);
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.state, WakeState.claimed);
      expect(a.attempt, 1);
      expect(a.claimedAt, t0);
    });

    test('two racing claimers never both get a wake', () async {
      for (var i = 0; i < 20; i++) {
        await repo.insertIfAbsent(wake('w$i'));
      }
      final ids = [for (var i = 0; i < 20; i++) 'w$i'];
      final results = await Future.wait([
        repo.claim('w-1', ids: ids, now: t0),
        repo.claim('w-1', ids: ids.reversed.toList(), now: t0),
        repo.claim('w-1', ids: ids, now: t0),
      ]);
      final all = [for (final r in results) ...r];
      expect(all, hasLength(20));
      expect(all.toSet(), hasLength(20));
    });

    test('a claim in another workspace does not touch this one', () async {
      await repo.insertIfAbsent(wake('a'));
      expect(await repo.claim('w-2', ids: ['a'], now: t0), isEmpty);
      expect((await repo.getById('w-1', 'a'))!.state, WakeState.pending);
    });
  });

  group('settling', () {
    test('markDelivered settles exactly once', () async {
      await repo.insertIfAbsent(wake('a'));
      await repo.claim('w-1', ids: ['a'], now: t0);
      expect(
        await repo.markDelivered('w-1', ids: ['a'], runId: 'run-1', now: t0),
        1,
      );
      expect(
        await repo.markDelivered('w-1', ids: ['a'], runId: 'run-2', now: t0),
        0,
      );
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.state, WakeState.delivered);
      expect(a.deliveredRunId, 'run-1');
      expect(a.settledAt, t0);
    });

    test('a settled wake cannot be skipped, expired or cancelled', () async {
      await repo.insertIfAbsent(wake('a'));
      await repo.markDelivered('w-1', ids: ['a'], runId: 'run-1', now: t0);
      expect(
        await repo.markSkipped('w-1', ids: ['a'], reason: 'busy', now: t0),
        0,
      );
      expect(
        await repo.markExpired('w-1', ids: ['a'], reason: 'late', now: t0),
        0,
      );
      expect(await repo.cancel('w-1', ids: ['a'], reason: 'stop', now: t0), 0);
      expect((await repo.getById('w-1', 'a'))!.state, WakeState.delivered);
    });

    test('skip, expire and cancel record the reason', () async {
      await repo.insertIfAbsent(wake('s'));
      await repo.insertIfAbsent(wake('e'));
      await repo.insertIfAbsent(
        wake('c', state: WakeState.held, stateReason: 'paused'),
      );
      expect(
        await repo.markSkipped('w-1', ids: ['s'], reason: 'busy', now: t0),
        1,
      );
      expect(
        await repo.markExpired('w-1', ids: ['e'], reason: 'late', now: t0),
        1,
      );
      expect(
        await repo.cancel('w-1', ids: ['c'], reason: 'goal_ended', now: t0),
        1,
      );
      expect((await repo.getById('w-1', 's'))!.stateReason, 'busy');
      expect((await repo.getById('w-1', 'e'))!.state, WakeState.expired);
      final c = (await repo.getById('w-1', 'c'))!;
      expect(c.state, WakeState.cancelled);
      expect(c.stateReason, 'goal_ended');
    });

    test('a reason the entity cannot read back is refused', () {
      expect(
        () => repo.markSkipped('w-1', ids: ['a'], reason: '', now: t0),
        throwsArgumentError,
      );
      expect(
        () => repo.cancel('w-1', ids: ['a'], reason: 'x' * 101, now: t0),
        throwsArgumentError,
      );
    });

    test('hold and release move between pending and held', () async {
      await repo.insertIfAbsent(wake('a'));
      expect(await repo.hold('w-1', ids: ['a'], reason: 'goal_paused'), 1);
      expect(await repo.hold('w-1', ids: ['a'], reason: 'again'), 0);
      expect((await repo.getById('w-1', 'a'))!.state, WakeState.held);
      expect(await repo.release('w-1', ids: ['a']), 1);
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.state, WakeState.pending);
      expect(a.stateReason, isNull);
    });

    test('releaseClaim returns a claim to pending', () async {
      await repo.insertIfAbsent(wake('a'));
      await repo.claim('w-1', ids: ['a'], now: t0);
      expect(await repo.releaseClaim('w-1', ids: ['a']), 1);
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.state, WakeState.pending);
      expect(a.claimedAt, isNull);
      expect(a.attempt, 1);
    });

    test('reclaimStaleClaims returns only old claims', () async {
      await repo.insertIfAbsent(wake('old'));
      await repo.insertIfAbsent(wake('new'));
      await repo.claim('w-1', ids: ['old'], now: t0);
      await repo.claim(
        'w-1',
        ids: ['new'],
        now: t0.add(const Duration(minutes: 10)),
      );
      final back = await repo.reclaimStaleClaims(
        'w-1',
        claimedBefore: t0.add(const Duration(minutes: 5)),
      );
      expect(back.map((w) => w.id), ['old']);
      expect(back.single.state, WakeState.pending);
      expect((await repo.getById('w-1', 'new'))!.state, WakeState.claimed);
    });

    test('a claim released and taken afresh is not reclaimed', () async {
      await repo.insertIfAbsent(wake('w'));
      // Claimed long ago, then released and claimed again by a new delivery
      // before the sweep's write: its age is the new claim's.
      await repo.claim('w-1', ids: ['w'], now: t0);
      await repo.releaseClaim('w-1', ids: ['w']);
      final fresh = t0.add(const Duration(minutes: 10));
      expect(await repo.claim('w-1', ids: ['w'], now: fresh), ['w']);
      expect(
        await repo.reclaimStaleClaims(
          'w-1',
          claimedBefore: t0.add(const Duration(minutes: 5)),
        ),
        isEmpty,
      );
      final w = (await repo.getById('w-1', 'w'))!;
      expect(w.state, WakeState.claimed);
      expect(w.claimedAt, fresh);
      expect(w.attempt, 2);
    });

    test('expireDue expires pending and held wakes past expiresAt', () async {
      final soon = t0.add(const Duration(minutes: 1));
      await repo.insertIfAbsent(wake('p', expiresAt: soon));
      await repo.insertIfAbsent(
        wake('h', expiresAt: soon, state: WakeState.held, stateReason: 'x'),
      );
      await repo.insertIfAbsent(
        wake('later', expiresAt: t0.add(const Duration(hours: 1))),
      );
      await repo.insertIfAbsent(wake('never'));
      expect(await repo.expireDue('w-1', now: soon), hasLength(2));
      expect((await repo.getById('w-1', 'p'))!.state, WakeState.expired);
      expect((await repo.getById('w-1', 'later'))!.state, WakeState.pending);
    });

    test('deferWaiting bounds a waiting wake; expireWaiting expires only '
        'those reasons and keeps the reason', () async {
      final bound = t0.add(const Duration(days: 7));
      final later = t0.add(const Duration(minutes: 1));
      await repo.insertIfAbsent(wake('p'));
      await repo.insertIfAbsent(wake('c'));
      await repo.claim('w-1', ids: ['c'], now: t0);
      await repo.insertIfAbsent(
        wake('other', expiresAt: t0.add(const Duration(days: 1))),
      );
      for (final id in ['p', 'c']) {
        expect(
          await repo.deferWaiting(
            'w-1',
            id: id,
            until: later,
            reason: 'budget_blocked',
            expiresAt: bound,
          ),
          1,
        );
      }
      final c = (await repo.getById('w-1', 'c'))!;
      expect(c.state, WakeState.pending);
      expect(c.claimedAt, isNull);
      expect(c.notBefore, later);
      expect(c.expiresAt, bound);
      expect(c.stateReason, 'budget_blocked');
      // In another workspace the id is not found.
      expect(
        await repo.deferWaiting(
          'w-2',
          id: 'p',
          until: later,
          reason: 'budget_blocked',
          expiresAt: bound,
        ),
        0,
      );
      expect(
        await repo.expireWaiting(
          'w-1',
          now: bound.subtract(const Duration(seconds: 1)),
          reasons: {'budget_blocked'},
        ),
        isEmpty,
      );
      expect(
        await repo.expireWaiting(
          'w-1',
          now: bound,
          reasons: {'agent_paused'},
        ),
        isEmpty,
      );
      final expired = await repo.expireWaiting(
        'w-1',
        now: bound,
        reasons: {'budget_blocked', 'agent_paused'},
      );
      expect([for (final w in expired) w.id], unorderedEquals(['p', 'c']));
      final p = (await repo.getById('w-1', 'p'))!;
      expect(p.state, WakeState.expired);
      expect(p.stateReason, 'budget_blocked');
      expect(p.settledAt, isNotNull);
      // A wake past its own expiry for another reason is not this one's.
      expect(
        (await repo.getById('w-1', 'other'))!.state,
        WakeState.pending,
      );
    });

    test('deleteSettledBefore keeps open and recent wakes', () async {
      await repo.insertIfAbsent(wake('old'));
      await repo.insertIfAbsent(wake('recent'));
      await repo.insertIfAbsent(wake('open'));
      await repo.markDelivered('w-1', ids: ['old'], runId: 'r', now: t0);
      await repo.markDelivered(
        'w-1',
        ids: ['recent'],
        runId: 'r',
        now: t0.add(const Duration(days: 20)),
      );
      expect(
        await repo.deleteSettledBefore(
          'w-1',
          cutoff: t0.add(const Duration(days: 14)),
        ),
        1,
      );
      expect(await repo.getById('w-1', 'old'), isNull);
      expect(await repo.getById('w-1', 'recent'), isNotNull);
      expect(await repo.getById('w-1', 'open'), isNotNull);
    });
  });

  group('counts and cancels', () {
    test('countDeliveredRunsSince counts distinct runs', () async {
      for (final id in ['a', 'b', 'c']) {
        await repo.insertIfAbsent(wake(id));
      }
      await repo.insertIfAbsent(wake('d', conversationId: 'conv-2'));
      await repo.markDelivered('w-1', ids: ['a', 'b'], runId: 'r1', now: t0);
      await repo.markDelivered('w-1', ids: ['c'], runId: 'r2', now: t0);
      await repo.markDelivered('w-1', ids: ['d'], runId: 'r3', now: t0);
      final since = t0.subtract(const Duration(minutes: 1));
      expect(await repo.countDeliveredRunsSince('w-1', since: since), 3);
      expect(
        await repo.countDeliveredRunsSince(
          'w-1',
          since: since,
          conversationId: 'conv-1',
        ),
        2,
      );
      expect(
        await repo.countDeliveredRunsSince(
          'w-1',
          since: t0.add(const Duration(seconds: 1)),
        ),
        0,
      );
    });

    test('cancelWhere matches detail keys and columns', () async {
      await repo.insertIfAbsent(
        wake('g1', detail: WakeDetail(goalId: 'goal-1')),
      );
      await repo.insertIfAbsent(
        wake('g2', detail: WakeDetail(goalId: 'goal-2')),
      );
      await repo.insertIfAbsent(
        wake('r1', detail: WakeDetail(ruleId: 'rule-1')),
      );
      await repo.insertIfAbsent(wake('a1', detail: WakeDetail(askId: 'ask-1')));
      await repo.insertIfAbsent(wake('u1', requestedByUserId: 'user-1'));
      await repo.insertIfAbsent(
        wake('c2', conversationId: 'conv-2', requestedByUserId: 'user-1'),
      );
      expect(
        await repo.cancelWhere(
          'w-1',
          goalId: 'goal-1',
          reason: 'goal_ended',
          now: t0,
        ),
        hasLength(1),
      );
      expect(
        await repo.cancelWhere('w-1', ruleId: 'rule-1', reason: 'x', now: t0),
        hasLength(1),
      );
      expect(
        await repo.cancelWhere('w-1', askId: 'ask-1', reason: 'x', now: t0),
        hasLength(1),
      );
      expect(
        await repo.cancelWhere(
          'w-1',
          requestedByUserId: 'user-1',
          conversationId: 'conv-1',
          reason: 'member_removed',
          now: t0,
        ),
        hasLength(1),
      );
      expect((await repo.getById('w-1', 'g2'))!.state, WakeState.pending);
      expect((await repo.getById('w-1', 'c2'))!.state, WakeState.pending);
      expect((await repo.getById('w-1', 'g1'))!.stateReason, 'goal_ended');
    });

    test('cancelWhere without a filter is refused', () {
      expect(
        () => repo.cancelWhere('w-1', reason: 'x', now: t0),
        throwsArgumentError,
      );
    });

    test('workspacesWithOpenWakes lists workspaces with work', () async {
      expect(await repo.workspacesWithOpenWakes(), isEmpty);
      await repo.insertIfAbsent(wake('a', workspaceId: 'w-2'));
      expect(await repo.workspacesWithOpenWakes(), ['w-2']);
    });

    test('a held wake that expires keeps its workspace open (its expiry '
        'must be swept); one that never expires does not', () async {
      await repo.insertIfAbsent(
        wake('h', workspaceId: 'w-2', state: WakeState.held),
      );
      expect(await repo.workspacesWithOpenWakes(), isEmpty);
      expect(await repo.hasExpiringHeld('w-2'), isFalse);
      await repo.insertIfAbsent(
        wake(
          'x',
          workspaceId: 'w-2',
          state: WakeState.held,
          expiresAt: t0.add(const Duration(days: 7)),
        ),
      );
      expect(await repo.workspacesWithOpenWakes(), ['w-2']);
      expect(await repo.hasExpiringHeld('w-2'), isTrue);
    });
  });

  group('storage', () {
    test('the stored-value checks refuse unknown values', () async {
      await repo.insertIfAbsent(wake('a'));
      final db = dbs.of('w-1');
      for (final set in [
        "state = 'lost'",
        "reason = 'whim'",
        "lane = 'middle'",
        "detail = '[1]'",
        "chain = '{}'",
        "run_options = 'null-ish'",
        "payload = '${'x' * 4001}'",
        'attempt = -1',
        'expires_at = created_at - 1',
      ]) {
        await expectLater(
          db.customStatement("UPDATE agent_wakes SET $set WHERE id = 'a'"),
          throwsA(anything),
          reason: set,
        );
      }
    });

    Future<Map<String, Object?>> raw(String id) async =>
        (await dbs
                .of('w-1')
                .customSelect(
                  'SELECT * FROM agent_wakes WHERE id = ?',
                  variables: [Variable.withString(id)],
                )
                .getSingle())
            .data;

    /// Breaks a rule only the entity checks: an empty space id.
    Future<void> spoil(String id) => dbs
        .of('w-1')
        .customStatement(
          "UPDATE agent_wakes SET space_id = '' WHERE id = '$id'",
        );

    test('an unreadable row is left out instead of failing reads', () async {
      await repo.insertIfAbsent(wake('good'));
      await repo.insertIfAbsent(wake('bad'));
      await spoil('bad');
      expect(
        (await repo.listForConversation('w-1', 'conv-1')).map((w) => w.id),
        ['good'],
      );
      expect(await repo.getById('w-1', 'bad'), isNull);
    });

    test(
      'a refused open row is settled once and never drives the timer',
      () async {
        await repo.insertIfAbsent(
          wake('bad', notBefore: t0.subtract(const Duration(hours: 1))),
        );
        await repo.insertIfAbsent(wake('good'));
        await spoil('bad');
        // The earliest pending row is the refused one: it is settled on the
        // way and the timer is armed from the next readable wake.
        expect(await repo.earliestPendingNotBefore('w-1'), t0);
        expect(await raw('bad'), containsPair('state', 'skipped'));
        expect(await raw('bad'), containsPair('state_reason', 'invalid_row'));
        expect(warnings.single, contains('1 open ones settled as skipped'));
        expect((await repo.listDue('w-1', now: t0)).map((w) => w.id), ['good']);
        // Settled rows are not settled again.
        await repo.listForConversation('w-1', 'conv-1');
        expect(warnings, hasLength(2));
        expect(warnings.last, isNot(contains('settled')));
      },
    );

    test('a refused due row is settled by listDue', () async {
      await repo.insertIfAbsent(wake('bad'));
      await spoil('bad');
      expect(await repo.listDue('w-1', now: t0), isEmpty);
      expect(await raw('bad'), containsPair('state', 'skipped'));
      expect(await repo.earliestPendingNotBefore('w-1'), isNull);
    });

    test('a malformed detail reads as empty', () async {
      await repo.insertIfAbsent(wake('a', detail: WakeDetail(goalId: 'g')));
      await dbs
          .of('w-1')
          .customStatement(
            'UPDATE agent_wakes SET detail = \'{"goalId": 7}\' '
            "WHERE id = 'a'",
          );
      expect((await repo.getById('w-1', 'a'))!.detail.goalId, isNull);
    });

    test('a wake goes with its conversation', () async {
      await repo.insertIfAbsent(wake('a'));
      await dbs
          .of('w-1')
          .customStatement("DELETE FROM conversations WHERE id = 'conv-1'");
      expect(await repo.getById('w-1', 'a'), isNull);
    });
  });

  group('workspace isolation', () {
    test('a wake in one workspace is invisible from another', () async {
      await repo.insertIfAbsent(wake('a', dedupKey: 'k'));
      expect(await repo.getById('w-2', 'a'), isNull);
      expect(await repo.getByDedupKey('w-2', 'k'), isNull);
      expect(await repo.listDue('w-2', now: t0), isEmpty);
      expect(await repo.listForConversation('w-2', 'conv-1'), isEmpty);
      expect(await repo.watchForConversation('w-2', 'conv-1').first, isEmpty);
      expect(
        await repo.markDelivered('w-2', ids: ['a'], runId: 'r', now: t0),
        0,
      );
      expect(
        await repo.cancelWhere(
          'w-2',
          conversationId: 'conv-1',
          reason: 'x',
          now: t0,
        ),
        isEmpty,
      );
      expect((await repo.getById('w-1', 'a'))!.state, WakeState.pending);
    });
  });
}
