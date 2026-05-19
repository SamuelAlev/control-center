// Web bootstrap for Control Center.
//
// The web build is the SAME app on another device: it cannot be its own server,
// so it dials a cc-server over WSS and reads/writes through the cc_data remote
// repositories (no local Drift DB). This bootstrap is the web-specific startup —
// a connection gate that, once connected, renders the FULL desktop UI
// (`ControlCenterApp`: sidebar, PR review, every screen) inside a Riverpod
// scope whose overrides install the web-flavoured dependencies (the connected
// RPC client, ephemeral preferences, the keychain secure store, a pre-resolved
// onboarding gate, and the connected workspace as the active one).
//
// Build: `flutter build web` (default entrypoint `lib/main.dart`).
import 'dart:async';
import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/control_center_app.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/storage/web_local_storage_backend.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/guards.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

/// Web bootstrap: install lightweight error handlers, then run the connect-gate
/// root. On a successful connection it renders the full app over the connected
/// RPC client (no Sentry, no background services, no local database — the
/// server owns execution).
Future<void> bootstrapAndRun() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lightweight handlers only — the desktop's Sentry + AppLog server seams pull
  // VM-only dependencies, so web logs to the browser console instead.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error\n$stack');
    return true;
  };

  runApp(const ControlCenterWebApp());

  // index.html ships a first-paint splash (#cc-splash) shown until Flutter
  // mounts. An inline <script> to remove it would be blocked by the strict CSP
  // (script-src has no 'unsafe-inline'), so drop it from Dart on the first
  // frame instead. No-op when the element is absent.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    web.document.getElementById('cc-splash')?.remove();
  });
}

/// One `localStorage`-backed preferences store, shared by the connect gate
/// (boot resolution + save-on-connect) and the connected app's
/// [appPreferencesProvider] override. Sharing it is what makes a connection
/// changed in Settings → server connection the one the next reload reads.
final WebLocalStorageBackend _webBackend = WebLocalStorageBackend();

/// Root of the web build — a Material-free [WidgetsApp] themed by [CcTheme]
/// that hosts the connection gate. Once connected, the gate swaps in the full
/// [ControlCenterApp] (which installs its own `MaterialApp`).
///
/// Owns the theme mode while disconnected: it defaults to following the OS /
/// browser `prefers-color-scheme` ([_WebThemeMode.system]), honours the user's
/// saved override from `localStorage`, and re-resolves when the system
/// appearance changes — so the connect gate matches the host appearance.
class ControlCenterWebApp extends StatefulWidget {
  /// Creates the web app.
  const ControlCenterWebApp({super.key});

  @override
  State<ControlCenterWebApp> createState() => _ControlCenterWebAppState();
}

class _ControlCenterWebAppState extends State<ControlCenterWebApp>
    with WidgetsBindingObserver {
  _WebThemeMode _mode = _WebThemeMode.system;

  @override
  void initState() {
    super.initState();
    // Observe platform brightness so a `system`-mode app re-themes live when the
    // OS / browser switches between light and dark.
    WidgetsBinding.instance.addObserver(this);
    _mode = _loadThemeMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Only `system` mode tracks the OS appearance; light/dark are pinned.
    if (_mode == _WebThemeMode.system && mounted) {
      setState(() {});
    }
  }

  /// Resolves the concrete light/dark tokens for the current mode, reading the
  /// live OS / browser appearance when the mode is `system`.
  CcThemeData _resolveTheme() {
    final dark = switch (_mode) {
      _WebThemeMode.light => false,
      _WebThemeMode.dark => true,
      _WebThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
    return dark ? CcThemeData.dark() : CcThemeData.light();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _resolveTheme();
    return CcTheme(
      data: themeData,
      child: Builder(
        builder: (context) {
          final t = context.designSystem ?? themeData.tokens;
          return WidgetsApp(
            debugShowCheckedModeBanner: false,
            color: t.bgBrandSolid,
            title: 'Control Center',
            // The reused desktop widgets localize their labels, so the web root
            // installs the same l10n delegates the desktop app does — no
            // Material ancestor needed (WidgetsApp wires up Localizations).
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Default UI font = the bundled Manrope (cc_ui host asset, no
            // network), so every descendant Text inherits the brand family.
            // Code text opts into Fira Code explicitly via CcFonts.code.
            textStyle: CcFonts.ui(
              textStyle: CcTypography.body,
            ).copyWith(color: t.textPrimary, decoration: TextDecoration.none),
            // The connect gate is route-agnostic, so it uses `builder` and owns
            // NO Navigator: the gate would otherwise consume browser
            // back/forward (popstate) and momentarily regenerate the connect
            // screen — a flash — while the connected app's go_router is the only
            // thing that should sync with the URL. Once connected, that inner
            // `MaterialApp.router` is the sole routing authority. The host is a
            // `const` widget so this `builder` re-running (e.g. on a theme
            // change) reuses the same element subtree and never remounts the
            // gate / re-triggers the connect flow.
            builder: (context, _) => const _WebGateHost(),
          );
        },
      ),
    );
  }
}

/// Stable host for the connect gate: provides the [Overlay] that the connect
/// form's text fields (selection toolbar/magnifier) and any Cc popovers need,
/// without an app-level Navigator that would sync with the browser URL. Being a
/// `const` widget, it survives `WidgetsApp.builder` re-runs so the gate is never
/// remounted (which would re-trigger the connect flow / flash).
class _WebGateHost extends StatelessWidget {
  const _WebGateHost();

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [OverlayEntry(builder: (_) => const _WebRoot())],
    );
  }
}

