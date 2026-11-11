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

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/features/demo/demo_world.dart';
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

/// The demo's forge connections, or null on a real server.
///
/// A demo server holds no credential and wires no forge port, so
/// `forge.listConnections` is not in its registry at all. Bound here, at the
/// composition root, so the production provider carries no demo branch of
/// its own and — the part that shows — the viewer has an identity, so the
/// seeded review requests actually address somebody. See `kDemoViewerLogin`.
final demoForgeConnectionsProvider = Provider<List<ForgeConnection>?>(
  (ref) => ref.watch(isDemoServerProvider)
      ? const [
          ForgeConnection(
            forge: ForgeHost.github,
            status: ForgeConnectionStatus.connected,
            username: kDemoViewerLogin,
            source: ForgeCredentialSource.oauth,
          ),
        ]
      : null,
);

/// The demo's `github.currentUser` answer, or null on a real server.
///
/// The op is absent from a demo's registry and no amount of retrying will
/// change that. The team membership is what routes the retriever PR's TEAM
/// review request into the visitor's queue. See `kDemoViewerLogin`.
final demoGitHubIdentityProvider = Provider<Map<String, dynamic>?>(
  (ref) => ref.watch(isDemoServerProvider)
      ? const {
          'user': {'login': kDemoViewerLogin, 'name': 'Maya Okonkwo'},
          'teams': [
            {'org': kDemoViewerOrg, 'slug': kDemoViewerTeamSlug},
          ],
        }
      : null,
);
