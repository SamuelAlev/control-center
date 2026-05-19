import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/connection_chip.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pre-connection status screen, shown until the phone is connected.
///
/// It guides the user through pairing (scan the QR) and then reports live
/// connection progress: connecting, waiting for the user to approve the device
/// on their Mac, or a failure with a retry. Once connected the router swaps to
/// the tab shell.
///
/// Sentence case throughout. No Material.
class ConnectScreen extends ConsumerWidget {
  /// Creates a [ConnectScreen].
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(remoteUiStateProvider);
    final state = async.value ?? ref.read(remoteSessionProvider).currentUiState;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: ConnectionChip(),
                ),
              ),
              Expanded(
                child: Center(
                  child: switch (state.status) {
                    RemoteStatus.connecting => _Connecting(t: t),
                    RemoteStatus.awaitingApproval => _AwaitingApproval(t: t),
                    RemoteStatus.connectionFailed => _Failed(
                      t: t,
                      reason: state.reason ?? "Couldn't connect.",
                      onRetry: () => ref.read(remoteSessionProvider).retry(),
                    ),
                    RemoteStatus.pendingPairing => _PendingPairing(
                      t: t,
                      host: _hostOf(
                        ref
                            .read(remoteSessionProvider)
                            .pendingPairingRecord
                            ?.signalingUrl,
                      ),
                      onConfirm: () => ref
                          .read(remoteSessionProvider)
                          .confirmPendingPairing(),
                      onDecline: () => ref
                          .read(remoteSessionProvider)
                          .declinePendingPairing(),
                    ),
                    // `connected` is transient here (the router redirects away).
                    RemoteStatus.notPaired ||
                    RemoteStatus.connected => _NotPaired(t: t),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Not paired: instructs the user to scan the QR shown by the Mac.
class _NotPaired extends StatelessWidget {
  const _NotPaired({required this.t});

  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.scanLine, size: 56, color: t.fgTertiary),
        const SizedBox(height: 20),
        Text(
          'Control Center',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan the QR code from your Mac to pair this phone.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.5, color: t.textSecondary),
        ),
        const SizedBox(height: 20),
        Text(
          'Open your camera and point it at the QR shown in '
          'Control Center on your Mac. This phone connects directly '
          'to your Mac over a private link.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: t.textTertiary),
        ),
      ],
    );
  }
}

/// Connecting: signaling → WebRTC → handshake in progress.
class _Connecting extends StatelessWidget {
  const _Connecting({required this.t});

  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CcSpinner(size: 36, color: t.textSecondary),
        const SizedBox(height: 24),
        Text(
          'Connecting to your Mac…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Establishing a secure, direct link.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
        ),
      ],
    );
  }
}

/// Authenticated, waiting for the user to approve the device on their Mac.
class _AwaitingApproval extends StatelessWidget {
  const _AwaitingApproval({required this.t});

  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.userCheck, size: 48, color: t.textSecondary),
        const SizedBox(height: 20),
        Text(
          'Almost there',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Go to Control Center on your Mac and approve this device '
          'to finish connecting.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.5, color: t.textSecondary),
        ),
        const SizedBox(height: 24),
        CcSpinner(size: 22, color: t.textTertiary),
      ],
    );
  }
}

/// Repeated connect failures: explain and offer a manual retry.
class _Failed extends StatelessWidget {
  const _Failed({required this.t, required this.reason, required this.onRetry});

  final DesignSystemTokens t;
  final String reason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.wifiOff, size: 48, color: t.textWarningPrimary),
        const SizedBox(height: 20),
        Text(
          "Couldn't connect",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reason,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
        ),
        const SizedBox(height: 24),
        CcButton(
          onPressed: onRetry,
          variant: CcButtonVariant.primary,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

/// Extracts the host (or null) from a signaling URL for the confirm gate.
String? _hostOf(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(url);
  return (uri != null && uri.host.isNotEmpty) ? uri.host : null;
}

/// A pairing link opened the app — require explicit confirmation before
/// connecting, so a forged `#<payload>` can't silently hijack the channel
/// onto attacker infrastructure (VULN-004). Shows the broker host and asks the
/// user to confirm; declining discards the offer and falls back to any stored
/// pairing.
class _PendingPairing extends StatelessWidget {
  const _PendingPairing({
    required this.t,
    required this.host,
    required this.onConfirm,
    required this.onDecline,
  });

  final DesignSystemTokens t;
  final String? host;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.externalLink, size: 48, color: t.textWarningPrimary),
        const SizedBox(height: 20),
        Text(
          'Connect to this server?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (host != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              host!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
        Text(
          'A link asked Control Center to pair with this server. Only continue '
          'if you started it yourself.',
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
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            CcButton(
              onPressed: onConfirm,
              variant: CcButtonVariant.primary,
              child: const Text('Connect'),
            ),
          ],
        ),
      ],
    );
  }
}