class _WebRoot extends StatefulWidget {
  const _WebRoot();

  @override
  State<_WebRoot> createState() => _WebRootState();
}

enum _Phase { disconnected, connecting, connected }

class _WebRootState extends State<_WebRoot> {
  _Phase _phase = _Phase.disconnected;
  String? _error;
  RemoteRpcClient? _client;
  String? _activeWorkspaceId;

  // Pre-filled connection fields (saved creds, overridden by a fresh URL hint).
  _Creds _hints = const _Creds(server: 'ws://localhost:9030/rpc');
  bool _bootResolved = false;

  // Reconnect machinery: the last creds we connected with, whether a drop
  // should auto-reconnect (false after an explicit disconnect), and how many
  // consecutive reconnect attempts have failed.
  _Creds? _lastCreds;
  bool _autoReconnect = true;
  int _reconnectAttempt = 0;
  bool _reconnecting = false;
  StreamSubscription<RemoteChannelState>? _connSub;
  bool _disposed = false;

  /// The persisted connection store — the same one Settings → server connection
  /// reads/writes (URL + device id in `localStorage`, the pairing key in secure
  /// storage), so a change made in Settings is what the next reload resumes.
  late final ServerConnectionStore _store = ServerConnectionStore(
    AppPreferences(_webBackend),
    SecureStore.keychain(),
  );

  static const _maxReconnectAttempts = 6;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// Resolve initial connection fields: saved creds first (so a reload
  /// reconnects), then overlay any fresh URL pairing hint (which wins). If we
  /// have a complete, remember-enabled record, connect straight away.
  Future<void> _boot() async {
    final saved = await _loadSavedCreds();
    final urlHints = _readUrlHints();
    final hints = saved.merge(urlHints);
    if (!mounted) {
      return;
    }
    setState(() {
      _hints = hints;
      _bootResolved = true;
    });
    final hasUrlPairing =
        urlHints.server.isNotEmpty && (urlHints.psk?.isNotEmpty ?? false);
    if (hasUrlPairing) {
      // A fresh, complete pairing deep link → connect with its own values.
      await _connect(
        uri: Uri.parse(urlHints.server),
        deviceId: urlHints.device ?? saved.device ?? 'web-client',
        psk: urlHints.psk!,
      );
    } else if (urlHints.server.isEmpty &&
        urlHints.psk == null &&
        saved.remember &&
        saved.isComplete) {
      // A clean reload with a remembered session → resume it. We never pair a
      // saved key with a URL-provided host; that case falls through to the gate.
      await _connect(
        uri: Uri.parse(saved.server),
        deviceId: saved.device ?? 'web-client',
        psk: saved.psk!,
      );
    }
  }

