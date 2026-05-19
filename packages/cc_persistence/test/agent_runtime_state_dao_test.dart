import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // agent_runtime_state.agent_id FK-references agents.id.
    await db
        .into(db.agentsTable)
        .insert(
          AgentsTableCompanion.insert(
            id: 'a-1',
            name: 'Agent One',
            title: 'One',
            agentMdPath: '/a/one.md',
            workspaceId: 'w-1',
            skills: '',
          ),
        );
    await db
        .into(db.agentsTable)
        .insert(
          AgentsTableCompanion.insert(
            id: 'a-2',
            name: 'Agent Two',
            title: 'Two',
            agentMdPath: '/a/two.md',
            workspaceId: 'w-2',
            skills: '',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('AgentRuntimeStateDao workspace isolation', () {
    test('upsert + getByWorkspace returns only the workspace rows', () async {
      await db.agentRuntimeStateDao.upsert(
        AgentRuntimeStateTableCompanion.insert(
          agentId: 'a-1',
          workspaceId: 'w-1',
          reportedStatus: const Value('alive'),
        ),
      );
      await db.agentRuntimeStateDao.upsert(
        AgentRuntimeStateTableCompanion.insert(
          agentId: 'a-2',
          workspaceId: 'w-2',
          reportedStatus: const Value('idle'),
        ),
      );

      final rows = await db.agentRuntimeStateDao.getByWorkspace('w-1');
      expect(rows, hasLength(1));
      expect(rows.first.agentId, 'a-1');

      final watchRows = await db.agentRuntimeStateDao
          .watchByWorkspace('w-2')
          .first;
      expect(watchRows, hasLength(1));
      expect(watchRows.first.reportedStatus, 'idle');
    });

    test('getForAgent is workspace-scoped', () async {
      await db.agentRuntimeStateDao.upsert(
        AgentRuntimeStateTableCompanion.insert(
          agentId: 'a-1',
          workspaceId: 'w-1',
          currentRunId: const Value('run-1'),
        ),
      );
      expect(
        (await db.agentRuntimeStateDao.getForAgent('w-1', 'a-1'))?.currentRunId,
        'run-1',
      );
      // a-1 does not exist in w-2.
      expect(await db.agentRuntimeStateDao.getForAgent('w-2', 'a-1'), isNull);
      expect(
        await db.agentRuntimeStateDao.getForAgent('w-1', 'missing'),
        isNull,
      );
    });

    test(
      'getAll spans every workspace (intentional cross-workspace GC read)',
      () async {
        await db.agentRuntimeStateDao.upsert(
          AgentRuntimeStateTableCompanion.insert(
            agentId: 'a-1',
            workspaceId: 'w-1',
          ),
        );
        await db.agentRuntimeStateDao.upsert(
          AgentRuntimeStateTableCompanion.insert(
            agentId: 'a-2',
            workspaceId: 'w-2',
          ),
        );
        expect(await db.agentRuntimeStateDao.getAll(), hasLength(2));
      },
    );

    test('upsert replaces on conflict (same agentId PK)', () async {
      await db.agentRuntimeStateDao.upsert(
        AgentRuntimeStateTableCompanion.insert(
          agentId: 'a-1',
          workspaceId: 'w-1',
          reportedStatus: const Value('alive'),
        ),
      );
      await db.agentRuntimeStateDao.upsert(
        AgentRuntimeStateTableCompanion.insert(
          agentId: 'a-1',
          workspaceId: 'w-1',
          reportedStatus: const Value('stuck'),
          note: const Value('halted'),
        ),
      );
      final row = await db.agentRuntimeStateDao.getForAgent('w-1', 'a-1');
      expect(row?.reportedStatus, 'stuck');
      expect(row?.note, 'halted');
    });

    test('deleteForAgent is workspace-scoped', () async {
      await db.agentRuntimeStateDao.upsert(
        AgentRuntimeStateTableCompanion.insert(
          agentId: 'a-1',
          workspaceId: 'w-1',
        ),
      );
      // A foreign workspace cannot delete it.
      expect(await db.agentRuntimeStateDao.deleteForAgent('w-2', 'a-1'), 0);
      expect(
        await db.agentRuntimeStateDao.getForAgent('w-1', 'a-1'),
        isNotNull,
      );

      expect(await db.agentRuntimeStateDao.deleteForAgent('w-1', 'a-1'), 1);
      expect(await db.agentRuntimeStateDao.getForAgent('w-1', 'a-1'), isNull);
    });
  });
}
