import 'dart:math' as math;

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';

/// Aggregate behaviour of one arm across every task it ran.
///
/// Costs are reported *per verified success* — never per attempt — because a
/// cheap configuration that fails half the time is not cheap
/// (HARNESS_RESEARCH §6). All arithmetic stays in micro-USD.
class EvaluationArmSummary {
  /// Creates an [EvaluationArmSummary].
  const EvaluationArmSummary({
    required this.armId,
    required this.axis,
    required this.effective,
    required this.attempts,
    required this.completed,
    required this.eligible,
    required this.verifiedSuccesses,
    required this.harnessErrors,
    required this.ineligible,
    required this.costComplete,
    required this.totalCostMicros,
    required this.tokens,
    required this.cost,
    required this.metrics,
    required this.meanLatencyMs,
    required this.p50LatencyMs,
    required this.p95LatencyMs,
    required this.perStratumSuccessRate,
  });

  /// Builds a summary from the attempts of one arm.
  factory EvaluationArmSummary.fromAttempts({
    required String armId,
    required EvaluationAxis axis,
    required EvaluationEffectiveConfig effective,
    required List<EvaluationAttempt> attempts,
  }) {
    var completed = 0;
    var eligible = 0;
    var passed = 0;
    var errors = 0;
    var ineligible = 0;
    var costComplete = true;
    var costMicros = 0;
    var tokens = const EvaluationTokenBreakdown();
    var cost = const EvaluationCostRoles();
    var metrics = const EvaluationAttemptMetrics();
    final latencies = <int>[];
    final perStratumPass = <CacheStratum, int>{};
    final perStratumTotal = <CacheStratum, int>{};
    for (final attempt in attempts) {
      if (attempt.completed) {
        completed++;
      } else {
        errors++;
      }
      if (attempt.identityMismatches.isNotEmpty ||
          !attempt.verificationComplete) {
        ineligible++;
      }
      if (attempt.verifiedSuccess) {
        passed++;
      }
      if (attempt.completed && attempt.identityMismatches.isEmpty) {
        eligible++;
      }
      final attemptCost = attempt.attemptCostMicros;
      if (attemptCost == null) {
        costComplete = false;
      } else {
        costMicros += attemptCost;
      }
      tokens = tokens + attempt.tokens;
      cost = cost + attempt.cost;
      metrics = _addMetrics(metrics, attempt.metrics);
      latencies.add(attempt.latency.totalMs);
      perStratumTotal[attempt.stratum] =
          (perStratumTotal[attempt.stratum] ?? 0) + 1;
      if (attempt.verifiedSuccess) {
        perStratumPass[attempt.stratum] =
            (perStratumPass[attempt.stratum] ?? 0) + 1;
      }
    }
    latencies.sort();
    // A cost total is only comparable when EVERY attempt in the arm was priced;
    // otherwise the cheaper-looking arm may simply be the unpriced one.
    final totalMicros = (costComplete && attempts.isNotEmpty)
        ? costMicros
        : null;
    return EvaluationArmSummary(
      armId: armId,
      axis: axis,
      effective: effective,
      attempts: attempts.length,
      completed: completed,
      eligible: eligible,
      verifiedSuccesses: passed,
      harnessErrors: errors,
      ineligible: ineligible,
      costComplete: costComplete && attempts.isNotEmpty,
      totalCostMicros: totalMicros,
      tokens: tokens,
      cost: cost,
      metrics: metrics,
      meanLatencyMs: latencies.isEmpty ? 0 : _mean(latencies),
      p50LatencyMs: _percentile(latencies, 0.5),
      p95LatencyMs: _percentile(latencies, 0.95),
      perStratumSuccessRate: {
        for (final entry in perStratumTotal.entries)
          entry.key: (perStratumPass[entry.key] ?? 0) / entry.value,
      },
    );
  }

  /// The arm id.
  final String armId;

  /// The axis this arm deviated on.
  final EvaluationAxis axis;

  /// The effective configuration it ran under.
  final EvaluationEffectiveConfig effective;

  /// Attempts observed.
  final int attempts;

  /// Attempts that reached a clean terminal state.
  final int completed;

  /// Attempts that completed without an observed identity contradiction.
  final int eligible;

  /// Attempts proven successful by an independent behavioral check.
  final int verifiedSuccesses;

  /// Attempts the harness itself faulted on.
  final int harnessErrors;

  /// Attempts whose evidence is unusable (identity mismatch or a skipped
  /// declared check).
  final int ineligible;

  /// Whether every attempt in this arm was priced.
  final bool costComplete;

  /// Total spend across every attempt (failures and auxiliary calls included),
  /// or null when any attempt was unpriced.
  final int? totalCostMicros;

  /// Total tokens by cache role.
  final EvaluationTokenBreakdown tokens;

  /// Total cost by role.
  final EvaluationCostRoles cost;

  /// Total recovery and context-management metrics.
  final EvaluationAttemptMetrics metrics;

  /// Mean wall-clock duration per attempt, ms.
  final double meanLatencyMs;

  /// Median attempt duration, ms.
  final double p50LatencyMs;

  /// 95th-percentile attempt duration, ms.
  final double p95LatencyMs;

  /// Verified-success rate per cache stratum.
  final Map<CacheStratum, double> perStratumSuccessRate;

  /// Verified-success rate over every observed attempt, including failures.
  double get successRate => attempts > 0 ? verifiedSuccesses / attempts : 0;

  /// The headline metric: micro-USD of all attempts over verified successes.
  ///
  /// Null when nothing was verified successful (an infinite cost is not a
  /// number) or when any attempt was unpriced (a partial total would flatter
  /// the arm).
  double? get costPerVerifiedSuccessMicros {
    final micros = totalCostMicros;
    if (micros == null || verifiedSuccesses <= 0) {
      return null;
    }
    return micros / verifiedSuccesses;
  }

