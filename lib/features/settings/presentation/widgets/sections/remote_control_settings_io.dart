// Desktop variant of the remote-control settings block.
//
// Remote control is now server-owned: the connected `cc_server` is the host
// (the desktop is a thin client and no longer runs an in-process WebRTC
// signaling host backed by a local database — that legacy desktop-as-host
// surface read the DB directly and is gone). The Devices panel renders the
// [ServerPairingPanel] (mint / list / revoke pairings via the cc_server over
// RPC), exactly like the web client; there is no client-side transport to
// configure, so the transport section is empty. The conditional-import seam is
// kept so both targets resolve, even though the desktop and web blocks are now
// identical.
library;

import 'package:control_center/features/remote_control/presentation/widgets/server_pairing_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desktop has no in-process remote-control transport to configure (the
/// `cc_server` is the host), so this section is empty — mirroring web.
class RemoteControlSection extends ConsumerWidget {
  /// Creates the (empty) desktop transport section.
  const RemoteControlSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}

/// Desktop Devices panel: server-owned phone pairing over RPC.
class PairedDevicesPanel extends ConsumerWidget {
  /// Creates the desktop paired-devices panel.
  const PairedDevicesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const ServerPairingPanel();
}
