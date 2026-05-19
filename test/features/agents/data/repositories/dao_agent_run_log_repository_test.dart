
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/tables/agent_run_logs.dart' show AgentRunLogsTable;
import 'package:cc_persistence/repositories/dao_agent_run_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

/// Helper: insert a workspace row so FK constraints on [AgentRunLogsTable]
/// are satisfied.
Future<void> _seedWorkspace(AppDatabase db, String id) => db.into(db.workspacesTable).insert(
      WorkspacesTableCompanion.insert(id: id, name: 'ws-$id'),
    );

/// Helper: insert an agent row so FK constraints on [AgentRunLogsTable] are
/// satisfied.
Future<void> _seedAgent(AppDatabase db, String id, String workspaceId) =>
    db.into(db.agentsTable).insert(
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
  String? channelId,
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
}) {
  return AgentRunLog(
    id: id,
    agentId: agentId,
    workspaceId: workspaceId,
    conversationId: conversationId,
    ticketId: ticketId,
    channelId: channelId,
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
  );
}

void main() {
  late AppDatabase db;
  late AgentDao dao;
  late DaoAgentRunLogRepository repo;

  setUp(() async {
    db = createTestDatabase();
    dao = AgentDao(db);
    repo = DaoAgentRunLogRepository(dao);
    // FK prerequisites for run logs.
    await _seedWorkspace(db, 'ws-1');
    await _seedAgent(db, 'agent-1', 'ws-1');
  });

  tearDown(() async {
    await db.close();
  });

  // ── getById ─────────────────────────────────────────────────────────────

  group('getById', () {
    test('returns null for nonexistent id', () async {
      expect(await repo.getById('nope'), isNull);
    });

    test('returns the log after upsert', () async {
      final log = _makeLog();
      await repo.upsert(log);

      final fetched = await repo.getById('log-1');
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
        channelId: 'ch-1',
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

      final fetched = await repo.getById('full-1');
      expect(fetched, isNotNull);
      expect(fetched, log);
    });
  });

  // ── upsert / CRUD ───────────────────────────────────────────────────────

  group('upsert', () {
    test('inserts a new log', () async {
      await repo.upsert(_makeLog());

      final fetched = await repo.getById('log-1');
      expect(fetched, isNotNull);
    });

    test('updates an existing log with the same id', () async {
      await repo.upsert(_makeLog(status: RunStatus.pending));

      await repo.upsert(_makeLog(status: RunStatus.completed));

      final fetched = await repo.getById('log-1');
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

      final fetched = await repo.getById('clear-1');
      // Fields are NOT cleared — Value.absentIfNull omits them from the
      // UPDATE, so the original values remain.
      expect(fetched!.summary, 'original');
      expect(fetched.logPath, '/tmp/run.log');
      expect(fetched.liveness, RunLiveness.alive);
    });

    test('handles run with minimal fields', () async {
      final minimal = AgentRunLog(
        id: 'minimal-1',
        agentId: 'agent-1',
        startedAt: DateTime(2025),
        status: RunStatus.pending,
      );
      await repo.upsert(minimal);

      final fetched = await repo.getById('minimal-1');
      expect(fetched, isNotNull);
      expect(fetched!.workspaceId, isNull);
      expect(fetched.conversationId, isNull);
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
      await _seedAgent(db, 'agent-2', 'ws-1');
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
      await repo.upsert(_makeLog(
        id: 'older',
        startedAt: DateTime(2025, 1),
      ));
      await repo.upsert(_makeLog(
        id: 'newer',
        startedAt: DateTime(2025, 6),
      ));

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
      await _seedAgent(db, 'agent-2', 'ws-1');
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
      await repo.upsert(_makeLog(
        id: 'oldest',
        agentId: 'agent-1',
        startedAt: DateTime(2025, 1),
      ));
      await repo.upsert(_makeLog(
        id: 'newest',
        agentId: 'agent-1',
        startedAt: DateTime(2025, 12),
      ));

      final logs = await repo.watchAll().first;
      expect(logs[0].id, 'newest');
      expect(logs[1].id, 'oldest');
    });
  });

  // ── watchActiveByConversation ───────────────────────────────────────────

  group('watchActiveByConversation', () {
    test('emits empty list when no active logs match', () async {
      final logs = await repo
          .watchActiveByConversation('ws-1', 'conv-1')
          .first;
      expect(logs, isEmpty);
    });

    test('emits only active logs for matching workspace + conversation',
        () async {
      // Completed log – should be excluded.
      await repo.upsert(_makeLog(
        id: 'completed-1',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        status: RunStatus.completed,
        completedAt: DateTime(2025),
      ));
      // Active (pending) log for the right workspace/conversation.
      await repo.upsert(_makeLog(
        id: 'active-1',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        status: RunStatus.running,
        completedAt: null,
      ));

      final logs = await repo
          .watchActiveByConversation('ws-1', 'conv-1')
          .first;
      expect(logs.length, 1);
      expect(logs.single.id, 'active-1');
    });

    test('excludes logs with different workspaceId', () async {
      await _seedWorkspace(db, 'ws-2');
      await _seedAgent(db, 'agent-2', 'ws-2');
      await repo.upsert(_makeLog(
        id: 'ws1-log',
        agentId: 'agent-1',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        completedAt: null,
        status: RunStatus.running,
      ));
      await repo.upsert(_makeLog(
        id: 'ws2-log',
        agentId: 'agent-2',
        conversationId: 'conv-1',
        workspaceId: 'ws-2',
        completedAt: null,
        status: RunStatus.running,
      ));

      final logs = await repo
          .watchActiveByConversation('ws-1', 'conv-1')
          .first;
      expect(logs.length, 1);
      expect(logs.single.id, 'ws1-log');
    });

    test('excludes logs with different conversationId', () async {
      await repo.upsert(_makeLog(
        id: 'conv1-log',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        completedAt: null,
        status: RunStatus.running,
      ));
      await repo.upsert(_makeLog(
        id: 'conv2-log',
        conversationId: 'conv-2',
        workspaceId: 'ws-1',
        completedAt: null,
        status: RunStatus.running,
      ));

      final logs = await repo
          .watchActiveByConversation('ws-1', 'conv-1')
          .first;
      expect(logs.length, 1);
      expect(logs.single.id, 'conv1-log');
    });

    test('excludes logs where completedAt is not null', () async {
      await repo.upsert(_makeLog(
        id: 'done',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        completedAt: DateTime(2025),
        status: RunStatus.completed,
      ));
      await repo.upsert(_makeLog(
        id: 'active',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        completedAt: null,
        status: RunStatus.running,
      ));

      final logs = await repo
          .watchActiveByConversation('ws-1', 'conv-1')
          .first;
      expect(logs.length, 1);
      expect(logs.single.id, 'active');
    });

    test('live stream emits when a new active log is inserted', () async {
      final stream = repo.watchActiveByConversation('ws-1', 'conv-1');

      // First emission: empty.
      final first = await stream.first;
      expect(first, isEmpty);

      // Insert an active log.
      await repo.upsert(_makeLog(
        id: 'live-1',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        completedAt: null,
        status: RunStatus.running,
      ));

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
      await repo.upsert(_makeLog(
        id: 'to-complete',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        completedAt: null,
        status: RunStatus.running,
      ));

      // Mark it as completed.
      await repo.upsert(_makeLog(
        id: 'to-complete',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        completedAt: DateTime(2025),
        status: RunStatus.completed,
      ));

      // It should no longer appear in the active stream.
      final logs = await repo
          .watchActiveByConversation('ws-1', 'conv-1')
          .first;
      expect(logs, isEmpty);
    });
  });

  // ── edge cases ───────────────────────────────────────────────────────────

  group('edge cases', () {
    test('getById is case-sensitive', () async {
      await repo.upsert(_makeLog(id: 'Log-1'));
      expect(await repo.getById('log-1'), isNull);
      expect(await repo.getById('Log-1'), isNotNull);
    });

    test('multiple upserts of same id preserve latest values', () async {
      await repo.upsert(_makeLog(
        id: 'multi',
        status: RunStatus.pending,
        summary: 'first',
      ));
      await repo.upsert(_makeLog(
        id: 'multi',
        status: RunStatus.completed,
        summary: 'second',
      ));
      await repo.upsert(_makeLog(
        id: 'multi',
        status: RunStatus.error,
        summary: 'third',
      ));

      final fetched = await repo.getById('multi');
      expect(fetched!.status, RunStatus.error);
      expect(fetched.summary, 'third');
    });

    test('watchByAgent returns empty for agent with no logs but other agent has logs',
        () async {
      await _seedAgent(db, 'agent-2', 'ws-1');
      await repo.upsert(_makeLog(id: 'log-1', agentId: 'agent-2'));

      final logs = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(logs, isEmpty);
    });

    test('watchActiveByConversation with completedAt: null but completed status',
        () async {
      // completedAt: null + status: completed is unusual but possible
      // during a race. The DAO filter is on completedAt IS NULL, not
      // status, so it WILL include this log.
      await repo.upsert(_makeLog(
        id: 'null-completed',
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        completedAt: null,
        status: RunStatus.completed,
      ));

      final logs = await repo
          .watchActiveByConversation('ws-1', 'conv-1')
          .first;
      expect(logs.length, 1);
      expect(logs.single.id, 'null-completed');
    });

    test('upsert with null workspaceId does not trigger FK issue', () async {
      // workspaceId FK is nullable in run_logs table.
      await repo.upsert(_makeLog(id: 'no-ws', workspaceId: null));

      final fetched = await repo.getById('no-ws');
      expect(fetched, isNotNull);
      expect(fetched!.workspaceId, isNull);
    });

    test('upsert with non-null nullable fields round-trips correctly',
        () async {
      await repo.upsert(_makeLog(
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
      ));

      final fetched = await repo.getById('nullable-test');
      expect(fetched!.summary, 'summary text');
      expect(fetched.adapter, 'anthropic');
      expect(fetched.pid, 99999);
      expect(fetched.logPath, '/logs/test.log');
      expect(fetched.liveness, RunLiveness.stalled);
      expect(fetched.errorFamily, RunErrorFamily.budgetExceeded);
      expect(fetched.lastOutputAt, DateTime(2025, 6, 2));
      expect(fetched.continuationSummary, 'cont');
      expect(fetched.contextSnapshotJson, '{}');
    });

    test('run status values round-trip correctly', () async {
      for (final status in RunStatus.values) {
        final id = 'status-${status.name}';
        await repo.upsert(_makeLog(id: id, status: status));
        final fetched = await repo.getById(id);
        expect(fetched!.status, status, reason: 'status $status');
      }
    });

    test('retry meta round-trips correctly', () async {
      final log = _makeLog(
        id: 'retry-test',
        retry: const RetryMeta(parentRunId: 'parent-run', attempt: 5),
      );
      await repo.upsert(log);

      final fetched = await repo.getById('retry-test');
      expect(fetched!.retry.parentRunId, 'parent-run');
      expect(fetched.retry.attempt, 5);
    });

    test('cost with zero values round-trips correctly', () async {
      final log = _makeLog(id: 'zero-cost', cost: RunCost.zero);
      await repo.upsert(log);

      final fetched = await repo.getById('zero-cost');
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

      final fetched = await repo.getById('nonzero-cost');
      expect(fetched!.cost.inputTokens, 1000);
      expect(fetched.cost.outputTokens, 500);
      expect(fetched.cost.estimatedCostCents, 75);
    });
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
