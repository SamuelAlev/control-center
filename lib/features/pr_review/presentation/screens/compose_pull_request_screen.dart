import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_commits_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_chip.dart';
import 'package:control_center/features/pr_review/presentation/widgets/compose/compose_branch_bar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/compose/compose_file_tree_overlay.dart';
import 'package:control_center/features/pr_review/presentation/widgets/compose/compose_pr_body_field.dart';
import 'package:control_center/features/pr_review/presentation/widgets/compose/compose_pr_pickers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/compose/compose_unpushed_head_notice.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/presentation/widgets/sticky_header.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_tree_width_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "open a pull request" page: the PR detail layout in compose mode —
/// pick base/compare branches, fill the title + description, choose assignees
/// and reviewers, preview the real diff, then create (optionally as a draft).
///
/// Reachable two ways. From the PR list it is standalone and every candidate
/// branch comes from the GitHub remote. From a conversation's Source Control
/// panel it carries [channelId], which lets it resolve that conversation's
/// isolated worktree, offer its branch as the compare head, pre-select it and
/// publish it to `origin` before opening the PR — a chat worktree's branch is
/// local-only, so without this the screen showed no branch to compare and the
/// create buttons could never enable.
class ComposePullRequestScreen extends ConsumerStatefulWidget {
  /// Creates a [ComposePullRequestScreen].
  const ComposePullRequestScreen({super.key, this.channelId});

  /// The conversation this compose was launched from, or null when it was opened
  /// standalone from the pull-request list.
  final String? channelId;

  @override
  ConsumerState<ComposePullRequestScreen> createState() =>
      _ComposePullRequestScreenState();
}

