import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_label.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';

/// A horizontal timing waterfall over a run's step-runs: each bar is offset and
/// sized to the step's slice of the run's wall-clock window. Failed steps
/// expand their error inline. A restarted step also draws its archived previous
/// tries as faded ghost bars, so a retried failure keeps its place on the
/// timeline instead of being overwritten by the new attempt. Reads only the
/// persisted step-run rows — no new data plumbing.
///
/// The header shows the run's **active** duration (PRD 25 §6) — the sum of the
/// time it was actually running — and, when a stop→restart gap exists, a
/// discontinuity chip labelling the excluded idle time. The step bars stay
/// scaled to the wall-clock window so their relative positions are unchanged.
///
/// **Collapsed by default.** On a long pipeline the bars pushed the canvas — the
/// thing you actually navigate — off screen, so the timing detail sits behind a
/// disclosure whose summary row (active total + idle gap) is the part worth
/// glancing at. Expanded, the bars scroll inside a capped height rather than
/// growing the column without limit.
class PipelineRunWaterfall extends StatefulWidget {
  /// Creates a [PipelineRunWaterfall].
  const PipelineRunWaterfall({
    super.key,
    required this.run,
    required this.stepRuns,
    required this.definition,
    required this.now,
    this.costByStepId = const {},
    this.initiallyExpanded = false,
  });

  /// The run these step-runs belong to — source of the active-duration total.
  final PipelineRun run;

  /// The run's step-runs (latest per step), ordered by start.
  final List<PipelineStepRun> stepRuns;

  /// The pipeline definition (for step labels).
  final PipelineDefinition definition;

  /// Current time, ticked by the caller, for live (unfinished) bar widths.
  /// Ignored once the run has a `finishedAt`: a stopped run's timeline is
  /// frozen there so it can't keep growing off a step row left open.
  final DateTime now;

  /// Per-step cost in US cents, keyed by template step id. Empty when no
  /// agent runs were dispatched (or cost has not rolled up yet).
  final Map<String, int> costByStepId;

  /// Whether the bars start expanded. Defaults to false — see the class doc.
  final bool initiallyExpanded;

  @override
  State<PipelineRunWaterfall> createState() => _PipelineRunWaterfallState();
}

class _PipelineRunWaterfallState extends State<PipelineRunWaterfall> {
  /// Tallest the bars get before they scroll instead of pushing the canvas down
  /// (~9 rows), so a 40-step pipeline can't own the screen.
  static const double _maxBarsHeight = 180;

  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final stepRuns = widget.stepRuns;
    final definition = widget.definition;
    final now = widget.now;

