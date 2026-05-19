import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart'
    show EmptyConfigState;
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The queue owns profile-local copies of the shared row sort so browsing a
/// profile never disturbs (or inherits) the main queue's / inbox's column
/// sort. The data providers stay shared, so no duplicate fetches.
final _profileQueueOverrides = [
  inboxSortProvider.overrideWith(InboxSortNotifier.new),
  prListSortProvider.overrideWith(PrListSortNotifier.new),
];

/// A user profile's pull-request view: the same repo-grouped table as the main
/// queue (left repo rail + stacked section cards, updated-desc), browse-only
/// (no selection, no per-repo "new PR"). The population is the author's open
/// PRs in the workspace, narrowed by the profile's local title search.
///
/// Wrapped in a [ProviderScope] so the reused table widgets read profile-local
/// copies of the sort providers ([_profileQueueOverrides]).
class UserProfilePrQueue extends StatelessWidget {
  /// Creates a [UserProfilePrQueue] for [login].
  const UserProfilePrQueue({
    super.key,
    required this.login,
    required this.searchFocusNode,
  });

  /// The profile whose PRs are shown.
  final String login;

  /// The (screen-owned) focus node for the profile search field, focused by
  /// the `/` and ⌘F shortcuts.
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: _profileQueueOverrides,
      child: _ProfilePrQueueBody(
        login: login,
        searchFocusNode: searchFocusNode,
      ),
    );
  }
}

class _ProfilePrQueueBody extends ConsumerWidget {
  const _ProfilePrQueueBody({
    required this.login,
    required this.searchFocusNode,
  });

  final String login;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final openAsync = ref.watch(prsByAuthorInWorkspaceProvider(login));
    final query = ref.watch(userProfileSearchProvider(login));
    // The workspace repo-list order — the single ordering used everywhere repos
    // are listed. Sections follow it so the profile rail matches the queue.
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final repoOrder = <String, int>{};
    final linked = githubLinkedReposOf(
      workspaceId == null
          ? const AsyncData([])
          : ref.watch(reposForWorkspaceProvider(workspaceId)),
    );
    for (var i = 0; i < linked.length; i++) {
      repoOrder[linked[i].id] = i;
    }

    return ScopedShortcuts(
      scope: '/users',
      bindings: {
        'pr.user-focus-search': searchFocusNode.requestFocus,
        'pr.user-focus-search-alt': searchFocusNode.requestFocus,
        'pr.user-refresh': () => ref.invalidate(prsByRepoProvider),
      },
      child: openAsync.when(
        loading: () => const Center(child: CcSpinner()),
        error: (error, _) => Center(
          child: CcAlert(
            variant: CcAlertVariant.danger,
            title: l10n.failedToLoad,
            description: Text(error.toString()),
          ),
        ),
        data: (groups) {
          final sections = _sectionsFor(groups, query, repoOrder);
          if (sections.isEmpty) {
            return _emptyState(l10n, query);
          }
          return PrRepoView(sections: sections);
        },
      ),
    );
  }

  /// Builds one repo section per repo with matching open PRs, ordered by the
  /// workspace repo-list order ([repoOrder]) so the profile rail matches the
  /// main queue everywhere. The rows within each card are sorted for display by
  /// the shared updated-desc default.
  List<PrRepoSectionData> _sectionsFor(
    List<RepoPullRequests> groups,
    String query,
    Map<String, int> repoOrder,
  ) {
    final q = query.trim().toLowerCase();
    bool matches(PullRequest pr) =>
        q.isEmpty ||
        pr.title.toLowerCase().contains(q) ||
        '#${pr.number}'.contains(q);

    final sections = <PrRepoSectionData>[];
    for (final group in groups) {
      final items = <PrInboxItem>[
        for (final pr in group.prs)
          if (matches(pr)) PrInboxItem(pr: pr, repo: group.repo),
      ];
      if (items.isNotEmpty) {
        sections.add((repo: group.repo, items: items));
      }
    }
    const last = 1 << 30;
    sections.sort(
      (a, b) => (repoOrder[a.repo.id] ?? last).compareTo(
        repoOrder[b.repo.id] ?? last,
      ),
    );
    return sections;
  }

  Widget _emptyState(AppLocalizations l10n, String query) {
    if (query.trim().isNotEmpty) {
      return EmptyConfigState(
        icon: AppIcons.searchX,
        message: l10n.noPrsMatchSearch,
        hint: l10n.noPrsMatchSearchHint,
      );
    }
    return EmptyConfigState(
      icon: AppIcons.gitPullRequest,
      message: l10n.noPrsByUserInWorkspace(login),
      hint: '',
    );
  }
}
