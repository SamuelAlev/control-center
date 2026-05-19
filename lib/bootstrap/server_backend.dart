import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/app_windows.dart' show runServerSetupWindow;
import 'package:control_center/bootstrap/thin_client_boot.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_pairing.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart'
    show ConnectionErrorAlert, UserFacingMessage;
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/server_discovery_button.dart';
import 'package:flutter/widgets.dart';

/// The desktop's resolved backend: the resilient RPC client, its connection
/// supervisor (path + health for the connection pill), and — for the local
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

  /// The connection supervisor: live path, latency, and reconnect state.
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

  /// Tears the whole backend down (used when switching servers in-app).
  Future<void> dispose() async {
    if (local != null) {
      await local!.dispose();
    } else {
      await client.close();
    }
  }
}

/// Resolves how the desktop reaches its `cc_server`, returning a connected
/// [ServerBackend].
///
/// The desktop opens no database — it must connect to a server that owns the
/// data. This reads the persisted server list ([ServerConnectionStore]):
///   * **local** → spawns and connects a local `cc_server`
///     ([startThinClientBackend]) with automatic respawn.
///   * **remote** → resolves the active [ServerEntry]'s descriptor through
///     the [ReachabilityResolver] (best reachable + secure path wins) with
///     the keychain-stored pairing key and the TOFU-pinned fingerprint.
///   * **first run / unconfigured / failed connect** → shows the pre-app
///     setup screen so the user chooses (local, invite code, or manual URL).
///
/// [forceServerId] connects to a specific paired server (the in-app server
/// switch); it also flips the persisted mode/active-server so the next boot
/// lands there too. Runs before the `ProviderContainer` exists, so it takes
/// the storage backends directly rather than reading them through Riverpod.
Future<ServerBackend> resolveServerBackend({
  required AppPreferences prefs,
  required SecureStore secureStore,
  String? forceServerId,
}) async {
  final store = ServerConnectionStore(prefs, secureStore);

  if (forceServerId != null) {
    if (forceServerId == localServerId) {
      await store.setMode(ServerConnectionMode.local);
    } else {
      final entry = store.entry(forceServerId);
      if (entry != null) {
        await store.setMode(ServerConnectionMode.remote);
        await store.setActiveServer(forceServerId);
      }
    }
  }

  if (!store.isConfigured) {
    // First run: ask the user how Control Center should run.
    return _runServerSetup(store);
  }

  if (store.readMode() == ServerConnectionMode.local) {
    // A configured-local boot can still fail to spawn a server — e.g. a dev
    // or unpackaged build where no `cc_server` is embedded beside the app and
    // none is locatable in the source tree. Fall back to the setup screen
    // with the error so the user can retry locally or switch to a remote
    // server, instead of crashing the boot.
    try {
      return await _localBackend();
    } on Object catch (e) {
      AppLog.w('cc_server', 'local server start failed, asking user: $e');
      return _runServerSetup(store, error: e);
    }
  }

  // Remote: resolve the active paired server. A missing entry/key or a failed
  // connect falls back to the setup screen (with the error) instead of
  // crashing the boot — the desktop cannot self-serve.
  final entry = store.readActive();
  if (entry != null) {
    final psk = await store.readPsk(entry.serverId);
    if (psk != null && psk.isNotEmpty) {
      try {
        return _remoteBackend(
          await connectToEntry(store: store, entry: entry, psk: psk),
        );
      } on Object catch (e) {
        AppLog.w('cc_server', 'remote connect failed, asking user: $e');
        return _runServerSetup(store, error: e);
      }
    }
  }
  return _runServerSetup(store);
}

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
    required this.onResolved,
  });

  final ServerConnectionStore store;
  final Object? initialError;
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
    required this.onResolved,
  });

  final ServerConnectionStore store;
  final Object? initialError;
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
  }

  @override
  void dispose() {
    _url.dispose();
    _invite.dispose();
    _device.dispose();
    _psk.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_mode == ServerConnectionMode.local) {
        final backend = await _localBackend();
        await widget.store.setMode(ServerConnectionMode.local);
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
                        : () => setState(
                            () => _mode = ServerConnectionMode.local,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _OptionTile(
                    icon: AppIcons.cloud,
                    title: l10n.serverModeRemote,
                    description: l10n.serverModeRemoteDescription,
                    selected: isRemote,
                    onTap: _busy
                        ? null
                        : () => setState(
                            () => _mode = ServerConnectionMode.remote,
                          ),
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
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      t,
                      l10n.serverSetupInviteCode,
                      _invite,
                      hint: l10n.serverSetupInviteCodeHint,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (!hasInvite) ...[
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
