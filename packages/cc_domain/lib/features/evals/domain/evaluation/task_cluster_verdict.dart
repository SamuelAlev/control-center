import 'dart:math' as math;

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/evals/domain/evaluation/task_cluster_gate.dart';
import 'package:cc_domain/features/evals/domain/evaluation/task_cluster_statistics.dart';

/// Turns a plan's attempts into one verdict per treatment arm.
///
/// 1. Per task and arm, the mean score over the planned repetitions. A task
///    is used only when both arms scored every planned repetition; otherwise
///    it is dropped and listed with the reason.
/// 2. More than 10 % of either arm's planned attempts (over the tasks that
///    started) missing for a reason other than the spend ceiling: the
///    harness is unreliable and no claim is made.
/// 3. Fewer used tasks than `minTasks`, or fewer than half of them
///    informative (not 0 of k or k of k in both arms): no claim.
/// 4. The task-clustered paired t-test with the exact sign-flip test beside
///    it ([TaskClusterTest]), Holm's correction across the plan's treatment
///    arms.
class TaskClusterJudge {
  /// Creates a [TaskClusterJudge] for [plan] over its selected [tasks].
  const TaskClusterJudge({required this.plan, required this.tasks});

  /// The plan.
  final EvaluationPlan plan;

  /// The tasks the plan scheduled.
  final List<EvaluationTask> tasks;

  /// The method every verdict names.
  static const method =
      'task-cluster paired t (df N−1) with exact sign-flip check';

  /// The one-sided p an interim look must beat to stop the campaign.
  static const interimLevel = 0.001;

  /// The share of an arm's planned attempts that may be missing.
  static const missingTolerance = 0.10;

  /// Planned repetitions per arm per task (k), over every stratum.
  int get repetitions =>
      plan.strata.fold<int>(0, (sum, spec) => sum + spec.repetitions);

  List<String> get _plannedSlots => [
    for (final spec in plan.strata)
      for (var rep = 0; rep < spec.repetitions; rep++)
        '${spec.stratum.wire}/$rep',
  ];

  /// One verdict per treatment arm, in plan order.
  List<NonInferiorityVerdict> judge({
    required List<EvaluationAttempt> attempts,
    required bool coverageComplete,
    bool stoppedAtInterim = false,
  }) {
    final baseline = plan.baselineArm;
    if (baseline == null ||
        plan.hypothesis == EvaluationHypothesis.calibration) {
      return const [];
    }
    final treatments = [
      for (final arm in plan.arms)
        if (!arm.isBaseline) arm,
    ];
    final analyses = [
      for (final treatment in treatments)
        _analyse(baseline, treatment, attempts, coverageComplete),
    ];
    final bestPs = [
      for (final a in analyses)
        a.gate == null ? a.test.bestP(plan.hypothesis) : 1.0,
    ];
    final rejected = TaskClusterStatistics.holm(bestPs, plan.alpha);
    final levels = _holmLevels(bestPs);
    return [
      for (var i = 0; i < analyses.length; i++)
        _verdict(
          analyses[i],
          rejected: rejected[i],
          level: levels[i],
          family: analyses.length,
          stoppedAtInterim: stoppedAtInterim,
        ),
    ];
  }

  /// Whether the one interim look stops the campaign (Haybittle-Peto):
  /// every treatment arm passes the task gates and makes a superior or
  /// inferior claim whose one-sided t p is below [interimLevel] and whose
  /// sign-flip p is within alpha (the check every claim needs).
  bool interimStop(List<EvaluationAttempt> attempts) {
    final baseline = plan.baselineArm;
    if (baseline == null || plan.interimAtTasks == null) {
      return false;
    }
    final treatments = [
      for (final arm in plan.arms)
        if (!arm.isBaseline) arm,
    ];
    if (treatments.isEmpty) {
      return false;
    }
    for (final treatment in treatments) {
      final analysis = _analyse(baseline, treatment, attempts, false);
      if (analysis.gate != null) {
        return false;
      }
      final decisive = [TaskClusterClaim.superior, TaskClusterClaim.inferior]
          .any(
            (claim) =>
                analysis.test.tP(claim) < interimLevel &&
                analysis.test.signFlipP(claim) <= plan.alpha,
          );
      if (!decisive) {
        return false;
      }
    }
    return true;
  }

