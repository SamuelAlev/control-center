import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart'
    show EmptyConfigState;
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
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

/// Profile-local copies of shared table sort state. Browsing a profile must not
/// mutate the main PR queue or inbox ordering.
final _profileQueueOverrides = [
  inboxSortProvider.overrideWith(InboxSortNotifier.new),
  prListSortProvider.overrideWith(PrListSortNotifier.new),
];

/// Shared all-state PR browser used by user and team profiles.
class GitHubProfilePrQueue extends StatelessWidget {
  /// Creates a profile PR browser.
  const GitHubProfilePrQueue({
    super.key,
    required this.profileKey,
    required this.activity,
    required this.emptyMessage,
    required this.searchFocusNode,
  });

  /// Stable key for search and state-filter providers.
  final String profileKey;

  /// Profile activity returned by the server.
  final AsyncValue<GitHubProfileActivity> activity;

  /// Empty state when the profile has no PRs in the workspace.
  final String emptyMessage;

  /// Search focus target used by keyboard shortcuts.
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: _profileQueueOverrides,
      child: _ProfilePrQueueBody(
        profileKey: profileKey,
        activity: activity,
        emptyMessage: emptyMessage,
        searchFocusNode: searchFocusNode,
      ),
    );
  }
}

class _ProfilePrQueueBody extends ConsumerWidget {
  const _ProfilePrQueueBody({
    required this.profileKey,
    required this.activity,
    required this.emptyMessage,
    required this.searchFocusNode,
  });

  final String profileKey;
  final AsyncValue<GitHubProfileActivity> activity;
  final String emptyMessage;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(userProfileSearchProvider(profileKey));
    final filter = ref.watch(profilePrStateFilterProvider(profileKey));
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final reposAsync = workspaceId == null
        ? const AsyncValue<List<Repo>>.data(<Repo>[])
        : ref.watch(reposForWorkspaceProvider(workspaceId));
    final linked = forgeLinkedReposOf(reposAsync);
    final repoOrder = <String, int>{};
    for (var i = 0; i < linked.length; i++) {
      repoOrder[linked[i].id] = i;
    }

    return ScopedShortcuts(
      scope: '/users',
      bindings: {
        'pr.user-focus-search': searchFocusNode.requestFocus,
        'pr.user-focus-search-alt': searchFocusNode.requestFocus,
        'pr.user-refresh': () {
          ref.invalidate(userProfileActivityProvider);
          ref.invalidate(teamProfileActivityProvider);
        },
      },
      child: activity.when(
        loading: () => const Center(child: CcSpinner()),
        error: (error, _) => Center(
          child: CcAlert(
            variant: CcAlertVariant.danger,
            title: l10n.failedToLoad,
            description: Text(error.toString()),
          ),
        ),
        data: (value) {
          if (!reposAsync.hasValue && value.repos.isNotEmpty) {
            return const Center(child: CcSpinner());
          }
          final groups = _joinRepos(value, linked);
          final counts = _stateCounts(groups);
          final sections = _sectionsFor(groups, query, filter, repoOrder);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CcSegmentedToggle<ProfilePrStateFilter>(
                  value: filter,
                  semanticLabel: l10n.profilePrStateFilterLabel,
                  onChanged: (next) => ref
                      .read(profilePrStateFilterProvider(profileKey).notifier)
                      .set(next),
                  segments: [
                    CcSegment(
                      value: ProfilePrStateFilter.all,
                      label: '${l10n.all} ${counts.all}',
                    ),
                    CcSegment(
                      value: ProfilePrStateFilter.open,
                      label: '${l10n.openLabel} ${counts.open}',
                    ),
                    CcSegment(
                      value: ProfilePrStateFilter.merged,
                      label: '${l10n.merged} ${counts.merged}',
                    ),
                    CcSegment(
                      value: ProfilePrStateFilter.closed,
                      label: '${l10n.closed} ${counts.closed}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: sections.isEmpty
                    ? _emptyState(l10n, query, emptyMessage)
                    : PrRepoView(sections: sections),
              ),
            ],
          );
        },
      ),
    );
  }

  List<RepoPullRequests> _joinRepos(
    GitHubProfileActivity activity,
    List<Repo> linked,
  ) {
    final reposById = {for (final repo in linked) repo.id: repo};
    return [
      for (final group in activity.repos)
        if (reposById[group.repoId] case final repo? when group.prs.isNotEmpty)
          RepoPullRequests(repo: repo, prs: group.prs),
    ];
  }

  ({int all, int open, int merged, int closed}) _stateCounts(
    List<RepoPullRequests> groups,
  ) {
    var all = 0, open = 0, merged = 0, closed = 0;
    for (final group in groups) {
      for (final pr in group.prs) {
        all++;
        switch (pr.state) {
          case PrState.open:
            open++;
          case PrState.merged:
            merged++;
          case PrState.closed:
            closed++;
        }
      }
    }
    return (all: all, open: open, merged: merged, closed: closed);
  }

  List<PrRepoSectionData> _sectionsFor(
    List<RepoPullRequests> groups,
    String query,
    ProfilePrStateFilter filter,
    Map<String, int> repoOrder,
  ) {
    final q = query.trim().toLowerCase();
    bool matches(PullRequest pr) {
      final stateMatches = switch (filter) {
        ProfilePrStateFilter.all => true,
        ProfilePrStateFilter.open => pr.state == PrState.open,
        ProfilePrStateFilter.merged => pr.state == PrState.merged,
        ProfilePrStateFilter.closed => pr.state == PrState.closed,
      };
      return stateMatches &&
          (q.isEmpty ||
              pr.title.toLowerCase().contains(q) ||
              '#${pr.number}'.contains(q));
    }

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

  Widget _emptyState(AppLocalizations l10n, String query, String emptyMessage) {
    if (query.trim().isNotEmpty) {
      return EmptyConfigState(
        icon: AppIcons.searchX,
        message: l10n.noPrsMatchSearch,
        hint: l10n.noProfilePrsMatchSearchHint,
      );
    }
    return EmptyConfigState(
      icon: AppIcons.gitPullRequest,
      message: emptyMessage,
      hint: '',
    );
  }
}
