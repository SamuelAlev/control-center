import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/app_windows.dart' show runServerSetupWindow;
import 'package:control_center/bootstrap/thin_client_boot.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/auth_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_entry_factory.dart';
import 'package:control_center/core/server/server_pairing.dart';
import 'package:control_center/core/server/sso_login.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart'
    show ConnectionErrorAlert, UserFacingMessage;
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/server_discovery_button.dart';
import 'package:flutter/widgets.dart';

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
    // First run: ask the user how Control Center should run.
    return sources.runSetup(store);
  }

  if (store.readMode() == ServerConnectionMode.local) {
    // A configured-local boot can still fail to spawn a server — e.g. a dev
    // or unpackaged build where no `cc_server` is embedded beside the app and
    // none is locatable in the source tree. Fall back to the setup screen
    // with the error so the user can retry locally or switch to a remote
    // server, instead of crashing the boot.
    try {
      return await sources.startLocal();
    } on Object catch (e) {
      AppLog.w('cc_server', 'local server start failed, asking user: $e');
      return sources.runSetup(store, error: e);
    }
  }

  // Remote: resolve the active paired server. A missing entry/key or a failed
  // connect falls back to the setup screen (with the error) instead of
  // crashing the boot — the desktop cannot self-serve.
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
        return await sources.connectRemote(store, entry, psk);
      }
    } on Object catch (e) {
      AppLog.w('cc_server', 'remote connect failed, asking user: $e');
      return sources.runSetup(store, error: e);
    }
  }
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
  return backend;
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
    _ServerSetupApp(
      store: store,
      initialError: error,
      previousSessionClosed: previousSessionClosed,
      onResolved: completer.complete,
    ),
  );
  return completer.future;
}

/// Minimal Material-free app that hosts the server-setup screen before the full
/// app boots. Themed by [CcTheme] off the OS appearance and localized via the
/// app's l10n delegates (no Riverpod, no database — there is no server yet).
class _ServerSetupApp extends StatelessWidget {
  const _ServerSetupApp({
    required this.store,
    required this.initialError,
    required this.previousSessionClosed,
    required this.onResolved,
  });

  final ServerConnectionStore store;
  final Object? initialError;
  final Future<void>? previousSessionClosed;
  final ValueChanged<ServerBackend> onResolved;

  @override
  Widget build(BuildContext context) {
    final dark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final themeData = dark ? CcThemeData.dark() : CcThemeData.light();
    return CcTheme(
      data: themeData,
      child: Builder(
        builder: (context) {
          final t = context.designSystem ?? themeData.tokens;
          final screen = _ServerSetupScreen(
            store: store,
            initialError: initialError,
            previousSessionClosed: previousSessionClosed,
            onResolved: onResolved,
          );
          return WidgetsApp(
            debugShowCheckedModeBanner: false,
            color: t.bgBrandSolid,
            title: 'Control Center',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            textStyle: CcFonts.ui(
              textStyle: CcTypography.body,
            ).copyWith(color: t.textPrimary, decoration: TextDecoration.none),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (c, _, _) => builder(c),
            ),
            // This transient pre-app surface has exactly one screen. Ignore any
            // OS-supplied initial route (a restored deep path such as
            // '/settings/repositories', which the real GoRouter owns) so the
            // named-route resolver does not log "Could not navigate to initial
            // route" and fall back before the full app boots.
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
  }
}

class _ServerSetupScreen extends StatefulWidget {
  const _ServerSetupScreen({
    required this.store,
    required this.initialError,
    required this.previousSessionClosed,
    required this.onResolved,
  });

  final ServerConnectionStore store;
  final Object? initialError;

  /// Completes once the app session this screen replaced is torn down (null
  /// on boot, where there was none). Gates the local spawn.
  final Future<void>? previousSessionClosed;
  final ValueChanged<ServerBackend> onResolved;

  @override
  State<_ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<_ServerSetupScreen> {
  late ServerConnectionMode _mode = widget.store.readMode();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _invite = TextEditingController();
  final TextEditingController _device = TextEditingController();
  final TextEditingController _psk = TextEditingController();

  bool _busy = false;
  Object? _error;

  // The unauthenticated /auth/providers probe adapts the form the moment
  // the URL names a server: one "Sign in with <label>" button per offered
  // SSO connection (SAML, OIDC, …), the browser round-trip hands the
  // credential back through the control-center://pair link and the manual
  // invite/pairing fields stay available unless the server disabled pairing.
  AuthProvidersSnapshot? _auth;
  String? _probedOrigin;
  AuthProviderInfo? _ssoBusyProvider;
  bool _awaitingBrowser = false;
  Timer? _ssoProbeDebounce;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
    final active = widget.store.readActive();
    if (active != null) {
      final path = active.descriptor.paths.firstOrNull;
      _url.text = path?.rpcUri?.toString() ?? '';
      _device.text = active.deviceId;
    }
    _url.addListener(_scheduleSsoProbe);
    _scheduleSsoProbe();
    pendingSsoPairLink.addListener(_onPendingPairLink);
  }

  @override
  void dispose() {
    _url.removeListener(_scheduleSsoProbe);
    pendingSsoPairLink.removeListener(_onPendingPairLink);
    _ssoProbeDebounce?.cancel();
    cancelSsoLogin();
    _url.dispose();
    _invite.dispose();
    _device.dispose();
    _psk.dispose();
    super.dispose();
  }

  List<AuthProviderInfo> get _ssoProviders =>
      _auth?.providers ?? const <AuthProviderInfo>[];

  bool get _pairingAllowed => _auth?.pairingEnabled ?? true;

  /// Switches between the local and remote options. Re-runs the probe: the
  /// URL field can already carry a value (restored from the active entry, or
  /// typed before a detour through "run locally"), and the field's own
  /// listener never fires for it — so without this the SSO buttons would
  /// only ever appear after the user edited an address that was already
  /// correct.
  void _selectMode(ServerConnectionMode mode) {
    setState(() => _mode = mode);
    _scheduleSsoProbe();
  }

  void _scheduleSsoProbe() {
    _ssoProbeDebounce?.cancel();
    final origin = httpOriginFor(_url.text);
    final remote = _mode == ServerConnectionMode.remote;
    if (!remote || origin == null) {
      if (_auth != null) {
        setState(() => _auth = null);
      }
      return;
    }
    if (_auth != null && _probedOrigin == origin) {
      return; // Already probed this exact origin.
    }
    _ssoProbeDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_probeSso(origin));
    });
  }

