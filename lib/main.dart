import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cc_ui/cc_ui.dart' show CcToastScope;
import 'package:control_center/core/deep_link/deep_link_handler.dart';
import 'package:control_center/core/notifications/notification_event_mapper.dart';
import 'package:control_center/core/observability/sentry_bootstrap.dart';
import 'package:control_center/core/providers/app_log_provider.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/font_cache_path_provider.dart';
import 'package:control_center/core/theme/app_theme.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/features/focus_mode/presentation/screens/focus_pill_app.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_server_provider.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/data/services/pr_polling_service.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_workspace_chip.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/app_shortcuts.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect whether this Flutter engine is for a sub-window (e.g. focus pill).
  final windowController = await WindowController.fromCurrentEngine();
  final rawArgs = windowController.arguments;
  if (rawArgs.isNotEmpty) {
    final args = jsonDecode(rawArgs) as Map<String, dynamic>;
    if (args['type'] == 'focusPill') {
      await _bootstrapFocusPill(windowController, args);
      return;
    }
  }

  // Clear any stale hotkeys left over from a previous run before the
  // KeybindingDispatcher registers its in-app shortcuts. Guarded because the
  // platform channel may be unavailable in some headless contexts.
  try {
    await hotKeyManager.unregisterAll();
  } on Object catch (e) {
    AppLog.w('main', 'hotkey_manager unregisterAll failed: $e');
  }

  // Captures the real Application Support directory and redirects
  // google_fonts' cache into a `fonts/` subfolder so it doesn't pollute the
  // root with .ttf files. Must run before any code that reads app paths.
  await FontCachePathProvider.install();
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
      // ignore: invalid_use_of_visible_for_testing_member
      HardwareKeyboard.instance.clearState();
      return;
    }
    FlutterError.presentError(details);
    AppLog.e('main', 'Flutter Error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.e('main', 'Platform Error: $error', error, stack);
    return true;
  };

  ErrorWidget.builder = (details) {
    final message = const bool.fromEnvironment('dart.vm.product')
        ? 'An unexpected error occurred.'
        : details.exceptionAsString();
    return Material(
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
    );
  };

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(1024, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Control Center',
  );
  final prefs = await SharedPreferences.getInstance();

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    final x = prefs.getDouble('window_x');
    final y = prefs.getDouble('window_y');
    final w = prefs.getDouble('window_w');
    final h = prefs.getDouble('window_h');
    if (x != null && y != null) {
      await windowManager.setPosition(Offset(x, y));
    }
    if (w != null && h != null) {
      await windowManager.setSize(Size(w, h));
    }
    await windowManager.show();
    await windowManager.focus();
  });
  windowManager.addListener(WindowPositionListener(prefs));

  // A focus-pill sub-window is always-on-top and keeps the process alive on
  // macOS, so it can outlive the main window. A restart-orphaned pill closes
  // itself on launch (see `_bootstrapFocusPill`); here we only intercept the
  // main-window close so we can tear the pill (and its ticking timer) down
  // before the app exits.
  await windowManager.setPreventClose(true);

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialise the app-wide logger from persisted preferences.
  container.read(appLogLevelProvider);

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

  // Wire macOS menu-bar Preferences to in-app Settings, and deep link
  // URLs (control-center://) forwarded from AppDelegate.
  const appChannel = MethodChannel('com.controlcenter/app');
  appChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'openSettings':
        final router = container.read(routerProvider);
        router.go(settingsAppearanceRoute);
      case 'openUrl':
        final rawUrl = call.arguments as String?;
        if (rawUrl != null && rawUrl.isNotEmpty) {
          await _handleIncomingUrl(container, rawUrl);
        }
    }
  });

  if (!Platform.isMacOS) {
    for (final arg in Platform.executableArguments) {
      if (arg.startsWith('control-center://') ||
          arg.startsWith(_googleOAuthRedirectScheme)) {
        await _handleIncomingUrl(container, arg);
        break;
      }
    }
  }

  // Defer all background-service wiring until after the first frame paints.
  // Reading these providers eagerly here built the entire backend DI graph
  // (the MCP tool registry alone instantiates ~70 tools and watches ~30
  // providers) synchronously before `runApp`. On a JIT/debug build that
  // produced a multi-second burst of VM compilation, class-loading and GC on
  // the main thread at cold start — long enough to trip the 2s app-hang
  // watchdog. _startBackgroundServices runs the same wiring after first paint,
  // yielding between groups so the UI stays responsive.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_startBackgroundServices(container));
  });

  await runAppWithSentry(
    () => UncontrolledProviderScope(container: container, child: const MyApp()),
  );
}

