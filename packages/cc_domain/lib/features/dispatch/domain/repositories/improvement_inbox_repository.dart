import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';

/// The person's side of improvement proposals (plan section 13,
/// "Adoption"): what the reviews proposed in the spaces the person may read,
/// and the decisions on them. Every call names its workspace; a refusal
/// carries its `data.kind` (`improvement_already_decided`,
/// `improvement_campaign_required`, `improvement_changed_since`,
/// `improvement_target_missing`, `improvement_campaign_state`,
/// `improvement_admin_required`). Each proposal comes with the server's
/// `needs_admin` ([ImprovementProposalView]).
abstract interface class ImprovementInboxRepository {
  /// The workspace's proposals the person may read, newest first; only
  /// those with [status] when it is given.
  Stream<List<ImprovementProposalView>> watchForWorkspace(
    String workspaceId, {
    required ImprovementStatus? status,
  });

  /// One proposal.
  Future<ImprovementProposalView> get(String workspaceId, String proposalId);

  /// Applies a proposal (a skill change only after its campaign passed).
  Future<ImprovementProposalView> accept(String workspaceId, String proposalId);

  /// Rejects a proposal; a staged skill candidate is taken back.
  Future<ImprovementProposalView> reject(String workspaceId, String proposalId);

  /// Restores the text an accepted proposal replaced, while the current
  /// text is still what it wrote.
  Future<ImprovementProposalView> rollback(String workspaceId, String proposalId);

  /// Stages a skill proposal's candidate and measures it against the
  /// revision before it, with the person's corpus, model and limit.
  Future<ImprovementProposalView> startCampaign(
    String workspaceId,
    String proposalId, {
    required String corpusId,
    required String providerId,
    required String modelId,
    required int repetitions,
    required int budgetMicros,
  });
}
