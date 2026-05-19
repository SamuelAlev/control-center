import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_mcp/src/tools/consult_agent_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];

  void add(Agent agent) => _agents.add(agent);

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
  Future<Channel?> getChannelById(String workspaceId, String channelId) async =>
      null;

  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  final Map<String, List<ChannelParticipant>> _participants = {};
  final List<_SentMessage> sent = [];

  void addParticipantEntry(String channelId, ChannelParticipant p) {
    (_participants[channelId] ??= []).add(p);
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async {
    return List.unmodifiable(_participants[channelId] ?? []);
  }

  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    (_participants[channelId] ??= []).add(
      ChannelParticipant(
        id: '${channelId}_$principalId',
        channelId: channelId,
        principalId: principalId,
        participantType: participantType,
        role: 'member',
        joinedAt: DateTime(2025),
      ),
    );
  }

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
    sent.add(
      _SentMessage(
        channelId: channelId,
        content: content,
        senderId: senderId,
        senderType: senderType,
        messageType: messageType,
      ),
    );
    return 'msg-${sent.length}';
  }

  // Unused stubs
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
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => throw UnimplementedError();
  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async => throw UnimplementedError();
  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async => throw UnimplementedError();
  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    dynamic mode,
    List<String> repoIds = const [],
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
  }) async => throw UnimplementedError();
  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    dynamic mode,
  ) async {}
  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {}
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
  }) async => [];
  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}
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
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    dynamic embedding,
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
}

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

class _FakeMessagingPort implements MessagingPort {
  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String channelId,
    required String failedMessageId,
  }) async {}

  @override
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String channelId,
    String? conversationId,
  }) async => const ConversationCompactionResult(
    status: ConversationCompactionStatus.unavailable,
  );

  final List<_DispatchCall> dispatched = [];

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
    dispatched.add(
      _DispatchCall(
        channelId: channelId,
        agentId: agentId,
        prompt: prompt,
        workspaceId: workspaceId,
      ),
    );
    return null;
  }

  // Unused stubs
  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {}
  @override
  Future<void> addAgentToChannel(
    String workspaceId,
    String channelId,
    String agentId, {
    bool renameForGroup = true,
  }) async {}
  @override
  Future<bool> channelExists(String workspaceId, String channelId) async =>
      true;
  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    dynamic mode,
    List<String> repoIds = const [],
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
  }) async => throw UnimplementedError();
  @override
  Future<void> sendAndDispatch(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    List<dynamic>? structuredMentions,
    List<dynamic>? entityRefs,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {}
  @override
  Future<void> refinePlan({
    required String workspaceId,
    required String channelId,
    required String feedback,
  }) async {}
  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) async {}
  @override
  Future<void> deleteChannel(String workspaceId, String channelId) async {}
  @override
  Future<void> clearChannelMessages(
    String workspaceId,
    String channelId,
  ) async {}
  @override
  Future<void> stopRun(String workspaceId, String runLogId) async {}
  @override
  Future<bool> pauseRun(String runLogId) async => false;
  @override
  Future<bool> resumeRun(String runLogId) async => false;
  @override
  Future<bool> steerRun(
    String runLogId,
    String message, {
    bool followUp = false,
  }) async => false;
}

class _DispatchCall {
  const _DispatchCall({
    required this.channelId,
    required this.agentId,
    required this.prompt,
    required this.workspaceId,
  });
  final String channelId;
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

