import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';

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

  /// Execute. When [viewerLoginByForge] is non-null, priority reviews are
  /// limited to PRs that explicitly request the viewer's review — matched
  /// against the viewer's login on EACH repo's own forge (the same human is a
  /// different account on GitHub and GitLab; a forge missing from the map has
  /// no PR of theirs). When null, any PR with at least one requested reviewer
  /// is eligible.
  PrListData execute({
    required List<RepoPullRequests> byRepo,
    Map<ForgeHost, String>? viewerLoginByForge,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final priorityReviews = <PriorityReview>[];

    for (final rp in byRepo) {
      final login = viewerLoginByForge?[rp.repo.forge];
      for (final pr in rp.prs) {
        if (!pr.isPriority || pr.isDraft) {
          continue;
        }

        if (viewerLoginByForge != null) {
          final me = (login ?? '').toLowerCase();
          if (me.isEmpty) {
            continue;
          }
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
