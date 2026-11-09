/// The remote-control settings block (`PairedDevicesPanel`), identical on
/// desktop and web.
///
/// Remote control is server-owned: the connected `cc_server` hosts it and no
/// client has a transport to configure, so the block carries only the Devices
/// panel, the [ServerPairingPanel] (pairing form + minted credential, triggered
/// by the host page's header button).
library;

import 'package:cc_data/cc_data.dart';
import 'package:control_center/features/remote_control/presentation/widgets/server_pairing_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Devices panel: pair more clients (a browser, a desktop app, a phone) to
/// the connected `cc_server` over RPC.
class PairedDevicesPanel extends ConsumerWidget {
  /// Creates the pairing panel.
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
