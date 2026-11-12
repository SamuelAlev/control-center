import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// Records the SQL of every read, so a test can say which tables a repository
/// method touched.
class _CaptureReads extends QueryInterceptor {
  final List<String> reads = [];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    reads.add(statement);
    return executor.runSelect(statement, args);
  }
}

/// Counts every row INSERT and UPDATE on [tables] with temporary triggers, so
/// a test asserts which rows a write actually rewrote rather than what it
/// sent.
Future<void> _countWrites(WorkspaceDatabase db, List<String> tables) async {
  await db.customStatement(
    'CREATE TEMP TABLE IF NOT EXISTS row_writes (tbl TEXT, kind TEXT)',
  );
  for (final table in tables) {
    for (final kind in ['INSERT', 'UPDATE']) {
      await db.customStatement(
        'CREATE TEMP TRIGGER count_${table}_$kind AFTER $kind ON $table '
        "BEGIN INSERT INTO row_writes VALUES ('$table', '$kind'); END",
      );
    }
  }
}

/// How many rows of [table] were inserted or updated since [_resetWrites].
Future<int> _writesTo(WorkspaceDatabase db, String table) async {
  final row = await db
      .customSelect(
        'SELECT COUNT(*) AS n FROM row_writes WHERE tbl = ?',
        variables: [Variable.withString(table)],
      )
      .getSingle();
  return row.read<int>('n');
}

Future<void> _resetWrites(WorkspaceDatabase db) =>
    db.customStatement('DELETE FROM row_writes');

