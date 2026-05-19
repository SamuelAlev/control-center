import 'dart:async';
import 'dart:math' as math;

import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_sidebar_overlay.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tabs_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/editable_pr_title.dart';
import 'package:control_center/features/pr_review/presentation/widgets/merge_flyout_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/open_in_ide_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_overlay.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_timer_banner.dart';
import 'package:control_center/features/pr_review/presentation/widgets/sticky_header.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_polling_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_tree_width_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/ready_auto_scroll.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pull request detail screen.
class PullRequestDetailScreen extends ConsumerWidget {
  /// PullRequestDetailScreen({super.key,.
  const PullRequestDetailScreen({super.key, required this.prNumber});

  /// PR number from the route parameters.
  final int prNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prAsync = ref.watch(prDetailProvider(prNumber));
    // Stamp freshness on every successful (re)load — initial fetch and each
    // poll/manual refresh — so the title row can report "Checked {time}".
    ref.listen(prDetailProvider(prNumber), (_, next) {
      if (next is AsyncData && !next.isLoading) {
        ref.read(lastCheckedProvider.notifier).stamp('pr-detail:$prNumber');
      }
    });
    return prAsync.when(
      data: (pr) {
        if (pr == null) {
          return PageWrapper(child: _NotFound(prNumber: prNumber));
        }
        return PageWrapper(
          // The editable PR title lives in the fixed title row (not the
          // scrolling body) so it stays visible while the diff/conversation
          // scrolls. It's still editable in place via [EditablePrTitle].
          titleWidget: EditablePrTitle(
            pr: pr,
            canEdit: ref.watch(prCanEditProvider(prNumber)),
          ),
          breadcrumbActions: [_PrBreadcrumbActions(pr: pr, prNumber: prNumber)],
          // Key by PR number so navigating between PRs gets a fresh
          // [_PrDetailBodyState] — without this, the diff view's
          // [GlobalKey]s for individual files (keyed by path) leak across
          // PRs, causing e.g. PR1's `package.json` content to bleed into
          // PR2's `package.json` view because the old [PrFileDiffState]
          // (with its cached `_fileLinesFuture`) gets reused.
          child: _PrDetailBody(
            key: ValueKey('pr-detail-$prNumber'),
            pr: pr,
            prNumber: prNumber,
          ),
        );
      },
      loading: () => const PageWrapper(child: PrDetailSkeleton()),
      error: (e, _) => PageWrapper(
        child: _ErrorState(prNumber: prNumber, error: e),
      ),
    );
  }
}

class _PrBreadcrumbActions extends ConsumerWidget {
  const _PrBreadcrumbActions({required this.pr, required this.prNumber});

  final PullRequest pr;
  final int prNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(activeRepoProvider);
    final owner = repo?.githubOwner ?? '';
    final repoName = repo?.githubRepoName ?? '';
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    // Determine if current user is the PR author
    final currentLogin = ref.watch(currentUserLoginProvider);
    final isAuthor =
        currentLogin.isNotEmpty &&
        pr.author?.login.toLowerCase() == currentLogin;

    // Check repo permission for merge/close
    final permissionAsync = ref.watch(
      repoPermissionProvider((owner: owner, repo: repoName)),
    );
    final hasWriteAccess =
        permissionAsync.whenOrNull(
          data: (perm) => perm == 'admin' || perm == 'write',
        ) ??
        false;

    // Watch check runs and reviews for merge readiness
    final checksAsync = ref.watch(prCheckRunsProvider(prNumber));
    final reviewsAsync = ref.watch(prReviewsProvider(prNumber));
    final checks = checksAsync.value ?? [];
    final reviews = reviewsAsync.value ?? [];

    final canClose = isAuthor || hasWriteAccess;

