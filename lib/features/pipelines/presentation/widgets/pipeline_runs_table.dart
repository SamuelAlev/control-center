import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The runs list's content pane: one bordered card holding a column header over
/// divided [PipelineRunRow]s — the same table the inbox and the PR queue use, so
/// a run reads like every other work item in the app.
class PipelineRunsTable extends StatelessWidget {
  /// Creates a [PipelineRunsTable].
  const PipelineRunsTable({
    super.key,
    required this.runs,
    required this.now,
    required this.titleFor,
    required this.onOpen,
    this.focusedRunId,
  });

  /// The runs to render, in display order.
  final List<PipelineRun> runs;

  /// Current time for live durations / relative starts.
  final DateTime now;

  /// Resolves a run's friendly pipeline name (null → the row falls back to the
  /// template id).
  final String? Function(PipelineRun run) titleFor;

  /// Opens a run's page.
  final ValueChanged<PipelineRun> onOpen;

  /// The run under the keyboard cursor, if any.
  final String? focusedRunId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ColumnHeaderRow(),
          CcDivider(color: tokens.borderSecondary),
          for (var i = 0; i < runs.length; i++) ...[
            if (i > 0) CcDivider(color: tokens.borderSoft),
            PipelineRunRow(
              run: runs[i],
              now: now,
              title: titleFor(runs[i]),
              focused: runs[i].id == focusedRunId,
              onOpen: () => onOpen(runs[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// The column header, aligned to [PipelineRunRowMetrics]. The status column is
/// deliberately unlabelled — its pills read for themselves, and a "Status"
/// header would be the widest thing in a column of 11px chips.
class _ColumnHeaderRow extends StatelessWidget {
  const _ColumnHeaderRow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = TextStyle(
      color: tokens.idle,
      fontSize: 11,
      height: 1.3,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PipelineRunRowMetrics.hPad,
        vertical: 8,
      ),
      child: Row(
        children: [
          // Reserve the row's trigger-glyph slot so the name column lines up.
          const SizedBox(width: PipelineRunRowMetrics.trigger + AppSpacing.sm),
          Expanded(child: Text(l10n.pipelineRunColumnPipeline, style: style)),
          const SizedBox(width: AppSpacing.md),
          const SizedBox(width: PipelineRunRowMetrics.status),
          SizedBox(
            width: PipelineRunRowMetrics.duration,
            child: Text(
              l10n.pipelineRunColumnDuration,
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
          SizedBox(
            width: PipelineRunRowMetrics.started,
            child: Text(
              l10n.pipelineRunColumnStarted,
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