  /// Mean re-reads per attempt.
  double get meanReReads => attempts > 0 ? metrics.reReads / attempts : 0;

  /// Mean physical provider requests per attempt.
  double get meanProviderCalls =>
      attempts > 0 ? metrics.providerCalls / attempts : 0;

  /// Mean loop turns per attempt.
  double get meanRoundTrips =>
      attempts > 0 ? metrics.modelRoundTrips / attempts : 0;

  /// Mean compaction passes per attempt.
  double get meanCompactions =>
      attempts > 0 ? metrics.compactions / attempts : 0;

  /// Mean masked observations per attempt.
  double get meanMasks =>
      attempts > 0 ? metrics.maskedObservations / attempts : 0;

  /// Mean snapshot frames per attempt.
  double get meanSnapshots =>
      attempts > 0 ? metrics.snapshotFrames / attempts : 0;

  /// Mean invalid tool calls per attempt.
  double get meanInvalidToolCalls =>
      attempts > 0 ? metrics.invalidToolCalls / attempts : 0;

  /// Mean failed tool calls per attempt.
  double get meanFailedToolCalls =>
      attempts > 0 ? metrics.failedToolCalls / attempts : 0;

  /// Mean patch failures per attempt.
  double get meanPatchFailures =>
      attempts > 0 ? metrics.patchFailures / attempts : 0;

  /// Serializes for the report.
  Map<String, Object?> toJson() => {
    'armId': armId,
    'axis': axis.wire,
    'effective': effective.toJson(),
    'attempts': attempts,
    'completed': completed,
    'eligible': eligible,
    'ineligible': ineligible,
    'verifiedSuccesses': verifiedSuccesses,
    'harnessErrors': harnessErrors,
    'successRate': successRate,
    'costComplete': costComplete,
    'totalCostMicros': totalCostMicros,
    'costPerVerifiedSuccessMicros': costPerVerifiedSuccessMicros,
    'tokens': tokens.toJson(),
    'cost': cost.toJson(),
    'metrics': metrics.toJson(),
    'meanLatencyMs': meanLatencyMs,
    'p50LatencyMs': p50LatencyMs,
    'p95LatencyMs': p95LatencyMs,
    'perStratumSuccessRate': {
      for (final e in perStratumSuccessRate.entries) e.key.wire: e.value,
    },
  };
}

/// One arm's behaviour on one task.
class EvaluationTaskOutcome {
  /// Creates an [EvaluationTaskOutcome].
  const EvaluationTaskOutcome({
    required this.taskId,
    required this.taskKind,
    required this.armId,
    required this.attempts,
    required this.eligible,
    required this.verifiedSuccesses,
    required this.harnessErrors,
    required this.costComplete,
    required this.totalCostMicros,
  });

  /// Builds from the attempts of one (task, arm).
  factory EvaluationTaskOutcome.fromAttempts({
    required String taskId,
    required EvaluationTaskKind taskKind,
    required String armId,
    required List<EvaluationAttempt> attempts,
  }) {
    var passed = 0;
    var errors = 0;
    var eligible = 0;
    var costComplete = true;
    var costMicros = 0;
    for (final attempt in attempts) {
      if (attempt.verifiedSuccess) {
        passed++;
      }
      if (!attempt.completed) {
        errors++;
      }
      if (attempt.completed && attempt.identityMismatches.isEmpty) {
        eligible++;
      }
      final attemptCost = attempt.attemptCostMicros;
      if (attemptCost == null) {
        costComplete = false;
      } else {
        costMicros += attemptCost;
      }
    }
    return EvaluationTaskOutcome(
      taskId: taskId,
      taskKind: taskKind,
      armId: armId,
      attempts: attempts.length,
      eligible: eligible,
      verifiedSuccesses: passed,
      harnessErrors: errors,
      costComplete: costComplete && attempts.isNotEmpty,
      totalCostMicros: costComplete && attempts.isNotEmpty ? costMicros : null,
    );
  }

  /// The task.
  final String taskId;

  /// The task class.
  final EvaluationTaskKind taskKind;

  /// The arm.
  final String armId;

  /// Attempts observed.
  final int attempts;

  /// Attempts usable as evidence.
  final int eligible;

  /// Verified successes.
  final int verifiedSuccesses;

  /// Harness faults.
  final int harnessErrors;

  /// Whether every attempt on this (task, arm) was priced.
  final bool costComplete;

  /// Total spend in micro-USD, or null when incomplete.
  final int? totalCostMicros;

  /// Verified-success rate over every observed attempt, including failures.
  double get successRate => attempts > 0 ? verifiedSuccesses / attempts : 0;

  /// Cost per verified success in micro-USD, or null.
  double? get costPerSuccessMicros {
    final micros = totalCostMicros;
    if (micros == null || verifiedSuccesses <= 0) {
      return null;
    }
    return micros / verifiedSuccesses;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'taskKind': taskKind.wire,
    'armId': armId,
    'attempts': attempts,
    'eligible': eligible,
    'verifiedSuccesses': verifiedSuccesses,
    'harnessErrors': harnessErrors,
    'costComplete': costComplete,
    'totalCostMicros': totalCostMicros,
    'successRate': successRate,
    'costPerSuccessMicros': costPerSuccessMicros,
  };
}

/// The kind of per-task regression a treatment showed against the baseline.
enum RegressionKind {
  /// The baseline solved the task and the treatment did not (or less often).
  qualityLoss('quality_loss'),

  /// Quality held but the treatment cost materially more per success.
  costRegression('cost_regression'),

  /// The treatment faulted in the harness where the baseline did not.
  harnessError('harness_error');

  const RegressionKind(this.wire);

  /// Stable wire string.
  final String wire;

  /// Sentence-case label.
  String get label => switch (this) {
    RegressionKind.qualityLoss => 'Quality loss',
    RegressionKind.costRegression => 'Cost regression',
    RegressionKind.harnessError => 'Harness error',
  };
}