    final lastChecked = ref.watch(
      lastCheckedProvider.select((m) => m['pr-detail:$prNumber']),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Freshness label only — the manual refresh lives in the overflow menu.
        if (lastChecked != null) ...[
          RefreshControl(lastChecked: lastChecked),
          const SizedBox(width: 8),
        ],
        // Primary action(s): Review for non-authors, Merge when mergeable.
        // Secondary actions (Ask AI review, Close PR) live in the overflow
        // menu to keep this row scannable.
        if (!isAuthor) ...[
          ReviewOverlayButton(pr: pr, owner: owner, repo: repoName),
          const SizedBox(width: 8),
        ],
        if (hasWriteAccess && pr.canMerge) ...[
          MergeFlyoutButton(
            pr: pr,
            owner: owner,
            repo: repoName,
            checks: checks,
            reviews: reviews,
          ),
          const SizedBox(width: 8),
        ],
        // Open the PR's branch in an editor/IDE — its branch is lazily checked
        // out into a CoW worktree on click. Needs the repo checked out locally
        // (the CoW source) and an active workspace to own the worktree.
        if (repo != null &&
            repo.path.trim().isNotEmpty &&
            workspaceId != null) ...[
          OpenInIdeButton(pr: pr, repo: repo, workspaceId: workspaceId),
          const SizedBox(width: 8),
        ],
        _PrMoreActionsMenu(pr: pr, canClose: canClose),
      ],
    );
  }
}

class _PrMoreActionsMenu extends ConsumerStatefulWidget {
  const _PrMoreActionsMenu({required this.pr, required this.canClose});

  final PullRequest pr;
  final bool canClose;

  @override
  ConsumerState<_PrMoreActionsMenu> createState() => _PrMoreActionsMenuState();
}

class _PrMoreActionsMenuState extends ConsumerState<_PrMoreActionsMenu>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _controller;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = FPopoverController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startAiReview() async {
    if (_aiLoading) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    final workspace = ref.read(activeWorkspaceProvider);
    final repo = ref.read(activeRepoProvider);

    await _controller.hide();
    if (!mounted) {
      return;
    }

    if (workspace == null || repo == null) {
      scaffold.showSnackBar(SnackBar(content: Text(l10n.noActiveWorkspace)));
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final engine = ref.read(pipelineEngineProvider);
      final run = await engine.start(
        'pr_review',
        workspaceId: workspace.id,
        triggerEventType: 'manual',
        triggerPayload: {
          'workspaceId': workspace.id,
          'repoOwner': repo.githubOwner,
          'repoName': repo.githubRepoName,
          'repoFullName': repo.fullName,
          'prNumber': widget.pr.number,
          'prNodeId': widget.pr.nodeId,
          'prTitle': widget.pr.title,
          'author': widget.pr.author?.login ?? '',
        },
      );
      if (!mounted) {
        return;
      }
      if (run == null) {
        scaffold.showSnackBar(
          SnackBar(content: Text(l10n.failedToStartAiReview('duplicate run'))),
        );
        return;
      }
      context.go(pipelineRunRoute(run.id));
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.failedToStartAiReview('$e'))),
      );
    } finally {
      if (mounted) {
        setState(() => _aiLoading = false);
      }
    }
  }

  Future<void> _closePr() async {
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    await _controller.hide();
    if (!mounted) {
      return;
    }

    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.closePullRequest),
        body: Text(l10n.closePullRequestConfirm),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.of(ctx).pop(false),
                  variant: FButtonVariant.outline,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.of(ctx).pop(true),
                  variant: FButtonVariant.destructive,
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref
          .read(prReviewRepositoryProvider)
          .closePullRequest(prNumber: widget.pr.number);
      scaffold.showSnackBar(SnackBar(content: Text(l10n.pullRequestClosed)));
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.failedToClosePr('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showClose = widget.canClose && widget.pr.isOpen;
    final destructive = context.theme.colors.destructive;

    return FPopoverMenu.tiles(
      control: FPopoverControl.managed(controller: _controller),
      style: const FPopoverMenuStyleDelta.delta(maxWidth: 220),
      divider: FItemDivider.full,
      menu: [
        FTileGroup(
          divider: FItemDivider.full,
          children: [
            FTile(
              prefix: _aiLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.sparkles, size: 16),
              title: Text(l10n.askAi),
              onPress: _aiLoading ? null : _startAiReview,
            ),
            FTile(
              prefix: const Icon(LucideIcons.refreshCw, size: 16),
              title: Text(l10n.refresh),
              onPress: () {
                unawaited(_controller.hide());
                unawaited(
                  ref
                      .read(prDetailPollingProvider(widget.pr.number).notifier)
                      .refreshAll(),
                );
              },
            ),
            FTile(
              prefix: const Icon(LucideIcons.externalLink, size: 16),
              title: Text(l10n.openOnGithub),
              onPress: () {
                unawaited(_controller.hide());
                unawaited(launchUrl(Uri.parse(widget.pr.htmlUrl)));
              },
            ),
          ],
        ),
        if (showClose)
          FTileGroup(
            divider: FItemDivider.full,
            children: [
              FTile(
                prefix: Icon(LucideIcons.x, size: 16, color: destructive),
                title: Text(l10n.close, style: TextStyle(color: destructive)),
                onPress: _closePr,
              ),
            ],
          ),
      ],
      child: FTooltip(
        tipAnchor: Alignment.topCenter,
        childAnchor: Alignment.bottomCenter,
        tipBuilder: (_, _) => Text(l10n.prMoreActions),
        child: FButton.icon(
          onPress: () => _controller.toggle(),
          child: const Icon(LucideIcons.moreHorizontal, size: 16),
        ),
      ),
    );
  }
}

