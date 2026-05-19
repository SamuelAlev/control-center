import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoAgentWorkingMemoryRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // A workspace is a database FILE now, so there is no `workspaces` row to
    // seed inside it; registering it is what makes it addressable.
    await seedTestWorkspace(global, dbs, 'ws1');
    await seedTestWorkspace(global, dbs, 'ws2');
    repo = DaoAgentWorkingMemoryRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  /// Inserts the parent agent row into [workspaceId]'s own database, satisfying
  /// the `agent_working_memory` → `agents` FK.
  Future<void> seedAgent(String id, String workspaceId) {
    final db = dbs.of(workspaceId);
    return db
        .into(db.agentsTable)
        .insert(
          AgentsTableCompanion.insert(
            id: id,
            workspaceId: workspaceId,
            name: 'agent-$id',
            title: 'Agent $id',
            agentMdPath: '/tmp/$id.md',
            skills: '[]',
          ),
        );
  }

  test('upsert then getByAgent returns the working memory', () async {
    await seedAgent('agent1', 'ws1');

    final memory = AgentWorkingMemory(
      id: 'wm1',
      workspaceId: 'ws1',
      agentId: 'agent1',
      content: 'Remember: user likes short answers',
      updatedAt: DateTime(2025, 6, 1),
    );

    await repo.upsert(memory);

    final retrieved = await repo.getByAgent('ws1', 'agent1');
    expect(retrieved, isNotNull);
    expect(retrieved!.id, 'wm1');
    expect(retrieved.content, 'Remember: user likes short answers');
    expect(retrieved.agentId, 'agent1');
  });

  test('getByAgent returns null for missing agent', () async {
    final result = await repo.getByAgent('ws1', 'nonexistent');
    expect(result, isNull);
  });

  /// `upsert` reads the workspace off the entity and `getByAgent` takes it as a
  /// parameter, so this now proves the repository ROUTES to the right database
  /// file on top of the DAO's `WHERE workspace_id = ?`.
  test('getByAgent returns null for wrong workspace', () async {
    await seedAgent('agent1', 'ws1');

    final memory = AgentWorkingMemory(
      id: 'wm1',
      workspaceId: 'ws1',
      agentId: 'agent1',
      content: 'test',
      updatedAt: DateTime(2025),
    );
    await repo.upsert(memory);

    final result = await repo.getByAgent('ws2', 'agent1');
    expect(result, isNull);
  });

  test('upsert overwrites existing working memory', () async {
    await seedAgent('agent1', 'ws1');

    final original = AgentWorkingMemory(
      id: 'wm1',
      workspaceId: 'ws1',
      agentId: 'agent1',
      content: 'original',
      updatedAt: DateTime(2025, 1, 1),
    );
    await repo.upsert(original);

    final updated = AgentWorkingMemory(
      id: 'wm1',
      workspaceId: 'ws1',
      agentId: 'agent1',
      content: 'updated content',
      updatedAt: DateTime(2025, 6, 15),
    );
    await repo.upsert(updated);

    final retrieved = await repo.getByAgent('ws1', 'agent1');
    expect(retrieved!.content, 'updated content');
    expect(retrieved.updatedAt, DateTime(2025, 6, 15));
  });

  test('watchByAgent emits upserted memory', () async {
    await seedAgent('agent1', 'ws1');

    final memory = AgentWorkingMemory(
      id: 'wm1',
      workspaceId: 'ws1',
      agentId: 'agent1',
      content: 'stream test',
      updatedAt: DateTime(2025),
    );
    await repo.upsert(memory);

    final stream = repo.watchByAgent('ws1', 'agent1');
    final emitted = await stream.first;

    expect(emitted, isNotNull);
    expect(emitted!.content, 'stream test');
  });

  test('watchByAgent emits null for non-existent', () async {
    final stream = repo.watchByAgent('ws1', 'nonexistent');
    final emitted = await stream.first;
    expect(emitted, isNull);
  });

  test('watchByWorkspace returns all memories in workspace', () async {
    await seedAgent('agent1', 'ws1');
    await seedAgent('agent2', 'ws1');

    await repo.upsert(
      AgentWorkingMemory(
        id: 'wm1',
        workspaceId: 'ws1',
        agentId: 'agent1',
        content: 'mem1',
        updatedAt: DateTime(2025),
      ),
    );
    await repo.upsert(
      AgentWorkingMemory(
        id: 'wm2',
        workspaceId: 'ws1',
        agentId: 'agent2',
        content: 'mem2',
        updatedAt: DateTime(2025),
      ),
    );

    final stream = repo.watchByWorkspace('ws1');
    final emitted = await stream.first;

    expect(emitted.length, 2);
    expect(emitted.map((m) => m.content).toSet(), {'mem1', 'mem2'});
  });

  test('watchByWorkspace returns empty for empty workspace', () async {
    final stream = repo.watchByWorkspace('ws1');
    final emitted = await stream.first;
    expect(emitted, isEmpty);
  });

  test('upsert with empty content', () async {
    await seedAgent('agent1', 'ws1');

    final memory = AgentWorkingMemory(
      id: 'wm1',
      workspaceId: 'ws1',
      agentId: 'agent1',
      content: '',
      updatedAt: DateTime(2025),
    );
    await repo.upsert(memory);

    final retrieved = await repo.getByAgent('ws1', 'agent1');
    expect(retrieved!.content, '');
  });
}
