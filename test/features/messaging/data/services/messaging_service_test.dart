import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:cc_infra/src/messaging/messaging_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeMessagingRepo implements MessagingRepository {
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
      watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
          Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  final _channels = <Channel>[];
  final _participants = <String, List<ChannelParticipant>>{};
  final _messages = <String, List<ChannelMessage>>{};
  final _compacted = <String>{};
  final _embeddings = <String, Uint8List>{};
  String? _lastUpdatedName;

  ChannelParticipant _makeParticipant(String channelId, String agentId) =>
      ChannelParticipant(
        id: 'p-$agentId',
        channelId: channelId,
        agentId: agentId,
        role: 'member',
        joinedAt: DateTime.now(),
      );

  @override
  Stream<List<Channel>> watchChannels() =>
      Stream.value(List.unmodifiable(_channels));

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value(List.unmodifiable(
        _channels.where((c) => c.workspaceId == workspaceId).toList(),
      ));

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      Stream.value(List.unmodifiable(_participants[channelId] ?? []));

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      Stream.value(List.unmodifiable(_messages[channelId] ?? []));

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async {
    final channel = Channel(
      id: 'dm-$agentId',
      name: '',
      isDm: true,
      workspaceId: workspaceId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _channels.add(channel);
    _participants[channel.id] = [_makeParticipant(channel.id, agentId)];
    return channel;
  }

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  String? pipelineRunId,
    }) async {
    final channel = Channel(
      id: 'group-${name.hashCode}',
      name: name,
      isDm: false,
      workspaceId: workspaceId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      mode: mode,
    );
    _channels.add(channel);
    _participants[channel.id] =
        agentIds.map((id) => _makeParticipant(channel.id, id)).toList();
    return channel;
  }

  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) async {
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _channels[idx] = _channels[idx].copyWith(mode: mode);
    }
  }

  @override
  Future<void> addParticipant(String channelId, String agentId) async {
    _participants.putIfAbsent(channelId, () => []);
    _participants[channelId]!.add(_makeParticipant(channelId, agentId));
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async =>
      List.unmodifiable(_participants[channelId] ?? []);

  @override
  Future<bool> channelExists(String channelId) async => true;

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
    _messages.putIfAbsent(channelId, () => []);
    final msg = ChannelMessage(
      id: id ?? 'msg-${_messages[channelId]!.length}',
      channelId: channelId,
      senderId: senderId,
      senderType:
          senderType == 'user' ? ChannelSenderType.user : ChannelSenderType.agent,
      content: content,
      messageType: messageType == 'system'
          ? ChannelMessageType.system
          : messageType == 'ticket_card'
              ? ChannelMessageType.ticketCard
              : messageType == 'agent_turn'
                  ? ChannelMessageType.agentTurn
                  : messageType == 'plan'
                      ? ChannelMessageType.plan
                      : ChannelMessageType.text,
      metadata: metadata,
      parentMessageId: parentMessageId,
      createdAt: DateTime.now(),
    );
    _messages[channelId]!.add(msg);
    return msg.id;
  }

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {
    for (final msgs in _messages.values) {
      final idx = msgs.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        msgs[idx] = msgs[idx].copyWith(
          content: content,
          metadata: metadata,
        );
        return;
      }
    }
  }

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async =>
      List.unmodifiable(_messages[channelId] ?? []);

  @override
  Future<void> markCompacted(List<String> ids) async {
    _compacted.addAll(ids);
  }

  @override
  Future<void> deleteChannel(String channelId) async {
    _channels.removeWhere((c) => c.id == channelId);
    _messages.remove(channelId);
    _participants.remove(channelId);
  }

  Future<void> updateChannelType(String channelId, String type) async {}

  @override
  Future<void> updateChannelName(String channelId, String name) async {
    _lastUpdatedName = name;
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _channels[idx] = _channels[idx].copyWith(name: name);
    }
  }

  String? get lastUpdatedName => _lastUpdatedName;

  @override
  Future<void> clearChannelMessages(String channelId) async {
    _messages[channelId]?.clear();
  }

  @override
  Future<void> removeParticipant(String channelId, String agentId) async {
    _participants[channelId]?.removeWhere((p) => p.agentId == agentId);
  }

  @override
  Future<void> updateMessageEmbedding(
    String messageId,
    Uint8List embedding,
  ) async {
    _embeddings[messageId] = embedding;
  }

  Uint8List? embeddingFor(String messageId) => _embeddings[messageId];

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

  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      const Stream.empty();

  @override
  Future<ChannelMessage?> getMessageById(String messageId) => Future.value(null);
}

