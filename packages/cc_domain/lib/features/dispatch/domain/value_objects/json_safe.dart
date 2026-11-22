import 'package:collection/collection.dart';

/// Helpers for the free-form JSON maps the wake and goal value objects carry
/// (`WakeDetail.fields`, `WakeRunOptions.outputSchema`, verdict and evidence
/// payloads): the check that a value survives `jsonEncode` unchanged, and
/// deep equality for value semantics.
// ignore: avoid_classes_with_only_static_members
abstract final class JsonSafe {
  static const _equality = DeepCollectionEquality();

  /// Whether [value] is null, a bool, a finite number, a string, or a list or
  /// a string-keyed map of such values, at any depth.
  static bool isValue(Object? value) => switch (value) {
    null || bool() || String() => true,
    num() => value.isFinite,
    List<Object?>() => value.every(isValue),
    Map<Object?, Object?>() => value.entries.every(
      (e) => e.key is String && isValue(e.value),
    ),
    _ => false,
  };

  /// Throws [ArgumentError] naming [name] unless [map] is JSON-safe.
  static void require(Map<String, Object?> map, String name) {
    if (!isValue(map)) {
      throw ArgumentError.value(map, name, 'must hold JSON values only');
    }
  }

  /// [raw] as a string-keyed map when it is one and JSON-safe, else null.
  static Map<String, Object?>? mapOrNull(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = <String, Object?>{};
    for (final entry in raw.entries) {
      if (entry.key is! String) {
        return null;
      }
      map[entry.key as String] = entry.value;
    }
    return isValue(map) ? map : null;
  }

  /// Deep equality of two JSON values.
  static bool equals(Object? a, Object? b) => _equality.equals(a, b);

  /// A hash consistent with [equals].
  static int hash(Object? value) => _equality.hash(value);

  /// [raw] when it is a non-empty string, else null.
  static String? stringOrNull(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;

  /// [raw] as an int when it is an integral number, else null.
  static int? intOrNull(Object? raw) => switch (raw) {
    int() => raw,
    double() when raw.isFinite && raw == raw.truncateToDouble() => raw.toInt(),
    _ => null,
  };

  /// The strings of [raw] when it is a list (other elements dropped), else
  /// an empty list.
  static List<String> strings(Object? raw) => [
    if (raw is List)
      for (final item in raw)
        if (item is String && item.isNotEmpty) item,
  ];

  /// [raw] parsed as an ISO-8601 instant, or null.
  static DateTime? dateOrNull(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
