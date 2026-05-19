import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_skeleton.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_row.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/repo_pr_helpers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One collapsible repository group inside the queue panel: a tappable header
/// (repo name + a count of visible/total) over the lane- and filter-narrowed,
/// sorted [PrListRow]s. The whole group hides itself when nothing is visible,
/// so an active lane filter never leaves empty headers behind.
class RepoPrSection extends ConsumerStatefulWidget {
  /// Creates a [RepoPrSection].
  const RepoPrSection({
    super.key,
    required this.repoPrs,
    required this.rowKey,
    required this.rowFocusNode,
    this.isLoading = false,
    this.hasMore = false,
    this.loadingMore = false,
    this.browseOnly = false,
    this.onLoadMore,
  });

  /// The repo and its (unfiltered) pull requests.
  final RepoPullRequests repoPrs;

  /// Stable row-key getter, keyed by (repo id, PR number).
  final PrRowKeyGetter rowKey;

  /// Row focus-node getter, keyed by (repo id, PR number).
  final PrRowFocusGetter rowFocusNode;

  /// Whether the repo's PRs are still loading (renders a skeleton).
  final bool isLoading;

  /// Whether more PRs can be paged in.
  final bool hasMore;

  /// Whether a "load more" request is in flight.
  final bool loadingMore;

  /// Browse-only rows (the user-profile list): no selection checkbox, a plain
  /// "Open" action, forwarded to each [PrListRow].
  final bool browseOnly;

  /// What the "load more" row triggers. Defaults to paging the main PR queue
  /// (`prsByRepoProvider.loadMore`); the user-profile queue overrides this to
  /// page its own merged/closed history instead.
  final VoidCallback? onLoadMore;

  @override
  ConsumerState<RepoPrSection> createState() => _RepoPrSectionState();
}

