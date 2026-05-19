import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/usecases/classify_pull_requests_use_case.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_keyboard_hints.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/decision_lanes_rail.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_batch_bar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_queue_toolbar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_repo_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_row.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_search_field.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_search_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/ready_auto_scroll.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The pull-request queue: a decision-lane rail over a single, dense, sortable
/// queue panel of collapsible repo groups. Lanes are the primary triage axis,
/// the capsule rail filters by relationship, and inline merge/peek/batch
/// actions keep the operator in the queue.
class PullRequestListScreen extends ConsumerStatefulWidget {
  /// Creates a [PullRequestListScreen].
  const PullRequestListScreen({super.key});

  @override
  ConsumerState<PullRequestListScreen> createState() =>
      _PullRequestListScreenState();
}

class _PullRequestListScreenState extends ConsumerState<PullRequestListScreen> {
  bool _didRefreshOnMount = false;
  PrListData? _lastShownData;
  final ScrollController _bodyScrollController = ScrollController();
  // Keyed by (repoId, number) rather than number alone — PR numbers are only
  // unique within a repo, so two repos each holding e.g. PR #1 would otherwise
  // share one [GlobalKey]/[FocusNode] and trip "multiple widgets used the same
  // GlobalKey" (most visibly after a workspace-wide search spans repos).
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  final Map<String, FocusNode> _rowFocus = <String, FocusNode>{};
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'pr-search');

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
    _bodyScrollController.dispose();
    _searchFocusNode.dispose();
    for (final node in _rowFocus.values) {
      node.dispose();
    }
    _rowFocus.clear();
    _rowKeys.clear();
    super.dispose();
  }

  /// Globally-unique row identity within the queue: a repo's PR numbers are
  /// unique only within that repo, so the key folds in the repo id.
  String _rowId(String repoId, int number) => '$repoId#$number';

  GlobalKey _rowKey(String repoId, int number) =>
      _rowKeys.putIfAbsent(_rowId(repoId, number), GlobalKey.new);

  FocusNode _rowFocusNode(String repoId, int number) => _rowFocus.putIfAbsent(
    _rowId(repoId, number),
    () => FocusNode(debugLabel: 'pr-$repoId#$number'),
  );

  // ── data shaping ──────────────────────────────────────────────────────

  Map<DecisionLane, int> _laneCounts(
    PrListData data,
    String login,
    PrListFilters filters,
  ) {
    final counts = {for (final l in DecisionLane.values) l: 0};
    for (final group in data.byRepo) {
      for (final pr in applyFilters(
        group.prs,
        filters: filters,
        currentLogin: login,
      )) {
        for (final lane in lanesOfPr(pr, login)) {
          counts[lane] = counts[lane]! + 1;
        }
      }
    }
    return counts;
  }

  /// Every PR known to the queue, paired with its repo (unfiltered) so the
  /// batch bar can resolve selected numbers even after filters change.
  List<PrRepoPair> _allPairs(PrListData data) => [
    for (final group in data.byRepo)
      for (final pr in group.prs) (pr: pr, repo: group.repo),
  ];

  /// The ready-lane PRs across the capsule-filtered population — the pool the
  /// "Merge N ready" shortcut acts on.
  List<PrRepoPair> _readyPairs(
    PrListData data,
    String login,
    PrListFilters filters,
  ) {
    return [
      for (final group in data.byRepo)
        for (final pr in applyFilters(
          group.prs,
          filters: filters,
          currentLogin: login,
        ))
          if (lanesOfPr(pr, login).contains(DecisionLane.ready))
            (pr: pr, repo: group.repo),
    ];
  }

  /// Flattened, in-order PR numbers currently visible (respecting collapse,
  /// capsule filters, the active lane, and sort) — the keyboard cursor's ring.
  List<int> _visibleNumbers(PrListData data, String login) {
    final filters = ref.read(prListFiltersProvider);
    final lane = ref.read(decisionLaneFilterProvider);
    final sort = ref.read(prListSortProvider);
    final collapsed = ref.read(collapsedReposProvider);
    final result = <int>[];
    for (final group in data.byRepo) {
      if (collapsed.contains(group.repo.id)) {
        continue;
      }
      for (final pr in visiblePrsFor(
        group.prs,
        filters: filters,
        currentLogin: login,
        lane: lane,
        sort: sort,
      )) {
        result.add(pr.number);
      }
    }
    return result;
  }

  PrRepoPair? _pairFor(PrListData data, int number) {
    for (final group in data.byRepo) {
      for (final pr in group.prs) {
        if (pr.number == number) {
          return (pr: pr, repo: group.repo);
        }
      }
    }
    return null;
  }

  // ── keyboard triage ───────────────────────────────────────────────────

  void _cycle(int delta, PrListData data, String login) {
    final flat = _visibleNumbers(data, login);
    if (flat.isEmpty) {
      return;
    }
    final current = ref.read(selectedPrNumberProvider);
    final idx = current == null ? -1 : flat.indexOf(current);
    final base = idx < 0 ? (delta > 0 ? -1 : 0) : idx;
    final raw = (base + delta) % flat.length;
    ref
        .read(selectedPrNumberProvider.notifier)
        .select(flat[raw < 0 ? raw + flat.length : raw]);
  }

  void _openSelected(PrListData data) {
    final current = ref.read(selectedPrNumberProvider);
    if (current == null) {
      return;
    }
    final pair = _pairFor(data, current);
    openPrInRepo(ref, context, pair?.repo, current);
  }

  void _toggleSelectCursor() {
    final current = ref.read(selectedPrNumberProvider);
    if (current == null) {
      return;
    }
    ref.read(prSelectionProvider.notifier).toggle(current);
  }

  void _peekCursor() {
    final current = ref.read(selectedPrNumberProvider);
    if (current == null) {
      return;
    }
    ref.read(peekedPrsProvider.notifier).toggle(current);
  }

  Future<void> _mergeCursor(PrListData data, String login) async {
    final current = ref.read(selectedPrNumberProvider);
    if (current == null) {
      return;
    }
    final pair = _pairFor(data, current);
    if (pair == null) {
      return;
    }
    if (!lanesOfPr(pair.pr, login).contains(DecisionLane.ready)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).laneReadyHint)),
      );
      return;
    }
    await confirmAndMergeReadyPrs(context, ref, [pair]);
  }

  void _ensureSelectedVisible(int? number) {
    if (number == null) {
      return;
    }
    // The cursor selects by PR number; resolve it to its repo (the same
    // first-match rule the open/merge paths use) to rebuild the composite key.
    final data = _lastShownData;
    final pair = data == null ? null : _pairFor(data, number);
    if (pair == null) {
      return;
    }
    final id = _rowId(pair.repo.id, number);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rowKeys[id]?.currentContext;
      if (ctx == null || !ctx.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      _rowFocus[id]?.requestFocus();
    });
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prDataAsync = ref.watch(prListDataProvider);
    final isAuthed = ref.watch(isGitHubAuthenticatedProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final reposAsync = workspaceId != null
        ? ref.watch(reposForWorkspaceProvider(workspaceId))
        : null;
    final hasRepos = reposAsync?.value?.isNotEmpty ?? false;
    final isLoading = prDataAsync.isLoading;
    if (prDataAsync.hasValue) {
      _lastShownData = prDataAsync.value;
    }
    final data = prDataAsync.value ?? _lastShownData;
    final login = ref.watch(currentUserLoginProvider);
    // Watched so lane counts + the ready pool stay live as the queue narrows.
    final filters = ref.watch(prListFiltersProvider);
    final isSearching = ref.watch(prSearchQueryProvider).isActive;
    final repos = githubLinkedReposOf(reposAsync ?? const AsyncData([]));
    final prsState =
        ref.watch(prsByRepoProvider).value ??
        const PrsByRepoState(
          repos: [],
          hasMore: {},
          nextPage: {},
          loadingMore: {},
        );

    ref.listen<int?>(selectedPrNumberProvider, (_, next) {
      _ensureSelectedVisible(next);
    });
    final l10n = AppLocalizations.of(context);

    return ScopedShortcuts(
      scope: '/pull-requests',
      bindings: {
        // `/` and ⌘F/Ctrl+F both focus the queue search field.
        'pr.list-focus-search': _searchFocusNode.requestFocus,
        'pr.list-focus-search-alt': _searchFocusNode.requestFocus,
        if (!isLoading)
          'pr.list-refresh': () => ref.invalidate(prsByRepoProvider),
        if (data != null) ...{
          'pr.list-next': () => _cycle(1, data, login),
          'pr.list-prev': () => _cycle(-1, data, login),
          'pr.list-open': () => _openSelected(data),
          'pr.list-select': _toggleSelectCursor,
          'pr.list-merge': () => _mergeCursor(data, login),
          'pr.list-peek': _peekCursor,
        },
      },
      child: PageWrapper(
        title: l10n.pullRequests,
        subtitle: l10n.priorityReviewsDescription,
        actions: [
          PrSearchField(focusNode: _searchFocusNode),
          const SizedBox(width: AppSpacing.sm),
          FButton.icon(
            onPress: isLoading
                ? null
                : () {
                    ref.invalidate(prsByRepoProvider);
                    if (isSearching) {
                      ref.invalidate(prSearchResultsProvider);
                    }
                  },
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: FCircularProgress(),
                  )
                : const Icon(LucideIcons.refreshCw, size: 16),
          ),
        ],
        child: _buildBody(
          prDataAsync: prDataAsync,
          isAuthed: isAuthed,
          hasRepos: hasRepos,
          repos: repos,
          data: data,
          login: login,
          filters: filters,
          isSearching: isSearching,
          prsState: prsState,
        ),
      ),
    );
  }

  Widget _buildBody({
    required AsyncValue<PrListData> prDataAsync,
    required bool isAuthed,
    required bool hasRepos,
    required List<Repo> repos,
    required PrListData? data,
    required String login,
    required PrListFilters filters,
    required bool isSearching,
    required PrsByRepoState prsState,
  }) {
    final l10n = AppLocalizations.of(context);

    if (!isAuthed) {
      return EmptyConfigState(
        icon: LucideIcons.gitPullRequest,
        message: l10n.connectGitHubToLoadPrs,
        hint: l10n.signInWithGhAuth,
      );
    }
    if (prDataAsync.hasError && data == null) {
      return Center(
        child: FAlert(
          variant: FAlertVariant.destructive,
          title: Text(l10n.failedToLoad),
          subtitle: Text(prDataAsync.error.toString()),
        ),
      );
    }
    if (!prDataAsync.isLoading && data != null && data.isEmpty) {
      if (!hasRepos) {
        return EmptyConfigState(
          icon: LucideIcons.gitPullRequest,
          message: l10n.noRepositoriesConfigured,
          hint: l10n.addGithubRepoPrompt,
          action: FButton(
            onPress: () => GoRouter.of(context).go(settingsReposRoute),
            prefix: const Icon(LucideIcons.settings, size: 14),
            child: Text(l10n.repositoriesSettings),
          ),
        );
      }
      if (isSearching) {
        return EmptyConfigState(
          icon: LucideIcons.searchX,
          message: l10n.noPrsMatchSearch,
          hint: l10n.noPrsMatchSearchHint,
        );
      }
      return EmptyConfigState(
        icon: LucideIcons.checkCheck,
        message: l10n.allCaughtUp,
        hint: l10n.noOpenPullRequests,
      );
    }

    final sortedRepos = List<Repo>.of(repos)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final counts = data != null
        ? _laneCounts(data, login, filters)
        : {for (final l in DecisionLane.values) l: 0};
    final readyPairs = data != null
        ? _readyPairs(data, login, filters)
        : <PrRepoPair>[];
    final allPairs = data != null ? _allPairs(data) : <PrRepoPair>[];
    final totalCount = counts.values.fold<int>(0, (a, b) => a + b);

    return Stack(
      children: [
        ReadyAutoScroll(
          controller: _bodyScrollController,
          child: ListView(
            controller: _bodyScrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kPrListMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecisionLanesRail(counts: counts),
                      const SizedBox(height: AppSpacing.lg),
                      _QueuePanel(
                        toolbar: PrQueueToolbar(
                          totalCount: totalCount,
                          readyPairs: readyPairs,
                        ),
                        body: _buildQueueBody(
                          data: data,
                          login: login,
                          sortedRepos: sortedRepos,
                          isSearching: isSearching,
                          prsState: prsState,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrKeyboardHints.queue(l10n),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.lg,
          child: Center(child: PrBatchBar(allPrs: allPairs)),
        ),
      ],
    );
  }

  Widget _buildQueueBody({
    required PrListData? data,
    required String login,
    required List<Repo> sortedRepos,
    required bool isSearching,
    required PrsByRepoState prsState,
  }) {
    if (data == null && sortedRepos.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final repo in sortedRepos)
            RepoPrSection(
              repoPrs: RepoPullRequests(repo: repo, prs: const []),
              isLoading: true,
              rowKey: _rowKey,
              rowFocusNode: _rowFocusNode,
            ),
        ],
      );
    }
    if (data == null || data.byRepo.isEmpty) {
      return const _QueueEmpty();
    }

    final lane = ref.watch(decisionLaneFilterProvider);
    final filters = ref.watch(prListFiltersProvider);
    final anyVisible = data.byRepo.any(
      (g) => visiblePrsFor(
        g.prs,
        filters: filters,
        currentLogin: login,
        lane: lane,
        sort: ref.watch(prListSortProvider),
      ).isNotEmpty,
    );
    if (!anyVisible) {
      return const _QueueEmpty();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final repoPrs in data.byRepo)
          RepoPrSection(
            repoPrs: repoPrs,
            // Search results are a single server-side page, so the load-more
            // affordance (which pages the locally-loaded set) is suppressed.
            hasMore: isSearching
                ? false
                : (prsState.hasMore[repoPrs.repo.id] ?? false),
            loadingMore: isSearching
                ? false
                : (prsState.loadingMore[repoPrs.repo.id] ?? false),
            rowKey: _rowKey,
            rowFocusNode: _rowFocusNode,
          ),
      ],
    );
  }
}

/// The bordered queue panel: a toolbar over the repo groups, read as a single
/// flat instrument table.
class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.toolbar, required this.body});

  final Widget toolbar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = context.theme.colors;
    final border = tokens?.borderSecondary ?? colors.border;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens?.panel ?? colors.card,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [toolbar, body],
        ),
      ),
    );
  }
}

/// Shown inside the panel when the active lane / filters leave nothing to show.
class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: tokens?.borderSecondary ?? colors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          Text(
            l10n.nothingInLane,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.nothingInLaneHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens?.muted ?? colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
