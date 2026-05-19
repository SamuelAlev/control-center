import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/observability/domain/benchmark.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Benchmark / eval providers (PRD 06, feature #13) ─────────────────────────
//
// CC's own agent run history IS the eval set: every completed/errored run is a
// scored trial (reward 1.0 = completed, 0.0 = failed), with real cost, tokens
// and duration. The BenchmarkScorer then computes pass@k, success%, spend, and
// a markdown report — a scored benchmark with spend-per-task, not just
// diagnostics. (Running a fresh task suite against verifiers is left to the
// dispatch harness; this scores what actually ran.)

/// The pure-domain benchmark scorer (pass@k, ETA, markdown report).
final benchmarkScorerProvider = Provider<BenchmarkScorer>(
  (ref) => const BenchmarkScorer(),
);

/// Maps a single run log to a scored benchmark trial.
BenchmarkTrial _trialFromRun(AgentRunLog run) {
  final status = switch (run.status) {
    RunStatus.completed => TrialStatus.pass,
    RunStatus.error => TrialStatus.fail,
    RunStatus.running || RunStatus.pending => TrialStatus.running,
  };
  final durationMs =
      run.cost.durationMs ??
      (run.completedAt != null
          ? run.completedAt!.difference(run.startedAt).inMilliseconds
          : 0);
  final detail = run.status == RunStatus.error
      ? (run.errorCode ?? run.errorFamily?.name ?? run.summary ?? 'failed')
      : '';
  return BenchmarkTrial(
    name: (run.summary?.isNotEmpty ?? false)
        ? run.summary!
        : '${run.agentId.split('-').first} · ${run.id.substring(0, run.id.length.clamp(0, 8))}',
    status: status,
    reward: switch (status) {
      TrialStatus.pass => 1,
      TrialStatus.fail => 0,
      _ => null,
    },
    costCents: run.cost.estimatedCostCents,
    // Each run is its own trial and contributes only its own spend. Subagent
    // cost already appears as the subagent's own trial, so folding the parent's
    // rolled-up `childCostCents` in here too would double-count it in the
    // report's total spend. Keep advisor cost at 0 (no separate advisor spend
    // is tracked per trial).
    advisorCostCents: 0,
    // tokIn includes cache-read (the reference counts cached prefix in input);
    // tokOut folds reasoning into output; tokCache is the cached-read overlap.
    tokIn: run.cost.inputTokens + run.cost.cachedReadTokens,
    tokOut: run.cost.outputTokens + run.cost.thoughtTokens,
    tokCache: run.cost.cachedReadTokens,
    durationMs: durationMs,
    detail: detail,
  );
}

/// A scored benchmark run over the active workspace's recent agent runs.
final workspaceBenchmarkRunProvider = Provider.autoDispose<BenchmarkRun>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider) ?? 'workspace';
  final runs = ref.watch(workspaceRunLogsProvider);
  // Most recent first for the report; only terminal/active runs are trials.
  final ordered = [...runs]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  final trials = ordered.map(_trialFromRun).toList(growable: false);
  // A stable, time-free id (Date.now is avoided in pure providers): the run is
  // derived fresh on every rebuild from live data.
  return BenchmarkRun(
    id: 'eval-$workspaceId',
    dataset: 'agent runs',
    trials: trials,
    expectedTotal: trials.length,
    startedAt: trials.isEmpty
        ? ordered.isEmpty
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : ordered.last.startedAt
        : ordered.last.startedAt,
    finishedAt: ordered.isEmpty ? null : ordered.first.completedAt,
  );
});
