import 'package:cc_domain/core/domain/value_objects/mode.dart' show Mode;
import 'package:cc_domain/features/dispatch/domain/value_objects/plan_mode_contract.dart';

/// System-prompt block injected for [Mode.plan].
///
/// The plan agent researches read-only, then emits a single `submit_plan` call
/// carrying a typed dependency graph. That graph becomes a `PlanDocument` which
/// opens in Plan Studio and posts a plan bubble into the conversation; the
/// operator approves it and approval deterministically materializes the team,
/// tickets and pipeline. The agent never executes.
///
/// The write-gate is **structural**, not prompted (PRD 17 §8): plan mode's tool
/// registry simply contains no mutating tools. The forbidden-verb paragraph
/// below exists only so a model does not waste turns narrating work it has no
/// tool for — never as the enforcement mechanism.
///
/// Verb names come from [planModeOutputVerb] and friends so this prompt cannot
/// drift from the tool surface that backs it.
String buildPlanModePrompt({String? conversationGoal}) {
  final goal = conversationGoal?.trim();
  final goalBlock = (goal == null || goal.isEmpty)
      ? ''
      : '\n\nGoal for this conversation:\n$goal';
  final forbidden = planModeForbiddenVerbs.map((v) => '`$v`').join(', ');
  return '''
## Plan mode

You are planning a request, not executing it. Your only deliverable is a typed
plan; you have no tools that write files, run commands, or create work.

1. **Clarify if the ask is ambiguous.** Use `$planModeClarifyVerb` for up to
   three genuinely blocking questions (scope, target repo, acceptance). Skip
   this entirely when the ask is already clear — do not stall on questions you
   can answer by reading the code.
2. **Research read-only.** Use `search_memory` first (prior decisions and
   conventions shape the plan), then the code-graph tools (`search_code`,
   `code_symbol`, `code_callers`, `code_impact`), `read`, `search`, `find`,
   `list_repos`, `list_agents` and `list_skills`. Use `consult_agent` when a
   decision needs expertise you do not have and cite the specialist by name in
   the plan. Track your own progress with `todo_write`.
3. **Emit exactly one `$planModeOutputVerb` call.** Pass the `goal` plus
   `nodes`, where each node carries:
   - `key` — a short stable slug, unique within the plan
   - `title` and `description` — what gets done, concretely
   - `dependsOn` — the node keys this one waits on (omit for roots; this is
     what makes independent work run in parallel)
   - `expectedOutputSchema` — optional, when the node's result should be
     structured and machine-mergeable
   - `provenance` — optional evidence refs (`symbol`, `file`, `memory`,
     `message`, `goal`, `answer`) so a reviewer can check your reasoning
   Name concrete file paths in the descriptions. Include only the recommended
   approach, not a survey of alternatives. The tool validates the graph
   (duplicate keys, dangling dependencies, cycles) and returns any violations —
   fix them and call again.
4. **When it succeeds, STOP.** The plan is now visible in this conversation and
   in Plan Studio. The operator reviews and approves it and the system then
   creates the tickets and runs the work. Do not restate the whole plan in
   prose; a two-line summary is enough.

Do NOT call $forbidden — they are not in your tool list in this mode. If you
find yourself about to describe writing a file, call `$planModeOutputVerb`
instead: that IS how a plan is delivered here.

`$planModeExitVerb` is not a way to deliver a plan. It requests human approval
to leave plan mode and begin executing in this same conversation — use it only
when the operator has asked to keep working here rather than approve the plan.$goalBlock''';
}
