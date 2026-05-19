// Web bootstrap for Control Center.
//
// The web build is the SAME app on another device: it cannot be its own server,
// so it dials a cc-server over WSS and reads/writes through the cc_data remote
// repositories (no local Drift DB). This bootstrap is the web-specific startup —
// a connection gate that, once connected, renders the FULL desktop UI
// (`ControlCenterApp`: sidebar, PR review, every screen) inside a Riverpod
// scope whose overrides install the web-flavoured dependencies (the connected
// RPC client, ephemeral preferences, the keychain secure store and the
// connected workspace as the active one). The onboarding gate computes live,
// exactly like the desktop, so a freshly-minted server still onboards.
//
// Build: `scripts/build_web.sh` (SkWasm with a CanvasKit fallback).
import 'dart:async';
import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/control_center_app.dart';
import 'package:control_center/core/infrastructure/provider_retry.dart';
import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/auth_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_entry_factory.dart';
import 'package:control_center/core/server/server_pairing.dart';
import 'package:control_center/core/server/sso_login.dart';
import 'package:control_center/core/server/sso_pair_link.dart'
    show httpOriginFor;
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:control_center/core/storage/web_local_storage_backend.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/shiki_bootstrap.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:web/web.dart' as web;

/// Web bootstrap: install lightweight error handlers, then run the connect-gate
/// root. On a successful connection it renders the full app over the connected
/// RPC client (no Sentry, no background services, no local database — the
/// server owns execution).
Future<void> bootstrapAndRun() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit's web player (an HTML media element backend) before
  // any Player is created. Output-device selection is desktop-only; the web
  // player always uses the browser's default output.
  MediaKit.ensureInitialized();

  // Hand right-click to the app. Flutter web ships with the browser's own
  // context menu enabled, which both covers our `showCcMenuAt` menus (space
  // rows, tabs, tickets, the explorer) and makes the engine suppress Flutter's
  // selection toolbars entirely — so text selection has no copy affordance.
  await BrowserContextMenu.disableContextMenu();

  // Cap the engine image cache well below Flutter's default (~100MB / 1000
  // images) — mirrors the desktop bootstrap; the UI shows mostly small,
  // already-downscaled avatars and thumbnails.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;

  // Pre-warm the shiki highlighter (CC themes + the hottest grammars) and opt
  // into the tokenize Web Worker (web/shiki_tokenize_worker.js). Registration
  // itself is lazy — this only warms.
  initializeShikiHighlighting();

  // Lightweight handlers only — the desktop's Sentry + AppLog server seams pull
  // VM-only dependencies, so web logs to the browser console instead.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is RemoteRpcClientClosedException) {
      debugPrint('RPC client closed; in-flight requests cancelled.');
      return true;
    }
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
///
/// Wrapped in an [ObservableKeyValueBackend] so the per-user preference sync
/// can observe writes; it also backs `keyValueBackendProvider`, so the facade
/// and the change stream are the same store on web exactly as on desktop.
final ObservableKeyValueBackend _webBackend = ObservableKeyValueBackend(
  WebLocalStorageBackend(),
);

