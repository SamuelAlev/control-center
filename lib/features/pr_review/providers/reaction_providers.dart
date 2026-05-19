import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Target type for a reaction toggle operation.
enum ReactionTarget {
  /// A review comment on a PR diff.
  reviewComment,

  /// A top-level issue comment on a PR.
  issueComment,

  /// The PR description itself.
  pullRequest,
}

/// Toggles a reaction on a review comment, issue comment, or pull request.
Future<void> toggleReaction(
  WidgetRef ref,
  ReactionTarget target, {
  int? commentId,
  int? prNumber,
  required String content,
  required bool add,
}) async {
  final repo = ref.read(prReviewRepositoryProvider);
  final login = ref
      .read(githubUserProvider)
      .maybeWhen(data: (user) => user?.login, orElse: () => null);

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
