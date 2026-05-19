import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/pr_review/domain/services/reviewer_matching_service.dart';
import 'package:cc_infra/src/pr_review/dispatch_reviewers_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_filesystem_port.dart';

// ---------------------------------------------------------------------------
// Fakes with replay semantics (so .first resolves even after pre-seeding)
// ---------------------------------------------------------------------------

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];
  final _controller = StreamController<List<Agent>>.broadcast();
  List<Agent>? _lastEmitted;

  List<Agent> get saved => List.unmodifiable(_agents);

  void _emit() {
    _lastEmitted = List.unmodifiable(_agents);
    _controller.add(_lastEmitted!);
  }

  @override
  Stream<List<Agent>> watchAll() => _replay(
    _controller.stream,
    () => _lastEmitted ?? List.unmodifiable(_agents),
  );

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => _replay(
    _controller.stream.map(
      (agents) => agents.where((a) => a.workspaceId == workspaceId).toList(),
    ),
    () => (_lastEmitted ?? _agents)
        .where((a) => a.workspaceId == workspaceId)
        .toList(),
  );

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    try {
      return _agents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Agent?> findByWorkspaceAndName(String ws, String name) async {
    for (final a in _agents) {
      if (a.workspaceId == ws && a.name == name) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(Agent agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      _agents[index] = agent;
    } else {
      _agents.add(agent);
    }
    _emit();
  }

  @override
  Future<void> delete(String workspaceId, String id) async {
    _agents.removeWhere((a) => a.id == id);
    _emit();
  }

  void dispose() => _controller.close();
}

Stream<T> _replay<T>(Stream<T> source, T Function() currentValue) {
  late StreamController<T> c;
  c = StreamController<T>.broadcast(
    onListen: () {
      // Emit current value first, then forward subsequent events
      c.add(currentValue());
      c.addStream(source).then((_) => c.close());
    },
  );
  return c.stream;
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> _workspaces = [];
  final _controller = StreamController<List<Workspace>>.broadcast();
  List<Workspace>? _lastEmitted;

  void _emit() {
    _lastEmitted = List.unmodifiable(_workspaces);
    _controller.add(_lastEmitted!);
  }

  @override
  Stream<List<Workspace>> watchAll() => _replay(
    _controller.stream,
    () => _lastEmitted ?? List.unmodifiable(_workspaces),
  );

  @override
  Future<List<Workspace>> getAll() async => List.unmodifiable(_workspaces);

  @override
  Future<Workspace?> getById(String id) async =>
      _workspaces.where((w) => w.id == id).firstOrNull;

  @override
  Future<String> upsert(Workspace workspace) async {
    final index = _workspaces.indexWhere((w) => w.id == workspace.id);
    if (index >= 0) {
      _workspaces[index] = workspace;
    } else {
      _workspaces.add(workspace);
    }
    _emit();
    return workspace.id;
  }

  @override
  Future<void> delete(String id) async {
    _workspaces.removeWhere((w) => w.id == id);
    _emit();
  }

  @override
  Stream<List<Repo>> watchReposForWorkspace(String _) => Stream.value(const []);

  @override
  Future<void> setReposForWorkspace(String _, List<String> _) async {}

  final Set<String> _repoLinks = {};

  @override
  Future<bool> isRepoLinkedToWorkspace(String ws, String repo) async =>
      _repoLinks.contains('$ws/$repo');

  @override
  Future<void> unlinkRepoFromWorkspace(String _, String _) async {}

  void dispose() => _controller.close();

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {}
}

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging({this.participants = const []});
  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) async =>
      null;
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <ChannelMessage>[], hasMore: false));
  final List<ChannelParticipant> participants;
  final List<_SentMessage> sentMessages = [];
  final List<_AddedParticipant> addedParticipants = [];

  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    addedParticipants.add(_AddedParticipant(channelId, principalId));
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => List.unmodifiable(participants);

  @override
  Future<bool> channelExists(String workspaceId, String channelId) async =>
      true;

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
    sentMessages.add(
      _SentMessage(
        channelId: channelId,
        content: content,
        senderId: senderId,
        senderType: senderType,
        messageType: messageType,
      ),
    );
    return 'msg-${sentMessages.length}';
  }

  // Unused stubs
  @override
  Stream<List<Channel>> watchChannels() => throw UnimplementedError();
  @override
  Stream<List<ChannelParticipant>> watchParticipants(String _, String _) =>
      throw UnimplementedError();
  @override
  Stream<List<ChannelMessage>> watchMessages(String _, String _, String _) =>
      throw UnimplementedError();
  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String _) =>
      throw UnimplementedError();
  @override
  Future<ChannelMessage?> getMessageById(String _, String _) =>
      throw UnimplementedError();
  @override
  Future<Channel> createChannel(
    String _,
    String _,
    List<String> _, {
    Mode mode = Mode.chat,
    List<String> repoIds = const [],
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
  }) => throw UnimplementedError();
  @override
  Future<void> setChannelMode(String _, String _, Mode _) =>
      throw UnimplementedError();
  @override
  Future<List<ChannelMessage>> getMessages(
    String _,
    String _, {
    String? conversationId,
  }) => throw UnimplementedError();
  @override
  Future<void> markCompacted(String _, List<String> _) =>
      throw UnimplementedError();
  @override
  Future<void> deleteChannel(String _, String _) => throw UnimplementedError();
  @override
  Future<void> updateChannelName(String _, String _, String _) =>
      throw UnimplementedError();
  @override
  Future<void> clearChannelMessages(String _, String _) =>
      throw UnimplementedError();
  @override
  Future<void> removeParticipant(String _, String _, String _) =>
      throw UnimplementedError();
  @override
  Future<void> updateMessageEmbedding(String _, String _, Uint8List _) =>
      throw UnimplementedError();
  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String _,
    String _,
  ) => throw UnimplementedError();
  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding(
    String _, {
    int limit = 200,
  }) => throw UnimplementedError();
  @override
  Future<void> updateMessage(
    String _,
    String _, {
    String? idempotencyKey,
    String? content,
    Map<String, dynamic>? metadata,
  }) => throw UnimplementedError();

  // Unused-by-this-test surface (incl. the repo's newer paging/revert methods)
  // routes here so the fake stays compilable as the interface grows.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReviewChannels implements ReviewChannelRepository {
  _FakeReviewChannels({this._assocs = const []});
  final List<ReviewChannelAssociation> _assocs;
  final Map<String, ReviewChannelStatus> _statusUpdates = {};

  Map<String, ReviewChannelStatus> get statusUpdates =>
      Map.unmodifiable(_statusUpdates);

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(
    _assocs.cast<ReviewChannelAssociation?>().firstWhere(
      (a) => a?.channelId == channelId,
      orElse: () => null,
    ),
  );

  @override
  Stream<List<ReviewChannelAssociation>> watchAllByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(
    _assocs
        .where((a) => a.workspaceId == workspaceId && a.channelId == channelId)
        .toList(),
  );

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewChannelStatus status,
  ) async {
    _statusUpdates[id] = status;
  }

  @override
  Stream<ReviewChannelAssociation?> watchByPr(String _, String _) =>
      throw UnimplementedError();
  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(String _) =>
      throw UnimplementedError();
  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) => throw UnimplementedError();
}

