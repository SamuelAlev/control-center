import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/runtime/server_wake_rules_wiring.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The wake rules' `startedByRun` port over the real run log: the run log's
/// `started_by_run_id` column, followed only inside its workspace.
void main() {
  late WorkspaceDatabaseManager dbs;
  late DaoAgentRunLogRepository runLogs;

  setUp(() async {
    final global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final ws in ['ws-1', 'ws-2']) {
      await seedTestWorkspace(global, dbs, ws);
      await dbs.of(ws).customStatement(
        'INSERT INTO agents (id, name, title, agent_md_path, '
        "workspace_id, skills) VALUES ('agent-1', 'A', 'Agent', '', ?, '')",
        [ws],
      );
    }
    runLogs = DaoAgentRunLogRepository(dbs);
  });

  Future<void> run(
    String ws,
    String id, {
    String? startedBy,
    List<String> wakeIds = const [],
  }) => runLogs.upsert(
    AgentRunLog(
      id: id,
      agentId: 'agent-1',
      workspaceId: ws,
      startedAt: DateTime.utc(2026, 5),
      status: RunStatus.running,
      wakeIds: wakeIds,
      wakeReason: wakeIds.isEmpty ? WakeReason.assignment : WakeReason.schedule,
      startedByRunId: startedBy,
    ),
  );

  test('the column is written with the run and read back; a later write '
      'of the run without it keeps it', () async {
    await run('ws-1', 'run-lead');
    await run('ws-1', 'run-reviewer', startedBy: 'run-lead');
    expect(
      (await runLogs.getById('ws-1', 'run-reviewer'))!.startedByRunId,
      'run-lead',
    );
    await run('ws-1', 'run-reviewer');
    expect(
      (await runLogs.getById('ws-1', 'run-reviewer'))!.startedByRunId,
      'run-lead',
    );
    expect(await startedByRunOf(runLogs, 'ws-1', 'run-reviewer'), 'run-lead');
  });

  test('a run nothing started by a direct dispatch (a person\'s operation, '
      'a pipeline step) has no starter', () async {
    await run('ws-1', 'run-person');
    expect(await startedByRunOf(runLogs, 'ws-1', 'run-person'), isNull);
    expect(await startedByRunOf(runLogs, 'ws-1', 'run-missing'), isNull);
  });

  test('a run id from another workspace is ignored', () async {
    await run('ws-2', 'run-foreign');
    await run('ws-1', 'run-reviewer', startedBy: 'run-foreign');
    expect(await startedByRunOf(runLogs, 'ws-1', 'run-reviewer'), isNull);
    // Asked from the other workspace, the run is not there at all.
    expect(await startedByRunOf(runLogs, 'ws-2', 'run-reviewer'), isNull);
  });

  test('a run that delivers wakes is followed through its wakes, not the '
      'column', () async {
    await run('ws-1', 'run-lead');
    await run('ws-1', 'run-woken', startedBy: 'run-lead', wakeIds: ['wk-1']);
    expect(await startedByRunOf(runLogs, 'ws-1', 'run-woken'), isNull);
  });
}
