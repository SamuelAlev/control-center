import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/dispatch/providers/agent_registry_provider.dart';
import 'package:control_center/features/observability/presentation/widgets/agent_transcript_drawer.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/agent_roster_section.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/fleet_section.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/goal_section.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/quota_section.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Live tab: every current-state surface — the agent roster (kill, live
/// elapsed, transcript drawer), quota limits, the active goal budget, and the
/// fleet workers / jobs. Re-ticks every second so elapsed durations stay live.
class LiveTab extends ConsumerStatefulWidget {
  /// Creates a [LiveTab].
  const LiveTab({super.key});

  @override
  ConsumerState<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends ConsumerState<LiveTab> {
  Timer? _ticker;
  String? _selectedAgentId;

  @override
  void initState() {
    super.initState();
    // 1s re-tick keeps "running for 12s" labels live without re-querying.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final rosterAsync = ref.watch(workspaceAgentRosterProvider(workspaceId));
    final runs = ref.watch(workspaceRunLogsProvider);

    // Latest + active run per agent, for stats and the kill pid.
    final latestRun = <String, AgentRunLog>{};
    final activeRun = <String, AgentRunLog>{};
    for (final run in runs) {
      final prev = latestRun[run.agentId];
      if (prev == null || run.startedAt.isAfter(prev.startedAt)) {
        latestRun[run.agentId] = run;
      }
      // Keep the NEWEST uncompleted run per agent, so the kill button targets
      // the live process rather than an older orphaned run's stale pid.
      if (run.completedAt == null) {
        final prevActive = activeRun[run.agentId];
        if (prevActive == null || run.startedAt.isAfter(prevActive.startedAt)) {
          activeRun[run.agentId] = run;
        }
      }
    }

    final agentsSection = rosterAsync.when(
      loading: () => ObsSection(
        title: l10n.obsAgentsTitle,
        icon: AppIcons.bot,
        child: const Center(child: CcSpinner()),
      ),
      error: (e, _) => ObsSection(
        title: l10n.obsAgentsTitle,
        icon: AppIcons.bot,
        child: Text(
          l10n.obsRosterLoadError,
          style: CcTypography.body.copyWith(color: t.textTertiary),
        ),
      ),
      data: (roster) {
        if (roster.isEmpty) {
          return ObsSection(
            title: l10n.obsAgentsTitle,
            icon: AppIcons.bot,
            child: CcEmptyState(
              icon: AppIcons.bot,
              message: l10n.obsRosterEmpty,
              description: l10n.obsRosterEmptyDescription,
            ),
          );
        }
        final sorted = sortObsRoster(roster);
        return AgentRosterSection(
          roster: sorted,
          latestRunByAgent: latestRun,
          activeRunByAgent: activeRun,
          selectedAgentId: _selectedAgentId,
          onSelectAgent: (id) => setState(
            () => _selectedAgentId = id == _selectedAgentId ? null : id,
          ),
        );
      },
    );

    final list = ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        agentsSection,
        const SizedBox(height: AppSpacing.lg),
        const QuotaSection(),
        const SizedBox(height: AppSpacing.lg),
        const GoalSection(),
        const SizedBox(height: AppSpacing.lg),
        const FleetSection(),
      ],
    );

    final selected = rosterAsync.asData?.value
        .where((a) => a.id == _selectedAgentId)
        .firstOrNull;
    if (selected == null) {
      return list;
    }
    return Row(
      children: [
        Expanded(child: list),
        AgentTranscriptDrawer(
          agent: selected,
          latestRun: latestRun[selected.id],
          onClose: () => setState(() => _selectedAgentId = null),
          onKill: activeRun[selected.id]?.pid == null
              ? null
              : () => ref
                    .read(processControlPortProvider)
                    .kill(activeRun[selected.id]!.pid!),
        ),
      ],
    );
  }
}