    if (stepRuns.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // A finished run's timeline is frozen at its end, never at `now`. An
    // interrupted run can leave a step row without a `finishedAt` and reading
    // the live clock for those rows kept the bars — and the idle gap below —
    // growing for hours after the run had actually stopped.
    final clock = run.finishedAt ?? now;

    final ordered = [...stepRuns]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    // The window opens at the earliest thing that ever ran — including the
    // ARCHIVED first try of a restarted step, whose start predates the row's
    // re-stamped `startedAt` — or a retry's ghost bars would land off-scale.
    final runStart = ordered
        .map(
          (s) => s.priorAttempts.isEmpty
              ? s.startedAt
              : s.priorAttempts.first.startedAt,
        )
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final runEnd = ordered
        .map((s) => s.finishedAt ?? clock)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final totalMs = runEnd
        .difference(runStart)
        .inMilliseconds
        .clamp(1, 1 << 31);

    // Run-level total is the ACTIVE duration (excludes idle stop→restart gaps).
    // The wall-clock span (first step start → last step end) still drives the
    // bars; the difference between the two is the idle time we surface as a
    // discontinuity chip so the numbers don't look inconsistent. A >2s floor
    // avoids flagging ordinary scheduling skew as a gap.
    final activeDuration = run.activeDurationAt(clock);
    final idleMs = totalMs - activeDuration.inMilliseconds;
    final hasGap = idleMs > 2000;

    final bars = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in ordered)
          _WaterfallRow(
            stepRun: s,
            label: renderStepLabel(
              definition.step(s.stepId)?.config.label,
              state: widget.run.state,
              trigger: widget.run.triggerPayload,
              fallback: s.stepId,
            ),
            runStartMs: runStart.millisecondsSinceEpoch,
            totalMs: totalMs,
            clock: clock,
            costCents: widget.costByStepId[s.stepId],
            tokens: t,
            theme: theme,
          ),
      ],
    );

    // Both rules are full-bleed by construction: the bottom border lives on
    // the decoration (padding inside it, exactly like the meta strip above),
    // and the header/bars seam is inset-free, so the canvas's vertical seam
    // below lands on a continuous border instead of dangling in a gap.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderSecondary)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Semantics(
                button: true,
                expanded: _expanded,
                label: l10n.pipelineWaterfallTimeline,
                child: CcTappable(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  builder: (context, states) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: _expanded ? 0 : -0.25,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            AppIcons.chevronDown,
                            size: 14,
                            color: t.fgQuaternary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.pipelineWaterfallTimeline,
                          style: CcTypography.caption.copyWith(
                            color: t.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.pipelineWaterfallActive(
                            formatPipelineDuration(activeDuration),
                          ),
                          style: CcTypography.caption.copyWith(
                            color: t.textTertiary,
                          ),
                        ),
                        if (hasGap) ...[
                          const SizedBox(width: 8),
                          _GapChip(idleMs: idleMs, tokens: t, theme: theme),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_expanded) ...[
              const CcDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: _maxBarsHeight),
                  child: SingleChildScrollView(child: bars),
                ),
              ),
            ],
          ],
        ),
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
    required this.clock,
    required this.costCents,
    required this.tokens,
    required this.theme,
  });

  final PipelineStepRun stepRun;
  final String label;
  final int runStartMs;
  final int totalMs;

  /// End of the timeline for rows that have no `finishedAt`: `now` while the
  /// run is live, the run's own `finishedAt` once it is not.
  final DateTime clock;
  final int? costCents;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final stepEnd = stepRun.finishedAt ?? clock;
    final start = stepRun.startedAt.millisecondsSinceEpoch - runStartMs;
    final end = stepEnd.millisecondsSinceEpoch - runStartMs;
    final leftFrac = (start / totalMs).clamp(0.0, 1.0);
    final widthFrac = ((end - start) / totalMs).clamp(0.0, 1.0);
    // Floored at zero: a step still open when its run stopped can carry a
    // `startedAt` past the run's `finishedAt`.
    final durationMs = stepEnd
        .difference(stepRun.startedAt)
        .inMilliseconds
        .clamp(0, 1 << 31);
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
                  style: CcTypography.caption.copyWith(
                    color: tokens.textSecondary,
                  ),
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
                          // Ghost bars: the step's superseded tries (Retry /
                          // crash-resume re-opened the same row). Faded, same
                          // status hue — the failure's trail stays visible
                          // around the live bar instead of being overwritten
                          // by it. An interrupted try ends where the next one
                          // began; the row's own start bounds the last.
                          for (var i = 0; i < stepRun.priorAttempts.length; i++)
                            () {
                              final a = stepRun.priorAttempts[i];
                              final aStart =
                                  a.startedAt.millisecondsSinceEpoch -
                                  runStartMs;
                              final aEndMs =
                                  (a.finishedAt ??
                                          (i + 1 < stepRun.priorAttempts.length
                                              ? stepRun
                                                    .priorAttempts[i + 1]
                                                    .startedAt
                                              : stepRun.startedAt))
                                      .millisecondsSinceEpoch -
                                  runStartMs;
                              final aLeft = (aStart / totalMs).clamp(0.0, 1.0);
                              final aWidth = ((aEndMs - aStart) / totalMs)
                                  .clamp(0.0, 1.0);
                              return Positioned(
                                left: w * aLeft,
                                width: (w * aWidth).clamp(2.0, w),
                                top: 0,
                                bottom: 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      a.status,
                                    ).withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            }(),
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
                      (stepRun.attemptCount > 1
                          ? ' ×${stepRun.attemptCount}'
                          : ''),
                  textAlign: TextAlign.right,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textQuaternary,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  (costCents != null && costCents! > 0)
                      ? _fmtCost(costCents!)
                      : '',
                  textAlign: TextAlign.right,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
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
                style: CcTypography.caption.copyWith(
                  color: tokens.textErrorPrimary,
                ),
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

/// A muted chip marking a stop→restart discontinuity: the run sat idle for
/// [idleMs] (excluded from the active total). The leading dashes read as a
/// break in the timeline. Carries a tooltip because "idle" alone doesn't say
/// what the number measures.
class _GapChip extends StatelessWidget {
  const _GapChip({
    required this.idleMs,
    required this.tokens,
    required this.theme,
  });

  final int idleMs;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.pipelineWaterfallIdle(
      formatPipelineDuration(Duration(milliseconds: idleMs)),
    );
    return CcTooltip(
      message: l10n.pipelineWaterfallIdleTooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: tokens.bgSecondary,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: Text(
          '┄ $label',
          style: CcTypography.caption.copyWith(color: tokens.textQuaternary),
        ),
      ),
    );
  }
}
