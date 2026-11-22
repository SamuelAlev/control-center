import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
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
import 'package:cc_infra/src/code_mode/bundled_code_runner.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../code_mode/code_mode_test_support.dart'
    show MemoryExecutions, MemoryStore;
import '../helpers/windows_safe_delete.dart';

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

class _Approver implements ConfirmationPort {
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    return true;
  }
}

class _Rules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async {
    final now = DateTime.now();
    return [
      ActionPolicyRule(
        id: 'space-write-prompt',
        workspaceId: 'ws-1',
        scopeType: ActionScopeType.space,
        scopeId: 'space-1',
        actionClass: ActionClass.fileWriteOutsideWorktree,
        decision: ActionDecision.prompt,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Lookup extends McpTool {
  @override
  String get name => 'lookup_thing';
  @override
  String get description => 'Looks a thing up.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('{"found": "the thing"}');
}

/// Blocks until its caller stops waiting.
class _Hang extends McpTool {
  final started = Completer<void>();

  @override
  String get name => 'hang';
  @override
  String get description => 'Waits for a long time.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) =>
      Completer<CallResult>().future;

  @override
  Future<CallResult> runUntilAbandoned(
    Map<String, dynamic> arguments,
    Future<void> abandoned,
  ) async {
    if (!started.isCompleted) {
      started.complete();
    }
    await abandoned;
    return CallResult.error('abandoned');
  }
}

/// Calls `repl` with [code] once, then answers in text.
class _ReplProvider extends LlmProviderPort {
  _ReplProvider(this.code);

  final String code;
  int _calls = 0;

  @override
  String get displayName => 'repl scenario';
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
  _Loop(this.code);

  final String code;

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
    provider: _ReplProvider(code),
    context: context,
    config: config,
    cancel: cancel,
  );
}

/// One model turn of [_TurnsProvider]: a `repl` script, a `task` call, or
/// the closing text.
typedef _Turn = ({String? code, String? task});

/// Plays [turns] in order, one per completion, then ends in text; keeps the
/// text of every tool result it is shown.
class _TurnsProvider extends LlmProviderPort {
  _TurnsProvider(this.label, this.turns, this.results);

  final String label;
  final List<_Turn> turns;
  final Map<String, String> results;
  int _calls = 0;

  @override
  String get displayName => 'store scenario';
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
    for (final block in messages.last.content) {
      if (block is HarnessToolResultBlock) {
        results[block.toolUseId] = block.content;
      }
    }
    final n = _calls++;
    if (n < turns.length) {
      final turn = turns[n];
      final id = '${label}_$n';
      yield turn.code != null
          ? LlmToolUseDelta(
              id: id,
              name: 'repl',
              argumentsJson: jsonEncode({
                'code': turn.code,
                'description': 'store scenario',
              }),
            )
          : LlmToolUseDelta(
              id: id,
              name: 'task',
              argumentsJson: jsonEncode({
                'description': turn.task,
                'label': 'child',
              }),
            );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

/// The real loop for the session's run ([parent]) and for the subagent it
/// spawns ([child]), each with its own turns.
class _ParentChildLoop implements AgentLoop {
  _ParentChildLoop({required this.parent, required this.child});

  final List<_Turn> parent;
  final List<_Turn> child;
  final results = <String, String>{};
  int _runs = 0;

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
    final first = _runs++ == 0;
    return const AgentLoopRunner().run(
      history: history,
      userMessage: userMessage,
      tools: tools,
      deferredTools: deferredTools,
      scriptTools: scriptTools,
      provider: first
          ? _TurnsProvider('parent', parent, results)
          : _TurnsProvider('child', child, results),
      context: context,
      config: config,
      cancel: cancel,
    );
  }
}

void main() {
  final runner = _runner();
  final skip = runner == null
      ? 'the code mode runner is not built: build it with '
            '`CARGO_TARGET_DIR=build/cargo/codemode cargo build --release '
            '--locked --manifest-path '
            'packages/cc_natives/native/codemode/Cargo.toml`, or set '
            'CC_CODEMODE_RUNNER to its absolute path'
      : null;

  late Directory dir;
  late CodeSandboxProcess process;
  late MemoryExecutions executions;
  late CodeExecutionService service;
  late _Approver approver;
  late MemoryStore store;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_repl_runner_');
    process = CodeSandboxProcess(executable: runner!);
    final availability = await process.selfTest();
    expect(availability.isAvailable, isTrue, reason: '$availability');
    executions = MemoryExecutions();
    service = CodeExecutionService(
      sandbox: process,
      executions: executions,
      store: store = MemoryStore(),
      serverProcessCap: 2,
    );
    approver = _Approver();
  });

  tearDown(() async {
    await service.dispose();
    await deleteDirBestEffort(dir);
  });

  DispatchSession build(String code, List<McpTool> tools, {AgentLoop? loop}) =>
      DispatchSession(
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
          agentLoop: loop ?? _Loop(code),
          mcpRegistry: McpToolRegistry(tools),
          confirmationPort: approver,
          actionGuard: ActionGuardService(repository: _Rules()),
          codeExecutions: service,
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
      );

  test('a script calls two tools through the run\'s gate, one of them gated, '
      'and its execution is saved', () async {
    final target = p.join(dir.path, 'from-script.txt');
    final session = build(
      '''
const found = await tools.lookup_thing({});
await tools.write({path: ${jsonEncode(target)}, content: "scripted"});
return {found: found.found};
''',
      [_Lookup()],
    );
    final events = <AgentProcessEvent>[];
    final sub = session.controller.stream.listen(events.add);
    await session.run();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();

    final nested = events.whereType<ToolCallEvent>().where(
      (e) => e.parentToolCallId == 'call_repl',
    );
    expect(nested.map((e) => e.toolName), ['lookup_thing', 'write']);
    expect(nested.map((e) => e.toolCallId), ['call_repl/1', 'call_repl/2']);
    final nestedResults = events.whereType<ToolResultEvent>().where(
      (e) => e.parentToolCallId == 'call_repl',
    );
    expect(nestedResults, hasLength(2));

    expect(
      approver.requests.single.origin,
      ScriptCallOrigin(
        parentToolCallId: 'call_repl',
        executionId: 'run-1/call_repl',
      ),
    );
    expect(File(target).readAsStringSync(), 'scripted');

    final saved = executions.rows['run-1/call_repl']!;
    expect(saved.execution.status, CodeExecutionStatus.completed);
    expect(saved.execution.runId, 'run-1');
    expect(saved.calls.map((c) => c.toolName), ['lookup_thing', 'write']);
    expect(saved.calls.map((c) => c.status), [
      NestedCallStatus.completed,
      NestedCallStatus.completed,
    ]);

    final replResult = events.whereType<ToolResultEvent>().singleWhere(
      (e) => e.toolCallId == 'call_repl',
    );
    expect(replResult.outputs, startsWith('Script completed in'));
    expect(replResult.outputs, contains('the thing'));
    expect(process.liveProcessCount, 0);
  }, skip: skip);

  test(
    'stopping the run while a script waits on a nested call ends the '
    'script, and no runner outlives the run',
    () async {
      final hang = _Hang();
      final session = build('await tools.hang({}); return 1;', [hang]);
      int? liveAtDone;
      final sub = session.controller.stream.listen((event) {
        if (event is DoneEvent) {
          liveAtDone ??= process.liveProcessCount;
        }
      });
      final run = session.run();
      await hang.started.future;
      expect(process.liveProcessCount, 1);

      await session.terminate();
      await run;
      await sub.cancel();

      expect(liveAtDone, 0);
      expect(process.liveProcessCount, 0);
      final saved = executions.rows['run-1/call_repl']!;
      expect(saved.execution.status, CodeExecutionStatus.cancelled);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a subagent\'s scripts get no store: they cannot read or overwrite '
    'what the parent stored, which the parent\'s next script still loads',
    () async {
      final loop = _ParentChildLoop(
        parent: [
          (
            code: "store('plan', 'from the parent'); return 'saved';",
            task: null,
          ),
          (code: null, task: 'Read the untrusted page.'),
          (code: "return load('plan') ?? 'missing';", task: null),
        ],
        child: [
          (
            code:
                "const seen = load('plan') ?? 'nothing'; "
                "try { store('plan', 'from the child'); return seen + "
                "' / stored'; } catch (e) { return seen + ' / ' + e.name; }",
            task: null,
          ),
        ],
      );
      final session = build('', const [], loop: loop);
      await session.run();

      expect(loop.results['parent_0'], contains('saved'));
      final child = loop.results['child_0']!;
      expect(child, contains('nothing / '));
      expect(child, isNot(contains('stored')));
      expect(child, contains('store() is unavailable in this run'));
      expect(loop.results['parent_2'], contains('from the parent'));
      expect(store.values.keys, ['conv-1|agent-1']);
      expect(
        store.values['conv-1|agent-1']!['plan'],
        contains('from the parent'),
      );
      // The child's execution is still recorded, under its own run, naming
      // its conversation and its agent.
      final childRows = executions.rows.values.where(
        (r) => r.execution.runId.startsWith('run-1-sub-'),
      );
      expect(childRows, hasLength(1));
      expect(childRows.single.execution.conversationId, 'conv-1');
      expect(childRows.single.execution.agentId, 'agent-1');
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
