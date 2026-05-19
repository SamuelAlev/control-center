import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/connection_descriptor.dart';

/// The compact JSON payload encoded into the pairing QR's URL fragment.
///
/// Deep-link shape: `https://<pwa-host>/#<base64url(payload)>`. Because the
/// payload rides in the **fragment**, the PWA's HTTPS host (Cloudflare Pages)
/// never sees it — the browser keeps fragments client-side. The PWA reads
/// `location.hash`, decodes this, persists a `PairingRecord` to IndexedDB,
/// then `history.replaceState`-strips the fragment so the PSK leaves the URL.
///
/// Version 2 (PRD 15): the payload carries the server's full
/// [ConnectionDescriptor] — every known path (loopback/LAN/tailnet/wss/relay)
/// plus the identity fingerprint — instead of a single transport address. The
/// client's `ReachabilityResolver` picks the best reachable path at connect
/// time and the embedded fingerprint seeds the TOFU pin.
///
/// Fields are single-letter keys to keep the QR compact:
///  - `v` payload version (2)
///  - `d` the connection descriptor's compact JSON map
///  - `i` the minted device id
///  - `k` PSK (32-byte base64url)
///  - `x` expiry (epoch milliseconds; the QR is short-lived, ~5 min)
class PairingPayload {
  /// Creates a [PairingPayload].
  PairingPayload({
    required this.descriptor,
    required this.deviceId,
    required this.psk,
    required this.expiresAt,
    this.version = currentVersion,
  });

  /// Deserializes a [PairingPayload] from its compact JSON form.
  ///
  /// Only version-2 payloads exist (the v1 webrtc/relay shape was deleted
  /// with the topology-agnostic connectivity rewrite — pre-1.0, no
  /// compatibility). A payload without a valid descriptor map throws
  /// [FormatException]; callers treat that as "not a pairing payload".
  factory PairingPayload.fromJson(Map<String, dynamic> json) {
    final d = json['d'];
    if (d is! Map) {
      throw const FormatException('Pairing payload has no descriptor');
    }
    return PairingPayload(
      version: (json['v'] as num?)?.toInt() ?? currentVersion,
      descriptor: ConnectionDescriptor.fromJson(d.cast<String, dynamic>()),
      deviceId: json['i'] as String? ?? '',
      psk: json['k'] as String? ?? '',
      expiresAt: json['x'] is num
          ? DateTime.fromMillisecondsSinceEpoch((json['x'] as num).toInt())
          : DateTime.now(),
    );
  }

  /// Current payload version.
  static const int currentVersion = 2;

  /// The hosted PWA origin the pairing QR points phones at when the operator
  /// hasn't configured one. The desktop's `RemoteControlConfig` defaults its
  /// `pwaHost` to this; point it at a self-hosted origin to override.
  static const String defaultPwaHost = 'remote.usectrl.dev';

  /// Payload version.
  final int version;

  /// The server's full connection descriptor: every known path plus the
  /// identity fingerprint (the client's initial TOFU pin).
  final ConnectionDescriptor descriptor;

  /// The minted device id (sent in the client's auth handshake).
  final String deviceId;

  /// PSK (base64url, no padding).
  final String psk;

  /// When this pairing offer expires.
  final DateTime expiresAt;

  /// Serializes to the compact JSON form.
  Map<String, dynamic> toJson() => {
    'v': version,
    'd': descriptor.toJson(),
    'i': deviceId,
    'k': psk,
    'x': expiresAt.millisecondsSinceEpoch,
  };

  /// Base64url-encodes the JSON payload (no padding) for the URL fragment.
  String encode() {
    final json = jsonEncode(toJson());
    return base64UrlEncode(utf8.encode(json)).replaceAll('=', '');
  }

  /// Decodes a base64url payload string (with or without padding).
  static PairingPayload decode(String encoded) {
    final normalized = base64Url.normalize(encoded);
    final bytes = base64Url.decode(normalized);
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return PairingPayload.fromJson(json);
  }

  /// Builds the `<scheme>://<pwaHost>/#<payload>` pairing deep link.
  ///
  /// [pwaHost] is normally a bare host (`remote.example.com`,
  /// `localhost:8081`). Scheme is inferred: `http` for loopback hosts —
  /// `http://localhost` / `127.0.0.1` / `[::1]` are secure contexts and a local
  /// `flutter run -d chrome` dev server has no TLS — and `https` for everything
  /// else (service workers and IndexedDB are secure-context-gated on real
  /// hosts). If [pwaHost] already carries an `http(s)://` scheme it is used
  /// verbatim, so a full origin works too.
  String toDeepLink(String pwaHost) {
    final host = pwaHost.trim();
    final String origin;
    if (host.startsWith('http://') || host.startsWith('https://')) {
      origin = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    } else {
      origin = '${_isLoopbackHost(host) ? 'http' : 'https'}://$host';
    }
    return '$origin/#${encode()}';
  }

  /// Whether [host] (a bare `host[:port]`) points at the local machine, which
  /// browsers treat as a secure context even over plain `http`.
  static bool _isLoopbackHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'localhost' ||
        lower.startsWith('localhost:') ||
        lower.startsWith('127.0.0.1') ||
        lower == '::1' ||
        lower.startsWith('[::1]');
  }

  /// Whether this pairing offer has passed its [expiresAt].
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
