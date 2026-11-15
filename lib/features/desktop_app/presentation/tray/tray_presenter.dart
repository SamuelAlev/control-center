import 'dart:async';

import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:control_center/core/providers/desktop_shell_provider.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/features/desktop_app/presentation/close_to_tray_prompt.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_menu.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_actions.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_window.dart';
import 'package:control_center/features/desktop_app/providers/desktop_app_preferences.dart';
import 'package:control_center/features/desktop_app/providers/desktop_shell_state_providers.dart';
import 'package:control_center/features/desktop_app/providers/tray_status_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A click on the tray icon this soon after the panel closed itself on
/// losing focus is the same click: pressing the icon took the focus away.
/// It closes the panel rather than reopening it.
const Duration _toggleGrace = Duration(milliseconds: 400);

/// The session's side of the tray: keeps the icon and its menu in step with
/// the session's status, answers clicks, owns the tray panel and decides what
/// closing the main window does.
///
/// A widget so it can show the first-close prompt and host the panel window;
/// it wraps the session's floating windows ([views]) and adds the panel to
/// them while it is open. Everything it reacts to arrives through provider
/// listeners and shell streams, never through a rebuild, so it keeps working
/// while the main window is hidden and frames are off.
class TrayPresenter extends ConsumerStatefulWidget {
  /// Creates a [TrayPresenter].
  const TrayPresenter({required this.views, super.key});

  /// The session's other floating windows.
  final List<Widget> views;

  @override
  ConsumerState<TrayPresenter> createState() => _TrayPresenterState();
}

class _TrayPresenterState extends ConsumerState<TrayPresenter>
    implements TrayPanelActions {
  late final DesktopShell _shell = ref.read(desktopShellProvider);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _panelOpen = false;
  DateTime? _panelBlurredAt;
  bool _prompting = false;

  @override
  void initState() {
    super.initState();
    if (!_shell.traySupported) {
      return;
    }
    _shell.closeInterceptor = _onCloseRequested;
    ref
      ..listenManual(trayStatusProvider, (_, _) => _pushIcon())
      ..listenManual(trayIconShownProvider, (_, _) => _pushIcon())
      ..listenManual(localeProvider, (_, _) => _pushIcon());
    _subscriptions
      ..add(_shell.trayEvents.listen(_onTrayEvent))
      ..add(_shell.trayMenuSelections.listen(_onMenuSelection));
    _pushIcon();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    if (_shell.traySupported) {
      _shell
        ..closeInterceptor = null
        ..removeTrayIcon();
    }
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizationsLoader.lookupLoaded(
    remapTranslationLocale(
      ref.read(localeProvider) ?? PlatformDispatcher.instance.locale,
    ),
  );

  void _pushIcon() {
    if (!ref.read(trayIconShownProvider)) {
      _shell.removeTrayIcon();
      if (_panelOpen) {
        dismiss();
      }
      return;
    }
    final status = ref.read(trayStatusProvider);
    final l10n = _l10n;
    _shell.setTrayIcon(
      trayIconSpecFor(status, l10n),
      trayMenuFor(status, l10n),
    );
  }

  void _onTrayEvent(TrayPointerEvent event) {
    switch (event) {
      case TrayPointerEvent.primary:
        final blurredAt = _panelBlurredAt;
        final sameClick =
            blurredAt != null &&
            DateTime.now().difference(blurredAt) < _toggleGrace;
        if (_panelOpen || sameClick) {
          _panelBlurredAt = null;
          _setPanelOpen(false);
        } else {
          _setPanelOpen(true);
        }
      case TrayPointerEvent.double:
        // Windows reports the first click of a double click on its own, so
        // the panel may be opening: the double click means the app.
        openApp();
      case TrayPointerEvent.secondary:
        // The native menu opens itself.
        break;
    }
  }

  void _onMenuSelection(String id) {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    switch (id) {
      case TrayMenuIds.open:
        openApp();
      // The menu's "Settings…" is the app's, as in any menu bar app; the
      // panel's own button is the one for this page.
      case TrayMenuIds.settings when workspaceId != null:
        openRoute(settingsRoute(workspaceId));
      case TrayMenuIds.settings:
        openApp();
      case TrayMenuIds.quit:
        quit();
      case TrayMenuIds.inbox when workspaceId != null:
        openRoute(inboxRoute(workspaceId));
      case final String space
          when space.startsWith(TrayMenuIds.spacePrefix) && workspaceId != null:
        openRoute(
          spaceRoute(
            workspaceId,
            space.substring(TrayMenuIds.spacePrefix.length),
          ),
        );
      default:
        openApp();
    }
  }

  /// Decides what the main window's close does; true when handled here.
  bool _onCloseRequested() {
    if (!ref.read(canKeepRunningProvider)) {
      return false;
    }
    if (ref.read(closeActionProvider) == CloseAction.quit) {
      return false;
    }
    final notifier = ref.read(closeActionProvider.notifier);
    if (!notifier.chosen && asksBeforeFirstHide(defaultTargetPlatform)) {
      unawaited(_askBeforeFirstHide());
      return true;
    }
    _hideMainWindow();
    return true;
  }

  Future<void> _askBeforeFirstHide() async {
    if (_prompting) {
      return;
    }
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      // No app to ask in (still booting): do what the button always did.
      quit();
      return;
    }
    _prompting = true;
    try {
      final choice = await showCloseToTrayPrompt(context);
      if (choice == null) {
        // Dismissed: the operator changed their mind about closing.
        return;
      }
      await ref.read(closeActionProvider.notifier).set(choice);
      switch (choice) {
        case CloseAction.keepRunning:
          _hideMainWindow();
        case CloseAction.quit:
          quit();
      }
    } finally {
      _prompting = false;
    }
  }

  void _hideMainWindow() {
    _shell.hideMainWindow();
  }

  void _setPanelOpen(bool open) {
    if (!mounted || _panelOpen == open) {
      return;
    }
    setState(() => _panelOpen = open);
    // Opening is a rebuild, and rebuilds wait for a frame — which never
    // comes while the main window is hidden (frames are off with no visible
    // window). A forced frame is the one that ignores that.
    final binding = SchedulerBinding.instance;
    if (binding.framesEnabled) {
      binding.ensureVisualUpdate();
    } else {
      binding.scheduleForcedFrame();
    }
  }

  @override
  void openApp() {
    _setPanelOpen(false);
    _shell.revealMainWindow();
  }

  @override
  void openRoute(String route) {
    openApp();
    ref.read(routerProvider).go(route);
  }

  @override
  void openSettings() {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      openApp();
      return;
    }
    openRoute(settingsDesktopAppRoute(workspaceId));
  }

  @override
  void switchWorkspace(String workspaceId) {
    // The route is the active workspace's source of truth, so a switch is a
    // navigation, hidden window or not; it lands where the chip's does.
    ref.read(routerProvider).go(inboxRoute(workspaceId));
  }

  @override
  void quit() {
    _setPanelOpen(false);
    _shell.quit();
  }

  @override
  void dismiss({bool returnFocus = false}) {
    if (!returnFocus) {
      _panelBlurredAt = DateTime.now();
    }
    _setPanelOpen(false);
  }

  @override
  Widget build(BuildContext context) => ViewCollection(
    views: [
      ...widget.views,
      if (_panelOpen) TrayPanelWindow(actions: this),
    ],
  );
}
