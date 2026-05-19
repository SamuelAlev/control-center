import 'package:cc_domain/core/domain/value_objects/mode.dart';

/// The per-mode MCP tool surface, as pure data.
///
/// Extracted from `ModeToolGuard` so *both* enforcement paths can consult one
/// table instead of two diverging ones:
///
///  * the MCP dispatcher (external CLI adapters reaching in over MCP) and
///  * the built-in harness registry, which bridges `McpTool`s directly and
///    therefore never reaches the dispatcher's guard at all.
///
/// That second path is why this file exists. The curated allow-lists were
/// authoritative on paper and inert in practice for the built-in harness — the
/// mode's tool surface there was "everything except exec tier", so a mutating
/// MCP tool declaring no effect classes was neither filtered nor gated.
///
/// Dependency-free (no repositories, no async) so a test can assert
/// prompt/allow-list/registry agreement without booting anything.
class ModeToolPolicy {
  const ModeToolPolicy._();

  /// Knowledge writes + reads that are *always* permitted regardless of mode:
  /// shared memory and published artifacts.
  ///
  /// Contributing to and reading shared memory is not a mutation of the
  /// reviewed/planned artifact — it is how knowledge survives across runs and
  /// agents. Blocking it in review/plan mode (the original behaviour) is the
  /// reason agents almost never wrote facts and never wrote policies. Sandbox
  /// filesystem write rules are untouched; these are knowledge writes only.
  static const Set<String> memoryKnowledgeTools = {
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
    // Artifacts (PRD Part 2 §2.1). Publishing an artifact is a knowledge write,
    // not a worktree mutation: it writes one local row and posts one message —
    // no filesystem, no process, no external system. A review agent must be
    // able to hand back a findings table and a plan agent a dependency
    // diagram, in the same modes that forbid them touching the worktree.
    'publish_artifact',
    'revise_artifact',
    'list_artifacts',
    'get_artifact',
  };

  /// Code-graph tools — read-only, always permitted.
  static const Set<String> codeGraphTools = {
    'search_code',
    'code_symbol',
    'code_callers',
    'code_callees',
    'code_impact',
  };

  /// Run-mechanics tools permitted in every mode: catalogue discovery and the
  /// "what can I call right now" introspection are read-only and the
  /// per-conversation todo checklist is how an agent plans and reports
  /// multi-step progress — blocking it in review/plan mode broke planning
  /// exactly where it matters most.
  ///
  /// `todo_read` rides along with `todo_write` deliberately: it is the read-back
  /// half of the same checklist and the only way an agent recovers stable item
  /// ids after a context reset. Allowing the write while refusing the read left
  /// the MCP path (Claude CLI / Pi) able to overwrite a list it could not first
  /// inspect — in exactly the modes whose prompt tells it to track progress.
  static const Set<String> runMechanicsTools = {
    'search_tool_bm25',
    'list_my_tools',
    'todo_write',
    'todo_read',
  };

  /// Tools available to any participant in a review-mode conversation.
  ///
  /// Curated allow-list — anything not listed here is rejected. Covers the
  /// review-participation verbs, communication, read-only context fetchers,
  /// the CEO-only orchestration verbs and (critically) the ticket-completion
  /// verbs that pipeline agents — which run in review mode — must call to
  /// finish their work.
  static const Set<String> reviewAllowed = {
    ...memoryKnowledgeTools,
    ...codeGraphTools,
    ...runMechanicsTools,
    // Review participation
    'add_review_node',
    'confirm_review_node',
    'dismiss_review_node',
    'request_peer_review',
    // Communication
    'send_channel_message',
    'get_channel_messages',
    'consult_agent',
    // Context gathering (read-only)
    'get_pr_diff',
    'get_pr_check_runs',
    'list_github_pr_reviews',
    'get_github_file_content',
    // The review prompt tells the agent to use this for the catalog view, so it
    // has to actually be callable. It was named in the prompt and missing here —
    // reachable on the built-in harness path (read tier bypasses the allow-list)
    // and refused on the external-CLI path. The prompt/allow-list parity test
    // now holds the line.
    'list_pull_requests',
    'list_repos',
    'list_agents',
    'list_skills',
    'read',
    // Ticketing — the typed tools that replaced the retired `ticket_cli`.
    // Review channels can capture, edit, link and act on work.
    'create_ticket',
    'update_ticket',
    'assign_ticket',
    'reassign_ticket',
    'add_ticket_collaborator',
    'comment_on_ticket',
    'close_ticket',
    'fail_ticket',
    'delegate_ticket',
    'list_tickets',
    'get_ticket',
    'link_ticket_to_pr',
    'unlink_ticket_from_pr',
    'link_tickets',
    'unlink_tickets',
    'list_ticket_relations',
    'submit_output',
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
  /// Plan agents deliver via `submit_plan` (a typed `PlanDocument`), never via
  /// the filesystem — there is no writable plans directory and no write tool in
  /// this mode. The set is a subset of [reviewAllowed] minus the
  /// review-specific verbs and external ticket actions, keeping the
  /// memory/code-graph tools and ticket completion so a plan agent dispatched
  /// against a ticket can still close it out.
  static const Set<String> planAllowed = {
    ...memoryKnowledgeTools,
    ...codeGraphTools,
    ...runMechanicsTools,
    // Communication
    'send_channel_message',
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
    // Ticketing — the typed tools let a plan agent work on the ticket it was
    // dispatched against (edit / comment / close), but not orchestrate new
    // work (no create / assign / delegate here).
    'update_ticket',
    'comment_on_ticket',
    'close_ticket',
    'fail_ticket',
    'list_tickets',
    'get_ticket',
    'list_ticket_relations',
    'submit_output',
    // The typed plan output contract (PRD 17 §8): the Planner emits a
    // PlanDocument that opens in Plan Studio instead of a prose plan.
    'submit_plan',
    // The sanctioned way OUT of plan mode: opens a `plan_exit` approval a human
    // must approve before execution is unblocked (PRD 09 hard gate).
    'exit_plan_mode',
    // User-facing UI prompts
    'request_confirmation',
    'ask_user_question',
  };

  /// Tools available to the orchestrator agent in an orchestrate-mode
  /// conversation. Research + read tools + the single proposal-emitting verb.
  /// Hiring/decomposition/ticket-completion happen deterministically *after*
  /// the user approves the proposal — never by the orchestrator mid-run — so
  /// `hire_agent`, `delegate_ticket`, `complete_ticket` and `fail_ticket` are
  /// intentionally excluded.
  static const Set<String> orchestrateAllowed = {
    ...memoryKnowledgeTools,
    ...codeGraphTools,
    ...runMechanicsTools,
    'propose_orchestration',
    // Playbooks (PRD 17 §10): instantiating one only PROPOSES a plan (the
    // operator still approves) and saving one is a pure template write.
    'create_playbook',
    'run_playbook',
    'send_channel_message',
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

  /// Whether [toolName] is permitted in [mode]. Pure and in-memory.
  static bool isAllowed(String toolName, Mode mode) => switch (mode) {
    Mode.chat => true,
    Mode.review => reviewAllowed.contains(toolName),
    Mode.plan => planAllowed.contains(toolName),
    Mode.orchestrate => orchestrateAllowed.contains(toolName),
  };

  /// The curated allow-list for [mode], or null for the unrestricted [Mode.chat].
  static Set<String>? allowListFor(Mode mode) => switch (mode) {
    Mode.chat => null,
    Mode.review => reviewAllowed,
    Mode.plan => planAllowed,
    Mode.orchestrate => orchestrateAllowed,
  };
}
