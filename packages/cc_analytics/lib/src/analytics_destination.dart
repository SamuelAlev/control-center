// ignore_for_file: avoid_classes_with_only_static_members — build-time constants plus the provider switch.

import 'package:cc_analytics/src/umami_analytics_sink.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:http/http.dart' as http;

/// Where Control Center's analytics go, and the one place that picks the
/// provider.
///
/// Every process builds its provider sink through [createSink]; switching
/// providers (or adding a second, fan-out sink) is a change here and nowhere
/// else. The defaults can be overridden at build time with
/// `--define=CC_ANALYTICS_HOST=…` / `--define=CC_ANALYTICS_WEBSITE_ID=…`, e.g.
/// for a fork that reports to its own instance.
abstract final class AnalyticsDestination {
  /// The Umami instance.
  static final Uri umamiHost = Uri.parse(
    const String.fromEnvironment(
      'CC_ANALYTICS_HOST',
      defaultValue: 'https://analytics.alev.dev/',
    ),
  );

  /// The Umami website that collects Control Center usage.
  static const String umamiWebsiteId = String.fromEnvironment(
    'CC_ANALYTICS_WEBSITE_ID',
    defaultValue: '1ce627f2-53d8-49de-b3e1-0fc8daf94951',
  );

  /// The provider sink for a process described by [context].
  ///
  /// [nativeUserAgent] controls whether a User-Agent header is sent (false
  /// on the web, where browsers refuse to let a page set one).
  static AnalyticsSink createSink({
    required AnalyticsContext context,
    required bool nativeUserAgent,
    http.Client? client,
    void Function(String message)? onDiagnostic,
  }) => UmamiAnalyticsSink(
    host: umamiHost,
    websiteId: umamiWebsiteId,
    userAgent: nativeUserAgent
        ? umamiUserAgent(
            platform: context.platform,
            appVersion: context.appVersion,
            product: context.appType == AnalyticsAppType.server
                ? 'ControlCenterServer'
                : 'ControlCenter',
          )
        : null,
    client: client,
    onDiagnostic: onDiagnostic,
  );
}
