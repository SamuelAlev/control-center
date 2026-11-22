@TestOn('!windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart' show BashTool;
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// A script's call of a tool that guards itself (`bash`, whose command
/// runner asks the action guard, the command net and, through the run
/// gateway, about what the command does): the row of the call carries the
/// decision that actually let the tool act or stopped it, whoever asked,
/// and the model's summary line counts the call the same way.
///
/// Runs the real loop, the real `bash` tool and its real runner, the real
/// code runner (`CC_CODEMODE_RUNNER`) and a real workspace database, with a
/// fake approver.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCodeExecutionRepository executions;
  late CodeSandboxProcess sandbox;
  late CodeExecutionService service;
  late Directory cwd;
  late _Rules rules;
  late _Approver approver;

  const workspaceId = 'ws-guarded';
  const executionId = 'run-1/call_1';

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
    cwd = Directory.systemTemp.createTempSync('self_guarded_');
    rules = _Rules();
    approver = _Approver();
  });

  tearDown(() async {
    await service.dispose();
    await sandbox.dispose();
    await dbs.closeAll();
    await global.close();
    cwd.deleteSync(recursive: true);
  });

  /// Runs a script that calls `bash` once per command in [commands],
  /// catching each refusal, through a loop whose `bash` runs on the host
  /// with the guard over [rules] and [approver]; [relay] stands in for the
  /// run gateway. Returns the script's result.
  Future<CodeExecutionResult> runScript(
    List<String> commands, {
    CommandWaitRelay? relay,
  }) async {
    final origins = RunScriptOrigins(runId: 'run-1')
      ..begin('call_1', executionId);
    final bash = BashTool(
      SandboxedHarnessCommandRunner(
        mode: Mode.chat,
        networkEnabled: false,
        confirmationPort: approver,
        actionGuard: ActionGuardService(
          repository: rules,
          confirmationPort: approver,
        ),
        hostProcesses: const HostToolProcessLauncher(),
        workspaceId: workspaceId,
        agentId: 'agent-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
        scriptOrigins: origins,
        callWaits: relay,
      ),
    );
    final list = commands.map((c) => "'$c'").join(', ');
    final code =
        '''
const out = [];
for (const command of [$list]) {
  try {
    await tools.bash({ command, description: 'Run one check command' });
    out.push('ok');
  } catch (e) {
    out.push('refused');
  }
}
return out;
''';
    final executed = Completer<CodeExecutionResult>();
    final parent = _Parent((context) async {
      try {
        executed.complete(
          await service.execute(
            CodeExecutionRequest(
              readOnly: false,
              past: null,
              workspaceId: workspaceId,
              runId: 'run-1',
              parentToolCallId: 'call_1',
              surface: CodeExecutionSurface.harness,
              code: code,
              description: 'runs commands',
              limits: CodeModeLimits(wallClockMs: 20000),
              tools: [
                ScriptToolDescriptor(
                  name: 'bash',
                  namespace: ScriptToolNamespace.builtin,
                  description: 'bash.',
                  inputSchema: const {'type': 'object'},
                ),
              ],
              agentId: 'agent-1',
            ),
            callNested: (call) => callThroughReentry(context.reentry!, call),
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
          tools: [parent, bash],
          provider: _Provider(),
          context: HarnessToolContext(workingDirectory: cwd.path),
        )
        .drain<void>();
    addTearDown(() => run);
    return executed.future;
  }

  Future<List<(NestedCallStatus, NestedCallGateDecision?, int)>> rows() async {
    final detail = (await executions.get(workspaceId, executionId))!;
    return [
      for (final c in detail.calls)
        (c.status, c.gateDecision, c.approvalWaitMs),
    ];
  }

  test('a card a person approved reads approved', () async {
    rules.add(ActionDecision.prompt);
    approver.delay = const Duration(milliseconds: 50);
    final result = await runScript(['true']);

    final [(status, gate, waited)] = await rows();
    expect(status, NestedCallStatus.completed);
    expect(gate, NestedCallGateDecision.approved);
    expect(waited, greaterThan(0));
    expect(result.result.text, contains('1 tool call (1 ok)'));
  });

  test('a declined card and the refusal after it read denied, in the '
      'record and in the summary the model reads', () async {
    rules.add(ActionDecision.prompt);
    approver.answer = false;
    final result = await runScript(['true', 'true']);

    expect(approver.requests, hasLength(1));
    final got = await rows();
    expect(got.map((r) => (r.$1, r.$2)), [
      (NestedCallStatus.denied, NestedCallGateDecision.denied),
      (NestedCallStatus.denied, NestedCallGateDecision.denied),
    ]);
    final detail = (await executions.get(workspaceId, executionId))!;
    expect(detail.execution.callCounts.denied, 2);
    expect(detail.execution.callCounts.failed, 0);
    expect(detail.calls.last.error, contains('already declined'));
    expect(result.result.text, contains('2 tool calls (2 denied)'));
  });

  test('a policy denial inside the tool reads denied, with no card', () async {
    rules.add(ActionDecision.deny);
    final result = await runScript(['true']);

    expect(approver.requests, isEmpty);
    final [(status, gate, waited)] = await rows();
    expect(
      (status, gate, waited),
      (NestedCallStatus.denied, NestedCallGateDecision.denied, 0),
    );
    expect(result.result.text, contains('1 tool call (1 denied)'));
  });

  test('a command nobody was asked about reads allowed', () async {
    final result = await runScript(['true']);

    expect(approver.requests, isEmpty);
    final [(status, gate, _)] = await rows();
    expect(
      (status, gate),
      (NestedCallStatus.completed, NestedCallGateDecision.allowed),
    );
    expect(result.result.text, contains('1 tool call (1 ok)'));
  });

  test('a gateway card for a request the command made: declined reads '
      'denied, approved reads approved', () async {
    // The run gateway decides a request the running command made (a push)
    // and tells the command's registration (`CommandWaitRelay.register`).
    final relay = _Gateway([false, true]);
    final result = await runScript(['sleep 0.2', 'sleep 0.2'], relay: relay);

    expect((await rows()).map((r) => (r.$1, r.$2)), [
      (NestedCallStatus.denied, NestedCallGateDecision.denied),
      (NestedCallStatus.completed, NestedCallGateDecision.approved),
    ]);
    expect(result.result.text, contains('2 tool calls (1 ok, 1 denied)'));
  });
}

/// Stands in for the run gateway: each registered command gets the next
/// decision of [decisions] while it runs, after a card's wait.
class _Gateway implements CommandWaitRelay {
  _Gateway(this.decisions);

  final List<bool> decisions;
  var _next = 0;

  @override
  CommandWait register(
    PersonWaitListener listener,
    Map<String, String> env, {
    required void Function(bool approved) decided,
  }) {
    final approved = decisions[_next++];
    unawaited(() async {
      listener(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      listener(false);
      decided(approved);
    }());
    return CommandWait(environment: const {}, release: () {});
  }

  @override
  void Function() holdScriptApprovals(ScriptApprovalBudget approvals) => () {};
}

class _Approver implements ConfirmationPort {
  bool answer = true;
  Duration? delay;
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    final d = delay;
    if (d != null) {
      await Future<void>.delayed(d);
    }
    return answer;
  }
}

class _Rules implements ActionPolicyRepository {
  final list = <ActionPolicyRule>[];

  void add(ActionDecision decision) {
    final now = DateTime.now();
    list.add(
      ActionPolicyRule(
        id: 'spawn-${decision.wire}',
        workspaceId: 'ws-guarded',
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: ActionClass.processSpawn,
        decision: decision,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => list;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  String get displayName => 'Self-guarded scenario';
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