/// Bootstraps the floating focus pill in its own sub-window engine.
///
/// A focus session lives for exactly one app run, so the pill must vanish on
/// any restart. The challenge: a hot restart re-runs this same entrypoint on
/// the *existing* native window without recreating it, and — because the
/// platform closes pill windows with `isReleasedWhenClosed = false` — even a
/// *completed* pill leaves its Flutter engine alive (window merely hidden). So
/// on a hot restart this entrypoint can re-run for the live pill AND for any
/// such "zombie" engine from an earlier, already-finished session.
///
/// We tell a genuinely *new* pill from any *re-run* with a one-shot launch
/// token (see [consumeFreshPillLaunch]): the main window mints it, stores it and
/// stamps it into these args before creating the window, and it is good for
/// exactly one launch. A fresh pill consumes it and shows; a hot-restart re-run
/// (live pill or hidden zombie) finds it already consumed, so we attach an empty
/// root and close. A runApp() root must exist before close() — returning bare,
/// or calling destroy() (which quits the whole app), crashes the engine during
/// reassembly.
Future<void> _bootstrapFocusPill(
  WindowController windowController,
  Map<String, dynamic> args,
) async {
  // Plugins (including window_manager) are registered for sub-windows by the
  // FlutterMultiWindowPlugin.setOnWindowCreatedCallback in AppDelegate; this
  // binds window_manager to this sub-window.
  await windowManager.ensureInitialized();

  if (!await consumeFreshPillLaunch(args['pillToken'] as String?)) {
    runApp(const SizedBox.shrink());
    try {
      await windowManager.close();
    } on Object catch (_) {}
    return;
  }

  final x = (args['pillX'] as num?)?.toDouble() ?? 700;
  final y = (args['pillY'] as num?)?.toDouble() ?? 30;
  const pillSize = Size(420, 72);
  await windowManager.setSize(pillSize);
  await windowManager.setMinimumSize(pillSize);
  await windowManager.setMaximumSize(pillSize);
  // Min == max isn't enough on macOS: the window keeps its resize handles and,
  // once dragged, sticks at the new size. Lock it outright.
  await windowManager.setResizable(false);
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  await windowManager.setAlwaysOnTop(true);
  // Note: Do NOT call setSkipTaskbar(true) here — window_manager's macOS
  // implementation hides the *entire app* from the Dock (dockTile.isVisible),
  // not just one window. That would make the main window unreachable once the
  // user focuses another application.
  await windowManager.setBackgroundColor(const Color(0x00000000));
  await windowManager.setPosition(Offset(x, y));
  await windowManager.show();
  await runAppWithSentry(
    () => FocusPillApp(windowController: windowController, args: args),
  );
}

