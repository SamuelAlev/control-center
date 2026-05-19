import 'package:control_center/core/domain/ports/conversation_mode_resolver.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';

/// MCP-layer guard consulted by the dispatcher to enforce per-mode tool
/// allow-lists.
///
/// Replaces the original `ReviewChannelToolGuard`, which keyed off the
/// `review_channels` association table. The new shape keys off the
/// `channels.mode` column so the guard generalizes to plan mode (and any
/// future mode) without needing a separate join table.
///
/// **Maintenance note:** when adding a new mutating MCP tool, decide whether
/// it belongs in [_reviewAllowed] / [_planAllowed]. The default is "no" —
/// the absence of an entry means the tool is rejected in that mode.
class ConversationModeToolGuard {
  /// Creates a new [ConversationModeToolGuard].
  ConversationModeToolGuard(this._resolver);

  final ConversationModeResolver _resolver;

  /// Tools available to any participant in a review-mode conversation.
  ///
  /// Curated allow-list — anything not listed here is rejected. Covers the
  /// review-participation verbs, communication, read-only context fetchers,
  /// and the CEO-only orchestration verbs.
  static const Set<String> _reviewAllowed = {
    // Review participation
    'add_review_node',
    'confirm_review_node',
    'dismiss_review_node',
    'request_peer_review',
    // Communication
    'send_channel_message',
    'send_thread_reply',
    'get_channel_messages',
    // Context gathering (read-only)
    'get_pr_diff',
    'get_pr_check_runs',
    'list_github_pr_reviews',
    'get_github_file_content',
    'search_memory',
    'search_code',
    'code_symbol',
    'code_callers',
    'code_callees',
    'code_impact',
    'list_repos',
    'list_agents',
    'list_skills',
    'read',
    // Ticketing (review channels can capture + link work, not reassign/close)
    'create_ticket',
    'list_tickets',
    'get_ticket',
    'link_ticket_to_pr',
    // CEO-only orchestration (still review-scoped)
    'delegate_review',
    'propose_hire',
    'finalize_review',
    'start_ai_review',
    // User-facing UI prompts
    'request_confirmation',
    'ask_user_question',
  };

  /// Tools available to any participant in a plan-mode conversation.
  ///
  /// Plan agents write via the filesystem (timestamped plan files), not via
  /// MCP, so this set is intentionally a subset of [_reviewAllowed] minus
  /// the review-specific verbs and ticket actions.
  static const Set<String> _planAllowed = {
    // Communication
    'send_channel_message',
    'send_thread_reply',
    'get_channel_messages',
    // Read-only context
    'get_pr_diff',
    'get_github_file_content',
    'search_memory',
    'search_code',
    'code_symbol',
    'code_callers',
    'code_callees',
    'code_impact',
    'list_repos',
    'list_agents',
    'list_skills',
    'read',
    'consult_agent',
    'propose_hire',
    // Ticketing (read-only)
    'list_tickets',
    'get_ticket',
    // User-facing UI prompts
    'request_confirmation',
    'ask_user_question',
  };

  /// Returns null when the call is allowed for [channelId]'s mode, or an
  /// error message describing the refusal. Refusals are surfaced to the
  /// calling agent so the model adapts rather than silently swallowing
  /// the failure.
  Future<String?> rejectIfDisallowed(
    String toolName,
    String? channelId,
  ) async {
    if (channelId == null) {
      return null;
    }
    final mode = await _resolver.resolveForConversation(channelId);
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
    }
  }
}
