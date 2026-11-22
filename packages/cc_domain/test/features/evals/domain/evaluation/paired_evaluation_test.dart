import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_report_renderer.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/evals/domain/evaluation/task_cluster_statistics.dart';
import 'package:cc_domain/features/evals/domain/evaluation/task_cluster_verdict.dart';
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

const _cold1 = [StratumSpec(stratum: CacheStratum.cold, repetitions: 1)];

/// One attempt with a single DECLARED authoritative check, priced in micro-USD.
EvaluationAttempt attempt({
  required String taskId,
  required String armId,
  required bool success,
  required int micros,
  int repetition = 0,
  CacheStratum stratum = CacheStratum.cold,
  EvaluationAttemptEnd end = EvaluationAttemptEnd.finished,
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
  end: end,
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
  EvaluationHypothesis hypothesis = EvaluationHypothesis.nonInferiority,
  EvaluationOutcomeMeasure outcome = EvaluationOutcomeMeasure.verifiedSuccess,
  double margin = 0.1,
  double maxCostRatio = 1.0,
  int? minTasks = 10,
  int? interimAtTasks,
  List<String> treatments = const ['cheap'],
  List<StratumSpec> strata = _cold1,
}) => EvaluationPlan(
  id: 'p',
  hypothesis: hypothesis,
  primaryOutcome: outcome,
  minTasks: minTasks,
  arms: [
    const EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline),
    for (final id in treatments)
      EvaluationArm(id: id, axis: EvaluationAxis.effortRouting),
  ],
  nonInferiorityMargin: hypothesis == EvaluationHypothesis.nonInferiority
      ? margin
      : null,
  interimAtTasks: interimAtTasks,
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

List<EvaluationTask> tasksOf(int count) => [
  for (var i = 0; i < count; i++) task('t$i'),
];

EvaluationReport reportFrom(
  List<EvaluationAttempt> attempts, {
  EvaluationHypothesis hypothesis = EvaluationHypothesis.nonInferiority,
  EvaluationOutcomeMeasure outcome = EvaluationOutcomeMeasure.verifiedSuccess,
  double margin = 0.1,
  double maxCostRatio = 1.0,
  int? minTasks = 10,
  List<String> treatments = const ['cheap'],
  List<EvaluationTask>? tasks,
  List<StratumSpec> strata = _cold1,
  bool stoppedAtInterim = false,
}) => const EvaluationReportBuilder().build(
  manifest: _manifest,
  plan: plan(
    hypothesis: hypothesis,
    outcome: outcome,
    margin: margin,
    maxCostRatio: maxCostRatio,
    minTasks: minTasks,
    treatments: treatments,
    strata: strata,
  ),
  tasks: tasks ?? [task('t1')],
  attempts: attempts,
  generatedAtEpochMs: 1000,
  stoppedAtInterim: stoppedAtInterim,
);

/// A complete, fully-priced campaign of [pairs] cold repetitions on one task.
List<EvaluationAttempt> pairedCampaign({
  required int pairs,
  bool treatmentPasses = true,
  int baselineMicros = 10000,
  int treatmentMicros = 4000,
  String taskId = 't1',
}) => [
  for (var i = 0; i < pairs; i++)
    attempt(
      taskId: taskId,
      armId: 'baseline',
      success: true,
      micros: baselineMicros,
      repetition: i,
    ),
  for (var i = 0; i < pairs; i++)
    attempt(
      taskId: taskId,
      armId: 'cheap',
      success: treatmentPasses,
      micros: treatmentMicros,
      repetition: i,
    ),
];

/// One attempt per arm on each of [count] independent tasks.
List<EvaluationAttempt> populationAttempts({
  required int count,
  required bool Function(int) baselinePasses,
  required bool Function(int) treatmentPasses,
  int baselineMicros = 10000,
  int treatmentMicros = 4000,
  String treatment = 'cheap',
  EvaluationAttemptEnd Function(int)? treatmentEnd,
}) => [
  for (var i = 0; i < count; i++) ...[
    attempt(
      taskId: 't$i',
      armId: 'baseline',
      success: baselinePasses(i),
      micros: baselineMicros,
    ),
    attempt(
      taskId: 't$i',
      armId: treatment,
      success: treatmentPasses(i),
      micros: treatmentMicros,
      end: treatmentEnd?.call(i) ?? EvaluationAttemptEnd.finished,
    ),
  ],
];