/// Root of the web build — a Material-free [WidgetsApp] themed by [CcTheme]
/// that hosts the connection gate. Once connected, the gate swaps in the full
/// [ControlCenterApp] (which installs its own `MaterialApp`).
///
/// Owns the theme mode while disconnected: it defaults to following the OS /
/// browser `prefers-color-scheme` ([_WebThemeMode.system]), honours the user's
/// saved override from `localStorage` and re-resolves when the system
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
  Object? _error;
  RemoteServerConnection? _connection;
  String? _activeWorkspaceId;
  StreamSubscription<ServerConnectionStatus>? _statusSub;

  // Pre-filled connection fields (saved entry, overridden by a fresh URL hint).
  _Creds _hints = const _Creds(server: 'ws://localhost:9030/rpc');
  bool _bootResolved = false;

  /// The persisted server list — the same store the Settings → servers section
  /// reads/writes, so a change made in Settings is what the next reload
  /// resumes.
  late final ServerConnectionStore _store = ServerConnectionStore(
    AppPreferences(_webBackend),
    SecureStore.keychain(),
  );

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// Resolve the boot connection: a fresh URL hint (invite or pairing link)
  /// wins; otherwise a saved paired server resumes. Reconnects after drops are
  /// the [ResilientRpcClient]'s job — the gate only handles first connects.
  Future<void> _boot() async {
    final urlHints = _readUrlHints();
    _stripCredentialFragment();
    final active = _store.readActive();
    final defaultServer =
        active?.descriptor.paths.firstOrNull?.rpcUri?.toString() ??
        'ws://localhost:9030/rpc';
    if (!mounted) {
      return;
    }
    setState(() {
      _hints = _Creds(
        server: urlHints.server.isNotEmpty ? urlHints.server : defaultServer,
        device: urlHints.device ?? active?.deviceId ?? 'web-client',
        psk: urlHints.psk,
        invite: urlHints.invite,
      );
      _bootResolved = true;
    });
    if (urlHints.isInvite && !(urlHints.psk?.isNotEmpty ?? false)) {
      // An invite deep link: redeem the one-time code for this browser's own
      // device credential + the server's descriptor, then connect.
      await _pair(
        server: urlHints.server,
        inviteCode: urlHints.invite!,
        remember: true,
      );
      return;
    }
    if (urlHints.server.isNotEmpty && (urlHints.psk?.isNotEmpty ?? false)) {
      if (ssoLoginInFlight()) {
        // The expected completion of an SSO round-trip this tab started
        // (the IdP redirected back with the credential fragment).
        await _pair(
          server: urlHints.server,
          deviceId: urlHints.device ?? 'web-client',
          psk: urlHints.psk!,
          remember: true,
        );
        return;
      }
      // An unbidden pairing link (forged or forwarded): do NOT auto-connect.
      // The connect form is pre-filled above; the user reviews the server
      // and presses Connect. One explicit click beats silently re-homing
      // the app to whatever server the link names.
      return;
    }
    if (urlHints.server.isEmpty && urlHints.psk == null && active != null) {
      // A clean reload with a remembered session → resume it.
      final psk = await _store.readPsk(active.serverId);
      if (psk != null && psk.isNotEmpty) {
        await _resume(active, psk);
      }
    }
  }

  /// Resumes a stored entry (descriptor + pin) with its keychain PSK.
  Future<void> _resume(ServerEntry entry, String psk) async {
    setState(() {
      _phase = _Phase.connecting;
      _error = null;
    });
    try {
      final connection = await connectToEntry(
        store: _store,
        entry: entry,
        psk: psk,
      );
      await _adopt(connection);
    } catch (e) {
      _failToGate(e);
    }
  }

  /// First-time pairing (gate form, pairing link, or invite link).
  Future<void> _pair({
    required String server,
    String inviteCode = '',
    String deviceId = '',
    String psk = '',
    required bool remember,
  }) async {
    setState(() {
      _phase = _Phase.connecting;
      _error = null;
    });
    try {
      final RemoteServerConnection connection;
      if (remember || inviteCode.isNotEmpty) {
        connection = await pairWithServer(
          store: _store,
          rawUrl: server,
          platform: 'web',
          inviteCode: inviteCode,
          deviceId: deviceId,
          psk: psk,
        );
      } else {
        // Ephemeral session: verify + connect without persisting anything.
        final entry = await ServerEntryFactory.fromManualUrl(
          rawUrl: server,
          deviceId: deviceId,
        );
        if (entry == null) {
          throw StateError(
            'Could not reach the server at that address (its /healthz did '
            'not answer with an identity).',
          );
        }
        connection = await connectToEntry(
          store: _store,
          entry: entry,
          psk: psk,
        );
      }
      await _adopt(connection);
    } catch (e) {
      _failToGate(e);
    }
  }

  void _failToGate(Object e) {
    if (!mounted) {
      return;
    }
    setState(() {
      _connection = null;
      _error = e;
      _phase = _Phase.disconnected;
    });
  }

  /// Binds a live connection into the app: resolves the landing workspace,
  /// reconciles the CSP cookie and watches for a terminal identity mismatch
  /// (transient drops are the resilient client's business, not the gate's).
  Future<void> _adopt(RemoteServerConnection connection) async {
    final workspaces = RemoteWorkspaceRepository(connection.client);
    final list = await workspaces.list();
    // Land in the persisted last-active workspace (written to localStorage by
    // the in-app workspace switch) when it still exists, else the first.
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
      await connection.dispose();
      return;
    }

    // Reconcile the CSP cookie so the Cloudflare Worker can stamp a
    // host-scoped policy on the next load (see _kProxyOriginCookie). CSP can
    // only tighten, never relax, on a live page, so when the connected
    // cc-server origin changes we reload once — the saved entry makes the
    // reload resume straight back into this session.
    final origin = connection.mediaProxy?.httpBase.toString() ?? '';
    if (origin.isNotEmpty && origin != _readProxyOriginCookie()) {
      _setProxyOriginCookie(origin);
      if (_store.readActive() != null && _readProxyOriginCookie() == origin) {
        web.window.location.reload();
        return;
      }
    }

    await _statusSub?.cancel();
    _statusSub = connection.supervisor.status.listen((status) {
      if (status.phase == ServerConnectionPhase.identityMismatch) {
        // TOFU hard stop: the server's identity changed. No retry loop, no
        // "continue anyway" — the user must re-pair with a fresh invite. The
        // status carries the mismatch exception's text, which the gate's
        // classifier maps to the localized identity-mismatch copy.
        unawaited(connection.dispose());
        _failToGate(
          status.error ??
              StateError('The server presented a changed identity.'),
        );
      }
    });

    final old = _connection;
    setState(() {
      _connection = connection;
      _activeWorkspaceId = landingWorkspaceId;
      _phase = _Phase.connected;
    });
    if (old != null && !identical(old, connection)) {
      // After the frame that remounts `_ConnectedApp` around the new
      // connection (its `ValueKey` changes), so the outgoing provider scope
      // never sees its RPC client closed underneath it while still mounted.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(old.dispose()),
      );
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  /// Switches the connected app to another paired server (Settings action).
  Future<void> _switchTo(String serverId) async {
    final entry = _store.entry(serverId);
    if (entry == null) {
      throw StateError('Unknown server');
    }
    final psk = await _store.readPsk(serverId);
    if (psk == null || psk.isEmpty) {
      throw StateError('No pairing key stored for that server');
    }
    final connection = await connectToEntry(
      store: _store,
      entry: entry,
      psk: psk,
    );
    await _store.setActiveServer(serverId);
    await _adopt(connection);
  }

  Future<void> _disconnect() async {
    await _statusSub?.cancel();
    _statusSub = null;
    await _connection?.dispose();
    await _store.clear();
    // Drop the CSP origin cookie so the next load returns to the strict
    // (unpaired) policy — no host is connected to allow-list.
    _clearProxyOriginCookie();
    if (!mounted) {
      return;
    }
    setState(() {
      _connection = null;
      _activeWorkspaceId = null;
      _phase = _Phase.disconnected;
      _error = null;
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: t.bgPrimary,
      child: switch (_phase) {
        _Phase.connected => _ConnectedApp(
          // Rebuild the whole app (fresh ProviderScope) when the connected
          // server or active workspace changes, so the overrides re-resolve.
          key: ValueKey(
            'app-${_connection!.entry.serverId}-${_activeWorkspaceId ?? '-'}',
          ),
          connection: _connection!,
          activeWorkspaceId: _activeWorkspaceId,
          onDisconnect: _disconnect,
          onSwitchServer: _switchTo,
        ),
        _ when !_bootResolved => const Center(child: CcSpinner()),
        _ => _ConnectGate(
          connecting: _phase == _Phase.connecting,
          error: _error,
          initial: _hints,
          onConnect:
              ({
                required Uri uri,
                required String deviceId,
                required String psk,
                String inviteCode = '',
                bool remember = true,
              }) => _pair(
                server: uri.toString(),
                inviteCode: inviteCode,
                deviceId: deviceId,
                psk: psk,
                remember: remember,
              ),
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
///  - The onboarding gate is NOT overridden: it computes live exactly like the
///    desktop (the signed-in user's forge connections, plus the server's
///    workspace list over RPC). Connecting to a freshly-minted
///    server therefore lands on the same first-run onboarding the desktop
///    shows, instead of an empty inbox with nothing configured.
///  - [activeWorkspaceIdProvider] → bound to the workspace resolved at connect
///    (the persisted last-active one, else the first), so workspace-scoped
///    screens scope to it immediately; switches persist via the inherited
///    setActive. The desktop notifier reads the Drift bootstrap stream, which
///    does not exist on web.
class _ConnectedApp extends StatelessWidget {
  const _ConnectedApp({
    super.key,
    required this.connection,
    required this.activeWorkspaceId,
    required this.onDisconnect,
    required this.onSwitchServer,
  });

  final RemoteServerConnection connection;
  final String? activeWorkspaceId;
  final VoidCallback onDisconnect;
  final Future<void> Function(String serverId) onSwitchServer;

  @override
  Widget build(BuildContext context) {
    Widget app = const ControlCenterApp();
    final proxy = connection.mediaProxy;
    if (proxy != null) {
      // Above the whole app so every remote-media widget (newsfeed, avatars,
      // PR body, dialogs/overlays in the same element tree) can resolve it.
      app = MediaProxyScope(config: proxy, child: app);
    }
    return ProviderScope(
      // Bounded, unrecoverable-error-aware retry: keeps a subscription stream
      // error (e.g. a GitHub rate limit) from looping into a resubscribe storm.
      retry: appProviderRetry,
      overrides: [
        rpcClientProvider.overrideWithValue(connection.client),
        // The bulk-content lane, beside the RPC client it belongs with — the
        // composer's picture upload runs in a notifier with no BuildContext,
        // so the scope above the app is not enough on its own.
        mediaProxyConfigProvider.overrideWithValue(proxy),
        serverConnectionSupervisorProvider.overrideWithValue(
          connection.supervisor,
        ),
        serverSwitchHandlerProvider.overrideWithValue(onSwitchServer),
        // localStorage-backed so web preferences (theme, the server list, …)
        // survive a reload. Shares `_webBackend` with the connect gate's
        // `_store`, so a change made in Settings is read on next boot.
        appPreferencesProvider.overrideWithValue(AppPreferences(_webBackend)),
        keyValueBackendProvider.overrideWithValue(_webBackend),
        secureStoreProvider.overrideWithValue(SecureStore.keychain()),
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
    this.invite,
    this.remember = true,
  });

  final String server;
  final String? device;
  final String? psk;

  /// One-time invite code from an invite deep link — redeemed against the
  /// server's `/invites/redeem` to mint this browser's device credential.
  final String? invite;
  final bool remember;

  bool get isComplete => server.isNotEmpty && (psk != null && psk!.isNotEmpty);

  /// Whether this is an invite deep link (a server plus a code, no PSK yet).
  bool get isInvite =>
      server.isNotEmpty && (invite != null && invite!.isNotEmpty);

  /// Overlays [other]'s non-null fields onto this record (used to let a fresh
  /// URL pairing hint win over saved values).
  _Creds merge(_Creds other) => _Creds(
    server: other.server.isNotEmpty ? other.server : server,
    device: other.device ?? device,
    psk: other.psk ?? psk,
    invite: other.invite ?? invite,
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

/// Loads the saved theme mode (defaults to following the system appearance).
_WebThemeMode _loadThemeMode() =>
    _WebThemeMode.fromName(web.window.localStorage.getItem(_kTheme));

// --- Connected-origin cookie → host-scoped CSP --------------------------------
//
// The deployed web client is a static SPA served by Cloudflare; its CSP can't
// name the cc-server host until the user connects (the host is typed in the
// connect form and only then is it known). The Cloudflare Worker
// (worker/csp.js, run_worker_first) reads this cookie on each document request
// and stamps a per-request CSP adding the connected cc-server origin to
// connect-src, img-src and media-src — so the CanvasKit `fetch()` to
// `/proxy/media`, the `<img>` src and the `<audio>`/`<video>` src (soundscape
// stream, meeting playback, proxied video) are all allowed for the paired host,
// and ONLY that host.
//
// The cookie holds ONLY the origin (scheme+host+port) — never the pairing key,
// which stays in secure storage — so it is not sensitive. CSP can only tighten
// (never relax) after a page has loaded, so the first connect on a fresh page
// (no cookie → strict CSP) reloads once; subsequent reloads see the cookie and
// skip the reload, resuming straight into the session.

const _kProxyOriginCookie = 'cc_proxy_origin';

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

/// Reads connection hints from the current URL — a base64url-JSON or
/// query-string URL FRAGMENT only. Query parameters deliberately carry
/// nothing: a `?psk=` lands in the static host's access logs, proxies and
/// the browser's history and the invariant is that the PSK rides in the
/// fragment so it never reaches a server.
_Creds _readUrlHints() {
  final base = Uri.base;
  String? server;
  String? device;
  String? psk;
  String? invite;
  void take(String? s, void Function(String) set) {
    if (s != null && s.isNotEmpty) {
      set(s);
    }
  }

  final fragment = base.fragment;
  if (fragment.isNotEmpty) {
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
      take(parsed['invite'] ?? parsed['inv'], (v) => invite = v);
    }
  }
  return _Creds(server: server ?? '', device: device, psk: psk, invite: invite);
}

/// Removes the credential fragment from the address bar and history. The
/// PSK is a live pairing credential: leaving it in the URL keeps it one
/// shoulder-surf, one screenshot and one history entry away from leaking.
void _stripCredentialFragment() {
  try {
    final base = Uri.base;
    if (base.fragment.isEmpty) {
      return;
    }
    web.window.history.replaceState(null, '', base.removeFragment().toString());
  } on Object {
    // Best effort — a sandboxed history API must not break boot.
  }
}

/// The connection bootstrap — web can't self-serve, so it dials a cc-server.
/// Fields are pre-filled by the parent ([initial]): saved creds overlaid by a
/// fresh pairing deep link (query params or a base64url-JSON URL fragment, the
/// PSK riding in the fragment so it never reaches the static host).
class _ConnectGate extends StatefulWidget {
  const _ConnectGate({
    required this.connecting,
    required this.error,
    required this.initial,
    required this.onConnect,
  });

  final bool connecting;
  final Object? error;
  final _Creds initial;
  final Future<void> Function({
    required Uri uri,
    required String deviceId,
    required String psk,
    String inviteCode,
    bool remember,
  })
  onConnect;

  @override
  State<_ConnectGate> createState() => _ConnectGateState();
}

class _ConnectGateState extends State<_ConnectGate> {
  late final TextEditingController _server;
  late final TextEditingController _invite;
  late final TextEditingController _device;
  late final TextEditingController _psk;
  late bool _remember;

  /// What the entered server's unauthenticated `/auth/providers` probe
  /// found; null = unknown (not probed, or the server did not answer).
  AuthProvidersSnapshot? _auth;
  String? _probedOrigin;
  AuthProviderInfo? _ssoBusyProvider;
  bool _awaitingPopup = false;
  String? _ssoError;
  bool _showManual = false;
  Timer? _ssoDebounce;

  bool get _ssoAvailable => _auth?.providers.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.initial.server);
    _invite = TextEditingController(text: widget.initial.invite ?? '');
    _device = TextEditingController(
      text: widget.initial.device ?? 'web-client',
    );
    _psk = TextEditingController(text: widget.initial.psk ?? '');
    // Default to remembering for a fresh device (reload-resume is the point),
    // but honour a returning user's explicit opt-out (saved creds, remember off).
    _remember = widget.initial.remember || !widget.initial.isComplete;
    _server.addListener(_scheduleSsoProbe);
    _scheduleSsoProbe();
  }

  @override
  void dispose() {
    _ssoDebounce?.cancel();
    cancelSsoLogin();
    _server.removeListener(_scheduleSsoProbe);
    _server.dispose();
    _invite.dispose();
    _device.dispose();
    _psk.dispose();
    super.dispose();
  }

  /// The HTTP origin a browser would use for the entered server URL —
  /// component-built (never `Uri.replace` with emptied components, which
  /// leaves dangling `?#` and corrupts every derived URL).
  String? get _serverOrigin => httpOriginFor(_server.text);

  void _scheduleSsoProbe() {
    _ssoDebounce?.cancel();
    final origin = _serverOrigin;
    if (origin == null) {
      if (_auth != null) {
        setState(() {
          _auth = null;
          _ssoError = null;
        });
      }
      return;
    }
    if (_auth != null && _probedOrigin == origin) {
      return; // Already probed this exact origin.
    }
    _ssoDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_probeSso(origin));
    });
  }

  /// Silent availability probe — the form ADAPTS to the answer (SSO
  /// buttons when offered, manual form hidden when pairing is disabled);
  /// failures are quiet here because the user has not asked for SSO yet.
  Future<void> _probeSso(String origin) async {
    final snapshot = await probeAuthProviders(origin);
    if (!mounted) {
      return;
    }
    setState(() {
      _auth = snapshot;
      _probedOrigin = snapshot == null ? null : origin;
    });
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
      inviteCode: _invite.text.trim(),
      remember: _remember,
    );
  }

  /// "Sign in with …": open a NEW TAB for the IdP round-trip and wait for
  /// the completion page to postMessage the minted credential back to this
  /// tab (origin-validated — the message carries a credential). Falls back
  /// to navigating this tab when the popup is blocked; either path lands in
  /// the same pairing machinery.
  Future<void> _startSso(AuthProviderInfo provider) async {
    final l10n = AppLocalizations.of(context);
    final origin = _serverOrigin;
    if (origin == null) {
      setState(() => _ssoError = l10n.ssoProbeFailed);
      return;
    }
    setState(() {
      _ssoBusyProvider = provider;
      _ssoError = null;
    });
    final payload = await startSsoLogin(
      provider: provider,
      origin: origin,
      clientOrigin: Uri.base.origin,
      onAwaiting: () {
        if (mounted) {
          setState(() {
            _ssoBusyProvider = null;
            _awaitingPopup = true;
          });
        }
      },
    );
    if (payload == null || !mounted) {
      // Abandoned (the gate was disposed) or same-tab: the reload's
      // credential fragment completes it in `_boot` instead.
      return;
    }
    unawaited(
      widget.onConnect(
        uri: Uri.parse(payload.server),
        deviceId: payload.deviceId,
        psk: payload.psk,
        remember: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final hasInvite = _invite.text.trim().isNotEmpty;
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
                      l10n.webConnectTitle,
                      style: CcTypography.title.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.webConnectSubtitle,
                  style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                ),
                const SizedBox(height: AppSpacing.lg),
                _field(
                  t,
                  l10n.webConnectServerLabel,
                  _server,
                  hint: 'wss://host:9030/rpc',
                  onChanged: (_) => setState(() {}),
                ),
                if (_ssoError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _ssoError!,
                    style: CcTypography.caption.copyWith(color: t.danger),
                  ),
                ],
                if (_ssoAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  // SSO is the primary action when the server offers it —
                  // one button per advertised connection; the manual
                  // invite/pairing fields collapse behind the toggle below
                  // so both paths stay one click apart.
                  for (final provider
                      in _auth?.providers ?? const <AuthProviderInfo>[]) ...[
                    CcButton(
                      onPressed: (widget.connecting || _ssoBusyProvider != null)
                          ? null
                          : () => _startSso(provider),
                      variant: CcButtonVariant.accent,
                      loading: identical(_ssoBusyProvider, provider),
                      fullWidth: true,
                      child: Text(l10n.ssoSignInWith(provider.label)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_awaitingPopup) ...[
                    Text(
                      l10n.ssoWaitingForBrowser,
                      style: CcTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  if (_auth?.pairingEnabled ?? true)
                    CcButton(
                      onPressed: widget.connecting
                          ? null
                          : () => setState(() => _showManual = !_showManual),
                      variant: CcButtonVariant.ghost,
                      fullWidth: true,
                      child: Text(
                        _showManual
                            ? l10n.ssoHideManualPairing
                            : l10n.ssoUseManualPairing,
                      ),
                    ),
                ],
                // Pairing disabled server-side = SSO-only onboarding: the manual form
                // disappears entirely (the toggle stays hidden with it).
                if ((!_ssoAvailable || _showManual) &&
                    (_auth?.pairingEnabled ?? true)) ...[
                  const SizedBox(height: AppSpacing.md),
                  // A one-time invite code replaces the manual device-id +
                  // pairing-key pair (same behavior as the desktop
                  // server-setup screen): redeeming it mints this browser's
                  // own credential.
                  _field(
                    t,
                    l10n.serverSetupInviteCode,
                    _invite,
                    hint: l10n.serverSetupInviteCodeHint,
                    onChanged: (_) => setState(() {}),
                    onSubmit: hasInvite,
                  ),
                  if (!hasInvite) ...[
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      t,
                      l10n.webConnectDeviceIdLabel,
                      _device,
                      hint: 'web-client',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      t,
                      l10n.webConnectPairingKeyLabel,
                      _psk,
                      hint: l10n.webConnectPairingKeyHint,
                      obscure: true,
                      onSubmit: true,
                    ),
                  ],
                  if (widget.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    ConnectionErrorAlert(error: widget.error!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  // Informed opt-in: the key is sensitive. When checked it is
                  // kept in this browser's localStorage so a reload
                  // reconnects; the deploy CSP (web/_headers) limits the
                  // egress a foothold could use.
                  Row(
                    children: [
                      CcCheckbox(
                        value: _remember,
                        onChanged: widget.connecting
                            ? null
                            : (v) => setState(() => _remember = v),
                        semanticLabel: l10n.webConnectStayConnected,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.webConnectStayConnectedDetail,
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
                    variant: CcButtonVariant.primary,
                    loading: widget.connecting,
                    fullWidth: true,
                    child: Text(l10n.connect),
                  ),
                ],
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
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
          onSubmitted: onSubmit ? (_) => _submit() : null,
        ),
      ],
    );
  }
}
