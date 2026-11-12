import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_restore_gate.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';

/// The label of a backup's verification state.
///
/// "Unverified", never "Failed": an incomplete entry is either a snapshot
/// that never finished or one taken before snapshots recorded checksums, and
/// the label has to be true of both.
String backupVerificationLabel(
  AppLocalizations l10n,
  BackupSnapshotView backup,
) => backup.complete
    ? l10n.backupSnapshotComplete
    : l10n.backupSnapshotUnverified;

/// One install snapshot: when it was taken, what it holds, and what can be
/// restored.
class BackupSnapshotRow extends StatelessWidget {
  /// Creates the row for [snapshot].
  const BackupSnapshotRow({
    super.key,
    required this.snapshot,
    required this.workspaceNames,
    required this.expanded,
    required this.restoringKey,
    required this.refusal,
    required this.deleting,
    required this.downloading,
    required this.progress,
    required this.canTransfer,
    required this.onExpandedChanged,
    required this.onRestore,
    required this.onDownload,
    required this.onDelete,
  });

  /// The snapshot.
  final BackupSnapshotView snapshot;

  /// Live workspace names by id.
  final Map<String, String> workspaceNames;

  /// Whether the detail is showing.
  final bool expanded;

  /// `workspaceId:path` of the entry being restored, if any.
  final String? restoringKey;

  /// The refused restore of one of its entries: that entry's key
  /// (`workspaceId:path`) and the worded refusal.
  final ({String key, String message})? refusal;

  /// Whether it is being deleted.
  final bool deleting;

  /// Whether it is downloading.
  final bool downloading;

  /// How far the download has got.
  final ({int transferred, int? total})? progress;

  /// Whether files can move over this connection.
  final bool canTransfer;

  /// Fired when the header is activated.
  final ValueChanged<bool> onExpandedChanged;

  /// Fired by an entry's Restore, with the workspace's name.
  final Future<void> Function(BackupSnapshotWorkspaceView, String) onRestore;

  /// Fired by Download.
  final Future<void> Function(BackupSnapshotView) onDownload;

  /// Fired by Delete.
  final Future<void> Function(BackupSnapshotView) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final createdAt = snapshot.createdAt;
    final note = CcTypography.caption.copyWith(color: tokens.textSecondary);

    return SettingsEntityRow(
      title: snapshot.name,
      icon: AppIcons.archive,
      tone: snapshot.complete ? CcStatusTone.positive : CcStatusTone.caution,
      statusLabel: backupVerificationLabel(l10n, snapshot),
      subtitleWidget: createdAt == null
          ? null
          : AppTimestamp.relative(createdAt),
      meta: [
        if (snapshot.isLastGoodCopy)
          CcStatusTag(
            label: l10n.backupSnapshotLastGoodCopy,
            tone: CcStatusTone.info,
          ),
        SettingsMetaFact(value: humanBytes(snapshot.bytes)),
        SettingsMetaFact(
          value: l10n.backupSnapshotWorkspaces(snapshot.workspaces.length),
        ),
        if (snapshot.skippedWorkspaceIds.isNotEmpty)
          SettingsMetaFact(
            value: l10n.backupSnapshotSkipped(
              snapshot.skippedWorkspaceIds.length,
            ),
          ),
      ],
      expanded: expanded,
      onExpandedChanged: onExpandedChanged,
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (snapshot.isLastGoodCopy) ...[
            Text(l10n.backupSnapshotLastGoodCopyNote, style: note),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!snapshot.complete) ...[
            Text(
              l10n.backupSnapshotUnverifiedNote,
              style: CcTypography.caption.copyWith(
                color: tokens.textWarningPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CcButton(
              size: CcButtonSize.sm,
              icon: AppIcons.download,
              loading: downloading,
              onPressed: !canTransfer || downloading
                  ? null
                  : () => onDownload(snapshot),
              child: Text(l10n.backupDownloadAction),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            BackupTransferProgressBar(
              transferred: progress!.transferred,
              total: progress!.total,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.backupServerPathLabel,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          SettingsCopyField(value: snapshot.path),
          const SizedBox(height: AppSpacing.md),
          const BackupRestoreOwnerOnlyNote(),
          for (final entry in snapshot.workspaces)
            BackupSnapshotWorkspaceRow(
              entry: entry,
              // A snapshot outlives the registry: a workspace can be deleted,
              // or the whole file moved to another install. Naming the id and
              // refusing the restore beats an import that fails server-side
              // with "unknown workspace" after a type-to-confirm.
              name: workspaceNames[entry.workspaceId],
              busy: restoringKey == '${entry.workspaceId}:${entry.path}',
              refusal: refusal?.key == '${entry.workspaceId}:${entry.path}'
                  ? refusal?.message
                  : null,
              onRestore: onRestore,
            ),
          const SizedBox(height: AppSpacing.lg),
          // The delete lives inside the callout that warns about it. It trails
          // the copy where there is room and drops beneath it where a trailing
          // button would squeeze the warning into a sliver.
          LayoutBuilder(
            builder: (context, constraints) {
              final inline =
                  constraints.maxWidth >= kSettingsFieldInlineBreakpoint;
              final delete = CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.destructive,
                icon: AppIcons.trash2,
                loading: deleting,
                onPressed: deleting ? null : () => onDelete(snapshot),
                child: Text(l10n.backupDeleteSnapshotAction),
              );
              return CcAlert(
                variant: CcAlertVariant.danger,
                title: l10n.backupDeleteSnapshotLabel,
                description: Text(
                  // Cleanup spares a last good copy; a person can still
                  // delete it, so the warning says what that costs.
                  snapshot.isLastGoodCopy
                      ? l10n.backupDeleteLastGoodCopyDescription
                      : l10n.backupDeleteSnapshotDescription,
                  style: CcTypography.bodySm.copyWith(
                    color: tokens.textErrorPrimary,
                  ),
                ),
                trailing: inline ? delete : null,
                action: inline ? null : delete,
              );
            },
          ),
        ],
      ),
    );
  }
}
