import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/run_transcript.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/run_transcript_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:test/test.dart';

class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopBroker implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
  }) async => const ScopedCredentials(handle: 'h', environment: {});

  @override
  Future<void> revoke(String handle) async {}
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keyless credential so the harness path clears its auth gate without a secret.
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
  Future<void> remove(String providerId, {String? accountLabel}) async {}
}

/// In-memory run-log store, so the test can assert the child row's shape and
/// the ORDER of writes relative to the transcript being finalized.
class _MemRunLogRepo implements AgentRunLogRepository {
  _MemRunLogRepo(this.writeOrder);

  final Map<String, AgentRunLog> rows = {};
  final List<String> writeOrder;

  @override
  Future<void> upsert(AgentRunLog log) async {
    rows[log.id] = log;
    writeOrder.add('run:${log.id}:${log.status.name}');
  }

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final row = rows[id];
    return row != null && row.workspaceId == workspaceId ? row : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemTranscriptRepo implements RunTranscriptRepository {
  _MemTranscriptRepo(this.writeOrder);

  final List<String> writeOrder;
  final Map<String, List<Map<String, dynamic>>> segments = {};
  final Map<String, bool> complete = {};
  final Map<String, TurnOutcome?> outcomes = {};

  @override
  Future<void> upsert({
    required String runId,
    required String workspaceId,
    required List<Map<String, dynamic>> segmentsJson,
    required int transcriptChars,
    required DateTime startedAt,
    required DateTime updatedAt,
    TurnOutcome? outcome,
    bool complete = false,
  }) async {
    segments[runId] = segmentsJson;
    this.complete[runId] = complete;
    outcomes[runId] = outcome;
    writeOrder.add('transcript:$runId:complete=$complete');
  }

  @override
  Future<RunTranscript?> getForRun(String workspaceId, String runId) async =>
      null;

  @override
  Future<int> deleteForRun(String workspaceId, String runId) async => 0;
}

/// Drives the real `_spawnSubagent`: the FIRST run (the parent turn) invokes the
/// registered `task` tool for real, which spawns the subagent; the nested run
/// (the child) yields [childEvents].
class _TaskInvokingLoop implements AgentLoop {
  _TaskInvokingLoop({required this.childEvents, this.childThrows = false})
    : toolCallId = 'call-task-1';

  final List<AgentLoopEvent> childEvents;
  final bool childThrows;
  final String toolCallId;
  int runs = 0;

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
  }) {
    runs++;
    final isParent = runs == 1;
    if (!isParent) {
      return _child();
    }
    return _parent(tools, context);
  }

  Stream<AgentLoopEvent> _child() async* {
    if (childThrows) {
      yield* Stream<AgentLoopEvent>.error(StateError('child exploded'));
      return;
    }
    yield* Stream.fromIterable(childEvents);
  }

  Stream<AgentLoopEvent> _parent(
    List<HarnessTool> tools,
    HarnessToolContext? context,
  ) async* {
    final task = tools.firstWhere((t) => t.name == 'task');
    // Mirrors AgentLoopRunner: the tool sees the id of the call executing it.
    final result = await task.execute(
      const {'description': 'look around', 'label': 'scout'},
      (context ?? const HarnessToolContext(workingDirectory: '.'))
          .withToolCallId(toolCallId),
    );
    yield LoopToolCallResult(
      toolName: 'task',
      toolUseId: toolCallId,
      result: result,
    );
    yield const LoopDone(LoopDoneReason.completed);
  }
}

typedef _Harness = ({
  DispatchSession session,
  _MemRunLogRepo runLogs,
  _MemTranscriptRepo transcripts,
  ActiveStreamRegistry registry,
  List<String> writeOrder,
});

_Harness _buildSession({
  required List<AgentLoopEvent> childEvents,
  bool childThrows = false,
  String? workspaceId = 'ws-1',
}) {
  final tempDir = Directory.systemTemp.createTempSync('cc_subagent_tx_');
  addTearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // One shared list, so the test can assert the transcript is finalized BEFORE
  // the run row flips terminal.
  final writeOrder = <String>[];
  final runLogs = _MemRunLogRepo(writeOrder);
  final transcripts = _MemTranscriptRepo(writeOrder);
  final registry = ActiveStreamRegistry();

  final deps = SandboxDispatchDeps(
    sandbox: _NoopSandbox(),
    broker: _NoopBroker(),
    agentRepo: _UnusedAgentRepo(),
    runLogRepo: runLogs,
    defaultCaps: AgentCapabilities.safeDefault,
    eventBus: null,
    backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
    harnessCredentialStore: _KeylessStore(),
    harnessProviderFactory: const HarnessProviderFactory(),
    agentLoop: _TaskInvokingLoop(
      childEvents: childEvents,
      childThrows: childThrows,
    ),
    runTranscriptRecorder: RunTranscriptRecorder(
      registry: registry,
      repo: transcripts,
    ),
  );

  final session = DispatchSession(
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
    dispatchId: 'd1',
    cliName: 'cc-harness',
    prompt: 'go',
    agentDirHostPath: tempDir.path,
    modelId: 'openai/test-model',
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: workspaceId,
    conversationId: 'conv-1',
    runLogId: 'run-parent',
    mode: Mode.chat,
  );

  return (
    session: session,
    runLogs: runLogs,
    transcripts: transcripts,
    registry: registry,
    writeOrder: writeOrder,
  );
}

