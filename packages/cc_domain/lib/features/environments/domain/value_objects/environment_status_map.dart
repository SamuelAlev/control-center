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
  factory EnvironmentStatusMap.fromJson(Map<String, dynamic> json) {
    final rules = json['state'];
    if (rules is! List || rules.isEmpty) {
      throw const FormatException('statusMap.state needs at least one rule');
    }
    return EnvironmentStatusMap(
      state: [
        for (final rule in rules)
          EnvironmentStateRule.fromJson(Map<String, dynamic>.from(rule as Map)),
      ],
      detail: json['detail'] as String?,
      warnings: [
        for (final warning in (json['warnings'] as List?) ?? const [])
          EnvironmentWarningRule.fromJson(
            Map<String, dynamic>.from(warning as Map),
          ),
      ],
      endpoints: [
        for (final endpoint in (json['endpoints'] as List?) ?? const [])
          EnvironmentEndpointMap.fromJson(
            Map<String, dynamic>.from(endpoint as Map),
          ),
      ],
      services: json['services'] as String?,
      list: json['list'] as String?,
      missingErrorCodes: [
        for (final code in (json['missingErrorCodes'] as List?) ?? const [])
          '$code',
      ],
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

  /// Parses a condition.
  factory EnvironmentStatusCondition.fromJson(Map<String, dynamic> json) {
    final path = json['path'] as String?;
    final any = json['any'] as String?;
    final none = json['none'] as String?;
    if (path == null && any == null && none == null) {
      throw const FormatException('A condition needs path, any or none');
    }
    return EnvironmentStatusCondition(
      path: path,
      equals: json['equals'],
      any: any,
      none: none,
      where: json['where'] is Map
          ? Map<String, dynamic>.from(json['where'] as Map)
          : const {},
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

  /// Parses a rule.
  factory EnvironmentStateRule.fromJson(Map<String, dynamic> json) {
    final state = EnvironmentReportedState.tryParse(json['state'] as String?);
    if (state == null) {
      throw FormatException('Unknown state: ${json['state']}');
    }
    final when = json['when'];
    return EnvironmentStateRule(
      state: state,
      message: json['message'] as String?,
      when: when is Map
          ? EnvironmentStatusCondition.fromJson(Map<String, dynamic>.from(when))
          : null,
    );
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

  /// Parses a rule.
  factory EnvironmentWarningRule.fromJson(Map<String, dynamic> json) =>
      EnvironmentWarningRule(
        when: EnvironmentStatusCondition.fromJson(
          Map<String, dynamic>.from(json['when'] as Map),
        ),
        message: json['message'] as String,
      );

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

  /// Parses a mapping.
  factory EnvironmentEndpointMap.fromJson(Map<String, dynamic> json) =>
      EnvironmentEndpointMap(
        role: json['role'] as String,
        label: json['label'] as String?,
        url: json['url'] as String?,
        hostPort: json['hostPort'] as String?,
        primary: json['primary'] == true,
      );

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
