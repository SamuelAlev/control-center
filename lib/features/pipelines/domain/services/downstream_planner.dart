import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';

/// The decision the engine acts on after a step settles: which steps to mark
/// skipped, which to schedule, and whether the run has reached a terminal.
///
/// Computed by [planDownstream] from the current completion state — a pure
/// function so the branching/skip rules can be unit-tested without the engine,
/// repository, or event bus.
class DownstreamPlan {
  /// Creates a [DownstreamPlan].
  const DownstreamPlan({
    required this.toSkip,
    required this.toRun,
    required this.terminalReached,
  });

  /// Step ids that can never fire (a router took another branch, or an
  /// upstream was skipped) and should be recorded as `skipped`.
  final List<String> toSkip;

  /// Step ids that are now ready to execute.
  final List<String> toRun;

  /// Whether at least one terminal node has a fully-*completed* incoming
  /// branch, meaning the run is done.
  final bool terminalReached;
}

/// Decides what happens next in [definition] given the steps that have
/// [completed] and those already [skipped], the [existing] step-run ids (any
/// status — these are neither re-skipped nor re-run), and the branch each
/// router [chosenRoutes] selected (`stepId -> routeKey`).
///
/// Branching rules:
/// - A non-join step fires when **every** trigger is satisfied: all of a
///   trigger's sources have *completed* (skipped does not count) and, for a
///   routed edge, the source router chose exactly this key.
/// - A join fires when **all** its `waitForStepIds` have reached a terminal
///   state (completed *or* skipped) — so a gated branch that was skipped does
///   not stall the join.
/// - A step is *dead* (→ skipped) when any of its triggers can never be
///   satisfied: a source was skipped, or a routed source router chose a
///   different key. Skipping one step can kill its descendants, so skip
///   detection iterates to a fixpoint. Joins are never killed this way (a
///   skipped wait-for source still counts as terminal for them).
/// - A terminal is "reached" only via a branch that actually *completed*; an
///   all-skipped incoming edge does not finish the run.
DownstreamPlan planDownstream({
  required PipelineDefinition definition,
  required Set<String> completed,
  required Set<String> skipped,
  required Set<String> existing,
  required Map<String, String> chosenRoutes,
}) {
  final skip = <String>{...skipped};
  final existSet = <String>{...existing};
  final toSkip = <String>[];

  bool triggerDead(StepTrigger t) {
    for (final src in t.sourceStepIds) {
      if (skip.contains(src)) return true;
    }
    if (t.routeKey != null && t.sourceStepIds.isNotEmpty) {
      final src = t.sourceStepIds.first;
      if (chosenRoutes.containsKey(src) && chosenRoutes[src] != t.routeKey) {
        return true;
      }
    }
    return false;
  }

  bool isDead(PipelineStepDefinition s) {
    // Joins resolve on terminal state, which skips satisfy — never dead.
    if (s.kind == StepKind.join) return false;
    if (s.triggers.isEmpty) return false;
    return s.triggers.any(triggerDead);
  }

  var changed = true;
  while (changed) {
    changed = false;
    for (final s in definition.steps) {
      if (s.kind == StepKind.trigger || s.kind == StepKind.terminal) continue;
      if (existSet.contains(s.id)) continue;
      if (!isDead(s)) continue;
      toSkip.add(s.id);
      existSet.add(s.id);
      skip.add(s.id);
      changed = true;
    }
  }

  final terminalSet = <String>{...completed, ...skip};

  final terminalReached = definition.steps.any((s) =>
      s.kind == StepKind.terminal &&
      s.triggers.any((t) =>
          t.sourceStepIds.isNotEmpty &&
          t.sourceStepIds.every(terminalSet.contains) &&
          // Reached only through a branch that genuinely completed; a wholly
          // skipped incoming edge must not finish the run.
          t.sourceStepIds.any(completed.contains)));

  bool triggerSatisfied(StepTrigger t) {
    if (!t.sourceStepIds.every(completed.contains)) return false;
    if (t.routeKey != null) {
      final src = t.sourceStepIds.isEmpty ? null : t.sourceStepIds.first;
      return src != null && chosenRoutes[src] == t.routeKey;
    }
    return true;
  }

  final toRun = <String>[];
  for (final s in definition.steps) {
    if (s.kind == StepKind.trigger || s.kind == StepKind.terminal) continue;
    if (existSet.contains(s.id)) continue;
    if (s.triggers.isEmpty) continue;
    final ready = s.kind == StepKind.join
        ? s.waitForStepIds.every(terminalSet.contains)
        : s.triggers.every(triggerSatisfied);
    if (ready) toRun.add(s.id);
  }

  return DownstreamPlan(
    toSkip: toSkip,
    toRun: toRun,
    terminalReached: terminalReached,
  );
}
