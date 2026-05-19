import 'package:control_center/features/pr_review/domain/entities/issue_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/pr_diff_toolbar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_keyboard_hints.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The PR "Files changed" body: a toolbar plus the unified single-canvas diff
/// renderer ([UnifiedDiffView]). Returns slivers for the host
/// [CustomScrollView] in `pull_request_detail_screen.dart`.
class PrDiffView extends ConsumerStatefulWidget {
  /// Creates the PR diff view.
  const PrDiffView({
    super.key,
    required this.files,
    required this.comments,
    this.prNumber = 0,
    this.commits = const [],
    this.selectedCommitShas = const {},
    this.onCommitSelectionChanged,
    this.onToggleViewed,
    this.fetchFileContent,
    this.inlineCommentsController,
    this.issueComments = const [],
    this.hasDiffUpdate = false,
    this.onRefreshDiff,
    this.fullDiff = '',
    this.totalCommitsCount = 0,
  });

  /// Files changed in the PR, in display order.
  final List<PrFile> files;

  /// Server-side review comments.
  final List<PrCodeReviewComment> comments;

  /// PR number (drives the inline-comments controller).
  final int prNumber;

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

  /// Full PR unified diff text — used to recover patches GitHub truncated.
  final String fullDiff;

  /// True total number of commits from the PR detail. Passed to the toolbar's
  /// commit-range selector for the truncation notice.
  final int totalCommitsCount;

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

  @override
  Widget build(BuildContext context) {
    final totalAdditions = widget.files.fold<int>(0, (s, f) => s + f.additions);
    final totalDeletions = widget.files.fold<int>(0, (s, f) => s + f.deletions);
    final inlineCtrl = widget.inlineCommentsController;
    if (inlineCtrl != null) {
      // Refresh the toolbar count when drafts change. The diff body virtualises
      // internally, so a top-level rebuild here stays cheap.
      ref.watch(prInlineCommentsControllerProvider(inlineCtrl.prNumber));
    }
    final localThreads = inlineCtrl == null
        ? const <PrInlineThread>[]
        : inlineCtrl.threads;
    final totalCommentCount =
        widget.comments.length +
        localThreads.length +
        widget.issueComments.length;

    final toolbar = PrDiffToolbar(
      fileCount: widget.files.length,
      additions: totalAdditions,
      deletions: totalDeletions,
      commentCount: totalCommentCount,
      commits: widget.commits,
      selectedCommitShas: widget.selectedCommitShas,
      onCommitSelectionChanged: widget.onCommitSelectionChanged,
      inlineCommentsController: inlineCtrl,
      splitView: _splitView,
      onSplitViewChanged: (v) => setState(() => _splitView = v),
      issueComments: widget.issueComments,
      reviewComments: widget.comments,
      hasDiffUpdate: widget.hasDiffUpdate,
      onRefreshDiff: widget.onRefreshDiff,
      totalCommitsCount: widget.totalCommitsCount,
    );

    if (widget.files.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toolbar,
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.fileQuestion,
                        size: 36,
                        color: context.theme.colors.mutedForeground,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context).noFileChangesInScope,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.theme.colors.mutedForeground,
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
        SliverToBoxAdapter(
          // Horizontal inset matches the diff file headers' 12px content gutter
          // so the toolbar lines up with the file rows below instead of running
          // flush against the file tree (left) and the window edge (right).
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: toolbar,
          ),
        ),
        UnifiedDiffView(
          key: _unifiedKey,
          files: widget.files,
          prNumber: widget.prNumber,
          onToggleViewed: widget.onToggleViewed,
          fetchFileContent: widget.fetchFileContent,
          inlineCommentsController: widget.inlineCommentsController,
          serverComments: widget.comments,
          splitView: _splitView,
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
