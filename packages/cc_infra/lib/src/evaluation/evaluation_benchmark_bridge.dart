import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/observability/domain/benchmark.dart';

/// Projects an [EvaluationReport] onto the existing benchmark value objects so
/// a campaign can be read with the tooling that already exists
/// (`BenchmarkScorer.markdownReport`, the observability UI's trial table).
///
/// The mapping keeps the two failure kinds apart, exactly the way the
/// evaluation does: a trial is `error` when the HARNESS faulted and `fail` when
/// the run finished without satisfying its behavioral checks.
class EvaluationBenchmarkBridge {
  /// Creates an [EvaluationBenchmarkBridge].
  const EvaluationBenchmarkBridge();

  /// The benchmark run for [report].
  BenchmarkRun toBenchmarkRun(
    EvaluationReport report, {
    BenchmarkRun? previous,
  }) {
    final trials = <BenchmarkTrial>[
      for (final attempt in report.attempts) _trial(attempt),
    ];
    return BenchmarkRun(
      id: previous?.id ?? report.planId,
      dataset: report.manifest.corpusId,
      trials: trials,
      expectedTotal: previous?.expectedTotal ?? trials.length,
      startedAt: previous?.startedAt ?? _startedAt(report),
      finishedAt: DateTime.fromMillisecondsSinceEpoch(
        report.generatedAtEpochMs,
      ),
    );
  }

  /// The markdown table plus the success-adjusted cost line.
  String markdown(
    BenchmarkRun run, {
    BenchmarkScorer scorer = const BenchmarkScorer(),
  }) {
    final adjusted = scorer.successAdjustedCostCents(run);
    final unknown = run.totalCostMicros == null;
    return '${scorer.markdownReport(run)}\n'
        'success-adjusted cost: '
        '${unknown
            ? 'unknown (unpriced attempts)'
            : adjusted == null
            ? '∞ (no verified success)'
            : '\$${(adjusted / 100).toStringAsFixed(6)} per verified success'}\n';
  }

  static BenchmarkTrial _trial(EvaluationAttempt attempt) => BenchmarkTrial(
    name: _name(attempt),
    status: !attempt.completed
        ? TrialStatus.error
        : (attempt.verifiedSuccess ? TrialStatus.pass : TrialStatus.fail),
    reward: attempt.completed ? (attempt.verifiedSuccess ? 1 : 0) : null,
    costCents: attempt.cost.budgetMicros == null
        ? null
        : ((attempt.cost.budgetMicros! + (attempt.cost.auxMicros ?? 0)) /
                  microsPerCent)
              .round(),
    costMicros: attempt.cost.budgetMicros == null
        ? null
        : attempt.cost.budgetMicros! + (attempt.cost.auxMicros ?? 0),
    advisorCostCents: attempt.cost.advisorMicros == null
        ? 0
        : (attempt.cost.advisorMicros! / microsPerCent).round(),
    advisorCostMicros: attempt.cost.advisorMicros,
    tokIn: attempt.tokens.inputTokens,
    tokOut: attempt.tokens.output,
    tokCache: attempt.tokens.cacheRead + attempt.tokens.cacheWrite,
    durationMs: attempt.latency.totalMs,
    detail: _detail(attempt),
  );

  static String _name(EvaluationAttempt attempt) =>
      '${attempt.taskId} · ${attempt.armId} · ${attempt.stratum.wire}'
      '#${attempt.repetition}';

  static String _detail(EvaluationAttempt attempt) {
    if (!attempt.completed) {
      return 'harness: ${attempt.error ?? 'did not complete'}';
    }
    final failed = [
      for (final result in attempt.verification)
        if (result.proves && !result.passed) result.verifierId,
    ];
    if (failed.isNotEmpty) {
      return 'failed: ${failed.join(', ')}';
    }
    if (attempt.proving.isEmpty) {
      return 'unverified (no authoritative check)';
    }
    return 'verified ${attempt.proving.length} check(s)';
  }

  static DateTime _startedAt(EvaluationReport report) {
    if (report.attempts.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(report.generatedAtEpochMs);
    }
    final earliest = report.attempts
        .map((a) => a.startedAtEpochMs)
        .reduce((a, b) => a < b ? a : b);
    return DateTime.fromMillisecondsSinceEpoch(earliest);
  }
}
