import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/app_windows.dart' show runServerSetupWindow;
import 'package:control_center/bootstrap/thin_client_boot.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_discovery.dart';
import 'package:control_center/core/server/server_pairing.dart';
import 'package:control_center/core/server/server_startup_status.dart';
import 'package:control_center/core/server/sso_login.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/desktop_update_lifecycle.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/server_activity_overlay.dart'
    show ServerStartupIndicator;
import 'package:control_center/shared/widgets/server_connect/connect_appearance.dart';
import 'package:control_center/shared/widgets/server_connect/connect_landing.dart';
import 'package:control_center/shared/widgets/server_connect/pairing_link_dialog.dart';
import 'package:control_center/shared/widgets/server_connect/server_connect_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The desktop's resolved backend: the resilient RPC client, its connection
/// supervisor (path + health for the connection pill) and — for the local
/// mode — the spawned `cc_server` to supervise.
class ServerBackend {
  /// Creates a backend handle.
  ServerBackend({
    required this.client,
    required this.supervisor,
    this.local,
    this.entry,
    this.mediaProxy,
  });

  /// The resilient RPC client (override `rpcClientProvider` with this). It
  /// survives path failovers and — for the local mode — server respawns.
  final ResilientRpcClient client;

  /// The connection supervisor: live path, latency and reconnect state.
  final ServerConnectionSupervisor supervisor;

  /// The local spawn handle, or null when connected to a remote server whose
  /// lifecycle is not ours to manage.
  final ThinClientBackend? local;

  /// The paired-server entry backing a remote connection (null for local).
  final ServerEntry? entry;

  /// Routes remote media (avatars, feed images, PR-body images/video) through
  /// the connected server's `/proxy/media` endpoint, so the desktop never
  /// fetches an upstream host directly. Null when the connection can't be
  /// expressed as a proxy base (e.g. relay-only with no HTTP path).
  final MediaProxyConfig? mediaProxy;

  /// Tears the whole backend down (used when switching servers in-app). For
  /// the local mode this also stops the spawned `cc_server` child.
  Future<void> dispose() async {
    if (local != null) {
      await local!.dispose();
    } else {
      await client.close();
    }
  }
}

/// Where [resolveServerBackend] gets each kind of backend from. The defaults
/// spawn the bundled `cc_server`, connect to a paired server and show the
/// pre-app setup window; tests pass fakes so the local-vs-remote decision is
/// checked without a process, a socket or a window.
class ServerBackendSources {
  /// Creates the sources, defaulting each to the real implementation.
  const ServerBackendSources({
    this.startLocal = _localBackend,
    this.connectRemote = _connectRemoteBackend,
    this.runSetup = _runServerSetup,
  });

  /// Spawns the bundled `cc_server` and connects to it over loopback. The
  /// ONLY way a local server process comes into existence.
  final Future<ServerBackend> Function() startLocal;

  /// Connects to a paired remote server with its stored pairing key.
  final Future<ServerBackend> Function(
    ServerConnectionStore store,
    ServerEntry entry,
    String psk,
  )
  connectRemote;

  /// Shows the pre-app setup screen (optionally with the error that sent
  /// the boot there) and resolves with the backend the user's choice made.
  final Future<ServerBackend> Function(
    ServerConnectionStore store, {
    Object? error,
  })
  runSetup;
}

