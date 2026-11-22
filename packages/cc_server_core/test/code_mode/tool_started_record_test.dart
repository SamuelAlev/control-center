import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/src/code_mode/code_execution_record.dart';
import 'package:cc_mcp/cc_mcp.dart' show McpToolDispatcher;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// Each surface tells the record when a script's call got past its gate and
/// its tool started (`NestedCallRequest.onToolStarted`): a call whose script
/// stopped waiting while that tool still ran leaves a row that keeps the
/// gate's decision and says the tool was still running, and a call given up
/// on before its tool started does not.
///
/// Runs the real runner (`CC_CODEMODE_RUNNER`, an absolute path to a built
/// `cc_codemode`) against a real workspace database.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCodeExecutionRepository executions;
  late CodeSandboxProcess sandbox;
  late CodeExecutionService service;
  late Completer<void> release;
  late Completer<void> deployStarted;

  const workspaceId = 'ws-started';

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
    service = CodeExecutionService(
      sandbox: sandbox,
      executions: executions,
      store: DaoCodeModeStoreRepository(dbs),
      serverProcessCap: 2,
    );
    release = Completer<void>();
    deployStarted = Completer<void>();
  });

  tearDown(() async {
    if (!release.isCompleted) {
      release.complete();
    }
    await service.dispose();
    await sandbox.dispose();
    await dbs.closeAll();
    await global.close();
  });

  CodeExecutionRequest request(
    CodeExecutionSurface surface, {
    String code = 'await tools.deploy({}); return 1;',
    int wallClockMs = 1000,
  }) => CodeExecutionRequest(
    readOnly: false,
    past: null,
    workspaceId: workspaceId,
    runId: 'run-1',
    parentToolCallId: 'call_1',
    surface: surface,
    code: code,
    description: 'outlives its script',
    limits: CodeModeLimits(wallClockMs: wallClockMs),
    tools: [
      for (final name in ['deploy', 'ping'])
        ScriptToolDescriptor(
          name: name,
          namespace: ScriptToolNamespace.builtin,
          description: '$name.',
          inputSchema: const {'type': 'object'},
        ),
    ],
    agentId: 'agent-1',
  );

  /// The one call row of the record [executionId], once the script ended:
  /// [status], the gate's decision kept, and the tool still running.
  Future<void> expectStillRunning(
    String executionId, {
    CodeExecutionStatus script = CodeExecutionStatus.timedOut,
    NestedCallStatus status = NestedCallStatus.cancelled,
  }) async {
    final detail = (await executions.get(workspaceId, executionId))!;
    expect(detail.execution.status, script);
    final row = detail.calls.single;
    expect(row.status, status);
    expect(row.gateDecision, NestedCallGateDecision.allowed);
    expect(row.error, ScriptCall.stillRunningDetail);
  }

  /// Runs `parent` in a loop with [tools] and [config]: its body runs the
  /// script [code] on the harness surface.
  ///
  /// `ping` returns once [pingAfter] completes. [callDeadline], when given,
  /// replaces each call's deadline (the script's remaining time) with a
  /// shorter one, as the loop's own tool timeout does.
  Future<CodeExecutionResult> runOnHarness({
    required String code,
    required Future<void> pingAfter,
    int wallClockMs = 1000,
    Duration? callDeadline,
    AgentLoopConfig config = const AgentLoopConfig(),
  }) async {
    final executed = Completer<CodeExecutionResult>();
    final parent = _Parent((context) async {
      try {
        executed.complete(
          await service.execute(
            request(
              CodeExecutionSurface.harness,
              code: code,
              wallClockMs: wallClockMs,
            ),
            callNested: (call) => callThroughReentry(
              context.reentry!,
              callDeadline == null ? call : _withDeadline(call, callDeadline),
            ),
          ),
        );
      } on Object catch (e, st) {
        executed.completeError(e, st);
      }
    });
    final run = const AgentLoopRunner()
        .run(
          history: <HarnessMessage>[],
          userMessage: 'Run the script.',
          tools: [
            parent,
            _HarnessDeploy(release.future, deployStarted),
            _Ping(pingAfter),
          ],
          provider: _Provider(),
          config: config,
        )
        .drain<void>();
    addTearDown(() async {
      if (!release.isCompleted) {
        release.complete();
      }
      await run;
    });
    return executed.future;
  }

  /// The server log lines from here on.
  List<String> logLines() {
    final lines = <String>[];
    final previous = CcInfraLog.sink;
    CcInfraLog.sink = (level, message, [error, stackTrace]) =>
        lines.add(message);
    addTearDown(() => CcInfraLog.sink = previous);
    return lines;
  }

  /// Lets [release] return the held tool, then expects the one log line
  /// saying how call 1 of [executionId] ended after its script stopped
  /// waiting for it.
  Future<void> expectLateReturnLogged(
    List<String> lines,
    String executionId,
  ) async {
    release.complete();
    for (var i = 0; i < 100 && !lines.any((l) => l.contains('returned')); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(
      lines.where((l) => l.contains('returned after the script stopped')),
      [
        allOf(
          contains('call 1 (deploy) of $executionId'),
          contains('as completed'),
        ),
      ],
    );
  }

  test('on MCP', () async {
    final dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([_McpDeploy(release.future)]),
    );
    const scope = McpCallScope(
      workspaceId: workspaceId,
      agentId: 'agent-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      attested: true,
      runId: 'dispatch-1',
      runLogId: 'run-1',
    );
    final approvals = ScriptApprovalBudget();

    final result = await service.execute(
      request(CodeExecutionSurface.mcp),
      callNested: (call) =>
          dispatcher.callNested(scope, call, approvals: approvals),
    );

    await expectStillRunning(result.execution.id);
  }, timeout: const Timeout(Duration(seconds: 60)));

  // The harness gate gives up on a tool at the call's deadline and at the
  // script's end, and settles the call at once: the script never waits on a
  // tool the gate stopped waiting for. A tool it gave up on after it started
  // keeps its status and decision and says it was still running; how it
  // ended goes to the server log.
  group('on the harness', () {
    test('at the call\'s deadline', () async {
      final lines = logLines();
      final result = await runOnHarness(
        code:
            'try { await tools.deploy({}); return "resolved"; } '
            'catch (e) { return "rejected: " + e.message; }',
        pingAfter: Future<void>.value(),
        wallClockMs: 10000,
        callDeadline: const Duration(milliseconds: 300),
      );

      await expectStillRunning(
        result.execution.id,
        script: CodeExecutionStatus.completed,
        status: NestedCallStatus.timedOut,
      );
      // What the script itself was told: the same detail.
      expect(
        result.result.text,
        contains('rejected: ${ScriptCall.stillRunningDetail}'),
      );
      await expectLateReturnLogged(lines, result.execution.id);
    });

    test('at the script\'s end', () async {
      final lines = logLines();
      // `deploy` has started by the time `ping` returns, and the script
      // ends without waiting for it.
      final result = await runOnHarness(
        code: 'tools.deploy({}); await tools.ping({}); return 1;',
        pingAfter: deployStarted.future,
      );

      expect(deployStarted.isCompleted, isTrue);
      final detail = (await executions.get(workspaceId, result.execution.id))!;
      expect(detail.execution.status, CodeExecutionStatus.completed);
      final row = detail.calls.firstWhere((c) => c.toolName == 'deploy');
      expect(row.status, NestedCallStatus.cancelled);
      expect(row.gateDecision, NestedCallGateDecision.allowed);
      expect(row.error, ScriptCall.stillRunningDetail);
      await expectLateReturnLogged(lines, result.execution.id);
    });

    test('given up on before the tool started, the row says so', () async {
      final entered = Completer<void>();
      // `deploy` is held in its pre-tool hook when `ping` returns, and the
      // script ends without waiting for it.
      final result = await runOnHarness(
        code: 'tools.deploy({}); await tools.ping({}); return 1;',
        pingAfter: entered.future,
        config: AgentLoopConfig(
          steering: LoopSteeringConfig(
            hooks: _SlowBefore(release.future, entered),
          ),
        ),
      );

      final detail = (await executions.get(workspaceId, result.execution.id))!;
      final row = detail.calls.firstWhere((c) => c.toolName == 'deploy');
      expect(row.status, NestedCallStatus.cancelled);
      expect(row.gateDecision, isNull);
      expect(row.error, 'Tool "deploy" was cancelled.');
      expect(deployStarted.isCompleted, isFalse);
    });
  });
}

