import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';

/// Reads one JSON object of a definition strictly.
///
/// A definition is written by hand, so a typo must fail where it was made.
/// Every accessor takes a key, records it as known and, when the value has
/// the wrong shape, adds an [EnvironmentDefinitionIssue] at `<path>.<key>`
/// instead of throwing. [finish] then reports every key nothing asked for.
/// Parsers keep going after an issue, so one pass names as many as it can.
class EnvironmentJsonReader {
  EnvironmentJsonReader._(this._json, this.path, this.issues);

  /// A reader over [json] at [path], or null after reporting at [path] that
  /// it is not an object.
  static EnvironmentJsonReader? of(
    Object? json,
    String path,
    List<EnvironmentDefinitionIssue> issues,
  ) {
    if (json is! Map) {
      issues.add(EnvironmentDefinitionIssue(path, 'Must be an object'));
      return null;
    }
    return EnvironmentJsonReader._(
      {for (final entry in json.entries) '${entry.key}': entry.value},
      path,
      issues,
    );
  }

  final Map<String, Object?> _json;

  /// Where this object sits, such as `components[2].ready`. Empty at the top.
  final String path;

  /// Where issues go, shared with every reader of the same definition.
  final List<EnvironmentDefinitionIssue> issues;

  final Set<String> _known = {};

  /// Every key present, for objects whose keys are names, such as `env`.
  Iterable<String> get keys => _json.keys;

  /// The path of [key] in this object.
  String pathOf(String key) => path.isEmpty ? key : '$path.$key';

  /// Adds an issue at [key].
  void report(String key, String message) =>
      issues.add(EnvironmentDefinitionIssue(pathOf(key), message));

  /// Adds an issue about this object as a whole.
  void reportHere(String message) =>
      issues.add(EnvironmentDefinitionIssue(path, message));

  /// Whether [key] holds a value. `null` counts as absent.
  bool has(String key) {
    _known.add(key);
    return _json[key] != null;
  }

  /// Whether [key] is present at all, even as `null`.
  bool contains(String key) {
    _known.add(key);
    return _json.containsKey(key);
  }

  /// The raw value of [key], unchecked.
  Object? raw(String key) {
    _known.add(key);
    return _json[key];
  }

  /// Marks [keys] as known without reading them.
  void allow(Iterable<String> keys) => _known.addAll(keys);

  /// Reports [key] with [message] when it is present: a field this object
  /// would otherwise ignore.
  void refuse(String key, String message) {
    _known.add(key);
    if (_json.containsKey(key)) {
      report(key, message);
    }
  }

  Object? _value(String key, {required bool required}) {
    _known.add(key);
    final value = _json[key];
    if (value == null && required) {
      report(key, 'Required');
    }
    return value;
  }