class _PrDetailBody extends ConsumerStatefulWidget {
  const _PrDetailBody({super.key, required this.pr, required this.prNumber});
  final PullRequest pr;
  final int prNumber;
  @override
  ConsumerState<_PrDetailBody> createState() => _PrDetailBodyState();
}

class _PrDetailBodyState extends ConsumerState<_PrDetailBody>
    with TickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<PrDiffViewState> _diffKey = GlobalKey<PrDiffViewState>();

  double _treeWidth = kDefaultPrTreeWidth;
  static const double _tabStripHeight = 44;
  static const double _stickyTopInset = _tabStripHeight;

  double _prHeaderHeight = 0;
  int _activeTab = 0;

  /// Last scroll offset observed while exactly one position was attached to
  /// [_scrollController]. Used to position the tree overlay during the brief
  /// frame in which [ReadyAutoScroll] re-parents the scroll view (flipping
  /// `_ready`) and the controller momentarily holds two positions — reading
  /// `.offset` then trips the `_positions.length == 1` assertion.
  double _lastScrollOffset = 0;

  late Widget _treeOverlay;

  @override
  void initState() {
    super.initState();
    _treeWidth = ref.read(prTreeWidthProvider);
    _tabController.addListener(_onTabChanged);
    _treeOverlay = _buildTree();
  }

  @override
  void didUpdateWidget(covariant _PrDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pr != widget.pr) {
      _treeOverlay = _buildTree();
    }
  }

  Widget _buildTree() => RepaintBoundary(
    key: ValueKey('tree-${widget.pr.number}'),
    child: TreeOverlay(pr: widget.pr, diffKey: _diffKey),
  );

  Widget _buildResizableTree(double availableWidth) {
    // Cap the tree at 50 % of the available width by giving the spacer
    // region a minExtent equal to half the width.
    final spacerMinExtent = (availableWidth * 0.5).ceilToDouble();
    return FResizable(
      axis: Axis.horizontal,
      divider: FResizableDivider.divider,
      children: [
        FResizableRegion.region(
          initialExtent: _treeWidth,
          minExtent: 160,
          builder: (context, data, _) {
            final w = data.extent.current;
            if ((w - _treeWidth).abs() > 1) {
              Future.microtask(() {
                if (mounted) {
                  setState(() => _treeWidth = w);
                  ref.read(prTreeWidthProvider.notifier).setWidth(w);
                }
              });
            }
            return _treeOverlay;
          },
        ),
        FResizableRegion.region(
          initialExtent: availableWidth - _treeWidth,
          minExtent: spacerMinExtent,
          builder: (context, data, _) =>
              const IgnorePointer(child: SizedBox.expand()),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    if (_tabController.index == _activeTab) {
      return;
    }

    setState(() => _activeTab = _tabController.index);
  }

  /// Reported by [_MeasureSize] on every header layout. The PR sidebar
  /// (reviewers/assignees/checks) grows asynchronously as those providers
  /// resolve, so the header's true height is not known at first frame — a
  /// one-shot post-frame measure would latch the pre-load height and strand
  /// the file-tree overlay over the tab strip. Reporting on every layout keeps
  /// [_prHeaderHeight] (and thus the tree's top) in sync. The `< 0.5` gate
  /// makes steady-state layouts free.
  void _onHeaderSize(Size size) {
    if (!mounted) {
      return;
    }
    if ((size.height - _prHeaderHeight).abs() < 0.5) {
      return;
    }
    setState(() => _prHeaderHeight = size.height);
  }

  @override
  Widget build(BuildContext context) {
    final pollingState = ref.watch(prDetailPollingProvider(widget.prNumber));

    ref.listen<PrChecksUiState>(prChecksUiProvider, (prev, next) {
      final requested = next.requestedTabIndex;
      if (requested == null) {
        return;
      }
      if (requested >= 0 && requested < _tabController.length) {
        if (_tabController.index != requested) {
          _tabController.animateTo(requested);
        }
      }
      ref.read(prChecksUiProvider.notifier).consumeTabRequest();
    });

    ref.listen(prDetailProvider(widget.prNumber), (prev, next) {
      final prevSha = prev?.value?.headSha;
      final nextSha = next.value?.headSha;
      if (prevSha != null &&
          nextSha != null &&
          prevSha.isNotEmpty &&
          nextSha.isNotEmpty &&
          prevSha != nextSha) {
        ref
            .read(prDetailPollingProvider(widget.prNumber).notifier)
            .notifyDiffStale();
      }
    });

    return ScopedShortcuts(
      scope: '/pull-requests/',
      bindings: {
        'pr.detail-tab-conv': () => _tabController.animateTo(0),
        'pr.detail-tab-files': () => _tabController.animateTo(1),
        'pr.detail-tab-review': () => _tabController.animateTo(3),
        'pr.detail-refresh': () => unawaited(
          ref
              .read(prDetailPollingProvider(widget.prNumber).notifier)
              .refreshAll(),
        ),
      },
      child: Column(
        children: [
          ReviewTimerBanner(prNumber: widget.prNumber),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideLayout = constraints.maxWidth >= 880;
                final showTree =
                    _activeTab == 0 && constraints.maxWidth >= 1024;
                return Stack(
                  children: [
                    StickyHeaderInset(
                      top: _stickyTopInset,
                      child: PrimaryScrollController(
                        controller: _scrollController,
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ReadyAutoScroll(
                            controller: _scrollController,
                            child: CustomScrollView(
                              controller: _scrollController,
                              slivers: [
                                SliverToBoxAdapter(
                                  // The file-tree overlay pins directly below this
                                  // header, so its top tracks the header's height. The
                                  // PrSidebar (reviewers/checks) grows asynchronously as
                                  // those providers resolve; [_MeasureSize] reports the
                                  // header's height on every layout so the tree never
                                  // latches an early, shorter measurement and ends up
                                  // painted over the tab strip.
                                  child: _MeasureSize(
                                    onChange: _onHeaderSize,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        0,
                                        24,
                                        16,
                                      ),
                                      child: PrHeaderSection(
                                        pr: widget.pr,
                                        prNumber: widget.pr.number,
                                        isWide: isWideLayout,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _TabStripHeaderDelegate(
                                    height: _tabStripHeight,
                                    background: context.theme.colors.background,
                                    borderColor: context.theme.colors.border,
                                    child: TabStripContent(
                                      controller: _tabController,
                                      prNumber: widget.pr.number,
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.only(
                                    // When the tree is visible the body shifts right to
                                    // make room for it; the tree itself is overlaid by
                                    // the [Positioned] below inside the same Stack.
                                    left: showTree ? _treeWidth : 0,
                                  ),
                                  // The tab content sits on a white surface, not
                                  // the warm off-white page canvas — the diff's
                                  // context lines are transparent and reveal this
                                  // behind the code. The matching tree panel and
                                  // the diff's own opaque fills (gutter, file
                                  // headers, gaps) use the same surface.
                                  sliver: DecoratedSliver(
                                    decoration: BoxDecoration(
                                      color:
                                          context.designSystem?.bgPrimary ??
                                          context.theme.colors.background,
                                    ),
                                    sliver: ActiveTabBody(
                                      tabIndex: _activeTab,
                                      pr: widget.pr,
                                      diffKey: _diffKey,
                                      hasDiffUpdate: pollingState.hasDiffUpdate,
                                      onRefreshDiff: () => unawaited(
                                        ref
                                            .read(
                                              prDetailPollingProvider(
                                                widget.prNumber,
                                              ).notifier,
                                            )
                                            .refreshDiff(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showTree && _prHeaderHeight > 0)
                      AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          // `_scrollController.offset` asserts when the controller has
                          // zero or multiple positions attached — which happens for a
                          // frame while ReadyAutoScroll re-parents the scrollable. Read
                          // the live pixels off a position directly (no assert): the
                          // sole one when settled, else the most-recently attached one
                          // (the new view after a re-parent). This keeps the tree in
                          // sync even when the re-parent settles without a scroll event,
                          // instead of stranding it at a stale cached offset.
                          final positions = _scrollController.positions;
                          final ScrollPosition? p = positions.length == 1
                              ? positions.first
                              : (positions.isNotEmpty ? positions.last : null);
                          if (p != null && p.hasPixels) {
                            _lastScrollOffset = p.pixels;
                          }
                          final offset = _lastScrollOffset;
                          // Tree sits inside the Files-Changed body, top-aligned
                          // with the toolbar card (which sits below the PR header
                          // and the tab strip). On scroll the tree slides up with
                          // the toolbar until it pins below the sticky tab strip.
                          final treeTop = math.max(
                            _stickyTopInset,
                            _prHeaderHeight + _stickyTopInset - offset,
                          );
                          return Positioned(
                            left: 0,
                            top: treeTop,
                            right: 0,
                            bottom: 0,
                            child: child!,
                          );
                        },
                        child: _buildResizableTree(constraints.maxWidth),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.prNumber});
  final int prNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.fileQuestion,
            size: 48,
            color: context.theme.colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.pullRequestNotFound,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pullRequestNotFoundBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => context.go(pullRequestsRoute),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.arrowLeft, size: 16),
                const SizedBox(width: 8),
                Text(l10n.backToPullRequests),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabStripHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabStripHeaderDelegate({
    required this.height,
    required this.background,
    required this.borderColor,
    required this.child,
  });

  final double height;
  final Color background;
  final Color borderColor;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabStripHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.background != background ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.child != child;
  }
}

/// Reports its child's laid-out [Size] via [onChange] on every layout pass —
/// including the asynchronous re-layouts that happen as the PR sidebar's
/// checks/reviews stream in. Unlike a GlobalKey + one-shot post-frame measure,
/// this fires whenever the size actually changes, so a consumer that positions
/// itself off the size never latches a stale value.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderBox(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderBox renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderBox extends RenderProxyBox {
  _MeasureSizeRenderBox(this.onChange);

  ValueChanged<Size> onChange;
  Size? _lastReported;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_lastReported == newSize) {
      return;
    }
    _lastReported = newSize;
    // onChange calls setState; defer out of the layout phase.
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}

class _ErrorState extends ConsumerStatefulWidget {
  const _ErrorState({required this.prNumber, required this.error});
  final int prNumber;
  final Object error;

  @override
  ConsumerState<_ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends ConsumerState<_ErrorState> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.triangleAlert,
                size: 48,
                color: colors.destructive,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.couldntLoadPullRequest,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FButton(
                    onPress: () =>
                        ref.invalidate(prDetailProvider(widget.prNumber)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.refreshCw, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.retry),
                      ],
                    ),
                  ),
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => setState(() => _showDetails = !_showDetails),
                    child: Text(l10n.showDetails),
                  ),
                ],
              ),
              if (_showDetails) ...[
                const SizedBox(height: 16),
                SelectableText(
                  widget.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
