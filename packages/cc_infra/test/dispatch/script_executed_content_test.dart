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
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/bundled_code_runner.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../code_mode/code_mode_test_support.dart'
    show MemoryExecutions, MemoryStore;
import '../helpers/windows_safe_delete.dart';

/// A script's call to a tool that runs what it is handed (a `debug` program
/// or expression, a `bash` command) through the harness gate: refused and
/// audited before anything runs when its summary is over what the guard
/// audit stores whole, run and audited whole at the bound.
void main() {
  final runner = _runner();
  final skip = runner == null
      ? 'the code mode runner is not built: set CC_CODEMODE_RUNNER'
      : null;
  const bound = ActionGuardService.maxScriptActionSummaryBytes;

  late Directory dir;
  late CodeSandboxProcess process;
  late CodeExecutionService service;
  late MemoryExecutions records;
  late List<GuardAudit> audits;
  late _Approver approver;
  // What the last run emitted.
  var events = <AgentProcessEvent>[];

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_exec_content_');
    process = CodeSandboxProcess(executable: runner!);
    final availability = await process.selfTest();
    expect(availability.isAvailable, isTrue, reason: '$availability');
    records = MemoryExecutions();
    service = CodeExecutionService(
      sandbox: process,
      executions: records,
      store: MemoryStore(),
      serverProcessCap: 2,
    );
    audits = [];
    approver = _Approver();
  });

  tearDown(() async {
    await service.dispose();
    await deleteDirBestEffort(dir);
  });

  /// Runs [code] as one `repl` script and returns what it returned, as the
  /// `repl` result's text. [direct] is a call the model makes itself first;
  /// [requestedBy] the person the run acts for; [external] the tools of the
  /// workspace's own MCP server; [autonomy] the space's autonomy dial;
  /// [hooks] the run's shell hooks.
  Future<String> script(
    String code, {
    _Direct? direct,
    AgentLoopHooks? hooks,
    String? requestedBy,
    List<McpTool> external = const [],
    String? autonomy,
    bool withRepl = true,
    AgentRunGateway? gateway,
  }) async {
    final session = DispatchSession(
      freshHistory: false,
      readOnly: false,
      deps: SandboxDispatchDeps(
        hostExecution: const HostExecutionGate(
          posture: HostExecutionPosture.offByOwner,
        ),
        sandbox: _NoopSandbox(),
        agentRepo: _UnusedAgentRepo(),
        runLogRepo: _RunLogs(),
        eventBus: null,
        resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
            AgentCommitIdentity.person((
              name: 'Test User',
              email: 'test@example.test',
            )),
        backendRegistry: BackendRegistry({
          'cc-harness': const HarnessBackend(),
        }),
        harnessCredentialStore: _KeylessStore(),
        agentLoop: _Loop(code, direct, hooks),
        mcpRegistry: McpToolRegistry(const [])
          ..setWorkspaceTools('ws-1', external),
        confirmationPort: approver,
        autonomyResolver: autonomy == null ? null : (_, _, _) async => autonomy,
        agentRunGateway: gateway,
        actionGuard: ActionGuardService(
          repository: _NoRules(),
          onAudit: audits.add,
        ),
        kernelLauncherFactory:
            ({
              required workingDirectory,
              required hostProcesses,
              workspaceId,
              conversationId,
            }) async => _NoInterpreter(),
        debugSupervisor: DebugSessionSupervisor(),
        codeExecutions: withRepl ? service : null,
      ),
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
      runLogId: 'run-1',
      mode: Mode.chat,
      requestedByUserId: requestedBy,
    );
    events = <AgentProcessEvent>[];
    final sub = session.controller.stream.listen(events.add);
    await session.run();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    return events
        .whereType<ToolResultEvent>()
        .singleWhere((e) => e.toolCallId == 'call_repl')
        .outputs;
  }

  /// The script's two calls: [over] first, caught, then [at].
  String twoCalls(String tool, String over, String at) =>
      '''
const out = {};
try { await tools.$tool($over); out.over = 'ran'; }
catch (e) { out.over = String(e.message); }
try { await tools.$tool($at); out.at = 'ran'; }
catch (e) { out.at = String(e.message); }
return out;
''';

  GuardAudit sized(String tool) => audits.singleWhere(
    (a) => a.source == kScriptActionSizeSource,
    orElse: () => fail('no size refusal of $tool was audited: $audits'),
  );

  test('a 1 MB debug expression is refused before the tool runs and audited '
      'with all of it; the next call reaches the tool', () async {
    const over = 1000 * 1000;
    final out = await script(
      twoCalls(
        'debug',
        "{op: 'evaluate', expression: 'x'.repeat($over)}",
        "{op: 'evaluate', expression: 'y'}",
      ),
    );

    expect(out, contains('The command is 1,000,007 bytes'));
    expect(out, contains('takes at most 16,384'));
    final refused = sized('debug');
    expect(refused.actionSummary, 'debug: ${'x' * over}');
    expect(refused.command, 'x' * over);
    expect(refused.decision.name, 'deny');
    // The second call passed the gate: the tool answered for itself.
    expect(out, contains('No debug session is running'));
  }, skip: skip);

  test('a script cannot call eval: it is not among its tools, so the call '
      'is refused in the runner before it reaches the gate', () async {
    // `tools` hands back a function for any name; one that is not in the
    // script's catalog rejects without starting a call.
    final out = await script('''
const kind = typeof tools.eval;
try {
  await tools.eval({code: '1 + 1'});
  return kind + ' ran';
} catch (e) {
  return kind + ' refused: ' + e.message;
}
''');
    expect(out, contains('function refused: Unknown tool "eval".'));
    expect(out, contains('Use searchTools(query) to find tools.'));
    expect(audits, isEmpty, reason: 'no gate saw the call');
    expect(records.rows.values.single.calls, isEmpty);
  }, skip: skip);

  test('a debug launch over the bound is refused before an adapter starts; '
      'an expression at the bound reaches the tool and the audit holds it '
      'whole', () async {
    final at = bound - utf8.encode('debug: ').length;
    final out = await script(
      twoCalls(
        'debug',
        "{op: 'launch', program: 'main.py', args: ['x'.repeat(20000)]}",
        "{op: 'evaluate', expression: 'y'.repeat($at)}",
      ),
    );

    expect(out, contains('a command a script runs takes at most 16,384'));
    final refused = sized('debug');
    final launched = jsonEncode(['main.py', 'x' * 20000]);
    expect(refused.actionSummary, 'debug: $launched');
    expect(refused.command, launched);

    // The tool answered for itself: no session to evaluate in.
    expect(out, contains('No debug session is running'));
    final whole = audits.singleWhere((a) => a.command == 'y' * at);
    expect(whole.actionSummary, 'debug: ${'y' * at}');
    expect(utf8.encode(whole.actionSummary), hasLength(bound));
  }, skip: skip);

  test('one byte over the bound is refused', () async {
    final at = bound - utf8.encode('debug: ').length + 1;
    final out = await script(
      twoCalls('debug', "{op: 'evaluate', expression: 'x'.repeat($at)}", '{}'),
    );
    expect(out, contains('The command is 16,385 bytes'));
    expect(sized('debug').command, 'x' * at);
  }, skip: skip);

  test('a script\'s call over the bound is refused before the owner\'s '
      'pre-tool hook is handed it; one byte under, the hook sees it; a call '
      'the hook denies is in the script\'s record, denied', () async {
    final under = bound - utf8.encode('debug: ').length - 1;
    final hooks = _Hooks();
    final out = await script(hooks: hooks, '''
const out = {};
for (const [k, n] of [['over', ${under + 2}], ['under', $under],
                      ['hooked', 1]]) {
  try { await tools.debug({op: 'evaluate', expression: 'x'.repeat(n)}); out[k] = 'ran'; }
  catch (e) { out[k] = String(e.message); }
}
return out;
''');

    expect(out, contains('The command is 16,385 bytes'));
    final debugs = [
      for (final (name, args) in hooks.pre)
        if (name == 'debug') args,
    ];
    expect(
      [for (final a in debugs) (a['expression'] as String).length],
      [under, 1],
      reason: 'the hook never saw the call over the bound',
    );
    expect(sized('debug').command, 'x' * (under + 2));
    expect(out, contains('Denied by policy hook.'));

    // The script's own record: the size refusal and the hook's denial are
    // both denied calls, each with its reason; the hook's has no guard row.
    final calls = records.rows.values.single.calls;
    final bySeq = {for (final c in calls) c.sequence: c};
    expect(bySeq[1]!.status, NestedCallStatus.denied);
    expect(bySeq[1]!.gateDecision, NestedCallGateDecision.denied);
    expect(bySeq[1]!.error, contains('The command is 16,385 bytes'));
    expect(bySeq[3]!.status, NestedCallStatus.denied);
    expect(bySeq[3]!.gateDecision, NestedCallGateDecision.denied);
    expect(bySeq[3]!.error, contains('Denied by policy hook.'));
    expect(
      audits.where((a) => a.command == 'x'),
      isEmpty,
      reason: 'a hook\'s denial writes no guard row',
    );
  }, skip: skip);

  test('every guard row of a run names the run and the person it acts for: '
      'a command the model runs and one a script runs', () async {
    final out = await script(
      "return await tools.bash({command: 'echo nested', "
      "description: 'nested'});",
      direct: (
        tool: 'bash',
        args: {'command': 'echo direct', 'description': 'direct'},
      ),
      requestedBy: 'person-1',
    );

    expect(out, contains('"exit_code": 0'));
    for (final command in ['echo direct', 'echo nested']) {
      expect(
        audits.map((a) => a.actionSummary),
        contains('bash: $command'),
        reason: 'the check of `$command` was audited',
      );
    }
    for (final row in audits) {
      expect(row.runId, 'run-1', reason: row.actionSummary);
      expect(row.onBehalfOfUserId, 'person-1', reason: row.actionSummary);
    }
  }, skip: skip);

  test('one run, one id: a script\'s `bash` row and the gateway row its '
      'command raises both name the run\'s run log', () async {
    final host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => host.close(force: true));
    final guard = ActionGuardService(
      repository: _NoRules(),
      confirmationPort: approver,
      onAudit: audits.add,
    );
    final gateway =
        AgentRunGateway(
            guard: guard,
            broker: _NoBroker(),
            loopbackBase: () async =>
                Uri.parse('http://127.0.0.1:${host.port}'),
          )
          ..environments = AgentEnvironmentGateway(
            environments: _NoEnvironments(),
            context: _NoContext(),
            guard: guard,
            runHost:
                (
                  binary,
                  arguments, {
                  required workingDirectory,
                  environment = const {},
                }) async => throw StateError('nothing runs on the host here'),
          );
    host.listen(gateway.handle);
    // `cc-env up` sent to the gateway as the run's own shim sends it.
    const command =
        r"printf 'up\0' | curl -s -o /dev/null -w '%{http_code}' "
        r'-H "X-CC-Agent-Run: $CC_AGENT_RUN_TOKEN" -H "X-CC-Env-Tool: cc-env" '
        r'--data-binary @- "$CC_AGENT_GATEWAY/agent/env"';

    final out = await script(
      'return await tools.bash({command: ${jsonEncode(command)}, '
      "description: 'cc-env up'});",
      gateway: gateway,
    );

    expect(out, contains('"output": "200"'), reason: out);
    final scripted = audits.singleWhere(
      (a) => a.actionSummary == 'bash: $command',
    );
    final raised = audits.singleWhere(
      (a) => a.actionSummary == 'cc-env up',
      orElse: () => fail('the gateway audited no `cc-env up`: $audits'),
    );
    expect(scripted.runId, 'run-1', reason: 'the run log');
    expect(raised.runId, scripted.runId);
  }, skip: skip);

  group('an external MCP tool: a script\'s call takes the gate the model\'s '
      'call takes, and gets its verdict', () {
    const direct = (tool: 'mcp__srv__ping', args: <String, Object?>{});

    /// The model calls the tool itself in a run without code mode (with it,
    /// an external tool is callable only from a script), then a script calls
    /// it in a run with code mode; the cards each raised.
    Future<
      ({List<ConfirmationRequest> direct, List<ConfirmationRequest> nested})
    >
    both({String? autonomy}) async {
      final tool = _External();
      await script(
        'return 0;',
        direct: direct,
        external: [tool],
        autonomy: autonomy,
        withRepl: false,
      );
      final model = [...approver.asked];
      expect(tool.ran, 1, reason: _results(events));
      approver.asked.clear();
      final out = await script(
        'return await tools.mcp__srv__ping({});',
        external: [tool],
        autonomy: autonomy,
      );
      expect(out, contains('pong'));
      expect(tool.ran, 2, reason: _results(events));
      return (direct: model, nested: [...approver.asked]);
    }

    test('by default, both ask, and neither card offers to remember: '
        'nothing would read it', () async {
      final asked = await both();

      expect(asked.direct, hasLength(1));
      expect(asked.direct.single.origin, isNull);
      expect(asked.nested, hasLength(1));
      expect(asked.nested.single.origin, isNotNull);
      for (final card in [...asked.direct, ...asked.nested]) {
        expect(card.rememberChoice, isNull);
      }
    }, skip: skip);

    test('a space that acts freely: neither asks', () async {
      final asked = await both(autonomy: 'actFreely');

      expect(asked.direct, isEmpty);
      expect(asked.nested, isEmpty);
    }, skip: skip);
  });
}