Future<int> _count(WorkspaceDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

const _ws = 'ws-1';

AgentRunLog _run({
  String id = 'run-1',
  RunStatus status = RunStatus.running,
  DateTime? startedAt,
  String? contextSnapshotJson,
  Map<String, dynamic>? expectedOutputSchema,
  Map<String, dynamic>? outputJson,
  RunVerification? verification,
  String? pipelineRunId,
  String? pipelineStepId,
  String? ticketId,
}) => AgentRunLog(
  id: id,
  agentId: 'agent-1',
  workspaceId: _ws,
  conversationId: 'conv-1',
  spaceId: 'space-1',
  ticketId: ticketId,
  startedAt: startedAt ?? DateTime.utc(2026, 1, 1),
  status: status,
  contextSnapshotJson: contextSnapshotJson,
  expectedOutputSchema: expectedOutputSchema,
  outputJson: outputJson,
  verification: verification,
  pipelineRunId: pipelineRunId,
  pipelineStepId: pipelineStepId,
);

/// A run with every payload field set.
AgentRunLog _fullRun({String id = 'run-1', String? pipelineRunId}) => _run(
  id: id,
  contextSnapshotJson: '{"mode":"build"}',
  expectedOutputSchema: const {'type': 'object'},
  outputJson: const {'result': 'ok'},
  verification: RunVerification(
    status: VerificationStatus.passed,
    verifier: 'tests',
    verifiedAt: DateTime.utc(2026, 1, 2),
  ),
  pipelineRunId: pipelineRunId,
  pipelineStepId: pipelineRunId == null ? null : 'step',
  ticketId: 'ticket-1',
);

void _expectPayload(AgentRunLog? run) {
  expect(run, isNotNull);
  expect(run!.contextSnapshotJson, '{"mode":"build"}');
  expect(run.expectedOutputSchema, {'type': 'object'});
  expect(run.outputJson, {'result': 'ok'});
  expect(run.verification.verifier, 'tests');
}

void _expectNoPayload(AgentRunLog run) {
  expect(run.contextSnapshotJson, isNull);
  expect(run.expectedOutputSchema, isNull);
  expect(run.outputJson, isNull);
  // The verdict is a list column; only its detail stays behind.
  expect(run.verification.status, VerificationStatus.passed);
  expect(run.verification.verifier, isNull);
}

PipelineDefinition _graph() => PipelineDefinition(
  templateId: 'tpl-1',
  workspaceId: _ws,
  name: 'Pinned',
  version: 1,
  steps: [
    PipelineStepDefinition(
      id: 'trigger',
      kind: StepKind.trigger,
      bodyKey: 'pipeline.trigger',
    ),
  ],
);

PipelineRun _pipelineRun({
  String id = 'prun-1',
  PipelineRunStatus status = PipelineRunStatus.running,
  String? dedupKey,
  DateTime? startedAt,
  DateTime? finishedAt,
  bool withSnapshot = true,
}) => PipelineRun(
  id: id,
  templateId: 'tpl-1',
  workspaceId: _ws,
  status: status,
  dedupKey: dedupKey,
  startedAt: startedAt ?? DateTime.utc(2026, 1, 1),
  finishedAt: finishedAt,
  templateSnapshot: withSnapshot ? _graph() : null,
);

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late _CaptureReads capture;
  late WorkspaceDatabase db;

  setUp(() async {
    capture = _CaptureReads();
    // One executor per workspace, as in production; the warning is about two
    // databases sharing one.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    global = createTestGlobalDatabase();
    dbs = WorkspaceDatabaseManager(
      dataDir: Directory.systemTemp.path,
      global: global,
      executorFactory: (_) => NativeDatabase.memory().interceptWith(capture),
    );
    await seedTestWorkspace(global, dbs, _ws);
    db = dbs.of(_ws);
    await seedAgent(db, 'agent-1');
    await seedParents(
      db,
      spaces: ['space-1'],
      conversations: ['conv-1'],
      tickets: ['ticket-1'],
    );
    await _countWrites(db, [
      'agent_run_logs',
      'agent_run_payloads',
      'pipeline_runs',
      'pipeline_run_snapshots',
    ]);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('agent run payloads', () {
    late DaoAgentRunLogRepository repo;

    setUp(() async {
      repo = DaoAgentRunLogRepository(dbs);
      await seedPipelineRun(db, 'prun-1');
    });

    test('the single-run and harvest reads return the whole run', () async {
      await repo.upsert(_fullRun(pipelineRunId: 'prun-1'));

      _expectPayload(await repo.getById(_ws, 'run-1'));
      _expectPayload(await repo.activeRunForAgent(_ws, 'agent-1'));
      _expectPayload(await repo.latestForTicket(_ws, 'ticket-1'));
      _expectPayload(
        (await repo.forPipelineStep(_ws, 'prun-1', 'step')).single,
      );
    });

    test('list reads return runs without their payload, and never read the '
        'payload table', () async {
      await repo.upsert(_fullRun(pipelineRunId: 'prun-1'));
      capture.reads.clear();

      final lists = [
        await repo.watchByAgent(_ws, 'agent-1').first,
        await repo.watchByConversation(_ws, 'conv-1').first,
        await repo.watchBySpace(_ws, 'space-1').first,
        await repo.watchActiveByConversation(_ws, 'conv-1').first,
        await repo.watchActiveBySpace(_ws, 'space-1').first,
        await repo.watchNonTerminalForWorkspace(_ws).first,
        await repo.watchRecent(10).first,
        await repo.nonTerminal(),
        await repo.forPipelineRun(_ws, 'prun-1'),
        await repo.page(_ws, limit: 10),
      ];

      for (final list in lists) {
        _expectNoPayload(list.single);
      }
      expect(capture.reads, isNotEmpty);
      expect(
        capture.reads.where((sql) => sql.contains('agent_run_payloads')),
        isEmpty,
      );

      capture.reads.clear();
      await repo.getById(_ws, 'run-1');
      expect(capture.reads, anyElement(contains('agent_run_payloads')));
    });

    test('status and counter writes never write the payload row', () async {
      await repo.upsert(_fullRun());
      await _resetWrites(db);

      await repo.updateRuntime(
        _ws,
        'run-1',
        markRunning: true,
        summary: 'working',
        liveness: RunLiveness.alive,
        pid: 42,
      );
      await repo.updateCost(_ws, 'run-1', const RunCost(inputTokens: 10));
      await repo.addChildCostMicros(_ws, 'run-1', 5);
      expect(await repo.addOutputRejection(_ws, 'run-1'), 1);
      expect(await repo.addOutputRejection(_ws, 'run-1'), 2);
      // Writing back the whole run it read, with only its status changed, is
      // what the kill and the replay paths do.
      final whole = (await repo.getById(_ws, 'run-1'))!;
      await repo.upsert(whole.copyWith(status: RunStatus.error));
      await repo.completeIfActive(
        whole.copyWith(
          status: RunStatus.completed,
          completedAt: DateTime.utc(2026, 1, 3),
        ),
      );

      expect(await _writesTo(db, 'agent_run_logs'), greaterThan(0));
      expect(await _writesTo(db, 'agent_run_payloads'), 0);
      _expectPayload(await repo.getById(_ws, 'run-1'));
    });

    test('payload writes never write the run-log row', () async {
      await repo.upsert(_run());
      await _resetWrites(db);

      await repo.recordOutput(_ws, 'run-1', {'result': 'done'});
      await repo.updateRuntime(
        _ws,
        'run-1',
        contextSnapshotJson: '{"tools":[]}',
      );

      expect(await _writesTo(db, 'agent_run_logs'), 0);
      expect(await _writesTo(db, 'agent_run_payloads'), 2);
      final run = (await repo.getById(_ws, 'run-1'))!;
      expect(run.outputJson, {'result': 'done'});
      expect(run.contextSnapshotJson, '{"tools":[]}');
    });

    test('a run with nothing to keep has no payload row', () async {
      await repo.upsert(_run());

      expect(await _count(db, 'agent_run_payloads'), 0);
      expect((await repo.getById(_ws, 'run-1'))!.outputJson, isNull);
    });

    test('writing back a list-read run keeps its payload', () async {
      await repo.upsert(_fullRun());
      final listed = (await repo.watchByAgent(_ws, 'agent-1').first).single;

      await repo.upsert(listed.copyWith(summary: 'renamed'));

      final whole = await repo.getById(_ws, 'run-1');
      _expectPayload(whole);
      expect(whole!.summary, 'renamed');
    });

    test('a terminal verdict with detail lands in the payload row', () async {
      await repo.upsert(_run());
      const verdict = RunVerification(
        status: VerificationStatus.failed,
        verifier: 'reviewer',
        notes: 'tests red',
      );

      await repo.completeIfActive(
        _run(
          status: RunStatus.completed,
          verification: verdict,
        ).copyWith(completedAt: DateTime.utc(2026, 1, 2)),
      );

      expect((await repo.getById(_ws, 'run-1'))!.verification, verdict);
    });

    test(
      'an output for a run of another workspace or no run is a no-op',
      () async {
        await repo.upsert(_run());
        const other = 'ws-2';
        await seedTestWorkspace(global, dbs, other);

        await repo.recordOutput(other, 'run-1', {'result': 'stolen'});
        await repo.recordOutput(_ws, 'missing', {'result': 'nobody'});

        expect(await _count(db, 'agent_run_payloads'), 0);
        expect(await repo.addOutputRejection(other, 'run-1'), isNull);
      },
    );

    test('deleting a run deletes its payload row', () async {
      await repo.upsert(_fullRun());
      await repo.upsert(_fullRun(id: 'run-2'));
      expect(await _count(db, 'agent_run_payloads'), 2);

      // The retention sweep deletes run logs with plain SQL.
      await db.customStatement("DELETE FROM agent_run_logs WHERE id = 'run-1'");
      expect(await _count(db, 'agent_run_payloads'), 1);

      await db.agentDao.deleteAgentWithLogs('agent-1');
      expect(await _count(db, 'agent_run_payloads'), 0);
    });
  });

  group('pipeline run snapshots', () {
    late PipelineRunRepositoryImpl repo;

    setUp(() {
      repo = PipelineRunRepositoryImpl(dbs, global.workspaceRouteDao);
    });

    test(
      'the single-run, recovery and admission reads carry the graph',
      () async {
        await repo.insertRun(_pipelineRun(dedupKey: 'key'));
        await repo.insertRun(
          _pipelineRun(id: 'prun-q', status: PipelineRunStatus.queued),
        );

        expect((await repo.getRun('prun-1'))!.templateSnapshot, _graph());
        expect(
          (await repo.watchRun('prun-1').first)!.templateSnapshot,
          _graph(),
        );
        expect(
          (await repo.nonTerminalRuns()).map((r) => r.templateSnapshot),
          everyElement(_graph()),
        );
        expect(
          (await repo.activeForDedupKey(
            templateId: 'tpl-1',
            workspaceId: _ws,
            dedupKey: 'key',
          ))!.templateSnapshot,
          _graph(),
        );
        final next = await repo.nextQueuedRunForTemplate(
          workspaceId: _ws,
          templateId: 'tpl-1',
        );
        expect(next!.id, 'prun-q');
        expect(next.templateSnapshot, _graph());
      },
    );

    test(
      'list reads carry no graph and never read the snapshot table',
      () async {
        await repo.insertRun(_pipelineRun());
        await repo.insertRun(
          _pipelineRun(id: 'prun-0', startedAt: DateTime.utc(2025)),
        );
        capture.reads.clear();

        final listed = await repo.watchForWorkspace(_ws).first;
        final all = await repo.watchAll().first;
        final older = await repo.runsBefore(_ws, listed.first);

        expect(
          [...listed, ...all, ...older].map((r) => r.templateSnapshot),
          everyElement(isNull),
        );
        expect(older.single.id, 'prun-0');
        expect(capture.reads, isNotEmpty);
        expect(
          capture.reads.where((sql) => sql.contains('pipeline_run_snapshots')),
          isEmpty,
        );
      },
    );

    test(
      'lifecycle, state and cost writes never write the snapshot row',
      () async {
        await repo.insertRun(_pipelineRun());
        expect(await _writesTo(db, 'pipeline_run_snapshots'), 1);
        await _resetWrites(db);

        final run = (await repo.getRun('prun-1'))!;
        await repo.updateRun(
          run.copyWith(
            status: PipelineRunStatus.completed,
            finishedAt: DateTime.utc(2026, 1, 2),
          ),
        );
        await repo.updateRunState('prun-1', {'step': 'done'});
        await repo.incrementCost('prun-1', 3, 30);

        expect(await _writesTo(db, 'pipeline_runs'), 3);
        expect(await _writesTo(db, 'pipeline_run_snapshots'), 0);
        expect((await repo.getRun('prun-1'))!.templateSnapshot, _graph());
      },
    );

    test('a run without a graph has no snapshot row', () async {
      await repo.insertRun(_pipelineRun(withSnapshot: false));

      expect(await _count(db, 'pipeline_run_snapshots'), 0);
      expect((await repo.getRun('prun-1'))!.templateSnapshot, isNull);
    });

    test('deleting a run deletes its snapshot row', () async {
      await repo.insertRun(
        _pipelineRun(
          status: PipelineRunStatus.completed,
          finishedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await repo.insertRun(
        _pipelineRun(
          id: 'prun-old',
          status: PipelineRunStatus.completed,
          startedAt: DateTime.utc(2025),
          finishedAt: DateTime.utc(2025),
        ),
      );

      await repo.deleteRun(_ws, 'prun-1');
      expect(await _count(db, 'pipeline_run_snapshots'), 1);

      await db.pipelineDao.deleteFinishedRunsForTemplate(
        templateId: 'tpl-1',
        cutoff: DateTime.utc(2026),
        keepAtLeast: 0,
      );
      expect(await _count(db, 'pipeline_run_snapshots'), 0);
    });
  });
}