/// Resolves how the desktop reaches its `cc_server`, returning a connected [ServerBackend].
/// The desktop opens no database — it must connect to a server that owns the data.
/// the [ReachabilityResolver] (best reachable + secure path wins) with the keychain-stored
/// pairing key and the TOFU-pinned fingerprint.
///
/// The bundled server is spawned ONLY when local is the target: a boot whose
/// persisted mode is remote, or a switch to a paired server, never starts one.
///
/// [forceServerId] is the in-app switch (`DesktopServerSwitcher.switchTo`):
/// see [_switchServerBackend] for how it differs from a boot.
Future<ServerBackend> resolveServerBackend({
  required AppPreferences prefs,
  required SecureStore secureStore,
  String? forceServerId,
  ServerBackendSources sources = const ServerBackendSources(),
}) async {
  final store = ServerConnectionStore(prefs, secureStore);

  if (forceServerId != null) {
    return _switchServerBackend(store, forceServerId, sources);
  }

  if (!store.isConfigured) {
    // A return to setup must not replay a failure from an earlier session.
    serverStartupStatus.value = null;
    return sources.runSetup(store);
  }

  if (store.readMode() == ServerConnectionMode.local) {
    // A configured-local boot can still fail to spawn a server — e.g. a dev
    // or unpackaged build where no `cc_server` is embedded beside the app and
    // none is locatable in the source tree. Fall back to the setup screen
    // with the error so the user can retry locally or switch to a remote
    // server, instead of crashing the boot.
    try {
      final backend = await sources.startLocal();
      serverStartupStatus.value = const ServerStartupStatus(
        phase: ServerStartupPhase.ready,
      );
      return backend;
    } on Object catch (e) {
      serverStartupStatus.value = ServerStartupStatus(
        phase: ServerStartupPhase.failed,
        error: e,
      );
      AppLog.w('cc_server', 'local server start failed, asking user: $e');
      return sources.runSetup(store, error: e);
    }
  }

  // Remote: resolve the active paired server. A missing entry/key or a failed
  // connect falls back to the setup screen (with the error) instead of
  // crashing the boot — the desktop cannot self-serve.
  serverStartupStatus.value = const ServerStartupStatus(
    phase: ServerStartupPhase.connecting,
  );
  final entry = store.readActive();
  if (entry != null) {
    try {
      // The keychain read is inside the try on purpose: it throws, it is the
      // FIRST thing this path does, and it happens before any window exists.
      // macOS refuses a keychain item to a binary whose signature no longer
      // matches the one that stored it — which is every rebuild of an
      // ad-hoc-signed debug build — so an uncaught throw here turned a stale
      // credential into a silent, windowless boot.
      final psk = await store.readPsk(entry.serverId);
      if (psk != null && psk.isNotEmpty) {
        final backend = await sources.connectRemote(store, entry, psk);
        serverStartupStatus.value = const ServerStartupStatus(
          phase: ServerStartupPhase.ready,
        );
        return backend;
      }
    } on Object catch (e) {
      serverStartupStatus.value = ServerStartupStatus(
        phase: ServerStartupPhase.failed,
        error: e,
      );
      AppLog.w('cc_server', 'remote connect failed, asking user: $e');
      return sources.runSetup(store, error: e);
    }
  }
  serverStartupStatus.value = null;
  return sources.runSetup(store);
}

/// The in-app switch to [serverId] (a paired server id, or [localServerId]).
///
/// Unlike a boot, the app is already running on another session that stays
/// live until this one has connected, so:
///  * a failure THROWS for the settings UI to show. It never falls back to
///    the setup screen, which replaces the whole running app and offers
///    "Run locally" — a second bundled server against the same data dir.
///  * an unknown server id throws instead of falling through to the persisted
///    mode, which spawned a second bundled server when that mode was local.
///  * the choice is persisted only once the new backend is up, so a failed
///    switch leaves the next boot (and the settings list) on the session that
///    is actually live.
///
/// The bundled server is spawned only for [localServerId]; switching to a
/// paired server never starts one. The local child of the session being left
/// is stopped when the caller disposes that session.
Future<ServerBackend> _switchServerBackend(
  ServerConnectionStore store,
  String serverId,
  ServerBackendSources sources,
) async {
  serverStartupStatus.value = ServerStartupStatus(
    phase: serverId == localServerId
        ? ServerStartupPhase.starting
        : ServerStartupPhase.connecting,
  );
  try {
    final ServerBackend backend;
    final Future<void> Function() persist;
    if (serverId == localServerId) {
      backend = await sources.startLocal();
      persist = () => store.setMode(ServerConnectionMode.local);
    } else {
      final entry = store.entry(serverId);
      if (entry == null) {
        throw StateError('No paired server with id "$serverId".');
      }
      final psk = await store.readPsk(serverId);
      if (psk == null || psk.isEmpty) {
        throw StateError(
          'No pairing key is stored for ${entry.name}. Pair with it again.',
        );
      }
      backend = await sources.connectRemote(store, entry, psk);
      persist = () async {
        await store.setMode(ServerConnectionMode.remote);
        await store.setActiveServer(serverId);
      };
    }
    try {
      await persist();
    } on Object {
      // The caller never sees this backend, so nobody else would stop a local
      // child it spawned.
      await backend.dispose();
      rethrow;
    }
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.ready,
    );
    return backend;
  } on Object catch (error) {
    serverStartupStatus.value = ServerStartupStatus(
      phase: ServerStartupPhase.failed,
      error: error,
    );
    rethrow;
  }
}

