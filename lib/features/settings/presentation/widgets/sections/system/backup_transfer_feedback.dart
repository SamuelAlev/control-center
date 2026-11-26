import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/server_owner_required.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:flutter/widgets.dart';

/// Turns a failed backup transfer into a sentence with a fix in it.
///
/// The transfer layer throws a status, not prose, precisely so this can happen
/// here: a 403 on these routes always means one specific missing role, and
/// "HTTP 403" tells the operator nothing about which one. A refusal the server
/// names by kind (a file a restore will not adopt, a full disk) is worded by
/// that kind on either lane; the server's own message is the last resort.
String describeBackupTransferError(AppLocalizations l10n, Object error) {
  if (error is RemoteRpcException) {
    // An owner-only op (a restore through `workspace.import`) refused by
    // kind, in the app's words; this path also serves export and delete.
    final ownerOnly = serverOwnerRequiredFromRpc(
      code: error.code,
      message: error.message,
      data: error.data,
    );
    return ownerOnly != null
        ? l10n.serverOwnerOnly
        : failureMessage(l10n, error);
  }
  if (error is! BackupTransferException) {
    return failureMessage(l10n, error);
  }
  // The upload restore refuses anyone but the server owner by kind.
  if (error.kind == serverOwnerRequiredKind) {
    return l10n.backupRestoreServerOwnerOnly;
  }
  // The upload restore answers a refused file as `400 {error, kind}`.
  final refusal = storageRefusalMessageForKind(l10n, error.kind);
  if (refusal != null) {
    return refusal;
  }
  final message = error.serverMessage;
  if (message != null) {
    return message;
  }
  return switch (error.statusCode) {
    403 => l10n.backupTransferForbidden,
    404 => l10n.backupTransferUnsupported,
    413 => l10n.backupTransferTooLarge,
    _ => l10n.failedWithError('HTTP ${error.statusCode}'),
  };
}

/// Whether the server refused the caller, as opposed to failing to answer.
bool isBackupRefusal(Object error) =>
    error is RemoteRpcException && error.code == RpcErrorCodes.unauthorized;

/// Says why a workspace's backups could not be listed.
String describeBackupListError(AppLocalizations l10n, Object error) =>
    isBackupRefusal(error)
    ? l10n.backupListForbidden
    : describeBackupTransferError(l10n, error);

/// Reports a completed restore of a workspace: [done] says what was restored,
/// and when the file carried grants the server held back ([held] of them),
/// the toast says so and where they wait, so the review is not missed.
void reportRestoreDone(
  BuildContext context, {
  required String done,
  required int held,
}) {
  final toasts = CcToastScope.maybeOf(context);
  if (held == 0) {
    toasts?.show(done, variant: CcToastVariant.success);
    return;
  }
  toasts?.show(
    AppLocalizations.of(context).backupRestoreHeldBack(held),
    title: done,
    variant: CcToastVariant.warning,
  );
}

/// A refused restore, worded, in place under the control that started it.
///
/// Not a toast: the sentence says why this file will not do and what to do
/// instead, which has to stay readable while the person picks another file.
class BackupRestoreRefusal extends StatelessWidget {
  /// Creates the line for [message].
  const BackupRestoreRefusal({super.key, required this.message});

  /// The worded refusal ([describeBackupTransferError]).
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
              child: Icon(
                AppIcons.triangleAlert,
                size: 12,
                color: tokens.fgErrorPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: CcTypography.caption.copyWith(
                  color: tokens.textErrorPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reports where a download landed — or says nothing, when the person dismissed
/// the save dialog. A cancelled action needs no toast; it was theirs.
void reportBackupDownload(BuildContext context, BackupDownload result) {
  final l10n = AppLocalizations.of(context);
  final message = switch (result.outcome) {
    BackupDownloadOutcome.saved => l10n.backupDownloadSaved(result.path ?? ''),
    // The web build has no writable path to name, and inventing one would be
    // worse than saying who has the file.
    BackupDownloadOutcome.handedToBrowser => l10n.backupDownloadInBrowser,
    BackupDownloadOutcome.cancelled => null,
  };
  if (message == null) {
    return;
  }
  CcToastScope.maybeOf(context)?.show(message, variant: CcToastVariant.success);
}

/// How much of a backup transfer has moved, as a bar and a byte count.
///
/// These are the two payloads in the product where a spinner is not enough: a
/// workspace database or a whole-install archive can run to gigabytes, and
/// "something is happening" for four minutes is indistinguishable from a hang.
/// Bytes rather than a percentage in the label because the bar already carries
/// the fraction, and "1.2 GB of 4.0 GB" also answers "how much longer".
class BackupTransferProgressBar extends StatelessWidget {
  /// Creates a [BackupTransferProgressBar].
  const BackupTransferProgressBar({
    super.key,
    required this.transferred,
    this.total,
  });

  /// Bytes moved so far.
  final int transferred;

  /// The expected total, or null when the server declared no length — the bar
  /// is then indeterminate rather than pretending to a denominator it lacks.
  final int? total;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final expected = total;
    final label = expected == null || expected <= 0
        ? humanBytes(transferred)
        : '${humanBytes(transferred)} / ${humanBytes(expected)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcProgressBar(
          value: expected == null || expected <= 0
              ? null
              : (transferred / expected).clamp(0.0, 1.0),
          semanticLabel: label,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: CcFonts.numeric(
            textStyle: CcTypography.caption.copyWith(
              color: tokens.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
