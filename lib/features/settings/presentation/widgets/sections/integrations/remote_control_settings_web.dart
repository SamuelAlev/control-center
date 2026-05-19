// Web variant of the remote-control settings block.
//
// The web client cannot HOST a WebRTC remote-control server (that is the
// desktop's in-process signaling host), so there is no transport-config
// section here. But the web client IS a first-party client of a `cc_server`,
// so it CAN pair more clients to that server over RPC — another browser, a
// desktop app, or a phone. The Devices panel therefore renders the
// server-mediated [ServerPairingPanel] (pairing form + minted credential,
// triggered by the host page's header button, via the connected RPC client).
library;

import 'package:cc_data/cc_data.dart';
import 'package:control_center/features/remote_control/presentation/widgets/server_pairing_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web Devices panel: pair additional clients to the connected `cc_server`.
class PairedDevicesPanel extends ConsumerWidget {
  /// Creates the web pairing panel.
  const PairedDevicesPanel({
    super.key,
    required this.formOpen,
    required this.onRequestClose,
    required this.minted,
    required this.onMinted,
  });

  /// Forwarded to [ServerPairingPanel.formOpen].
  final bool formOpen;

  /// Forwarded to [ServerPairingPanel.onRequestClose].
  final VoidCallback onRequestClose;

  /// Forwarded to [ServerPairingPanel.minted].
  final PairingMint? minted;

  /// Forwarded to [ServerPairingPanel.onMinted].
  final ValueChanged<PairingMint?> onMinted;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ServerPairingPanel(
    formOpen: formOpen,
    onRequestClose: onRequestClose,
    minted: minted,
    onMinted: onMinted,
  );
}
