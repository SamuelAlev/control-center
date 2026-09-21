import 'dart:io';

import 'package:cc_server_core/src/builtin_credentials.dart';
import 'package:cc_server_core/src/dotenv.dart';

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

/// Resolved configuration for the headless server (CLI args override env override defaults).
///
/// * `--data-dir` / `CC_SERVER_DATA_DIR` — SQLite DB + secrets dir (default `<cwd>/.cc_server`).
/// * `--port` / `CC_SERVER_PORT` — TCP port (default 9030).
/// * `--bind` / `CC_SERVER_BIND` — `loopback` (default) or `any` (requires TLS in `LocalRpcServer`).
/// * `--repo-roots` / `CC_SERVER_REPO_ROOTS` — browse roots for registering checkouts (default home; never above).
/// * `--public-url` / `CC_SERVER_PUBLIC_URL` — RPC WebSocket URL advertised by `pairing.mint` (set explicitly behind NAT/proxy).
/// * `--allowed-origins` / `CC_SERVER_ALLOWED_ORIGINS` — browser CORS origins (default [CcServerConfig.defaultAllowedOrigins]; loopback/native always allowed).
/// * `--tls-cert`/`CC_SERVER_TLS_CERT` + `--tls-key`/`CC_SERVER_TLS_KEY` — PEM paths for in-process `wss://` (both required).
/// * `--log-level` / `CC_SERVER_LOG_LEVEL` — `debug`/`info`/`warning`(default)/`error`; booting/ready lines always print.
/// * `--sandbox` / `CC_SERVER_SANDBOX` — `on`(default)/`off`; OS-native agent sandbox kill switch.
/// * `--code-index` / `CC_SERVER_CODE_INDEX` — `on`(default)/`off`; background code-graph indexing kill switch.
/// * `--code-index-defer` / `CC_SERVER_CODE_INDEX_DEFER` — seconds to hold first reconcile after ready (default 15, 0..300).
/// * `--tool-deferral` / `CC_SERVER_TOOL_DEFERRAL` — `on`(default)/`off`; `off` makes every admitted tool resident.
/// * `--insecure` / `CC_SERVER_INSECURE` — allow non-loopback plaintext; only behind a TLS-terminating proxy (ignored when TLS set).
///
/// Credentials are **environment-only** (`ps` can read argv): `GOOGLE_OAUTH_CLIENT_ID`/`SECRET`, `KLIPY_APP_KEY`,
/// `GITHUB_APP_ID`/`PRIVATE_KEY`, `GITHUB_CLIENT_ID`, `LINEAR_CLIENT_ID`/`SECRET`, `LINEAR_API_KEY`. Each falls back
/// to a release build-in (`builtin_credentials.dart`); empty disables the feature. Only `GITHUB_CLIENT_ID` may be baked in —
/// private key and Linear secret must not. Provider apps seed `ProviderAppSettings` once at boot, then the store wins.
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
    this.toolDeferralEnabled = true,
    this.credentialGateSeconds = 900,
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

  /// Google OAuth device-code client id (`GOOGLE_OAUTH_CLIENT_ID`, else built-in).
  /// Empty disables calendar sync. Also used by "use Control Center's Google app".
  final String googleClientId;

  /// Device-code client secret (`GOOGLE_OAUTH_CLIENT_SECRET`, else built-in). Never leaves the server.
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

  /// OS-native agent sandbox when available (`--sandbox` / `CC_SERVER_SANDBOX`, default on).
  /// Opt-out only: without a backend (Windows / missing tools) runs use env sanitization + policy.
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

  /// Whether harness runs defer the schemas of tools they are unlikely to need.
  /// From `--tool-deferral` / `CC_SERVER_TOOL_DEFERRAL` (`on`/`off`, default
  /// on). Off makes every admitted tool resident — the pre-deferral request,
  /// byte for byte.
  final bool toolDeferralEnabled;

  /// Seconds a run waits for a fixable credential before failing (`--credential-gate`, default 900, 0..3600).
  /// `0` never parks; the ceiling keeps unattended runs from waiting forever.
  final int credentialGateSeconds;

  /// Klipy GIF app key (`KLIPY_APP_KEY`, else built-in). Empty disables `gif.*` ops.
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

  /// Resolves config from [args] + the process environment, with a `.env` in
  /// the working directory layered under it.
  ///
  /// [environment] overrides both, for tests.
  static CcServerConfig resolve(
    List<String> args, {
    Map<String, String>? environment,
  }) {
    final flags = _parseFlags(args);
    final env = environment ?? environmentWithDotenv();

    String? pick(String flag, String envKey) => flags[flag] ?? env[envKey];

    /// Env-only credential (`ps` can read argv). Empty/unset both mean absent so a built-in can apply.
    String? pickCredential(String envKey) {
      final value = env[envKey]?.trim();
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
    // Environment > the credential baked in at release build time. A
    // self-hoster's own Google Cloud client therefore wins over ours.
    final googleClientId =
        pickCredential('GOOGLE_OAUTH_CLIENT_ID') ?? builtinGoogleClientId;
    final googleClientSecret =
        pickCredential('GOOGLE_OAUTH_CLIENT_SECRET') ??
        builtinGoogleClientSecret;
    final allowedOrigins = _parseOrigins(
      pick('allowed-origins', 'CC_SERVER_ALLOWED_ORIGINS'),
    );
    final klipyAppKey = pickCredential('KLIPY_APP_KEY') ?? builtinKlipyAppKey;
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
    final toolDeferralEnabled =
        (pick('tool-deferral', 'CC_SERVER_TOOL_DEFERRAL') ?? 'on')
            .trim()
            .toLowerCase() !=
        'off';
    final credentialGateSeconds =
        (int.tryParse(
                  pick('credential-gate', 'CC_SERVER_CREDENTIAL_GATE') ?? '',
                ) ??
                900)
            .clamp(0, 3600);
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
      toolDeferralEnabled: toolDeferralEnabled,
      credentialGateSeconds: credentialGateSeconds,
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