class _ComposePullRequestScreenState
    extends ConsumerState<ComposePullRequestScreen> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(
      () =>
          ref.read(composePrProvider.notifier).setTitle(_titleController.text),
    );
    final channelId = widget.channelId;
    if (channelId != null && channelId.isNotEmpty) {
      // `fireImmediately` matters: a plain listen only reacts to a *transition*,
      // so a branch that is already resolved by the time this screen mounts (a
      // warm provider, or a cached worktree lookup) would never seed the head —
      // leaving the compare picker empty for exactly the case this flow exists
      // to serve.
      ref.listenManual<AsyncValue<String?>>(
        worktreeBranchProvider(channelId),
        (_, next) => _seedHead(next.value),
        fireImmediately: true,
      );
    }
  }

  /// Defaults the compare branch to the conversation's worktree branch, once,
  /// while the user hasn't picked one.
  ///
  /// Deferred to a microtask because both call sites (`initState` and a listener
  /// firing during build) are widget lifecycles, where Riverpod forbids writing
  /// to a provider.
  void _seedHead(String? branch) {
    if (branch == null || branch.isEmpty) {
      return;
    }
    Future.microtask(() {
      if (!mounted || ref.read(composePrProvider).head.isNotEmpty) {
        return;
      }
      ref.read(composePrProvider.notifier).setHead(branch);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool asDraft}) async {
    final toaster = CcToastScope.of(context);
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    // The active workspace is the source of truth (route-driven), not the raw
    // route param — reading it via the provider keeps this working when the
    // caller isn't mounted under a workspace-prefixed route.
    final ws = ref.read(activeWorkspaceIdProvider);
    if (ws == null) {
      return;
    }
    // The PR is composed against the active repo; capture it before the await so
    // the detail URL carries the repo it was created in.
    final repo = ref.read(activeRepoProvider);
    final number = await ref
        .read(composePrProvider.notifier)
        .submit(asDraft: asDraft);
    if (!mounted) {
      return;
    }
    if (number != null) {
      router.go(
        repo != null
            ? pullRequestDetailRoute(ws, repo.fullName, number)
            : pullRequestsRoute(ws),
      );
    } else {
      final error = ref.read(composePrProvider).error;
      toaster.show(
        l10n.failedWithError(error ?? ''),
        variant: CcToastVariant.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAuthed = ref.watch(hasAnyForgeConnectedProvider);
    final repo = ref.watch(activeRepoProvider);

    // Switching the active repo invalidates any staged branches (they belong to
    // the old repo). Clear them so the diff and pickers don't reference a branch
    // that no longer exists — the base re-defaults below once the new repo's
    // default branch resolves.
    ref.listen(activeRepoIdProvider, (previous, next) {
      if (previous != next) {
        ref.read(composePrProvider.notifier).resetBranches();
      }
    });

    // Default the base branch to the repo's default branch once it resolves
    // (only while the user hasn't picked one yet).
    ref.listen(defaultBranchProvider, (_, next) {
      final def = next.value;
      if (def != null &&
          def.isNotEmpty &&
          ref.read(composePrProvider).base.isEmpty) {
        ref.read(composePrProvider.notifier).setBase(def);
      }
    });

    // The conversation's worktree branch — the compare head the user means and
    // the one the remote listing cannot know about until it is published.
    final channelId = widget.channelId;
    final localBranchAsync = channelId == null || channelId.isEmpty
        ? const AsyncValue<String?>.data(null)
        : ref.watch(worktreeBranchProvider(channelId));
    final localBranch = localBranchAsync.value;

    final state = ref.watch(composePrProvider);

    return PageWrapper(
      title: l10n.openPullRequest,
      // The standalone copy ("from a branch you've pushed") is a lie when the
      // compose was launched from a conversation: the branch is precisely one the
      // user has NOT pushed and publishing it is part of this flow.
      subtitle: (channelId == null || channelId.isEmpty)
          ? l10n.composePrSubtitle
          : l10n.composePrSubtitleFromChannel,
      breadcrumbActions: [
        CcButton(
          onPressed: () => GoRouter.of(
            context,
          ).go(pullRequestsRoute(context.currentWorkspaceId!)),
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          child: Text(l10n.cancel),
        ),
        const SizedBox(width: AppSpacing.sm),
        CcButton(
          onPressed: (!state.canSubmit || state.submitting)
              ? null
              : () => _submit(asDraft: true),
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          child: Text(l10n.createAsDraft),
        ),
        const SizedBox(width: AppSpacing.sm),
        CcButton(
          onPressed: (!state.canSubmit || state.submitting)
              ? null
              : () => _submit(asDraft: false),
          loading: state.submitting,
          icon: AppIcons.gitPullRequestCreate,
          size: CcButtonSize.sm,
          child: Text(l10n.createPullRequest),
        ),
      ],
      child: (!isAuthed || repo == null || !repo.hasForgeRemote)
          ? EmptyConfigState(
              icon: AppIcons.gitPullRequest,
              message: l10n.composePrNoRepo,
              hint: l10n.composePrNoRepoHint,
            )
          : _Body(
              repoFullName: repo.fullName,
              titleController: _titleController,
              localBranch: localBranch,
              channelId: channelId,
            ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.repoFullName,
    required this.titleController,
    this.localBranch,
    this.channelId,
  });

  final String repoFullName;
  final TextEditingController titleController;

  /// The launching conversation's worktree branch, when there is one.
  final String? localBranch;

  /// The launching conversation, when the compose came from a chat.
  final String? channelId;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<PrDiffViewState> _diffKey = GlobalKey<PrDiffViewState>();
  final GlobalKey _formKey = GlobalKey();
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  /// Height of the pinned Files/Commits tab strip — mirrors the PR detail page.
  static const double _tabStripHeight = 44;

  /// Width of the changed-files tree gutter (shared/persisted with PR detail).
  double _treeWidth = kDefaultPrTreeWidth;

  /// Measured height of the form block above the diff — the document offset at
  /// which the tab strip + sticky tree begin.
  double _formHeight = 0;

  /// Last good scroll offset; reused for the frame the controller transiently
  /// holds multiple positions (reading `.offset` then would assert).
  double _lastScrollOffset = 0;

  /// Active diff tab: 0 = Files changed, 1 = Commits.
  int _activeTab = 0;

  // The tree widget is cached and only rebuilt when the compared branches
  // change — reusing the same instance across resize-drag frames preserves the
  // tree's internal open/closed directory state.
  String _treeBase = '';
  String _treeHead = '';
  Widget _treeOverlay = const SizedBox.shrink();

  @override
  void initState() {
    super.initState();
    _treeWidth = ref.read(prTreeWidthProvider);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging || _tabController.index == _activeTab) {
      return;
    }
    setState(() => _activeTab = _tabController.index);
  }

  void _scheduleFormMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureForm());
  }

  void _measureForm() {
    final ctx = _formKey.currentContext;
    if (ctx == null) {
      return;
    }
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return;
    }
    final h = box.size.height;
    if ((h - _formHeight).abs() < 0.5 || !mounted) {
      return;
    }
    setState(() => _formHeight = h);
  }

  Widget _buildResizableTree(double availableWidth) {
    // Cap the tree at 50% of the available width by giving the spacer region a
    // minExtent equal to half the width.
    final spacerMinExtent = (availableWidth * 0.5).ceilToDouble();
    return CcResizable(
      axis: Axis.horizontal,
      onResize: (extents) {
        // The tree is the first region; persist its width back to the shared
        // provider (and our local field) when a drag changes it.
        final w = extents.first;
        if ((w - _treeWidth).abs() > 1) {
          Future.microtask(() {
            if (mounted) {
              setState(() => _treeWidth = w);
              ref.read(prTreeWidthProvider.notifier).setWidth(w);
            }
          });
        }
      },
      regions: [
        CcResizableRegion(
          initialExtent: _treeWidth,
          minExtent: 160,
          builder: (context) => _treeOverlay,
        ),
        CcResizableRegion(
          initialExtent: availableWidth - _treeWidth,
          minExtent: spacerMinExtent,
          builder: (context) => const IgnorePointer(child: SizedBox.expand()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final token = ref.watch(githubAuthTokenProvider);
    final base = ref.watch(composePrProvider.select((s) => s.base));
    final head = ref.watch(composePrProvider.select((s) => s.head));

    // Rebuild the cached tree — and snap back to the Files tab — when the
    // compared branches change.
    if (base != _treeBase || head != _treeHead) {
      _treeBase = base;
      _treeHead = head;
      _treeOverlay = RepaintBoundary(
        key: ValueKey('compose-tree-$base...$head'),
        child: ComposeFileTreeOverlay(
          base: base,
          head: head,
          diffKey: _diffKey,
        ),
      );
      if (_activeTab != 0) {
        _activeTab = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tabController.index != 0) {
            _tabController.index = 0;
          }
        });
      }
    }

    final validPair = base.isNotEmpty && head.isNotEmpty && base != head;
    // The compare branch exists only in the conversation's worktree: GitHub has
    // never seen it, so it must be published before a PR can name it as head.
    // Only claimed once the remote listing has actually resolved — while it is
    // loading, "absent from the list" means nothing.
    final remoteBranches = ref.watch(repoBranchesProvider);
    final needsPublish =
        head.isNotEmpty &&
        widget.channelId != null &&
        head == widget.localBranch &&
        remoteBranches.hasValue &&
        !remoteBranches.requireValue.contains(head);
    final diffAsync = ref.watch(
      branchComparisonProvider((base: base, head: head)),
    );

    // Default the title to the head branch's first commit once the comparison
    // resolves — only while the user hasn't typed a title yet. Setting the
    // controller text propagates to the form state via the title listener.
    ref.listen(branchComparisonProvider((base: base, head: head)), (_, next) {
      final commits = next.value?.commits;
      if (commits == null || commits.isEmpty) {
        return;
      }
      if (widget.titleController.text.trim().isNotEmpty) {
        return;
      }
      widget.titleController.text = commits.first.title;
    });
    final diff = diffAsync.value;
    final filesCount = diff?.files.length ?? 0;
    final commitsCount = diff?.commits.length ?? 0;
    final showTabs =
        validPair && diff != null && (filesCount > 0 || commitsCount > 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        _scheduleFormMeasure();
        final showTree =
            showTabs &&
            _activeTab == 0 &&
            filesCount > 0 &&
            constraints.maxWidth >= 1024;
        return Stack(
          children: [
            StickyHeaderInset(
              top: showTabs ? _tabStripHeight : 0,
              child: PrimaryScrollController(
                controller: _scrollController,
                // No explicit scrollbar: the app-wide [CcScrollBehavior]
                // injects the design-system one for vertical scrollables.
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child:
                          NotificationListener<SizeChangedLayoutNotification>(
                            onNotification: (_) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _measureForm(),
                              );
                              return true;
                            },
                            child: SizeChangedLayoutNotifier(
                              child: Padding(
                                key: _formKey,
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xl,
                                  0,
                                  AppSpacing.xl,
                                  AppSpacing.lg,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1100,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ComposeBranchBar(
                                          localBranch: widget.localBranch,
                                        ),
                                        if (needsPublish) ...[
                                          const SizedBox(height: AppSpacing.md),
                                          ComposeUnpushedHeadNotice(
                                            branch: head,
                                            channelId: widget.channelId!,
                                          ),
                                        ],
                                        const SizedBox(height: AppSpacing.lg),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(l10n.titleLabel),
                                            const SizedBox(height: 6),
                                            CcTextField(
                                              controller:
                                                  widget.titleController,
                                              hintText: l10n.prTitle,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ComposePrBodyField(
                                                repoFullName:
                                                    widget.repoFullName,
                                                githubToken: token,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xl,
                                            ),
                                            const SizedBox(
                                              width: 240,
                                              child: ComposePrSidebar(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        Container(
                                          height: 1,
                                          color: t.borderSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                    if (showTabs)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _ComposeTabBarDelegate(
                          height: _tabStripHeight,
                          background: t.bgPrimary,
                          borderColor: t.borderSecondary,
                          child: _ComposeTabBar(
                            controller: _tabController,
                            filesCount: filesCount,
                            commitsCount: commitsCount,
                          ),
                        ),
                      ),
                    _buildBodySliver(
                      l10n: l10n,
                      validPair: validPair,
                      diffAsync: diffAsync,
                      showTree: showTree,
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                ),
              ),
            ),
            if (showTree && _formHeight > 0)
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  if (_scrollController.positions.length == 1) {
                    _lastScrollOffset = _scrollController.offset;
                  }
                  // The tree slides up with the diff, then pins just below the
                  // sticky tab strip at the top of the scroll viewport.
                  final treeTop = math.max(
                    _tabStripHeight,
                    _formHeight + _tabStripHeight - _lastScrollOffset,
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
    );
  }

  Widget _buildBodySliver({
    required AppLocalizations l10n,
    required bool validPair,
    required AsyncValue<ComposeDiff?> diffAsync,
    required bool showTree,
  }) {
    if (!validPair) {
      return SliverToBoxAdapter(
        child: _CenteredHint(message: l10n.composePrPickBranches),
      );
    }
    return diffAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CcSpinner()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _CenteredHint(message: l10n.failedWithError('$e')),
      ),
      data: (diff) {
        if (diff == null || (diff.files.isEmpty && diff.commits.isEmpty)) {
          return SliverToBoxAdapter(
            child: _CenteredHint(message: l10n.composePrNothingToCompare),
          );
        }
        if (_activeTab == 1) {
          return SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: CommitsTab(
                    commits: diff.commits,
                    isLoading: false,
                    error: null,
                    totalCommitsCount: diff.totalCommits,
                  ),
                ),
              ),
            ),
          );
        }
        if (diff.files.isEmpty) {
          return SliverToBoxAdapter(
            child: _CenteredHint(message: l10n.composePrNothingToCompare),
          );
        }
        return SliverPadding(
          padding: EdgeInsets.only(left: showTree ? _treeWidth : 0),
          sliver: PrDiffView(
            key: _diffKey,
            files: diff.files,
            comments: const [],
          ),
        );
      },
    );
  }
}

/// The pinned Files-changed / Commits tab strip above the compose diff, styled
/// to match the PR detail page's tab strip.
class _ComposeTabBar extends StatelessWidget {
  const _ComposeTabBar({
    required this.controller,
    required this.filesCount,
    required this.commitsCount,
  });

  final TabController controller;
  final int filesCount;
  final int commitsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      indicatorColor: t.textPrimary,
      labelColor: t.textPrimary,
      unselectedLabelColor: t.textTertiary,
      tabs: [
        Tab(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.fileText, size: 14),
              const SizedBox(width: 6),
              Text(l10n.filesChanged),
              const SizedBox(width: 6),
              CountBadge(count: filesCount),
            ],
          ),
        ),
        Tab(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.gitCommit, size: 14),
              const SizedBox(width: 6),
              Text(l10n.commits),
              const SizedBox(width: 6),
              CountBadge(count: commitsCount),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sliver delegate that pins [_ComposeTabBar] below the form while the diff
/// scrolls. Mirrors the PR detail page's tab-strip header.
class _ComposeTabBarDelegate extends SliverPersistentHeaderDelegate {
  _ComposeTabBarDelegate({
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
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ComposeTabBarDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.background != background ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.child != child;
  }
}

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: t.textTertiary),
        ),
      ),
    );
  }
}
