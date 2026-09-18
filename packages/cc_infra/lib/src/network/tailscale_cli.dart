import 'dart:convert';
import 'dart:io';

/// Upper bound on `tailscale status --json`.
const Duration kTailscaleStatusTimeout = Duration(seconds: 3);

/// Candidate `tailscale` CLI locations, in preference order. The macOS
/// App Store build ships no `tailscale` on PATH — its CLI lives inside the
/// app bundle. The bare `'tailscale'` fallback relies on PATH (Linux,
/// Homebrew-linked installs); a missing binary throws in [Process.run] and
/// degrades to "no tailnet found".
const List<String> kTailscaleBinaryCandidates = <String>[
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

/// The first existing CLI candidate, else the bare PATH name (whose absence
/// surfaces as a caught [ProcessException] in [listOnlineTailscalePeers]).
String resolveTailscaleCommand() {
  for (final path in kTailscaleBinaryCandidates) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return 'tailscale';
}

/// Runs `tailscale status --json` against the first resolvable CLI.
///
/// Never throws: no Tailscale install, a dead daemon, or a timeout all
/// degrade to an empty list.
Future<List<TailscalePeer>> listOnlineTailscalePeers({
  Duration timeout = kTailscaleStatusTimeout,
}) async {
  try {
    final result = await Process.run(resolveTailscaleCommand(), const [
      'status',
      '--json',
    ]).timeout(timeout);
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