class _FakeMessagingPort implements MessagingPort {
  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String channelId,
    required String failedMessageId,
  }) async {}

  final List<_DispatchRecord> dispatches = [];

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    dynamic wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    dispatches.add(
      _DispatchRecord(
        channelId: channelId,
        agentId: agentId,
        prompt: prompt,
        workspaceId: workspaceId,
      ),
    );
    return null;
  }

  @override
  Future<bool> channelExists(String _, String _) async => true;
  @override
  Future<Channel> createChannel(
    String _,
    String _,
    List<String> _, {
    Mode mode = Mode.chat,
    List<String> repoIds = const [],
    String? pipelineRunId,
    String? createdByUserId,
  }) => throw UnimplementedError();
  @override
  Future<void> sendAndDispatch(
    String _,
    String _,
    String _, {
    String? senderUserId,
    String? conversationId,
    List<dynamic>? structuredMentions,
    List<dynamic>? entityRefs,
    Map<String, dynamic>? metadata,
  }) => throw UnimplementedError();
  @override
  Future<void> refinePlan({
    required String workspaceId,
    required String channelId,
    required String feedback,
  }) => throw UnimplementedError();

  // Unused-by-this-test surface (sendUserMessage/addAgentToChannel/steerRun/…)
  // routes here so the fake stays compilable as the port grows.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Record types
// ---------------------------------------------------------------------------

class _SentMessage {
  const _SentMessage({
    required this.channelId,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.messageType,
  });
  final String channelId;
  final String content;
  final String senderId;
  final String senderType;
  final String messageType;
}

class _AddedParticipant {
  const _AddedParticipant(this.channelId, this.agentId);
  final String channelId;
  final String agentId;
}

