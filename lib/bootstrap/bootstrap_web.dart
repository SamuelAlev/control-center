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
import 'package:control_center/core/server/pairing_link.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_entry_factory.dart';
import 'package:control_center/core/server/server_pairing.dart';
import 'package:control_center/core/server/sso_login_web.dart'
    show openSsoWebFragment;
import 'package:control_center/core/storage/legacy_snapshot_cleanup.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:control_center/core/storage/web_local_storage_backend.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/shiki_bootstrap.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/server_connect/connect_appearance.dart';
import 'package:control_center/shared/widgets/server_connect/connect_dialog_host.dart';
import 'package:control_center/shared/widgets/server_connect/connect_landing.dart';
import 'package:control_center/shared/widgets/server_connect/pairing_link_dialog.dart';
import 'package:control_center/shared/widgets/server_connect/server_connect_dialog.dart';
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
  // context menu enabled, which both covers our `showCcMenuAt` menus (tabs,
  // tickets, the explorer) and makes the engine suppress Flutter's
  // selection toolbars entirely — so text selection has no copy affordance.
  await BrowserContextMenu.disableContextMenu();

  // Cap the engine image cache well below Flutter's default (~100MB / 1000
  // images) — mirrors the desktop bootstrap; the UI shows mostly small,
  // already-downscaled avatars and thumbnails.
  PaintingBinding.instance.imageCache
    ..maximumSize = 400
    ..maximumSizeBytes = 32 << 20;

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

/// Language and theme on the connect gate, over the same store the connected
/// app reads, so a choice made at the gate is the one it opens with.
final ConnectAppearance _webAppearance = ConnectAppearance(
  AppPreferences(_webBackend),
);

/// Root of the web build — a Material-free [WidgetsApp] themed by [CcTheme]
/// that hosts the connection gate. Once connected, the gate swaps in the full
/// [ControlCenterApp] (which installs its own `MaterialApp`).
///
/// Owns the theme mode while disconnected: it defaults to following the OS /
/// browser `prefers-color-scheme`, honours the user's saved choice from
/// [_webAppearance] and re-resolves when the system appearance changes, so the
/// connect gate matches the host appearance.
class ControlCenterWebApp extends StatefulWidget {
  /// Creates the web app.
  const ControlCenterWebApp({super.key});

  @override
  State<ControlCenterWebApp> createState() => _ControlCenterWebAppState();
}

class _ControlCenterWebAppState extends State<ControlCenterWebApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Observe platform brightness so an unpinned theme re-themes live when the
    // OS / browser switches between light and dark.
    WidgetsBinding.instance.addObserver(this);
    _webAppearance.addListener(_onAppearanceChanged);
  }

  @override
  void dispose() {
    _webAppearance.removeListener(_onAppearanceChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAppearanceChanged() => setState(() {});

  @override
  void didChangePlatformBrightness() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Resolves the concrete light/dark tokens, reading the live OS / browser
  /// appearance unless the user pinned one.
  CcThemeData _resolveTheme() {
    final dark = _webAppearance.isDark(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
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
            locale: _webAppearance.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: kSupportedAppLocales,
            localeResolutionCallback: resolveAppLocale,
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
    await removeLegacyCalendarSnapshots(AppPreferences(_webBackend));
    final urlHints = await _readUrlHints();
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
      if (urlHints.trustedHandoff) {
        // Only a decryptable, expected SSO completion may auto-connect.
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

  /// First-time pairing (gate dialog, pairing link, or invite link). Resolves
  /// with the failure, or null once connected.
  Future<Object?> _pair({
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
          persistSnapshots: false,
        );
      }
      await _adopt(connection);
      return null;
    } catch (e) {
      _failToGate(e);
      return e;
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

  /// Binds a live connection into the app: resolves the landing workspace and
  /// watches for a terminal identity mismatch (transient drops are the
  /// resilient client's business, not the gate's).
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
      } else if (status.authenticationRejected) {
        // This device no longer has a valid pairing. Leave the protected UI,
        // then forget its stored key and every server/user snapshot.
        _failToGate(
          status.error ?? StateError('The server rejected this device.'),
        );
        unawaited(() async {
          try {
            await _statusSub?.cancel();
            _statusSub = null;
            await connection.dispose();
            await _store.removeEntry(connection.entry.serverId);
          } on Object catch (error) {
            debugPrint('Could not remove revoked pairing: $error');
          }
        }());
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

  /// Leaves a lost server for the connect gate (the lost-connection dialog's
  /// sign-in action). Unlike [_disconnect] the pairing stays stored, so the
  /// gate can reconnect to it or pair with another server.
  Future<void> _returnToGate() async {
    await _statusSub?.cancel();
    _statusSub = null;
    final old = _connection;
    // Pre-fill the gate with the stored pairing, so Connect retries this
    // server in one click.
    final entry = old?.entry ?? _store.readActive();
    final psk = entry == null ? null : await _store.readPsk(entry.serverId);
    if (!mounted) {
      await old?.dispose();
      return;
    }
    setState(() {
      if (entry != null) {
        _hints = _Creds(
          server:
              entry.descriptor.paths.firstOrNull?.rpcUri?.toString() ??
              _hints.server,
          device: entry.deviceId,
          psk: psk,
        );
      }
      _connection = null;
      _activeWorkspaceId = null;
      _phase = _Phase.disconnected;
      _error = null;
    });
    // After the frame that unmounts `_ConnectedApp`, as in [_adopt].
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => unawaited(old?.dispose()))
      ..ensureVisualUpdate();
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
          // A new authenticated connection needs fresh providers even when
          // another account connects to the same server and workspace.
          key: ValueKey((_connection, _activeWorkspaceId)),
          connection: _connection!,
          activeWorkspaceId: _activeWorkspaceId,
          onDisconnect: _disconnect,
          onReturnToGate: _returnToGate,
          onSwitchServer: _switchTo,
        ),
        _ when !_bootResolved => const Center(child: CcSpinner()),
        _ => _ConnectGate(
          connecting: _phase == _Phase.connecting,
          error: _error,
          initial: _hints,
          onConnect: _pair,
        ),
      },
    );
  }
}

