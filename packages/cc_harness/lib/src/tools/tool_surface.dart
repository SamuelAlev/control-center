import 'package:cc_harness/src/tools/action_class.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// Declarative description of the tool surface a run may see.
///
/// Replaces the binary read-only/unrestricted switch the loop used to carry.
/// That binary could express "may this run mutate the worktree?" and nothing
/// else — in particular it could not express "read-only, AND these specific
/// write-tier verbs are the sanctioned way to deliver the run's output", which
/// is exactly what plan and orchestrate mode need. Every mode-specific fact now
/// arrives as data on one of these.
///
/// Name-based data only: the kernel still knows nothing about Control Center's
/// conversation modes. Dispatch maps its `Mode` onto a spec at the boundary.
class ToolSurfaceSpec {
  /// Creates a tool-surface spec.
  const ToolSurfaceSpec({
    this.maxTier = ToolApprovalTier.exec,
    this.allowNames,
    this.freeTier = ToolApprovalTier.read,
    this.denyNames = const {},
    this.pinnedNames = const {},
    this.deniedActionClasses = const {},
  });

  /// Everything: read, write, and exec tools all available.
  const ToolSurfaceSpec.unrestricted() : this();

  /// The historical read-only surface, byte-for-byte: exec-tier tools and the
  /// three built-in worktree mutators are dropped; read tools and write-tier
  /// bridged tools (memory, messaging, tickets) remain.
  ///
  /// Kept as a named factory so the migration off the old binary policy is a
  /// provable no-op — the same tools come out.
  const ToolSurfaceSpec.readOnlyLegacy()
    : this(maxTier: ToolApprovalTier.write, denyNames: worktreeMutators);

  /// Built-in tools that mutate the working tree.
  ///
  /// Denied by name rather than by tier because a *bridged* write-tier MCP tool
  /// (propose a fact, comment on a ticket) is fine in a read-only mode, while
  /// these three are the read-only guarantee itself. `apply_patch` is included
  /// so a plan-mode agent never sees a write tool whose calls would then fail
  /// at the action-policy gate with an opaque denial.
  static const Set<String> worktreeMutators = {'write', 'edit', 'apply_patch'};

  /// Highest approval tier permitted. Tools above it are dropped.
  final ToolApprovalTier maxTier;

  /// When non-null, the curated set of tool names permitted *above* [freeTier].
  /// Null means no allow-list — the tier/deny nets are the only filter.
  final Set<String>? allowNames;

  /// Tiers at or below this bypass [allowNames].
  ///
  /// The safety valve that makes an allow-list adoptable: curating ~200 bridged
  /// MCP tools by hand would otherwise silently strip *read* tools from every
  /// read-only mode and every read-only subagent. With `freeTier = read`, an
  /// allow-list constrains exactly the write-gate and nothing else.
  final ToolApprovalTier freeTier;

  /// Tool names always dropped, regardless of tier or allow-list.
  final Set<String> denyNames;

  /// Tool names that survive every filter above.
  ///
  /// This is where a mode's own output verb lives. A run must never be denied
  /// the one call that delivers its deliverable — an earlier version of the
  /// guard preset did exactly that to orchestrate mode's
  /// `propose_orchestration`, leaving the mode structurally unable to produce
  /// anything.
  final Set<String> pinnedNames;

  /// Effect classes this surface refuses outright. Advisory to the loop (the
  /// action guard is the enforcer); carried here so one declaration feeds both.
  final Set<ActionClass> deniedActionClasses;

  /// Whether [tool] is present on this surface.
  bool admits(HarnessTool tool) {
    if (pinnedNames.contains(tool.name)) {
      return true;
    }
    if (denyNames.contains(tool.name)) {
      return false;
    }
    if (tool.approvalTier.index > maxTier.index) {
      return false;
    }
    final allow = allowNames;
    if (allow != null &&
        tool.approvalTier.index > freeTier.index &&
        !allow.contains(tool.name)) {
      return false;
    }
    return true;
  }

  /// The subset of [tools] this surface admits, order preserved.
  List<HarnessTool> filter(Iterable<HarnessTool> tools) => [
    for (final t in tools)
      if (admits(t)) t,
  ];

  /// A structured account of what this surface does to [tools].
  ///
  /// Feeds the generated capability preamble: the sentence "you may call X, Y,
  /// Z" is derived from the same list handed to the loop, so a prompt cannot
  /// name a tool the run does not have.
  ToolSurfaceReport describe(Iterable<HarnessTool> tools) {
    final included = <String>[];
    final excluded = <String, String>{};
    for (final t in tools) {
      if (admits(t)) {
        included.add(t.name);
        continue;
      }
      if (denyNames.contains(t.name)) {
        excluded[t.name] = 'denied by name';
      } else if (t.approvalTier.index > maxTier.index) {
        excluded[t.name] = 'above the ${maxTier.name} tier ceiling';
      } else {
        excluded[t.name] = 'not on the mode allow-list';
      }
    }
    return ToolSurfaceReport(included: included, excluded: excluded);
  }
}

/// What a [ToolSurfaceSpec] admitted and what it removed, with reasons.
class ToolSurfaceReport {
  /// Creates a report.
  const ToolSurfaceReport({required this.included, required this.excluded});

  /// Names present on the surface, in registration order.
  final List<String> included;

  /// Names removed, mapped to why.
  final Map<String, String> excluded;
}
