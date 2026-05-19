import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_mcp/src/tools/propose_hire_tool.dart';
import 'package:test/test.dart';

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

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);

  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => Stream.value([]);

  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => Stream.value([]);

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value([]);

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
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async => null;

  String? lastChannelId;
  String? lastContent;
  String? lastSenderId;
  String? lastSenderType;
  String? lastMessageType;
  Map<String, dynamic>? lastMetadata;
  String? lastId;

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
    lastChannelId = channelId;
    lastContent = content;
    lastSenderId = senderId;
    lastSenderType = senderType;
    lastMessageType = messageType;
    lastMetadata = metadata;
    lastId = id;
    return id ?? '';
  }

  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) async {}

  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    List<String> repoIds = const [],
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
    String? content,
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
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) async {}

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
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

void main() {
  group('ProposeHireTool', () {
    late _FakeMessagingRepository repository;
    late ProposeHireTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = ProposeHireTool(messaging: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'propose_hire');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      final required = schema['required'] as List<dynamic>;
      expect(
        required,
        containsAll([
          'channel_id',
          'workspace_id',
          'name',
          'title',
          'skills',
          'rationale',
        ]),
      );
      // persona is NOT required
      expect(required, isNot(contains('persona')));
      final props = schema['properties'] as Map<String, dynamic>;
      expect((props['skills'] as Map<String, dynamic>)['type'], 'array');
      expect(
        ((props['skills'] as Map<String, dynamic>)['items']
            as Map<String, dynamic>)['type'],
        'string',
      );
    });

    test('sends hire proposal and returns success', () async {
      final result = await tool.call({
        'channel_id': 'ch-42',
        'workspace_id': 'ws-1',
        'name': 'rust-reviewer',
        'title': 'Rust Code Reviewer',
        'skills': ['rust', 'memory-safety'],
        'rationale': 'No Rust expert available.',
      });

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['channel_id'], 'ch-42');
      expect(data['status'], 'pending_approval');
      expect(data['message_id'], isA<String>());
      expect(data['message_id'], isNotEmpty);
    });

    test('sends correct message metadata to repository', () async {
      await tool.call({
        'channel_id': 'ch-42',
        'workspace_id': 'ws-1',
        'name': 'rust-reviewer',
        'title': 'Rust Code Reviewer',
        'skills': ['rust', 'memory-safety'],
        'rationale': 'No Rust expert available.',
      });

      expect(repository.lastChannelId, 'ch-42');
      expect(repository.lastSenderId, 'system');
      expect(repository.lastSenderType, 'agent');
      expect(repository.lastMessageType, 'hire_proposal');
      expect(
        repository.lastContent,
        'Proposing to hire **rust-reviewer** (Rust Code Reviewer).\n\nNo Rust expert available.',
      );

      final metadata = repository.lastMetadata!;
      expect(metadata['workspaceId'], 'ws-1');
      expect(metadata['name'], 'rust-reviewer');
      expect(metadata['title'], 'Rust Code Reviewer');
      expect(metadata['skills'], ['rust', 'memory-safety']);
      expect(metadata['rationale'], 'No Rust expert available.');
      expect(metadata['status'], 'pending');
      expect(metadata['persona'], isNull);
    });

    test('includes persona in metadata when provided', () async {
      await tool.call({
        'channel_id': 'ch-1',
        'workspace_id': 'ws-1',
        'name': 'pythonista',
        'title': 'Python Expert',
        'skills': ['python'],
        'rationale': 'Need Python review.',
        'persona': 'Senior Python dev with Django chops.',
      });

      expect(
        repository.lastMetadata!['persona'],
        'Senior Python dev with Django chops.',
      );
    });

    test('omits persona from metadata when absent', () async {
      await tool.call({
        'channel_id': 'ch-1',
        'workspace_id': 'ws-1',
        'name': 'pythonista',
        'title': 'Python Expert',
        'skills': ['python'],
        'rationale': 'Need Python review.',
      });

      final metadata = repository.lastMetadata!;
      expect(metadata.containsKey('persona'), isFalse);
    });

    test('filters non-String entries from skills', () async {
      await tool.call({
        'channel_id': 'ch-1',
        'workspace_id': 'ws-1',
        'name': 'generalist',
        'title': 'Generalist',
        'skills': ['python', 42, 'rust', null, 'go'],
        'rationale': 'Need review.',
      });

      final metadata = repository.lastMetadata!;
      expect(metadata['skills'], ['python', 'rust', 'go']);
    });

    test('generates unique message IDs for each call', () async {
      final r1 = await tool.call({
        'channel_id': 'ch-a',
        'workspace_id': 'ws-1',
        'name': 'agent-a',
        'title': 'Agent A',
        'skills': ['a'],
        'rationale': 'Need A.',
      });
      final r2 = await tool.call({
        'channel_id': 'ch-b',
        'workspace_id': 'ws-2',
        'name': 'agent-b',
        'title': 'Agent B',
        'skills': ['b'],
        'rationale': 'Need B.',
      });

      final id1 =
          (jsonDecode(r1.content.first.text)
                  as Map<String, dynamic>)['message_id']
              as String;
      final id2 =
          (jsonDecode(r2.content.first.text)
                  as Map<String, dynamic>)['message_id']
              as String;
      expect(id1, isNot(id2));
    });

    group('arg validation', () {
      test('returns error when channel_id is missing', () async {
        final result = await tool.call({
          'workspace_id': 'ws-1',
          'name': 'agent',
          'title': 'Agent',
          'skills': ['a'],
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: channel_id'),
        );
      });

      test('returns error when channel_id is not a String', () async {
        final result = await tool.call({
          'channel_id': 123,
          'workspace_id': 'ws-1',
          'name': 'agent',
          'title': 'Agent',
          'skills': ['a'],
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: channel_id'),
        );
      });

      test('returns error when workspace_id is missing', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'name': 'agent',
          'title': 'Agent',
          'skills': ['a'],
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: workspace_id'),
        );
      });

      test('returns error when workspace_id is not a String', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': true,
          'name': 'agent',
          'title': 'Agent',
          'skills': ['a'],
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: workspace_id'),
        );
      });

      test('returns error when name is missing', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'title': 'Agent',
          'skills': ['a'],
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: name'),
        );
      });

      test('returns error when name is not a String', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'name': ['bad'],
          'title': 'Agent',
          'skills': ['a'],
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: name'),
        );
      });

      test('returns error when title is missing', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'name': 'agent',
          'skills': ['a'],
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: title'),
        );
      });

      test('returns error when title is not a String', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'name': 'agent',
          'title': 3.14,
          'skills': ['a'],
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: title'),
        );
      });

      test('returns error when skills is missing', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'name': 'agent',
          'title': 'Agent',
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: skills'),
        );
      });

      test('returns error when skills is not a List', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'name': 'agent',
          'title': 'Agent',
          'skills': 'not-a-list',
          'rationale': 'Need.',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: skills'),
        );
      });

      test('returns error when rationale is missing', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'name': 'agent',
          'title': 'Agent',
          'skills': ['a'],
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: rationale'),
        );
      });

      test('returns error when rationale is not a String', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'name': 'agent',
          'title': 'Agent',
          'skills': ['a'],
          'rationale': null,
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Missing or invalid argument: rationale'),
        );
      });
    });

    test('throws from repository bubbles up as CallResult error', () async {
      final badRepo = _ThrowingMessagingRepository();
      final t = ProposeHireTool(messaging: badRepo);
      final result = await t.call({
        'channel_id': 'ch-1',
        'workspace_id': 'ws-1',
        'name': 'agent',
        'title': 'Agent',
        'skills': ['a'],
        'rationale': 'Need.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('boom'));
    });
  });
}

class _ThrowingMessagingRepository extends _FakeMessagingRepository {
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
    throw Exception('boom');
  }
}
