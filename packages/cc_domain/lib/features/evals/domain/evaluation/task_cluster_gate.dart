import 'dart:math' as math;

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/task_cluster_statistics.dart';

/// A claim the gate can make about one treatment arm.
enum TaskClusterClaim {
  /// The treatment is better: H0 Δ ≤ 0 rejected.
  superior,

  /// The treatment loses less than the margin: H0 Δ ≤ −margin rejected.
  nonInferior,

  /// The treatment is worse: H0 Δ ≥ 0 rejected.
  inferior,
}

/// The task-clustered one-sided paired t-test on per-task mean differences,
/// with the exact sign-flip test beside it.
///
/// The unit is the task: each task contributes one difference d_i (the
/// treatment's mean score minus the baseline's, oriented so positive is
/// better), and repetitions only sharpen it. Bounds are
/// d̄ ± t(1−α, N−1)·s/√N. A claim needs both the t p and the sign-flip p at
/// or below its level, which protects small N and the zero-variance case.
class TaskClusterTest {
  TaskClusterTest._({
    required this.differences,
    required this.alpha,
    required this.margin,
    required this.mean,
    required this.standardDeviation,
    required this.lowerBound,
    required this.upperBound,
    required this.tStatistic,
    required this.pSuperior,
    required this.pNonInferior,
    required this.pInferior,
    required this.signFlipSuperior,
    required this.signFlipNonInferior,
    required this.signFlipInferior,
    required this.minimumDetectableEffect,
  });

  /// Runs the test on [differences] at one-sided level [alpha]; [margin] is
  /// the non-inferiority margin when the plan has one. [seed] fixes the
  /// Monte Carlo sign flips above 20 tasks.
  factory TaskClusterTest.of(
    List<double> differences, {
    required double alpha,
    required double? margin,
    required int seed,
  }) {
    final n = differences.length;
    final mean = n == 0
        ? 0.0
        : differences.fold<double>(0, (a, b) => a + b) / n;
    var squares = 0.0;
    for (final d in differences) {
      squares += (d - mean) * (d - mean);
    }
    final sd = n < 2 ? 0.0 : math.sqrt(squares / (n - 1));
    // Rounding noise in a mean of equal fractions is not variance.
    final s = sd < 1e-12 ? 0.0 : sd;
    double pAbove(double shift) {
      if (n < 2) {
        return 1;
      }
      if (s == 0) {
        return mean + shift > 0 ? 0 : 1;
      }
      final t = (mean + shift) / (s / math.sqrt(n));
      return 1 - TaskClusterStatistics.studentTCdf(t, n - 1);
    }

    double pBelow() {
      if (n < 2) {
        return 1;
      }
      if (s == 0) {
        return mean < 0 ? 0 : 1;
      }
      final t = mean / (s / math.sqrt(n));
      return TaskClusterStatistics.studentTCdf(t, n - 1);
    }

    double lower = -1;
    double upper = 1;
    double? mde;
    if (n >= 2) {
      final q = TaskClusterStatistics.studentTQuantile(1 - alpha, n - 1);
      final radius = q * s / math.sqrt(n);
      lower = math.max(-1, mean - radius);
      upper = math.min(1, mean + radius);
      mde =
          (q + TaskClusterStatistics.studentTQuantile(0.8, n - 1)) *
          s /
          math.sqrt(n);
    }
    double flip(List<double> values) =>
        TaskClusterStatistics.signFlipPValue(values, seed: seed);
    return TaskClusterTest._(
      differences: List.unmodifiable(differences),
      alpha: alpha,
      margin: margin,
      mean: mean,
      standardDeviation: s,
      lowerBound: lower,
      upperBound: upper,
      tStatistic: n >= 2 && s > 0 ? mean / (s / math.sqrt(n)) : null,
      pSuperior: pAbove(0),
      pNonInferior: margin == null ? null : pAbove(margin),
      pInferior: pBelow(),
      signFlipSuperior: flip(differences),
      signFlipNonInferior: margin == null
          ? null
          : flip([for (final d in differences) d + margin]),
      signFlipInferior: flip([for (final d in differences) -d]),
      minimumDetectableEffect: mde,
    );
  }

