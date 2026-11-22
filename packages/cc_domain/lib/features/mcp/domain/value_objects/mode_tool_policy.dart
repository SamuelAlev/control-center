import 'package:cc_domain/core/domain/value_objects/mode.dart';

/// The per-mode MCP tool surface, as pure data.
///
/// Extracted from `ModeToolGuard` so *both* enforcement paths can consult one
/// table instead of two diverging ones:
///  * the MCP dispatcher (external CLI adapters reaching in over MCP) and
///  * the built-in harness registry, which bridges `McpTool`s directly and
///    therefore never reaches the dispatcher's guard at all.
/// That second path is why this file exists. The curated allow-lists were
/// authoritative on paper and inert in practice for the built-in harness — the
/// mode's tool surface there was "everything except exec tier", so a mutating
/// MCP tool declaring no effect classes was neither filtered nor gated.
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

  /// Reading a space's environment: what is up and what its logs say. Review
  /// and plan agents may look at the running stack, not change it.
  static const Set<String> environmentReadTools = {
    'environment_status',
    'environment_logs',
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
    // How a run asks the operator, in every mode. The harness pins this name
    // on its own surface; the MCP dispatcher does not — it is a flat
    // allow-list, so a read-tier tool absent from this set is refused to
    // Claude and Pi. Omitting it is how a run reported the tool missing and
    // guessed instead of asking.
    'ask_user',
    // Code mode's script tool. It has no effects of its own: every effect is
    // a nested call the gate checks under its own name, against this same
    // allow-list, so admitting it in every mode widens nothing.
    'repl',
    // Waiting instead of polling, in every mode: a wake starts a later run of
    // the same agent in the same conversation, under that conversation's
    // mode, and touches nothing else.
    'wake_me',
    'list_wakes',
    'cancel_wake',
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
    ...environmentReadTools,
    ...runMechanicsTools,
    // Review participation
    'add_review_node',
    'confirm_review_node',
    'dismiss_review_node',
    'resolve_review_node',
    'request_peer_review',
    // Communication
    'send_message',
    'get_messages',
    'agent_activity',
    'consult_agent',
    // Context gathering (read-only)
    'list_repos',
    'list_agents',
    'list_skills',
    'read',
    'render_media',
    // Ticketing — the typed tools that replaced the retired `ticket_cli`.
    // Review spaces can capture, edit, link and act on work.
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
    'ticket_pr_link',
    'ticket_relation',
    'list_ticket_relations',
    'submit_output',
    // CEO-only orchestration (still review-scoped)
    'finalize_review',
    'publish_review_to_github',
    'start_ai_review',
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
    ...environmentReadTools,
    ...memoryKnowledgeTools,
    ...codeGraphTools,
    ...runMechanicsTools,
    // Communication
    'send_message',
    'get_messages',
    'agent_activity',
    'consult_agent',
    // Read-only context
    'list_repos',
    'list_agents',
    'list_skills',
    'read',
    'render_media',
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
  };

  /// Tools available to the orchestrator agent in an orchestrate-mode
  /// conversation. Research + read tools + the single proposal-emitting verb.
  /// Hiring/decomposition/ticket-completion happen deterministically *after*
  /// the user approves the proposal — never by the orchestrator mid-run — so
  /// `delegate_ticket`, `complete_ticket` and `fail_ticket` are
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
    'send_message',
    'get_messages',
    'agent_activity',
    'consult_agent',
    'list_repos',
    'list_agents',
    'list_skills',
    'list_tickets',
    'get_ticket',
    'read',
    'render_media',
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

  /// The tools a run calls directly, with their definitions in every request,
  /// whether or not it has `repl`. Every other admitted tool is reached from
  /// a script when a script may call it, and is deferred (found through
  /// `search_tools`, loaded on first use) when it may not.
  ///
  /// Kept to what most runs use in their first turns and what must never need
  /// a script: the file and shell loop, talking to a person and delegating,
  /// the checklist, recall and reporting back. Every name here is a
  /// definition on every turn of every run, and selection measurably degrades
  /// past 30 to 50 definitions, so a tool earns its place by being used in
  /// most runs, not by being important when it is used. Names a run never
  /// materializes (no space means no `ask_user`) are inert.
  ///
  /// `todo_read` is not here: `todo_write` already returns the whole list,
  /// which is all the next `todo_write` needs (an item is updated by sending
  /// its content unchanged), so reading it back is the occasional call after
  /// a context reset.
  static const Set<String> directTools = {
    // The file and shell loop.
    'read',
    'write',
    'edit',
    'search',
    'find',
    'bash',
    'read_output',
    // People and delegation.
    'ask_user',
    'task',
    // Used by most runs.
    'todo_write',
    'search_memory',
    'send_message',
  };

  /// How an agent finds the tools that are deferred.
  ///
  /// `search_tools` is the harness's own search-AND-load verb; `list_my_tools`
  /// browses the whole surface. Neither may itself be deferred: a deferred
  /// surface whose only way in is itself deferred is a surface with no way in.
  /// A run with `repl` gets `search_tools` when something is deferred and no
  /// `list_my_tools`: its scripts' `ALL_TOOLS` and the name index in its
  /// prompt replace it.
  static const Set<String> residentDiscovery = {
    'search_tools',
    'list_my_tools',
  };

  /// The tools a run in [mode] calls directly: [directTools] and the mode's
  /// own loop. Everything else the mode admits is script-only or deferred.
  ///
  /// A mode's own required and pinned verbs are NOT listed here — dispatch
  /// unions them in from the mode's capability profile, because a run must
  /// never have to discover the one call that delivers its deliverable.
  static Set<String> directNamesFor(Mode mode) => {
    ...directTools,
    // A mode's core loop is direct IN that mode and script-only or
    // deferred everywhere else. `add_review_node` is the heaviest definition in the catalogue and
    // a review agent calls it on nearly every turn, so it belongs in exactly
    // one mode's resident set rather than in all four or in none.
    ...switch (mode) {
      Mode.chat => const <String>{},
      Mode.review => const {
        'add_review_node',
        'confirm_review_node',
        'dismiss_review_node',
        'resolve_review_node',
      },
      Mode.plan => const {'submit_plan'},
      Mode.orchestrate => const {'propose_orchestration'},
    },
  };
}
