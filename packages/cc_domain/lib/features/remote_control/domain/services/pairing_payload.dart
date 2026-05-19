import 'dart:convert';

/// The compact JSON payload encoded into the pairing QR's URL fragment.
///
/// Deep-link shape: `https://<pwa-host>/#<base64url(payload)>`. Because the
/// payload rides in the **fragment**, the PWA's HTTPS host (Cloudflare Pages)
/// never sees it — the browser keeps fragments client-side. The PWA reads
/// `location.hash`, decodes this, persists a `PairingRecord` to IndexedDB,
/// then `history.replaceState`-strips the fragment so the PSK leaves the URL.
///
/// Fields are single-letter keys to keep the QR compact:
///  - `v` payload version
///  - `s` signaling broker WebSocket URL
///  - `r` pairing room code
///  - `k` PSK (32-byte base64url)
///  - `i` desktop app-instance id
///  - `t` STUN server URLs
///  - `x` expiry (epoch milliseconds; the QR is short-lived, ~5 min)
class PairingPayload {
  /// Creates a [PairingPayload].
  PairingPayload({
    required this.version,
    required this.signalingUrl,
    required this.room,
    required this.psk,
    required this.appInstanceId,
    required this.stunUrls,
    required this.expiresAt,
    this.mode = modeWebrtc,
  });

  /// Builds a RELAY pairing payload: the phone and cc_server rendezvous in the
  /// broker [room] (which is the device id) and relay E2E-encrypted RPC — no
  /// WebRTC, no STUN, no desktop app-instance. Used when cc_server owns the
  /// connection but is not directly reachable from the phone.
  factory PairingPayload.relay({
    required String signalingUrl,
    required String deviceId,
    required String psk,
    required DateTime expiresAt,
  }) =>
      PairingPayload(
        version: currentVersion,
        signalingUrl: signalingUrl,
        room: deviceId,
        psk: psk,
        appInstanceId: '',
        stunUrls: const <String>[],
        expiresAt: expiresAt,
        mode: modeRelay,
      );

  /// Deserializes a [PairingPayload] from its compact JSON form.
  factory PairingPayload.fromJson(Map<String, dynamic> json) {
    final stun = json['t'];
    return PairingPayload(
      version: (json['v'] as num?)?.toInt() ?? currentVersion,
      signalingUrl: json['s'] as String? ?? '',
      room: json['r'] as String? ?? '',
      psk: json['k'] as String? ?? '',
      appInstanceId: json['i'] as String? ?? '',
      stunUrls: stun is List
          ? stun.map((e) => e.toString()).toList()
          : <String>[],
      expiresAt: json['x'] is num
          ? DateTime.fromMillisecondsSinceEpoch((json['x'] as num).toInt())
          : DateTime.now(),
      mode: json['m'] as String? ?? modeWebrtc,
    );
  }

  /// Transport mode: desktop-owned WebRTC over a broker (the default,
  /// fingerprint-bound DataChannel).
  static const String modeWebrtc = 'webrtc';

  /// Transport mode: cc_server-owned relay — frames are E2E-encrypted and
  /// tunnelled through the broker as `signal` payloads.
  static const String modeRelay = 'relay';

  /// Current payload version.
  static const int currentVersion = 1;

  /// The hosted signaling broker (`wss://…`) used when the operator hasn't
  /// configured one. The desktop's `RemoteControlConfig` defaults its
  /// `signalingUrl` to this (so the QR always carries a working broker) and the
  /// phone falls back to it when a payload omits `s`. Either side can override.
  static const String defaultSignalingUrl = 'wss://signaling.usectrl.dev';

  /// The hosted PWA origin the pairing QR points phones at when the operator
  /// hasn't configured one. The desktop's `RemoteControlConfig` defaults its
  /// `pwaHost` to this; point it at a self-hosted origin to override.
  static const String defaultPwaHost = 'remote.usectrl.dev';

  /// Payload version.
  final int version;

  /// Signaling broker `wss://…` URL.
  final String signalingUrl;

  /// Pairing room code.
  final String room;

  /// PSK (base64url, no padding).
  final String psk;

  /// Desktop app-instance id (the signaling peer id).
  final String appInstanceId;

  /// STUN server URLs.
  final List<String> stunUrls;

  /// When this pairing offer expires.
  final DateTime expiresAt;

  /// Transport mode — [modeWebrtc] (default) or [modeRelay]. Tells the phone
  /// whether to negotiate WebRTC to the desktop or relay through the broker to
  /// cc_server.
  final String mode;

  /// Serializes to the compact JSON form. `m` is omitted for the default WebRTC
  /// mode so existing QRs stay byte-identical.
  Map<String, dynamic> toJson() => {
    'v': version,
    's': signalingUrl,
    'r': room,
    'k': psk,
    'i': appInstanceId,
    't': stunUrls,
    'x': expiresAt.millisecondsSinceEpoch,
    if (mode != modeWebrtc) 'm': mode,
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
  /// `http://localhost` / `127.0.0.1` / `[::1]` are secure contexts, and a local
  /// `flutter run -d chrome` dev server has no TLS — and `https` for everything
  /// else (WebRTC, service workers and IndexedDB are secure-context-gated on
  /// real hosts). If [pwaHost] already carries an `http(s)://` scheme it is used
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