/// The connected web app: a Riverpod scope whose overrides install the web-flavoured
/// dependencies, rendering the FULL [ControlCenterApp].
/// single data entrypoint; on web there is no in-process host default).
/// `_webBackend`), so web preferences survive a reload.
/// [secureStoreProvider] → flutter_secure_storage, which works on web.
/// The onboarding gate is NOT overridden: it computes live exactly like the
/// desktop (the signed-in user's forge connections, plus the server's workspace list over
/// RPC).
class _ConnectedApp extends StatelessWidget {
  const _ConnectedApp({
    super.key,
    required this.connection,
    required this.activeWorkspaceId,
    required this.onDisconnect,
    required this.onReturnToGate,
    required this.onSwitchServer,
  });

  final RemoteServerConnection connection;
  final String? activeWorkspaceId;
  final VoidCallback onDisconnect;
  final Future<void> Function() onReturnToGate;
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
        returnToServerSignInProvider.overrideWithValue(onReturnToGate),
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

/// A connection record (server URL + device id + PSK) plus whether to remember
/// it across reloads.
class _Creds {
  const _Creds({
    required this.server,
    this.device,
    this.psk,
    this.invite,
    this.trustedHandoff = false,
    this.remember = true,
  });

  final String server;
  final String? device;
  final String? psk;

  /// One-time high-entropy invite code redeemed over authenticated Noise.
  /// The public demo's short admission code uses a client-held sealed result.
  final String? invite;
  final bool remember;

  /// True only after client-held decryption of an expected SSO completion.
  final bool trustedHandoff;

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
    trustedHandoff: other.trustedHandoff,
    remember: other.remember && remember,
  );
}

// --- Web connection persistence -------------------------------------------
//
// The connection (server URL + device id + pairing key) is persisted through
// the shared [ServerConnectionStore] (see `_WebRootState._store` /
// `_loadSavedCreds` / `_saveCreds`), the SAME store the Settings → server
// connection section writes — so a change in Settings is what the next reload
// resumes.

/// Reads connection hints from the current URL — a base64url-JSON or
/// query-string URL FRAGMENT only. Query parameters deliberately carry
/// nothing: a `?psk=` lands in the static host's access logs, proxies and
/// the browser's history and the invariant is that the PSK rides in the
/// fragment so it never reaches a server.
Future<_Creds> _readUrlHints() async {
  final base = Uri.base;
  String? server;
  String? device;
  String? psk;
  String? invite;
  var trustedHandoff = false;
  void take(String? s, void Function(String) set) {
    if (s != null && s.isNotEmpty) {
      set(s);
    }
  }

  final fragment = base.fragment;
  if (fragment.isNotEmpty) {
    var parsed = decodePairingFragment(fragment);
    final json = decodePairingJson(fragment);
    if (json != null && json.containsKey('box')) {
      final handoff = await openSsoWebFragment(json);
      if (handoff != null) {
        parsed = {'s': handoff.server, 'i': handoff.deviceId, 'k': handoff.psk};
        trustedHandoff = json['idpInitiated'] != true;
      }
    }
    if (parsed != null) {
      take(parsed['server'] ?? parsed['s'], (v) => server = v);
      take(parsed['device'] ?? parsed['i'], (v) => device = v);
      take(parsed['psk'] ?? parsed['k'], (v) => psk = v);
      take(parsed['invite'] ?? parsed['inv'], (v) => invite = v);
    }
  }
  return _Creds(
    server: server ?? '',
    device: device,
    psk: psk,
    invite: invite,
    trustedHandoff: trustedHandoff,
  );
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

/// The connection bootstrap: web can't self-serve, so it dials a cc-server.
/// The dialogs are pre-filled by the parent ([initial]): saved creds overlaid
/// by a fresh pairing deep link (a base64url-JSON or query-string URL
/// fragment, the PSK riding in the fragment so it never reaches the static
/// host).
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

  /// Resolves with the failure, or null once connected.
  final Future<Object?> Function({
    required String server,
    required String deviceId,
    required String psk,
    required String inviteCode,
    required bool remember,
  })
  onConnect;

  @override
  State<_ConnectGate> createState() => _ConnectGateState();
}

