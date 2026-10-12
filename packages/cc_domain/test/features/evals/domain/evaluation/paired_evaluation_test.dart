import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_report_renderer.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:test/test.dart';

const _effective = EvaluationEffectiveConfig(
  adapter: 'builtin',
  providerId: 'anthropic',
  modelId: 'm',
);

const _manifest = EvaluationManifest(
  corpusId: 'c',
  corpusHash: 'h',
  adapter: 'builtin',
  providerId: 'anthropic',
  modelId: 'm',
);

/// One attempt with a single DECLARED authoritative check, priced in micro-USD.
EvaluationAttempt attempt({
  required String taskId,
  required String armId,
  required bool success,
  required int micros,
  int repetition = 0,
  CacheStratum stratum = CacheStratum.cold,
  bool completed = true,
  int checks = 1,
}) => EvaluationAttempt(
  attemptId: '$taskId-$armId-${stratum.wire}-$repetition',
  taskId: taskId,
  taskKind: EvaluationTaskKind.bugfix,
  armId: armId,
  effective: _effective,
  stratum: stratum,
  repetition: repetition,
  seed: 1,
  startedAtEpochMs: 0,
  completed: completed,
  cost: EvaluationCostRoles(estimatedApiMicros: micros),
  expectedAuthoritativeChecks: checks,
  verification: [
    for (var i = 0; i < checks; i++)
      EvaluationVerificationResult(
        verifierId: 'v$i',
        kind: EvaluationVerifierKind.tests,
        passed: success,
      ),
  ],
);

EvaluationPlan plan({
  double margin = 0.05,
  double maxCostRatio = 1.0,
  int minPairs = 8,
  List<StratumSpec> strata = const [
    StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
  ],
}) => EvaluationPlan(
  id: 'p',
  arms: const [
    EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline),
    EvaluationArm(id: 'cheap', axis: EvaluationAxis.effortRouting),
  ],
  minPairs: minPairs,
  nonInferiorityMargin: margin,
  maxCostRatio: maxCostRatio,
  strata: strata,
);

EvaluationTask task(String id) => EvaluationTask(
  id: id,
  kind: EvaluationTaskKind.bugfix,
  prompt: 'p',
  verifiers: const [
    EvaluationVerifier(id: 'v', kind: EvaluationVerifierKind.noWrites),
  ],
);

EvaluationReport reportFrom(
  List<EvaluationAttempt> attempts, {
  double margin = 0.05,
  double maxCostRatio = 1.0,
  int minPairs = 8,
  List<EvaluationTask>? tasks,
  List<StratumSpec> strata = const [
    StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
  ],
}) => const EvaluationReportBuilder().build(
  manifest: _manifest,
  plan: plan(
    margin: margin,
    maxCostRatio: maxCostRatio,
    minPairs: minPairs,
    strata: strata,
  ),
  tasks: tasks ?? [task('t1')],
  attempts: attempts,
  generatedAtEpochMs: 1000,
);

/// A complete, fully-priced paired campaign of [pairs] repetitions.
List<EvaluationAttempt> pairedCampaign({
  required int pairs,
  bool treatmentPasses = true,
  int baselineMicros = 10000,
  int treatmentMicros = 4000,
  int treatmentFailuresFrom = 1 << 30,
  int baselineFailuresFrom = 1 << 30,
  String taskId = 't1',
}) => [
  for (var i = 0; i < pairs; i++)
    attempt(
      taskId: taskId,
      armId: 'baseline',
      success: i < baselineFailuresFrom,
      micros: baselineMicros,
      repetition: i,
    ),
  for (var i = 0; i < pairs; i++)
    attempt(
      taskId: taskId,
      armId: 'cheap',
      success: treatmentPasses ? i < treatmentFailuresFrom : false,
      micros: treatmentMicros,
      repetition: i,
    ),
];

/// Matched outcomes on independent tasks (repetitions within a task are not
/// additional task-level samples).
EvaluationReport taskPopulation({
  required int count,
  required bool Function(int) baselinePasses,
  required bool Function(int) treatmentPasses,
  int baselineMicros = 10000,
  int treatmentMicros = 4000,
}) => reportFrom(
  [
    for (var i = 0; i < count; i++) ...[
      attempt(
        taskId: 't$i',
        armId: 'baseline',
        success: baselinePasses(i),
        micros: baselineMicros,
      ),
      attempt(
        taskId: 't$i',
        armId: 'cheap',
        success: treatmentPasses(i),
        micros: treatmentMicros,
      ),
    ],
  ],
  tasks: [for (var i = 0; i < count; i++) task('t$i')],
);