/// One task where a treatment arm lost ground against the baseline.
class TaskRegression {
  /// Creates a [TaskRegression].
  const TaskRegression({
    required this.taskId,
    required this.taskKind,
    required this.baselineArmId,
    required this.treatmentArmId,
    required this.kind,
    required this.baselineSuccessRate,
    required this.treatmentSuccessRate,
    this.baselineCostPerSuccessMicros,
    this.treatmentCostPerSuccessMicros,
    this.detail = '',
  });

  /// The task.
  final String taskId;

  /// Its class.
  final EvaluationTaskKind taskKind;

  /// The arm being compared against.
  final String baselineArmId;

  /// The arm being compared.
  final String treatmentArmId;

  /// What kind of regression.
  final RegressionKind kind;

  /// Baseline success rate on this task.
  final double baselineSuccessRate;

  /// Treatment success rate on this task.
  final double treatmentSuccessRate;

  /// Baseline cost per verified success, when it verified any.
  final double? baselineCostPerSuccessMicros;

  /// Treatment cost per verified success, when it verified any.
  final double? treatmentCostPerSuccessMicros;

  /// Human-readable detail.
  final String detail;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'taskKind': taskKind.wire,
    'baselineArmId': baselineArmId,
    'treatmentArmId': treatmentArmId,
    'kind': kind.wire,
    'baselineSuccessRate': baselineSuccessRate,
    'treatmentSuccessRate': treatmentSuccessRate,
    if (baselineCostPerSuccessMicros != null)
      'baselineCostPerSuccessMicros': baselineCostPerSuccessMicros,
    if (treatmentCostPerSuccessMicros != null)
      'treatmentCostPerSuccessMicros': treatmentCostPerSuccessMicros,
    if (detail.isNotEmpty) 'detail': detail,
  };
}

/// The quality verdict for one treatment arm against the baseline.
enum QualityVerdict {
  /// The one-sided bound is entirely above zero: quality improved.
  superior('superior'),

  /// The one-sided bound clears the −margin: a loss as large as the margin is
  /// excluded at the plan's alpha.
  nonInferior('non_inferior'),

  /// The upper bound lies below the negative prespecified margin: a regression
  /// has been demonstrated, not merely a failure to establish non-inferiority.
  inferior('inferior'),

  /// Missing evidence or bounds that do not establish either conclusion.
  inconclusive('inconclusive');

  const QualityVerdict(this.wire);

  /// Stable wire string.
  final String wire;

  /// Sentence-case label.
  String get label => switch (this) {
    QualityVerdict.superior => 'Superior',
    QualityVerdict.nonInferior => 'Non-inferior',
    QualityVerdict.inferior => 'Inferior',
    QualityVerdict.inconclusive => 'Inconclusive',
  };
}

/// What the campaign recommends doing with the quality default.
enum AdoptionRecommendation {
  /// Keep the pinned quality default (the only safe default).
  keepQualityDefault('keep_quality_default'),

  /// Adopt the treatment where the evidence supports it.
  adoptTreatment('adopt_treatment'),

  /// Not enough evidence either way.
  inconclusive('inconclusive');

  const AdoptionRecommendation(this.wire);

  /// Stable wire string.
  final String wire;

  /// Sentence-case label.
  String get label => switch (this) {
    AdoptionRecommendation.keepQualityDefault => 'Keep quality default',
    AdoptionRecommendation.adoptTreatment => 'Adopt treatment',
    AdoptionRecommendation.inconclusive => 'Inconclusive',
  };
}

/// The paired quality + cost verdict for one treatment arm.
///
/// Quality uses one-sided task-cluster bounds on the treatment-minus-baseline
/// verified-success difference. Repeated pairs on one task do not create new
/// independent task evidence.
class NonInferiorityVerdict {
  /// Creates a [NonInferiorityVerdict].
  const NonInferiorityVerdict({
    required this.baselineArmId,
    required this.treatmentArmId,
    required this.pairs,
    required this.expectedPairs,
    required this.effectiveTaskCount,
    required this.baselineOnlyWins,
    required this.treatmentOnlyWins,
    required this.bothPass,
    required this.bothFail,
    required this.observedDelta,
    required this.lowerBound,
    required this.upperBound,
    required this.margin,
    required this.alpha,
    required this.verdict,
    required this.costRatio,
    required this.maxCostRatio,
    required this.recommendation,
    required this.blockedTaskIds,
    required this.method,
    required this.reason,
  });

  /// The arm compared against.
  final String baselineArmId;

  /// The arm under test.
  final String treatmentArmId;

  /// Matched pairs found.
  final int pairs;

  /// Matched pairs the plan required.
  final int expectedPairs;

  /// Distinct tasks contributing matched pairs to the cluster-level bound.
  final int effectiveTaskCount;

  /// Pairs the baseline passed and the treatment failed.
  final int baselineOnlyWins;

  /// Pairs the treatment passed and the baseline failed.
  final int treatmentOnlyWins;

  /// Pairs both passed.
  final int bothPass;

  /// Pairs both failed.
  final int bothFail;

  /// Macro-average of per-task paired success-rate differences.
  final double observedDelta;

  /// One-sided (1 − alpha) lower bound on the task-level mean difference.
  final double lowerBound;

  /// One-sided (1 − alpha) upper bound on the task-level mean difference.
  final double upperBound;

  /// The relative non-inferiority margin the plan set.
  final double margin;

  /// The significance level the plan set.
  final double alpha;

  /// The quality verdict.
  final QualityVerdict verdict;

  /// Treatment cost over baseline cost, or null when either arm's cost is
  /// incomplete or the pair is not comparable.
  final double? costRatio;

  /// The largest cost ratio the plan would accept for adoption.
  final double maxCostRatio;

  /// What to do with the quality default.
  final AdoptionRecommendation recommendation;