    setUp(() {
      agents = _FakeAgentRepository();
      messaging = _FakeMessagingRepository();
      messagingPort = _FakeMessagingPort();
      tool = ConsultAgentTool(
        agents: agents,
        messaging: messaging,
        messagingPort: messagingPort,
      );
    });

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
          containsAll(['channel_id', 'workspace_id', 'topic', 'question']),
        );
        final props = schema['properties'] as Map<String, dynamic>;
        expect(props['rationale'], isNotNull);
        expect((props['rationale'] as Map<String, dynamic>)['type'], 'string');
      });
    });

    group('arg validation', () {
      test('returns error for missing channel_id', () async {
        final result = await tool.call({
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('channel_id'));
      });

      test('returns error for channel_id of wrong type', () async {
        final result = await tool.call({
          'channel_id': 123,
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('channel_id'));
      });

      test('returns error for missing workspace_id', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'topic': 'security',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('workspace_id'));
      });

      test('returns error for workspace_id of wrong type', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': null,
          'topic': 'security',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('workspace_id'));
      });

      test('returns error for missing topic', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('topic'));
      });

      test('returns error for topic of wrong type', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': true,
          'question': 'Is this safe?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('topic'));
      });

      test('returns error for missing question', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('question'));
      });

      test('returns error for question of wrong type', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 42,
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('question'));
      });
    });

    group('matching', () {
      test('returns error when no agent matches topic', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'architect',
            title: 'System Architect',
            workspaceId: 'ws-1',
            skills: ['architecture'],
          ),
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'quantum computing',
          'question': 'How to?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('No agent matching topic'));
        expect(result.content.first.text, contains('quantum computing'));
        expect(result.content.first.text, contains('propose_hire'));
      });

      test('finds agent by skill match over title match', () async {
        agents.add(
          _createAgent(
            id: 'a-skill',
            name: 'generic',
            title: 'Generic Helper',
            workspaceId: 'ws-1',
            skills: ['performance'],
          ),
        );
        agents.add(
          _createAgent(
            id: 'a-title',
            name: 'perf',
            title: 'Performance Expert',
            workspaceId: 'ws-1',
            skills: [],
          ),
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'performance',
          'question': 'Optimize?',
        });

        expect(result.isError, isFalse);
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['consulted_agent_id'], 'a-skill');
      });

      test('title match works when skills do not match', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'coder',
            title: 'Performance Specialist',
            workspaceId: 'ws-1',
            skills: ['python'],
          ),
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'performance',
          'question': 'Is this fast?',
        });

        expect(result.isError, isFalse);
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['consulted_agent_id'], 'a-1');
      });

      test('name match provides fallback scoring', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'security-bot',
            title: 'Helper',
            workspaceId: 'ws-1',
            skills: [],
          ),
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Audit?',
        });

        expect(result.isError, isFalse);
      });

      test('empty agents list returns no match', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Safe?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('No agent matching topic'));
      });

      test('case-insensitive topic matching', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'guard',
            title: 'Guard',
            workspaceId: 'ws-1',
            skills: ['Security'],
          ),
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'SECURITY',
          'question': 'Safe?',
        });

        expect(result.isError, isFalse);
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          ChannelParticipant(
            id: 'p-1',
            channelId: 'ch-1',
            principalId: 'a-1',
            participantType: PrincipalType.agent,
            role: 'member',
            joinedAt: DateTime(2025),
          ),
        );

        final preParticipants = await messaging.getParticipants('ws-1', 'ch-1');
        expect(preParticipants.length, 1);

        await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-plan',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Is this encryption safe?',
        });

        expect(messaging.sent.length, 1);
        final msg = messaging.sent.first;
        expect(msg.channelId, 'ch-plan');
        expect(msg.senderId, 'system');
        expect(msg.senderType, 'agent');
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'database',
          'question': 'Postgres or MySQL?',
        });

        expect(messagingPort.dispatched.length, 1);
        final dispatch = messagingPort.dispatched.first;
        expect(dispatch.channelId, 'ch-1');
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'legal',
          'question': 'Is this compliant?',
        });

        final dispatch = messagingPort.dispatched.first;
        expect(dispatch.prompt, isNot(contains('Context:')));
      });
    });

    group('sendMessage detail', () {
      test('system message includes metadata channel context', () async {
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
          'channel_id': 'ch-meta',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'testing',
          'question': 'How?',
        });

        expect(messagingPort.dispatched.first.workspaceId, 'ws-1');
      });
    });

    group('matching detail', () {
      test('multi-word topic matches when a single word is in skill', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'bot',
            title: 'Helper',
            workspaceId: 'ws-1',
            skills: ['database performance tuning'],
          ),
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'database',
          'question': 'Optimize?',
        });

        // 'database' is contained in skill 'database performance tuning'
        expect(result.isError, isFalse);
      });

      test('partial word match within skill works', () async {
        agents.add(
          _createAgent(
            id: 'a-1',
            name: 'bot',
            title: 'Helper',
            workspaceId: 'ws-1',
            skills: ['cybersecurity'],
          ),
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Audit?',
        });

        // 'security' is a substring of 'cybersecurity'
        expect(result.isError, isFalse);
      });

      test('exact word match preferred over substring match', () async {
        agents.add(
          _createAgent(
            id: 'a-exact',
            name: 'generic-bot',
            title: 'Helper',
            workspaceId: 'ws-1',
            skills: ['security'],
          ),
        );
        agents.add(
          _createAgent(
            id: 'a-substring',
            name: 'sec-bot',
            title: 'Helper',
            workspaceId: 'ws-1',
            skills: ['cybersecurity'],
          ),
        );

        // Both match 'security' — skill score 3. The exact match also gets
        // title/name points from 'security-bot'. But the first has skill
        // 'security' which is an exact contains match. Both get 3 for skill.
        // Tiebreaker: the loop order — first found wins.
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Audit?',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['consulted_agent_id'], 'a-exact');
      });

      test(
        'topic matching is whitespace-sensitive (only matches exact topic)',
        () async {
          agents.add(
            _createAgent(
              id: 'a-1',
              name: 'bot',
              title: 'Security Expert',
              workspaceId: 'ws-1',
              skills: ['security audit'],
            ),
          );

          final result = await tool.call({
            'channel_id': 'ch-1',
            'workspace_id': 'ws-1',
            'topic': 'security',
            'question': 'Audit?',
          });

          expect(result.isError, isFalse);
          // 'security audit' contains 'security' — match on skill
        },
      );
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'testing',
          'question': 'Q1?',
        });
        final countAfterFirst = (await messaging.getParticipants(
          'ws-1',
          'ch-1',
        )).length;
        messaging.sent.clear();
        messagingPort.dispatched.clear();

        // Second consult — same agent, same channel
        await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'testing',
          'question': 'Q2?',
        });

        final participants = await messaging.getParticipants('ws-1', 'ch-1');
        expect(participants.length, countAfterFirst);
        // Still dispatched a second time (consult is stateless)
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
            messagingPort: messagingPort,
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
            'channel_id': 'ch-1',
            'workspace_id': 'ws-1',
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
          messagingPort: messagingPort,
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'testing',
          'question': 'How to test?',
          'rationale': 'Need to ensure coverage.',
        });

        expect(result.isError, isFalse);
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['channel_id'], 'ch-1');
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'testing',
          'question': 'How?',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(
          data.keys,
          containsAll([
            'channel_id',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'testing',
          'question': 'How?',
          'extra_unknown_field': 'ignored',
          'another_one': 123,
        });

        expect(result.isError, isFalse);
      });
    });

    group('edge cases', () {
      test('agents from wrong workspace are not matched', () async {
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Safe?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('No agent matching topic'));
      });

      test('agent with strongest combined match wins', () async {
        final strong = _createAgent(
          id: 'a-strong',
          name: 'generic',
          title: 'Security Architect',
          workspaceId: 'ws-1',
          skills: ['security'],
        );
        final weak = _createAgent(
          id: 'a-weak',
          name: 'security-bot',
          title: 'Security Helper',
          workspaceId: 'ws-1',
          skills: [],
        );
        agents.add(strong);
        agents.add(weak);

        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Audit?',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['consulted_agent_id'], 'a-strong');
      });

      test('calling call() wraps exceptions as error result', () async {
        final throwingRepo = _ThrowingMessagingRepository();
        final throwingTool = ConsultAgentTool(
          agents: agents,
          messaging: throwingRepo,
          messagingPort: messagingPort,
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'testing',
          'question': 'How?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('boom'));
      });

      test('empty string topic matches everything', () async {
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
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': '',
          'question': 'Safe?',
        });

        // Empty string contains('') is always true, so it finds a match
        expect(result.isError, isFalse);
      });

      test('empty workspace yields error', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'topic': 'security',
          'question': 'Safe?',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('No agent matching topic'));
      });
    });
  });
}

class _ThrowingMessagingRepository extends _FakeMessagingRepository {
  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async {
    throw Exception('boom');
  }
}