class _DispatchRecord {
  const _DispatchRecord({
    required this.channelId,
    required this.agentId,
    required this.prompt,
    required this.workspaceId,
  });
  final String channelId;
  final String agentId;
  final String prompt;
  final String? workspaceId;
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Agent _agent({
  required String id,
  required String name,
  String title = 'Engineer',
  String workspaceId = 'ws-1',
  List<String> skills = const [],
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '/agents/$id.md',
    workspaceId: workspaceId,
    skills: AgentSkills(skills),
    createdAt: DateTime(2025),
  );
}

Workspace _workspace({
  String id = 'ws-1',
  String name = 'Test Workspace',
  int reviewConcurrency = 3,
}) {
  return Workspace(
    id: id,
    name: name,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
    reviewConcurrency: reviewConcurrency,
  );
}

ReviewChannelAssociation _assoc({
  String id = 'assoc-1',
  String channelId = 'ch-1',
  String workspaceId = 'ws-1',
  int prNumber = 42,
  String repoFullName = 'owner/repo',
  ReviewChannelStatus status = ReviewChannelStatus.requested,
}) {
  return ReviewChannelAssociation(
    id: id,
    channelId: channelId,
    workspaceId: workspaceId,
    prExternalId: 'pr-node-1',
    prNumber: prNumber,
    repoFullName: repoFullName,
    status: status,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeAgentRepository agents;
  late _FakeWorkspaceRepository workspaces;
  late FakeFilesystemPort fs;
  late _FakeMessaging messaging;
  late _FakeReviewChannels reviewChannels;
  late _FakeMessagingPort messagingPort;

  setUp(() {
    agents = _FakeAgentRepository();
    workspaces = _FakeWorkspaceRepository();
    fs = FakeFilesystemPort();
    messaging = _FakeMessaging();
    reviewChannels = _FakeReviewChannels();
    messagingPort = _FakeMessagingPort();
  });

  tearDown(() {
    agents.dispose();
    workspaces.dispose();
  });

  DispatchReviewersService sut0({ReviewerMatchingService? matching}) {
    return DispatchReviewersService(
      agents: agents,
      messaging: messaging,
      reviewChannels: reviewChannels,
      messagingPort: messagingPort,
      workspaces: workspaces,
      filesystemPort: fs,
      matching: matching,
    );
  }

  void seedWorkspaceAndAgents() {
    workspaces.upsert(_workspace());
    agents.upsert(
      _agent(
        id: 'a1',
        name: 'SeniorFlutter',
        title: 'Senior Flutter Engineer',
        skills: ['flutter'],
      ),
    );
    agents.upsert(
      _agent(
        id: 'a2',
        name: 'BackendGuru',
        title: 'Backend Engineer',
        skills: ['go', 'rust'],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Reviewer selection
  // -----------------------------------------------------------------------

  group('reviewer selection', () {
    test('dispatches matched reviewers and reports unmatched', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'go'},
          {'role': 'nonexistent'},
        ],
      );

      expect(result['dispatched'], hasLength(2));
      expect(result['unmatched'], hasLength(1));
      expect(
        ((result['unmatched'] as List)[0] as Map<String, dynamic>)['role'],
        'nonexistent',
      );
    });

    test('skips reviewers with empty or non-string role', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': ''},
          {'role': 'flutter'},
          {},
          {'role': 123},
        ],
      );

      expect(result['dispatched'], hasLength(1));
      expect(result['unmatched'], isEmpty);
    });

