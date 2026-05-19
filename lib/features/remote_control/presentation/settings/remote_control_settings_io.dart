// Desktop variant of the remote-control settings block.
//
// Remote control is now server-owned: the connected `cc_server` is the host
// (the desktop is a thin client and no longer runs an in-process WebRTC
// signaling host backed by a local database — that legacy desktop-as-host
// surface read the DB directly and is gone) and there is no client-side
// transport to configure, so the settings block carries only the Devices
// panel: the [ServerPairingPanel] (pairing form + minted credential, triggered
// by the host page's header button). The conditional-import seam is kept so
// both targets resolve, even though the desktop and web blocks are now
// identical.
library;

import 'package:cc_data/cc_data.dart';
import 'package:control_center/features/remote_control/presentation/widgets/server_pairing_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desktop Devices panel: server-owned phone pairing over RPC.
class PairedDevicesPanel extends ConsumerWidget {
  /// Creates the desktop pairing panel.
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