  /// Silent availability probe — failures simply leave the manual form.
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

  /// Opens the browser for one provider's SSO round-trip; the bounce page
  /// hands the minted credential back as a `control-center://pair` link,
  /// which the platform channel parks on [pendingSsoPairLink] while the
  /// setup window is still up (no session exists to adopt it directly), so
  /// the round-trip resolves through [_onPendingPairLink] rather than here.
  Future<void> _startSso(AuthProviderInfo provider) async {
    final l10n = AppLocalizations.of(context);
    final origin = httpOriginFor(_url.text);
    if (origin == null) {
      setState(() => _error = UserFacingMessage(l10n.serverSetupInvalidUrl));
      return;
    }
    setState(() {
      _ssoBusyProvider = provider;
      _error = null;
    });
    try {
      await startSsoLogin(
        provider: provider,
        origin: origin,
        onAwaiting: () {
          if (mounted) {
            setState(() {
              _ssoBusyProvider = null;
              _awaitingBrowser = true;
            });
          }
        },
      );
    } on SsoBrowserOpenException {
      if (mounted) {
        setState(() {
          _ssoBusyProvider = null;
          _awaitingBrowser = false;
          _error = UserFacingMessage(l10n.ssoBrowserOpenFailed);
        });
      }
    }
  }

  void _onPendingPairLink() {
    final rawUrl = pendingSsoPairLink.value;
    if (rawUrl == null || _resolved) {
      return;
    }
    pendingSsoPairLink.value = null;
    unawaited(_resolvePairLink(rawUrl));
  }

  Future<void> _resolvePairLink(String rawUrl) async {
    final payload = decodeSsoPairLink(rawUrl);
    if (payload == null) {
      return;
    }
    // A bounce for a round-trip THIS window started is expected; anything
    // else (a cold-launch link, a forwarded/forged one) must be confirmed —
    // the link carries a credential for whatever server it names and
    // anyone can craft one.
    if (!isSsoLoginInFlight()) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showCcConfirmDialog(
        context: context,
        title: l10n.ssoPairConfirmTitle,
        message: l10n.ssoPairConfirmBody(payload.server),
        confirmLabel: l10n.ssoPairConfirmConnect,
        cancelLabel: l10n.ssoPairConfirmCancel,
      );
      if (!confirmed) {
        if (mounted) {
          setState(() => _awaitingBrowser = false);
        }
        return;
      }
    }
    ssoLoginStartedAt.value = null; // Consumed by this bounce.
    setState(() => _busy = true);
    try {
      final entry = await ServerEntryFactory.fromManualUrl(
        rawUrl: payload.server,
        deviceId: payload.deviceId,
      );
      if (entry == null) {
        throw StateError(
          'The SSO server did not answer its identity probe '
          '(${payload.server})',
        );
      }
      // Connect FIRST — this verifies the server's Ed25519 identity — then
      // persist: a failed or impostor connect must never write an entry
      // (the same invariant `pairWithServer` applies to manual pairing).
      final connection = await connectToEntry(
        store: widget.store,
        entry: entry,
        psk: payload.psk,
      );
      await widget.store.upsertEntry(
        connection.supervisor.pinnedFingerprint.isNotEmpty
            ? entry.withPin(connection.supervisor.pinnedFingerprint)
            : entry,
        psk: payload.psk,
      );
      await widget.store.setMode(ServerConnectionMode.remote);
      await widget.store.setActiveServer(entry.serverId);
      _resolved = true;
      widget.onResolved(_remoteBackend(connection));
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _awaitingBrowser = false;
        _error = e;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_mode == ServerConnectionMode.local) {
        await widget.previousSessionClosed;
        final backend = await _localBackend();
        try {
          await widget.store.setMode(ServerConnectionMode.local);
        } on Object {
          // The form stays up with the error, and the user may now choose a
          // remote server instead: the child spawned above must not survive.
          await backend.dispose();
          rethrow;
        }
        widget.onResolved(backend);
        return;
      }