Future<void> _drain(DispatchSession session) async {
  final drained = session.controller.stream.drain<void>();
  await session.run();
  await drained;
}

String? _childRunId(_MemRunLogRepo repo) => repo.rows.values
    .where((r) => r.role == AgentRunRole.sub)
    .map((r) => r.id)
    .firstOrNull;

void main() {
  test(
    'a subagent run records its own tool calls, reasoning and text',
    () async {
      final h = _buildSession(
        childEvents: [
          const LoopThinkingDelta('where to look'),
          const LoopToolCallStart(
            toolName: 'Read',
            toolUseId: 'c1',
            args: {'path': 'a.dart'},
          ),
          LoopToolCallResult(
            toolName: 'Read',
            toolUseId: 'c1',
            result: HarnessToolResult.success('file body'),
          ),
          const LoopTextDelta('found it'),
          const LoopDone(LoopDoneReason.completed),
        ],
      );

      await _drain(h.session);

      final childId = _childRunId(h.runLogs);
      expect(childId, isNotNull, reason: 'a child run row must be written');
      final recorded = decodeTranscript(h.transcripts.segments[childId]);
      expect(recorded.map((s) => s.runtimeType.toString()), [
        'ReasoningSegment',
        'ToolSegment',
        'TextSegment',
      ]);
      final tool = recorded[1] as ToolSegment;
      expect(tool.toolName, 'Read');
      expect(tool.outputs, 'file body');
      expect(tool.status, ToolSegmentStatus.ok);
      expect((recorded[2] as TextSegment).text, 'found it');
    },
  );

  test('the transcript is keyed by the CHILD run id, not the parent', () async {
    final h = _buildSession(
      childEvents: [
        const LoopTextDelta('done'),
        const LoopDone(LoopDoneReason.completed),
      ],
    );

    await _drain(h.session);

    final childId = _childRunId(h.runLogs)!;
    expect(childId, isNot('run-parent'));
    expect(h.transcripts.segments.keys, [childId]);
  });

  test('the child row records the spawning task tool-call id', () async {
    final h = _buildSession(
      childEvents: [const LoopDone(LoopDoneReason.completed)],
    );

    await _drain(h.session);

    final child = h.runLogs.rows[_childRunId(h.runLogs)]!;
    expect(child.spawnToolCallId, 'call-task-1');
    expect(child.parentRunId, 'run-parent');
  });

  test(
    'the recording is finalized before the child row flips terminal',
    () async {
      final h = _buildSession(
        childEvents: [
          const LoopTextDelta('done'),
          const LoopDone(LoopDoneReason.completed),
        ],
      );

      await _drain(h.session);

      final childId = _childRunId(h.runLogs)!;
      final finalize = h.writeOrder.indexOf(
        'transcript:$childId:complete=true',
      );
      final terminal = h.writeOrder.indexOf('run:$childId:completed');
      expect(finalize, greaterThanOrEqualTo(0));
      expect(terminal, greaterThanOrEqualTo(0));
      expect(
        finalize,
        lessThan(terminal),
        reason:
            'a client must never see `completed` next to a half-written '
            'transcript',
      );
    },
  );

  test('the run stream is released once the subagent finishes', () async {
    final h = _buildSession(
      childEvents: [const LoopDone(LoopDoneReason.completed)],
    );

    await _drain(h.session);

    expect(h.registry.isActive(_childRunId(h.runLogs)!), isFalse);
  });

  test('a child error is recorded and the outcome is failed', () async {
    final h = _buildSession(
      childEvents: [
        const LoopError('tool blew up'),
        const LoopDone(LoopDoneReason.completed),
      ],
    );

    await _drain(h.session);

    final childId = _childRunId(h.runLogs)!;
    final recorded = decodeTranscript(h.transcripts.segments[childId]);
    expect((recorded.single as ErrorSegment).message, 'tool blew up');
    expect(h.transcripts.outcomes[childId], TurnOutcome.failed);
  });

  test(
    'a crashing child still leaves a finalized, readable transcript',
    () async {
      final h = _buildSession(childEvents: const [], childThrows: true);

      await _drain(h.session);

      final childId = _childRunId(h.runLogs)!;
      expect(h.transcripts.complete[childId], isTrue);
      expect(h.transcripts.outcomes[childId], TurnOutcome.failed);
      final recorded = decodeTranscript(h.transcripts.segments[childId]);
      expect(
        recorded.whereType<ErrorSegment>().single.message,
        contains('child exploded'),
      );
    },
  );

  test('an in-flight tool is marked interrupted when the child dies', () async {
    final h = _buildSession(
      childEvents: [
        const LoopToolCallStart(toolName: 'Bash', toolUseId: 'c1', args: {}),
        // No result, no LoopDone — the stream just ends.
      ],
    );

    await _drain(h.session);

    final childId = _childRunId(h.runLogs)!;
    final recorded = decodeTranscript(h.transcripts.segments[childId]);
    expect(
      (recorded.single as ToolSegment).status,
      ToolSegmentStatus.interrupted,
    );
  });

  test(
    'a workspace-less dispatch records nothing rather than unreachably',
    () async {
      final h = _buildSession(
        childEvents: [
          const LoopTextDelta('done'),
          const LoopDone(LoopDoneReason.completed),
        ],
        workspaceId: null,
      );

      await _drain(h.session);

      expect(h.transcripts.segments, isEmpty);
    },
  );
}
