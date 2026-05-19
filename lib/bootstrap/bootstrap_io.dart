import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cc_data/cc_data.dart';
import 'package:cc_rpc/cc_rpc.dart'
    show RemoteRpcClient, RemoteRpcClientClosedException;
import 'package:control_center/app/app_windows.dart'
    show AppWindows, runBootFailureWindow;
import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/app/window_geometry_watcher.dart';
import 'package:control_center/app/window_visibility_guard.dart';
import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/core/deep_link/deep_link_handler.dart';
import 'package:control_center/core/infrastructure/provider_retry.dart';
import 'package:control_center/core/keybindings/stuck_keys.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/core/media/media_disk_cache.dart';
import 'package:control_center/core/notifications/rpc_notification_mapper.dart';
import 'package:control_center/core/observability/sentry_bootstrap.dart';
import 'package:control_center/core/providers/app_log_provider.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/core/providers/shutdown_progress_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_entry_factory.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:control_center/core/storage/app_support_path_provider.dart';
import 'package:control_center/core/storage/native_key_value_backend.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/update/desktop_update_controller.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/core/utils/cc_domain_logging.dart';
import 'package:control_center/core/utils/cc_infra_logging.dart';
import 'package:control_center/di/notification_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/syntax/shiki_bootstrap.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nativeapi/nativeapi.dart';

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
/// `runAppWithSentry(AppWindows())`. The desktop is a thin client exactly like
/// web: it hosts no server, no MCP, no database. The web counterpart is
/// `bootstrap_web.dart`.
Future<void> bootstrapAndRun() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _prepareDesktop();
  } on Object catch (error, stack) {
    // Everything above happens while the app owns NO window, so a throw here
    // reaches nobody: `PlatformDispatcher.onError` logs it to a terminal the
    // operator may not be watching, the engine keeps its run loop alive, and
    // the app becomes a running process with nothing on screen. Put the
    // failure in a window instead — it is the only surface left.
    AppLog.e('main', 'desktop bootstrap failed: $error', error, stack);
    // The bootstrap may have got far enough to start polling window geometry.
    // Nothing about an error window is worth remembering, and it has no reason
    // to keep a timer running for the rest of the process's life.
    _windowGeometryWatcher?.dispose();
    runBootFailureWindow(error, stack);
    return;
  }
  await runAppWithSentry(() => const _DesktopAppHost());
}

