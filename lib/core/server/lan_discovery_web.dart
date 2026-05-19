/// Web stub for LAN discovery: a browser cannot join multicast groups, so
/// discovery is a desktop-only affordance (PRD 15 clarification — mDNS and
/// multi-path probing are native-client features). Mirrors the API of
/// `lan_discovery.dart` and always returns nothing.
library;

/// How a [DiscoveredServer] was found (mirrors the VM implementation).
enum DiscoverySource {
  /// Direct probe of this machine.
  local,

  /// mDNS/DNS-SD advertisement on the local network.
  lan,

  /// Tailscale peer enumeration + `/healthz` probing.
  tailscale,
}

/// A server advertised on the local network (unused shape on web).
class DiscoveredServer {
  /// Creates a [DiscoveredServer].
  const DiscoveredServer({
    required this.name,
    required this.host,
    required this.port,
    required this.serverId,
    required this.fingerprintPrefix,
    required this.tls,
    this.source = DiscoverySource.lan,
  });

  /// Display name.
  final String name;

  /// Host/IP on the LAN.
  final String host;

  /// RPC port.
  final int port;

  /// The server's stable id.
  final String serverId;

  /// Fingerprint prefix hint from the TXT record.
  final String fingerprintPrefix;

  /// Whether the endpoint serves TLS.
  final bool tls;

  /// How the server was found.
  final DiscoverySource source;

  /// The canonical RPC URL for this server (`ws(s)://host:port/rpc`).
  String get rpcUrl => '${tls ? 'wss' : 'ws'}://$host:$port/rpc';
}

/// No-op discovery on web.
class LanServerDiscovery {
  /// Creates the stub discoverer.
  const LanServerDiscovery();

  /// Always resolves to an empty list on web.
  Future<List<DiscoveredServer>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async => const [];
}
