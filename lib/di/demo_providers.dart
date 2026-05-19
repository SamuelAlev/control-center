/// The demo gate, bound at the composition root.
///
/// It lives in `di/` rather than in `features/demo/` because it is asked
/// EVERYWHERE — by shared widgets (the composer, the avatar hovercard) and by
/// the settings shell, neither of which may import another feature. It cannot
/// live in `core/` either: the answer is derived from the server list, which
/// the settings feature owns, and core must not depend on a feature. The
/// composition root is the one layer allowed to know both, which is the same
/// reason every repository port is bound here.
library;

import 'package:control_center/features/settings/providers/server_connection_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app is connected to a PUBLIC DEMO server.
///
/// Read off the ACTIVE server's connection descriptor, which carries the flag
/// from two directions that must agree:
///  * a manually entered URL picks it up from the pre-connect `/healthz` probe
///    (`ServerIdentityProbe.demo`);
///  * a redeemed invite picks it up from the descriptor in the redeem
///    envelope, which the client prefers over the URL it was given.
///
/// It is deliberately NOT an RPC call: the shell needs to know before the
/// first frame, and a demo visitor's whole session is bracketed by this.
/// Default-false everywhere, so a normal install is untouched.
final isDemoServerProvider = Provider<bool>((ref) {
  final servers = ref.watch(serverListProvider);
  final activeId = servers.activeServerId;
  if (activeId == null || activeId.isEmpty) {
    return false;
  }
  for (final entry in servers.entries) {
    if (entry.serverId == activeId) {
      return entry.descriptor.isDemo;
    }
  }
  return false;
});