Future<ServerBackend> _connectRemoteBackend(
  ServerConnectionStore store,
  ServerEntry entry,
  String psk,
) async =>
    _remoteBackend(await connectToEntry(store: store, entry: entry, psk: psk));

ServerBackend _remoteBackend(RemoteServerConnection connection) =>
    ServerBackend(
      client: connection.client,
      supervisor: connection.supervisor,
      entry: connection.entry,
      mediaProxy: connection.mediaProxy,
    );

/// The sentinel "server id" the switcher uses for the local spawn.
const String localServerId = 'local';

Future<ServerBackend> _localBackend() async {
  final backend = await startThinClientBackend();
  return ServerBackend(
    client: backend.client,
    supervisor: backend.supervisor,
    local: backend,
    mediaProxy: backend.mediaProxy,
  );
}

/// Shows the pre-app setup screen and resolves with the backend the user's
/// choice produced (after a successful spawn/connect, which also persists the
/// choice so the next boot skips this screen).
Future<ServerBackend> _runServerSetup(
  ServerConnectionStore store, {
  Object? error,
}) => showServerSetup(store, error: error);

/// Shows the server setup window in place of whatever the root view renders
/// and resolves with the backend the user's choice produced.
///
/// The boot path reaches it through [resolveServerBackend]; the running app
/// returns here when the user leaves a lost server for the sign-in screen
/// (`DesktopServerSwitcher.returnToSetup`). [previousSessionClosed] completes
/// once the session being left is torn down: "Run locally" waits for it, so
/// the bundled server it starts never overlaps the one being stopped on the
/// same data directory.
Future<ServerBackend> showServerSetup(
  ServerConnectionStore store, {
  Object? error,
  Future<void>? previousSessionClosed,
}) {
  final completer = Completer<ServerBackend>();
  // Render in a real native window via `runServerSetupWindow` — NOT a bare
  // `runApp`. The macOS runner is headless (windows are created in Dart by the
  // windowing layer), so a plain `runApp` into the implicit view never shows;
  // the screen would build but no window would appear. Once the user resolves,
  // the bootstrap runs the main `AppWindows` tree, which replaces this window.
  runServerSetupWindow(
    ProviderScope(
      child: DesktopUpdateLifecycle(
        child: ServerSetupApp(
          store: store,
          initialError: error,
          previousSessionClosed: previousSessionClosed,
          onResolved: completer.complete,
        ),
      ),
    ),
  );
  return completer.future;
}

/// Minimal Material-free app that hosts the server-setup screen before the full
/// app boots. Themed by [CcTheme] off the OS appearance or the operator's saved
/// choice, and localized via the app's l10n delegates. Its isolated provider
/// scope runs only the updater; no authenticated providers or database are
/// mounted before server admission.
class ServerSetupApp extends StatefulWidget {
  /// Creates the standalone setup surface, independent of native window hosting.
  const ServerSetupApp({
    super.key,
    required this.store,
    required this.initialError,
    required this.previousSessionClosed,
    required this.onResolved,
    this.discovery = const ServerDiscovery(),
  });

  /// Saved server choices and device credentials.
  final ServerConnectionStore store;

  /// The failed boot attempt that brought the user back to setup.
  final Object? initialError;

  /// Completes when the previous session has released its local server.
  final Future<void>? previousSessionClosed;

  /// Adopts the backend after a successful connection.
  final ValueChanged<ServerBackend> onResolved;

  /// Server discovery, shared with the URL field's discovery control.
  final ServerDiscovery discovery;

  @override
  State<ServerSetupApp> createState() => _ServerSetupAppState();
}

