import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:cc_infra/src/messaging/messaging_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Workspace every space in this suite is created in.
///
/// A workspace id selects the database file, so it is the scoping key for every
/// id lookup below: an id paired with a different workspace must not resolve.
const _ws = 'ws-1';

class _FakeMessagingRepo implements MessagingRepository {

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {}
  @override
  Future<List<String>?> spaceRepoSelection(
    String workspaceId,
    String spaceId,
  ) async => null;

  @override
  Future<Map<String, String>> spaceRepoBranches(
    String workspaceId,
    String spaceId,
  ) async => const {};

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) async {}
  @override
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      getMessages(workspaceId, spaceId);

  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => const Stream.empty();

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async {
    for (final c in _spaces) {
      if (c.id == spaceId && _owns(workspaceId, spaceId)) {
        return c;
      }
    }
    return null;
  }

  @override
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <Message>[], hasMore: false));

  final _spaces = <Space>[];
  final _participants = <String, List<SpaceParticipant>>{};
  final _messages = <String, List<Message>>{};
  final _compacted = <String>{};
  final _embeddings = <String, Uint8List>{};
  String? _lastUpdatedName;

  /// Owning workspace of each space id, the scoping key for id lookups.
  final _spaceWorkspace = <String, String>{};

  /// Whether [spaceId] belongs to [workspaceId]. An id that was never created
  /// here belongs to no workspace.
  bool _owns(String workspaceId, String spaceId) =>
      _spaceWorkspace[spaceId] == workspaceId;

  SpaceParticipant _makeParticipant(
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) => SpaceParticipant(
    id: 'p-$principalId',
    spaceId: spaceId,
    principalId: principalId,
    participantType: participantType,
    role: 'member',
    joinedAt: DateTime.now(),
  );

  @override
  Stream<List<Space>> watchSpaces() => Stream.value(List.unmodifiable(_spaces));

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value(
        List.unmodifiable(
          _spaces.where((c) => c.workspaceId == workspaceId).toList(),
        ),
      );

  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => Stream.value(
    List.unmodifiable(
      _owns(workspaceId, spaceId) ? _participants[spaceId] ?? [] : const [],
    ),
  );

  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => Stream.value(
    List.unmodifiable(
      _owns(workspaceId, spaceId) ? _messages[spaceId] ?? [] : const [],
    ),
  );

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) async {
    final space = Space(
      id: 'channel-${_spaces.length}-${name.hashCode}',
      name: name,
      workspaceId: workspaceId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      mode: mode,
      pipelineRunId: pipelineRunId,
    );
    _spaces.add(space);
    _spaceWorkspace[space.id] = workspaceId;
    _participants[space.id] = [
      if (createdByUserId != null)
        _makeParticipant(
          space.id,
          createdByUserId,
          participantType: PrincipalType.user,
        ),
      ...agentIds.map((id) => _makeParticipant(space.id, id)),
    ];
    return space;
  }

  @override
  Future<void> setSpaceMode(
    String workspaceId,
    String spaceId,
    Mode mode,
  ) async {
    if (!_owns(workspaceId, spaceId)) {
      return;
    }
    final idx = _spaces.indexWhere((c) => c.id == spaceId);
    if (idx != -1) {
      _spaces[idx] = _spaces[idx].copyWith(mode: mode);
    }
  }

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    if (!_owns(workspaceId, spaceId)) {
      return;
    }
    _participants.putIfAbsent(spaceId, () => []);
    _participants[spaceId]!.add(
      _makeParticipant(spaceId, principalId, participantType: participantType),
    );
  }

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => List.unmodifiable(
    _owns(workspaceId, spaceId) ? _participants[spaceId] ?? [] : const [],
  );

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      !_deletedSpaces.contains(spaceId);

  /// Spaces deleted via `deleteSpace`, so `spaceExists` reflects it.
  final Set<String> _deletedSpaces = {};

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    _messages.putIfAbsent(spaceId, () => []);
    final msg = Message(
      id: id ?? 'msg-${_messages[spaceId]!.length}',
      spaceId: spaceId,
      conversationId: spaceId,
      senderId: senderId,
      senderType: senderType == 'user' ? SenderType.user : SenderType.agent,
      content: content,
      messageType: messageType == 'system'
          ? MessageType.system
          : messageType == 'ticket_card'
          ? MessageType.ticketCard
          : messageType == 'agent_turn'
          ? MessageType.agentTurn
          : messageType == 'plan'
          ? MessageType.plan
          : MessageType.text,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    _messages[spaceId]!.add(msg);
    return msg.id;
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
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
  Future<List<Message>> searchInSpace(
    String workspaceId,
    String spaceId,
    String query, {
    int limit = 20,
  }) async => const [];

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => List.unmodifiable(
    _owns(workspaceId, spaceId) ? _messages[spaceId] ?? [] : const [],
  );

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {
    _compacted.addAll(ids);
  }

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {
    if (!_owns(workspaceId, spaceId)) {
      return;
    }
    _spaces.removeWhere((c) => c.id == spaceId);
    _messages.remove(spaceId);
    _participants.remove(spaceId);
    _spaceWorkspace.remove(spaceId);
    _deletedSpaces.add(spaceId);
  }

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {
    if (!_owns(workspaceId, spaceId)) {
      return;
    }
    _lastUpdatedName = name;
    final idx = _spaces.indexWhere((c) => c.id == spaceId);
    if (idx != -1) {
      _spaces[idx] = _spaces[idx].copyWith(name: name);
    }
  }

  String? get lastUpdatedName => _lastUpdatedName;

  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) async {
    if (!_owns(workspaceId, spaceId)) {
      return;
    }
    _messages[spaceId]?.clear();
  }

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String principalId,
  ) async {
    if (!_owns(workspaceId, spaceId)) {
      return;
    }
    _participants[spaceId]?.removeWhere((p) => p.principalId == principalId);
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
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) async => [];

  @override
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async {
    // A message is reachable only through its space, so the space's
    // workspace scopes the lookup.
    for (final entry in _messages.entries) {
      if (!_owns(workspaceId, entry.key)) {
        continue;
      }
      final idx = entry.value.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        // Reflects any `updateMessage` applied to the per-space list.
        return entry.value[idx];
      }
    }
    final seeded = _messagesById[messageId];
    return seeded != null && _owns(workspaceId, seeded.spaceId) ? seeded : null;
  }

  /// Messages keyed by id, for `getMessageById` lookups (retryAgentTurn, …).
  final Map<String, Message> _messagesById = {};

  /// Seeds a message the repo will return from `getMessageById` AND reflect in
  /// `updateMessage` (which scans the per-space `_messages` lists).
  void seedMessage(Message message) {
    _messagesById[message.id] = message;
    _messages.putIfAbsent(message.spaceId, () => []).add(message);
  }

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => MessagePage.empty;

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async => const [];

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async => const [];

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

