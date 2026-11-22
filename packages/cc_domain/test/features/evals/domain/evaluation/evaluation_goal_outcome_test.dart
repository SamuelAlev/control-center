import 'package:cc_domain/features/evals/domain/evaluation/evaluation_arm_settings.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_descriptive_summary.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_goal_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:test/test.dart';

EvaluationAttempt attempt(
  String arm, {
  required bool completed,
  required bool hiddenPassed,
  int? costMicros = 1000,
  EvaluationGoalOutcome? goal,
}) => EvaluationAttempt(
  attemptId: '$arm-${goal.hashCode}-$completed-$hiddenPassed',
  taskId: 't',
  taskKind: EvaluationTaskKind.bugfix,
  armId: arm,
  effective: const EvaluationEffectiveConfig(
    adapter: 'builtin',
    providerId: 'p',
    modelId: 'm',
    goalVerification: GoalVerificationMode.checksReview,
  ),
  stratum: CacheStratum.cold,
  repetition: 0,
  seed: 1,
  ordinal: 0,
  startedAtEpochMs: 0,
  // Not completed = the goal arm accepted no claim: the agent stopped.
  end: completed
      ? EvaluationAttemptEnd.finished
      : EvaluationAttemptEnd.agentStopped,
  cost: EvaluationCostRoles(estimatedApiMicros: costMicros),
  metrics: const EvaluationAttemptMetrics(userTurns: 2, modelRoundTrips: 5),
  verification: [
    EvaluationVerificationResult(verifierId: 'hidden', passed: hiddenPassed),
  ],
  expectedAuthoritativeChecks: 1,
  goal: goal,
);

void main() {
  test('a goal outcome refuses an acceptance with no claim', () {
    expect(
      () => EvaluationGoalOutcome(
        claims: 0,
        accepted: true,
        verification: GoalVerificationResult.notRun,
        rounds: 0,
        segments: 1,
      ),
      throwsArgumentError,
    );
  });

  test('the goal outcome and the effective goal setting survive attempt '
      'JSON', () {
    final goal = EvaluationGoalOutcome(
      claims: 3,
      accepted: false,
      verification: GoalVerificationResult.failedRounds,
      rounds: 3,
      segments: 3,
      holdDetail: 'verification_failed',
    );
    final original = attempt(
      'checks-review',
      completed: false,
      hiddenPassed: false,
      goal: goal,
    );
    final parsed = EvaluationAttempt.fromJson(original.toJson());
    expect(parsed.goal, goal);
    expect(
      parsed.effective.goalVerification,
      GoalVerificationMode.checksReview,
    );
    expect(parsed, original);
  });

  test('descriptive numbers count false completions per arm', () {
    EvaluationGoalOutcome claimed({required bool accepted}) =>
        EvaluationGoalOutcome(
          claims: 1,
          accepted: accepted,
          verification: accepted
              ? GoalVerificationResult.passed
              : GoalVerificationResult.cannotVerify,
          rounds: accepted ? 0 : 1,
          segments: 1,
        );
    final arms = EvaluationDescriptiveArm.of(
      [
        attempt('claim-only', completed: true, hiddenPassed: false),
        attempt('claim-only', completed: true, hiddenPassed: true),
        attempt(
          'checks-review',
          completed: true,
          hiddenPassed: true,
          goal: claimed(accepted: true),
        ),
        attempt(
          'checks-review',
          completed: false,
          hiddenPassed: false,
          costMicros: null,
          goal: claimed(accepted: false),
        ),
      ],
      armOrder: const ['claim-only', 'checks-review', 'unused'],
    );
    expect(arms.map((a) => a.armId), ['claim-only', 'checks-review', 'unused']);
    final claimOnly = arms[0];
    expect(claimOnly.completions, 2);
    expect(claimOnly.falseCompletions, 1);
    expect(claimOnly.falseCompletionRate, 0.5);
    expect(claimOnly.falseCompletionsPerAttempt, 0.5);
    expect(claimOnly.verifiedRate, 0.5);
    expect(claimOnly.totalCostMicros, 2000);
    expect(claimOnly.meanTurns, 2);
    final checked = arms[1];
    expect(checked.falseCompletions, 0);
    expect(checked.falseCompletionRate, 0);
    expect(checked.falseCompletionsPerAttempt, 0);
    expect(checked.agentStopped, 1);
    expect(checked.harnessFaults, 0);
    expect(checked.totalCostMicros, isNull, reason: 'one attempt unpriced');
    expect(checked.goalsClaimed, 2);
    expect(checked.goalsAccepted, 1);
    expect(checked.goalsVerified, 1);
    expect(checked.goalsStopped, 1);
    expect(checked.meanFailedRounds, 0.5);
    expect(arms[2].attempts, 0);
    expect(arms[2].falseCompletionRate, isNull);
    expect(arms[2].falseCompletionsPerAttempt, isNull);
  });
}
