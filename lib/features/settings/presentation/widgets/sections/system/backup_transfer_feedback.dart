import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:flutter/widgets.dart';

/// Turns a failed backup transfer into a sentence with a fix in it.
///
/// The transfer layer throws a status, not prose, precisely so this can happen
/// here: a 403 on these routes always means one specific missing role, and
/// "HTTP 403" tells the operator nothing about which one. The server's own
/// message wins when it sent one — only it knows that the file handed to a
/// restore was not a workspace database.
String describeBackupTransferError(AppLocalizations l10n, Object error) {
  if (error is! BackupTransferException) {
    return l10n.failedWithError('$error');
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
  CcToastScope.maybeOf(
    context,
  )?.show(message, variant: CcToastVariant.success);
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
          style: CcFonts.code(
            textStyle: CcTypography.caption.copyWith(
              color: tokens.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
