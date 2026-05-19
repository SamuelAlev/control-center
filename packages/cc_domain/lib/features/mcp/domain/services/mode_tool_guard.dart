import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';

/// MCP-layer guard consulted by the dispatcher to enforce per-mode tool
/// allow-lists.
///
/// Replaces the original `ReviewSpaceToolGuard`, which keyed off the
/// `review_spaces` association table. The new shape keys off the
/// `spaces.mode` column so the guard generalizes to plan mode (and any
/// future mode) without needing a separate join table.
///
/// **Server-authoritative mode resolution.** The guard never trusts a
/// client-supplied `space_id` as the sole authority: when a call omits one
/// it falls back to the calling agent's *active run* (resolved from the DB via
/// [AgentRunLogRepository]) to recover the conversation it is working in.
/// Without this, an agent in review/plan mode could escape its restrictions by
/// simply not passing `space_id`.
///
/// **Maintenance note:** the allow-lists themselves live in [ModeToolPolicy]
/// (pure data, shared with the built-in harness registry so the two paths
/// cannot diverge). When adding a new mutating MCP tool, decide whether it
/// belongs in `ModeToolPolicy.reviewAllowed` / `planAllowed` /
/// `orchestrateAllowed`. The default is "no" — the absence of an entry means
/// the tool is rejected in that mode.
class ModeToolGuard {
  /// Creates a new [ModeToolGuard].
  ModeToolGuard(this._resolver, {AgentRunLogRepository? runLogs})
    : _runLogs = runLogs;

  final ModeResolver _resolver;
  final AgentRunLogRepository? _runLogs;

  /// Returns null when the call is allowed for the caller's conversation
  /// mode, or an error message describing the refusal. Refusals are surfaced
  /// to the calling agent so the model adapts rather than silently swallowing
  /// the failure.
  ///
  /// Mode is resolved server-side: from [spaceId] when supplied, otherwise
  /// from the calling agent's active run (via [agentId]). An agent cannot
  /// escape its mode by omitting `space_id`. [workspaceId] scopes both
  /// lookups, so a space or agent id from another workspace resolves to no
  /// mode rather than that workspace's mode.
  Future<String?> rejectIfDisallowed(
    String toolName, {
    required String workspaceId,
    String? spaceId,
    String? agentId,
  }) async {
    final mode = await resolveMode(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
    );
    if (mode == null || isAllowed(toolName, mode)) {
      return null;
    }
    return refusalMessage(toolName, mode);
  }

  /// Resolves the caller's conversation mode server-side, or `null` when there
  /// is no conversation to scope to (an unscoped call — treated as
  /// unrestricted, same as chat). Prefer this + [isAllowed] when checking many
  /// tools at once (e.g. `list_my_tools`) so the mode is resolved from the DB
  /// exactly once instead of per tool. [workspaceId] scopes every lookup.
  Future<Mode?> resolveMode({
    required String workspaceId,
    String? spaceId,
    String? agentId,
  }) async {
    final resolvedSpaceId = await _resolveConversationId(
      workspaceId,
      spaceId,
      agentId,
    );
    if (resolvedSpaceId == null) {
      return null;
    }
    return _resolver.resolveForConversation(workspaceId, resolvedSpaceId);
  }

  /// Whether [toolName] is permitted in [mode]. Pure and in-memory; delegates
  /// to the shared [ModeToolPolicy] table.
  bool isAllowed(String toolName, Mode mode) =>
      ModeToolPolicy.isAllowed(toolName, mode);

  /// The refusal message surfaced when [toolName] is blocked in [mode]. Only
  /// meaningful when [isAllowed] returns false; returns an empty string for the
  /// unrestricted [Mode.chat].
  String refusalMessage(String toolName, Mode mode) => switch (mode) {
    Mode.chat => '',
    Mode.review =>
      'Tool `$toolName` is not available in a review-mode conversation. '
          'Review spaces are restricted to commentary, suggestions, '
          'ticket creation and orchestration — not mutations of unrelated '
          'state. If you need to take action on the result of this review, '
          'finalize the review and let the user act on the published '
          'summary.',
    Mode.plan =>
      'Tool `$toolName` is not available in a plan-mode conversation. Plan '
          'agents produce a plan and do not execute. To begin executing, '
          'call `exit_plan_mode` to request approval — a human must approve '
          'before this conversation leaves plan mode and mutating tools '
          'unlock.',
    Mode.orchestrate =>
      'Tool `$toolName` is not available in orchestrate mode. Research the '
          'request and call `propose_orchestration` once with the full '
          'plan. Hiring agents, creating sub-tickets and completing work '
          'all happen deterministically AFTER the user approves your '
          'proposal — do not attempt them here.',
  };

  /// Resolves the conversation a call belongs to. Prefers an explicit
  /// [spaceId]; otherwise falls back to the calling agent's active run so
  /// an agent cannot dodge its mode by omitting `space_id`.
  Future<String?> _resolveConversationId(
    String workspaceId,
    String? spaceId,
    String? agentId,
  ) async {
    if (spaceId != null && spaceId.isNotEmpty) {
      return spaceId;
    }
    if (agentId == null || agentId.isEmpty || _runLogs == null) {
      return null;
    }
    final activeRun = await _runLogs.activeRunForAgent(workspaceId, agentId);
    return activeRun?.conversationId ?? activeRun?.spaceId;
  }
}
