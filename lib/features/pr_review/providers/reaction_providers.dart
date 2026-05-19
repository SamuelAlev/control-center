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

  /// A review submission's summary card.
  review,
}

/// Toggles a reaction on a review comment, issue comment, review summary, or
/// pull request.
///
/// [pr] is the PR's full identity — the reaction rides the repository bound to
/// that PR's OWN repo, never the active one.
Future<void> toggleReaction(
  WidgetRef ref,
  ReactionTarget target, {
  required PrRef pr,
  int? commentId,
  int? reviewId,
  required String content,
  required bool add,
}) async {
  final repo = ref.read(prRepositoryProvider(pr));
  if (repo == null) {
    return;
  }
  final prNumber = pr.number;
  final login = ref
      .read(githubUserProvider)
      .maybeWhen(data: (user) => user?.login, orElse: () => null);

  switch (target) {
    case ReactionTarget.reviewComment:
      await repo.toggleReviewCommentReaction(
        commentId: commentId!,
        prNumber: prNumber,
        content: content,
        add: add,
        currentUserLogin: login,
      );
    case ReactionTarget.issueComment:
      await repo.toggleIssueCommentReaction(
        commentId: commentId!,
        prNumber: prNumber,
        content: content,
        add: add,
        currentUserLogin: login,
      );
    case ReactionTarget.pullRequest:
      await repo.togglePullRequestReaction(
        prNumber: prNumber,
        content: content,
        add: add,
        currentUserLogin: login,
      );
    case ReactionTarget.review:
      await repo.toggleReviewReaction(
        reviewId: reviewId!,
        prNumber: prNumber,
        content: content,
        add: add,
        currentUserLogin: login,
      );
  }
}
