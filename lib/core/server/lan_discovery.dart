/// Zero-config LAN discovery of `cc_server` instances (PRD 15 §7).
///
/// Desktop-only client counterpart of the server's mDNS responder
/// (`CcMdnsResponder` in `packages/cc_infra/lib/src/network/mdns_responder.dart`):
/// browses the DNS-SD service type the server advertises and resolves each
/// instance to a connectable host/port plus its identity TXT metadata.
///
/// VM-only (`package:multicast_dns` is `dart:io`-based) — import this file
/// exclusively from desktop code paths, never from web-reachable ones.
library;

import 'dart:convert';

import 'package:multicast_dns/multicast_dns.dart';

/// The DNS-SD service type `cc_server` advertises.
///
/// KEEP IN SYNC with `ccServerMdnsServiceType` in cc_infra's
/// `mdns_responder.dart` — the lib-boundary ratchet
/// (`test/core/lib_boundary_test.dart`) forbids importing cc_infra here, so
/// the wire constant is deliberately declared on both sides.
const String _ccServerServiceType = '_ccserver._tcp.local';

/// TXT key: the server's stable identifier (de-dupe key across interfaces).
const String _txtKeyServerId = 'sid';

/// TXT key: first 16 hex chars of the server's TLS certificate fingerprint.
const String _txtKeyFingerprint = 'fp';

/// TXT key: the human-readable server name.
const String _txtKeyName = 'name';

/// TXT key: whether the server expects TLS (`'1'`) or plaintext (`'0'`).
const String _txtKeyTls = 'tls';

/// How long each per-instance SRV/TXT/A sub-lookup may take. Records usually
/// arrive from the mDNS client's cache (the PTR response carries them as
/// additionals), so this only bounds the unhappy path.
const Duration _recordLookupTimeout = Duration(seconds: 2);

/// How a [DiscoveredServer] was found.
enum DiscoverySource {
  /// Direct probe of this machine (a loopback-bound server is invisible to
  /// both mDNS and the tailnet).
  local,

  /// mDNS/DNS-SD advertisement on the local network.
  lan,

  /// Tailscale peer enumeration + `/healthz` probing (mDNS cannot cross a
  /// tailnet — no multicast).
  tailscale,
}

/// A `cc_server` instance found on the local network.
class DiscoveredServer {
  /// Creates an immutable discovery result.
  const DiscoveredServer({
    required this.name,
    required this.host,
    required this.port,
    required this.serverId,
    required this.fingerprintPrefix,
    required this.tls,
    this.source = DiscoverySource.lan,
  });

  /// The human-readable server name (TXT `name`, falling back to the mDNS
  /// instance label).
  final String name;

  /// The host to connect to — a resolved IPv4 address when available,
  /// otherwise the advertised `<hostname>.local` target.
  final String host;

  /// The advertised server port.
  final int port;

  /// The server's stable identifier (TXT `sid`) — the de-dupe key.
  final String serverId;

  /// The first 16 hex chars of the server's TLS certificate fingerprint
  /// (TXT `fp`), empty when the server did not advertise one.
  final String fingerprintPrefix;

  /// Whether the server expects a TLS connection (TXT `tls` == `'1'`).
  final bool tls;

  /// How the server was found.
  final DiscoverySource source;

  /// The canonical RPC URL for this server (`ws(s)://host:port/rpc`) — what a
  /// discovery pick writes into the server-URL field.
  String get rpcUrl => '${tls ? 'wss' : 'ws'}://$host:$port/rpc';

  @override
  bool operator ==(Object other) {
    return other is DiscoveredServer &&
        other.name == name &&
        other.host == host &&
        other.port == port &&
        other.serverId == serverId &&
        other.fingerprintPrefix == fingerprintPrefix &&
        other.tls == tls &&
        other.source == source;
  }

  @override
  int get hashCode =>
      Object.hash(name, host, port, serverId, fingerprintPrefix, tls, source);

  @override
  String toString() =>
      'DiscoveredServer($name, $host:$port, sid: $serverId, tls: $tls, '
      'source: ${source.name})';
}

