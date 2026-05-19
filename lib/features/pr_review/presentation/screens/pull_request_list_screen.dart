import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_bar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_menu.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_display_options_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart'
    show EmptyConfigState, prPassesFilters;
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/service_status/presentation/widgets/github_degraded_banner.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The pull-request queue: the inbox's view (left repo rail + stacked section
/// cards) keyed by repository. One card per repo with open PRs, sorted
/// updated-desc, with per-repo "new PR" and multi-select bulk actions
/// (close / assign / ask-for-review). The shared filter menu/bar and display
/// options narrow the view.
class PullRequestListScreen extends ConsumerStatefulWidget {
  /// Creates a [PullRequestListScreen].
  const PullRequestListScreen({super.key});

  @override
  ConsumerState<PullRequestListScreen> createState() =>
      _PullRequestListScreenState();
}

class _PullRequestListScreenState extends ConsumerState<PullRequestListScreen> {
  bool _didRefreshOnMount = false;
  // Whether a manual refresh (forced server sweep) is in flight, so the refresh
  // icon spins for the whole fetch — the live queue subscription itself never
  // re-enters a loading state on a forced sweep.
  bool _refreshing = false;
  final CcOverlayController _filterMenuController = CcOverlayController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didRefreshOnMount) {
        return;
      }
      final cached = ref.read(prsByRepoProvider);
      if (!cached.hasValue) {
        return;
      }
      _didRefreshOnMount = true;
      ref.invalidate(prsByRepoProvider);
    });
  }

  @override
  void dispose() {
    _filterMenuController.dispose();
    super.dispose();
  }

  /// Forces an immediate server-side GitHub sweep, spinning the refresh icon
  /// until it settles. The queue is otherwise live (server-pushed snapshots),
  /// so this doesn't tear down the subscription.
  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await ref.read(prsByRepoProvider.notifier).forceRefresh();
    } catch (_) {
      // The queue keeps its last snapshot / shows its own error; the spin
      // just stops.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  /// Opens the compose screen for a new pull request (the repo is chosen there,
  /// defaulting to the active repo).
  void _newPr() {
    GoRouter.of(
      context,
    ).go(pullRequestsComposeRoute(context.currentWorkspaceId!));
  }

  /// One repo section per github-linked repo, in the SAME order as the
  /// workspace repo list ([reposForWorkspaceProvider], the operator's own
  /// drag-to-reorder order) — the single ordering used everywhere repos are
  /// listed. Repos are never hidden: one with no PR matching the active filters
  /// still appears (with a 0 count), so the left rail is the always-complete
  /// repo map. The row sort inside each card is the shared updated-desc default.
  List<PrRepoSectionData> _buildSections({
    required PrsByRepoState state,
    required List<Repo> linkedRepos,
    required PrListFilters filters,
    required String login,
    required bool showDrafts,
    Map<String, Set<String>> viewerTeamsByOrg = const {},
  }) {
    final prsByRepoId = {for (final rp in state.repos) rp.repo.id: rp.prs};
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prDataAsync = ref.watch(prsByRepoProvider);
    // The thin client holds no GitHub token; auth is the SERVER's. Optimistic
    // while loading so the "connect GitHub" gate never flashes.
    final isAuthed = prDataAsync.maybeWhen(
      data: (s) => s.authenticated,
      orElse: () => true,
    );
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final reposAsync = workspaceId != null
        ? ref.watch(reposForWorkspaceProvider(workspaceId))
        : const AsyncData(<Repo>[]);
    final linkedRepos = forgeLinkedReposOf(reposAsync);
    final filters = ref.watch(prListFiltersProvider);
    final showDrafts = ref.watch(
      prListDisplayPrefsProvider.select((p) => p.showDrafts),
    );
    final login = ref.watch(currentUserLoginProvider);
    final viewerTeams =
        ref.watch(viewerGitHubTeamsProvider).value ??
        const <String, Set<String>>{};

    // Stamp freshness whenever the queue successfully (re)loads from GitHub.
    ref.listen(prsByRepoProvider, (_, next) {
      if (next is AsyncData && !next.isLoading) {
        ref.read(lastCheckedProvider.notifier).stamp('pr-list');
      }
    });
    final lastChecked = ref.watch(
      lastCheckedProvider.select((m) => m['pr-list']),
    );

    return ScopedShortcuts(
      scope: '/pull-requests',
      bindings: {
        'pr.list-open-filter': _filterMenuController.show,
        if (!prDataAsync.isLoading) 'pr.list-refresh': _refresh,
      },
      child: PageWrapper(
        title: l10n.pullRequests,
        subtitle: l10n.priorityReviewsDescription,
        actions: [
          PrFilterButton(
            scope: prListFilterScope,
            controller: _filterMenuController,
          ),
          const SizedBox(width: AppSpacing.xs),
          const PrDisplayOptionsButton(),
          const SizedBox(width: AppSpacing.sm),
          RefreshControl(
            lastChecked: lastChecked,
            // `sweeping` covers the server-side GitHub fetch the subscription
            // itself never reports: the snapshot is pushed instantly from the
            // server's cache, so without it the icon would sit still while the
            // fresh data is still being fetched.
            isLoading:
                prDataAsync.isLoading ||
                _refreshing ||
                (prDataAsync.value?.sweeping ?? false),
            onRefresh: _refresh,
          ),
          const SizedBox(width: AppSpacing.sm),
          CcButton(
            onPressed: (isAuthed && linkedRepos.isNotEmpty) ? _newPr : null,
            icon: AppIcons.gitPullRequestCreate,
            size: CcButtonSize.sm,
            child: Text(l10n.newPr),
          ),
        ],
        child: _buildBody(
          l10n: l10n,
          prDataAsync: prDataAsync,
          isAuthed: isAuthed,
          linkedRepos: linkedRepos,
          filters: filters,
          login: login,
          showDrafts: showDrafts,
          viewerTeamsByOrg: viewerTeams,
        ),
      ),
    );
  }

  Widget _buildBody({
    required AppLocalizations l10n,
    required AsyncValue<PrsByRepoState> prDataAsync,
    required bool isAuthed,
    required List<Repo> linkedRepos,
    required PrListFilters filters,
    required String login,
    required bool showDrafts,
    required Map<String, Set<String>> viewerTeamsByOrg,
  }) {
    if (!isAuthed) {
      return EmptyConfigState(
        icon: AppIcons.gitPullRequest,
        message: l10n.connectGitHubToLoadPrs,
        hint: l10n.signInWithGhAuth,
      );
    }
    if (prDataAsync.hasError && !prDataAsync.hasValue) {
      return Center(
        child: CcAlert(
          variant: CcAlertVariant.danger,
          title: l10n.failedToLoad,
          description: Text(prDataAsync.error.toString()),
        ),
      );
    }
    final state = prDataAsync.value;
    if (state == null) {
      return const Center(child: CcSpinner());
    }
    if (linkedRepos.isEmpty) {
      return EmptyConfigState(
        icon: AppIcons.gitPullRequest,
        message: l10n.noRepositoriesConfigured,
        hint: l10n.addGithubRepoPrompt,
        action: CcButton(
          onPressed: () => GoRouter.of(
            context,
          ).go(settingsReposRoute(context.currentWorkspaceId!)),
          icon: AppIcons.settings,
          child: Text(l10n.repositoriesSettings),
        ),
      );
    }

    final sections = _buildSections(
      state: state,
      linkedRepos: linkedRepos,
      filters: filters,
      login: login,
      showDrafts: showDrafts,
      viewerTeamsByOrg: viewerTeamsByOrg,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The queue is a projection of GitHub state, so a degraded GitHub
          // makes it stale or partial while it still looks authoritative.
          // Renders nothing while GitHub is healthy.
          const GitHubDegradedBanner(),
          if (filters.isActive) ...[
            PrFilterBar(scope: prListFilterScope),
            const SizedBox(height: AppSpacing.md),
          ],
          Expanded(child: PrRepoView(sections: sections, selectable: true)),
        ],
      ),
    );
  }
}
