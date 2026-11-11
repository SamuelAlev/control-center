import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClientClosedException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/app_windows.dart'
    show runBootFailureWindow, runDesktopBootWindow;
import 'package:control_center/app/tray/launch_context.dart';
import 'package:control_center/app/tray/main_window_visibility.dart';
import 'package:control_center/app/tray/native_desktop_shell.dart';
import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/app/window_geometry_watcher.dart';
import 'package:control_center/app/window_visibility_guard.dart';
import 'package:control_center/bootstrap/desktop_app_host.dart';
import 'package:control_center/bootstrap/desktop_boot_app.dart';
import 'package:control_center/bootstrap/desktop_server_switcher.dart';
import 'package:control_center/bootstrap/desktop_session.dart';
import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/core/keybindings/stuck_keys.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/core/media/media_disk_cache.dart';
import 'package:control_center/core/observability/sentry_bootstrap.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/storage/app_support_path_provider.dart';
import 'package:control_center/core/storage/native_key_value_backend.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/core/utils/cc_domain_logging.dart';
import 'package:control_center/core/utils/cc_infra_logging.dart';
import 'package:control_center/features/desktop_app/providers/desktop_app_preferences.dart';
import 'package:control_center/shared/syntax/shiki_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nativeapi_flutter/nativeapi_flutter.dart' show WindowManager;

/// The process-wide observable preferences backend (NSUserDefaults / Registry /
/// GSettings).
///
/// A single instance shared by [AppPreferences] and `keyValueBackendProvider`,
/// so the per-user preference sync observes every write made through the
/// facade — including ones from notifiers that expose no provider to listen to.
/// Top-level because the desktop has exactly one preferences store for the
/// whole process and a server switch rebuilds the container around the same
/// store. Mirrors `_webBackend` in `bootstrap_web.dart`.
final ObservableKeyValueBackend desktopPrefsBackend = ObservableKeyValueBackend(
  NativeKeyValueBackend(),
);

/// Polls window geometry into preferences for the life of the process.
///
/// Module scope because the two things that must reach it — the exit handler
/// that flushes a last-moment move, and the boot-failure path, which can be
/// taken AFTER the watcher is already running — sit on either side of
/// [_prepareDesktop]'s scope.
WindowGeometryWatcher? _windowGeometryWatcher;

/// Desktop bootstrap: full-featured native multi-window app.
///
/// This is the verbatim desktop startup sequence — logging installs,
/// font-cache redirect, error handlers, multi-window chrome, the
/// `ProviderContainer` with its real (keychain + native preferences) storage
/// overrides, font preload, deep-link wiring and spawning/connecting to the
/// `cc_server` that owns all data and execution — culminating in
/// `runAppWithSentry` with [DesktopAppHost]. The desktop is a thin client like
/// web: it hosts no server, no MCP, no database. The web counterpart is
/// `bootstrap_web.dart`.
///
/// [arguments] are the program's own; the Windows and Linux login entries
/// mark a login launch with one (see `resolveLaunchContext`).
Future<void> bootstrapAndRun([List<String> arguments = const []]) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _prepareDesktop(arguments);
  } on Object catch (error, stack) {
    // Startup can fail before the first window or while the localized boot
    // surface is visible. Replace either state with an actionable error.
    AppLog.e('main', 'desktop bootstrap failed: $error', error, stack);
    // The bootstrap may have got far enough to start polling window geometry.
    // Nothing about an error window is worth remembering, and it has no reason
    // to keep a timer running for the rest of the process's life.
    _windowGeometryWatcher?.dispose();
    runBootFailureWindow(error, stack);
    return;
  }
  await runAppWithSentry(() => const DesktopAppHost());
}

