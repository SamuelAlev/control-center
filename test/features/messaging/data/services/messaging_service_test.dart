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
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:cc_infra/src/messaging/messaging_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Workspace every channel in this suite is created in.
///
/// A workspace id selects the database file, so it is the scoping key for every
/// id lookup below: an id paired with a different workspace must not resolve.
const _ws = 'ws-1';

class _FakeMessagingRepo implements MessagingRepository {
  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) async {
    for (final c in _channels) {
      if (c.id == channelId && _owns(workspaceId, channelId)) {
        return c;
      }
    }
    return null;
  }

  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  final _channels = <Channel>[];
  final _participants = <String, List<ChannelParticipant>>{};
  final _messages = <String, List<ChannelMessage>>{};
  final _compacted = <String>{};
  final _embeddings = <String, Uint8List>{};
  String? _lastUpdatedName;

  /// Owning workspace of each channel id, the scoping key for id lookups.
  final _channelWorkspace = <String, String>{};

  /// Whether [channelId] belongs to [workspaceId]. An id that was never created
  /// here belongs to no workspace.
  bool _owns(String workspaceId, String channelId) =>
      _channelWorkspace[channelId] == workspaceId;

  ChannelParticipant _makeParticipant(
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) => ChannelParticipant(
    id: 'p-$principalId',
    channelId: channelId,
    principalId: principalId,
    participantType: participantType,
    role: 'member',
    joinedAt: DateTime.now(),
  );

  @override
  Stream<List<Channel>> watchChannels() =>
      Stream.value(List.unmodifiable(_channels));

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value(
        List.unmodifiable(
          _channels.where((c) => c.workspaceId == workspaceId).toList(),
        ),
      );

  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => Stream.value(
    List.unmodifiable(
      _owns(workspaceId, channelId) ? _participants[channelId] ?? [] : const [],
    ),
  );

  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => Stream.value(
    List.unmodifiable(
      _owns(workspaceId, channelId) ? _messages[channelId] ?? [] : const [],
    ),
  );

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
  }) async {
    final channel = Channel(
      id: 'channel-${_channels.length}-${name.hashCode}',
      name: name,
      workspaceId: workspaceId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      mode: mode,
      pipelineRunId: pipelineRunId,
    );
    _channels.add(channel);
    _channelWorkspace[channel.id] = workspaceId;
    _participants[channel.id] = [
      if (createdByUserId != null)
        _makeParticipant(
          channel.id,
          createdByUserId,
          participantType: PrincipalType.user,
        ),
      ...agentIds.map((id) => _makeParticipant(channel.id, id)),
    ];
    return channel;
  }

  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) async {
    if (!_owns(workspaceId, channelId)) {
      return;
    }
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _channels[idx] = _channels[idx].copyWith(mode: mode);
    }
  }

  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    if (!_owns(workspaceId, channelId)) {
      return;
    }
    _participants.putIfAbsent(channelId, () => []);
    _participants[channelId]!.add(
      _makeParticipant(
        channelId,
        principalId,
        participantType: participantType,
      ),
    );
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => List.unmodifiable(
    _owns(workspaceId, channelId) ? _participants[channelId] ?? [] : const [],
  );

  @override
  Future<bool> channelExists(String workspaceId, String channelId) async =>
      !_deletedChannels.contains(channelId);

  /// Channels deleted via `deleteChannel`, so `channelExists` reflects it.
  final Set<String> _deletedChannels = {};

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
  }) async {
    _messages.putIfAbsent(channelId, () => []);
    final msg = ChannelMessage(
      id: id ?? 'msg-${_messages[channelId]!.length}',
      channelId: channelId,
      conversationId: channelId,
      senderId: senderId,
      senderType: senderType == 'user'
          ? ChannelSenderType.user
          : ChannelSenderType.agent,
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
      createdAt: DateTime.now(),
    );
    _messages[channelId]!.add(msg);
    return msg.id;
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    for (final msgs in _messages.values) {
      final idx = msgs.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        msgs[idx] = msgs[idx].copyWith(content: content, metadata: metadata);
        return;
      }
    }
  }

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
  }) async => List.unmodifiable(
    _owns(workspaceId, channelId) ? _messages[channelId] ?? [] : const [],
  );

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {
    _compacted.addAll(ids);
  }

  @override
  Future<void> deleteChannel(String workspaceId, String channelId) async {
    if (!_owns(workspaceId, channelId)) {
      return;
    }
    _channels.removeWhere((c) => c.id == channelId);
    _messages.remove(channelId);
    _participants.remove(channelId);
    _channelWorkspace.remove(channelId);
    _deletedChannels.add(channelId);
  }

  @override
  Future<void> updateChannelName(
    String workspaceId,
    String channelId,
    String name,
  ) async {
    if (!_owns(workspaceId, channelId)) {
      return;
    }
    _lastUpdatedName = name;
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _channels[idx] = _channels[idx].copyWith(name: name);
    }
  }

  String? get lastUpdatedName => _lastUpdatedName;

  @override
  Future<void> clearChannelMessages(
    String workspaceId,
    String channelId,
  ) async {
    if (!_owns(workspaceId, channelId)) {
      return;
    }
    _messages[channelId]?.clear();
  }

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String principalId,
  ) async {
    if (!_owns(workspaceId, channelId)) {
      return;
    }
    _participants[channelId]?.removeWhere((p) => p.principalId == principalId);
  }

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {
    _embeddings[messageId] = embedding;
  }

  Uint8List? embeddingFor(String messageId) => _embeddings[messageId];

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
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async {
    // A message is reachable only through its channel, so the channel's
    // workspace scopes the lookup.
    for (final entry in _messages.entries) {
      if (!_owns(workspaceId, entry.key)) {
        continue;
      }
      final idx = entry.value.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        // Reflects any `updateMessage` applied to the per-channel list.
        return entry.value[idx];
      }
    }
    final seeded = _messagesById[messageId];
    return seeded != null && _owns(workspaceId, seeded.channelId)
        ? seeded
        : null;
  }

  /// Messages keyed by id, for `getMessageById` lookups (retryAgentTurn, …).
  final Map<String, ChannelMessage> _messagesById = {};

  /// Seeds a message the repo will return from `getMessageById` AND reflect in
  /// `updateMessage` (which scans the per-channel `_messages` lists).
  void seedMessage(ChannelMessage message) {
    _messagesById[message.id] = message;
    _messages.putIfAbsent(message.channelId, () => []).add(message);
  }

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