  Future<void> _connect({
    required Uri uri,
    required String deviceId,
    required String psk,
    bool remember = true,
  }) async {
    await _connSub?.cancel();
    _connSub = null;
    setState(() {
      _phase = _Phase.connecting;
      _error = null;
    });
    try {
      final client = await connectRemoteRpc(
        uri: uri,
        deviceId: deviceId,
        psk: psk,
      );
      final workspaces = RemoteWorkspaceRepository(client);
      final list = await workspaces.list();
      // Land in the persisted last-active workspace (written to localStorage by
      // the in-app workspace switch via ActiveWorkspaceIdNotifier.setActive)
      // when it still exists, else the first workspace. Seed BOTH the RPC
      // client's per-request workspace_id (below) and the UI's initial active id
      // (in setState) with it, so a fresh load lands on the last workspace
      // instead of always the first.
      final persistedWorkspaceId = AppPreferences(
        _webBackend,
      ).getString(activeWorkspaceIdPrefKey);
      String? landingWorkspaceId;
      if (list.isNotEmpty) {
        landingWorkspaceId =
            (persistedWorkspaceId != null &&
                list.any((w) => w.id == persistedWorkspaceId))
            ? persistedWorkspaceId
            : list.first.id;
        await workspaces.setActive(landingWorkspaceId);
      }
      if (!mounted) {
        await client.close();
        return;
      }
      _lastCreds = _Creds(
        server: uri.toString(),
        device: deviceId,
        psk: psk,
        remember: remember,
      );
      _autoReconnect = true;
      _reconnectAttempt = 0;
      _reconnecting = false;
      if (remember) {
        await _saveCreds(_lastCreds!);
      } else {
        await _clearSavedCreds();
      }
      // Reconcile the CSP cookie so the Cloudflare Worker can stamp a
      // host-scoped policy on the next load (see _kProxyOriginCookie). CSP can
      // only tighten, never relax, on a live page, so when the connected
      // cc-server origin changes we reload once — the saved creds make the
      // reload resume straight back into this session.
      final origin = _connectedOrigin(_lastCreds!);
      if (origin.isNotEmpty && origin != _readProxyOriginCookie()) {
        _setProxyOriginCookie(origin);
        if (remember && _readProxyOriginCookie() == origin) {
          // The cookie landed (Secure cookies drop over plain http — e.g. local
          // dev, where no CSP is enforced anyway — so the re-read guard avoids
          // a reload loop there). Tear down and reload; the next boot resumes.
          web.window.location.reload();
          return;
        }
      }
      // Watch for socket drops and auto-reconnect with the same credentials.
      _connSub = client.connectionState.listen((state) {
        if (state == RemoteChannelState.closed) {
          _onChannelClosed();
        }
      });
      setState(() {
        _client = client;
        _activeWorkspaceId = landingWorkspaceId;
        _phase = _Phase.connected;
      });
    } catch (e) {
      await _client?.close();
      if (!mounted) {
        return;
      }
      setState(() {
        _client = null;
        _error = e.toString().replaceFirst('Exception: ', '');
        _phase = _Phase.disconnected;
      });
    }
  }

