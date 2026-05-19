/// Same-machine discovery of a `cc_server`.
///
/// A loopback-bound server (the default `--bind loopback`) is invisible to
/// both LAN discovery (mDNS advertising is disabled for loopback binds —
/// the server is not reachable from the network anyway) and tailnet
/// discovery (peers exclude Self). Yet "a server on this machine" is the
/// most common development setup, so the discovery dialog probes loopback
/// directly on the well-known default port.
///
/// VM-only — import exclusively from desktop code paths.
library;

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/identity_probe_client.dart';
import 'package:control_center/core/server/lan_discovery.dart';
import 'package:control_center/core/server/tailscale_discovery.dart'
    show defaultCcServerPort;

/// Loopback probes refuse instantly when nothing listens; one second only
/// bounds a pathologically stalled local accept.
const Duration _loopbackProbeTimeout = Duration(seconds: 1);

/// Probes `127.0.0.1` for a `cc_server` on the default port.
class LoopbackServerDiscovery {
  /// Creates a discoverer. No state is kept between calls.
  const LoopbackServerDiscovery();

  /// Returns the locally-running server, or an empty list. TLS first (a
  /// loopback bind MAY still serve TLS), plaintext second. Never throws.
  Future<List<DiscoveredServer>> discover({
    int port = defaultCcServerPort,
  }) async {
    for (final scheme in const ['https', 'http']) {
      final base = Uri.parse('$scheme://127.0.0.1:$port');
      final probe = await probeServerIdentity(
        base,
        timeout: _loopbackProbeTimeout,
        httpClientFactory: identityProbeClientFactory(base),
      );
      if (probe != null) {
        return [
          DiscoveredServer(
            name: probe.serverName.isNotEmpty ? probe.serverName : '127.0.0.1',
            host: '127.0.0.1',
            port: port,
            serverId: probe.serverId,
            fingerprintPrefix: probe.fingerprint.length > 16
                ? probe.fingerprint.substring(0, 16)
                : probe.fingerprint,
            tls: scheme == 'https',
            source: DiscoverySource.local,
          ),
        ];
      }
    }
    return const [];
  }
}