  /// Tasks whose individual outcome blocks adoption regardless of the
  /// aggregate verdict.
  final List<String> blockedTaskIds;

  /// Which statistical method produced the bound.
  final String method;

  /// Why the verdict came out this way.
  final String reason;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'baselineArmId': baselineArmId,
    'treatmentArmId': treatmentArmId,
    'pairs': pairs,
    'expectedPairs': expectedPairs,
    'effectiveTaskCount': effectiveTaskCount,
    'baselineOnlyWins': baselineOnlyWins,
    'treatmentOnlyWins': treatmentOnlyWins,
    'bothPass': bothPass,
    'bothFail': bothFail,
    'observedDelta': observedDelta,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
    'margin': margin,
    'alpha': alpha,
    'verdict': verdict.wire,
    'costRatio': costRatio,
    'maxCostRatio': maxCostRatio,
    'recommendation': recommendation.wire,
    'blockedTaskIds': blockedTaskIds,
    'method': method,
    'reason': reason,
  };
}

/// The whole paired campaign: pinned manifest + plan + every attempt, plus the
/// derived summaries, regressions, verdicts and the honest list of unknowns.
class EvaluationReport {
  /// Creates an [EvaluationReport].
  const EvaluationReport({
    required this.manifest,
    required this.planId,
    required this.seed,
    required this.executionMode,
    required this.generatedAtEpochMs,
    required this.armSummaries,
    required this.taskOutcomes,
    required this.regressions,
    required this.verdicts,
    required this.caveats,
    required this.planViolations,
    required this.unknowns,
    required this.attempts,
    required this.expectedTrials,
    required this.expectedPairs,
    required this.coverageComplete,
    this.routePolicyId,
    this.memoryExperimentId,
  });

  /// The pinned manifest every attempt shared.
  final EvaluationManifest manifest;

  /// The plan id.
  final String planId;

  /// The campaign seed.
  final int seed;

  /// Live or replay.
  final EvaluationExecutionMode executionMode;

  /// When the report was generated, epoch ms.
  final int generatedAtEpochMs;

  /// Per-arm aggregates.
  final List<EvaluationArmSummary> armSummaries;

  /// Per-(task, arm) outcomes.
  final List<EvaluationTaskOutcome> taskOutcomes;

  /// Per-task regressions the treatments showed.
  final List<TaskRegression> regressions;

  /// Paired quality/cost verdicts per treatment arm.
  final List<NonInferiorityVerdict> verdicts;

  /// Account/cache caveats carried from the plan.
  final List<EvaluationCaveat> caveats;

  /// Plan validation problems recorded at run time (adoption is blocked when
  /// non-empty).
  final List<String> planViolations;

  /// Everything the campaign could not establish.
  final List<String> unknowns;

  /// The routing policy declared by the plan, if any.
  final String? routePolicyId;

  /// The memory experiment declared by the plan, if any.
  final String? memoryExperimentId;

  /// Whether each planned task/arm/stratum/repetition produced an attempt.
  final bool coverageComplete;

  /// Every attempt, in execution order.
  final List<EvaluationAttempt> attempts;

  /// Trials the plan required.
  final int expectedTrials;

  /// Matched pairs the plan required per treatment arm.
  final int expectedPairs;

  /// Whether any model was called to produce this report.
  bool get liveModelCalls =>
      executionMode == EvaluationExecutionMode.live &&
      attempts.any((a) => a.live);

  /// The baseline (quality default) arm summary, when present.
  EvaluationArmSummary? get baselineSummary {
    for (final summary in armSummaries) {
      if (summary.axis == EvaluationAxis.baseline) {
        return summary;
      }
    }
    return null;
  }

  /// The recommendation this campaign supports for the quality default.
  ///
  /// Any plan violation, incomplete coverage, a per-task quality regression, an
  /// inconclusive verdict, incomplete cost evidence, or a treatment that is not
  /// actually cheaper all keep the default.
  AdoptionRecommendation get overallRecommendation {
    if (planViolations.isNotEmpty || !coverageComplete) {
      return AdoptionRecommendation.keepQualityDefault;
    }
    final adoptable = [
      for (final v in verdicts)
        if (v.recommendation == AdoptionRecommendation.adoptTreatment) v,
    ];
    if (adoptable.isEmpty) {
      return verdicts.isEmpty
          ? AdoptionRecommendation.inconclusive
          : AdoptionRecommendation.keepQualityDefault;
    }
    return AdoptionRecommendation.adoptTreatment;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'manifest': manifest.toJson(),
    'planId': planId,
    'seed': seed,
    'executionMode': executionMode.wire,
    'liveModelCalls': liveModelCalls,
    'generatedAtEpochMs': generatedAtEpochMs,
    'coverageComplete': coverageComplete,
    'expectedTrials': expectedTrials,
    'expectedPairs': expectedPairs,
    'armSummaries': [for (final s in armSummaries) s.toJson()],
    'taskOutcomes': [for (final o in taskOutcomes) o.toJson()],
    'regressions': [for (final r in regressions) r.toJson()],
    'verdicts': [for (final v in verdicts) v.toJson()],
    'caveats': [for (final c in caveats) c.toJson()],
    'planViolations': planViolations,
    'unknowns': unknowns,
    'recommendation': overallRecommendation.wire,
    if (routePolicyId != null) 'routePolicyId': routePolicyId,
    if (memoryExperimentId != null) 'memoryExperimentId': memoryExperimentId,
    'attempts': [for (final a in attempts) a.toJson()],
  };
}

/// Builds an [EvaluationReport] from raw attempts: the aggregation, per-task
/// regression detection and paired non-inferiority arithmetic live here, pure
/// and testable.
class EvaluationReportBuilder {
  /// Creates an [EvaluationReportBuilder].
  const EvaluationReportBuilder({
    this.costRegressionRatio = 0.2,
    this.costRegressionFloorMicros = microsPerCent,
  });

