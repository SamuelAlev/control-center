import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/agent_transcript_drawer.dart';
import 'package:control_center/features/observability/presentation/widgets/insights/agents_insight_section.dart';
import 'package:control_center/features/observability/presentation/widgets/insights/insights_toolbar.dart';
import 'package:control_center/features/observability/presentation/widgets/insights/kpi_strip.dart';
import 'package:control_center/features/observability/presentation/widgets/insights/run_log_section.dart';
import 'package:control_center/features/observability/presentation/widgets/insights_charts.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/behavior_section.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/cost_breakdown_sections.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Insights tab (default): a global time-range picker + faceted filters
/// over the workspace run log, a KPI strip with vs-previous deltas, activity /
/// cost charts, cost breakdowns, the per-agent table and the granular run
/// log that docks the transcript drawer.
class InsightsTab extends ConsumerStatefulWidget {
  /// Creates an [InsightsTab].
  const InsightsTab({super.key});

  @override
  ConsumerState<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends ConsumerState<InsightsTab> {
  final CcOverlayController _rangeController = CcOverlayController();
  String? _selectedRunId;
  bool _showAllAgents = false;

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final series = ref.watch(insightsSeriesProvider);
    final runs = ref.watch(filteredRunLogsProvider);
    final perAgent = ref.watch(insightsPerAgentProvider);

    final selectedRun = _selectedRunId == null
        ? null
        : runs.where((r) => r.id == _selectedRunId).firstOrNull;

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: InsightsToolbar(rangeController: _rangeController),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const InsightsKpiStrip(),
              const SizedBox(height: AppSpacing.lg),
              ObsSection(
                title: l10n.obsChartActivity,
                icon: AppIcons.activity,
                child: series.buckets.isEmpty
                    ? CcEmptyState(
                        icon: AppIcons.chartColumn,
                        message: l10n.obsNoRunsInRange,
                      )
                    : ObsActivityChart(
                        buckets: series.buckets,
                        kind: series.kind,
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ObsSection(
                title: l10n.obsChartCost,
                icon: AppIcons.chartColumn,
                child: series.buckets.isEmpty
                    ? CcEmptyState(
                        icon: AppIcons.chartColumn,
                        message: l10n.obsNoRunsInRange,
                      )
                    : ObsCostChart(buckets: series.buckets, kind: series.kind),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _BreakdownGrid(),
              const SizedBox(height: AppSpacing.lg),
              AgentsInsightSection(
                showAll: _showAllAgents,
                onToggleShowAll: () =>
                    setState(() => _showAllAgents = !_showAllAgents),
              ),
              const SizedBox(height: AppSpacing.lg),
              RunLogSection(
                selectedRunId: _selectedRunId,
                onSelectRun: (run) {
                  // Runs without a workspace cannot back a transcript drawer;
                  // the row is inert for them.
                  if (run.workspaceId == null) {
                    return;
                  }
                  setState(() => _selectedRunId = run.id);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const BehaviorSection(),
            ],
          ),
        ),
      ],
    );

    if (selectedRun == null) {
      return main;
    }
    final agentName = perAgent
        .where((row) => row.agentId == selectedRun.agentId)
        .firstOrNull
        ?.displayName;
    return Row(
      children: [
        Expanded(child: main),
        AgentTranscriptDrawer(
          agent: AgentRef(
            id: selectedRun.agentId,
            displayName: agentName ?? selectedRun.agentId,
            kind: AgentKind.values.byName(selectedRun.role.name),
            workspaceId: selectedRun.workspaceId!,
            status: AgentStatus.idle,
            createdAt: selectedRun.startedAt,
            lastActivity: selectedRun.lastOutputAt ?? selectedRun.startedAt,
          ),
          latestRun: selectedRun,
          onClose: () => setState(() => _selectedRunId = null),
        ),
      ],
    );
  }
}

/// The cost-breakdown grid: role + token model (+ per-run) beside the by-model
/// card on wide layouts, stacked on narrow ones.
class _BreakdownGrid extends StatelessWidget {
  const _BreakdownGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CostByRoleSection(),
            SizedBox(height: AppSpacing.lg),
            TokenModelSection(),
            SizedBox(height: AppSpacing.lg),
            PerRunSection(),
          ],
        );
        if (constraints.maxWidth >= 880) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: ByModelSection()),
            ],
          );
        }
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            SizedBox(height: AppSpacing.lg),
            ByModelSection(),
          ],
        );
      },
    );
  }
}
