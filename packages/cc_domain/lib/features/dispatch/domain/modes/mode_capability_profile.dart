import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/plan_mode_contract.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/tools.dart';

/// Everything a conversation [Mode] guarantees, declared **once**.
///
/// ## Why this exists
///
/// "What may an agent do, and what must it produce, in mode M" used to be
/// asserted independently in five places: the mode prompt, the harness tool
/// registry, the guard preset, the MCP allow-lists, and the sandbox policy. They
/// drifted, and the drift was invisible until an agent hit it:
///
///  * plan mode's prompt instructed the agent to write plan files, while the
///    write tools had been removed and the sandbox carve-out deleted — so the
///    instructed deliverable was impossible and the run ended reporting success;
///  * orchestrate mode's guard preset denied `vendorSyncWrite`, which is the
///    effect class its *only* output verb declares — so the mode could not
///    produce its own deliverable either.
///
/// Both are the same bug: a fact with more than one writable home. Every
/// consumer now projects from this table instead of holding a copy, and the
/// prompt's capability sentences are *generated* from the materialized tool list
/// (see `buildCapabilityPreamble`) so a prompt cannot name a tool the run does
/// not have.
///
/// ## Layering
///
/// This is a `cc_domain` concept. The kernel keeps only [ToolSurfaceSpec] and
/// [CompletionContract] — name-based data with no product semantics — so
/// `cc_harness` never learns what a [Mode] is (PRD 26's boundary law). Dispatch
/// materializes the projections at the composition boundary.
class ModeCapabilityProfile {
  /// Creates a capability profile.
  const ModeCapabilityProfile({
    required this.mode,
    required this.label,
    required this.intent,
    required this.deliverableNoun,
    required this.requiredVerbs,
    required this.forbiddenVerbs,
    required this.maxTier,
    required this.deniedClasses,
    required this.worktreeWritable,
    this.sanctionedExitVerb,
    this.contractNudge,
    this.contractUnmetSummary,
  });

  /// The mode this profile describes.
  final Mode mode;

  /// Short human label, e.g. `plan (read-only)`. Used in the generated preamble
  /// and in UI that explains what a mode guarantees.
  final String label;

  /// One sentence stating what the agent is doing in this mode.
  final String intent;

  /// What the mode produces, as a noun (`plan`, `proposal`, `review`). Used to
  /// parameterize hand-authored guidance so it never hard-codes a verb.
  final String deliverableNoun;

  /// Verbs the run MUST be able to call, and must call to have delivered
  /// anything. Empty means the mode has no completion contract.
  ///
  /// These are pinned into the tool surface and pre-approved past every gate:
  /// a run may never be denied the one call that delivers its own output.
  final Set<String> requiredVerbs;

  /// Verbs named in the prompt as unavailable.
  ///
  /// Purely so a weak model does not burn turns narrating work it has no tool
  /// for. The absence of these tools is what enforces the gate — never this
  /// list (PRD 17 §8: "structural, not prompted").
  final Set<String> forbiddenVerbs;

  /// The sanctioned way out of this mode, if any (e.g. `exit_plan_mode`).
  final String? sanctionedExitVerb;

  /// Highest approval tier the mode admits.
  final ToolApprovalTier maxTier;

  /// Effect classes the mode refuses outright. Consumed by the guard's mode
  /// preset, which no longer keeps its own copy.
  final Set<ActionClass> deniedClasses;

  /// Whether bind-mounted worktrees are writable. Consumed by the sandbox
  /// policy resolver, which no longer keeps its own mode switch.
  final bool worktreeWritable;

  /// Text injected when the run would stop with [requiredVerbs] uncalled.
  final String? contractNudge;

  /// Run summary recorded when the contract is never satisfied.
  final String? contractUnmetSummary;

  /// Names that must survive every tool filter: the output verbs, the exit verb,
  /// and the user-interaction tools (which ARE the approval mechanism, so gating
  /// them would deadlock a run that needs to ask something).
  Set<String> get pinnedVerbs => {
    ...requiredVerbs,
    ?sanctionedExitVerb,
    ...interactionVerbs,
  };

  /// Tools that surface a question to the operator. Always available.
  static const Set<String> interactionVerbs = {
    'ask_user_question',
    'request_confirmation',
  };

  /// The kernel-level tool surface for this mode.
  ///
  /// `freeTier: read` is deliberate: the curated MCP allow-list constrains only
  /// write-tier-and-above tools, so adopting it cannot silently strip read tools
  /// from a read-only mode (or from a read-only subagent).
  ToolSurfaceSpec toToolSurfaceSpec() => ToolSurfaceSpec(
    maxTier: maxTier,
    allowNames: ModeToolPolicy.allowListFor(mode),
    denyNames: worktreeWritable ? const {} : ToolSurfaceSpec.worktreeMutators,
    pinnedNames: pinnedVerbs,
    deniedActionClasses: deniedClasses,
  );

