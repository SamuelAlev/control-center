import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/ports/wake_run_ledger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// The persistence the wake queue adds on top of the outbox: deferral, claim
/// refresh, reopening a delivered wake, the rows that expiry and a filtered
/// cancel move, and the run ledger (`agent_run_logs.wake_ids`).
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWakeRepository repo;
  late DaoAgentRunLogRepository runs;
  // UTC: the repository reads instants back as UTC, and `==` on DateTime also
  // compares isUtc.
  final t0 = DateTime.utc(2026, 5, 1, 12);

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    repo = DaoWakeRepository(dbs, clock: () => t0);
    runs = DaoAgentRunLogRepository(dbs);
    for (final ws in ['w-1', 'w-2']) {
      await seedTestWorkspace(global, dbs, ws);
      final db = dbs.of(ws);
      await seedParents(db, agents: ['agent-1'], spaces: ['sp-1']);
      await seedConversation(db, 'conv-1', spaceId: 'sp-1');
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Wake wake(
    String id, {
    String workspaceId = 'w-1',
    WakeState state = WakeState.pending,
    String? stateReason,
    DateTime? expiresAt,
    WakeDetail? detail,
  }) => Wake(
    id: id,
    workspaceId: workspaceId,
    spaceId: 'sp-1',
    conversationId: 'conv-1',
    agentId: 'agent-1',
    reason: WakeReason.peerMessage,
    payload: 'p $id',
    detail: detail,
    dedupKey: 'key:$id',
    notBefore: t0,
    expiresAt: expiresAt,
    state: state,
    stateReason: stateReason,
    createdAt: t0.subtract(const Duration(minutes: 1)),
  );

  test('defer moves pending and claimed wakes to a later time', () async {
    await repo.insertIfAbsent(wake('a'));
    await repo.insertIfAbsent(wake('b'));
    await repo.claim('w-1', ids: ['b'], now: t0);
    final later = t0.add(const Duration(minutes: 5));
    expect(
      await repo.defer('w-1', ids: ['a', 'b'], until: later, reason: 'x'),
      2,
    );
    for (final id in ['a', 'b']) {
      final w = (await repo.getById('w-1', id))!;
      expect(w.state, WakeState.pending);
      expect(w.notBefore, later);
      expect(w.stateReason, 'x');
      expect(w.claimedAt, isNull);
    }
    expect(await repo.listDue('w-1', now: t0), isEmpty);
    // A foreign workspace moves nothing.
    expect(await repo.defer('w-2', ids: ['a'], until: t0, reason: 'x'), 0);
  });

  test('refreshClaims keeps an in-flight claim from going stale', () async {
    await repo.insertIfAbsent(wake('a'));
    await repo.insertIfAbsent(wake('b'));
    await repo.claim('w-1', ids: ['a', 'b'], now: t0);
    final later = t0.add(const Duration(minutes: 2));
    expect(await repo.refreshClaims('w-1', ids: ['a'], now: later), 1);
    final reclaimed = await repo.reclaimStaleClaims(
      'w-1',
      claimedBefore: t0.add(const Duration(minutes: 1)),
    );
    expect([for (final w in reclaimed) w.id], ['b']);
    expect((await repo.getById('w-1', 'a'))!.state, WakeState.claimed);
  });

  test('reopenDelivered returns a delivered wake to pending', () async {
    await repo.insertIfAbsent(wake('a'));
    await repo.claim('w-1', ids: ['a'], now: t0);
    await repo.markDelivered('w-1', ids: ['a'], runId: 'run-1', now: t0);
    expect(
      await repo.reopenDelivered('w-1', ids: ['a'], reason: 'server_stopped'),
      1,
    );
    final w = (await repo.getById('w-1', 'a'))!;
    expect(w.state, WakeState.pending);
    expect(w.deliveredRunId, isNull);
    expect(w.settledAt, isNull);
    expect(w.attempt, 1);
    expect(w.stateReason, 'server_stopped');
    // Only delivered wakes move.
    expect(
      await repo.reopenDelivered('w-1', ids: ['a'], reason: 'server_stopped'),
      0,
    );
  });

  test('expireDue and cancelWhere return the wakes they moved', () async {
    await repo.insertIfAbsent(
      wake('e', expiresAt: t0.add(const Duration(minutes: 1))),
    );
    await repo.insertIfAbsent(wake('g', detail: WakeDetail(goalId: 'g-1')));
    final expired = await repo.expireDue(
      'w-1',
      now: t0.add(const Duration(minutes: 1)),
    );
    expect([for (final w in expired) w.id], ['e']);
    expect(expired.single.state, WakeState.expired);
    final cancelled = await repo.cancelWhere(
      'w-1',
      goalId: 'g-1',
      reason: 'goal_ended',
      now: t0,
    );
    expect([for (final w in cancelled) w.id], ['g']);
    expect(cancelled.single.stateReason, 'goal_ended');
  });

  group('run ledger', () {
    AgentRunLog run(
      String id, {
      List<String> wakeIds = const [],
      DateTime? startedAt,
    }) => AgentRunLog(
      id: id,
      agentId: 'agent-1',
      workspaceId: 'w-1',
      conversationId: 'conv-1',
      startedAt: startedAt ?? t0,
      status: RunStatus.running,
      wakeIds: wakeIds,
    );

    test('finds the run a wake is on, in its workspace only', () async {
      await runs.upsert(run('run-1', wakeIds: ['wk-1', 'wk-2']));
      expect(
        await runs.runForWake('w-1', 'wk-2'),
        WakeLedgerRun(runId: 'run-1', live: true, endReason: null),
      );
      expect(await runs.runForWake('w-1', 'wk-9'), isNull);
      expect(await runs.runForWake('w-2', 'wk-2'), isNull);
    });

    test('reads the newest run carrying the wake, and how it ended', () async {
      // Delivered to run-1, which a server stop ended; delivered again to
      // run-2, which finished.
      await runs.upsert(run('run-1', wakeIds: ['wk-1']));
      await runs.completeIfActive(
        run('run-1').copyWith(
          status: RunStatus.error,
          completedAt: t0.add(const Duration(minutes: 1)),
          endReason: RunEndReason.serverStopped,
        ),
      );
      final stopped = (await runs.runForWake('w-1', 'wk-1'))!;
      expect(stopped.live, isFalse);
      expect(stopped.endReason, RunEndReason.serverStopped);
      expect(stopped.tookItsWakes, isFalse);

      await runs.upsert(
        run(
          'run-2',
          wakeIds: ['wk-1'],
          startedAt: t0.add(const Duration(minutes: 5)),
        ),
      );
      await runs.completeIfActive(
        run('run-2', startedAt: t0.add(const Duration(minutes: 5))).copyWith(
          status: RunStatus.completed,
          completedAt: t0.add(const Duration(minutes: 6)),
          endReason: RunEndReason.completed,
        ),
      );
      final finished = (await runs.runForWake('w-1', 'wk-1'))!;
      expect(finished.runId, 'run-2');
      expect(finished.tookItsWakes, isTrue);
    });

    test('the wake reason is written with the row and never cleared', () async {
      await runs.upsert(
        run('run-1').copyWith(wakeReason: WakeReason.userMessage),
      );
      // A later write built without it, then the terminal write.
      await runs.upsert(run('run-1'));
      await runs.completeIfActive(
        run('run-1').copyWith(
          status: RunStatus.completed,
          completedAt: t0.add(const Duration(minutes: 1)),
        ),
      );
      expect(
        (await runs.getById('w-1', 'run-1'))!.wakeReason,
        WakeReason.userMessage,
      );
      await runs.upsert(run('run-sub'));
      expect((await runs.getById('w-1', 'run-sub'))!.wakeReason, isNull);
    });

    test('adds drained wakes without repeats; completion keeps them', () async {
      await runs.upsert(run('run-1', wakeIds: ['wk-1']));
      await runs.addWakeIds('w-1', 'run-1', ['wk-2', 'wk-1']);
      await runs.addWakeIds('w-1', 'run-1', ['wk-2']);
      expect((await runs.getById('w-1', 'run-1'))!.wakeIds, ['wk-1', 'wk-2']);
      // A terminal write built from the run's start does not drop what the
      // run drained.
      await runs.completeIfActive(
        run('run-1', wakeIds: ['wk-1']).copyWith(
          status: RunStatus.completed,
          completedAt: t0.add(const Duration(minutes: 1)),
        ),
      );
      expect((await runs.getById('w-1', 'run-1'))!.wakeIds, ['wk-1', 'wk-2']);
      // A missing run is a no-op.
      await runs.addWakeIds('w-1', 'run-missing', ['wk-3']);
      expect(await runs.runForWake('w-1', 'wk-3'), isNull);
    });
  });
}
