import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/mcp/application/tools/submit_reviewer_verdict_tool.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagingRepository implements MessagingRepository {
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
      watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
          Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  // Spies
  String? lastChannelId;
  String? lastContent;
  String? lastSenderId;
  String? lastSenderType;
  String? lastMessageType;
  Map<String, dynamic>? lastMetadata;
  String? lastId;

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
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      const Stream.empty();

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<ChannelMessage?> getMessageById(String messageId) async => null;

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);

  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) async {}

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) async {
    throw UnimplementedError();
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
}

void main() {
  group('SubmitReviewerVerdictTool', () {
    late _FakeMessagingRepository repository;
    late SubmitReviewerVerdictTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = SubmitReviewerVerdictTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'submit_reviewer_verdict');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(
        schema['required'],
        containsAll([
          'channel_id',
          'reviewer_id',
          'verdict',
          'confidence',
          'explanation',
        ]),
      );
      final props = schema['properties'] as Map<String, dynamic>;
      expect((props['verdict'] as Map<String, dynamic>)['enum'],
          ['ship', 'hold', 'block']);
      expect((props['confidence'] as Map<String, dynamic>)['minimum'], 0);
      expect((props['confidence'] as Map<String, dynamic>)['maximum'], 1);
    });

    // --- Arg validation: channel_id ---

    test('errors on missing channel_id', () async {
      final result = await tool.call({
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('channel_id'));
    });

    test('errors on non-string channel_id', () async {
      final result = await tool.call({
        'channel_id': 42,
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('channel_id'));
    });

    // --- Arg validation: reviewer_id ---

    test('errors on missing reviewer_id', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('reviewer_id'));
    });

    test('errors on non-string reviewer_id', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 99,
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('reviewer_id'));
    });

    // --- Arg validation: verdict ---

    test('errors on missing verdict', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('verdict'));
    });

    test('errors on non-string verdict', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': true,
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('verdict'));
    });

    test('errors on invalid verdict value', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'maybe',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('verdict'));
    });

    // --- Arg validation: confidence ---

    test('errors on missing confidence', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('confidence'));
    });

    test('errors on non-numeric confidence', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 'high',
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('confidence'));
    });

    test('errors on confidence below 0', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': -0.1,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('out of range'));
    });

    test('errors on confidence above 1', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 1.5,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('out of range'));
    });

    test('errors on NaN confidence', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': double.nan,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('out of range'));
    });

    // --- Arg validation: explanation ---

    test('errors on missing explanation', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0.8,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('explanation'));
    });

    test('errors on non-string explanation', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 12345,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text,
          contains('explanation'));
    });

    // --- Confidence boundary acceptance ---

    test('accepts confidence exactly 0.0', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'block',
        'confidence': 0.0,
        'explanation': 'Terrible.',
      });
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['confidence'], 0.0);
    });

    test('accepts confidence exactly 1.0', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'hold',
        'confidence': 1.0,
        'explanation': 'Needs minor fix.',
      });
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['confidence'], 1.0);
    });

    // --- Success: all verdict variants ---

    test('sends message and returns success for ship verdict', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'agent-7',
        'verdict': 'ship',
        'confidence': 0.95,
        'explanation': 'All checks pass, looks solid.',
      });
      expect(result.isError, isFalse);

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['channel_id'], 'ch-1');
      expect(data['reviewer_id'], 'agent-7');
      expect(data['verdict'], 'ship');
      expect(data['confidence'], 0.95);
      expect(data['message_id'], isA<String>());
      expect(data['message_id'], isNotEmpty);

      // Verify message sent to repository
      expect(repository.lastChannelId, 'ch-1');
      expect(repository.lastSenderId, 'agent-7');
      expect(repository.lastContent, 'All checks pass, looks solid.');
      expect(repository.lastSenderType, 'agent');
      expect(repository.lastMessageType, 'system');
      expect(repository.lastId, data['message_id']);
      expect(repository.lastMetadata, {
        'reviewerVerdict': true,
        'verdict': 'ship',
        'confidence': 0.95,
      });
    });

    test('sends message and returns success for hold verdict', () async {
      final result = await tool.call({
        'channel_id': 'ch-2',
        'reviewer_id': 'agent-3',
        'verdict': 'hold',
        'confidence': 0.7,
        'explanation': 'Needs clarification on one point.',
      });
      expect(result.isError, isFalse);

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['verdict'], 'hold');
      expect(data['confidence'], 0.7);
      expect(repository.lastMetadata!['verdict'], 'hold');
      expect(repository.lastMetadata!['confidence'], 0.7);
    });

    test('sends message and returns success for block verdict', () async {
      final result = await tool.call({
        'channel_id': 'ch-3',
        'reviewer_id': 'agent-9',
        'verdict': 'block',
        'confidence': 0.99,
        'explanation': 'Security vulnerability found.',
      });
      expect(result.isError, isFalse);

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['verdict'], 'block');
      expect(data['confidence'], 0.99);
      expect(repository.lastMetadata!['verdict'], 'block');
      expect(repository.lastMetadata!['confidence'], 0.99);
    });

    // --- Integer confidence ---

    test('accepts integer confidence', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0, // int -> num -> toDouble() == 0.0
        'explanation': 'Perfect.',
      });
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['confidence'], 0.0);
    });
  });
}