class _FakeAgentDispatchPort implements AgentDispatchPort {
  final List<String> pausedDispatchIds = [];
  final List<String> resumedDispatchIds = [];
  bool pauseReturn = false;
  bool resumeReturn = false;

  @override
  Future<bool> pauseDispatch(String dispatchId) async {
    pausedDispatchIds.add(dispatchId);
    return pauseReturn;
  }

  @override
  Future<bool> resumeDispatch(String dispatchId) async {
    resumedDispatchIds.add(dispatchId);
    return resumeReturn;
  }

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
    String? userText,
    String? modelId,
    String? agentId,
    String? agentName,
    String? workspaceId,
    String? conversationId,
    String? runLogId,
    String? ticketId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    Mode? mode,
    int? silenceTimeoutMinutes,
    Map<String, String>? environment,
    List<String>? imagePaths,
    String? effortLevel,
    String? agentConfigDir,
    List<String>? adapterArgsOverride,
    Map<String, String>? adapterEnvOverride,
    int? costCapCents,
  }) => DispatchHandle(dispatchId: 'ds-1', events: _controller.stream);

  @override
  Future<void> stopDispatch(String dispatchId) async => _controller.close();

  @override
  Future<void> stopAllForAgent(String agentId) async => _controller.close();

  @override
  Future<bool> steerDispatch(
    String dispatchId,
    String message, {
    bool followUp = false,
  }) async => false;

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
  Future<AgentRunLog?> getById(String workspaceId, String id) async => _runLog;
}