EvaluationReport taskPopulation({
  required int count,
  required bool Function(int) baselinePasses,
  required bool Function(int) treatmentPasses,
  int baselineMicros = 10000,
  int treatmentMicros = 4000,
  EvaluationHypothesis hypothesis = EvaluationHypothesis.nonInferiority,
  EvaluationAttemptEnd Function(int)? treatmentEnd,
}) => reportFrom(
  populationAttempts(
    count: count,
    baselinePasses: baselinePasses,
    treatmentPasses: treatmentPasses,
    baselineMicros: baselineMicros,
    treatmentMicros: treatmentMicros,
    treatmentEnd: treatmentEnd,
  ),
  hypothesis: hypothesis,
  tasks: tasksOf(count),
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

  group('per-task regressions (descriptive)', () {
    test('a task the baseline solved and the treatment did not is listed', () {
      final report = reportFrom(
        pairedCampaign(pairs: 8, treatmentPasses: false),
        strata: const [StratumSpec(stratum: CacheStratum.cold, repetitions: 8)],
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

    test('the list is read against how many losses chance alone shows', () {
      // k = 3, pooled rate 1/2: identical arms show a lower treatment rate
      // with probability (1 − P(tie)) / 2 = (1 − 20/64) / 2.
      final attempts = [
        for (var r = 0; r < 3; r++) ...[
          attempt(
            taskId: 't1',
            armId: 'baseline',
            success: r < 2,
            micros: 1,
            repetition: r,
          ),
          attempt(
            taskId: 't1',
            armId: 'cheap',
            success: r < 1,
            micros: 1,
            repetition: r,
          ),
        ],
      ];
      final report = reportFrom(
        attempts,
        strata: const [StratumSpec(stratum: CacheStratum.cold, repetitions: 3)],
      );
      expect(
        report.verdicts.single.expectedChanceLosses,
        closeTo(22 / 64, 1e-12),
      );
      final markdown = const EvaluationReportRenderer().render(report);
      expect(markdown, contains('about 0.3 of these 1 task(s) by chance'));
    });

    test('a harness error counts harness faults only', () {
      final report = reportFrom([
        attempt(taskId: 't1', armId: 'baseline', success: true, micros: 1),
        attempt(
          taskId: 't1',
          armId: 'cheap',
          success: false,
          micros: 1,
          end: EvaluationAttemptEnd.agentStopped,
        ),
      ]);
      expect(
        report.regressions.map((r) => r.kind),
        isNot(contains(RegressionKind.harnessError)),
      );
      expect(report.taskOutcomes.every((o) => o.harnessErrors == 0), isTrue);
    });
  });

  group('the task-cluster verdict', () {
    test('a tiny sample is inconclusive even when identical', () {
      final report = reportFrom(
        pairedCampaign(pairs: 1, baselineMicros: 10000, treatmentMicros: 1),
      );
      final verdict = report.verdicts.single;
      expect(verdict.pairs, 1);
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.reason, startsWith('1 tasks, 10 needed'));
      expect(verdict.recommendation, AdoptionRecommendation.noDecision);
      expect(report.overallRecommendation, AdoptionRecommendation.noDecision);
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
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.reason, startsWith('1 tasks, 10 needed'));
      expect(verdict.recommendation, AdoptionRecommendation.noDecision);
      expect(
        verdict.method,
        'task-cluster paired t (df N−1) with exact sign-flip check',
      );
      expect(verdict.toJson()['pValue'], isA<double>());
      expect(verdict.toJson()['signFlipP'], isA<double>());
    });

    test('an improved task population establishes superiority', () {
      final report = taskPopulation(
        count: 12,
        baselinePasses: (_) => false,
        treatmentPasses: (_) => true,
      );
      final verdict = report.verdicts.single;
      expect(verdict.treatmentOnlyWins, 12);
      expect(verdict.effectiveTaskCount, 12);
      // Every task moved by the same amount: no spread, so the claim rests
      // on the exact sign-flip p (1/4096).
      expect(verdict.standardDeviation, 0);
      expect(verdict.lowerBound, 1);
      expect(verdict.signFlipP, closeTo(1 / 4096, 1e-12));
      expect(verdict.verdict, QualityVerdict.superior);
      expect(verdict.recommendation, AdoptionRecommendation.adoptTreatment);
    });

    test('identical saturated tasks are no evidence (s = 0, d = 0)', () {
      final report = taskPopulation(
        count: 12,
        baselinePasses: (_) => true,
        treatmentPasses: (_) => true,
      );
      final verdict = report.verdicts.single;
      expect(verdict.informativeTasks, 0);
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.reason, contains('saturated task set'));
      expect(verdict.costRatio, closeTo(0.4, 1e-9));
      expect(verdict.recommendation, AdoptionRecommendation.noDecision);
    });

    test('exact ties on informative tasks support non-inferiority', () {
      // Both arms pass one of two repetitions on every task: d = 0, s = 0,
      // and the claim rests on the sign-flip p of d + m (2^−N).
      const strata = [StratumSpec(stratum: CacheStratum.cold, repetitions: 2)];
      final tasks = tasksOf(10);
      final report = reportFrom(
        [
          for (final t in tasks)
            for (var r = 0; r < 2; r++) ...[
              attempt(
                taskId: t.id,
                armId: 'baseline',
                success: r == 0,
                micros: 10000,
                repetition: r,
              ),
              attempt(
                taskId: t.id,
                armId: 'cheap',
                success: r == 1,
                micros: 4000,
                repetition: r,
              ),
            ],
        ],
        tasks: tasks,
        strata: strata,
      );
      final verdict = report.verdicts.single;
      expect(verdict.informativeTasks, 10);
      expect(verdict.observedDelta, 0);
      expect(verdict.verdict, QualityVerdict.nonInferior);
      expect(verdict.signFlipP, closeTo(1 / 1024, 1e-12));
      expect(verdict.costRatio, closeTo(0.4, 1e-9));
      expect(
        report.overallRecommendation,
        AdoptionRecommendation.adoptTreatment,
      );
    });

    test('a regressed task population is demonstrably inferior', () {
      final report = taskPopulation(
        count: 12,
        baselinePasses: (_) => true,
        treatmentPasses: (_) => false,
      );
      final verdict = report.verdicts.single;
      expect(verdict.baselineOnlyWins, 12);
      expect(verdict.upperBound, lessThan(0));
      expect(verdict.verdict, QualityVerdict.inferior);
      expect(verdict.recommendation, AdoptionRecommendation.keepQualityDefault);
      expect(
        report.overallRecommendation,
        AdoptionRecommendation.keepQualityDefault,
      );
    });

    test('a loss with an ambiguous interval is inconclusive, not inferior', () {
      final report = taskPopulation(
        count: 12,
        baselinePasses: (_) => true,
        treatmentPasses: (i) => i != 0,
      );
      final verdict = report.verdicts.single;
      expect(verdict.baselineOnlyWins, 1);
      expect(verdict.lowerBound, lessThan(-0.1));
      expect(verdict.upperBound, greaterThan(0));
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.reason, contains('this is not evidence of no difference'));
      expect(verdict.recommendation, AdoptionRecommendation.noDecision);
    });

    test('a skipped verifier drops the task, it is not a quality loss', () {
      // Ten tasks: one missing attempt of ten planned is within the 10 %
      // rule (at eight tasks it would read "harness unreliable").
      final tasks = tasksOf(10);
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
      expect(verdict.effectiveTaskCount, 9);
      expect(verdict.pairs, 9);
      expect(verdict.baselineOnlyWins, 0);
      expect(verdict.droppedTasks.single.taskId, 't0');
      expect(
        verdict.droppedTasks.single.reason,
        contains('declared checks skipped'),
      );
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.reason, '9 tasks, 10 needed');
      expect(report.unknowns.join(), contains('unverified'));
    });

    test('one regressed task is listed and blocks nothing', () {
      // Both arms pass one of two repetitions on every task except t0, where
      // the treatment passes neither.
      const strata = [StratumSpec(stratum: CacheStratum.cold, repetitions: 2)];
      final tasks = tasksOf(20);
      final report = reportFrom(
        [
          for (final t in tasks)
            for (var r = 0; r < 2; r++) ...[
              attempt(
                taskId: t.id,
                armId: 'baseline',
                success: r == 0,
                micros: 10000,
                repetition: r,
              ),
              attempt(
                taskId: t.id,
                armId: 'cheap',
                success: r == 0 && t.id != 't0',
                micros: 3000,
                repetition: r,
              ),
            ],
        ],
        tasks: tasks,
        strata: strata,
      );
      final verdict = report.verdicts.single;
      expect(
        report.regressions
            .where((r) => r.kind == RegressionKind.qualityLoss)
            .map((r) => r.taskId),
        ['t0'],
      );
      expect(verdict.verdict, QualityVerdict.nonInferior);
      expect(verdict.recommendation, AdoptionRecommendation.adoptTreatment);
    });

    test('an agent that stopped scores as a failure, not as missing', () {
      final report = taskPopulation(
        count: 12,
        baselinePasses: (_) => true,
        treatmentPasses: (_) => true,
        treatmentEnd: (_) => EvaluationAttemptEnd.agentStopped,
      );
      final verdict = report.verdicts.single;
      expect(verdict.effectiveTaskCount, 12);
      expect(verdict.droppedTasks, isEmpty);
      expect(verdict.observedDelta, -1);
      expect(verdict.verdict, QualityVerdict.inferior);
    });

    test('a harness fault drops its task block and says why', () {
      final report = taskPopulation(
        count: 11,
        baselinePasses: (_) => false,
        treatmentPasses: (_) => true,
        treatmentEnd: (i) => i == 0
            ? EvaluationAttemptEnd.harnessFault
            : EvaluationAttemptEnd.finished,
      );
      final verdict = report.verdicts.single;
      expect(verdict.tasksPlanned, 11);
      expect(verdict.effectiveTaskCount, 10);
      expect(verdict.droppedTasks.single.taskId, 't0');
      expect(verdict.droppedTasks.single.reason, contains('harness fault 1'));
      expect(verdict.verdict, QualityVerdict.superior);
    });

    test('more than 10 % missing is a harness too unreliable to judge', () {
      final report = taskPopulation(
        count: 12,
        baselinePasses: (_) => false,
        treatmentPasses: (_) => true,
        treatmentEnd: (i) => i < 2
            ? EvaluationAttemptEnd.harnessFault
            : EvaluationAttemptEnd.finished,
      );
      final verdict = report.verdicts.single;
      expect(verdict.effectiveTaskCount, 10);
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(verdict.reason, startsWith('harness unreliable: 2 of 12'));
    });

    test('ceiling stops are missing data but not unreliability', () {
      final report = taskPopulation(
        count: 12,
        baselinePasses: (_) => false,
        treatmentPasses: (_) => true,
        treatmentEnd: (i) => i < 2
            ? EvaluationAttemptEnd.ceilingStopped
            : EvaluationAttemptEnd.finished,
      );
      final verdict = report.verdicts.single;
      expect(verdict.effectiveTaskCount, 10);
      expect(verdict.droppedTasks.first.reason, contains('spend ceiling'));
      expect(verdict.verdict, QualityVerdict.superior);
      expect(report.unknowns.join(), contains('cut by the spend ceiling'));
    });

    test('false completions orient the difference so lower is better', () {
      final tasks = tasksOf(10);
      final report = reportFrom(
        [
          for (final t in tasks) ...[
            // Baseline finished and its check failed: a false completion.
            attempt(taskId: t.id, armId: 'baseline', success: false, micros: 1),
            attempt(taskId: t.id, armId: 'cheap', success: true, micros: 2),
          ],
        ],
        hypothesis: EvaluationHypothesis.superiority,
        outcome: EvaluationOutcomeMeasure.falseCompletion,
        maxCostRatio: 3,
        tasks: tasks,
      );
      final verdict = report.verdicts.single;
      expect(verdict.observedDelta, 1);
      expect(verdict.verdict, QualityVerdict.superior);
      expect(verdict.costRatio, closeTo(2, 1e-9));
      expect(verdict.recommendation, AdoptionRecommendation.adoptTreatment);
    });

    test('Holm holds every treatment of one plan to the family level', () {
      final tasks = tasksOf(12);
      final report = reportFrom(
        [
          ...populationAttempts(
            count: 12,
            baselinePasses: (_) => false,
            treatmentPasses: (_) => true,
            treatment: 'masking',
          ),
          for (final t in tasks)
            attempt(taskId: t.id, armId: 'hybrid', success: false, micros: 1),
        ],
        treatments: const ['masking', 'hybrid'],
        tasks: tasks,
      );
      expect(report.verdicts.map((v) => v.treatmentArmId), [
        'masking',
        'hybrid',
      ]);
      expect(report.verdicts.first.verdict, QualityVerdict.superior);
      expect(report.verdicts.last.verdict, QualityVerdict.inconclusive);
      expect(
        report.overallRecommendation,
        AdoptionRecommendation.adoptTreatment,
      );
      expect(TaskClusterStatistics.holm([0.03, 0.04], 0.05), [false, false]);
      expect(TaskClusterStatistics.holm([0.04, 0.01], 0.05), [true, true]);
      expect(TaskClusterStatistics.holm([0.02, 0.5], 0.05), [true, false]);
    });

    test('the interim look stops only on p < 0.001', () {
      final tasks = tasksOf(14);
      final interimPlan = plan(
        hypothesis: EvaluationHypothesis.superiority,
        interimAtTasks: 10,
      );
      final judge = TaskClusterJudge(plan: interimPlan, tasks: tasks);
      final decisive = populationAttempts(
        count: 10,
        baselinePasses: (_) => false,
        treatmentPasses: (_) => true,
      );
      expect(judge.completedTaskBlocks(decisive), 10);
      expect(judge.interimStop(decisive), isTrue);
      // Six of ten tasks improved: superior at the final alpha (t p about
      // 0.003), not below the interim's 0.001.
      final mixed = populationAttempts(
        count: 10,
        baselinePasses: (_) => false,
        treatmentPasses: (i) => i < 6,
      );
      expect(judge.interimStop(mixed), isFalse);
      expect(judge.interimStop(decisive.take(18).toList()), isFalse);
      final report = const EvaluationReportBuilder().build(
        manifest: _manifest,
        plan: interimPlan,
        tasks: tasks,
        attempts: decisive,
        generatedAtEpochMs: 0,
        stoppedAtInterim: true,
      );
      expect(report.stoppedAtInterim, isTrue);
      expect(report.verdicts.single.verdict, QualityVerdict.superior);
      expect(
        report.verdicts.single.reason,
        startsWith('stopped at the interim look after 10 tasks'),
      );
      expect(report.verdicts.single.droppedTasks.length, 4);
    });

    test('a regression screen calls inferior on the sign-flip p alone', () {
      EvaluationReport screen(int count) => reportFrom(
        populationAttempts(
          count: count,
          baselinePasses: (_) => true,
          treatmentPasses: (_) => false,
        ),
        hypothesis: EvaluationHypothesis.regressionScreen,
        minTasks: 3,
        tasks: tasksOf(count),
      );
      // 1/32 at five tasks; 1/16 at four cannot reach 0.05.
      expect(screen(5).verdicts.single.verdict, QualityVerdict.inferior);
      expect(screen(4).verdicts.single.verdict, QualityVerdict.inconclusive);
      expect(screen(4).verdicts.single.signFlipP, closeTo(1 / 16, 1e-12));
    });
  });

  group('cost and coverage', () {
    test('unknown treatment cost never supports adoption', () {
      final tasks = tasksOf(10);
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
      expect(verdict.recommendation, AdoptionRecommendation.noDecision);
      expect(verdict.reason, contains('unpriced'));
      expect(report.unknowns.join(), contains('not priced'));
      final markdown = const EvaluationReportRenderer().render(report);
      expect(markdown, contains('? (unpriced)'));
      expect(markdown, contains('| ? |'));
    });

    test('the cost ratio is over the used task blocks only', () {
      final tasks = tasksOf(11);
      final report = reportFrom([
        for (final t in tasks) ...[
          attempt(
            taskId: t.id,
            armId: 'baseline',
            success: false,
            micros: 10000,
          ),
          if (t.id == 't0')
            unpricedAttempt(
              taskId: t.id,
              armId: 'cheap',
            ).copyWith(end: EvaluationAttemptEnd.harnessFault)
          else
            attempt(taskId: t.id, armId: 'cheap', success: true, micros: 4000),
        ],
      ], tasks: tasks);
      final verdict = report.verdicts.single;
      expect(verdict.effectiveTaskCount, 10);
      expect(verdict.costRatio, closeTo(0.4, 1e-9));
      expect(verdict.recommendation, AdoptionRecommendation.adoptTreatment);
    });

    test('a task missing a planned stratum is dropped, not judged', () {
      final report = reportFrom(
        pairedCampaign(pairs: 10, baselineMicros: 10000, treatmentMicros: 1000),
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 10),
          StratumSpec(stratum: CacheStratum.warm, repetitions: 10),
        ],
      );
      expect(report.coverageComplete, isFalse);
      final verdict = report.verdicts.single;
      expect(verdict.effectiveTaskCount, 0);
      expect(verdict.droppedTasks.single.reason, contains('not run 10'));
      expect(verdict.verdict, QualityVerdict.inconclusive);
      expect(report.overallRecommendation, AdoptionRecommendation.noDecision);
      expect(report.unknowns.join(), contains('coverage is incomplete'));
    });

    test('extra cold attempts cannot stand in for a missing warm one', () {
      final report = reportFrom(
        pairedCampaign(pairs: 2),
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
          StratumSpec(stratum: CacheStratum.warm, repetitions: 1),
        ],
      );
      expect(report.attempts.length, report.expectedTrials);
      expect(report.coverageComplete, isFalse);
      expect(report.verdicts.single.effectiveTaskCount, 0);
      expect(report.verdicts.single.verdict, QualityVerdict.inconclusive);
      expect(report.overallRecommendation, AdoptionRecommendation.noDecision);
    });

    test('a post-idle plan is analysed only when complete', () {
      final tasks = tasksOf(10);
      final report = reportFrom(
        populationAttempts(
          count: 10,
          baselinePasses: (_) => false,
          treatmentPasses: (_) => true,
        ),
        tasks: tasks,
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
          StratumSpec(
            stratum: CacheStratum.postIdle,
            repetitions: 1,
            idleFor: Duration(minutes: 1),
          ),
        ],
      );
      expect(report.verdicts.single.verdict, QualityVerdict.inconclusive);
      expect(
        report.verdicts.single.reason,
        contains('analysed only when every planned trial ran'),
      );
    });
  });

  group('statistics', () {
    test("Student's t quantile matches the table", () {
      for (final (df, expected) in [
        (4, 2.132),
        (9, 1.833),
        (24, 1.711),
        (99, 1.660),
      ]) {
        expect(
          TaskClusterStatistics.studentTQuantile(0.95, df),
          closeTo(expected, 0.0005),
          reason: 't.95 at df $df',
        );
      }
      expect(
        TaskClusterStatistics.studentTQuantile(0.95, 1),
        closeTo(6.314, 0.0005),
      );
      expect(TaskClusterStatistics.studentTCdf(0, 7), closeTo(0.5, 1e-12));
      expect(
        TaskClusterStatistics.studentTCdf(2.132, 4),
        closeTo(0.95, 0.0002),
      );
    });

    test('the exact sign-flip p enumerates every pattern', () {
      double flip(List<double> v) =>
          TaskClusterStatistics.signFlipPValue(v, seed: 1);
      expect(flip([1, 1, 1, 1, 1]), 1 / 32);
      expect(flip([0.2, 0.5, 1, 0.3, 0.1]), 1 / 32);
      // One loss among five unit differences: sums ≥ 3 need at most one
      // negative sign, 6 of 32 patterns.
      expect(flip([1, 1, 1, 1, -1]), 6 / 32);
      // A zero difference carries no sign.
      expect(flip([1, 0]), 2 / 4);
      expect(flip([-1, -1, -1]), 1);
      expect(flip(const []), 1);
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

    test('the markdown report renders the question, the test and the '
        'per-task scores', () {
      final report = reportFrom(
        pairedCampaign(pairs: 10, baselineMicros: 10000, treatmentMicros: 4000),
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 10),
        ],
      );
      final markdown = const EvaluationReportRenderer().render(report);
      expect(markdown, contains('## Arms'));
      expect(markdown, contains('## Paired verdicts'));
      expect(markdown, contains('non_inferiority on verified_success'));
      expect(markdown, contains('margin 10.0 points (absolute)'));
      expect(markdown, contains('tasks used 1 of 1 planned (k = 10'));
      expect(
        markdown,
        contains('task-cluster paired t (df N−1) with exact sign-flip check'),
      );
      expect(markdown, contains('smallest effect this size could detect'));
      expect(markdown, contains('No decision (not enough evidence)'));
      expect(markdown, isNot(contains('Hoeffding')));
      expect(markdown, isNot(contains('Keep quality default')));
      expect(markdown, contains('| per attempt | per completion |'));
      expect(markdown, contains('saturated: 10 of 10 in every arm'));
      expect(markdown, contains('## Per-task regressions'));
      expect(markdown, contains('## Unknowns'));
    });

    test('a calibration plan reports pass rates and prices, no verdict', () {
      const calibration = EvaluationPlan(
        id: 'cal',
        hypothesis: EvaluationHypothesis.calibration,
        primaryOutcome: EvaluationOutcomeMeasure.verifiedSuccess,
        minTasks: null,
        arms: [EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline)],
        strata: [StratumSpec(stratum: CacheStratum.cold, repetitions: 3)],
      );
      final tasks = tasksOf(2);
      expect(calibration.violations(tasks), isEmpty);
      final report = const EvaluationReportBuilder().build(
        manifest: _manifest,
        plan: calibration,
        tasks: tasks,
        attempts: [
          for (var r = 0; r < 3; r++) ...[
            attempt(
              taskId: 't0',
              armId: 'baseline',
              success: false,
              micros: 10000,
              repetition: r,
            ),
            attempt(
              taskId: 't1',
              armId: 'baseline',
              success: r != 2,
              micros: 20000,
              repetition: r,
              end: r == 2
                  ? EvaluationAttemptEnd.agentStopped
                  : EvaluationAttemptEnd.finished,
            ),
          ],
        ],
        generatedAtEpochMs: 0,
      );
      expect(report.verdicts, isEmpty);
      expect(report.overallRecommendation, AdoptionRecommendation.noDecision);
      final markdown = const EvaluationReportRenderer().render(report);
      expect(markdown, contains('calibration plan runs one arm'));
      expect(markdown, contains(r'| t0 | 0 of 3 · $0.010000 | saturated'));
      expect(markdown, contains(r'| t1 | 2 of 3 · $0.020000 |  |'));
      expect(markdown, contains('| agent stopped |'));
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
  end: EvaluationAttemptEnd.finished,
  expectedAuthoritativeChecks: 1,
  verification: [
    EvaluationVerificationResult(
      verifierId: 'v',
      kind: EvaluationVerifierKind.tests,
      passed: success,
    ),
  ],
);
