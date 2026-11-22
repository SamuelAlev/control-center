import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/context.dart' show ToolOutputReference;
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/src/code_mode/code_execution_record.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// The record of a script whose calls outlive it, against the real runner
/// and a real workspace database: every write of one execution goes through
/// one queue, a call still running when the script ends says so, what it did
/// afterwards goes to the log, and no interleaving leaves a record running.
///
/// Runs the real runner (`CC_CODEMODE_RUNNER`, an absolute path to a built
/// `cc_codemode`).
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCodeExecutionRepository executions;
  late CodeSandboxProcess sandbox;
  late List<String> logged;

  const workspaceId = 'ws-record';

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
    await db.customStatement(
      'INSERT INTO agent_run_logs (id, agent_id, workspace_id) '
      "VALUES ('run-1', 'agent-1', ?)",
      [workspaceId],
    );
    executions = DaoCodeExecutionRepository(dbs);
    final runner = BundledCodeRunner.locate(
      appSupportRoot: Directory.systemTemp.path,
    );
    sandbox = CodeSandboxProcess(executable: runner.executable);
    expect((await sandbox.selfTest()).isAvailable, isTrue);
    logged = [];
    CcInfraLog.sink = (level, message, [error, stackTrace]) =>
        logged.add('${level.name}: $message');
  });

  tearDown(() async {
    CcInfraLog.sink = null;
    await sandbox.dispose();
    await dbs.closeAll();
    await global.close();
  });

  CodeExecutionService serviceOver(CodeExecutionRepository records) =>
      CodeExecutionService(
        sandbox: sandbox,
        executions: records,
        store: DaoCodeModeStoreRepository(dbs),
        serverProcessCap: 2,
      );

  CodeExecutionRequest request(
    String code, {
    int wallClockMs = 20000,
    int? maxOutputTokens,
    Future<ToolOutputReference?> Function(String)? sink,
  }) => CodeExecutionRequest(
    readOnly: false,
    past: null,
    workspaceId: workspaceId,
    runId: 'run-1',
    parentToolCallId: 'call_1',
    surface: CodeExecutionSurface.harness,
    code: code,
    description: 'record test',
    limits: CodeModeLimits(wallClockMs: wallClockMs),
    maxOutputTokens: maxOutputTokens,
    tools: [
      ScriptToolDescriptor(
        name: 'deploy',
        namespace: ScriptToolNamespace.builtin,
        description: 'Deploy.',
        inputSchema: const {'type': 'object'},
      ),
    ],
    agentId: 'agent-1',
    fullOutputSink: sink,
  );

  test('a call whose tool was still running when the script ended keeps '
      'its gate decision and says so; its later outcome goes to the log and '
      'the record is not changed', () async {
    final service = serviceOver(executions);
    final release = Completer<void>();
    final returned = Completer<void>();
    final result = await service.execute(
      request('await tools.deploy({}); return 1;', wallClockMs: 1000),
      callNested: (r) async {
        r.onToolStarted!(NestedCallGateDecision.approved);
        await release.future;
        returned.complete();
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: 'deployed',
          gateDecision: NestedCallGateDecision.approved,
        );
      },
    );
    expect(
      result.execution.status,
      CodeExecutionStatus.timedOut,
      reason: '${result.execution.errorKind}: ${result.result.text}',
    );
    final id = result.execution.id;
    final before = (await executions.get(workspaceId, id))!;
    expect(before.execution.status, CodeExecutionStatus.timedOut);
    final row = before.calls.single;
    expect(row.status, NestedCallStatus.cancelled);
    expect(row.gateDecision, NestedCallGateDecision.approved);
    expect(row.error, ScriptCall.stillRunningDetail);
    expect(row.durationMs, greaterThan(0));

    release.complete();
    await returned.future;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final after = (await executions.get(workspaceId, id))!;
    expect(after.calls, before.calls, reason: 'a finished record is closed');
    expect(after.execution, before.execution);
    expect(
      logged.where(
        (l) =>
            l.contains('call 1 (deploy) of $id') &&
            l.contains('settled after its script ended, as completed'),
      ),
      hasLength(1),
    );
    await service.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('a call that settles while the finish is on its way is recorded as '
      'the result states it, once; how it ended is a log line, and the record '
      'is finished', () async {
    final service = serviceOver(executions);
    final sinkEntered = Completer<void>();
    final result = await service.execute(
      request(
        "text('x'.repeat(200000)); await tools.deploy({}); return 1;",
        wallClockMs: 1000,
        maxOutputTokens: CodeModeLimits.outputTokens.floor,
        sink: (full) async {
          sinkEntered.complete();
          // The call settles now, past the settle grace, while the finish
          // is being built.
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return null;
        },
      ),
      callNested: (r) async {
        await sinkEntered.future;
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: 'deployed',
          gateDecision: NestedCallGateDecision.allowed,
        );
      },
    );
    final stored = (await executions.get(workspaceId, result.execution.id))!;
    expect(stored.execution.status, CodeExecutionStatus.timedOut);
    expect(stored.calls, hasLength(1));
    expect(stored.calls.single.status, NestedCallStatus.cancelled);
    expect(stored.calls.single.status, result.calls.single.status);
    expect(stored.calls.single.error, result.calls.single.error);
    expect(
      logged.where((l) => l.contains('settled after its script ended')),
      hasLength(1),
    );
    expect(
      logged.where((l) => l.startsWith('error:')),
      isEmpty,
      reason: logged.join('\n'),
    );
    await service.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('a finish that fails closes the record by the smallest write: it '
      'does not stay running', () async {
    final service = serviceOver(_FailingFinish(executions));
    final result = await service.execute(
      request('return 1;'),
      callNested: (r) => throw StateError('no calls'),
    );
    expect(result.result.text, contains('could not be completed'));
    final stored = (await executions.get(workspaceId, result.execution.id))!;
    expect(stored.execution.status, CodeExecutionStatus.sandboxError);
    expect(stored.execution.errorKind, CodeExecutionErrorKind.hostError);
    expect(
      logged.where((l) => l.contains('was closed as sandbox_error/host_error')),
      hasLength(1),
    );
    await service.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'a script of a run whose space was deleted is refused and not run',
    () async {
      final service = serviceOver(executions);
      var ran = false;
      final result = await service.execute(
        CodeExecutionRequest(
          readOnly: false,
          past: null,
          workspaceId: workspaceId,
          runId: 'run-1',
          parentToolCallId: 'call_1',
          surface: CodeExecutionSurface.harness,
          code: 'await tools.deploy({}); return 1;',
          description: 'gone',
          limits: CodeModeLimits.defaults,
          tools: const [],
          agentId: 'agent-1',
          spaceId: 'space-deleted',
        ),
        callNested: (r) async {
          ran = true;
          return NestedCallOutcome(status: NestedCallStatus.completed);
        },
      );
      expect(result.execution.status, CodeExecutionStatus.refused);
      expect(result.execution.errorKind, CodeExecutionErrorKind.spaceGone);
      expect(result.result.text, contains('space was deleted'));
      expect(ran, isFalse);
      expect(await executions.get(workspaceId, result.execution.id), isNull);
      await service.dispose();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

/// The real repository, except that every finish fails.
class _FailingFinish implements CodeExecutionRepository {
  _FailingFinish(this._inner);

  final CodeExecutionRepository _inner;

  @override
  Future<void> begin(
    String workspaceId,
    CodeExecution execution, {
    required String source,
  }) => _inner.begin(workspaceId, execution, source: source);

  @override
  Future<CodeExecutionAppendOutcome> appendCall(
    String workspaceId,
    CodeExecutionCall call,
  ) => _inner.appendCall(workspaceId, call);

  @override
  Future<CodeExecutionFinishResult> finish(
    String workspaceId,
    CodeExecution execution, {
    required CodeExecutionPayload payload,
    required List<CodeExecutionCall> calls,
  }) async => throw StateError('the disk is full');

  @override
  Future<bool> close(
    String workspaceId,
    String executionId, {
    required CodeExecutionStatus status,
    required String errorKind,
    required int durationMs,
  }) => _inner.close(
    workspaceId,
    executionId,
    status: status,
    errorKind: errorKind,
    durationMs: durationMs,
  );

  @override
  Future<int> highestIdSuffix(
    String workspaceId, {
    required String runId,
    required String toolCallId,
  }) =>
      _inner.highestIdSuffix(workspaceId, runId: runId, toolCallId: toolCallId);

  @override
  Future<CodeExecutionPage> list(
    String workspaceId,
    CodeExecutionQuery query,
  ) => _inner.list(workspaceId, query);

  @override
  Future<CodeExecutionDetail?> get(String workspaceId, String executionId) =>
      _inner.get(workspaceId, executionId);
}