      if (normalizeServerUrl(_url.text) == null) {
        setState(() {
          _busy = false;
          _error = UserFacingMessage(l10n.serverSetupInvalidUrl);
        });
        return;
      }
      final connection = await pairWithServer(
        store: widget.store,
        rawUrl: _url.text,
        platform: 'desktop',
        inviteCode: _invite.text,
        deviceId: _device.text.trim(),
        psk: _psk.text.trim(),
      );
      widget.onResolved(_remoteBackend(connection));
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final isRemote = _mode == ServerConnectionMode.remote;
    final hasInvite = _invite.text.trim().isNotEmpty;
    return ColoredBox(
      color: t.bgPrimary,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: CcCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.radio, size: 22, color: t.fgBrandPrimary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.serverSetupTitle,
                          style: CcTypography.title.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.serverSetupSubtitle,
                    style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _OptionTile(
                    icon: AppIcons.monitor,
                    title: l10n.serverModeLocal,
                    description: l10n.serverModeLocalDescription,
                    selected: _mode == ServerConnectionMode.local,
                    onTap: _busy
                        ? null
                        : () => _selectMode(ServerConnectionMode.local),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _OptionTile(
                    icon: AppIcons.cloud,
                    title: l10n.serverModeRemote,
                    description: l10n.serverModeRemoteDescription,
                    selected: isRemote,
                    onTap: _busy
                        ? null
                        : () => _selectMode(ServerConnectionMode.remote),
                  ),
                  if (isRemote) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _field(
                      t,
                      l10n.serverRemoteUrl,
                      _url,
                      hint: 'wss://host:9030/rpc',
                      // LAN + tailnet discovery behind a suffix button: the
                      // button badges the found count, the dialog lists the
                      // servers and a pick fills this field.
                      suffix: ServerDiscoveryButton(
                        onSelected: (server) =>
                            setState(() => _url.text = server.rpcUrl),
                      ),
                    ),
                    for (final provider in _ssoProviders) ...[
                      const SizedBox(height: AppSpacing.md),
                      CcButton(
                        onPressed: (_busy || _ssoBusyProvider != null)
                            ? null
                            : () => unawaited(_startSso(provider)),
                        variant: CcButtonVariant.secondary,
                        loading: identical(_ssoBusyProvider, provider),
                        fullWidth: true,
                        child: Text(l10n.ssoSignInWith(provider.label)),
                      ),
                    ],
                    if (_ssoProviders.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _awaitingBrowser
                            ? l10n.ssoWaitingForBrowser
                            : l10n.ssoOpensBrowser,
                        style: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_pairingAllowed) ...[
                      const SizedBox(height: AppSpacing.md),
                      _field(
                        t,
                        l10n.serverSetupInviteCode,
                        _invite,
                        hint: l10n.serverSetupInviteCodeHint,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    if (!hasInvite && _pairingAllowed) ...[
                      const SizedBox(height: AppSpacing.md),
                      _field(t, l10n.serverRemoteDeviceId, _device),
                      const SizedBox(height: AppSpacing.md),
                      _field(
                        t,
                        l10n.serverRemotePairingKey,
                        _psk,
                        hint: l10n.serverRemotePairingKeyHint,
                        obscure: true,
                      ),
                    ],
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    ConnectionErrorAlert(error: _error!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Pairing disabled server-side = SSO-only onboarding: no
                  // manual submit (matches the web connect gate).
                  if (!isRemote || _pairingAllowed)
                    CcButton(
                      onPressed: _busy ? null : _submit,
                      variant: CcButtonVariant.accent,
                      loading: _busy,
                      fullWidth: true,
                      child: Text(
                        isRemote
                            ? l10n.serverSetupConnect
                            : l10n.serverSetupRunLocal,
                      ),
                    ),
                ],
              ),
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
    ValueChanged<String>? onChanged,
    Widget? suffix,
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
          enabled: !_busy,
          onChanged: onChanged,
          suffix: suffix,
        ),
      ],
    );
  }
}

/// A tappable, selectable option card (icon + title + description + check).
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? t.bgBrandPrimary : t.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? t.borderBrand : t.borderPrimary,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? t.fgBrandPrimary : t.fgTertiary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CcTypography.body.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              selected ? AppIcons.circleCheck : AppIcons.circle,
              size: 18,
              color: selected ? t.fgBrandPrimary : t.borderPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