/// Everything the desktop must do BEFORE it can render: storage, window
/// chrome, and the connection to the `cc_server` that owns all state.
///
/// Separated from [bootstrapAndRun] so a failure in here is distinguishable
/// from one thrown after the app tree is mounted — only the former may replace
/// the app with the boot-failure window.
Future<void> _prepareDesktop() async {
  // Load the libmpv-backed player (media_kit) before any Player is created —
  // every playback surface (soundscape, meeting audio, rig listen,
  // notification sounds) depends on it.
  MediaKit.ensureInitialized();

  // Cap the engine image cache well below Flutter's default (~100MB / 1000
  // images). The desktop shows mostly small avatars and feed thumbnails
  // (already downscaled via ResizeImage), so the default budget just lets
  // decoded bitmaps accumulate as idle RSS.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;

  // Route the client-resident packages' log seams (cc_infra device adapters /
  // dio clients + cc_domain) into AppLog before anything else starts. The
  // connected `cc_server` installs its own logging for the server packages.
  installCcInfraLogging();
  installCcDomainLogging();

  // Pre-warm the shiki highlighter (CC themes + the hottest grammars) so the
  // first visible code block doesn't pay the one-time grammar compile.
  // Registration itself is lazy — this only warms.
  initializeShikiHighlighting();

  // The focus pill and meeting-recording toolbar are sibling windows in this
  // same isolate (Flutter native multi-window) — there is no separate sub-window
  // engine to dispatch to. They are declared in `AppWindows` and styled in the
  // `setWillShowHook` below.

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
  final secureStore = SecureStore.keychain();

  // Multi-window chrome: nativeapi observes and controls the windows that
  // Flutter's windowing layer creates (see `AppWindows`). Style each window the
  // moment it is about to show — restore the primary window's geometry (clamped
  // to a display that still exists), hide its title bar and give the HUDs their
  // frameless always-on-top chrome. Replaces window_manager's WindowOptions +
  // waitUntilReadyToShow + WindowListener.
  //
  // The guard installed alongside them repairs the launch-time lifecycle
  // state: the runner is headless, so at the moment AppKit activates the app
  // there is no window yet and the engine reports `hidden` — which disables
  // frames, leaving the window that appears seconds later (once cc_server is
  // up) black until something forces a frame. See `WindowVisibilityGuard`.
  WindowVisibilityGuard.instance.install();
  const windowManager = WindowManager.instance;
  windowManager.setWillShowHook((windowId) {
    final window = windowManager.get(windowId);
    if (window != null) {
      styleWindowOnShow(window, prefs);
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
    // The pass above cannot identify a window on its FIRST show: Flutter
    // applies the title only after the call that created and showed it, so
    // `styleWindowOnShow` matched nothing and the window is wearing stock
    // macOS chrome right now. The title lands before this microtask runs.
    scheduleMicrotask(
      () => dressKnownWindows(
        windowManager,
        prefs,
        onMainWindow: (_) => WindowVisibilityGuard.instance.onMainWindowShown(),
      ),
    );
  });
  // The save side of the same feature. It POLLS rather than listening to
  // `WindowMovedEvent` / `WindowResizedEvent`, which is not a preference: in
  // cnativeapi's macOS window-manager delegate every notification handler has
  // its `OnWindowEvent(...)` call commented out upstream, so no window event
  // is ever dispatched to Dart and the listener that used to live here had
  // never persisted anything. Zoom and full-screen have no notification at
  // all, in any version, so those states have to be read either way.
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

  // Thin-client flip: the desktop opens NO database. It connects to a
  // `cc_server` that owns the data over loopback/WSS RPC — the same path the web
  // build uses. The user's persisted choice decides which server:
  //   * LOCAL  → spawn a `cc_server` here (owns the SAME control_center.db under
  //     the app-support root) and connect to it over loopback.
  //   * REMOTE → resolve the active paired server's descriptor (best reachable
  //     path wins) with the stored pairing key + TOFU pin.
  // On first run (or a failed remote connect) this shows the pre-app setup
  // screen so the user chooses. `rpcClientProvider` is overridden with the
  // resulting resilient client, so the whole UI + feature providers read/write
  // through the server instead of an in-process Drift host.
  final backend = await resolveServerBackend(
    prefs: prefs,
    secureStore: secureStore,
  );

  final session = await DesktopBackendSession.build(
    backend: backend,
    prefs: prefs,
    secureStore: secureStore,
  );
  DesktopServerSwitcher.instance._adopt(session, prefs, secureStore);

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
      // Only a locally-spawned server is ours to stop; a remote connection is
      // not our child. For a local server we drive a GRACEFUL shutdown so the
      // server streams its per-service teardown progress — the overlay rendered
      // by `shutdownProgressProvider` shows it live — BEFORE we tear the client
      // down. Dispose the CURRENT session (it may have been switched).
      final session = DesktopServerSwitcher.instance._current;
      final local = session?.backend.local;
      if (session != null && local != null) {
        session.container.read(shutdownProgressProvider.notifier).begin();
        // Give the overlay at least one painted frame before we proceed: the
        // state change schedules a rebuild via markNeedsBuild, but without
        // yielding to the frame pipeline the overlay may never paint (the
        // container can be disposed on the same microtask turn if stopServer
        // returns instantly — e.g. an already-dead process).
        await WidgetsBinding.instance.endOfFrame;
      }
      await session?.dispose();
      return AppExitResponse.exit;
    },
  );
}

/// One connected desktop session: the backend plus the `ProviderContainer`
/// and the per-session side services (workspace binding, notification mapper,
/// deep-link handlers). Rebuilt wholesale on an in-app server switch.
class DesktopBackendSession {
  DesktopBackendSession._(this.backend, this.container);

  /// The connected backend.
  final ServerBackend backend;

  /// The app's provider container, bound to [backend]'s client.
  final ProviderContainer container;

