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
/// VM-only (`dart:io` process + sockets) — import exclusively from desktop
/// code paths, never from web-reachable ones.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/lan_discovery.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// The port `cc_server` listens on unless `--port`/`CC_SERVER_PORT` overrides
/// it. KEEP IN SYNC with the default in `cc_server_config.dart` (9030) — a
/// tailnet probe has no mDNS SRV record to learn the port from, so it can
/// only try the documented default.
const int defaultCcServerPort = 9030;

/// Upper bound on `tailscale status --json`.
const Duration _statusTimeout = Duration(seconds: 3);

/// Per-peer `/healthz` probe budget (connection stalls included). Kept short:
/// tailnets list every peer ever seen, most of which are not a cc_server —
/// and a dropped packet path costs one timeout per scheme tried.
const Duration _perPeerTimeout = Duration(seconds: 1);

/// How many peers are probed concurrently. A large tailnet must not fan out
/// unbounded, nor serialize (a 50-peer tailnet of timeouts would otherwise
/// hang the dialog).
const int _probeConcurrency = 8;

/// Candidate `tailscale` CLI locations, in preference order. The macOS
/// App Store build ships no `tailscale` on PATH — its CLI lives inside the
/// app bundle. The bare `'tailscale'` fallback relies on PATH (Linux,
/// Homebrew-linked installs); a missing binary throws in [Process.run] and
/// degrades to "no tailnet found".
const List<String> _tailscaleBinaryCandidates = <String>[
  '/Applications/Tailscale.app/Contents/MacOS/Tailscale',
  '/usr/local/bin/tailscale',
  '/opt/homebrew/bin/tailscale',
];

/// A Tailscale peer worth probing: online and holding at least one IPv4
/// tailnet address.
class TailscalePeer {
  /// Creates a peer record.
  const TailscalePeer({
    required this.name,
    required this.dnsName,
    required this.addresses,
  });

  /// The peer's machine name (`HostName`), may be empty.
  final String name;

  /// The peer's MagicDNS FQDN (`DNSName`, trailing dot stripped), may be
  /// empty when MagicDNS is disabled on the tailnet.
  final String dnsName;

  /// The peer's IPv4 tailnet addresses (100.64.0.0/10), never empty.
  final List<String> addresses;

  /// The stable host to advertise/connect: the MagicDNS name when available
  /// (it survives tailnet IP reassignment and classifies as a `TailnetPath`),
  /// otherwise the first tailnet IP.
  String get host => dnsName.isNotEmpty ? dnsName : addresses.first;

  @override
  String toString() => 'TailscalePeer($host)';
}

/// Parses `tailscale status --json` output into the online, IPv4-reachable
/// peers (Self excluded — a local server is found by LAN discovery or
/// loopback). Pure and unit-testable; malformed input yields an empty list.
List<TailscalePeer> tailscalePeersFrom(String jsonText) {
  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }
    final peers = decoded['Peer'];
    if (peers is! Map<String, dynamic>) {
      return const [];
    }
    final result = <TailscalePeer>[];
    for (final raw in peers.values) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      if (raw['Online'] != true) {
        continue;
      }
      final ips = raw['TailscaleIPs'];
      if (ips is! List) {
        continue;
      }
      final addresses = ips
          .whereType<String>()
          .where((ip) => !ip.contains(':'))
          .toList(growable: false);
      if (addresses.isEmpty) {
        continue;
      }
      var dnsName = (raw['DNSName'] as String? ?? '').trim();
      if (dnsName.endsWith('.')) {
        dnsName = dnsName.substring(0, dnsName.length - 1);
      }
      result.add(
        TailscalePeer(
          name: (raw['HostName'] as String? ?? '').trim(),
          dnsName: dnsName,
          addresses: addresses,
        ),
      );
    }
    return result;
  } catch (_) {
    return const [];
  }
}

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
    final peers = await _peers();
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

  /// Runs `tailscale status --json` against the first resolvable CLI.
  Future<List<TailscalePeer>> _peers() async {
    try {
      final result = await Process.run(_tailscaleCommand(), const [
        'status',
        '--json',
      ]).timeout(_statusTimeout);
      if (result.exitCode != 0) {
        return const [];
      }
      final stdout = result.stdout;
      return stdout is String ? tailscalePeersFrom(stdout) : const [];
    } catch (_) {
      // No Tailscale install / daemon down — not an error for discovery.
      return const [];
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

  /// The first existing CLI candidate, else the bare PATH name (whose absence
  /// surfaces as a caught [ProcessException] in [_peers]).
  static String _tailscaleCommand() {
    for (final path in _tailscaleBinaryCandidates) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return 'tailscale';
  }
}
