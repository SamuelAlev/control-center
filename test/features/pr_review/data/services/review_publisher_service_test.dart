import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_infra/src/git/review_publisher_service.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging(this._messages);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {}
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
  final List<Message> _messages;

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
  }) async => _messages.where((m) => m.spaceId == spaceId).toList();

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
  }) async => '';

  @override
  Stream<List<Space>> watchSpaces() => const Stream.empty();
  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => const Stream.empty();
  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => const Stream.empty();
  @override
  Future<void> setSpaceMode(
    String workspaceId,
    String spaceId,
    Mode mode,
  ) async {}
  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
  }) => throw UnimplementedError();
  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {}
  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async => true;
  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => [];
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
    Uint8List embedding,
  ) async {}
  @override
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) async => [];
  @override
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];
  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      const Stream.empty();
  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      null;

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => MessagePage.empty;

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async => const [];

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async => const [];

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

class _FakeReviewSpaces implements ReviewSpaceRepository {
  _FakeReviewSpaces(this.association);
  ReviewSpaceAssociation? association;
  final List<({String id, ReviewSpaceStatus status})> statusUpdates = [];

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(association?.spaceId == spaceId ? association : null);

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(
    association?.workspaceId == workspaceId && association?.spaceId == spaceId
        ? [association!]
        : const [],
  );

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(null);

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Future<ReviewSpaceAssociation> create({
    required String spaceId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
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

ReviewSpaceAssociation _assoc({
  String workspaceId = 'ws',
  String spaceId = 'ch-1',
  ReviewSpaceStatus status = ReviewSpaceStatus.inProgress,
}) {
  return ReviewSpaceAssociation(
    id: 'r-1',
    spaceId: spaceId,
    workspaceId: workspaceId,
    prExternalId: 'pr-node',
    prNumber: 42,
    repoFullName: 'org/repo',
    status: status,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

Message _node({
  required String id,
  required String authorId,
  String spaceId = 'ch-1',
  String priority = 'p1',
  String content = 'finding',
  List<String> confirmedBy = const [],
  String status = 'open',
  String? filePath,
  int? lineNumber,
  int? lineEnd,
}) {
  return Message(
    id: id,
    spaceId: spaceId,
    conversationId: spaceId,
    senderId: authorId,
    senderType: SenderType.agent,
    content: content,
    messageType: MessageType.reviewNode,
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
      final reviews = _FakeReviewSpaces(_assoc());
      final service = ReviewPublisherService(
        githubPrClientFor: (_) => github,
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
        reviewSpaces: reviews,
      );

      final result = await service.publish(workspaceId: 'ws', spaceId: 'ch-1');

      expect(github.calls, hasLength(1));
      expect(github.calls.single.comments, hasLength(1));
      expect(github.calls.single.event, 'COMMENT'); // p1 present → hold
      expect(result.findingCount, 2); // n-1 + n-3 (n-2 excluded)
      expect(result.inlineCount, 1);
      expect(result.usedFallback, isFalse);
      expect(reviews.statusUpdates.last.status, ReviewSpaceStatus.completed);
    });

    test('rejects a space owned by another workspace', () async {
      final service = ReviewPublisherService(
        githubPrClientFor: (_) => _FakeGitHubPrClient(),
        messaging: _FakeMessaging([]),
        reviewSpaces: _FakeReviewSpaces(_assoc(workspaceId: 'ws-A')),
      );

      expect(
        () => service.publish(workspaceId: 'ws-B', spaceId: 'ch-1'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test(
      'falls back to body when GitHub rejects the inline anchors (422)',
      () async {
        final github = _FakeGitHubPrClient(rejectInlineWith422: true);
        final service = ReviewPublisherService(
          githubPrClientFor: (_) => github,
          messaging: _FakeMessaging([
            _node(
              id: 'n-1',
              authorId: 'qa',
              confirmedBy: ['arch'],
              filePath: 'lib/a.dart',
              lineNumber: 999,
            ),
          ]),
          reviewSpaces: _FakeReviewSpaces(_assoc()),
        );

        final result = await service.publish(
          workspaceId: 'ws',
          spaceId: 'ch-1',
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
        githubPrClientFor: (_) => github,
        messaging: _FakeMessaging([
          _node(
            id: 'n-1',
            authorId: 'eng',
            filePath: 'lib/a.dart',
            lineNumber: 5,
          ),
        ]),
        reviewSpaces: _FakeReviewSpaces(_assoc()),
      );

      final consensus = await service.publish(
        workspaceId: 'ws',
        spaceId: 'ch-1',
      );
      expect(consensus.findingCount, 0);

      final allOpen = await service.publish(
        workspaceId: 'ws',
        spaceId: 'ch-1',
        selection: ReviewPublishSelection.allOpen,
      );
      expect(allOpen.findingCount, 1);
      expect(allOpen.inlineCount, 1);
    });

    test('errors when the space is not linked to a review', () async {
      final service = ReviewPublisherService(
        githubPrClientFor: (_) => _FakeGitHubPrClient(),
        messaging: _FakeMessaging([]),
        reviewSpaces: _FakeReviewSpaces(_assoc(spaceId: 'ch-OTHER')),
      );

      expect(
        () => service.publish(workspaceId: 'ws', spaceId: 'ch-1'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
