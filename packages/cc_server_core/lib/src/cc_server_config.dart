import 'dart:io';

/// Resolved configuration for the headless server, from CLI args + environment.
///
/// Args (`--key value` or `--key=value`) override environment, which overrides
/// defaults:
///  * `--data-dir` / `CC_SERVER_DATA_DIR` — where the SQLite DB + secrets live.
///    Defaults to `<cwd>/.cc_server`.
///  * `--port` / `CC_SERVER_PORT` — TCP port (default 9030).
///  * `--bind` / `CC_SERVER_BIND` — `loopback` (default) or `any`. `any` exposes
///    the server beyond localhost and `LocalRpcServer` then requires TLS.
///  * `--repo-roots` / `CC_SERVER_REPO_ROOTS` — comma-separated base directories
///    a connected (web) client may browse when picking a git checkout to
///    register. Defaults to the OS user's home directory. Browsing above a root
///    is refused, so this is the only filesystem a client can enumerate.
///  * `--public-url` / `CC_SERVER_PUBLIC_URL` — the RPC WebSocket URL this
///    server advertises to paired clients (handed back by `pairing.mint` so a
///    phone can dial the server directly). Defaults to `ws://localhost:<port>`
///    for a loopback bind and `wss://<hostname>:<port>` for a public bind; a
///    real deployment behind a proxy/NAT MUST set this explicitly.
  ///  * `--allowed-origins` / `CC_SERVER_ALLOWED_ORIGINS` — comma-separated
  ///    browser origins permitted to dial the RPC WebSocket cross-origin (e.g. a
  ///    hosted web build). Defaults to [CcServerConfig.defaultAllowedOrigins]
  ///    (`https://app.usectrl.dev`). Loopback (`localhost` / `127.0.0.1`) and
  ///    native clients are always allowed regardless of this list.
  ///  * `--google-client-id` / `CC_GOOGLE_OAUTH_CLIENT_ID` — the Google OAuth
  ///    device-code client id used to connect + sync Google Calendar. Empty
  ///    disables calendar sync.
  ///  * `--google-client-secret` / `CC_GOOGLE_OAUTH_CLIENT_SECRET` — the secret
  ///    for that confidential device-code client.
  ///  * `--tls-cert` / `CC_SERVER_TLS_CERT` + `--tls-key` / `CC_SERVER_TLS_KEY`
  ///    — PEM cert-chain + private-key paths. When BOTH are set the server
  ///    serves `wss://` directly (a public bind needs TLS); a real deployment
  ///    behind a TLS-terminating proxy leaves them unset and uses `--insecure`.
  ///  * `--insecure` / `CC_SERVER_INSECURE` — allow a non-loopback bind over
  ///    PLAINTEXT (no TLS). Off by default (the server fails closed). Set ONLY
  ///    when a TLS-terminating reverse proxy fronts cc_server on a trusted
  ///    private network — the standard containerised topology. Ignored when TLS
  ///    cert+key are present (TLS always wins).
  class CcServerConfig {
  /// Creates a [CcServerConfig].
  const CcServerConfig({
    required this.dataDir,
    required this.port,
    required this.bindAny,
    required this.repoRoots,
    required this.publicUrl,
    required this.signalingUrl,
    required this.googleClientId,
    required this.googleClientSecret,
    required this.allowedOrigins,
    this.tlsCertPath = '',
    this.tlsKeyPath = '',
    this.allowInsecure = false,
    this.klipyAppKey = '',
  });

  /// The hosted signaling broker used when `--signaling-url` is unset, so phone
  /// pairing works out of the box. Matches the desktop's
  /// `PairingPayload.defaultSignalingUrl` and the phone's fallback.
  static const String defaultSignalingUrl = 'wss://signaling.usectrl.dev';

  /// The browser origin(s) a hosted web build is served from, so a thin web
  /// client can dial this server directly out of the box. Loopback
  /// (`localhost` / `127.0.0.1`) is always allowed in addition to this set.
  static const List<String> defaultAllowedOrigins = [
    'https://app.usectrl.dev',
  ];

  /// Directory holding the SQLite database and the paired-device secrets file.
  final String dataDir;

  /// TCP port to listen on.
  final int port;

  /// Whether to bind all interfaces (`InternetAddress.anyIPv4`) instead of
  /// loopback. Binding `any` without TLS is refused by `LocalRpcServer`.
  final bool bindAny;

  /// Allow-listed base directories a client may browse when adding a repo. A
  /// client can navigate within these but never above them.
  final List<String> repoRoots;

  /// The RPC WebSocket URL this server advertises to paired clients — handed
  /// back by `pairing.mint` so a phone dials the server directly. Resolved from
  /// `--public-url` / `CC_SERVER_PUBLIC_URL`, else defaulted from the bind.
  final String publicUrl;

  /// The signaling broker (`wss://…`) cc_server dials, as a peer, to relay a
  /// phone's RPC when the server is not directly reachable from the phone
  /// (different networks / NAT). The QR advertises the same broker + room so the
  /// phone rendezvous there. From `--signaling-url` / `CC_SERVER_SIGNALING_URL`,
  /// else [defaultSignalingUrl].
  final String signalingUrl;

  /// The Google OAuth **device-code** (TV & limited-input) client id the server
  /// authorizes Google Calendar with. From `--google-client-id` /
  /// `CC_GOOGLE_OAUTH_CLIENT_ID`. Empty disables the calendar sync (the
  /// `calendar connect` command and the periodic sync both no-op).
  final String googleClientId;

  /// The client secret for the confidential device-code client. From
  /// `--google-client-secret` / `CC_GOOGLE_OAUTH_CLIENT_SECRET`. Safe to hold
  /// server-side (the server is a trusted, non-distributed binary).
  final String googleClientSecret;

  /// Browser origins permitted to dial the RPC WebSocket cross-origin (e.g. a
  /// hosted web build). Loopback origins (`localhost` / `127.0.0.1`) and native
  /// clients are always allowed regardless of this set; anything else must be
  /// listed here to connect. From `--allowed-origins` /
  /// `CC_SERVER_ALLOWED_ORIGINS` (comma-separated), else
  /// [defaultAllowedOrigins].
  final Set<String> allowedOrigins;

  /// Path to a PEM certificate chain. When set together with [tlsKeyPath], the
  /// server binds `wss://` (TLS), which a non-loopback bind otherwise requires.
  /// Empty ⇒ no TLS in-process (loopback, or a non-loopback bind via
  /// [allowInsecure] behind a TLS-terminating proxy). From `--tls-cert` /
  /// `CC_SERVER_TLS_CERT`.
  final String tlsCertPath;

  /// Path to the PEM private key matching [tlsCertPath]. From `--tls-key` /
  /// `CC_SERVER_TLS_KEY`.
  final String tlsKeyPath;

  /// Whether to permit a non-loopback bind over PLAINTEXT (no TLS). Off by
  /// default — the server fails closed. Set ONLY when a TLS-terminating reverse
  /// proxy fronts cc_server on a trusted private network (the standard
  /// containerised topology). Ignored when [tlsConfigured]. From `--insecure` /
  /// `CC_SERVER_INSECURE`.
  final bool allowInsecure;

  /// The Klipy GIF app key the server uses for the `gif.*` ops (the GIF picker
  /// in the PR/review composer). From `--klipy-app-key` / `CC_KLIPY_APP_KEY`.
  /// Empty disables the `gif.*` ops (the picker then shows no results).
  final String klipyAppKey;

  /// Whether in-process TLS is configured (both cert + key paths are present).
  bool get tlsConfigured => tlsCertPath.isNotEmpty && tlsKeyPath.isNotEmpty;

  /// Whether Google Calendar sync is configured (a client id is present).
  bool get googleCalendarConfigured => googleClientId.isNotEmpty;

  /// Whether the Klipy GIF picker is configured (an app key is present).
  bool get klipyConfigured => klipyAppKey.isNotEmpty;

  /// The address to bind, derived from [bindAny].
  InternetAddress get bindAddress =>
      bindAny ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;

  /// A human-readable host for log lines.
  String get bindHost => bindAny ? '0.0.0.0' : '127.0.0.1';

  /// Resolves config from [args] + the process environment.
  static CcServerConfig resolve(List<String> args) {
    final flags = _parseFlags(args);
    final env = Platform.environment;

    String? pick(String flag, String envKey) =>
        flags[flag] ?? env[envKey];

    final dataDir =
        pick('data-dir', 'CC_SERVER_DATA_DIR') ??
        '${Directory.current.path}${Platform.pathSeparator}.cc_server';
    final port =
        int.tryParse(pick('port', 'CC_SERVER_PORT') ?? '') ?? 9030;
    final bind = (pick('bind', 'CC_SERVER_BIND') ?? 'loopback').toLowerCase();
    final repoRoots = _parseRoots(pick('repo-roots', 'CC_SERVER_REPO_ROOTS'));
    final bindAny = bind == 'any' || bind == 'all' || bind == '0.0.0.0';
    final publicUrlRaw = pick('public-url', 'CC_SERVER_PUBLIC_URL')?.trim();
    final publicUrl = (publicUrlRaw != null && publicUrlRaw.isNotEmpty)
        ? publicUrlRaw
        : _defaultPublicUrl(port, bindAny: bindAny);
    final signalingRaw = pick('signaling-url', 'CC_SERVER_SIGNALING_URL')?.trim();
    final signalingUrl = (signalingRaw != null && signalingRaw.isNotEmpty)
        ? signalingRaw
        : defaultSignalingUrl;
    final googleClientId =
        pick('google-client-id', 'CC_GOOGLE_OAUTH_CLIENT_ID')?.trim() ?? '';
    final googleClientSecret =
        pick('google-client-secret', 'CC_GOOGLE_OAUTH_CLIENT_SECRET')?.trim() ??
        '';
    final allowedOrigins =
        _parseOrigins(pick('allowed-origins', 'CC_SERVER_ALLOWED_ORIGINS'));
    final klipyAppKey =
        pick('klipy-app-key', 'CC_KLIPY_APP_KEY')?.trim() ?? '';
    final tlsCertPath = pick('tls-cert', 'CC_SERVER_TLS_CERT')?.trim() ?? '';
    final tlsKeyPath = pick('tls-key', 'CC_SERVER_TLS_KEY')?.trim() ?? '';
    final allowInsecure = _parseBool(pick('insecure', 'CC_SERVER_INSECURE'));

    return CcServerConfig(
      dataDir: dataDir,
      port: port,
      bindAny: bindAny,
      repoRoots: repoRoots,
      publicUrl: publicUrl,
      signalingUrl: signalingUrl,
      googleClientId: googleClientId,
      googleClientSecret: googleClientSecret,
      allowedOrigins: allowedOrigins,
      tlsCertPath: tlsCertPath,
      tlsKeyPath: tlsKeyPath,
      allowInsecure: allowInsecure,
      klipyAppKey: klipyAppKey,
    );
  }

  /// Best-effort advertised URL when `--public-url` is unset. Loopback ⇒
  /// `ws://localhost:<port>` (a phone on this machine). A public bind ⇒
  /// `wss://<hostname>:<port>` — only a hint; a server behind a proxy/NAT must
  /// set `--public-url` to its externally-reachable address.
  static String _defaultPublicUrl(int port, {required bool bindAny}) {
    if (!bindAny) {
      return 'ws://localhost:$port/rpc';
    }
    final host = Platform.localHostname.trim();
    final safeHost = host.isEmpty ? 'localhost' : host;
    return 'wss://$safeHost:$port/rpc';
  }

  /// Parses the comma-separated `repo-roots` value, falling back to the OS
  /// user's home directory (or the working directory) when unset/empty.
  static List<String> _parseRoots(String? raw) {
    final roots = (raw ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (roots.isNotEmpty) {
      return roots;
    }
    final env = Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'];
    return [
      if (home != null && home.trim().isNotEmpty)
        home.trim()
      else
        Directory.current.path,
    ];
  }

  /// Parses the comma-separated `allowed-origins` value, falling back to
  /// [defaultAllowedOrigins] when unset/empty. Trims whitespace and any
  /// trailing slash so `https://app.usectrl.dev/` matches the Origin header a
  /// browser sends (`https://app.usectrl.dev`).
  static Set<String> _parseOrigins(String? raw) {
    final parts = (raw ?? '')
        .split(',')
        .map((s) => s.trim())
        .map((s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s)
        .where((s) => s.isNotEmpty)
        .toSet();
    if (parts.isNotEmpty) {
      return parts;
    }
    return defaultAllowedOrigins.toSet();
  }

  /// Parses a boolean flag/env value. A bare `--insecure` flag arrives as
  /// `'true'` (see [_parseFlags]); `CC_SERVER_INSECURE` accepts `1`/`true`/
  /// `yes`/`on` (case-insensitive). Anything else (incl. null) is false.
  static bool _parseBool(String? raw) {
    final v = raw?.trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes' || v == 'on';
  }

  static Map<String, String> _parseFlags(List<String> args) {
    final out = <String, String>{};
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (!a.startsWith('--')) {
        continue;
      }
      final body = a.substring(2);
      final eq = body.indexOf('=');
      if (eq >= 0) {
        out[body.substring(0, eq)] = body.substring(eq + 1);
      } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        out[body] = args[++i];
      } else {
        out[body] = 'true';
      }
    }
    return out;
  }
}