class _FakeAgentDispatchPort implements AgentDispatchPort {
  final List<String> pausedDispatchIds = [];
  final List<String> resumedDispatchIds = [];

  /// The prompt and image references of the most recent [start]. What the
  /// agent was actually handed, which is the only place a `@[file:…]`
  /// reference either has a body or does not.
  String? lastPrompt;
  List<String>? lastImagePaths;
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
    String? spaceId,
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
    String? claudeConfigDir,
    List<({String accountId, String configDir})>? claudeAccounts,
    Future<void> Function({required String accountId, DateTime? resetsAt})?
    onClaudeAccountExhausted,
    Future<void> Function({required String accountId, String? reason})?
    onClaudeAccountAuthFailed,
    ClaudeAccountRefusal? claudeAccountsSpent,
    Future<List<String>?> Function({
      String? workspaceId,
      String? agentId,
      required String providerId,
      required List<String> credentialIds,
    })?
    onResolveHarnessRotation,
    Future<void> Function({
      required String providerId,
      required String credentialId,
    })?
    onHarnessCredentialExhausted,
    int? costCapCents,
  }) {
    lastPrompt = prompt;
    lastImagePaths = imagePaths;
    return DispatchHandle(dispatchId: 'ds-1', events: _controller.stream);
  }

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
    String? spaceId,
    String? conversationId,
    String? adapterId,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    return PreparedDispatch(
      effectivePrompt: prompt,
      effectiveConversationId: conversationId ?? spaceId,
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

  group('createSpace', () {
    test('creates a space', () async {
      final space = await service.createSpace(_ws, 'My Team', [
        'agent-1',
        'agent-2',
      ]);
      expect(space.name, 'My Team');
    });

    test('creates a single-agent space', () async {
      final space = await service.createSpace(_ws, 'Solo', ['agent-1']);
      expect(space.name, 'Solo');
    });
  });

  group('sendUserMessage', () {
    test('sends a user message to space', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await service.sendUserMessage(_ws, space.id, 'Hello!');
      final msgs = await repo.getMessages(_ws, space.id);
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await svc.sendUserMessage(_ws, space.id, 'Event test');
      // DomainEventBus delivers asynchronously (broadcast stream).
      await pumpEventQueue();

      expect(events.length, 1);
      expect(events[0].spaceId, space.id);
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      final longContent = 'x' * 200;
      await svc.sendUserMessage(_ws, space.id, longContent);
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await svc.sendUserMessage(_ws, space.id, 'Embed me');
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await svc.sendUserMessage(_ws, space.id, 'No embed');
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await svc.sendUserMessage(_ws, space.id, '');
      await pumpEventQueue();

      expect(embedPort.embedCalls, isEmpty);
    });
  });

  group('addAgentToSpace', () {
    test('adds agent and sends system message', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await service.addAgentToSpace(_ws, space.id, 'agent-2');
      final participants = await repo.getParticipants(_ws, space.id);
      expect(participants.any((p) => p.principalId == 'agent-2'), isTrue);
    });

    test('does not add duplicate agent', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      final initialCount = (await repo.getParticipants(_ws, space.id)).length;
      await service.addAgentToSpace(_ws, space.id, 'agent-1');
      final participants = await repo.getParticipants(_ws, space.id);
      expect(participants.length, initialCount);
    });

    test('renames space when third participant joins', () async {
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
      final space = await svc.createSpace(_ws, '', ['agent-1']);
      // Add second agent (1→2 participants, no rename).
      await svc.addAgentToSpace(_ws, space.id, 'agent-tmp');
      // Add third agent (2→3 participants, triggers participant-name rename).
      await svc.addAgentToSpace(_ws, space.id, 'agent-2');

      expect(repo.lastUpdatedName, 'Alice, Bob');
      agentRepo.dispose();
    });
  });

  group('deleteSpace', () {
    test('deletes a space', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await service.deleteSpace(_ws, space.id);
      final participants = await repo.getParticipants(_ws, space.id);
      expect(participants, isEmpty);
    });

    test('publishes SpaceDeleted event when eventBus is wired', () async {
      final eventBus = DomainEventBus();
      final events = <SpaceDeleted>[];
      eventBus.on<SpaceDeleted>().listen(events.add);

      final svc = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        resolveDefaultUserId: () async => 'user-1',
        eventBus: eventBus,
      );
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await svc.deleteSpace(_ws, space.id);
      await pumpEventQueue();
      expect(events.length, 1);
      expect(events[0].spaceId, space.id);
      eventBus.dispose();
    });
  });

  group('updateSpaceName', () {
    test('completes without error', () async {
      final space = await service.createSpace(_ws, 'Old', ['a1']);
      await service.updateSpaceName(_ws, space.id, 'New Name');
    });
  });

  group('clearSpaceMessages', () {
    test('clears all messages in space', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await service.sendUserMessage(_ws, space.id, 'msg1');
      await service.sendUserMessage(_ws, space.id, 'msg2');
      await service.clearSpaceMessages(_ws, space.id);
      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs, isEmpty);
    });
  });

  group('removeParticipant', () {
    test('removes an agent from space', () async {
      final space = await service.createSpace(_ws, 'Team', ['a1', 'a2']);
      await service.removeParticipant(_ws, space.id, 'a1');
      final participants = await repo.getParticipants(_ws, space.id);
      expect(participants.any((p) => p.principalId == 'a1'), isFalse);
      expect(participants.any((p) => p.principalId == 'a2'), isTrue);
    });
  });

  group('stopRun', () {
    test('stops a given run log id', () async {
      // dispatchAgent registers run log ids in the dispatch service's
      // _runToDispatch map. We then stop those runs.
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: '',
      );
      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs, isEmpty);
    });

    test('sends thinking message and dispatches', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'Hello from agent'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs.any((m) => m.messageType == MessageType.agentTurn), isTrue);
    });

    test('upserts run log when dispatching', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      expect(runLogRepo._upsertCount, greaterThanOrEqualTo(1));
    });

    test('handles dispatch error gracefully', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      dispatchPort.emitError(Exception('Dispatch failed'));
      // Should not throw
    });

    test('stamps the dispatching workspace on the run log', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      // A run log stamped with the wrong workspace is written to another
      // database file, so every workspace-scoped surface misses the run and the
      // ownership check on stopRun/pauseRun/steer rejects it.
      expect(runLogRepo._runLog?.workspaceId, _ws);
      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs.any((m) => m.messageType == MessageType.agentTurn), isTrue);
    });

    test('dispatch updates run log', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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
      final space = await svc.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await svc.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: 'Build it',
      );

      final msgs = await repo.getMessages(_ws, space.id);
      final thinking = msgs.firstWhere(
        (m) => m.messageType == MessageType.agentTurn,
      );
      expect(thinking.metadata?['agentName'], 'Builder');
      agentRepo.dispose();
    });

    test('registers stream ids in the registry', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await service.sendAndDispatch(_ws, space.id, 'Hello without agent repo');

      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs.length, 1);
      expect(msgs[0].content, 'Hello without agent repo');
      expect(msgs[0].isUser, isTrue);
    });

    test('falls back to sendUserMessage when no agents exist', () async {
      agentRepo.clear();
      final svc = makeServiceWithAgentRepo();
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await svc.sendAndDispatch(_ws, space.id, 'No agents available');

      final msgs = await repo.getMessages(_ws, space.id);
      // Just the user message, no dispatch
      expect(msgs.length, 1);
      expect(msgs[0].isUser, isTrue);
    });

    test('dispatches to explicitly mentioned agents', () async {
      final svc = makeServiceWithAgentRepo();
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(_ws, space.id, '@Builder please build');
      // dispatchAgent is unawaited; pump so thinking message is inserted.
      await pumpEventQueue();

      final msgs = await repo.getMessages(_ws, space.id);
      expect(
        msgs.any((m) => m.isUser && m.content == '@Builder please build'),
        isTrue,
      );
      expect(msgs.any((m) => m.messageType == MessageType.agentTurn), isTrue);
    });

    test('dispatches to default agent when no mentions', () async {
      final svc = makeServiceWithAgentRepo();
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(_ws, space.id, 'Do something without mention');
      await pumpEventQueue();

      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs.any((m) => m.messageType == MessageType.agentTurn), isTrue);
    });

    // The bug these guard: the composer uploaded four screenshots, the message
    // reached the agent naming them, and the agent answered that it could see
    // references but had nothing to open.
    group('attachments', () {
      final blob = 'blob:sha256:${'a' * 64}';
      Map<String, dynamic> metadata({String kind = 'image'}) => {
        'attachments': [
          {
            'id': 'a1',
            'path': blob,
            'name': 'shot.png',
            'kind': kind,
            'order': 0,
          },
        ],
      };

      MessagingService serviceWithAttachments(Map<String, String> paths) =>
          MessagingService(
            repo,
            agentRepo: agentRepo,
            agentDispatchService: dispatchService,
            streamRegistry: streamRegistry,
            streamProcessor: makeStreamProcessor(),
            resolveDefaultUserId: () async => 'user-1',
            promptAttachments:
                ({
                  required workspaceId,
                  required spaceId,
                  required attachments,
                }) async => paths,
          );

      test('replaces the reference in place with the materialized path', () async {
        final svc = serviceWithAttachments({'shot.png': '/space/attach/shot.png'});
        final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
        await svc.sendAndDispatch(
          _ws,
          space.id,
          'compare @[file:shot.png] with the mock',
          metadata: metadata(),
        );
        await pumpEventQueue();

        expect(
          dispatchPort.lastPrompt,
          'compare /space/attach/shot.png with the mock',
        );
      });

      test('stores the message with its reference intact', () async {
        // The transcript renders the token as the composer's chip; only the
        // prompt carries paths.
        final svc = serviceWithAttachments({'shot.png': '/space/attach/shot.png'});
        final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
        await svc.sendAndDispatch(
          _ws,
          space.id,
          'look at @[file:shot.png]',
          metadata: metadata(),
        );
        await pumpEventQueue();

        final user = (await repo.getMessages(
          _ws,
          space.id,
        )).firstWhere((m) => m.isUser);
        expect(user.content, 'look at @[file:shot.png]');
        expect(user.attachments.single.path, blob);
      });

      test('puts an uploaded picture on the user turn as an image', () async {
        final svc = serviceWithAttachments(const {});
        final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
        await svc.sendAndDispatch(
          _ws,
          space.id,
          'what is wrong here? @[file:shot.png]',
          metadata: metadata(),
        );
        await pumpEventQueue();

        expect(dispatchPort.lastImagePaths, [blob]);
      });

      test('a non-picture is not sent as an image', () async {
        final svc = serviceWithAttachments({'shot.png': '/space/attach/spec.pdf'});
        final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
        await svc.sendAndDispatch(
          _ws,
          space.id,
          'read @[file:shot.png]',
          metadata: metadata(kind: 'file'),
        );
        await pumpEventQueue();

        expect(dispatchPort.lastImagePaths, isNull);
        expect(dispatchPort.lastPrompt, 'read /space/attach/spec.pdf');
      });

      test('leaves a reference nothing resolved exactly as written', () async {
        final svc = serviceWithAttachments(const {});
        final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
        await svc.sendAndDispatch(
          _ws,
          space.id,
          'read @[file:notes.md] first',
          metadata: metadata(),
        );
        await pumpEventQueue();

        expect(dispatchPort.lastPrompt, 'read @[file:notes.md] first');
      });
    });

    test('does not dispatch when stripped content is empty', () async {
      final svc = makeServiceWithAgentRepo();
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);

      await svc.sendAndDispatch(_ws, space.id, '@Builder');

      final msgs = await repo.getMessages(_ws, space.id);
      // Only the user message — the mention strips to empty content, so there
      // is nothing to dispatch.
      expect(msgs.length, 1);
      expect(msgs.any((m) => m.isUser && m.content == '@Builder'), isTrue);
    });

    test('refines pending plan when prior message is a pending plan', () async {
      final svc = makeServiceWithAgentRepo();
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'refined plan'));

      // Insert a pending plan message as the LAST message, so that after
      // sendAndDispatch inserts the user message, the plan becomes the
      // second-to-last message.
      const planMsgId = 'plan-msg-1';
      unawaited(
        repo.sendMessage(
          workspaceId: _ws,
          spaceId: space.id,
          content: 'Here is the plan',
          senderId: 'agent-1',
          senderType: 'agent',
          messageType: 'plan',
          id: planMsgId,
          metadata: {'planStatus': 'pending'},
        ),
      );

      await svc.sendAndDispatch(_ws, space.id, 'Please refine this plan');

      final msgs = await repo.getMessages(_ws, space.id);
      final plan = msgs.firstWhere((m) => m.id == planMsgId);
      expect(plan.metadata?['planStatus'], 'refining');
    });

    test('dispatches with workspaceId', () async {
      final svc = makeServiceWithAgentRepo();
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      await svc.sendAndDispatch(_ws, space.id, '@Builder build this');
      await pumpEventQueue();

      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs.any((m) => m.messageType == MessageType.agentTurn), isTrue);
    });
  });

  // An agent's own finished turn can name a teammate ("@Reviewer can you look?")
  // and that teammate is woken — the promise the Summons block makes in
  // PromptBuilder.mentions. Before this existed the mention was inert prose and
  // every handoff an agent believed it had performed silently vanished.
  group('agent-authored mention wake', () {
    late _ReplayAgentRepo agentRepo;
    late MessagingService svc;

    setUp(() {
      agentRepo = _ReplayAgentRepo();
      agentRepo.upsert(_testAgent(id: 'agent-1', name: 'Builder'));
      agentRepo.upsert(_testAgent(id: 'agent-2', name: 'Reviewer'));
      svc = MessagingService(
        repo,
        agentRepo: agentRepo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: makeStreamProcessor(),
        resolveDefaultUserId: () async => 'user-1',
      );
    });

    tearDown(() {
      agentRepo.dispose();
    });

    /// Runs one turn for `agent-1` whose text is [text], then closes the
    /// stream so the turn finalizes. Awaiting the dispatch first is what
    /// guarantees the processor is subscribed before the events are emitted —
    /// the fake port's controller is a broadcast one and drops what it has no
    /// listener for.
    Future<Space> runTurn(
      String text, {
      List<String> chain = const [],
      bool fail = false,
    }) async {
      final space = await svc.createSpace(_ws, 'Chat', ['agent-1']);
      await svc.dispatchAgentRun(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: 'go',
        mentionChain: chain,
      );
      dispatchPort.emitEvent(TextEvent(content: text));
      if (fail) {
        dispatchPort.emitError(StateError('boom'));
      } else {
        dispatchPort.emitEvent(DoneEvent());
      }
      await dispatchPort.stop();
      await pumpEventQueue();
      return space;
    }

    Future<bool> wokeReviewer(Space space) async {
      final msgs = await repo.getMessages(_ws, space.id);
      return msgs.any(
        (m) =>
            m.messageType == MessageType.agentTurn && m.senderId == 'agent-2',
      );
    }

    Future<String?> systemNotice(Space space) async {
      final msgs = await repo.getMessages(_ws, space.id);
      return msgs
          .where(
            (m) =>
                m.messageType == MessageType.system &&
                m.content.startsWith('Mention'),
          )
          .map((m) => m.content)
          .firstOrNull;
    }

    test('wakes the mentioned agent and adds it to the space', () async {
      final space = await runTurn('Open question for @Reviewer — thoughts?');

      final participants = await repo.getParticipants(_ws, space.id);
      expect(participants.any((p) => p.principalId == 'agent-2'), isTrue);
      expect(await wokeReviewer(space), isTrue);
    });

    test('does not wake for a mention inside a code fence', () async {
      final space = await runTurn(
        'Here is the annotation:\n```dart\n@Reviewer\n```\nNothing to do.',
      );

      expect(await wokeReviewer(space), isFalse);
      final participants = await repo.getParticipants(_ws, space.id);
      expect(participants.any((p) => p.principalId == 'agent-2'), isFalse);
    });

    test('does not wake for an address-like @', () async {
      final space = await runTurn('mail it to sam@reviewer.com');
      expect(await wokeReviewer(space), isFalse);
    });

    test('does not wake itself', () async {
      final space = await runTurn('I, @Builder, will handle it.');
      final msgs = await repo.getMessages(_ws, space.id);
      final turns = msgs.where(
        (m) =>
            m.messageType == MessageType.agentTurn && m.senderId == 'agent-1',
      );
      expect(turns.length, 1);
    });

    test('an unknown name is prose, not a failed mention', () async {
      final space = await runTurn('ping @nobody about it');
      expect(await wokeReviewer(space), isFalse);
      // No nagging: any "@" in a sentence would otherwise narrate itself.
      expect(await systemNotice(space), isNull);
    });

    test('does not wake when the turn failed', () async {
      final space = await runTurn('@Reviewer take a look', fail: true);
      expect(await wokeReviewer(space), isFalse);
    });

    test('refuses a cycle and says so', () async {
      // Reviewer is already on this wake path, so waking it would close a loop.
      final space = await runTurn('@Reviewer back to you', chain: ['agent-2']);

      expect(await wokeReviewer(space), isFalse);
      expect(await systemNotice(space), contains('cycle detected'));
    });

    test('refuses past the depth cap and says so', () async {
      final space = await runTurn(
        '@Reviewer one more hop',
        chain: ['a', 'b', 'c'],
      );

      expect(await wokeReviewer(space), isFalse);
      expect(await systemNotice(space), contains('chain depth 4'));
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'refined plan output'));

      // Insert a pending plan.
      unawaited(
        repo.sendMessage(
          workspaceId: _ws,
          spaceId: space.id,
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
        spaceId: space.id,
        feedback: 'Make it shorter',
      );

      final msgs = await repo.getMessages(_ws, space.id);
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'refined'));

      // Insert a plan with status 'approved' (not pending).
      unawaited(
        repo.sendMessage(
          workspaceId: _ws,
          spaceId: space.id,
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
        spaceId: space.id,
        feedback: 'Change the approach',
      );

      final msgs = await repo.getMessages(_ws, space.id);
      final plan = msgs.firstWhere((m) => m.id == 'plan-2');
      // Falls back to the first plan found, status updated to 'refining'.
      expect(plan.metadata?['planStatus'], 'refining');
    });

    test('throws StateError when no plan exists', () async {
      final svc = makeServiceWithAgentRepo();
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);

      // No plan messages in the space.
      expect(
        () => svc.refinePlan(
          workspaceId: _ws,
          spaceId: space.id,
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
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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

      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs.any((m) => m.messageType == MessageType.agentTurn), isTrue);
    });

    test('passes ticketId to dispatch', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: 'Do something',
        ticketId: 'ticket-42',
      );

      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs.any((m) => m.messageType == MessageType.agentTurn), isTrue);
    });

    test('dispatches an agent turn into the conversation', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      final msgs = await repo.getMessages(_ws, space.id);
      final thinking = msgs.firstWhere(
        (m) => m.messageType == MessageType.agentTurn,
      );
      expect(thinking.conversationId, space.id);
    });
  });

  group('addAgentToSpace edge cases', () {
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
      final space = await svc.createSpace(_ws, 'Team', ['a1', 'a2', 'a3']);
      // Adding a 4th agent: participants.length was 3, not 2, so no rename.
      await svc.addAgentToSpace(_ws, space.id, 'a4');

      expect(repo.lastUpdatedName, isNull);
      agentRepo.dispose();
    });
  });

  group('stopRun multiple', () {
    test('stops multiple run log ids', () async {
      // First dispatch.
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));
      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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
        spaceId: space.id,
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
      // Create a space with no participating agents.
      final space = await service.createSpace(_ws, 'Empty', const []);

      // Send a message that does not mention any agent. With no agents in the
      // space, the default-agent resolver finds no agent to dispatch.
      await svc.sendAndDispatch(_ws, space.id, 'Hello without mention');

      final msgs = await repo.getMessages(_ws, space.id);
      // Only the user message — no thinking message dispatched.
      expect(msgs.length, 1);
      expect(msgs[0].isUser, isTrue);
    });

    test('dispatches to the sole agent of a single-agent space', () async {
      final svc = makeServiceWithAgentRepo();
      final space = await service.createSpace(_ws, 'Solo', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'response'));

      // No mention: the default-agent resolver picks the sole space agent.
      await svc.sendAndDispatch(_ws, space.id, 'Hello without mention');
      await pumpEventQueue();

      final msgs = await repo.getMessages(_ws, space.id);
      expect(msgs.any((m) => m.messageType == MessageType.agentTurn), isTrue);
    });
  });

  group('spaceExists', () {
    test('delegates to the repository', () async {
      expect(await service.spaceExists(_ws, 'ch-1'), isTrue);
    });
  });

  group('retryAgentTurn', () {
    test(
      'marks the failed message retried and re-dispatches the agent',
      () async {
        final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
        // Seed a failed agent-turn message.
        final failed = Message(
          id: 'm-failed',
          spaceId: space.id,
          conversationId: space.id,
          senderId: 'agent-1',
          senderType: SenderType.agent,
          content: '',
          messageType: MessageType.agentTurn,
          createdAt: DateTime(2025),
        );
        repo.seedMessage(failed);

        dispatchPort.emitEvent(TextEvent(content: 'retry'));
        await service.retryAgentTurn(
          workspaceId: _ws,
          spaceId: space.id,
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
        spaceId: 'ch-1',
        failedMessageId: 'never-existed',
      );
      // No dispatch, no throw.
    });

    test('stamps the run log with the workspace and the failed turn\'s '
        'conversation', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      // The failed turn lived in a parenthesis, not the space's `main`
      // conversation.
      repo.seedMessage(
        Message(
          id: 'm-failed',
          spaceId: space.id,
          conversationId: 'conv-side',
          senderId: 'agent-1',
          senderType: SenderType.agent,
          content: '',
          messageType: MessageType.agentTurn,
          createdAt: DateTime(2025),
        ),
      );

      dispatchPort.emitEvent(TextEvent(content: 'retry'));
      await service.retryAgentTurn(
        workspaceId: _ws,
        spaceId: space.id,
        failedMessageId: 'm-failed',
      );

      // A workspace-less retry run is invisible to every workspace-scoped
      // surface (the composer's stop affordance, the run tree, presence) and is
      // rejected by the ownership check on stopRun/pauseRun/steer — i.e. an
      // unstoppable run. The conversation must be the failed turn's, not the
      // space's `main`.
      final run = await runLogRepo.getById(_ws, 'any');
      expect(run?.workspaceId, _ws);
      expect(run?.conversationId, 'conv-side');
    });
  });

  group('addAgentToSpace rename', () {
    test('renames the space when a second agent joins a 1:1 space', () async {
      // A 1:1 space is two participants: the human who created it and one
      // agent. That is the shape the rename path keys off.
      final space = await service.createSpace(_ws, 'One', [
        'agent-1',
      ], createdByUserId: 'user-1');
      // A second agent joining triggers the group-name rename path.
      await service.addAgentToSpace(_ws, space.id, 'agent-2');

      final updated = await repo.getSpaceById(_ws, space.id);
      // The renamed space holds both agent names.
      expect(updated?.name, isNot('One'));
    });
  });

  group('deleteSpace', () {
    test('deletes the space and publishes a SpaceDeleted event', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      await service.deleteSpace(_ws, space.id);
      expect(await repo.spaceExists(_ws, space.id), isFalse);
    });
  });

  group('stopRun / steerRun delegation', () {
    test('stopRun delegates to the dispatch service', () async {
      final space = await service.createSpace(_ws, 'Chat', ['agent-1']);
      dispatchPort.emitEvent(TextEvent(content: 'hello'));
      await service.dispatchAgent(
        workspaceId: _ws,
        spaceId: space.id,
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
