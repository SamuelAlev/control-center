import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_keyboard_hints.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_repo_section.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// The PR-queue UI-state providers the profile queue owns its own copies of, so
/// browsing a profile never disturbs (or inherits) the main PR list's lane
/// filter, sort, selection, peek, collapse, or keyboard cursor. The data
/// providers (`prsByRepoProvider`, the profile providers) are *not* overridden,
/// so they stay shared with the rest of the app — no duplicate fetches.
final _profileQueueOverrides = [
  selectedPrNumberProvider.overrideWith(SelectedPrNumberNotifier.new),
  peekedPrsProvider.overrideWith(PeekedPrsNotifier.new),
  prSelectionProvider.overrideWith(PrSelectionNotifier.new),
  decisionLaneFilterProvider.overrideWith(DecisionLaneFilterNotifier.new),
  prListSortProvider.overrideWith(PrListSortNotifier.new),
  prListFiltersProvider.overrideWith(PrListFiltersNotifier.new),
  collapsedReposProvider.overrideWith(CollapsedReposNotifier.new),
];

/// A user profile's pull-request queue: the same dense rows, peek, and
/// per-repo accordions as the main PR list, in browse-only mode (no
/// select/merge). The population is the author's open PRs (already loaded for
/// the workspace) plus any merged/closed history the state rail has fetched,
/// narrowed by the profile's state filter and local search.
///
/// Wrapped in a [ProviderScope] so the reused list widgets read profile-local
/// copies of the queue's UI-state providers ([_profileQueueOverrides]).
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
      child: _ProfilePrQueueBody(login: login, searchFocusNode: searchFocusNode),
    );
  }
}

class _ProfilePrQueueBody extends ConsumerStatefulWidget {
  const _ProfilePrQueueBody({required this.login, required this.searchFocusNode});

  final String login;
  final FocusNode searchFocusNode;

  @override
  ConsumerState<_ProfilePrQueueBody> createState() =>
      _ProfilePrQueueBodyState();
}

class _ProfilePrQueueBodyState extends ConsumerState<_ProfilePrQueueBody> {
  // Keyed by (repoId, number): a profile is one author, but the same PR number
  // can still recur across repos, so fold the repo id into the key.
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  final Map<String, FocusNode> _rowFocus = <String, FocusNode>{};

  /// Last assembled groups, so the cursor's scroll-into-view can resolve a PR
  /// number back to its repo.
  List<RepoPullRequests> _lastData = const [];

  @override
  void dispose() {
    for (final node in _rowFocus.values) {
      node.dispose();
    }
    _rowFocus.clear();
    _rowKeys.clear();
    super.dispose();
  }

  String _rowId(String repoId, int number) => '$repoId#$number';

  GlobalKey _rowKey(String repoId, int number) =>
      _rowKeys.putIfAbsent(_rowId(repoId, number), GlobalKey.new);

  FocusNode _rowFocusNode(String repoId, int number) => _rowFocus.putIfAbsent(
    _rowId(repoId, number),
    () => FocusNode(debugLabel: 'profile-pr-$repoId#$number'),
  );

  // ── keyboard triage ───────────────────────────────────────────────────

  List<int> _visibleNumbers(List<RepoPullRequests> data) {
    final collapsed = ref.read(collapsedReposProvider);
    final result = <int>[];
    for (final group in data) {
      if (collapsed.contains(group.repo.id)) {
        continue;
      }
      for (final pr in group.prs) {
        result.add(pr.number);
      }
    }
    return result;
  }

  ({PullRequest pr, Repo repo})? _pairFor(
    List<RepoPullRequests> data,
    int number,
  ) {
    for (final group in data) {
      for (final pr in group.prs) {
        if (pr.number == number) {
          return (pr: pr, repo: group.repo);
        }
      }
    }
    return null;
  }

