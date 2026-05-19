import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart'
    as ap;
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart'
    hide ThinkingEvent;
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Workspace every stream in this suite is processed in; the turn's message
/// update must be written back through it.
const _ws = 'ws-1';

class _FakeMessagingRepo implements MessagingRepository {
  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) async =>
      null;

  final updateCalls = <_UpdateCall>[];
  final compactedIds = <String>[];
  final embeddings = <String, Uint8List>{};
  List<ChannelMessage> storedMessages = [];

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    updateCalls.add(_UpdateCall(workspaceId, messageId, content, metadata));
  }

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async => id ?? 'sent';

  @override
  Future<List<ChannelMessage>> searchInChannel(
    String workspaceId,
    String channelId,
    String query, {
    int limit = 20,
  }) async => const [];

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async => storedMessages;

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async =>
      compactedIds.addAll(ids);

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {
    embeddings[messageId] = Uint8List.fromList(embedding);
  }

  // --- unused stubs ---
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) => const Stream.empty();
  @override
  Stream<List<Channel>> watchChannels() => const Stream.empty();
  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => const Stream.empty();
  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => const Stream.empty();
  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      const Stream.empty();
  @override
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async => null;
  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
    List<String> repoIds = const [],
  }) async => throw UnimplementedError();
  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) async {}
  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {}
  @override
  Future<bool> channelExists(String workspaceId, String channelId) async =>
      true;
  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => [];
  @override
  Future<void> deleteChannel(String workspaceId, String channelId) async {}
  @override
  Future<void> updateChannelName(
    String workspaceId,
    String channelId,
    String name,
  ) async {}
  @override
  Future<void> clearChannelMessages(
    String workspaceId,
    String channelId,
  ) async {}
  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) async {}
  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String channelId,
  ) async => [];
  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];
  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => MessagePage.empty;
  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async => const [];
  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async => const [];
}

class _FakeAgentDispatchService implements AgentDispatchService {
  @override
  Future<bool> pauseRun(String runLogId) async => false;

  @override
  Future<bool> resumeRun(String runLogId) async => false;

  @override
  Future<({List<String> args, Map<String, String> env})> Function(String)?
  get adapterLaunchOverrides => null;

  bool completeRunCalled = false;
  bool failRunCalled = false;
  String? lastCompleteRunSummary;
  RunCost? lastCompleteRunCost;
  String? lastFailError;

  @override
  Future<void> completeRun(
    AgentRunLog runLog,
    String? summary, {
    RunCost? cost,
  }) async {
    completeRunCalled = true;
    lastCompleteRunSummary = summary;
    lastCompleteRunCost = cost;
  }

  @override
  Future<void> failRun(AgentRunLog runLog, String error) async {
    failRunCalled = true;
    lastFailError = error;
  }

  @override
  Future<AgentDispatchResult> dispatch({
    required String agentId,
    required String prompt,
    required String workingDirectory,
    String? adapterId,
    String? workspaceId,
    String? conversationId,
    String? channelId,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? requestedByUserId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
    AgentRunRole role = AgentRunRole.main,
    String? parentAgentId,
    int? costCapCents,
  }) async => throw UnimplementedError();

  @override
  Future<void> stopRun(String workspaceId, String runLogId) async =>
      throw UnimplementedError();

  @override
  Future<bool> steerRun(
    String runLogId,
    String message, {
    bool followUp = false,
  }) async => throw UnimplementedError();
}

class _UpdateCall {
  _UpdateCall(this.workspaceId, this.messageId, this.content, this.metadata);

  /// Workspace the update was written through — the message id alone addresses
  /// no database file.
  final String workspaceId;
  final String messageId;
  final String? content;
  final Map<String, dynamic>? metadata;
}

AgentRunLog _testRunLog() => AgentRunLog(
  id: 'run-1',
  agentId: 'agent-1',
  startedAt: DateTime(2025, 1, 1, 12, 0),
  status: RunStatus.running,
);

DateTime _t(int second) => DateTime(2025, 1, 1, 12, 0, second);

