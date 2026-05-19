import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_diff_scope_notifier.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_clone_progress_card.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Files tab.
class FilesTab extends ConsumerWidget {
  const FilesTab({
    super.key,
    required this.pr,
    required this.allFiles,
    required this.commits,
    required this.comments,
    required this.isLoading,
    required this.error,
    required this.diffKey,
    this.hasDiffUpdate = false,
    this.onRefreshDiff,
  });

  final PullRequest pr;
  final List<PrFile> allFiles;
  final List<PrCommit> commits;
  final List<PrCodeReviewComment> comments;
  final bool isLoading;
  final Object? error;
  final GlobalKey<PrDiffViewState> diffKey;
  final bool hasDiffUpdate;
  final VoidCallback? onRefreshDiff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(prDiffScopeProvider);
    final scoped = scope.isScoped;

    // Watch the full load state for clone-progress reporting.
    final filesLoad = ref.watch(prFilesLoadProvider(pr.number));
    final clonePhase = filesLoad.value?.clonePhase;
    final cloneMessage = filesLoad.value?.cloneMessage ?? '';

    var scopedFiles = const <PrFile>[];
    var scopeLoading = false;
    Object? scopeError;

    if (scoped) {
      final byPath = <String, PrFile>{};
      for (final commit in commits) {
        if (!scope.selectedShas.contains(commit.sha)) {
          continue;
        }

        final async = ref.watch(prCommitFilesProvider(commit.sha));
        if (async.isLoading) {
          scopeLoading = true;
        }

        if (async.hasError && scopeError == null) {
          scopeError = async.error;
        }

        for (final f in async.value ?? const <PrFile>[]) {
          byPath[f.filename] = f;
        }
      }
      scopedFiles = byPath.values.toList();
    }

    final files = sortFilesByTreeOrder(scoped ? scopedFiles : allFiles);
    final effectiveLoading = scoped ? scopeLoading : isLoading;
    final effectiveError = scoped ? scopeError : error;

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
          error: filesLoad.error ??
              filesLoad.value?.error ??
              'Clone failed',
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

    // Full PR diff text (cached by SWR). Used to extract patches for files
    // whose per-file patch was truncated by GitHub.
    final diffAsync = ref.watch(prDiffProvider(pr.number));
    final fullDiff = diffAsync.value ?? '';

    return PrDiffView(
      key: diffKey,
      files: files,
      comments: comments,
      prNumber: pr.number,
      commits: commits,
      selectedCommitShas: scope.selectedShas,
      onCommitSelectionChanged: scopeNotifier.updateSelection,
      fetchFileContent: fetcher,
      fullDiff: fullDiff,
      inlineCommentsController: inlineCommentsController,
      issueComments: issueComments,
      hasDiffUpdate: hasDiffUpdate,
      onRefreshDiff: onRefreshDiff,
      totalCommitsCount: pr.commitsCount,
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
  /// SectionError({super.key,.
  const SectionError({super.key, required this.error});

  /// Object.
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 32,
            color: context.theme.colors.destructive,
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).failedToLoad, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
