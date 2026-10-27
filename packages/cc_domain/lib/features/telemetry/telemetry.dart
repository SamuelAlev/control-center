/// Usage analytics and the install-wide telemetry configuration.
///
/// `Analytics` is the per-process facade: consent gating on the server's
/// `TelemetryConfig`, the PII policy, pseudonymization, and hand-off to an
/// `AnalyticsSink` (the provider seam). `AnalyticsEvents` is the tracking
/// plan.
library;

export 'domain/entities/analytics_envelope.dart';
export 'domain/entities/analytics_event.dart';
export 'domain/entities/telemetry_config.dart';
export 'domain/ports/analytics_sink.dart';
export 'domain/repositories/telemetry_config_repository.dart';
export 'domain/services/analytics.dart';
export 'domain/services/analytics_events.dart';
export 'domain/services/analytics_property_policy.dart';
export 'domain/services/analytics_pseudonymizer.dart';
export 'domain/services/server_telemetry_config_repository.dart';
export 'domain/value_objects/analytics_app_type.dart';
export 'domain/value_objects/analytics_context.dart';
export 'domain/value_objects/analytics_id.dart';
