import 'package:cc_domain/features/telemetry/domain/value_objects/analytics_app_type.dart';
import 'package:collection/collection.dart';

const _propertiesEquality = MapEquality<String, Object>();

/// Whether an [AnalyticsEnvelope] is a screen view or a custom event.
enum AnalyticsEnvelopeKind {
  /// A screen view (a page view in web-analytics terms).
  screenView,

  /// A named product event.
  event,
}

/// One record, sanitized and ready for a provider.
///
/// This is all an `AnalyticsSink` ever sees. Properties are already merged
/// with the context, checked by `AnalyticsPropertyPolicy` and pseudonymized,
/// so every value is a `String`, finite `num` or `bool`. A sink translates the
/// envelope into its provider's format and must not add fields of its own
/// that identify the user, the machine or its network.
class AnalyticsEnvelope {
  /// Creates an [AnalyticsEnvelope].
  AnalyticsEnvelope({
    required this.kind,
    required this.name,
    required this.appType,
    required this.occurredAt,
    required Map<String, Object> properties,
    this.path,
    this.distinctId,
    this.locale,
    this.screen,
  }) : properties = Map.unmodifiable(properties) {
    if (kind == AnalyticsEnvelopeKind.screenView && path == null) {
      throw ArgumentError.value(path, 'path', 'required for screen views');
    }
  }

  /// Screen view or event.
  final AnalyticsEnvelopeKind kind;

  /// Event name, or the screen name for a screen view.
  final String name;

  /// Route template for a screen view; for an event, the template of the
  /// screen it happened on, when known.
  final String? path;

  /// Surface that recorded it.
  final AnalyticsAppType appType;

  /// When it was recorded (UTC).
  final DateTime occurredAt;

  /// Sanitized properties.
  final Map<String, Object> properties;

  /// Pseudonymous, stable per-device identifier, when the device is known.
  /// Providers that support it use it to keep one device's events in one
  /// session series across restarts.
  final String? distinctId;

  /// UI locale (`en_US`), when known.
  final String? locale;

  /// Display size as `WIDTHxHEIGHT`, when known.
  final String? screen;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsEnvelope &&
      other.kind == kind &&
      other.name == name &&
      other.path == path &&
      other.appType == appType &&
      other.occurredAt == occurredAt &&
      other.distinctId == distinctId &&
      other.locale == locale &&
      other.screen == screen &&
      _propertiesEquality.equals(other.properties, properties);

  @override
  int get hashCode => Object.hash(
    kind,
    name,
    path,
    appType,
    occurredAt,
    distinctId,
    locale,
    screen,
    _propertiesEquality.hash(properties),
  );

  @override
  String toString() =>
      'AnalyticsEnvelope(${kind.name} $name, ${properties.length} props)';
}
