import 'package:cc_harness/src/tools/tool.dart';
import 'package:cc_harness/src/tools/tool_surface.dart';

/// How many levels of subagent nesting are permitted below the top-level run.
///
/// `2` means `agent → sub → sub`: a top-level run spawns children (level 1),
/// each child may spawn grandchildren (level 2) and grandchildren get no
/// `task` tool at all. Enforced structurally — the dispatch layer omits `task`
/// from the registry of a child that has reached the cap, so the model cannot
/// call what it cannot see — with a hard refusal at the spawn chokepoint as the
/// backstop. Never enforced by prompt instructions alone.
///
/// Raising this multiplies concurrent provider traffic at every level; see the
/// wave cap the dispatch layer hands each child loop before changing it.
const int maxSubagentDepth = 2;

/// The kind of ephemeral subagent a parent run can spawn via the `task` tool.
///
/// Each type maps to a [SubagentProfile]: a system-prompt addendum, a tool
/// surface, a turn budget and the set of approval tiers its tools may use.
/// Adding a new type is a single map entry.
enum SubagentType {
  /// General-purpose: read + write + exec tools, completes a bounded task.
  general,

  /// Read-only investigation (no writes / no commands).
  explore,

  /// Read-only planning: research and produce a plan.
  plan;

  /// Parses an id from the tool arg, defaulting to [general].
  static SubagentType fromId(String? id) =>
      SubagentType.values.where((t) => t.name == id).firstOrNull ??
      SubagentType.general;
}

/// Data-driven behaviour profile for a [SubagentType].
class SubagentProfile {
  /// Creates a [SubagentProfile].
  const SubagentProfile({
    required this.type,
    required this.surface,
    required this.maxTurns,
    required this.systemPromptAddendum,
    required this.allowedTiers,
  });

  /// The subagent type this profile describes.
  final SubagentType type;

  /// Tool surface the child loop runs under (drives
  /// `HarnessToolRegistry.toolsFor`).
  final ToolSurfaceSpec surface;

  /// Max loop turns for the child.
  final int maxTurns;

  /// Instructions appended to the base system prompt for the child.
  final String systemPromptAddendum;

  /// Approval tiers the child's tools may use (a second clamp on top of
  /// [surface]-based filtering — e.g. `explore` is read-only).
  final Set<ToolApprovalTier> allowedTiers;

  /// Filters [tools] down to those whose tier this profile permits.
  List<HarnessTool> filterTools(Iterable<HarnessTool> tools) => [
    for (final t in tools)
      if (allowedTiers.contains(t.approvalTier)) t,
  ];

  /// Whether a subagent on this profile may spawn a child running [requested].
  ///
  /// A read-only parent must not acquire write/exec reach by proxy. `task` is
  /// read-tier, so it survives a read-only clamp: without this check an
  /// `explore` child could spawn a `general` grandchild and mutate the worktree
  /// its own surface denied it. The child's tiers must be a subset of ours.
  bool admitsChildType(SubagentType requested) =>
      subagentProfileFor(requested).allowedTiers.every(allowedTiers.contains);

  /// Builds the child's system prompt from a [base] prompt.
  ///
  /// [canSpawn] must match what the child's registry actually contains, so the
  /// prompt can never claim a `task` tool the run does not have (or deny one it
  /// does).
  String buildSystemPrompt(String base, {bool canSpawn = false}) {
    final depthNote = canSpawn
        ? 'You may spawn subagents of your own with the `task` tool for '
              'parallelizable sub-work. They are the last level: a subagent you '
              'spawn cannot spawn any further, so do not plan on deeper nesting.'
        : 'You cannot spawn further subagents.';
    final addendum = '$systemPromptAddendum $depthNote';
    return base.isEmpty ? addendum : '$base\n\n$addendum';
  }
}

const Map<SubagentType, SubagentProfile> _profiles = {
  SubagentType.general: SubagentProfile(
    type: SubagentType.general,
    surface: ToolSurfaceSpec.unrestricted(),
    maxTurns: 40,
    allowedTiers: {
      ToolApprovalTier.read,
      ToolApprovalTier.write,
      ToolApprovalTier.exec,
    },
    systemPromptAddendum:
        'You are a general-purpose subagent spawned to handle a focused '
        'sub-task. Complete it end-to-end using the available read, write, '
        'edit and command tools, then return a concise result summary as your '
        'final message.',
  ),
  SubagentType.explore: SubagentProfile(
    type: SubagentType.explore,
    surface: ToolSurfaceSpec.readOnlyLegacy(),
    maxTurns: 30,
    allowedTiers: {ToolApprovalTier.read},
    systemPromptAddendum:
        'You are an EXPLORE subagent. Investigate the codebase READ-ONLY using '
        'read, search and find. Do NOT modify files or run mutating commands. '
        'Return your findings with exact file paths and line references as your '
        'final message.',
  ),
  SubagentType.plan: SubagentProfile(
    type: SubagentType.plan,
    surface: ToolSurfaceSpec.readOnlyLegacy(),
    maxTurns: 40,
    allowedTiers: {ToolApprovalTier.read},
    systemPromptAddendum:
        'You are a PLAN subagent. Research the request and produce a concrete, '
        'reviewable implementation plan. Do NOT modify files. Deliver the plan '
        'as your final message.',
  ),
};

/// Returns the profile for [type].
SubagentProfile subagentProfileFor(SubagentType type) => _profiles[type]!;