  /// How much more expensive per success a treatment may be before
  /// quality-held pairs are reported as a cost regression (relative).
  final double costRegressionRatio;

  /// Absolute micro-USD floor under which a cost difference is noise.
  final int costRegressionFloorMicros;

  /// Builds the report.
  EvaluationReport build({
    required EvaluationManifest manifest,
    required EvaluationPlan plan,
    required List<EvaluationTask> tasks,
    required List<EvaluationAttempt> attempts,
    required int generatedAtEpochMs,
    List<String> extraUnknowns = const [],
    List<EvaluationCaveat> extraCaveats = const [],
  }) {
    final byArm = <String, List<EvaluationAttempt>>{};
    for (final attempt in attempts) {
      byArm.putIfAbsent(attempt.armId, () => []).add(attempt);
    }

    final armSummaries = <EvaluationArmSummary>[
      for (final arm in plan.arms)
        EvaluationArmSummary.fromAttempts(
          armId: arm.id,
          axis: arm.axis,
          effective: EvaluationEffectiveConfig.forArm(manifest, arm),
          attempts: byArm[arm.id] ?? const [],
        ),
    ];

    final taskOutcomes = <EvaluationTaskOutcome>[];
    for (final task in tasks) {
      for (final arm in plan.arms) {
        final group = [
          for (final a in byArm[arm.id] ?? const <EvaluationAttempt>[])
            if (a.taskId == task.id) a,
        ];
        if (group.isEmpty) {
          continue;
        }
        taskOutcomes.add(
          EvaluationTaskOutcome.fromAttempts(
            taskId: task.id,
            taskKind: task.kind,
            armId: arm.id,
            attempts: group,
          ),
        );
      }
    }

    final plannedTrials = plan.schedule(tasks);
    final expectedTrials = plannedTrials.length;
    final expectedPairs = _expectedPairs(plan, tasks);
    final plannedKeys = {
      for (final trial in plannedTrials)
        '${trial.taskId}\u0000${trial.armId}\u0000${trial.stratum.wire}'
            '\u0000${trial.repetition}',
    };
    final observedKeys = {
      for (final attempt in attempts)
        '${attempt.taskId}\u0000${attempt.armId}\u0000${attempt.stratum.wire}'
            '\u0000${attempt.repetition}',
    };
    final missingTrials = plannedKeys.difference(observedKeys).length;
    // Coverage means the PLANNED trials ran — not merely "some attempts
    // happened". A campaign that skipped a stratum, an arm or a repetition has
    // unequal arms and cannot support a savings claim.
    final coverageComplete = plannedKeys.isNotEmpty && missingTrials == 0;

    final baseline = plan.baselineArm;
    final regressions = <TaskRegression>[];
    final verdicts = <NonInferiorityVerdict>[];
    if (baseline != null) {
      for (final arm in plan.arms) {
        if (arm.isBaseline) {
          continue;
        }
        regressions.addAll(
          _regressions(
            baseline: baseline,
            treatment: arm,
            tasks: tasks,
            taskOutcomes: taskOutcomes,
          ),
        );
        verdicts.add(
          _verdict(
            plan: plan,
            baseline: baseline,
            treatment: arm,
            summaries: armSummaries,
            attempts: attempts,
            regressions: regressions,
            expectedPairs: expectedPairs,
            coverageComplete: coverageComplete,
          ),
        );
      }
    }

    return EvaluationReport(
      manifest: manifest,
      planId: plan.id,
      seed: plan.seed,
      executionMode: attempts.isEmpty
          ? EvaluationExecutionMode.live
          : attempts.first.executionMode,
      generatedAtEpochMs: generatedAtEpochMs,
      armSummaries: armSummaries,
      taskOutcomes: taskOutcomes,
      regressions: regressions,
      verdicts: verdicts,
      caveats: [...plan.caveats, ...extraCaveats],
      coverageComplete: coverageComplete,
      planViolations: plan.violations(tasks),
      unknowns: [
        ..._unknowns(
          plan: plan,
          baseline: baseline,
          attempts: attempts,
          verdicts: verdicts,
          expectedTrials: expectedTrials,
          missingTrials: missingTrials,
        ),
        ...extraUnknowns,
      ],
      attempts: attempts,
      expectedTrials: expectedTrials,
      expectedPairs: expectedPairs,
      routePolicyId: plan.routePolicy?.id,
      memoryExperimentId: plan.memoryExperiment?.id,
    );
  }

  /// Matched pairs the plan requires: one per (task, stratum, repetition).
  static int _expectedPairs(EvaluationPlan plan, List<EvaluationTask> tasks) {
    var pairs = 0;
    for (final spec in plan.strata) {
      pairs += tasks.length * spec.repetitions;
    }
    return pairs;
  }

