import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/script_past_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/testing/fake_workspace_repository.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/code_mode/server_code_mode_wiring.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// Code mode as the server boots it, against the real runner and a real
/// workspace database: no script is admitted before the sweep of records a
/// restart left running, so the sweep finishes every running record and
/// never a live one.
///
/// Runs the real runner (`CC_CODEMODE_RUNNER`, an absolute path to a built
/// `cc_codemode`).
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late Directory data;
  const workspaceId = 'ws-boot';

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, workspaceId);
    final db = dbs.of(workspaceId);
    await db.customStatement(
      'INSERT INTO agents '
      '(id, name, title, agent_md_path, workspace_id, skills) '
      "VALUES ('agent-1', 'agent-1', 'Agent', '', ?, '')",
      [workspaceId],
    );
    for (final run in ['run-old', 'run-new']) {
      await db.customStatement(
        'INSERT INTO agent_run_logs (id, agent_id, workspace_id) '
        "VALUES (?, 'agent-1', ?)",
        [run, workspaceId],
      );
    }
    data = Directory.systemTemp.createTempSync('cc_code_mode_boot');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
    data.deleteSync(recursive: true);
  });

  test('a script waits for the sweep, which finishes the record the last '
      'process left running and not the script that waited', () async {
    final now = DateTime.now().toUtc();
    final workspaces = FakeWorkspaceRepository();
    await workspaces.upsert(
      Workspace(id: workspaceId, name: 'boot', createdAt: now, updatedAt: now),
    );
    final executions = DaoCodeExecutionRepository(dbs);
    final orphan = CodeExecution.idFor(runId: 'run-old', toolCallId: 'c1');
    await executions.begin(
      workspaceId,
      CodeExecution(
        id: orphan,
        runId: 'run-old',
        toolCallId: 'c1',
        surface: CodeExecutionSurface.harness,
        // A clock that stepped back: started "after" this boot.
        startedAt: now.add(const Duration(hours: 1)),
        durationMs: 0,
        status: CodeExecutionStatus.running,
        sourceHash: 'ab' * 32,
        sourceBytes: 8,
        limits: CodeModeLimits.defaults,
        agentId: 'agent-1',
        description: 'x',
      ),
      source: 'return 1',
    );

    final events = DomainEventBus();
    addTearDown(events.dispose);
    final codeMode = ServerCodeMode.start(
      events: events,
      dataDir: data.path,
      workspaceDbs: dbs,
      crossWorkspace: CrossWorkspaceQueries(dbs),
      embeddings: null,
      maxProcesses: 2,
      maxHeapBytes: CodeModeLimits.heap.defaultValue,
      demo: false,
      workspaces: workspaces,
      workspaceSettings: DaoWorkspaceSettingsRepository(dbs),
      hiddenSpaces:
          ({required workspaceId, required callerConversationId}) async =>
              const <String>{},
    );
    final service = codeMode.service!;
    addTearDown(service.dispose);
    expect(await codeMode.startupLine(), contains('code_mode=available'));

    var done = false;
    final script = service
        .execute(
          CodeExecutionRequest(
            readOnly: false,
            past: null,
            workspaceId: workspaceId,
            runId: 'run-new',
            parentToolCallId: 'c1',
            surface: CodeExecutionSurface.harness,
            code: 'return 2;',
            description: 'after boot',
            limits: CodeModeLimits.defaults,
            tools: const [],
            agentId: 'agent-1',
          ),
          callNested: (r) => throw StateError('no calls'),
        )
        .whenComplete(() => done = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(done, isFalse, reason: 'admitted before the sweep');
    expect(
      (await executions.get(workspaceId, orphan))!.execution.status,
      CodeExecutionStatus.running,
    );

    final announced = <String>[];
    codeMode
      ..sweepOrphans(announce: announced.add)
      ..sweepOrphans(announce: announced.add);
    final result = await script.timeout(const Duration(seconds: 20));
    expect(result.execution.status, CodeExecutionStatus.completed);
    final swept = (await executions.get(workspaceId, orphan))!.execution;
    expect(swept.status, CodeExecutionStatus.sandboxError);
    expect(swept.errorKind, CodeExecutionErrorKind.serverStopped);
    expect(
      (await executions.get(
        workspaceId,
        result.execution.id,
      ))!.execution.status,
      CodeExecutionStatus.completed,
    );
    expect(
      announced.single,
      'cc_server: closed 1 code mode script record(s) a previous server '
      'process left running, in 1 workspace(s) '
      '(sandbox_error/server_stopped)',
    );
    expect(codeMode.hostFacts.maxParkedProcesses, service.parkedCap);
    expect(codeMode.hostExecutableDirs, contains(isNotEmpty));

    // An MCP run keeps one script-past port across its scripts, until it
    // settles.
    ScriptPastPort portOf(String run) => codeMode.mcpPasts.forRun(
      runLogId: run,
      workspaceId: workspaceId,
      conversationId: 'conv-1',
      spaceId: null,
    );
    final first = portOf('run-mcp');
    expect(portOf('run-mcp'), same(first));
    portOf('run-other');
    expect(codeMode.mcpPasts.length, 2);
    events.publish(
      AgentRunSettled(
        agentId: 'agent-1',
        workspaceId: workspaceId,
        spaceId: null,
        conversationId: 'conv-1',
        runId: 'run-mcp',
        status: RunStatus.completed,
        endReason: RunEndReason.completed,
        costMicros: 0,
        limitResetsAt: null,
        wakeIds: const [],
        requestedByUserId: null,
        wakeReason: null,
        occurredAt: now,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(codeMode.mcpPasts.length, 1);
    expect(portOf('run-mcp'), isNot(same(first)));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