  /// Task blocks (every arm, every planned repetition recorded) finished.
  int completedTaskBlocks(List<EvaluationAttempt> attempts) {
    final recorded = <String>{
      for (final a in attempts)
        '${a.taskId}\u0000${a.armId}\u0000${a.stratum.wire}/${a.repetition}',
    };
    final slots = _plannedSlots;
    var blocks = 0;
    for (final task in tasks) {
      final complete = plan.arms.every(
        (arm) => slots.every(
          (slot) => recorded.contains('${task.id}\u0000${arm.id}\u0000$slot'),
        ),
      );
      if (complete) {
        blocks++;
      }
    }
    return blocks;
  }

  List<double> _holmLevels(List<double> ps) {
    final m = ps.length;
    final order = List<int>.generate(m, (i) => i)
      ..sort((a, b) => ps[a].compareTo(ps[b]));
    final levels = List<double>.filled(m, plan.alpha);
    for (var rank = 0; rank < m; rank++) {
      levels[order[rank]] = plan.alpha / (m - rank);
    }
    return levels;
  }

  _Analysis _analyse(
    EvaluationArm baseline,
    EvaluationArm treatment,
    List<EvaluationAttempt> attempts,
    bool coverageComplete,
  ) {
    final outcome = plan.primaryOutcome;
    final slots = _plannedSlots;
    final k = slots.length;
    final byKey = <String, EvaluationAttempt>{};
    for (final a in attempts) {
      if (a.armId == baseline.id || a.armId == treatment.id) {
        byKey['${a.taskId}\u0000${a.armId}\u0000${a.stratum.wire}/${a.repetition}'] =
            a;
      }
    }
    final differences = <double>[];
    final dropped = <DroppedTask>[];
    var informative = 0;
    var bothPass = 0;
    var bothFail = 0;
    var baseOnly = 0;
    var treatOnly = 0;
    var startedTasks = 0;
    var baseMissing = 0;
    var treatMissing = 0;
    var baseCost = 0;
    var treatCost = 0;
    var costComplete = true;
    for (final task in tasks) {
      final base = _block(byKey, task.id, baseline.id, slots, outcome);
      final treat = _block(byKey, task.id, treatment.id, slots, outcome);
      if (base.recorded + treat.recorded > 0) {
        startedTasks++;
      }
      baseMissing += base.unreliable;
      treatMissing += treat.unreliable;
      if (!base.complete || !treat.complete) {
        dropped.add(
          DroppedTask(
            taskId: task.id,
            reason: base.recorded + treat.recorded == 0
                ? 'not run'
                : [
                    if (!base.complete) '${baseline.id}: ${base.why(k)}',
                    if (!treat.complete) '${treatment.id}: ${treat.why(k)}',
                  ].join('; '),
          ),
        );
        continue;
      }
      final baseMean = base.sum / k;
      final treatMean = treat.sum / k;
      final saturated =
          baseMean == treatMean && (baseMean == 0 || baseMean == 1);
      if (!saturated) {
        informative++;
      }
      differences.add(
        outcome.lowerIsBetter ? baseMean - treatMean : treatMean - baseMean,
      );
      for (final slot in slots) {
        final b = byKey['${task.id}\u0000${baseline.id}\u0000$slot']!;
        final t = byKey['${task.id}\u0000${treatment.id}\u0000$slot']!;
        if (b.verifiedSuccess && t.verifiedSuccess) {
          bothPass++;
        } else if (!b.verifiedSuccess && !t.verifiedSuccess) {
          bothFail++;
        } else if (b.verifiedSuccess) {
          baseOnly++;
        } else {
          treatOnly++;
        }
      }
      final bc = base.costMicros;
      final tc = treat.costMicros;
      if (bc == null || tc == null) {
        costComplete = false;
      } else {
        baseCost += bc;
        treatCost += tc;
      }
    }
    final n = differences.length;
    final test = TaskClusterTest.of(
      differences,
      alpha: plan.alpha,
      margin: plan.hypothesis == EvaluationHypothesis.nonInferiority
          ? plan.nonInferiorityMargin
          : null,
      seed: plan.seed,
    );
    final plannedPerArm = startedTasks * k;
    final minTasks = plan.minTasks ?? 0;
    String? gate;
    if (plan.hasPostIdleStratum && !coverageComplete) {
      gate =
          'a plan with a post-idle stratum is analysed only when every '
          'planned trial ran';
    } else if (plannedPerArm > 0 &&
        math.max(baseMissing, treatMissing) >
            missingTolerance * plannedPerArm) {
      gate =
          'harness unreliable: ${math.max(baseMissing, treatMissing)} of '
          '$plannedPerArm planned attempts of '
          '${baseMissing >= treatMissing ? baseline.id : treatment.id} are '
          'missing (more than 10 %)';
    } else if (n < minTasks) {
      gate = '$n tasks, $minTasks needed';
    } else if (informative < (n + 1) ~/ 2) {
      gate =
          'saturated task set: only $informative of $n used tasks are '
          'informative (not 0 of $k or $k of $k in both arms)';
    }
    return _Analysis(
      baseline: baseline,
      treatment: treatment,
      test: test,
      gate: gate,
      dropped: dropped,
      informative: informative,
      bothPass: bothPass,
      bothFail: bothFail,
      baselineOnlyWins: baseOnly,
      treatmentOnlyWins: treatOnly,
      costRatio: costComplete && n > 0 && baseCost > 0
          ? treatCost / baseCost
          : null,
      expectedChanceLosses: _chanceLosses(baseline, treatment, attempts),
    );
  }

