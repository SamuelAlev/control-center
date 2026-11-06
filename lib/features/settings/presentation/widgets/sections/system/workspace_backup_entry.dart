import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The local date and time of [backup], in the active locale.
String workspaceBackupLabel(BuildContext context, BackupSnapshotView backup) {
  final createdAt = backup.createdAt;
  return createdAt == null
      ? backup.name
      : DateFormat.yMMMd(
          Localizations.localeOf(context).toString(),
        ).add_Hm().format(createdAt.toLocal());
}

/// One restore point. The absolute time leads, because choosing which backup to
/// go back to is a question about a date.
class WorkspaceBackupEntry extends StatefulWidget {
  /// Creates a [WorkspaceBackupEntry].
  const WorkspaceBackupEntry({
    super.key,
    required this.backup,
    required this.canRestore,
    required this.canDownload,
    required this.restoring,
    required this.deleting,
    required this.downloading,
    required this.progress,
    required this.onRestore,
    required this.onDownload,
    required this.onDelete,
  });

  /// The backup this row offers.
  final BackupSnapshotView backup;

  /// Whether Restore shows. A deleted workspace has nothing to restore into.
  final bool canRestore;

  /// Whether Download is enabled.
  final bool canDownload;

  /// Whether a restore of this backup is running.
  final bool restoring;

  /// Whether this backup is being deleted.
  final bool deleting;

  /// Whether this backup is downloading.
  final bool downloading;

  /// How far the download has got.
  final ({int transferred, int? total})? progress;

  /// Fired by Restore.
  final Future<void> Function(BackupSnapshotWorkspaceView) onRestore;

  /// Fired by Download.
  final Future<void> Function(BackupSnapshotView) onDownload;

  /// Fired by Delete.
  final Future<void> Function(BackupSnapshotView) onDelete;

  @override
  State<WorkspaceBackupEntry> createState() => _WorkspaceBackupEntryState();
}

class _WorkspaceBackupEntryState extends State<WorkspaceBackupEntry> {
  bool _hovered = false;

  Future<void> _copyPath(String path) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: path));
    if (mounted) {
      CcToastScope.maybeOf(
        context,
      )?.show(l10n.copied, variant: CcToastVariant.success);
    }
  }

  Widget _details(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final backup = widget.backup;
    final createdAt = backup.createdAt;
    final label = Text(
      workspaceBackupLabel(context, backup),
      style: CcTypography.bodySm.copyWith(color: tokens.textPrimary),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (createdAt == null)
          label
        else
          AppTimestamp(dateTime: createdAt, child: label),
        Text(
          backup.complete
              ? humanBytes(backup.bytes)
              : l10n.backupSnapshotIncomplete,
          style: CcTypography.caption.copyWith(
            color: backup.complete
                ? tokens.textTertiary
                : tokens.textWarningPrimary,
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final backup = widget.backup;
    final entry = backup.workspaces.firstOrNull;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsHoverReveal(
          active: _hovered,
          child: CcIconButton(
            icon: AppIcons.trash2,
            size: CcButtonSize.sm,
            tooltip: l10n.delete,
            semanticLabel: l10n.delete,
            loading: widget.deleting,
            onPressed: widget.deleting ? null : () => widget.onDelete(backup),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CcIconButton(
          icon: AppIcons.copy,
          size: CcButtonSize.sm,
          tooltip: l10n.copyPath,
          semanticLabel: l10n.copyPath,
          onPressed: () => _copyPath(entry?.path ?? backup.path),
        ),
        const SizedBox(width: AppSpacing.xs),
        CcIconButton(
          icon: AppIcons.download,
          size: CcButtonSize.sm,
          tooltip: l10n.backupDownloadAction,
          semanticLabel: l10n.backupDownloadAction,
          loading: widget.downloading,
          onPressed: widget.canDownload && !widget.downloading
              ? () => widget.onDownload(backup)
              : null,
        ),
        if (widget.canRestore) ...[
          const SizedBox(width: AppSpacing.xs),
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            loading: widget.restoring,
            onPressed: entry != null && !widget.restoring
                ? () => widget.onRestore(entry)
                : null,
            child: Text(l10n.backupRestoreAction),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The actions drop beneath the date where sharing a line would
            // squeeze the date into a sliver.
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= kSettingsFieldInlineBreakpoint) {
                  return Row(
                    children: [
                      Expanded(child: _details(context)),
                      const SizedBox(width: AppSpacing.md),
                      _actions(context),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _details(context),
                    const SizedBox(height: AppSpacing.xs),
                    _actions(context),
                  ],
                );
              },
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpacing.sm),
              BackupTransferProgressBar(
                transferred: progress.transferred,
                total: progress.total,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
