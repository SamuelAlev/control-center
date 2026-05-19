import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoAgentGoalRunRepository] end-to-end against an in-memory
/// database. Covers every repository method (getById, listByWorkspace,
/// listActive, getActiveForAgent, upsert) through the domain [AgentGoalRun]
/// entity and the goal-run mapper, including the persisted wire names for
/// every [AgentGoalStatus] and the workspace-isolation rules.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoAgentGoalRunRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoAgentGoalRunRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  AgentGoalRun goal({
    String id = 'goal-1',
    String workspaceId = 'w-1',
    String spaceId = 'ch-1',
    String conversationId = 'conv-1',
    String agentId = 'agent-1',
    String userText = 'Ship the feature',
    AgentGoalKind kind = AgentGoalKind.goal,
    AgentGoalStatus status = AgentGoalStatus.active,
    DateTime? deadlineAt,
    int costCapCents = 5000,
    int costCents = 0,
    int maxRuns = 100,
    bool uncapped = false,
    int runCount = 0,
    String? activeRunId,
    int consecutiveFailures = 0,
    String? requestedByUserId,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AgentGoalRun(
    id: id,
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    agentId: agentId,
    userText: userText,
    kind: kind,
    status: status,
    deadlineAt: uncapped ? null : (deadlineAt ?? DateTime(2026, 8, 1)),
    costCapCents: costCapCents,
    costCents: costCents,
    maxRuns: uncapped ? null : maxRuns,
    runCount: runCount,
    activeRunId: activeRunId,
    consecutiveFailures: consecutiveFailures,
    requestedByUserId: requestedByUserId,
    summary: summary,
    createdAt: createdAt ?? DateTime(2026),
    updatedAt: updatedAt ?? DateTime(2026),
  );

  group('upsert + read round-trip', () {
    test('getById returns null when absent', () async {
      expect(await repo.getById('w-1', 'missing'), isNull);
    });

    test('upsert then getById round-trips every field', () async {
      await repo.upsert(
        goal(
          kind: AgentGoalKind.loop,
          costCents: 1250,
          runCount: 7,
          activeRunId: 'run-9',
          consecutiveFailures: 2,
          requestedByUserId: 'user-1',
          summary: 'halfway there',
        ),
      );
      final loaded = await repo.getById('w-1', 'goal-1');
      expect(loaded, isNotNull);
      expect(loaded!.id, 'goal-1');
      expect(loaded.workspaceId, 'w-1');
      expect(loaded.spaceId, 'ch-1');
      expect(loaded.conversationId, 'conv-1');
      expect(loaded.agentId, 'agent-1');
      expect(loaded.userText, 'Ship the feature');
      expect(loaded.kind, AgentGoalKind.loop);
      expect(loaded.status, AgentGoalStatus.active);
      expect(loaded.deadlineAt, DateTime(2026, 8, 1));
      expect(loaded.costCapCents, 5000);
      expect(loaded.costCents, 1250);
      expect(loaded.maxRuns, 100);
      expect(loaded.runCount, 7);
      expect(loaded.activeRunId, 'run-9');
      expect(loaded.consecutiveFailures, 2);
      expect(loaded.requestedByUserId, 'user-1');
      expect(loaded.summary, 'halfway there');
      expect(loaded.createdAt, DateTime(2026));
      expect(loaded.updatedAt, DateTime(2026));
    });

    test('an uncapped goal round-trips null walls', () async {
      await repo.upsert(goal(uncapped: true));
      final loaded = await repo.getById('w-1', 'goal-1');
      expect(loaded, isNotNull);
      expect(loaded!.deadlineAt, isNull);
      expect(loaded.maxRuns, isNull);
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await repo.upsert(goal(userText: 'first'));
      await repo.upsert(
        goal(userText: 'second', status: AgentGoalStatus.paused, runCount: 3),
      );
      final loaded = await repo.getById('w-1', 'goal-1');
      expect(loaded?.userText, 'second');
      expect(loaded?.status, AgentGoalStatus.paused);
      expect(loaded?.runCount, 3);
      expect(await repo.listByWorkspace('w-1'), hasLength(1));
    });
  });

  group('wire-name mapping', () {
    test('every status round-trips through its wire name', () async {
      for (final status in AgentGoalStatus.values) {
        final id = 'goal-${status.wire}';
        await repo.upsert(goal(id: id, status: status));
        expect((await repo.getById('w-1', id))?.status, status);
      }
    });

    test('budget_exhausted persists as the snake-case wire name', () async {
      await repo.upsert(
        goal(id: 'goal-be', status: AgentGoalStatus.budgetExhausted),
      );
      final raw = await dbs
          .of('w-1')
          .customSelect(
            "SELECT status FROM agent_goal_runs WHERE id = 'goal-be'",
          )
          .getSingle();
      expect(raw.read<String>('status'), 'budget_exhausted');
      expect(
        (await repo.getById('w-1', 'goal-be'))?.status,
        AgentGoalStatus.budgetExhausted,
      );
    });

    test('kind wire names round-trip (goal / loop)', () async {
      await repo.upsert(goal(id: 'goal-g', kind: AgentGoalKind.goal));
      await repo.upsert(goal(id: 'goal-l', kind: AgentGoalKind.loop));
      expect((await repo.getById('w-1', 'goal-g'))?.kind, AgentGoalKind.goal);
      expect((await repo.getById('w-1', 'goal-l'))?.kind, AgentGoalKind.loop);
    });
  });

  group('workspace isolation', () {
    test('getById does not find a foreign-workspace id', () async {
      await repo.upsert(goal(id: 'goal-1', workspaceId: 'w-1'));
      expect(await repo.getById('w-2', 'goal-1'), isNull);
    });

    test(
      'watchByWorkspace emits only the workspace rows, newest first',
      () async {
        await repo.upsert(goal(id: 'goal-1'));
        await repo.upsert(goal(id: 'goal-2', createdAt: DateTime.utc(2026, 2)));
        await repo.upsert(goal(id: 'goal-3', workspaceId: 'w-2'));
        final rows = await repo.watchByWorkspace('w-1').first;
        expect(rows.map((g) => g.id), ['goal-2', 'goal-1']);
      },
    );

    test(
      'listByWorkspace returns only the workspace rows, newest first',
      () async {
        await repo.upsert(goal(id: 'goal-1', createdAt: DateTime(2026)));
        await repo.upsert(goal(id: 'goal-2', createdAt: DateTime(2026, 2)));
        await repo.upsert(goal(id: 'goal-3', workspaceId: 'w-2'));
        final rows = await repo.listByWorkspace('w-1');
        expect(rows.map((g) => g.id), ['goal-2', 'goal-1']);
      },
    );

    test('getActiveForAgent does not leak across workspaces', () async {
      await repo.upsert(goal(id: 'goal-1', workspaceId: 'w-1'));
      expect(await repo.getActiveForAgent('w-2', 'agent-1'), isNull);
    });
  });

  group('listActive (documented cross-workspace exception)', () {
    test('returns active goals across ALL workspaces', () async {
      await repo.upsert(goal(id: 'goal-1', workspaceId: 'w-1'));
      await repo.upsert(
        goal(id: 'goal-2', workspaceId: 'w-2', agentId: 'agent-2'),
      );
      final active = await repo.listActive();
      expect(active.map((g) => g.id), containsAll(['goal-1', 'goal-2']));
    });

    test('excludes every terminal and paused status', () async {
      var i = 0;
      for (final status in AgentGoalStatus.values) {
        await repo.upsert(goal(id: 'goal-${i++}', status: status));
      }
      final active = await repo.listActive();
      expect(active, hasLength(1));
      expect(active.single.status, AgentGoalStatus.active);
    });
  });

  group('getActiveForAgent', () {
    test('returns only the active goal for the agent', () async {
      await repo.upsert(
        goal(id: 'goal-done', status: AgentGoalStatus.completed),
      );
      await repo.upsert(
        goal(id: 'goal-failed', status: AgentGoalStatus.failed),
      );
      await repo.upsert(goal(id: 'goal-live'));
      await repo.upsert(goal(id: 'goal-other', agentId: 'agent-2'));
      final loaded = await repo.getActiveForAgent('w-1', 'agent-1');
      expect(loaded?.id, 'goal-live');
    });

    test('returns null when the agent has no active goal', () async {
      await repo.upsert(
        goal(id: 'goal-done', status: AgentGoalStatus.completed),
      );
      expect(await repo.getActiveForAgent('w-1', 'agent-1'), isNull);
    });
  });
}
