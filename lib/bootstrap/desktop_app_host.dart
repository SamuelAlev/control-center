import 'dart:async';
import 'dart:io';

import 'package:control_center/app/app_windows.dart' show AppWindows;
import 'package:control_center/app/control_center_app.dart';
import 'package:control_center/app/tray/main_window_visibility.dart';
import 'package:control_center/bootstrap/desktop_deep_links.dart';
import 'package:control_center/bootstrap/desktop_server_switcher.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:control_center/core/update/desktop_update_controller.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root desktop widget: keeps the primary native window while remounting the
/// current [DesktopServerSwitcher] session's UI. Also owns the
/// container-scoped platform handlers (menu-bar Preferences, deep links),
/// re-registered per session.
class DesktopAppHost extends StatefulWidget {
  /// Creates the host.
  const DesktopAppHost({super.key});

  @override
  State<DesktopAppHost> createState() => _DesktopAppHostState();
}

class _DesktopAppHostState extends State<DesktopAppHost> {
  static const _appChannel = MethodChannel('com.controlcenter/app');

  DesktopServerSwitcher get _switcher => DesktopServerSwitcher.instance;

  @override
  void initState() {
    super.initState();
    _switcher.generation.addListener(_onSession);
    _wirePlatformHandlers();
  }

  @override
  void dispose() {
    _switcher.generation.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (mounted) {
      setState(() {});
    }
    _wirePlatformHandlers();
  }

  ProviderContainer? get _container => _switcher.current?.container;

  Future<void> _handleIncomingUrl(ProviderContainer container, String url) =>
      handleDesktopIncomingUrl(
        container,
        url,
        adoptPairLink: _switcher.adoptPairLink,
      );

  void _wirePlatformHandlers() {
    // Wire macOS menu-bar Preferences to in-app Settings, the app-menu
    // "Check for Updates…" item to the desktop updater and deep link URLs
    // (control-center://) forwarded from AppDelegate. Uses the CURRENT
    // session's container on every call.
    _appChannel.setMethodCallHandler((call) async {
      // SSO pair links are adopted even with NO session yet: the browser
      // round-trip may have been started by the pre-app server-setup window,
      // and dropping the credential here would strand the user mid-login
      // (the setup screen listens on the pending notifier).
      if (call.method == 'openUrl') {
        final earlyUrl = call.arguments as String?;
        if (earlyUrl != null && isSsoPairLink(earlyUrl)) {
          await _switcher.adoptPairLink(earlyUrl);
          return;
        }
      }
      // A Dock click, or a second launch handed to this instance: bring the
      // main window back, even from the tray. Needs no session — the window
      // outlives every one of them.
      if (call.method == 'reopen') {
        MainWindowVisibility.instance.reveal();
        return;
      }
      final container = _container;
      if (container == null) {
        return;
      }
      switch (call.method) {
        case 'openSettings':
          MainWindowVisibility.instance.reveal();
          final router = container.read(routerProvider);
          if (isAuthenticationRoute(
            router.routerDelegate.currentConfiguration.uri.path,
          )) {
            return;
          }
          final wsId = container.read(activeWorkspaceIdProvider);
          router.go(
            wsId == null ? workspaceListRoute : settingsLandingRoute(wsId),
          );
        case 'openUrl':
          final rawUrl = call.arguments as String?;
          if (rawUrl != null && rawUrl.isNotEmpty) {
            // A link opens where it can be seen, even from the tray.
            MainWindowVisibility.instance.reveal();
            await _handleIncomingUrl(container, rawUrl);
          }
        case 'checkForUpdates':
          // The single user-initiated path into the updater (same as the
          // Settings → About button): interactive Sparkle prompt, drain-gated
          // while a meeting is recording.
          unawaited(container.read(desktopUpdateProvider.notifier).checkNow());
      }
    });

    if (!Platform.isMacOS) {
      final container = _container;
      if (container != null) {
        for (final arg in Platform.executableArguments) {
          if (arg.startsWith('control-center://')) {
            unawaited(_handleIncomingUrl(container, arg));
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _switcher.current;
    if (session == null) {
      return const SizedBox.shrink();
    }
    // Route every remote-media fetch (avatars, feed images, PR-body media)
    // through the connected server's `/proxy/media` endpoint — the desktop is
    // a thin client, so it must not hit upstream hosts directly. Omitted only
    // if the connection couldn't be expressed as a proxy base.
    return UncontrolledProviderScope(
      container: session.container,
      child: AppWindows(
        sessionKey: ObjectKey(session),
        mediaProxy: session.backend.mediaProxy,
        app: const ControlCenterApp(),
      ),
    );
  }
}
