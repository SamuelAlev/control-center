import 'package:control_center/features/mcp/application/tools/dispatch_reviewers_tool.dart' show DispatchReviewersTool;

/// Port for dispatching reviewers into a review channel.
///
/// Extracted from [DispatchReviewersTool] so both MCP tools and pipeline
/// step bodies can call it without depending on the MCP layer.
abstract class DispatchReviewersPort {
  /// Dispatches reviewers into [channelId] for [workspaceId].
  ///
  /// Each reviewer in [reviewers] is a map with keys:
  /// `role` (required), `scope?`, `prompt_override?`.
  ///
  /// [concurrency] limits parallel dispatch (default from workspace).
  ///
  /// Returns a map with `dispatched` and `unmatched` lists.
  Future<Map<String, dynamic>> dispatch({
    required String channelId,
    required String workspaceId,
    required List<Map<String, dynamic>> reviewers,
    int? concurrency,
  });
}
