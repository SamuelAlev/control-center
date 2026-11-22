import 'dart:convert';

/// The commit each checkout of a goal's conversation was at when the goal
/// started (`agent_goal_runs.start_ref`), keyed by the checkout's directory
/// name under the space's `repos/`. "What changed since the goal started"
/// diffs each checkout against its entry here, never against a date.
///
/// A checkout that had no commit yet maps to [noCommit] (its base is git's
/// empty tree). A checkout missing from the map appeared after the start.
final class GoalStartRefs {
  /// Creates the refs; throws [ArgumentError] on a malformed entry.
  GoalStartRefs(Map<String, String> refs)
    : refs = Map.unmodifiable(Map.of(refs)) {
    if (refs.length > maxCheckouts) {
      throw ArgumentError('at most $maxCheckouts checkouts');
    }
    for (final MapEntry(:key, :value) in refs.entries) {
      if (key.isEmpty ||
          key.length > maxNameLength ||
          key.contains('/') ||
          key.contains(r'\') ||
          key == '.' ||
          key == '..') {
        throw ArgumentError('not a checkout name: "$key"');
      }
      if (value != noCommit && !_commit.hasMatch(value)) {
        throw ArgumentError('not a commit id for "$key": "$value"');
      }
    }
  }

  /// The entry of a checkout that had no commit when the goal started.
  static const String noCommit = '';

  /// The most checkouts recorded.
  static const int maxCheckouts = 256;

  /// The longest checkout name.
  static const int maxNameLength = 255;

  /// A full SHA-1 or SHA-256 commit id, lower case.
  static final RegExp _commit = RegExp(r'^[0-9a-f]{40}(?:[0-9a-f]{24})?$');

  /// Checkout name to its commit at the start ([noCommit] for none).
  final Map<String, String> refs;

  /// [kept] with each checkout of [now] it has no entry for added (a
  /// checkout that appeared after the start, recorded as it first shows);
  /// [kept]'s entries never change. Null when both are null.
  static GoalStartRefs? merged(GoalStartRefs? kept, GoalStartRefs? now) {
    if (now == null) {
      return kept;
    }
    if (kept == null) {
      return now;
    }
    final refs = Map.of(kept.refs);
    for (final MapEntry(:key, :value) in now.refs.entries) {
      if (refs.length >= maxCheckouts) {
        break;
      }
      refs.putIfAbsent(key, () => value);
    }
    return refs.length == kept.refs.length ? kept : GoalStartRefs(refs);
  }

  /// The JSON object form.
  Map<String, String> toJson() => Map.of(refs);

  /// The stored text form (a JSON object).
  String encode() => jsonEncode(refs);

  /// Reads the JSON object form; null when [json] is not a valid one.
  static GoalStartRefs? tryFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final refs = <String, String>{};
    for (final MapEntry(:key, :value) in json.entries) {
      if (key is! String || value is! String) {
        return null;
      }
      refs[key] = value;
    }
    try {
      return GoalStartRefs(refs);
    } on ArgumentError {
      return null;
    }
  }

  /// Reads the stored text form; null when absent or malformed.
  static GoalStartRefs? tryParse(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    try {
      return tryFromJson(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalStartRefs &&
          other.refs.length == refs.length &&
          refs.entries.every((e) => other.refs[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered([
    for (final e in refs.entries) Object.hash(e.key, e.value),
  ]);

  @override
  String toString() => 'GoalStartRefs($refs)';
}