  /// Builds a container for [backend] and runs the post-connect side wiring.
  static Future<DesktopBackendSession> build({
    required ServerBackend backend,
    required AppPreferences prefs,
    required SecureStore secureStore,
  }) async {
    final container = ProviderContainer(
      // Bounded, unrecoverable-error-aware retry: keeps a subscription stream
      // error (e.g. a GitHub rate limit) from looping into a resubscribe storm.
      retry: appProviderRetry,
      overrides: [
        appPreferencesProvider.overrideWithValue(prefs),
        keyValueBackendProvider.overrideWithValue(desktopPrefsBackend),
        secureStoreProvider.overrideWithValue(secureStore),
        rpcClientProvider.overrideWithValue(backend.client),
        // The bulk-content lane, beside the RPC client it belongs with. The
        // composer uploads an attached picture over HTTP because the RPC
        // socket refuses a frame that size; the notifier doing it has no
        // BuildContext, so MediaProxyScope alone is not enough.
        mediaProxyConfigProvider.overrideWithValue(backend.mediaProxy),
        serverConnectionSupervisorProvider.overrideWithValue(
          backend.supervisor,
        ),
        serverSwitchHandlerProvider.overrideWithValue(
          DesktopServerSwitcher.instance.switchTo,
        ),
      ],
    );

    // Initialise the app-wide logger from persisted preferences.
    container.read(appLogLevelProvider);

    // Bind the RPC session to the active workspace BEFORE the UI subscribes to
    // any workspace-scoped op and re-bind on every workspace switch. The
    // thin-client desktop opens no database, so (like `bootstrap_web`) the
    // workspace set comes from the connected `cc_server`: without this the
    // server session stays unbound and every workspace-scoped query fails with
    // "No workspace bound to this session" / "Missing workspace_id".
    await _bindActiveWorkspace(container, backend.client);

    // Pre-load any system fonts selected by the user so they are available
    // to Flutter's text engine before the first frame renders.
    final fontNotifier = container.read(fontSettingsProvider.notifier);
    final fontSettings = container.read(fontSettingsProvider);
    if (fontSettings.appFontSelection.source == FontSource.system) {
      await fontNotifier.loadSystemFont(fontSettings.appFontSelection);
    }
    if (fontSettings.codeFontSelection.source == FontSource.system) {
      await fontNotifier.loadSystemFont(fontSettings.codeFontSelection);
    }

    final session = DesktopBackendSession._(backend, container);

    // OS notifications: maps the connected server's pushed `notifications/*`
    // frames (RemoteEventForwarder) to AppNotifications. Retained for the
    // session's lifetime via the RPC subscription created in its constructor.
    session._notificationMapper = RpcNotificationMapper(
      client: backend.client,
      notificationPort: container.read(notificationServiceProvider),
      localizations: () => lookupAppLocalizations(
        container.read(localeProvider) ?? PlatformDispatcher.instance.locale,
      ),
      activeWorkspaceId: () => container.read(activeWorkspaceIdProvider),
      // Read lazily (like `activeWorkspaceId`) so the mapper always sees the
      // freshest identity even though it may still be loading at construction
      // time (`currentUserIdProvider` is null until `identity.me` resolves).
      currentUserId: () => container.read(currentUserIdProvider),
      // Read lazily for the same reason: a mute toggled in Settings must take
      // effect on the next frame, not on the next launch.
      mutedRepos: () =>
          container.read(mutedReposProvider).asData?.value ?? const {},
      // Read lazily for the same reason again: the forge connections resolve
      // over RPC after construction, and connecting one mid-session must start
      // suppressing that account's own actions on the next frame.
      viewerLogins: () => container.read(viewerLoginSetProvider),
    );
    return session;
  }

  // Held for the session's lifetime (subscription created in its ctor).
  // ignore: unused_field
  RpcNotificationMapper? _notificationMapper;

  /// Disposes the container and the backend (local child included).
  Future<void> dispose() async {
    container.dispose();
    await backend.dispose();
  }
}

/// App-global handle the settings UI uses to switch the desktop between
/// paired servers without a restart (PRD 15 §10 fast switch). The host widget
/// below rebuilds the whole provider tree around the new session.
class DesktopServerSwitcher {
  DesktopServerSwitcher._();

  /// The process-wide instance.
  static final DesktopServerSwitcher instance = DesktopServerSwitcher._();

  DesktopBackendSession? _current;
  AppPreferences? _prefs;
  SecureStore? _secure;
  final ValueNotifier<int> _generation = ValueNotifier(0);

  /// The live session (the host widget renders it).
  DesktopBackendSession? get current => _current;