class _FakeDispatchAgentUseCase extends Fake implements DispatchAgentUseCase {
  @override
  Future<PreparedDispatch> execute({
    required String workspaceId,
    required String agentId,
    required String prompt,
    String? channelId,
    String? conversationId,
    String? adapterId,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    return PreparedDispatch(
      effectivePrompt: prompt,
      effectiveConversationId: conversationId ?? channelId,
      agent: null,
      mode: Mode.chat,
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
      delete(a.workspaceId, a.id);
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
  Future<List<Float32List>> embedAll(List<String> texts) async => [
    for (final text in texts) await embed(text),
  ];

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
}) => Agent(
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
      resolveDefaultUserId: () async => 'user-1',
    );
  });

  tearDown(() async {
    await dispatchPort.stop();
  });

  group('createChannel', () {
    test('creates a channel', () async {
      final channel = await service.createChannel(_ws, 'My Team', [
        'agent-1',
        'agent-2',
      ]);
      expect(channel.name, 'My Team');
    });

    test('creates a single-agent channel', () async {
      final channel = await service.createChannel(_ws, 'Solo', ['agent-1']);
      expect(channel.name, 'Solo');
    });
  });

  group('sendUserMessage', () {
    test('sends a user message to channel', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await service.sendUserMessage(_ws, channel.id, 'Hello!');
      final msgs = await repo.getMessages(_ws, channel.id);
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
        resolveDefaultUserId: () async => 'user-1',
        eventBus: eventBus,
      );
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await svc.sendUserMessage(_ws, channel.id, 'Event test');
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
        resolveDefaultUserId: () async => 'user-1',
        eventBus: eventBus,
      );
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      final longContent = 'x' * 200;
      await svc.sendUserMessage(_ws, channel.id, longContent);
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
        resolveDefaultUserId: () async => 'user-1',
        embeddingPort: embedPort,
      );
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await svc.sendUserMessage(_ws, channel.id, 'Embed me');
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
        resolveDefaultUserId: () async => 'user-1',
        embeddingPort: embedPort,
      );
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await svc.sendUserMessage(_ws, channel.id, 'No embed');
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
        resolveDefaultUserId: () async => 'user-1',
        embeddingPort: embedPort,
      );
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await svc.sendUserMessage(_ws, channel.id, '');
      await pumpEventQueue();

      expect(embedPort.embedCalls, isEmpty);
    });
  });

  group('addAgentToChannel', () {
    test('adds agent and sends system message', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await service.addAgentToChannel(_ws, channel.id, 'agent-2');
      final participants = await repo.getParticipants(_ws, channel.id);
      expect(participants.any((p) => p.principalId == 'agent-2'), isTrue);
    });

    test('does not add duplicate agent', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      final initialCount = (await repo.getParticipants(_ws, channel.id)).length;
      await service.addAgentToChannel(_ws, channel.id, 'agent-1');
      final participants = await repo.getParticipants(_ws, channel.id);
      expect(participants.length, initialCount);
    });

    test('renames channel when third participant joins', () async {
      final agentRepo = FakeAgentRepository();
      unawaited(agentRepo.upsert(_testAgent(id: 'agent-1', name: 'Alice')));
      unawaited(agentRepo.upsert(_testAgent(id: 'agent-2', name: 'Bob')));

      final svc = MessagingService(
        repo,
        agentRepo: agentRepo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        resolveDefaultUserId: () async => 'user-1',
      );
      final channel = await svc.createChannel(_ws, '', ['agent-1']);
      // Add second agent (1→2 participants, no rename).
      await svc.addAgentToChannel(_ws, channel.id, 'agent-tmp');
      // Add third agent (2→3 participants, triggers participant-name rename).
      await svc.addAgentToChannel(_ws, channel.id, 'agent-2');

      expect(repo.lastUpdatedName, 'Alice, Bob');
      agentRepo.dispose();
    });
  });

  group('deleteChannel', () {
    test('deletes a channel', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await service.deleteChannel(_ws, channel.id);
      final participants = await repo.getParticipants(_ws, channel.id);
      expect(participants, isEmpty);
    });

    test('publishes ChannelDeleted event when eventBus is wired', () async {
      final eventBus = DomainEventBus();
      final events = <ChannelDeleted>[];
      eventBus.on<ChannelDeleted>().listen(events.add);

      final svc = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        resolveDefaultUserId: () async => 'user-1',
        eventBus: eventBus,
      );
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await svc.deleteChannel(_ws, channel.id);
      await pumpEventQueue();
      expect(events.length, 1);
      expect(events[0].channelId, channel.id);
      eventBus.dispose();
    });
  });

  group('updateChannelName', () {
    test('completes without error', () async {
      final channel = await service.createChannel(_ws, 'Old', ['a1']);
      await service.updateChannelName(_ws, channel.id, 'New Name');
    });
  });

  group('clearChannelMessages', () {
    test('clears all messages in channel', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await service.sendUserMessage(_ws, channel.id, 'msg1');
      await service.sendUserMessage(_ws, channel.id, 'msg2');
      await service.clearChannelMessages(_ws, channel.id);
      final msgs = await repo.getMessages(_ws, channel.id);
      expect(msgs, isEmpty);
    });
  });

  group('removeParticipant', () {
    test('removes an agent from channel', () async {
      final channel = await service.createChannel(_ws, 'Team', ['a1', 'a2']);
      await service.removeParticipant(_ws, channel.id, 'a1');
      final participants = await repo.getParticipants(_ws, channel.id);
      expect(participants.any((p) => p.principalId == 'a1'), isFalse);
      expect(participants.any((p) => p.principalId == 'a2'), isTrue);
    });
  });

  group('stopRun', () {
    test('stops a given run log id', () async {
      // dispatchAgent registers run log ids in the dispatch service's
      // _runToDispatch map. We then stop those runs.
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      // The dispatch registered a run log; grab its id.
      final runLog = runLogRepo._runLog;
      expect(runLog, isNotNull);

      await service.stopRun(_ws, runLog!.id);
      // Should not throw; the stopDispatch closes the controller.
    });
  });

  group('pauseRun', () {
    test('pauses a dispatched run by its run log id', () async {
      dispatchPort.pauseReturn = true;
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      final runLog = runLogRepo._runLog;
      expect(runLog, isNotNull);

      final accepted = await service.pauseRun(runLog!.id);

      expect(accepted, isTrue);
      expect(dispatchPort.pausedDispatchIds, isNotEmpty);
    });

    test('returns false for an unknown run log id', () async {
      dispatchPort.pauseReturn = true;
      final accepted = await service.pauseRun('never-dispatched');
      expect(accepted, isFalse);
      expect(dispatchPort.pausedDispatchIds, isEmpty);
    });

    test('forwards a false result when the transport cannot pause', () async {
      // pauseReturn defaults to false.
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );
      final runLog = runLogRepo._runLog;

      final accepted = await service.pauseRun(runLog!.id);

      expect(accepted, isFalse);
    });
  });

  group('resumeRun', () {
    test('resumes a paused run by its run log id', () async {
      dispatchPort.resumeReturn = true;
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );
      final runLog = runLogRepo._runLog;

      final accepted = await service.resumeRun(runLog!.id);

      expect(accepted, isTrue);
      expect(dispatchPort.resumedDispatchIds, isNotEmpty);
    });

    test('returns false for an unknown run log id', () async {
      dispatchPort.resumeReturn = true;
      final accepted = await service.resumeRun('never-dispatched');
      expect(accepted, isFalse);
      expect(dispatchPort.resumedDispatchIds, isEmpty);
    });
  });

  group('dispatchAgent', () {
    test('does nothing when prompt is empty', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: '',
      );
      final msgs = await repo.getMessages(_ws, channel.id);
      expect(msgs, isEmpty);
    });

    test('sends thinking message and dispatches', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'Hello from agent'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      final msgs = await repo.getMessages(_ws, channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('upserts run log when dispatching', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      expect(runLogRepo._upsertCount, greaterThanOrEqualTo(1));
    });

    test('handles dispatch error gracefully', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      dispatchPort.emitError(Exception('Dispatch failed'));
      // Should not throw
    });

    test('stamps the dispatching workspace on the run log', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      // A run log stamped with the wrong workspace is written to another
      // database file, so every workspace-scoped surface misses the run and the
      // ownership check on stopRun/pauseRun/steer rejects it.
      expect(runLogRepo._runLog?.workspaceId, _ws);
      final msgs = await repo.getMessages(_ws, channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('dispatch updates run log', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      expect(runLogRepo._upsertCount, greaterThanOrEqualTo(1));
    });

    test('uses agent name and directory from agent repo', () async {
      final agentRepo = FakeAgentRepository();
      unawaited(
        agentRepo.upsert(
          _testAgent(
            id: 'agent-1',
            name: 'Builder',
            agentMdPath: '/home/agents/builder/agent.md',
          ),
        ),
      );

      final svc = MessagingService(
        repo,
        agentRepo: agentRepo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        resolveDefaultUserId: () async => 'user-1',
      );
      final channel = await svc.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await svc.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Build it',
      );

      final msgs = await repo.getMessages(_ws, channel.id);
      final thinking = msgs.firstWhere(
        (m) => m.messageType == ChannelMessageType.agentTurn,
      );
      expect(thinking.metadata?['agentName'], 'Builder');
      agentRepo.dispose();
    });

    test('registers stream ids in the registry', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
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
      resolveDefaultUserId: () async => 'user-1',
    );

    test('falls back to sendUserMessage when agentRepo is null', () async {
      // The default service has no agentRepo.
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await service.sendAndDispatch(
        _ws,
        channel.id,
        'Hello without agent repo',
      );

      final msgs = await repo.getMessages(_ws, channel.id);
      expect(msgs.length, 1);
      expect(msgs[0].content, 'Hello without agent repo');
      expect(msgs[0].isUser, isTrue);
    });

    test('falls back to sendUserMessage when no agents exist', () async {
      agentRepo.clear();
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await svc.sendAndDispatch(_ws, channel.id, 'No agents available');

      final msgs = await repo.getMessages(_ws, channel.id);
      // Just the user message, no dispatch
      expect(msgs.length, 1);
      expect(msgs[0].isUser, isTrue);
    });

    test('dispatches to explicitly mentioned agents', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(_ws, channel.id, '@Builder please build');
      // dispatchAgent is unawaited; pump so thinking message is inserted.
      await pumpEventQueue();

      final msgs = await repo.getMessages(_ws, channel.id);
      expect(
        msgs.any((m) => m.isUser && m.content == '@Builder please build'),
        isTrue,
      );
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('dispatches to default agent when no mentions', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(
        _ws,
        channel.id,
        'Do something without mention',
      );
      await pumpEventQueue();

      final msgs = await repo.getMessages(_ws, channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('does not dispatch when stripped content is empty', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);

      await svc.sendAndDispatch(_ws, channel.id, '@Builder');

      final msgs = await repo.getMessages(_ws, channel.id);
      // Only the user message — the mention strips to empty content, so there
      // is nothing to dispatch.
      expect(msgs.length, 1);
      expect(msgs.any((m) => m.isUser && m.content == '@Builder'), isTrue);
    });

    test('refines pending plan when prior message is a pending plan', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'refined plan'));

      // Insert a pending plan message as the LAST message, so that after
      // sendAndDispatch inserts the user message, the plan becomes the
      // second-to-last message.
      const planMsgId = 'plan-msg-1';
      unawaited(
        repo.sendMessage(
          workspaceId: _ws,
          channelId: channel.id,
          content: 'Here is the plan',
          senderId: 'agent-1',
          senderType: 'agent',
          messageType: 'plan',
          id: planMsgId,
          metadata: {'planStatus': 'pending'},
        ),
      );

      await svc.sendAndDispatch(_ws, channel.id, 'Please refine this plan');

      final msgs = await repo.getMessages(_ws, channel.id);
      final plan = msgs.firstWhere((m) => m.id == planMsgId);
      expect(plan.metadata?['planStatus'], 'refining');
    });

    test('dispatches with workspaceId', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(_ws, channel.id, '@Builder build this');
      await pumpEventQueue();

      final msgs = await repo.getMessages(_ws, channel.id);
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
      resolveDefaultUserId: () async => 'user-1',
    );

    test('refines a pending plan and dispatches agent', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'refined plan output'));

      // Insert a pending plan.
      unawaited(
        repo.sendMessage(
          workspaceId: _ws,
          channelId: channel.id,
          content: 'Original plan',
          senderId: 'agent-1',
          senderType: 'agent',
          messageType: 'plan',
          id: 'plan-1',
          metadata: {'planStatus': 'pending'},
        ),
      );

      await svc.refinePlan(
        workspaceId: _ws,
        channelId: channel.id,
        feedback: 'Make it shorter',
      );

      final msgs = await repo.getMessages(_ws, channel.id);
      // Plan status should be 'refining'.
      final plan = msgs.firstWhere((m) => m.id == 'plan-1');
      expect(plan.metadata?['planStatus'], 'refining');
      // A user feedback message should be sent.
      expect(
        msgs.any((m) => m.isUser && m.content == 'Make it shorter'),
        isTrue,
      );
    });

    test('falls back to any plan when no pending plan exists', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'refined'));

      // Insert a plan with status 'approved' (not pending).
      unawaited(
        repo.sendMessage(
          workspaceId: _ws,
          channelId: channel.id,
          content: 'Approved plan',
          senderId: 'agent-1',
          senderType: 'agent',
          messageType: 'plan',
          id: 'plan-2',
          metadata: {'planStatus': 'approved'},
        ),
      );

      await svc.refinePlan(
        workspaceId: _ws,
        channelId: channel.id,
        feedback: 'Change the approach',
      );

      final msgs = await repo.getMessages(_ws, channel.id);
      final plan = msgs.firstWhere((m) => m.id == 'plan-2');
      // Falls back to the first plan found, status updated to 'refining'.
      expect(plan.metadata?['planStatus'], 'refining');
    });

    test('throws StateError when no plan exists', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);

      // No plan messages in the channel.
      expect(
        () => svc.refinePlan(
          workspaceId: _ws,
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
        resolveDefaultUserId: () async => 'user-1',
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
        resolveDefaultUserId: () async => 'user-1',
        agentRepo: null,
      );
      expect(service, isNotNull);
    });
  });

  group('dispatchAgent details', () {
    test('passes wakeContext to dispatch', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        workspaceId: _ws,
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

      final msgs = await repo.getMessages(_ws, channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('passes ticketId to dispatch', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
        ticketId: 'ticket-42',
      );

      final msgs = await repo.getMessages(_ws, channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });

    test('dispatches an agent turn into the conversation', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      final msgs = await repo.getMessages(_ws, channel.id);
      final thinking = msgs.firstWhere(
        (m) => m.messageType == ChannelMessageType.agentTurn,
      );
      expect(thinking.conversationId, channel.id);
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
        resolveDefaultUserId: () async => 'user-1',
      );
      // Create a group with 3 agents (participants.length = 3).
      final channel = await svc.createChannel(_ws, 'Team', ['a1', 'a2', 'a3']);
      // Adding a 4th agent: participants.length was 3, not 2, so no rename.
      await svc.addAgentToChannel(_ws, channel.id, 'a4');

      expect(repo.lastUpdatedName, isNull);
      agentRepo.dispose();
    });
  });

  group('stopRun multiple', () {
    test('stops multiple run log ids', () async {
      // First dispatch.
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));
      await service.dispatchAgent(
        workspaceId: _ws,
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
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Task 2',
      );
      final runLog2 = runLogRepo._runLog;
      expect(runLog2, isNotNull);

      // Stop both — should complete without error.
      await service.stopRun(_ws, runLog1!.id);
      await service.stopRun(_ws, runLog2!.id);
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
      resolveDefaultUserId: () async => 'user-1',
    );

    test('no dispatch when default agent resolver finds no agent', () async {
      final svc = makeServiceWithAgentRepo();
      // Create a channel with no participating agents.
      final channel = await service.createChannel(_ws, 'Empty', const []);

      // Send a message that does not mention any agent. With no agents in the
      // channel, the default-agent resolver finds no agent to dispatch.
      await svc.sendAndDispatch(_ws, channel.id, 'Hello without mention');

      final msgs = await repo.getMessages(_ws, channel.id);
      // Only the user message — no thinking message dispatched.
      expect(msgs.length, 1);
      expect(msgs[0].isUser, isTrue);
    });

    test('dispatches to the sole agent of a single-agent channel', () async {
      final svc = makeServiceWithAgentRepo();
      final channel = await service.createChannel(_ws, 'Solo', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      // No mention: the default-agent resolver picks the sole channel agent.
      await svc.sendAndDispatch(_ws, channel.id, 'Hello without mention');
      await pumpEventQueue();

      final msgs = await repo.getMessages(_ws, channel.id);
      expect(
        msgs.any((m) => m.messageType == ChannelMessageType.agentTurn),
        isTrue,
      );
    });
  });

  group('channelExists', () {
    test('delegates to the repository', () async {
      expect(await service.channelExists(_ws, 'ch-1'), isTrue);
    });
  });

  group('retryAgentTurn', () {
    test(
      'marks the failed message retried and re-dispatches the agent',
      () async {
        final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
        // Seed a failed agent-turn message.
        final failed = ChannelMessage(
          id: 'm-failed',
          channelId: channel.id,
          conversationId: channel.id,
          senderId: 'agent-1',
          senderType: ChannelSenderType.agent,
          content: '',
          messageType: ChannelMessageType.agentTurn,
          createdAt: DateTime(2025),
        );
        repo.seedMessage(failed);

        dispatchPort.emitEvent(TextEvent(content: 'retry'));
        await service.retryAgentTurn(
          workspaceId: _ws,
          channelId: channel.id,
          failedMessageId: 'm-failed',
        );

        // The failed message is marked retried.
        final updated = await repo.getMessageById(_ws, 'm-failed');
        expect(updated?.metadata?['retried'], isTrue);
      },
    );

    test('is a no-op when the failed message does not exist', () async {
      await service.retryAgentTurn(
        workspaceId: _ws,
        channelId: 'ch-1',
        failedMessageId: 'never-existed',
      );
      // No dispatch, no throw.
    });

    test('stamps the run log with the workspace and the failed turn\'s '
        'conversation', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      // The failed turn lived in a parenthesis, not the channel's `main`
      // conversation.
      repo.seedMessage(
        ChannelMessage(
          id: 'm-failed',
          channelId: channel.id,
          conversationId: 'conv-side',
          senderId: 'agent-1',
          senderType: ChannelSenderType.agent,
          content: '',
          messageType: ChannelMessageType.agentTurn,
          createdAt: DateTime(2025),
        ),
      );

      dispatchPort.emitEvent(TextEvent(content: 'retry'));
      await service.retryAgentTurn(
        workspaceId: _ws,
        channelId: channel.id,
        failedMessageId: 'm-failed',
      );

      // A workspace-less retry run is invisible to every workspace-scoped
      // surface (the composer's stop affordance, the run tree, presence) and is
      // rejected by the ownership check on stopRun/pauseRun/steer — i.e. an
      // unstoppable run. The conversation must be the failed turn's, not the
      // channel's `main`.
      final run = await runLogRepo.getById(_ws, 'any');
      expect(run?.workspaceId, _ws);
      expect(run?.conversationId, 'conv-side');
    });
  });

  group('addAgentToChannel rename', () {
    test(
      'renames the channel when a second agent joins a 1:1 channel',
      () async {
        // A 1:1 channel is two participants: the human who created it and one
        // agent. That is the shape the rename path keys off.
        final channel = await service.createChannel(_ws, 'One', [
          'agent-1',
        ], createdByUserId: 'user-1');
        // A second agent joining triggers the group-name rename path.
        await service.addAgentToChannel(_ws, channel.id, 'agent-2');

        final updated = await repo.getChannelById(_ws, channel.id);
        // The renamed channel holds both agent names.
        expect(updated?.name, isNot('One'));
      },
    );
  });

  group('deleteChannel', () {
    test('deletes the channel and publishes a ChannelDeleted event', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      await service.deleteChannel(_ws, channel.id);
      expect(await repo.channelExists(_ws, channel.id), isFalse);
    });
  });

  group('stopRun / steerRun delegation', () {
    test('stopRun delegates to the dispatch service', () async {
      final channel = await service.createChannel(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      await service.dispatchAgent(
        workspaceId: _ws,
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );
      final runLog = runLogRepo._runLog;
      expect(runLog, isNotNull);
      // Should not throw.
      await service.stopRun(_ws, runLog!.id);
    });
  });
}
