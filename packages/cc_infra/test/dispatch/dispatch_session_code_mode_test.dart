import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/harness/repl_tool.dart' show ReplTool;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

const _replCallId = 'call_repl';

class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keeps the composition snapshot the session records for its run.
class _RunLogs implements AgentRunLogRepository {
  final snapshots = <String>[];

  @override
  Future<void> upsert(AgentRunLog log) async {}

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => null;

  @override
  Future<bool> completeIfActive(
    AgentRunLog completed, {
    bool writeCost = true,
  }) async => false;

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async {
    if (contextSnapshotJson != null) {
      snapshots.add(contextSnapshotJson);
    }
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _KeylessStore implements ProviderCredentialStore {
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      ProviderCredential(
        providerId: providerId,
        method: HarnessAuthMethod.none,
        baseUrl: 'http://127.0.0.1:1',
      );

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    (await activeCredential(providerId))!,
  ];

  @override
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

class _RecordingApprover implements ConfirmationPort {
  _RecordingApprover(this.answer);

  final bool answer;
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    return answer;
  }
}

class _NoBroker implements CredentialBrokerPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Rules implements ActionPolicyRepository {
  _Rules(this.values);

  final List<ActionPolicyRule> values;

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => values;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A read-tier MCP tool: an ordinary bridged tool, which the chat surface
/// defers (and so code mode moves behind the script tool).
class _McpTool extends McpTool {
  _McpTool(this.name, {this.scriptCallable = true});

  @override
  final String name;
  @override
  final bool scriptCallable;
  @override
  String get description => 'The $name operation.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('$name ran');
}

/// The execution service a session with code mode gets. These tests run the
/// [_FakeRepl] in place of the session's own `repl`, so it never runs a
/// script; it only puts a script tool on the session's surface.
class _IdleExecutions implements CodeExecutionPort {
  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) => throw UnimplementedError('these tests replace the repl tool');
}

/// The `repl` the loop runs in place of the session's own: its body is the
/// test's script, given the call's reentry.
class _FakeRepl extends HarnessTool {
  _FakeRepl(this._body);

  final Future<String> Function(ToolReentry reentry) _body;

  @override
  String get name => 'repl';
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
  bool get scriptCallable => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success(await _body(context.reentry!));
}

/// Calls `repl` on turn one, then answers in text.
class _ReplProvider extends LlmProviderPort {
  int _calls = 0;

