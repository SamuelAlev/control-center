import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

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

/// Keeps the run-log rows written and the composition snapshot.
class _RunLogs implements AgentRunLogRepository {
  final snapshots = <String>[];
  final rows = <AgentRunLog>[];

  @override
  Future<void> upsert(AgentRunLog log) async => rows.add(log);

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

/// Answers every question with its first option and keeps the requests.

/// Answers every approval with yes and keeps the cards. The first [held]
/// cards are answered together, once all of them are up, so every script
/// that raised one is registered at the same moment.
class _Approver implements ConfirmationPort {
  _Approver({required this.held});

  final int held;
  final cards = <ConfirmationRequest>[];
  final _firstRound = Completer<void>();

  /// Completes once the first [held] cards are all up.
  Future<void> get firstRound => _firstRound.future;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    cards.add(request);
    if (cards.length == held) {
      _firstRound.complete();
    }
    await _firstRound.future;
    return true;
  }
}

/// Which loop a script runs in: 0 the session's own run, 1 its subagent,
/// 2 the subagent's subagent.
typedef _Depth = int;

/// The execution service, faked. Every script starts under the same tool
/// call id; each waits until all [scripts] are running, makes one gated
/// `write`, and then, deepest first, each ends after one more gated `write`
/// made once the script below it has ended. Each execution is named
/// `<derived id>#2`, as the real service names one after a repeated tool
/// call id, so a card that fell back to the derived id would show it.
class _Scripts implements CodeExecutionPort {
  _Scripts({required this.scripts, required this.approver});

  final int scripts;
  final _Approver approver;
  final requests = <CodeExecutionRequest>[];
  final executions = <CodeExecution>[];
  final outcomes = <NestedCallStatus>[];
  final _allRunning = Completer<void>();
  final _ended = <_Depth, Completer<void>>{};

  /// The depth of the run [runId]: subagent run ids are numbered in the
  /// order the session spawned them.
  _Depth depthOf(String runId) => runId == 'run-1'
      ? 0
      : runId.startsWith('run-1-sub-0-')
      ? 1
      : 2;

  /// The id the service chose for [request]'s execution.
  static String idOf(CodeExecutionRequest request) =>
      '${CodeExecution.idFor(runId: request.runId, toolCallId: request.parentToolCallId)}#2';

  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    requests.add(request);
    if (requests.length == scripts) {
      _allRunning.complete();
    }
    await _allRunning.future;
    final depth = depthOf(request.runId);
    final ended = _ended.putIfAbsent(depth, Completer.new);
    final id = idOf(request);
    Future<void> write(int n) async {
      final outcome = await callNested(
        NestedCallRequest(
          sequence: n,
          toolCallId: '${request.parentToolCallId}/$n',
          name: 'write',
          arguments: {'path': 'depth-$depth-$n.txt', 'content': 'x'},
          origin: ScriptCallOrigin(
            parentToolCallId: request.parentToolCallId,
            executionId: id,
          ),
          deadline: const Duration(seconds: 30),
          site: null,
          cancel: cancel,
        ),
      );
      outcomes.add(outcome.status);
    }

    await write(1);
    await approver.firstRound;
    final below = depth + 1;
    if (below < scripts) {
      await _ended.putIfAbsent(below, Completer.new).future;
    }
    await write(2);
    final execution = CodeExecution(
      id: id,
      runId: request.runId,
      toolCallId: request.parentToolCallId,
      surface: request.surface,
      startedAt: DateTime.utc(2026),
      durationMs: 1,
      status: CodeExecutionStatus.completed,
      sourceHash: '0' * 64,
      sourceBytes: request.code.length,
      limits: request.limits,
    );
    executions.add(execution);
    ended.complete();
    return CodeExecutionResult(
      result: const ScriptResult(
        text: 'Script completed in 0.0 s · 2 tool calls',
        isError: false,
        truncated: false,
        outputChars: 0,
      ),
      execution: execution,
      calls: const [],
    );
  }
}

/// Calls `repl` once under [callId], then answers in text.
class _ReplProvider extends LlmProviderPort {
  _ReplProvider(this.callId);

  final String callId;
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
        id: callId,
        name: 'repl',
        argumentsJson: jsonEncode({'code': 'return 1;', 'description': 'try'}),
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

/// Every loop, at every depth, calls `repl` under the same tool call id
/// ([callId], as a local model's `call_0`). A loop with a `task` tool, up to
/// [spawnBelow] loops, also spawns a subagent at the same moment, so the
/// scripts of a run, its subagent and that subagent's own subagent all run
/// at once.
class _Loop implements AgentLoop {
  _Loop({required this.spawnBelow});

  final int spawnBelow;
  static const callId = 'call_0';

  /// What each loop yielded, in the order the loops started.
  final yielded = <List<AgentLoopEvent>>[];

  /// Each loop's configuration, in the same order.
  final configs = <AgentLoopConfig>[];

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
  }) async* {
    final index = yielded.length;
    final events = <AgentLoopEvent>[];
    yielded.add(events);
    configs.add(config);
    Future<void>? spawned;
    if (index < spawnBelow) {
      final task = tools.firstWhere((t) => t.name == 'task');
      spawned = task.execute(
        {'description': 'look around $index', 'label': 'scout-$index'},
        (context ?? const HarnessToolContext(workingDirectory: '.'))
            .withToolCallId('call_task'),
      );
    }
    await for (final event in const AgentLoopRunner().run(
      history: history,
      userMessage: userMessage,
      tools: tools,
      deferredTools: deferredTools,
      scriptTools: scriptTools,
      provider: _ReplProvider(callId),
      context: context,
      config: config,
      cancel: cancel,
    )) {
      events.add(event);
      yield event;
    }
    await spawned;
  }
}

