import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/dao_agent_working_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoAgentWorkingMemoryRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = DaoAgentWorkingMemoryRepository(db.agentWorkingMemoryDao);
  });

  tearDown(() async {
    await db.close();
  });

  // Seed FK dependencies
  Future<void> seedWorkspace(String id) => db
      .into(db.workspacesTable)
      .insert(WorkspacesTableCompanion.insert(id: id, name: 'WS $id'));

  Future<void> seedAgent(String id, String workspaceId) => db
      .into(db.agentsTable)
      .insert(AgentsTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        name: 'agent-$id',
        title: 'Agent $id',
        agentMdPath: '/tmp/$id.md',
        skills: '[]',
      ));

  test('upsert then getByAgent returns the working memory', () async {
    await seedWorkspace('ws1');
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
    await seedWorkspace('ws1');
    final result = await repo.getByAgent('ws1', 'nonexistent');
    expect(result, isNull);
  });

  test('getByAgent returns null for wrong workspace', () async {
    await seedWorkspace('ws1');
    await seedWorkspace('ws2');
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
    await seedWorkspace('ws1');
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
    await seedWorkspace('ws1');
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
    await seedWorkspace('ws1');
    final stream = repo.watchByAgent('ws1', 'nonexistent');
    final emitted = await stream.first;
    expect(emitted, isNull);
  });

  test('watchByWorkspace returns all memories in workspace', () async {
    await seedWorkspace('ws1');
    await seedAgent('agent1', 'ws1');
    await seedAgent('agent2', 'ws1');

    await repo.upsert(AgentWorkingMemory(
      id: 'wm1', workspaceId: 'ws1', agentId: 'agent1',
      content: 'mem1', updatedAt: DateTime(2025),
    ));
    await repo.upsert(AgentWorkingMemory(
      id: 'wm2', workspaceId: 'ws1', agentId: 'agent2',
      content: 'mem2', updatedAt: DateTime(2025),
    ));

    final stream = repo.watchByWorkspace('ws1');
    final emitted = await stream.first;

    expect(emitted.length, 2);
    expect(emitted.map((m) => m.content).toSet(), {'mem1', 'mem2'});
  });

  test('watchByWorkspace returns empty for empty workspace', () async {
    await seedWorkspace('ws1');
    final stream = repo.watchByWorkspace('ws1');
    final emitted = await stream.first;
    expect(emitted, isEmpty);
  });

  test('upsert with empty content', () async {
    await seedWorkspace('ws1');
    await seedAgent('agent1', 'ws1');

    final memory = AgentWorkingMemory(
      id: 'wm1', workspaceId: 'ws1', agentId: 'agent1',
      content: '', updatedAt: DateTime(2025),
    );
    await repo.upsert(memory);

    final retrieved = await repo.getByAgent('ws1', 'agent1');
    expect(retrieved!.content, '');
  });
}
