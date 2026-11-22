import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';

/// Persistence port for improvement proposals (`improvement_proposals`).
///
/// Every method is workspace-scoped: [insert] takes the workspace from the
/// proposal, every other method takes `workspaceId` first.
///
/// There is no full-row update: a decision and the campaign fields are each
/// one conditional statement, so two people deciding at once never both
/// apply a change.
///
/// A stored proposal the entity refuses (an import or a hand edit) is left
/// out of every read; a read that meets a `proposed` one marks it `expired`,
/// so nobody can accept it.
abstract interface class ImprovementProposalRepository {
  /// Inserts a new proposal. Throws when its id exists.
  Future<void> insert(ImprovementProposal proposal);

  /// Moves the proposal [id] from [from] to [to] (a status other than
  /// `proposed`, and other than [from]), recording [decidedByUserId] and
  /// `decided_at` = [now], and [beforeText], [afterText] and [appliedRef]
  /// when given (null leaves a field as it is). Returns whether this call
  /// moved it: only that caller applies (or rolls back) the change.
  Future<bool> decide(
    String workspaceId, {
    required String id,
    required ImprovementStatus from,
    required ImprovementStatus to,
    required String? decidedByUserId,
    String? beforeText,
    String? afterText,
    String? appliedRef,
    required DateTime now,
  });

  /// Sets the evaluation campaign of the `proposed` proposal [id] whose
  /// campaign state is one of [from]: its [state], [campaignId] and
  /// [candidateRevisionId] (both always written: a null campaign id forgets
  /// the previous campaign, a null candidate drops the staged one). Returns false when the proposal is
  /// no longer proposed, is in another campaign state, or does not exist:
  /// the claim that makes one start, one launch.
  Future<bool> setCampaign(
    String workspaceId, {
    required String id,
    required Set<ImprovementCampaignState> from,
    required String? campaignId,
    required ImprovementCampaignState state,
    required String? candidateRevisionId,
  });

  /// Ends a start's claim on proposal [id]: `campaign_state` `staging` →
  /// [to] with no staged candidate, whatever the proposal's status (a start
  /// that lost to a decision still lets go of its claim). False when it is
  /// not `staging`.
  Future<bool> releaseStaging(
    String workspaceId, {
    required String id,
    required ImprovementCampaignState to,
  });

  /// Records [appliedRef] on the `accepted` proposal [id] that has none yet:
  /// a skill change is claimed first and marked applied once its file is
  /// written, so a row accepted without its mark is one whose write did not
  /// finish. Returns whether this call marked it.
  Future<bool> markApplied(
    String workspaceId, {
    required String id,
    required String appliedRef,
  });

  /// The proposal [id], or null.
  Future<ImprovementProposal?> getById(String workspaceId, String id);

  /// The workspace's proposals, newest first, narrowed to [statuses].
  Future<List<ImprovementProposal>> listForWorkspace(
    String workspaceId, {
    Set<ImprovementStatus>? statuses,
  });

  /// Watches every proposal in the workspace, newest first.
  Stream<List<ImprovementProposal>> watchForWorkspace(String workspaceId);

  /// The proposals made for [goalId], newest first.
  Future<List<ImprovementProposal>> listByGoal(
    String workspaceId,
    String goalId,
  );

  /// The newest proposal made in [conversationId], or null (the 20-minute
  /// cooldown between reviews).
  Future<ImprovementProposal?> latestForConversation(
    String workspaceId,
    String conversationId,
  );

  /// Marks `proposed` proposals whose `expiresAt` is at or before [now]
  /// `expired`, except the ids in [except] (rows whose cleanup failed stay
  /// proposed for the next sweep). Returns how many.
  Future<int> expireDue(
    String workspaceId, {
    required DateTime now,
    required Set<String> except,
  });
}