/// The built runner, from `CC_CODEMODE_RUNNER` or the repository's release
/// build, or null when neither exists.
String? _runner() {
  final named = Platform.environment[BundledCodeRunner.environmentOverride];
  if (named != null && named.isNotEmpty) {
    return File(named).existsSync() ? named : null;
  }
  final built = p.normalize(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'build',
      'cargo',
      'codemode',
      'release',
      Platform.isWindows ? 'cc_codemode.exe' : 'cc_codemode',
    ),
  );
  return File(built).existsSync() ? built : null;
}

/// A kernel launcher that has no interpreter to start.
class _NoInterpreter implements KernelLauncher {
  @override
  Future<void> writeFile(String relativePath, String contents) async {}

  @override
  Future<Process> start(KernelLanguage language, String runnerPath) =>
      throw StateError('no interpreter here');
}

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

class _RunLogs implements AgentRunLogRepository {
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
  }) async => false;

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

class _NoBroker implements CredentialBrokerPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A space with no environment to start: the command is checked, then fails.
class _NoEnvironments implements EnvironmentPort {
  @override
  Future<SpaceEnvironment> ensure({
    required String workspaceId,
    required String spaceId,
    String? definitionId,
    Map<String, dynamic> options = const {},
    bool attended = false,
    required Principal by,
  }) async => throw Exception('no environment here');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoContext implements AgentEnvironmentContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Each tool result [events] holds, one per line.
String _results(List<AgentProcessEvent> events) => events
    .whereType<ToolResultEvent>()
    .map((e) => '${e.toolCallId}: ${e.outputs}')
    .join('\n');

/// Approves every card, and keeps what each one said.
class _Approver implements ConfirmationPort {
  final asked = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    asked.add(request);
    return true;
  }
}

