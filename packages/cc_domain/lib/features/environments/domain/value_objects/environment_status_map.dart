import 'package:cc_domain/features/environments/domain/services/environment_definition_reader.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:collection/collection.dart';

/// Reads a tool's own JSON without jq.
///
/// Paths are JSON pointers with `*` as a wildcard over arrays and objects.
/// State rules are ordered and the first match wins.
class EnvironmentStatusMap {
  /// Creates an [EnvironmentStatusMap].
  const EnvironmentStatusMap({
    required this.state,
    this.detail,
    this.warnings = const [],
    this.endpoints = const [],
    this.services,
    this.list,
    this.missingErrorCodes = const [],
  });

  /// Parses a `statusMap` object.
  ///
  /// Throws [EnvironmentDefinitionException] listing every issue.
  factory EnvironmentStatusMap.fromJson(Map<String, dynamic> json) {
    final issues = <EnvironmentDefinitionIssue>[];
    final map = read(EnvironmentJsonReader.of(json, 'statusMap', issues)!);
    if (map == null || issues.isNotEmpty) {
      throw EnvironmentDefinitionException(issues);
    }
    return map;
  }

  /// Reads a `statusMap` object, or null when it can't be built.
  static EnvironmentStatusMap? read(EnvironmentJsonReader reader) {
    final rules = reader.objects('state', required: true, nonEmpty: true);
    final state = [
      for (final rule in rules ?? const <EnvironmentJsonReader>[])
        EnvironmentStateRule.read(rule),
    ];
    final detail = reader.string('detail');
    final warnings = [
      for (final rule
          in reader.objects('warnings') ?? const <EnvironmentJsonReader>[])
        EnvironmentWarningRule.read(rule),
    ];
    final endpoints = [
      for (final endpoint
          in reader.objects('endpoints') ?? const <EnvironmentJsonReader>[])
        EnvironmentEndpointMap.read(endpoint),
    ];
    final services = readJsonPointer(reader, 'services');
    final list = readJsonPointer(reader, 'list');
    final missingErrorCodes = reader.strings('missingErrorCodes');
    reader.finish();
    if (rules == null ||
        state.contains(null) ||
        warnings.contains(null) ||
        endpoints.contains(null)) {
      return null;
    }
    return EnvironmentStatusMap(
      state: state.cast<EnvironmentStateRule>(),
      detail: detail,
      warnings: warnings.cast<EnvironmentWarningRule>(),
      endpoints: endpoints.cast<EnvironmentEndpointMap>(),
      services: services,
      list: list,
      missingErrorCodes: missingErrorCodes ?? const [],
    );
  }

  /// Ordered state rules.
  final List<EnvironmentStateRule> state;

  /// A detail template with `{/pointer}` interpolation.
  final String? detail;

  /// Warning rules.
  final List<EnvironmentWarningRule> warnings;

  /// Endpoint mappings.
  final List<EnvironmentEndpointMap> endpoints;

  /// Pointer to service names.
  final String? services;

  /// Pointer to names in the `list` verb's output.
  final String? list;

  /// Error codes that mean "no such environment".
  final List<String> missingErrorCodes;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'state': [for (final rule in state) rule.toJson()],
    if (detail != null) 'detail': detail,
    if (warnings.isNotEmpty)
      'warnings': [for (final warning in warnings) warning.toJson()],
    if (endpoints.isNotEmpty)
      'endpoints': [for (final endpoint in endpoints) endpoint.toJson()],
    if (services != null) 'services': services,
    if (list != null) 'list': list,
    if (missingErrorCodes.isNotEmpty) 'missingErrorCodes': missingErrorCodes,
  };

  /// Turns the tool's [json] into a report.
  EnvironmentStatusReport evaluate(Object? json) {
    var state = EnvironmentReportedState.degraded;
    String? message;
    for (final rule in this.state) {
      if (rule.when == null || rule.when!.matches(json)) {
        state = rule.state;
        message = rule.message == null
            ? null
            : _interpolate(rule.message!, json);
        break;
      }
    }
    final endpoints = <EnvironmentEndpoint>[];
    for (final map in this.endpoints) {
      final endpoint = map.resolve(json);
      if (endpoint != null) {
        endpoints.add(endpoint);
      }
    }
    final pointer = services;
    return EnvironmentStatusReport(
      state: state,
      message: message,
      detail: detail == null ? null : _interpolate(detail!, json),
      endpoints: endpoints,
      services: pointer == null
          ? const []
          : [
              for (final value in jsonPointerAll(json, pointer))
                if (value is String && value.isNotEmpty) value,
            ],
      warnings: [
        for (final rule in warnings)
          if (rule.when.matches(json)) rule.message,
      ],
    );
  }

  /// Names from the `list` verb's [json].
  List<String> names(Object? json) {
    final pointer = list;
    if (pointer == null) {
      return const [];
    }
    return [
      for (final value in jsonPointerAll(json, pointer))
        if (value is String) value,
    ];
  }

  static final RegExp _interpolation = RegExp(r'\{(/[^}]*)\}');

  static String _interpolate(String template, Object? json) =>
      template.replaceAllMapped(_interpolation, (match) {
        final value = jsonPointer(json, match.group(1)!);
        return value == null ? '-' : '$value';
      });

  @override
  bool operator ==(Object other) =>
      other is EnvironmentStatusMap &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A condition on a tool's JSON.