class _ServerSetupAppState extends State<ServerSetupApp> {
  late final ConnectAppearance _appearance = ConnectAppearance(
    widget.store.preferences,
  );

  @override
  void dispose() {
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appearance,
      builder: (context, _) {
        final dark = _appearance.isDark(
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
        );
        final themeData = dark ? CcThemeData.dark() : CcThemeData.light();
        return CcTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              final t = context.designSystem ?? themeData.tokens;
              final screen = _ServerSetupScreen(
                store: widget.store,
                appearance: _appearance,
                initialError: widget.initialError,
                previousSessionClosed: widget.previousSessionClosed,
                onResolved: widget.onResolved,
                discovery: widget.discovery,
              );
              return WidgetsApp(
                debugShowCheckedModeBanner: false,
                color: t.bgBrandSolid,
                title: 'Control Center',
                locale: _appearance.locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: kSupportedAppLocales,
                localeResolutionCallback: resolveAppLocale,
                textStyle: CcFonts.ui(textStyle: CcTypography.body).copyWith(
                  color: t.textPrimary,
                  decoration: TextDecoration.none,
                ),
                builder: (context, child) => ServerStartupIndicator(
                  showFailures: false,
                  child: child ?? const SizedBox.shrink(),
                ),
                pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
                  settings: settings,
                  pageBuilder: (c, _, _) => builder(c),
                ),
                // This transient pre-app surface has exactly one screen. Ignore
                // any OS-supplied initial route (a restored deep path such as
                // '/settings/repositories', which the real GoRouter owns) so
                // the named-route resolver does not log "Could not navigate to
                // initial route" and fall back before the full app boots.
                onGenerateRoute: (settings) => PageRouteBuilder<void>(
                  settings: settings,
                  pageBuilder: (c, _, _) => screen,
                ),
                onGenerateInitialRoutes: (_) => [
                  PageRouteBuilder<void>(
                    settings: const RouteSettings(name: '/'),
                    pageBuilder: (c, _, _) => screen,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ServerSetupScreen extends StatefulWidget {
  const _ServerSetupScreen({
    required this.store,
    required this.appearance,
    required this.initialError,
    required this.previousSessionClosed,
    required this.onResolved,
    required this.discovery,
  });

  final ServerConnectionStore store;
  final ConnectAppearance appearance;
  final Object? initialError;

  /// Completes once the app session this screen replaced is torn down (null
  /// on boot, where there was none). Gates the local spawn.
  final Future<void>? previousSessionClosed;
  final ValueChanged<ServerBackend> onResolved;
  final ServerDiscovery discovery;

  @override
  State<_ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<_ServerSetupScreen> {
  /// How this client last ran, which decides the screen's main action.
  late final ServerConnectionMode _lastMode = widget.store.readMode();

  bool _startingLocal = false;
  bool _pairing = false;
  bool _resolved = false;
  Object? _error;

  bool get _busy => _startingLocal || _pairing;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
    pendingSsoPairLink.addListener(_onPendingPairLink);
    if (pendingSsoPairLink.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onPendingPairLink();
        }
      });
    }
  }

  @override
  void dispose() {
    pendingSsoPairLink.removeListener(_onPendingPairLink);
    cancelSsoLogin();
    super.dispose();
  }

  /// A new attempt replaces the last one's failure, in the callout and in the
  /// activity panel alike.
  void _clearError() {
    setState(() => _error = null);
    serverStartupStatus.value = null;
  }

  void _onPendingPairLink() {
    final rawUrl = pendingSsoPairLink.value;
    if (rawUrl == null || _resolved) {
      return;
    }
    pendingSsoPairLink.value = null;
    unawaited(_resolvePairLink(rawUrl));
  }

  /// Finishes an SSO round-trip the connect dialog started. The credential
  /// comes back on the `control-center://pair` channel, not through the
  /// dialog, so a failure closes it to reach the callout.
  Future<void> _resolvePairLink(String rawUrl) async {
    final payload = await decodeSsoPairLink(rawUrl);
    if (payload == null || !mounted) {
      return;
    }
    if (payload.unsolicited) {
      final l10n = AppLocalizations.of(context);
      final approved = await showCcDialog<bool>(
        context: context,
        builder: (dialogContext) => CcDialog(
          title: l10n.ssoPairConfirmTitle,
          content: Text(l10n.ssoPairConfirmBody(payload.server)),
          actions: [
            CcButton(
              variant: CcButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.ssoPairConfirmCancel),
            ),
            CcButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.ssoPairConfirmConnect),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) {
        return;
      }
    }
    setState(() => _pairing = true);
    try {
      await _connect((
        rawUrl: payload.server,
        inviteCode: '',
        deviceId: payload.deviceId,
        psk: payload.psk,
      ));
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {
        _pairing = false;
        _error = e;
      });
    }
  }

  /// Pairs and adopts the server. A failure stays with the caller, which shows
  /// it beside the credentials that caused it.
  Future<void> _connect(ServerConnectCredentials credentials) async {
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.connecting,
    );
    try {
      final connection = await pairWithServer(
        store: widget.store,
        rawUrl: credentials.rawUrl,
        platform: 'desktop',
        inviteCode: credentials.inviteCode,
        deviceId: credentials.deviceId,
        psk: credentials.psk,
      );
      serverStartupStatus.value = const ServerStartupStatus(
        phase: ServerStartupPhase.ready,
      );
      _resolved = true;
      widget.onResolved(_remoteBackend(connection));
    } on Object catch (e) {
      serverStartupStatus.value = ServerStartupStatus(
        phase: ServerStartupPhase.failed,
        error: e,
      );
      rethrow;
    }
  }