/// Drives [events] through a fresh processor and returns the final state.
Future<_Result> _run(
  List<AgentProcessEvent> events, {
  bool close = true,
  void Function(StreamController<AgentProcessEvent>)? mid,
}) async {
  final repo = _FakeMessagingRepo();
  final dispatch = _FakeAgentDispatchService();
  final registry = ActiveStreamRegistry();
  final processor = AgentStreamProcessor(
    agentDispatchService: dispatch,
    repo: repo,
    streamRegistry: registry,
  );
  final controller = StreamController<AgentProcessEvent>.broadcast();
  const messageId = 'run-1';
  registry.register(messageId);

  processor.processStream(
    stream: controller.stream,
    workspaceId: _ws,
    dispatchResult: AgentDispatchResult(
      stream: controller.stream,
      dispatchId: 'd-1',
      runLog: _testRunLog(),
    ),
    channelId: 'ch-1',
    agentId: 'agent-1',
    agentName: 'Tester',
    messageId: messageId,
  );

  for (final e in events) {
    controller.add(e);
  }
  await pumpEventQueue();
  mid?.call(controller);
  await pumpEventQueue();
  if (close) {
    await controller.close();
    await pumpEventQueue();
  }
  return _Result(repo, dispatch, registry);
}

class _Result {
  _Result(this.repo, this.dispatch, this.registry);
  final _FakeMessagingRepo repo;
  final _FakeAgentDispatchService dispatch;
  final ActiveStreamRegistry registry;

  _UpdateCall get finalCall =>
      repo.updateCalls.lastWhere((c) => c.metadata?['streamComplete'] == true);

  List<TranscriptSegment> get segments =>
      decodeTranscript(finalCall.metadata?['segments']);

  String? get content => finalCall.content;
  String? get outcome => finalCall.metadata?['outcome'] as String?;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('interleaving', () {
    test('reasoning -> tool -> text -> tool -> text preserves order', () async {
      final r = await _run([
        ap.ThinkingEvent(content: 'let me look', timestamp: _t(1)),
        ToolCallEvent(
          toolName: 'Read',
          toolCallId: 'c1',
          inputs: {'file_path': 'a.dart'},
          timestamp: _t(2),
        ),
        ToolResultEvent(
          toolCallId: 'c1',
          outputs: 'contents',
          timestamp: _t(3),
        ),
        TextEvent(content: 'I read it. ', timestamp: _t(4)),
        ToolCallEvent(
          toolName: 'Edit',
          toolCallId: 'c2',
          inputs: {'file_path': 'a.dart'},
          timestamp: _t(5),
        ),
        ToolResultEvent(toolCallId: 'c2', outputs: 'edited', timestamp: _t(6)),
        TextEvent(content: 'Done.', timestamp: _t(7)),
        DoneEvent(timestamp: _t(8)),
      ]);

      final seg = r.segments;
      expect(seg.map((s) => s.runtimeType.toString()).toList(), [
        'ReasoningSegment',
        'ToolSegment',
        'TextSegment',
        'ToolSegment',
        'TextSegment',
      ]);
      expect((seg[0] as ReasoningSegment).text, 'let me look');
      expect((seg[1] as ToolSegment).toolName, 'Read');
      expect((seg[1] as ToolSegment).status, ToolSegmentStatus.ok);
      expect((seg[1] as ToolSegment).outputs, 'contents');
      expect((seg[2] as TextSegment).text, 'I read it. ');
      expect((seg[3] as ToolSegment).toolName, 'Edit');
      expect((seg[4] as TextSegment).text, 'Done.');
      // Every transcript write goes through the workspace the stream was
      // dispatched in; a message id on its own selects no database file.
      expect(r.repo.updateCalls.map((c) => c.workspaceId).toSet(), {_ws});
    });

    test('consecutive text deltas coalesce into one segment', () async {
      final r = await _run([
        TextEvent(content: 'Hello ', timestamp: _t(1)),
        TextEvent(content: 'there ', timestamp: _t(2)),
        TextEvent(content: 'world', timestamp: _t(3)),
        DoneEvent(timestamp: _t(4)),
      ]);
      expect(r.segments, hasLength(1));
      expect((r.segments.single as TextSegment).text, 'Hello there world');
    });

    test('a tool call splits the text into separate segments', () async {
      final r = await _run([
        TextEvent(content: 'before', timestamp: _t(1)),
        ToolCallEvent(toolName: 'Bash', toolCallId: 'c1', timestamp: _t(2)),
        ToolResultEvent(toolCallId: 'c1', outputs: 'ok', timestamp: _t(3)),
        TextEvent(content: 'after', timestamp: _t(4)),
        DoneEvent(timestamp: _t(5)),
      ]);
      final texts = r.segments
          .whereType<TextSegment>()
          .map((s) => s.text)
          .toList();
      expect(texts, ['before', 'after']);
    });
  });