/// Builds a [DiscoveredServer] from resolved mDNS records — pure and
/// unit-testable (no sockets).
///
/// [instance] is the full service-instance FQDN from the PTR record;
/// [target] and [port] come from the SRV record; [txt] the parsed TXT
/// entries (see [parseTxtEntries]); [resolvedIp], when given, is preferred
/// over [target] as the connect host.
///
/// Returns `null` when the advertisement is not a usable `cc_server`
/// (missing `sid`, invalid port, or no host at all).
DiscoveredServer? discoveredFrom({
  required String instance,
  required String target,
  required int port,
  required Map<String, String> txt,
  String? resolvedIp,
}) {
  final serverId = txt[_txtKeyServerId]?.trim() ?? '';
  if (serverId.isEmpty) {
    return null;
  }
  if (port <= 0 || port > 65535) {
    return null;
  }
  var host = (resolvedIp != null && resolvedIp.isNotEmpty)
      ? resolvedIp
      : target.trim();
  if (host.endsWith('.')) {
    host = host.substring(0, host.length - 1);
  }
  if (host.isEmpty) {
    return null;
  }
  final advertisedName = txt[_txtKeyName]?.trim() ?? '';
  return DiscoveredServer(
    name: advertisedName.isNotEmpty
        ? advertisedName
        : instanceLabelOf(instance),
    host: host,
    port: port,
    serverId: serverId,
    fingerprintPrefix: txt[_txtKeyFingerprint]?.trim() ?? '',
    tls: txt[_txtKeyTls]?.trim() == '1',
  );
}

/// Extracts the instance label from a full service-instance FQDN:
/// `My Server._ccserver._tcp.local` → `My Server`. Unrecognized names are
/// returned unchanged.
String instanceLabelOf(String instanceFqdn) {
  const suffix = '.$_ccServerServiceType';
  if (instanceFqdn.toLowerCase().endsWith(suffix)) {
    return instanceFqdn.substring(0, instanceFqdn.length - suffix.length);
  }
  return instanceFqdn;
}

/// Parses `package:multicast_dns`'s TXT representation — the record's
/// length-prefixed strings re-joined with newlines — into a key→value map.
/// Entries without `=` become keys with an empty value (DNS-SD boolean
/// attributes); later duplicates win.
Map<String, String> parseTxtEntries(String txtText) {
  final entries = <String, String>{};
  for (final line in const LineSplitter().convert(txtText)) {
    if (line.isEmpty) {
      continue;
    }
    final separator = line.indexOf('=');
    if (separator <= 0) {
      entries[line] = '';
      continue;
    }
    entries[line.substring(0, separator)] = line.substring(separator + 1);
  }
  return entries;
}

/// Browses the LAN for advertised `cc_server` instances.
class LanServerDiscovery {
  /// Creates a discoverer. Each [discover] call runs its own short-lived
  /// [MDnsClient]; no state is kept between calls.
  const LanServerDiscovery();

  /// Looks up every `cc_server` advertising on the local network, resolving
  /// each to a [DiscoveredServer]. De-duped by [DiscoveredServer.serverId]
  /// (one server may announce on several interfaces).
  ///
  /// mDNS is inherently flaky (blocked multicast, VPNs, sandboxes), so every
  /// failure degrades to "found nothing so far" — this never throws.
  Future<List<DiscoveredServer>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final client = MDnsClient();
    final found = <String, DiscoveredServer>{};
    final seenInstances = <String>{};
    try {
      await client.start();
      final pointers = client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_ccServerServiceType),
        timeout: timeout,
      );
      await for (final pointer in pointers) {
        if (!seenInstances.add(pointer.domainName)) {
          continue;
        }
        try {
          final server = await _resolveInstance(client, pointer.domainName);
          if (server != null) {
            found[server.serverId] = server;
          }
        } catch (_) {
          // Skip the instance that failed to resolve; keep browsing.
        }
      }
    } catch (_) {
      // mDNS unavailable — report whatever was found before the failure.
    } finally {
      try {
        client.stop();
      } catch (_) {
        // Best-effort cleanup.
      }
    }
    return found.values.toList(growable: false);
  }

  Future<DiscoveredServer?> _resolveInstance(
    MDnsClient client,
    String instance,
  ) async {
    final srv = await _firstOrNull(
      client.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(instance),
        timeout: _recordLookupTimeout,
      ),
    );
    if (srv == null) {
      return null;
    }

    final txt = <String, String>{};
    final txtRecord = await _firstOrNull(
      client.lookup<TxtResourceRecord>(
        ResourceRecordQuery.text(instance),
        timeout: _recordLookupTimeout,
      ),
    );
    if (txtRecord != null) {
      txt.addAll(parseTxtEntries(txtRecord.text));
    }

    String? resolvedIp;
    final address = await _firstOrNull(
      client.lookup<IPAddressResourceRecord>(
        ResourceRecordQuery.addressIPv4(srv.target),
        timeout: _recordLookupTimeout,
      ),
    );
    if (address != null) {
      resolvedIp = address.address.address;
    }

    return discoveredFrom(
      instance: instance,
      target: srv.target,
      port: srv.port,
      txt: txt,
      resolvedIp: resolvedIp,
    );
  }

  /// First record of a lookup stream, or `null` when the stream times out
  /// empty or errors — mDNS lookups must never take the caller down.
  Future<T?> _firstOrNull<T extends ResourceRecord>(Stream<T> records) async {
    try {
      return await records.first;
    } catch (_) {
      return null;
    }
  }
}
