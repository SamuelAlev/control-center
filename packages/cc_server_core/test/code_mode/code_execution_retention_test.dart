import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// The server's execution service saving through the real repositories:
/// the payload caps hold on what is stored, and the retention sweep that
/// prunes a run log takes its executions with it.
///
/// Runs the real runner (`CC_CODEMODE_RUNNER`, an absolute path to a built
/// `cc_codemode`).
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCodeExecutionRepository executions;
  late CodeSandboxProcess sandbox;
  late CodeExecutionService service;

  const workspaceId = 'ws-retention';

  Future<void> seedRun(String runId, {DateTime? completedAt}) async {
    final db = dbs.of(workspaceId);
    await db.customStatement(
      'INSERT OR IGNORE INTO agents '
      '(id, name, title, agent_md_path, workspace_id, skills) '
      "VALUES ('agent-1', 'agent-1', 'Agent', '', ?, '')",
      [workspaceId],
    );
    final started =
        (completedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    final at = completedAt == null
        ? null
        : completedAt.millisecondsSinceEpoch ~/ 1000;
    await db.customStatement(
      'INSERT INTO agent_run_logs '
      '(id, agent_id, workspace_id, status, started_at, completed_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [
        runId,
        'agent-1',
        workspaceId,
        if (at == null) 'running' else 'completed',
        started,
        at,
      ],
    );
  }

  Future<CodeExecutionResult> run(
    String runId,
    String code, {
    CodeModeLimits? limits,
  }) => service.execute(
    CodeExecutionRequest(
      readOnly: false,
      past: null,
      workspaceId: workspaceId,
      runId: runId,
      parentToolCallId: 'call_1',
      surface: CodeExecutionSurface.harness,
      code: code,
      description: 'retention test',
      limits: limits ?? CodeModeLimits.defaults,
      tools: const [],
      agentId: 'agent-1',
    ),
    callNested: (request) => throw StateError('this script calls no tools'),
  );

  Future<int> count(String table) async {
    final row = await dbs
        .of(workspaceId)
        .customSelect('SELECT COUNT(*) AS n FROM $table')
        .getSingle();
    return row.read<int>('n');
  }

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, workspaceId);
    executions = DaoCodeExecutionRepository(dbs);
    final runner = BundledCodeRunner.locate(
      appSupportRoot: Directory.systemTemp.path,
    );
    sandbox = CodeSandboxProcess(executable: runner.executable);
    final availability = await sandbox.selfTest();
    expect(availability.isAvailable, isTrue, reason: '$availability');
    service = CodeExecutionService(
      sandbox: sandbox,
      executions: executions,
      store: DaoCodeModeStoreRepository(dbs),
      serverProcessCap: 2,
    );
  });

  tearDown(() async {
    await service.dispose();
    await dbs.closeAll();
    await global.close();
  });

  test('the stored payload never exceeds its caps', () async {
    await seedRun('run-big');
    // A source just under the admission cap, output over its storage cap
    // and console over its own.
    final padding = '/' * (CodeExecutionPayload.maxSourceBytes - 4096);
    final code =
        '// $padding\n'
        "console.log('c'.repeat(100 * 1024));\n"
        // Three bytes a character, so the most output a run may ask for is
        // more bytes than the stored copy keeps.
        "text('\u20ac'.repeat(300 * 1024));\n"
        'return 1;';
    final result = await run(
      'run-big',
      code,
      limits: CodeModeLimits.defaults.withOverrides(
        maxOutputTokens: CodeModeLimits.outputTokens.ceiling,
      ),
    );
    expect(result.execution.status, CodeExecutionStatus.completed);

    final stored = (await executions.get(workspaceId, result.execution.id))!;
    final payload = stored.payload!;
    expect(payload.source, code, reason: 'a source under the cap is whole');
    expect(
      utf8.encode(payload.source).length,
      lessThanOrEqualTo(CodeExecutionPayload.maxSourceBytes),
    );
    final outputBytes = utf8.encode(payload.output).length;
    expect(outputBytes, lessThanOrEqualTo(CodeExecutionPayload.maxOutputBytes));
    expect(
      outputBytes,
      greaterThan(CodeExecutionPayload.maxOutputBytes ~/ 2),
      reason: 'the output was kept up to its cap, not dropped',
    );
    expect(
      utf8.encode(payload.console).length,
      lessThanOrEqualTo(CodeExecutionPayload.maxConsoleBytes),
    );
    expect(stored.execution.outputTruncated, isTrue);
  });

  test(
    'a source over the cap is refused, and what is kept is capped',
    () async {
      await seedRun('run-huge');
      final code = '// ${'x' * (CodeExecutionPayload.maxSourceBytes + 1024)}';
      final result = await run('run-huge', code);
      expect(result.execution.status, CodeExecutionStatus.refused);
      final stored = await executions.get(workspaceId, result.execution.id);
      if (stored?.payload case final payload?) {
        expect(
          utf8.encode(payload.source).length,
          lessThanOrEqualTo(CodeExecutionPayload.maxSourceBytes),
        );
      }
    },
  );

  test('pruning a run log removes its executions', () async {
    await seedRun('run-old', completedAt: DateTime.utc(2025));
    await seedRun('run-new', completedAt: DateTime.utc(2026, 11, 16));
    final old = await run('run-old', "text('old'); return 1;");
    final kept = await run('run-new', "text('new'); return 2;");
    expect(await count('code_executions'), 2);
    expect(await count('code_execution_payloads'), 2);

    await DatabaseRetentionService(
      workspaces: dbs,
      global: global,
      now: () => DateTime.utc(2026, 11, 17),
    ).runOnce();

    expect(await executions.get(workspaceId, old.execution.id), isNull);
    expect(await executions.get(workspaceId, kept.execution.id), isNotNull);
    expect(await count('code_executions'), 1);
    expect(await count('code_execution_payloads'), 1);
  });
}
