import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_schedule.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/task_cluster_verdict.dart';

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
      }
      if (attempt.end == EvaluationAttemptEnd.harnessFault) {
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

  /// Attempts the harness itself faulted on (`harness_fault`; an agent that
  /// stopped or a spend-ceiling stop is not a harness error).
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
      if (attempt.end == EvaluationAttemptEnd.harnessFault) {
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

  /// Harness faults (`harness_fault` only).
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
  /// The one-sided lower bound is above zero: quality improved.
  superior('superior'),

  /// The one-sided lower bound clears −margin: a loss as large as the margin
  /// is excluded (non-inferiority plans only).
  nonInferior('non_inferior'),

  /// The one-sided upper bound is below zero: a loss of any size has been
  /// demonstrated, and its size is printed.
  inferior('inferior'),

  /// Missing evidence, too few or saturated tasks, or bounds that establish
  /// nothing.
  inconclusive('inconclusive');

  const QualityVerdict(this.wire);

  /// Stable wire string.
  final String wire;

  /// Sentence-case label.
  String get label => switch (this) {
    QualityVerdict.superior => 'Superior',
    QualityVerdict.nonInferior => 'Non-inferior',
    QualityVerdict.inferior => 'Inferior',
    QualityVerdict.inconclusive => 'No decision (not enough evidence)',
  };
}

/// What the campaign recommends doing with the default.
enum AdoptionRecommendation {
  /// Keep the default: the evidence is against the treatment (it is
  /// inferior, or its cost exceeds the plan's ceiling).
  keepQualityDefault('keep_quality_default'),

  /// Adopt the treatment where the evidence supports it.
  adoptTreatment('adopt_treatment'),

  /// Not enough evidence either way: never read as a decision against the
  /// treatment.
  noDecision('no_decision');

  const AdoptionRecommendation(this.wire);

  /// Stable wire string.
  final String wire;

  /// Sentence-case label.
  String get label => switch (this) {
    AdoptionRecommendation.keepQualityDefault => 'Keep the default',
    AdoptionRecommendation.adoptTreatment => 'Adopt treatment',
    AdoptionRecommendation.noDecision => 'No decision (not enough evidence)',
  };
}

/// A planned task the verdict could not use, and why.
class DroppedTask {
  /// Creates a [DroppedTask].
  const DroppedTask({required this.taskId, required this.reason});

  /// The task.
  final String taskId;

  /// Why it was dropped (not run, or which arm missed which repetitions).
  final String reason;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {'taskId': taskId, 'reason': reason};
}

/// The paired quality and cost verdict for one treatment arm.
///
/// Quality is the task-clustered one-sided paired t-test on per-task mean
/// differences of the plan's primary outcome, with the exact sign-flip test
/// beside it: a claim needs both. Repetitions sharpen a task's difference
/// and never count as more tasks.
class NonInferiorityVerdict {
  /// Creates a [NonInferiorityVerdict].
  const NonInferiorityVerdict({
    required this.baselineArmId,
    required this.treatmentArmId,
    required this.hypothesis,
    required this.primaryOutcome,
    required this.pairs,
    required this.expectedPairs,
    required this.tasksPlanned,
    required this.effectiveTaskCount,
    required this.informativeTasks,
    required this.repetitions,
    required this.droppedTasks,
    required this.baselineOnlyWins,
    required this.treatmentOnlyWins,
    required this.bothPass,
    required this.bothFail,
    required this.observedDelta,
    required this.standardDeviation,
    required this.lowerBound,
    required this.upperBound,
    required this.tStatistic,
    required this.degreesOfFreedom,
    required this.pValue,
    required this.signFlipP,
    required this.minimumDetectableEffect,
    required this.margin,
    required this.alpha,
    required this.verdict,
    required this.costRatio,
    required this.maxCostRatio,
    required this.recommendation,
    required this.method,
    required this.reason,
    required this.stoppedAtInterim,
    required this.expectedChanceLosses,
  });

  /// The arm compared against.
  final String baselineArmId;

  /// The arm under test.
  final String treatmentArmId;

  /// What the plan asked.
  final EvaluationHypothesis hypothesis;

  /// What attempts were scored on.
  final EvaluationOutcomeMeasure primaryOutcome;

  /// Repetition pairs (same task, stratum and repetition, both scored) in
  /// the used tasks.
  final int pairs;

  /// Repetition pairs the plan scheduled.
  final int expectedPairs;

  /// Tasks the plan scheduled.
  final int tasksPlanned;

  /// Tasks used: both arms scored on every planned repetition.
  final int effectiveTaskCount;

  /// Used tasks not saturated (not 0 of k or k of k in both arms).
  final int informativeTasks;

  /// Planned repetitions per arm per task (k).
  final int repetitions;

  /// Planned tasks left out, with the reason.
  final List<DroppedTask> droppedTasks;

  /// Repetition pairs only the baseline verified (descriptive).
  final int baselineOnlyWins;

  /// Repetition pairs only the treatment verified (descriptive).
  final int treatmentOnlyWins;

  /// Repetition pairs both verified (descriptive).
  final int bothPass;

  /// Repetition pairs neither verified (descriptive).
  final int bothFail;

  /// d̄: the mean per-task difference, positive meaning the treatment did
  /// better on the primary outcome.
  final double observedDelta;

  /// s, the spread of the per-task differences.
  final double standardDeviation;

  /// One-sided (1 − alpha) lower bound on the task-mean difference.
  final double lowerBound;

  /// One-sided (1 − alpha) upper bound on the task-mean difference.
  final double upperBound;

  /// The t statistic, or null below two tasks or with no spread.
  final double? tStatistic;

  /// N − 1.
  final int degreesOfFreedom;

  /// The one-sided t p of the claim made, or of the plan's own claim when
  /// none was made.
  final double pValue;

  /// The exact sign-flip p of the same claim.
  final double signFlipP;

  /// The smallest difference this many tasks with this spread would detect
  /// with 80 % power; null below two tasks.
  final double? minimumDetectableEffect;

  /// The non-inferiority margin in absolute points, when the plan has one.
  final double? margin;

  /// The plan's one-sided level per claim.
  final double alpha;

  /// The quality verdict.
  final QualityVerdict verdict;

  /// Treatment cost over baseline cost on the used tasks, or null when
  /// either is unpriced or there is none.
  final double? costRatio;

  /// The largest cost ratio the plan accepts for adoption.
  final double maxCostRatio;

  /// What to do with the default.
  final AdoptionRecommendation recommendation;

  /// Which statistical method produced the bound.
  final String method;

  /// The verdict in one plain sentence.
  final String reason;

  /// Whether the campaign stopped at its interim look.
  final bool stoppedAtInterim;

  /// How many compared tasks would show a lower treatment rate by chance
  /// alone if the arms were identical (what the descriptive per-task
  /// regression list is read against).
  final double expectedChanceLosses;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'baselineArmId': baselineArmId,
    'treatmentArmId': treatmentArmId,
    'hypothesis': hypothesis.wire,
    'primaryOutcome': primaryOutcome.wire,
    'pairs': pairs,
    'expectedPairs': expectedPairs,
    'tasksPlanned': tasksPlanned,
    'effectiveTaskCount': effectiveTaskCount,
    'informativeTasks': informativeTasks,
    'repetitions': repetitions,
    'droppedTasks': [for (final d in droppedTasks) d.toJson()],
    'baselineOnlyWins': baselineOnlyWins,
    'treatmentOnlyWins': treatmentOnlyWins,
    'bothPass': bothPass,
    'bothFail': bothFail,
    'observedDelta': observedDelta,
    'standardDeviation': standardDeviation,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
    'tStatistic': tStatistic,
    'degreesOfFreedom': degreesOfFreedom,
    'pValue': pValue,
    'signFlipP': signFlipP,
    'minimumDetectableEffect': minimumDetectableEffect,
    'margin': margin,
    'alpha': alpha,
    'verdict': verdict.wire,
    'costRatio': costRatio,
    'maxCostRatio': maxCostRatio,
    'recommendation': recommendation.wire,
    'method': method,
    'reason': reason,
    'stoppedAtInterim': stoppedAtInterim,
    'expectedChanceLosses': expectedChanceLosses,
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
    required this.hypothesis,
    required this.primaryOutcome,
    required this.repetitions,
    required this.stoppedAtInterim,
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
  /// The verdict does not need it: it judges the complete task blocks.
  final bool coverageComplete;

  /// What the plan asked.
  final EvaluationHypothesis hypothesis;

  /// What attempts were scored on.
  final EvaluationOutcomeMeasure primaryOutcome;

  /// Planned repetitions per arm per task (k).
  final int repetitions;

  /// Whether the campaign stopped at its interim look.
  final bool stoppedAtInterim;

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

  /// The recommendation this campaign supports for the default.
  ///
  /// Adopt when a treatment's verdict and cost support it; keep the default
  /// only when every treatment has evidence against it (inferior, or over
  /// the cost ceiling); otherwise no decision. A plan violation or a
  /// calibration plan is never a decision.
  AdoptionRecommendation get overallRecommendation {
    if (planViolations.isNotEmpty || verdicts.isEmpty) {
      return AdoptionRecommendation.noDecision;
    }
    final recommendations = {for (final v in verdicts) v.recommendation};
    if (recommendations.contains(AdoptionRecommendation.adoptTreatment)) {
      return AdoptionRecommendation.adoptTreatment;
    }
    if (recommendations.contains(AdoptionRecommendation.noDecision)) {
      return AdoptionRecommendation.noDecision;
    }
    return AdoptionRecommendation.keepQualityDefault;
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
    'hypothesis': hypothesis.wire,
    'primaryOutcome': primaryOutcome.wire,
    'repetitions': repetitions,
    'stoppedAtInterim': stoppedAtInterim,
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
    bool stoppedAtInterim = false,
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
    final judge = TaskClusterJudge(plan: plan, tasks: tasks);
    final expectedPairs = tasks.length * judge.repetitions;
    final plannedKeys = {
      for (final trial in plannedTrials)
        '${trial.taskId}\u0000${trial.armId}\u0000${trial.stratum.wire}\u0000${trial.repetition}',
    };
    final observedKeys = {
      for (final attempt in attempts)
        '${attempt.taskId}\u0000${attempt.armId}\u0000${attempt.stratum.wire}\u0000${attempt.repetition}',
    };
    final missingTrials = plannedKeys.difference(observedKeys).length;
    // Coverage means every PLANNED trial ran. The verdict judges complete
    // task blocks instead; coverage only gates a post-idle plan.
    final coverageComplete = plannedKeys.isNotEmpty && missingTrials == 0;

    final baseline = plan.baselineArm;
    final regressions = <TaskRegression>[];
    final verdicts = judge.judge(
      attempts: attempts,
      coverageComplete: coverageComplete,
      stoppedAtInterim: stoppedAtInterim,
    );
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
      hypothesis: plan.hypothesis,
      primaryOutcome: plan.primaryOutcome,
      repetitions: judge.repetitions,
      stoppedAtInterim: stoppedAtInterim,
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
        'trial(s) never ran; the verdict uses only the task blocks both arms '
        'completed',
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
    final faulted = attempts
        .where((a) => a.end == EvaluationAttemptEnd.harnessFault)
        .length;
    if (faulted > 0) {
      unknowns.add(
        '$faulted attempt(s) faulted in the harness: missing data, and their '
        'task blocks are dropped from the verdict',
      );
    }
    final ceilingStopped = attempts
        .where((a) => a.end == EvaluationAttemptEnd.ceilingStopped)
        .length;
    if (ceilingStopped > 0) {
      unknowns.add(
        '$ceilingStopped attempt(s) were cut by the spend ceiling: missing '
        'data, and their task blocks are dropped from the verdict',
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
      if (arm.memoryPolicy == MemoryPolicyMode.snapshotImages &&
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

String _usd(double micros) => '\$${(micros / 1000000).toStringAsFixed(4)}';