  /// The per-task differences, positive meaning the treatment did better.
  final List<double> differences;

  /// The one-sided level the bounds are drawn at.
  final double alpha;

  /// The non-inferiority margin, when the plan has one.
  final double? margin;

  /// d̄, the mean per-task difference.
  final double mean;

  /// s, the standard deviation of the differences (N − 1 denominator).
  final double standardDeviation;

  /// d̄ − t(1−α, N−1)·s/√N, clamped to [−1, 1].
  final double lowerBound;

  /// d̄ + t(1−α, N−1)·s/√N, clamped to [−1, 1].
  final double upperBound;

  /// d̄ / (s/√N); null below two tasks or when every difference is equal.
  final double? tStatistic;

  /// One-sided t p for superiority (H0 Δ ≤ 0).
  final double pSuperior;

  /// One-sided t p for non-inferiority (H0 Δ ≤ −margin).
  final double? pNonInferior;

  /// One-sided t p for inferiority (H0 Δ ≥ 0).
  final double pInferior;

  /// Exact sign-flip p on d_i.
  final double signFlipSuperior;

  /// Exact sign-flip p on d_i + margin.
  final double? signFlipNonInferior;

  /// Exact sign-flip p on −d_i.
  final double signFlipInferior;

  /// The smallest true difference this many tasks with this spread would
  /// detect with 80 % power at alpha; null below two tasks.
  final double? minimumDetectableEffect;

  /// Tasks in the test.
  int get tasks => differences.length;

  /// Degrees of freedom, N − 1.
  int get degreesOfFreedom => math.max(0, tasks - 1);

  /// The t p of [claim].
  double tP(TaskClusterClaim claim) => switch (claim) {
    TaskClusterClaim.superior => pSuperior,
    TaskClusterClaim.nonInferior => pNonInferior ?? 1,
    TaskClusterClaim.inferior => pInferior,
  };

  /// The sign-flip p of [claim].
  double signFlipP(TaskClusterClaim claim) => switch (claim) {
    TaskClusterClaim.superior => signFlipSuperior,
    TaskClusterClaim.nonInferior => signFlipNonInferior ?? 1,
    TaskClusterClaim.inferior => signFlipInferior,
  };

  /// The p a claim is held to under [hypothesis]: the larger of its t p and
  /// sign-flip p (both must hold), except that a regression screen calls
  /// inferior on the sign-flip p alone.
  double claimP(TaskClusterClaim claim, EvaluationHypothesis hypothesis) =>
      hypothesis == EvaluationHypothesis.regressionScreen &&
          claim == TaskClusterClaim.inferior
      ? signFlipInferior
      : math.max(tP(claim), signFlipP(claim));

  /// The claims [hypothesis] may make, in the order they are checked.
  static List<TaskClusterClaim> claimsFor(EvaluationHypothesis hypothesis) =>
      switch (hypothesis) {
        EvaluationHypothesis.nonInferiority => const [
          TaskClusterClaim.superior,
          TaskClusterClaim.nonInferior,
          TaskClusterClaim.inferior,
        ],
        EvaluationHypothesis.superiority ||
        EvaluationHypothesis.regressionScreen => const [
          TaskClusterClaim.superior,
          TaskClusterClaim.inferior,
        ],
        EvaluationHypothesis.calibration => const [],
      };

  /// The first claim of [hypothesis] that holds at [level], or null.
  TaskClusterClaim? claimAt(EvaluationHypothesis hypothesis, double level) {
    for (final claim in claimsFor(hypothesis)) {
      if (claimP(claim, hypothesis) <= level) {
        return claim;
      }
    }
    return null;
  }

  /// The smallest claim p under [hypothesis] (what Holm ranks by).
  double bestP(EvaluationHypothesis hypothesis) {
    var best = 1.0;
    for (final claim in claimsFor(hypothesis)) {
      best = math.min(best, claimP(claim, hypothesis));
    }
    return best;
  }
}