  Future<void> _runLocal() async {
    setState(() {
      _startingLocal = true;
      _error = null;
    });
    try {
      serverStartupStatus.value = const ServerStartupStatus(
        phase: ServerStartupPhase.starting,
      );
      await widget.previousSessionClosed;
      final backend = await _localBackend();
      try {
        await widget.store.setMode(ServerConnectionMode.local);
      } on Object {
        // The landing stays up with the error, and the user may now choose a
        // remote server instead: the child spawned above must not survive.
        await backend.dispose();
        rethrow;
      }
      serverStartupStatus.value = const ServerStartupStatus(
        phase: ServerStartupPhase.ready,
      );
      widget.onResolved(backend);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      serverStartupStatus.value = ServerStartupStatus(
        phase: ServerStartupPhase.failed,
        error: e,
      );
      setState(() {
        _startingLocal = false;
        _error = e;
      });
    }
  }

  void _openConnect() {
    _clearError();
    final l10n = AppLocalizations.of(context);
    final active = widget.store.readActive();
    unawaited(
      showCcDialog<void>(
        context: context,
        builder: (_) => ServerConnectDialog(
          title: l10n.connectToServer,
          intro: l10n.connectToServerIntro,
          prefillUrl:
              active?.descriptor.paths.firstOrNull?.rpcUri?.toString() ?? '',
          prefillDeviceId: active?.deviceId ?? '',
          discovery: widget.discovery,
          onConnect: _connect,
        ),
      ),
    );
  }

  void _openPasteLink() {
    _clearError();
    unawaited(
      showCcDialog<void>(
        context: context,
        builder: (_) => PairingLinkDialog(onConnect: _connect),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remoteFirst = _lastMode == ServerConnectionMode.remote;
    final local = ConnectAction(
      icon: AppIcons.monitor,
      label: l10n.serverSetupRunLocal,
      primary: !remoteFirst,
      loading: _startingLocal,
      onPressed: _busy ? null : () => unawaited(_runLocal()),
    );
    final connect = ConnectAction(
      icon: AppIcons.cloud,
      label: l10n.connectToServer,
      primary: remoteFirst,
      onPressed: _busy ? null : _openConnect,
    );
    return ConnectLanding(
      subtitle: l10n.connectWelcomeSubtitle,
      appearance: widget.appearance,
      error: _error,
      actions: [
        if (remoteFirst) ...[connect, local] else ...[local, connect],
        ConnectAction(
          icon: AppIcons.link,
          label: l10n.connectPasteLink,
          onPressed: _busy ? null : _openPasteLink,
        ),
      ],
    );
  }
}
