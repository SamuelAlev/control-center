import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';

/// Renders an [EvaluationReport] as the auditable markdown artifact the
/// campaign produces.
///
/// The renderer is deliberately blunt about missing evidence: an unobserved
/// cost role prints `?`, an arm with no verified success prints `∞` for
/// cost-per-success, and an offline replay is labelled as such in the first
/// line so it can never be mistaken for a live result.
class EvaluationReportRenderer {
  /// Creates an [EvaluationReportRenderer].
  const EvaluationReportRenderer({this.maxAttemptRows = 60});

  /// How many attempt rows to print before truncating (the JSONL keeps all).
  final int maxAttemptRows;

  /// Renders [report].
  String render(EvaluationReport report) {
    final buffer = StringBuffer();
    final replay =
        report.executionMode == EvaluationExecutionMode.offlineReplay;
    buffer
      ..writeln(
        replay
            ? '# Evaluation report — OFFLINE REPLAY (deterministic '
                  're-verification, no model calls)'
            : '# Evaluation report — LIVE',
      )
      ..writeln()
      ..writeln(
        '> ${report.liveModelCalls ? 'Model calls were made.' : 'No model calls were made for this report.'}',
      )
      ..writeln()
      ..writeln('| field | value |')
      ..writeln('| --- | --- |')
      ..writeln('| campaign | ${report.planId} (seed ${report.seed}) |')
      ..writeln('| manifest | ${report.manifest.manifestHash} |')
      ..writeln(
        '| corpus | ${report.manifest.corpusId} '
        '(${report.manifest.corpusHash}) |',
      )
      ..writeln(
        '| pinned | ${report.manifest.adapter} · '
        '${report.manifest.providerId}/${report.manifest.modelId} · '
        'effort ${report.manifest.effortLevel ?? 'adapter default'} |',
      )
      ..writeln(
        '| repo | ${report.manifest.repoRef ?? '(unset)'} @ '
        '${report.manifest.baseCommit ?? '(unset)'} |',
      )
      ..writeln('| CLI | ${report.manifest.cliVersion ?? '(built-in)'} |')
      ..writeln('| attempts | ${report.attempts.length} |')
      ..writeln(
        '| recommendation | **${report.overallRecommendation.label}** |',
      )
      ..writeln();

    if (report.planViolations.isNotEmpty) {
      buffer
        ..writeln('## ⚠ Plan violations (adoption blocked)')
        ..writeln();
      for (final violation in report.planViolations) {
        buffer.writeln('- $violation');
      }
      buffer.writeln();
    }

    buffer
      ..writeln('## Arms')
      ..writeln()
      ..writeln(
        '| arm | axis | model | effort | mem | session | mcp cache | overlap | '
        'attempts | verified | rate | cost | \$/verified success | '
        'in/cacheWrite/cacheRead/out | re-reads | round trips | '
        'invalid calls | patch failures | p50 | p95 |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | '
        '--- | --- | --- | --- | --- | --- | --- | --- | --- |',
      );
    for (final summary in report.armSummaries) {
      final effective = summary.effective;
      buffer.writeln(
        '| ${summary.armId} | ${summary.axis.label} | ${effective.modelId} '
        '| ${effective.effortLevel ?? '—'} | ${effective.memoryPolicy.label} '
        '| ${effective.sessionContinuity.wire} '
        '| ${effective.mcpDiscoveryCache.wire} '
        '| ${effective.toolOverlap.wire} | ${summary.attempts} '
        '| ${summary.verifiedSuccesses} '
        '| ${(summary.successRate * 100).toStringAsFixed(0)}% '
        '| ${_usdOrUnknown(summary.totalCostMicros)} '
        '| ${_costPerSuccess(summary.costPerVerifiedSuccessMicros, costComplete: summary.costComplete)} '
        '| ${summary.tokens.uncachedInput}/${summary.tokens.cacheWrite}/'
        '${summary.tokens.cacheRead}/${summary.tokens.output} '
        '| ${summary.meanReReads.toStringAsFixed(1)} '
        '| ${summary.meanRoundTrips.toStringAsFixed(1)} '
        '| ${summary.meanInvalidToolCalls.toStringAsFixed(1)} '
        '| ${summary.meanPatchFailures.toStringAsFixed(1)} '
        '| ${summary.p50LatencyMs.round()}ms '
        '| ${summary.p95LatencyMs.round()}ms |',
      );
    }
    buffer.writeln();

    buffer
      ..writeln('## Cost roles')
      ..writeln()
      ..writeln('| arm | subscription | est. API | billed | aux | advisor |')
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    for (final summary in report.armSummaries) {
      buffer.writeln(
        '| ${summary.armId} | ${_usdOrUnknown(summary.cost.subscriptionMicros)} '
        '| ${_usdOrUnknown(summary.cost.estimatedApiMicros)} '
        '| ${_usdOrUnknown(summary.cost.billedMicros)} '
        '| ${_usdOrUnknown(summary.cost.auxMicros)} '
        '| ${_usdOrUnknown(summary.cost.advisorMicros)} |',
      );
    }
    buffer.writeln();

    final strata = <CacheStratum>{};
    for (final summary in report.armSummaries) {
      strata.addAll(summary.perStratumSuccessRate.keys);
    }
    if (strata.isNotEmpty) {
      final ordered = CacheStratum.values.where(strata.contains).toList();
      buffer
        ..writeln('## Cache strata')
        ..writeln()
        ..writeln('| arm | ${ordered.map((s) => s.label).join(' | ')} |')
        ..writeln('| --- |${ordered.map((_) => ' --- |').join()}');
      for (final summary in report.armSummaries) {
        buffer.writeln(
          '| ${summary.armId} | '
          '${ordered.map((s) {
            final rate = summary.perStratumSuccessRate[s];
            return rate == null ? '—' : '${(rate * 100).toStringAsFixed(0)}%';
          }).join(' | ')} |',
        );
      }
      buffer.writeln();
    }

    buffer
      ..writeln('## Paired verdicts')
      ..writeln();
    if (report.verdicts.isEmpty) {
      buffer.writeln('_None: no baseline arm ran._');
    }
    for (final verdict in report.verdicts) {
      buffer
        ..writeln('### ${verdict.treatmentArmId} vs ${verdict.baselineArmId}')
        ..writeln()
        ..writeln('- quality: **${verdict.verdict.label}** — ${verdict.reason}')
        ..writeln(
          '- pairs ${verdict.pairs} planned ${verdict.expectedPairs}, '
          'effective tasks ${verdict.effectiveTaskCount} '
          '(both pass ${verdict.bothPass}, both fail '
          '${verdict.bothFail}, baseline-only ${verdict.baselineOnlyWins}, '
          'treatment-only ${verdict.treatmentOnlyWins})',
        )
        ..writeln(
          '- task-mean delta '
          '${(verdict.observedDelta * 100).toStringAsFixed(1)}pt, '
          'one-sided bounds ${(verdict.lowerBound * 100).toStringAsFixed(1)}pt '
          'to ${(verdict.upperBound * 100).toStringAsFixed(1)}pt, '
          'margin ${(verdict.margin * 100).toStringAsFixed(1)}pt '
          '(${verdict.method})',
        )
        ..writeln(
          '- cost ratio ${verdict.costRatio?.toStringAsFixed(2) ?? '?'} '
          '(ceiling ${verdict.maxCostRatio.toStringAsFixed(2)})',
        )
        ..writeln(
          '- recommendation: **${verdict.recommendation.label}**'
          '${verdict.blockedTaskIds.isEmpty ? '' : ' · blocked: '
                    '${verdict.blockedTaskIds.join(', ')}'}',
        )
        ..writeln();
    }

    buffer
      ..writeln('## Per-task regressions')
      ..writeln();
    if (report.regressions.isEmpty) {
      buffer.writeln('_None detected._');
    } else {
      buffer
        ..writeln(
          '| task | class | arm | kind | baseline | treatment | detail |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
      for (final regression in report.regressions) {
        buffer.writeln(
          '| ${regression.taskId} | ${regression.taskKind.label} '
          '| ${regression.treatmentArmId} | ${regression.kind.label} '
          '| ${(regression.baselineSuccessRate * 100).toStringAsFixed(0)}% '
          '| ${(regression.treatmentSuccessRate * 100).toStringAsFixed(0)}% '
          '| ${_escape(regression.detail)} |',
        );
      }
    }
    buffer.writeln();

    buffer
      ..writeln('## Attempts')
      ..writeln()
      ..writeln(
        '| # | task | arm | stratum | rep | seed | result | verified | '
        'cost | tokens | round trips | re-reads | error |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | '
        '--- | --- |',
      );
    final rows = report.attempts.take(maxAttemptRows).toList();
    for (final attempt in rows) {
      buffer.writeln(
        '| ${attempt.ordinal} | ${attempt.taskId} | ${attempt.armId} '
        '| ${attempt.stratum.label} | ${attempt.repetition} | ${attempt.seed} '
        '| ${attempt.completed ? (attempt.verificationFailed ? 'fail' : 'ok') : 'error'} '
        '| ${attempt.verifiedSuccess ? 'yes' : 'no'} '
        '| ${_usdOrUnknown(attempt.attemptCostMicros)} '
        '| ${attempt.tokens.totalTokens} '
        '| ${attempt.metrics.modelRoundTrips} '
        '| ${attempt.metrics.reReads} '
        '| ${_escape(attempt.error ?? '')} |',
      );
    }
    if (report.attempts.length > rows.length) {
      buffer.writeln(
        '| … | ${report.attempts.length - rows.length} more in the JSONL |',
      );
    }
    buffer.writeln();

    buffer
      ..writeln('## Unknowns')
      ..writeln();
    if (report.unknowns.isEmpty) {
      buffer.writeln('_None recorded._');
    } else {
      for (final unknown in report.unknowns) {
        buffer.writeln('- $unknown');
      }
    }
    buffer.writeln();

    if (report.caveats.isNotEmpty) {
      buffer
        ..writeln('## Caveats')
        ..writeln();
      for (final caveat in report.caveats) {
        buffer.writeln('- `${caveat.code}` — ${caveat.message}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _usdOrUnknown(int? micros) =>
      micros == null ? '?' : '\$${(micros / 1000000).toStringAsFixed(6)}';

  static String _costPerSuccess(double? micros, {required bool costComplete}) {
    if (!costComplete) {
      return '? (unpriced)';
    }
    return micros == null
        ? '∞ (no verified success)'
        : '\$${(micros / 1000000).toStringAsFixed(6)}';
  }

  static String _escape(String value) =>
      value.replaceAll('\n', ' ').replaceAll('|', r'\|');
}