  /// Bumped on every adopted session; the host listens and remounts.
  ValueListenable<int> get generation => _generation;

  /// Adopts an SSO login bounce-back (`control-center://pair#<b64url
  /// {s: origin, i: deviceId, k: psk}>` — the same payload shape the web
  /// client's URL fragment carries): probes the server for its published
  /// identity, persists the entry + credential and live-switches to it.
  ///
  /// The link arrives from the server's ACS bounce page after a browser SSO
  /// round-trip; the credential inside is one-time-use-shaped (a freshly
  /// minted device PSK), so leaking the link leaks nothing beyond that
  /// device's own session.
  Future<void> adoptPairLink(String rawUrl) async {
    final prefs = _prefs;
    final secure = _secure;
    if (prefs == null || secure == null) {
      // Pre-app (the server-setup window started the browser round-trip):
      // park the credential for the setup screen, which is listening.
      AppLog.w(
        'deep-link',
        'pair link arrived before backend init — parked for the setup screen',
      );
      pendingSsoPairLink.value = rawUrl;
      return;
    }
    final payload = decodeSsoPairLink(rawUrl);
    if (payload == null) {
      AppLog.w('deep-link', 'pair link fragment is malformed');
      return;
    }
    // Only an EXPECTED bounce is auto-adopted: a pair link arriving with no
    // SSO round-trip in flight was not started by this app — anyone can
    // forge a `control-center://pair` link and adopting one would silently
    // re-home the session to an impostor server (one-click MITM). Refuse it
    // loudly in the log; the user can still pair manually.
    if (!isSsoLoginInFlight()) {
      AppLog.w(
        'deep-link',
        'ignoring unbidden pair link (no SSO round-trip in flight): '
            '${payload.server}',
      );
      return;
    }
    ssoLoginStartedAt.value = null; // Consumed by this bounce.
    final entry = await ServerEntryFactory.fromManualUrl(
      rawUrl: payload.server,
      deviceId: payload.deviceId,
    );
    if (entry == null) {
      AppLog.w(
        'deep-link',
        'pair link server did not answer /healthz: ${payload.server}',
      );
      return;
    }
    await ServerConnectionStore(
      prefs,
      secure,
    ).upsertEntry(entry, psk: payload.psk);
    await switchTo(entry.serverId);
  }

  void _adopt(
    DesktopBackendSession session,
    AppPreferences prefs,
    SecureStore secure,
  ) {
    _current = session;
    _prefs = prefs;
    _secure = secure;
    _generation.value++;
  }

  /// Switches to [serverId] (a paired server id, or `local`): disposes the
  /// current session, resolves the new backend and remounts the app.
  /// Throws on connect failure — the caller surfaces the error and the
  /// current session stays live (the old session is only torn down after the
  /// new one connected).
  Future<void> switchTo(String serverId) async {
    final prefs = _prefs;
    final secure = _secure;
    if (prefs == null || secure == null) {
      throw StateError('Desktop backend not initialised yet');
    }
    final backend = await resolveServerBackend(
      prefs: prefs,
      secureStore: secure,
      forceServerId: serverId,
    );
    final DesktopBackendSession next;
    try {
      next = await DesktopBackendSession.build(
        backend: backend,
        prefs: prefs,
        secureStore: secure,
      );
    } on Object {
      // `resolveServerBackend` may have SPAWNED a local cc_server child. If the
      // session build then fails we keep the old session (correct) — but that
      // child would be orphaned, holding the SQLite file open against every
      // later switch. Dispose it before surfacing the failure.
      await backend.dispose();
      rethrow;
    }
    final old = _current;
    _adopt(next, prefs, secure);
    if (old != null) {
      // Tear the OLD session down only AFTER the frame that remounts the app
      // around the new one. `_adopt` merely schedules that rebuild (setState),
      // so disposing here and now would leave the still-mounted widget tree
      // sitting on a disposed `ProviderContainer`: every `ref.watch` in it
      // throws, the remount frame dies half-built and the window is left
      // painted but dead — visible content, no navigation, hard quit only.
      // Post-frame callbacks run after `finalizeTree`, i.e. once the old tree
      // is unmounted for real.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(old.dispose()),
      );
      // A post-frame callback needs a frame to be scheduled; `setState` above
      // normally does that, but not if the host widget is not mounted yet.
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }
}

