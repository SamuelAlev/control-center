import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_goal_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';

/// What one arm's attempts did: counts and means, never a verdict.
///
/// A campaign's paired verdict decides adoption, and with few distinct
/// tasks its bound cannot conclude; these numbers say what happened anyway.
class EvaluationDescriptiveArm {
  /// Creates the summary of [armId] over [attempts] (that arm's only).
  EvaluationDescriptiveArm(this.armId, List<EvaluationAttempt> attempts)
    : attempts = attempts.length,
      completions = attempts.where((a) => a.completed).length,
      agentStopped = attempts
          .where((a) => a.end == EvaluationAttemptEnd.agentStopped)
          .length,
      harnessFaults = attempts
          .where((a) => a.end == EvaluationAttemptEnd.harnessFault)
          .length,
      ceilingStopped = attempts
          .where((a) => a.end == EvaluationAttemptEnd.ceilingStopped)
          .length,
      verifiedSuccesses = attempts.where((a) => a.verifiedSuccess).length,
      falseCompletions = attempts
          .where((a) => a.completed && a.verificationFailed)
          .length,
      totalCostMicros = attempts.any((a) => a.attemptCostMicros == null)
          ? null
          : attempts.fold<int>(0, (sum, a) => sum + a.attemptCostMicros!),
      meanTurns = _mean(attempts.map((a) => a.metrics.userTurns)),
      meanRoundTrips = _mean(attempts.map((a) => a.metrics.modelRoundTrips)),
      goals = [
        for (final attempt in attempts)
          if (attempt.goal != null) attempt.goal!,
      ];

  /// The arm.
  final String armId;

  /// Attempts recorded.
  final int attempts;

  /// Attempts that ended as done (for a goal: the arm accepted a claim).
  final int completions;

  /// Attempts the agent gave up on (scored as failures).
  final int agentStopped;

  /// Attempts the harness faulted on (missing data).
  final int harnessFaults;

  /// Attempts the spend ceiling cut (missing data).
  final int ceilingStopped;

  /// Completions whose authoritative checks all passed.
  final int verifiedSuccesses;

  /// Completions with an authoritative check that ran and failed.
  final int falseCompletions;

  /// Every attempt's cost; null when any attempt was unpriced.
  final int? totalCostMicros;

  /// Mean user turns per attempt (for a goal: worker segments).
  final double meanTurns;

  /// Mean model round trips per attempt (a goal's reviews included).
  final double meanRoundTrips;

  /// The goal outcomes of the arm's goal attempts.
  final List<EvaluationGoalOutcome> goals;

  /// Verified successes over attempts.
  double get verifiedRate => attempts == 0 ? 0 : verifiedSuccesses / attempts;

  /// False completions over completions; null without a completion.
  double? get falseCompletionRate =>
      completions == 0 ? null : falseCompletions / completions;

  /// False completions over attempts (the goal-verification campaign's
  /// outcome: its arms complete at different rates, so the per-completion
  /// rate alone compares different denominators); null without an attempt.
  double? get falseCompletionsPerAttempt =>
      attempts == 0 ? null : falseCompletions / attempts;

  /// Mean cost per attempt; null when unpriced or empty.
  double? get meanCostMicros => totalCostMicros == null || attempts == 0
      ? null
      : totalCostMicros! / attempts;

  /// Goal attempts in which the agent claimed.
  int get goalsClaimed => goals.where((g) => g.claimed).length;

  /// Goal attempts whose arm accepted a claim.
  int get goalsAccepted => goals.where((g) => g.accepted).length;

  /// Goal attempts the product's verification passed.
  int get goalsVerified => goals
      .where((g) => g.verification == GoalVerificationResult.passed)
      .length;

  /// Goal attempts whose verification stopped for a person.
  int get goalsStopped => goals
      .where(
        (g) =>
            g.verification != GoalVerificationResult.notRun &&
            g.verification != GoalVerificationResult.passed,
      )
      .length;

  /// Mean failed verification rounds per goal attempt.
  double get meanFailedRounds => _mean(goals.map((g) => g.rounds));

  /// One summary per arm in [armOrder] (arms with no attempt included), then
  /// any arm [attempts] name that [armOrder] does not.
  static List<EvaluationDescriptiveArm> of(
    List<EvaluationAttempt> attempts, {
    required List<String> armOrder,
  }) {
    final order = [
      ...armOrder,
      for (final attempt in attempts)
        if (!armOrder.contains(attempt.armId)) attempt.armId,
    ];
    return [
      for (final arm in {...order})
        EvaluationDescriptiveArm(arm, [
          for (final attempt in attempts)
            if (attempt.armId == arm) attempt,
        ]),
    ];
  }

  static double _mean(Iterable<int> values) {
    final list = values.toList();
    return list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;
  }
}
