import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';

/// Compiles an approved single-agent [PlanDocument] into an
/// [OrchestrationProposal] (PRD 17 §8: "the plan flows through the same
/// estimate/partial-approval/execution machinery").
///
/// Pure and deterministic: one role (the authoring agent), the plan's work
/// nodes as sub-tickets, and a generated synthesis step (the validator
/// requires one) that summarizes the executed plan.
///
/// **Staffing is the agent's call, not the compiler's.** The plan executes as
/// the agent that wrote it; if a node would be better done by someone else, that
/// agent delegates (`delegate_task`) or hires a specialist (`hire_agent`) from
/// inside its run, where it can actually judge the work. Compiling a worker per
/// node instead would hire N agents on every approval whether or not the work
/// warranted it.
class PlanDocumentCompiler {
  const PlanDocumentCompiler._();

  /// The single role key every compiled plan uses.
  static const String roleKey = 'planner';

  /// The deterministic id of the orchestration [planId] compiles into.
  ///
  /// Derived, not stored, so both halves agree without a schema change: the
  /// server uses it to make approval idempotent, and the client uses it to
  /// follow (and cancel) an approved plan's execution without waiting for the
  /// approve call's return value.
  static String orchestrationIdFor(String planId) => 'plan_$planId';

  /// Compiles [doc] into a proposal executed entirely by [agentId].
  static OrchestrationProposal toProposal(
    PlanDocument doc, {
    required String agentId,
    int? maxCostCents,
  }) => OrchestrationProposal(
    goal: doc.goal,
    roles: [
      // Not const: existingAgentId is the runtime authoring agent.
      // ignore: prefer_const_constructors
      ProposedRole(
        roleKey: roleKey,
        title: 'Planner',
        existingAgentId: agentId,
      ),
    ],
    subTickets: [
      for (final node in doc.graph.workNodes)
        node.copyWith(roleKey: roleKey).toSubTicket(),
    ],
    synthesis: const SynthesisSpec(
      roleKey: roleKey,
      prompt:
          'Every step of the approved plan has finished. Synthesize the '
          'step outputs into a final summary for the operator: what was '
          'done, what changed, and any follow-ups. List anything that '
          'could not be completed under gaps.',
      outputSchema: {
        'type': 'object',
        'properties': {
          'summary': {'type': 'string'},
          'gaps': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['summary', 'gaps'],
      },
    ),
    budget: BudgetSpec(maxCostCents: maxCostCents),
  );
}
