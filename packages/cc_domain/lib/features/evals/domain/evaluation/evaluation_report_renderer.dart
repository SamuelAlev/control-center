import 'package:cc_domain/features/evals/domain/evaluation/evaluation_descriptive_summary.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
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
        '| question | ${report.hypothesis.wire} on '
        '${report.primaryOutcome.wire}, k = ${report.repetitions} per arm '
        'per task |',
      )
      ..writeln(
        '| recommendation | **${report.overallRecommendation.label}** |',
      );
    if (report.stoppedAtInterim) {
      buffer.writeln('| stopped | at the interim look |');
    }
    buffer.writeln();

    _descriptive(buffer, report);
    _perTask(buffer, report);

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
      buffer.writeln(
        report.hypothesis == EvaluationHypothesis.calibration
            ? '_None: a calibration plan runs one arm and reaches no verdict '
                  'by design; it measures pass rates and prices._'
            : '_None: no baseline arm ran._',
      );
    }
    for (final verdict in report.verdicts) {
      _verdict(buffer, verdict);
    }

    buffer
      ..writeln('## Per-task regressions (descriptive, block nothing)')
      ..writeln();
    for (final verdict in report.verdicts) {
      final compared = {
        for (final o in report.taskOutcomes)
          if (o.armId == verdict.treatmentArmId) o.taskId,
      }.length;
      buffer.writeln(
        '> ${verdict.treatmentArmId}: identical arms would show a lower '
        'treatment rate on about '
        '${verdict.expectedChanceLosses.toStringAsFixed(1)} of these '
        '$compared task(s) by chance alone.',
      );
    }
    if (report.verdicts.isNotEmpty) {
      buffer.writeln();
    }
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
        '| ${attempt.completed ? (attempt.verificationFailed ? 'fail' : 'ok') : attempt.end.wire} '
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

  /// What the attempts did, arm by arm, marked as counts rather than a
  /// verdict: a campaign whose gate reads Inconclusive still says what
  /// happened.
  static void _descriptive(StringBuffer buffer, EvaluationReport report) {
    final arms = EvaluationDescriptiveArm.of(
      report.attempts,
      armOrder: [for (final summary in report.armSummaries) summary.armId],
    );
    buffer
      ..writeln('## Descriptive numbers (not a verdict)')
      ..writeln()
      ..writeln(
        '> What these attempts did, arm by arm. These are counts, not a '
        'decision: the paired verdicts below decide adoption, and with few '
        'distinct tasks they cannot conclude however the arms compare. '
        'A false completion is a completion with an authoritative check that '
        'ran and failed. An agent that stopped scores as a failure; a harness '
        'fault or a ceiling stop is missing data.',
      )
      ..writeln()
      ..writeln(
        '| arm | attempts | completions | agent stopped | harness faults '
        '| ceiling stops | verified successes | verified rate '
        '| false completions | per attempt | per completion | cost '
        '| mean cost | mean turns | mean round trips |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- '
        '| --- | --- | --- | --- |',
      );
    for (final arm in arms) {
      final falseRate = arm.falseCompletionRate;
      final perAttempt = arm.falseCompletionsPerAttempt;
      final mean = arm.meanCostMicros;
      buffer.writeln(
        '| ${arm.armId} | ${arm.attempts} | ${arm.completions} '
        '| ${arm.agentStopped} | ${arm.harnessFaults} | ${arm.ceilingStopped} '
        '| ${arm.verifiedSuccesses} '
        '| ${(arm.verifiedRate * 100).toStringAsFixed(0)}% '
        '| ${arm.falseCompletions} '
        '| ${perAttempt == null ? '—' : '${(perAttempt * 100).toStringAsFixed(0)}%'} '
        '| ${falseRate == null ? '—' : '${(falseRate * 100).toStringAsFixed(0)}%'} '
        '| ${arm.attempts == 0 ? '—' : _usdOrUnknown(arm.totalCostMicros)} '
        '| ${arm.attempts == 0
            ? '—'
            : mean == null
            ? '?'
            : _usdOrUnknown(mean.round())} '
        '| ${arm.meanTurns.toStringAsFixed(1)} '
        '| ${arm.meanRoundTrips.toStringAsFixed(1)} |',
      );
    }
    buffer.writeln();
    if (arms.every((arm) => arm.goals.isEmpty)) {
      return;
    }
    buffer
      ..writeln(
        '| arm | goal attempts | claimed | accepted | verified by the product '
        '| stopped for a person | failed rounds (mean) |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
    for (final arm in arms) {
      buffer.writeln(
        '| ${arm.armId} | ${arm.goals.length} | ${arm.goalsClaimed} '
        '| ${arm.goalsAccepted} | ${arm.goalsVerified} | ${arm.goalsStopped} '
        '| ${arm.meanFailedRounds.toStringAsFixed(1)} |',
      );
    }
    buffer.writeln();
  }

  /// One treatment's verdict block.
  static void _verdict(StringBuffer buffer, NonInferiorityVerdict verdict) {
    String pts(double v) => (v * 100).toStringAsFixed(1);
    String p(double v) =>
        v < 0.0001 ? v.toStringAsExponential(1) : v.toStringAsFixed(4);
    final margin = verdict.margin;
    final mde = verdict.minimumDetectableEffect;
    final t = verdict.tStatistic;
    buffer
      ..writeln('### ${verdict.treatmentArmId} vs ${verdict.baselineArmId}')
      ..writeln()
      ..writeln(
        '- question: ${verdict.hypothesis.wire} on '
        '${verdict.primaryOutcome.wire}'
        '${margin == null ? '' : ', margin ${pts(margin)} points (absolute)'}'
        ', one-sided alpha ${verdict.alpha}',
      )
      ..writeln(
        '- tasks used ${verdict.effectiveTaskCount} of '
        '${verdict.tasksPlanned} planned (k = ${verdict.repetitions}, '
        '${verdict.informativeTasks} informative)',
      );
    for (final dropped in verdict.droppedTasks) {
      buffer.writeln('  - dropped ${dropped.taskId}: ${dropped.reason}');
    }
    buffer
      ..writeln(
        '- mean difference ${pts(verdict.observedDelta)} points per task '
        '(positive favours the treatment), one-sided bounds '
        '${pts(verdict.lowerBound)} to ${pts(verdict.upperBound)}',
      )
      ..writeln(
        '- t ${t == null ? '—' : t.toStringAsFixed(3)}, df '
        '${verdict.degreesOfFreedom}, p ${p(verdict.pValue)}, sign-flip p '
        '${p(verdict.signFlipP)} (${verdict.method})',
      )
      ..writeln(
        '- smallest effect this size could detect: '
        '${mde == null ? '—' : '${pts(mde)} points'} (observed s '
        '${pts(verdict.standardDeviation)} points)',
      )
      ..writeln(
        '- cost ratio over the used tasks '
        '${verdict.costRatio?.toStringAsFixed(2) ?? '?'} (ceiling '
        '${verdict.maxCostRatio.toStringAsFixed(2)})',
      )
      ..writeln('- verdict: **${verdict.verdict.label}**: ${verdict.reason}')
      ..writeln('- recommendation: **${verdict.recommendation.label}**')
      ..writeln();
  }

  /// Each task's primary-outcome score per arm, with a saturation note: a
  /// task at 0 of k or k of k in every arm carries no information.
  static void _perTask(StringBuffer buffer, EvaluationReport report) {
    final arms = [for (final summary in report.armSummaries) summary.armId];
    final taskIds = {for (final o in report.taskOutcomes) o.taskId};
    if (taskIds.isEmpty || arms.isEmpty) {
      return;
    }
    final k = report.repetitions;
    buffer
      ..writeln('## Per-task scores (${report.primaryOutcome.wire})')
      ..writeln()
      ..writeln(
        '> Score of k = $k per arm, with the mean price per attempt. A task '
        'saturated in every arm (0 of $k or $k of $k) carries no information.',
      )
      ..writeln()
      ..writeln('| task | ${arms.join(' | ')} | note |')
      ..writeln('| --- |${arms.map((_) => ' --- |').join()} --- |');
    for (final taskId in taskIds) {
      final sums = <int>{};
      var allScored = true;
      final cells = <String>[];
      for (final arm in arms) {
        final group = [
          for (final a in report.attempts)
            if (a.taskId == taskId && a.armId == arm) a,
        ];
        final scores = [for (final a in group) ?a.score(report.primaryOutcome)];
        final sum = scores.fold<int>(0, (x, y) => x + y);
        if (scores.length != k) {
          allScored = false;
        }
        sums.add(sum == 0 ? 0 : (sum == k ? k : -1));
        final priced = group.every((a) => a.attemptCostMicros != null);
        final cost = group.isEmpty || !priced
            ? '?'
            : _usdOrUnknown(
                (group.fold<int>(0, (x, a) => x + a.attemptCostMicros!) /
                        group.length)
                    .round(),
              );
        cells.add(
          group.isEmpty
              ? '—'
              : '$sum of ${scores.length}'
                    '${scores.length < k ? ' (${k - scores.length} missing)' : ''}'
                    ' · $cost',
        );
      }
      final note = !allScored
          ? 'incomplete'
          : sums.length == 1 && sums.first != -1
          ? 'saturated: ${sums.first} of $k in every arm'
          : '';
      buffer.writeln('| $taskId | ${cells.join(' | ')} | $note |');
    }
    buffer.writeln();
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
