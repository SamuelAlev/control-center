import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';

/// Pr list data.
class PrListData {
  /// PrListData({.
  const PrListData({required this.priorityReviews, required this.byRepo});

  /// PRs awaiting priority review.
  final List<PriorityReview> priorityReviews;

  /// PRs grouped by repository.
  final List<RepoPullRequests> byRepo;

  /// Whether all classification lists are empty.
  bool get isEmpty => priorityReviews.isEmpty && byRepo.isEmpty;
}

/// Classify pull requests use case.
class ClassifyPullRequestsUseCase {
  /// ClassifyPullRequestsUseCase().
  const ClassifyPullRequestsUseCase();

  /// priorityDuration.
  static const priorityDuration = Duration(hours: 24);

  /// Execute. When [currentUserLogin] is non-null, priority reviews are
  /// limited to PRs that explicitly request that user's review.
  /// When null, any PR with at least one requested reviewer is eligible.
  PrListData execute({
    required List<RepoPullRequests> byRepo,
    String? currentUserLogin,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final priorityReviews = <PriorityReview>[];

    for (final rp in byRepo) {
      for (final pr in rp.prs) {
        if (!pr.isPriority || pr.isDraft) {
          continue;
        }

        if (currentUserLogin != null && currentUserLogin.isNotEmpty) {
          final me = currentUserLogin.toLowerCase();
          final matches = pr.requestedReviewers.any(
            (r) => r.login.toLowerCase() == me,
          );
          if (!matches) {
            continue;
          }
        }

        final lastActivity = pr.updatedAt ?? pr.createdAt ?? effectiveNow;
        final age = effectiveNow.difference(lastActivity);
        if (age > priorityDuration) {
          priorityReviews.add(PriorityReview(pr: pr, repo: rp.repo));
        }
      }
    }

    return PrListData(priorityReviews: priorityReviews, byRepo: byRepo);
  }
}