/// Root desktop widget: renders the current [DesktopBackendSession]'s
/// provider tree and remounts it (new `ValueKey`) when the switcher adopts a
/// new session. Also owns the container-scoped platform handlers (menu-bar
/// Preferences, deep links), re-registered per session.
class _DesktopAppHost extends StatefulWidget {
  const _DesktopAppHost();

  @override
  State<_DesktopAppHost> createState() => _DesktopAppHostState();
}

class _DesktopAppHostState extends State<_DesktopAppHost> {
  static const _appChannel = MethodChannel('com.controlcenter/app');

  @override
  void initState() {
    super.initState();
    DesktopServerSwitcher.instance.generation.addListener(_onSession);
    _wirePlatformHandlers();
  }

  @override
  void dispose() {
    DesktopServerSwitcher.instance.generation.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (mounted) {
      setState(() {});
    }
    _wirePlatformHandlers();
  }

  ProviderContainer? get _container =>
      DesktopServerSwitcher.instance.current?.container;

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
          await DesktopServerSwitcher.instance.adoptPairLink(earlyUrl);
          return;
        }
      }
      final container = _container;
      if (container == null) {
        return;
      }
      switch (call.method) {
        case 'openSettings':
          final router = container.read(routerProvider);
          final wsId = container.read(activeWorkspaceIdProvider);
          router.go(
            wsId == null ? workspaceListRoute : settingsProfileRoute(wsId),
          );
        case 'openUrl':
          final rawUrl = call.arguments as String?;
          if (rawUrl != null && rawUrl.isNotEmpty) {
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
    final session = DesktopServerSwitcher.instance.current;
    if (session == null) {
      return const SizedBox.shrink();
    }
    // Route every remote-media fetch (avatars, feed images, PR-body media)
    // through the connected server's `/proxy/media` endpoint — the desktop is
    // a thin client, so it must not hit upstream hosts directly. Omitted only
    // if the connection couldn't be expressed as a proxy base.
    final mediaProxy = session.backend.mediaProxy;
    return KeyedSubtree(
      key: ValueKey(
        'server-${session.backend.entry?.serverId ?? 'local'}-'
        '${DesktopServerSwitcher.instance.generation.value}',
      ),
      child: UncontrolledProviderScope(
        container: session.container,
        child: mediaProxy != null
            ? MediaProxyScope(config: mediaProxy, child: const AppWindows())
            : const AppWindows(),
      ),
    );
  }
}

/// Binds the RPC session to the active workspace and keeps it bound.
///
/// Lists the connected server's workspaces, binds the session to the active one
/// (the persisted choice if it still exists on this server, otherwise the
/// first), seeds [activeWorkspaceIdProvider] and re-binds on every later
/// workspace switch (a switch is a URL navigation that updates the provider).
/// Best-effort: a failure is logged, not fatal — onboarding can still create
/// the first workspace, which binds the session through the same listener.
Future<void> _bindActiveWorkspace(
  ProviderContainer container,
  RemoteRpcClient client,
) async {
  final workspaces = RemoteWorkspaceRepository(client);
  try {
    final list = await workspaces.list();
    if (list.isNotEmpty) {
      final current = container.read(activeWorkspaceIdProvider);
      final activeId = current != null && list.any((w) => w.id == current)
          ? current
          : list.first.id;
      await workspaces.setActive(activeId);
      await container
          .read(activeWorkspaceIdProvider.notifier)
          .setActive(activeId);
    }
  } on Object catch (e) {
    AppLog.w('main', 'initial workspace session binding failed: $e');
  }
  // Re-bind whenever the active workspace changes. The subscription lives for
  // the container's (app's) lifetime.
  container.listen<String?>(activeWorkspaceIdProvider, (_, next) {
    if (next != null) {
      unawaited(workspaces.setActive(next));
    }
  });
}

