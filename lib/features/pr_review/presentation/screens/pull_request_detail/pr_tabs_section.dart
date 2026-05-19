import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_ai_review_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_checks_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_commits_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_files_tab.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab strip content.
class TabStripContent extends ConsumerWidget {
  /// Creates a [TabStripContent].
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

    // Driven by the shared [TabController] so keyboard shortcuts, programmatic
    // tab requests (prChecksUiProvider) and chip taps all stay in sync. The
    // chip row matches the segmented tab convention used on the workspace and
    // ticket detail pages, rather than a Material underline TabBar.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = controller.index;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrTabChip(
              icon: AppIcons.fileText,
              label: l10n.filesChanged,
              count: filesCount,
              selected: selected == 0,
              onTap: () => controller.animateTo(0),
            ),
            const SizedBox(width: 4),
            _PrTabChip(
              icon: AppIcons.gitCommit,
              label: l10n.commits,
              count: commitsCount,
              selected: selected == 1,
              onTap: () => controller.animateTo(1),
            ),
            const SizedBox(width: 4),
            _PrTabChip(
              icon: AppIcons.zap,
              label: l10n.actions,
              count: workflowCount,
              selected: selected == 2,
              onTap: () => controller.animateTo(2),
            ),
            const SizedBox(width: 4),
            _PrTabChip(
              icon: AppIcons.sparkles,
              label: l10n.aiReview,
              selected: selected == 3,
              onTap: () => controller.animateTo(3),
            ),
          ],
        );
      },
    );
  }
}

/// A single segmented tab chip. Selected chips get a filled rounded
/// background; the rest are transparent. Mirrors the tab style used on the
/// workspace and ticket detail pages.
class _PrTabChip extends StatelessWidget {
  const _PrTabChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = selected ? t.textPrimary : t.textTertiary;
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? t.bgSecondary : Colors.transparent,
          borderRadius: AppRadii.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              CountBadge(count: count!, selected: selected),
            ],
          ],
        ),
      ),
    );
  }
}

/// Active tab body.
class ActiveTabBody extends ConsumerWidget {
  /// Creates an [ActiveTabBody].
  const ActiveTabBody({
    super.key,
    required this.tabIndex,
    required this.pr,
    required this.diffKey,
    this.hasDiffUpdate = false,
    this.onRefreshDiff,
  });

  /// The active tab index.
  final int tabIndex;

  /// The pull request.
  final PullRequest pr;

  /// Key for the diff view widget.
  final GlobalKey<PrDiffViewState> diffKey;

  /// Whether there is a pending diff update.
  final bool hasDiffUpdate;

  /// Callback to refresh the diff.
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
  /// Creates a [CountBadge].
  const CountBadge({super.key, required this.count, this.selected = false});

  /// Number to display in the badge.
  final int count;

  /// Whether the parent tab chip is selected — drives the badge fill so the
  /// count stays legible against the selected chip's secondary background.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? t.bgPrimary : t.bgSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: selected ? t.textPrimary : t.textTertiary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
