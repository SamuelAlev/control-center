import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_labels.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Fixed column widths shared by [PipelineRunRow] and the runs table's column
/// header, so the status / duration / started cells align down the table.
abstract final class PipelineRunRowMetrics {
  /// The leading trigger-glyph slot (manual vs automatic).
  static const double trigger = 16;

  /// The status pill column.
  static const double status = 104;

  /// The active-duration cell.
  static const double duration = 76;

  /// The "started N ago" cell.
  static const double started = 100;

  /// Horizontal row padding.
  static const double hPad = 16;
}

/// One pipeline run as a table row: trigger glyph, pipeline name, then aligned
/// status / duration / started columns. Clicking the row opens the run's page.
///
/// The relative time carries no `AppTimestamp`: the whole row is one tap target,
/// and a nested copy-the-timestamp gesture would swallow that tap. The run's
/// exact start instant lives on the run page.
class PipelineRunRow extends StatelessWidget {
  /// Creates a [PipelineRunRow].
  const PipelineRunRow({
    super.key,
    required this.run,
    required this.now,
    required this.onOpen,
    this.title,
    this.focused = false,
    this.queuePosition,
  });

  /// The run to render.
  final PipelineRun run;

  /// Current time for the live duration / relative start.
  final DateTime now;

  /// Opens this run's page.
  final VoidCallback onOpen;

  /// Friendly pipeline name resolved from the template. Falls back to the run's
  /// template id when null.
  final String? title;

  /// Whether the keyboard cursor is on this row (j/k walk the table; Enter
  /// opens). Distinct from hover and never a selection: the row has no
  /// selected state because opening it navigates away.
  final bool focused;

  /// This run's place in its template's queue, 1 being the next to be admitted.
  /// Null for anything not `queued`. See [pipelineQueuePositions].
  final int? queuePosition;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    // PRD 25 §6: active run time, excluding idle stop→restart gaps — not the
    // wall-clock span, which inflated the duration with overnight stops.
    final duration = run.activeDurationAt(now);
    final label = title ?? run.templateId;
    // A queued run has done no work, so its "duration" was a hard-coded `<1s`
    // in a column of real timings — six of them under two running rows read as
    // six runs that had already finished instantly. The cell carries the queue
    // position instead, which is the one thing about a waiting run worth a
    // column: `next`, then `2nd`, `3rd`, ...
    final position = run.status == PipelineRunStatus.queued
        ? queuePosition
        : null;
    final durationLabel = position != null
        ? (position == 1
              ? l10n.pipelineRunQueueNext
              : l10n.pipelineRunQueuePosition(position))
        : formatPipelineDurationCoarse(duration);
    // The CURRENT attempt's start, matching the run page's header: a rerun
    // restarts the work, and a queue row still reading "3 h ago" for a run
    // whose steps went again five minutes ago is the row nobody trusts.
    final startedLabel = formatPipelineRelative(
      run.currentAttemptStartedAt,
      now,
      l10n,
    );

    final isManual =
        run.triggerEventType == null || run.triggerEventType == 'manual';
    final isWatch =
        run.triggerEventType == IndexCodeTemplate.watchTriggerEventType;
    // The glyph's tooltip NAMES the trigger and, where one was recorded, its
    // reason. It used to say "Automatic" for every non-manual run, which is
    // the one thing about a run the operator can already see — a background
    // reindex fired by a save and a pipeline fired by a merged PR looked
    // identical and neither said why.
    final triggerLabel = isManual
        ? l10n.pipelineRunTriggerManual
        : runTriggerLabel(l10n, run);
    final triggerReason = runTriggerReason(l10n, run);
    final triggerTooltip = triggerReason == null
        ? triggerLabel
        : '$triggerLabel · $triggerReason';

    return CcTappable(
      onPressed: onOpen,
      semanticLabel: position != null
          ? '$label · $triggerTooltip · $durationLabel'
          : '$label · $triggerTooltip · $startedLabel',
      builder: (context, states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return ColoredBox(
          color: focused
              ? tokens.accentSoft
              : hovered
              ? tokens.hover
              : const Color(0x00000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PipelineRunRowMetrics.hPad,
              vertical: 9,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: PipelineRunRowMetrics.trigger,
                  child: CcTooltip(
                    message: triggerTooltip,
                    child: Icon(
                      isManual
                          ? AppIcons.play
                          : isWatch
                          ? AppIcons.filePen
                          : AppIcons.zap,
                      size: 12,
                      color: tokens.fgQuaternary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: PipelineRunRowMetrics.status,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PipelineStatusBadge.forRun(status: run.status),
                  ),
                ),
                SizedBox(
                  width: PipelineRunRowMetrics.duration,
                  child: Text(
                    durationLabel,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      // The queue position is the row's live fact, not a
                      // finished measurement: it reads at the same weight as a
                      // duration but in the running accent, so a waiting block
                      // is scannable without relying on colour alone (the
                      // wording carries it).
                      color: position != null
                          ? tokens.textSecondary
                          : tokens.textTertiary,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: PipelineRunRowMetrics.started,
                  child: Text(
                    startedLabel,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textTertiary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
