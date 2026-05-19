import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
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
  late _FakeReviewChannels reviewChannels;
  late ReviewPublisherService service;

  setUp(() {
    github = _FakeGithub();
    messaging = _FakeMessaging();
    reviewChannels = _FakeReviewChannels();
    service = ReviewPublisherService(
      githubPrClient: github,
      messaging: messaging,
      reviewChannels: reviewChannels,
    );
  });

  ReviewChannelAssociation association({
    String workspaceId = 'ws1',
    String repoFullName = 'owner/repo',
    int prNumber = 42,
    ReviewChannelStatus status = ReviewChannelStatus.awaitingApproval,
  }) => ReviewChannelAssociation(
    id: 'assoc1',
    channelId: 'ch1',
    workspaceId: workspaceId,
    prExternalId: 'PR_node1',
    prNumber: prNumber,
    repoFullName: repoFullName,
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  /// Builds a review-node channel message from a payload.
  ChannelMessage nodeMessage(
    String id, {
    required ReviewNodePayload payload,
    required String senderId,
    String content = 'finding text',
  }) => ChannelMessage(
    id: id,
    channelId: 'ch1',
    conversationId: 'ch1',
    senderId: senderId,
    senderType: ChannelSenderType.agent,
    content: content,
    messageType: ChannelMessageType.reviewNode,
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
    test('throws ArgumentError when the channel has no association', () async {
      reviewChannels.association = null;
      await expectLater(
        service.publish(workspaceId: 'ws1', channelId: 'ch1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'throws WorkspaceMismatchException when workspace does not own it',
      () async {
        reviewChannels.association = association(workspaceId: 'other');
        await expectLater(
          service.publish(workspaceId: 'ws1', channelId: 'ch1'),
          throwsA(isA<WorkspaceMismatchException>()),
        );
      },
    );

    test('throws ArgumentError on a malformed repoFullName', () async {
      reviewChannels.association = association(repoFullName: 'no-slash-here');
      await expectLater(
        service.publish(workspaceId: 'ws1', channelId: 'ch1'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ReviewPublisherService.publish — selection', () {
    test('consensus publishes only peer-confirmed findings', () async {
      reviewChannels.association = association();
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
        channelId: 'ch1',
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
        reviewChannels.association = association();
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
          channelId: 'ch1',
          selection: ReviewPublishSelection.allOpen,
        );
        expect(result.findingCount, 2);
      },
    );
  });

  group('ReviewPublisherService.publish — fallback + side effects', () {
    test('falls back to body-only on a 422 from inline submit', () async {
      reviewChannels.association = association();
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
        channelId: 'ch1',
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
      reviewChannels.association = association();
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
        service.publish(workspaceId: 'ws1', channelId: 'ch1'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('marks the association completed on success', () async {
      reviewChannels.association = association(
        status: ReviewChannelStatus.awaitingApproval,
      );
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
        ),
      ];
      await service.publish(workspaceId: 'ws1', channelId: 'ch1');
      expect(reviewChannels.updatedStatus, ReviewChannelStatus.completed);
      expect(reviewChannels.watchedWorkspaceId, 'ws1');
      expect(reviewChannels.updatedWorkspaceId, 'ws1');
      expect(messaging.readWorkspaceId, 'ws1');
    });

    test('skips the status update when already completed', () async {
      reviewChannels.association = association(
        status: ReviewChannelStatus.completed,
      );
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
        ),
      ];
      await service.publish(workspaceId: 'ws1', channelId: 'ch1');
      expect(reviewChannels.updatedStatus, isNull);
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
  List<ChannelMessage> messages = const [];

  /// Workspace the transcript read was scoped to.
  String? readWorkspaceId;

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async {
    readWorkspaceId = workspaceId;
    return messages;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeReviewChannels implements ReviewChannelRepository {
  ReviewChannelAssociation? association;
  ReviewChannelStatus? updatedStatus;

  /// Workspace the association lookup was scoped to.
  String? watchedWorkspaceId;

  /// Workspace the status write was scoped to.
  String? updatedWorkspaceId;

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  ) {
    watchedWorkspaceId = workspaceId;
    return Stream.value(association);
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewChannelStatus status,
  ) async {
    updatedWorkspaceId = workspaceId;
    updatedStatus = status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