  static _ArmBlock _block(
    Map<String, EvaluationAttempt> byKey,
    String taskId,
    String armId,
    List<String> slots,
    EvaluationOutcomeMeasure outcome,
  ) {
    final block = _ArmBlock();
    for (final slot in slots) {
      final attempt = byKey['$taskId\u0000$armId\u0000$slot'];
      if (attempt == null) {
        block.missing['not run'] = (block.missing['not run'] ?? 0) + 1;
        continue;
      }
      block.recorded++;
      final cost = attempt.attemptCostMicros;
      block.costMicros = cost == null || block.costMicros == null
          ? null
          : block.costMicros! + cost;
      final score = attempt.score(outcome);
      if (score != null) {
        block.scored++;
        block.sum += score;
        continue;
      }
      final cause = switch (attempt.end) {
        EvaluationAttemptEnd.harnessFault => 'harness fault',
        EvaluationAttemptEnd.ceilingStopped => 'spend ceiling',
        _ when attempt.identityMismatches.isNotEmpty => 'pin contradicted',
        _ => 'declared checks skipped',
      };
      block.missing[cause] = (block.missing[cause] ?? 0) + 1;
      if (attempt.end != EvaluationAttemptEnd.ceilingStopped) {
        block.unreliable++;
      }
    }
    if (block.recorded == 0) {
      block.costMicros = null;
    }
    return block;
  }