  /// A string, or null when absent or wrong.
  String? string(String key, {bool required = false, bool nonEmpty = false}) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    if (value is! String) {
      report(key, 'Must be a string');
      return null;
    }
    if (nonEmpty && value.trim().isEmpty) {
      report(key, 'Must not be empty');
      return null;
    }
    return value;
  }

  /// A real `true` or `false`; a string never counts.
  bool? boolean(String key, {bool required = false}) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    if (value is! bool) {
      report(key, 'Must be true or false');
      return null;
    }
    return value;
  }

  /// A whole number inside [min] and [max], when given.
  int? integer(String key, {bool required = false, int? min, int? max}) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    final number = wholeNumber(value);
    if (number == null) {
      report(key, 'Must be a whole number');
      return null;
    }
    final range = rangeIssue(number, min: min, max: max);
    if (range != null) {
      report(key, range);
      return null;
    }
    return number;
  }

  /// A list of strings, each checked at `<key>[i]`.
  List<String>? strings(
    String key, {
    bool required = false,
    bool nonEmpty = false,
  }) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    if (value is! List) {
      report(key, 'Must be a list of strings');
      return null;
    }
    if (nonEmpty && value.isEmpty) {
      report(key, 'Must not be empty');
      return null;
    }
    final result = <String>[];
    var ok = true;
    for (final (index, item) in value.indexed) {
      if (item is String) {
        result.add(item);
      } else {
        ok = false;
        issues.add(
          EnvironmentDefinitionIssue(
            '${pathOf(key)}[$index]',
            'Must be a string',
          ),
        );
      }
    }
    return ok ? result : null;
  }

  /// An object of string values, each checked at `<key>.<name>`.
  Map<String, String>? stringMap(String key, {bool required = false}) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    if (value is! Map) {
      report(key, 'Must be an object');
      return null;
    }
    final result = <String, String>{};
    var ok = true;
    for (final entry in value.entries) {
      final item = entry.value;
      if (item is String) {
        result['${entry.key}'] = item;
      } else {
        ok = false;
        issues.add(
          EnvironmentDefinitionIssue(
            '${pathOf(key)}.${entry.key}',
            'Must be a string',
          ),
        );
      }
    }
    return ok ? result : null;
  }

  /// A nested object, as a reader at `<key>`.
  EnvironmentJsonReader? object(String key, {bool required = false}) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    return EnvironmentJsonReader.of(value, pathOf(key), issues);
  }

  /// A plain object with string keys, unchecked inside.
  Map<String, Object?>? map(String key, {bool required = false}) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    if (value is! Map) {
      report(key, 'Must be an object');
      return null;
    }
    return {for (final entry in value.entries) '${entry.key}': entry.value};
  }

  /// A list, unchecked inside.
  List<Object?>? list(
    String key, {
    bool required = false,
    bool nonEmpty = false,
  }) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    if (value is! List) {
      report(key, 'Must be a list');
      return null;
    }
    if (nonEmpty && value.isEmpty) {
      report(key, 'Must not be empty');
      return null;
    }
    return value;
  }

  /// A list of objects, as readers at `<key>[i]`. An item that is not an
  /// object is reported and left out.
  List<EnvironmentJsonReader>? objects(
    String key, {
    bool required = false,
    bool nonEmpty = false,
  }) {
    final items = list(key, required: required, nonEmpty: nonEmpty);
    if (items == null) {
      return null;
    }
    return [
      for (final (index, item) in items.indexed)
        ?EnvironmentJsonReader.of(item, '${pathOf(key)}[$index]', issues),
    ];
  }

  /// One of [values], by wire name. A typo names every allowed value.
  T? choice<T>(String key, Map<String, T> values, {bool required = false}) {
    final value = _value(key, required: required);
    if (value == null) {
      return null;
    }
    final found = value is String ? values[value] : null;
    if (found == null) {
      report(key, choiceIssue(value, values.keys));
      return null;
    }
    return found;
  }

  /// Reports every key no accessor asked for. `$schema` is tolerated where
  /// [schema] is set: editors use it to find the JSON Schema.
  void finish({bool schema = false}) {
    for (final key in _json.keys) {
      if (_known.contains(key) || (schema && key == r'$schema')) {
        continue;
      }
      final near = closestKey(key, _known);
      report(
        key,
        near == null ? 'Unknown field' : 'Unknown field. Did you mean "$near"?',
      );
    }
  }
}

/// [value] as an int when it is a whole number, else null.
int? wholeNumber(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return null;
}

/// What is wrong with [number] for the range [min]..[max], or null.
String? rangeIssue(int number, {int? min, int? max}) {
  if ((min != null && number < min) || (max != null && number > max)) {
    if (min != null && max != null) {
      return 'Must be between $min and $max';
    }
    return min != null ? 'Must be at least $min' : 'Must be at most $max';
  }
  return null;
}

/// The issue for [value] that is none of [allowed].
String choiceIssue(Object? value, Iterable<String> allowed) {
  final list = allowed.join(', ');
  if (value is! String) {
    return 'Must be one of: $list';
  }
  final near = closestKey(value, allowed);
  return near == null
      ? 'Unknown value "$value". Use one of: $list'
      : 'Unknown value "$value". Did you mean "$near"? Use one of: $list';
}

/// The entry of [candidates] closest to [key], when it is close enough to be
/// a typo of it.
String? closestKey(String key, Iterable<String> candidates) {
  String? best;
  var bestDistance = 1 << 30;
  final lower = key.toLowerCase();
  for (final candidate in candidates) {
    final distance = _editDistance(lower, candidate.toLowerCase());
    if (distance < bestDistance) {
      best = candidate;
      bestDistance = distance;
    }
  }
  if (best == null) {
    return null;
  }
  final limit = key.length <= 4 ? 1 : 2;
  return bestDistance <= limit ? best : null;
}

int _editDistance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (index) => index);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final insert = current[j - 1] + 1;
      final delete = previous[j] + 1;
      final replace = previous[j - 1] + cost;
      current[j] = insert < delete
          ? (insert < replace ? insert : replace)
          : (delete < replace ? delete : replace);
    }
    previous = current;
  }
  return previous[b.length];
}