class EnvironmentStatusCondition {
  /// Creates an [EnvironmentStatusCondition].
  const EnvironmentStatusCondition({
    this.path,
    this.equals,
    this.any,
    this.none,
    this.where = const {},
  });

  /// Reads a condition, or null when it can't be built.
  static EnvironmentStatusCondition? read(EnvironmentJsonReader reader) {
    final path = readJsonPointer(reader, 'path');
    final any = readJsonPointer(reader, 'any');
    final none = readJsonPointer(reader, 'none');
    final equals = reader.raw('equals');
    final where = reader.map('where');
    final given = [
      reader.has('path'),
      reader.has('any'),
      reader.has('none'),
    ].where((present) => present).length;
    var ok = true;
    if (given != 1) {
      reader.reportHere('Needs exactly one of path, any and none');
      ok = false;
    }
    if (reader.contains('equals') && !reader.has('path')) {
      reader.report('equals', 'Only goes with path');
      ok = false;
    }
    if (where != null && reader.has('path')) {
      reader.report('where', 'Only goes with any or none');
      ok = false;
    }
    reader.finish();
    if (!ok || (path == null && any == null && none == null)) {
      return null;
    }
    return EnvironmentStatusCondition(
      path: path,
      equals: equals,
      any: any,
      none: none,
      where: where ?? const {},
    );
  }

  /// Pointer compared with [equals].
  final String? path;

  /// The expected value.
  final Object? equals;

  /// Pointer to an array where some item must match [where].
  final String? any;

  /// Pointer to an array where no item may match [where].
  final String? none;

  /// Field values an item must have.
  final Map<String, dynamic> where;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    if (path != null) 'path': path,
    if (path != null) 'equals': equals,
    if (any != null) 'any': any,
    if (none != null) 'none': none,
    if (where.isNotEmpty) 'where': where,
  };

  /// Whether [json] satisfies this condition.
  bool matches(Object? json) {
    final pointer = path;
    if (pointer != null) {
      return jsonPointer(json, pointer) == equals;
    }
    final anyPointer = any;
    if (anyPointer != null) {
      return _items(json, anyPointer).any(_itemMatches);
    }
    return !_items(json, none!).any(_itemMatches);
  }

  Iterable<Object?> _items(Object? json, String pointer) {
    final value = jsonPointer(json, pointer);
    return value is List ? value : const [];
  }

  bool _itemMatches(Object? item) {
    if (item is! Map) {
      return where.isEmpty;
    }
    return where.entries.every((entry) => item[entry.key] == entry.value);
  }

  @override
  bool operator ==(Object other) =>
      other is EnvironmentStatusCondition &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// One ordered state rule.
class EnvironmentStateRule {
  /// Creates an [EnvironmentStateRule].
  const EnvironmentStateRule({required this.state, this.when, this.message});

  /// Reads a rule, or null when it can't be built.
  static EnvironmentStateRule? read(EnvironmentJsonReader reader) {
    final whenReader = reader.object('when');
    final when = whenReader == null
        ? null
        : EnvironmentStatusCondition.read(whenReader);
    final state = reader.choice('state', {
      for (final state in EnvironmentReportedState.values) state.name: state,
    }, required: true);
    final message = reader.string('message');
    reader.finish();
    if (state == null || (reader.has('when') && when == null)) {
      return null;
    }
    return EnvironmentStateRule(state: state, message: message, when: when);
  }

  /// The state this rule assigns.
  final EnvironmentReportedState state;

  /// The condition, or null for the catch-all.
  final EnvironmentStatusCondition? when;