class _FakeAgentDispatchPort implements AgentDispatchPort {
  final StreamController<AgentProcessEvent> _controller =
      StreamController<AgentProcessEvent>.broadcast();
  Stream<AgentProcessEvent> get events => _controller.stream;

  void emitEvent(AgentProcessEvent event) => _controller.add(event);
  void emitError(Object error) => _controller.addError(error);

  @override
  DispatchHandle start({
    required String cliName,
    required String prompt,
    required String workingDirectory,
    String? modelId,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? runLogId,
    String? ticketId,
    WakeContext? wakeContext,
    ConversationMode? mode,
    int? silenceTimeoutMinutes,
    Map<String, String>? environment,
    List<String>? imagePaths,
    String? effortLevel,
    List<String>? adapterArgsOverride,
    Map<String, String>? adapterEnvOverride,
  }) =>
      DispatchHandle(dispatchId: 'ds-1', events: _controller.stream);

  @override
  Future<void> stopDispatch(String dispatchId) async => _controller.close();

  @override
  Future<void> stopAllForAgent(String agentId) async => _controller.close();

  @override
  Future<void> stop() async => _controller.close();
}

class _FakeRunLogRepo extends Fake implements AgentRunLogRepository {
  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => const [];

  AgentRunLog? _runLog;
  var _upsertCount = 0;

  @override
  Future<void> upsert(AgentRunLog runLog) async {
    _runLog = runLog;
    _upsertCount++;
  }

  @override
  Future<AgentRunLog?> getById(String id) async => _runLog;
}

class _FakeDispatchAgentUseCase extends Fake implements DispatchAgentUseCase {
  @override
  Future<PreparedDispatch> execute({
    required String agentId,
    required String prompt,
    String? workspaceId,
    String? channelId,
    String? conversationId,
    String? adapterId,
    String? workingDirectory,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    return PreparedDispatch(
      effectivePrompt: prompt,
      effectiveConversationId: conversationId ?? channelId,
      agent: null,
      mode: ConversationMode.chat,
      resolvedAdapterId: null,
      cliName: 'pi',
    );
  }
}

/// [FakeAgentRepository] wrapper that replays current state on [watchAll] and
/// [watchByWorkspace] so `.first` completes immediately.
class _ReplayAgentRepo extends FakeAgentRepository {
  void clear() {
    for (final a in List.of(saved)) {
      delete(a.id);
    }
  }

  @override
  Stream<List<Agent>> watchAll() => Stream.value(saved);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(saved.where((a) => a.workspaceId == workspaceId).toList());
}

class _FakeEmbeddingPort implements EmbeddingPort {
  var _ready = false;
  final _dimension = 384;
  final _embedCalls = <String>[];

  @override
  bool get isReady => _ready;

  @override
  int get dimension => _dimension;

  @override
  Future<Float32List> embed(String text) async {
    _embedCalls.add(text);
    return Float32List(_dimension);
  }

