import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/code_mode/orphaned_execution_sweep.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// A script runs only inside the server that admitted it, so a record a
/// server start finds still running belonged to a process that died: the
/// boot sweep finishes it as `server_stopped`.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCodeExecutionRepository executions;
  final bootedAt = DateTime.utc(2026, 11, 17, 12);

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    executions = DaoCodeExecutionRepository(dbs);
    await seedTestWorkspace(global, dbs, 'ws-1');
    final db = dbs.of('ws-1');
    await db.customStatement(
      'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, skills) '
      "VALUES ('agent-1', 'agent-1', 'Agent', '', 'ws-1', '')",
    );
    await db.customStatement(
      'INSERT INTO agent_run_logs (id, agent_id, workspace_id) '
      "VALUES ('run-1', 'agent-1', 'ws-1')",
    );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<String> begin(String toolCallId, DateTime startedAt) async {
    final id = CodeExecution.idFor(runId: 'run-1', toolCallId: toolCallId);
    await executions.begin(
      'ws-1',
      CodeExecution(
        id: id,
        runId: 'run-1',
        toolCallId: toolCallId,
        surface: CodeExecutionSurface.harness,
        startedAt: startedAt,
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
    return id;
  }

  test('every record left running by the previous process is finished as '
      'server_stopped, even one whose start time is after this boot (a '
      'clock that stepped back)', () async {
    final orphan = await begin(
      'call_old',
      bootedAt.subtract(const Duration(minutes: 5)),
    );
    final stepped = await begin(
      'call_new',
      DateTime.now().add(const Duration(hours: 1)),
    );

    expect(await sweepOrphanedExecutionsIn(dbs.of('ws-1')), 2);

    final swept = (await executions.get('ws-1', orphan))!.execution;
    expect(swept.status, CodeExecutionStatus.sandboxError);
    expect(swept.errorKind, CodeExecutionErrorKind.serverStopped);
    expect(swept.durationMs, greaterThan(0));
    final ahead = (await executions.get('ws-1', stepped))!.execution;
    expect(ahead.status, CodeExecutionStatus.sandboxError);
    expect(ahead.durationMs, 0);
    // A second sweep finds nothing.
    expect(await sweepOrphanedExecutionsIn(dbs.of('ws-1')), 0);
  });

  group('admission waits for the sweep of its workspace', () {
    late CodeSandboxProcess sandbox;
    late List<String> warnings;

    setUp(() async {
      sandbox = CodeSandboxProcess(
        executable: BundledCodeRunner.locate(
          appSupportRoot: Directory.systemTemp.path,
        ).executable,
      );
      expect((await sandbox.selfTest()).isAvailable, isTrue);
      warnings = [];
      final previous = CcHostLog.sink;
      CcHostLog.sink = (level, message, [error, stackTrace]) {
        if (message.contains('sweep failed')) {
          warnings.add(message);
        }
      };
      addTearDown(() => CcHostLog.sink = previous);
    });

    CodeExecutionService serviceOver(OrphanedExecutionSweeps sweeps) {
      final service = CodeExecutionService(
        sandbox: sandbox,
        executions: executions,
        store: DaoCodeModeStoreRepository(dbs),
        serverProcessCap: 2,
        admission: sweeps.admit,
      );
      addTearDown(service.dispose);
      return service;
    }

    Future<CodeExecutionResult> script(
      CodeExecutionService service,
      String callId, {
      int wallClockMs = 30000,
    }) => service.execute(
      CodeExecutionRequest(
        readOnly: false,
        past: null,
        workspaceId: 'ws-1',
        runId: 'run-1',
        parentToolCallId: callId,
        surface: CodeExecutionSurface.harness,
        code: 'return 1;',
        description: 'after boot',
        limits: CodeModeLimits(wallClockMs: wallClockMs),
        tools: const [],
        agentId: 'agent-1',
      ),
      callNested: (r) => throw StateError('no calls'),
    );

    test(
      'a workspace whose boot sweep failed admits no script until a sweep '
      'of it succeeds; each script retries it, the failure is logged once, '
      'and the stale record is finished before a script is recorded',
      () async {
        final orphan = await begin('call_old', bootedAt);
        var failures = 3;
        final sweeps = OrphanedExecutionSweeps(
          crossWorkspace: CrossWorkspaceQueries(dbs),
          workspaceDbs: dbs,
          sweepIn: (db) async {
            if (failures > 0) {
              failures--;
              throw StateError('database is locked');
            }
            return sweepOrphanedExecutionsIn(db);
          },
        );
        final service = serviceOver(sweeps);
        final announced = <String>[];
        await sweeps.sweepAll(announce: announced.add);
        expect(failures, 2, reason: 'the boot pass tried the workspace');
        expect(announced, isEmpty, reason: 'it closed nothing');

        for (final callId in ['c1', 'c2']) {
          final refused = await script(service, callId);
          expect(refused.execution.status, CodeExecutionStatus.refused);
          expect(
            refused.execution.errorKind,
            CodeExecutionErrorKind.auditUnavailable,
            reason: refused.result.text,
          );
          expect(refused.result.text, contains('server log'));
          expect(
            (await executions.get('ws-1', orphan))!.execution.status,
            CodeExecutionStatus.running,
          );
        }
        expect(failures, 0);
        expect(
          warnings.where((w) => w.contains('failed again')),
          hasLength(1),
          reason: 'logged once while it keeps failing',
        );

        final admitted = await script(service, 'c3');
        expect(admitted.execution.status, CodeExecutionStatus.completed);
        final swept = (await executions.get('ws-1', orphan))!.execution;
        expect(swept.status, CodeExecutionStatus.sandboxError);
        expect(swept.errorKind, CodeExecutionErrorKind.serverStopped);
        expect(
          (await executions.get(
            'ws-1',
            admitted.execution.id,
          ))!.execution.status,
          CodeExecutionStatus.completed,
        );
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test('a sweep that has not run ends the wait in the busy refusal at the '
        'wall clock, and the record stays as it was', () async {
      final orphan = await begin('call_old', bootedAt);
      final sweeps = OrphanedExecutionSweeps(
        crossWorkspace: CrossWorkspaceQueries(dbs),
        workspaceDbs: dbs,
      );
      final service = serviceOver(sweeps);
      final clock = Stopwatch()..start();
      final r = await script(service, 'c1', wallClockMs: 1000);
      expect(r.execution.status, CodeExecutionStatus.refused);
      expect(r.execution.errorKind, CodeExecutionErrorKind.serverBusy);
      expect(clock.elapsedMilliseconds, lessThan(5000));
      expect(
        (await executions.get('ws-1', orphan))!.execution.status,
        CodeExecutionStatus.running,
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
