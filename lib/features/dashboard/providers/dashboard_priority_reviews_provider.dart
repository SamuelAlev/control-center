import 'package:cc_domain/core/domain/entities/repo.dart' show Repo;
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pull_requests_use_case.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// The dashboard's "priority reviews": the open PRs across the active
/// workspace's repos that request the operator's review and have waited longer
/// than [ClassifyPullRequestsUseCase.priorityDuration].
///
/// Fetched SERVER-SIDE over RPC (`pr.searchReviewRequestedForWorkspace`): the
/// thin client holds no GitHub token, so the host runs the
/// `review-requested:<server login>` search across the bound workspace's linked
/// repos and returns the matching PRs. This client only joins them back to the
/// workspace's [Repo] entities and applies the wait-time threshold.
///
/// Auto-disposes (no `keepAlive`): the call is cheap, so re-fetching on each
/// dashboard visit keeps this "needs you now" surface fresh — including after a
/// merge done elsewhere. Rebuilds when the active workspace / linked repos change.
final dashboardPriorityReviewsProvider =
    FutureProvider<List<PriorityReview>>((ref) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const [];
  }

  final repos = githubLinkedReposOf(
    ref.watch(reposForWorkspaceProvider(workspaceId)),
  );
  if (repos.isEmpty) {
    return const [];
  }
  final reposById = {for (final r in repos) r.id: r};

  final results = await ref
      .watch(openPrListRepositoryProvider)
      .reviewRequestedForWorkspace(workspaceId);

  final now = DateTime.now();
  final reviews = <PriorityReview>[];
  for (final r in results) {
    final repo = reposById[r.repoId];
    if (repo == null) {
      continue;
    }
    final lastActivity = r.pr.updatedAt ?? r.pr.createdAt ?? now;
    if (now.difference(lastActivity) >
        ClassifyPullRequestsUseCase.priorityDuration) {
      reviews.add(PriorityReview(pr: r.pr, repo: repo));
    }
  }

  // Most-recently-active first, so grouping (which preserves first-seen order)
  // lists the repo with the freshest waiting review at the top.
  reviews.sort(
    (a, b) => (b.pr.updatedAt ?? b.pr.createdAt ?? _epoch)
        .compareTo(a.pr.updatedAt ?? a.pr.createdAt ?? _epoch),
  );
  return reviews;
});
