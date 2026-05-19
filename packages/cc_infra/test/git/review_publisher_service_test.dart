import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_infra/src/git/review_publisher_service.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [ReviewPublisherService] with faked repositories and a
/// [GitHubPrClient] subclass that captures `submitReview` calls. Covers: the
/// workspace-mismatch guard, the missing-association guard, the malformed
/// repoFullName guard, the consensus selection rule (author self-confirm does
/// not count, dismissed/resolved are skipped, allOpen publishes unconfirmed),
/// the 422 inline-fallback path and the status-set-to-completed side effect.
void main() {
  late _FakeGithub github;
  late _FakeMessaging messaging;
  late _FakeReviewSpaces reviewSpaces;
  late ReviewPublisherService service;

  setUp(() {
    github = _FakeGithub();
    messaging = _FakeMessaging();
    reviewSpaces = _FakeReviewSpaces();
    service = ReviewPublisherService(
      githubPrClientFor: (_) => github,
      messaging: messaging,
      reviewSpaces: reviewSpaces,
    );
  });

  ReviewSpaceAssociation association({
    String workspaceId = 'ws1',
    String repoFullName = 'owner/repo',
    int prNumber = 42,
    ReviewSpaceStatus status = ReviewSpaceStatus.awaitingApproval,
  }) => ReviewSpaceAssociation(
    id: 'assoc1',
    spaceId: 'ch1',
    workspaceId: workspaceId,
    prExternalId: 'PR_node1',
    prNumber: prNumber,
    repoFullName: repoFullName,
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  /// Builds a review-node space message from a payload.
  Message nodeMessage(
    String id, {
    required ReviewNodePayload payload,
    required String senderId,
    String content = 'finding text',
  }) => Message(
    id: id,
    spaceId: 'ch1',
    conversationId: 'ch1',
    senderId: senderId,
    senderType: SenderType.agent,
    content: content,
    messageType: MessageType.reviewNode,
    metadata: payload.toMetadata(),
    createdAt: DateTime.utc(2026, 1, 1),
  );

  ReviewNodePayload payload({
    ReviewNodeStatus status = ReviewNodeStatus.consensusReady,
    List<String> confirmedBy = const ['peer'],
    ReviewNodePriority priority = ReviewNodePriority.p0,
    double confidence = 0.9,
    String? filePath = 'lib/a.dart',
  }) => ReviewNodePayload(
    kind: ReviewNodeKind.bug,
    priority: priority,
    confidence: confidence,
    anchor: ReviewNodeAnchor(filePath: filePath, lineNumber: 10),
    status: status,
    confirmedBy: confirmedBy,
  );

  group('ReviewPublisherService.publish — guards', () {
    test('throws ArgumentError when the space has no association', () async {
      reviewSpaces.association = null;
      await expectLater(
        service.publish(workspaceId: 'ws1', spaceId: 'ch1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'throws WorkspaceMismatchException when workspace does not own it',
      () async {
        reviewSpaces.association = association(workspaceId: 'other');
        await expectLater(
          service.publish(workspaceId: 'ws1', spaceId: 'ch1'),
          throwsA(isA<WorkspaceMismatchException>()),
        );
      },
    );

    test('throws ArgumentError on a malformed repoFullName', () async {
      reviewSpaces.association = association(repoFullName: 'no-slash-here');
      await expectLater(
        service.publish(workspaceId: 'ws1', spaceId: 'ch1'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ReviewPublisherService.publish — selection', () {
    test('consensus publishes only peer-confirmed findings', () async {
      reviewSpaces.association = association();
      messaging.messages = [
        // Confirmed by a peer → published.
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
        ),
        // Only confirmed by the author → dropped under consensus.
        nodeMessage(
          'm2',
          payload: payload(confirmedBy: ['a2']),
          senderId: 'a2',
        ),
        // Dismissed → always dropped.
        nodeMessage(
          'm3',
          payload: payload(status: ReviewNodeStatus.dismissed),
          senderId: 'a3',
        ),
        // Resolved → always dropped.
        nodeMessage(
          'm4',
          payload: payload(status: ReviewNodeStatus.resolved),
          senderId: 'a4',
        ),
      ];
      final result = await service.publish(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        selection: ReviewPublishSelection.consensus,
      );
      expect(result.findingCount, 1);
      expect(result.usedFallback, isFalse);
      expect(github.submits, hasLength(1));
      expect(github.submits.single.owner, 'owner');
      expect(github.submits.single.repo, 'repo');
      expect(github.submits.single.prNumber, 42);
    });

    test(
      'allOpen publishes every open finding regardless of confirmation',
      () async {
        reviewSpaces.association = association();
        messaging.messages = [
          nodeMessage(
            'm1',
            payload: payload(confirmedBy: ['peer']),
            senderId: 'a1',
          ),
          nodeMessage(
            'm2',
            payload: payload(confirmedBy: const []),
            senderId: 'a2',
          ),
        ];
        final result = await service.publish(
          workspaceId: 'ws1',
          spaceId: 'ch1',
          selection: ReviewPublishSelection.allOpen,
        );
        expect(result.findingCount, 2);
      },
    );
  });

  group('ReviewPublisherService.publish — fallback + side effects', () {
    test('falls back to body-only on a 422 from inline submit', () async {
      reviewSpaces.association = association();
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer'], filePath: 'lib/x.dart'),
          senderId: 'a1',
        ),
      ];
      github
        ..firstSubmitThrows422 = true
        ..reviewId = 999;
      final result = await service.publish(
        workspaceId: 'ws1',
        spaceId: 'ch1',
      );
      expect(result.usedFallback, isTrue);
      expect(result.inlineCount, 0); // fallback → no inline comments
      expect(result.reviewId, 999);
      // Two submit attempts: the rejected inline one, then the body fallback.
      expect(github.submits, hasLength(2));
      // The first attempt carried comments; the second did not.
      expect(github.submits.first.comments, isNotNull);
      expect(github.submits.last.comments, isNull);
    });

    test('rethrows non-422 NetworkException from inline submit', () async {
      reviewSpaces.association = association();
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer'], filePath: 'lib/x.dart'),
          senderId: 'a1',
        ),
      ];
      github.firstSubmitThrows = const NetworkException(
        'forbidden',
        statusCode: 403,
      );
      await expectLater(
        service.publish(workspaceId: 'ws1', spaceId: 'ch1'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('marks the association completed on success', () async {
      reviewSpaces.association = association(
        status: ReviewSpaceStatus.awaitingApproval,
      );
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
        ),
      ];
      await service.publish(workspaceId: 'ws1', spaceId: 'ch1');
      expect(reviewSpaces.updatedStatus, ReviewSpaceStatus.completed);
      expect(reviewSpaces.watchedWorkspaceId, 'ws1');
      expect(reviewSpaces.updatedWorkspaceId, 'ws1');
      expect(messaging.readWorkspaceId, 'ws1');
    });

    test('skips the status update when already completed', () async {
      reviewSpaces.association = association(
        status: ReviewSpaceStatus.completed,
      );
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
        ),
      ];
      await service.publish(workspaceId: 'ws1', spaceId: 'ch1');
      expect(reviewSpaces.updatedStatus, isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _SubmitCall {
  _SubmitCall(this.owner, this.repo, this.prNumber, this.comments);
  final String owner;
  final String repo;
  final int prNumber;
  final List<Map<String, dynamic>>? comments;
}

/// A [GitHubPrClient] subclass that captures `submitReview` calls. The real
/// constructor needs a [Dio], but every networked method is overridden so the
/// Dio is never used.
class _FakeGithub extends GitHubPrClient {
  _FakeGithub() : super(Dio());

  final submits = <_SubmitCall>[];
  int reviewId = 1;
  bool firstSubmitThrows422 = false;
  NetworkException? firstSubmitThrows;

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
    final call = _SubmitCall(owner, repo, prNumber, comments);
    submits.add(call);
    if (submits.length == 1) {
      if (firstSubmitThrows != null) {
        throw firstSubmitThrows!;
      }
      if (firstSubmitThrows422) {
        throw const NetworkException('unprocessable', statusCode: 422);
      }
    }
    return GitHubReview(
      id: reviewId,
      state: GitHubReviewState.commented,
      body: body ?? '',
      submittedAt: DateTime.utc(2026, 1, 1),
    );
  }
}

class _FakeMessaging implements MessagingRepository {
  List<Message> messages = const [];

  /// Workspace the transcript read was scoped to.
  String? readWorkspaceId;

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async {
    readWorkspaceId = workspaceId;
    return messages;
  }

  // The publisher reads space-wide (findings live in each reviewer's own
  // stream), so this is the one the service actually calls.
  @override
  Future<List<Message>> getSpaceMessages(
    String workspaceId,
    String spaceId,
  ) async {
    readWorkspaceId = workspaceId;
    return messages;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}

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
  ReviewSpaceAssociation? association;
  ReviewSpaceStatus? updatedStatus;

  /// Workspace the association lookup was scoped to.
  String? watchedWorkspaceId;

  /// Workspace the status write was scoped to.
  String? updatedWorkspaceId;

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) {
    watchedWorkspaceId = workspaceId;
    return Stream.value(association);
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
  ) async {
    updatedWorkspaceId = workspaceId;
    updatedStatus = status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