typedef _Session = ({DispatchSession session, _RunLogs runLogs});

_Session _build({
  required _Loop loop,
  required CodeExecutionPort executions,
  required ConfirmationPort approver,
}) {
  final dir = Directory.systemTemp.createTempSync('cc_repl_origins_');
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
    agentLoop: loop,
    confirmationPort: approver,
    codeExecutions: executions,
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
    runLogId: 'run-1',
    mode: Mode.chat,
  );
  return (session: session, runLogs: runLogs);
}

Future<void> _drain(DispatchSession session) async {
  final sub = session.controller.stream.listen((_) {});
  await session.run();
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sub.cancel();
}

/// What the cards and the records say when [scripts] loops (the run and its
/// subagents, one below the other) all run a script under `call_0` at once.
Future<void> _expectEachScriptNamedExactly(int scripts) async {
  final approver = _Approver(held: scripts);
  final service = _Scripts(scripts: scripts, approver: approver);
  final loop = _Loop(spawnBelow: scripts - 1);
  final h = _build(loop: loop, executions: service, approver: approver);

  await _drain(h.session).timeout(const Duration(seconds: 20));

  // One script per loop, each under its own run: the run's own row and one
  // child row per level, each the child of the one above. Distinct run ids
  // are what the service's one-script-per-run admission keys on.
  expect(service.requests, hasLength(scripts));
  final byDepth = {
    for (final r in service.requests) service.depthOf(r.runId): r,
  };
  expect(byDepth.keys, unorderedEquals([for (var d = 0; d < scripts; d++) d]));
  expect(byDepth[0]!.runId, 'run-1');
  for (var d = 1; d < scripts; d++) {
    final row = h.runLogs.rows.singleWhere((r) => r.id == byDepth[d]!.runId);
    expect(row.parentRunId, byDepth[d - 1]!.runId);
    expect(row.role, AgentRunRole.sub);
  }
  for (final r in service.requests) {
    expect(r.parentToolCallId, 'call_0');
    // Only the run's own scripts use the store; a subagent's do not.
    expect(r.storeEnabled, service.depthOf(r.runId) == 0);
  }
  final ids = [for (var d = 0; d < scripts; d++) _Scripts.idOf(byDepth[d]!)];
  expect(ids.toSet(), hasLength(scripts));

  // Every gated call ran.
  expect(
    service.outcomes,
    List.filled(scripts * 2, NestedCallStatus.completed),
  );

  // The first cards were up together, all for a script under `call_0`: each
  // names its own script's execution, none another's.
  final cards = [for (final c in approver.cards) c.origin];
  expect(cards, hasLength(scripts * 2));
  expect(cards.every((o) => o?.parentToolCallId == 'call_0'), isTrue);
  expect([
    for (final o in cards.take(scripts)) o!.executionId,
  ], unorderedEquals(ids));
  // Then, deepest first, each script made one more call after the script
  // below it ended: its card still names its own execution, so ending one
  // script left the others registered.
  expect([
    for (final o in cards.skip(scripts)) o!.executionId,
  ], ids.reversed.toList());

  // The records name the execution and the run each script ran as.
  expect(
    {for (final e in service.executions) e.id: e.runId},
    {for (var d = 0; d < scripts; d++) ids[d]: byDepth[d]!.runId},
  );

  // Every registration ended with its script: the run's own origins name
  // no execution again.
  expect(h.session.scriptOrigins.originOf('call_0').executionId, isNull);

  // Each loop's nested calls came out of that loop, under its own `repl`
  // call: what the loop yields is what its run's transcript records.
  for (final events in loop.yielded) {
    final nested = events.whereType<LoopToolCallStart>().where(
      (e) => e.parentToolUseId != null,
    );
    expect(nested.map((e) => (e.toolName, e.parentToolUseId)), [
      ('write', 'call_0'),
      ('write', 'call_0'),
    ]);
  }
}

void main() {
  test('a run and its subagent running scripts under the same tool call id '
      'at once each name their own execution on every card', () async {
    await _expectEachScriptNamedExactly(2);
  });

  test('every loop, a subagent\'s too, refuses a script\'s call too long '
      'to audit whole before its hook or a card', () async {
    final approver = _Approver(held: 2);
    final service = _Scripts(scripts: 2, approver: approver);
    final loop = _Loop(spawnBelow: 1);
    final h = _build(loop: loop, executions: service, approver: approver);
    await _drain(h.session).timeout(const Duration(seconds: 20));

    const bound = ActionGuardService.maxScriptActionSummaryBytes;
    final at = {'command': 'x' * (bound - 'runs: '.length)};
    final over = {'command': 'x' * (bound - 'runs: '.length + 1)};
    expect(loop.configs, hasLength(2));
    for (final config in loop.configs) {
      final refuse = config.tools.nestedCallRefusal;
      expect(refuse, isNotNull);
      expect(refuse!(_Runs(), at), isNull);
      expect(refuse(_Runs(), over), contains('16,385 bytes'));
    }
  });

  test('so do a subagent\'s own subagent, and ending the deepest script '
      'leaves the others registered', () async {
    await _expectEachScriptNamedExactly(3);
  });
}

/// A tool that runs the command it is handed.
class _Runs extends HarnessTool {
  @override
  String get name => 'runs';
  @override
  String get description => 'Runs a command.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;
  @override
  String? executedContent(Map<String, dynamic> args) => '${args['command']}';

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ran');
}
