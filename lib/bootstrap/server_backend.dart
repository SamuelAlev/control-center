import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient, connectRemoteRpc;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/app_windows.dart' show runServerSetupWindow;
import 'package:control_center/bootstrap/thin_client_boot.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/cc_server_process.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';

/// The desktop's resolved backend: the connected RPC client plus, for the local
/// mode, the spawned `cc_server` process to supervise. [process] is null for a
/// remote connection — that server's lifecycle is not ours to manage.
class ServerBackend {
  /// Creates a backend handle.
  ServerBackend({required this.client, this.process, this.mediaProxy});

  /// The connected RPC client (override `rpcClientProvider` with this).
  final RemoteRpcClient client;

  /// The supervised local `cc_server` child, or null when connected to a remote
  /// server we did not spawn.
  final CcServerProcess? process;

  /// Routes remote media (avatars, feed images, PR-body images/video) through
  /// the connected server's `/proxy/media` endpoint, so the desktop never
  /// fetches an upstream host directly — every outbound fetch goes through
  /// `cc_server`. Null when the connection can't be expressed as a proxy base.
  final MediaProxyConfig? mediaProxy;
}

/// Resolves how the desktop reaches its `cc_server`, returning a connected
/// [ServerBackend].
///
/// The desktop opens no database — it must connect to a server that owns the
/// data. This reads the persisted [ServerConnectionConfig]:
///   * **local** → spawns and connects a local `cc_server` ([startThinClientBackend]).
///   * **remote** → dials the configured URL with the keychain-stored pairing key.
///   * **first run / unconfigured / failed remote** → shows the pre-app setup
///     screen so the user chooses (and, for remote, fixes a bad URL/key).
///
/// Runs before the `ProviderContainer` exists, so it takes the storage backends
/// directly rather than reading them through Riverpod.
Future<ServerBackend> resolveServerBackend({
  required AppPreferences prefs,
  required SecureStore secureStore,
}) async {
  final store = ServerConnectionStore(prefs, secureStore);
  if (!store.isConfigured) {
    // First run: ask the user how Control Center should run.
    return _runServerSetup(store, initial: ServerConnectionConfig.localDefault);
  }

  final config = store.read();
  if (config.mode == ServerConnectionMode.local) {
    // A configured-local boot can still fail to spawn a server — e.g. a dev or
    // unpackaged build where no `cc_server` is embedded beside the app and none
    // is locatable in the source tree, or a moved/renamed app. Fall back to the
    // setup screen with the error (symmetric with the remote path below) so the
    // user can retry locally or switch to a remote server, instead of crashing
    // the boot on an uncaught exception.
    try {
      final backend = await startThinClientBackend();
      return ServerBackend(
        client: backend.client,
        process: backend.process,
        mediaProxy: backend.mediaProxy,
      );
    } on Object catch (e) {
      AppLog.w('cc_server', 'local server start failed, asking user: $e');
      return _runServerSetup(store, initial: config, error: '$e');
    }
  }

  // Remote: dial the configured server. A missing URL/key or a failed connect
  // falls back to the setup screen (prefilled, with the error) instead of
  // crashing the boot — the desktop cannot self-serve.
  final dialUrl = ServerConnectionConfig.normalizeRemoteUrl(config.remoteUrl);
  if (config.isRemoteComplete && dialUrl != null) {
    final psk = await store.readPsk();
    if (psk != null && psk.isNotEmpty) {
      try {
        final client = await connectRemoteRpc(
          uri: Uri.parse(dialUrl),
          deviceId: config.remoteDeviceId,
          psk: psk,
        );
        AppLog.i(
          'cc_server',
          'connected to remote server ${config.remoteUrl}',
        );
        return ServerBackend(
          client: client,
          mediaProxy: MediaProxyConfig.fromConnection(
            serverUri: Uri.parse(dialUrl),
            deviceId: config.remoteDeviceId,
            psk: psk,
          ),
        );
      } on Object catch (e) {
        AppLog.w('cc_server', 'remote connect failed, asking user: $e');
        return _runServerSetup(store, initial: config, error: '$e');
      }
    }
  }
  return _runServerSetup(store, initial: config);
}

