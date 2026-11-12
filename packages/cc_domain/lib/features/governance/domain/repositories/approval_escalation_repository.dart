/// How far each pending approval has escalated.
///
/// The tier decides whether the next sweep comments again, so losing it
/// repeats an escalation people already saw: state, never a cache row. It goes
/// with its approval.
abstract interface class ApprovalEscalationRepository {
  /// The highest tier [approvalId] reached, 0 when it never escalated.
  Future<int> tierOf(String workspaceId, String approvalId);

  /// Records that [approvalId] escalated to [tier] (1 or more).
  Future<void> recordTier(String workspaceId, String approvalId, int tier);
}
