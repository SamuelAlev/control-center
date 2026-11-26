import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show LaneSignInNeed, TokenSignInNeed;
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRepo extends EmptyPrReviewRepository {
  String? lastPrBody;
  int updatePrCalls = 0;
  int? lastCommentId;
  String? lastCommentBody;
  List<String> addedLabels = const [];
  List<String> removedLabels = const [];
  int requestReviewersCalls = 0;
  List<String> requestedUserLogins = const [];
  List<String> requestedTeamSlugs = const [];
  Completer<void>? gate;
  Object? refuseWith;

  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  }) async {
    updatePrCalls++;
    final refusal = refuseWith;
    if (refusal != null) {
      throw refusal;
    }
    lastPrBody = body;
    final wait = gate;
    if (wait != null) {
      await wait.future;
    }
  }

  @override
  Future<void> updateIssueComment({
    required int prNumber,
    required int commentId,
    required String body,
  }) async {
    lastCommentId = commentId;
    lastCommentBody = body;
  }

  int? lastReviewCommentId;
  String? lastReviewCommentBody;

  /// What the forge holds for the review comment, as the streams serve it.
  String reviewCommentOnForge = 'old';

  @override
  Future<void> updateReviewComment({
    required int prNumber,
    required int commentId,
    required String body,
  }) async {
    final refusal = refuseWith;
    if (refusal != null) {
      throw refusal;
    }
    lastReviewCommentId = commentId;
    lastReviewCommentBody = body;
    final wait = gate;
    if (wait != null) {
      await wait.future;
    }
    reviewCommentOnForge = body;
  }

  @override
  Future<void> addLabels({
    required int prNumber,
    required List<String> names,
  }) async {
    addedLabels = names;
  }

  @override
  Future<void> removeLabels({
    required int prNumber,
    required List<String> names,
  }) async {
    removedLabels = names;
  }

  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) async {
    requestReviewersCalls++;
    final refusal = refuseWith;
    if (refusal != null) {
      throw refusal;
    }
    requestedUserLogins = userLogins;
    requestedTeamSlugs = teamSlugs;
    final wait = gate;
    if (wait != null) {
      await wait.future;
    }
  }
}