/// Wires up background services after the first frame has painted.
///
/// Building large slices of the backend DI graph before `runApp` blocked the
/// main thread through cold start; deferring past first paint (and yielding
/// between groups) keeps startup responsive and spreads the cost across the
/// event loop instead of one synchronous burst.
Future<void> _startBackgroundServices(ProviderContainer container) async {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  // MCP server — reading the provider assembles the tool registry + its deps.
  container.read(mcpServerProvider);
  await settle();

  // Pipeline lifecycle reconcilers / listeners.
  container.listen(pipelineResumeProvider, (_, _) {});
  container.listen(pipelineTriggerDispatcherAliveProvider, (_, _) {});
  container.listen(agentRunTaskCompleterAliveProvider, (_, _) {});
  container.listen(subPipelineResumeAliveProvider, (_, _) {});
  container.listen(pipelineScheduleAliveProvider, (_, _) {});
  container.listen(pipelineCostRollupAliveProvider, (_, _) {});
  await settle();

  // Workspace + analytics listeners.
  container.listen(ceoAgentSeedProvider, (_, _) {});
  container.listen(builtInTemplateReseedProvider, (_, _) {});
  // Caches the active workspace's name + logo so the title-bar chip renders it
  // instantly on the next cold start instead of flashing "no workspace".
  container.listen(workspaceDisplayCacheProvider, (_, _) {});
  container.listen(xpEngineProvider, (_, _) {});
  container.listen(snapshotAggregatorProvider, (_, _) {});
  container.listen(worktreeGcListenerProvider, (_, _) {});
  await settle();

  // Ticketing listeners.
  container.listen(ticketResumeListenerAliveProvider, (_, _) {});
  container.listen(ticketRemoteSyncAliveProvider, (_, _) {});
  container.listen(ticketChannelServiceAliveProvider, (_, _) {});
  container.listen(ticketDispatcherAliveProvider, (_, _) {});
  // Orchestration: register the deterministic bodies into the pipeline body
  // registry, and keep the run listener alive to map terminal run states.
  container.read(orchestrationBodiesProvider);
  container.listen(orchestrationRunListenerProvider, (_, _) {});
  // Memory: harvest schema-validated ticket outputs into workspace memory.
  container.listen(memoryHarvestListenerProvider, (_, _) {});
  // Observability: persist the audit trail + bridge domain events into it.
  container.listen(activityLogPersisterProvider, (_, _) {});
  container.listen(domainEventAuditBridgeProvider, (_, _) {});
  // Meetings: finalize a meeting when its summary pipeline run ends.
  container.listen(meetingSummaryReconcilerAliveProvider, (_, _) {});
  // Calendar: periodic Google sync + "meeting starting soon" alert scheduler.
  container.listen(calendarSyncAliveProvider, (_, _) {});
  container.listen(meetingAlertSchedulerAliveProvider, (_, _) {});
  await settle();

  // Notification event mapper — maps DomainEventBus events to desktop
  // notifications. Retained for the app's lifetime via the event-bus
  // subscriptions created in its constructor.
  // ignore: unused_local_variable
  final notificationEventMapper = NotificationEventMapper(
    eventBus: container.read(domainEventBusProvider),
    notificationPort: container.read(notificationServiceProvider),
    localizations: () => lookupAppLocalizations(
      container.read(localeProvider) ?? PlatformDispatcher.instance.locale,
    ),
  );

  // PR polling service for external PR detection.
  final prPollingService = PrPollingService(
    githubClient: container.read(githubApiClientProvider),
    eventBus: container.read(domainEventBusProvider),
    repos: [], // Populated from linked repos below.
  );
  // Best-effort: start polling once repos are available.
  Future.delayed(const Duration(seconds: 10), () async {
    try {
      final repoEntities = await container
          .read(repoRepositoryProvider)
          .watchAll()
          .first;
      final repos = repoEntities
          .where((r) => r.hasGitHubRemote)
          .map((r) => (owner: r.githubOwner, name: r.githubRepoName))
          .toList();
      if (repos.isNotEmpty) {
        prPollingService
          ..stop()
          ..start();
      }
    } on Object catch (e) {
      AppLog.w('main', 'PR polling start failed: $e');
    }
  });

  // Content-blocking filter list auto-update.
  Future.delayed(const Duration(seconds: 15), () async {
    if (!container.read(contentBlockingProvider)) {
      return;
    }
    try {
      await container.read(filterListUpdateProvider.notifier).autoUpdate();
    } on Object catch (e) {
      AppLog.w('main', 'filter list auto-update failed: $e');
    }
  });

  // Seed default newsfeed feeds and refresh in background.
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      final repo = container.read(newsfeedRepositoryProvider);
      await repo.seedDefaultFeedsIfEmpty();
      await container
          .read(newsfeedRefreshControllerProvider.notifier)
          .refreshAll();
    } on Object catch (e) {
      AppLog.w('main', 'newsfeed seed/refresh failed: $e');
    }
  });

  // Backfill message embeddings on cold start (best-effort, non-blocking).
  Future.delayed(const Duration(seconds: 30), () async {
    try {
      await container.read(backfillMessageEmbeddingsUseCaseProvider).execute();
    } on Object catch (e) {
      AppLog.w('main', 'message embedding backfill failed: $e');
    }
  });
}

/// Scheme prefix Google reserves for an iOS-type OAuth client's redirect
/// (`com.googleusercontent.apps.<client>://…`). Matched by prefix because the
/// `<client>` portion varies per deployment.
const String _googleOAuthRedirectScheme = 'com.googleusercontent.apps.';

/// Dispatches an inbound custom-scheme URL: OAuth redirects feed the in-flight
/// Google sign-in flow via the redirect channel, everything else goes through
/// the app's deep-link router.
Future<void> _handleIncomingUrl(
  ProviderContainer container,
  String rawUrl,
) async {
  if (rawUrl.startsWith(_googleOAuthRedirectScheme)) {
    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      container.read(googleOAuthRedirectChannelProvider).emit(uri);
    }
    return;
  }
  await _handleDeepLink(container, rawUrl);
}

