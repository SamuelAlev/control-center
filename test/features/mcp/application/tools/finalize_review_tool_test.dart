import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/entities/review_channel_association.dart';
import 'package:control_center/core/domain/repositories/review_channel_repository.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/mcp/application/tools/finalize_review_tool.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessaging implements MessagingRepository {
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
      watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
          Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  _FakeMessaging(this._messages);
  final List<ChannelMessage> _messages;
  final List<Map<String, dynamic>> sent = [];

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
    sent.add({
      'channelId': channelId,
      'content': content,
      'senderId': senderId,
      'messageType': messageType,
      'metadata': metadata,
    });
    return '';
  }

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async =>
      _messages.where((m) => m.channelId == channelId).toList();

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);
  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      Stream.value(_messages);
  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      Stream.value([]);
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
  Future<List<ChannelParticipant>> getParticipants(String channelId) async =>
      [];
  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {}
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
  @override
  Future<void> updateMessageEmbedding(
    String messageId,
    Uint8List embedding,
  ) async {}
  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String channelId,
  ) async => [];
  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({
    int limit = 200,
  }) async => [];
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
}

class _FakeReviewChannels implements ReviewChannelRepository {
  _FakeReviewChannels(this.association);
  ReviewChannelAssociation association;
  final List<({String id, ReviewChannelStatus status})> statusUpdates = [];

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(String channelId) =>
      Stream.value(
        association.channelId == channelId ? association : null,
      );

  @override
  Stream<ReviewChannelAssociation?> watchByPr(String workspaceId, String prNodeId) =>
      Stream.value(null);

  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prNodeId,
    required int prNumber,
    required String repoFullName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateStatus(String id, ReviewChannelStatus status) async {
    statusUpdates.add((id: id, status: status));
    association = association.copyWith(status: status);
  }
}

ChannelMessage _node({
  required String id,
  required String channelId,
  required String authorId,
  required String kind,
  String content = 'finding',
  List<String> confirmedBy = const [],
}) {
  return ChannelMessage(
    id: id,
    channelId: channelId,
    senderId: authorId,
    senderType: ChannelSenderType.agent,
    content: content,
    messageType: ChannelMessageType.reviewNode,
    metadata: {
      'nodeType': kind,
      'priority': 'p1',
      'confidence': 0.85,
      'status': 'open',
      'confirmedBy': confirmedBy,
    },
    createdAt: DateTime.utc(2026),
  );
}

void main() {
  group('FinalizeReviewTool consensus', () {
    test(
      'classifies as consensus-ready when a peer (not the author) confirms',
      () async {
        final assoc = ReviewChannelAssociation(
          id: 'r-1',
          channelId: 'ch-1',
          workspaceId: 'ws',
          prNodeId: 'pr-1',
          prNumber: 42,
          repoFullName: 'org/repo',
          status: ReviewChannelStatus.inProgress,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        final messaging = _FakeMessaging([
          _node(
            id: 'n-1',
            channelId: 'ch-1',
            authorId: 'security',
            kind: 'bug',
            confirmedBy: ['backend'],
          ),
          _node(
            id: 'n-2',
            channelId: 'ch-1',
            authorId: 'frontend',
            kind: 'suggestion',
          ),
        ]);
        final reviews = _FakeReviewChannels(assoc);
        final tool = FinalizeReviewTool(
          messaging: messaging,
          reviewChannels: reviews,
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'finalizer_id': 'ceo',
        });

        expect(result.isError, isFalse);
        final json = jsonDecode(result.content.first.text)
            as Map<String, dynamic>;
        expect(json['consensus_ready'], 1);
        expect(json['needs_adjudication'], 1);
        expect(json['status'], 'awaiting_approval');
        expect(reviews.statusUpdates.last.status,
            ReviewChannelStatus.awaitingApproval);
      },
    );

    test(
      'a node confirmed only by its own author is NOT consensus-ready',
      () async {
        final assoc = ReviewChannelAssociation(
          id: 'r-1',
          channelId: 'ch-1',
          workspaceId: 'ws',
          prNodeId: 'pr-1',
          prNumber: 42,
          repoFullName: 'org/repo',
          status: ReviewChannelStatus.inProgress,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        final messaging = _FakeMessaging([
          _node(
            id: 'n-1',
            channelId: 'ch-1',
            authorId: 'security',
            kind: 'bug',
            confirmedBy: ['security'], // self-confirmation, should be stripped
          ),
        ]);
        final tool = FinalizeReviewTool(
          messaging: messaging,
          reviewChannels: _FakeReviewChannels(assoc),
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'finalizer_id': 'ceo',
        });

        final json = jsonDecode(result.content.first.text)
            as Map<String, dynamic>;
        expect(json['consensus_ready'], 0);
        expect(json['needs_adjudication'], 1);
      },
    );

    test('errors when channel is not linked to a review', () async {
      final assoc = ReviewChannelAssociation(
        id: 'r-1',
        channelId: 'ch-OTHER',
        workspaceId: 'ws',
        prNodeId: 'pr-1',
        prNumber: 42,
        repoFullName: 'org/repo',
          status: ReviewChannelStatus.inProgress,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final tool = FinalizeReviewTool(
        messaging: _FakeMessaging([]),
        reviewChannels: _FakeReviewChannels(assoc),
      );

      final result = await tool.call({
        'channel_id': 'ch-1',
        'finalizer_id': 'ceo',
      });
      expect(result.isError, isTrue);
    });
  });
}
