import 'package:cc_domain/features/telemetry/domain/value_objects/analytics_id.dart';
import 'package:collection/collection.dart';

/// Pattern for event names: lower snake_case, `<object>_<past-tense verb>`
/// (`message_sent`), at most 50 characters (the Umami column width).
final RegExp analyticsEventNamePattern = RegExp(r'^[a-z][a-z0-9_]{0,49}$');

/// Pattern for property keys: lower snake_case, at most 40 characters.
final RegExp analyticsPropertyKeyPattern = RegExp(r'^[a-z][a-z0-9_]{0,39}$');

/// Most properties one event may carry, context included.
const int analyticsMaxProperties = 48;

const _propertiesEquality = MapEquality<String, Object>();

/// Something recorded for analytics: a [AnalyticsScreenView] or an
/// [AnalyticsEvent].
///
/// Property values are raw here: `String`, `num`, `bool` or `AnalyticsId`.
/// `Analytics` runs them through `AnalyticsPropertyPolicy` and pseudonymizes
/// IDs before anything reaches a sink.
sealed class AnalyticsRecord {
  const AnalyticsRecord();

  /// Event-specific properties.
  Map<String, Object> get properties;
}

/// A product action, named in the tracking plan (`AnalyticsEvents`).
class AnalyticsEvent extends AnalyticsRecord {
  /// Creates an [AnalyticsEvent]. Throws [ArgumentError] for a malformed
  /// [name] or property key, or too many properties.
  AnalyticsEvent(this.name, [Map<String, Object?> properties = const {}])
    : properties = Map.unmodifiable({
        for (final MapEntry(:key, :value) in properties.entries) key: ?value,
      }) {
    if (!analyticsEventNamePattern.hasMatch(name)) {
      throw ArgumentError.value(name, 'name', 'must be lower snake_case');
    }
    _validateKeys(this.properties);
  }

  /// Event name.
  final String name;

  @override
  final Map<String, Object> properties;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsEvent &&
      other.name == name &&
      _propertiesEquality.equals(other.properties, properties);

  @override
  int get hashCode => Object.hash(name, _propertiesEquality.hash(properties));

  @override
  String toString() => 'AnalyticsEvent($name, ${properties.keys.toList()})';
}

/// A screen the user navigated to.
///
/// [path] is the route TEMPLATE (`/workspaces/:workspaceId/spaces/:spaceId`),
/// never the concrete location: concrete paths carry raw IDs and split one
/// screen into thousands of rows. IDs worth keeping go in [properties] as
/// `AnalyticsId`s.
class AnalyticsScreenView extends AnalyticsRecord {
  /// Creates an [AnalyticsScreenView]. Throws [ArgumentError] when [path] is
  /// not a route template or [screen] is malformed.
  AnalyticsScreenView({
    required this.path,
    required this.screen,
    Map<String, Object?> properties = const {},
  }) : properties = Map.unmodifiable({
         for (final MapEntry(:key, :value) in properties.entries) key: ?value,
       }) {
    if (path.length > 200 || !_templatePattern.hasMatch(path)) {
      throw ArgumentError.value(path, 'path', 'must be a route template');
    }
    if (!analyticsEventNamePattern.hasMatch(screen)) {
      throw ArgumentError.value(screen, 'screen', 'must be lower snake_case');
    }
    _validateKeys(this.properties);
  }

  /// The screen view for a router location.
  ///
  /// [template] is the matched route pattern (GoRouter's `fullPath`) and
  /// [parameters] its path/query parameters. The screen name is the literal
  /// segments joined with `_` (`/workspaces/:workspaceId/spaces/:spaceId` →
  /// `workspaces_spaces`). `…Id` parameters become pseudonymized `…_id`
  /// properties and numeric ones (`:prNumber`) plain numbers; anything else
  /// is dropped, since a free-form parameter can carry a search term or a
  /// file path.
  factory AnalyticsScreenView.fromRoute(
    String template, [
    Map<String, String> parameters = const {},
  ]) {
    var path = template.isEmpty ? '/' : template;
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    final literals = [
      for (final segment in path.split('/'))
        if (segment.isNotEmpty && !segment.startsWith(':'))
          segment.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_'),
    ];
    var screen = literals.isEmpty ? 'root' : literals.join('_');
    screen = screen
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (screen.isEmpty || !RegExp('^[a-z]').hasMatch(screen)) {
      screen = 'screen_$screen';
    }
    if (screen.length > 50) {
      screen = screen.substring(0, 50).replaceAll(RegExp(r'_$'), '');
    }
    final properties = <String, Object?>{};
    for (final MapEntry(:key, :value) in parameters.entries) {
      final snake = key
          .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')
          .replaceAll(RegExp('[^a-z0-9_]'), '_')
          .replaceAll(RegExp('^_+'), '');
      if (!analyticsPropertyKeyPattern.hasMatch(snake) || value.isEmpty) {
        continue;
      }
      if (snake == 'id' || snake.endsWith('_id')) {
        properties[snake == 'id' ? '${screen.split('_').last}_id' : snake] =
            AnalyticsId(value);
      } else if (int.tryParse(value) case final number?) {
        properties[snake] = number;
      }
    }
    return AnalyticsScreenView(
      path: _templatePattern.hasMatch(path) ? path : '/',
      screen: screen,
      properties: properties,
    );
  }

  /// `/`, or slash-separated literal segments and `:param` placeholders.
  static final _templatePattern = RegExp(r'^(?:/|(?:/:?[A-Za-z0-9_-]+)+/?)$');

  /// Route template.
  final String path;

  /// Stable screen name (the route name, snake_cased).
  final String screen;

  @override
  final Map<String, Object> properties;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsScreenView &&
      other.path == path &&
      other.screen == screen &&
      _propertiesEquality.equals(other.properties, properties);

  @override
  int get hashCode =>
      Object.hash(path, screen, _propertiesEquality.hash(properties));

  @override
  String toString() => 'AnalyticsScreenView($path)';
}

void _validateKeys(Map<String, Object> properties) {
  if (properties.length > analyticsMaxProperties) {
    throw ArgumentError.value(
      properties.length,
      'properties',
      'at most $analyticsMaxProperties allowed',
    );
  }
  for (final key in properties.keys) {
    if (!analyticsPropertyKeyPattern.hasMatch(key)) {
      throw ArgumentError.value(key, 'properties', 'keys must be snake_case');
    }
  }
}
