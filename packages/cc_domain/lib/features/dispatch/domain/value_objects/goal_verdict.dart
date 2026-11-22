import 'package:cc_domain/features/dispatch/domain/value_objects/json_safe.dart';

/// The reviewer's overall answer on a goal's completion claim.
enum GoalVerdictOutcome {
  /// Every criterion is met: the goal completes.
  pass,

  /// Something is unmet: the agent gets another round.
  fail,

  /// The reviewer could not tell: a person decides.
  cannotVerify,
}

/// Wire names for [GoalVerdictOutcome].
extension GoalVerdictOutcomeWire on GoalVerdictOutcome {
  /// Wire name.
  String get wire => switch (this) {
    GoalVerdictOutcome.pass => 'pass',
    GoalVerdictOutcome.fail => 'fail',
    GoalVerdictOutcome.cannotVerify => 'cannot_verify',
  };

  /// Every wire name.
  static List<String> get wireNames => [
    for (final value in GoalVerdictOutcome.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static GoalVerdictOutcome? tryParse(String? raw) {
    for (final value in GoalVerdictOutcome.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// The reviewer's finding on one "Done means" item.
enum GoalCriterionState {
  /// The criterion holds.
  met,

  /// The criterion does not hold.
  unmet,

  /// The reviewer could not decide.
  cannotTell,
}

/// Wire names for [GoalCriterionState].
extension GoalCriterionStateWire on GoalCriterionState {
  /// Wire name.
  String get wire => switch (this) {
    GoalCriterionState.met => 'met',
    GoalCriterionState.unmet => 'unmet',
    GoalCriterionState.cannotTell => 'cannot_tell',
  };

  /// Every wire name.
  static List<String> get wireNames => [
    for (final value in GoalCriterionState.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static GoalCriterionState? tryParse(String? raw) {
    for (final value in GoalCriterionState.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// One item of a verdict: a criterion, the finding, and what the reviewer
/// looked at.
class GoalVerdictItem {
  /// Creates an item. Throws [ArgumentError] for an empty or over-long
  /// criterion, or over-long evidence.
  GoalVerdictItem({
    required this.criterion,
    required this.state,
    this.evidence = '',
  }) {
    if (criterion.trim().isEmpty) {
      throw ArgumentError.value(criterion, 'criterion', 'must not be empty');
    }
    if (criterion.length > maxCriterionLength) {
      throw ArgumentError.value(
        criterion.length,
        'criterion',
        'must be at most $maxCriterionLength characters',
      );
    }
    if (evidence.length > maxEvidenceLength) {
      throw ArgumentError.value(
        evidence.length,
        'evidence',
        'must be at most $maxEvidenceLength characters',
      );
    }
  }

  /// The longest criterion text, in characters.
  static const int maxCriterionLength = 300;

  /// The longest evidence text, in characters.
  static const int maxEvidenceLength = 2000;

  /// The "Done means" item judged.
  final String criterion;

  /// The finding.
  final GoalCriterionState state;

  /// What the reviewer looked at.
  final String evidence;

  /// JSON form: `{criterion, state, evidence}`.
  Map<String, Object?> toJson() => {
    'criterion': criterion,
    'state': state.wire,
    'evidence': evidence,
  };

  /// Parses strictly. Throws [FormatException] or [ArgumentError].
  static GoalVerdictItem fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('a verdict item must be an object');
    }
    final criterion = json['criterion'];
    final state = GoalCriterionStateWire.tryParse(
      json['state'] is String ? json['state'] as String : null,
    );
    final evidence = json['evidence'] ?? '';
    if (criterion is! String || state == null || evidence is! String) {
      throw FormatException(
        'a verdict item needs `criterion`, `state` '
        '(${GoalCriterionStateWire.wireNames.join(', ')}) and `evidence`',
      );
    }
    return GoalVerdictItem(
      criterion: criterion,
      state: state,
      evidence: evidence,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalVerdictItem &&
          criterion == other.criterion &&
          state == other.state &&
          evidence == other.evidence;

  @override
  int get hashCode => Object.hash(criterion, state, evidence);
}

/// The independent reviewer's structured verdict on a completion claim, as
/// it answers through `submit_output`:
/// `{verdict: pass | fail | cannot_verify, items: [{criterion, state,
/// evidence}], concerns}`.
class GoalVerdict {
  /// Creates a verdict. Throws [ArgumentError] past the limits.
  GoalVerdict({
    required this.verdict,
    List<GoalVerdictItem> items = const [],
    List<String> concerns = const [],
  }) : items = List.unmodifiable(items),
       concerns = List.unmodifiable(concerns) {
    if (items.length > maxItems) {
      throw ArgumentError.value(items.length, 'items', 'at most $maxItems');
    }
    if (concerns.length > maxConcerns) {
      throw ArgumentError.value(
        concerns.length,
        'concerns',
        'at most $maxConcerns',
      );
    }
    for (final concern in concerns) {
      if (concern.length > maxConcernLength) {
        throw ArgumentError.value(
          concern.length,
          'concerns',
          'each concern is at most $maxConcernLength characters',
        );
      }
    }
  }

  /// The most items a verdict may carry (one per criterion, with room).
  static const int maxItems = 24;

  /// The most concerns a verdict may carry.
  static const int maxConcerns = 10;

  /// The longest concern, in characters.
  static const int maxConcernLength = 1000;

  /// The `submit_output` schema the reviewer's run is dispatched with.
  static const Map<String, Object?> outputSchema = {
    'type': 'object',
    'required': ['verdict', 'items'],
    'properties': {
      'verdict': {
        'type': 'string',
        'enum': ['pass', 'fail', 'cannot_verify'],
      },
      'items': {
        'type': 'array',
        'maxItems': maxItems,
        'items': {
          'type': 'object',
          'required': ['criterion', 'state', 'evidence'],
          'properties': {
            'criterion': {'type': 'string'},
            'state': {
              'type': 'string',
              'enum': ['met', 'unmet', 'cannot_tell'],
            },
            'evidence': {'type': 'string'},
          },
        },
      },
      'concerns': {
        'type': 'array',
        'maxItems': maxConcerns,
        'items': {'type': 'string'},
      },
    },
  };

  /// The overall answer.
  final GoalVerdictOutcome verdict;

  /// The per-criterion findings.
  final List<GoalVerdictItem> items;

  /// Anything else the reviewer flagged (weakened tests, out-of-bounds
  /// changes).
  final List<String> concerns;

  /// The items the reviewer found unmet.
  List<GoalVerdictItem> get unmet => [
    for (final item in items)
      if (item.state == GoalCriterionState.unmet) item,
  ];

  /// JSON form.
  Map<String, Object?> toJson() => {
    'verdict': verdict.wire,
    'items': [for (final item in items) item.toJson()],
    'concerns': concerns,
  };

  /// Parses strictly (the reviewer's `submit_output`). Throws
  /// [FormatException] or [ArgumentError].
  static GoalVerdict fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('a verdict must be an object');
    }
    final verdict = GoalVerdictOutcomeWire.tryParse(
      json['verdict'] is String ? json['verdict'] as String : null,
    );
    if (verdict == null) {
      throw FormatException(
        '`verdict` must be one of ${GoalVerdictOutcomeWire.wireNames}',
      );
    }
    final items = json['items'] ?? const <Object?>[];
    final concerns = json['concerns'] ?? const <Object?>[];
    if (items is! List) {
      throw const FormatException('`items` must be a list');
    }
    if (concerns is! List || concerns.any((c) => c is! String)) {
      throw const FormatException('`concerns` must be a list of strings');
    }
    return GoalVerdict(
      verdict: verdict,
      items: [for (final item in items) GoalVerdictItem.fromJson(item)],
      concerns: concerns.cast<String>(),
    );
  }

  /// Like [fromJson], but null instead of throwing.
  static GoalVerdict? tryFromJson(Object? json) {
    try {
      return fromJson(json);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalVerdict &&
          verdict == other.verdict &&
          JsonSafe.equals(items, other.items) &&
          JsonSafe.equals(concerns, other.concerns);

  @override
  int get hashCode =>
      Object.hash(verdict, Object.hashAll(items), Object.hashAll(concerns));

  @override
  String toString() => 'GoalVerdict(${toJson()})';
}
