import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/consult_agent_tool.dart';
import 'package:test/test.dart';

import 'peer_tool_kit.dart';

/// The kit the current test delivers through.
late PeerKit _kit;

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];

  void add(Agent agent) {
    _agents.add(agent);
    _kit.agents[agent.id] = agent;
  }

  @override
  Stream<List<Agent>> watchAll() => Stream.value(List.unmodifiable(_agents));

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(_agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    try {
      // Scoped, not id-only: an agent id owned by another workspace must not
      // resolve, mirroring the per-workspace database file.
      return _agents.firstWhere(
        (a) => a.id == id && a.workspaceId == workspaceId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    for (final a in _agents) {
      if (a.workspaceId == workspaceId && a.name == name) {
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
  }

  @override
  Future<void> delete(String workspaceId, String id) async {
    _agents.removeWhere((a) => a.id == id && a.workspaceId == workspaceId);
  }
}

class _FakeMessagingRepository implements MessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {}
  @override
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      getMessages(workspaceId, spaceId);

  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => const Stream.empty();

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => null;

  @override
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <Message>[], hasMore: false));

  final Map<String, List<SpaceParticipant>> _participants = {};
  final List<_SentMessage> sent = [];
  int _ids = 0;

  void addParticipantEntry(String spaceId, SpaceParticipant p) {
    (_participants[spaceId] ??= []).add(p);
  }

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async {
    return List.unmodifiable(_participants[spaceId] ?? []);
  }

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    (_participants[spaceId] ??= []).add(
      SpaceParticipant(
        id: '${spaceId}_$principalId',
        spaceId: spaceId,
        principalId: principalId,
        participantType: participantType,
        role: 'member',
        joinedAt: DateTime(2025),
      ),
    );
  }

  bool hasSpace = true;

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      hasSpace;

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
    sent.add(
      _SentMessage(
        spaceId: spaceId,
        content: content,
        senderId: senderId,
        senderType: senderType,
        messageType: messageType,
      ),
    );
    final messageId = 'msg-${++_ids}';
    _kit.conversation('c-$spaceId', spaceId: spaceId, workspaceId: workspaceId);
    _kit.messages[messageId] = Message(
      id: messageId,
      spaceId: spaceId,
      conversationId: 'c-$spaceId',
      senderId: senderId,
      senderType: SenderType.system,
      content: content,
      messageType: MessageType.system,
      createdAt: _kit.now,
    );
    return messageId;
  }

  // Unused stubs
  @override
  Stream<List<Space>> watchSpaces() => const Stream.empty();
  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => const Stream.empty();
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
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => const Stream.empty();
  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      const Stream.empty();
  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      _kit.messages[messageId];
  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => throw UnimplementedError();
  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async => throw UnimplementedError();
  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async => throw UnimplementedError();
  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    dynamic mode,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
  }) async => throw UnimplementedError();
  @override
  Future<void> setSpaceMode(
    String workspaceId,
    String spaceId,
    dynamic mode,
  ) async {}
  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {}
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
  }) async => [];
  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}
  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {}
  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {}
  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) async {}
  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) async {}
  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    dynamic embedding,
  ) async {}
  @override
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) async => [];
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

class _SentMessage {
  const _SentMessage({
    required this.spaceId,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.messageType,
  });
  final String spaceId;
  final String content;
  final String senderId;
  final String senderType;
  final String messageType;
}

/// The runs the wake queue started, with the consultation brief their
/// wake carried.
class _FakeMessagingPort {
  final List<_DispatchCall> dispatched = [];
}

class _DispatchCall {
  const _DispatchCall({
    required this.spaceId,
    required this.agentId,
    required this.prompt,
    required this.workspaceId,
  });
  final String spaceId;
  final String agentId;
  final String prompt;
  final String workspaceId;
}

Agent _createAgent({
  required String id,
  required String name,
  required String title,
  required String workspaceId,
  List<String> skills = const [],
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '$workspaceId/agents/$name/AGENTS.md',
    workspaceId: workspaceId,
    skills: AgentSkills(skills),
    createdAt: DateTime(2025),
  );
}