  List<String> get embedCalls => List.unmodifiable(_embedCalls);
}

Agent _testAgent({
  required String id,
  required String name,
  String workspaceId = 'ws-1',
  String agentMdPath = '/agents/test/agent.md',
}) =>
    Agent(
      id: id,
      name: name,
      title: 'Test $name',
      agentMdPath: agentMdPath,
      workspaceId: workspaceId,
      skills: AgentSkills([]),
      createdAt: DateTime.now(),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeMessagingRepo repo;
  late _FakeAgentDispatchPort dispatchPort;
  late AgentDispatchService dispatchService;
  late _FakeRunLogRepo runLogRepo;
  late ActiveStreamRegistry streamRegistry;
  late MessagingService service;

  AgentStreamProcessor makeStreamProcessor() => AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: streamRegistry,
      );

  setUp(() {
    repo = _FakeMessagingRepo();
    dispatchPort = _FakeAgentDispatchPort();
    runLogRepo = _FakeRunLogRepo();
    streamRegistry = ActiveStreamRegistry();
    dispatchService = AgentDispatchService(
      agentDispatch: dispatchPort,
      dispatchUseCase: _FakeDispatchAgentUseCase(),
      runLogRepo: runLogRepo,
    );
    service = MessagingService(
      repo,
      agentDispatchService: dispatchService,
      streamRegistry: streamRegistry,
      streamProcessor: makeStreamProcessor(),
    );
  });

  tearDown(() async {
    await dispatchPort.stop();
  });

  group('openDm', () {
    test('creates a DM channel', () async {
      final channel = await service.openDm('agent-1');
      expect(channel.isDm, true);
      expect(channel.id, contains('agent-1'));
    });
  });

  group('createGroup', () {
    test('creates a group channel', () async {
      final channel =
          await service.createGroup('My Team', ['agent-1', 'agent-2']);
      expect(channel.isDm, false);
      expect(channel.name, 'My Team');
    });
  });

  group('sendUserMessage', () {
    test('sends a user message to channel', () async {
      final channel = await service.openDm('agent-1');
      await service.sendUserMessage(channel.id, 'Hello!');
      final msgs = await repo.getMessages(channel.id);
      expect(msgs.length, 1);
      expect(msgs[0].content, 'Hello!');
      expect(msgs[0].isUser, isTrue);
    });

    test('publishes MessageReceived event when eventBus is wired', () async {
      final eventBus = DomainEventBus();
      final events = <MessageReceived>[];
      eventBus.on<MessageReceived>().listen(events.add);

      final svc = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        eventBus: eventBus,
      );
      final channel = await service.openDm('agent-1');
      await svc.sendUserMessage(channel.id, 'Event test');
      // DomainEventBus delivers asynchronously (broadcast stream).
      await pumpEventQueue();

      expect(events.length, 1);
      expect(events[0].channelId, channel.id);
      expect(events[0].contentPreview, 'Event test');
      expect(events[0].isAgentMessage, false);
      eventBus.dispose();
    });
    test('truncates long content in event preview', () async {
      final eventBus = DomainEventBus();
      final events = <MessageReceived>[];
      eventBus.on<MessageReceived>().listen(events.add);

      final svc = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        eventBus: eventBus,
      );
      final channel = await service.openDm('agent-1');
      final longContent = 'x' * 200;
      await svc.sendUserMessage(channel.id, longContent);
      await pumpEventQueue();

      expect(events.length, 1);
      expect(events[0].contentPreview.length, 121);
      expect(events[0].contentPreview.endsWith('\u2026'), isTrue);
      eventBus.dispose();
    });