  NonInferiorityVerdict _verdict(
    _Analysis a, {
    required bool rejected,
    required double level,
    required int family,
    required bool stoppedAtInterim,
  }) {
    final test = a.test;
    final hypothesis = plan.hypothesis;
    final claim = a.gate == null && rejected
        ? test.claimAt(hypothesis, level)
        : null;
    final verdict = switch (claim) {
      TaskClusterClaim.superior => QualityVerdict.superior,
      TaskClusterClaim.nonInferior => QualityVerdict.nonInferior,
      TaskClusterClaim.inferior => QualityVerdict.inferior,
      null => QualityVerdict.inconclusive,
    };
    final reported =
        claim ??
        switch (hypothesis) {
          EvaluationHypothesis.nonInferiority => TaskClusterClaim.nonInferior,
          EvaluationHypothesis.regressionScreen => TaskClusterClaim.inferior,
          _ => TaskClusterClaim.superior,
        };
    final n = test.tasks;
    final confidence = '${((1 - plan.alpha) * 100).toStringAsFixed(0)} %';
    final margin = plan.nonInferiorityMargin;
    final range = test.standardDeviation > 0
        ? 'the treatment could be anywhere from ${_signed(test.lowerBound)} '
              'to ${_signed(test.upperBound)} points different; this is not '
              'evidence of no difference'
        : test.mean == 0
        ? 'every used task tied exactly; this is not evidence of no '
              'difference'
        : 'every used task moved by ${_signed(test.mean)} points, and the '
              'exact sign-flip check (p ${_p(test.signFlipP(reported))}) '
              'cannot tell that from chance at this size';
    var reason = switch (claim) {
      TaskClusterClaim.superior =>
        'the treatment is better: ${_pts(test.mean)} points per task over $n '
            'tasks, at least ${_pts(test.lowerBound)} at $confidence confidence',
      TaskClusterClaim.nonInferior =>
        'the treatment is no worse than the ${_pts(margin ?? 0)}-point margin: '
            'at worst ${_pts(-test.lowerBound)} points lower over $n tasks at '
            '$confidence confidence'
            '${test.upperBound < 0 ? '; a loss smaller than the margin is demonstrated' : ''}',
      TaskClusterClaim.inferior =>
        test.upperBound < 0
            ? 'the treatment is worse: ${_pts(-test.mean)} points per task '
                  'lower over $n tasks, at least ${_pts(-test.upperBound)} at '
                  '$confidence confidence'
            : 'the treatment scored lower: ${_pts(-test.mean)} points per task '
                  'over $n tasks, too consistent for chance (exact sign-flip p '
                  '${_p(test.signFlipInferior)})',
      null =>
        a.gate == null
            ? (family > 1 && test.bestP(hypothesis) <= plan.alpha
                  ? 'held to the Holm level ${_p(level)} across $family '
                        'treatments, no claim stands; $range'
                  : range)
            : n >= 2 && test.standardDeviation > 0
            ? '${a.gate}; $range'
            : a.gate!,
    };
    if (stoppedAtInterim) {
      reason = 'stopped at the interim look after $n tasks: $reason';
    }
    return NonInferiorityVerdict(
      baselineArmId: a.baseline.id,
      treatmentArmId: a.treatment.id,
      hypothesis: hypothesis,
      primaryOutcome: plan.primaryOutcome,
      pairs: n * repetitions,
      expectedPairs: tasks.length * repetitions,
      tasksPlanned: tasks.length,
      effectiveTaskCount: n,
      informativeTasks: a.informative,
      repetitions: repetitions,
      droppedTasks: a.dropped,
      baselineOnlyWins: a.baselineOnlyWins,
      treatmentOnlyWins: a.treatmentOnlyWins,
      bothPass: a.bothPass,
      bothFail: a.bothFail,
      observedDelta: test.mean,
      standardDeviation: test.standardDeviation,
      lowerBound: test.lowerBound,
      upperBound: test.upperBound,
      tStatistic: test.tStatistic,
      degreesOfFreedom: test.degreesOfFreedom,
      pValue: test.tP(reported),
      signFlipP: test.signFlipP(reported),
      minimumDetectableEffect: test.minimumDetectableEffect,
      margin: margin,
      alpha: plan.alpha,
      verdict: verdict,
      costRatio: a.costRatio,
      maxCostRatio: plan.maxCostRatio,
      recommendation: _recommend(verdict, a.costRatio),
      method: method,
      reason: _withCost(reason, verdict, a.costRatio),
      stoppedAtInterim: stoppedAtInterim,
      expectedChanceLosses: a.expectedChanceLosses,
    );
  }

