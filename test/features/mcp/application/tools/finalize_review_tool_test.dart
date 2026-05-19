import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_mcp/src/tools/finalize_review_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging(this._messages);
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
  final List<ChannelMessage> _messages;
  final List<Map<String, dynamic>> sent = [];

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
  }) async => _messages.where((m) => m.channelId == channelId).toList();

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);
  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => Stream.value(_messages);
  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => Stream.value([]);
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
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {}
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
}

class _FakeReviewChannels implements ReviewChannelRepository {
  _FakeReviewChannels(this.association);
  ReviewChannelAssociation association;
  final List<({String id, ReviewChannelStatus status})> statusUpdates = [];

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(
    association.workspaceId == workspaceId && association.channelId == channelId
        ? association
        : null,
  );

  @override
  Stream<List<ReviewChannelAssociation>> watchAllByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(
    association.workspaceId == workspaceId && association.channelId == channelId
        ? [association]
        : const [],
  );

  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prNodeId,
  ) => Stream.value(null);

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
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewChannelStatus status,
  ) async {
    if (association.workspaceId != workspaceId || association.id != id) {
      return;
    }
    statusUpdates.add((id: id, status: status));
    association = association.copyWith(status: status);
  }
}

class _FakeAxisRepo implements ReviewAxisResultRepository {
  _FakeAxisRepo(this._results);
  final List<ReviewAxisResult> _results;
  final List<ReviewAxisResult> upserts = [];

  @override
  Future<List<ReviewAxisResult>> forPr(
    String workspaceId,
    String prNodeId,
  ) async => _results;
  @override
  Stream<List<ReviewAxisResult>> watchForPr(
    String workspaceId,
    String prNodeId,
  ) => Stream.value(_results);
  @override
  Future<void> upsert(
    String workspaceId,
    String prNodeId,
    ReviewAxisResult result,
  ) async {
    upserts.add(result);
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
    conversationId: channelId,
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
          'workspace_id': 'ws',
          'channel_id': 'ch-1',
          'finalizer_id': 'ceo',
        });

        expect(result.isError, isFalse);
        final json =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(json['consensus_ready'], 1);
        expect(json['needs_adjudication'], 1);
        expect(json['status'], 'awaiting_approval');
        expect(
          reviews.statusUpdates.last.status,
          ReviewChannelStatus.awaitingApproval,
        );
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
          'workspace_id': 'ws',
          'channel_id': 'ch-1',
          'finalizer_id': 'ceo',
        });

        final json =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
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
        'workspace_id': 'ws',
        'channel_id': 'ch-1',
        'finalizer_id': 'ceo',
      });
      expect(result.isError, isTrue);
    });

    test('a gated failing axis escalates the finding verdict to block', () async {
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
      // Only p1 findings → the finding-only verdict is HOLD (no p0).
      final messaging = _FakeMessaging([
        _node(id: 'n-1', channelId: 'ch-1', authorId: 'a', kind: 'suggestion'),
      ]);
      // A gated, failing contract axis (deterministic engine) must escalate the
      // authoritative verdict to BLOCK.
      final axes = _FakeAxisRepo([
        const ReviewAxisResult(
          axis: ReviewAxis.apiContract,
          verdict: ReviewAxisVerdict.fail,
          findingsCount: 1,
          gated: true,
          confidence: 0.9,
        ),
      ]);
      final tool = FinalizeReviewTool(
        messaging: messaging,
        reviewChannels: _FakeReviewChannels(assoc),
        reviewAxisResults: axes,
      );

      final result = await tool.call({
        'workspace_id': 'ws',
        'channel_id': 'ch-1',
        'finalizer_id': 'ceo',
      });

      expect(result.isError, isFalse);
      final summary = messaging.sent.firstWhere(
        (m) => m['messageType'] == 'review_summary',
      );
      final metadata = summary['metadata'] as Map<String, dynamic>;
      expect(metadata['verdict'], 'block');
    });
  });
}
