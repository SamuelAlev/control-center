import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// One run's metric bar: tokens billed, cost, tool count and duration.
///
/// Extracted from `AgentTranscriptDrawer` so the agent-scoped drawer and the
/// run-scoped activity tab report the same numbers the same way.
///
/// Deliberately carries NO context-window gauge. [RunCost.inputTokens] is the
/// SUM across the run's turns and every turn re-sends the whole conversation —
/// so a 20-turn run reads ~700k "input tokens" against a ~200k window and the
/// gauge pegs at an alarming, meaningless 350%. The sum is a fine billing total,
/// which is what `obsStatTokens` reports; context occupancy is a per-turn peak
/// this entity does not carry.
class RunActivityStatBar extends StatelessWidget {
  /// Creates a [RunActivityStatBar].
  const RunActivityStatBar({
    super.key,
    required this.cost,
    required this.toolCount,
    this.childCostCents = 0,
  });

  /// The run's accumulated cost/token/duration figures, or null when unknown.
  final RunCost? cost;

  /// Number of tool calls in the run's activity.
  final int toolCount;

  /// Cost rolled up from runs this one delegated. Shown as a sub-line on the
  /// cost tile so a parent's delegated spend is visible rather than hidden.
  final int childCostCents;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalTokens = cost?.totalTokens ?? 0;
    final cents = cost?.estimatedCostCents ?? 0;
    // A priced-at-zero run that clearly burned tokens means the model's pricing
    // was not resolvable — say "unknown" rather than assert it was free.
    final costUnknown = cents == 0 && totalTokens > 0;

    return Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.sm,
      children: [
        ObsStatTile(label: l10n.obsStatTokens, value: fmtTokens(totalTokens)),
        ObsStatTile(
          label: l10n.obsStatCost,
          value: costUnknown ? '—' : fmtCents(cents),
          sub: childCostCents > 0
              ? l10n.obsStatDelegatedCost(fmtCents(childCostCents))
              : null,
        ),
        ObsStatTile(label: l10n.obsStatTools, value: '$toolCount'),
        ObsStatTile(
          label: l10n.obsStatDuration,
          value: cost?.durationMs == null || cost!.durationMs == 0
              ? '—'
              : fmtDuration(cost!.durationMs!),
        ),
      ],
    );
  }
}