  group('tool pairing', () {
    test('pairs result by toolCallId even when interleaved', () async {
      final r = await _run([
        ToolCallEvent(toolName: 'A', toolCallId: 'c1', timestamp: _t(1)),
        ToolCallEvent(toolName: 'B', toolCallId: 'c2', timestamp: _t(2)),
        ToolResultEvent(toolCallId: 'c1', outputs: 'ra', timestamp: _t(3)),
        ToolResultEvent(toolCallId: 'c2', outputs: 'rb', timestamp: _t(4)),
        DoneEvent(timestamp: _t(5)),
      ]);
      final tools = r.segments.cast<ToolSegment>();
      expect(tools[0].toolName, 'A');
      expect(tools[0].outputs, 'ra');
      expect(tools[1].toolName, 'B');
      expect(tools[1].outputs, 'rb');
    });

    test('falls back to last open tool when result id is empty', () async {
      final r = await _run([
        ToolCallEvent(toolName: 'A', toolCallId: '', timestamp: _t(1)),
        ToolResultEvent(toolCallId: '', outputs: 'paired', timestamp: _t(2)),
        DoneEvent(timestamp: _t(3)),
      ]);
      expect(r.segments, hasLength(1));
      final tool = r.segments.single as ToolSegment;
      expect(tool.outputs, 'paired');
      expect(tool.status, ToolSegmentStatus.ok);
    });

    test('partial outputs append then final result replaces', () async {
      final r = await _run([
        ToolCallEvent(toolName: 'Bash', toolCallId: 'c1', timestamp: _t(1)),
        ToolResultEvent(
          toolCallId: 'c1',
          outputs: 'line1\n',
          isPartial: true,
          timestamp: _t(2),
        ),
        ToolResultEvent(
          toolCallId: 'c1',
          outputs: 'line2\n',
          isPartial: true,
          timestamp: _t(3),
        ),
        ToolResultEvent(
          toolCallId: 'c1',
          outputs: 'final complete output',
          timestamp: _t(4),
        ),
        DoneEvent(timestamp: _t(5)),
      ]);
      final tool = r.segments.single as ToolSegment;
      expect(tool.outputs, 'final complete output');
      expect(tool.status, ToolSegmentStatus.ok);
    });

    test('isError maps to error status', () async {
      final r = await _run([
        ToolCallEvent(toolName: 'Bash', toolCallId: 'c1', timestamp: _t(1)),
        ToolResultEvent(
          toolCallId: 'c1',
          outputs: 'boom',
          isError: true,
          timestamp: _t(2),
        ),
        DoneEvent(timestamp: _t(3)),
      ]);
      expect(
        (r.segments.single as ToolSegment).status,
        ToolSegmentStatus.error,
      );
    });

    test(
      'orphan result (no open call) creates a terminal tool segment',
      () async {
        final r = await _run([
          ToolResultEvent(
            toolCallId: 'x',
            outputs: 'orphan',
            toolName: 'Ghost',
            timestamp: _t(1),
          ),
          DoneEvent(timestamp: _t(2)),
        ]);
        final tool = r.segments.single as ToolSegment;
        expect(tool.toolName, 'Ghost');
        expect(tool.outputs, 'orphan');
        expect(tool.status, ToolSegmentStatus.ok);
      },
    );
  });