  /// The socket dropped. If the user did not explicitly disconnect and we have
  /// saved credentials, reconnect with capped exponential backoff; otherwise
  /// fall back to the connect gate with an explanatory message.
  void _onChannelClosed() {
    if (_disposed || !_autoReconnect || _lastCreds == null || _reconnecting) {
      return;
    }
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      if (mounted) {
        setState(() {
          _phase = _Phase.disconnected;
          _error = 'Lost the connection to the server. Tap connect to retry.';
        });
      }
      return;
    }
    _reconnecting = true;
    _reconnectAttempt++;
    final delay = Duration(
      seconds: (1 << (_reconnectAttempt - 1)).clamp(1, 16),
    );
    if (mounted) {
      setState(() => _phase = _Phase.connecting);
    }
    // Hold the in-flight gate (`_reconnecting`) across the whole attempt — only
    // release it in `finally`, so a `closed` event can never start a second
    // reconnect while this one is mid-connect.
    Future.delayed(delay, () async {
      if (_disposed || !_autoReconnect || _lastCreds == null) {
        _reconnecting = false;
        return;
      }
      final c = _lastCreds!;
      try {
        await _connect(
          uri: Uri.parse(c.server),
          deviceId: c.device ?? 'web-client',
          psk: c.psk ?? '',
          remember: c.remember,
        );
      } finally {
        _reconnecting = false;
      }
    });
  }

  Future<void> _disconnect() async {
    _autoReconnect = false;
    await _connSub?.cancel();
    _connSub = null;
    await _client?.close();
    await _clearSavedCreds();
    // Drop the CSP origin cookie so the next load returns to the strict
    // (unpaired) policy — no host is connected to allow-list.
    _clearProxyOriginCookie();
    if (!mounted) {
      return;
    }
    setState(() {
      _client = null;
      _activeWorkspaceId = null;
      _lastCreds = null;
      _phase = _Phase.disconnected;
      _error = null;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _connSub?.cancel();
    _client?.close();
    super.dispose();
  }

  /// Loads the persisted connection from [_store] — the same store the
  /// Settings → server connection section reads/writes — so a reload resumes
  /// the last session (and honours a change made in Settings). Defaults the
  /// server URL when nothing is stored.
  Future<_Creds> _loadSavedCreds() async {
    final config = _store.read();
    final psk = _nonEmpty(await _store.readPsk());
    final configured = _store.isConfigured;
    return _Creds(
      server: config.remoteUrl.isNotEmpty
          ? config.remoteUrl
          : 'ws://localhost:9030/rpc',
      device: configured ? config.remoteDeviceId : 'web-client',
      psk: psk,
      // A stored, complete record with a pairing key is a "remembered" session.
      remember: configured && psk != null,
    );
  }

  /// Persists [c] through [_store] for the next reload (URL + device id in
  /// `localStorage`, the pairing key in secure storage). The PSK is sensitive;
  /// the deploy ships a strict CSP (`web/_headers`) to remove the exfiltration
  /// egress a foothold would need, mirroring the cc_remote PWA.
  Future<void> _saveCreds(_Creds c) async {
    await _store.save(
      ServerConnectionConfig(
        mode: ServerConnectionMode.remote,
        remoteUrl: c.server,
        remoteDeviceId: c.device ?? 'web-client',
      ),
      psk: c.psk,
    );
  }

  /// Forgets the saved connection (so a reload returns to the connect gate).
  Future<void> _clearSavedCreds() => _store.clear();

  /// Builds the media-proxy config from the live connection so remote media
  /// (feed favicons, article thumbnails, avatars, PR-body images/video) load
  /// through the host's `/proxy/media` endpoint — the browser cannot fetch them
  /// cross-origin directly (CORS). Null when the creds are incomplete, leaving
  /// direct loads.
  MediaProxyConfig? _mediaProxyConfig() {
    final creds = _lastCreds;
    if (creds == null) {
      return null;
    }
    final uri = Uri.tryParse(creds.server);
    if (uri == null) {
      return null;
    }
    return MediaProxyConfig.fromConnection(
      serverUri: uri,
      deviceId: creds.device ?? '',
      psk: creds.psk ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: t.bgPrimary,
      child: switch (_phase) {
        _Phase.connected => _ConnectedApp(
          // Rebuild the whole app (fresh ProviderScope) when the connected
          // client or active workspace changes, so the overrides re-resolve.
          key: ValueKey('app-${_activeWorkspaceId ?? '-'}'),
          client: _client!,
          activeWorkspaceId: _activeWorkspaceId,
          mediaProxy: _mediaProxyConfig(),
          onDisconnect: _disconnect,
        ),
        _ when !_bootResolved => const Center(child: CcSpinner()),
        _ => _ConnectGate(
          connecting: _phase == _Phase.connecting,
          reconnecting: _reconnecting || _reconnectAttempt > 0,
          error: _error,
          initial: _hints,
          onConnect: _connect,
        ),
      },
    );
  }
}

/// The connected web app: a Riverpod scope whose overrides install the
/// web-flavoured dependencies, rendering the FULL [ControlCenterApp].
///
/// Overrides:
///  - [rpcClientProvider] → the connected [RemoteRpcClient] (the entire UI's
///    single data entrypoint; on web there is no in-process host default).
///  - [appPreferencesProvider] → a `localStorage`-backed store (shared
///    `_webBackend`), so web preferences survive a reload.
///  - [secureStoreProvider] → flutter_secure_storage, which works on web.
///  - [onboardingGateProvider] → [OnboardingGate.complete]: the connect gate IS
///    onboarding on web, so the router lands on the dashboard, not onboarding.
///  - [activeWorkspaceIdProvider] → bound to the workspace resolved at connect
///    (the persisted last-active one, else the first), so workspace-scoped
///    screens scope to it immediately; switches persist via the inherited
///    setActive. The desktop notifier reads the Drift bootstrap stream, which
///    does not exist on web.
class _ConnectedApp extends StatelessWidget {
  const _ConnectedApp({
    super.key,
    required this.client,
    required this.activeWorkspaceId,
    required this.onDisconnect,
    this.mediaProxy,
  });

  final RemoteRpcClient client;
  final String? activeWorkspaceId;
  final VoidCallback onDisconnect;

  /// Routes remote media (images, favicons, PR-body images/video) through the
  /// host's `/proxy/media` endpoint to defeat browser CORS. Null only when
  /// connection creds are incomplete.
  final MediaProxyConfig? mediaProxy;

  @override
  Widget build(BuildContext context) {
    Widget app = const ControlCenterApp();
    final proxy = mediaProxy;
    if (proxy != null) {
      // Above the whole app so every remote-media widget (newsfeed, avatars,
      // PR body, dialogs/overlays in the same element tree) can resolve it.
      app = MediaProxyScope(config: proxy, child: app);
    }
    return ProviderScope(
      overrides: [
        rpcClientProvider.overrideWithValue(client),
        // localStorage-backed so web preferences (theme, the server connection,
        // …) survive a reload. Shares `_webBackend` with the connect gate's
        // `_store`, so a connection changed in Settings is read on next boot.
        appPreferencesProvider.overrideWithValue(AppPreferences(_webBackend)),
        secureStoreProvider.overrideWithValue(SecureStore.keychain()),
        onboardingGateProvider.overrideWithValue(OnboardingGate.complete),
        activeWorkspaceIdProvider.overrideWith(
          () => _WebActiveWorkspaceIdNotifier(activeWorkspaceId),
        ),
      ],
      child: app,
    );
  }
}

/// Web [ActiveWorkspaceIdNotifier] replacement: the connected workspace is the
/// source of truth, so the active id is fixed up front (the desktop notifier
/// reconciles against a Drift bootstrap stream that does not exist on web). A
/// workspace switch reconnects the whole app, so [setActive] just updates the
/// local state.
class _WebActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  _WebActiveWorkspaceIdNotifier(this._initial);

  final String? _initial;

  @override
  String? build() => _initial;

  // setActive is inherited from the base: it flips state synchronously AND
  // persists to appPreferencesProvider (the localStorage-backed store on web),
  // so an in-app workspace switch is remembered and the next fresh load lands on
  // it (the connect flow reads that persisted id back). The desktop `build()` —
  // which reconciles against the Drift bootstrap stream — is the only piece web
  // can't reuse, hence the `build()` override above and nothing else.
}

