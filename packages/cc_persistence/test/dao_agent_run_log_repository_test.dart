import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/tables/agent_run_logs.dart'
    show AgentRunLogsTable;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Helper: insert an agent row so FK constraints on [AgentRunLogsTable] are
/// satisfied.
Future<void> _seedAgent(WorkspaceDatabase db, String id, String workspaceId) =>
    db
        .into(db.agentsTable)
        .insert(
          AgentsTableCompanion.insert(
            id: id,
            name: 'agent-$id',
            title: 'Agent $id',
            agentMdPath: '/agents/$id.md',
            workspaceId: workspaceId,
            skills: 'dart',
          ),
        );

/// Minimal domain entity for tests.  Only set fields that matter for the
/// scenario under test.
AgentRunLog _makeLog({
  String id = 'log-1',
  String agentId = 'agent-1',
  String? workspaceId = 'ws-1',
  String? conversationId,
  String? ticketId,
  String? spaceId,
  DateTime? startedAt,
  DateTime? completedAt,
  RunStatus status = RunStatus.completed,
  String? summary,
  String? adapter,
  int? pid,
  String? logPath,
  RunCost? cost,
  RunLiveness? liveness,
  RunErrorFamily? errorFamily,
  DateTime? lastOutputAt,
  String? continuationSummary,
  String? contextSnapshotJson,
  RetryMeta? retry,
  int childCostMicros = 0,
  String? parentRunId,
  String? effort,
  String? taskFamily,
  String? nativeSessionId,
  bool resumedNativeSession = false,
  RunVerification? verification,
  RunLatencyProfile? latency,
}) {
  return AgentRunLog(
    id: id,
    agentId: agentId,
    workspaceId: workspaceId,
    conversationId: conversationId,
    ticketId: ticketId,
    spaceId: spaceId,
    startedAt: startedAt ?? DateTime(2025, 6, 1),
    completedAt: completedAt,
    status: status,
    summary: summary,
    adapter: adapter,
    pid: pid,
    logPath: logPath,
    cost: cost ?? RunCost.zero,
    liveness: liveness,
    errorFamily: errorFamily,
    lastOutputAt: lastOutputAt,
    continuationSummary: continuationSummary,
    contextSnapshotJson: contextSnapshotJson,
    retry: retry ?? const RetryMeta(),
    childCostMicros: childCostMicros,
    parentRunId: parentRunId,
    effort: effort,
    taskFamily: taskFamily,
    nativeSessionId: nativeSessionId,
    resumedNativeSession: resumedNativeSession,
    verification: verification,
    latency: latency,
  );
}

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoAgentRunLogRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // `watchAll`/`watchRecent` merge one stream per REGISTERED workspace, so
    // both workspaces this file writes to have to be in the registry — a
    // workspace database is not discovered by having been handed out.
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    repo = DaoAgentRunLogRepository(dbs);
    // FK prerequisite for run logs: the agent row, in ws-1's own database.
    await _seedAgent(dbs.of('ws-1'), 'agent-1', 'ws-1');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  // ── getById ─────────────────────────────────────────────────────────────

  group('getById', () {
    test('returns null for nonexistent id', () async {
      expect(await repo.getById('ws-1', 'nope'), isNull);
    });

    test('returns the log after upsert', () async {
      final log = _makeLog();
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'log-1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'log-1');
      expect(fetched.agentId, 'agent-1');
      expect(fetched.status, RunStatus.completed);
    });

    test('round-trips all fields including nullable ones', () async {
      final log = AgentRunLog(
        id: 'full-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        ticketId: 'ticket-1',
        spaceId: 'ch-1',
        startedAt: DateTime(2025, 1, 2, 3, 4, 5),
        completedAt: DateTime(2025, 1, 3),
        status: RunStatus.error,
        summary: 'All done',
        adapter: 'openai',
        pid: 12345,
        logPath: '/tmp/run.log',
        cost: const RunCost(
          inputTokens: 100,
          outputTokens: 50,
          estimatedCostCents: 15,
        ),
        liveness: RunLiveness.failed,
        errorFamily: RunErrorFamily.transientUpstream,
        lastOutputAt: DateTime(2025, 1, 2, 12),
        continuationSummary: 'continued...',
        contextSnapshotJson: '{"key": "val"}',
        retry: const RetryMeta(parentRunId: 'parent-1', attempt: 3),
      );
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'full-1');
      expect(fetched, isNotNull);
      expect(fetched, log);
    });
  });

  // ── upsert / CRUD ───────────────────────────────────────────────────────

  group('upsert', () {
    test('inserts a new log', () async {
      await repo.upsert(_makeLog());

      final fetched = await repo.getById('ws-1', 'log-1');
      expect(fetched, isNotNull);
    });

    test('updates an existing log with the same id', () async {
      await repo.upsert(_makeLog(status: RunStatus.pending));

      await repo.upsert(_makeLog(status: RunStatus.completed));

      final fetched = await repo.getById('ws-1', 'log-1');
      expect(fetched!.status, RunStatus.completed);
    });

    test('nullable fields survive re-upsert with absent values', () async {
      // drift.Value.absentIfNull(null) means "don't touch this column" on
      // conflict-update, so clearing nullable fields on the entity and
      // re-upserting will NOT null them in the DB — the previous value
      // survives.  This test documents that behaviour.
      final withFields = _makeLog(
        id: 'clear-1',
        summary: 'original',
        logPath: '/tmp/run.log',
        liveness: RunLiveness.alive,
      );
      await repo.upsert(withFields);

      // Re-upsert the same id without those fields.
      final cleared = withFields.copyWith(
        removeSummary: true,
        removeLogPath: true,
        removeLiveness: true,
      );
      await repo.upsert(cleared);

      final fetched = await repo.getById('ws-1', 'clear-1');
      // Fields are NOT cleared — Value.absentIfNull omits them from the
      // UPDATE, so the original values remain.
      expect(fetched!.summary, 'original');
      expect(fetched.logPath, '/tmp/run.log');
      expect(fetched.liveness, RunLiveness.alive);
    });

    /// The workspace id is the only field beyond the identity ones that is now
    /// mandatory on write — it is what picks the database file. Everything else
    /// may be omitted.
    test('handles run with minimal fields', () async {
      final minimal = AgentRunLog(
        id: 'minimal-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: DateTime(2025),
        status: RunStatus.pending,
      );
      await repo.upsert(minimal);

      final fetched = await repo.getById('ws-1', 'minimal-1');
      expect(fetched, isNotNull);
      expect(fetched!.conversationId, isNull);
      expect(fetched.cost.inputTokens, 0);
      expect(fetched.retry.attempt, 0);
    });
  });

  // ── watchByAgent ────────────────────────────────────────────────────────

  group('watchByAgent', () {
    test('emits empty list when agent has no logs', () async {
      final logs = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(logs, isEmpty);
    });

    test('emits logs for the given agent', () async {
      await repo.upsert(_makeLog());
      await repo.upsert(_makeLog(id: 'log-2'));

      final logs = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(logs.length, 2);
      expect(logs.map((l) => l.id), containsAll(['log-1', 'log-2']));
    });

    test('does not emit logs from other agents', () async {
      await _seedAgent(dbs.of('ws-1'), 'agent-2', 'ws-1');
      await repo.upsert(_makeLog());
      await repo.upsert(_makeLog(id: 'log-2', agentId: 'agent-2'));

      final logs = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(logs.length, 1);
      expect(logs.single.id, 'log-1');
    });

    test('emits updated list after insert', () async {
      final stream = repo.watchByAgent('ws-1', 'agent-1');

      await repo.upsert(_makeLog(id: 'log-1'));
      await repo.upsert(_makeLog(id: 'log-2'));

      final logs = await stream.first;
      expect(logs.length, 2);
    });

    test('emits updated list after update', () async {
      await repo.upsert(_makeLog(status: RunStatus.pending));

      final stream = repo.watchByAgent('ws-1', 'agent-1');

      // First emission already has the pending log.
      final first = await stream.first;
      expect(first.single.status, RunStatus.pending);

      // Update the same log.
      await repo.upsert(_makeLog(status: RunStatus.error));

      // A new emission should follow.
      // We restart a fresh listen to catch the updated state after the
      // update.
      final afterUpdate = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(afterUpdate.single.status, RunStatus.error);
    });

    test('logs are ordered by startedAt descending', () async {
      await repo.upsert(_makeLog(id: 'older', startedAt: DateTime(2025, 1)));
      await repo.upsert(_makeLog(id: 'newer', startedAt: DateTime(2025, 6)));

      final logs = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(logs[0].id, 'newer');
      expect(logs[1].id, 'older');
    });
  });

  // ── watchAll ────────────────────────────────────────────────────────────

  group('watchAll', () {
    test('emits empty list when no logs exist', () async {
      final logs = await repo.watchAll().first;
      expect(logs, isEmpty);
    });

    test('emits logs from all agents', () async {
      await _seedAgent(dbs.of('ws-1'), 'agent-2', 'ws-1');
      await repo.upsert(_makeLog());
      await repo.upsert(_makeLog(id: 'log-2', agentId: 'agent-2'));

      final logs = await repo.watchAll().first;
      expect(logs.length, 2);
    });

    test('emits updated list after insert', () async {
      final stream = repo.watchAll();

      await repo.upsert(_makeLog());

      final logs = await stream.first;
      expect(logs.length, 1);
    });

    test('logs are ordered by startedAt descending', () async {
      await repo.upsert(
        _makeLog(
          id: 'oldest',
          agentId: 'agent-1',
          startedAt: DateTime(2025, 1),
        ),
      );
      await repo.upsert(
        _makeLog(
          id: 'newest',
          agentId: 'agent-1',
          startedAt: DateTime(2025, 12),
        ),
      );

      final logs = await repo.watchAll().first;
      expect(logs[0].id, 'newest');
      expect(logs[1].id, 'oldest');
    });

    /// CROSS-WORKSPACE BY DESIGN: `watchAll` is one of the two reads that spans
    /// files. It merges a stream per REGISTERED workspace and re-sorts the
    /// result newest-first, because concatenating per-workspace lists would
    /// otherwise leave them interleaved by workspace.
    test('merges logs from every registered workspace, newest first', () async {
      await _seedAgent(dbs.of('ws-2'), 'agent-2', 'ws-2');
      await repo.upsert(
        _makeLog(id: 'ws1-middle', startedAt: DateTime(2025, 6)),
      );
      await repo.upsert(
        _makeLog(
          id: 'ws2-newest',
          agentId: 'agent-2',
          workspaceId: 'ws-2',
          startedAt: DateTime(2025, 12),
        ),
      );
      await repo.upsert(
        _makeLog(
          id: 'ws2-oldest',
          agentId: 'agent-2',
          workspaceId: 'ws-2',
          startedAt: DateTime(2025),
        ),
      );

      final logs = await repo.watchAll().first;
      expect(logs.map((l) => l.id), ['ws2-newest', 'ws1-middle', 'ws2-oldest']);

      // The bounded companion trims the same merged order.
      final recent = await repo.watchRecent(2).first;
      expect(recent.map((l) => l.id), ['ws2-newest', 'ws1-middle']);

      // ...while the workspace-scoped read sees only its own file.
      expect(
        (await repo.watchByAgent('ws-2', 'agent-2').first).map((l) => l.id),
        ['ws2-newest', 'ws2-oldest'],
      );
    });
  });

  // ── watchActiveByConversation ───────────────────────────────────────────

  group('watchActiveByConversation', () {
    test('emits empty list when no active logs match', () async {
      final logs = await repo.watchActiveByConversation('ws-1', 'conv-1').first;
      expect(logs, isEmpty);
    });

    test(
      'emits only active logs for matching workspace + conversation',
      () async {
        // Completed log – should be excluded.
        await repo.upsert(
          _makeLog(
            id: 'completed-1',
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            status: RunStatus.completed,
            completedAt: DateTime(2025),
          ),
        );
        // Active (pending) log for the right workspace/conversation.
        await repo.upsert(
          _makeLog(
            id: 'active-1',
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            status: RunStatus.running,
            completedAt: null,
          ),
        );

        final logs = await repo
            .watchActiveByConversation('ws-1', 'conv-1')
            .first;
        expect(logs.length, 1);
        expect(logs.single.id, 'active-1');
      },
    );

    test('excludes logs with different workspaceId', () async {
      await _seedAgent(dbs.of('ws-2'), 'agent-2', 'ws-2');
      await repo.upsert(
        _makeLog(
          id: 'ws1-log',
          agentId: 'agent-1',
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          completedAt: null,
          status: RunStatus.running,
        ),
      );
      await repo.upsert(
        _makeLog(
          id: 'ws2-log',
          agentId: 'agent-2',
          conversationId: 'conv-1',
          workspaceId: 'ws-2',
          completedAt: null,
          status: RunStatus.running,
        ),
      );

      final logs = await repo.watchActiveByConversation('ws-1', 'conv-1').first;
      expect(logs.length, 1);
      expect(logs.single.id, 'ws1-log');
    });

    test('excludes logs with different conversationId', () async {
      await repo.upsert(
        _makeLog(
          id: 'conv1-log',
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          completedAt: null,
          status: RunStatus.running,
        ),
      );
      await repo.upsert(
        _makeLog(
          id: 'conv2-log',
          conversationId: 'conv-2',
          workspaceId: 'ws-1',
          completedAt: null,
          status: RunStatus.running,
        ),
      );

      final logs = await repo.watchActiveByConversation('ws-1', 'conv-1').first;
      expect(logs.length, 1);
      expect(logs.single.id, 'conv1-log');
    });

    test('excludes logs where completedAt is not null', () async {
      await repo.upsert(
        _makeLog(
          id: 'done',
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          completedAt: DateTime(2025),
          status: RunStatus.completed,
        ),
      );
      await repo.upsert(
        _makeLog(
          id: 'active',
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          completedAt: null,
          status: RunStatus.running,
        ),
      );

      final logs = await repo.watchActiveByConversation('ws-1', 'conv-1').first;
      expect(logs.length, 1);
      expect(logs.single.id, 'active');
    });

    test('live stream emits when a new active log is inserted', () async {
      final stream = repo.watchActiveByConversation('ws-1', 'conv-1');

      // First emission: empty.
      final first = await stream.first;
      expect(first, isEmpty);

      // Insert an active log.
      await repo.upsert(
        _makeLog(
          id: 'live-1',
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          completedAt: null,
          status: RunStatus.running,
        ),
      );

      // Stream should emit again with the new log.
      // Since the first() call consumed the first empty emission, the next
      // emission will be the updated list.
      final after = await repo
          .watchActiveByConversation('ws-1', 'conv-1')
          .first;
      expect(after.length, 1);
      expect(after.single.id, 'live-1');
    });

    test('live stream emits when an active log becomes completed', () async {
      // Insert an active log.
      await repo.upsert(
        _makeLog(
          id: 'to-complete',
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          completedAt: null,
          status: RunStatus.running,
        ),
      );

      // Mark it as completed.
      await repo.upsert(
        _makeLog(
          id: 'to-complete',
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          completedAt: DateTime(2025),
          status: RunStatus.completed,
        ),
      );

      // It should no longer appear in the active stream.
      final logs = await repo.watchActiveByConversation('ws-1', 'conv-1').first;
      expect(logs, isEmpty);
    });
  });

  // ── edge cases ───────────────────────────────────────────────────────────

  group('edge cases', () {
    test('getById is case-sensitive', () async {
      await repo.upsert(_makeLog(id: 'Log-1'));
      expect(await repo.getById('ws-1', 'log-1'), isNull);
      expect(await repo.getById('ws-1', 'Log-1'), isNotNull);
    });

    test('multiple upserts of same id preserve latest values', () async {
      await repo.upsert(
        _makeLog(id: 'multi', status: RunStatus.pending, summary: 'first'),
      );
      await repo.upsert(
        _makeLog(id: 'multi', status: RunStatus.completed, summary: 'second'),
      );
      await repo.upsert(
        _makeLog(id: 'multi', status: RunStatus.error, summary: 'third'),
      );

      final fetched = await repo.getById('ws-1', 'multi');
      expect(fetched!.status, RunStatus.error);
      expect(fetched.summary, 'third');
    });

    test(
      'watchByAgent returns empty for agent with no logs but other agent has logs',
      () async {
        await _seedAgent(dbs.of('ws-1'), 'agent-2', 'ws-1');
        await repo.upsert(_makeLog(id: 'log-1', agentId: 'agent-2'));

        final logs = await repo.watchByAgent('ws-1', 'agent-1').first;
        expect(logs, isEmpty);
      },
    );

    test(
      'watchActiveByConversation with completedAt: null but completed status',
      () async {
        // completedAt: null + status: completed is unusual but possible
        // during a race. The DAO filter is on completedAt IS NULL, not
        // status, so it WILL include this log.
        await repo.upsert(
          _makeLog(
            id: 'null-completed',
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            completedAt: null,
            status: RunStatus.completed,
          ),
        );

        final logs = await repo
            .watchActiveByConversation('ws-1', 'conv-1')
            .first;
        expect(logs.length, 1);
        expect(logs.single.id, 'null-completed');
      },
    );

    /// Was "a null workspaceId does not trigger an FK issue" — when every
    /// workspace shared one database a workspace-less run log was merely odd.
    /// Now the workspace id is what SELECTS the database file, so a run with no
    /// workspace has nowhere to be written and the repository rejects it loudly
    /// rather than guessing a workspace or silently dropping the row.
    ///
    /// Note the `() =>`: `upsert` is not `async`, so the guard throws
    /// SYNCHRONOUSLY rather than completing the returned future with an error.
    test('upsert rejects a run log with no workspace', () async {
      expect(
        () => repo.upsert(_makeLog(id: 'no-ws', workspaceId: null)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.upsert(_makeLog(id: 'empty-ws', workspaceId: '')),
        throwsA(isA<ArgumentError>()),
      );

      expect(await repo.getById('ws-1', 'no-ws'), isNull);
    });

    test(
      'upsert with non-null nullable fields round-trips correctly',
      () async {
        await repo.upsert(
          _makeLog(
            id: 'nullable-test',
            summary: 'summary text',
            adapter: 'anthropic',
            pid: 99999,
            logPath: '/logs/test.log',
            liveness: RunLiveness.stalled,
            errorFamily: RunErrorFamily.budgetExceeded,
            lastOutputAt: DateTime(2025, 6, 2),
            continuationSummary: 'cont',
            contextSnapshotJson: '{}',
          ),
        );

        final fetched = await repo.getById('ws-1', 'nullable-test');
        expect(fetched!.summary, 'summary text');
        expect(fetched.adapter, 'anthropic');
        expect(fetched.pid, 99999);
        expect(fetched.logPath, '/logs/test.log');
        expect(fetched.liveness, RunLiveness.stalled);
        expect(fetched.errorFamily, RunErrorFamily.budgetExceeded);
        expect(fetched.lastOutputAt, DateTime(2025, 6, 2));
        expect(fetched.continuationSummary, 'cont');
        expect(fetched.contextSnapshotJson, '{}');
      },
    );

    test('run status values round-trip correctly', () async {
      for (final status in RunStatus.values) {
        final id = 'status-${status.name}';
        await repo.upsert(_makeLog(id: id, status: status));
        final fetched = await repo.getById('ws-1', id);
        expect(fetched!.status, status, reason: 'status $status');
      }
    });

    test('retry meta round-trips correctly', () async {
      final log = _makeLog(
        id: 'retry-test',
        retry: const RetryMeta(parentRunId: 'parent-run', attempt: 5),
      );
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'retry-test');
      expect(fetched!.retry.parentRunId, 'parent-run');
      expect(fetched.retry.attempt, 5);
    });

    test('cost with zero values round-trips correctly', () async {
      final log = _makeLog(id: 'zero-cost', cost: RunCost.zero);
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'zero-cost');
      expect(fetched!.cost.inputTokens, 0);
      expect(fetched.cost.outputTokens, 0);
      expect(fetched.cost.estimatedCostCents, 0);
    });

    test('cost with non-zero values round-trips', () async {
      final log = _makeLog(
        id: 'nonzero-cost',
        cost: const RunCost(
          inputTokens: 1000,
          outputTokens: 500,
          estimatedCostCents: 75,
        ),
      );
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'nonzero-cost');
      expect(fetched!.cost.inputTokens, 1000);
      expect(fetched.cost.outputTokens, 500);
      expect(fetched.cost.estimatedCostCents, 75);
    });
  });

  // ── exact cost, latency and verification telemetry ──────────────────────

  group('accounting telemetry round-trip', () {
    test('exact micro-USD cost and its basis survive a write/read', () async {
      final log = _makeLog(
        id: 'exact-cost',
        cost: const RunCost(
          inputTokens: 10,
          estimatedCostCents: 0,
          costMicros: 4321,
          costBasis: CostBasis.subscription,
        ),
      );
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'exact-cost');
      // A sub-cent cost must NOT come back as the rounded cents (0).
      expect(fetched!.cost.costMicros, 4321);
      expect(fetched.cost.estimatedCostCents, 0);
      expect(fetched.cost.costBasis, CostBasis.subscription);
      expect(fetched.cost.preciseCostMicros, 4321);
    });

    test('a legacy cents-only row reads as an estimated cost', () async {
      final log = _makeLog(
        id: 'legacy-cost',
        cost: const RunCost(inputTokens: 5, estimatedCostCents: 12),
      );
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'legacy-cost');
      expect(fetched!.cost.costMicros, 0);
      // Unknown provenance must NOT be read as provider-reported/billed.
      expect(fetched.cost.costBasis, CostBasis.estimated);
      // The cents figure is still authoritative for that historical row.
      expect(fetched.cost.preciseCostMicros, 120000);
    });

    test('child cost micros, effort and task family round-trip', () async {
      final log = _makeLog(
        id: 'hierarchy',
        childCostMicros: 50000,
        effort: 'high',
        taskFamily: 'refactor',
        parentRunId: 'parent-1',
      );
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'hierarchy');
      expect(fetched!.childCostMicros, 50000);
      expect(fetched.effort, 'high');
      expect(fetched.taskFamily, 'refactor');
      // Inclusive total = own exact cost + the propagated rollup.
      expect(fetched.totalCostMicrosWithChildren, 50000);
    });

    test('stage latency profile round-trips exactly', () async {
      final log = _makeLog(
        id: 'latency',
        latency: const RunLatencyProfile({
          RunStage.submitted: RunStageTiming(
            stage: RunStage.submitted,
            offsetMs: 0,
            source: RunTimingSource.harness,
          ),
          RunStage.requestSent: RunStageTiming(
            stage: RunStage.requestSent,
            offsetMs: 300,
            source: RunTimingSource.transport,
            requestId: 'request-1:2',
          ),
          RunStage.firstResponseByte: RunStageTiming(
            stage: RunStage.firstResponseByte,
            offsetMs: 520,
            source: RunTimingSource.transport,
            requestId: 'request-1:2',
          ),
          RunStage.firstUsefulText: RunStageTiming(
            stage: RunStage.firstUsefulText,
            offsetMs: 1500,
            source: RunTimingSource.adapter,
            durationMs: 980,
            provider: 'anthropic',
            modelId: 'claude-opus-4-8',
          ),
        }),
      );
      await repo.upsert(log);

      final fetched = await repo.getById('ws-1', 'latency');
      expect(fetched!.latency.offsetMs(RunStage.firstUsefulText), 1500);
      expect(fetched.latency.durationMs(RunStage.firstUsefulText), 980);
      // The transport-observed byte is what makes a TTFB claim legitimate; it
      // has to survive storage or the claim cannot be re-derived on replay.
      expect(fetched.latency.transportTtfbMs, 220);
      expect(fetched.latency.timeToFirstUsefulWorkMs, 1500);
      expect(
        fetched.latency.timings[RunStage.firstUsefulText]!.provider,
        'anthropic',
      );
    });

    test('a run with no timings stores and reads back as unknown', () async {
      await repo.upsert(_makeLog(id: 'no-timings'));

      final fetched = await repo.getById('ws-1', 'no-timings');
      // Unknown, NOT zero: an empty profile carries no observations at all.
      expect(fetched!.latency.isEmpty, isTrue);
      expect(fetched.latency.offsetMs(RunStage.submitted), isNull);
    });

    test('verification is stored separately from run status', () async {
      await repo.upsert(
        _makeLog(
          id: 'verified',
          status: RunStatus.completed,
          verification: RunVerification(
            status: VerificationStatus.passed,
            verifier: 'behavioral-check',
            verifiedAt: DateTime.utc(2026, 10, 11, 12, 30),
            notes: 'tests green',
          ),
        ),
      );
      await repo.upsert(
        _makeLog(id: 'unverified', status: RunStatus.completed),
      );

      final verified = await repo.getById('ws-1', 'verified');
      expect(verified!.verification.status, VerificationStatus.passed);
      expect(verified.verification.verifier, 'behavioral-check');
      expect(verified.verification.notes, 'tests green');
      expect(verified.isVerifiedSuccess, isTrue);

      final unchecked = await repo.getById('ws-1', 'unverified');
      // A completed run that nothing checked is NOT a verified success.
      expect(unchecked!.verification.status, VerificationStatus.unverified);
      expect(unchecked.isVerifiedSuccess, isFalse);
      expect(unchecked.isCompleted, isTrue);
    });

    test('native session lineage round-trips as data', () async {
      await repo.upsert(
        _makeLog(
          id: 'resumed',
          nativeSessionId: 'sess-abc',
          resumedNativeSession: true,
        ),
      );
      await repo.upsert(_makeLog(id: 'fresh'));

      final resumed = await repo.getById('ws-1', 'resumed');
      expect(resumed!.nativeSessionId, 'sess-abc');
      expect(resumed.resumedNativeSession, isTrue);

      // A run with no native session must not read back as "resumed".
      final fresh = await repo.getById('ws-1', 'fresh');
      expect(fresh!.nativeSessionId, isNull);
      expect(fresh.resumedNativeSession, isFalse);
    });

    test('a failed verification on a completed run is preserved', () async {
      await repo.upsert(
        _makeLog(
          id: 'rejected',
          verification: const RunVerification(
            status: VerificationStatus.failed,
            verifier: 'behavioral-check',
          ),
        ),
      );

      final fetched = await repo.getById('ws-1', 'rejected');
      expect(fetched!.verification.status, VerificationStatus.failed);
      expect(fetched.isCompleted, isTrue);
      expect(fetched.isVerifiedSuccess, isFalse);
    });
  });

  group('atomic cost writes', () {
    test('concurrent siblings accumulate sub-cent spend exactly', () async {
      await repo.upsert(_makeLog(status: RunStatus.running));
      await Future.wait([
        for (var i = 0; i < 40; i++)
          repo.addChildCostMicros('ws-1', 'log-1', 375),
      ]);
      final row = (await repo.getById('ws-1', 'log-1'))!;
      expect(row.childCostMicros, 15000);
      expect(row.childCostCents, 2);
      expect(row.status, RunStatus.running);
    });

    test('first increment widens legacy cents before adding micros', () async {
      await repo.upsert(_makeLog(status: RunStatus.running));
      await dbs
          .of('ws-1')
          .agentDao
          .updateLogCost(
            'ws-1',
            'log-1',
            const AgentRunLogsTableCompanion(childCostCents: Value(7)),
          );
      await repo.addChildCostMicros('ws-1', 'log-1', 5500);
      final row = (await repo.getById('ws-1', 'log-1'))!;
      expect(row.childCostMicros, 75500);
      expect(row.childCostCents, 8);
    });

    test(
      'own cost update preserves rollup, terminal state and metadata',
      () async {
        final original = _makeLog(
          status: RunStatus.completed,
          completedAt: DateTime.utc(2025, 6, 2),
          summary: 'answer',
          logPath: '/runs/log.ndjson',
          childCostMicros: 15001,
          nativeSessionId: 'thread-1',
        );
        await repo.upsert(original);
        await repo.updateCost(
          'ws-1',
          'log-1',
          const RunCost(
            inputTokens: 45,
            outputTokens: 9,
            estimatedCostCents: 3,
            costMicros: 25125,
            durationMs: 321,
          ),
        );
        final row = (await repo.getById('ws-1', 'log-1'))!;
        expect(row.cost.inputTokens, 45);
        expect(row.cost.costMicros, 25125);
        expect(row.cost.durationMs, 321);
        expect(row.childCostMicros, 15001);
        expect(row.status, RunStatus.completed);
        expect(row.completedAt?.toUtc(), original.completedAt);
        expect(row.summary, 'answer');
        expect(row.logPath, '/runs/log.ndjson');
        expect(row.nativeSessionId, 'thread-1');
      },
    );

    test('terminal write racing child increments never loses rollup', () async {
      final original = _makeLog(
        status: RunStatus.running,
        summary: 'in flight',
      );
      await repo.upsert(original);
      final terminal = original.copyWith(
        status: RunStatus.completed,
        completedAt: DateTime.utc(2025, 6, 2),
        summary: 'done',
        cost: const RunCost(inputTokens: 4, costMicros: 123),
      );
      await Future.wait([
        repo.completeIfActive(terminal).then((_) {}),
        for (var i = 0; i < 32; i++)
          repo.addChildCostMicros('ws-1', 'log-1', 777),
      ]);
      final row = (await repo.getById('ws-1', 'log-1'))!;
      expect(row.childCostMicros, 24864);
      expect(row.childCostCents, 2);
      expect(row.status, RunStatus.completed);
      expect(row.summary, 'done');
      expect(row.cost.inputTokens, 4);
      expect(await repo.completeIfActive(terminal), isFalse);
    });

    test(
      'runtime metadata writes never replace own or descendant spend',
      () async {
        await repo.upsert(
          _makeLog(status: RunStatus.pending, summary: 'initial'),
        );
        await Future.wait([
          repo
              .updateRuntime('ws-1', 'log-1', pid: 76, markRunning: true)
              .then((_) {}),
          repo
              .updateRuntime(
                'ws-1',
                'log-1',
                logPath: '/runs/log.ndjson',
                contextSnapshotJson: '{"tools":["read"]}',
                lastOutputAt: DateTime.utc(2025, 6, 1, 2),
                modelId: 'model-a',
                effort: 'high',
                taskFamily: 'repair',
              )
              .then((_) {}),
          repo.updateCost(
            'ws-1',
            'log-1',
            const RunCost(inputTokens: 34, costMicros: 1350),
          ),
          for (var i = 0; i < 12; i++)
            repo.addChildCostMicros('ws-1', 'log-1', 750),
        ]);
        final row = (await repo.getById('ws-1', 'log-1'))!;
        expect(row.status, RunStatus.running);
        expect(row.pid, 76);
        expect(row.logPath, '/runs/log.ndjson');
        expect(row.contextSnapshotJson, '{"tools":["read"]}');
        expect(row.lastOutputAt?.toUtc(), DateTime.utc(2025, 6, 1, 2));
        expect(row.modelId, 'model-a');
        expect(row.effort, 'high');
        expect(row.taskFamily, 'repair');
        expect(row.summary, 'initial');
        expect(row.cost.inputTokens, 34);
        expect(row.cost.costMicros, 1350);
        expect(row.childCostMicros, 9000);
        expect(row.childCostCents, 1);
      },
    );

    test(
      'runtime start cannot revive terminal or already started runs',
      () async {
        final original = _makeLog(status: RunStatus.pending);
        await repo.upsert(original);
        expect(
          await repo.updateRuntime('ws-1', 'log-1', markRunning: true),
          true,
        );
        expect(
          await repo.updateRuntime('ws-1', 'log-1', markRunning: true, pid: 20),
          true,
        );
        expect((await repo.getById('ws-1', 'log-1'))!.pid, 20);
        await repo.completeIfActive(
          original.copyWith(
            status: RunStatus.completed,
            completedAt: DateTime.utc(2025, 6, 2),
          ),
        );
        expect(
          await repo.updateRuntime('ws-1', 'log-1', markRunning: true),
          false,
        );
        expect(
          await repo.updateRuntime(
            'ws-1',
            'log-1',
            markRunning: true,
            logPath: '/runs/late.ndjson',
            lastOutputAt: DateTime.utc(2025, 6, 2, 1),
            summary: 'terminal diagnosis',
          ),
          true,
        );
        final completed = (await repo.getById('ws-1', 'log-1'))!;
        expect(completed.status, RunStatus.completed);
        expect(completed.summary, 'terminal diagnosis');
        expect(completed.logPath, '/runs/late.ndjson');
        expect(completed.lastOutputAt?.toUtc(), DateTime.utc(2025, 6, 2, 1));
      },
    );

    test(
      'workspace scope and absent rows are harmless, invalid id fails',
      () async {
        await repo.upsert(_makeLog(status: RunStatus.running));
        await repo.addChildCostMicros('ws-2', 'log-1', 15000);
        await repo.updateCost('ws-2', 'log-1', const RunCost(inputTokens: 10));
        expect(
          await repo.completeIfActive(
            _makeLog(
              workspaceId: 'ws-2',
              status: RunStatus.completed,
              completedAt: DateTime.utc(2025, 6, 2),
            ),
          ),
          isFalse,
        );
        expect(
          await repo.updateRuntime('ws-2', 'log-1', summary: 'foreign'),
          false,
        );
        expect((await repo.getById('ws-1', 'log-1'))!.childCostMicros, 0);
        expect(
          (await repo.getById('ws-1', 'log-1'))!.status,
          RunStatus.running,
        );
        await repo.addChildCostMicros('ws-1', 'absent', 1);
        await repo.updateCost('ws-1', 'absent', RunCost.zero);
        expect(await repo.updateRuntime('ws-1', 'absent', pid: 30), false);
        await expectLater(
          repo.updateCost('../escape', 'log-1', RunCost.zero),
          throwsArgumentError,
        );
        await expectLater(
          repo.addChildCostMicros('../escape', 'log-1', 1),
          throwsArgumentError,
        );
        await expectLater(
          repo.updateRuntime('../escape', 'log-1', summary: 'invalid'),
          throwsArgumentError,
        );
        await expectLater(
          repo.completeIfActive(
            _makeLog(workspaceId: null, status: RunStatus.completed),
          ),
          throwsArgumentError,
        );
      },
    );
  });

  // ── run status helpers on entity ────────────────────────────────────────

  group('AgentRunLog computed properties', () {
    test('isRunning', () {
      expect(_makeLog(status: RunStatus.running).isRunning, isTrue);
      expect(_makeLog(status: RunStatus.pending).isRunning, isFalse);
      expect(_makeLog(status: RunStatus.completed).isRunning, isFalse);
    });

    test('isActive', () {
      expect(_makeLog(status: RunStatus.pending).isActive, isTrue);
      expect(_makeLog(status: RunStatus.running).isActive, isTrue);
      expect(_makeLog(status: RunStatus.completed).isActive, isFalse);
      expect(_makeLog(status: RunStatus.error).isActive, isFalse);
    });

    test('isCompleted', () {
      expect(_makeLog(status: RunStatus.completed).isCompleted, isTrue);
      expect(_makeLog(status: RunStatus.running).isCompleted, isFalse);
    });

    test('isError', () {
      expect(_makeLog(status: RunStatus.error).isError, isTrue);
      expect(_makeLog(status: RunStatus.completed).isError, isFalse);
    });
  });
}
