import 'dart:async';

import 'package:cc_analytics/cc_analytics.dart';
import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart'
    show BuildInfo, CalendarEventDto, ConfirmationRequestDto;
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:cc_remote/app_router.dart';
import 'package:cc_remote/debug_log.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

void _log(String message) => rlog('analytics', message);

/// When `main()` started, for `app_opened.startup_ms`.
DateTime? _launchedAt;

/// Records the launch instant. Call first thing in `main()`.
void markAppLaunch() => _launchedAt ??= DateTime.now();

/// The install's telemetry decision, read from the paired server once a
/// client exists. The phone never decides on its own whether to collect.
final telemetryConfigProvider = StreamProvider<TelemetryConfig>((ref) async* {
  final client = await ref.watch(rpcClientProvider.future);
  yield* RemoteTelemetryConfigRepository(client).watch();
});

/// The phone's analytics facade (`app_type: remote`).
///
/// Sends nothing until the paired server's usage-analytics switch allows it,
/// and never from a debug or profile build, which logs events instead.
final analyticsProvider = Provider<Analytics>((ref) {
  final display = PlatformDispatcher.instance.displays.firstOrNull;
  final ratio = display?.devicePixelRatio ?? 0;
  late final Analytics analytics;
  analytics = Analytics(
    context: AnalyticsContext(
      appType: AnalyticsAppType.remote,
      appVersion: BuildInfo.buildVersion,
      appBuild: BuildInfo.buildGitSha,
      // The browser's OS (`ios`, `android`), which is what tells phone use
      // apart from a desktop browser opening the PWA.
      platform: defaultTargetPlatform.name.toLowerCase(),
      launchId: AnalyticsId(const Uuid().v4()),
      locale: PlatformDispatcher.instance.locale.toString(),
      serverMode: AnalyticsServerMode.remote,
      screenWidth: ratio == 0 ? null : (display!.size.width / ratio).round(),
      screenHeight: ratio == 0 ? null : (display!.size.height / ratio).round(),
    ),
    collectionAllowed: kReleaseMode,
    sinkFactory: (_) => AnalyticsDestination.createSink(
      context: analytics.context,
      nativeUserAgent: false,
      onDiagnostic: _log,
    ),
    developmentSink: const LoggingAnalyticsSink(_log),
    onDiagnostic: _log,
  );
  ref
    ..listen(telemetryConfigProvider, (_, next) {
      final config = next.value;
      if (config != null) {
        analytics.configure(config);
      }
    }, fireImmediately: true)
    ..onDispose(() => unawaited(analytics.dispose()));
  return analytics;
});

/// Keeps the phone's analytics context current and records app open,
/// foreground/background, reconnects and screen views. Watched from the
/// root app for its lifetime.
final analyticsSessionProvider = Provider<void>((ref) {
  final analytics = ref.watch(analyticsProvider);

  ref
    ..listen(appLocaleProvider, (_, code) {
      analytics.updateContext(
        (c) => c.copyWith(
          locale: code ?? PlatformDispatcher.instance.locale.toString(),
        ),
      );
    }, fireImmediately: true)
    ..listen(rpcClientProvider, (_, next) {
      final client = next.value;
      if (client == null) {
        return;
      }
      analytics.updateContext(
        (c) => c.copyWith(serverVersion: client.serverBuild?.version),
      );
      RemoteIdentityRepository(client).me().then(
        (me) => analytics.identify(userId: me.user.id, deviceId: me.deviceId),
        onError: (Object _) {},
      );
    }, fireImmediately: true);

  final launchedAt = _launchedAt;
  analytics.track(
    AnalyticsEvents.appOpened(
      startupMs: launchedAt == null
          ? 0
          : DateTime.now().difference(launchedAt).inMilliseconds,
    ),
  );

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

  final router = ref.watch(appRouterProvider);
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

  router.routerDelegate.addListener(onRoute);
  WidgetsBinding.instance.addPostFrameCallback((_) => onRoute());

  ref.onDispose(() {
    router.routerDelegate.removeListener(onRoute);
    lifecycle.dispose();
  });
});

/// Records the user's answer to an approval request from [surface]
/// (`inbox`, `conversation`). IDs, severity and action classes only.
void trackApprovalDecision(
  WidgetRef ref,
  ConfirmationRequestDto request, {
  required bool approved,
  required bool remembered,
  required String surface,
}) => ref
    .read(analyticsProvider)
    .track(
      AnalyticsEvents.approvalDecided(
        approved: approved,
        remembered: remembered,
        surface: surface,
        actionClasses: request.actionClasses,
        severity: request.severity,
        workspaceId: request.workspaceId,
        spaceId: request.spaceId,
        conversationId: request.conversationId,
      ),
    );

/// Opens [event]'s meeting link and records `calendar_meeting_joined` with
/// the conferencing provider only (never the URL).
void joinCalendarMeeting(WidgetRef ref, CalendarEventDto event) {
  ref
      .read(analyticsProvider)
      .track(
        AnalyticsEvents.calendarMeetingJoined(
          provider: AnalyticsEvents.meetingProvider(event.meetingUrl),
          workspaceId: ref.read(activeWorkspaceIdProvider).value,
          calendarEventId: event.id,
        ),
      );
  openExternal(event.meetingUrl);
}

/// Awaits [action] (a plan approval or rejection) and, once it succeeds,
/// records `plan_decided` for [decision] (`decision`, `planId`,
/// `workspaceId`, `partial`). [analytics] is read by the caller before any
/// await, while the screen is still mounted.
Future<T> recordPlanDecision<T>(
  Analytics analytics,
  Future<T> action,
  (String decision, String planId, String workspaceId, bool? partial) decision,
) async {
  final result = await action;
  final (verdict, planId, workspaceId, partial) = decision;
  analytics.track(
    AnalyticsEvents.planDecided(
      decision: verdict,
      planId: planId,
      workspaceId: workspaceId,
      partial: partial,
    ),
  );
  return result;
}