class _ConnectGateState extends State<_ConnectGate> {
  /// Defaults to remembering for a fresh device (reload-resume is the point),
  /// but honours a returning user's explicit opt-out.
  late final ValueNotifier<bool> _remember = ValueNotifier(
    widget.initial.remember || !widget.initial.isComplete,
  );
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    // An unbidden pairing link: the parent will not connect it, so show its
    // server and wait for the user to press Connect.
    if (!widget.connecting && (widget.initial.psk?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final host = _hostContext;
        if (mounted && host != null) {
          _openConnect(host);
        }
      });
    }
  }

  @override
  void dispose() {
    _remember.dispose();
    super.dispose();
  }

  /// A context under the dialog host's Navigator.
  BuildContext? _hostContext;

  Future<void> _connect(ServerConnectCredentials credentials) async {
    final failure = await widget.onConnect(
      server: credentials.rawUrl,
      deviceId: credentials.deviceId.isEmpty
          ? 'web-client'
          : credentials.deviceId,
      psk: credentials.psk,
      inviteCode: credentials.inviteCode,
      remember: _remember.value,
    );
    if (failure != null) {
      throw failure;
    }
  }

  /// Hides the landing's callout while a dialog shows the same failure.
  Future<void> _showDialog(BuildContext context, WidgetBuilder builder) async {
    setState(() => _dialogOpen = true);
    await showCcDialog<void>(context: context, builder: builder);
    if (mounted) {
      setState(() => _dialogOpen = false);
    }
  }

  void _openConnect(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initial = widget.initial;
    unawaited(
      _showDialog(
        context,
        (_) => ServerConnectDialog(
          title: l10n.connectToServer,
          intro: l10n.connectToServerIntro,
          prefillUrl: initial.server,
          prefillInvite: initial.invite ?? '',
          prefillDeviceId: initial.device ?? 'web-client',
          prefillPsk: initial.psk ?? '',
          onConnect: _connect,
          footer: _RememberChoice(remember: _remember),
        ),
      ),
    );
  }

  void _openPasteLink(BuildContext context) {
    unawaited(
      _showDialog(
        context,
        (_) => PairingLinkDialog(
          onConnect: _connect,
          footer: _RememberChoice(remember: _remember),
        ),
      ),
    );
  }

  Widget _buildLanding(BuildContext context) {
    _hostContext = context;
    final l10n = AppLocalizations.of(context);
    final idle = !widget.connecting;
    return ConnectLanding(
      subtitle: l10n.connectWelcomeSubtitleWeb,
      appearance: _webAppearance,
      error: _dialogOpen ? null : widget.error,
      actions: [
        ConnectAction(
          icon: AppIcons.cloud,
          label: l10n.connectToServer,
          primary: true,
          loading: widget.connecting && !_dialogOpen,
          onPressed: idle ? () => _openConnect(context) : null,
        ),
        ConnectAction(
          icon: AppIcons.link,
          label: l10n.connectPasteLink,
          onPressed: idle ? () => _openPasteLink(context) : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) =>
      ConnectDialogHost(builder: _buildLanding);
}

/// Informed opt-in: the key is sensitive. When checked it is kept in this
/// browser's localStorage so a reload reconnects; the deploy CSP (web/_headers)
/// limits the egress a foothold could use.
class _RememberChoice extends StatelessWidget {
  const _RememberChoice({required this.remember});

  final ValueNotifier<bool> remember;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ValueListenableBuilder<bool>(
      valueListenable: remember,
      builder: (context, value, _) => Row(
        children: [
          CcCheckbox(
            value: value,
            onChanged: (next) => remember.value = next,
            semanticLabel: l10n.webConnectStayConnected,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.webConnectStayConnectedDetail,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
