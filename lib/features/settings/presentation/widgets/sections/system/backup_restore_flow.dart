import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/type_to_confirm_labels.dart';
import 'package:flutter/widgets.dart';

/// Confirms, then adopts one workspace file out of a backup.
///
/// This IS `workspace.import` — a backup's per-workspace path is exactly what
/// that op takes as its source — so restoring and importing cannot drift into
/// two mechanisms that treat the same file differently. [onBusy] brackets the
/// import, not the confirmation. A refused file is not a toast: [onRefused]
/// gets the worded refusal to show under the entry that was restored (and
/// null when a new attempt starts, to clear it).
Future<void> restoreWorkspaceFromBackup(
  BuildContext context, {
  required BackupActions actions,
  required BackupSnapshotWorkspaceView entry,
  required String workspaceName,
  required ValueChanged<bool> onBusy,
  required ValueChanged<String?> onRefused,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showCcConfirmDialog(
    context: context,
    title: l10n.backupRestoreTitle,
    message: l10n.backupRestoreBody(workspaceName),
    confirmLabel: l10n.backupRestoreAction,
    cancelLabel: l10n.cancel,
    danger: true,
    typeToConfirm: workspaceName,
    typeToConfirmLabels: appTypeToConfirmLabels(context),
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  onRefused(null);
  onBusy(true);
  try {
    final held = await actions.importWorkspace(
      workspaceId: entry.workspaceId,
      sourcePath: entry.path,
    );
    if (context.mounted) {
      reportRestoreDone(
        context,
        done: l10n.backupRestoreDone(workspaceName),
        held: held,
      );
    }
  } on Object catch (e) {
    onRefused(describeBackupTransferError(l10n, e));
  } finally {
    onBusy(false);
  }
}
