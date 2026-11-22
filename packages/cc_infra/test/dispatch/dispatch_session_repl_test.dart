import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
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
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_transcript_port.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/run_script_past.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/harness/repl_tool.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
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

class _Approver implements ConfirmationPort {
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async => true;
}

/// Answers every question with its first option and keeps the requests.
class _Questions implements AgentQuestionPort {
  final requests = <AgentQuestionRequest>[];

  @override
  Future<AgentQuestionAnswer?> ask(
    AgentQuestionRequest request, {
    Future<void>? abandoned,
  }) async {
    requests.add(request);
    return const AgentQuestionAnswer(selectedLabels: ['yes']);
  }
}

class _McpTool extends McpTool {
  _McpTool(this.name);

  @override
  final String name;
  @override
  String get description => 'The $name operation.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('$name ran');
}

/// A nested call the fake service makes, and what the run's origins said
/// while it was in flight.
typedef _Seen = ({String name, NestedCallOutcome outcome, ScriptCallOrigin at});

/// The execution service, faked: it names each execution `<derived id>#2`
/// (as the real one does after a repeated tool call id), makes the
/// configured nested calls in order and records what it saw.
class _Executions implements CodeExecutionPort {
  _Executions({
    this.calls = const [],
    this.waitForCancel = false,
    this.originsOf,
    this.availability = const CodeRunnerAvailability.available(),
  });

  final List<(String, Map<String, dynamic>)> calls;
  final bool waitForCancel;

  /// Reads the session's origins for a parent call id, while a call runs.
  ScriptCallOrigin Function(String parentToolCallId)? Function()? originsOf;

  final requests = <CodeExecutionRequest>[];
  final seen = <_Seen>[];
  final started = Completer<void>();
  bool ended = false;

