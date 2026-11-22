import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';

/// The question a plan asks of each treatment arm, declared before the run.
enum EvaluationHypothesis {
  /// Is the treatment better? H0: the task-mean difference is at most 0.
  superiority('superiority'),

  /// Is the treatment no worse than the margin? H0: the difference is at most
  /// −margin. For an arm whose case is a saving.
  nonInferiority('non_inferiority'),

  /// A screen for a small corpus (a skill change): no claim of quality, only
  /// whether a loss shows. A unanimous loss reads inferior on the exact
  /// sign-flip p alone; the observed difference is what a person judges by.
  regressionScreen('regression_screen'),

  /// One arm, no comparison: the report prints pass rates, prices and how
  /// attempts ended per task, and no verdict.
  calibration('calibration');

  const EvaluationHypothesis(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string; throws [FormatException] for an unknown or absent
  /// one, because a plan that does not say what it asks cannot be judged.
  static EvaluationHypothesis fromWire(String? raw) => values.firstWhere(
    (value) => value.wire == raw,
    orElse: () => throw FormatException(
      'unknown plan hypothesis "$raw" (superiority | non_inferiority | '
      'regression_screen | calibration)',
    ),
  );
}

/// What an attempt is scored on.
enum EvaluationOutcomeMeasure {
  /// 1 when the attempt finished and every authoritative check passed.
  /// Higher is better.
  verifiedSuccess('verified_success'),

  /// 1 when the attempt finished (or its goal claim was accepted) and an
  /// authoritative check ran and failed. Lower is better.
  falseCompletion('false_completion');

  const EvaluationOutcomeMeasure(this.wire);

  /// Stable wire string.
  final String wire;

  /// Whether a lower score is the better one.
  bool get lowerIsBetter => this == falseCompletion;

  /// Parses a wire string; throws [FormatException] for an unknown or absent
  /// one.
  static EvaluationOutcomeMeasure fromWire(String? raw) => values.firstWhere(
    (value) => value.wire == raw,
    orElse: () => throw FormatException(
      'unknown primary outcome "$raw" (verified_success | false_completion)',
    ),
  );
}

/// How an attempt ended, which decides whether it is evidence.
enum EvaluationAttemptEnd {
  /// The loop completed, or the goal arm accepted a claim: scored on its
  /// checks.
  finished('finished'),

  /// The agent gave up: it ran out of turns or budget, left a contract
  /// unmet, hit the tool-call ceiling, or its goal claim was not accepted.
  /// Scored as a failure, never dropped.
  agentStopped('agent_stopped'),

  /// The harness failed (an exception, a provider error, lost output, a
  /// per-call price breach, a cancellation): missing data.
  harnessFault('harness_fault'),

  /// The campaign's spend ceiling was reached inside the attempt: missing
  /// data, and not a sign of an unreliable harness.
  ceilingStopped('ceiling_stopped');

  const EvaluationAttemptEnd(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string; throws [FormatException] for an unknown or absent
  /// one (an attempt that does not say how it ended cannot be scored).
  static EvaluationAttemptEnd fromWire(String? raw) => values.firstWhere(
    (value) => value.wire == raw,
    orElse: () => throw FormatException('unknown attempt end "$raw"'),
  );
}

/// Thrown by a backend that refuses to start an attempt because the
/// campaign's spend ceiling is reached: the engine records the attempt as
/// `ceiling_stopped` (missing data), not as a harness fault.
class EvaluationCeilingReached implements Exception {
  /// Creates an [EvaluationCeilingReached] with [message].
  const EvaluationCeilingReached(this.message);

  /// What was reached.
  final String message;

  @override
  String toString() => message;
}

/// An attempt's score on a plan's primary outcome.
extension EvaluationAttemptScore on EvaluationAttempt {
  /// 1 or 0 on [measure], or null when the attempt is missing data: a
  /// harness fault, a ceiling stop, a contradicted pin, or a finished
  /// attempt whose declared checks did not all run. An agent that stopped
  /// scores 0 on either measure (a failure, and no false completion).
  int? score(EvaluationOutcomeMeasure measure) {
    if (end == EvaluationAttemptEnd.harnessFault ||
        end == EvaluationAttemptEnd.ceilingStopped ||
        identityMismatches.isNotEmpty) {
      return null;
    }
    if (end == EvaluationAttemptEnd.agentStopped) {
      return 0;
    }
    if (!verificationComplete || proving.isEmpty) {
      return null;
    }
    return switch (measure) {
      EvaluationOutcomeMeasure.verifiedSuccess => verifiedSuccess ? 1 : 0,
      EvaluationOutcomeMeasure.falseCompletion => verificationFailed ? 1 : 0,
    };
  }
}
