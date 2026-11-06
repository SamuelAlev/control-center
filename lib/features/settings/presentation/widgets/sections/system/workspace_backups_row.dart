import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_restore_flow.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/workspace_backup_entry.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/type_to_confirm_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One workspace's scheduled backups: when it was last backed up, and each
/// restore point once opened.
///
/// A deleted workspace keeps its row so its files stay findable, without
/// Restore: `workspace.import` has no live workspace to adopt into.
class WorkspaceBackupsRow extends ConsumerStatefulWidget {
  /// Creates a [WorkspaceBackupsRow].
  const WorkspaceBackupsRow({
    super.key,
    required this.workspaceId,
    required this.workspaceName,
    required this.backups,
    required this.expanded,
    required this.onExpandedChanged,
    this.workspaceDeleted = false,
  });

  /// The workspace these backups hold.
  final String workspaceId;

  /// Its display name.
  final String workspaceName;

  /// Its backups, newest first. Never empty.
  final List<BackupSnapshotView> backups;

  /// Whether the restore points are showing.
  final bool expanded;

  /// Fired when the header is activated.
  final ValueChanged<bool> onExpandedChanged;

  /// Whether the workspace is gone, which moves these backups to the install
  /// owner's lane.
  final bool workspaceDeleted;

  @override
  ConsumerState<WorkspaceBackupsRow> createState() =>
      _WorkspaceBackupsRowState();
}

class _WorkspaceBackupsRowState extends ConsumerState<WorkspaceBackupsRow> {
  String? _restoring;
  String? _deleting;
  String? _downloading;
  ({int transferred, int? total})? _progress;

  void _fail(Object error) {
    if (mounted) {
      CcToastScope.maybeOf(context)?.show(
        describeBackupTransferError(AppLocalizations.of(context), error),
        variant: CcToastVariant.danger,
      );
    }
  }

  Future<void> _restore(BackupSnapshotWorkspaceView entry) =>
      restoreWorkspaceFromBackup(
        context,
        actions: ref.read(backupActionsProvider),
        entry: entry,
        workspaceName: widget.workspaceName,
        onBusy: (busy) {
          if (mounted) {
            setState(() => _restoring = busy ? entry.path : null);
          }
        },
      );

  Future<void> _download(BackupSnapshotView backup) async {
    setState(() => _downloading = backup.name);
    try {
      final result = await ref
          .read(backupTransferProvider)
          .downloadWorkspaceBackup(
            workspaceId: widget.workspaceId,
            name: backup.name,
            onProgress: (transferred, total) {
              if (mounted) {
                setState(
                  () => _progress = (transferred: transferred, total: total),
                );
              }
            },
          );
      if (mounted) {
        reportBackupDownload(context, result);
      }
    } on Object catch (e) {
      _fail(e);
    } finally {
      if (mounted) {
        setState(() {
          _downloading = null;
          _progress = null;
        });
      }
    }
  }

  Future<void> _delete(BackupSnapshotView backup) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.backupScheduledDeleteTitle,
      message: l10n.backupScheduledDeleteBody(
        workspaceBackupLabel(context, backup),
        widget.workspaceName,
      ),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      danger: true,
      typeToConfirm: widget.workspaceName,
      typeToConfirmLabels: appTypeToConfirmLabels(context),
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _deleting = backup.name);
    final actions = ref.read(backupActionsProvider);
    try {
      await (widget.workspaceDeleted
          ? actions.deleteOrphanedBackup(
              workspaceId: widget.workspaceId,
              name: backup.name,
            )
          : actions.deleteWorkspaceBackup(
              workspaceId: widget.workspaceId,
              name: backup.name,
            ));
      if (mounted) {
        CcToastScope.maybeOf(context)?.show(
          l10n.backupScheduledDeleteDone,
          variant: CcToastVariant.success,
        );
      }
    } on Object catch (e) {
      _fail(e);
    } finally {
      if (mounted) {
        setState(() => _deleting = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final canTransfer = ref.watch(backupTransferAvailableProvider);
    final backups = widget.backups;
    final latest = backups.first;
    final latestAt = latest.createdAt;

    return SettingsEntityRow(
      title: widget.workspaceName,
      icon: AppIcons.archive,
      tone: widget.workspaceDeleted
          ? null
          : latest.complete
          ? CcStatusTone.positive
          : CcStatusTone.caution,
      statusLabel: widget.workspaceDeleted
          ? null
          : latest.complete
          ? l10n.backupSnapshotComplete
          : l10n.backupSnapshotIncomplete,
      subtitleWidget: latestAt == null
          ? null
          : AppTimestamp(
              dateTime: latestAt,
              child: Text(
                l10n.backupScheduledLast(formatRelativeTime(context, latestAt)),
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
      meta: [
        // Not the row's status slot: beside the title it would squeeze the
        // name, which is all that identifies a workspace that no longer exists.
        if (widget.workspaceDeleted)
          CcStatusTag(
            label: l10n.backupScheduledWorkspaceDeleted,
            tone: CcStatusTone.neutral,
          ),
        SettingsMetaFact(value: l10n.backupScheduledCount(backups.length)),
        SettingsMetaFact(value: humanBytes(backups.map((b) => b.bytes).sum)),
      ],
      expanded: widget.expanded,
      onExpandedChanged: widget.onExpandedChanged,
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final backup in backups)
            WorkspaceBackupEntry(
              key: ValueKey(backup.name),
              backup: backup,
              canRestore: !widget.workspaceDeleted,
              canDownload: canTransfer && backup.workspaces.isNotEmpty,
              restoring:
                  _restoring != null &&
                  _restoring == backup.workspaces.firstOrNull?.path,
              deleting: _deleting == backup.name,
              downloading: _downloading == backup.name,
              progress: _downloading == backup.name ? _progress : null,
              onRestore: _restore,
              onDownload: _download,
              onDelete: _delete,
            ),
        ],
      ),
    );
  }
}
