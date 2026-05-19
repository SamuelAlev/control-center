import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_document_compiler.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_estimator.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';

/// Gathers the pure [PlanEstimator]'s inputs from the server's data
/// (PRD 17 §3) and persists the computed per-node estimates back into the
/// stored proposal/plan so an approval records exactly what the operator saw.
///
/// Inputs per honesty rule:
///  - **History**: each role's resolved agent's completed MAIN runs (up to
///    [historyCap] most recent). A role bound to a not-yet-hired agent has no
///    history — its nodes honestly say "no history yet".
///  - **Blast radius**: the union of `impactRadius` subgraphs over each
///    node's `symbol` provenance refs, plus its `file` refs. No provenance →
///    no blast radius, never an inference from prose.
class PlanEstimateService {
  /// Creates the service.
  PlanEstimateService({
    required OrchestrationRepository orchestrations,
    required PlanDocumentRepository planDocuments,
    required AgentRunLogRepository runLogs,
    required CodeGraphRepository codeGraph,
    this.historyCap = 50,
  }) : _orchestrations = orchestrations,
       _plans = planDocuments,
       _runLogs = runLogs,
       _codeGraph = codeGraph;

  final OrchestrationRepository _orchestrations;
  final PlanDocumentRepository _plans;
  final AgentRunLogRepository _runLogs;
  final CodeGraphRepository _codeGraph;

  /// Most-recent completed runs considered per role.
  final int historyCap;

  static const _estimator = PlanEstimator();

  /// Estimates an orchestration's proposal, persists the node estimates into
  /// the stored proposal (same revision — an estimate is not a semantic
  /// edit) and returns the wire payload.
  Future<Map<String, dynamic>> estimateOrchestration(
    String workspaceId,
    String orchestrationId,
  ) async {
    final o = await _orchestrations.getById(workspaceId, orchestrationId);
    if (o == null) {
      throw StateError('Orchestration $orchestrationId not found');
    }
    final estimate = await _estimate(workspaceId, o.proposal);
    await _orchestrations.update(
      o.copyWith(
        proposal: _withEstimates(o.proposal, estimate),
        updatedAt: DateTime.now(),
      ),
    );
    return _toWire(estimate);
  }

  /// Estimates a plan-mode document (compiled through the single-role
  /// wrapper so the authoring agent's history backs every node).
  Future<Map<String, dynamic>> estimatePlanDocument(
    String workspaceId,
    String planId,
  ) async {
    final doc = await _plans.getById(workspaceId, planId);
    if (doc == null) {
      throw StateError('Plan $planId not found');
    }
    final proposal = PlanDocumentCompiler.toProposal(doc, agentId: doc.agentId);
    final estimate = await _estimate(workspaceId, proposal);
    final estimated = _withEstimates(proposal, estimate);
    final byKey = {for (final t in estimated.subTickets) t.key: t};
    await _plans.upsert(
      doc.copyWith(
        graph: PlanGraph(
          nodes: [
            for (final node in doc.graph.nodes)
              node.copyWith(estimate: byKey[node.key]?.estimate),
          ],
        ),
        updatedAt: DateTime.now(),
      ),
    );
    return _toWire(estimate);
  }

  Future<PlanEstimate> _estimate(
    String workspaceId,
    OrchestrationProposal proposal,
  ) async {
    final graph = PlanGraph.fromProposal(proposal);

    final historyByRoleKey = <String, List<RunCost>>{};
    for (final role in proposal.roles) {
      final agentId = role.existingAgentId;
      if (agentId == null || agentId.isEmpty) {
        continue; // A hire has no history — "no history yet" is the truth.
      }
      final runs = await _runLogs.watchByAgent(workspaceId, agentId).first;
      final samples = runs
          .where(
            (r) =>
                r.status == RunStatus.completed && r.role == AgentRunRole.main,
          )
          .take(historyCap)
          .map((r) => r.cost)
          .toList();
      if (samples.isNotEmpty) {
        historyByRoleKey[role.roleKey] = samples;
      }
    }

    final impactByNodeKey = <String, NodeImpact>{};
    for (final node in graph.nodes) {
      final symbolRefs = [
        for (final ref in node.provenance)
          if (ref.kind == 'symbol') ref.ref,
      ];
      final fileRefs = {
        for (final ref in node.provenance)
          if (ref.kind == 'file') ref.ref,
      };
      if (symbolRefs.isEmpty && fileRefs.isEmpty) {
        continue;
      }
      final files = <String>{...fileRefs};
      final symbols = <String>{};
      for (final symbolId in symbolRefs) {
        try {
          final subgraph = await _codeGraph.impactRadius(workspaceId, symbolId);
          for (final s in subgraph.nodes) {
            symbols.add(s.id);
            files.add(s.filePath);
          }
        } catch (_) {
          // Unresolvable symbol ref — count nothing for it.
        }
      }
      impactByNodeKey[node.key] = NodeImpact(
        files: files.length,
        symbols: symbols.length,
      );
    }

    return _estimator.estimate(
      graph: graph,
      historyByRoleKey: historyByRoleKey,
      impactByNodeKey: impactByNodeKey,
      budgetCeilingCents: proposal.budget.maxCostCents,
    );
  }

  OrchestrationProposal _withEstimates(
    OrchestrationProposal proposal,
    PlanEstimate estimate,
  ) => proposal.copyWith(
    subTickets: [
      for (final t in proposal.subTickets)
        t.copyWith(estimate: estimate.byNodeKey[t.key]),
    ],
  );

  Map<String, dynamic> _toWire(PlanEstimate estimate) => {
    'nodes': {
      for (final e in estimate.byNodeKey.entries) e.key: e.value.toJson(),
    },
    if (estimate.totalCostCentsLow != null)
      'total_cost_cents_low': estimate.totalCostCentsLow,
    if (estimate.totalCostCentsHigh != null)
      'total_cost_cents_high': estimate.totalCostCentsHigh,
    if (estimate.totalDurationMsLow != null)
      'total_duration_ms_low': estimate.totalDurationMsLow,
    if (estimate.totalDurationMsHigh != null)
      'total_duration_ms_high': estimate.totalDurationMsHigh,
    if (estimate.budgetCeilingCents != null)
      'budget_ceiling_cents': estimate.budgetCeilingCents,
    'is_partial': estimate.isPartial,
    'exceeds_budget': estimate.exceedsBudget,
  };
}
