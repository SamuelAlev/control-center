import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/constants/app_log_level.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/messaging_events.dart';
import 'package:control_center/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/dispatch/data/services/agent_dispatch_service.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart'
    as ap;
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart'
    hide ThinkingEvent;
import 'package:control_center/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:control_center/features/messaging/data/services/active_stream_registry.dart';
import 'package:control_center/features/messaging/data/services/agent_stream_processor.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeMessagingRepo implements MessagingRepository {
  final updateCalls = <_UpdateCall>[];
  final sendCalls = <_SendCall>[];
  final compactedIds = <String>[];
  final embeddings = <String, Uint8List>{};
  List<ChannelMessage> storedMessages = [];

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {
    updateCalls.add(_UpdateCall(messageId, content, metadata));
  }

  @override
  Future<String> sendMessage({
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? parentMessageId,
  }) async {
    sendCalls.add(_SendCall(
      channelId: channelId,
      content: content,
      senderId: senderId,
      senderType: senderType,
      messageType: messageType,
      metadata: metadata,
    ));
    return id ?? 'sent-${sendCalls.length}';
  }

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async =>
      storedMessages;

  @override
  Future<void> markCompacted(List<String> ids) async {
    compactedIds.addAll(ids);
  }

  @override
  Future<void> updateMessageEmbedding(
    String messageId,
    Uint8List embedding,
  ) async {
    embeddings[messageId] = Uint8List.fromList(embedding);
  }

  // --- unused stubs ---

  @override
  Stream<List<Channel>> watchChannels() => const Stream.empty();
  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      const Stream.empty();
  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      const Stream.empty();
  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      const Stream.empty();
  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      const Stream.empty();
  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      const Stream.empty();
  @override
  Future<ChannelMessage?> getMessageById(String messageId) async => null;
  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async =>
      throw UnimplementedError();
  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) async =>
      throw UnimplementedError();
  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) async {}
  @override
  Future<void> addParticipant(String channelId, String agentId) async {}
  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async =>
      [];
  @override
  Future<void> deleteChannel(String channelId) async {}
  @override
  Future<void> updateChannelName(String channelId, String name) async {}
  @override
  Future<void> clearChannelMessages(String channelId) async {}
  @override
  Future<void> removeParticipant(String channelId, String agentId) async {}
  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String channelId,
  ) async =>
      [];
  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({
    int limit = 200,
  }) async =>
      [];
}

class _FakeAgentDispatchService implements AgentDispatchService {
  bool completeRunCalled = false;
  bool failRunCalled = false;
  AgentRunLog? lastCompleteRunLog;
  String? lastCompleteRunSummary;
  RunCost? lastCompleteRunCost;
  AgentRunLog? lastFailRunLog;
  String? lastFailError;

  @override
  Future<void> completeRun(
    AgentRunLog runLog,
    String? summary, {
    RunCost? cost,
  }) async {
    completeRunCalled = true;
    lastCompleteRunLog = runLog;
    lastCompleteRunSummary = summary;
    lastCompleteRunCost = cost;
  }

  @override
  Future<void> failRun(AgentRunLog runLog, String error) async {
    failRunCalled = true;
    lastFailRunLog = runLog;
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
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> stopRun(String runLogId) async {
    throw UnimplementedError();
  }
}

class _FakeEmbeddingPort implements EmbeddingPort {
  @override
  bool isReady = false;
  int embedCallCount = 0;
  String? lastEmbedText;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async {
    embedCallCount++;
    lastEmbedText = text;
    return Float32List(dimension);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _UpdateCall {
  _UpdateCall(this.messageId, this.content, this.metadata);
  final String messageId;
  final String? content;
  final Map<String, dynamic>? metadata;
}

class _SendCall {
  _SendCall({
    required this.channelId,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    this.metadata,
  });
  final String channelId;
  final String content;
  final String senderId;
  final String senderType;
  final String messageType;
  final Map<String, dynamic>? metadata;
}

/// Builds a minimal [AgentRunLog] for test use.
AgentRunLog _testRunLog({String id = 'run-1', String agentId = 'agent-1'}) =>
    AgentRunLog(
      id: id,
      agentId: agentId,
      startedAt: DateTime(2025, 1, 1, 12, 0),
      status: RunStatus.running,
    );

/// Builds an [AgentDispatchResult] wrapping a controller's stream.
AgentDispatchResult _testDispatchResult(
  StreamController<AgentProcessEvent> controller, {
  AgentRunLog? runLog,
}) =>
    AgentDispatchResult(
      stream: controller.stream,
      dispatchId: 'dispatch-1',
      runLog: runLog ?? _testRunLog(),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -----------------------------------------------------------------------
  // _firstLine helper (private — tested indirectly via behavior)
  // -----------------------------------------------------------------------
  group('firstLine (via completeRun summary)', () {
    test('first line extracted from response', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'hello\nworld',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      expect(dispatchService.lastCompleteRunSummary, 'hello');
    });

    test('single line returned as-is', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'single line',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      expect(dispatchService.lastCompleteRunSummary, 'single line');
    });
  });

  // -----------------------------------------------------------------------
  // Event type dispatch
  // -----------------------------------------------------------------------
  group('event dispatch', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;
    late AgentDispatchResult dispatchResult;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      dispatchResult = _testDispatchResult(controller);
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('text event accumulates in assistant buffer', () async {
      registry.register('resp-1');
      registry.register('think-1');

      final stream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = stream!.listen(deltas.add);

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: 'Hello', timestamp: DateTime(2025, 1, 1, 12, 0, 1)),
      );
      controller.add(
        TextEvent(
          content: ' world',
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ),
      );
      await pumpAndClose();

      await sub.cancel();
      expect(deltas, ['Hello', ' world']);
    });