class _RepoPrSectionState extends ConsumerState<RepoPrSection> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final repoId = widget.repoPrs.repo.id;
    final collapsedNotifier = ref.read(collapsedReposProvider.notifier);
    final collapsed = ref.watch(
      collapsedReposProvider.select((s) => s.contains(repoId)),
    );
    final filters = ref.watch(prListFiltersProvider);
    final currentLogin = ref.watch(currentUserLoginProvider);
    final lane = ref.watch(decisionLaneFilterProvider);
    final sort = ref.watch(prListSortProvider);

    final visible = widget.isLoading
        ? const <PullRequest>[]
        : visiblePrsFor(
            widget.repoPrs.prs,
            filters: filters,
            currentLogin: currentLogin,
            lane: lane,
            sort: sort,
          );

    // Hide the whole group when a filter/lane leaves it empty — no dangling
    // headers. (Loading groups always render their skeleton.)
    if (!widget.isLoading && visible.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalCount = widget.repoPrs.prs.length;
    final suffix = widget.hasMore ? '+' : '';
    final narrowed = lane != null || filters.isActive;
    final countLabel = narrowed
        ? '${visible.length} / $totalCount$suffix'
        : '$totalCount$suffix';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RepoSectionHeader(
          repoFullName: widget.repoPrs.repo.fullName,
          countLabel: countLabel,
          collapsed: collapsed,
          onTap: () => collapsedNotifier.toggle(repoId),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: collapsed
              ? const SizedBox(width: double.infinity)
              : widget.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: RepoSectionSkeleton(),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final pr in visible)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: tokens.borderSecondary,
                          ),
                          // This section spreads every visible row into a
                          // Column (not a lazy sliver), so without a boundary a
                          // single row's hover/stream tick repaints every avatar
                          // in the queue. Isolate each row's paint layer.
                          RepaintBoundary(
                            child: PrListRow(
                              pr: pr,
                              repo: widget.repoPrs.repo,
                              lane: primaryLaneOf(lanesOfPr(pr, currentLogin)),
                              rowKey: widget.rowKey(repoId, pr.number),
                              focusNode: widget.rowFocusNode(repoId, pr.number),
                              browseOnly: widget.browseOnly,
                            ),
                          ),
                        ],
                      ),
                    if (widget.hasMore)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: tokens.borderSecondary,
                          ),
                          LoadMoreRow(
                            loading: widget.loadingMore,
                            onLoad:
                                widget.onLoadMore ??
                                () => ref
                                    .read(prsByRepoProvider.notifier)
                                    .loadMore(repoId),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The collapsible repo-group header — a chevron + folder glyph + repo name +
/// a visible/total count — shared by the boxed [RepoPrSection] (the short
/// user-profile list) and the virtualized [RepoPrSectionSliver] (the main
/// queue) so the two stay visually identical.
class _RepoSectionHeader extends StatelessWidget {
  const _RepoSectionHeader({
    required this.repoFullName,
    required this.countLabel,
    required this.collapsed,
    required this.onTap,
  });

  final String repoFullName;
  final String countLabel;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: tokens.rail,
          border: Border(
            top: BorderSide(color: tokens.borderSecondary),
            left: BorderSide(color: tokens.borderSecondary),
            right: BorderSide(color: tokens.borderSecondary),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.lg,
        ),
        child: Row(
          children: [
            AnimatedRotation(
              turns: collapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 150),
              child: Icon(AppIcons.chevronDown, size: 14, color: tokens.muted),
            ),
            const SizedBox(width: 6),
            Icon(AppIcons.folderGit, size: 14, color: tokens.muted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                repoFullName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFamily: CcFonts.codeFamily,
                  color: tokens.fg,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              countLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontFamily: CcFonts.codeFamily,
                color: tokens.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliver-emitting variant of [RepoPrSection] for the main, potentially long
/// PR queue: rows render through a lazy [SliverList] so only the on-screen rows
/// are built and laid out. The boxed [RepoPrSection] builds every row eagerly —
/// fine for the short user-profile list, but the source of the queue's
/// mount-time and filter-change layout cost. Returns a [SliverMainAxisGroup] so
/// a [CustomScrollView] can compose one per repo behind a single bordered panel.
///
/// Collapsing drops the row sliver (the chevron still animates); the boxed
/// variant's [AnimatedSize] height-slide is traded for instant collapse, which
/// a virtualized sliver list cannot animate.
class RepoPrSectionSliver extends ConsumerWidget {
  /// Creates a [RepoPrSectionSliver].
  const RepoPrSectionSliver({
    super.key,
    required this.repoPrs,
    required this.rowKey,
    required this.rowFocusNode,
    this.hasMore = false,
    this.loadingMore = false,
    this.browseOnly = false,
    this.onLoadMore,
  });

  /// The repo and its (unfiltered) pull requests.
  final RepoPullRequests repoPrs;

  /// Stable row-key getter, keyed by (repo id, PR number).
  final PrRowKeyGetter rowKey;

  /// Row focus-node getter, keyed by (repo id, PR number).
  final PrRowFocusGetter rowFocusNode;

  /// Whether more PRs can be paged in.
  final bool hasMore;

  /// Whether a "load more" request is in flight.
  final bool loadingMore;

  /// Browse-only rows (no selection checkbox, plain "Open" action).
  final bool browseOnly;

  /// What the "load more" row triggers; defaults to paging the main queue.
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final repoId = repoPrs.repo.id;
    final collapsed = ref.watch(
      collapsedReposProvider.select((s) => s.contains(repoId)),
    );
    final filters = ref.watch(prListFiltersProvider);
    final currentLogin = ref.watch(currentUserLoginProvider);
    final lane = ref.watch(decisionLaneFilterProvider);
    final sort = ref.watch(prListSortProvider);

    final visible = visiblePrsFor(
      repoPrs.prs,
      filters: filters,
      currentLogin: currentLogin,
      lane: lane,
      sort: sort,
    );

    // Hide the whole group when a filter/lane leaves it empty — no dangling
    // headers. A zero-extent adapter keeps the slivers list rectangular.
    if (visible.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final totalCount = repoPrs.prs.length;
    final suffix = hasMore ? '+' : '';
    final narrowed = lane != null || filters.isActive;
    final countLabel = narrowed
        ? '${visible.length} / $totalCount$suffix'
        : '$totalCount$suffix';

    Widget rowTile(PullRequest pr) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: tokens.borderSecondary),
        // The lazy SliverList already bounds how many rows exist, but the
        // RepaintBoundary still isolates each row so a single row's
        // hover/stream tick never repaints its on-screen neighbours.
        RepaintBoundary(
          child: PrListRow(
            pr: pr,
            repo: repoPrs.repo,
            lane: primaryLaneOf(lanesOfPr(pr, currentLogin)),
            rowKey: rowKey(repoId, pr.number),
            focusNode: rowFocusNode(repoId, pr.number),
            browseOnly: browseOnly,
          ),
        ),
      ],
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _RepoSectionHeader(
            repoFullName: repoPrs.repo.fullName,
            countLabel: countLabel,
            collapsed: collapsed,
            onTap: () =>
                ref.read(collapsedReposProvider.notifier).toggle(repoId),
          ),
        ),
        if (!collapsed)
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, i) => rowTile(visible[i]),
          ),
        if (!collapsed && hasMore)
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: tokens.borderSecondary,
                ),
                LoadMoreRow(
                  loading: loadingMore,
                  onLoad:
                      onLoadMore ??
                      () => ref
                          .read(prsByRepoProvider.notifier)
                          .loadMore(repoId),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
