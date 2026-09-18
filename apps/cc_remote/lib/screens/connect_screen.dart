import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/connect/connect_status_views.dart';
import 'package:cc_remote/widgets/connection_chip.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pre-connection status screen, shown until the phone is connected.
///
/// It guides the user through pairing (scan the QR) and then reports live
/// connection progress: connecting, a failure with a retry, or the terminal
/// identity-mismatch stop. Once connected the router swaps to the tab shell.
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
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: ConnectionChip(),
                ),
              ),
              Expanded(
                child: Center(
                  child: switch (state.status) {
                    RemoteStatus.connecting => ConnectingView(t: t),
                    RemoteStatus.connectionFailed => ConnectionFailedView(
                      t: t,
                      reason: state.reason,
                      debugDetail: state.debugDetail,
                      onRetry: () => ref.read(remoteSessionProvider).retry(),
                    ),
                    RemoteStatus.identityMismatch => IdentityMismatchView(
                      t: t,
                      onForget: () => ref.read(remoteSessionProvider).unpair(),
                    ),
                    RemoteStatus.pendingPairing => PendingPairingView(
                      t: t,
                      serverName: ref
                          .read(remoteSessionProvider)
                          .pendingPairingRecord
                          ?.descriptor
                          .serverName,
                      onConfirm: () => ref
                          .read(remoteSessionProvider)
                          .confirmPendingPairing(),
                      onDecline: () => ref
                          .read(remoteSessionProvider)
                          .declinePendingPairing(),
                    ),
                    RemoteStatus.notPaired ||
                    RemoteStatus.connected => NotPairedView(t: t),
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