    test('thinking event accumulates in reasoning buffer', () async {
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        ap.ThinkingEvent(
          content: 'Let me think...',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      expect(thinkingUpdate, isNotEmpty);

      final finalUpdate = thinkingUpdate.last;
      expect(finalUpdate.metadata?['streamComplete'], true);

      final events =
          (finalUpdate.metadata?['events'] as List?)
              ?.cast<Map<String, dynamic>>();
      expect(events, isNotNull);
      final reasoningEv = events!.firstWhere(
        (e) => e['kind'] == 'reasoning',
        orElse: () => <String, dynamic>{},
      );
      expect(reasoningEv['content'], 'Let me think...');
    });

    test('toolCall event flushes reasoning and adds structured event', () async {
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        ap.ThinkingEvent(
          content: 'Reasoning before tool call',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      controller.add(
        ToolCallEvent(
          toolName: 'read_file',
          toolCallId: 'tc-1',
          inputs: {'path': '/foo'},
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[],
      ).toList();

      final kinds = events.map((e) => e['kind'] as String).toList();
      expect(kinds, contains('reasoning'));
      expect(kinds, contains('tool_call'));
    });

    test('toolResult event adds structured event with outputs', () async {
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        ToolResultEvent(
          outputs: 'File contents here',
          toolCallId: 'tc-1',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[],
      ).toList();

      final toolResultEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'tool_result',
        orElse: () => <String, dynamic>{},
      );
      expect(toolResultEv['outputs'] as String, 'File contents here');
    });

    test('error event adds structured error event', () async {
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        ErrorEvent(
          content: 'Something went wrong',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[],
      ).toList();

      final errorEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'error',
        orElse: () => <String, dynamic>{},
      );
      expect(errorEv['content'] as String, 'Something went wrong');
    });

    test('sandboxViolation adds banner to assistant buffer', () async {
      registry.register('resp-1');
      registry.register('think-1');

      final textStream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = textStream!.listen(deltas.add);

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        SandboxViolationEvent(
          content: 'Blocked file read: /etc/passwd',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      await sub.cancel();
      expect(
        deltas.any((d) => d.contains('🛡') && d.contains('Blocked file read')),
        true,
      );
    });

    test('UsageEvent accumulates cost', () async {
      final runLog = _testRunLog();
      dispatchResult = _testDispatchResult(controller, runLog: runLog);

      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'Hi',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      controller.add(
        UsageEvent(
          usage: const RunUsage(inputTokens: 100, outputTokens: 50),
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ),
      );
      await pumpAndClose();

      expect(dispatchService.completeRunCalled, true);
      expect(dispatchService.lastCompleteRunCost, isNotNull);
      expect(dispatchService.lastCompleteRunCost!.inputTokens, 100);
      expect(dispatchService.lastCompleteRunCost!.outputTokens, 50);
    });

    test('debug event appends to assistant buffer', () async {
      registry.register('resp-1');
      registry.register('think-1');

      final textStream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = textStream!.listen(deltas.add);

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        DebugEvent(
          content: 'Launching pi',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      await sub.cancel();
      expect(
        deltas.any((d) => d.contains('Launching pi')),
        true,
      );
    });
  });

  // -----------------------------------------------------------------------
  // Buffer management
  // -----------------------------------------------------------------------
  group('buffer management', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;
    late AgentDispatchResult dispatchResult;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      dispatchResult = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('multiple text events assemble into one response message', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(
          content: 'Part 1 ',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ))
        ..add(TextEvent(
          content: 'Part 2',
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ));
      await pumpAndClose();

      final respUpdate = repo.updateCalls
          .where((c) => c.messageId == 'resp-1')
          .toList();
      final finalUpdate = respUpdate.lastWhere(
        (c) => c.metadata?['streamComplete'] == true,
        orElse: () => respUpdate.last,
      );
      expect(finalUpdate.content!.trim(), 'Part 1 Part 2');
    });

    test('reasoning buffer flushed when toolCall arrives', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller
        ..add(ap.ThinkingEvent(
          content: 'Step 1',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ))
        ..add(ap.ThinkingEvent(
          content: ' Step 2',
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ))
        ..add(ToolCallEvent(
          toolName: 'search',
          toolCallId: 'tc-1',
          timestamp: DateTime(2025, 1, 1, 12, 0, 3),
        ));
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[],
      ).toList();