  @override
  final CodeRunnerAvailability availability;

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    requests.add(request);
    if (!started.isCompleted) {
      started.complete();
    }
    final executionId =
        '${CodeExecution.idFor(runId: request.runId, toolCallId: request.parentToolCallId)}#2';
    var status = CodeExecutionStatus.completed;
    try {
      for (final (i, (name, args)) in calls.indexed) {
        final origin = ScriptCallOrigin(
          parentToolCallId: request.parentToolCallId,
          executionId: executionId,
        );
        final outcome = await callNested(
          NestedCallRequest(
            sequence: i + 1,
            toolCallId: '${request.parentToolCallId}/${i + 1}',
            name: name,
            arguments: args,
            origin: origin,
            deadline: const Duration(seconds: 30),
            site: null,
            cancel: cancel,
          ),
        );
        seen.add((
          name: name,
          outcome: outcome,
          at:
              originsOf?.call()?.call(request.parentToolCallId) ??
              ScriptCallOrigin(parentToolCallId: '-', executionId: '-'),
        ));
      }
      if (waitForCancel) {
        await cancel.whenCancelled;
        // The runner's kill grace: the script ends a moment after the stop.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        status = CodeExecutionStatus.cancelled;
      }
    } finally {
      ended = true;
    }
    return CodeExecutionResult(
      result: ScriptResult(
        text: 'Script ${status.wire}: ${seen.length} calls',
        isError: status != CodeExecutionStatus.completed,
        truncated: false,
        outputChars: 0,
      ),
      execution: CodeExecution(
        id: executionId,
        runId: request.runId,
        toolCallId: request.parentToolCallId,
        surface: request.surface,
        startedAt: DateTime.utc(2026),
        durationMs: 1,
        status: status,
        sourceHash: '0' * 64,
        sourceBytes: request.code.length,
        limits: request.limits,
      ),
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

typedef _Started = ({
  List<HarnessTool> tools,
  List<HarnessTool> scriptTools,
  AgentLoopConfig config,
});

/// Runs the real loop with a provider that calls `repl`. With [spawnChild],
/// the session's own run calls `task` instead and the subagent calls `repl`.
class _Loop implements AgentLoop {
  _Loop({this.spawnChild = false, this.observe = false, this.readHandle});

  final bool spawnChild;

  /// Calls `read_output` on this handle before the run's `repl` turn, and
  /// keeps what it answered in [read].
  final String? readHandle;
  final read = <HarnessToolResult>[];

  /// Hands the loop's observation ingest one output too long to keep
  /// inline, as a cut tool result does, and ends.
  final bool observe;
  final started = <_Started>[];

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
    started.add((tools: tools, scriptTools: scriptTools, config: config));
    final handle = readHandle;
    if (handle != null && started.length == 1) {
      return () async* {
        read.add(
          await tools.firstWhere((t) => t.name == 'read_output').execute({
            'handle': handle,
          }, context!),
        );
        yield* _runner(
          history: history,
          userMessage: userMessage,
          tools: tools,
          deferredTools: deferredTools,
          scriptTools: scriptTools,
          context: context,
          config: config,
          cancel: cancel,
        );
      }();
    }
    if (observe) {
      return () async* {
        await config.tools.observationIngest!.ingest(
          toolName: 'bash',
          result: HarnessToolResult(content: 'line of output\n' * 40000),
          context: context!,
        );
        yield const LoopDone(LoopDoneReason.completed);
      }();
    }
    if (spawnChild && started.length == 1) {
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
    return _runner(
      history: history,
      userMessage: userMessage,
      tools: tools,
      deferredTools: deferredTools,
      scriptTools: scriptTools,
      context: context,
      config: config,
      cancel: cancel,
    );
  }

  Stream<AgentLoopEvent> _runner({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    required List<HarnessTool> deferredTools,
    required List<HarnessTool> scriptTools,
    required HarnessToolContext? context,
    required AgentLoopConfig config,
    required CancellationToken? cancel,
  }) => const AgentLoopRunner().run(
    history: history,
    userMessage: userMessage,
    tools: tools,
    deferredTools: deferredTools,
    scriptTools: scriptTools,
    provider: _ReplProvider(started.length == 1 ? 'call_repl' : 'call_kid'),
    context: context,
    config: config,
    cancel: cancel,
  );
}

typedef _Session = ({DispatchSession session, _Loop loop, _RunLogs runLogs});

final _limits = CodeModeLimits(maxNestedCalls: 7, wallClockMs: 45000);

_Session _build({
  required _Loop loop,
  CodeExecutionPort? executions,
  Future<CodeModeLimits> Function(String workspaceId)? limits,
  AgentQuestionPort? questions,
  String? runLogId = 'run-1',
  ScriptPastSources? scriptPast,
  ToolOutputStore? toolOutputStore,
  bool readOnly = false,
}) {
  final dir = Directory.systemTemp.createTempSync('cc_repl_wiring_');
  addTearDown(() => deleteDirBestEffort(dir));
  final runLogs = _RunLogs();
  final deps = SandboxDispatchDeps(
    // Only a sandbox holds a read-only run's worktree read-only.
    hostExecution: HostExecutionGate(
      posture: readOnly
          ? HostExecutionPosture.sandboxed
          : HostExecutionPosture.offByOwner,
    ),
    sandboxManager: readOnly ? _PassThroughSandbox() : null,
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
    mcpRegistry: McpToolRegistry([
      _McpTool('lookup_thing'),
      // The MCP endpoint's own script tool: never bridged into a harness run.
      _McpTool('repl'),
    ]),
    confirmationPort: _Approver(),
    agentQuestionPort: questions,
    codeExecutions: executions,
    codeModeLimits: limits,
    scriptPast: scriptPast,
    toolOutputStore: toolOutputStore,
  );
  final session = DispatchSession(
    freshHistory: false,
    readOnly: readOnly,
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
  return (session: session, loop: loop, runLogs: runLogs);
}

Future<List<AgentProcessEvent>> _drain(DispatchSession session) async {
  final events = <AgentProcessEvent>[];
  final sub = session.controller.stream.listen(events.add);
  await session.run();
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sub.cancel();
  return events;
}

List<String> _names(Iterable<HarnessTool> tools) => [
  for (final t in tools) t.name,
];

Map<String, dynamic> _scriptsOf(_RunLogs runLogs) =>
    (jsonDecode(runLogs.snapshots.single) as Map)['scripts']
        as Map<String, dynamic>;

void main() {
  test('a run gets its own repl, bound to the run, and its scripts '
      'name the execution the service chose', () async {
    final questions = _Questions();
    late _Session h;
    final executions = _Executions(
      calls: [
        ('lookup_thing', const {}),
        (
          'ask_user',
          const {
            'question': 'Proceed?',
            'options': [
              {'label': 'yes'},
            ],
          },
        ),
      ],
      originsOf: () => h.session.scriptOrigins.originOf,
    );
    h = _build(
      loop: _Loop(),
      executions: executions,
      limits: (ws) async {
        expect(ws, 'ws-1');
        return _limits;
      },
      questions: questions,
    );

    final events = await _drain(h.session);

    final run = h.loop.started.single;
    expect(run.tools.first, isA<ReplTool>());
    expect(_names(run.tools).where((n) => n == 'repl'), hasLength(1));
    expect(_names(run.scriptTools), contains('lookup_thing'));
    final repl = run.tools.first as ReplTool;
    expect(
      repl.scriptTools.map((d) => d.name),
      containsAll(['lookup_thing', 'ask_user']),
    );
    expect(repl.scriptTools.map((d) => d.name), isNot(contains('repl')));

    final request = executions.requests.single;
    expect(request.workspaceId, 'ws-1');
    expect(request.runId, 'run-1');
    expect(request.parentToolCallId, 'call_repl');
    expect(request.conversationId, 'conv-1');
    expect(request.agentId, 'agent-1');
    expect(request.spaceId, 'space-1');
    expect(request.storeEnabled, isTrue);
    expect(request.limits, _limits);

    // Begun with the service's id before the first call reached the gate,
    // ended when the script ended.
    expect(executions.seen.map((s) => s.outcome.status), [
      NestedCallStatus.completed,
      NestedCallStatus.completed,
    ]);
    for (final seen in executions.seen) {
      expect(seen.at.executionId, 'run-1/call_repl#2');
    }
    expect(
      questions.requests.single.origin,
      ScriptCallOrigin(
        parentToolCallId: 'call_repl',
        executionId: 'run-1/call_repl#2',
      ),
    );
    // The script ended: nothing is registered under its call any more.
    expect(h.session.scriptOrigins.originOf('call_repl').executionId, isNull);
    final nested = events.whereType<ToolCallEvent>().where(
      (e) => e.parentToolCallId == 'call_repl',
    );
    expect(nested.map((e) => e.toolName), ['lookup_thing', 'ask_user']);
    expect(_scriptsOf(h.runLogs), {'available': true});
    // Texts pushed into the run, and its background command texts, name a
    // tool in the form its surface gives it.
    expect(h.session.toolForms('lookup_thing'), ToolCallForm.script);
    expect(h.session.toolForms('bash'), ToolCallForm.direct);
    expect(h.session.toolForms('not_a_tool'), ToolCallForm.plain);
    final background = backgroundCommandsOf([
      ...run.tools,
      ...run.scriptTools,
    ])!;
    expect(background.callForms('bash_kill'), ToolCallForm.script);
    expect(background.callForms('bash'), ToolCallForm.direct);
  });

  test('a run without a run-log row gets no repl: its scripts could not be '
      'recorded, so its tools are called directly', () async {
    final executions = _Executions(calls: [('lookup_thing', const {})]);
    final h = _build(loop: _Loop(), executions: executions, runLogId: null);

    final events = await _drain(h.session);

    final run = h.loop.started.single;
    expect(_names(run.tools), isNot(contains('repl')));
    expect(_names(run.tools), contains('lookup_thing'));
    expect(run.scriptTools, isEmpty);
    expect(executions.requests, isEmpty);
    expect(
      events.whereType<DebugEvent>().map((e) => e.content),
      contains(contains('no run log')),
    );
    // No repl: every tool is named for a direct call.
    expect(h.session.toolForms('lookup_thing'), ToolCallForm.direct);
  });

  test('without an execution service the run has no repl, and its '
      'composition says why', () async {
    final h = _build(loop: _Loop());

    await _drain(h.session);

    final run = h.loop.started.single;
    expect(_names(run.tools), isNot(contains('repl')));
    expect(run.scriptTools, isEmpty);
    expect(_scriptsOf(h.runLogs), {
      'available': false,
      'reason': 'this server runs no scripts',
    });
  });

  test('a runner that failed its self-test gives no repl, and the reason '
      'names no host detail', () async {
    final executions = _Executions(
      availability: const CodeRunnerAvailability.unavailable(
        'seccomp failed at /opt/runner/cc_codemode',
      ),
    );
    final h = _build(loop: _Loop(), executions: executions);

    await _drain(h.session);

    expect(_names(h.loop.started.single.tools), isNot(contains('repl')));
    expect(h.loop.started.single.scriptTools, isEmpty);
    expect(executions.requests, isEmpty);
    expect(_scriptsOf(h.runLogs), {
      'available': false,
      'reason': 'the script runner is unavailable on this server',
    });
  });

  test('limits that cannot be read leave the run without a repl and say '
      'why', () async {
    final executions = _Executions();
    final h = _build(
      loop: _Loop(),
      executions: executions,
      limits: (_) async => throw StateError('settings unreadable'),
    );

    final events = await _drain(h.session);

    expect(_names(h.loop.started.single.tools), isNot(contains('repl')));
    expect(executions.requests, isEmpty);
    final scripts = _scriptsOf(h.runLogs);
    expect(scripts['available'], isFalse);
    // The exception's text goes to the server log: members read these.
    expect(scripts['reason'], contains('limits could not be read'));
    expect(scripts['reason'], isNot(contains('settings unreadable')));
    final debug = events.whereType<DebugEvent>().map((e) => e.content);
    expect(debug, contains(contains('code mode limits could not be read')));
    expect(debug, everyElement(isNot(contains('settings unreadable'))));
  });

  test('a subagent\'s repl uses the same service under the child\'s own run '
      'id, and its prompt lists the script-only tools', () async {
    final executions = _Executions(calls: [('lookup_thing', const {})]);
    final h = _build(loop: _Loop(spawnChild: true), executions: executions);

    await _drain(h.session);

    expect(h.loop.started, hasLength(2));
    final child = h.loop.started.last;
    expect(child.tools.first, isA<ReplTool>());
    final request = executions.requests.single;
    final childRow = h.runLogs.rows.singleWhere(
      (row) => row.parentRunId == 'run-1',
    );
    expect(request.runId, childRow.id);
    expect(request.runId, isNot('run-1'));
    expect(request.parentToolCallId, 'call_kid');
    // A subagent's scripts get no store (it runs as its parent's agent, and
    // the store is keyed by conversation and agent), while the record still
    // names the conversation and the agent.
    expect(request.storeEnabled, isFalse);
    expect(request.agentId, 'agent-1');
    expect(request.conversationId, 'conv-1');
    expect(executions.seen.single.outcome.status, NestedCallStatus.completed);
    expect(child.config.systemPrompt, contains('callable from `repl`'));
    expect(child.config.systemPrompt, contains('`lookup_thing`'));
  });

  test("a run's scripts read its own past: the main run its conversation, "
      'a subagent its own run, never an id a script chose', () async {
    final transcripts = _PastTranscripts();
    final outputs = InMemoryToolOutputStore();
    final executions = _Executions(calls: [('lookup_thing', const {})]);
    final h = _build(
      loop: _Loop(spawnChild: true),
      executions: executions,
      toolOutputStore: outputs,
      scriptPast: ScriptPastSources(
        transcripts: transcripts,
        hiddenSpaces:
            ({
              required String workspaceId,
              String? callerConversationId,
            }) async {
              transcripts.asked.add(
                'hidden $workspaceId $callerConversationId',
              );
              return const {};
            },
      ),
    );

    await _drain(h.session);

    final request = executions.requests.single;
    final childRow = h.runLogs.rows.singleWhere(
      (row) => row.parentRunId == 'run-1',
    );
    expect(request.readOnly, isFalse);
    final past = request.past!;
    await past.history(start: null, limit: 50, roles: null, tools: null);
    expect(transcripts.asked, [
      'hidden ws-1 conv-1',
      'pageRun ws-1/${childRow.id}',
    ]);
    // The child keeps a value under its parent's store scope; it reads it
    // back, and only what its own run stored is listed.
    final parentOnly = await outputs.put(
      const ToolOutputWrite(
        scope: ToolOutputScope(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
        ),
        toolName: 'bash',
        content: 'parent',
      ),
    );
    final handle = newToolOutputHandle();
    expect(await past.keep(handle: handle, label: 'l', content: 'c'), isTrue);
    expect([for (final e in await past.outputs()) e.handle], [handle]);
    expect(
      (await past.readOutput(parentOnly!.handle, offset: 0, limit: 10)).status,
      ToolOutputReadStatus.notFound,
    );
  });

  test("a main run's past is its conversation", () async {
    final transcripts = _PastTranscripts();
    final executions = _Executions(calls: [('lookup_thing', const {})]);
    final h = _build(
      loop: _Loop(),
      executions: executions,
      toolOutputStore: InMemoryToolOutputStore(),
      scriptPast: ScriptPastSources(
        transcripts: transcripts,
        hiddenSpaces:
            ({
              required String workspaceId,
              String? callerConversationId,
            }) async => const {},
      ),
    );

    await _drain(h.session);

    final request = executions.requests.single;
    expect(request.readOnly, isFalse);
    await request.past!.history(start: null, limit: 50, roles: null, tools: null);
    expect(transcripts.asked, ['page ws-1/conv-1']);
  });

  test('without the sources a run has no past', () async {
    final executions = _Executions(calls: [('lookup_thing', const {})]);
    final h = _build(loop: _Loop(), executions: executions);
    await _drain(h.session);
    expect(executions.requests.single.past, isNull);
  });

  test('a read-only run keeps its cut outputs under its own scope and drops '
      'them when it ends: its worker lists and loads none of them', () async {
    for (final readOnly in [true, false]) {
      final store = _SpyStore();
      final h = _build(
        loop: _Loop(observe: true),
        toolOutputStore: store,
        readOnly: readOnly,
      );
      await _drain(h.session);
      expect(h.loop.started, hasLength(1), reason: 'readOnly: $readOnly');
      const worker = ToolOutputScope(
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
      );
      final written = store.writes.single;
      if (readOnly) {
        expect(written.scope.agentId, 'agent-1#ro:run-1');
        expect(written.scope.conversationId, 'conv-1');
        // Retired when the run ended.
        expect(await store.list(written.scope), isEmpty);
        expect(await store.list(worker), isEmpty);
        final load = await store.read(worker, store.handles.single);
        expect(load.status, ToolOutputReadStatus.notFound);
      } else {
        expect(written.scope, worker);
        expect(await store.list(worker), hasLength(1));
      }
    }
  });

  test("a read-only run loads the worker's cut output by the handle its "
      'history shows, through read_output and loadOutput, and lists it; the '
      "worker's scope gains nothing of the run's", () async {
    const worker = ToolOutputScope(
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      agentId: 'agent-1',
    );
    final store = _SpyStore();
    final stored = await store.put(
      ToolOutputWrite(
        scope: worker,
        toolName: 'bash',
        content: 'WORKER EVIDENCE ${'x' * 5000}',
      ),
    );
    final handle = stored!.handle;
    final executions = _Executions(calls: [('lookup_thing', const {})]);
    final transcripts = _PastTranscripts();
    final h = _build(
      loop: _Loop(readHandle: handle),
      executions: executions,
      toolOutputStore: store,
      readOnly: true,
      scriptPast: ScriptPastSources(
        transcripts: transcripts,
        hiddenSpaces:
            ({
              required String workspaceId,
              String? callerConversationId,
            }) async => const {},
      ),
    );
    await _drain(h.session);

    // read_output, the tool.
    final read = h.loop.read.single;
    expect(read.isError, isFalse, reason: read.content);
    expect(read.content, contains('WORKER EVIDENCE'));
    // loadOutput and outputs(), the script's.
    final request = executions.requests.single;
    expect(request.readOnly, isTrue);
    final past = request.past!;
    final load = await past.readOutput(handle, offset: 0, limit: 100);
    expect(load.status, ToolOutputReadStatus.ok);
    expect(load.chunk!.text, startsWith('WORKER EVIDENCE'));
    expect([for (final e in await past.outputs()) e.handle], [handle]);
    // Nothing the run did went into the worker's scope.
    expect([for (final e in await store.list(worker)) e.handle], [handle]);
    expect(store.writes.where((w) => w.scope == worker), hasLength(1));
  });

  test('stopping the run ends a running script before the run reports '
      'itself finished', () async {
    final executions = _Executions(waitForCancel: true);
    final h = _build(loop: _Loop(), executions: executions);
    bool? endedAtDone;
    final sub = h.session.controller.stream.listen((event) {
      if (event is DoneEvent) {
        endedAtDone ??= executions.ended;
      }
    });
    addTearDown(sub.cancel);

    final run = h.session.run();
    await executions.started.future;
    expect(executions.ended, isFalse);
    await h.session.terminate();
    await run;

    expect(endedAtDone, isTrue);
    expect(executions.ended, isTrue);
  });
}

/// Records which transcript a run's past asked for.
class _PastTranscripts implements ConversationTranscriptPort {
  final List<String> asked = [];

  static const _empty = TranscriptPage(
    rows: [],
    messageCount: 0,
    nextStart: null,
  );

  @override
  Future<TranscriptPage> page({
    required String workspaceId,
    required String conversationId,
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  }) async {
    asked.add('page $workspaceId/$conversationId');
    return _empty;
  }

  @override
  Future<TranscriptPage> pageRun({
    required String workspaceId,
    required String runId,
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  }) async {
    asked.add('pageRun $workspaceId/$runId');
    return _empty;
  }

  @override
  Future<TranscriptSlice?> slice({
    required String workspaceId,
    required String conversationId,
    required String rowId,
    required int offset,
  }) async => null;

  @override
  Future<TranscriptSlice?> sliceRun({
    required String workspaceId,
    required String runId,
    required String rowId,
    required int offset,
  }) async => null;
}

class _SpyStore extends InMemoryToolOutputStore {
  final writes = <ToolOutputWrite>[];
  final handles = <String>[];

  @override
  Future<ToolOutputReference?> put(ToolOutputWrite write) async {
    writes.add(write);
    final reference = await super.put(write);
    if (reference != null) {
      handles.add(reference.handle);
    }
    return reference;
  }
}

class _PassThroughSandbox extends SandboxManager {
  _PassThroughSandbox() : super.test();

  @override
  Future<SandboxWrapResult> wrap({
    required SandboxConfig config,
    required List<String> argv,
    String? workingDirectory,
  }) async => SandboxWrapResult(
    executable: argv.first,
    argv: argv.sublist(1),
    environment: const {},
  );

  @override
  Future<void> disposeSession(String sessionId) async {}
}
