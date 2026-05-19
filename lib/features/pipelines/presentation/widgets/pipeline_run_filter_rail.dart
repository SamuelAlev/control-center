import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/count_rail_item.dart';
import 'package:flutter/widgets.dart';

/// Status filter for the runs list. Keeps the operator's most common triage —
/// "what's running" / "what broke" — one click away.
enum PipelineRunFilter {
  /// Every run in the workspace.
  all,

  /// Runs currently executing.
  running,

  /// Runs that ended in failure.
  failed;

  /// Whether [run] belongs in this filter.
  bool matches(PipelineRun run) => switch (this) {
    PipelineRunFilter.all => true,
    PipelineRunFilter.running => run.status == PipelineRunStatus.running,
    PipelineRunFilter.failed => run.status == PipelineRunStatus.failed,
  };

  /// The rail's label for this filter.
  String label(AppLocalizations l10n) => switch (this) {
    PipelineRunFilter.all => l10n.pipelineRunFilterAll,
    PipelineRunFilter.running => l10n.pipelineStatusRunning,
    PipelineRunFilter.failed => l10n.pipelineStatusFailed,
  };
}

/// The runs list's left rail: one entry per status filter with its live count —
/// the inbox rail keyed by run status. Pure navigation; the table beside it is
/// the source of truth.
class PipelineRunFilterRail extends StatelessWidget {
  /// Creates a [PipelineRunFilterRail].
  const PipelineRunFilterRail({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  /// Run count per filter.
  final Map<PipelineRunFilter, int> counts;

  /// The active filter.
  final PipelineRunFilter selected;

  /// Invoked with the tapped filter.
  final ValueChanged<PipelineRunFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final filter in PipelineRunFilter.values)
          CountRailItem(
            label: filter.label(l10n),
            count: counts[filter] ?? 0,
            selected: filter == selected,
            onPressed: () => onSelect(filter),
          ),
      ],
    );
  }
}
