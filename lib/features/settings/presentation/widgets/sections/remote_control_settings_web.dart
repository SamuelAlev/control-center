// Web variant of the remote-control settings block.
//
// The web client cannot HOST a WebRTC remote-control server (that is the
// desktop's in-process signaling host), so the transport-config section is
// absent here. But the web client IS a first-party client of a `cc_server`, so
// it CAN pair more clients to that server over RPC — another browser, a desktop
// app, or a phone. The Devices panel therefore renders the server-mediated
// [ServerPairingPanel] (mint / list / revoke via the connected RPC client).
library;

import 'package:control_center/features/remote_control/presentation/widgets/server_pairing_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web has no local remote-control transport server to configure, so this
/// section is empty (the pairing UI lives in the Devices panel below).
class RemoteControlSection extends ConsumerWidget {
  /// Creates the (empty) web transport section.
  const RemoteControlSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}

/// Web Devices panel: pair additional clients to the connected `cc_server`.
class PairedDevicesPanel extends ConsumerWidget {
  /// Creates the web paired-devices panel.
  const PairedDevicesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const ServerPairingPanel();
}
