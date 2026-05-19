import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_merge_button.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A pull request paired with its owning repo, for batch resolution.
typedef PrRepoPair = ({PullRequest pr, Repo repo});

/// Confirms, then squash-merges every PR in [ready], skipping any that error,
/// and reports the outcome. Shared by the batch bar and the toolbar's
/// "Merge N ready" button so both go through the same confirmation + refresh.
Future<void> confirmAndMergeReadyPrs(
  BuildContext context,
  WidgetRef ref,
  List<PrRepoPair> ready,
) async {
  if (ready.isEmpty) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  final toaster = CcToastScope.of(context);
  final confirmed = await showCcDialog<bool>(
    context: context,
    builder: (ctx) => CcDialog(
      title: l10n.mergeReadyConfirmTitle,
      content: Text(l10n.mergeReadyConfirmBody(ready.length)),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          variant: CcButtonVariant.primary,
          child: Text(l10n.merge),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }

  var merged = 0;
  final mergedNumbers = <int>[];
  for (final pair in ready) {
    try {
      await performPrMerge(
        ref,
        pair.repo,
        prNumber: pair.pr.number,
        method: PrMergeMethod.squash,
        commitTitle: pair.pr.title,
        commitMessage: pair.pr.body,
      );
      merged++;
      mergedNumbers.add(pair.pr.number);
    } on Exception {
      // Skip the failing PR; surface the partial result below.
    }
  }
  ref.read(prSelectionProvider.notifier).removeAll(mergedNumbers);
  ref.invalidate(prsByRepoProvider);
  toaster.show(l10n.mergedCountPrs(merged), variant: CcToastVariant.success);
}

/// The floating batch action bar shown while PRs are selected. It reports the
/// selection count and offers a single safe batch action — merging the selected
/// PRs that are actually ready — behind a confirmation, plus a clear button.
class PrBatchBar extends ConsumerWidget {
  /// Creates a [PrBatchBar].
  const PrBatchBar({super.key, required this.allPrs});

  /// Every PR currently known to the queue, paired with its repo, so selected
  /// numbers can be resolved back to entities for classification + merge.
  final List<PrRepoPair> allPrs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(prSelectionProvider);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserLoginProvider);

    final selectedPairs = allPrs
        .where((p) => selection.contains(p.pr.number))
        .toList();
    final readyPairs = selectedPairs.where((p) {
      final awaitingMe =
          me.isNotEmpty &&
          p.pr.requestedReviewers.any((r) => r.login.toLowerCase() == me);
      return classifyDecisionLanes(
        p.pr,
        awaitingMe: awaitingMe,
      ).contains(DecisionLane.ready);
    }).toList();

    final visible = selection.selected.isNotEmpty;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.4),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: IgnorePointer(
          ignoring: !visible,
          child: Container(
            decoration: BoxDecoration(
              // A solid dark surface in both themes (fg inverts to near-white in
              // dark mode, which made the bar white-on-white).
              color: tokens.bgPrimarySolid,
              borderRadius: AppRadii.brMd,
              boxShadow: AppShadows.golden,
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.countSelected(selection.selected.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textWhite,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 1,
                  height: 20,
                  color: tokens.fgWhite.withAlpha(40),
                ),
                const SizedBox(width: AppSpacing.sm),
                CcButton(
                  onPressed: readyPairs.isEmpty
                      ? null
                      : () => confirmAndMergeReadyPrs(context, ref, readyPairs),
                  variant: CcButtonVariant.primary,
                  size: CcButtonSize.sm,
                  icon: LucideIcons.gitMerge,
                  child: Text(l10n.mergeReadyAction),
                ),
                const SizedBox(width: AppSpacing.xs),
                _DarkBarButton(
                  icon: LucideIcons.x,
                  onTap: () => ref.read(prSelectionProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkBarButton extends StatelessWidget {
  const _DarkBarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: tokens.fgWhite),
      ),
    );
  }
}
