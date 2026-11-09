import 'dart:async';

import 'package:control_center/app/tray/native_desktop_shell.dart';
import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/bootstrap/session_overrides.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/core/infrastructure/provider_retry.dart';
import 'package:control_center/core/notifications/rpc_notification_mapper.dart';
import 'package:control_center/core/providers/app_log_provider.dart';
import 'package:control_center/core/providers/desktop_shell_provider.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/shutdown_progress_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/agent_wait_reminder_provider.dart';
import 'package:control_center/di/notification_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/rpc_client_workspace_sync_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Process-wide inputs every desktop session is built from: they outlive
/// server switches, which rebuild the container around the same stores.
class DesktopSessionEnv {
  /// Creates the environment.
  const DesktopSessionEnv({
    required this.prefsBackend,
    required this.secureStore,
    required this.mediaPlaybackAvailable,
  });

  /// The one observable native preferences store of this process.
  final ObservableKeyValueBackend prefsBackend;

  /// The keychain facade.
  final SecureStore secureStore;

  /// Whether media_kit found libmpv at boot.
  final bool mediaPlaybackAvailable;

  /// The typed facade over [prefsBackend].
  AppPreferences get prefs => AppPreferences(prefsBackend);
}

/// One connected desktop session: the backend plus the `ProviderContainer`
/// and the per-session side services (notification mapper, wait reminders).
/// Rebuilt wholesale on an in-app server switch.
class DesktopBackendSession {
  DesktopBackendSession._(this.backend, this.container);

  /// A session around an already-built [container], for tests.
  @visibleForTesting
  DesktopBackendSession.forTesting(this.backend, this.container);

  /// The connected backend.
  final ServerBackend backend;

  /// The app's provider container, bound to [backend]'s client.
  final ProviderContainer container;

  RpcNotificationMapper? _notificationMapper;
  bool _disposed = false;

  /// Builds a container for [backend] and runs the post-connect side wiring.
  ///
  /// [switchServer] and [returnToSignIn] are the switcher's actions, handed to
  /// the settings UI and the lost-connection dialog.
  static Future<DesktopBackendSession> build({
    required ServerBackend backend,
    required DesktopSessionEnv env,
    required Future<void> Function(String serverId) switchServer,
    required Future<void> Function() returnToSignIn,
  }) async {
    // Who this session's device-local caches belong to. Best-effort: without
    // it the app simply waits for live answers instead of using any cache.
    final scope = await tryResolveSessionScope(
      backend.client,
      backend.supervisor,
      onError: (e) =>
          AppLog.w('main', 'could not resolve the session scope: $e'),
    );
    final container = ProviderContainer(
      // Bounded, unrecoverable-error-aware retry: keeps a subscription stream
      // error (e.g. a GitHub rate limit) from looping into a resubscribe storm.
      retry: appProviderRetry,
      overrides: sessionOverrides(
        client: backend.client,
        supervisor: backend.supervisor,
        mediaProxy: backend.mediaProxy,
        prefsBackend: env.prefsBackend,
        secureStore: env.secureStore,
        scope: scope,
        switchServer: switchServer,
        returnToSignIn: returnToSignIn,
        platform: [
          mediaPlaybackAvailableProvider.overrideWithValue(
            env.mediaPlaybackAvailable,
          ),
          // Process-wide, like the tray icon and the window it drives: a
          // server switch hands the next container the same shell.
          desktopShellProvider.overrideWithValue(NativeDesktopShell.instance),
        ],
      ),
    );
    final session = DesktopBackendSession._(backend, container);

    try {
      // Initialise the app-wide logger from persisted preferences.
      container.read(appLogLevelProvider);

      // Point the stateless client at the active workspace BEFORE anything
      // below subscribes to a workspace-scoped op; the sink follows every
      // later switch. (`ControlCenterApp` keeps it alive afterwards.)
      container.read(rpcClientWorkspaceSyncProvider);

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

      // OS notifications: maps the connected server's pushed `notifications/*`
      // frames (RemoteEventForwarder) to AppNotifications. Every input is read
      // lazily so the mapper always sees the freshest identity, mutes and
      // forge connections (they resolve over RPC after construction). Its
      // subscription is cancelled first on [dispose], before the container
      // those reads go through.
      session._notificationMapper = RpcNotificationMapper(
        client: backend.client,
        notificationPort: container.read(notificationServiceProvider),
        localizations: () => lookupAppLocalizations(
          container.read(localeProvider) ?? PlatformDispatcher.instance.locale,
        ),
        activeWorkspaceId: () => container.read(activeWorkspaceIdProvider),
        currentUserId: () => container.read(currentUserIdProvider),
        mutedRepos: () =>
            container.read(mutedReposProvider).asData?.value ?? const {},
        viewerLogins: () => container.read(viewerLoginSetProvider),
      );
      // Re-raises unanswered agent waits and withdraws ended ones. Lives as
      // long as the container; reading it starts its feed subscription.
      container.read(agentWaitReminderProvider);
      return session;
    } on Object {
      session._notificationMapper?.dispose();
      container.dispose();
      rethrow;
    }
  }

  /// Retires the session when the app quits.
  ///
  /// A bundled `cc_server` is stopped gracefully FIRST, while the container,
  /// the shutdown overlay watching it and the RPC client are all alive: the
  /// child streams its per-service teardown over that client and the overlay
  /// shows it live. Only once the child has exited is the session disposed. A
  /// remote server is not ours to stop; its session is just disposed.
  ///
  /// [nextFrame] defaults to the binding's `endOfFrame`; it gives the overlay
  /// one painted frame before the child is signalled.
  Future<void> quit({Future<void> Function()? nextFrame}) async {
    if (backend.isLocal) {
      container.read(shutdownProgressProvider.notifier).begin();
      await (nextFrame ?? () => WidgetsBinding.instance.endOfFrame)();
      try {
        await backend.stopLocalServer();
      } on Object catch (e) {
        AppLog.w('cc_server', 'graceful local shutdown failed: $e');
      }
    }
    await dispose();
  }

  /// Disposes the notification mapper, the container and the backend (local
  /// child included), in that order. Idempotent.
  ///
  /// The mapper goes first: its frame handler reads the container, and a frame
  /// arriving between the container's disposal and the client's close would
  /// otherwise read a disposed container. The backend is disposed even when
  /// the container's teardown throws (a provider's `onDispose`): on a switch to
  /// a remote server this is what stops the bundled `cc_server`, and skipping
  /// it left that child running behind the remote session.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    try {
      _notificationMapper?.dispose();
      _notificationMapper = null;
      container.dispose();
    } finally {
      await backend.dispose();
    }
  }
}