  group('errors and violations', () {
    test('error event becomes an ErrorSegment', () async {
      final r = await _run([
        ErrorEvent(
          content: 'rate limited',
          code: 'rate_limit_error',
          source: 'anthropic',
          timestamp: _t(1),
        ),
        DoneEvent(timestamp: _t(2)),
      ]);
      final seg = r.segments.single as ErrorSegment;
      expect(seg.message, 'rate limited');
      expect(seg.code, 'rate_limit_error');
    });

    test(
      'sandbox violation becomes a ViolationSegment and is NOT in content',
      () async {
        final r = await _run([
          TextEvent(content: 'answer', timestamp: _t(1)),
          SandboxViolationEvent(
            content: 'blocked net',
            action: 'network-connect',
            timestamp: _t(2),
          ),
          DoneEvent(timestamp: _t(3)),
        ]);
        expect(r.segments.whereType<ViolationSegment>(), hasLength(1));
        expect(r.content, 'answer');
        expect(r.content, isNot(contains('blocked net')));
      },
    );

    test('debug events are dropped', () async {
      final r = await _run([
        DebugEvent(content: 'launching pi', timestamp: _t(1)),
        TextEvent(content: 'hi', timestamp: _t(2)),
        DoneEvent(timestamp: _t(3)),
      ]);
      expect(r.segments, hasLength(1));
      expect(r.segments.single, isA<TextSegment>());
    });
  });

