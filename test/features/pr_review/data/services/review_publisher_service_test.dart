import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
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
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_infra/src/git/review_publisher_service.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:dio/dio.dart';
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
  }) async => '';

  @override
  Stream<List<Channel>> watchChannels() => const Stream.empty();
  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => const Stream.empty();
  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
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
  ReviewChannelAssociation? association;
  final List<({String id, ReviewChannelStatus status})> statusUpdates = [];

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(association?.channelId == channelId ? association : null);

  @override
  Stream<List<ReviewChannelAssociation>> watchAllByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(
    association?.workspaceId == workspaceId &&
            association?.channelId == channelId
        ? [association!]
        : const [],
  );

  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(null);

  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewChannelStatus status,
  ) async {
    statusUpdates.add((id: id, status: status));
    association = association?.copyWith(status: status);
  }
}

/// Fake PR client that records submit calls and can simulate a 422 on the
/// inline-comments attempt.
class _FakeGitHubPrClient extends GitHubPrClient {
  _FakeGitHubPrClient({this.rejectInlineWith422 = false}) : super(Dio());

  final bool rejectInlineWith422;
  final List<
    ({String event, String? body, List<Map<String, dynamic>>? comments})
  >
  calls = [];

  @override
  Future<GitHubReview> submitReview(
    String owner,
    String repo, {
    required int prNumber,
    required String event,
    String? body,
    String? commitId,
    List<Map<String, dynamic>>? comments,
    CancelToken? cancelToken,
  }) async {
    calls.add((event: event, body: body, comments: comments));
    if (rejectInlineWith422 && comments != null && comments.isNotEmpty) {
      throw const NetworkException('Unprocessable entity', statusCode: 422);
    }
    return GitHubReview(
      id: 7001,
      state: GitHubReviewState.commented,
      body: body ?? '',
      submittedAt: DateTime.utc(2026),
    );
  }
}

ReviewChannelAssociation _assoc({
  String workspaceId = 'ws',
  String channelId = 'ch-1',
  ReviewChannelStatus status = ReviewChannelStatus.inProgress,
}) {
  return ReviewChannelAssociation(
    id: 'r-1',
    channelId: channelId,
    workspaceId: workspaceId,
    prExternalId: 'pr-node',
    prNumber: 42,
    repoFullName: 'org/repo',
    status: status,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

ChannelMessage _node({
  required String id,
  required String authorId,
  String channelId = 'ch-1',
  String priority = 'p1',
  String content = 'finding',
  List<String> confirmedBy = const [],
  String status = 'open',
  String? filePath,
  int? lineNumber,
  int? lineEnd,
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
      'nodeType': 'bug',
      'priority': priority,
      'confidence': 0.85,
      'status': status,
      'confirmedBy': confirmedBy,
      'filePath': ?filePath,
      'lineNumber': ?lineNumber,
      'lineEnd': ?lineEnd,
    },
    createdAt: DateTime.utc(2026),
  );
}

void main() {
  group('ReviewPublisherService', () {
    test('publishes consensus findings inline and marks completed', () async {
      final github = _FakeGitHubPrClient();
      final reviews = _FakeReviewChannels(_assoc());
      final service = ReviewPublisherService(
        githubPrClient: github,
        messaging: _FakeMessaging([
          // consensus + anchored → inline
          _node(
            id: 'n-1',
            authorId: 'qa',
            confirmedBy: ['arch'],
            priority: 'p1',
            filePath: 'lib/a.dart',
            lineNumber: 10,
          ),
          // not consensus → skipped
          _node(
            id: 'n-2',
            authorId: 'eng',
            priority: 'p0',
            filePath: 'lib/b.dart',
            lineNumber: 3,
          ),
          // consensus but unanchored → body
          _node(
            id: 'n-3',
            authorId: 'arch',
            confirmedBy: ['qa'],
            priority: 'p2',
          ),
        ]),
        reviewChannels: reviews,
      );

      final result = await service.publish(
        workspaceId: 'ws',
        channelId: 'ch-1',
      );

      expect(github.calls, hasLength(1));
      expect(github.calls.single.comments, hasLength(1));
      expect(github.calls.single.event, 'COMMENT'); // p1 present → hold
      expect(result.findingCount, 2); // n-1 + n-3 (n-2 excluded)
      expect(result.inlineCount, 1);
      expect(result.usedFallback, isFalse);
      expect(reviews.statusUpdates.last.status, ReviewChannelStatus.completed);
    });

    test('rejects a channel owned by another workspace', () async {
      final service = ReviewPublisherService(
        githubPrClient: _FakeGitHubPrClient(),
        messaging: _FakeMessaging([]),
        reviewChannels: _FakeReviewChannels(_assoc(workspaceId: 'ws-A')),
      );

      expect(
        () => service.publish(workspaceId: 'ws-B', channelId: 'ch-1'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test(
      'falls back to body when GitHub rejects the inline anchors (422)',
      () async {
        final github = _FakeGitHubPrClient(rejectInlineWith422: true);
        final service = ReviewPublisherService(
          githubPrClient: github,
          messaging: _FakeMessaging([
            _node(
              id: 'n-1',
              authorId: 'qa',
              confirmedBy: ['arch'],
              filePath: 'lib/a.dart',
              lineNumber: 999,
            ),
          ]),
          reviewChannels: _FakeReviewChannels(_assoc()),
        );

        final result = await service.publish(
          workspaceId: 'ws',
          channelId: 'ch-1',
        );

        expect(github.calls, hasLength(2));
        expect(github.calls.first.comments, isNotEmpty);
        expect(github.calls.last.comments, anyOf(isNull, isEmpty));
        expect(result.usedFallback, isTrue);
        expect(result.inlineCount, 0);
        expect(github.calls.last.body, contains('Inline findings'));
      },
    );

    test('all_open selection includes unconfirmed findings', () async {
      final github = _FakeGitHubPrClient();
      final service = ReviewPublisherService(
        githubPrClient: github,
        messaging: _FakeMessaging([
          _node(
            id: 'n-1',
            authorId: 'eng',
            filePath: 'lib/a.dart',
            lineNumber: 5,
          ),
        ]),
        reviewChannels: _FakeReviewChannels(_assoc()),
      );

      final consensus = await service.publish(
        workspaceId: 'ws',
        channelId: 'ch-1',
      );
      expect(consensus.findingCount, 0);

      final allOpen = await service.publish(
        workspaceId: 'ws',
        channelId: 'ch-1',
        selection: ReviewPublishSelection.allOpen,
      );
      expect(allOpen.findingCount, 1);
      expect(allOpen.inlineCount, 1);
    });

    test('errors when the channel is not linked to a review', () async {
      final service = ReviewPublisherService(
        githubPrClient: _FakeGitHubPrClient(),
        messaging: _FakeMessaging([]),
        reviewChannels: _FakeReviewChannels(_assoc(channelId: 'ch-OTHER')),
      );

      expect(
        () => service.publish(workspaceId: 'ws', channelId: 'ch-1'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
