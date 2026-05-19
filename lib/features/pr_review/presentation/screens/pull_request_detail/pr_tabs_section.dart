import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_ai_review_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_checks_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_commits_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_files_tab.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tab strip content.
class TabStripContent extends ConsumerWidget {
  /// TabStripContent({.
  const TabStripContent({
    super.key,
    required this.controller,
    required this.prNumber,
  });

  /// TabController.
  final TabController controller;

  /// Pull request number for data lookups.
  final int prNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Use the true totals from the PR detail when available; fall back to the
    // loaded counts so the badges are never zero while data is still loading.
    // This matters for large PRs whose local clone takes minutes — the files
    // list stays empty during the clone but GitHub already reported the total.
    final prDetail = ref.watch(prDetailProvider(prNumber)).value;
    final loadedFilesCount =
        ref.watch(prFilesProvider(prNumber)).value?.length ?? 0;
    final filesCount = (prDetail?.changedFiles ?? 0) > loadedFilesCount
        ? prDetail!.changedFiles
        : loadedFilesCount;
    final loadedCommitsCount =
        ref.watch(prCommitsProvider(prNumber)).value?.length ?? 0;
    final commitsCount = (prDetail?.commitsCount ?? 0) > 0
        ? prDetail!.commitsCount
        : loadedCommitsCount;
    final checks = ref.watch(prCheckRunsProvider(prNumber)).value ?? const [];
    final workflowCount = groupChecksByWorkflow(checks).length;

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      indicatorColor: context.theme.colors.primary,
      labelColor: context.theme.colors.foreground,
      unselectedLabelColor: context.theme.colors.mutedForeground,
      tabs: [
        Tab(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.fileText, size: 14),
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
              const Icon(LucideIcons.gitCommit, size: 14),
              const SizedBox(width: 6),
              Text(l10n.commits),
              const SizedBox(width: 6),
              CountBadge(count: commitsCount),
            ],
          ),
        ),
        Tab(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.zap, size: 14),
              const SizedBox(width: 6),
              Text(l10n.actions),
              const SizedBox(width: 6),
              CountBadge(count: workflowCount),
            ],
          ),
        ),
        Tab(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.sparkles, size: 14),
              const SizedBox(width: 6),
              Text(l10n.aiReview),
            ],
          ),
        ),
      ],
    );
  }
}

/// Active tab body.
class ActiveTabBody extends ConsumerWidget {
  const ActiveTabBody({
    super.key,
    required this.tabIndex,
    required this.pr,
    required this.diffKey,
    this.hasDiffUpdate = false,
    this.onRefreshDiff,
  });

  final int tabIndex;
  final PullRequest pr;
  final GlobalKey<PrDiffViewState> diffKey;
  final bool hasDiffUpdate;
  final VoidCallback? onRefreshDiff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ActiveTabBody is consumed by the parent's `CustomScrollView` as a sliver
    // so the Files tab can virtualise its file list directly against the outer
    // viewport. Tabs that don't need virtualisation are wrapped in
    // [SliverToBoxAdapter].
    switch (tabIndex) {
      case 0:
        final filesAsync = ref.watch(prFilesProvider(pr.number));
        final commitsAsync = ref.watch(prCommitsProvider(pr.number));
        final reviewCommentsAsync = ref.watch(
          prReviewCommentsProvider(pr.number),
        );
        return FilesTab(
          pr: pr,
          allFiles: filesAsync.value ?? const [],
          commits: commitsAsync.value ?? const [],
          comments: reviewCommentsAsync.value ?? const [],
          isLoading: filesAsync.isLoading,
          error: filesAsync.hasError ? filesAsync.error : null,
          diffKey: diffKey,
          hasDiffUpdate: hasDiffUpdate,
          onRefreshDiff: onRefreshDiff,
        );
      case 1:
        final commitsAsync = ref.watch(prCommitsProvider(pr.number));
        return SliverToBoxAdapter(
          child: CommitsTab(
            commits: commitsAsync.value ?? const [],
            isLoading: commitsAsync.isLoading,
            error: commitsAsync.hasError ? commitsAsync.error : null,
            totalCommitsCount: pr.commitsCount,
          ),
        );
      case 2:
        final checksAsync = ref.watch(prCheckRunsProvider(pr.number));
        return SliverToBoxAdapter(
          child: ChecksTab(
            checks: checksAsync.value ?? const [],
            isLoading: checksAsync.isLoading,
            error: checksAsync.hasError ? checksAsync.error : null,
          ),
        );
      case 3:
        return SliverToBoxAdapter(child: PrAiReviewTab(pr: pr));
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }
}

/// Count badge.
class CountBadge extends StatelessWidget {
  /// CountBadge({super.key,.
  const CountBadge({super.key, required this.count});

  /// Number to display in the badge.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.theme.colors.mutedForeground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
