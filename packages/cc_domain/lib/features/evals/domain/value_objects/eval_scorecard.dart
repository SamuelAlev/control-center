import 'dart:convert';
import 'dart:math' as math;

import 'package:cc_domain/features/evals/domain/services/eval_graders.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_outcome.dart';

/// One repetition of an eval batch: the outcome plus every grader's verdict.
class EvalRepetitionResult {
  /// Creates an [EvalRepetitionResult].
  const EvalRepetitionResult({required this.outcome, required this.grades});

  /// The observed outcome.
  final EvalOutcome outcome;

  /// The per-grader verdicts for this repetition.
  final List<GradeResult> grades;

  /// A repetition passes only when every grader passes.
  bool get passed => grades.isNotEmpty && grades.every((g) => g.passed);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'outcome': outcome.toJson(),
    'passed': passed,
    'grades': grades.map((g) => g.toJson()).toList(),
  };
}

/// The aggregate result of an eval batch (PRD 21 §5): pass-rate, cost, latency,
/// variance, and a per-grader breakdown. Statistics — never single-run
/// verdicts (live re-execution is sampled behaviour, spec adversarial review).
class EvalScorecard {
  /// Creates an [EvalScorecard].
  const EvalScorecard({
    required this.batchSize,
    required this.passRate,
    required this.passRateStdDev,
    required this.avgCostCents,
    required this.costStdDev,
    required this.avgTurns,
    required this.avgDurationMs,
    required this.perGraderPassRate,
    required this.repsPassed,
  });

  /// Aggregates a batch of repetition results into a scorecard.
  factory EvalScorecard.fromReps(List<EvalRepetitionResult> reps) {
    if (reps.isEmpty) {
      return const EvalScorecard(
        batchSize: 0,
        passRate: 0,
        passRateStdDev: 0,
        avgCostCents: 0,
        costStdDev: 0,
        avgTurns: 0,
        avgDurationMs: 0,
        perGraderPassRate: {},
        repsPassed: 0,
      );
    }
    final n = reps.length;
    final passed = reps.where((r) => r.passed).length;
    final passRate = passed / n;
    final passSamples = reps.map((r) => r.passed ? 1.0 : 0.0).toList();
    final costSamples = reps
        .map((r) => r.outcome.costCents.toDouble())
        .toList();
    final turns = reps.map((r) => r.outcome.turnCount).toList();
    final durations = reps.map((r) => r.outcome.durationMs).toList();

    // Per-grader pass rate across the batch.
    final graderPass = <String, int>{};
    final graderCount = <String, int>{};
    for (final rep in reps) {
      for (final g in rep.grades) {
        graderCount[g.graderId] = (graderCount[g.graderId] ?? 0) + 1;
        if (g.passed) {
          graderPass[g.graderId] = (graderPass[g.graderId] ?? 0) + 1;
        }
      }
    }
    final perGrader = <String, double>{};
    for (final id in graderCount.keys) {
      perGrader[id] = (graderPass[id] ?? 0) / graderCount[id]!;
    }

    return EvalScorecard(
      batchSize: n,
      passRate: passRate,
      passRateStdDev: _stdDev(passSamples),
      avgCostCents: _mean(costSamples),
      costStdDev: _stdDev(costSamples),
      avgTurns: turns.isEmpty ? 0 : turns.reduce((a, b) => a + b) / n,
      avgDurationMs: durations.isEmpty
          ? 0
          : durations.reduce((a, b) => a + b) / n,
      perGraderPassRate: perGrader,
      repsPassed: passed,
    );
  }

  /// Parses from JSON.
  factory EvalScorecard.fromJson(Map<String, dynamic> json) => EvalScorecard(
    batchSize: (json['batchSize'] as num?)?.toInt() ?? 0,
    passRate: (json['passRate'] as num?)?.toDouble() ?? 0,
    passRateStdDev: (json['passRateStdDev'] as num?)?.toDouble() ?? 0,
    avgCostCents: (json['avgCostCents'] as num?)?.toDouble() ?? 0,
    costStdDev: (json['costStdDev'] as num?)?.toDouble() ?? 0,
    avgTurns: (json['avgTurns'] as num?)?.toDouble() ?? 0,
    avgDurationMs: (json['avgDurationMs'] as num?)?.toDouble() ?? 0,
    perGraderPassRate: ((json['perGraderPassRate'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
    repsPassed: (json['repsPassed'] as num?)?.toInt() ?? 0,
  );

  /// Number of repetitions in the batch.
  final int batchSize;

  /// Fraction of repetitions that passed every grader `[0, 1]`.
  final double passRate;

  /// Standard deviation of the per-rep pass indicator (variance band).
  final double passRateStdDev;

  /// Mean metered cost in cents.
  final double avgCostCents;

  /// Standard deviation of per-rep cost.
  final double costStdDev;

  /// Mean turn count.
  final double avgTurns;

  /// Mean wall-clock duration in ms.
  final double avgDurationMs;

  /// Per-grader pass rate across the batch.
  final Map<String, double> perGraderPassRate;

  /// Number of repetitions that passed.
  final int repsPassed;

  /// Whether this scorecard clears a promotion gate at [threshold] pass-rate
  /// (PRD 21 §6 canary gate).
  bool isGreen({double threshold = 0.9}) =>
      batchSize > 0 && passRate >= threshold;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'batchSize': batchSize,
    'passRate': passRate,
    'passRateStdDev': passRateStdDev,
    'avgCostCents': avgCostCents,
    'costStdDev': costStdDev,
    'avgTurns': avgTurns,
    'avgDurationMs': avgDurationMs,
    'perGraderPassRate': perGraderPassRate,
    'repsPassed': repsPassed,
  };

  /// Serializes to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  static double _mean(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  static double _stdDev(List<double> xs) {
    if (xs.length < 2) {
      return 0;
    }
    final m = _mean(xs);
    final variance =
        xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / xs.length;
    return math.sqrt(variance);
  }
}