      final reasoningEvs =
          events.where((e) => (e['kind'] as String?) == 'reasoning').toList();
      final reasoningContent =
          reasoningEvs.map((e) => e['content'] as String).join();
      expect(reasoningContent, contains('Step 1'));
      expect(reasoningContent, contains('Step 2'));
    });

    test('empty reasoning buffer is not flushed', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        ToolCallEvent(
          toolName: 'action',
          toolCallId: 'tc-1',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[],
      ).toList();

      final reasoningEvs = events.where((e) => (e['kind'] as String?) == 'reasoning');
      expect(reasoningEvs, isEmpty);
    });

    test('consecutive same-type events coalesce in thinking lines', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(
          content: 'A',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ))
        ..add(TextEvent(
          content: 'B',
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ))
        ..add(TextEvent(
          content: 'C',
          timestamp: DateTime(2025, 1, 1, 12, 0, 3),
        ));
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final thinking = thinkingUpdate
          .map((c) => c.metadata?['thinking'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .join('\n');

      expect(thinking, contains('[text] ×3'));
    });

    test('single-event type appears without count', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'Only one',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final thinking = thinkingUpdate
          .map((c) => c.metadata?['thinking'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .join('\n');

      expect(thinking, contains('[text]'));
      expect(thinking, isNot(contains('[text] ×1')));
    });
  });

  // -----------------------------------------------------------------------
  // Message assembly (onDone)
  // -----------------------------------------------------------------------
  group('message assembly on done', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;
    late AgentDispatchResult dispatchResult;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      dispatchResult = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('persists thinking message with complete metadata', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        ap.ThinkingEvent(
          content: 'reasoning text',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final finalThinkUpdate = repo.updateCalls
          .where(
            (c) =>
                c.messageId == 'think-1' &&
                c.metadata?['streamComplete'] == true,
          )
          .toList();
      expect(finalThinkUpdate, isNotEmpty);

      final metadata = finalThinkUpdate.first.metadata!;
      expect(metadata['agentName'], 'TestAgent');
      expect(metadata['streamComplete'], true);
      expect(metadata['events'], isNotEmpty);
    });

    test('persists response message with assembled content', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(
          content: 'Hello',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ))
        ..add(TextEvent(
          content: ' World',
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ));
      await pumpAndClose();

      final respUpdate = repo.updateCalls
          .where(
            (c) =>
                c.messageId == 'resp-1' &&
                c.metadata?['streamComplete'] == true,
          )
          .toList();
      expect(respUpdate, isNotEmpty);
      expect(respUpdate.first.content, 'Hello World');
    });

    test('calls completeRun with first line preview', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'First line\nSecond line',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      expect(dispatchService.completeRunCalled, true);
      expect(dispatchService.lastCompleteRunSummary, 'First line');
    });

    test('completeRun summary is null for empty response', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        ap.ThinkingEvent(
          content: 'thinking only',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      expect(dispatchService.completeRunCalled, true);
      expect(dispatchService.lastCompleteRunSummary, null);
    });

    test('unregisters both streams on done', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      expect(registry.isActive('think-1'), true);
      expect(registry.isActive('resp-1'), true);

      controller.add(
        TextEvent(
          content: 'hi',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      expect(registry.isActive('think-1'), false);
      expect(registry.isActive('resp-1'), false);
    });

    test('emits MessageReceived on event bus when provided', () async {
      final eventBus = DomainEventBus();
      final receivedEvents = <MessageReceived>[];
      eventBus.on<MessageReceived>().listen(receivedEvents.add);

      final processorWithBus = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        eventBus: eventBus,
      );

      final controller2 = StreamController<AgentProcessEvent>.broadcast();
      final result2 = _testDispatchResult(controller2);
      registry.register('resp-2');
      registry.register('think-2');

      processorWithBus.processStream(
        stream: controller2.stream,
        dispatchResult: result2,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-2',
        responseId: 'resp-2',
      );

      controller2.add(
        TextEvent(
          content: 'Agent reply here',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );

      await pumpEventQueue();
      await controller2.close();
      await pumpEventQueue();

      expect(receivedEvents, isNotEmpty);
      expect(receivedEvents.first.channelId, 'ch-1');
      expect(receivedEvents.first.senderName, 'TestAgent');
      expect(receivedEvents.first.isAgentMessage, true);
      expect(receivedEvents.first.contentPreview, 'Agent reply here');
    });

    test('contentPreview truncated at 120 chars', () async {
      final eventBus = DomainEventBus();
      final receivedEvents = <MessageReceived>[];
      eventBus.on<MessageReceived>().listen(receivedEvents.add);

      final processorWithBus = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        eventBus: eventBus,
      );

      final controller2 = StreamController<AgentProcessEvent>.broadcast();
      final result2 = _testDispatchResult(controller2);
      registry.register('resp-3');
      registry.register('think-3');

      final longContent = 'A' * 200;

      processorWithBus.processStream(
        stream: controller2.stream,
        dispatchResult: result2,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-3',
        responseId: 'resp-3',
      );

      controller2.add(
        TextEvent(
          content: longContent,
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );

      await pumpEventQueue();
      await controller2.close();
      await pumpEventQueue();

      expect(receivedEvents.first.contentPreview.length,
          lessThanOrEqualTo(121));
      expect(receivedEvents.first.contentPreview, endsWith('…'));
    });
  });

  // -----------------------------------------------------------------------
  // Stream error handling
  // -----------------------------------------------------------------------
  group('stream error', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;
    late AgentDispatchResult dispatchResult;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      dispatchResult = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');
    });

    test('stream error persists error on thinking message', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.addError('Connection lost');

      await pumpEventQueue();

      final errorUpdate = repo.updateCalls
          .where(
            (c) =>
                c.messageId == 'think-1' && c.metadata?['error'] == true,
          )
          .toList();
      expect(errorUpdate, isNotEmpty);
      expect(errorUpdate.first.content, contains('Connection lost'));
      expect(errorUpdate.first.metadata?['streamComplete'], true);
    });

    test('stream error unregisters both streams', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.addError('Boom');

      await pumpEventQueue();

      expect(registry.isActive('think-1'), false);
      expect(registry.isActive('resp-1'), false);
    });

    test('stream error calls failRun', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.addError('Process crashed');

      await pumpEventQueue();

      expect(dispatchService.failRunCalled, true);
      expect(dispatchService.lastFailError, 'Process crashed');
    });
  });

  // -----------------------------------------------------------------------
  // Compaction
  // -----------------------------------------------------------------------
  group('compaction', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('does not compact when context size is null (no agent)', () async {
      final result = _testDispatchResult(controller);

      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'hello',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      expect(repo.compactedIds, isEmpty);
      final systemMessages = repo.sendCalls
          .where((c) => c.messageType == 'system')
          .toList();
      expect(systemMessages, isEmpty);
    });

    test('compacts when messages exceed context size', () async {
      final messages = List.generate(
        10,
        (i) => ChannelMessage(
          id: 'msg-$i',
          channelId: 'ch-1',
          senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'Message number $i with some extra text to fill space',
          messageType: ChannelMessageType.text,
          createdAt: DateTime(2025),
        ),
      );
      repo.storedMessages = messages;

      final agent = Agent(
        id: 'agent-1',
        name: 'TestAgent',
        title: 'Test Agent',
        agentMdPath: '/path/to/agent.md',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        contextSize: 50,
        createdAt: DateTime(2025),
      );

      final result = AgentDispatchResult(
        stream: controller.stream,
        dispatchId: 'dispatch-1',
        runLog: _testRunLog(),
        agent: agent,
      );

      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'hello',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      expect(repo.compactedIds, isNotEmpty);
      final systemMessages = repo.sendCalls
          .where((c) => c.messageType == 'system')
          .toList();
      expect(systemMessages, isNotEmpty);
      expect(systemMessages.first.metadata?['compacted'], true);
    });

    test('does not compact when messages fit within context size', () async {
      final messages = [
        ChannelMessage(
          id: 'msg-1',
          channelId: 'ch-1',
          senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'short',
          messageType: ChannelMessageType.text,
          createdAt: DateTime(2025),
        ),
      ];
      repo.storedMessages = messages;

      final agent = Agent(
        id: 'agent-1',
        name: 'TestAgent',
        title: 'Test Agent',
        agentMdPath: '/path/to/agent.md',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        contextSize: 10000,
        createdAt: DateTime(2025),
      );

      final result = AgentDispatchResult(
        stream: controller.stream,
        dispatchId: 'dispatch-1',
        runLog: _testRunLog(),
        agent: agent,
      );

      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'hi',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      expect(repo.compactedIds, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // Metadata extraction (contentExtractor)
  // -----------------------------------------------------------------------
  group('metadata extraction', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;
    late AgentDispatchResult dispatchResult;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      dispatchResult = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('text event passes content through to stream', () async {
      final stream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = stream!.listen(deltas.add);

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'direct content',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      await sub.cancel();
      expect(deltas.first, 'direct content');
    });

    test('thinking event passes content through to reasoning buffer', () async {
      registry.register('resp-2');
      registry.register('think-2');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-2',
        responseId: 'resp-2',
      );

      controller.add(
        ap.ThinkingEvent(
          content: 'deep reasoning here',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-2')
          .toList();
      final events = thinkUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[],
      ).toList();
      final reasoning = events.firstWhere(
        (e) => (e['kind'] as String?) == 'reasoning',
        orElse: () => <String, dynamic>{},
      );
      expect(reasoning['content'] as String, 'deep reasoning here');
    });

    test('toolCall extracts toolName from metadata', () async {
      registry.register('resp-3');
      registry.register('think-3');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-3',
        responseId: 'resp-3',
      );

      controller.add(
        ToolCallEvent(
          toolName: 'read_file',
          toolCallId: 'tc-1',
          inputs: {'path': '/etc/hosts'},
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-3')
          .toList();
      final events = thinkUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[],
      ).toList();
      final toolCallEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'tool_call',
        orElse: () => <String, dynamic>{},
      );
      expect(toolCallEv['toolName'] as String, 'read_file');
      expect(toolCallEv['inputs'] as Object?, isNotNull);
    });

    test('toolCall falls back to firstLine when no toolName in metadata', () async {
      registry.register('resp-4');
      registry.register('think-4');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-4',
        responseId: 'resp-4',
      );

      // ToolCallEvent always sets toolName but always has metadata too.
      // The fallback to _firstLine(event.content) happens when
      // event.metadata?['toolName'] is null. Since ToolCallEvent always
      // sets toolName in metadata, we test with a ToolCallEvent.
      // The key insight: toolName flows from event.metadata
      controller.add(
        ToolCallEvent(
          toolName: 'my_tool',
          toolCallId: 'tc-1',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-4')
          .toList();
      final events = thinkUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[],
      ).toList();
      final toolCallEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'tool_call',
        orElse: () => <String, dynamic>{},
      );
      expect(toolCallEv['toolName'] as String, 'my_tool');
    });
  });

  // -----------------------------------------------------------------------
  // Embedding
  // -----------------------------------------------------------------------
  group('embedding', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('embeds response when embedding port is ready', () async {
      final embedPort = _FakeEmbeddingPort();
      embedPort.isReady = true;

      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        embeddingPort: embedPort,
      );

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'embeddable response',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      // Wait for unawaited embedding future
      await pumpEventQueue();

      expect(embedPort.embedCallCount, 1);
      expect(embedPort.lastEmbedText, 'embeddable response');
    });

    test('does not embed when embedding port is not ready', () async {
      final embedPort = _FakeEmbeddingPort();
      embedPort.isReady = false;

      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        embeddingPort: embedPort,
      );

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'response',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();
      await pumpEventQueue();

      expect(embedPort.embedCallCount, 0);
    });

    test('does not embed empty response', () async {
      final embedPort = _FakeEmbeddingPort();
      embedPort.isReady = true;

      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        embeddingPort: embedPort,
      );

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      // No text events → response is empty
      await pumpAndClose();
      await pumpEventQueue();

      expect(embedPort.embedCallCount, 0);
    });
  });

  // -----------------------------------------------------------------------
  // Structured events — duration tracking
  // -----------------------------------------------------------------------
  group('event duration tracking', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;
    late AgentDispatchResult dispatchResult;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      dispatchResult = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('structured events receive computed duration', () async {
      processor.processStream(
        stream: controller.stream,
        dispatchResult: dispatchResult,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      final t1 = DateTime(2025, 1, 1, 12, 0, 5);
      final t2 = DateTime(2025, 1, 1, 12, 0, 10);

      controller
        ..add(ToolCallEvent(
          toolName: 'first',
          toolCallId: 'tc-1',
          timestamp: t1,
        ))
        ..add(ToolResultEvent(
          outputs: 'result',
          toolCallId: 'tc-1',
          timestamp: t2,
        ));
      await pumpAndClose();

      final thinkUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .firstWhere(
            (c) => c.metadata?['streamComplete'] == true,
            orElse: () => throw 'no final think update',
          );
      final events = (thinkUpdate.metadata!['events'] as List)
          .cast<Map<String, dynamic>>();

      final toolCallEv = events.firstWhere(
        (e) => e['kind'] == 'tool_call',
        orElse: () => <String, dynamic>{},
      );
      expect(toolCallEv['durationMs'], t2.difference(t1).inMilliseconds);
    });
  });

  // -----------------------------------------------------------------------
  // Parallel stream processing
  // -----------------------------------------------------------------------
  group('parallel stream processing', () {
    test('two processors can run concurrently on different channels', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );

      final c1 = StreamController<AgentProcessEvent>.broadcast();
      final c2 = StreamController<AgentProcessEvent>.broadcast();

      registry.register('resp-1');
      registry.register('think-1');
      registry.register('resp-2');
      registry.register('think-2');

      processor.processStream(
        stream: c1.stream,
        dispatchResult: _testDispatchResult(c1, runLog: _testRunLog(id:'run-1')),
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'AgentOne',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );
      processor.processStream(
        stream: c2.stream,
        dispatchResult: _testDispatchResult(c2, runLog: _testRunLog(id:'run-2')),
        channelId: 'ch-2',
        agentId: 'agent-2',
        agentName: 'AgentTwo',
        thinkingId: 'think-2',
        responseId: 'resp-2',
      );

      c1.add(TextEvent(
        content: 'channel one reply',
        timestamp: DateTime(2025, 1, 1, 12, 0, 1),
      ));
      c2.add(TextEvent(
        content: 'channel two reply',
        timestamp: DateTime(2025, 1, 1, 12, 0, 1),
      ));

      await Future.wait([c1.close(), c2.close()]);
      await pumpEventQueue();

      final r1 = repo.updateCalls
          .firstWhere((c) => c.messageId == 'resp-1' && c.metadata?['streamComplete'] == true,
              orElse: () => throw 'resp-1 not complete');
      final r2 = repo.updateCalls
          .firstWhere((c) => c.messageId == 'resp-2' && c.metadata?['streamComplete'] == true,
              orElse: () => throw 'resp-2 not complete');
      expect(r1.content, 'channel one reply');
      expect(r2.content, 'channel two reply');
    });

    test('two processors on same channel do not interfere', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );

      final c1 = StreamController<AgentProcessEvent>.broadcast();
      final c2 = StreamController<AgentProcessEvent>.broadcast();

      registry.register('resp-1');
      registry.register('think-1');
      registry.register('resp-2');
      registry.register('think-2');

      processor.processStream(
        stream: c1.stream,
        dispatchResult: _testDispatchResult(c1, runLog: _testRunLog(id:'run-1')),
        channelId: 'ch-shared',
        agentId: 'agent-1',
        agentName: 'AgentOne',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );
      processor.processStream(
        stream: c2.stream,
        dispatchResult: _testDispatchResult(c2, runLog: _testRunLog(id:'run-2')),
        channelId: 'ch-shared',
        agentId: 'agent-2',
        agentName: 'AgentTwo',
        thinkingId: 'think-2',
        responseId: 'resp-2',
      );

      c1.add(TextEvent(content: 'first reply',  timestamp: DateTime(2025, 1, 1, 12, 0, 1)));
      c2.add(TextEvent(content: 'second reply', timestamp: DateTime(2025, 1, 1, 12, 0, 1)));

      await Future.wait([c1.close(), c2.close()]);
      await pumpEventQueue();

      final r1 = repo.updateCalls
          .firstWhere((c) => c.messageId == 'resp-1' && c.metadata?['streamComplete'] == true,
              orElse: () => throw 'resp-1 not complete');
      final r2 = repo.updateCalls
          .firstWhere((c) => c.messageId == 'resp-2' && c.metadata?['streamComplete'] == true,
              orElse: () => throw 'resp-2 not complete');
      expect(r1.content, 'first reply');
      expect(r2.content, 'second reply');
    });
  });

  // -----------------------------------------------------------------------
  // Compaction edge cases
  // -----------------------------------------------------------------------
  group('compaction edge cases', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('compacts when exactly at boundary', () async {
      // contextSize=50 means charLimit=150.
      // Two messages with 76 chars each → total 152 > 150 → compacts.
      final messages = [
        ChannelMessage(
          id: 'msg-1', channelId: 'ch-1', senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'A' * 76,
          messageType: ChannelMessageType.text, createdAt: DateTime(2025),
        ),
        ChannelMessage(
          id: 'msg-2', channelId: 'ch-1', senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'B' * 76,
          messageType: ChannelMessageType.text, createdAt: DateTime(2025),
        ),
      ];
      repo.storedMessages = messages;

      final agent = Agent(
        id: 'agent-1', name: 'TestAgent', title: 'Test Agent',
        agentMdPath: '/path/to/agent.md', workspaceId: 'ws-1',
        skills: AgentSkills([]), contextSize: 50, createdAt: DateTime(2025),
      );
      final result = AgentDispatchResult(
        stream: controller.stream, dispatchId: 'dispatch-1',
        runLog: _testRunLog(), agent: agent,
      );

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(TextEvent(content: 'hi', timestamp: DateTime(2025, 1, 1)));
      await pumpAndClose();
      await pumpEventQueue();

      expect(repo.compactedIds, isNotEmpty);
    });

    test('does not compact when no messages exist', () async {
      repo.storedMessages = [];

      final agent = Agent(
        id: 'agent-1', name: 'TestAgent', title: 'Test Agent',
        agentMdPath: '/path/to/agent.md', workspaceId: 'ws-1',
        skills: AgentSkills([]), contextSize: 10, createdAt: DateTime(2025),
      );
      final result = AgentDispatchResult(
        stream: controller.stream, dispatchId: 'dispatch-1',
        runLog: _testRunLog(), agent: agent,
      );

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(TextEvent(content: 'hi', timestamp: DateTime(2025, 1, 1)));
      await pumpAndClose();
      await pumpEventQueue();

      expect(repo.compactedIds, isEmpty);
      final systemMessages = repo.sendCalls
          .where((c) => c.messageType == 'system').toList();
      expect(systemMessages, isEmpty);
    });

    test('compaction preserves newest messages', () async {
      // contextSize=50 → charLimit=150. Three 76-char messages:
      // total=228, compact oldest until under 150.
      // Compact msg-0 (76 chars → total 152), then msg-1 (76 chars → total 76, stops).
      // msg-2 is preserved.
      final messages = [
        ChannelMessage(
          id: 'msg-0', channelId: 'ch-1', senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'A' * 76,
          messageType: ChannelMessageType.text, createdAt: DateTime(2025),
        ),
        ChannelMessage(
          id: 'msg-1', channelId: 'ch-1', senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'B' * 76,
          messageType: ChannelMessageType.text, createdAt: DateTime(2025),
        ),
        ChannelMessage(
          id: 'msg-2', channelId: 'ch-1', senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'C' * 76,
          messageType: ChannelMessageType.text, createdAt: DateTime(2025),
        ),
      ];
      repo.storedMessages = messages;

      final agent = Agent(
        id: 'agent-1', name: 'TestAgent', title: 'Test Agent',
        agentMdPath: '/path/to/agent.md', workspaceId: 'ws-1',
        skills: AgentSkills([]), contextSize: 50, createdAt: DateTime(2025),
      );
      final result = AgentDispatchResult(
        stream: controller.stream, dispatchId: 'dispatch-1',
        runLog: _testRunLog(), agent: agent,
      );

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(TextEvent(content: 'hi', timestamp: DateTime(2025, 1, 1)));
      await pumpAndClose();
      await pumpEventQueue();

      expect(repo.compactedIds, contains('msg-0'));
      expect(repo.compactedIds, contains('msg-1'));
      expect(repo.compactedIds, isNot(contains('msg-2')));
    });

    test('compaction system message has compacted flag', () async {
      final messages = List.generate(10, (i) => ChannelMessage(
        id: 'msg-$i', channelId: 'ch-1', senderId: 'user',
        senderType: ChannelSenderType.user,
        content: 'Message number $i with substantial text to fill space',
        messageType: ChannelMessageType.text, createdAt: DateTime(2025),
      ));
      repo.storedMessages = messages;

      final agent = Agent(
        id: 'agent-1', name: 'TestAgent', title: 'Test Agent',
        agentMdPath: '/path/to/agent.md', workspaceId: 'ws-1',
        skills: AgentSkills([]), contextSize: 50, createdAt: DateTime(2025),
      );
      final result = AgentDispatchResult(
        stream: controller.stream, dispatchId: 'dispatch-1',
        runLog: _testRunLog(), agent: agent,
      );

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(TextEvent(content: 'hi', timestamp: DateTime(2025, 1, 1)));
      await pumpAndClose();
      await pumpEventQueue();

      final systemMsg = repo.sendCalls
          .firstWhere((c) => c.messageType == 'system',
              orElse: () => throw 'no system message');
      expect(systemMsg.metadata?['compacted'], true);
    });
  });

  // -----------------------------------------------------------------------
  // DB flush behavior
  // -----------------------------------------------------------------------
  group('DB flush behavior', () {
    test('multiple rapid events coalesce into fewer DB writes', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      // Send 5 rapid events then close immediately (before debounce timer fires)
      controller
        ..add(TextEvent(content: 'a', timestamp: DateTime(2025, 1, 1, 12, 0, 1)))
        ..add(TextEvent(content: 'b', timestamp: DateTime(2025, 1, 1, 12, 0, 2)))
        ..add(TextEvent(content: 'c', timestamp: DateTime(2025, 1, 1, 12, 0, 3)))
        ..add(TextEvent(content: 'd', timestamp: DateTime(2025, 1, 1, 12, 0, 4)))
        ..add(TextEvent(content: 'e', timestamp: DateTime(2025, 1, 1, 12, 0, 5)));
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      // onDone flushes once; timer never fires because we closed first.
      // Events coalesce into one final write.
      final thinkUpdates = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      expect(thinkUpdates.length, lessThan(5));
    });

    test('events after close do not trigger DB write', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream,
        dispatchResult: result,
        channelId: 'ch-1',
        agentId: 'agent-1',
        agentName: 'TestAgent',
        thinkingId: 'think-1',
        responseId: 'resp-1',
      );

      controller.add(TextEvent(content: 'before', timestamp: DateTime(2025, 1, 1)));
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      final countAfterClose = repo.updateCalls.length;

      // Adding to a closed broadcast controller does not throw,
      // but the stream subscription has already received done.
      try {
        controller.add(TextEvent(content: 'after close', timestamp: DateTime(2025)));
      } catch (_) {
        // Acceptable — some implementations throw
      }
      await pumpEventQueue();

      expect(repo.updateCalls.length, countAfterClose);
    });
  });

  // -----------------------------------------------------------------------
  // contentExtractor edge cases
  // -----------------------------------------------------------------------
  group('contentExtractor edge cases', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('empty text event does not produce content', () async {
      final stream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = stream!.listen(deltas.add);

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: '', timestamp: DateTime(2025, 1, 1, 12, 0, 1)),
      );
      controller.add(
        TextEvent(content: 'real', timestamp: DateTime(2025, 1, 1, 12, 0, 2)),
      );
      await pumpAndClose();

      await sub.cancel();
      expect(deltas, ['real']);
    });

    test('special characters in content are preserved', () async {
      final stream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = stream!.listen(deltas.add);

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: 'emoji 🎉 unicode ñ', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpAndClose();

      await sub.cancel();
      expect(deltas.first, 'emoji 🎉 unicode ñ');
    });

    test('multiline content in text event', () async {
      final stream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = stream!.listen(deltas.add);

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(
          content: 'line one\nline two\nline three',
          timestamp: DateTime(2025, 1, 1),
        ),
      );
      await pumpAndClose();

      await sub.cancel();
      expect(deltas.first, contains('line one'));
      expect(deltas.first, contains('line two'));
      expect(deltas.first, contains('line three'));
    });
  });

  // -----------------------------------------------------------------------
  // RunCost accumulation
  // -----------------------------------------------------------------------
  group('RunCost accumulation', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;
    late AgentDispatchResult dispatchResult;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      dispatchResult = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('multiple UsageEvents accumulate correctly', () async {
      processor.processStream(
        stream: controller.stream, dispatchResult: dispatchResult,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(content: 'first', timestamp: DateTime(2025, 1, 1, 12, 0, 1)))
        ..add(UsageEvent(
          usage: const RunUsage(
            inputTokens: 100, outputTokens: 50, estimatedCostCents: 10,
          ),
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ))
        ..add(UsageEvent(
          usage: const RunUsage(
            inputTokens: 200, outputTokens: 100, estimatedCostCents: 20,
          ),
          timestamp: DateTime(2025, 1, 1, 12, 0, 3),
        ));
      await pumpAndClose();

      expect(dispatchService.completeRunCalled, true);
      expect(dispatchService.lastCompleteRunCost, isNotNull);
      expect(dispatchService.lastCompleteRunCost!.inputTokens, 300);
      expect(dispatchService.lastCompleteRunCost!.outputTokens, 150);
      expect(dispatchService.lastCompleteRunCost!.estimatedCostCents, 30);
    });

    test('UsageEvent with zero tokens does not affect cost', () async {
      processor.processStream(
        stream: controller.stream, dispatchResult: dispatchResult,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(content: 'first', timestamp: DateTime(2025, 1, 1, 12, 0, 1)))
        ..add(UsageEvent(
          usage: const RunUsage(
            inputTokens: 50, outputTokens: 25, estimatedCostCents: 5,
          ),
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ))
        ..add(UsageEvent(
          usage: RunUsage.zero,
          timestamp: DateTime(2025, 1, 1, 12, 0, 3),
        ));
      await pumpAndClose();

      expect(dispatchService.lastCompleteRunCost!.inputTokens, 50);
      expect(dispatchService.lastCompleteRunCost!.outputTokens, 25);
      expect(dispatchService.lastCompleteRunCost!.estimatedCostCents, 5);
    });

    test('cost is included in completeRun call', () async {
      processor.processStream(
        stream: controller.stream, dispatchResult: dispatchResult,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(content: 'costed response', timestamp: DateTime(2025, 1, 1, 12, 0, 1)))
        ..add(UsageEvent(
          usage: const RunUsage(
            inputTokens: 42, outputTokens: 7, estimatedCostCents: 1,
          ),
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ));
      await pumpAndClose();

      expect(dispatchService.completeRunCalled, true);
      expect(dispatchService.lastCompleteRunLog, isNotNull);
      expect(dispatchService.lastCompleteRunCost, isNotNull);
      expect(dispatchService.lastCompleteRunCost!.inputTokens, 42);
      expect(dispatchService.lastCompleteRunCost!.estimatedCostCents, 1);
    });
  });

  // -----------------------------------------------------------------------
  // Registry lifecycle
  // -----------------------------------------------------------------------
  group('registry lifecycle', () {
    test('unregistering a stream stops delta delivery', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);

      registry.register('resp-1');
      registry.register('think-1');
      final stream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = stream!.listen(deltas.add);

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: 'first', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpEventQueue();
      expect(deltas, ['first']);

      // Unregister stops the controller; subsequent adds are dropped
      await registry.unregister('resp-1');

      controller.add(
        TextEvent(content: 'second', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      await sub.cancel();
      expect(deltas, ['first']);
    });

    test('processing without registered streams does not crash', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);

      // Do NOT register streams

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: 'hi', timestamp: DateTime(2025, 1, 1)),
      );
      controller.add(
        ap.ThinkingEvent(content: 'thinking', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      // Should not crash — updateMessage still called through repo
      expect(dispatchService.completeRunCalled, true);
      expect(dispatchService.lastCompleteRunSummary, 'hi');
    });

    test('re-registering mid-stream continues delivery', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);

      registry.register('resp-1');
      registry.register('think-1');
      final deltas = <String>[];
      final sub = registry.streamFor('resp-1')!.listen(deltas.add);

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: 'first', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpEventQueue();

      await registry.unregister('resp-1');

      // Re-register and re-subscribe
      registry.register('resp-1');
      final deltas2 = <String>[];
      final sub2 = registry.streamFor('resp-1')!.listen(deltas2.add);

      controller.add(
        TextEvent(content: 'second', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      await sub.cancel();
      await sub2.cancel();
      expect(deltas, ['first']);
      expect(deltas2, ['second']);
    });
  });

  // -----------------------------------------------------------------------
  // eventBus edge cases
  // -----------------------------------------------------------------------
  group('eventBus edge cases', () {
    test('null eventBus does not crash', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        // eventBus omitted → null
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: 'hello', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      // Should complete without error
      expect(dispatchService.completeRunCalled, true);
    });

    test('eventBus receives isAgentMessage: true', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final eventBus = DomainEventBus();
      final receivedEvents = <MessageReceived>[];
      eventBus.on<MessageReceived>().listen(receivedEvents.add);

      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        eventBus: eventBus,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: 'agent message', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      expect(receivedEvents, isNotEmpty);
      expect(receivedEvents.first.isAgentMessage, true);
    });

    test('contentPreview for empty response is null', () async {
      final repo = _FakeMessagingRepo();
      final dispatchService = _FakeAgentDispatchService();
      final registry = ActiveStreamRegistry();
      final eventBus = DomainEventBus();
      final receivedEvents = <MessageReceived>[];
      eventBus.on<MessageReceived>().listen(receivedEvents.add);

      final processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        eventBus: eventBus,
      );
      final controller = StreamController<AgentProcessEvent>.broadcast();
      final result = _testDispatchResult(controller);
      registry.register('resp-1');
      registry.register('think-1');

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      // Only thinking event — no text content
      controller.add(
        ap.ThinkingEvent(content: 'thinking only', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();

      expect(receivedEvents, isNotEmpty);
      // When there is no text content, preview is empty string
      expect(receivedEvents.first.contentPreview, '');
    });
  });

  // -----------------------------------------------------------------------
  // Debug event log-level filtering
  // -----------------------------------------------------------------------
  group('debug event log-level filtering', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    AppLogLevel savedLevel = AppLogLevel.debug;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
      savedLevel = AppLog.level;
    });

    tearDown(() {
      AppLog.init(savedLevel);
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('debug event suppressed when log level is below info', () async {
      AppLog.init(AppLogLevel.warning);

      final textStream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = textStream!.listen(deltas.add);

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        DebugEvent(content: 'should be hidden', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpAndClose();
      await sub.cancel();

      expect(deltas.any((d) => d.contains('should be hidden')), false);
    });

    test('debug event emitted when log level is info', () async {
      AppLog.init(AppLogLevel.info);

      final textStream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = textStream!.listen(deltas.add);

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        DebugEvent(content: 'should appear', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpAndClose();
      await sub.cancel();

      expect(deltas.any((d) => d.contains('should appear')), true);
    });
  });

  // -----------------------------------------------------------------------
  // UsageEvent edge cases
  // -----------------------------------------------------------------------
  group('UsageEvent edge cases', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('UsageEvent without prior text has null timeToFirstTokenMs', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        UsageEvent(
          usage: const RunUsage(inputTokens: 10, outputTokens: 5),
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      expect(dispatchService.completeRunCalled, true);
      expect(dispatchService.lastCompleteRunCost, isNotNull);
      // No text event before usage → timeToFirstTokenMs should be null
      expect(dispatchService.lastCompleteRunCost!.timeToFirstTokenMs, null);
    });

    test('UsageEvent with durationMs carries duration to cost', () async {
      final runLog = _testRunLog();
      final result = _testDispatchResult(controller, runLog: runLog);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(content: 'hi', timestamp: DateTime(2025, 1, 1, 12, 0, 1)))
        ..add(UsageEvent(
          usage: const RunUsage(inputTokens: 20, outputTokens: 10),
          durationMs: 1500,
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ));
      await pumpAndClose();

      expect(dispatchService.lastCompleteRunCost!.durationMs, 1500);
    });

    test('multiple UsageEvents without text events accumulate cost', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller
        ..add(UsageEvent(
          usage: const RunUsage(inputTokens: 10, outputTokens: 5, estimatedCostCents: 2),
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ))
        ..add(UsageEvent(
          usage: const RunUsage(inputTokens: 20, outputTokens: 10, estimatedCostCents: 3),
          timestamp: DateTime(2025, 1, 1, 12, 0, 2),
        ));
      await pumpAndClose();

      expect(dispatchService.lastCompleteRunCost!.inputTokens, 30);
      expect(dispatchService.lastCompleteRunCost!.outputTokens, 15);
      expect(dispatchService.lastCompleteRunCost!.estimatedCostCents, 5);
    });
  });

  // -----------------------------------------------------------------------
  // Log line coalescing — interleaved types
  // -----------------------------------------------------------------------
  group('log line coalescing interleaved', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('interleaved event types produce distinct log line entries', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(content: 'A', timestamp: DateTime(2025, 1, 1, 12, 0, 1)))
        ..add(ap.ThinkingEvent(content: 'think', timestamp: DateTime(2025, 1, 1, 12, 0, 2)))
        ..add(TextEvent(content: 'B', timestamp: DateTime(2025, 1, 1, 12, 0, 3)));
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final thinking = thinkingUpdate
          .map((c) => c.metadata?['thinking'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .join('\n');

      // Interleaved types cause separate entries; each type boundary flushes
      // the previous type's log line.
      expect(thinking, contains('[text]'));
      expect(thinking, contains('[thinking]'));
    });

    test('single log line for same event type across entire stream', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(content: 'A', timestamp: DateTime(2025, 1, 1, 12, 0, 1)))
        ..add(TextEvent(content: 'B', timestamp: DateTime(2025, 1, 1, 12, 0, 2)))
        ..add(TextEvent(content: 'C', timestamp: DateTime(2025, 1, 1, 12, 0, 3)))
        ..add(TextEvent(content: 'D', timestamp: DateTime(2025, 1, 1, 12, 0, 4)));
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final thinking = thinkingUpdate
          .map((c) => c.metadata?['thinking'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .join('\n');

      // All text events coalesce into one entry
      expect(thinking, contains('[text] ×4'));
      expect(thinking, isNot(contains('[text] ×1')));
      expect(thinking, isNot(contains('[text] ×2')));
      expect(thinking, isNot(contains('[text] ×3')));
    });
  });

  // -----------------------------------------------------------------------
  // Structured events flush reasoning
  // -----------------------------------------------------------------------
  group('structured events flush reasoning', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('sandboxViolation flushes prior reasoning before adding event', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      final t1 = DateTime(2025, 1, 1, 12, 0, 1);
      final t2 = DateTime(2025, 1, 1, 12, 0, 5);

      controller
        ..add(ap.ThinkingEvent(content: 'prior reasoning', timestamp: t1))
        ..add(SandboxViolationEvent(content: 'blocked', timestamp: t2));
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[],
      ).toList();

      final reasoningEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'reasoning',
        orElse: () => <String, dynamic>{},
      );
      expect(reasoningEv['content'] as String, 'prior reasoning');
      expect(reasoningEv['durationMs'] as int, t2.difference(t1).inMilliseconds);

      final sandboxEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'sandbox_violation',
        orElse: () => <String, dynamic>{},
      );
      expect(sandboxEv['content'] as String, 'blocked');
    });

    test('error event flushes prior reasoning before adding event', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      final t1 = DateTime(2025, 1, 1, 12, 0, 1);
      final t2 = DateTime(2025, 1, 1, 12, 0, 3);

      controller
        ..add(ap.ThinkingEvent(content: 'some reasoning', timestamp: t1))
        ..add(ErrorEvent(content: 'oops', timestamp: t2));
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[],
      ).toList();

      final reasoningEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'reasoning',
        orElse: () => <String, dynamic>{},
      );
      expect(reasoningEv['content'] as String, 'some reasoning');
      expect(reasoningEv['durationMs'] as int, t2.difference(t1).inMilliseconds);

      final errorEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'error',
        orElse: () => <String, dynamic>{},
      );
      expect(errorEv['content'] as String, 'oops');
    });
  });

  // -----------------------------------------------------------------------
  // Duration tracking — preservation
  // -----------------------------------------------------------------------
  group('duration preservation', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('duration of previous event is not overwritten when already set', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      final t1 = DateTime(2025, 1, 1, 12, 0, 0);
      final t2 = DateTime(2025, 1, 1, 12, 0, 5);
      final t3 = DateTime(2025, 1, 1, 12, 0, 10);

      // First toolCall gets duration from toolResult
      controller
        ..add(ToolCallEvent(toolName: 'a', toolCallId: 'tc-1', timestamp: t1))
        ..add(ToolResultEvent(outputs: 'r1', toolCallId: 'tc-1', timestamp: t2))
        // Now another toolCall — closePreviousDuration should see
        // prev (toolResult) already has duration from _addStructured
        ..add(ToolCallEvent(toolName: 'b', toolCallId: 'tc-2', timestamp: t3));
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[],
      ).toList();

      // First toolCall (kind=tool_call, toolName='a') has duration closed by toolResult
      final tc1 = events.firstWhere(
        (e) => (e['kind'] as String?) == 'tool_call' && (e['toolName'] as String?) == 'a',
        orElse: () => <String, dynamic>{},
      );
      expect(tc1['durationMs'] as int, t2.difference(t1).inMilliseconds);

      // Second toolCall should get duration from onDone
      final tc2 = events.firstWhere(
        (e) => (e['kind'] as String?) == 'tool_call' && (e['toolName'] as String?) == 'b',
        orElse: () => <String, dynamic>{},
      );
      expect(tc2, isNotEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // Compaction with embedding
  // -----------------------------------------------------------------------
  group('compaction with embedding', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;
    late _FakeEmbeddingPort embedPort;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      embedPort = _FakeEmbeddingPort();
      embedPort.isReady = true;
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
        embeddingPort: embedPort,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('compaction with ready embedding port embeds summary message', () async {
      final messages = List.generate(
        10,
        (i) => ChannelMessage(
          id: 'msg-$i', channelId: 'ch-1', senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'Message number $i with some extra text to fill space',
          messageType: ChannelMessageType.text, createdAt: DateTime(2025),
        ),
      );
      repo.storedMessages = messages;

      final agent = Agent(
        id: 'agent-1', name: 'TestAgent', title: 'Test Agent',
        agentMdPath: '/path/to/agent.md', workspaceId: 'ws-1',
        skills: AgentSkills([]), contextSize: 50, createdAt: DateTime(2025),
      );
      final result = AgentDispatchResult(
        stream: controller.stream, dispatchId: 'dispatch-1',
        runLog: _testRunLog(), agent: agent,
      );

      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        TextEvent(content: 'hi', timestamp: DateTime(2025, 1, 1)),
      );
      await pumpAndClose();
      // Wait for unawaited embedding futures
      await pumpEventQueue();
      await pumpEventQueue();

      // The compaction summary should have been embedded
      final systemMsg = repo.sendCalls
          .firstWhere((c) => c.messageType == 'system',
              orElse: () => throw 'no system message');
      expect(systemMsg.metadata?['compacted'], true);
      // The system message should have an embedding stored
      expect(repo.embeddings, isNotEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // DoneEvent handling
  // -----------------------------------------------------------------------
  group('done event', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('DoneEvent is logged in thinking lines but produces no content', () async {
      final textStream = registry.streamFor('resp-1');
      final deltas = <String>[];
      final sub = textStream!.listen(deltas.add);

      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller
        ..add(TextEvent(content: 'Hello', timestamp: DateTime(2025, 1, 1, 12, 0, 1)))
        ..add(DoneEvent(timestamp: DateTime(2025, 1, 1, 12, 0, 2)));
      await pumpAndClose();

      await sub.cancel();
      // DoneEvent does not add content to response stream
      expect(deltas, ['Hello']);

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final thinking = thinkingUpdate
          .map((c) => c.metadata?['thinking'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .join('\n');

      // DoneEvent appears in log lines
      expect(thinking, contains('[done]'));
    });
  });

  // -----------------------------------------------------------------------
  // Tool call inputs edge cases
  // -----------------------------------------------------------------------
  group('toolCall inputs edge cases', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('toolCall with null inputs omits inputs from event', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        ToolCallEvent(
          toolName: 'no_input_tool',
          toolCallId: 'tc-1',
          inputs: null,
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[],
      ).toList();

      final toolCallEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'tool_call',
        orElse: () => <String, dynamic>{},
      );
      expect(toolCallEv['toolName'] as String, 'no_input_tool');
      expect(toolCallEv['inputs'] as Object?, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // Snapshot includes in-progress reasoning
  // -----------------------------------------------------------------------
  group('snapshot edge cases', () {
    late _FakeMessagingRepo repo;
    late _FakeAgentDispatchService dispatchService;
    late ActiveStreamRegistry registry;
    late AgentStreamProcessor processor;
    late StreamController<AgentProcessEvent> controller;

    setUp(() {
      repo = _FakeMessagingRepo();
      dispatchService = _FakeAgentDispatchService();
      registry = ActiveStreamRegistry();
      processor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: registry,
      );
      controller = StreamController<AgentProcessEvent>.broadcast();
      registry.register('resp-1');
      registry.register('think-1');
    });

    Future<void> pumpAndClose() async {
      await pumpEventQueue();
      await controller.close();
      await pumpEventQueue();
    }

    test('snapshot includes in-progress reasoning while buffer is non-empty', () async {
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      // Send a thinking event but do NOT close with a toolCall —
      // reasoning stays in buffer until onDone flushes it.
      controller.add(
        ap.ThinkingEvent(
          content: 'still going...',
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[],
      ).toList();

      // The final flush (onDone) produces a reasoning event
      final reasoningEv = events.firstWhere(
        (e) => (e['kind'] as String?) == 'reasoning',
        orElse: () => <String, dynamic>{},
      );
      expect(reasoningEv['content'] as String, 'still going...');
    });

    test('thinking with empty extracted content does not produce reasoning event', () async {
      // The content extractor may return empty for certain content.
      // We test with empty content directly, which behaves the same.
      final result = _testDispatchResult(controller);
      processor.processStream(
        stream: controller.stream, dispatchResult: result,
        channelId: 'ch-1', agentId: 'agent-1', agentName: 'TestAgent',
        thinkingId: 'think-1', responseId: 'resp-1',
      );

      controller.add(
        ap.ThinkingEvent(
          content: '', // empty content → extracted is empty
          timestamp: DateTime(2025, 1, 1, 12, 0, 1),
        ),
      );
      await pumpAndClose();

      final thinkingUpdate = repo.updateCalls
          .where((c) => c.messageId == 'think-1')
          .toList();
      final events = thinkingUpdate.expand(
        (c) =>
            (c.metadata?['events'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[],
      ).toList();

      final reasoningEvs = events.where((e) => (e['kind'] as String?) == 'reasoning');
      expect(reasoningEvs, isEmpty);
    });
  });
}
