import 'dart:typed_data';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_model_manager.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_service.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/features/messaging/domain/usecases/backfill_message_embeddings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEmbeddingService extends EmbeddingService {
  _FakeEmbeddingService()
      : super(
          modelInfo: EmbeddingModelInfo.allMiniLmL6V2,
          paths: const EmbeddingModelPaths(
            model: '/fake/model.onnx',
            vocab: '/fake/vocab.txt',
          ),
        );

  @override
  bool get isReady => true;

  @override
  Future<Float32List> embed(String text) async {
    final vec = Float32List(384);
    vec[0] = text.length.toDouble();
    return vec;
  }
}

class _NotReadyEmbeddingService extends EmbeddingService {
  _NotReadyEmbeddingService()
      : super(
          modelInfo: EmbeddingModelInfo.allMiniLmL6V2,
          paths: const EmbeddingModelPaths(
            model: '/fake/model.onnx',
            vocab: '/fake/vocab.txt',
          ),
        );

  @override
  bool get isReady => false;
}

class _FakeMessagingRepository implements MessagingRepository {


  _FakeMessagingRepository([this._messagesWithoutEmbedding = const []]);
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
  final List<ChannelMessage> _messagesWithoutEmbedding;
  final List<String> _embeddedIds = [];

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200}) async =>
      _messagesWithoutEmbedding;

  @override
  Future<void> updateMessageEmbedding(String messageId, Uint8List embedding) async {
    _embeddedIds.add(messageId);
  }

  List<String> get embeddedIds => _embeddedIds;

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(String channelId) async => [];

  @override
  Stream<List<Channel>> watchChannels() => const Stream.empty();

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      const Stream.empty();

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) => throw UnimplementedError();

  @override
  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) async {}

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> addParticipant(String channelId, String agentId) async {}

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async => [];

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
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async => [];

  @override
  Future<void> markCompacted(List<String> ids) async {}

  @override
  Future<void> deleteChannel(String channelId) async {}

  @override
  Future<void> updateChannelName(String channelId, String name) async {}

  @override
  Future<void> clearChannelMessages(String channelId) async {}

  @override
  Future<void> removeParticipant(String channelId, String agentId) async {}
}

ChannelMessage _msg({required String id, required String content}) =>
    ChannelMessage(
      id: id,
      channelId: 'ch1',
      senderId: 'user',
      senderType: ChannelSenderType.user,
      content: content,
      messageType: ChannelMessageType.text,
      createdAt: DateTime(2026, 5, 21),
    );

void main() {
  group('BackfillMessageEmbeddingsUseCase', () {
    test('returns 0 when embedding service is null', () async {
      final repo = _FakeMessagingRepository();
      final useCase = BackfillMessageEmbeddingsUseCase(
        messagingRepository: repo,
      );
      final count = await useCase.execute();
      expect(count, equals(0));
    });

    test('returns 0 when embedding service is not ready', () async {
      final repo = _FakeMessagingRepository();
      final useCase = BackfillMessageEmbeddingsUseCase(
        messagingRepository: repo,
        embeddingService: _NotReadyEmbeddingService(),
      );
      final count = await useCase.execute();
      expect(count, equals(0));
    });

    test('returns 0 when no messages need embedding', () async {
      final repo = _FakeMessagingRepository();
      final useCase = BackfillMessageEmbeddingsUseCase(
        messagingRepository: repo,
        embeddingService: _FakeEmbeddingService(),
      );
      final count = await useCase.execute();
      expect(count, equals(0));
    });

    test('backfills messages without embeddings', () async {
      final msgs = [
        _msg(id: 'm1', content: 'Hello world'),
        _msg(id: 'm2', content: 'How are you?'),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BackfillMessageEmbeddingsUseCase(
        messagingRepository: repo,
        embeddingService: _FakeEmbeddingService(),
      );

      final count = await useCase.execute();
      expect(count, equals(2));
      expect(repo.embeddedIds, containsAll(['m1', 'm2']));
    });
  });
}