/// Theme mode for the connect gate (before the full app installs its own
/// Material theme). [system] follows the OS / browser appearance.
enum _WebThemeMode {
  /// Follow the OS / browser appearance.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark;

  /// Parses a persisted value, defaulting to [system] for null/unknown input.
  static _WebThemeMode fromName(String? value) => switch (value) {
    'light' => _WebThemeMode.light,
    'dark' => _WebThemeMode.dark,
    _ => _WebThemeMode.system,
  };
}

/// A connection record (server URL + device id + PSK) plus whether to remember
/// it across reloads.
class _Creds {
  const _Creds({
    required this.server,
    this.device,
    this.psk,
    this.remember = true,
  });

  final String server;
  final String? device;
  final String? psk;
  final bool remember;

  bool get isComplete => server.isNotEmpty && (psk != null && psk!.isNotEmpty);

  /// Overlays [other]'s non-null fields onto this record (used to let a fresh
  /// URL pairing hint win over saved values).
  _Creds merge(_Creds other) => _Creds(
    server: other.server.isNotEmpty ? other.server : server,
    device: other.device ?? device,
    psk: other.psk ?? psk,
    remember: other.remember && remember,
  );
}

// --- Web connection persistence -------------------------------------------
//
// The connection (server URL + device id + pairing key) is persisted through
// the shared [ServerConnectionStore] (see `_WebRootState._store` /
// `_loadSavedCreds` / `_saveCreds`), the SAME store the Settings → server
// connection section writes — so a change in Settings is what the next reload
// resumes. Only the connect-gate theme override lives in raw `localStorage`.

const _kTheme = 'cc_web.theme';

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

/// Loads the saved theme mode (defaults to following the system appearance).
_WebThemeMode _loadThemeMode() =>
    _WebThemeMode.fromName(web.window.localStorage.getItem(_kTheme));