/// A call the model makes itself, before its script.
typedef _Direct = ({String tool, Map<String, Object?> args});

/// A tool of an external MCP server, as the bridge declares one: no effect
/// class, the exec tier, and a card unless a setting spares it.
class _External extends McpTool {
  int ran = 0;

  @override
  String get name => 'mcp__srv__ping';

  @override
  String get description => '[srv] Answers pong.';

  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  ToolApproval toolApproval(Map<String, dynamic> arguments) =>
      ToolApproval.exec;

  @override
  bool get requiresApproval => true;

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    ran++;
    return CallResult.success('pong');
  }
}

class _NoRules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Calls `repl` with [code] once (after [direct], when given),
/// then answers in text.
class _ReplProvider extends LlmProviderPort {
  _ReplProvider(this.code, this.direct);

  final String code;
  final _Direct? direct;
  int _calls = 0;

  @override
  String get displayName => 'exec content scenario';
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
      if (direct case final call?) {
        yield LlmToolUseDelta(
          id: 'call_direct',
          name: call.tool,
          argumentsJson: jsonEncode(call.args),
        );
      }
      yield LlmToolUseDelta(
        id: 'call_repl',
        name: 'repl',
        argumentsJson: jsonEncode({'code': code, 'description': 'two calls'}),
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

/// The real loop, with a provider that sends one script.
class _Loop implements AgentLoop {
  _Loop(this.code, this.direct, this.hooks);

  final String code;
  final _Direct? direct;

  /// Stands in for the owner's shell hooks, which the session sets only
  /// when its hook folder holds a script.
  final AgentLoopHooks? hooks;

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
  }) => const AgentLoopRunner().run(
    history: history,
    userMessage: userMessage,
    tools: tools,
    deferredTools: deferredTools,
    scriptTools: scriptTools,
    provider: _ReplProvider(code, direct),
    context: context,
    config: switch (hooks) {
      null => config,
      final hooks => AgentLoopConfig(
        systemPrompt: config.systemPrompt,
        model: config.model,
        maxTokens: config.maxTokens,
        tools: config.tools,
        guards: config.guards,
        compaction: config.compaction,
        transcript: config.transcript,
        steering: LoopSteeringConfig(
          hooks: hooks,
          queue: config.steering.queue,
          pauseGate: config.steering.pauseGate,
        ),
      ),
    },
    cancel: cancel,
  );
}

/// The owner's pre-tool hook, recording what it was handed: allows every
/// call but a cell described `hooked out`.
class _Hooks implements AgentLoopHooks {
  final pre = <(String, Map<String, dynamic>)>[];

  @override
  bool get interceptsTools => true;
  @override
  Future<void> onSessionStart() async {}
  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    pre.add((toolName, args));
    // The one-character expression is the call the hook denies.
    return args['expression'] != 'x';
  }

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {}
}
