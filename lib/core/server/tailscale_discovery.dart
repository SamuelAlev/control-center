/// Tailnet discovery of `cc_server` instances.
///
/// mDNS cannot cross a tailnet (no multicast), so LAN discovery
/// (`lan_discovery.dart`) never sees servers reachable only over Tailscale.
/// This complements it: enumerate the tailnet's peers via the local
/// `tailscale` CLI (`tailscale status --json`) and probe each online peer's
/// `/healthz` for the published `cc_server` identity
/// ([probeServerIdentity]). A non-`cc_server` peer is rejected by the
/// `/healthz` response shape, not by port-open alone.
///
/// VM-only (`dart:io` sockets) — import exclusively from desktop
/// code paths, never from web-reachable ones. The CLI spawn itself lives in
/// `cc_infra` ([listOnlineTailscalePeers]); this file only probes `/healthz`.
library;

import 'dart:async';
import 'dart:io';

import 'package:cc_infra/cc_infra.dart'
    show TailscalePeer, listOnlineTailscalePeers;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/lan_discovery.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

export 'package:cc_infra/cc_infra.dart' show TailscalePeer, tailscalePeersFrom;

/// The port `cc_server` listens on unless `--port`/`CC_SERVER_PORT` overrides
/// it. KEEP IN SYNC with the default in `cc_server_config.dart` (9030) — a
/// tailnet probe has no mDNS SRV record to learn the port from, so it can
/// only try the documented default.
const int defaultCcServerPort = 9030;

/// Per-peer `/healthz` probe budget (connection stalls included). Kept short:
/// tailnets list every peer ever seen, most of which are not a cc_server —
/// and a dropped packet path costs one timeout per scheme tried.
const Duration _perPeerTimeout = Duration(seconds: 1);

/// How many peers are probed concurrently. A large tailnet must not fan out
/// unbounded, nor serialize (a 50-peer tailnet of timeouts would otherwise
/// hang the dialog).
const int _probeConcurrency = 8;

/// Discovers `cc_server` instances reachable over the local tailnet.
class TailscaleServerDiscovery {
  /// Creates a discoverer. Each [discover] call re-runs `tailscale status`
  /// (peers come and go); no state is kept between calls.
  const TailscaleServerDiscovery();

  /// Probes every online tailnet peer for a `cc_server` on [port].
  ///
  /// Like LAN discovery, this never throws: no Tailscale install, an
  /// offline tailnet, or no answering servers all degrade to an empty list.
  Future<List<DiscoveredServer>> discover({
    int port = defaultCcServerPort,
  }) async {
    final found = <DiscoveredServer>[];
    await for (final chunk in discoverStream(port: port)) {
      found.addAll(chunk);
    }
    return found;
  }

  /// The incremental counterpart of [discover]: yields each probe chunk as
  /// it resolves so callers can paint partial results instead of blocking on
  /// the slowest peer. Yields nothing when there are no peers; never throws.
  Stream<List<DiscoveredServer>> discoverStream({
    int port = defaultCcServerPort,
  }) async* {
    final peers = await listOnlineTailscalePeers();
    if (peers.isEmpty) {
      return;
    }
    for (var i = 0; i < peers.length; i += _probeConcurrency) {
      final end = i + _probeConcurrency;
      final chunk = peers.sublist(i, end > peers.length ? peers.length : end);
      final results = await Future.wait(
        chunk.map((peer) => _probePeer(peer, port)),
      );
      final found = results.whereType<DiscoveredServer>().toList(
        growable: false,
      );
      if (found.isNotEmpty) {
        yield found;
      }
    }
  }

  /// Probes one peer and stores ONLY the host that actually answered, so
  /// every listed server is reachable at the exact host in its URL: the
  /// MagicDNS name first (preferred — stable across IP reassignment and
  /// classifies as a `TailnetPath`), the tailnet IP as fallback for clients
  /// whose resolver does not handle MagicDNS. For each candidate, TLS first
  /// (a non-loopback `cc_server` bind requires TLS), plaintext second (the
  /// `--insecure` escape hatch). Returns null when no candidate's `/healthz`
  /// answers with a server identity.
  Future<DiscoveredServer?> _probePeer(TailscalePeer peer, int port) async {
    final candidates = <String>{
      if (peer.dnsName.isNotEmpty) peer.dnsName,
      peer.addresses.first,
    };
    for (final candidate in candidates) {
      for (final scheme in const ['https', 'http']) {
        final probe = await probeServerIdentity(
          Uri.parse('$scheme://$candidate:$port'),
          timeout: _perPeerTimeout,
          httpClientFactory: () => _probeClientFor(candidate, port),
        );
        if (probe != null) {
          return DiscoveredServer(
            name: probe.serverName.isNotEmpty
                ? probe.serverName
                : (peer.name.isNotEmpty ? peer.name : candidate),
            host: candidate,
            port: port,
            serverId: probe.serverId,
            fingerprintPrefix: probe.fingerprint.length > 16
                ? probe.fingerprint.substring(0, 16)
                : probe.fingerprint,
            tls: scheme == 'https',
            source: DiscoverySource.tailscale,
          );
        }
      }
    }
    return null;
  }

  /// An HTTP client that accepts the server's self-signed certificate, but
  /// ONLY for the exact host:port under probe.
  ///
  /// Why this is safe here: cc_server's TLS identity is self-signed by
  /// design — trust is TOFU on the `/healthz` fingerprint and the pin is
  /// verified cryptographically by the Ed25519 handshake at connect time. A
  /// poisoned probe therefore fails closed at connect instead of trusting
  /// anything. X.509 chain validation adds nothing for this protocol and
  /// the callback is host/port-narrowed so a reused client cannot silently
  /// cover an unrelated request.
  http.Client _probeClientFor(String host, int port) {
    final inner = HttpClient()
      ..connectionTimeout = _perPeerTimeout
      ..badCertificateCallback = (cert, certHost, certPort) =>
          certHost == host && certPort == port;
    return IOClient(inner);
  }
}