/// Holds the pre-tool hook of `deploy` until [release] completes, after
/// completing [entered].
class _SlowBefore implements AgentLoopHooks {
  _SlowBefore(this.release, this.entered);

  final Future<void> release;
  final Completer<void> entered;

  @override
  bool get interceptsTools => true;
  @override
  Future<void> onSessionStart() async {}
  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    if (toolName == 'deploy') {
      entered.complete();
      await release;
    }
    return true;
  }

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {}
}

/// An MCP tool nobody is asked about that returns once [release] completes.
class _McpDeploy extends McpTool {
  _McpDeploy(this.release);

  final Future<void> release;

  @override
  String get name => 'deploy';
  @override
  String get description => 'Deploy.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    await release;
    return CallResult.success('deployed');
  }
}

/// A read-tier harness tool that completes [started] when it starts and
/// returns once [release] completes.
class _HarnessDeploy extends HarnessTool {
  _HarnessDeploy(this.release, this.started);

  final Future<void> release;
  final Completer<void> started;

  @override
  String get name => 'deploy';
  @override
  String get description => 'Deploy.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    started.complete();
    await release;
    return HarnessToolResult.success('deployed');
  }
}

/// A read-tier harness tool that returns once [after] completes.
class _Ping extends HarnessTool {
  _Ping(this.after);

  final Future<void> after;

  @override
  String get name => 'ping';
  @override
  String get description => 'Ping.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    await after;
    return HarnessToolResult.success('pong');
  }
}

/// [call] with [deadline] in place of its own.
NestedCallRequest _withDeadline(NestedCallRequest call, Duration deadline) =>
    NestedCallRequest(
      sequence: call.sequence,
      toolCallId: call.toolCallId,
      name: call.name,
      arguments: call.arguments,
      origin: call.origin,
      deadline: deadline,
      site: null,
      cancel: call.cancel,
      onPersonWait: call.onPersonWait,
      onToolStarted: call.onToolStarted,
    );

/// The shape `repl` has: self-guarding, not parallel-safe, and its body runs
/// the script with the call's reentry.
class _Parent extends HarnessTool {
  _Parent(this.body);

  final Future<void> Function(HarnessToolContext context) body;

  @override
  String get name => 'parent';
  @override
  String get description => 'Runs a script.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  bool get selfGuards => true;
  @override
  bool get parallelSafe => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    await body(context);
    return HarnessToolResult.success('script finished');
  }
}

/// Calls `parent` on turn one, then answers in text.
class _Provider extends LlmProviderPort {
  int calls = 0;

  @override
  String get displayName => 'Tool started scenario';
  @override
  String get defaultModel => 'controlled';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    if (calls++ == 0) {
      yield const LlmToolUseDelta(
        id: 'call_1',
        name: 'parent',
        argumentsJson: '{}',
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}