// --- Connected-origin cookie → host-scoped CSP --------------------------------
//
// The deployed web client is a static SPA served by Cloudflare; its CSP can't
// name the cc-server host until the user connects (the host is typed in the
// connect form, and only then is it known). The Cloudflare Worker
// (worker/csp.js, run_worker_first) reads this cookie on each document request
// and stamps a per-request CSP adding the connected cc-server origin to
// connect-src + img-src — so the CanvasKit `fetch()` to `/proxy/media` is
// allowed for the paired host, and ONLY that host.
//
// The cookie holds ONLY the origin (scheme+host+port) — never the pairing key,
// which stays in secure storage — so it is not sensitive. CSP can only tighten
// (never relax) after a page has loaded, so the first connect on a fresh page
// (no cookie → strict CSP) reloads once; subsequent reloads see the cookie and
// skip the reload, resuming straight into the session.

const _kProxyOriginCookie = 'cc_proxy_origin';

/// The connected cc-server's http(s) origin (scheme+host+port), derived exactly
/// as the media-proxy base URL is (see [MediaProxyConfig.fromConnection]) — so
/// the Worker's allow-list matches the proxy requests 1:1. Empty when the creds
/// are incomplete or the server URL isn't ws/wss.
String _connectedOrigin(_Creds creds) {
  final uri = Uri.tryParse(creds.server);
  if (uri == null) {
    return '';
  }
  return MediaProxyConfig.fromConnection(
        serverUri: uri,
        deviceId: creds.device ?? '',
        psk: creds.psk ?? '',
      )?.httpBase.toString() ??
      '';
}

/// Reads [name] from `document.cookie`, returning null when absent. Values are
/// URL-encoded on write (see [_setProxyOriginCookie]); callers decode as needed.
String? _readCookie(String name) {
  final raw = web.document.cookie;
  for (final part in raw.split(';')) {
    final eq = part.indexOf('=');
    final k = eq < 0 ? part.trim() : part.substring(0, eq).trim();
    if (k == name) {
      return eq < 0 ? '' : part.substring(eq + 1).trim();
    }
  }
  return null;
}

/// The connected origin from the cookie, decoded, or null when absent/invalid.
String? _readProxyOriginCookie() {
  final raw = _readCookie(_kProxyOriginCookie);
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    return Uri.decodeComponent(raw);
  } catch (_) {
    return null;
  }
}

/// Stores the (non-sensitive) cc-server origin in the CSP cookie. `Secure`
/// (Cloudflare serves https), `SameSite=Lax`, `Path=/`, ~1y. The value is
/// URL-encoded so IPv6 hosts (with `[`/`]`) don't break the cookie octets.
void _setProxyOriginCookie(String origin) {
  web.document.cookie =
      '$_kProxyOriginCookie=${Uri.encodeComponent(origin)}; Path=/; '
      'Max-Age=31536000; SameSite=Lax; Secure';
}

/// Clears the CSP origin cookie (next load returns to the strict, unpaired CSP).
void _clearProxyOriginCookie() {
  web.document.cookie =
      '$_kProxyOriginCookie=; Path=/; Max-Age=0; SameSite=Lax; Secure';
}

/// Reads connection hints from the current URL — `?server=&device=&psk=` query
/// params or a base64url-JSON / query-string URL fragment (the PSK rides in the
/// fragment so it never reaches the static host).
_Creds _readUrlHints() {
  final base = Uri.base;
  String? server;
  String? device;
  String? psk;
  void take(String? s, void Function(String) set) {
    if (s != null && s.isNotEmpty) {
      set(s);
    }
  }

  take(base.queryParameters['server'], (v) => server = v);
  take(base.queryParameters['device'], (v) => device = v);
  take(base.queryParameters['psk'], (v) => psk = v);
  final fragment = base.fragment;
  if (fragment.isNotEmpty && (server == null || psk == null)) {
    Map<String, String>? parsed;
    try {
      final padded = fragment.padRight((fragment.length + 3) & ~3, '=');
      final json = jsonDecode(utf8.decode(base64Url.decode(padded)));
      if (json is Map) {
        parsed = {for (final e in json.entries) '${e.key}': '${e.value}'};
      }
    } catch (_) {
      try {
        parsed = Uri.splitQueryString(fragment);
      } catch (_) {
        parsed = null;
      }
    }
    if (parsed != null) {
      take(parsed['server'] ?? parsed['s'], (v) => server = v);
      take(parsed['device'] ?? parsed['i'], (v) => device = v);
      take(parsed['psk'] ?? parsed['k'], (v) => psk = v);
    }
  }
  return _Creds(server: server ?? '', device: device, psk: psk);
}

