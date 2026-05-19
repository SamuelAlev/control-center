import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/usecases/backfill_message_embeddings_use_case.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_infra/src/embedding/embedding_model_manager.dart';
import 'package:cc_infra/src/embedding/embedding_service.dart';
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

/// Workspace whose unembedded messages the fake repository holds. A backfill
/// pass runs one workspace at a time, so a pass over any other workspace must
/// see nothing here.
const _ws = 'ws-1';

class _FakeMessagingRepository implements MessagingRepository {
  _FakeMessagingRepository([this._messagesWithoutEmbedding = const []]);
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
  final List<ChannelMessage> _messagesWithoutEmbedding;
  final List<String> _embeddedIds = [];

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => workspaceId == _ws ? _messagesWithoutEmbedding : const [];

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {
    _embeddedIds.add('$workspaceId/$messageId');
  }

  List<String> get embeddedIds => _embeddedIds;

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String channelId,
  ) async => [];

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
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
    List<String> repoIds = const [],
  }) => throw UnimplementedError();

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
    return '';
  }

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
}

ChannelMessage _msg({required String id, required String content}) =>
    ChannelMessage(
      id: id,
      channelId: 'ch1',
      conversationId: 'ch1',
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
      final count = await useCase.execute(_ws);
      expect(count, equals(0));
    });

    test('returns 0 when embedding service is not ready', () async {
      final repo = _FakeMessagingRepository();
      final useCase = BackfillMessageEmbeddingsUseCase(
        messagingRepository: repo,
        embeddingService: _NotReadyEmbeddingService(),
      );
      final count = await useCase.execute(_ws);
      expect(count, equals(0));
    });

    test('returns 0 when no messages need embedding', () async {
      final repo = _FakeMessagingRepository();
      final useCase = BackfillMessageEmbeddingsUseCase(
        messagingRepository: repo,
        embeddingService: _FakeEmbeddingService(),
      );
      final count = await useCase.execute(_ws);
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

      final count = await useCase.execute(_ws);
      expect(count, equals(2));
      // Each vector is written back through the workspace its message came
      // from, so the write can never land in a neighbouring workspace's file.
      expect(repo.embeddedIds, containsAll(['$_ws/m1', '$_ws/m2']));
    });

    test('embeds nothing for a workspace that holds no messages', () async {
      final repo = _FakeMessagingRepository([
        _msg(id: 'm1', content: 'Hello world'),
      ]);
      final useCase = BackfillMessageEmbeddingsUseCase(
        messagingRepository: repo,
        embeddingService: _FakeEmbeddingService(),
      );

      final count = await useCase.execute('ws-other');

      expect(count, equals(0));
      expect(repo.embeddedIds, isEmpty);
    });
  });
}
