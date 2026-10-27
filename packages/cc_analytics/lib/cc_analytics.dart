/// Analytics provider adapters for Control Center.
///
/// The `AnalyticsSink` implementations behind `cc_domain`'s `Analytics`
/// facade, plus `AnalyticsDestination`, which picks the provider. Pure Dart
/// and web-safe: `cc_domain` + `package:http`, no `dart:io`/FFI/Flutter.
library;

export 'src/analytics_destination.dart';
export 'src/umami_analytics_sink.dart';