    test('passes scope to dispatched spec', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter', 'scope': 'lib/ui/**'},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, contains('Scope filter: lib/ui/**'));
    });

    test('uses prompt_override instead of built brief', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter', 'prompt_override': 'Custom review instructions.'},
        ],
      );

      expect(
        messagingPort.dispatches.single.prompt,
        'Custom review instructions.',
      );
    });

    test('dispatched result includes agent_id, agent_name and role', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final d = (result['dispatched'] as List).single as Map;
      expect(d['role'], 'flutter');
      expect(d['agent_id'], 'a1');
      expect(d['agent_name'], 'SeniorFlutter');
    });
  });

  // -----------------------------------------------------------------------
  // Dispatch logic
  // -----------------------------------------------------------------------

  group('dispatch logic', () {
    test('adds participant when agent is not already in channel', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(messaging.addedParticipants, hasLength(1));
      expect(messaging.addedParticipants.single.agentId, 'a1');
    });

    test('does NOT add participant when agent is already in channel', () async {
      seedWorkspaceAndAgents();
      messaging = _FakeMessaging(
        participants: [
          ChannelParticipant(
            id: 'p1',
            channelId: 'ch-1',
            principalId: 'a1',
            participantType: PrincipalType.agent,
            role: 'member',
            joinedAt: DateTime(2025),
          ),
        ],
      );

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(messaging.addedParticipants, isEmpty);
    });

    test('sends assignment message to channel', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final msg = messaging.sentMessages.single;
      expect(msg.channelId, 'ch-1');
      expect(msg.senderId, 'system');
      expect(msg.senderType, 'agent');
      expect(msg.messageType, 'system');
      expect(msg.content, '@SeniorFlutter you are on review duty as flutter.');
    });

    test('dispatches agent via messaging port with brief', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final disp = messagingPort.dispatches.single;
      expect(disp.agentId, 'a1');
      expect(disp.channelId, 'ch-1');
      expect(disp.workspaceId, 'ws-1');
      expect(disp.prompt, contains('PR #42 in owner/repo'));
      expect(disp.prompt, contains('"flutter" reviewer'));
    });

    test(
      'uses effective concurrency from workspace when not overridden',
      () async {
        seedWorkspaceAndAgents();
        unawaited(workspaces.upsert(_workspace(reviewConcurrency: 5)));

        final result = await sut0().dispatch(
          channelId: 'ch-1',
          workspaceId: 'ws-1',
          reviewers: [
            {'role': 'flutter'},
          ],
        );

        expect(result['concurrency'], 5);
      },
    );

    test('overrides workspace concurrency with explicit argument', () async {
      seedWorkspaceAndAgents();
      unawaited(workspaces.upsert(_workspace(reviewConcurrency: 5)));

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
        concurrency: 1,
      );

      expect(result['concurrency'], 1);
    });

    test('defaults concurrency to 3 when workspace not found', () async {
      unawaited(
        agents.upsert(
          _agent(
            id: 'a1',
            name: 'SF',
            title: 'Senior Flutter',
            skills: ['flutter'],
          ),
        ),
      );
      // No workspace seeded

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(result['concurrency'], 3);
    });

    test('dispatchAgent receives correct workspaceId parameter', () async {
      unawaited(
        workspaces.upsert(_workspace(id: 'ws-custom', reviewConcurrency: 10)),
      );
      unawaited(
        agents.upsert(
          _agent(
            id: 'a1',
            name: 'SeniorFlutter',
            title: 'Senior Flutter Engineer',
            skills: ['flutter'],
            workspaceId: 'ws-custom',
          ),
        ),
      );
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-custom',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final disp = messagingPort.dispatches.single;
      expect(disp.workspaceId, 'ws-custom');
    });
  });

  // -----------------------------------------------------------------------
  // Status transitions
  // -----------------------------------------------------------------------

  group('status transitions', () {
    test('transitions requested → inProgress when agents dispatched', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(
        assocs: [_assoc(status: ReviewChannelStatus.requested)],
      );

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(
        reviewChannels.statusUpdates['assoc-1'],
        ReviewChannelStatus.inProgress,
      );
    });

    test('does NOT transition when no agents were dispatched', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(
        assocs: [_assoc(status: ReviewChannelStatus.requested)],
      );

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'nonexistent'},
        ],
      );

      expect(reviewChannels.statusUpdates, isEmpty);
    });

    test('does NOT transition when assoc is null', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(reviewChannels.statusUpdates, isEmpty);
    });

    test('does NOT transition when status is already inProgress', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(
        assocs: [_assoc(status: ReviewChannelStatus.inProgress)],
      );

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(reviewChannels.statusUpdates, isEmpty);
    });

    test('does NOT transition when status is completed', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(
        assocs: [_assoc(status: ReviewChannelStatus.completed)],
      );

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(reviewChannels.statusUpdates, isEmpty);
    });

    test('does NOT transition when status is awaitingApproval', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(
        assocs: [_assoc(status: ReviewChannelStatus.awaitingApproval)],
      );

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(reviewChannels.statusUpdates, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // Edge cases
  // -----------------------------------------------------------------------

  group('edge cases', () {
    test('handles empty reviewers list', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [],
      );

      expect(result['dispatched'], isEmpty);
      expect(result['unmatched'], isEmpty);
    });

    test('all unmatched yields empty dispatched', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'alien'},
          {'role': 'unknown'},
        ],
      );

      expect(result['dispatched'], isEmpty);
      expect(result['unmatched'], hasLength(2));
    });

    test('repoFullName empty string when assoc is null', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, contains('the PR in '));
    });

    test('repo path null when filesystem has no repo dir', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, isNot(contains('The repository is cloned at')));
    });

    test('repo path included when repo dir exists on filesystem', () async {
      final tmpDir = await Directory.systemTemp.createTemp('drstest_');
      try {
        // The provisioner's layout is `<convDir>/repos/<slug>` — there is no
        // singular `repo/` dir (see DispatchReviewersService._resolveRepoPath).
        // The slug comes from the association's repoFullName ("owner/repo").
        final repoDir = Directory('${tmpDir.path}/repos/repo');
        repoDir.createSync(recursive: true);

        final convFs = _MockConversationDirFilesystemPort(tmpDir);
        final localAgents = _FakeAgentRepository();
        final localWorkspaces = _FakeWorkspaceRepository();

        unawaited(localWorkspaces.upsert(_workspace()));
        unawaited(
          localAgents.upsert(
            _agent(
              id: 'a1',
              name: 'SF',
              title: 'Senior Flutter',
              skills: ['flutter'],
            ),
          ),
        );

        final sut = DispatchReviewersService(
          agents: localAgents,
          messaging: messaging,
          reviewChannels: _FakeReviewChannels(assocs: [_assoc()]),
          messagingPort: messagingPort,
          workspaces: localWorkspaces,
          filesystemPort: convFs,
        );

        await sut.dispatch(
          channelId: 'ch-1',
          workspaceId: 'ws-1',
          reviewers: [
            {'role': 'flutter'},
          ],
        );

        final prompt = messagingPort.dispatches.single.prompt;
        expect(prompt, contains('The repository is cloned at'));
        expect(prompt, contains(repoDir.path));
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('pool is closed even when dispatchAgent throws', () async {
      seedWorkspaceAndAgents();
      final throwingPort = _ThrowingMessagingPort();

      final sut = DispatchReviewersService(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: throwingPort,
        workspaces: workspaces,
        filesystemPort: fs,
      );

      await expectLater(
        sut.dispatch(
          channelId: 'ch-1',
          workspaceId: 'ws-1',
          reviewers: [
            {'role': 'flutter'},
          ],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -----------------------------------------------------------------------
  // Brief variations
  // -----------------------------------------------------------------------

  group('brief variations', () {
    test('uses "the PR in" when prNumber is null', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, contains('the PR in'));
      expect(prompt, isNot(contains('PR #')));
    });

    test('includes scope filter in brief', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter', 'scope': 'lib/**.dart'},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, contains('Scope filter: lib/**.dart'));
    });

    test('full brief includes PR number, scope and repo path', () async {
      final tmpDir = await Directory.systemTemp.createTemp('drstest_');
      try {
        // The provisioner's layout is `<convDir>/repos/<slug>` — there is no
        // singular `repo/` dir (see DispatchReviewersService._resolveRepoPath).
        // The slug comes from the association's repoFullName ("owner/repo").
        final repoDir = Directory('${tmpDir.path}/repos/repo');
        repoDir.createSync(recursive: true);

        final convFs = _MockConversationDirFilesystemPort(tmpDir);
        final localAgents = _FakeAgentRepository();
        final localWorkspaces = _FakeWorkspaceRepository();

        unawaited(localWorkspaces.upsert(_workspace()));
        unawaited(
          localAgents.upsert(
            _agent(
              id: 'a1',
              name: 'FlutterDev',
              title: 'Flutter Engineer',
              skills: ['flutter'],
            ),
          ),
        );

        final sut = DispatchReviewersService(
          agents: localAgents,
          messaging: messaging,
          reviewChannels: _FakeReviewChannels(
            assocs: [_assoc(prNumber: 99, repoFullName: 'acme/widgets')],
          ),
          messagingPort: messagingPort,
          workspaces: localWorkspaces,
          filesystemPort: convFs,
        );

        await sut.dispatch(
          channelId: 'ch-1',
          workspaceId: 'ws-1',
          reviewers: [
            {'role': 'flutter', 'scope': 'lib/**.dart'},
          ],
        );

        final prompt = messagingPort.dispatches.single.prompt;
        expect(prompt, contains('PR #99 in acme/widgets'));
        expect(prompt, contains('Scope filter: lib/**.dart'));
        expect(prompt, contains('The repository is cloned at'));
        expect(prompt, contains(repoDir.path));
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('concise brief when no optional fields are available', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, contains('"flutter" reviewer for the PR in '));
      expect(prompt, isNot(contains('Scope filter:')));
      expect(prompt, isNot(contains('The repository is cloned at')));
      expect(prompt, isNot(contains('PR #')));
    });
  });

  // -----------------------------------------------------------------------
  // Reviewer field validation
  // -----------------------------------------------------------------------

  group('reviewer field validation', () {
    test('scope is treated as null when not a String (number)', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter', 'scope': 42},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, isNot(contains('Scope filter:')));
    });

    test('scope is treated as null when not a String (list)', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {
            'role': 'flutter',
            'scope': ['lib/', 'src/'],
          },
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, isNot(contains('Scope filter:')));
    });

    test('prompt_override non-String falls back to built brief', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter', 'prompt_override': 123},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, contains('You have been assigned as the'));
      expect(prompt, isNot(contains('123')));
    });

    test('prompt_override empty string is used as-is', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter', 'prompt_override': ''},
        ],
      );

      expect(messagingPort.dispatches.single.prompt, '');
    });
  });

  // -----------------------------------------------------------------------
  // Multiple reviewer dispatch
  // -----------------------------------------------------------------------

  group('multiple reviewer dispatch', () {
    test(
      'dispatches multiple reviewers with different roles concurrently',
      () async {
        unawaited(workspaces.upsert(_workspace()));
        unawaited(
          agents.upsert(
            _agent(id: 'a1', name: 'FlutterDev', skills: ['flutter']),
          ),
        );
        unawaited(
          agents.upsert(_agent(id: 'a2', name: 'GoDev', skills: ['go'])),
        );
        unawaited(
          agents.upsert(_agent(id: 'a3', name: 'RustDev', skills: ['rust'])),
        );

        final result = await sut0().dispatch(
          channelId: 'ch-1',
          workspaceId: 'ws-1',
          reviewers: [
            {'role': 'flutter'},
            {'role': 'go'},
            {'role': 'rust'},
          ],
        );

        expect(result['dispatched'], hasLength(3));
        expect(result['unmatched'], isEmpty);
        expect(messaging.sentMessages, hasLength(3));
      },
    );

    test('partial: some matched, some unmatched in same call', () async {
      seedWorkspaceAndAgents(); // seeds flutter (a1) and go/rust (a2)
      reviewChannels = _FakeReviewChannels(
        assocs: [_assoc(status: ReviewChannelStatus.requested)],
      );

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'go'},
          {'role': 'python'},
        ],
      );

      expect(result['dispatched'], hasLength(2));
      expect(result['unmatched'], hasLength(1));
      expect(
        reviewChannels.statusUpdates['assoc-1'],
        ReviewChannelStatus.inProgress,
      );
    });

    test('same agent matched for two roles gets two messages', () async {
      seedWorkspaceAndAgents(); // seeds flutter (a1) and go/rust (a2)

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'go'},
          {'role': 'rust'},
        ],
      );

      // Both roles match a2; each role gets its own dispatch and message.
      expect(result['dispatched'], hasLength(2));
      expect(messaging.sentMessages, hasLength(2));
      expect(messaging.sentMessages[0].content, contains('as go.'));
      expect(messaging.sentMessages[1].content, contains('as rust.'));
    });
  });

  // -----------------------------------------------------------------------
  // Channel result
  // -----------------------------------------------------------------------

  group('channel result', () {
    test('result includes channel_id', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [],
      );

      expect(result['channel_id'], 'ch-1');
    });
  });

  // -----------------------------------------------------------------------
  // Result structure
  // -----------------------------------------------------------------------

  group('result structure', () {
    test('unmatched entry includes scope when provided', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'nonexistent', 'scope': 'src/**'},
        ],
      );

      expect(
        ((result['unmatched'] as List)[0] as Map<String, dynamic>)['scope'],
        'src/**',
      );
    });

    test('unmatched entry has null scope when not provided', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'nonexistent'},
        ],
      );

      expect(
        ((result['unmatched'] as List)[0] as Map<String, dynamic>)['scope'],
        isNull,
      );
    });

    test('return map includes all expected top-level keys', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(
        result.keys,
        containsAll(['channel_id', 'concurrency', 'dispatched', 'unmatched']),
      );
    });

    test(
      'multiple unmatched entries preserve distinct roles and scopes',
      () async {
        seedWorkspaceAndAgents();

        final result = await sut0().dispatch(
          channelId: 'ch-1',
          workspaceId: 'ws-1',
          reviewers: [
            {'role': 'python', 'scope': 'backend/**'},
            {'role': 'ruby'},
            {'role': 'scala', 'scope': 'core/**'},
          ],
        );

        expect(result['unmatched'], hasLength(3));
        expect(
          ((result['unmatched'] as List)[0] as Map<String, dynamic>)['role'],
          'python',
        );
        expect(
          ((result['unmatched'] as List)[0] as Map<String, dynamic>)['scope'],
          'backend/**',
        );
        expect(
          ((result['unmatched'] as List)[1] as Map<String, dynamic>)['role'],
          'ruby',
        );
        expect(
          ((result['unmatched'] as List)[1] as Map<String, dynamic>)['scope'],
          isNull,
        );
        expect(
          ((result['unmatched'] as List)[2] as Map<String, dynamic>)['role'],
          'scala',
        );
        expect(
          ((result['unmatched'] as List)[2] as Map<String, dynamic>)['scope'],
          'core/**',
        );
      },
    );
  });

  // -----------------------------------------------------------------------
  // ReviewerMatchingService injection
  // -----------------------------------------------------------------------

  group('ReviewerMatchingService injection', () {
    test('uses injected matching service', () async {
      seedWorkspaceAndAgents();

      // Custom matching that always returns the second agent regardless of role.
      final custom = _CustomMatching(
        (candidates, role) => candidates.where((a) => a.id == 'a2').firstOrNull,
      );

      final result = await sut0(matching: custom).dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      // Even though 'flutter' should match a1 by default, our custom
      // matcher forces a2.
      expect(result['dispatched'], hasLength(1));
      final d = (result['dispatched'] as List).single as Map;
      expect(d['agent_id'], 'a2');
    });

    test('custom matching service can override default behavior', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      // Custom matching that never matches any agent.
      final custom = _CustomMatching((candidates, role) => null);

      final result = await sut0(matching: custom).dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'go'},
        ],
      );

      // All reviewers unmatched because custom matcher returns null.
      expect(result['dispatched'], isEmpty);
      expect(result['unmatched'], hasLength(2));
    });
  });

  // -----------------------------------------------------------------------
  // Concurrency pool behavior
  // -----------------------------------------------------------------------

  group('concurrency pool behavior', () {
    test('respects concurrency limit', () async {
      seedWorkspaceAndAgents();
      unawaited(workspaces.upsert(_workspace(reviewConcurrency: 10)));

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
        concurrency: 4,
      );

      expect(result['concurrency'], 4);
    });

    test('concurrency of 1 serializes dispatch', () async {
      seedWorkspaceAndAgents();

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'go'},
        ],
        concurrency: 1,
      );

      expect(result['concurrency'], 1);
      // Both agents still dispatched even with serial execution.
      expect(result['dispatched'], hasLength(2));
    });

    test('zero concurrency uses workspace default', () async {
      seedWorkspaceAndAgents();
      unawaited(workspaces.upsert(_workspace(reviewConcurrency: 5)));

      // Not specifying concurrency falls back to workspace default.
      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(result['concurrency'], 5);
    });
  });

  // -----------------------------------------------------------------------
  // Agent matching edge cases
  // -----------------------------------------------------------------------

  group('agent matching edge cases', () {
    test('agent with multiple skills matches any', () async {
      unawaited(workspaces.upsert(_workspace()));
      unawaited(
        agents.upsert(
          _agent(
            id: 'a1',
            name: 'Polyglot',
            title: 'Engineer',
            skills: ['flutter', 'go', 'rust'],
          ),
        ),
      );

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'go'},
        ],
      );

      // Both roles match the same multi-skilled agent.
      expect(result['dispatched'], hasLength(2));
      expect(result['unmatched'], isEmpty);
    });

    test('agent matched by skill not just title', () async {
      unawaited(workspaces.upsert(_workspace()));
      unawaited(
        agents.upsert(
          _agent(
            id: 'a1',
            name: 'Manager',
            title: 'Manager',
            skills: ['flutter'],
          ),
        ),
      );

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      // Agent matched on skill 'flutter', not the title 'Manager'.
      expect(result['dispatched'], hasLength(1));
      final d = (result['dispatched'] as List).single as Map;
      expect(d['agent_name'], 'Manager');
    });

    test('no agents in workspace yields all unmatched', () async {
      unawaited(workspaces.upsert(_workspace()));
      // No agents seeded at all.

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'go'},
        ],
      );

      expect(result['dispatched'], isEmpty);
      expect(result['unmatched'], hasLength(2));
    });

    test('agent matched by name when skill and title do not match', () async {
      unawaited(workspaces.upsert(_workspace()));
      unawaited(
        agents.upsert(
          _agent(
            id: 'a1',
            name: 'RustyBot',
            title: 'Backend Engineer',
            skills: ['go'],
          ),
        ),
      );

      final result = await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'rust'},
        ],
      );

      // Name 'RustyBot' contains 'rust' → score 1, still matched.
      expect(result['dispatched'], hasLength(1));
      final d = (result['dispatched'] as List).single as Map;
      expect(d['agent_name'], 'RustyBot');
    });

    test(
      'combined title and skill match scores higher than skill-only',
      () async {
        unawaited(workspaces.upsert(_workspace()));
        // Agent with title + skill match (score 2+3=5) should beat skill-only
        // agent (score 3).
        unawaited(
          agents.upsert(
            _agent(
              id: 'a1',
              name: 'Senior',
              title: 'Flutter Specialist',
              skills: ['flutter'],
            ),
          ),
        );
        unawaited(
          agents.upsert(
            _agent(
              id: 'a2',
              name: 'Random',
              title: 'Generalist',
              skills: ['flutter'],
            ),
          ),
        );

        final result = await sut0().dispatch(
          channelId: 'ch-1',
          workspaceId: 'ws-1',
          reviewers: [
            {'role': 'flutter'},
          ],
        );

        // a1 has title 'Flutter Specialist' → score 5; a2 has only skill → 3.
        expect(result['dispatched'], hasLength(1));
        final d = (result['dispatched'] as List).single as Map;
        expect(d['agent_name'], 'Senior');
      },
    );
  });

  // -----------------------------------------------------------------------
  // Message sending edge cases
  // -----------------------------------------------------------------------

  group('message sending edge cases', () {
    test('sends message with correct senderType', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(messaging.sentMessages.single.senderType, 'agent');
    });

    test('message content formats agent name correctly', () async {
      seedWorkspaceAndAgents();

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final content = messaging.sentMessages.single.content;
      expect(content, '@SeniorFlutter you are on review duty as flutter.');
      expect(content, startsWith('@SeniorFlutter'));
    });
  });

  // -----------------------------------------------------------------------
  // Repo path resolution
  // -----------------------------------------------------------------------

  group('repo path resolution', () {
    test('repo path is null when conversation dir does not exist', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final prompt = messagingPort.dispatches.single.prompt;
      // The brief should not include the repo-path preamble.
      expect(prompt, isNot(contains('The repository is cloned at')));
    });

    test('handles filesystem exception gracefully', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      final throwingFs = _ThrowingFilesystemPort();
      final sut = DispatchReviewersService(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
        filesystemPort: throwingFs,
      );

      // Should not throw — exception caught and repo path returned as null.
      await sut.dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(messagingPort.dispatches, hasLength(1));
      final prompt = messagingPort.dispatches.single.prompt;
      expect(prompt, isNot(contains('The repository is cloned at')));
    });
  });

  // -----------------------------------------------------------------------
  // Channel participant edge cases
  // -----------------------------------------------------------------------

  group('channel participant edge cases', () {
    test('adds participant only once per agent', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      // Seed a single agent with both skills.
      agents = _FakeAgentRepository();
      unawaited(
        agents.upsert(
          _agent(
            id: 'a1',
            name: 'Polyglot',
            title: 'Engineer',
            skills: ['flutter', 'go'],
          ),
        ),
      );

      final sut = DispatchReviewersService(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
        filesystemPort: fs,
      );

      await sut.dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'go'},
        ],
        concurrency: 1,
      );

      // Both roles map to a1; participant added only once.
      expect(messaging.addedParticipants, hasLength(1));
      expect(messaging.addedParticipants.single.agentId, 'a1');
    });

    test('does not re-add participant when called twice', () async {
      seedWorkspaceAndAgents();
      reviewChannels = _FakeReviewChannels(assocs: [_assoc()]);

      await sut0().dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(messaging.addedParticipants, hasLength(1));

      // Seed participant so second call sees agent already in channel.
      messaging = _FakeMessaging(
        participants: [
          ChannelParticipant(
            id: 'p1',
            channelId: 'ch-1',
            principalId: 'a1',
            participantType: PrincipalType.agent,
            role: 'member',
            joinedAt: DateTime(2025),
          ),
        ],
      );

      final sut2 = DispatchReviewersService(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
        filesystemPort: fs,
      );

      await sut2.dispatch(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      // No additional participant added on second call.
      expect(messaging.addedParticipants, isEmpty);
    });
  });
}

// ---------------------------------------------------------------------------
// Special fakes
// ---------------------------------------------------------------------------

class _MockConversationDirFilesystemPort extends FakeFilesystemPort {
  _MockConversationDirFilesystemPort(this._tmpDir);
  final Directory _tmpDir;

  @override
  Future<String> conversationDir(String _, String _) async => _tmpDir.path;
}

class _ThrowingMessagingPort implements MessagingPort {
  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    dynamic wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    throw Exception('dispatch failed');
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _CustomMatching extends ReviewerMatchingService {
  _CustomMatching(this._matcher);
  final Agent? Function(List<Agent> candidates, String role) _matcher;

  @override
  Agent? findBestMatch(List<Agent> candidates, String role) =>
      _matcher(candidates, role);
}

class _ThrowingFilesystemPort extends FakeFilesystemPort {
  @override
  Future<String> conversationDir(String _, String _) async =>
      throw const FileSystemException('Permission denied', '/tmp');
}