void main() {
  group('ConsultAgentTool', () {
    late _FakeAgentRepository agents;
    late _FakeMessagingRepository messaging;
    late _FakeMessagingPort messagingPort;
    late ConsultAgentTool tool;

    setUp(() async {
      _kit = PeerKit();
      agents = _FakeAgentRepository();
      messaging = _FakeMessagingRepository();
      messagingPort = _FakeMessagingPort();
      _kit.onDispatch = (run) => messagingPort.dispatched.add(
        _DispatchCall(
          spaceId: run.spaceId,
          agentId: run.agentId,
          prompt: _kit.wakes
              .all(run.workspaceId)
              .lastWhere((w) => w.agentId == run.agentId)
              .payload,
          workspaceId: run.workspaceId,
        ),
      );
      await _kit.start();
      tool = ConsultAgentTool(
        agents: agents,
        messaging: messaging,
        service: _openGate(),
        peerAsks: _kit.service,
        rateLimiter: PairRateLimiter(),
      );
    });

    test(
      'foreign or missing space refuses without posting or dispatching',
      () async {
        messaging.hasSpace = false;
        final result = await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'foreign',
          'topic': 'security',
          'question': 'Check this?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('different workspace'));
        expect(messaging.sent, isEmpty);
      },
    );

    group('definition', () {
      test('has correct name', () {
        expect(tool.name, 'consult_agent');
      });

      test('has non-empty description', () {
        expect(tool.description, isNotEmpty);
      });

      test('has valid inputSchema', () {
        final schema = tool.inputSchema;
        expect(schema['type'], 'object');
        expect(
          schema['required'],
          containsAll(['space_id', 'workspace_id', 'topic', 'question']),
        );
        final props = schema['properties'] as Map<String, dynamic>;
        expect(props['rationale'], isNotNull);
        expect((props['rationale'] as Map<String, dynamic>)['type'], 'string');
      });
    });

    group('arg validation', () {
      test('returns error for missing space_id', () async {
        final result = await tool.call({
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('space_id'));
      });

      test('returns error for space_id of wrong type', () async {
        final result = await tool.call({
          'space_id': 123,
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('space_id'));
      });

      test('returns error for missing workspace_id', () async {
        final result = await tool.call({
          'space_id': 'ch-1',
          'topic': 'security',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('workspace_id'));
      });

      test('returns error for workspace_id of wrong type', () async {
        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': null,
          'topic': 'security',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('workspace_id'));
      });

      test('returns error for missing topic', () async {
        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('topic'));
      });

      test('returns error for topic of wrong type', () async {
        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': true,
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('topic'));
      });

      test('returns error for missing question', () async {
        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('question'));
      });

      test('returns error for question of wrong type', () async {
        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 42,
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('question'));
      });
    });

    group('recipient resolution', () {
      test('requires to_agent_id or to_agent_name', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Security Expert',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Safe?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Missing recipient'));
        expect(messaging.sent, isEmpty);
        expect(messagingPort.dispatched, isEmpty);
      });

      test('the topic never picks the agent', () async {
        agents.add(
          _createAgent(
            id: 'a-skill',
            name: 'sec',
            title: 'Security',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );
        agents.add(
          _createAgent(
            id: 'a-other',
            name: 'writer',
            title: 'Writer',
            workspaceId: 'ws-1',
            skills: ['docs'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-other',
          'topic': 'security',
          'question': 'Safe?',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['consulted_agent_id'], 'a-other');
      });

      test('resolves an exact, unique name', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Security Expert',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_name': 'expert',
          'topic': 'security',
          'question': 'Safe?',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['consulted_agent_id'], 'a-1');
      });

      test('an unknown name is rejected with the candidates', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Security Expert',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_name': 'exp',
          'topic': 'security',
          'question': 'Safe?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('No agent named "exp"'));
        expect(result.content.first.text, contains('expert'));
        expect(messagingPort.dispatched, isEmpty);
      });

      test('an ambiguous name is rejected with candidate ids', () async {
        for (final id in ['a-1', 'a-2']) {
          agents.add(
            _createAgent(
              id: id,
              name: 'expert',
              title: 'Expert',
              workspaceId: 'ws-1',
              skills: const [],
            ),
          );
        }

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_name': 'expert',
          'topic': 'security',
          'question': 'Safe?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('ambiguous'));
        expect(result.content.first.text, contains('a-1, a-2'));
        expect(messagingPort.dispatched, isEmpty);
      });

      test('an agent from another workspace is not resolved', () async {
        agents.add(
          _createAgent(
            id: 'a-ws2',
            name: 'expert',
            title: 'Security Expert',
            workspaceId: 'ws-2',
            skills: ['security'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-ws2',
          'topic': 'security',
          'question': 'Safe?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('No agent with id'));
      });
    });

    group('participant management', () {
      test('adds agent when not already a participant', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Security Expert',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );

        final preParticipants = await messaging.getParticipants('ws-1', 'ch-1');
        expect(preParticipants, isEmpty);

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'security',
          'question': 'Safe?',
        });

        final postParticipants = await messaging.getParticipants(
          'ws-1',
          'ch-1',
        );
        expect(postParticipants.length, 1);
        expect(postParticipants.first.principalId, 'a-1');
      });

      test('does not add agent when already a participant', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Security Expert',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );
        messaging.addParticipantEntry(
          'ch-1',
          SpaceParticipant(
            id: 'p-1',
            spaceId: 'ch-1',
            principalId: 'a-1',
            participantType: PrincipalType.agent,
            role: 'member',
            joinedAt: DateTime(2025),
          ),
        );

        final preParticipants = await messaging.getParticipants('ws-1', 'ch-1');
        expect(preParticipants.length, 1);

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'security',
          'question': 'Safe?',
        });

        final postParticipants = await messaging.getParticipants(
          'ws-1',
          'ch-1',
        );
        expect(postParticipants.length, 1);
      });

      test('adds only the matched agent, not other agents', () async {
        agents.add(
          _createAgent(
            id: 'a-match',
            name: 'florist',
            title: 'Florist',
            workspaceId: 'ws-1',
            skills: ['architecture'],
          ),
        );
        agents.add(
          _createAgent(
            id: 'a-other',
            name: 'spectator',
            title: 'Spectator',
            workspaceId: 'ws-1',
            skills: ['gossiping'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-match',
          'topic': 'architecture',
          'question': 'Layout?',
        });

        final participants = await messaging.getParticipants('ws-1', 'ch-1');
        expect(participants.length, 1);
        expect(participants.first.principalId, 'a-match');
      });
    });

    group('sendMessage', () {
      test('sends system message with agent mention and question', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'security-expert',
            title: 'Security Expert',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );

        await tool.call({
          'space_id': 'ch-plan',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'security',
          'question': 'Is this encryption safe?',
        });

        expect(messaging.sent.length, 1);
        final msg = messaging.sent.first;
        expect(msg.spaceId, 'ch-plan');
        expect(msg.senderId, 'system');
        expect(msg.senderType, 'system');
        expect(msg.messageType, 'system');
        expect(msg.content, contains('@security-expert'));
        expect(msg.content, contains('"security"'));
        expect(msg.content, contains('Is this encryption safe?'));
      });
    });

    group('dispatchAgent', () {
      test('dispatches agent with consultation brief', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'dba',
            title: 'Database Expert',
            workspaceId: 'ws-1',
            skills: ['database'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'database',
          'question': 'Postgres or MySQL?',
        });

        expect(messagingPort.dispatched.length, 1);
        final dispatch = messagingPort.dispatched.first;
        expect(dispatch.spaceId, 'ch-1');
        expect(dispatch.agentId, 'a-1');
        expect(dispatch.workspaceId, 'ws-1');
        expect(dispatch.prompt, contains('database'));
        expect(dispatch.prompt, contains('Postgres or MySQL?'));
        expect(dispatch.prompt, contains('planning discussion'));
        expect(dispatch.prompt, contains('expert assessment'));
      });

      test('dispatches with rationale included in brief', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'legal',
            title: 'Legal Advisor',
            workspaceId: 'ws-1',
            skills: ['legal'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'legal',
          'question': 'Is this compliant?',
          'rationale': 'We need to verify GDPR compliance before launch.',
        });

        final dispatch = messagingPort.dispatched.first;
        expect(dispatch.prompt, contains('Context:'));
        expect(dispatch.prompt, contains('GDPR compliance'));
      });

      test('does not include context section when rationale absent', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'legal',
            title: 'Legal Advisor',
            workspaceId: 'ws-1',
            skills: ['legal'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'legal',
          'question': 'Is this compliant?',
        });

        final dispatch = messagingPort.dispatched.first;
        expect(dispatch.prompt, isNot(contains('Context:')));
      });
    });

    group('sendMessage detail', () {
      test('system message includes metadata space context', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'sec-expert',
            title: 'Security Expert',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );

        await tool.call({
          'space_id': 'ch-meta',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'security',
          'question': 'Is this safe?',
        });

        final msg = messaging.sent.first;
        expect(msg.content, contains('@sec-expert'));
        expect(msg.content, contains('consulted as'));
        expect(msg.messageType, 'system');
      });

      test('message includes topic in the notification', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'architect',
            title: 'Architect',
            workspaceId: 'ws-1',
            skills: ['architecture'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'architecture',
          'question': 'Monolith or microservices?',
        });

        expect(messaging.sent.first.content, contains('"architecture"'));
      });
    });

    group('dispatchAgent detail', () {
      test('dispatch prompt includes topic and question verbatim', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'reviewer',
            title: 'Code Reviewer',
            workspaceId: 'ws-1',
            skills: ['review'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'review',
          'question': 'Please check the auth module for vulnerabilities.',
        });

        final dispatch = messagingPort.dispatched.first;
        expect(dispatch.prompt, contains('"review" specialist'));
        expect(
          dispatch.prompt,
          contains('Please check the auth module for vulnerabilities.'),
        );
      });

      test('dispatch prompt includes expert assessment guidance', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'How?',
        });

        final dispatch = messagingPort.dispatched.first;
        expect(dispatch.prompt, contains('expert assessment'));
        expect(dispatch.prompt, contains('concise'));
        expect(dispatch.prompt, contains('actionable'));
      });

      test('dispatch includes workspaceId in the call', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'How?',
        });

        expect(messagingPort.dispatched.first.workspaceId, 'ws-1');
      });
    });

    group('edge cases additional', () {
      test('re-consulting same agent does not duplicate participant', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        // First consult
        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'Q1?',
        });
        final countAfterFirst = (await messaging.getParticipants(
          'ws-1',
          'ch-1',
        )).length;
        messaging.sent.clear();
        messagingPort.dispatched.clear();
        // The first consult's run ends; a second wake would otherwise wait
        // behind it in that conversation.
        await _kit.finish('run-1', answer: 'Use the flag.');

        // Second consult — same agent, same space
        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'Q2?',
        });

        final participants = await messaging.getParticipants('ws-1', 'ch-1');
        expect(participants.length, countAfterFirst);
        // Woken a second time: a new consult is a new wake.
        expect(messagingPort.dispatched.length, 1);
        expect(messaging.sent.length, 1);
      });

      test('reason override via messageType system', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'legal',
            title: 'Legal Advisor',
            workspaceId: 'ws-1',
            skills: ['legal'],
          ),
        );

        await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'legal',
          'question': 'Compliant?',
        });

        final msg = messaging.sent.first;
        expect(msg.messageType, 'system');
        expect(msg.senderId, 'system');
      });

      test('topic with special characters works', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'C++ Expert',
            workspaceId: 'ws-1',
            skills: ['c++'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'c++',
          'question': 'std::move or std::forward?',
        });

        expect(result.isError, isFalse);
      });

      test(
        'exception during messaging.sendMessage propagates correctly',
        () async {
          final throwingRepo = _ThrowingMessagingRepository();
          final throwingTool = ConsultAgentTool(
            agents: agents,
            messaging: throwingRepo,
            service: _openGate(),
            peerAsks: _kit.service,
            rateLimiter: PairRateLimiter(),
          );
          agents.add(
            _createAgent(
              id: 'a-1',
              name: 'expert',
              title: 'Expert',
              workspaceId: 'ws-1',
              skills: ['testing'],
            ),
          );

          final result = await throwingTool.call({
            'space_id': 'ch-1',
            'workspace_id': 'ws-1',
            'to_agent_id': 'a-1',
            'topic': 'testing',
            'question': 'How?',
          });

          expect(result.isError, isTrue);
          expect(result.content.first.text, contains('boom'));
        },
      );

      test('exception during getParticipants returns error result', () async {
        final throwingRepo = _ThrowingMessagingRepository();
        final throwingTool = ConsultAgentTool(
          agents: agents,
          messaging: throwingRepo,
          service: _openGate(),
          peerAsks: _kit.service,
          rateLimiter: PairRateLimiter(),
        );
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Security Expert',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );

        final result = await throwingTool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'security',
          'question': 'Safe?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('boom'));
      });
    });

    group('result', () {
      test('returns success with structured JSON', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'How to test?',
          'rationale': 'Need to ensure coverage.',
        });

        expect(result.isError, isFalse);
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['space_id'], 'ch-1');
        expect(data['consulted_agent_id'], 'a-1');
        expect(data['consulted_agent_name'], 'expert');
        expect(data['topic'], 'testing');
        expect(data['question'], 'How to test?');
      });

      test('result is valid JSON', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'How?',
        });

        expect(() => jsonDecode(result.content.first.text), returnsNormally);
      });
    });

    group('result detail', () {
      test('success result has all expected JSON keys', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'How?',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(
          data.keys,
          containsAll([
            'space_id',
            'consulted_agent_id',
            'consulted_agent_name',
            'topic',
            'question',
          ]),
        );
      });

      test('JSON output does not include rationale', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'How?',
          'rationale': 'Important context here.',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data.containsKey('rationale'), isFalse);
      });

      test('non-interfering extra args do not break success', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        final result = await tool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'How?',
          'extra_unknown_field': 'ignored',
          'another_one': 123,
        });

        expect(result.isError, isFalse);
      });
    });

    group('edge cases', () {
      test('calling call() wraps exceptions as error result', () async {
        final throwingRepo = _ThrowingMessagingRepository();
        final throwingTool = ConsultAgentTool(
          agents: agents,
          messaging: throwingRepo,
          service: _openGate(),
          peerAsks: _kit.service,
          rateLimiter: PairRateLimiter(),
        );
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'expert',
            title: 'Expert',
            workspaceId: 'ws-1',
            skills: ['testing'],
          ),
        );

        final result = await throwingTool.call({
          'space_id': 'ch-1',
          'workspace_id': 'ws-1',
          'to_agent_id': 'a-1',
          'topic': 'testing',
          'question': 'How?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('boom'));
      });
    });
  });
}

class _ThrowingMessagingRepository extends _FakeMessagingRepository {
  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async {
    throw Exception('boom');
  }
}

/// A gate that admits every hand-off: both agents act with approval, no
/// budget stop. Gate refusals are covered in `peer_tools_gate_test.dart`.
TicketWorkflowService _openGate() => TicketWorkflowService(
  repository: _NoTickets(),
  eventBus: DomainEventBus(),
  resolveEffectiveAutonomy:
      ({required workspaceId, required agentId, spaceId}) async =>
          AutonomyLevel.actWithApproval,
  resolveRemainingBudgetMicros:
      ({required workspaceId, required agentId}) async => null,
);

class _NoTickets implements TicketRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
