import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_mcp/src/tools/list_channels_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagingRepository implements MessagingRepository {
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
      watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
          Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      const Stream.empty();

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value(
        _channels.where((c) => c.workspaceId == workspaceId).toList(),
      );

  @override
  Future<ChannelMessage?> getMessageById(String messageId) async => null;

  final List<Channel> _channels = [];
  final _controller = StreamController<List<Channel>>.broadcast();

  void addChannel(Channel c) {
    _channels.add(c);
    _controller.add(List.unmodifiable(_channels));
  }

  @override
  Stream<List<Channel>> watchChannels() {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_channels)));
    return _controller.stream;
  }

  @override
  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) async {}

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  String? pipelineRunId,
    }) async {
    throw UnimplementedError();
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
    return '';
  }

  @override
  Future<void> updateMessage(String messageId, {Map<String, dynamic>? metadata, String? content}) async {}

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async => [];

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      Stream.value([]);

  @override
  Future<void> markCompacted(List<String> ids) async {}

  @override
  Future<void> deleteChannel(String channelId) async {}

  Future<void> updateChannelType(String channelId, String type) async {}

  @override
  Future<void> updateChannelName(String channelId, String name) async {}

  @override
  Future<void> clearChannelMessages(String channelId) async {}

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addParticipant(String channelId, String agentId) async {}

  @override
  Future<bool> channelExists(String channelId) async => true;

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async => [];

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      Stream.value([]);

  @override
  Future<void> removeParticipant(String channelId, String agentId) async {}

  @override
  Future<void> updateMessageEmbedding(String messageId, Uint8List embedding) async {}

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(String channelId) async => [];

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200}) async => [];

  void dispose() => _controller.close();
}

void main() {
  group('ListChannelsTool', () {
    late _FakeMessagingRepository repository;
    late ListChannelsTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = ListChannelsTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'list_channels');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(((schema['properties'] as Map<String, dynamic>)['workspace_id'] as Map<String, dynamic>)['type'], 'string');
    });

    test('requires workspace_id', () async {
      final result = await tool.call({});
      expect(result.isError, isTrue);
    });

    test('returns empty list when no channels', () async {
      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['channels'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns the workspace\'s channels', () async {
      repository.addChannel(Channel(
        id: 'ch-1',
        name: 'review-1',
        isDm: false,
        workspaceId: 'ws-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(((data['channels'] as List<dynamic>)[0] as Map<String, dynamic>)['name'], 'review-1');
    });

    test('filters by workspace_id', () async {
      repository.addChannel(Channel(
        id: 'ch-1',
        name: 'review-1',
        isDm: false,
        workspaceId: 'ws-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      repository.addChannel(Channel(
        id: 'ch-2',
        name: 'review-2',
        isDm: false,
        workspaceId: 'ws-2',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(((data['channels'] as List<dynamic>)[0] as Map<String, dynamic>)['id'], 'ch-1');
    });

    test('respects limit', () async {
      for (var i = 0; i < 10; i++) {
        repository.addChannel(Channel(
          id: 'ch-$i',
          name: 'channel-$i',
          isDm: false,
          workspaceId: 'ws-1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ));
      }

      final result = await tool.call({'workspace_id': 'ws-1', 'limit': 3});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });
  });
}
