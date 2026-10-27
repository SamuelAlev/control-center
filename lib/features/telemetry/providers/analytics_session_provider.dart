import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/analytics/client_analytics_context.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/server_build_provider.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/settings/providers/server_connection_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps [analyticsProvider]'s context current and records the events no
/// single screen owns: app open, foreground/background, server connection
/// and screen views.
///
/// A pure side-effect provider, watched from `ControlCenterApp` for the
/// session's lifetime like the other root sync providers.
final analyticsSessionProvider = Provider<void>((ref) {
  final analytics = ref.watch(analyticsProvider);

  void updateContext() {
    final locale =
        ref.read(localeProvider) ?? PlatformDispatcher.instance.locale;
    final mode = ref.read(serverListProvider).mode;
    analytics.updateContext(
      (c) => c.copyWith(
        locale: locale.toString(),
        serverMode: mode == ServerConnectionMode.local
            ? AnalyticsServerMode.local
            : AnalyticsServerMode.remote,
        serverVersion: ref.read(serverBuildProvider)?.version,
        isDemo: ref.read(isDemoServerProvider),
      ),
    );
  }

  updateContext();
  ref
    ..listen(localeProvider, (_, _) => updateContext())
    ..listen(serverListProvider, (_, _) => updateContext())
    ..listen(serverBuildProvider, (_, _) => updateContext())
    ..listen(isDemoServerProvider, (_, _) => updateContext())
    ..listen(currentIdentityProvider, (_, next) {
      final me = next.value;
      if (me != null) {
        analytics.identify(userId: me.user.id, deviceId: me.deviceId);
      }
    }, fireImmediately: true);

  analytics.track(
    AnalyticsEvents.appOpened(startupMs: millisecondsSinceAppLaunch()),
  );

  // Connection lifecycle. The session starts connected (the container is
  // only built after the boot connection is admitted, and `app_opened`
  // covers it), so these record drops and the reconnects that follow.
  var connected = true;
  final connection = ref.watch(rpcClientProvider).connectionState.listen((
    state,
  ) {
    switch (state) {
      case RemoteChannelState.open when !connected:
        connected = true;
        analytics.track(AnalyticsEvents.serverConnected(reconnect: true));
      case RemoteChannelState.closed when connected:
        connected = false;
        analytics.track(AnalyticsEvents.serverDisconnected());
      case _:
    }
  }, onError: (Object _) {});

  // Meeting recordings, from the recorder's own state transitions so both
  // the native and the web recorder are covered.
  ref.listen(meetingRecorderControllerProvider, (previous, next) {
    final wasRecording = previous?.isRecording ?? false;
    if (!wasRecording && next.isRecording) {
      analytics.track(
        AnalyticsEvents.meetingRecordingStarted(
          workspaceId: ref.read(activeWorkspaceIdProvider),
          meetingId: next.meetingId,
        ),
      );
    } else if (wasRecording && !next.isRecording) {
      final startedAt = previous?.startedAt;
      analytics.track(
        AnalyticsEvents.meetingRecordingStopped(
          durationS: startedAt == null
              ? 0
              : (DateTime.now().difference(startedAt) - previous!.pausedTotal)
                    .inSeconds,
          workspaceId: ref.read(activeWorkspaceIdProvider),
          meetingId: previous?.meetingId,
        ),
      );
    }
  });

  // Foreground/background with time spent in each, flushing on the way out
  // so a closed laptop lid does not strand the queue.
  var phaseStarted = DateTime.now();
  int secondsInPhase() {
    final now = DateTime.now();
    final seconds = now.difference(phaseStarted).inSeconds;
    phaseStarted = now;
    return seconds;
  }

  final lifecycle = AppLifecycleListener(
    onHide: () {
      analytics
        ..track(AnalyticsEvents.appBackgrounded(foregroundS: secondsInPhase()))
        ..flush();
    },
    onShow: () => analytics.track(
      AnalyticsEvents.appForegrounded(backgroundS: secondsInPhase()),
    ),
  );

  // Screen views from the router: the matched route TEMPLATE plus its ID
  // parameters, recorded once per distinct location.
  final router = ref.watch(routerProvider);
  String? lastLocation;
  void onRoute() {
    final match = router.routerDelegate.currentConfiguration;
    if (match.isEmpty) {
      return;
    }
    final location = match.uri.toString();
    if (location == lastLocation) {
      return;
    }
    lastLocation = location;
    analytics.screen(
      AnalyticsScreenView.fromRoute(match.fullPath, {
        ...match.uri.queryParameters,
        ...match.pathParameters,
      }),
    );
  }

  void onTabOpened(String kind) =>
      analytics.track(AnalyticsEvents.tabOpened(kind: kind));
  EditorTabGroupController.onTabOpened = onTabOpened;

  router.routerDelegate.addListener(onRoute);
  WidgetsBinding.instance.addPostFrameCallback((_) => onRoute());

  ref.onDispose(() {
    // Only clear our own hook: a newer session may already have set its own.
    if (EditorTabGroupController.onTabOpened == onTabOpened) {
      EditorTabGroupController.onTabOpened = null;
    }
    router.routerDelegate.removeListener(onRoute);
    lifecycle.dispose();
    unawaited(connection.cancel());
  });
});
