import 'dart:convert';

/// How to reach one Control Center server, independent of topology.
///
/// A client holds a [ConnectionDescriptor] per paired server and lets the
/// `ReachabilityResolver` (cc_rpc) pick the best *reachable + secure* path at
/// connect time — loopback, LAN, tailnet, public TLS, or broker relay. The
/// descriptor is a **set of paths plus the pinned identity fingerprint**; no
/// single address is the server's identity (tunnel URLs rotate, LAN IPs move).
///
/// The descriptor is embedded (compact single-letter JSON keys) in invite
/// links and pairing QR fragments, re-published by the server over any live
/// path via the `connection.describe` op, and stored per server in the
/// client's `ServerConnectionStore`.
class ConnectionDescriptor {
  /// Creates a descriptor. [serverId] and [fingerprint] must be non-empty;
  /// [paths] must not be empty (a descriptor that names no path is useless).
  ConnectionDescriptor({
    required this.serverId,
    required this.serverName,
    required this.fingerprint,
    required List<ConnectionPath> paths,
    this.bulkHttpBase,
    List<String> stunUrls = const [],
    this.insecureAllowed = false,
    this.version = currentVersion,
  }) : paths = List.unmodifiable(paths),
       stunUrls = List.unmodifiable(stunUrls) {
    if (serverId.isEmpty) {
      throw ArgumentError.value(serverId, 'serverId', 'must not be empty');
    }
    if (fingerprint.isEmpty) {
      throw ArgumentError.value(
        fingerprint,
        'fingerprint',
        'must not be empty — every server publishes an identity fingerprint',
      );
    }
    if (paths.isEmpty) {
      throw ArgumentError.value(paths, 'paths', 'must name at least one path');
    }
  }

  /// Deserializes from the compact JSON form.
  factory ConnectionDescriptor.fromJson(Map<String, dynamic> json) {
    final rawPaths = json['p'];
    return ConnectionDescriptor(
      version: (json['v'] as num?)?.toInt() ?? currentVersion,
      serverId: json['sid'] as String? ?? '',
      serverName: json['n'] as String? ?? '',
      fingerprint: json['fp'] as String? ?? '',
      paths: rawPaths is List
          ? rawPaths
                .whereType<Map>()
                .map((m) => ConnectionPath.fromJson(m.cast<String, dynamic>()))
                .whereType<ConnectionPath>()
                .toList()
          : const <ConnectionPath>[],
      bulkHttpBase: json['b'] as String?,
      stunUrls: json['st'] is List
          ? (json['st'] as List).map((e) => e.toString()).toList()
          : const <String>[],
      insecureAllowed: json['ins'] as bool? ?? false,
    );
  }

  /// Current descriptor wire version. Bump on incompatible shape changes.
  static const int currentVersion = 1;

  /// Descriptor wire version this instance was parsed from / will serialize as.
  final int version;

  /// The server's stable id (minted once at first boot, never changes).
  final String serverId;

  /// Human-readable server name (shown in pickers and pairing UI).
  final String serverName;

  /// SHA-256 hex of the server's Ed25519 identity public key — the TOFU pin.
  /// The fingerprint, not any address, is the server's identity.
  final String fingerprint;

  /// Every known way to reach the server, unordered (the resolver ranks).
  final List<ConnectionPath> paths;

  /// Preferred HTTPS base URL for bulk transfers (media proxy, downloads)
  /// when one is reachable — bulk data avoids the relayed control plane.
  final String? bulkHttpBase;

  /// STUN server URLs for WebRTC surfaces that ride this descriptor.
  final List<String> stunUrls;

  /// Whether the operator launched the server with `--insecure` (plaintext
  /// off-loopback allowed). Loudly surfaced in every client UI; never default.
  final bool insecureAllowed;

  /// Serializes to the compact JSON form (single-letter keys, QR-friendly).
  Map<String, dynamic> toJson() => {
    'v': version,
    'sid': serverId,
    'n': serverName,
    'fp': fingerprint,
    'p': [for (final p in paths) p.toJson()],
    if (bulkHttpBase != null) 'b': bulkHttpBase,
    if (stunUrls.isNotEmpty) 'st': stunUrls,
    if (insecureAllowed) 'ins': true,
  };

  /// Base64url-encodes the JSON form (no padding) for URL fragments / QR.
  String encode() =>
      base64UrlEncode(utf8.encode(jsonEncode(toJson()))).replaceAll('=', '');