  void _cycle(int delta, List<RepoPullRequests> data) {
    final flat = _visibleNumbers(data);
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

  void _openSelected(List<RepoPullRequests> data) {
    final current = ref.read(selectedPrNumberProvider);
    if (current == null) {
      return;
    }
    final pair = _pairFor(data, current);
    openPrInRepo(ref, context, pair?.repo, current);
  }

  void _peekCursor() {
    final current = ref.read(selectedPrNumberProvider);
    if (current == null) {
      return;
    }
    ref.read(peekedPrsProvider.notifier).toggle(current);
  }

  void _refresh() {
    ref.invalidate(prsByRepoProvider);
    ref.invalidate(userClosedPrsProvider(widget.login));
    ref.invalidate(userPrCountsProvider(widget.login));
  }

  void _ensureSelectedVisible(int? number) {
    if (number == null) {
      return;
    }
    final pair = _pairFor(_lastData, number);
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

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final openAsync = ref.watch(prsByAuthorInWorkspaceProvider(widget.login));
    final states = ref.watch(userProfileStateFilterProvider(widget.login));
    final query = ref.watch(userProfileSearchProvider(widget.login));
    final wantClosed =
        states.contains(ProfilePrState.merged) ||
        states.contains(ProfilePrState.closed);
    final closedAsync = wantClosed
        ? ref.watch(userClosedPrsProvider(widget.login))
        : null;
    final closedState = closedAsync?.value;

    final data = _assembleProfileGroups(
      open: openAsync.value ?? const [],
      closed: closedState?.repos ?? const [],
      states: states,
      query: query,
    );
    _lastData = data;

    ref.listen<int?>(selectedPrNumberProvider, (_, next) {
      _ensureSelectedVisible(next);
    });

    final Widget content;
    if (openAsync.isLoading && !openAsync.hasValue) {
      content = const _Centered(child: FCircularProgress());
    } else if (openAsync.hasError && !openAsync.hasValue) {
      content = Center(
        child: FAlert(
          variant: FAlertVariant.destructive,
          title: Text(l10n.failedToLoad),
          subtitle: Text(openAsync.error.toString()),
        ),
      );
    } else if (data.isEmpty) {
      content = (closedAsync?.isLoading ?? false)
          ? const _Centered(child: FCircularProgress())
          : _emptyState(l10n, states, query);
    } else {
      content = _QueuePanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final group in data)
              RepoPrSection(
                repoPrs: group,
                browseOnly: true,
                rowKey: _rowKey,
                rowFocusNode: _rowFocusNode,
                // Only the merged/closed history paginates; the closed-state
                // maps are keyed by repo id (and empty for open-only groups, so
                // hasMore is false and no "load more" row shows there).
                hasMore: closedState?.hasMore[group.repo.id] ?? false,
                loadingMore: closedState?.loadingMore[group.repo.id] ?? false,
                onLoadMore: () => ref
                    .read(userClosedPrsProvider(widget.login).notifier)
                    .loadMore(group.repo.id),
              ),
          ],
        ),
      );
    }

    return ScopedShortcuts(
      scope: '/users',
      bindings: {
        'pr.user-focus-search': widget.searchFocusNode.requestFocus,
        'pr.user-focus-search-alt': widget.searchFocusNode.requestFocus,
        'pr.user-refresh': _refresh,
        if (data.isNotEmpty) ...{
          'pr.user-next': () => _cycle(1, data),
          'pr.user-prev': () => _cycle(-1, data),
          'pr.user-open': () => _openSelected(data),
          'pr.user-peek': _peekCursor,
        },
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          // The merged/closed history loads in the background once its card is
          // active; surface progress / failure without blocking the open list.
          if (closedAsync != null && closedAsync.isLoading && data.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: FCircularProgress(),
                ),
              ),
            ),
          if (closedAsync != null && closedAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: FAlert(
                title: Text(l10n.failedToLoad),
                subtitle: Text(closedAsync.error.toString()),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          PrKeyboardHints.userProfile(l10n),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _emptyState(
    AppLocalizations l10n,
    Set<ProfilePrState> states,
    String query,
  ) {
    if (query.trim().isNotEmpty) {
      return EmptyConfigState(
        icon: LucideIcons.searchX,
        message: l10n.noPrsMatchSearch,
        hint: l10n.noPrsMatchSearchHint,
      );
    }
    if (states.length == 1 && states.contains(ProfilePrState.open)) {
      return EmptyConfigState(
        icon: LucideIcons.gitPullRequest,
        message: l10n.noPrsByUserInWorkspace(widget.login),
        hint: '',
      );
    }
    return EmptyConfigState(
      icon: LucideIcons.gitPullRequest,
      message: l10n.profileNoPrsForFilter,
      hint: '',
    );
  }
}

/// Merges the author's open PRs with any fetched merged/closed history, keeps
/// only the [states] in play (and titles/numbers matching [query]), and groups
/// the survivors by repo — each group ordered most-recently-updated first.
List<RepoPullRequests> _assembleProfileGroups({
  required List<RepoPullRequests> open,
  required List<RepoPullRequests> closed,
  required Set<ProfilePrState> states,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  bool matches(PullRequest pr) =>
      q.isEmpty ||
      pr.title.toLowerCase().contains(q) ||
      '#${pr.number}'.contains(q);

  final byRepo = <String, ({Repo repo, List<PullRequest> prs})>{};
  void addGroup(RepoPullRequests group, bool Function(PullRequest) keep) {
    for (final pr in group.prs) {
      if (!keep(pr)) {
        continue;
      }
      final entry = byRepo.putIfAbsent(
        group.repo.id,
        () => (repo: group.repo, prs: <PullRequest>[]),
      );
      entry.prs.add(pr);
    }
  }

  if (states.contains(ProfilePrState.open) ||
      states.contains(ProfilePrState.draft)) {
    // The workspace queue carries this author's open PRs (open + draft).
    for (final group in open) {
      addGroup(
        group,
        (pr) => states.contains(profilePrStateOf(pr)) && matches(pr),
      );
    }
  }
  if (states.contains(ProfilePrState.merged) ||
      states.contains(ProfilePrState.closed)) {
    // The fetched history carries both merged and unmerged-closed PRs; keep
    // only the states whose card is active.
    for (final group in closed) {
      addGroup(
        group,
        (pr) => states.contains(profilePrStateOf(pr)) && matches(pr),
      );
    }
  }
  return _finalize(byRepo);
}

DateTime _topUpdated(RepoPullRequests group) =>
    group.prs.isNotEmpty ? (group.prs.first.updatedAt ?? _epoch) : _epoch;

List<RepoPullRequests> _finalize(
  Map<String, ({Repo repo, List<PullRequest> prs})> byRepo,
) {
  final groups =
      byRepo.values
          .map(
            (e) => RepoPullRequests(
              repo: e.repo,
              prs: List<PullRequest>.of(e.prs)
                ..sort(
                  (a, b) =>
                      (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch),
                ),
            ),
          )
          .toList()
        ..sort((a, b) => _topUpdated(b).compareTo(_topUpdated(a)));
  return groups;
}

/// A bordered, rounded panel wrapping the repo accordions — the same instrument
/// surface the main queue uses.
class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.child});

  final Widget child;

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
      child: ClipRRect(borderRadius: AppRadii.brLg, child: child),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(child: child),
    );
  }
}
