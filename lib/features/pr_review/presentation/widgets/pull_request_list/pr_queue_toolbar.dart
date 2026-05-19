import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_batch_bar.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The queue panel's toolbar: the active scope (lane name or "all"), a reset to
/// show everything, a "Merge N ready" shortcut, and the sort segment.
/// Mirrors the mock's panel header.
class PrQueueToolbar extends ConsumerWidget {
  /// Creates a [PrQueueToolbar].
  const PrQueueToolbar({
    super.key,
    required this.totalCount,
    required this.readyPairs,
  });

  /// Total PR count across the (filter-respecting) queue, for the "show all"
  /// reset label.
  final int totalCount;

  /// The PRs currently in the ready lane, for the "Merge N ready" shortcut.
  final List<PrRepoPair> readyPairs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final lane = ref.watch(decisionLaneFilterProvider);
    final sort = ref.watch(prListSortProvider);

    final scopeLabel = lane == null
        ? l10n.allOpenPrs
        : decisionLaneStyle(lane, tokens, l10n).label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    scopeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (lane != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  CcTappable(
                    onPressed: () =>
                        ref.read(decisionLaneFilterProvider.notifier).clear(),
                    builder: (context, states) => Text(
                      l10n.showAllCount(totalCount),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tokens.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (readyPairs.isNotEmpty) ...[
            CcButton(
              onPressed: () => confirmAndMergeReadyPrs(context, ref, readyPairs),
              variant: CcButtonVariant.primary,
              size: CcButtonSize.sm,
              icon: AppIcons.check,
              child: Text(l10n.mergeCountReady(readyPairs.length)),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          _SortSegment(
            sort: sort,
            onChanged: (s) => ref.read(prListSortProvider.notifier).set(s),
          ),
        ],
      ),
    );
  }
}

class _SortSegment extends StatelessWidget {
  const _SortSegment({required this.sort, required this.onChanged});

  final PrListSort sort;
  final ValueChanged<PrListSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedToggle<PrListSort>(
      value: sort,
      onChanged: onChanged,
      segments: [
        (value: PrListSort.recent, label: l10n.sortRecent),
        (value: PrListSort.oldest, label: l10n.sortOldest),
        (value: PrListSort.largest, label: l10n.sortLargest),
      ],
    );
  }
}
