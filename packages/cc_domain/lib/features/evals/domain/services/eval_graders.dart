import 'package:cc_domain/features/evals/domain/value_objects/eval_outcome.dart';

/// The kind of grader, in the precedence the harness Verifier port uses:
/// deterministic → judge → human (PRD 21 §5, PRD 26 Verifier alignment).
enum GraderKind {
  /// A checkable, token-free outcome grader (preferred).
  deterministic('deterministic'),

  /// An LLM-rubric judge (only where outcomes aren't checkable).
  judge('judge'),

  /// A human verdict (out-of-band; recorded, never auto).
  human('human');

  const GraderKind(this.wire);

  /// Stable wire string.
  final String wire;
}

/// The result of grading one [EvalOutcome].
class GradeResult {
  /// Creates a [GradeResult].
  const GradeResult({
    required this.graderId,
    required this.passed,
    required this.score,
    this.detail = '',
  });

  /// The grader that produced this result.
  final String graderId;

  /// Whether the grade is a pass.
  final bool passed;

  /// A normalized score in `[0, 1]`.
  final double score;

  /// Human-readable detail (why it passed/failed).
  final String detail;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'graderId': graderId,
    'passed': passed,
    'score': score,
    'detail': detail,
  };
}

/// A deterministic grader over an [EvalOutcome] (PRD 21 §5).
///
/// Deterministic graders are always preferred (free, exact). The eval runner
/// runs every configured grader over each repetition's outcome.
abstract interface class EvalGrader {
  /// Stable grader id (unique within a suite).
  String get id;

  /// Grader kind (drives precedence + whether it costs tokens).
  GraderKind get kind;

  /// Grades an outcome. Pure and synchronous for deterministic graders.
  GradeResult grade(EvalOutcome outcome);
}

/// Passes when the run reached a clean terminal state.
class OutcomeSuccessGrader implements EvalGrader {
  /// Creates an [OutcomeSuccessGrader].
  const OutcomeSuccessGrader({this.id = 'outcome_success'});

  @override
  final String id;

  @override
  GraderKind get kind => GraderKind.deterministic;

  @override
  GradeResult grade(EvalOutcome outcome) => GradeResult(
    graderId: id,
    passed: outcome.completed,
    score: outcome.completed ? 1 : 0,
    detail: outcome.completed
        ? 'Run completed.'
        : 'Run failed: ${outcome.error ?? "unknown"}.',
  );
}

/// Passes when metered cost is within a cent budget.
class CostBudgetGrader implements EvalGrader {
  /// Creates a [CostBudgetGrader].
  const CostBudgetGrader(this.maxCents, {this.id = 'cost_budget'});

  @override
  final String id;

  /// The inclusive cost ceiling in cents.
  final int maxCents;

  @override
  GraderKind get kind => GraderKind.deterministic;

  @override
  GradeResult grade(EvalOutcome outcome) {
    final passed = outcome.costCents <= maxCents;
    return GradeResult(
      graderId: id,
      passed: passed,
      score: passed ? 1 : 0,
      detail: 'Cost ${outcome.costCents}¢ ${passed ? "≤" : ">"} $maxCents¢.',
    );
  }
}

/// Passes when there were no sandbox-policy violations.
class NoSandboxViolationsGrader implements EvalGrader {
  /// Creates a [NoSandboxViolationsGrader].
  const NoSandboxViolationsGrader({this.id = 'no_sandbox_violations'});

  @override
  final String id;

  @override
  GraderKind get kind => GraderKind.deterministic;

  @override
  GradeResult grade(EvalOutcome outcome) {
    final passed = outcome.sandboxViolations == 0;
    return GradeResult(
      graderId: id,
      passed: passed,
      score: passed ? 1 : 0,
      detail: passed
          ? 'No sandbox violations.'
          : '${outcome.sandboxViolations} sandbox violation(s).',
    );
  }
}

/// Passes when the run stayed within a turn ceiling.
class MaxTurnsGrader implements EvalGrader {
  /// Creates a [MaxTurnsGrader].
  const MaxTurnsGrader(this.maxTurns, {this.id = 'max_turns'});

