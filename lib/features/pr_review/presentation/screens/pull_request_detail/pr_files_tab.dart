import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_diff_scope_notifier.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/utils/scoped_diff_files.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_clone_progress_card.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Files tab.
class FilesTab extends ConsumerWidget {
  /// Creates a [FilesTab].
  const FilesTab({
    super.key,
    required this.pr,
    required this.allFiles,
    required this.commits,
    required this.comments,
    required this.isLoading,
    required this.error,
    required this.diffKey,
    this.splitView = false,
    this.onRequestSidebarSearch,
    this.onShowFileTree,
    this.onOpenFileInEditor,
  });

  /// The pull request.
  final PullRequest pr;

  /// All files changed in the PR.
  final List<PrFile> allFiles;

  /// All commits in the PR.
  final List<PrCommit> commits;

  /// All review comments.
  final List<PrCodeReviewComment> comments;

  /// Whether data is still loading.
  final bool isLoading;

  /// Load error, if any.
  final Object? error;

  /// Key for the diff view widget.
  final GlobalKey<PrDiffViewState> diffKey;

  /// Whether split (side-by-side) view is active.
  final bool splitView;

  /// ⌘F → open the sidebar's "search in files" mode (returns true when handled;
  /// false falls back to the floating in-diff search).
  final bool Function()? onRequestSidebarSearch;

  /// `t` → switch the sidebar back to the file tree.
  final VoidCallback? onShowFileTree;

  /// Opens a file (repo-relative path) in an editable tab (the file header's
  /// "open in editor" action).
  final ValueChanged<String>? onOpenFileInEditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(prDiffScopeProvider);
    final scoped = scope.isScoped;

    // Watch the full load state for clone-progress reporting.
    final filesLoad = ref.watch(prFilesLoadProvider(pr.number));
    final clonePhase = filesLoad.value?.clonePhase;
    final cloneMessage = filesLoad.value?.cloneMessage ?? '';

    final scopedResult = watchScopedDiffFiles(
      ref,
      scope: scope,
      commits: commits,
      allFiles: allFiles,
      isLoading: isLoading,
      error: error,
    );

    final files = sortFilesByTreeOrder(scopedResult.files);
    final effectiveLoading = scopedResult.isLoading;
    final effectiveError = scopedResult.error;

    // Show clone-progress card while the local-git pipeline is running
    // and we don't have files yet.
    if (!scoped &&
        clonePhase != null &&
        clonePhase != ClonePhase.ready &&
        clonePhase != ClonePhase.error &&
        files.isEmpty) {
      return SliverToBoxAdapter(
        child: PrCloneProgressCard(
          phase: clonePhase,
          message: cloneMessage,
          fileCount: pr.changedFiles,
        ),
      );
    }

    if (clonePhase == ClonePhase.error && files.isEmpty) {
      return SliverToBoxAdapter(
        child: SectionError(
          error: filesLoad.error ?? filesLoad.value?.error ?? 'Clone failed',
        ),
      );
    }

    if (effectiveLoading && files.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: PrDiffSkeleton(),
        ),
      );
    }
    if (effectiveError != null && files.isEmpty) {
      return SliverToBoxAdapter(child: SectionError(error: effectiveError));
    }

    // Read directly from the repository stream rather than going through
    // `prFileContentProvider(...).future`. The Riverpod StreamProvider's
    // `.future` getter races with the SWR cache yield — when the cached
    // value is yielded before the internal listener attaches, `.future`
    // never sees it and hangs forever. `.first` on the stream is reliable.
    final repo = ref.read(prReviewRepositoryProvider);
    final fetcher = pr.headSha.isEmpty
        ? null
        : (String path) => repo
              .watchFileContent(path, pr.headSha)
              .first
              .timeout(const Duration(seconds: 15));
    final inlineCommentsController = ref.read(
      prInlineCommentsControllerProvider(pr.number).notifier,
    );
    final issueCommentsAsync = ref.watch(prIssueCommentsProvider(pr.number));
    final issueComments = issueCommentsAsync.value ?? const [];

    // Capture the scope notifier here so the callbacks below don't close
    // over `ref`. The diff view stashes [onToggleViewed] in its State and
    // may invoke it after this element has been deactivated (e.g. when the
    // keyboard handler fires during a tab/route transition), and `ref.read`
    // from an unmounted element throws.
    final scopeNotifier = ref.read(prDiffScopeProvider.notifier);

    return PrDiffView(
      key: diffKey,
      files: files,
      comments: comments,
      prNumber: pr.number,
      commits: commits,
      selectedCommitShas: scope.selectedShas,
      onCommitSelectionChanged: scopeNotifier.updateSelection,
      fetchFileContent: fetcher,
      inlineCommentsController: inlineCommentsController,
      issueComments: issueComments,
      showToolbar: false,
      splitView: splitView,
      totalCommitsCount: pr.commitsCount,
      onRequestSidebarSearch: onRequestSidebarSearch,
      onShowFileTree: onShowFileTree,
      onOpenFileInEditor: onOpenFileInEditor,
      onToggleViewed: ({required path, required viewed}) {
        if (pr.nodeId.isEmpty) {
          return;
        }

        repo.markFileAsViewed(
          prNumber: pr.number,
          nodeId: pr.nodeId,
          path: path,
          viewed: viewed,
        );
      },
    );
  }
}

/// Section error.
class SectionError extends StatelessWidget {
  /// Creates a [SectionError].
  const SectionError({super.key, required this.error});

  /// The error to display.
  final Object error;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.triangleAlert,
            size: 32,
            color: tokens.textErrorPrimary,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).failedToLoad,
            style: CcTypography.body.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
        ],
      ),
    );
  }
}
