import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/features/observability/domain/observability_metrics.dart';
import 'package:cc_domain/features/observability/domain/token_axis_aggregator.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Observability core providers (PRD 06) ────────────────────────────────────
//
// Every analytic here is computed CLIENT-SIDE from the existing
// `agent_run_log.watchAll` RPC stream — no new persisted surface. Reads are
// scoped to the active workspace; an absent workspace yields empty results
// rather than leaking another workspace's runs.

/// The pure-domain 5-axis aggregator.
final tokenAxisAggregatorProvider = Provider<TokenAxisAggregator>(
  (ref) => const TokenAxisAggregator(),
);

/// The pure-domain observability-metrics calculator.
final observabilityMetricsCalculatorProvider =
    Provider<ObservabilityMetricsCalculator>(
      (ref) => const ObservabilityMetricsCalculator(),
    );

/// How many recent runs the observability surfaces aggregate over. Bounds
/// both server work and client retention: the unbounded `watchAll` feed
/// re-materializes the whole run history on every run-log write and pins it
/// in the Riverpod cache for the process lifetime.
const int kObservabilityRunWindow = 2000;

/// Live stream of the [kObservabilityRunWindow] most recent run logs across
/// all workspaces (the global RPC feed), newest first.
/// CROSS-WORKSPACE BY DESIGN — immediately narrowed to the active workspace by
/// [workspaceRunLogsProvider]; never expose this directly to a workspace UI.
/// `autoDispose` so the snapshot is released when the observability surfaces
/// unmount instead of living for the rest of the session.
final allRunLogsProvider = StreamProvider.autoDispose<List<AgentRunLog>>(
  (ref) => ref
      .watch(agentRunLogRepositoryProvider)
      .watchRecent(kObservabilityRunWindow),
);

/// Run logs for the active workspace, with each run's role RESOLVED for cost
/// attribution: a run persisted as [AgentRunRole.main] whose agent reports to a
/// parent is re-attributed to [AgentRunRole.sub], so "main vs subagents" splits
/// meaningfully even before the live dispatch path stamps explicit roles.
/// Advisor runs keep their persisted role.
final workspaceRunLogsProvider = Provider.autoDispose<List<AgentRunLog>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const [];
  }
  final all = ref.watch(allRunLogsProvider).asData?.value ?? const [];
  final agents =
      ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
      const <Agent>[];
  final parented = <String, bool>{
    for (final a in agents) a.id: a.reportsTo != null,
  };
  final scoped = <AgentRunLog>[];
  for (final run in all) {
    if (run.workspaceId != workspaceId) {
      continue;
    }
    // Resolve effective role: keep an explicit sub/advisor; promote a
    // main-by-default run to sub when its agent reports to a parent.
    if (run.role == AgentRunRole.main && (parented[run.agentId] ?? false)) {
      scoped.add(run.copyWith(role: AgentRunRole.sub));
    } else {
      scoped.add(run);
    }
  }
  return scoped;
});
