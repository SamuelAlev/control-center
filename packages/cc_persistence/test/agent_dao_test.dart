import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Covers [AgentDao] — agent CRUD, plus the run-log read/watch paths the
/// repository test does not exercise at the DAO layer.
void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
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

  Future<void> log({
    required String id,
    required String agentId,
    required String ws,
    String? conversationId,
    String? pipelineRunId,
    String? pipelineStepId,
    DateTime? startedAt,
    DateTime? completedAt,
    String status = 'running',
  }) => db.agentDao.upsertLog(
    AgentRunLogsTableCompanion.insert(
      id: id,
      agentId: agentId,
      workspaceId: Value(ws),
      conversationId: conversationId == null
          ? const Value.absent()
          : Value(conversationId),
      pipelineRunId: pipelineRunId == null
          ? const Value.absent()
          : Value(pipelineRunId),
      pipelineStepId: pipelineStepId == null
          ? const Value.absent()
          : Value(pipelineStepId),
      startedAt: startedAt == null ? const Value.absent() : Value(startedAt),
      completedAt: completedAt == null
          ? const Value.absent()
          : Value(completedAt),
      status: Value(status),
    ),
  );

  group('AgentDao agents', () {
    test(
      'watchAll / getAll span every workspace (intentional cross-ws reads)',
      () async {
        final all = await db.agentDao.getAll();
        expect(all, hasLength(2));
        final watchAll = await db.agentDao.watchAll().first;
        expect(watchAll.map((a) => a.id).toSet(), {'a-1', 'a-2'});
      },
    );

    test('watchByWorkspace is scoped', () async {
      final rows = await db.agentDao.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'a-1');
    });

    test('getById + getByWorkspaceAndName', () async {
      expect((await db.agentDao.getById('a-1'))?.name, 'Agent One');
      expect(
        (await db.agentDao.getByWorkspaceAndName('w-1', 'Agent One'))?.id,
        'a-1',
      );
      // Names are unique per workspace — a-1's name is not found in w-2.
      expect(
        await db.agentDao.getByWorkspaceAndName('w-2', 'Agent One'),
        isNull,
      );
      expect(await db.agentDao.getById('missing'), isNull);
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'a-1',
          name: 'Agent Renamed',
          title: 'One',
          agentMdPath: '/a/one.md',
          workspaceId: 'w-1',
          skills: 'review',
        ),
      );
      final row = await db.agentDao.getById('a-1');
      expect(row?.name, 'Agent Renamed');
      expect(row?.skills, 'review');
    });

    test(
      'deleteAgentWithLogs removes agent + its run logs in one transaction',
      () async {
        await log(id: 'log-1', agentId: 'a-1', ws: 'w-1');
        expect(await db.agentDao.getLogById('log-1'), isNotNull);

        await db.agentDao.deleteAgentWithLogs('a-1');
        expect(await db.agentDao.getById('a-1'), isNull);
        expect(await db.agentDao.getLogById('log-1'), isNull);
      },
    );

    test('deleteById and deleteAll', () async {
      expect(await db.agentDao.deleteById('a-1'), 1);
      expect(await db.agentDao.getById('a-1'), isNull);
      expect(await db.agentDao.deleteAll(), greaterThan(0));
      expect(await db.agentDao.getAll(), isEmpty);
    });
  });

  group('AgentDao run logs', () {
    test('watchLogsByAgent is workspace + agent scoped', () async {
      await log(id: 'log-1', agentId: 'a-1', ws: 'w-1');
      await log(id: 'log-2', agentId: 'a-2', ws: 'w-2');
      final rows = await db.agentDao.watchLogsByAgent('w-1', 'a-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'log-1');
    });

    test('logsForPipelineRun is workspace-scoped', () async {
      await log(id: 'log-1', agentId: 'a-1', ws: 'w-1', pipelineRunId: 'run-1');
      await log(id: 'log-2', agentId: 'a-2', ws: 'w-2', pipelineRunId: 'run-1');
      final rows = await db.agentDao.logsForPipelineRun('w-1', 'run-1');
      expect(rows, hasLength(1));
    });

    test('logsForPipelineStep filters by step', () async {
      await log(
        id: 'log-1',
        agentId: 'a-1',
        ws: 'w-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-1',
      );
      await log(
        id: 'log-2',
        agentId: 'a-1',
        ws: 'w-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-2',
      );
      final rows = await db.agentDao.logsForPipelineStep(
        'w-1',
        'run-1',
        'step-1',
      );
      expect(rows, hasLength(1));
      expect(rows.first.id, 'log-1');
    });

    test('logsByWorkspace is scoped + newest-first', () async {
      await log(
        id: 'log-1',
        agentId: 'a-1',
        ws: 'w-1',
        startedAt: DateTime.utc(2025, 1, 1, 0, 1),
      );
      await log(
        id: 'log-2',
        agentId: 'a-1',
        ws: 'w-1',
        startedAt: DateTime.utc(2025, 1, 1, 0, 2),
      );
      await log(id: 'log-3', agentId: 'a-2', ws: 'w-2');
      final rows = await db.agentDao.logsByWorkspace('w-1');
      expect(rows, hasLength(2));
      // newest started first
      expect(rows.first.id, 'log-2');
    });

    test('watchAllLogs spans every workspace', () async {
      await log(id: 'log-1', agentId: 'a-1', ws: 'w-1');
      await log(id: 'log-2', agentId: 'a-2', ws: 'w-2');
      expect(await db.agentDao.watchAllLogs().first, hasLength(2));
    });

    test(
      'watchActiveLogsByConversation returns only active (completedAt null)',
      () async {
        await log(
          id: 'log-1',
          agentId: 'a-1',
          ws: 'w-1',
          conversationId: 'conv-1',
        );
        await log(
          id: 'log-2',
          agentId: 'a-1',
          ws: 'w-1',
          conversationId: 'conv-1',
          completedAt: DateTime.utc(2025, 1, 1),
          status: 'completed',
        );
        final rows = await db.agentDao
            .watchActiveLogsByConversation('w-1', 'conv-1')
            .first;
        expect(rows, hasLength(1));
        expect(rows.first.id, 'log-1');
      },
    );

    test('watchLogsByConversation emits active + completed', () async {
      await log(
        id: 'log-1',
        agentId: 'a-1',
        ws: 'w-1',
        conversationId: 'conv-1',
      );
      await log(
        id: 'log-2',
        agentId: 'a-1',
        ws: 'w-1',
        conversationId: 'conv-1',
        completedAt: DateTime.utc(2025, 1, 1),
      );
      final rows = await db.agentDao
          .watchLogsByConversation('w-1', 'conv-1')
          .first;
      expect(rows, hasLength(2));
      // oldest started first
      expect(rows.first.id, 'log-1');
    });

    test('getLogById + deleteLogsByAgentId', () async {
      await log(id: 'log-1', agentId: 'a-1', ws: 'w-1');
      await log(id: 'log-2', agentId: 'a-1', ws: 'w-1');
      expect(await db.agentDao.getLogById('missing'), isNull);

      final deleted = await db.agentDao.deleteLogsByAgentId('a-1');
      expect(deleted, 2);
      expect(await db.agentDao.getLogById('log-1'), isNull);
    });

    test('getActiveLogByAgent returns the newest non-completed run', () async {
      await log(
        id: 'log-old',
        agentId: 'a-1',
        ws: 'w-1',
        startedAt: DateTime.utc(2025, 1, 1),
        completedAt: DateTime.utc(2025, 1, 2),
      );
      await log(
        id: 'log-active',
        agentId: 'a-1',
        ws: 'w-1',
        startedAt: DateTime.utc(2025, 1, 3),
      );
      final active = await db.agentDao.getActiveLogByAgent('a-1');
      expect(active?.id, 'log-active');
      expect(await db.agentDao.getActiveLogByAgent('a-2'), isNull);
    });
  });
}
