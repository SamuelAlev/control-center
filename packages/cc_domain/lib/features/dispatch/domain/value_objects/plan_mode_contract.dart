/// The plan-mode contract, declared once so the prompt, the tool surface, the
/// completion contract and the tests cannot disagree about it.
///
/// This file exists because they *did* disagree: the plan-mode prompt used to
/// instruct the agent to write timestamped `.md` files into a `plans/`
/// directory, while the sandbox carve-out for that directory had been removed
/// and the harness tool registry strips every write tool in read-only modes. A
/// plan-mode run therefore had no way to produce the artifact it was told to
/// produce and the loop reported success anyway.
///
/// The surviving contract has exactly one output verb. Anything that names a
/// verb — a prompt, an allow-list, a nudge — names it from here.
library;

/// The one verb that delivers a plan. Emits a typed `PlanDocument` that opens
/// in Plan Studio and posts a plan bubble into the conversation.
const String planModeOutputVerb = 'submit_plan';

/// The sanctioned way *out* of plan mode: opens a `plan_exit` approval a human
/// must grant before mutating tools unlock. Not an output verb — an agent that
/// calls this instead of [planModeOutputVerb] has delivered nothing.
const String planModeExitVerb = 'exit_plan_mode';

/// How a plan agent resolves ambiguity before committing to a plan.
///
/// The harness tool is `ask_user` (`AskUserTool`), and this constant is the one
/// place the prompt learns its name. It said `ask_user_question` for a while —
/// a tool that was deleted and never existed under that name on the harness
/// surface — which is exactly the disagreement this file was created to stop:
/// the prompt instructed the agent to call something the run could not call,
/// so an ambiguous brief was planned against the model's own assumptions.
const String planModeClarifyVerb = 'ask_user';

/// Verbs a plan-mode run MUST be able to call. Every entry is asserted to be
/// present in the mode's tool surface, non-deniable by the guard preset and
/// named in the generated capability preamble.
const Set<String> planModeRequiredVerbs = {planModeOutputVerb};

/// Verbs a plan-mode run must NOT call, named explicitly in the prompt.
///
/// These are *already* absent from the tool surface — the write-gate is
/// structural, never prompted (PRD 17 §8). Naming them is purely so a model
/// does not burn turns narrating work it cannot do.
const Set<String> planModeForbiddenVerbs = {
  'write',
  'edit',
  'apply_patch',
  'bash',
  'hire_agent',
  'delegate_ticket',
  'create_ticket',
};

/// The nudge injected when a plan-mode run reaches the end of its turn without
/// ever completing a [planModeOutputVerb] call.
///
/// Deliberately authorizes an honest "no plan is needed here" exit: plan mode
/// is a space setting, so a user may ask a plain question inside it and a
/// contract that forces a bogus plan is worse than one that allows an opt-out.
const String planModeContractNudge =
    '''
You have not called `$planModeOutputVerb`. Nothing you have written so far is a
plan the user can see, review, or run — the plan does not exist until that call
succeeds. Do not describe the plan in prose instead.

Call `$planModeOutputVerb` now with the plan as a typed graph: `goal`, then
`nodes` where each node has `key`, `title`, `description` and `dependsOn`
(node keys it waits on). If the tool reports violations, fix them and call
again.

If this request genuinely needs no plan, say so in one sentence and stop.''';

/// The run summary recorded when a plan-mode run ends without its plan.
const String planModeContractUnmetSummary =
    'Ended without submitting a plan (no `$planModeOutputVerb` call).';

/// The orchestrate-mode sibling of [planModeOutputVerb]. Same contract shape,
/// same failure mode — an orchestrate run that ends without proposing has
/// produced nothing.
const String orchestrateModeOutputVerb = 'propose_orchestration';

/// Verbs an orchestrate-mode run MUST be able to call.
const Set<String> orchestrateModeRequiredVerbs = {orchestrateModeOutputVerb};

/// The nudge injected when an orchestrate-mode run stops without proposing.
const String orchestrateModeContractNudge =
    '''
You have not called `$orchestrateModeOutputVerb`. Your proposal does not exist
until that call succeeds and the user has nothing to approve.

Call `$orchestrateModeOutputVerb` now with the full plan: the goal, the roles,
the sub-ticket tree, the synthesis step and a budget. If the tool reports
violations, fix them and call again.

If this request does not warrant a team, say so in one sentence and stop.''';

/// The run summary recorded when an orchestrate-mode run ends without a proposal.
const String orchestrateModeContractUnmetSummary =
    'Ended without proposing an orchestration '
    '(no `$orchestrateModeOutputVerb` call).';
