import 'dart:async';

import 'package:cc_analytics/cc_analytics.dart';
import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/analytics/client_analytics_context.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The install's telemetry decision, over RPC. The server owns it.
final telemetryConfigRepositoryProvider = Provider<TelemetryConfigRepository>(
  (ref) => RemoteTelemetryConfigRepository(ref.watch(rpcClientProvider)),
);

/// The live telemetry config; changes when the operator flips the switch.
final telemetryConfigProvider = StreamProvider<TelemetryConfig>(
  (ref) => ref.watch(telemetryConfigRepositoryProvider).watch(),
);

/// This client's analytics facade.
///
/// Call sites record through it with events from `AnalyticsEvents`:
/// `ref.read(analyticsProvider).track(AnalyticsEvents.…)`. It sends nothing
/// until [telemetryConfigProvider] says the install allows it, and never
/// from a debug or profile build, which logs events at debug level instead.
/// Context (identity, server mode, locale) is kept current by
/// `analyticsSessionProvider`.
final analyticsProvider = Provider<Analytics>((ref) {
  late final Analytics analytics;
  analytics = Analytics(
    context: clientAnalyticsContext(),
    collectionAllowed: kReleaseMode,
    sinkFactory: (_) => AnalyticsDestination.createSink(
      context: analytics.context,
      // Browsers refuse a page-set User-Agent; native processes need one for
      // the provider to recognize the OS.
      nativeUserAgent: !kIsWeb,
      onDiagnostic: (message) => AppLog.d('Analytics', message),
    ),
    developmentSink: LoggingAnalyticsSink(
      (line) => AppLog.d('Analytics', line),
    ),
    onDiagnostic: (message) => AppLog.d('Analytics', message),
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

/// Shorthand for recording from a widget or notifier.
extension AnalyticsRef on Ref {
  /// Records [event] through [analyticsProvider].
  void track(AnalyticsEvent event) => read(analyticsProvider).track(event);
}

/// Shorthand for recording from a widget.
extension AnalyticsWidgetRef on WidgetRef {
  /// Records [event] through [analyticsProvider].
  void track(AnalyticsEvent event) => read(analyticsProvider).track(event);
}