  List<TaskRegression> _regressions({
    required EvaluationArm baseline,
    required EvaluationArm treatment,
    required List<EvaluationTask> tasks,
    required List<EvaluationTaskOutcome> taskOutcomes,
  }) {
    final regressions = <TaskRegression>[];
    for (final task in tasks) {
      final base = _outcome(taskOutcomes, task.id, baseline.id);
      final treat = _outcome(taskOutcomes, task.id, treatment.id);
      if (base == null || treat == null) {
        // A task one arm never ran cannot be judged, and the missing coverage
        // is reported separately rather than silently skipped.
        continue;
      }
      if (treat.successRate < base.successRate) {
        regressions.add(
          TaskRegression(
            taskId: task.id,
            taskKind: task.kind,
            baselineArmId: baseline.id,
            treatmentArmId: treatment.id,
            kind: RegressionKind.qualityLoss,
            baselineSuccessRate: base.successRate,
            treatmentSuccessRate: treat.successRate,
            baselineCostPerSuccessMicros: base.costPerSuccessMicros,
            treatmentCostPerSuccessMicros: treat.costPerSuccessMicros,
            detail:
                '${base.verifiedSuccesses}/${base.attempts} vs '
                '${treat.verifiedSuccesses}/${treat.attempts} verified',
          ),
        );
        continue;
      }
      final baseCost = base.costPerSuccessMicros;
      final treatCost = treat.costPerSuccessMicros;
      if (baseCost != null &&
          treatCost != null &&
          treatCost - baseCost > costRegressionFloorMicros &&
          baseCost > 0 &&
          (treatCost - baseCost) / baseCost > costRegressionRatio) {
        regressions.add(
          TaskRegression(
            taskId: task.id,
            taskKind: task.kind,
            baselineArmId: baseline.id,
            treatmentArmId: treatment.id,
            kind: RegressionKind.costRegression,
            baselineSuccessRate: base.successRate,
            treatmentSuccessRate: treat.successRate,
            baselineCostPerSuccessMicros: baseCost,
            treatmentCostPerSuccessMicros: treatCost,
            detail:
                'cost/success ${_usd(baseCost)} → ${_usd(treatCost)} at equal '
                'quality',
          ),
        );
      }
      if (treat.harnessErrors > 0 && base.harnessErrors < treat.harnessErrors) {
        regressions.add(
          TaskRegression(
            taskId: task.id,
            taskKind: task.kind,
            baselineArmId: baseline.id,
            treatmentArmId: treatment.id,
            kind: RegressionKind.harnessError,
            baselineSuccessRate: base.successRate,
            treatmentSuccessRate: treat.successRate,
            detail:
                '${treat.harnessErrors} harness fault(s) vs '
                '${base.harnessErrors} baseline',
          ),
        );
      }
    }
    return regressions;
  }

  NonInferiorityVerdict _verdict({
    required EvaluationPlan plan,
    required EvaluationArm baseline,
    required EvaluationArm treatment,
    required List<EvaluationArmSummary> summaries,
    required List<EvaluationAttempt> attempts,
    required List<TaskRegression> regressions,
    required int expectedPairs,
    required bool coverageComplete,
  }) {
    final baseByPair = <String, EvaluationAttempt>{};
    final treatByPair = <String, EvaluationAttempt>{};
    for (final attempt in attempts) {
      // An ineligible attempt is NOT evidence: quality is judged only on
      // attempts whose declared checks all ran and whose pin held.
      if (!attempt.completed ||
          !attempt.verificationComplete ||
          attempt.identityMismatches.isNotEmpty) {
        continue;
      }
      if (attempt.armId == baseline.id) {
        baseByPair[attempt.pairKey] = attempt;
      } else if (attempt.armId == treatment.id) {
        treatByPair[attempt.pairKey] = attempt;
      }
    }
    var pairs = 0;
    var bothPass = 0;
    var bothFail = 0;
    var bOnly = 0;
    var tOnly = 0;
    final taskSums = <String, int>{};
    final taskPairCounts = <String, int>{};
    for (final entry in baseByPair.entries) {
      final treatmentAttempt = treatByPair[entry.key];
      if (treatmentAttempt == null) {
        continue;
      }
      pairs++;
      final basePassed = entry.value.verifiedSuccess;
      final treatmentPassed = treatmentAttempt.verifiedSuccess;
      final difference = (treatmentPassed ? 1 : 0) - (basePassed ? 1 : 0);
      final taskId = entry.value.taskId;
      taskSums[taskId] = (taskSums[taskId] ?? 0) + difference;
      taskPairCounts[taskId] = (taskPairCounts[taskId] ?? 0) + 1;
      if (basePassed && treatmentPassed) {
        bothPass++;
      } else if (!basePassed && !treatmentPassed) {
        bothFail++;
      } else if (basePassed) {
        bOnly++;
      } else {
        tOnly++;
      }
    }
    final taskCount = taskSums.length;
    var delta = 0.0;
    for (final entry in taskSums.entries) {
      delta += entry.value / taskPairCounts[entry.key]!;
    }
    if (taskCount > 0) {
      delta /= taskCount;
    }
    final bound = _taskClusterBound(
      delta: delta,
      tasks: taskCount,
      alpha: plan.alpha,
    );

    final baseSummary = _summaryById(summaries, baseline.id);
    final treatSummary = _summaryById(summaries, treatment.id);
    // A cost ratio is only meaningful when BOTH arms priced every attempt and
    // the campaign actually ran to its planned coverage.
    final costComparable =
        coverageComplete &&
        (baseSummary?.costComplete ?? false) &&
        (treatSummary?.costComplete ?? false) &&
        (baseSummary?.totalCostMicros ?? 0) > 0;
    final costRatio = costComparable
        ? treatSummary!.totalCostMicros! / baseSummary!.totalCostMicros!
        : null;

    final blocked = <String>{
      for (final regression in regressions)
        if (regression.treatmentArmId == treatment.id &&
            regression.kind == RegressionKind.qualityLoss)
          regression.taskId,
    }.toList()..sort();

    final requiredPairs = plan.minPairs > expectedPairs
        ? plan.minPairs
        : expectedPairs;
    QualityVerdict verdict;
    var reason = '';
    if (!coverageComplete) {
      verdict = QualityVerdict.inconclusive;
      reason =
          'the campaign is incomplete ($pairs of $expectedPairs planned pairs '
          'present), so no quality verdict is allowed';
    } else if (pairs < requiredPairs) {
      verdict = QualityVerdict.inconclusive;
      reason =
          'only $pairs usable matched pair(s); $requiredPairs required before '
          'a quality verdict is allowed';
    } else if (taskCount == 0 ||
        !plan.alpha.isFinite ||
        plan.alpha <= 0 ||
        plan.alpha >= 1) {
      verdict = QualityVerdict.inconclusive;
      reason = 'no usable task-level quality bound is available';
    } else if (bound.lower > 0) {
      verdict = QualityVerdict.superior;
      reason =
          'the one-sided ${_pct(1 - plan.alpha)} task-cluster lower bound '
          '${_pct(bound.lower)} is above zero over $taskCount distinct task(s)';
    } else if (bound.lower > -plan.nonInferiorityMargin) {
      verdict = QualityVerdict.nonInferior;
      reason =
          'the one-sided ${_pct(1 - plan.alpha)} task-cluster lower bound '
          '${_pct(bound.lower)} clears the −${_pct(plan.nonInferiorityMargin)} '
          'margin over $taskCount distinct task(s) ($pairs matched pairs)';
    } else if (bound.upper < -plan.nonInferiorityMargin) {
      verdict = QualityVerdict.inferior;
      reason =
          'the one-sided ${_pct(1 - plan.alpha)} task-cluster upper bound '
          '${_pct(bound.upper)} is below the −'
          '${_pct(plan.nonInferiorityMargin)} margin over $taskCount '
          'distinct task(s)';
    } else {
      verdict = QualityVerdict.inconclusive;
      reason =
          'the task-cluster bounds ${_pct(bound.lower)} to '
          '${_pct(bound.upper)} do not establish non-inferiority or a '
          'regression against the −${_pct(plan.nonInferiorityMargin)} '
          'margin over $taskCount distinct task(s)';
    }

    AdoptionRecommendation recommendation;
    if (verdict == QualityVerdict.inconclusive) {
      recommendation = AdoptionRecommendation.inconclusive;
    } else if (verdict == QualityVerdict.inferior) {
      recommendation = AdoptionRecommendation.keepQualityDefault;
    } else if (blocked.isNotEmpty) {
      recommendation = AdoptionRecommendation.keepQualityDefault;
      reason =
          '$reason; blocked by per-task quality regression on '
          '${blocked.join(', ')}';
    } else if (costRatio == null) {
      recommendation = AdoptionRecommendation.keepQualityDefault;
      reason =
          '$reason; cost is incomplete or incomparable, so no savings claim '
          'is possible and the default is retained';
    } else if (costRatio >= plan.maxCostRatio) {
      recommendation = AdoptionRecommendation.keepQualityDefault;
      reason =
          '$reason; cost ratio ${costRatio.toStringAsFixed(3)} is not below '
          'the ${plan.maxCostRatio.toStringAsFixed(2)} ceiling, so there is no '
          'reason to move off the quality default';
    } else {
      recommendation = AdoptionRecommendation.adoptTreatment;
    }

    return NonInferiorityVerdict(
      baselineArmId: baseline.id,
      treatmentArmId: treatment.id,
      pairs: pairs,
      expectedPairs: expectedPairs,
      effectiveTaskCount: taskCount,
      baselineOnlyWins: bOnly,
      treatmentOnlyWins: tOnly,
      bothPass: bothPass,
      bothFail: bothFail,
      observedDelta: delta,
      lowerBound: bound.lower,
      upperBound: bound.upper,
      margin: plan.nonInferiorityMargin,
      alpha: plan.alpha,
      verdict: verdict,
      costRatio: costRatio,
      maxCostRatio: plan.maxCostRatio,
      recommendation: recommendation,
      blockedTaskIds: blocked,
      method: bound.method,
      reason: reason,
    );
  }

