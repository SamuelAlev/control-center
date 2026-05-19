import 'package:cc_domain/features/governance/domain/entities/agent_runtime_state.dart';
import 'package:cc_domain/features/governance/domain/value_objects/heartbeat_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/agent_runtime_state_mapper.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoAgentRuntimeStateRepository] and [AgentRuntimeStateMapper]
/// against in-memory per-workspace databases. Covers every repository method
/// (watch, list, get, upsert, delete) and the full mapper round-trip (domain ↔
/// row ↔ companion), including the `listAll` fan-out that now has to open every
/// registered workspace's file.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late AgentRuntimeStateMapper mapper;
  late DaoAgentRuntimeStateRepository repo;

  /// Inserts the parent agent row into [workspaceId]'s own database, satisfying
  /// the `agent_runtime_state` → `agents` FK.
  Future<void> seedAgent(
    String workspaceId,
    String agentId,
    String name,
  ) async {
    final db = dbs.of(workspaceId);
    await db
        .into(db.agentsTable)
        .insert(
          AgentsTableCompanion.insert(
            id: agentId,
            name: name,
            title: name,
            agentMdPath: '/a/$agentId.md',
            workspaceId: workspaceId,
            skills: '',
          ),
        );
  }

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // Both workspaces are REGISTERED: `listAll` fans out over the registry.
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    mapper = const AgentRuntimeStateMapper();
    repo = DaoAgentRuntimeStateRepository(dbs);
    await seedAgent('w-1', 'a-1', 'Agent One');
    await seedAgent('w-2', 'a-2', 'Agent Two');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  AgentRuntimeState state({
    String agentId = 'a-1',
    String workspaceId = 'w-1',
    HeartbeatStatus status = HeartbeatStatus.alive,
    DateTime? lastHeartbeatAt,
    String? currentRunId,
    String? note,
  }) => AgentRuntimeState(
    agentId: agentId,
    workspaceId: workspaceId,
    reportedStatus: status,
    lastHeartbeatAt: lastHeartbeatAt,
    currentRunId: currentRunId,
    note: note,
    updatedAt: DateTime(2026, 1, 1),
  );

  group('AgentRuntimeStateMapper round-trip', () {
    test('toCompanion → upsert → mapper toDomain is lossless', () async {
      final original = state(
        status: HeartbeatStatus.stuck,
        lastHeartbeatAt: DateTime(2026, 1, 2, 3, 4, 5),
        currentRunId: 'run-9',
        note: 'wedged on lint',
      );
      await repo.upsert(original);
      final loaded = await repo.getForAgent('w-1', 'a-1');
      expect(loaded, isNotNull);
      expect(loaded!.agentId, 'a-1');
      expect(loaded.workspaceId, 'w-1');
      expect(loaded.reportedStatus, HeartbeatStatus.stuck);
      expect(loaded.currentRunId, 'run-9');
      expect(loaded.note, 'wedged on lint');
    });

    test('toDomainList maps many rows', () {
      final rows = [
        AgentRuntimeStateTableData(
          agentId: 'a-1',
          workspaceId: 'w-1',
          reportedStatus: 'alive',
          lastHeartbeatAt: null,
          currentRunId: null,
          note: null,
          updatedAt: DateTime(2026, 1, 1),
        ),
        AgentRuntimeStateTableData(
          agentId: 'a-2',
          workspaceId: 'w-2',
          reportedStatus: 'idle',
          lastHeartbeatAt: DateTime(2026, 1, 2),
          currentRunId: 'run-2',
          note: 'waiting',
          updatedAt: DateTime(2026, 1, 3),
        ),
      ];
      final list = mapper.toDomainList(rows);
      expect(list, hasLength(2));
      expect(list.first.reportedStatus, HeartbeatStatus.alive);
      expect(list.last.reportedStatus, HeartbeatStatus.idle);
      expect(list.last.note, 'waiting');
    });

    test('toDomain reconstructs offline status from unknown storage value', () {
      final row = AgentRuntimeStateTableData(
        agentId: 'a-9',
        workspaceId: 'w-1',
        reportedStatus: 'not-a-real-status',
        lastHeartbeatAt: null,
        currentRunId: null,
        note: null,
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(mapper.toDomain(row).reportedStatus, HeartbeatStatus.offline);
    });
  });

  // Each workspace is its own database file, so these now prove that the
  // repository ROUTES by workspace id (upsert reads it off the entity, reads
  // take it as a parameter) on top of the DAO's `WHERE workspace_id = ?`.
  group('DaoAgentRuntimeStateRepository workspace isolation', () {
    test('listByWorkspace returns only the workspace rows', () async {
      await repo.upsert(state(agentId: 'a-1', workspaceId: 'w-1'));
      await repo.upsert(state(agentId: 'a-2', workspaceId: 'w-2'));
      final rows = await repo.listByWorkspace('w-1');
      expect(rows, hasLength(1));
      expect(rows.first.agentId, 'a-1');
    });

    test('watchByWorkspace emits only the workspace rows', () async {
      await repo.upsert(state(agentId: 'a-1', workspaceId: 'w-1'));
      await repo.upsert(state(agentId: 'a-2', workspaceId: 'w-2'));
      final rows = await repo.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.agentId, 'a-1');
    });

    test('getForAgent returns null for a foreign workspace', () async {
      await repo.upsert(state(agentId: 'a-1', workspaceId: 'w-1'));
      expect(await repo.getForAgent('w-2', 'a-1'), isNull);
      expect(await repo.getForAgent('w-1', 'a-1'), isNotNull);
      expect(await repo.getForAgent('w-1', 'missing'), isNull);
    });

    test('upsert replaces on conflict (same agentId PK)', () async {
      await repo.upsert(state(note: 'first'));
      await repo.upsert(state(note: 'second'));
      final loaded = await repo.getForAgent('w-1', 'a-1');
      expect(loaded?.note, 'second');
    });
  });

  group('DaoAgentRuntimeStateRepository cross-workspace + delete', () {
    test('listAll returns rows across every workspace', () async {
      await repo.upsert(state(agentId: 'a-1', workspaceId: 'w-1'));
      await repo.upsert(state(agentId: 'a-2', workspaceId: 'w-2'));
      final all = await repo.listAll();
      expect(all.map((s) => s.agentId).toSet(), {'a-1', 'a-2'});
    });

    test('delete is scoped by workspace', () async {
      await repo.upsert(state(agentId: 'a-1', workspaceId: 'w-1'));
      // delete from the wrong workspace is a no-op.
      await repo.delete('w-2', 'a-1');
      expect(await repo.getForAgent('w-1', 'a-1'), isNotNull);
      // delete from the right workspace removes the row.
      await repo.delete('w-1', 'a-1');
      expect(await repo.getForAgent('w-1', 'a-1'), isNull);
    });
  });
}
