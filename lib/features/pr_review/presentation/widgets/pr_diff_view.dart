import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/pr_diff_toolbar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_keyboard_hints.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR "Files changed" body: a toolbar plus the unified single-canvas diff
/// renderer ([UnifiedDiffView]). Returns slivers for the host
/// [CustomScrollView] in `pull_request_detail_screen.dart`.
class PrDiffView extends ConsumerStatefulWidget {
  /// Creates the PR diff view.
  const PrDiffView({
    super.key,
    required this.files,
    required this.comments,
    this.commits = const [],
    this.selectedCommitShas = const {},
    this.onCommitSelectionChanged,
    this.onToggleViewed,
    this.fetchFileContent,
    this.inlineCommentsController,
    this.issueComments = const [],
    this.hasDiffUpdate = false,
    this.onRefreshDiff,
    this.totalCommitsCount = 0,
    this.showToolbar = true,
    this.splitView,
    this.onRequestSidebarSearch,
    this.onShowFileTree,
    this.onOpenFileInEditor,
  });

  /// Files changed in the PR, in display order.
  final List<PrFile> files;

  /// Server-side review comments.
  final List<PrCodeReviewComment> comments;


  /// Commits in the PR (for the toolbar's commit-range selector).
  final List<PrCommit> commits;

  /// Currently selected commit SHAs for diff scoping.
  final Set<String> selectedCommitShas;

  /// Called when the toolbar's commit selection changes.
  final void Function(Set<String> shas)? onCommitSelectionChanged;

  /// Called when a file's "viewed" toggle flips.
  final void Function({required String path, required bool viewed})?
  onToggleViewed;

  /// Fetches full file content for gap expansion / truncated patches.
  final Future<String> Function(String path)? fetchFileContent;

  /// Controller for inline (draft) comments.
  final PrInlineCommentsController? inlineCommentsController;

  /// Conversation-timeline issue comments (for the toolbar count).
  final List<IssueComment> issueComments;

  /// Whether a newer diff is available on the server.
  final bool hasDiffUpdate;

  /// Called when the user asks to refresh a stale diff.
  final VoidCallback? onRefreshDiff;

  /// True total number of commits from the PR detail. Passed to the toolbar's
  /// commit-range selector for the truncation notice.
  final int totalCommitsCount;

  /// Whether to render the built-in stats/commits/view-mode toolbar above the
  /// diff. The PR detail page hosts those controls in its own merged toolbar
  /// and turns this off; other surfaces keep the default.
  final bool showToolbar;

  /// External split (side-by-side) view state. When non-null it drives the
  /// renderer directly (the host owns the toggle); when null the internal
  /// toolbar toggle owns it.
  final bool? splitView;

  /// ⌘F handler that opens the host sidebar's "search in files" mode instead of
  /// the floating in-diff overlay. Returns true when handled (see
  /// [UnifiedDiffView.onRequestSidebarSearch]). Null → always floating overlay.
  final bool Function()? onRequestSidebarSearch;

  /// Switches the host sidebar back to the file tree (the `t` key).
  final VoidCallback? onShowFileTree;

  /// Opens a file (repo-relative path) in an editable tab — wires the file
  /// header's "open in editor" action.
  final ValueChanged<String>? onOpenFileInEditor;

  @override
  ConsumerState<PrDiffView> createState() => PrDiffViewState();
}

/// State for [PrDiffView]; exposes [jumpToFile] for the file-tree navigator.
class PrDiffViewState extends ConsumerState<PrDiffView> {
  final GlobalKey<UnifiedDiffViewState> _unifiedKey =
      GlobalKey<UnifiedDiffViewState>();

  bool _splitView = false;

  /// Scrolls the diff so file [index] sits at the top.
  Future<void> jumpToFile(int index) async {
    await _unifiedKey.currentState?.jumpToFile(index);
  }

  /// Opens [threadId], focuses it and scrolls it into view — the comment
  /// permalink entry point.
  Future<void> revealThread(
    String threadId, {
    required int fileIndex,
    required int displayLine,
  }) async {
    await _unifiedKey.currentState?.revealThread(
      threadId,
      fileIndex: fileIndex,
      displayLine: displayLine,
    );
  }

  /// The index of [path] in the diff's file list, or -1 when the file is not
  /// in the current scope (a commit-range view, or an active filter).
  int filesIndexOf(String path) =>
      widget.files.indexWhere((f) => f.filename == path);

  Color _mutedColor(BuildContext context) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    return tokens.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    final totalAdditions = widget.files.fold<int>(0, (s, f) => s + f.additions);
    final totalDeletions = widget.files.fold<int>(0, (s, f) => s + f.deletions);
    final inlineCtrl = widget.inlineCommentsController;
    if (inlineCtrl != null) {
      // Refresh the toolbar count when drafts change. The diff body virtualises
      // internally, so a top-level rebuild here stays cheap.
      // The controller carries its own (repo, number) identity — keying off
      // it (rather than a bare number param) is what keeps the watch bound to
      // the PR's own repo.
      ref.watch(prInlineCommentsControllerProvider(inlineCtrl.pr));
    }
    final localThreads = inlineCtrl == null
        ? const <PrInlineThread>[]
        : inlineCtrl.threads;
    final totalCommentCount =
        widget.comments.length +
        localThreads.length +
        widget.issueComments.length;
    final splitView = widget.splitView ?? _splitView;

    final toolbar = widget.showToolbar
        ? PrDiffToolbar(
            fileCount: widget.files.length,
            additions: totalAdditions,
            deletions: totalDeletions,
            commentCount: totalCommentCount,
            commits: widget.commits,
            selectedCommitShas: widget.selectedCommitShas,
            onCommitSelectionChanged: widget.onCommitSelectionChanged,
            inlineCommentsController: inlineCtrl,
            splitView: splitView,
            onSplitViewChanged: (v) => setState(() => _splitView = v),
            issueComments: widget.issueComments,
            reviewComments: widget.comments,
            hasDiffUpdate: widget.hasDiffUpdate,
            onRefreshDiff: widget.onRefreshDiff,
            totalCommitsCount: widget.totalCommitsCount,
          )
        : null;

    if (widget.files.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (toolbar != null) ...[toolbar, const SizedBox(height: 16)],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.fileQuestion,
                        size: 36,
                        color: _mutedColor(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context).noFileChangesInScope,
                        style: CcTypography.body.copyWith(
                          color: _mutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        if (toolbar != null)
          SliverToBoxAdapter(
            // Horizontal inset matches the diff file headers' 12px content
            // gutter so the toolbar lines up with the file rows below instead
            // of running flush against the file tree (left) and the window
            // edge (right).
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: toolbar,
            ),
          ),
        UnifiedDiffView(
          key: _unifiedKey,
          files: widget.files,
          onToggleViewed: widget.onToggleViewed,
          fetchFileContent: widget.fetchFileContent,
          inlineCommentsController: widget.inlineCommentsController,
          serverComments: widget.comments,
          splitView: splitView,
          flushTop: !widget.showToolbar,
          onRequestSidebarSearch: widget.onRequestSidebarSearch,
          onShowFileTree: widget.onShowFileTree,
          onOpenFileInEditor: widget.onOpenFileInEditor,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 32),
            child: PrKeyboardHints.diff(AppLocalizations.of(context)),
          ),
        ),
      ],
    );
  }
}