  /// The kernel-level completion contract, or null when the mode owes nothing.
  CompletionContract? toCompletionContract() {
    if (requiredVerbs.isEmpty) {
      return null;
    }
    return CompletionContract(
      id: '$deliverableNoun.delivered',
      requiredToolNames: requiredVerbs,
      nudge:
          contractNudge ??
          'You have not called '
              '${requiredVerbs.map((v) => '`$v`').join(' or ')}. '
              'Your $deliverableNoun does not exist until you do. Call it now, '
              'or say in one sentence why none is needed and stop.',
      unmetSummary:
          contractUnmetSummary ??
          'Ended without delivering a $deliverableNoun.',
    );
  }
}

/// The capability profile table — the single declaration.
///
/// Seeded from the behavior that already shipped, so the consumers that stopped
/// holding their own copies are pure refactors with their existing goldens as
/// proof. The one intentional change: plan and orchestrate mode now pin their
/// output verbs, which is what makes their deliverables reachable.
const Map<Mode, ModeCapabilityProfile> modeCapabilityProfiles = {
  Mode.chat: ModeCapabilityProfile(
    mode: Mode.chat,
    label: 'chat',
    intent: 'You are doing the work, not planning it.',
    deliverableNoun: 'result',
    requiredVerbs: {},
    forbiddenVerbs: {},
    maxTier: ToolApprovalTier.exec,
    deniedClasses: {},
    worktreeWritable: true,
  ),
  Mode.review: ModeCapabilityProfile(
    mode: Mode.review,
    label: 'review (read-only)',
    intent: 'You are reviewing a change, not making one.',
    deliverableNoun: 'review',
    // Review findings accumulate through `add_review_node` and are published by
    // `finalize_review`, both of which may legitimately be called zero times
    // (a pipeline agent running in review mode completes a ticket instead), so
    // review carries no completion contract.
    requiredVerbs: {},
    forbiddenVerbs: {'write', 'edit', 'apply_patch', 'bash'},
    maxTier: ToolApprovalTier.write,
    deniedClasses: _readOnlyDeniedClasses,
    worktreeWritable: false,
  ),
  Mode.plan: ModeCapabilityProfile(
    mode: Mode.plan,
    label: 'plan (read-only)',
    intent: 'You are planning a request, not executing it.',
    deliverableNoun: 'plan',
    requiredVerbs: planModeRequiredVerbs,
    forbiddenVerbs: planModeForbiddenVerbs,
    sanctionedExitVerb: planModeExitVerb,
    maxTier: ToolApprovalTier.write,
    deniedClasses: _readOnlyDeniedClasses,
    worktreeWritable: false,
    contractNudge: planModeContractNudge,
    contractUnmetSummary: planModeContractUnmetSummary,
  ),
  Mode.orchestrate: ModeCapabilityProfile(
    mode: Mode.orchestrate,
    label: 'orchestrate (read-only)',
    intent: 'You are proposing a team and a plan, not running them.',
    deliverableNoun: 'proposal',
    requiredVerbs: orchestrateModeRequiredVerbs,
    forbiddenVerbs: {
      'write',
      'edit',
      'apply_patch',
      'bash',
      'hire_agent',
      'delegate_ticket',
      'create_ticket',
      'close_ticket',
      'fail_ticket',
    },
    maxTier: ToolApprovalTier.write,
    deniedClasses: _readOnlyDeniedClasses,
    worktreeWritable: false,
    contractNudge: orchestrateModeContractNudge,
    contractUnmetSummary: orchestrateModeContractUnmetSummary,
  ),
};

/// Effect classes every read-only mode refuses.
///
/// Note what is NOT here: `networkEgress` and `secretAccess` stay at their
/// built-in defaults, because research is the entire point of a read-only mode.
const Set<ActionClass> _readOnlyDeniedClasses = {
  ActionClass.fileDelete,
  ActionClass.fileWriteOutsideWorktree,
  ActionClass.gitCommit,
  ActionClass.gitPush,
  ActionClass.prCreate,
  ActionClass.prPublish,
  ActionClass.vendorSyncWrite,
  ActionClass.packageInstall,
  ActionClass.workspaceMutation,
  ActionClass.processSpawn,
};

/// The profile for [mode]. Total — every mode has one.
ModeCapabilityProfile profileFor(Mode mode) => modeCapabilityProfiles[mode]!;
