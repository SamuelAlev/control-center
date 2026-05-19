import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-vendor sync health (§188): last-sync time, consecutive-failure streak,
/// and the latest attempt's outcome — so a failing connection is visible
/// without log spelunking. Read-only; reflects the server's append-only sync
/// log streamed over RPC. Renders nothing until a workspace is active.
class SyncHealthCard extends ConsumerWidget {
  /// Creates a [SyncHealthCard].
  const SyncHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final configs =
        ref.watch(workspaceSyncConfigsProvider(workspaceId)).asData?.value ??
        const <TicketSyncConfig>[];
    final logs =
        ref.watch(workspaceSyncLogsProvider(workspaceId)).asData?.value ??
        const <TicketSyncLogEntry>[];

    return SectionCard(
      label: l10n.syncHealthTitle,
      child: configs.isEmpty
          ? Text(
              l10n.syncHealthNoConfigs,
              style: TextStyle(color: tokens.textTertiary, fontSize: 13),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: _SyncNowButton(),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < configs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _VendorHealthRow(
                    config: configs[i],
                    // Logs arrive newest-first; keep only this vendor's.
                    vendorLogs: logs
                        .where((e) => e.vendor == configs[i].vendor)
                        .toList(),
                  ),
                ],
              ],
            ),
    );
  }
}

class _VendorHealthRow extends StatelessWidget {
  const _VendorHealthRow({required this.config, required this.vendorLogs});

  final TicketSyncConfig config;
  final List<TicketSyncLogEntry> vendorLogs;

  /// Count of consecutive `failed` outcomes from the newest entry — the current
  /// failure streak (0 when the latest attempt was not a failure).
  int get _failedStreak {
    var n = 0;
    for (final e in vendorLogs) {
      if (e.outcome == SyncOutcome.failed) {
        n++;
      } else {
        break;
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final latest = vendorLogs.isEmpty ? null : vendorLogs.first;
    final streak = _failedStreak;

    final (icon, color, statusLabel) = switch (latest?.outcome) {
      null => (AppIcons.clock, tokens.textTertiary, l10n.syncHealthNeverSynced),
      SyncOutcome.ok => (
        AppIcons.checkCircle,
        tokens.fgSuccessSecondary,
        l10n.syncOutcomeOk,
      ),
      SyncOutcome.failed => (
        AppIcons.circleAlert,
        tokens.textErrorPrimary,
        l10n.syncOutcomeFailed,
      ),
      _ => (
        AppIcons.circleDashed,
        tokens.textTertiary,
        l10n.syncOutcomeSkipped,
      ),
    };

    final meta = <String>[
      config.enabled ? l10n.enabled : l10n.disabled,
      statusLabel,
      if (latest != null) formatRelativeTime(context, latest.createdAt),
      if (streak > 1) l10n.syncHealthFailedStreak(streak),
    ].join('  ·  ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vendorName(config.vendor),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              if (latest != null)
                AppTimestamp(
                  dateTime: latest.createdAt,
                  child: Text(
                    meta,
                    style: TextStyle(color: tokens.textTertiary, fontSize: 12),
                  ),
                )
              else
                Text(
                  meta,
                  style: TextStyle(color: tokens.textTertiary, fontSize: 12),
                ),
              if (streak > 0 && latest?.message != null) ...[
                const SizedBox(height: 2),
                Text(
                  latest!.message!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textErrorPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// A display name for a vendor id ('linear' → 'Linear').
  static String _vendorName(String vendor) => switch (vendor) {
    'github' => 'GitHub',
    'clickup' => 'ClickUp',
    _ =>
      vendor.isEmpty ? vendor : vendor[0].toUpperCase() + vendor.substring(1),
  };
}

/// "Sync now" (§188): manually triggers a vendor pull for the active workspace
/// via `ticketSyncNowProvider`, showing a toast with the result. Own loading
/// state so the button disables + spins mid-run.
class _SyncNowButton extends ConsumerStatefulWidget {
  const _SyncNowButton();

  @override
  ConsumerState<_SyncNowButton> createState() => _SyncNowButtonState();
}

class _SyncNowButtonState extends ConsumerState<_SyncNowButton> {
  bool _syncing = false;

  Future<void> _run() async {
    if (_syncing) {
      return;
    }
    setState(() => _syncing = true);
    final l10n = AppLocalizations.of(context);
    final messenger = CcToastScope.of(context);
    try {
      final r = await ref.read(ticketSyncNowProvider)();
      if (!mounted) {
        return;
      }
      messenger.show(l10n.syncNowResult(r.created + r.updated, r.failed));
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      messenger.show(l10n.syncNowFailed('$e'));
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcButton(
      onPressed: _run,
      variant: CcButtonVariant.secondary,
      size: CcButtonSize.sm,
      icon: AppIcons.rotateCw,
      loading: _syncing,
      child: Text(l10n.syncNow),
    );
  }
}