  /// Decodes a base64url descriptor produced by [encode].
  static ConnectionDescriptor decode(String encoded) {
    final bytes = base64Url.decode(base64Url.normalize(encoded));
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return ConnectionDescriptor.fromJson(json);
  }

  /// Returns a copy with [paths] replaced (used when the server re-publishes
  /// its current path set over a live connection).
  ConnectionDescriptor withPaths(
    List<ConnectionPath> newPaths, {
    String? newBulkHttpBase,
  }) => ConnectionDescriptor(
    version: version,
    serverId: serverId,
    serverName: serverName,
    fingerprint: fingerprint,
    paths: newPaths,
    bulkHttpBase: newBulkHttpBase ?? bulkHttpBase,
    stunUrls: stunUrls,
    insecureAllowed: insecureAllowed,
  );

  @override
  bool operator ==(Object other) =>
      other is ConnectionDescriptor &&
      other.version == version &&
      other.serverId == serverId &&
      other.serverName == serverName &&
      other.fingerprint == fingerprint &&
      other.bulkHttpBase == bulkHttpBase &&
      other.insecureAllowed == insecureAllowed &&
      _listEquals(other.paths, paths) &&
      _listEquals(other.stunUrls, stunUrls);

  @override
  int get hashCode => Object.hash(
    version,
    serverId,
    serverName,
    fingerprint,
    bulkHttpBase,
    insecureAllowed,
    Object.hashAll(paths),
    Object.hashAll(stunUrls),
  );

  @override
  String toString() =>
      'ConnectionDescriptor($serverId "$serverName", '
      '${paths.length} paths, fp=${fingerprint.length > 8 ? fingerprint.substring(0, 8) : fingerprint}…)';
}

/// One concrete way to reach a server. Ranked by [rank] — lower is better —
/// with the fixed precedence loopback > LAN > tailnet > wss(TLS) > relay.
sealed class ConnectionPath {
  const ConnectionPath();

  /// Parses one path from its compact JSON form. Returns null for an unknown
  /// `t` tag (forward compatibility: a client skips paths it can't use).
  static ConnectionPath? fromJson(Map<String, dynamic> json) {
    switch (json['t']) {
      case LoopbackPath.tag:
        return LoopbackPath(port: (json['port'] as num?)?.toInt() ?? 0);
      case LanPath.tag:
        return LanPath(
          host: json['h'] as String? ?? '',
          port: (json['port'] as num?)?.toInt() ?? 0,
          tls: json['tls'] as bool? ?? false,
        );
      case TailnetPath.tag:
        return TailnetPath(
          host: json['h'] as String? ?? '',
          port: (json['port'] as num?)?.toInt() ?? 0,
          tls: json['tls'] as bool? ?? false,
        );
      case WssPath.tag:
        return WssPath(uri: json['u'] as String? ?? '');
      case RelayPath.tag:
        return RelayPath(
          signalingUrl: json['s'] as String? ?? '',
          room: json['r'] as String? ?? '',
        );
      default:
        return null;
    }
  }

  /// Resolver precedence — lower wins. Fixed by PRD 15: loopback > LAN >
  /// tailnet > wss(TLS) > relay.
  int get rank;

  /// Whether frames flow peer-to-server without an intermediary relay.
  /// Drives the "direct"/"relayed" connection-path indicator.
  bool get isDirect;

  /// Serializes to the compact JSON form.
  Map<String, dynamic> toJson();

  /// The `ws(s)://…/rpc` URI to dial for socket paths; null for relay paths.
  Uri? get rpcUri;

  /// The `http(s)://…` origin used for `/healthz` probes; null for relay
  /// paths (relay probing is a broker join, not an HTTP GET).
  Uri? get probeUri;
}

/// The server on this same machine (thick desktop / dev loop).
class LoopbackPath extends ConnectionPath {
  /// Creates a loopback path on [port].
  const LoopbackPath({required this.port});

  /// JSON tag.
  static const tag = 'lo';

  /// The loopback TCP port.
  final int port;

  @override
  int get rank => 0;

  @override
  bool get isDirect => true;

  @override
  Uri? get rpcUri => Uri.parse('ws://127.0.0.1:$port/rpc');

  @override
  Uri? get probeUri => Uri.parse('http://127.0.0.1:$port');

  @override
  Map<String, dynamic> toJson() => {'t': tag, 'port': port};

  @override
  bool operator ==(Object other) => other is LoopbackPath && other.port == port;

  @override
  int get hashCode => Object.hash(tag, port);
}