/// Prepares the authenticated app, showing a boot surface only on first run.
///
/// Separated from [bootstrapAndRun] so a failure in here is distinguishable
/// from one thrown after the app tree is mounted — only the former may replace
/// the app with the boot-failure window.
Future<void> _prepareDesktop(List<String> arguments) async {
  // Cap the engine image cache well below Flutter's default (~100MB / 1000
  // images). The desktop shows mostly small avatars and feed thumbnails
  // (already downscaled via ResizeImage); decoded bitmaps stay resident
  // until a newer image needs the slot.
  PaintingBinding.instance.imageCache
    ..maximumSize = 400
    ..maximumSizeBytes = 32 << 20;

  // Route client-resident infrastructure and domain log seams into AppLog.
  // The connected server installs its own logging for server packages.
  installCcInfraLogging();
  installCcDomainLogging();

  // The focus pill and meeting-recording toolbar are sibling windows in this
  // same isolate (Flutter native multi-window) — there is no separate sub-window
  // engine to dispatch to. They are declared in `AppWindows` and styled in the
  // `setWillShowHook` below.

  FlutterError.onError = (details) {
    // Recover from a known Flutter macOS bug where the engine misses a KeyUp
    // (often after Cmd+V or window focus loss while a key is held), leaving
    // HardwareKeyboard._pressedKeys out of sync and blocking all subsequent
    // text input. See https://github.com/flutter/flutter/issues/136419.
    final ex = details.exception;
    if (ex is AssertionError &&
        ex.toString().contains('_pressedKeys.containsKey')) {
      // Release the stuck keys through the public event path — NEVER
      // `HardwareKeyboard.clearState()` here: it also detaches every
      // registered key handler (keybinding dispatcher, diff-view keys,
      // push-to-talk, …), permanently killing all shortcuts; each later press
      // then falls through unhandled and rings the macOS system alert.
      // Deferred one microtask so the synthesised key-ups never re-enter
      // HardwareKeyboard while the failed event is still mid-dispatch.
      scheduleMicrotask(releaseStuckKeys);
      return;
    }
    FlutterError.presentError(details);
    AppLog.e('main', 'Flutter Error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is RemoteRpcClientClosedException) {
      AppLog.i('main', 'RPC client closed; in-flight requests cancelled.');
      return true;
    }
    AppLog.e('main', 'Platform Error: $error', error, stack);
    return true;
  };

  ErrorWidget.builder = (details) {
    final message = const bool.fromEnvironment('dart.vm.product')
        ? 'An unexpected error occurred.'
        : details.exceptionAsString();
    // Be self-sufficient: with native multi-window the error widget can be
    // inserted above any MaterialApp (e.g. at the ViewCollection/window level),
    // where there is no ambient Directionality — without one, Material/Text here
    // would themselves throw "No Directionality", masking the real error.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Builder(
          builder: (context) {
            final tokens = context.designSystem;
            return Container(
              padding: const EdgeInsets.all(16),
              color: tokens?.bgPrimary ?? const Color(0xFFFCFBF9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: tokens?.danger ?? const Color(0xFFDC2626),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: tokens?.muted ?? const Color(0xFF3D3D3D),
                      fontSize: 12,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  };

  final prefs = AppPreferences(desktopPrefsBackend);

  // A login launch the operator asked to keep in the tray starts with the main
  // window hidden: the will-show hook below then styles it (its geometry is
  // restored for when it is revealed) without showing it. Only where
  // something stays on screen to bring it back: the Dock on macOS, the tray
  // icon elsewhere.
  await resolveLaunchContext(arguments);
  if (wasLaunchedAtLogin &&
      (prefs.getBool(startHiddenAtLoginKey) ?? false) &&
      (Platform.isMacOS ||
          (NativeDesktopShell.instance.traySupported &&
              (prefs.getBool(trayIconVisibleKey) ?? true)))) {
    MainWindowVisibility.instance.startHidden();
  }

  // Multi-window chrome: nativeapi observes and controls the windows that
  // Flutter's windowing layer creates (see `AppWindows`). Style each window the
  // moment it is about to show — restore the primary window's geometry (clamped
  // to a display that still exists), hide its title bar and give the HUDs their
  // frameless always-on-top chrome. Replaces window_manager's WindowOptions +
  // waitUntilReadyToShow + WindowListener.
  //
  // The guard repairs stale `hidden` lifecycle state after a main window
  // appears, including the setup→primary handoff. AppWindows also explicitly
  // shows each new macOS main window before its first frame: the engine's
  // delayed show cannot break a pre-presentation `hidden` state on its own.
  WindowVisibilityGuard.instance.install();
  const windowManager = WindowManager.instance;
  windowManager.setWillShowHook((windowId) {
    final window = windowManager.get(windowId);
    if (window != null) {
      styleWindowOnShow(window, prefs);
    }
    final title = window?.title;
    final visibility = MainWindowVisibility.instance;
    if (title == primaryWindowTitle && visibility.startingHidden) {
      // Starting in the tray: styled above, deliberately not shown. Linux's
      // hook observes a show it cannot veto, so the window is also ordered
      // back out once the show returns.
      scheduleMicrotask(() {
        if (visibility.startingHidden) {
          windowManager.get(windowId)?.hide();
        }
      });
      return;
    }
    // Showing the window is OUR job while this hook is installed. nativeapi
    // swizzles `NSWindow makeKeyAndOrderFront:` and, when a will-show hook is
    // registered, calls the hook INSTEAD of the original ("Hook handles all
    // logic; never call original here") — so a hook that returns without this
    // line styles every window and then leaves it invisible: the app, the
    // pre-app setup screen and the HUDs alike, with a live process and an
    // empty screen. This must stay AFTER the styling (that is the point of
    // styling on show) and must run even for a window we could not resolve.
    windowManager.callOriginalShow(windowId);
    if (title == primaryWindowTitle) {
      visibility.noteShown();
    }
    // Reconcile after the native show returns, then arm frame repairs. The
    // guard needs real visibility/focus to distinguish stale `hidden` from
    // the operator intentionally hiding the app.
    scheduleMicrotask(() {
      dressKnownWindows(
        windowManager,
        prefs,
        onMainWindow: (_) => WindowVisibilityGuard.instance.onMainWindowShown(),
      );
      if (title == trayPanelWindowTitle) {
        WindowVisibilityGuard.instance.onAuxiliaryWindowShown();
      }
    });
  });
  // The save side of the same feature. It POLLS rather than listening to
  // `WindowMovedEvent` / `WindowResizedEvent`: the listener that used to live
  // here never persisted anything, because the cnativeapi of the time had its
  // macOS notification handlers commented out. nativeapi 0.4.1 dispatches them
  // (and full-screen enter/exit), but polling reads exactly the states the
  // persist rules key on and needs no per-platform event coverage — see
  // `WindowGeometryWatcher`.
  //
  // Writing only once a window has held still for a tick is what keeps this
  // cheap (one write per drag, not one per frame) and is also what stops a
  // full-screen transition — which sweeps the window through a series of
  // intermediate frames — from persisting one of them as the size the app
  // opens at from then on.
  _windowGeometryWatcher = WindowGeometryWatcher(
    capture: () => captureWindowGeometry(windowManager),
    persist: (snapshot) => persistWindowSnapshot(prefs, snapshot),
  )..start();

  // Constructing the keychain facade does not read credentials. Saved-server
  // launches skip the temporary setup window and its first-frame wait; the
  // backend resolver still opens real setup if reconnecting needs user input.
  final secureStore = SecureStore.keychain();
  await runDesktopBootWindow(
    const DesktopBootApp(),
    isServerConfigured: ServerConnectionStore(prefs, secureStore).isConfigured,
  );

  // Load the libmpv-backed player (media_kit) before any Player is created —
  // every playback surface (soundscape, meeting audio, rig listen,
  // notification sounds) depends on it. Linux takes libmpv from the system and
  // a stock desktop has none, so there the app starts without playback rather
  // than not at all. macOS and Windows bundle it: a failure there is a broken
  // build and still stops the boot.
  var mediaPlaybackAvailable = true;
  try {
    MediaKit.ensureInitialized();
  } on Object catch (error) {
    if (!Platform.isLinux) {
      rethrow;
    }
    mediaPlaybackAvailable = false;
    AppLog.w('main', 'media playback disabled, no libmpv: $error');
  }

  // Pre-warm the shiki highlighter (CC themes + the hottest grammars) so the
  // first visible code block doesn't pay the one-time grammar compile.
  // Registration itself is lazy — this only warms.
  initializeShikiHighlighting();
  // Captures the real Application Support directory — the root every app path
  // derives from. Must run before any code that reads app paths.
  await AppSupportPathProvider.install();

  // The engine's ImageCache above is memory-only and dies with the process, and
  // `NetworkImage` on dart:io has no HTTP disk cache at all — so a desktop
  // paired to a REMOTE server re-downloaded every avatar, favicon and feed
  // thumbnail on each launch. (On loopback the server's own MediaCache already
  // covers it; on web the browser's HTTP cache does.) Installed here, right
  // after the app-support root resolves and before any surface can paint.
  //
  // A sweep on boot rather than on first write: it is what adopts the
  // running-total the write path then maintains, and it is when dropping a
  // month of expired entries is free.
  final mediaCache = MediaDiskCache(
    root: Directory(
      '${AppSupportPathProvider.realAppSupportDir.path}'
      '${Platform.pathSeparator}media-cache',
    ),
  );
  installMediaDiskCache(mediaCache);
  unawaited(mediaCache.sweep());

  // macOS delivers notifications via the native UNUserNotificationCenter channel
  // (see MacOsNotifier.swift); local_notifier is the Windows/Linux path.
  if (!Platform.isMacOS) {
    await localNotifier.setup(appName: 'Control Center');
  }
  // The desktop opens NO database. It connects to a
  // `cc_server` that owns the data over loopback/WSS RPC — the same path the web
  // build uses. The user's persisted choice decides which server:
  //   * LOCAL  → spawn a `cc_server` here (owns global.db + per-workspace
  //     databases under the app-support root) and connect over loopback.
  //   * REMOTE → resolve the active paired server's descriptor (best reachable
  //     path wins) with the stored pairing key + TOFU pin.
  // On first run (or a failed remote connect) this shows the pre-app setup
  // screen so the user chooses. `rpcClientProvider` is overridden with the
  // resulting resilient client, so the whole UI + feature providers read/write
  // through the server.
  final backend = await resolveServerBackend(
    prefs: prefs,
    secureStore: secureStore,
  );

  final env = DesktopSessionEnv(
    prefsBackend: desktopPrefsBackend,
    secureStore: secureStore,
    mediaPlaybackAvailable: mediaPlaybackAvailable,
  );
  final switcher = DesktopServerSwitcher.instance;
  final DesktopBackendSession session;
  try {
    session = await switcher.buildSession(backend, env);
  } on Object {
    await backend.dispose();
    rethrow;
  }
  switcher.start(session, env);

  // Tear the spawned server down on a clean app exit so it does not orphan and
  // keep the SQLite file open (which would fail the next boot). The listener
  // registers itself with WidgetsBinding on construction and lives for the app
  // lifetime.
  // ignore: unused_local_variable
  final lifecycle = AppLifecycleListener(
    onExitRequested: () async {
      // Save where the windows are before anything tears down. A move made in
      // the last second has no later poll to catch it, and this is the path
      // BOTH ways of quitting take — closing the main window routes through
      // `exitApplication` (see `_QuitOnCloseDelegate`), and so does ⌘Q.
      _windowGeometryWatcher
        ?..flushNow()
        ..dispose();
      // The CURRENT session (it may have been switched). A bundled server is
      // stopped gracefully while the shutdown overlay still shows its
      // progress; see [DesktopBackendSession.quit].
      await switcher.current?.quit();
      return AppExitResponse.exit;
    },
  );
}
