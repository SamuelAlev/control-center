import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_infra/src/git/review_publisher_service.dart';
import 'package:cc_infra/src/network/github/github_forge_pr_client.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart' show HttpMethod;
import 'package:test/test.dart';

/// Exercises [ReviewPublisherService] with faked repositories and a
/// [ForgePrClient] fake that captures `submitReview` calls. Covers: the
/// workspace-mismatch guard, the missing-association guard, the unlinked-repo
/// guard, routing by the association's repo, the consensus selection rule
/// (author self-confirm does not count, dismissed/resolved are skipped,
/// allOpen publishes unconfirmed), capability gating, the 422 inline-fallback
/// path and the status-set-to-completed side effect.
void main() {
  late _FakeForge github;
  late _FakeMessaging messaging;
  late _FakeReviewSpaces reviewSpaces;
  late ReviewPublisherService service;
  late List<({String? actingUserId, String workspaceId, String repo})> resolved;

  setUp(() {
    github = _FakeForge();
    messaging = _FakeMessaging();
    reviewSpaces = _FakeReviewSpaces();
    resolved = [];
    service = ReviewPublisherService(
      forgeClientFor:
          (actingUserId, {required workspaceId, required repoFullName}) async {
            resolved.add((
              actingUserId: actingUserId,
              workspaceId: workspaceId,
              repo: repoFullName,
            ));
            return repoFullName == 'owner/repo' ? github : null;
          },
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

    test('refuses a repo the workspace does not link', () async {
      reviewSpaces.association = association(repoFullName: 'other/repo');
      await expectLater(
        service.publish(workspaceId: 'ws1', spaceId: 'ch1'),
        throwsA(isA<StateError>()),
      );
      expect(github.submits, isEmpty);
    });
  });

  group('ReviewPublisherService.publish — the approval chokepoint', () {
    late TestHttpClient http;
    late List<int> guarded;
    late ReviewPublisherService onGitHub;

    setUp(() {
      guarded = [];
      http = TestHttpClient(
        handler: (request) => request.method == HttpMethod.post
            ? httpTextResponse(request, const {'id': 7})
            // The PR's file list: empty, so every anchor is accepted.
            : httpTextResponse(request, const <Object>[]),
      );
      final client = GitHubForgePrClient(
        client: GitHubApiClient(http),
        owner: 'owner',
        repo: 'repo',
        approvalGuard: (_, prNumber) async {
          guarded.add(prNumber);
          throw const ValidationException(
            'An agent opened this pull request at your request.',
          );
        },
      );
      onGitHub = ReviewPublisherService(
        forgeClientFor:
            (
              actingUserId, {
              required workspaceId,
              required repoFullName,
            }) async => client,
        messaging: messaging,
        reviewSpaces: reviewSpaces,
      );
      reviewSpaces.association = association();
      messaging.messages = [];
    });

    test('an approve-on-ship publish meets the forge client\'s approval '
        'guard before anything is sent', () async {
      await expectLater(
        onGitHub.publish(
          workspaceId: 'ws1',
          spaceId: 'ch1',
          approveOnShip: true,
          actingUserId: 'alice',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(guarded, [42]);
      expect(http.requests.where((r) => r.method == HttpMethod.post), isEmpty);
      expect(reviewSpaces.updatedStatus, isNull);
    });

    test('a comment review never asks the guard', () async {
      final result = await onGitHub.publish(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        actingUserId: 'alice',
      );
      expect(result.event, 'COMMENT');
      expect(guarded, isEmpty);
      expect(
        http.requests.where((r) => r.method == HttpMethod.post),
        hasLength(1),
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
      expect(github.submits.single.prNumber, 42);
      expect(resolved.single, (
        actingUserId: null,
        workspaceId: 'ws1',
        repo: 'owner/repo',
      ));
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
      final result = await service.publish(workspaceId: 'ws1', spaceId: 'ch1');
      expect(result.usedFallback, isTrue);
      expect(result.inlineCount, 0); // fallback → no inline comments
      expect(result.reviewId, 999);
      // Two submit attempts: the rejected inline one, then the body fallback.
      expect(github.submits, hasLength(2));
      // The first attempt carried comments; the second did not.
      expect(github.submits.first.comments, isNotEmpty);
      expect(github.submits.last.comments, isEmpty);
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

  group('ReviewPublisherService.publish — attribution', () {
    ReviewPublisherService attributing({required bool asPerson}) =>
        ReviewPublisherService(
          forgeClientFor:
              (_, {required workspaceId, required repoFullName}) async =>
                  github,
          messaging: messaging,
          reviewSpaces: reviewSpaces,
          automatedAttribution:
              ({required workspaceId, required owner, actingUserId}) async =>
                  asPerson ? (body) => '[cc for @octo] $body' : null,
        );

    setUp(() {
      reviewSpaces.association = association();
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
          content: 'null check missing',
        ),
      ];
    });

    test('automation posting under a person names itself everywhere, inline '
        'comments included', () async {
      await attributing(
        asPerson: true,
      ).publish(workspaceId: 'ws1', spaceId: 'ch1');
      final submit = github.submits.single;
      expect(submit.body, startsWith('[cc for @octo] '));
      expect(submit.comments, isNotEmpty);
      for (final comment in submit.comments) {
        expect(comment.body, startsWith('[cc for @octo] '));
      }
    });

    test('a bot account needs no prefix', () async {
      await attributing(
        asPerson: false,
      ).publish(workspaceId: 'ws1', spaceId: 'ch1');
      final submit = github.submits.single;
      expect(submit.body, isNot(startsWith('[cc for @octo]')));
      for (final comment in submit.comments) {
        expect(comment.body, isNot(startsWith('[cc for @octo]')));
      }
    });

    test(
      'a person pressing publish posts their own, unattributed review',
      () async {
        await attributing(
          asPerson: true,
        ).publish(workspaceId: 'ws1', spaceId: 'ch1', actingUserId: 'alice');
        expect(github.submits.single.body, isNot(startsWith('[cc for @octo]')));
      },
    );

    test('agent text automation posts pings no one; the prefix still names '
        'the person', () async {
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
          content: 'null check missing, cc @acme/security and @mallory',
        ),
      ];
      for (final asPerson in [true, false]) {
        github.submits.clear();
        await attributing(
          asPerson: asPerson,
        ).publish(workspaceId: 'ws1', spaceId: 'ch1');
        final submit = github.submits.single;
        final bodies = [submit.body, for (final c in submit.comments) c.body];
        expect(bodies.join(), contains('null check missing'));
        for (final body in bodies) {
          expect(body, isNot(contains('@acme/security')));
          expect(body, isNot(contains('@mallory')));
        }
        if (asPerson) {
          expect(submit.body, startsWith('[cc for @octo] '));
        }
      }
    });

    test('a person publishing their own review keeps their mentions', () async {
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
          content: 'null check missing, cc @mallory',
        ),
      ];
      await attributing(
        asPerson: true,
      ).publish(workspaceId: 'ws1', spaceId: 'ch1', actingUserId: 'alice');
      final submit = github.submits.single;
      expect(
        [submit.body, for (final c in submit.comments) c.body].join(),
        contains('@mallory'),
      );
    });

    test('automation on another forge carries no GitHub attribution', () async {
      github.forge = ForgeHost.gitlab;
      await attributing(
        asPerson: true,
      ).publish(workspaceId: 'ws1', spaceId: 'ch1');
      expect(github.submits.single.body, isNot(startsWith('[cc for @octo]')));
    });
  });

  group('ReviewPublisherService.publish — forge routing', () {
    setUp(() {
      messaging.messages = [
        nodeMessage(
          'm1',
          payload: payload(confirmedBy: ['peer']),
          senderId: 'a1',
        ),
      ];
    });

    test('publishes on the GitLab client the repo resolves to, as the person '
        'who pressed publish', () async {
      github.forge = ForgeHost.gitlab;
      github.reviewId = null;
      reviewSpaces.association = association();
      final result = await service.publish(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        actingUserId: 'alice',
      );
      expect(resolved.single.actingUserId, 'alice');
      expect(github.submits.single.verdict, ForgeReviewVerdict.requestChanges);
      expect(result.reviewId, isNull);
      expect(github.filesRead, 1);
    });

    test('a forge without "changes requested" gets a comment review', () async {
      github
        ..forge = ForgeHost.local
        ..caps = const ForgeCapabilities(forge: ForgeHost.local, supported: {});
      reviewSpaces.association = association();
      final result = await service.publish(workspaceId: 'ws1', spaceId: 'ch1');
      expect(github.submits.single.verdict, ForgeReviewVerdict.comment);
      expect(result.event, 'COMMENT');
    });
  });
}

class _SubmitCall {
  _SubmitCall(this.prNumber, this.verdict, this.comments, this.body);
  final int prNumber;
  final ForgeReviewVerdict verdict;
  final List<PendingReviewComment> comments;
  final String? body;
}

/// A [ForgePrClient] that captures `submitReview` calls and answers the diff
/// read empty (so the anchor index is permissive).
class _FakeForge implements ForgePrClient {
  @override
  ForgeHost forge = ForgeHost.github;

  ForgeCapabilities? caps;

  @override
  ForgeCapabilities get capabilities => caps ?? capabilitiesOf(forge);

  @override
  String get owner => 'owner';

  @override
  String get repo => 'repo';

  final submits = <_SubmitCall>[];
  int? reviewId = 1;
  int filesRead = 0;
  bool firstSubmitThrows422 = false;
  NetworkException? firstSubmitThrows;

  @override
  Future<PrFileListing> listFiles(
    int prNumber, {
    int? limit,
    ForgeCancelToken? cancelToken,
  }) async {
    filesRead++;
    return const PrFileListing([]);
  }

  @override
  Future<int?> submitReview({
    required int prNumber,
    required ForgeReviewVerdict verdict,
    String? body,
    List<PendingReviewComment> comments = const [],
    ForgeCancelToken? cancelToken,
  }) async {
    if (verdict == ForgeReviewVerdict.requestChanges &&
        !capabilities.requestChanges) {
      throw ForgeUnsupportedError(forge, 'requestChanges');
    }
    submits.add(_SubmitCall(prNumber, verdict, comments, body));
    if (submits.length == 1) {
      if (firstSubmitThrows != null) {
        throw firstSubmitThrows!;
      }
      if (firstSubmitThrows422) {
        throw const NetworkException('unprocessable', statusCode: 422);
      }
    }
    return reviewId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