    test('embeds message when embeddingPort is ready', () async {
      final embedPort = _FakeEmbeddingPort();
      embedPort._ready = true;

      final svc = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        embeddingPort: embedPort,
      );
      final channel = await service.openDm('agent-1');
      await svc.sendUserMessage(channel.id, 'Embed me');
      // Pump the microtask queue so the unawaited embed future completes.
      await pumpEventQueue();

      expect(embedPort.embedCalls, contains('Embed me'));
    });

    test('does not embed when embeddingPort is not ready', () async {
      final embedPort = _FakeEmbeddingPort();
      // _ready is false by default

      final svc = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        embeddingPort: embedPort,
      );
      final channel = await service.openDm('agent-1');
      await svc.sendUserMessage(channel.id, 'No embed');
      await pumpEventQueue();

      expect(embedPort.embedCalls, isEmpty);
    });

    test('does not embed empty content', () async {
      final embedPort = _FakeEmbeddingPort();
      embedPort._ready = true;

      final svc = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        embeddingPort: embedPort,
      );
      final channel = await service.openDm('agent-1');
      await svc.sendUserMessage(channel.id, '');
      await pumpEventQueue();

      expect(embedPort.embedCalls, isEmpty);
    });
  });

  group('addAgentToChannel', () {
    test('adds agent and sends system message', () async {
      final channel = await service.openDm('agent-1');
      await service.addAgentToChannel(channel.id, 'agent-2');
      final participants = await repo.getParticipants(channel.id);
      expect(participants.any((p) => p.agentId == 'agent-2'), isTrue);
    });

    test('does not add duplicate agent', () async {
      final channel = await service.openDm('agent-1');
      final initialCount = (await repo.getParticipants(channel.id)).length;
      await service.addAgentToChannel(channel.id, 'agent-1');
      final participants = await repo.getParticipants(channel.id);
      expect(participants.length, initialCount);
    });

    test('renames DM channel when third participant joins', () async {
      final agentRepo = FakeAgentRepository();
      unawaited(agentRepo.upsert(_testAgent(id: 'agent-1', name: 'Alice')));
      unawaited(agentRepo.upsert(_testAgent(id: 'agent-2', name: 'Bob')));

      final svc = MessagingService(
        repo,
        agentRepo: agentRepo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
      );
      final channel = await svc.openDm('agent-1');
      // Add second agent (1→2 participants, no rename).
      await svc.addAgentToChannel(channel.id, 'agent-tmp');
      // Add third agent (2→3 participants, triggers DM→group rename).
      await svc.addAgentToChannel(channel.id, 'agent-2');

      expect(repo.lastUpdatedName, 'Alice, Bob');
      agentRepo.dispose();
    });
  });

  group('deleteChannel', () {
    test('deletes a channel', () async {
      final channel = await service.openDm('agent-1');
      await service.deleteChannel(channel.id);
      final participants = await repo.getParticipants(channel.id);
      expect(participants, isEmpty);
    });

    test('publishes ConversationDeleted event when eventBus is wired', () async {
      final eventBus = DomainEventBus();
      final events = <ConversationDeleted>[];
      eventBus.on<ConversationDeleted>().listen(events.add);

      final svc = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        eventBus: eventBus,
      );
      final channel = await service.openDm('agent-1');
      await svc.deleteChannel(channel.id);
      await pumpEventQueue();
      expect(events.length, 1);
      expect(events[0].channelId, channel.id);
      eventBus.dispose();
    });
  });

  group('updateChannelName', () {
    test('completes without error', () async {
      final channel = await service.createGroup('Old', ['a1']);
      await service.updateChannelName(channel.id, 'New Name');
    });
  });

  group('clearChannelMessages', () {
    test('clears all messages in channel', () async {
      final channel = await service.openDm('agent-1');
      await service.sendUserMessage(channel.id, 'msg1');
      await service.sendUserMessage(channel.id, 'msg2');
      await service.clearChannelMessages(channel.id);
      final msgs = await repo.getMessages(channel.id);
      expect(msgs, isEmpty);
    });
  });

  group('removeParticipant', () {
    test('removes an agent from channel', () async {
      final channel = await service.createGroup('Team', ['a1', 'a2']);
      await service.removeParticipant(channel.id, 'a1');
      final participants = await repo.getParticipants(channel.id);
      expect(participants.any((p) => p.agentId == 'a1'), isFalse);
      expect(participants.any((p) => p.agentId == 'a2'), isTrue);
    });
  });

  group('stopRun', () {
    test('stops a given run log id', () async {
      // dispatchAgent registers run log ids in the dispatch service's
      // _runToDispatch map. We then stop those runs.
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      // The dispatch registered a run log; grab its id.
      final runLog = runLogRepo._runLog;
      expect(runLog, isNotNull);

      await service.stopRun(runLog!.id);
      // Should not throw; the stopDispatch closes the controller.
    });
  });

  group('dispatchAgent', () {
    test('does nothing when prompt is empty', () async {
      final channel = await service.openDm('agent-1');
      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: '',
      );
      final msgs = await repo.getMessages(channel.id);
      expect(msgs, isEmpty);
    });

    test('sends thinking message and dispatches', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'Hello from agent'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      final msgs = await repo.getMessages(channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('upserts run log when dispatching', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      expect(runLogRepo._upsertCount, greaterThanOrEqualTo(1));
    });

    test('handles dispatch error gracefully', () async {
      final channel = await service.openDm('agent-1');

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      dispatchPort.emitError(Exception('Dispatch failed'));
      // Should not throw
    });

    test('runs with workspaceId', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
        workspaceId: 'ws-1',
      );

      final msgs = await repo.getMessages(channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('dispatch updates run log', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      expect(runLogRepo._upsertCount, greaterThanOrEqualTo(1));
    });

    test('uses agent name and directory from agent repo', () async {
      final agentRepo = FakeAgentRepository();
      unawaited(agentRepo.upsert(_testAgent(
        id: 'agent-1',
        name: 'Builder',
        agentMdPath: '/home/agents/builder/agent.md',
      )));

      final svc = MessagingService(
        repo,
        agentRepo: agentRepo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
      );
      final channel = await svc.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await svc.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Build it',
      );

      final msgs = await repo.getMessages(channel.id);
      final thinking = msgs.firstWhere(
        (m) => m.messageType == ChannelMessageType.agentTurn,
      );
      expect(thinking.metadata?['agentName'], 'Builder');
      agentRepo.dispose();
    });

    test('registers stream ids in the registry', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      final runLog = runLogRepo._runLog;
      expect(runLog, isNotNull);
      expect(streamRegistry.isActive(runLog!.id), isTrue);
    });
  });

  group('sendAndDispatch', () {
    // Wrapper that replays current state so .first completes immediately.
    late _ReplayAgentRepo agentRepo;

    setUp(() {
      agentRepo = _ReplayAgentRepo();
      agentRepo.upsert(_testAgent(id: 'agent-1', name: 'Builder'));
      agentRepo.upsert(_testAgent(id: 'agent-2', name: 'Reviewer'));
    });

    tearDown(() {
      agentRepo.dispose();
    });

    MessagingService makeServiceWithAgentRepo() => MessagingService(
          repo,
          agentRepo: agentRepo,
          agentDispatchService: dispatchService,
          streamRegistry: streamRegistry,
          streamProcessor: makeStreamProcessor(),
        );

    test('falls back to sendUserMessage when agentRepo is null', () async {
      // The default service has no agentRepo.
      final channel = await service.openDm('agent-1');
      await service.sendAndDispatch(channel.id, 'Hello without agent repo');

      final msgs = await repo.getMessages(channel.id);
      expect(msgs.length, 1);
      expect(msgs[0].content, 'Hello without agent repo');
      expect(msgs[0].isUser, isTrue);
    });

    test('falls back to sendUserMessage when no agents exist', () async {
      agentRepo.clear();
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');
      await svc.sendAndDispatch(channel.id, 'No agents available');

      final msgs = await repo.getMessages(channel.id);
      // Just the user message, no dispatch
      expect(msgs.length, 1);
      expect(msgs[0].isUser, isTrue);
    });

    test('dispatches to explicitly mentioned agents', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(channel.id, '@Builder please build');
      // dispatchAgent is unawaited; pump so thinking message is inserted.
      await pumpEventQueue();

      final msgs = await repo.getMessages(channel.id);
      expect(msgs.any((m) => m.isUser && m.content == '@Builder please build'),
          isTrue);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('dispatches to default agent when no mentions', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(channel.id, 'Do something without mention');
      await pumpEventQueue();

      final msgs = await repo.getMessages(channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('does not dispatch when stripped content is empty', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');

      await svc.sendAndDispatch(channel.id, '@Builder');

      final msgs = await repo.getMessages(channel.id);
      // Only the user message (the mention is of an agent already in the DM).
      expect(msgs.length, 1);
      expect(msgs.any((m) => m.isUser && m.content == '@Builder'), isTrue);
    });

    test('refines pending plan when prior message is a pending plan', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'refined plan'));

      // Insert a pending plan message as the LAST message, so that after
      // sendAndDispatch inserts the user message, the plan becomes the
      // second-to-last message.
      const planMsgId = 'plan-msg-1';
      unawaited(repo.sendMessage(
        channelId: channel.id,
        content: 'Here is the plan',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'plan',
        id: planMsgId,
        metadata: {'planStatus': 'pending'},
      ));

      await svc.sendAndDispatch(channel.id, 'Please refine this plan');

      final msgs = await repo.getMessages(channel.id);
      final plan = msgs.firstWhere((m) => m.id == planMsgId);
      expect(plan.metadata?['planStatus'], 'refining');
    });

    test('dispatches with workspaceId', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(
        channel.id,
        '@Builder build this',
        workspaceId: 'ws-1',
      );
      await pumpEventQueue();

      final msgs = await repo.getMessages(channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });
  });

  group('refinePlan', () {
    late FakeAgentRepository agentRepo;

    setUp(() {
      agentRepo = FakeAgentRepository();
      agentRepo.upsert(_testAgent(id: 'agent-1', name: 'Builder'));
    });

    tearDown(() {
      agentRepo.dispose();
    });

    MessagingService makeServiceWithAgentRepo() => MessagingService(
          repo,
          agentRepo: agentRepo,
          agentDispatchService: dispatchService,
          streamRegistry: streamRegistry,
          streamProcessor: makeStreamProcessor(),
        );

    test('refines a pending plan and dispatches agent', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'refined plan output'));

      // Insert a pending plan.
      unawaited(repo.sendMessage(
        channelId: channel.id,
        content: 'Original plan',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'plan',
        id: 'plan-1',
        metadata: {'planStatus': 'pending'},
      ));

      await svc.refinePlan(
        channelId: channel.id,
        feedback: 'Make it shorter',
      );

      final msgs = await repo.getMessages(channel.id);
      // Plan status should be 'refining'.
      final plan = msgs.firstWhere((m) => m.id == 'plan-1');
      expect(plan.metadata?['planStatus'], 'refining');
      // A user feedback message should be sent.
      expect(msgs.any((m) => m.isUser && m.content == 'Make it shorter'), isTrue);
    });

    test('falls back to any plan when no pending plan exists', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'refined'));

      // Insert a plan with status 'approved' (not pending).
      unawaited(repo.sendMessage(
        channelId: channel.id,
        content: 'Approved plan',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'plan',
        id: 'plan-2',
        metadata: {'planStatus': 'approved'},
      ));

      await svc.refinePlan(
        channelId: channel.id,
        feedback: 'Change the approach',
      );

      final msgs = await repo.getMessages(channel.id);
      final plan = msgs.firstWhere((m) => m.id == 'plan-2');
      // Falls back to the first plan found, status updated to 'refining'.
      expect(plan.metadata?['planStatus'], 'refining');
    });

    test('throws StateError when no plan exists', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.openDm('agent-1');

      // No plan messages in the channel.
      expect(
        () => svc.refinePlan(
          channelId: channel.id,
          feedback: 'No plan to refine',
        ),
        throwsStateError,
      );
    });
  });

  group('MessagingService constructor', () {
    test('creates service with required deps', () {
      final streamProcessor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: streamRegistry,
      );
      final service = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: streamProcessor,
      );
      expect(service, isNotNull);
    });

    test('creates service with optional deps', () {
      final streamProcessor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: streamRegistry,
      );
      final service = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: streamProcessor,
        agentRepo: null,
      );
      expect(service, isNotNull);
    });
  });

  group('dispatchAgent details', () {
    test('passes wakeContext to dispatch', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
        wakeContext: const WakeContext(
          agentId: 'agent-1',
          runId: 'wake-run-1',
          workspaceId: 'ws-1',
          wakeReason: WakeReason.userMessage,
          ticketId: 'ticket-1',
        ),
      );

      final msgs = await repo.getMessages(channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('passes ticketId to dispatch', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
        ticketId: 'ticket-42',
      );

      final msgs = await repo.getMessages(channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('passes parentMessageId to dispatch', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
        parentMessageId: 'parent-msg-1',
      );

      final msgs = await repo.getMessages(channel.id);
      final thinking = msgs.firstWhere(
        (m) => m.messageType == ChannelMessageType.agentTurn,
      );
      expect(thinking.parentMessageId, 'parent-msg-1');
    });
  });

  group('addAgentToChannel edge cases', () {
    test('does not rename when participants.length != 2', () async {
      final agentRepo = FakeAgentRepository();
      unawaited(agentRepo.upsert(_testAgent(id: 'a1', name: 'Alpha')));
      unawaited(agentRepo.upsert(_testAgent(id: 'a2', name: 'Beta')));
      unawaited(agentRepo.upsert(_testAgent(id: 'a3', name: 'Gamma')));
      unawaited(agentRepo.upsert(_testAgent(id: 'a4', name: 'Delta')));

      final svc = MessagingService(
        repo,
        agentRepo: agentRepo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
      );
      // Create a group with 3 agents (participants.length = 3).
      final channel = await svc.createGroup('Team', ['a1', 'a2', 'a3']);
      // Adding a 4th agent: participants.length was 3, not 2, so no rename.
      await svc.addAgentToChannel(channel.id, 'a4');

      expect(repo.lastUpdatedName, isNull);
      agentRepo.dispose();
    });
  });

  group('stopRun multiple', () {
    test('stops multiple run log ids', () async {
      // First dispatch.
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));
      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Task 1',
      );
      final runLog1 = runLogRepo._runLog;
      expect(runLog1, isNotNull);

      // Second dispatch.
      dispatchPort.emitEvent(TextEvent(content: 'hello again'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));
      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Task 2',
      );
      final runLog2 = runLogRepo._runLog;
      expect(runLog2, isNotNull);

      // Stop both — should complete without error.
      await service.stopRun(runLog1!.id);
      await service.stopRun(runLog2!.id);
    });
  });

  group('sendAndDispatch further', () {
    late _ReplayAgentRepo agentRepo;

    setUp(() {
      agentRepo = _ReplayAgentRepo();
      agentRepo.upsert(_testAgent(id: 'agent-1', name: 'Builder'));
    });

    tearDown(() {
      agentRepo.dispose();
    });

    MessagingService makeServiceWithAgentRepo() => MessagingService(
          repo,
          agentRepo: agentRepo,
          agentDispatchService: dispatchService,
          streamRegistry: streamRegistry,
          streamProcessor: makeStreamProcessor(),
        );

    test('no dispatch when default agent resolver finds no agent', () async {
      final svc = makeServiceWithAgentRepo();
      // Create a group channel (isDm = false) with only one agent.
      final channel = await service.createGroup('Solo', ['agent-1']);

      // Send a message that does not mention any agent. Because the channel
      // is a group and no agent is explicitly mentioned, the default-agent
      // resolver finds no agent to dispatch.
      await svc.sendAndDispatch(channel.id, 'Hello without mention');

      final msgs = await repo.getMessages(channel.id);
      // Only the user message — no thinking message dispatched.
      expect(msgs.length, 1);
      expect(msgs[0].isUser, isTrue);
    });
  });
}
