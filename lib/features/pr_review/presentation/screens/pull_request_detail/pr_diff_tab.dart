import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_diff_scope_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_files_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_sidebar_overlay.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_chip.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/scoped_diff_files.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/commit_range_selector.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/diff_settings_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/toolbar_chips.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_overlay.dart';
import 'package:control_center/features/pr_review/providers/pr_diff_view_prefs_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_tree_width_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/ready_auto_scroll.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR-detail **Diff** tab: one toolbar row (tree toggle, commit-range
/// dropdown, diff stats, view settings) over the diff surface — a resizable
/// file-tree beside the scrolling diff. The tree toggle persists across
/// sessions; the tree is also dropped on narrow windows where there is no
/// room for it.
class PrDiffTab extends ConsumerStatefulWidget {
  /// Creates a [PrDiffTab].
  const PrDiffTab({
    super.key,
    required this.pr,
    this.pendingFileJump,
    this.hasDiffUpdate = false,
    this.onRefreshDiff,
    this.onOpenFileInEditor,
  });

  /// The pull request.
  final PullRequest pr;

  /// A cross-tab signal carrying a tree-order file index the Overview sidebar
  /// asked to open: this tab jumps to it, then clears it. Null when the Diff
  /// tab is used standalone (no Overview to drive it).
  final ValueNotifier<int?>? pendingFileJump;

  /// Whether there is a pending diff update banner to show.
  final bool hasDiffUpdate;

  /// Refreshes the diff when the pending-update banner is tapped.
  final VoidCallback? onRefreshDiff;

  /// Opens a file (repo-relative path) at an optional 1-based line in an
  /// editable code-server tab — the host (PR detail screen) owns the editor
  /// layout. Drives the tree hover action, the diff file header, and search
  /// results. Null on standalone use.
  final void Function(String path, {int? line})? onOpenFileInEditor;

  @override
  ConsumerState<PrDiffTab> createState() => _PrDiffTabState();
}

class _PrDiffTabState extends ConsumerState<PrDiffTab> {
  final ScrollController _scrollController = ScrollController();

  /// This tab's own diff view (per-tab, so split Diff panes never collide on a
  /// shared [GlobalKey]). Drives both the file-tree navigator and the
  /// Overview-driven file jump.
  final GlobalKey<PrDiffViewState> _diffKey = GlobalKey<PrDiffViewState>();

  double _treeWidth = kDefaultPrTreeWidth;

  /// Below this width the file tree is dropped (no room beside the diff).
  static const double _treeBreakpoint = 1024;

  /// Which sidebar surface is shown (tree vs "search in files").
  PrDiffSidebarMode _sidebarMode = PrDiffSidebarMode.tree;

  /// Bumped to (re)focus the search field when ⌘F / the search button reveals
  /// the search surface.
  int _searchFocusToken = 0;

  /// Whether the tree/search sidebar *fits* beside the diff at the current
  /// width (independent of the visibility toggle). Set from the layout pass and
  /// read by the ⌘F handler to decide sidebar-search vs the floating overlay.
  bool _treeFits = false;

  /// Reveals the sidebar in search mode + focuses the field. Returns false when
  /// there is no room for the sidebar (narrow window) so the caller (the diff's
  /// ⌘F handler) falls back to the floating in-diff search.
  bool _requestSidebarSearch() {
    if (!_treeFits) {
      return false;
    }
    ref.read(prTreeVisibleProvider.notifier).setVisible(visible: true);
    setState(() {
      _sidebarMode = PrDiffSidebarMode.search;
      _searchFocusToken++;
    });
    return true;
  }

  void _showFileTree() {
    if (_sidebarMode == PrDiffSidebarMode.tree) {
      return;
    }
    setState(() => _sidebarMode = PrDiffSidebarMode.tree);
  }

  @override
  void initState() {
    super.initState();
    _treeWidth = ref.read(prTreeWidthProvider);
    widget.pendingFileJump?.addListener(_maybeJumpToPendingFile);
    _maybeJumpToPendingFile();
  }

  @override
  void dispose() {
    widget.pendingFileJump?.removeListener(_maybeJumpToPendingFile);
    _scrollController.dispose();
    super.dispose();
  }

