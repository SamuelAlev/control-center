import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/type_to_confirm_labels.dart';
import 'package:flutter/widgets.dart';

/// Confirms, then adopts one workspace file out of a backup.
///
/// This IS `workspace.import` — a backup's per-workspace path is exactly what
/// that op takes as its source — so restoring and importing cannot drift into
/// two mechanisms that treat the same file differently. [onBusy] brackets the
/// import, not the confirmation.
Future<void> restoreWorkspaceFromBackup(
  BuildContext context, {
  required BackupActions actions,
  required BackupSnapshotWorkspaceView entry,
  required String workspaceName,
  required ValueChanged<bool> onBusy,
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
  onBusy(true);
  try {
    await actions.importWorkspace(
      workspaceId: entry.workspaceId,
      sourcePath: entry.path,
    );
    if (context.mounted) {
      CcToastScope.maybeOf(context)?.show(
        l10n.backupRestoreDone(workspaceName),
        variant: CcToastVariant.success,
      );
    }
  } on Object catch (e) {
    if (context.mounted) {
      CcToastScope.maybeOf(
        context,
      )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    }
  } finally {
    onBusy(false);
  }
}