  group('finalization', () {
    test('completed outcome when DoneEvent observed', () async {
      final r = await _run([
        TextEvent(content: 'hi', timestamp: _t(1)),
        DoneEvent(timestamp: _t(2)),
      ]);
      expect(r.outcome, 'completed');
      expect(r.dispatch.completeRunCalled, isTrue);
    });

    test('interrupted outcome when stream closes without DoneEvent', () async {
      final r = await _run([
        ToolCallEvent(toolName: 'Bash', toolCallId: 'c1', timestamp: _t(1)),
      ]);
      expect(r.outcome, 'interrupted');
      // The in-flight tool is rewritten to interrupted.
      expect(
        (r.segments.single as ToolSegment).status,
        ToolSegmentStatus.interrupted,
      );
    });

    test('content is the concatenation of text segments', () async {
      final r = await _run([
        TextEvent(content: 'part one', timestamp: _t(1)),
        ToolCallEvent(toolName: 'Read', toolCallId: 'c1', timestamp: _t(2)),
        ToolResultEvent(toolCallId: 'c1', outputs: 'x', timestamp: _t(3)),
        TextEvent(content: 'part two', timestamp: _t(4)),
        DoneEvent(timestamp: _t(5)),
      ]);
      expect(r.content, 'part one\n\npart two');
    });

    test('completeRun summary is the first line of content', () async {
      final r = await _run([
        TextEvent(content: 'summary line\nmore detail', timestamp: _t(1)),
        DoneEvent(timestamp: _t(2)),
      ]);
      expect(r.dispatch.lastCompleteRunSummary, 'summary line');
    });

    test('turn stats persisted from usage events', () async {
      final r = await _run([
        TextEvent(content: 'hi', timestamp: _t(1)),
        UsageEvent(
          usage: const RunUsage(
            inputTokens: 1000,
            outputTokens: 500,
            estimatedCostCents: 12,
          ),
          timestamp: _t(2),
        ),
        DoneEvent(timestamp: _t(3)),
      ]);
      final turn = r.finalCall.metadata!['turn'] as Map<String, dynamic>;
      expect(turn['totalTokens'], 1500);
      expect(turn['costCents'], 12);
      expect(turn['durationMs'], isA<int>());
    });

    test(
      'answer-less turn ending on an error is failed and carries the error text',
      () async {
        // The harness's no-credential refusal: an ErrorEvent followed by a
        // clean DoneEvent, so the stream never errors and this lands in
        // `_onDone`. It used to be laundered into `completed` with empty
        // content — a blank bubble, a body-less notification and no retry.
        final r = await _run([
          ErrorEvent(
            content: '[harness] No credential for provider "anthropic".',
            source: 'harness',
            timestamp: _t(1),
          ),
          DoneEvent(timestamp: _t(2)),
        ]);

        expect(r.outcome, 'failed');
        expect(r.finalCall.metadata!['error'], isTrue);
        expect(r.finalCall.metadata!['runId'], isNotNull);
        expect(r.dispatch.failRunCalled, isTrue);
        expect(r.dispatch.completeRunCalled, isFalse);
        expect(r.dispatch.lastFailError, contains('No credential'));
        // The error itself is still preserved as a transcript row.
        expect(r.segments.single, isA<ErrorSegment>());
      },
    );

    test('an error the turn recovered from still completes', () async {
      // ErrorEvent doubles as the stderr channel for subprocess adapters, so a
      // turn that produced a real answer must never be marked failed just
      // because something was written to stderr along the way.
      final r = await _run([
        ErrorEvent(content: '[acp] warning: noisy stderr', timestamp: _t(1)),
        TextEvent(content: 'here is the answer', timestamp: _t(2)),
        DoneEvent(timestamp: _t(3)),
      ]);

      expect(r.outcome, 'completed');
      expect(r.finalCall.metadata!.containsKey('error'), isFalse);
      expect(r.dispatch.completeRunCalled, isTrue);
      expect(r.dispatch.failRunCalled, isFalse);
      expect(r.content, 'here is the answer');
    });

    test('a turn that produced literally nothing still completes', () async {
      // No text and no error: there is nothing to blame, so the old
      // completed/interrupted classification stands.
      final r = await _run([DoneEvent(timestamp: _t(1))]);

      expect(r.outcome, 'completed');
      expect(r.finalCall.metadata!.containsKey('error'), isFalse);
      expect(r.dispatch.completeRunCalled, isTrue);
    });

    test('error path preserves partial segments and marks failed', () async {
      final repo = _FakeMessagingRepo();
      final dispatch = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatch,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>();
      registry.register('run-1');
      processor.processStream(
        stream: controller.stream,
        workspaceId: _ws,
        dispatchResult: AgentDispatchResult(
          stream: controller.stream,
          dispatchId: 'd-1',
          runLog: _testRunLog(),
        ),
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'Tester',
        messageId: 'run-1',
      );
      controller.add(TextEvent(content: 'partial answer', timestamp: _t(1)));
      await pumpEventQueue();
      controller.addError(StateError('stream blew up'));
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      final finalCall = repo.updateCalls.lastWhere(
        (c) => c.metadata?['streamComplete'] == true,
      );
      expect(finalCall.metadata?['outcome'], 'failed');
      expect(finalCall.metadata?['error'], true);
      final segs = decodeTranscript(finalCall.metadata?['segments']);
      expect(
        segs.whereType<TextSegment>().map((s) => s.text),
        contains('partial answer'),
      );
      expect(segs.whereType<ErrorSegment>(), isNotEmpty);
      expect(dispatch.failRunCalled, isTrue);
    });
  });

  group('live updates', () {
    test('registry receives ordered updates and a TurnFinished', () async {
      final repo = _FakeMessagingRepo();
      final dispatch = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatch,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('run-1');
      final received = <Object>[];
      registry.updatesFor('run-1')!.listen((u) => received.add(u.runtimeType));

      processor.processStream(
        stream: controller.stream,
        workspaceId: _ws,
        dispatchResult: AgentDispatchResult(
          stream: controller.stream,
          dispatchId: 'd-1',
          runLog: _testRunLog(),
        ),
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'Tester',
        messageId: 'run-1',
      );

      controller.add(TextEvent(content: 'hello', timestamp: _t(1)));
      await pumpEventQueue();
      controller.add(DoneEvent(timestamp: _t(2)));
      await controller.close();
      await pumpEventQueue();

      expect(received.first.toString(), 'SegmentOpened');
      expect(received.any((t) => t.toString() == 'TurnFinished'), isTrue);
      // The stream is unregistered after finishing.
      expect(registry.isActive('run-1'), isFalse);
    });
  });
}
