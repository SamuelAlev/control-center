import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cc_data/cc_data.dart';
import 'package:cc_infra/src/git/pr_polling_service.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/app/app_windows.dart';
import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/core/deep_link/deep_link_handler.dart';
import 'package:control_center/core/notifications/notification_event_mapper.dart';
import 'package:control_center/core/observability/sentry_bootstrap.dart';
import 'package:control_center/core/providers/app_log_provider.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/font_cache_path_provider.dart';
import 'package:control_center/core/storage/native_key_value_backend.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/core/utils/cc_domain_logging.dart';
import 'package:control_center/core/utils/cc_infra_logging.dart';
import 'package:control_center/core/utils/cc_mcp_logging.dart';
import 'package:control_center/core/utils/cc_persistence_logging.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_server_provider.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_detection_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_toolbar_controller.dart';
import 'package:control_center/features/meetings/providers/meeting_server_providers.dart';
import 'package:control_center/features/memory/providers/memory_server_providers.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/orchestration/providers/orchestration_server_providers.dart';
import 'package:control_center/features/pipelines/pipeline_server_providers.dart';
import 'package:control_center/features/remote_control/application/cc_host_logging.dart';
import 'package:control_center/features/remote_control/providers/local_rpc_server_provider.dart';
import 'package:control_center/features/remote_control/providers/remote_control_server_provider.dart';
import 'package:control_center/features/ticketing/ticketing_server_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_server_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:nativeapi/nativeapi.dart';

/// Desktop bootstrap: full-featured native multi-window app.
///
/// This is the verbatim desktop startup sequence — logging installs, hotkey
/// reset, font-cache redirect, error handlers, multi-window chrome, the
/// `ProviderContainer` with its real (keychain + native preferences) storage
/// overrides, font preload, deep-link wiring, and the deferred background
/// services — culminating in `runAppWithSentry(AppWindows())`. The desktop
/// self-serves its own data, so `rpcClientProvider` keeps its in-process host
/// default (no override needed). The web counterpart is `bootstrap_web.dart`.
Future<void> bootstrapAndRun() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Route the server-side packages' log seams (cc_host kernel + cc_infra
  // adapters / dio clients + cc_persistence repositories) into AppLog before any
  // server or client starts.
  installCcHostLogging();
  installCcInfraLogging();
  installCcPersistenceLogging();
  installCcDomainLogging();
  installCcMcpLogging();

  // The focus pill and meeting-recording toolbar are sibling windows in this
  // same isolate (Flutter native multi-window) — there is no separate sub-window
  // engine to dispatch to. They are declared in `AppWindows` and styled in the
  // `setWillShowHook` below.

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

  final prefs = AppPreferences(NativeKeyValueBackend());
  final secureStore = SecureStore.keychain();

  // Multi-window chrome: nativeapi observes and controls the windows that
  // Flutter's windowing layer creates (see `AppWindows`). Style each window the
  // moment it is about to show — restore the primary window's geometry, hide its
  // title bar, and give the HUDs their frameless always-on-top chrome — and
  // persist geometry back to prefs as the user moves/resizes. Replaces
  // window_manager's WindowOptions + waitUntilReadyToShow + WindowListener.
  final windowManager = WindowManager.instance;
  windowManager.setWillShowHook((windowId) {
    final window = windowManager.getById(windowId);
    if (window != null) {
      styleWindowOnShow(window, prefs);
    }
    return true;
  });
  windowManager.addCallbackListener<WindowMovedEvent>(
    (e) => persistWindowGeometry(windowManager, prefs, e.windowId),
  );
  windowManager.addCallbackListener<WindowResizedEvent>(
    (e) => persistWindowGeometry(windowManager, prefs, e.windowId),
  );

  // Thin-client flip: the desktop opens NO database. It connects to a
  // `cc_server` that owns the data over loopback/WSS RPC — the same path the web
  // build uses. The user's persisted choice decides which server:
  //   * LOCAL  → spawn a `cc_server` here (owns the SAME control_center.db under
  //     the app-support root) and connect to it over loopback.
  //   * REMOTE → dial a server running elsewhere with the stored pairing key.
  // On first run (or a failed remote connect) this shows the pre-app setup
  // screen so the user chooses. `rpcClientProvider` is overridden with the
  // resulting connected client, so the whole UI + feature providers read/write
  // through the server instead of an in-process Drift host.
  final backend = await resolveServerBackend(
    prefs: prefs,
    secureStore: secureStore,
  );

  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(prefs),
      secureStoreProvider.overrideWithValue(secureStore),
      rpcClientProvider.overrideWithValue(backend.client),
    ],
  );

  // Initialise the app-wide logger from persisted preferences.
  container.read(appLogLevelProvider);

  // Bind the RPC session to the active workspace BEFORE the UI subscribes to
  // any workspace-scoped op, and re-bind on every workspace switch. The
  // thin-client desktop opens no database, so (like `bootstrap_web`) the
  // workspace set comes from the connected `cc_server`: without this the server
  // session stays unbound and every workspace-scoped query fails with
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

  // Wire macOS menu-bar Preferences to in-app Settings, and deep link
  // URLs (control-center://) forwarded from AppDelegate.
  const appChannel = MethodChannel('com.controlcenter/app');
  appChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'openSettings':
        final router = container.read(routerProvider);
        final wsId = container.read(activeWorkspaceIdProvider);
        router.go(
          wsId == null ? workspaceListRoute : settingsAppearanceRoute(wsId),
        );
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

  // NOTE: the in-process background-service wiring (`_startBackgroundServices`,
  // kept below for reference) now runs inside the spawned `cc_server` — the
  // pipeline reconcilers, MCP server, orchestration listener, etc. The desktop
  // is a pure renderer and no longer assembles that backend DI graph in-process
  // (it has no database to back it). FOLLOW-UP: the desktop-host slice
  // (NotificationEventMapper, meeting capture/toolbar controllers) still needs
  // re-wiring to consume server events over RPC instead of the local event bus.
  //
  // Tear the spawned server down on a clean app exit so it does not orphan and
  // keep the SQLite file open (which would fail the next boot). The listener
  // registers itself with WidgetsBinding on construction and lives for the app
  // lifetime.
  // ignore: unused_local_variable
  final lifecycle = AppLifecycleListener(
    onExitRequested: () async {
      // Only a locally-spawned server is ours to stop; a remote connection has
      // no child process (process is null).
      await backend.process?.stop();
      return AppExitResponse.exit;
    },
  );

  // Route every remote-media fetch (avatars, feed images, PR-body images/video)
  // through the connected server's `/proxy/media` endpoint — the desktop is a
  // thin client, so it must not hit upstream hosts directly. Omitted only if the
  // connection couldn't be expressed as a proxy base (media then loads direct).
  final mediaProxy = backend.mediaProxy;
  await runAppWithSentry(
    () => UncontrolledProviderScope(
      container: container,
      child: mediaProxy != null
          ? MediaProxyScope(config: mediaProxy, child: const AppWindows())
          : const AppWindows(),
    ),
  );
}