  /// How many of the tasks both arms ran would show a lower treatment
  /// verified rate by chance alone if the arms were identical: per task,
  /// P(X_t/n_t < X_b/n_b) with both counts binomial at the task's pooled
  /// rate. At k = 3 and mid-range rates it is close to 0.3 per task.
  double _chanceLosses(
    EvaluationArm baseline,
    EvaluationArm treatment,
    List<EvaluationAttempt> attempts,
  ) {
    var expected = 0.0;
    for (final task in tasks) {
      var nb = 0;
      var xb = 0;
      var nt = 0;
      var xt = 0;
      for (final a in attempts) {
        if (a.taskId != task.id) {
          continue;
        }
        if (a.armId == baseline.id) {
          nb++;
          xb += a.verifiedSuccess ? 1 : 0;
        } else if (a.armId == treatment.id) {
          nt++;
          xt += a.verifiedSuccess ? 1 : 0;
        }
      }
      if (nb == 0 || nt == 0) {
        continue;
      }
      final p = (xb + xt) / (nb + nt);
      for (var b = 0; b <= nb; b++) {
        for (var t = 0; t <= nt; t++) {
          if (t * nb < b * nt) {
            expected += _binomial(nb, b, p) * _binomial(nt, t, p);
          }
        }
      }
    }
    return expected;
  }

  static double _binomial(int n, int x, double p) {
    var choose = 1.0;
    for (var i = 1; i <= x; i++) {
      choose = choose * (n - x + i) / i;
    }
    return choose * math.pow(p, x) * math.pow(1 - p, n - x);
  }

  AdoptionRecommendation _recommend(QualityVerdict verdict, double? ratio) =>
      switch (verdict) {
        QualityVerdict.inconclusive => AdoptionRecommendation.noDecision,
        QualityVerdict.inferior => AdoptionRecommendation.keepQualityDefault,
        _ when ratio == null => AdoptionRecommendation.noDecision,
        QualityVerdict.superior =>
          ratio <= plan.maxCostRatio
              ? AdoptionRecommendation.adoptTreatment
              : AdoptionRecommendation.keepQualityDefault,
        QualityVerdict.nonInferior =>
          ratio < 1 && ratio <= plan.maxCostRatio
              ? AdoptionRecommendation.adoptTreatment
              : AdoptionRecommendation.keepQualityDefault,
      };

  String _withCost(String reason, QualityVerdict verdict, double? ratio) {
    if (verdict != QualityVerdict.superior &&
        verdict != QualityVerdict.nonInferior) {
      return reason;
    }
    if (ratio == null) {
      return '$reason; cost over the used tasks is unpriced, so the cost '
          'ceiling cannot be checked';
    }
    final ceiling = verdict == QualityVerdict.nonInferior
        ? math.min(1.0, plan.maxCostRatio)
        : plan.maxCostRatio;
    final fits = verdict == QualityVerdict.nonInferior
        ? ratio < 1 && ratio <= plan.maxCostRatio
        : ratio <= plan.maxCostRatio;
    return fits
        ? reason
        : '$reason; its cost ratio ${ratio.toStringAsFixed(2)} is over the '
              '${ceiling.toStringAsFixed(2)} ceiling';
  }

  static String _pts(double v) => (v * 100).toStringAsFixed(1);

  static String _signed(double v) =>
      '${v > 0
          ? '+'
          : v < 0
          ? '−'
          : ''}${(v.abs() * 100).toStringAsFixed(1)}';

  static String _p(double p) =>
      p < 0.0001 ? p.toStringAsExponential(1) : p.toStringAsFixed(4);
}

class _ArmBlock {
  int recorded = 0;
  int scored = 0;
  int sum = 0;
  int unreliable = 0;
  int? costMicros = 0;
  final Map<String, int> missing = {};

  bool get complete => missing.isEmpty;

  String why(int k) =>
      '${k - scored} of $k repetitions missing (${[for (final e in missing.entries) '${e.key} ${e.value}'].join(', ')})';
}

class _Analysis {
  const _Analysis({
    required this.baseline,
    required this.treatment,
    required this.test,
    required this.gate,
    required this.dropped,
    required this.informative,
    required this.bothPass,
    required this.bothFail,
    required this.baselineOnlyWins,
    required this.treatmentOnlyWins,
    required this.costRatio,
    required this.expectedChanceLosses,
  });

  final EvaluationArm baseline;
  final EvaluationArm treatment;
  final TaskClusterTest test;
  final String? gate;
  final List<DroppedTask> dropped;
  final int informative;
  final int bothPass;
  final int bothFail;
  final int baselineOnlyWins;
  final int treatmentOnlyWins;
  final double? costRatio;
  final double expectedChanceLosses;
}
