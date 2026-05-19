import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/data/mappers/pr_review_mapper.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/usecases/classify_pull_requests_use_case.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// The dashboard's "priority reviews": the open PRs across the active
/// workspace's repos that request the operator's review and have waited longer
/// than [ClassifyPullRequestsUseCase.priorityDuration].
///
/// Unlike the PR-list screen — which loads every open PR in the workspace
/// (`prsByRepoProvider`) and classifies locally — this fetches *only* the
/// matching PRs through one server-side-filtered GitHub `search` call
/// (`review-requested:<login>`), with just the fields the panel renders. The
/// dashboard therefore no longer drags in the heavy workspace-wide list query
/// just to show a handful of reviews.
///
/// Auto-disposes (no `keepAlive`): the call is cheap, so re-fetching on each
/// dashboard visit keeps this "needs you now" surface fresh — including after a
/// merge done elsewhere — without the list query's refetch concerns. Rebuilds
/// when auth / active workspace / linked repos / the viewer's login change.
final dashboardPriorityReviewsProvider =
    FutureProvider<List<PriorityReview>>((ref) async {
  final isAuthed = ref.watch(isGitHubAuthenticatedProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (!isAuthed || workspaceId == null) {
    return const [];
  }

  // Server-side `review-requested:@me` needs the concrete login; the dashboard
  // is always reached authenticated, so this resolves in practice.
  final login = ref
      .watch(githubUserProvider)
      .maybeWhen(data: (user) => user?.login, orElse: () => null);
  if (login == null || login.isEmpty) {
    return const [];
  }

  final repos = githubLinkedReposOf(
    ref.watch(reposForWorkspaceProvider(workspaceId)),
  );
  if (repos.isEmpty) {
    return const [];
  }

  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final client = ref.watch(githubApiClientProvider);
  final nodes = await client.graphql.searchReviewRequestedPullRequests(
    reviewerLogin: login,
    repos: repos
        .map((r) => (owner: r.githubOwner, name: r.githubRepoName))
        .toList(growable: false),
    cancelToken: cancelToken,
  );

  // Group hits back onto the workspace's repos by `owner/name`. The search is
  // already scoped to these repos, so an unmatched hit is unexpected — skip it.
  final repoByFullName = {
    for (final r in repos) r.fullName.toLowerCase(): r,
  };

  final now = DateTime.now();
  final reviews = <PriorityReview>[];
  for (final node in nodes) {
    final mapped = priorityReviewFromSearchNode(node);
    if (mapped == null) {
      continue;
    }
    final repo = repoByFullName[mapped.repoFullName.toLowerCase()];
    if (repo == null) {
      continue;
    }
    final lastActivity = mapped.pr.updatedAt ?? mapped.pr.createdAt ?? now;
    if (now.difference(lastActivity) > ClassifyPullRequestsUseCase.priorityDuration) {
      reviews.add(PriorityReview(pr: mapped.pr, repo: repo));
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
