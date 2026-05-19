import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReactionTarget { reviewComment, issueComment, pullRequest }

Future<void> toggleReaction(
  WidgetRef ref,
  ReactionTarget target, {
  int? commentId,
  int? prNumber,
  required String content,
  required bool add,
}) async {
  final repo = ref.read(prReviewRepositoryProvider);
  final login = ref.read(githubUserProvider).maybeWhen(
    data: (user) => user?.login,
    orElse: () => null,
  );

  switch (target) {
    case ReactionTarget.reviewComment:
      await repo.toggleReviewCommentReaction(
        commentId: commentId!,
        prNumber: prNumber!,
        content: content,
        add: add,
        currentUserLogin: login,
      );
    case ReactionTarget.issueComment:
      await repo.toggleIssueCommentReaction(
        commentId: commentId!,
        prNumber: prNumber!,
        content: content,
        add: add,
        currentUserLogin: login,
      );
    case ReactionTarget.pullRequest:
      await repo.togglePullRequestReaction(
        prNumber: prNumber!,
        content: content,
        add: add,
        currentUserLogin: login,
      );
  }
}