/// Resolves a `control-center://pr/<owner>/<repo>/<number>` deep link. When
/// the target repo is registered in some workspace, switches the active
/// workspace and repo to that target before navigating to the PR detail —
/// otherwise the PR screen would render with the previously active repo's
/// context and fetch the wrong PR.
Future<void> _handleDeepLink(ProviderContainer container, String rawUrl) async {
  final uri = DeepLinkHandler.parse(rawUrl);
  if (uri == null) {
    return;
  }
  final pr = DeepLinkHandler.parsePr(uri);
  if (pr == null) {
    return;
  }

  final repoRepo = container.read(repoRepositoryProvider);
  final wsRepo = container.read(workspaceRepositoryProvider);

  final allRepos = await repoRepo.watchAll().first;
  final target = allRepos
      .where(
        (r) =>
            r.githubOwner.toLowerCase() == pr.owner.toLowerCase() &&
            r.githubRepoName.toLowerCase() == pr.repo.toLowerCase(),
      )
      .firstOrNull;

  if (target != null) {
    final allWorkspaces = await wsRepo.watchAll().first;
    for (final ws in allWorkspaces) {
      final wsRepos = await wsRepo.watchReposForWorkspace(ws.id).first;
      if (wsRepos.any((r) => r.id == target.id)) {
        await container
            .read(activeWorkspaceIdProvider.notifier)
            .setActive(ws.id);
        await container
            .read(activeRepoIdProvider.notifier)
            .setActive(target.id);
        break;
      }
    }
  }

  container.read(routerProvider).go('/pull-requests/${pr.number}');
}

/// Persists the main window's position/size and, on close, tears down the
/// floating focus pill so the app can exit cleanly.
class WindowPositionListener extends WindowListener {
  /// Creates a [WindowPositionListener] backed by [_prefs].
  WindowPositionListener(this._prefs);

  final SharedPreferences _prefs;

  @override
  void onWindowMoved() => _save();

  @override
  void onWindowResized() => _save();

  @override
  void onWindowClose() => _handleClose();

  Future<void> _handleClose() async {
    // Tear down the floating focus pill (and its ticking timer) before the main
    // window is destroyed, so the app exits cleanly instead of being kept alive
    // by the always-on-top pill. setPreventClose(true) is what lets us run this
    // before the window actually goes away.
    try {
      await closeAllFocusPillWindows();
    } on Object catch (_) {}
    await windowManager.destroy();
  }

  Future<void> _save() async {
    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();
    await _prefs.setDouble('window_x', pos.dx);
    await _prefs.setDouble('window_y', pos.dy);
    await _prefs.setDouble('window_w', size.width);
    await _prefs.setDouble('window_h', size.height);
  }
}

/// Root application widget.
class MyApp extends ConsumerWidget {
  /// Creates the root application widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localeOverride = ref.watch(localeProvider);
    final fontSettings = ref.watch(fontSettingsProvider);
    final appFontFamily = fontSettings.appFontSelection.family;

    return AppShortcuts(
      commandBuilder: buildGlobalCommands,
      onToggleWorkspaceSwitcher: () {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          toggleWorkspaceSwitcher(ctx);
        }
      },
      onCycleWorkspace: (delta) {
        final workspaces = ref.read(workspacesProvider).value ?? const [];
        if (workspaces.length < 2) {
          return;
        }
        final currentId = ref.read(activeWorkspaceIdProvider);
        final currentIndex = workspaces.indexWhere((w) => w.id == currentId);
        final base = currentIndex < 0 ? 0 : currentIndex;
        var nextIndex = (base + delta) % workspaces.length;
        if (nextIndex < 0) {
          nextIndex += workspaces.length;
        }
        ref
            .read(activeWorkspaceIdProvider.notifier)
            .setActive(workspaces[nextIndex].id);
      },
      onSelectWorkspaceByIndex: (index) {
        final workspaces = ref.read(workspacesProvider).value ?? const [];
        if (index < 0 || index >= workspaces.length) {
          return;
        }
        ref
            .read(activeWorkspaceIdProvider.notifier)
            .setActive(workspaces[index].id);
      },
      onToggleFocusMode: () {
        ref.read(focusModeProvider.notifier).toggle();
      },
      child: MaterialApp.router(
        title: 'Control Center',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.light(appFontFamily: appFontFamily),
        darkTheme: AppTheme.dark(appFontFamily: appFontFamily),
        themeMode: themeMode,
        locale: localeOverride,
        supportedLocales: [
          ...AppLocalizations.supportedLocales,
          const Locale('en', 'US'),
          const Locale('fr', 'FR'),
          const Locale('es', 'ES'),
          const Locale('it', 'IT'),
          const Locale('de', 'DE'),
          const Locale('pt', 'BR'),
          const Locale('nl', 'NL'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          // CcTheme is the purist token-delivery channel (replacing the Material
          // ThemeExtension). It wraps the whole navigator so every route and
          // overlay can resolve `context.designSystem`. CcToastScope hosts the
          // app-wide toast overlay — it needs an Overlay ancestor to insert
          // into, and `MaterialApp.builder` sits *above* the router's own
          // overlay, so we provide a root Overlay here for it to mount toasts on
          // top of every route.
          return CcTheme(
            data: isDark
                ? CcThemeData.dark(fontFamily: appFontFamily)
                : CcThemeData.light(fontFamily: appFontFamily),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => CcToastScope(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