  /// Consumes a pending Overview file-open: jump to the file once the diff
  /// mounts, then clear the signal.
  void _maybeJumpToPendingFile() {
    final index = widget.pendingFileJump?.value;
    if (index == null || !mounted) {
      return;
    }
    _scheduleJump(index, attempts: 30);
  }

  void _scheduleJump(int index, {required int attempts}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final state = _diffKey.currentState;
      if (state != null) {
        unawaited(state.jumpToFile(index));
        if (widget.pendingFileJump?.value == index) {
          widget.pendingFileJump!.value = null;
        }
      } else if (attempts > 0) {
        _scheduleJump(index, attempts: attempts - 1);
      } else if (widget.pendingFileJump?.value == index) {
        widget.pendingFileJump!.value = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final treeVisible = ref.watch(prTreeVisibleProvider);
    final splitView = ref.watch(prDiffSplitViewProvider);
    return Column(
      children: [
        _buildToolbar(context, treeVisible: treeVisible, splitView: splitView),
        Expanded(
          child: _buildFiles(
            context,
            treeVisible: treeVisible,
            splitView: splitView,
          ),
        ),
      ],
    );
  }

  /// The merged toolbar: tree toggle, commit-range dropdown, scoped diff
  /// stats, the pending-update chip, and the view-settings dropdown.
  Widget _buildToolbar(
    BuildContext context, {
    required bool treeVisible,
    required bool splitView,
  }) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final scope = ref.watch(prDiffScopeProvider);
    final commits =
        ref.watch(prCommitsProvider(widget.pr.number)).value ?? const [];
    final filesAsync = ref.watch(prFilesProvider(widget.pr.number));
    final scoped = watchScopedDiffFiles(
      ref,
      scope: scope,
      commits: commits,
      allFiles: filesAsync.value ?? const [],
      isLoading: filesAsync.isLoading,
      error: filesAsync.hasError ? filesAsync.error : null,
    );

    // While the unscoped file list is still streaming in, the PR detail's
    // changed-files count is the better number to show.
    final prDetail = ref.watch(prDetailProvider(widget.pr.number)).value;
    final fileCount =
        !scope.isScoped && (prDetail?.changedFiles ?? 0) > scoped.files.length
        ? prDetail!.changedFiles
        : scoped.files.length;
    final additions = scoped.files.fold<int>(0, (s, f) => s + f.additions);
    final deletions = scoped.files.fold<int>(0, (s, f) => s + f.deletions);

    return Container(
      // Left inset matches the file-tree filter field so the Tree chip
      // lines up with the input directly below it. Right stays at the
      // page inset for the Review action.
      padding: const EdgeInsets.fromLTRB(kPrDiffTreeFilterInset, 8, 24, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderSecondary)),
      ),
      child: Row(
        children: [
          CcTooltip(
            message: l10n.toggleFileTree,
            child: PrTabChip(
              icon: AppIcons.folderTree,
              label: l10n.treeLabel,
              fontSize: 12,
              selected: treeVisible,
              onTap: () {
                final notifier = ref.read(prTreeVisibleProvider.notifier);
                if (treeVisible) {
                  notifier.setVisible(visible: false);
                } else {
                  // Reveal in tree mode (the chip is "Tree"), not whatever mode
                  // a prior ⌘F left the sidebar in.
                  setState(() => _sidebarMode = PrDiffSidebarMode.tree);
                  notifier.setVisible(visible: true);
                }
              },
            ),
          ),
          if (commits.isNotEmpty) ...[
            const SizedBox(width: 8),
            CommitRangeSelector(
              commits: commits,
              selectedShas: scope.selectedShas,
              onSelectionChanged: ref
                  .read(prDiffScopeProvider.notifier)
                  .updateSelection,
              totalCommitsCount: widget.pr.commitsCount,
            ),
          ],
          const SizedBox(width: 16),
          Icon(AppIcons.fileText, size: 14, color: t.textTertiary),
          const SizedBox(width: 6),
          Text(
            l10n.diffFilesCount(fileCount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+$additions',
            style: const TextStyle(
              color: ReviewStatusColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '−$deletions',
            style: const TextStyle(
              color: ReviewStatusColors.failure,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          DiffSettingsButton(
            splitView: splitView,
            onSplitViewChanged: (v) =>
                ref.read(prDiffSplitViewProvider.notifier).setSplit(split: v),
          ),
          if (widget.hasDiffUpdate && widget.onRefreshDiff != null) ...[
            const SizedBox(width: 16),
            DiffUpdateChip(onRefresh: widget.onRefreshDiff!),
          ],
          const Spacer(),
          // Review approve/request-changes flyout — mirrors the one in the
          // Overview tab's action cluster so a reviewer can submit without
          // leaving the diff. Only meaningful on an open PR the viewer didn't
          // author. Pushed to the right edge by the spacer above.
          ..._buildReviewButton(),
        ],
      ),
    );
  }

  /// The Review button + flyout, shown to the right of the diff-view settings.
  /// Empty when the PR is merged/closed or the viewer is its author (a review
  /// would be a self-review) — matching the Overview tab action cluster's gating.
  List<Widget> _buildReviewButton() {
    if (!widget.pr.isOpen) {
      return const [];
    }
    final currentLogin = ref.watch(currentUserLoginProvider);
    final isAuthor =
        currentLogin.isNotEmpty &&
        widget.pr.author?.login.toLowerCase() == currentLogin;
    if (isAuthor) {
      return const [];
    }
    final repo = ref.watch(currentPrRepoProvider);
    return [
      ReviewOverlayButton(
        pr: widget.pr,
        owner: repo?.githubOwner ?? '',
        repo: repo?.githubRepoName ?? '',
      ),
    ];
  }

  Widget _buildFiles(
    BuildContext context, {
    required bool treeVisible,
    required bool splitView,
  }) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final files =
        ref.watch(prFilesProvider(widget.pr.number)).value ?? const [];

    final diffScroll = ColoredBox(
      color: t.bgPrimary,
      child: PrimaryScrollController(
        controller: _scrollController,
        child: CcScrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ReadyAutoScroll(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [_buildFilesSliver(splitView: splitView)],
            ),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Whether the sidebar fits at this width (read by the ⌘F handler to
        // choose sidebar-search vs the floating overlay). Assigned without
        // setState — only the later key event reads it.
        _treeFits = constraints.maxWidth >= _treeBreakpoint && files.isNotEmpty;
        final showTree = treeVisible && _treeFits;
        if (!showTree) {
          return diffScroll;
        }
        final maxTree = (constraints.maxWidth * 0.5).floorToDouble();
        final treeExtent = _treeWidth.clamp(160.0, maxTree);
        return CcResizable(
          axis: Axis.horizontal,
          onResize: (extents) {
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
              initialExtent: treeExtent,
              minExtent: 160,
              maxExtent: maxTree,
              builder: (context) => ColoredBox(
                color: t.bgPrimary,
                child: TreeOverlay(
                  pr: widget.pr,
                  diffKey: _diffKey,
                  mode: _sidebarMode,
                  searchFocusToken: _searchFocusToken,
                  onOpenSearch: _requestSidebarSearch,
                  onShowFileTree: _showFileTree,
                  onOpenFileInEditor:
                      widget.onOpenFileInEditor ?? (_, {int? line}) {},
                ),
              ),
            ),
            CcResizableRegion(
              initialExtent: constraints.maxWidth - treeExtent,
              minExtent: 320,
              builder: (context) => diffScroll,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilesSliver({required bool splitView}) {
    final filesAsync = ref.watch(prFilesProvider(widget.pr.number));
    final commitsAsync = ref.watch(prCommitsProvider(widget.pr.number));
    final reviewCommentsAsync = ref.watch(
      prReviewCommentsProvider(widget.pr.number),
    );
    return FilesTab(
      pr: widget.pr,
      allFiles: filesAsync.value ?? const [],
      commits: commitsAsync.value ?? const [],
      comments: reviewCommentsAsync.value ?? const [],
      isLoading: filesAsync.isLoading,
      error: filesAsync.hasError ? filesAsync.error : null,
      diffKey: _diffKey,
      splitView: splitView,
      onRequestSidebarSearch: _requestSidebarSearch,
      onShowFileTree: _showFileTree,
      onOpenFileInEditor: widget.onOpenFileInEditor,
    );
  }
}
