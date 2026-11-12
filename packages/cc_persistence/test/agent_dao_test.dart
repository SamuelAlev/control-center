import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
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
    // Parents the run logs below name.
    await seedParents(
      db,
      tickets: ['t-1', 't-2'],
      conversations: ['conv-1'],
      pipelineRuns: ['run-1'],
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
      workspaceId: ws,
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
      expect(rows.first.log.id, 'log-1');
    });

    test('logsPage is scoped, newest-first and pages by keyset', () async {
      final at = DateTime.utc(2025, 1, 1, 0, 1);
      // Three runs started in the same second: only the id orders them.
      await log(id: 'log-a', agentId: 'a-1', ws: 'w-1', startedAt: at);
      await log(id: 'log-c', agentId: 'a-1', ws: 'w-1', startedAt: at);
      await log(id: 'log-b', agentId: 'a-1', ws: 'w-1', startedAt: at);
      await log(
        id: 'log-old',
        agentId: 'a-1',
        ws: 'w-1',
        startedAt: DateTime.utc(2025),
      );
      await log(id: 'log-other', agentId: 'a-2', ws: 'w-2', startedAt: at);

      final first = await db.agentDao.logsPage('w-1', limit: 2);
      expect(first.map((r) => r.id), ['log-c', 'log-b']);

      final second = await db.agentDao.logsPage(
        'w-1',
        limit: 2,
        beforeStartedAt: first.last.startedAt,
        beforeId: first.last.id,
      );
      expect(second.map((r) => r.id), ['log-a', 'log-old']);

      final rest = await db.agentDao.logsPage(
        'w-1',
        limit: 2,
        beforeStartedAt: second.last.startedAt,
        beforeId: second.last.id,
      );
      expect(rest, isEmpty);
    });

    test('nonTerminalLogs reads only pending and running runs', () async {
      await log(id: 'log-run', agentId: 'a-1', ws: 'w-1');
      await log(id: 'log-pend', agentId: 'a-2', ws: 'w-2', status: 'pending');
      await log(
        id: 'log-done',
        agentId: 'a-1',
        ws: 'w-1',
        status: 'completed',
        completedAt: DateTime.utc(2025),
      );
      await log(id: 'log-fail', agentId: 'a-1', ws: 'w-1', status: 'error');

      final rows = await db.agentDao.nonTerminalLogs();
      expect(rows.map((r) => r.id).toSet(), {'log-run', 'log-pend'});
      expect(await db.agentDao.nonTerminalLogs(limit: 1), hasLength(1));

      final active = await db.agentDao.watchNonTerminalLogs('w-1').first;
      expect(active.map((r) => r.id), ['log-run']);
    });

    test('latestLogForTicket returns the newest run of that ticket', () async {
      Future<void> ticketLog(String id, String ws, String ticket, int minute) =>
          db.agentDao.upsertLog(
            AgentRunLogsTableCompanion.insert(
              id: id,
              agentId: 'a-1',
              workspaceId: ws,
              ticketId: Value(ticket),
              startedAt: Value(DateTime.utc(2025, 1, 1, 0, minute)),
            ),
          );
      await ticketLog('log-1', 'w-1', 't-1', 1);
      await ticketLog('log-2', 'w-1', 't-1', 2);
      await ticketLog('log-3', 'w-1', 't-2', 3);
      await ticketLog('log-4', 'w-2', 't-1', 4);

      expect(
        (await db.agentDao.latestLogForTicket('w-1', 't-1'))?.log.id,
        'log-2',
      );
      expect(await db.agentDao.latestLogForTicket('w-1', 't-9'), isNull);
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
      expect(active?.log.id, 'log-active');
      expect(await db.agentDao.getActiveLogByAgent('a-2'), isNull);
    });
  });
}