void main() {
  const prRef = (
    workspaceId: 'ws',
    repoFullName: 'acme/cc',
    number: 42,
    forge: null,
  );

  late _RecordingRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _RecordingRepo();
    container = ProviderContainer(
      overrides: [
        prRepositoryProvider(prRef).overrideWith((ref) => repo),
        prDetailProvider(prRef).overrideWith((ref) => Stream.value(null)),
        prIssueCommentsProvider(
          prRef,
        ).overrideWith((ref) => Stream.value(const [])),
        prReviewCommentsProvider(prRef).overrideWith(
          (ref) => Stream.value([_reviewComment(repo.reviewCommentOnForge)]),
        ),
        prReviewCommentIndexProvider(prRef).overrideWith(
          (ref) => Stream.value([_reviewComment(repo.reviewCommentOnForge)]),
        ),
      ],
    );
    // autoDispose: keep the notifier alive across async gaps.
    container.listen(prEditProvider(prRef), (_, _) {});
  });

  tearDown(() => container.dispose());

  test(
    'toggleTaskListItem PATCHes the box and keeps the HTML comment',
    () async {
      final notifier = container.read(prEditProvider(prRef).notifier);
      const body =
          ' - [ ] <!-- rebase-check -->If you want to rebase/retry this PR, '
          'check this box';
      final error = await notifier.toggleTaskListItem(
        currentBody: body,
        index: 0,
      );
      expect(error, isNull);
      expect(repo.lastPrBody, contains('[x]'));
      expect(repo.lastPrBody, contains('<!-- rebase-check -->'));
      expect(
        container.read(prEditProvider(prRef)).optimisticBody,
        repo.lastPrBody,
      );
    },
  );

  test(
    'toggleTaskListItem is ignored while a body save is in flight',
    () async {
      repo.gate = Completer<void>();
      final notifier = container.read(prEditProvider(prRef).notifier);
      const body = '- [ ] one\n- [ ] two';
      final first = notifier.toggleTaskListItem(currentBody: body, index: 0);
      await Future<void>.delayed(Duration.zero);
      final second = await notifier.toggleTaskListItem(
        currentBody: body,
        index: 1,
      );
      expect(second, isNull);
      expect(repo.updatePrCalls, 1);
      repo.gate!.complete();
      await first;
      expect(repo.updatePrCalls, 1);
    },
  );

  test('an edit refused for want of a sign-in asks for one, once per '
      'refusal', () async {
    final notifier = container.read(prEditProvider(prRef).notifier);
    repo.refuseWith = RemoteRpcException(
      RpcErrorCodes.unauthorized,
      'Sign in to GitHub',
      {'kind': 'needs_sign_in', 'lane': 'github'},
    );

    expect(await notifier.saveTitle('t'), isNotNull);
    expect(await notifier.saveTitle('t'), isNotNull);

    final state = container.read(prEditProvider(prRef));
    expect(state.signInRefusals, 2);
    expect(state.refusedNeed, const LaneSignInNeed(ConnectOAuthLane.github));
  });

  test('a refusal naming a token-only forge asks for its token', () async {
    final notifier = container.read(prEditProvider(prRef).notifier);
    repo.refuseWith = RemoteRpcException(
      RpcErrorCodes.unauthorized,
      'Add a GitLab token',
      {'kind': 'needs_sign_in', 'lane': 'gitlab'},
    );

    expect(await notifier.saveTitle('t'), isNotNull);

    expect(
      container.read(prEditProvider(prRef)).refusedNeed,
      const TokenSignInNeed(ForgeHost.gitlab),
    );
  });

  test('any other failure asks for nothing', () async {
    final notifier = container.read(prEditProvider(prRef).notifier);
    repo.refuseWith = RemoteRpcException(
      RpcErrorCodes.unauthorized,
      'Not a member',
    );

    expect(await notifier.saveTitle('t'), isNotNull);
    expect(container.read(prEditProvider(prRef)).signInRefusals, 0);
  });

  test('toggleCommentTaskListItem PATCHes the named comment', () async {
    final notifier = container.read(prEditProvider(prRef).notifier);
    final error = await notifier.toggleCommentTaskListItem(
      commentId: 9,
      currentBody: '- [ ] please rebase',
      index: 0,
    );
    expect(error, isNull);
    expect(repo.lastCommentId, 9);
    expect(repo.lastCommentBody, '- [x] please rebase');
    expect(
      container.read(prEditProvider(prRef)).optimisticComments[9],
      '- [x] please rebase',
    );
  });

  test('applyLabelChanges adds and removes in one pass', () async {
    final notifier = container.read(prEditProvider(prRef).notifier);
    final error = await notifier.applyLabelChanges(
      add: const ['bug'],
      remove: const ['wip'],
    );
    expect(error, isNull);
    expect(repo.addedLabels, ['bug']);
    expect(repo.removedLabels, ['wip']);
    expect(container.read(prEditProvider(prRef)).pendingLabels, isEmpty);
  });

  group('saveReviewComment', () {
    test('writes the forge and shows the new body until the open streams '
        'carry it', () async {
      container
        ..listen(prReviewCommentsProvider(prRef), (_, _) {})
        ..listen(prReviewCommentIndexProvider(prRef), (_, _) {});
      await container.read(prReviewCommentsProvider(prRef).future);
      await container.read(prReviewCommentIndexProvider(prRef).future);
      repo.gate = Completer<void>();
      final notifier = container.read(prEditProvider(prRef).notifier);

      final saving = notifier.saveReviewComment(commentId: 7, body: 'new');
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(prEditProvider(prRef)).optimisticReviewComments[7],
        'new',
      );
      // Conversation comments are numbered apart: id 7 there is untouched.
      expect(container.read(prEditProvider(prRef)).optimisticComments, {});

      repo.gate!.complete();
      expect(await saving, isNull);
      expect(repo.lastReviewCommentId, 7);
      expect(repo.lastReviewCommentBody, 'new');

      await container.read(prReviewCommentsProvider(prRef).future);
      await container.read(prReviewCommentIndexProvider(prRef).future);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(prEditProvider(prRef)).optimisticReviewComments,
        isEmpty,
      );
    });

    test('drops the new body at once when no stream is open', () async {
      final notifier = container.read(prEditProvider(prRef).notifier);
      expect(
        await notifier.saveReviewComment(commentId: 7, body: 'new'),
        isNull,
      );
      expect(
        container.read(prEditProvider(prRef)).optimisticReviewComments,
        isEmpty,
      );
    });

    test('a refusal puts the old body back and reports it', () async {
      repo.refuseWith = RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'Not the author',
      );
      final notifier = container.read(prEditProvider(prRef).notifier);
      expect(
        await notifier.saveReviewComment(commentId: 7, body: 'new'),
        isNotNull,
      );
      expect(
        container.read(prEditProvider(prRef)).optimisticReviewComments,
        isEmpty,
      );
    });
  });

  group('requestReviewer', () {
    test('requests review for a user and clears pendingReviewers', () async {
      final notifier = container.read(prEditProvider(prRef).notifier);
      final error = await notifier.requestReviewer(userLogin: 'Alice');
      expect(error, isNull);
      expect(repo.requestedUserLogins, ['Alice']);
      expect(repo.requestedTeamSlugs, isEmpty);
      expect(container.read(prEditProvider(prRef)).pendingReviewers, isEmpty);
    });

    test('requests review for a team', () async {
      final notifier = container.read(prEditProvider(prRef).notifier);
      final error = await notifier.requestReviewer(teamSlug: 'platform');
      expect(error, isNull);
      expect(repo.requestedUserLogins, isEmpty);
      expect(repo.requestedTeamSlugs, ['platform']);
      expect(container.read(prEditProvider(prRef)).pendingReviewers, isEmpty);
    });

    test('tracks pendingReviewers and suppresses duplicate calls while in flight',
        () async {
      repo.gate = Completer<void>();
      final notifier = container.read(prEditProvider(prRef).notifier);
      final first = notifier.requestReviewer(userLogin: 'Alice');
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(prEditProvider(prRef)).pendingReviewers,
        {'user:alice'},
      );
      expect(await notifier.requestReviewer(userLogin: 'alice'), isNull);
      expect(repo.requestReviewersCalls, 1);

      repo.gate!.complete();
      expect(await first, isNull);
      expect(container.read(prEditProvider(prRef)).pendingReviewers, isEmpty);
    });

    test('reports failures and clears pendingReviewers', () async {
      repo.refuseWith = RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'Denied',
      );
      final notifier = container.read(prEditProvider(prRef).notifier);
      expect(await notifier.requestReviewer(userLogin: 'alice'), isNotNull);
      expect(container.read(prEditProvider(prRef)).pendingReviewers, isEmpty);
    });
  });
}

PrCodeReviewComment _reviewComment(String body) => PrCodeReviewComment(
  id: 7,
  body: body,
  user: null,
  path: 'lib/a.dart',
  position: 1,
  createdAt: null,
);