  List<String> _unknowns({
    required EvaluationPlan plan,
    required EvaluationArm? baseline,
    required List<EvaluationAttempt> attempts,
    required List<NonInferiorityVerdict> verdicts,
    required int expectedTrials,
    required int missingTrials,
  }) {
    final unknowns = <String>[];
    if (baseline == null) {
      unknowns.add('no baseline (quality default) arm ran');
    }
    if (attempts.isEmpty) {
      unknowns.add('no attempts were recorded');
    } else if (missingTrials > 0) {
      unknowns.add(
        'coverage is incomplete: $missingTrials of $expectedTrials planned '
        'trial(s) never ran, so the arms are not comparable and no quality or '
        'savings verdict is allowed',
      );
    }
    final route = plan.routePolicy;
    if (route != null && !route.enabled) {
      unknowns.add(
        'routing policy "${route.id}" was not opted in, so no '
        'routed trial ran',
      );
    }
    final memory = plan.memoryExperiment;
    if (memory != null && !memory.enabled) {
      unknowns.add('memory experiment "${memory.id}" was not opted in');
    }
    final faulted = attempts.where((a) => !a.completed).length;
    if (faulted > 0) {
      unknowns.add(
        '$faulted attempt(s) faulted in the harness and are excluded from '
        'quality evidence',
      );
    }
    final skipped = attempts
        .where((a) => a.completed && !a.verificationComplete)
        .length;
    if (skipped > 0) {
      unknowns.add(
        '$skipped attempt(s) did not run every declared authoritative check, '
        'so their success is unverified',
      );
    }
    final mismatched = attempts
        .where((a) => a.identityMismatches.isNotEmpty)
        .length;
    if (mismatched > 0) {
      unknowns.add(
        '$mismatched attempt(s) contradicted the campaign pin (served model, '
        'tool surface or CLI version) and are excluded from evidence',
      );
    }
    final unpriced = attempts.where((a) => !a.costComparable).length;
    if (unpriced > 0) {
      unknowns.add(
        '$unpriced attempt(s) were not priced, so no savings claim can be made '
        'from this campaign',
      );
    }
    // A memory arm that never rewrote history did not exercise its policy.
    for (final arm in plan.arms) {
      final memoryArm =
          arm.memoryPolicy != null &&
          arm.memoryPolicy != MemoryPolicyMode.textCurrent;
      if (!memoryArm) {
        continue;
      }
      final armAttempts = attempts.where((a) => a.armId == arm.id).toList();
      if (armAttempts.isEmpty) {
        continue;
      }
      if (!armAttempts.any((a) => a.interventionExercised)) {
        unknowns.add(
          'arm "${arm.id}" asked for ${arm.memoryPolicy!.wire} but no attempt '
          'recorded a context window plus a fold, mask or snapshot: the policy '
          'was not exercised and this arm cannot be compared',
        );
      }
      if (plan.memoryExperiment?.mode == MemoryPolicyMode.snapshotImages &&
          !armAttempts.any((a) => a.metrics.renderedSnapshots)) {
        unknowns.add(
          'arm "${arm.id}" requested snapshot compaction but no attempt '
          'rendered a snapshot page',
        );
      }
    }
    final overlap = plan.overlapExperiment;
    if (overlap != null &&
        overlap.enabled &&
        !attempts.any((a) => a.metrics.parallelWaves > 0)) {
      unknowns.add(
        'the tool-overlap arm ran without a recorded parallel wave, so the '
        'scheduling change may not have been exercised',
      );
    }
    if (attempts.any((a) => a.latency.transportTtfbMs == null)) {
      unknowns.add(
        'transport TTFB is unobserved for some attempts (the adapter may '
        'hide the wire, or the first main request may lack a boundary)',
      );
    }
    if (attempts.any((a) => a.latency.providerTotalMs == null)) {
      unknowns.add(
        'provider-only latency is unavailable for some attempt(s); totalMs is '
        'attempt wall clock and must not be read as serving time',
      );
    }
    for (final verdict in verdicts) {
      if (verdict.verdict == QualityVerdict.inconclusive) {
        unknowns.add('${verdict.treatmentArmId}: ${verdict.reason}');
      }
    }
    if (plan.strata.any((s) => s.stratum == CacheStratum.postIdle)) {
      unknowns.add(
        'post-idle results depend on provider cache expiry, which the harness '
        'cannot observe; the idle duration is a guess recorded in the plan',
      );
    }
    return unknowns;
  }