void main() {
  test(
    'small latency samples interpolate instead of reporting the maximum as median',
    () {
      final attempts = [
        for (final ms in [40, 10])
          attempt(
            taskId: 't$ms',
            armId: 'baseline',
            success: true,
            micros: 1,
          ).copyWith(latency: EvaluationLatency(totalMs: ms)),
      ];
      final summary = EvaluationArmSummary.fromAttempts(
        armId: 'baseline',
        axis: EvaluationAxis.baseline,
        effective: _effective,
        attempts: attempts,
      );
      expect(summary.p50LatencyMs, 25);
      expect(summary.p95LatencyMs, closeTo(38.5, 1e-9));
    },
  );

  group('success-adjusted cost', () {
    test('divides ALL attempt cost by verified successes, in micro-USD', () {
      final report = reportFrom([
        attempt(taskId: 't1', armId: 'baseline', success: true, micros: 10000),
        attempt(taskId: 't1', armId: 'baseline', success: false, micros: 30000),
        attempt(taskId: 't1', armId: 'cheap', success: true, micros: 20000),
      ]);
      final baseline = report.armSummaries.firstWhere(
        (s) => s.armId == 'baseline',
      );
      expect(baseline.verifiedSuccesses, 1);
      expect(baseline.totalCostMicros, 40000);
      expect(baseline.costPerVerifiedSuccessMicros, 40000);
    });

    test('an arm with no verified success has no finite cost', () {
      final report = reportFrom([
        attempt(taskId: 't1', armId: 'baseline', success: false, micros: 5000),
      ]);
      expect(
        report.armSummaries
            .firstWhere((s) => s.armId == 'baseline')
            .costPerVerifiedSuccessMicros,
        isNull,
      );
    });

    test('one unpriced attempt makes the whole arm cost unknown', () {
      final report = reportFrom([
        attempt(taskId: 't1', armId: 'baseline', success: true, micros: 10000),
        unpricedAttempt(taskId: 't1', armId: 'baseline', repetition: 1),
      ]);
      final baseline = report.armSummaries.firstWhere(
        (s) => s.armId == 'baseline',
      );
      expect(baseline.costComplete, isFalse);
      expect(baseline.totalCostMicros, isNull);
      expect(baseline.costPerVerifiedSuccessMicros, isNull);
    });
  });

  group('per-task regressions', () {
    test('a task the baseline solved and the treatment did not is flagged', () {
      final report = reportFrom(
        pairedCampaign(pairs: 8, treatmentPasses: false),
      );
      final loss = report.regressions.singleWhere(
        (r) => r.kind == RegressionKind.qualityLoss,
      );
      expect(loss.taskId, 't1');
      expect(loss.baselineSuccessRate, 1);
      expect(loss.treatmentSuccessRate, 0);
    });

    test('equal quality at 3x cost is a cost regression', () {
      final report = reportFrom(
        pairedCampaign(pairs: 8, baselineMicros: 10000, treatmentMicros: 30000),
      );
      expect(
        report.regressions.map((r) => r.kind),
        contains(RegressionKind.costRegression),
      );
    });

    test('an exact tie produces no regression', () {
      final report = reportFrom(
        pairedCampaign(pairs: 8, baselineMicros: 10000, treatmentMicros: 10000),
      );
      expect(report.regressions, isEmpty);
    });
  });

  group('non-inferiority', () {
    test('a tiny sample is inconclusive even when identical', () {
      final report = reportFrom(
        pairedCampaign(pairs: 1, baselineMicros: 10000, treatmentMicros: 1),
      );
      final verdict = report.verdicts.single;
      expect(verdict.pairs, 1);
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.recommendation, AdoptionRecommendation.inconclusive);
    });

    test('identical repetitions on one task do not establish quality', () {
      final report = reportFrom(
        pairedCampaign(
          pairs: 1000,
          baselineMicros: 10000,
          treatmentMicros: 1000,
        ),
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 1000),
        ],
      );
      final verdict = report.verdicts.single;
      expect(verdict.pairs, 1000);
      expect(verdict.effectiveTaskCount, 1);
      expect(verdict.observedDelta, 0);
      expect(verdict.lowerBound, lessThan(-0.05));
      expect(verdict.upperBound, greaterThan(0.05));
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.recommendation, AdoptionRecommendation.inconclusive);
      expect(verdict.method, contains('task-cluster one-sided Hoeffding'));
      expect(verdict.toJson().containsKey('pValue'), isFalse);
    });

    test('independent improved task population establishes superiority', () {
      final report = taskPopulation(
        count: 8,
        baselinePasses: (_) => false,
        treatmentPasses: (_) => true,
      );
      final verdict = report.verdicts.single;
      expect(verdict.treatmentOnlyWins, 8);
      expect(verdict.effectiveTaskCount, 8);
      expect(verdict.lowerBound, greaterThan(0));
      expect(verdict.verdict, QualityVerdict.superior);
    });

    test('a cheaper arm needs quality evidence even with identical tasks', () {
      final report = taskPopulation(
        count: 8,
        baselinePasses: (_) => true,
        treatmentPasses: (_) => true,
      );
      expect(report.verdicts.single.verdict, QualityVerdict.inconclusive);
      expect(report.verdicts.single.costRatio, closeTo(0.4, 1e-9));
      expect(
        report.verdicts.single.recommendation,
        AdoptionRecommendation.inconclusive,
      );
    });

    test(
      'a cheaper non-inferior arm is adopted with a declared wide margin',
      () {
        final tasks = [for (var i = 0; i < 8; i++) task('t$i')];
        final report = reportFrom(
          [
            for (final t in tasks) ...[
              attempt(
                taskId: t.id,
                armId: 'baseline',
                success: true,
                micros: 10000,
              ),
              attempt(
                taskId: t.id,
                armId: 'cheap',
                success: true,
                micros: 4000,
              ),
            ],
          ],
          tasks: tasks,
          margin: 0.9,
        );
        expect(report.verdicts.single.verdict, QualityVerdict.nonInferior);
        expect(report.verdicts.single.costRatio, closeTo(0.4, 1e-9));
        expect(
          report.overallRecommendation,
          AdoptionRecommendation.adoptTreatment,
        );
      },
    );

    test('a regressed task population is demonstrably inferior', () {
      final report = taskPopulation(
        count: 8,
        baselinePasses: (_) => true,
        treatmentPasses: (_) => false,
      );
      final verdict = report.verdicts.single;
      expect(verdict.baselineOnlyWins, 8);
      expect(verdict.upperBound, lessThan(-0.05));
      expect(verdict.verdict, QualityVerdict.inferior);
      expect(verdict.recommendation, AdoptionRecommendation.keepQualityDefault);
    });

    test('a loss with an ambiguous interval is inconclusive, not inferior', () {
      final report = taskPopulation(
        count: 8,
        baselinePasses: (_) => true,
        treatmentPasses: (i) => i != 0,
      );
      final verdict = report.verdicts.single;
      expect(verdict.baselineOnlyWins, 1);
      expect(verdict.lowerBound, lessThan(-0.05));
      expect(verdict.upperBound, greaterThan(-0.05));
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.recommendation, AdoptionRecommendation.inconclusive);
    });

    test('a skipped verifier is not a paired quality loss', () {
      final tasks = [for (var i = 0; i < 8; i++) task('t$i')];
      final report = reportFrom([
        for (final t in tasks) ...[
          attempt(
            taskId: t.id,
            armId: 'baseline',
            success: true,
            micros: 10000,
          ),
          if (t.id == 't0')
            attempt(
              taskId: t.id,
              armId: 'cheap',
              success: false,
              micros: 4000,
            ).copyWith(verification: const [])
          else
            attempt(taskId: t.id, armId: 'cheap', success: true, micros: 4000),
        ],
      ], tasks: tasks);
      final verdict = report.verdicts.single;
      expect(verdict.pairs, 7);
      expect(verdict.baselineOnlyWins, 0);
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(report.unknowns.join(), contains('unverified'));
    });

    test('one regressed task blocks otherwise non-inferior adoption', () {
      final tasks = [for (var i = 0; i < 100; i++) task('t$i')];
      final report = reportFrom(
        [
          for (final t in tasks) ...[
            attempt(
              taskId: t.id,
              armId: 'baseline',
              success: true,
              micros: 10000,
            ),
            attempt(
              taskId: t.id,
              armId: 'cheap',
              success: t.id != 't0',
              micros: 3000,
            ),
          ],
        ],
        tasks: tasks,
        margin: 0.3,
      );
      final verdict = report.verdicts.single;
      expect(verdict.blockedTaskIds, ['t0']);
      expect(verdict.verdict, QualityVerdict.nonInferior);
      expect(verdict.recommendation, AdoptionRecommendation.keepQualityDefault);
    });
  });

  group('cost and coverage gates', () {
    test('unknown treatment cost never supports a cheapness claim', () {
      final tasks = [for (var i = 0; i < 8; i++) task('t$i')];
      final report = reportFrom([
        for (final t in tasks) ...[
          attempt(
            taskId: t.id,
            armId: 'baseline',
            success: false,
            micros: 10000,
          ),
          unpricedAttempt(taskId: t.id, armId: 'cheap'),
        ],
      ], tasks: tasks);
      final verdict = report.verdicts.single;
      expect(verdict.verdict, QualityVerdict.superior);
      expect(verdict.costRatio, isNull);
      expect(verdict.recommendation, AdoptionRecommendation.keepQualityDefault);
      expect(verdict.reason, contains('cost is incomplete'));
      expect(report.unknowns.join(), contains('not priced'));
      final markdown = const EvaluationReportRenderer().render(report);
      expect(markdown, contains('? (unpriced)'));
      expect(markdown, contains('| ? |'));
    });

    test('one unpriced attempt makes a priced arm incomparable', () {
      final tasks = [for (var i = 0; i < 8; i++) task('t$i')];
      final report = reportFrom([
        for (final t in tasks) ...[
          attempt(
            taskId: t.id,
            armId: 'baseline',
            success: false,
            micros: 10000,
          ),
          attempt(taskId: t.id, armId: 'cheap', success: true, micros: 4000),
        ],
        unpricedAttempt(taskId: 't0', armId: 'cheap', repetition: 99),
      ], tasks: tasks);
      expect(report.verdicts.single.verdict, QualityVerdict.superior);
      expect(report.verdicts.single.costRatio, isNull);
      expect(
        report.verdicts.single.recommendation,
        AdoptionRecommendation.keepQualityDefault,
      );
    });

    test('a campaign missing planned trials blocks adoption', () {
      // The plan asks for two strata; only the cold ones ran.
      final report = reportFrom(
        pairedCampaign(pairs: 10, baselineMicros: 10000, treatmentMicros: 1000),
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 10),
          StratumSpec(stratum: CacheStratum.warm, repetitions: 10),
        ],
      );
      expect(report.coverageComplete, isFalse);
      expect(report.verdicts.single.verdict, QualityVerdict.inconclusive);
      expect(
        report.overallRecommendation,
        AdoptionRecommendation.keepQualityDefault,
      );
      expect(report.unknowns.join(), contains('coverage is incomplete'));
    });

    test('extra cold attempts cannot mask a missing warm stratum', () {
      final report = reportFrom(
        pairedCampaign(pairs: 2),
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
          StratumSpec(stratum: CacheStratum.warm, repetitions: 1),
        ],
        minPairs: 2,
      );
      expect(report.attempts.length, report.expectedTrials);
      expect(report.coverageComplete, isFalse);
      expect(report.verdicts.single.verdict, QualityVerdict.inconclusive);
      expect(
        report.overallRecommendation,
        AdoptionRecommendation.keepQualityDefault,
      );
    });
  });

  group('report shape', () {
    test('records unknowns instead of hiding missing evidence', () {
      final report = reportFrom(
        pairedCampaign(pairs: 1, treatmentPasses: false),
      );
      expect(report.unknowns, isNotEmpty);
      expect(report.liveModelCalls, isTrue);
    });

    test('a live report says the model was called', () {
      final report = reportFrom([
        attempt(taskId: 't1', armId: 'baseline', success: true, micros: 10000),
      ]);
      expect(report.executionMode, EvaluationExecutionMode.live);
      expect(report.liveModelCalls, isTrue);
      final markdown = const EvaluationReportRenderer().render(report);
      expect(markdown, contains('# Evaluation report — LIVE'));
    });

    test('the markdown report renders arms, verdicts and unknowns', () {
      final report = reportFrom(
        pairedCampaign(pairs: 10, baselineMicros: 10000, treatmentMicros: 4000),
      );
      final markdown = const EvaluationReportRenderer().render(report);
      expect(markdown, contains('## Arms'));
      expect(markdown, contains('## Paired verdicts'));
      expect(markdown, contains('effective tasks 1'));
      expect(markdown, contains('task-cluster one-sided Hoeffding'));
      expect(markdown, isNot(contains('McNemar')));
      expect(markdown, contains('## Per-task regressions'));
      expect(markdown, contains('## Unknowns'));
    });
  });
}

/// An attempt whose provider calls were never priced: its cost is UNKNOWN, not
/// zero.
EvaluationAttempt unpricedAttempt({
  required String taskId,
  required String armId,
  int repetition = 0,
  bool success = true,
}) => EvaluationAttempt(
  attemptId: '$taskId-$armId-unpriced-$repetition',
  taskId: taskId,
  taskKind: EvaluationTaskKind.bugfix,
  armId: armId,
  effective: _effective,
  stratum: CacheStratum.cold,
  repetition: repetition,
  seed: 1,
  startedAtEpochMs: 0,
  completed: true,
  expectedAuthoritativeChecks: 1,
  verification: [
    EvaluationVerificationResult(
      verifierId: 'v',
      kind: EvaluationVerifierKind.tests,
      passed: success,
    ),
  ],
);
