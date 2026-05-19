import 'package:cc_domain/core/domain/ports/conversation_mode_resolver.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';

/// MCP-layer guard consulted by the dispatcher to enforce per-mode tool
/// allow-lists.
///
/// Replaces the original `ReviewChannelToolGuard`, which keyed off the
/// `review_channels` association table. The new shape keys off the
/// `channels.mode` column so the guard generalizes to plan mode (and any
/// future mode) without needing a separate join table.
///
/// **Server-authoritative mode resolution.** The guard never trusts a
/// client-supplied `channel_id` as the sole authority: when a call omits one
/// it falls back to the calling agent's *active run* (resolved from the DB via
/// [AgentRunLogRepository]) to recover the conversation it is working in.
/// Without this, an agent in review/plan mode could escape its restrictions by
/// simply not passing `channel_id`.
///
/// **Maintenance note:** when adding a new mutating MCP tool, decide whether
/// it belongs in [_reviewAllowed] / [_planAllowed] / [_orchestrateAllowed].
/// The default is "no" — the absence of an entry means the tool is rejected in
/// that mode.
class ConversationModeToolGuard {
  /// Creates a new [ConversationModeToolGuard].
  ConversationModeToolGuard(this._resolver, {AgentRunLogRepository? runLogs})
      : _runLogs = runLogs;

  final ConversationModeResolver _resolver;
  final AgentRunLogRepository? _runLogs;

  /// Knowledge-memory tools that are *always* permitted regardless of mode.
  ///
  /// Contributing to and reading shared memory is not a mutation of the
  /// reviewed/planned artifact — it is how knowledge survives across runs and
  /// agents. Blocking it in review/plan mode (the original behaviour) is the
  /// reason agents almost never wrote facts and never wrote policies. Sandbox
  /// filesystem write rules are untouched; these are knowledge writes only.
  static const Set<String> _memoryKnowledgeTools = {
    'search_memory',
    'propose_fact',
    'propose_policy',
    'supersede_fact',
    'supersede_policy',
    'record_observation',
    'update_my_notes',
    'get_my_notes',
    'list_memory_domains',
    'list_policies',
  };

  /// Code-graph tools — read-only, always permitted.
  static const Set<String> _codeGraphTools = {
    'search_code',
    'code_symbol',
    'code_callers',
    'code_callees',
    'code_impact',
  };

  /// Tools available to any participant in a review-mode conversation.
  ///
  /// Curated allow-list — anything not listed here is rejected. Covers the
  /// review-participation verbs, communication, read-only context fetchers,
  /// the CEO-only orchestration verbs, and (critically) the ticket-completion
  /// verbs that pipeline agents — which run in review mode — must call to
  /// finish their work.
  static const Set<String> _reviewAllowed = {
    ..._memoryKnowledgeTools,
    ..._codeGraphTools,
    // Review participation
    'add_review_node',
    'confirm_review_node',
    'dismiss_review_node',
    'request_peer_review',
    // Communication
    'send_channel_message',
    'send_thread_reply',
    'get_channel_messages',
    'consult_agent',
    // Context gathering (read-only)
    'get_pr_diff',
    'get_pr_check_runs',
    'list_github_pr_reviews',
    'get_github_file_content',
    'list_repos',
    'list_agents',
    'list_skills',
    'read',
    // Ticketing (review channels can capture + link work, submit their own
    // run output, not reassign external work)
    'create_ticket',
    'list_tickets',
    'get_ticket',
    'link_ticket_to_pr',
    'submit_output',
    'fail_ticket',
    'comment_on_ticket',
    // CEO-only orchestration (still review-scoped)
    'delegate_review',
    'propose_hire',
    'finalize_review',
    'publish_review_to_github',
    'start_ai_review',
    // User-facing UI prompts
    'request_confirmation',
    'ask_user_question',
  };

