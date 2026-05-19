import 'dart:io';

import 'package:cc_server_core/src/builtin_credentials.dart';

/// Minimum log severity the server emits. Ordered most-to-least chatty so
/// `a.index >= b.index` means "a is at least as severe as b".
enum CcServerLogLevel {
  /// Everything, including per-request dio traces and no-op sweep lines.
  debug,

  /// Lifecycle and status messages.
  info,

  /// Warnings and errors only (the default).
  warning,

  /// Errors only.
  error,
}

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
///    device-code client id used to connect + sync Google Calendar. Falls back
///    to the client baked into a release build; empty (neither set nor baked in)
///    disables calendar sync.
///  * `--google-client-secret` / `CC_GOOGLE_OAUTH_CLIENT_SECRET` — the secret
///    for that device-code client, with the same built-in fallback.
///  * `--klipy-app-key` / `CC_KLIPY_APP_KEY` — the Klipy GIF app key, with the
///    same built-in fallback. Empty disables the `gif.*` ops.
///  * `--tls-cert` / `CC_SERVER_TLS_CERT` + `--tls-key` / `CC_SERVER_TLS_KEY`
///    — PEM cert-chain + private-key paths. When BOTH are set the server
///    serves `wss://` directly (a public bind needs TLS); a real deployment
///    behind a TLS-terminating proxy leaves them unset and uses `--insecure`.
///  * `--log-level` / `CC_SERVER_LOG_LEVEL` — minimum severity emitted to
///    stdio + the rotating file log: `debug`, `info`, `warning` (default),
///    or `error`. `debug` opens the trace tier the façades suppress by
///    default (e.g. dio request/response lines, a code-graph index run that
///    found nothing to do). The booting/ready lines are always printed
///    regardless of level — a silent process reads as a hung one.
///  * `--sandbox` / `CC_SERVER_SANDBOX` — `on` (default) or `off`. Whether
///    agent runs are wrapped in the host's OS-native sandbox (Seatbelt on
///    macOS, bubblewrap on Linux/WSL2) when one is available. `off` is the
///    field kill switch for a host where the sandbox profile misbehaves.
///  * `--code-index` / `CC_SERVER_CODE_INDEX` — `on` (default) or `off`. The
///    field kill switch for background code-graph indexing: a host where
///    indexing misbehaves boots clean without a rebuild.
///  * `--code-index-defer` / `CC_SERVER_CODE_INDEX_DEFER` — seconds to hold
///    the first code-graph reconcile after the server reports ready (default
///    15, clamped 0..300), keeping the initial index sweep out of the
///    client's first RPC burst.
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
    this.webClientUrl = '',
    this.tlsCertPath = '',
    this.tlsKeyPath = '',
    this.allowInsecure = false,
    this.logLevel = CcServerLogLevel.warning,
    this.sandboxEnabled = true,
    this.codeIndexEnabled = true,
    this.codeIndexDeferSeconds = 15,
    this.klipyAppKey = '',
    this.serverName = '',
    this.mdnsMode = 'auto',
    this.tunnelProvider = 'off',
    this.tunnelBinaryPath = '',
    this.tunnelBinarySha256 = '',
    this.tunnelExtraArgs = const [],
  });

  /// The browser origin of the hosted web client (`https://app.example.com`),
  /// from `--web-client-url` / `CC_SERVER_WEB_CLIENT_URL`. SSO callbacks
  /// bounce the browser here with the minted credential in the URL fragment
  /// (fragments never reach the static host's logs); empty keeps the handoff
  /// same-origin, which only lands when this server serves the web bundle
  /// itself.
  final String webClientUrl;

  /// The hosted signaling broker used when `--signaling-url` is unset, so phone
  /// pairing works out of the box. This is what the connection descriptor's
  /// relay path advertises (and what pairing QRs therefore embed).
  static const String defaultSignalingUrl = 'wss://signaling.usectrl.dev';

  /// The browser origin(s) a hosted web build is served from, so a thin web
  /// client can dial this server directly out of the box. Loopback
  /// (`localhost` / `127.0.0.1`) is always allowed in addition to this set.
  static const List<String> defaultAllowedOrigins = ['https://app.usectrl.dev'];

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
  /// `CC_GOOGLE_OAUTH_CLIENT_ID`, else the client baked into a release build.
  /// Empty disables the calendar sync (the `calendar connect` command and the
  /// periodic sync both no-op).
  ///
  /// This is also the client the "use Control Center's Google app" option
  /// connects with, so a self-hoster who sets their own here gets *their* app
  /// behind that option rather than ours.
  final String googleClientId;

  /// The client secret for the device-code client. From
  /// `--google-client-secret` / `CC_GOOGLE_OAUTH_CLIENT_SECRET`, else the one
  /// baked into a release build. It never leaves the server: no RPC response
  /// carries it and a built-in connection stores a marker rather than the
  /// literal pair.
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

  /// Minimum severity emitted to stdio + the rotating file log. From
  /// `--log-level` / `CC_SERVER_LOG_LEVEL` (`debug` / `info` / `warning` /
  /// `error`, default `warning`). `debug` opens the trace tier the façades
  /// suppress by default (dio request/response lines, no-op index sweeps).
  /// The booting/ready lines bypass this — they always print.
  final CcServerLogLevel logLevel;

  /// Whether agent runs are wrapped in the host's OS-native sandbox when one
  /// is available. From `--sandbox` / `CC_SERVER_SANDBOX` (`on`/`off`, default
  /// on).
  ///
  /// This is an *opt-out*, not an enable: the host still has to offer a
  /// backend (`sandbox-exec` on macOS, `bwrap` + `socat` on Linux/WSL2). Where
  /// it does not — Windows, or a Linux box without those tools — agent runs
  /// fall back to environment sanitization, the command policy and the action
  /// guardrails, exactly as before. The switch exists so a host where the
  /// sandbox profile itself misbehaves can boot clean without a rebuild.
  final bool sandboxEnabled;

  /// Whether background code-graph indexing runs at all. From `--code-index`
  /// / `CC_SERVER_CODE_INDEX` (`on`/`off`, default on). The field kill switch
  /// for exactly the failure class indexing has caused before (boot-time
  /// stalls): a host where it misbehaves boots clean without a rebuild and
  /// it is how an indexing-caused boot problem is bisected in place.
  final bool codeIndexEnabled;

  /// Seconds the code-graph watch service holds its first reconcile after the
  /// server reports ready. From `--code-index-defer` /
  /// `CC_SERVER_CODE_INDEX_DEFER` (default 15, clamped 0..300). Keeps the
  /// initial index sweep out of the desktop's first RPC burst; `0` makes the
  /// deferral deterministic in tests.
  final int codeIndexDeferSeconds;

  /// The Klipy GIF app key the server uses for the `gif.*` ops (the GIF picker
  /// in the PR/review composer). From `--klipy-app-key` / `CC_KLIPY_APP_KEY`,
  /// else the key baked into a release build. Empty disables the `gif.*` ops
  /// (the picker then shows no results).
  final String klipyAppKey;

  /// Human-readable server name shown in pickers, discovery and pairing
  /// surfaces. From `--server-name` / `CC_SERVER_NAME`; empty ⇒ the identity
  /// store falls back to the machine hostname.
  final String serverName;

  /// mDNS LAN advertisement (PRD 15 §7): `auto` (advertise only when bound
  /// beyond loopback — a loopback server is not reachable from the LAN
  /// anyway), `on`, or `off`. From `--mdns` / `CC_SERVER_MDNS`. Discovery
  /// only advertises existence; joining still requires an invite + pairing.
  final String mdnsMode;

  /// Managed tunnel provider for "Share this server" (PRD 15 §5): `off`
  /// (default — public exposure is explicit opt-in), `cloudflared`, `ngrok`,
  /// or `tailscale`. From `--tunnel` / `CC_SERVER_TUNNEL`.
  final String tunnelProvider;

  /// Explicit tunnel binary path (else resolved from PATH). From
  /// `--tunnel-binary` / `CC_SERVER_TUNNEL_BINARY`.
  final String tunnelBinaryPath;

  /// Expected SHA-256 of the tunnel binary. When set, the binary is hashed
  /// and verified BEFORE every spawn — tunnel binaries are supply chain with
  /// network authority (PRD 15 adversarial note). From `--tunnel-sha256` /
  /// `CC_SERVER_TUNNEL_SHA256`.
  final String tunnelBinarySha256;

  /// Extra args appended to the tunnel invocation (e.g. a named cloudflared
  /// tunnel). From `--tunnel-args` / `CC_SERVER_TUNNEL_ARGS`
  /// (comma-separated).
  final List<String> tunnelExtraArgs;

  /// Whether mDNS advertising should run, resolving `auto` against the bind.
  bool get mdnsEnabled => switch (mdnsMode) {
    'on' => true,
    'off' => false,
    _ => bindAny,
  };

  /// Whether a managed tunnel is configured (explicit opt-in).
  bool get tunnelConfigured => tunnelProvider != 'off';

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

    String? pick(String flag, String envKey) => flags[flag] ?? env[envKey];

    /// [pick], but an explicitly-empty value reads as absent so a built-in
    /// default still applies (an unset variable and `CC_X=` should behave the
    /// same — an empty override is a deployment mistake, not a choice to run
    /// without the credential).
    String? pickCredential(String flag, String envKey) {
      final value = pick(flag, envKey)?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final dataDirRaw =
        pick('data-dir', 'CC_SERVER_DATA_DIR') ?? _defaultDataDir(env);
    // Absolutize: agents spawn with an absolute cwd (their overlay/worktree),
    // so a RELATIVE data dir would make derived paths (`--mcp-config`, the
    // `repos` symlink) be re-resolved against the agent's cwd and double the
    // path (e.g. `<cwd>/data/<ws>/agents/<slug>/.mcp.json` → file not found).
    final dataDir = Directory(dataDirRaw).absolute.path;
    final port = int.tryParse(pick('port', 'CC_SERVER_PORT') ?? '') ?? 9030;
    final bind = (pick('bind', 'CC_SERVER_BIND') ?? 'loopback').toLowerCase();
    final repoRoots = _parseRoots(pick('repo-roots', 'CC_SERVER_REPO_ROOTS'));
    final bindAny = bind == 'any' || bind == 'all' || bind == '0.0.0.0';
    final publicUrlRaw = pick('public-url', 'CC_SERVER_PUBLIC_URL')?.trim();
    final publicUrl = (publicUrlRaw != null && publicUrlRaw.isNotEmpty)
        ? publicUrlRaw
        : _defaultPublicUrl(port, bindAny: bindAny);
    final signalingRaw = pick(
      'signaling-url',
      'CC_SERVER_SIGNALING_URL',
    )?.trim();
    final signalingUrl = (signalingRaw != null && signalingRaw.isNotEmpty)
        ? signalingRaw
        : defaultSignalingUrl;
    final webClientUrl = pick(
      'web-client-url',
      'CC_SERVER_WEB_CLIENT_URL',
    )?.trim();
    // Flag > environment > the credential baked in at release build time. A
    // self-hoster's own Google Cloud client therefore always wins over ours.
    final googleClientId =
        pickCredential('google-client-id', 'CC_GOOGLE_OAUTH_CLIENT_ID') ??
        builtinGoogleClientId;
    final googleClientSecret =
        pickCredential(
          'google-client-secret',
          'CC_GOOGLE_OAUTH_CLIENT_SECRET',
        ) ??
        builtinGoogleClientSecret;
    final allowedOrigins = _parseOrigins(
      pick('allowed-origins', 'CC_SERVER_ALLOWED_ORIGINS'),
    );
    final klipyAppKey =
        pickCredential('klipy-app-key', 'CC_KLIPY_APP_KEY') ??
        builtinKlipyAppKey;
    final tlsCertPath = pick('tls-cert', 'CC_SERVER_TLS_CERT')?.trim() ?? '';
    final tlsKeyPath = pick('tls-key', 'CC_SERVER_TLS_KEY')?.trim() ?? '';
    final allowInsecure = _parseBool(pick('insecure', 'CC_SERVER_INSECURE'));
    final logLevel = switch ((pick('log-level', 'CC_SERVER_LOG_LEVEL') ?? '')
        .trim()
        .toLowerCase()) {
      'debug' => CcServerLogLevel.debug,
      'info' => CcServerLogLevel.info,
      'warning' || 'warn' => CcServerLogLevel.warning,
      'error' => CcServerLogLevel.error,
      // Empty (unset) and unrecognised values fall back to the warning
      // default.
      _ => CcServerLogLevel.warning,
    };
    final sandboxEnabled =
        (pick('sandbox', 'CC_SERVER_SANDBOX') ?? 'on').trim().toLowerCase() !=
        'off';
    final codeIndexEnabled =
        (pick('code-index', 'CC_SERVER_CODE_INDEX') ?? 'on')
            .trim()
            .toLowerCase() !=
        'off';
    final codeIndexDeferSeconds =
        (int.tryParse(
                  pick('code-index-defer', 'CC_SERVER_CODE_INDEX_DEFER') ?? '',
                ) ??
                15)
            .clamp(0, 300);
    final serverName = pick('server-name', 'CC_SERVER_NAME')?.trim() ?? '';
    final mdnsMode = switch ((pick('mdns', 'CC_SERVER_MDNS') ?? 'auto')
        .trim()
        .toLowerCase()) {
      'on' || 'true' || '1' => 'on',
      'off' || 'false' || '0' => 'off',
      _ => 'auto',
    };
    final tunnelProvider = switch ((pick('tunnel', 'CC_SERVER_TUNNEL') ?? 'off')
        .trim()
        .toLowerCase()) {
      'cloudflared' => 'cloudflared',
      'ngrok' => 'ngrok',
      'tailscale' => 'tailscale',
      _ => 'off',
    };
    final tunnelBinaryPath =
        pick('tunnel-binary', 'CC_SERVER_TUNNEL_BINARY')?.trim() ?? '';
    final tunnelBinarySha256 =
        pick(
          'tunnel-sha256',
          'CC_SERVER_TUNNEL_SHA256',
        )?.trim().toLowerCase() ??
        '';
    final tunnelExtraArgs = (pick('tunnel-args', 'CC_SERVER_TUNNEL_ARGS') ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

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
      webClientUrl: webClientUrl ?? '',
      tlsCertPath: tlsCertPath,
      tlsKeyPath: tlsKeyPath,
      allowInsecure: allowInsecure,
      logLevel: logLevel,
      sandboxEnabled: sandboxEnabled,
      codeIndexEnabled: codeIndexEnabled,
      codeIndexDeferSeconds: codeIndexDeferSeconds,
      klipyAppKey: klipyAppKey,
      serverName: serverName,
      mdnsMode: mdnsMode,
      tunnelProvider: tunnelProvider,
      tunnelBinaryPath: tunnelBinaryPath,
      tunnelBinarySha256: tunnelBinarySha256,
      tunnelExtraArgs: tunnelExtraArgs,
    );
  }

  /// Default data dir when neither `--data-dir` nor `CC_SERVER_DATA_DIR` is
  /// set: the platform's per-user application-data directory, so a standalone
  /// `cc_server` never scatters a `.cc_server` folder into whatever working
  /// directory it happened to launch from (which pollutes the source tree and
  /// IDE index during development). The desktop always passes `--data-dir`
  /// explicitly, so this only affects headless/manual runs. Falls back to a
  /// cwd-relative `.cc_server` only when the home/appdata dir can't be resolved.
  static String _defaultDataDir(Map<String, String> env) {
    const appName = 'control-center';
    String? base;
    if (Platform.isWindows) {
      base = env['APPDATA'] ?? env['LOCALAPPDATA'];
    } else if (Platform.isMacOS) {
      final home = env['HOME'];
      base = home == null ? null : '$home/Library/Application Support';
    } else {
      // Linux / other: XDG_DATA_HOME, else ~/.local/share.
      base = env['XDG_DATA_HOME'];
      if (base == null || base.isEmpty) {
        final home = env['HOME'];
        base = home == null ? null : '$home/.local/share';
      }
    }
    if (base == null || base.isEmpty) {
      return '${Directory.current.path}${Platform.pathSeparator}.cc_server';
    }
    return '$base${Platform.pathSeparator}$appName';
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