  @override
  final String id;

  /// The inclusive turn ceiling.
  final int maxTurns;

  @override
  GraderKind get kind => GraderKind.deterministic;

  @override
  GradeResult grade(EvalOutcome outcome) {
    final passed = outcome.turnCount <= maxTurns;
    return GradeResult(
      graderId: id,
      passed: passed,
      score: passed ? 1 : 0,
      detail: '${outcome.turnCount} turn(s) ${passed ? "≤" : ">"} $maxTurns.',
    );
  }
}

/// Passes when a named boolean signal the runner computed is true. Covers the
/// checkable deterministic graders — `testsPassed`, `planValid`, `diffApplied`,
/// `lintsClean` — without the domain needing to run those tools itself.
class SignalTrueGrader implements EvalGrader {
  /// Creates a [SignalTrueGrader].
  const SignalTrueGrader(this.signalKey, {required this.id, this.label});

  @override
  final String id;

  /// The [EvalOutcome.signals] key that must be `true`.
  final String signalKey;

  /// Human-readable label for the detail line.
  final String? label;

  @override
  GraderKind get kind => GraderKind.deterministic;

  @override
  GradeResult grade(EvalOutcome outcome) {
    final passed = outcome.signalBool(signalKey);
    final name = label ?? signalKey;
    return GradeResult(
      graderId: id,
      passed: passed,
      score: passed ? 1 : 0,
      detail: passed ? '$name ✓' : '$name ✗',
    );
  }
}

/// A declarative, serializable grader definition stored in an eval suite. The
/// runner materializes it into an [EvalGrader]. Judge graders carry a rubric
/// and are built by the runtime (which has an LLM), so [build] returns null for
/// non-deterministic kinds — the runner handles those separately.
class GraderSpec {
  /// Creates a [GraderSpec].
  const GraderSpec({
    required this.type,
    required this.id,
    this.params = const {},
    this.kind = GraderKind.deterministic,
    this.rubric,
  });

  /// Parses from JSON.
  factory GraderSpec.fromJson(Map<String, dynamic> json) => GraderSpec(
    type: json['type'] as String? ?? 'outcome_success',
    id: json['id'] as String? ?? (json['type'] as String? ?? 'grader'),
    params: (json['params'] as Map?)?.cast<String, dynamic>() ?? const {},
    kind: GraderKind.values.firstWhere(
      (k) => k.wire == (json['kind'] as String? ?? 'deterministic'),
      orElse: () => GraderKind.deterministic,
    ),
    rubric: json['rubric'] as String?,
  );

  /// Grader type discriminator (`outcome_success`/`cost_budget`/
  /// `no_sandbox_violations`/`max_turns`/`signal`/`judge`).
  final String type;

  /// Unique grader id within the suite.
  final String id;

  /// Type-specific params (e.g. `maxCents`, `maxTurns`, `signalKey`).
  final Map<String, dynamic> params;

  /// Grader kind.
  final GraderKind kind;

  /// The rubric text for a judge grader.
  final String? rubric;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'kind': kind.wire,
    if (params.isNotEmpty) 'params': params,
    if (rubric != null) 'rubric': rubric,
  };

  /// Materializes a deterministic [EvalGrader], or null for judge/human kinds
  /// (which the runtime handles with an LLM / out-of-band).
  EvalGrader? build() {
    if (kind != GraderKind.deterministic) {
      return null;
    }
    switch (type) {
      case 'cost_budget':
        return CostBudgetGrader(
          (params['maxCents'] as num?)?.toInt() ?? 100,
          id: id,
        );
      case 'no_sandbox_violations':
        return NoSandboxViolationsGrader(id: id);
      case 'max_turns':
        return MaxTurnsGrader(
          (params['maxTurns'] as num?)?.toInt() ?? 20,
          id: id,
        );
      case 'signal':
        return SignalTrueGrader(
          params['signalKey'] as String? ?? 'ok',
          id: id,
          label: params['label'] as String?,
        );
      case 'outcome_success':
      default:
        return OutcomeSuccessGrader(id: id);
    }
  }
}