/// A private-network address (manual IP or mDNS-resolved LAN name).
class LanPath extends ConnectionPath {
  /// Creates a LAN path.
  const LanPath({required this.host, required this.port, required this.tls});

  /// JSON tag.
  static const tag = 'lan';

  /// Host name or IP on the local network.
  final String host;

  /// TCP port.
  final int port;

  /// Whether the endpoint serves TLS.
  final bool tls;

  @override
  int get rank => 1;

  @override
  bool get isDirect => true;

  @override
  Uri? get rpcUri => Uri.parse('${tls ? 'wss' : 'ws'}://$host:$port/rpc');

  @override
  Uri? get probeUri => Uri.parse('${tls ? 'https' : 'http'}://$host:$port');

  @override
  Map<String, dynamic> toJson() => {
    't': tag,
    'h': host,
    'port': port,
    'tls': tls,
  };

  @override
  bool operator ==(Object other) =>
      other is LanPath &&
      other.host == host &&
      other.port == port &&
      other.tls == tls;

  @override
  int get hashCode => Object.hash(tag, host, port, tls);
}

/// A tailnet (Tailscale MagicDNS) address, reachable when the client machine
/// is joined to the same tailnet.
class TailnetPath extends ConnectionPath {
  /// Creates a tailnet path.
  const TailnetPath({
    required this.host,
    required this.port,
    required this.tls,
  });

  /// JSON tag.
  static const tag = 'ts';

  /// MagicDNS host name (e.g. `myserver.tail1234.ts.net`).
  final String host;

  /// TCP port.
  final int port;

  /// Whether the endpoint serves TLS.
  final bool tls;

  @override
  int get rank => 2;

  @override
  bool get isDirect => true;

  @override
  Uri? get rpcUri => Uri.parse('${tls ? 'wss' : 'ws'}://$host:$port/rpc');

  @override
  Uri? get probeUri => Uri.parse('${tls ? 'https' : 'http'}://$host:$port');

  @override
  Map<String, dynamic> toJson() => {
    't': tag,
    'h': host,
    'port': port,
    'tls': tls,
  };

  @override
  bool operator ==(Object other) =>
      other is TailnetPath &&
      other.host == host &&
      other.port == port &&
      other.tls == tls;

  @override
  int get hashCode => Object.hash(tag, host, port, tls);
}

/// A public TLS WebSocket endpoint (VPS, or a managed tunnel's stable URL).
class WssPath extends ConnectionPath {
  /// Creates a wss path from a full `wss://host[:port][/path]` URI string.
  const WssPath({required this.uri});

  /// JSON tag.
  static const tag = 'wss';

  /// Full `wss://…` URI (path defaults to `/rpc` when empty).
  final String uri;

  @override
  int get rank => 3;

  @override
  bool get isDirect => true;

  @override
  Uri? get rpcUri {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) {
      return null;
    }
    return parsed.path.isEmpty || parsed.path == '/'
        ? parsed.replace(path: '/rpc')
        : parsed;
  }

  @override
  Uri? get probeUri {
    final parsed = rpcUri;
    if (parsed == null) {
      return null;
    }
    return parsed.replace(
      scheme: parsed.scheme == 'wss' ? 'https' : 'http',
      path: '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {'t': tag, 'u': uri};

  @override
  bool operator ==(Object other) => other is WssPath && other.uri == uri;

  @override
  int get hashCode => Object.hash(tag, uri);
}

/// The broker-relayed path: both sides dial out to the signaling broker and
/// exchange end-to-end PSK-sealed frames — the guaranteed NAT-traversal
/// fallback (the broker never sees plaintext or the PSK).
class RelayPath extends ConnectionPath {
  /// Creates a relay path through [signalingUrl]'s broker in [room].
  const RelayPath({required this.signalingUrl, required this.room});

  /// JSON tag.
  static const tag = 'rly';

  /// The signaling broker WebSocket URL (`wss://…`).
  final String signalingUrl;

  /// The server's relay room id (high-entropy, stable per server).
  final String room;

  @override
  int get rank => 4;

  @override
  bool get isDirect => false;

  @override
  Uri? get rpcUri => null;

  @override
  Uri? get probeUri => null;

  @override
  Map<String, dynamic> toJson() => {'t': tag, 's': signalingUrl, 'r': room};

  @override
  bool operator ==(Object other) =>
      other is RelayPath &&
      other.signalingUrl == signalingUrl &&
      other.room == room;

  @override
  int get hashCode => Object.hash(tag, signalingUrl, room);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
