import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_document_compiler.dart';
import 'package:uuid/uuid.dart';

/// Approves a plan-mode [PlanDocument] (PRD 17 §8): compiles it into a
/// single-role orchestration proposal and pushes it through the SAME
/// deterministic approve/materialize machinery multi-agent plans use —
/// including partial approval.
///
/// Idempotent: the orchestration id is derived from the plan id, so a crash
/// between insert and approve resumes cleanly.
class PlanDocumentApprovalService {
  /// Creates the service. [approveOrchestration] is the
  /// `ApproveOrchestrationUseCase.approve` entry point.
  PlanDocumentApprovalService({
    required this._plans,
    required this._conversations,
    required this._orchestrations,
    required this._revisions,
    required this._validator,
    required Future<void> Function({
      required String workspaceId,
      required String orchestrationId,
      Set<String>? approvedNodeKeys,
    })
    approveOrchestration,
    this._onApproved,
  }) : _approve = approveOrchestration;

  final PlanDocumentRepository _plans;
  final ConversationRepository _conversations;
  final OrchestrationRepository _orchestrations;
  final OrchestrationRevisionRepository _revisions;
  final OrchestrationProposalValidator _validator;
  final Future<void> Function({
    required String workspaceId,
    required String orchestrationId,
    Set<String>? approvedNodeKeys,
  })
  _approve;

  /// Invoked after a successful approve+materialize.
  ///
  /// Wired to flip the authoring conversation out of plan mode: without it the
  /// plan's own room stayed read-only after approval, so the two halves of
  /// leaving plan mode were unlinked — approving a plan did not change
  /// `spaces.mode` and `exit_plan_mode` did not touch the plan's status.
  /// Optional so the service stays dependency-light and testable. `spaceId`
  /// is the room the plan's conversation belongs to — never the conversation
  /// id, which `spaces.mode` and message sends do not accept.
  final Future<void> Function(
    PlanDocument plan,
    String spaceId,
    String orchestrationId,
  )?
  _onApproved;

  static const _uuid = Uuid();

  /// The deterministic orchestration id a plan document compiles into.
  ///
  /// Delegates to the shared-kernel derivation so the client can follow the
  /// same orchestration (its live run state, its cancel) from a plan id alone.
  static String orchestrationIdFor(String planId) =>
      PlanDocumentCompiler.orchestrationIdFor(planId);

  /// Approves [planId], optionally narrowing to [approvedNodeKeys]
  /// (dependency-closure is enforced downstream by the approve use case).
  /// Returns `{orchestration_id}`.
  Future<Map<String, dynamic>> approve({
    required String workspaceId,
    required String planId,
    Set<String>? approvedNodeKeys,
    int? maxCostCents,
  }) async {
    final doc = await _plans.getById(workspaceId, planId);
    if (doc == null) {
      throw StateError('Plan $planId not found');
    }
    final proposal = PlanDocumentCompiler.toProposal(
      doc,
      agentId: doc.agentId,
      maxCostCents: maxCostCents,
    );
    final violations = _validator.validate(proposal);
    if (violations.isNotEmpty) {
      throw ArgumentError(
        'The compiled plan is not valid:\n${violations.join('\n')}',
      );
    }

    final spaceId = await _spaceOf(doc);
    final orchestrationId = orchestrationIdFor(doc.id);
    final existing = await _orchestrations.getById(
      workspaceId,
      orchestrationId,
    );
    if (existing != null && existing.status == OrchestrationStatus.failed) {
      // Approving a plan whose execution failed runs it again. The approve use
      // case treats any terminal row as done, so without this the plan was
      // stuck: its pipeline template (room id baked into every node) could
      // only be retried as-is. Reset to `proposed` and drop the template and
      // run so both are regenerated; the hires, team and project are kept.
      await _orchestrations.update(_resetForRerun(existing, spaceId));
    } else if (existing != null && existing.spaceId != spaceId) {
      // Written before the space was resolved (it held the conversation id):
      // repoint it so a resumed approval materializes into the real room.
      await _orchestrations.update(
        existing.copyWith(spaceId: spaceId, updatedAt: DateTime.now()),
      );
    }
    if (existing == null) {
      final now = DateTime.now();
      await _orchestrations.insert(
        Orchestration(
          id: orchestrationId,
          workspaceId: workspaceId,
          proposal: proposal,
          // The ROOM the plan was authored in. Storing the conversation id
          // here matched no space, so every generated step failed the instant
          // the run started with "no conversation to work in".
          spaceId: spaceId,
          orchestratorAgentId: doc.agentId,
          estimatedCostCents: proposal.budget.estimatedCostCents,
          maxCostCents: proposal.budget.maxCostCents,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _revisions.record(
        OrchestrationRevision(
          id: _uuid.v4(),
          workspaceId: workspaceId,
          orchestrationId: orchestrationId,
          revision: 1,
          proposal: proposal,
          authoredBy: doc.agentId,
          authorKind: 'agent',
          createdAt: now,
        ),
      );
    }

    if (doc.status != PlanDocumentStatus.approved) {
      await _plans.upsert(
        doc.copyWith(
          status: PlanDocumentStatus.approved,
          updatedAt: DateTime.now(),
        ),
      );
    }
    // BEFORE starting the work, not after.
    //
    // The hook takes the plan's conversation out of plan mode and an agent's
    // permissions are resolved from `spaces.mode` at dispatch time. Since
    // `_approve` starts the pipeline run without awaiting its first step, running
    // the hook afterwards was a race the room usually lost: the first work step
    // dispatched into a space still in plan mode, i.e. read-only, so the
    // approved plan executed with no ability to change anything. The plan row is
    // already `approved` above, so the hook's precondition holds.
    //
    // Best-effort: the plan is approved and materialized either way.
    try {
      await _onApproved?.call(doc, spaceId, orchestrationId);
    } on Object catch (_) {}
    await _approve(
      workspaceId: workspaceId,
      orchestrationId: orchestrationId,
      approvedNodeKeys: approvedNodeKeys,
    );
    return {'orchestration_id': orchestrationId};
  }

  /// [failed] rewound to an unapproved row in [spaceId] with no template or
  /// run, so the next approval regenerates both. `copyWith` cannot clear
  /// fields, hence the explicit rebuild.
  static Orchestration _resetForRerun(Orchestration failed, String spaceId) =>
      Orchestration(
        id: failed.id,
        workspaceId: failed.workspaceId,
        proposal: failed.proposal,
        parentTicketId: failed.parentTicketId,
        spaceId: spaceId,
        orchestratorAgentId: failed.orchestratorAgentId,
        revision: failed.revision,
        teamId: failed.teamId,
        projectId: failed.projectId,
        estimatedCostCents: failed.estimatedCostCents,
        maxCostCents: failed.maxCostCents,
        hiredAgentIds: failed.hiredAgentIds,
        createdAt: failed.createdAt,
        updatedAt: DateTime.now(),
      );

  /// The space [doc]'s conversation lives in. Throws rather than guessing:
  /// a plan whose conversation is gone has nowhere to run.
  Future<String> _spaceOf(PlanDocument doc) async {
    final conversation = await _conversations.getById(
      workspaceId: doc.workspaceId,
      conversationId: doc.conversationId,
    );
    if (conversation == null) {
      throw StateError(
        'Plan ${doc.id}: conversation ${doc.conversationId} no longer exists '
        'in this workspace, so the plan has no space to run in',
      );
    }
    return conversation.spaceId;
  }
}