  /// What happened, in words, when this rule decides the state: a failed rule
  /// says what failed rather than leaving a person to read `detail`. May hold
  /// `{/pointer}` placeholders like `detail`.
  final String? message;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    if (when != null) 'when': when!.toJson(),
    'state': state.name,
    if (message != null) 'message': message,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentStateRule &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A warning shown when its condition holds.
class EnvironmentWarningRule {
  /// Creates an [EnvironmentWarningRule].
  const EnvironmentWarningRule({required this.when, required this.message});

  /// Reads a rule, or null when it can't be built.
  static EnvironmentWarningRule? read(EnvironmentJsonReader reader) {
    final whenReader = reader.object('when', required: true);
    final when = whenReader == null
        ? null
        : EnvironmentStatusCondition.read(whenReader);
    final message = reader.string('message', required: true, nonEmpty: true);
    reader.finish();
    if (when == null || message == null) {
      return null;
    }
    return EnvironmentWarningRule(when: when, message: message);
  }

  /// When to warn.
  final EnvironmentStatusCondition when;

  /// What to say.
  final String message;

  /// JSON form.
  Map<String, dynamic> toJson() => {'when': when.toJson(), 'message': message};

  @override
  bool operator ==(Object other) =>
      other is EnvironmentWarningRule &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// One mapped endpoint.
class EnvironmentEndpointMap {
  /// Creates an [EnvironmentEndpointMap].
  const EnvironmentEndpointMap({
    required this.role,
    this.label,
    this.url,
    this.hostPort,
    this.primary = false,
  });

  /// Reads a mapping, or null when it can't be built.
  static EnvironmentEndpointMap? read(EnvironmentJsonReader reader) {
    final role = reader.string('role', required: true, nonEmpty: true);
    final label = reader.string('label');
    final url = readJsonPointer(reader, 'url');
    final hostPort = readJsonPointer(reader, 'hostPort');
    final primary = reader.boolean('primary');
    if (!reader.has('url') && !reader.has('hostPort')) {
      reader.reportHere('Needs url or hostPort');
    }
    reader.finish();
    if (role == null || (url == null && hostPort == null)) {
      return null;
    }
    return EnvironmentEndpointMap(
      role: role,
      label: label,
      url: url,
      hostPort: hostPort,
      primary: primary ?? false,
    );
  }

  /// Stable role.
  final String role;

  /// What to show.
  final String? label;

  /// Pointer to the URL.
  final String? url;

  /// Pointer to the port.
  final String? hostPort;

  /// The main entry point.
  final bool primary;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'role': role,
    if (label != null) 'label': label,
    if (url != null) 'url': url,
    if (hostPort != null) 'hostPort': hostPort,
    if (primary) 'primary': true,
  };

  /// The endpoint in [json], or null when its values are absent.
  EnvironmentEndpoint? resolve(Object? json) {
    final urlValue = url == null ? null : jsonPointer(json, url!);
    final portValue = hostPort == null ? null : jsonPointer(json, hostPort!);
    final text = urlValue is String && urlValue.isNotEmpty ? urlValue : null;
    final port = portValue is int ? portValue : null;
    if (text == null && port == null) {
      return null;
    }
    return EnvironmentEndpoint(
      role: role,
      label: label,
      url: text,
      hostPort: port,
      primary: primary,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EnvironmentEndpointMap &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// The JSON pointer at [key] of [reader], which must start with `/`.
String? readJsonPointer(EnvironmentJsonReader reader, String key) {
  final pointer = reader.string(key);
  if (pointer == null) {
    return null;
  }
  if (!pointer.startsWith('/')) {
    reader.report(key, 'Must be a JSON pointer starting with /');
    return null;
  }
  return pointer;
}

/// The value at [pointer] in [json], or null.
Object? jsonPointer(Object? json, String pointer) {
  final all = jsonPointerAll(json, pointer).toList(growable: false);
  return all.isEmpty ? null : all.first;
}

/// Every value at [pointer] in [json], expanding `*`.
Iterable<Object?> jsonPointerAll(Object? json, String pointer) {
  final segments = pointer
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  var current = <Object?>[json];
  for (final segment in segments) {
    final next = <Object?>[];
    for (final value in current) {
      if (segment == '*') {
        if (value is List) {
          next.addAll(value);
        } else if (value is Map) {
          next.addAll(value.values);
        }
      } else if (value is Map) {
        if (value.containsKey(segment)) {
          next.add(value[segment]);
        }
      } else if (value is List) {
        final index = int.tryParse(segment);
        if (index != null && index >= 0 && index < value.length) {
          next.add(value[index]);
        }
      }
    }
    current = next;
  }
  return current;
}
