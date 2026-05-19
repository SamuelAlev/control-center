import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_skeleton.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_row.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/repo_pr_helpers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        CcTappable(
          onPressed: () => collapsedNotifier.toggle(repoId),
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
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  LucideIcons.folderGit,
                  size: 14,
                  color: tokens.muted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.repoPrs.repo.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontFamily: 'JetBrains Mono',
                      color: tokens.fg,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  countLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontFamily: 'JetBrains Mono',
                    color: tokens.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
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
                          PrListRow(
                            pr: pr,
                            repo: widget.repoPrs.repo,
                            lane: primaryLaneOf(lanesOfPr(pr, currentLogin)),
                            rowKey: widget.rowKey(repoId, pr.number),
                            focusNode: widget.rowFocusNode(repoId, pr.number),
                            browseOnly: widget.browseOnly,
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
