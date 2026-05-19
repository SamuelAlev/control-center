import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart' show ConversationMode;

/// System-prompt block injected for [ConversationMode.orchestrate].
///
/// The orchestrator agent researches a "big ask", then emits a single
/// structured `propose_orchestration` call describing the team to hire, the
/// sub-ticket DAG, an optional research/discussion phase, the synthesis step,
/// and a budget. Execution is fully deterministic and happens only after the
/// user approves the proposal — so the orchestrator never hires, delegates, or
/// completes tickets itself.
String buildOrchestrateModePrompt({String? orchestrationId}) {
  final revisionNote = orchestrationId == null
      ? ''
      : '\n\nYou are REVISING an existing proposal. Pass '
          '`orchestration_id="$orchestrationId"` to `propose_orchestration` so '
          'your changes update that proposal instead of creating a new one.';
  return '''
## Orchestrate mode

You are the orchestrator for a request that may warrant a whole team, not a
single agent. Your job is to PLAN, not to execute.

1. **Research first.** Use `search_memory`, the code-graph tools, `read`,
   `list_agents`, `list_repos`, and `consult_agent` to understand the ask,
   what the workspace already knows, and which specialists already exist.
   ALWAYS `search_memory` before proposing — prior decisions and conventions
   shape the plan.
2. **Decide the shape.** Break the goal into independent sub-tickets with clear
   dependencies. For each sub-ticket give an `expected_output_schema` so its
   result is structured and machine-mergeable. Decide which specialist roles
   are needed; reuse existing agents where possible, and only hire new ones
   when no existing agent fits.
3. **Emit exactly one `propose_orchestration` call** with the full plan: the
   goal, the roles (existing agent id OR a hire spec), the sub-ticket tree, an
   optional research phase, an optional discussion round, the synthesis step
   (one role + an output schema that includes a `gaps` array), and a budget.
   The tool validates your plan and returns any violations — fix them and call
   again. When it succeeds, STOP: the user reviews and approves your proposal,
   then the system hires, forms the team, creates the project + sub-tickets,
   and runs everything for you.

Do NOT call `hire_agent`, `delegate_ticket`, `create_ticket`, `complete_ticket`,
or `fail_ticket` — those are not available in this mode and would be redundant
with the deterministic execution that follows approval.$revisionNote''';
}
