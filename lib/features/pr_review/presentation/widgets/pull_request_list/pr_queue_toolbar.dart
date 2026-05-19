import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_batch_bar.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final colors = context.theme.colors;
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
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (lane != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  FTappable.static(
                    onPress: () =>
                        ref.read(decisionLaneFilterProvider.notifier).clear(),
                    focusedOutlineStyle:
                        const FFocusedOutlineStyleDelta.context(),
                    child: Text(
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
            FButton(
              onPress: () => confirmAndMergeReadyPrs(context, ref, readyPairs),
              variant: FButtonVariant.primary,
              size: FButtonSizeVariant.sm,
              mainAxisSize: MainAxisSize.min,
              prefix: const Icon(LucideIcons.check, size: 14),
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final labels = {
      PrListSort.recent: l10n.sortRecent,
      PrListSort.oldest: l10n.sortOldest,
      PrListSort.largest: l10n.sortLargest,
    };

    Widget segment(PrListSort s) {
      final selected = s == sort;
      final fg = selected ? tokens.textPrimary : tokens.textTertiary;
      return FTappable.static(
        onPress: () => onChanged(s),
        focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? tokens.bgPrimary : Colors.transparent,
            borderRadius: AppRadii.brSm,
            border: Border.all(
              color: selected ? tokens.borderSecondary : Colors.transparent,
            ),
          ),
          child: Text(
            labels[s]!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(PrListSort.recent),
          segment(PrListSort.oldest),
          segment(PrListSort.largest),
        ],
      ),
    );
  }
}