/// The connection bootstrap — web can't self-serve, so it dials a cc-server.
/// Fields are pre-filled by the parent ([initial]): saved creds overlaid by a
/// fresh pairing deep link (query params or a base64url-JSON URL fragment, the
/// PSK riding in the fragment so it never reaches the static host).
class _ConnectGate extends StatefulWidget {
  const _ConnectGate({
    required this.connecting,
    required this.reconnecting,
    required this.error,
    required this.initial,
    required this.onConnect,
  });

  final bool connecting;
  final bool reconnecting;
  final String? error;
  final _Creds initial;
  final Future<void> Function({
    required Uri uri,
    required String deviceId,
    required String psk,
    bool remember,
  })
  onConnect;

  @override
  State<_ConnectGate> createState() => _ConnectGateState();
}

class _ConnectGateState extends State<_ConnectGate> {
  late final TextEditingController _server;
  late final TextEditingController _device;
  late final TextEditingController _psk;
  late bool _remember;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.initial.server);
    _device = TextEditingController(
      text: widget.initial.device ?? 'web-client',
    );
    _psk = TextEditingController(text: widget.initial.psk ?? '');
    // Default to remembering for a fresh device (reload-resume is the point),
    // but honour a returning user's explicit opt-out (saved creds, remember off).
    _remember = widget.initial.remember || !widget.initial.isComplete;
  }

  @override
  void dispose() {
    _server.dispose();
    _device.dispose();
    _psk.dispose();
    super.dispose();
  }

  void _submit() {
    final uri = Uri.tryParse(_server.text.trim());
    if (uri == null || (!uri.isScheme('ws') && !uri.isScheme('wss'))) {
      return;
    }
    widget.onConnect(
      uri: uri,
      deviceId: _device.text.trim().isEmpty
          ? 'web-client'
          : _device.text.trim(),
      psk: _psk.text.trim(),
      remember: _remember,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: CcCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.radio, size: 20, color: t.fgBrandPrimary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Connect to Control Center',
                      style: CcTypography.title.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Dial a running cc-server over WebSocket. Your key stays on '
                  'this device.',
                  style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                ),
                const SizedBox(height: AppSpacing.lg),
                _field(t, 'Server', _server, hint: 'wss://host:9030/rpc'),
                const SizedBox(height: AppSpacing.md),
                _field(t, 'Device id', _device, hint: 'web-client'),
                const SizedBox(height: AppSpacing.md),
                _field(
                  t,
                  'Pairing key',
                  _psk,
                  hint: 'paste the PSK',
                  obscure: true,
                  onSubmit: true,
                ),
                if (widget.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  CcAlert(
                    variant: CcAlertVariant.danger,
                    title: 'Could not connect',
                    description: Text(
                      widget.error!,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textErrorPrimary,
                      ),
                    ),
                  ),
                ] else if (widget.reconnecting && widget.connecting) ...[
                  const SizedBox(height: AppSpacing.md),
                  CcAlert(
                    variant: CcAlertVariant.info,
                    title: 'Reconnecting…',
                    description: Text(
                      'The connection dropped — retrying with your saved key.',
                      style: CcTypography.bodySm.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // Informed opt-in: the key is sensitive. When checked it is kept
                // in this browser's localStorage so a reload reconnects; the
                // deploy CSP (web/_headers) limits the egress a foothold could use.
                Row(
                  children: [
                    CcCheckbox(
                      value: _remember,
                      onChanged: widget.connecting
                          ? null
                          : (v) => setState(() => _remember = v),
                      semanticLabel: 'Stay connected on this device',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Stay connected on this device (stores your key in this '
                        'browser)',
                        style: CcTypography.bodySm.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                CcButton(
                  onPressed: widget.connecting ? null : _submit,
                  variant: CcButtonVariant.accent,
                  loading: widget.connecting,
                  fullWidth: true,
                  child: const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    DesignSystemTokens t,
    String label,
    TextEditingController controller, {
    String? hint,
    bool obscure = false,
    bool onSubmit = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            label,
            style: CcTypography.bodySm.copyWith(
              color: t.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        CcTextField(
          controller: controller,
          hintText: hint,
          obscureText: obscure,
          enabled: !widget.connecting,
          onSubmitted: onSubmit ? (_) => _submit() : null,
        ),
      ],
    );
  }
}