/// Shows the pre-app setup screen and resolves with the backend the user's
/// choice produced (after a successful spawn/connect, which also persists the
/// choice so the next boot skips this screen).
Future<ServerBackend> _runServerSetup(
  ServerConnectionStore store, {
  required ServerConnectionConfig initial,
  String? error,
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
      initial: initial,
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
    required this.initial,
    required this.initialError,
    required this.onResolved,
  });

  final ServerConnectionStore store;
  final ServerConnectionConfig initial;
  final String? initialError;
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
            initial: initial,
            initialError: initialError,
            onResolved: onResolved,
          );
          return WidgetsApp(
            debugShowCheckedModeBanner: false,
            color: t.bgBrandSolid,
            title: 'Control Center',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            textStyle: CcFonts.ui(textStyle: CcTypography.body).copyWith(
              color: t.textPrimary,
              decoration: TextDecoration.none,
            ),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (c, _, _) => builder(c),
            ),
            // This transient pre-app surface has exactly one screen. Ignore any
            // OS-supplied initial route (a restored deep path such as
            // '/settings/repositories', which the real GoRouter owns) so the
            // named-route resolver does not log "Could not navigate to initial
            // route" and fall back before the full app boots.
            //
            // `onGenerateRoute` (rather than `home`) keeps the navigator active
            // so `onGenerateInitialRoutes` is honored — `home` is mutually
            // exclusive with `onGenerateInitialRoutes`. Both always resolve to
            // the same single setup screen.
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
    required this.initial,
    required this.initialError,
    required this.onResolved,
  });

  final ServerConnectionStore store;
  final ServerConnectionConfig initial;
  final String? initialError;
  final ValueChanged<ServerBackend> onResolved;

  @override
  State<_ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<_ServerSetupScreen> {
  late ServerConnectionMode _mode = widget.initial.mode;
  late final TextEditingController _url = TextEditingController(
    text: widget.initial.remoteUrl,
  );
  late final TextEditingController _device = TextEditingController(
    text: widget.initial.remoteDeviceId,
  );
  final TextEditingController _psk = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _url.dispose();
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
        final backend = await startThinClientBackend();
        await widget.store.save(ServerConnectionConfig.localDefault);
        widget.onResolved(
          ServerBackend(
            client: backend.client,
            process: backend.process,
            mediaProxy: backend.mediaProxy,
          ),
        );
        return;
      }

      final normalizedUrl = ServerConnectionConfig.normalizeRemoteUrl(
        _url.text,
      );
      if (normalizedUrl == null) {
        setState(() {
          _busy = false;
          _error = l10n.serverSetupInvalidUrl;
        });
        return;
      }
      final deviceId = _device.text.trim().isEmpty
          ? ServerConnectionConfig.defaultRemoteDeviceId
          : _device.text.trim();
      final psk = _psk.text.trim();
      final client = await connectRemoteRpc(
        uri: Uri.parse(normalizedUrl),
        deviceId: deviceId,
        psk: psk,
      );
      await widget.store.save(
        ServerConnectionConfig(
          mode: ServerConnectionMode.remote,
          remoteUrl: normalizedUrl,
          remoteDeviceId: deviceId,
        ),
        psk: psk,
      );
      widget.onResolved(
        ServerBackend(
          client: client,
          mediaProxy: MediaProxyConfig.fromConnection(
            serverUri: Uri.parse(normalizedUrl),
            deviceId: deviceId,
            psk: psk,
          ),
        ),
      );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final isRemote = _mode == ServerConnectionMode.remote;
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
                        : () =>
                              setState(() => _mode = ServerConnectionMode.local),
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
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      t,
                      l10n.serverRemoteDeviceId,
                      _device,
                      hint: ServerConnectionConfig.defaultRemoteDeviceId,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      t,
                      l10n.serverRemotePairingKey,
                      _psk,
                      hint: l10n.serverRemotePairingKeyHint,
                      obscure: true,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    CcAlert(
                      variant: CcAlertVariant.danger,
                      title: l10n.serverSetupCouldNotConnect,
                      description: Text(
                        _error!,
                        style: CcTypography.bodySm.copyWith(
                          color: t.textErrorPrimary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  CcButton(
                    onPressed: _busy ? null : _submit,
                    variant: CcButtonVariant.accent,
                    loading: _busy,
                    fullWidth: true,
                    child: Text(
                      isRemote ? l10n.serverSetupConnect : l10n.serverSetupRunLocal,
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
