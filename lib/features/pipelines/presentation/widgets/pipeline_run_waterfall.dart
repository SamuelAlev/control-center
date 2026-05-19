import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:flutter/material.dart';

/// A horizontal timing waterfall over a run's step-runs: each bar is offset and
/// sized to the step's slice of the run's wall-clock window. Failed steps
/// expand their error inline. Reads only the persisted step-run timestamps —
/// no new data plumbing.
class PipelineRunWaterfall extends StatelessWidget {
  /// Creates a [PipelineRunWaterfall].
  const PipelineRunWaterfall({
    super.key,
    required this.stepRuns,
    required this.definition,
    required this.now,
    this.costByStepId = const {},
  });

  /// The run's step-runs (latest per step), ordered by start.
  final List<PipelineStepRun> stepRuns;

  /// The pipeline definition (for step labels).
  final PipelineDefinition definition;

  /// Current time, ticked by the caller, for live (unfinished) bar widths.
  final DateTime now;

  /// Per-step cost in US cents, keyed by template step id. Empty when no
  /// agent runs were dispatched (or cost has not rolled up yet).
  final Map<String, int> costByStepId;

  @override
  Widget build(BuildContext context) {
    if (stepRuns.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);

    final ordered = [...stepRuns]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final runStart = ordered.first.startedAt;
    final runEnd = ordered
        .map((s) => s.finishedAt ?? now)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final totalMs = runEnd.difference(runStart).inMilliseconds.clamp(1, 1 << 31);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in ordered)
            _WaterfallRow(
              stepRun: s,
              label: definition.step(s.stepId)?.config.label ?? s.stepId,
              runStartMs: runStart.millisecondsSinceEpoch,
              totalMs: totalMs,
              now: now,
              costCents: costByStepId[s.stepId],
              tokens: t,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _WaterfallRow extends StatelessWidget {
  const _WaterfallRow({
    required this.stepRun,
    required this.label,
    required this.runStartMs,
    required this.totalMs,
    required this.now,
    required this.costCents,
    required this.tokens,
    required this.theme,
  });

  final PipelineStepRun stepRun;
  final String label;
  final int runStartMs;
  final int totalMs;
  final DateTime now;
  final int? costCents;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final start = stepRun.startedAt.millisecondsSinceEpoch - runStartMs;
    final end = (stepRun.finishedAt ?? now).millisecondsSinceEpoch - runStartMs;
    final leftFrac = (start / totalMs).clamp(0.0, 1.0);
    final widthFrac = ((end - start) / totalMs).clamp(0.0, 1.0);
    final durationMs =
        (stepRun.finishedAt ?? now).difference(stepRun.startedAt).inMilliseconds;
    final color = _statusColor(stepRun.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 7,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    return SizedBox(
                      height: 14,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: tokens.bgSecondary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Positioned(
                            left: w * leftFrac,
                            width: (w * widthFrac).clamp(2.0, w),
                            top: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(
                  _fmtDuration(durationMs) +
                      (stepRun.attemptCount > 1 ? ' ×${stepRun.attemptCount}' : ''),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: tokens.textQuaternary),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  (costCents != null && costCents! > 0)
                      ? _fmtCost(costCents!)
                      : '',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: tokens.textTertiary),
                ),
              ),
            ],
          ),
          if (stepRun.status == PipelineStepStatus.failed &&
              stepRun.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                stepRun.errorMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tokens.textErrorPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(PipelineStepStatus s) => switch (s) {
        PipelineStepStatus.completed => tokens.fgBrandPrimary,
        PipelineStepStatus.running => tokens.accent,
        PipelineStepStatus.suspended => tokens.textQuaternary,
        PipelineStepStatus.failed => tokens.textErrorPrimary,
        PipelineStepStatus.skipped => tokens.borderSecondary,
        PipelineStepStatus.pending => tokens.borderSecondary,
        _ => tokens.textQuaternary,
      };

  String _fmtCost(int cents) {
    final dollars = cents / 100;
    if (dollars < 0.01) {
      return '<\$0.01';
    }
    return '\$${dollars.toStringAsFixed(2)}';
  }

  String _fmtDuration(int ms) {
    if (ms < 1000) {
      return '${ms}ms';
    }
    final s = ms / 1000;
    if (s < 60) {
      return '${s.toStringAsFixed(1)}s';
    }
    final m = s / 60;
    return '${m.toStringAsFixed(1)}m';
  }
}
