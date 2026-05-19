import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/offline/offline_queue_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "N pending changes" pill (PRD 19 §11): visible only while mutations
/// are queued, so the operator always knows whether their edits have synced.
/// The offline *status* itself is deliberately not shown here — the top-bar
/// connection pill already reports it — so this collapses to nothing whenever
/// the queue is empty.
class OfflinePendingPill extends ConsumerWidget {
  /// Creates an [OfflinePendingPill].
  const OfflinePendingPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(isOnlineProvider);
    final pending = ref.watch(offlineQueueControllerProvider);

    if (pending == 0) {
      return const SizedBox.shrink();
    }

    // Offline → caution (work isn't syncing yet); online → neutral (it's
    // flushing). Icon + label, never colour alone (AAA).
    final tone = online ? CcStatusTone.neutral : CcStatusTone.caution;
    final label = online
        ? '$pending ${l10n.offlineSyncingLabel}'
        : '$pending ${l10n.offlinePendingLabel}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online ? AppIcons.refreshCw : AppIcons.clock,
            size: 13,
            color: tone == CcStatusTone.caution ? ds.warn : ds.textTertiary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: ds.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
