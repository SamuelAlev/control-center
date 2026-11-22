import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/json_safe.dart';

/// Where a goal check runs.
enum GoalCheckLocation {
  /// A command in a one-shot sandbox over the conversation's worktree.
  worktree,

  /// A named task of the conversation's environment.
  environment,
}

/// Wire names for [GoalCheckLocation] (the contract's `in` key).
extension GoalCheckLocationWire on GoalCheckLocation {
  /// Persisted wire name.
  String get wire => switch (this) {
    GoalCheckLocation.worktree => 'worktree',
    GoalCheckLocation.environment => 'environment',
  };

  /// Every wire name.
  static List<String> get wireNames => [
    for (final value in GoalCheckLocation.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static GoalCheckLocation? tryParse(String? raw) {
    for (final value in GoalCheckLocation.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// One machine check of a goal: the server runs it when the agent claims
/// completion. Never the worker, never on the bare host.
class GoalCheck {
  /// Creates a check. Throws [ArgumentError] for an empty or over-long
  /// [run], or a timeout outside 1..[maxTimeoutSeconds].
  GoalCheck({
    required this.run,
    this.where = GoalCheckLocation.worktree,
    this.timeoutSeconds = defaultTimeoutSeconds,
  }) {
    if (run.trim().isEmpty) {
      throw ArgumentError.value(run, 'run', 'must not be empty');
    }
    if (run.length > maxRunLength) {
      throw ArgumentError.value(
        run.length,
        'run',
        'must be at most $maxRunLength characters',
      );
    }
    if (timeoutSeconds < 1 || timeoutSeconds > maxTimeoutSeconds) {
      throw ArgumentError.value(
        timeoutSeconds,
        'timeoutSeconds',
        'must be between 1 and $maxTimeoutSeconds',
      );
    }
  }

  /// The timeout a check gets when none is given, in seconds.
  static const int defaultTimeoutSeconds = 300;

  /// The longest timeout a check may have, in seconds.
  static const int maxTimeoutSeconds = 1800;

  /// The longest command (or task name) a check may have, in characters.
  static const int maxRunLength = 1000;

  /// The command (`in: worktree`) or the environment task's name
  /// (`in: environment`).
  final String run;

  /// Where it runs (the JSON key `in`).
  final GoalCheckLocation where;

  /// How long it may run before it counts as failed, in seconds.
  final int timeoutSeconds;

  /// The contract's JSON form: `{run, in, timeoutSeconds}`.
  Map<String, Object?> toJson() => {
    'run': run,
    'in': where.wire,
    'timeoutSeconds': timeoutSeconds,
  };

  /// Parses [toJson]'s output strictly. Throws [FormatException] for a
  /// missing or mistyped key and [ArgumentError] for a value out of range.
  static GoalCheck fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('a check must be an object');
    }
    final run = json['run'];
    if (run is! String) {
      throw const FormatException('a check needs a `run` string');
    }
    final where = json['in'];
    final location = where == null
        ? GoalCheckLocation.worktree
        : GoalCheckLocationWire.tryParse(where is String ? where : null);
    if (location == null) {
      throw FormatException(
        'a check `in` must be one of ${GoalCheckLocationWire.wireNames}',
      );
    }
    final rawTimeout = json['timeoutSeconds'];
    final timeout = rawTimeout == null
        ? defaultTimeoutSeconds
        : JsonSafe.intOrNull(rawTimeout);
    if (timeout == null) {
      throw const FormatException(
        'a check `timeoutSeconds` must be an integer',
      );
    }
    return GoalCheck(run: run, where: location, timeoutSeconds: timeout);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalCheck &&
          run == other.run &&
          where == other.where &&
          timeoutSeconds == other.timeoutSeconds;

  @override
  int get hashCode => Object.hash(run, where, timeoutSeconds);

  @override
  String toString() => 'GoalCheck(${toJson()})';
}

/// What "done" means for a goal, stored as data on the goal
/// (`agent_goal_runs.contract`): the success criteria, the checks the server
/// runs when the agent claims completion, the boundaries, and when to stop
/// and ask.
///
/// JSON keys exactly as the plan's section 8: `criteria`,
/// `checks: [{run, in, timeoutSeconds}]`, `boundaries`, `stopWhen`.
class GoalContract {
  /// Creates a contract. Throws [ArgumentError] past the limits: at most
  /// [maxCriteria] criteria of [maxCriterionLength] characters, at most
  /// [maxChecks] checks, and [maxTextLength] characters for [boundaries] and
  /// [stopWhen].
  GoalContract({
    List<String> criteria = const [],
    List<GoalCheck> checks = const [],
    this.boundaries,
    this.stopWhen,
  }) : criteria = List.unmodifiable(criteria),
       checks = List.unmodifiable(checks) {
    if (criteria.length > maxCriteria) {
      throw ArgumentError.value(
        criteria.length,
        'criteria',
        'at most $maxCriteria criteria',
      );
    }
    for (final criterion in criteria) {
      if (criterion.trim().isEmpty) {
        throw ArgumentError.value(criterion, 'criteria', 'must not be empty');
      }
      if (criterion.length > maxCriterionLength) {
        throw ArgumentError.value(
          criterion.length,
          'criteria',
          'each criterion is at most $maxCriterionLength characters',
        );
      }
    }
    if (checks.length > maxChecks) {
      throw ArgumentError.value(
        checks.length,
        'checks',
        'at most $maxChecks checks',
      );
    }
    _requireText(boundaries, 'boundaries');
    _requireText(stopWhen, 'stopWhen');
  }

  /// The most criteria a contract may have.
  static const int maxCriteria = 12;

  /// The longest criterion, in characters.
  static const int maxCriterionLength = 300;

  /// The most checks a contract may have.
  static const int maxChecks = 5;

  /// The longest [boundaries] or [stopWhen] text, in characters.
  static const int maxTextLength = 1000;

  /// The "Done means" items, in order.
  final List<String> criteria;

  /// The checks the server runs on a completion claim, in order.
  final List<GoalCheck> checks;

  /// What the agent must not touch or do, when stated.
  final String? boundaries;

  /// When the agent must stop and ask a person, when stated.
  final String? stopWhen;

  /// Whether the contract has no machine check (its card says so).
  bool get hasNoChecks => checks.isEmpty;

  /// The stored JSON object. Unset text is omitted.
  Map<String, Object?> toJson() => {
    'criteria': criteria,
    'checks': [for (final check in checks) check.toJson()],
    'boundaries': ?boundaries,
    'stopWhen': ?stopWhen,
  };

  /// [toJson] encoded, as the column stores it.
  String encode() => jsonEncode(toJson());

  /// Parses a contract strictly (from a person's dialog or an operation).
  /// Throws [FormatException] for a mistyped key and [ArgumentError] past a
  /// limit.
  static GoalContract fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('a goal contract must be an object');
    }
    final criteria = json['criteria'] ?? const <Object?>[];
    final checks = json['checks'] ?? const <Object?>[];
    if (criteria is! List || criteria.any((c) => c is! String)) {
      throw const FormatException('`criteria` must be a list of strings');
    }
    if (checks is! List) {
      throw const FormatException('`checks` must be a list');
    }
    final boundaries = json['boundaries'];
    final stopWhen = json['stopWhen'];
    if (boundaries != null && boundaries is! String) {
      throw const FormatException('`boundaries` must be a string');
    }
    if (stopWhen != null && stopWhen is! String) {
      throw const FormatException('`stopWhen` must be a string');
    }
    return GoalContract(
      criteria: criteria.cast<String>(),
      checks: [for (final check in checks) GoalCheck.fromJson(check)],
      boundaries: _blankToNull(boundaries as String?),
      stopWhen: _blankToNull(stopWhen as String?),
    );
  }

  /// Decodes the stored column. Null, empty, malformed or out-of-limit
  /// values read as null (no contract); it never throws.
  static GoalContract? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return tryFromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// [fromJson], but null for anything it would refuse (a wire value from a
  /// newer or older peer); it never throws.
  static GoalContract? tryFromJson(Object? json) {
    if (json == null) {
      return null;
    }
    try {
      return fromJson(json);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  /// A copy with the given fields replaced.
  GoalContract copyWith({
    List<String>? criteria,
    List<GoalCheck>? checks,
    String? boundaries,
    bool removeBoundaries = false,
    String? stopWhen,
    bool removeStopWhen = false,
  }) => GoalContract(
    criteria: criteria ?? this.criteria,
    checks: checks ?? this.checks,
    boundaries: removeBoundaries ? null : (boundaries ?? this.boundaries),
    stopWhen: removeStopWhen ? null : (stopWhen ?? this.stopWhen),
  );

  static String? _blankToNull(String? text) =>
      text == null || text.trim().isEmpty ? null : text;

  static void _requireText(String? text, String name) {
    if (text != null && text.length > maxTextLength) {
      throw ArgumentError.value(
        text.length,
        name,
        'must be at most $maxTextLength characters',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalContract &&
          JsonSafe.equals(criteria, other.criteria) &&
          JsonSafe.equals(checks, other.checks) &&
          boundaries == other.boundaries &&
          stopWhen == other.stopWhen;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(criteria),
    Object.hashAll(checks),
    boundaries,
    stopWhen,
  );

  @override
  String toString() => 'GoalContract(${toJson()})';
}
