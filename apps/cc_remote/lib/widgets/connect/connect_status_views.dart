import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/screens/session_utils.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Not paired: instructs the user to scan the QR shown by the Mac.
class NotPairedView extends StatelessWidget {
  const NotPairedView({super.key, required this.t});

  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.scanLine, size: 56, color: t.fgTertiary),
        const SizedBox(height: 20),
        Text(
          l10n.appTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.scanQrPrompt,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.5, color: t.textSecondary),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.scanQrHelp,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: t.textTertiary),
        ),
      ],
    );
  }
}

/// Connecting: signaling -> WebRTC -> handshake in progress.
class ConnectingView extends StatelessWidget {
  const ConnectingView({super.key, required this.t});

  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CcSpinner(size: 36, color: t.textSecondary),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context).connectingToMac,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).connectingDetail,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
        ),
      ],
    );
  }
}

/// Terminal identity-mismatch stop.
class IdentityMismatchView extends StatelessWidget {
  const IdentityMismatchView({
    super.key,
    required this.t,
    required this.onForget,
  });

  final DesignSystemTokens t;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.triangleAlert, size: 48, color: t.textErrorPrimary),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context).identityChangedTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).identityChangedBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
        ),
        const SizedBox(height: 24),
        CcButton(
          onPressed: onForget,
          variant: CcButtonVariant.destructive,
          child: Text(AppLocalizations.of(context).removePairing),
        ),
      ],
    );
  }
}

/// Repeated connect failures: explain and offer a manual retry.
class ConnectionFailedView extends StatelessWidget {
  const ConnectionFailedView({
    super.key,
    required this.t,
    required this.reason,
    required this.onRetry,
    this.debugDetail,
  });

  final DesignSystemTokens t;
  final RemoteFailureReason? reason;
  final VoidCallback onRetry;
  final String? debugDetail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = reason == null
        ? l10n.failureUnknown
        : failureReasonLabel(l10n, reason!);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.wifiOff, size: 48, color: t.textWarningPrimary),
        const SizedBox(height: 20),
        Text(
          l10n.couldntConnect,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          debugDetail == null ? label : '$label  [$debugDetail]',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
        ),
        const SizedBox(height: 24),
        CcButton(
          onPressed: onRetry,
          variant: CcButtonVariant.primary,
          child: Text(l10n.tryAgain),
        ),
      ],
    );
  }
}

/// A pairing link opened the app — require explicit confirmation.
class PendingPairingView extends StatelessWidget {
  const PendingPairingView({
    super.key,
    required this.t,
    required this.serverName,
    required this.onConfirm,
    required this.onDecline,
  });

  final DesignSystemTokens t;
  final String? serverName;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.externalLink, size: 48, color: t.textWarningPrimary),
        const SizedBox(height: 20),
        Text(
          l10n.pendingPairingTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (serverName != null && serverName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              serverName!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
        Text(
          l10n.pendingPairingBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CcButton(
              onPressed: onDecline,
              variant: CcButtonVariant.line,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 12),
            CcButton(
              onPressed: onConfirm,
              variant: CcButtonVariant.primary,
              child: Text(l10n.connect),
            ),
          ],
        ),
      ],
    );
  }
}