  @override
  String get displayName => 'Code mode scenario';
  @override
  String get defaultModel => 'test-model';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    if (_calls++ == 0) {
      yield const LlmToolUseDelta(
        id: _replCallId,
        name: 'repl',
        argumentsJson: '{}',
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

typedef _Started = ({
  List<HarnessTool> tools,
  List<HarnessTool> deferredTools,
  List<HarnessTool> scriptTools,
  AgentLoopConfig config,
});

/// Records what every loop was started with. The first (the session's own
/// run) either runs the real loop with [script] as its `repl`, or calls
/// `task` when [spawnChild]; any later run is a subagent and ends at once.
class _CodeModeLoop implements AgentLoop {
  _CodeModeLoop({this.script, this.spawnChild = false, this.whileRunning});

  final Future<String> Function(ToolReentry reentry)? script;

  /// Runs once, when the session's own run starts (its lease open).
  final void Function()? whileRunning;
  final bool spawnChild;
  final started = <_Started>[];
  final events = <AgentLoopEvent>[];
  String? replOutput;

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    List<HarnessTool> deferredTools = const [],
    List<HarnessTool> scriptTools = const [],
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) {
    started.add((
      tools: tools,
      deferredTools: deferredTools,
      scriptTools: scriptTools,
      config: config,
    ));
    if (started.length > 1) {
      return Stream.value(const LoopDone(LoopDoneReason.completed));
    }
    whileRunning?.call();
    if (spawnChild) {
      return () async* {
        final task = tools.firstWhere((t) => t.name == 'task');
        await task.execute(
          const {'description': 'look around', 'label': 'scout'},
          (context ?? const HarnessToolContext(workingDirectory: '.'))
              .withToolCallId('call-task'),
        );
        yield const LoopDone(LoopDoneReason.completed);
      }();
    }
    final body = script;
    if (body == null) {
      return Stream.value(const LoopDone(LoopDoneReason.completed));
    }
    final repl = _FakeRepl((reentry) async {
      final output = await body(reentry);
      replOutput = output;
      return output;
    });
    return const AgentLoopRunner()
        .run(
          history: history,
          userMessage: userMessage,
          tools: [for (final tool in tools) tool.name == 'repl' ? repl : tool],
          deferredTools: deferredTools,
          scriptTools: scriptTools,
          provider: _ReplProvider(),
          context: context,
          config: config,
          cancel: cancel,
        )
        .map((event) {
          events.add(event);
          return event;
        });
  }
}

typedef _Session = ({
  DispatchSession session,
  _CodeModeLoop loop,
  _RunLogs runLogs,
  Directory dir,
});

_Session _build({
  required _CodeModeLoop loop,
  bool withRepl = true,
  ConfirmationPort? confirmationPort,
  ActionGuardService? actionGuard,
  AgentRunGateway? gateway,
  String? runLogId = 'run-1',
  List<McpTool> extraMcpTools = const [],
}) {
  final dir = Directory.systemTemp.createTempSync('cc_code_mode_');
  addTearDown(() => deleteDirBestEffort(dir));
  final runLogs = _RunLogs();
  final deps = SandboxDispatchDeps(
    hostExecution: const HostExecutionGate(
      posture: HostExecutionPosture.offByOwner,
    ),
    sandbox: _NoopSandbox(),
    agentRepo: _UnusedAgentRepo(),
    runLogRepo: runLogs,
    eventBus: null,
    resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
        AgentCommitIdentity.person((
          name: 'Test User',
          email: 'test@example.test',
        )),
    backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
    harnessCredentialStore: _KeylessStore(),
    harnessProviderFactory: const HarnessProviderFactory(),
    agentLoop: loop,
    mcpRegistry: McpToolRegistry([_McpTool('lookup_thing'), ...extraMcpTools]),
    codeExecutions: withRepl ? _IdleExecutions() : null,
    confirmationPort: confirmationPort,
    actionGuard: actionGuard,
    agentRunGateway: gateway,
  );
  final session = DispatchSession(
    freshHistory: false,
    readOnly: false,
    deps: deps,
    onResolveHandle:
        ({
          required String sessionId,
          required SandboxSpec spec,
          required void Function(AgentProcessEvent) emit,
        }) async => SandboxHandle(
          sessionId: sessionId,
          backend: SandboxBackend.none,
          state: SandboxState.warm,
        ),
    onScheduleCooldown: (_) {},
    dispatchId: 'dispatch-1',
    cliName: 'cc-harness',
    prompt: 'go',
    agentDirHostPath: dir.path,
    modelId: 'openai/test-model',
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    runLogId: runLogId,
    mode: Mode.chat,
  );
  return (session: session, loop: loop, runLogs: runLogs, dir: dir);
}

Future<List<AgentProcessEvent>> _drain(DispatchSession session) async {
  final events = <AgentProcessEvent>[];
  final sub = session.controller.stream.listen(events.add);
  await session.run();
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sub.cancel();
  return events;
}

List<String> _names(List<HarnessTool> tools) => [for (final t in tools) t.name];

ActionPolicyRule _rule(ActionDecision decision) {
  final now = DateTime.now();
  return ActionPolicyRule(
    id: 'space-write-${decision.name}',
    workspaceId: 'ws-1',
    scopeType: ActionScopeType.space,
    scopeId: 'space-1',
    actionClass: ActionClass.fileWriteOutsideWorktree,
    decision: decision,
    createdAt: now,
    updatedAt: now,
  );
}

/// What the loop's gate hands its approval callback for one call.
ToolApprovalRequest _ask(
  HarnessTool tool,
  Map<String, dynamic> args,
  ToolCallOrigin origin, {
  CancellationToken withdrawn = CancellationToken.none,
  PersonWaitListener? onPersonWait,
}) => ToolApprovalRequest(
  tool: tool,
  args: args,
  origin: origin,
  withdrawn: withdrawn,
  onPersonWait: onPersonWait ?? (_) {},
);

void main() {
  test('the session names one run id for code mode', () {
    final withLog = _build(loop: _CodeModeLoop()).session;
    expect(withLog.hasRunLogRow, isTrue);
    expect(withLog.codeModeRunId, 'run-1');

    final withoutLog = _build(loop: _CodeModeLoop(), runLogId: null).session;
    expect(withoutLog.hasRunLogRow, isFalse);
    expect(withoutLog.codeModeRunId, 'dispatch-1');
  });

  test('a run hands the loop its script-only tools and records that it has '
      'scripts', () async {
    final h = _build(loop: _CodeModeLoop());

    await _drain(h.session);

    final run = h.loop.started.single;
    expect(run.tools.first.name, 'repl');
    expect(_names(run.scriptTools), contains('lookup_thing'));
    expect(_names(run.tools), isNot(contains('lookup_thing')));
    // Only a tool a script may not call is deferred.
    expect(run.deferredTools.where((t) => t.scriptCallable), isEmpty);
    expect(run.config.systemPrompt, contains('callable from `repl`'));

    final snapshot =
        jsonDecode(h.runLogs.snapshots.single) as Map<String, dynamic>;
    expect(snapshot['scripts'], {'available': true});
    expect(snapshot['scriptOnlyTools'], contains('lookup_thing'));
    expect(snapshot['scriptOnlyToolCount'], run.scriptTools.length);
  });

  test('a run keeps a tool a script may not call deferred, behind '
      'search_tools', () async {
    final h = _build(
      loop: _CodeModeLoop(),
      extraMcpTools: [_McpTool('hand_off', scriptCallable: false)],
    );

    await _drain(h.session);

    final run = h.loop.started.single;
    expect(_names(run.tools).take(2), ['repl', 'search_tools']);
    expect(_names(run.tools), isNot(contains('hand_off')));
    expect(_names(run.deferredTools), contains('hand_off'));
    expect(_names(run.scriptTools), contains('lookup_thing'));
    expect(_names(run.scriptTools), isNot(contains('hand_off')));
    // Both indexes are in the prompt: the deferred one points at a direct
    // call or `search_tools`, the script-only one at `repl`.
    expect(run.config.systemPrompt, contains('not loaded yet'));
    expect(run.config.systemPrompt, contains('callable from `repl`'));
    // Where hand_off is not: the `repl` description (which names no tool,
    // only namespaces and their counts), the catalog a script searches and
    // calls, and the request's definitions.
    final repl = run.tools.first as ReplTool;
    expect(repl.description, isNot(contains('hand_off')));
    expect(repl.description, contains('- control-center ('));
    final catalog = [for (final t in repl.scriptTools) t.name];
    expect(catalog, contains('lookup_thing'));
    expect(catalog, isNot(contains('hand_off')));
    expect([
      for (final t in run.tools) t.toSchema().name,
    ], isNot(contains('hand_off')));
    // Where it is: behind search_tools, which finds it as a direct tool (not
    // a script-only one) and loads it for the rest of the run; and in the
    // deferred list, whose tools the loop calls by name on first use.
    const ctx = HarnessToolContext(workingDirectory: '.');
    final search = run.tools[1];
    final found = await search.execute(const {'query': 'hand off'}, ctx);
    final match = ((jsonDecode(found.content) as Map)['matches'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((m) => m['name'] == 'hand_off');
    expect(match['already_loaded'], isFalse);
    expect(match, isNot(contains('script_only')));
    expect(found.activateTools, contains('hand_off'));
    final deferred = run.deferredTools.singleWhere((t) => t.name == 'hand_off');
    expect((await deferred.execute(const {}, ctx)).content, 'hand_off ran');
    final snapshot =
        jsonDecode(h.runLogs.snapshots.single) as Map<String, dynamic>;
    expect(snapshot['scriptOnlyTools'], isNot(contains('hand_off')));
  });

  test('without an execution service the run has no repl, defers what is '
      'not direct, and says why', () async {
    final h = _build(loop: _CodeModeLoop(), withRepl: false);

    await _drain(h.session);

    final run = h.loop.started.single;
    expect(_names(run.tools), isNot(contains('repl')));
    expect(run.scriptTools, isEmpty);
    expect(_names(run.deferredTools), contains('lookup_thing'));
    final snapshot =
        jsonDecode(h.runLogs.snapshots.single) as Map<String, dynamic>;
    expect(snapshot['scripts'], {
      'available': false,
      'reason': 'this server runs no scripts',
    });
    expect(snapshot['scriptOnlyTools'], isEmpty);
  });

  test('a nested gated call raises a card that names its script, and a '
      'declined one never runs', () async {
    final approver = _RecordingApprover(false);
    final audits = <GuardAudit>[];
    late _Session h;
    ToolReentryOutcome? outcome;
    h = _build(
      confirmationPort: approver,
      actionGuard: ActionGuardService(
        repository: _Rules([_rule(ActionDecision.prompt)]),
        onAudit: audits.add,
      ),
      loop: _CodeModeLoop(
        script: (reentry) async {
          outcome = await reentry.call('write', {
            'path': p.join(h.dir.path, 'from-script.txt'),
            'content': 'scripted',
          });
          return 'script done';
        },
      ),
    );

    await _drain(h.session);

    expect(outcome?.status, ToolReentryStatus.denied);
    expect(File(p.join(h.dir.path, 'from-script.txt')).existsSync(), isFalse);
    final request = approver.requests.single;
    // This fake `repl` registers no execution, so the card names none.
    expect(request.origin, ScriptCallOrigin(parentToolCallId: _replCallId));
    final audit = audits.single;
    expect(audit.decision, ActionDecision.deny);
    expect(audit.prompted, isTrue);
    expect(audit.runId, 'run-1');
  });

  test('a nested call the policy denies never runs and is audited like a '
      'direct one', () async {
    final approver = _RecordingApprover(true);
    final audits = <GuardAudit>[];
    late _Session h;
    ToolReentryOutcome? outcome;
    h = _build(
      confirmationPort: approver,
      actionGuard: ActionGuardService(
        repository: _Rules([_rule(ActionDecision.deny)]),
        onAudit: audits.add,
      ),
      loop: _CodeModeLoop(
        script: (reentry) async {
          outcome = await reentry.call('write', {
            'path': p.join(h.dir.path, 'denied.txt'),
            'content': 'scripted',
          });
          return 'script done';
        },
      ),
    );

    await _drain(h.session);

    expect(outcome?.status, ToolReentryStatus.denied);
    expect(outcome?.gate?.verdict, ToolGateVerdict.denied);
    expect(File(p.join(h.dir.path, 'denied.txt')).existsSync(), isFalse);
    expect(approver.requests, isEmpty);
    expect(audits.single.decision, ActionDecision.deny);
    expect(audits.single.ruleId, 'space-write-deny');
  });

  test('an allowed nested call runs and reaches the transcript under its '
      'parent', () async {
    late _Session h;
    h = _build(
      confirmationPort: _RecordingApprover(true),
      loop: _CodeModeLoop(
        script: (reentry) async {
          final lookup = await reentry.call('lookup_thing', const {});
          return lookup.result.content;
        },
      ),
    );

    final events = await _drain(h.session);

    expect(h.loop.replOutput, 'lookup_thing ran');
    final nested = events.whereType<ToolCallEvent>().singleWhere(
      (e) => e.toolName == 'lookup_thing',
    );
    expect(nested.parentToolCallId, _replCallId);
    expect(nested.toolCallId, '$_replCallId/1');
    final nestedResult = events.whereType<ToolResultEvent>().singleWhere(
      (e) => e.toolCallId == '$_replCallId/1',
    );
    expect(nestedResult.parentToolCallId, _replCallId);
  });

  test('a script\'s card names the execution the script runs as, which can '
      'differ from the derived id', () async {
    final approver = _RecordingApprover(false);
    late _Session h;
    h = _build(
      confirmationPort: approver,
      loop: _CodeModeLoop(script: (reentry) async => 'unused'),
    );

    await _drain(h.session);
    final approval = h.loop.started.single.config.tools.approvalCallback!;
    // The tool call id repeated in this run, so the service named this
    // execution `#2`.
    h.session.scriptOrigins.begin('call_again', 'run-1/call_again#2');
    await approval(
      _ask(
        WriteTool(),
        {'path': p.join(h.dir.path, 'again.txt'), 'content': 'x'},
        const ToolCallOrigin(
          toolCallId: 'call_again/1',
          parentToolUseId: 'call_again',
        ),
      ),
    );
    h.session.scriptOrigins.end('call_again', 'run-1/call_again#2');

    expect(
      approver.requests.single.origin,
      ScriptCallOrigin(
        parentToolCallId: 'call_again',
        executionId: 'run-1/call_again#2',
      ),
    );
  });

  test('a direct call\'s card carries no origin', () async {
    final approver = _RecordingApprover(false);
    late _Session h;
    h = _build(
      confirmationPort: approver,
      loop: _CodeModeLoop(script: (reentry) async => 'unused'),
    );

    await _drain(h.session);
    // The loop's own config: the approval callback asked directly.
    final approval = h.loop.started.single.config.tools.approvalCallback!;
    await approval(
      _ask(WriteTool(), {
        'path': p.join(h.dir.path, 'direct.txt'),
        'content': 'x',
      }, const ToolCallOrigin(toolCallId: 'call-direct')),
    );
    expect(approver.requests.single.origin, isNull);
  });

  test('the gateway grant carries the run log row', () async {
    final gateway = AgentRunGateway(
      guard: ActionGuardService(repository: _Rules(const [])),
      broker: _NoBroker(),
      loopbackBase: () async => Uri.parse('http://127.0.0.1:9'),
    );
    AgentRunGrant? grant;
    final h = _build(
      gateway: gateway,
      loop: _CodeModeLoop(
        whileRunning: () => grant = gateway
            .openRuns(workspaceId: 'ws-1', conversationId: 'conv-1')
            .single
            .grant,
      ),
    );

    await _drain(h.session);

    expect(grant?.runLogId, 'run-1');
    // The harness calls its tools in-process: its secret opens no MCP call.
    expect(grant?.mcpEndpoint, isFalse);
    expect(h.loop.started.single.tools.first.name, 'repl');
  });

  test('a subagent gets repl as its parent does', () async {
    final h = _build(loop: _CodeModeLoop(spawnChild: true));

    await _drain(h.session);

    expect(h.loop.started, hasLength(2));
    final child = h.loop.started.last;
    expect(child.tools.first.name, 'repl');
    expect(_names(child.scriptTools), contains('lookup_thing'));
    expect(child.deferredTools.where((t) => t.scriptCallable), isEmpty);
  });

  test('a subagent keeps a tool a script may not call deferred, as its '
      'parent does', () async {
    final h = _build(
      loop: _CodeModeLoop(spawnChild: true),
      extraMcpTools: [_McpTool('hand_off', scriptCallable: false)],
    );

    await _drain(h.session);

    final child = h.loop.started.last;
    expect(_names(child.tools).take(2), ['repl', 'search_tools']);
    expect(_names(child.deferredTools), contains('hand_off'));
    expect(_names(child.scriptTools), isNot(contains('hand_off')));
  });

  group('a script\'s card', () {
    // The review's proof: a script fired a gated call and returned without
    // awaiting it. The card stayed up with no way to take it down, and a
    // person's late approve was audited as an allowed, prompted action.
    for (final honoursWithdrawal in [true, false]) {
      test('is withdrawn when its script stops waiting, and a late answer '
          '${honoursWithdrawal ? '(none: the port resolves no)' : 'of yes'} '
          'is a denial that writes nothing', () async {
        final approver = _HeldApprover(honoursWithdrawal: honoursWithdrawal);
        final audits = <GuardAudit>[];
        late _Session h;
        ToolReentryOutcome? outcome;
        h = _build(
          confirmationPort: approver,
          actionGuard: ActionGuardService(
            repository: _Rules([_rule(ActionDecision.prompt)]),
            onAudit: audits.add,
          ),
          loop: _CodeModeLoop(
            script: (reentry) async {
              unawaited(
                reentry
                    .call('write', {
                      'path': p.join(h.dir.path, 'from-script.txt'),
                      'content': 'scripted',
                    })
                    .then((o) => outcome = o),
              );
              while (approver.requests.isEmpty) {
                await Future<void>.delayed(const Duration(milliseconds: 5));
              }
              return 'script done';
            },
          ),
        );

        await _drain(h.session);

        expect(outcome?.status, ToolReentryStatus.cancelled);
        final card = approver.requests.single;
        expect(card.withdrawn, isNotNull);
        if (!honoursWithdrawal) {
          // The run is over. A person now approves the stale card.
          approver.answers.single.complete(true);
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(audits.single.decision, ActionDecision.deny);
        expect(audits.single.prompted, isTrue);
        expect(
          File(p.join(h.dir.path, 'from-script.txt')).existsSync(),
          isFalse,
        );
      });
    }

    test('stops coming after a person declines one, and after '
        '${CodeModeLimits.maxApprovalAsks} asks', () async {
      final approver = _RecordingApprover(false);
      final audits = <GuardAudit>[];
      late _Session h;
      h = _build(
        confirmationPort: approver,
        actionGuard: ActionGuardService(
          repository: _Rules([_rule(ActionDecision.prompt)]),
          onAudit: audits.add,
        ),
        loop: _CodeModeLoop(script: (reentry) async => 'unused'),
      );
      await _drain(h.session);
      final approval = h.loop.started.single.config.tools.approvalCallback!;
      Future<ToolGateDecision> write(String parent, int n) => approval(
        _ask(WriteTool(), {
          'path': p.join(h.dir.path, '$parent-$n.txt'),
          'content': 'x',
        }, ToolCallOrigin(toolCallId: '$parent/$n', parentToolUseId: parent)),
      );

      h.session.scriptOrigins.begin('call_declined', 'run-1/call_declined');
      expect((await write('call_declined', 1)).askedPerson, isTrue);
      final refused = await write('call_declined', 2);
      expect(refused.allowed, isFalse);
      expect(refused.askedPerson, isFalse);
      expect(refused.reason, ScriptApprovalBudget.declinedReason);
      expect(approver.requests, hasLength(1));
      expect(audits.last.decision, ActionDecision.deny);
      expect(audits.last.prompted, isFalse);
      expect(audits.last.reason, ScriptApprovalBudget.declinedReason);

      // A script whose cards are all approved.
      final yes = _RecordingApprover(true);
      h = _build(
        confirmationPort: yes,
        loop: _CodeModeLoop(script: (reentry) async => 'unused'),
      );
      await _drain(h.session);
      final again = h.loop.started.single.config.tools.approvalCallback!;
      h.session.scriptOrigins.begin('call_many', 'run-1/call_many');
      final decisions = [
        for (var i = 1; i <= CodeModeLimits.maxApprovalAsks + 1; i++)
          await again(
            _ask(
              WriteTool(),
              {'path': p.join(h.dir.path, 'many-$i.txt'), 'content': 'x'},
              ToolCallOrigin(
                toolCallId: 'call_many/$i',
                parentToolUseId: 'call_many',
              ),
            ),
          ),
      ];
      expect(yes.requests, hasLength(CodeModeLimits.maxApprovalAsks));
      expect(decisions.last.allowed, isFalse);
      expect(decisions.last.reason, ScriptApprovalBudget.exhaustedReason);
      // A direct call is not a script's: it still asks.
      await again(
        _ask(WriteTool(), {
          'path': p.join(h.dir.path, 'direct.txt'),
          'content': 'x',
        }, const ToolCallOrigin(toolCallId: 'call-direct')),
      );
      expect(yes.requests, hasLength(CodeModeLimits.maxApprovalAsks + 1));
    });

    test('that nobody answered refuses only its call: the script\'s next '
        'call asks again, and a person\'s decline still refuses the rest '
        'without a card', () async {
      final approver = _ScriptedApprover([null, false]);
      final audits = <GuardAudit>[];
      final h = _build(
        confirmationPort: approver,
        actionGuard: ActionGuardService(
          repository: _Rules([_rule(ActionDecision.prompt)]),
          onAudit: audits.add,
        ),
        loop: _CodeModeLoop(script: (reentry) async => 'unused'),
      );
      await _drain(h.session);
      final approval = h.loop.started.single.config.tools.approvalCallback!;
      Future<ToolGateDecision> write(int n) => approval(
        _ask(WriteTool(), {
          'path': p.join(h.dir.path, 'expiring-$n.txt'),
          'content': 'x',
        }, ToolCallOrigin(toolCallId: 'call_x/$n', parentToolUseId: 'call_x')),
      );
      h.session.scriptOrigins.begin('call_x', 'run-1/call_x');

      final expired = await write(1);
      expect(expired.allowed, isFalse);
      expect(expired.reason, kUnansweredCardReason);
      expect(expired.askedPerson, isFalse);
      expect(audits.last.prompted, isTrue);
      expect(audits.last.unanswered, isTrue);

      final declined = await write(2);
      expect(declined.allowed, isFalse);
      expect(declined.askedPerson, isTrue);
      expect(audits.last.unanswered, isFalse);
      expect(approver.requests, hasLength(2));

      final refused = await write(3);
      expect(refused.reason, ScriptApprovalBudget.declinedReason);
      expect(approver.requests, hasLength(2));
      expect(File(p.join(h.dir.path, 'expiring-1.txt')).existsSync(), isFalse);
    });

    test('of a call the policy decides alone is not a wait, and one a person '
        'is asked is reported once', () async {
      final audits = <GuardAudit>[];
      late _Session h;
      h = _build(
        confirmationPort: _RecordingApprover(true),
        actionGuard: ActionGuardService(
          repository: _Rules([_rule(ActionDecision.allow)]),
          onAudit: audits.add,
        ),
        loop: _CodeModeLoop(script: (reentry) async => 'unused'),
      );
      await _drain(h.session);
      final approval = h.loop.started.single.config.tools.approvalCallback!;
      final waits = <bool>[];
      final allowed = await approval(
        _ask(
          WriteTool(),
          {'path': p.join(h.dir.path, 'a.txt'), 'content': 'x'},
          const ToolCallOrigin(toolCallId: 'c/1', parentToolUseId: 'c'),
          onPersonWait: waits.add,
        ),
      );
      expect(allowed.allowed, isTrue);
      expect(waits, isEmpty);

      h = _build(
        confirmationPort: _RecordingApprover(true),
        loop: _CodeModeLoop(script: (reentry) async => 'unused'),
      );
      await _drain(h.session);
      final tier = h.loop.started.single.config.tools.approvalCallback!;
      await tier(
        _ask(
          WriteTool(),
          {'path': p.join(h.dir.path, 'b.txt'), 'content': 'x'},
          const ToolCallOrigin(toolCallId: 'c/2', parentToolUseId: 'c'),
          onPersonWait: waits.add,
        ),
      );
      expect(waits, [true, false]);
    });
  });
}

/// Answers each card with the next of [answers]; null is a card nobody
/// answered, which calls `onUnanswered` and resolves no, as the server's
/// pending-confirmation registry does on a timeout or an expiry.
class _ScriptedApprover implements ConfirmationPort {
  _ScriptedApprover(this.answers);

  final List<bool?> answers;
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    final answer = answers.removeAt(0);
    if (answer == null) {
      request.onUnanswered?.call();
      return false;
    }
    return answer;
  }
}

/// Holds every card open until the test answers it. When
/// [honoursWithdrawal], a withdrawn card resolves no, as the server's
/// pending-confirmation registry does.
class _HeldApprover implements ConfirmationPort {
  _HeldApprover({required this.honoursWithdrawal});

  final bool honoursWithdrawal;
  final requests = <ConfirmationRequest>[];
  final answers = <Completer<bool>>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) {
    requests.add(request);
    final c = Completer<bool>();
    answers.add(c);
    if (honoursWithdrawal) {
      request.withdrawn?.then((_) {
        if (!c.isCompleted) {
          c.complete(false);
        }
      });
    }
    return c.future;
  }
}
