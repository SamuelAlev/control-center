import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';

/// One repo section per github-linked repo, in the SAME order as the
/// workspace repo list (`reposForWorkspaceProvider`, the operator's own
/// drag-to-reorder order) — the single ordering used everywhere repos are
/// listed. Repos are never hidden: one with no PR matching the active filters
/// still appears (with a 0 count), so the left rail is the always-complete
/// repo map. The row sort inside each card is the shared updated-desc default.
List<PrRepoSectionData> prListSections({
  required PrsByRepoState state,
  required List<Repo> linkedRepos,
  required PrListFilters filters,
  required String login,
  required bool showDrafts,
  required Set<String> reviewedKeys,
  Map<String, Set<String>> viewerTeamsByOrg = const {},
}) {
  final groups = filters.reviewedByMe
      ? overlayReviewedByMe(state.repos, reviewedKeys)
      : state.repos;
  final prsByRepoId = {for (final group in groups) group.repo.id: group.prs};
  return [
    for (final repo in linkedRepos)
      (
        repo: repo,
        items: <PrInboxItem>[
          for (final pr in prsByRepoId[repo.id] ?? const <PullRequest>[])
            if (prPassesFilters(
              pr,
              filters: filters,
              currentLogin: login,
              includeDrafts: showDrafts,
              viewerTeamsByOrg: viewerTeamsByOrg,
            ))
              PrInboxItem(pr: pr, repo: repo),
        ],
      ),
  ];
}