  static EvaluationTaskOutcome? _outcome(
    List<EvaluationTaskOutcome> outcomes,
    String taskId,
    String armId,
  ) {
    for (final outcome in outcomes) {
      if (outcome.taskId == taskId && outcome.armId == armId) {
        return outcome;
      }
    }
    return null;
  }

  static EvaluationArmSummary? _summaryById(
    List<EvaluationArmSummary> summaries,
    String armId,
  ) {
    for (final summary in summaries) {
      if (summary.armId == armId) {
        return summary;
      }
    }
    return null;
  }

  /// Finite-sample one-sided Hoeffding bounds across distinct tasks.
  ///
  /// Each task contributes one mean of its paired differences in [-1, 1].
  /// Repetitions within the same task affect its estimate but not the sample
  /// size. The radius sqrt(2 ln(1/alpha) / tasks) is valid without assuming
  /// within-task independence or a positive empirical variance. It presumes
  /// the distinct tasks represent independent draws from the target task
  /// population; otherwise these are descriptive bounds, not population
  /// guarantees. Clamp to the known possible difference range.
  static _PairedBound _taskClusterBound({
    required double delta,
    required int tasks,
    required double alpha,
  }) {
    const method = 'task-cluster one-sided Hoeffding, differences [-1,1]';
    if (tasks <= 0 || !alpha.isFinite || alpha <= 0 || alpha >= 1) {
      return const _PairedBound(lower: -1, upper: 1, method: method);
    }
    final radius = math.sqrt(2 * math.log(1 / alpha) / tasks);
    return _PairedBound(
      lower: math.max(-1.0, delta - radius),
      upper: math.min(1.0, delta + radius),
      method: method,
    );
  }
}

class _PairedBound {
  const _PairedBound({
    required this.lower,
    required this.upper,
    required this.method,
  });

  final double lower;
  final double upper;
  final String method;
}

EvaluationAttemptMetrics _addMetrics(
  EvaluationAttemptMetrics a,
  EvaluationAttemptMetrics b,
) => EvaluationAttemptMetrics(
  toolCalls: a.toolCalls + b.toolCalls,
  failedToolCalls: a.failedToolCalls + b.failedToolCalls,
  invalidToolCalls: a.invalidToolCalls + b.invalidToolCalls,
  repeatedFailedCalls: a.repeatedFailedCalls + b.repeatedFailedCalls,
  reReads: a.reReads + b.reReads,
  patchFailures: a.patchFailures + b.patchFailures,
  modelRoundTrips: a.modelRoundTrips + b.modelRoundTrips,
  providerCalls: a.providerCalls + b.providerCalls,
  failedProviderCalls: a.failedProviderCalls + b.failedProviderCalls,
  providerRetries: a.providerRetries + b.providerRetries,
  userTurns: a.userTurns + b.userTurns,
  compactions: a.compactions + b.compactions,
  compactionRecoveries: a.compactionRecoveries + b.compactionRecoveries,
  foldedSummaries: a.foldedSummaries + b.foldedSummaries,
  maskedObservations: a.maskedObservations + b.maskedObservations,
  snapshotFrames: a.snapshotFrames + b.snapshotFrames,
  contextWindowTokens: a.contextWindowTokens ?? b.contextWindowTokens,
  policyDenials: a.policyDenials + b.policyDenials,
  parallelWaves: a.parallelWaves + b.parallelWaves,
  initMetadataMs: a.initMetadataMs ?? b.initMetadataMs,
);

double _mean(List<int> xs) =>
    xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

double _percentile(List<int> sorted, double p) {
  if (sorted.isEmpty) {
    return 0;
  }
  final rank = (sorted.length - 1) * p;
  final lower = rank.floor();
  final upper = rank.ceil();
  if (lower == upper) {
    return sorted[lower].toDouble();
  }
  final weight = rank - lower;
  return sorted[lower] * (1 - weight) + sorted[upper] * weight;
}

String _pct(double value) => '${(value * 100).toStringAsFixed(1)}pt';

String _usd(double micros) => '\$${(micros / 1000000).toStringAsFixed(4)}';