  /// Tools available to any participant in a plan-mode conversation.
  ///
  /// Plan agents write via the filesystem (timestamped plan files), not via
  /// MCP, so this set is intentionally a subset of [_reviewAllowed] minus
  /// the review-specific verbs and external ticket actions — but it keeps the
  /// memory/code-graph tools and ticket completion so a plan agent dispatched
  /// against a ticket can still close it out.
  static const Set<String> _planAllowed = {
    ..._memoryKnowledgeTools,
    ..._codeGraphTools,
    // Communication
    'send_channel_message',
    'send_thread_reply',
    'get_channel_messages',
    'consult_agent',
    // Read-only context
    'get_pr_diff',
    'get_github_file_content',
    'list_repos',
    'list_agents',
    'list_skills',
    'read',
    'propose_hire',
    // Ticketing
    'list_tickets',
    'get_ticket',
    'submit_output',
    'fail_ticket',
    'comment_on_ticket',
    // User-facing UI prompts
    'request_confirmation',
    'ask_user_question',
  };

  /// Tools available to the orchestrator agent in an orchestrate-mode
  /// conversation. Research + read tools + the single proposal-emitting verb.
  /// Hiring/decomposition/ticket-completion happen deterministically *after*
  /// the user approves the proposal — never by the orchestrator mid-run — so
  /// `hire_agent`, `delegate_ticket`, `complete_ticket`, and `fail_ticket` are
  /// intentionally excluded.
  static const Set<String> _orchestrateAllowed = {
    ..._memoryKnowledgeTools,
    ..._codeGraphTools,
    'propose_orchestration',
    'send_channel_message',
    'send_thread_reply',
    'get_channel_messages',
    'consult_agent',
    'get_pr_diff',
    'get_github_file_content',
    'list_repos',
    'list_agents',
    'list_skills',
    'list_tickets',
    'get_ticket',
    'read',
    'request_confirmation',
    'ask_user_question',
  };

  /// Returns null when the call is allowed for the caller's conversation
  /// mode, or an error message describing the refusal. Refusals are surfaced
  /// to the calling agent so the model adapts rather than silently swallowing
  /// the failure.
  ///
  /// Mode is resolved server-side: from [channelId] when supplied, otherwise
  /// from the calling agent's active run (via [agentId]). An agent cannot
  /// escape its mode by omitting `channel_id`.
  Future<String?> rejectIfDisallowed(
    String toolName, {
    String? channelId,
    String? agentId,
  }) async {
    final resolvedChannelId =
        await _resolveConversationId(channelId, agentId);
    if (resolvedChannelId == null) {
      return null;
    }
    final mode = await _resolver.resolveForConversation(resolvedChannelId);
    switch (mode) {
      case ConversationMode.chat:
        return null;
      case ConversationMode.review:
        if (_reviewAllowed.contains(toolName)) {
          return null;
        }
        return 'Tool `$toolName` is not available in a review-mode '
            'conversation. Review channels are restricted to commentary, '
            'suggestions, ticket creation, and orchestration — not '
            'mutations of unrelated state. If you need to take action on '
            'the result of this review, finalize the review and let the '
            'user act on the published summary.';
      case ConversationMode.plan:
        if (_planAllowed.contains(toolName)) {
          return null;
        }
        return 'Tool `$toolName` is not available in a plan-mode '
            'conversation. Plan agents emit a written plan file in the '
            'conversation plans directory and do not call mutating tools. '
            'Hand the plan back to the user and let them carry it out.';
      case ConversationMode.orchestrate:
        if (_orchestrateAllowed.contains(toolName)) {
          return null;
        }
        return 'Tool `$toolName` is not available in orchestrate mode. '
            'Research the request and call `propose_orchestration` once with '
            'the full plan. Hiring agents, creating sub-tickets, and completing '
            'work all happen deterministically AFTER the user approves your '
            'proposal — do not attempt them here.';
    }
  }

  /// Resolves the conversation a call belongs to. Prefers an explicit
  /// [channelId]; otherwise falls back to the calling agent's active run so
  /// an agent cannot dodge its mode by omitting `channel_id`.
  Future<String?> _resolveConversationId(
    String? channelId,
    String? agentId,
  ) async {
    if (channelId != null && channelId.isNotEmpty) {
      return channelId;
    }
    if (agentId == null || agentId.isEmpty || _runLogs == null) {
      return null;
    }
    final activeRun = await _runLogs.activeRunForAgent(agentId);
    return activeRun?.conversationId ?? activeRun?.channelId;
  }
}