/// Wires up background services after the first frame has painted.
///
/// KEPT FOR REFERENCE after the thin-client flip: these server-side services
/// now run inside the spawned `cc_server` (the desktop has no in-process
/// database to back them). The desktop-host slice (NotificationEventMapper,
/// meeting capture/toolbar) still needs re-homing onto RPC events before this
/// can be deleted — until then it documents exactly what moved server-side.
// ignore: unused_element
Future<void> _startBackgroundServices(ProviderContainer container) async {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  // MCP server — reading the provider assembles the tool registry + its deps.
  container.read(mcpServerProvider);

  // Remote control listener — reading the provider assembles the WebRTC peer
  // manager + per-device signaling. Auto-starts only if enabled + configured.
  container.read(remoteControlServerProvider);
  // WSS "act as server" listener (LAN / same-origin web). Loopback bind;
  // auto-starts only when wsServeEnabled.
  container.read(localRpcServerProvider);
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

  // Ticketing listeners (remote Linear sync only — dispatch/resume moved to
  // the pipeline step resume listener + the conversation dispatch path).
  container.listen(ticketRemoteSyncAliveProvider, (_, _) {});
  // Pipeline step resume: advances a step when its dispatched agent runs end.
  container.listen(pipelineStepResumeListenerAliveProvider, (_, _) {});
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
  // Meetings: automatic detection — poll signals, offer a record prompt.
  container.listen(meetingDetectionControllerProvider, (_, _) {});
  // Meetings: floating recording-toolbar owner — registers the toolbar's
  // command channel and mirrors recorder state into the sub-window when open.
  container.listen(meetingToolbarControllerProvider, (_, _) {});
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

/// Binds the RPC session to the active workspace and keeps it bound.
///
/// Lists the connected server's workspaces, binds the session to the active one
/// (the persisted choice if it still exists on this server, otherwise the
/// first), seeds [activeWorkspaceIdProvider], and re-binds on every later
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

  String? targetWorkspaceId;
  if (target != null) {
    final allWorkspaces = await wsRepo.watchAll().first;
    for (final ws in allWorkspaces) {
      final wsRepos = await wsRepo.watchReposForWorkspace(ws.id).first;
      if (wsRepos.any((r) => r.id == target.id)) {
        targetWorkspaceId = ws.id;
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

  // Navigate into the resolved workspace's PR detail; the workspace prefix in
  // the URL is what re-scopes the app. Fall back to the active workspace, then
  // the picker, if the PR's repo isn't linked anywhere.
  final wsId = targetWorkspaceId ?? container.read(activeWorkspaceIdProvider);
  container
      .read(routerProvider)
      .go(
        wsId == null
            ? workspaceListRoute
            : pullRequestDetailRoute(wsId, '${pr.owner}/${pr.repo}', pr.number),
      );
}