/// Scheme prefix Google reserves for an iOS-type OAuth client's redirect
/// (`com.googleusercontent.apps.<client>://…`). Matched by prefix because the
/// `<client>` portion varies per deployment.
/// Dispatches an inbound custom-scheme URL through the app's deep-link router.
///
/// Google OAuth redirects are NOT handled here any more: the host runs the
/// device-code grant and owns the refresh token, so no client-side redirect
/// ever arrives (see `features/calendar/README.md`).
Future<void> _handleIncomingUrl(
  ProviderContainer container,
  String rawUrl,
) async {
  if (rawUrl.startsWith('control-center://pair')) {
    // The SSO login bounce page: carries a minted device credential in the
    // fragment; adoption + live server switch live on the switcher.
    await DesktopServerSwitcher.instance.adoptPairLink(rawUrl);
    return;
  }
  await _handleDeepLink(container, rawUrl);
}

/// Navigates to what an inbound `control-center://` link names.
///
/// Every destination is workspace-prefixed and the prefix is what re-scopes the
/// app — so a link opened while another workspace is active switches to the right
/// one instead of rendering the right screen with the wrong context.
Future<void> _handleDeepLink(ProviderContainer container, String rawUrl) async {
  switch (DeepLinkHandler.resolve(rawUrl)) {
    case final PrDeepLink pr:
      await _openPrDeepLink(container, pr);
    case SpaceDeepLink(:final workspaceId, :final spaceId):
      await _goToWorkspace(
        container,
        workspaceId,
        spaceRoute(workspaceId, spaceId),
      );
    case TicketDeepLink(:final workspaceId, :final ticketId):
      await _goToWorkspace(
        container,
        workspaceId,
        ticketDetailRoute(workspaceId, ticketId),
      );
    case null:
      return;
  }
}

/// Switches the active workspace to [workspaceId] and navigates to [route].
///
/// The provider is set before the navigation because the workspace id is what
/// every scoped provider reads; a link into a workspace the client does not know
/// falls back to the picker rather than opening an empty screen.
Future<void> _goToWorkspace(
  ProviderContainer container,
  String workspaceId,
  String route,
) async {
  final known = await container
      .read(workspaceRepositoryProvider)
      .getAll()
      .then((all) => all.any((w) => w.id == workspaceId))
      // A repository that cannot answer must not swallow the link: trust the id
      // and let the target screen report whatever it finds.
      .onError((_, _) => true);
  if (!known) {
    container.read(routerProvider).go(workspaceListRoute);
    return;
  }
  await container
      .read(activeWorkspaceIdProvider.notifier)
      .setActive(workspaceId);
  container.read(routerProvider).go(route);
}

/// Resolves a `control-center://pr/<owner>/<repo>/<number>` deep link. When
/// the target repo is registered in some workspace, switches the active
/// workspace and repo to that target before navigating to the PR detail —
/// otherwise the PR screen would render with the previously active repo's
/// context and fetch the wrong PR.
Future<void> _openPrDeepLink(ProviderContainer container, PrDeepLink pr) async {
  final repoRepo = container.read(repoRepositoryProvider);
  final wsRepo = container.read(workspaceRepositoryProvider);

  // Repos live inside a workspace, so the search walks workspaces in the
  // operator's manual order and stops at the first one holding this checkout.
  String? targetWorkspaceId;
  for (final ws in await wsRepo.getAll()) {
    final target = (await repoRepo.getAll(ws.id))
        .where(
          (r) =>
              r.remoteOwner.toLowerCase() == pr.owner.toLowerCase() &&
              r.remoteName.toLowerCase() == pr.repo.toLowerCase(),
        )
        .firstOrNull;
    if (target != null) {
      targetWorkspaceId = ws.id;
      await container.read(activeWorkspaceIdProvider.notifier).setActive(ws.id);
      await container.read(activeRepoIdProvider.notifier).setActive(target.id);
      break;
    }
  }

  // Navigate into the resolved workspace's PR detail; the workspace prefix in
  // the URL is what re-scopes the app. Fall back to the active workspace, then
  // the picker, if the PR's repo isn't linked anywhere.
  final wsId = targetWorkspaceId ?? container.read(activeWorkspaceIdProvider);
  container
      .read(routerProvider)
      .go(
        wsId == null
            ? workspaceListRoute
            : pullRequestDetailRoute(
                wsId,
                '${pr.owner}/${pr.repo}',
                pr.number,
                // A comment permalink lands on the diff with the comment
                // revealed; the tab falls back to the timeline itself when the
                // comment turns out to be outdated or out of scope.
                tab: pr.commentId == null ? null : 'pr.diff',
                commentId: pr.commentId,
              ),
      );
}
