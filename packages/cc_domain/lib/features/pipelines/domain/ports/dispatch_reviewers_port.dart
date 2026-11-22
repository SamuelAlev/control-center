/// Port for dispatching reviewers into a review space.
///
/// Extracted from `DispatchReviewersTool` so both MCP tools and pipeline
/// step bodies can call it without depending on the MCP layer.
abstract class DispatchReviewersPort {
  /// Dispatches reviewers into [spaceId] for [workspaceId].
  ///
  /// Each reviewer in [reviewers] is a map with keys:
  /// `role` (required), `scope?`, `prompt_override?`.
  ///
  /// [concurrency] limits parallel dispatch (default from workspace).
  ///
  /// [cohortBrief] is the deterministic review-area map (markdown) appended
  /// to each brief so reviewers walk areas in impact order and stamp their
  /// findings with a `cohort_key`. Null sends the brief without it.
  ///
  /// [startedByRunId] is the agent run whose tool call asks for the
  /// reviewers (an attested `dispatch_reviewers` call): each reviewer's run
  /// records it (`WakeContext.startedByRunId`), so it stays in that run's
  /// chain of wakes. Null when no run asks (a person's operation).
  ///
  /// Returns a map with `dispatched` and `unmatched` lists.
  Future<Map<String, dynamic>> dispatch({
    required String spaceId,
    required String workspaceId,
    required List<Map<String, dynamic>> reviewers,
    required String? startedByRunId,
    int? concurrency,
    String? cohortBrief,
  });
}
