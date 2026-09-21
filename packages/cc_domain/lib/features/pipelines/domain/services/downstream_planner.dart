import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';

/// The decision the engine acts on after a step settles: which steps to mark
/// skipped, which to schedule and whether the run has reached a terminal.
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

/// Next steps given [completed]/[skipped]/[existing]/[chosenRoutes]. Pure.
///
/// [resumable] bypasses [existing] (crash-resume). [startStepId] ignores other
/// triggers' edges. Non-join: every work trigger satisfied (completed only;
/// routed key exact). Start-bound+work: either side readies. Join: all
/// wait-fors terminal. Dead→skipped at fixpoint (joins never killed). Terminal
/// only via a completed branch.
DownstreamPlan planDownstream({
  required PipelineDefinition definition,
  required Set<String> completed,
  required Set<String> skipped,
  required Set<String> existing,
  required Map<String, String> chosenRoutes,
  Set<String> resumable = const {},
  String? startStepId,
}) {
  final skip = <String>{...skipped};
  final existSet = <String>{...existing};
  final toSkip = <String>[];

  final triggerIds = {
    for (final step in definition.steps)
      if (step.kind == StepKind.trigger) step.id,
  };
  final startId =
      startStepId ?? (triggerIds.length == 1 ? triggerIds.single : null);

  bool isStartBound(StepTrigger t) => t.sourceStepIds.any(triggerIds.contains);

  bool appliesToRun(StepTrigger t) {
    if (startId == null || !isStartBound(t)) {
      return true;
    }
    return t.sourceStepIds.contains(startId);
  }

  bool triggerDead(StepTrigger t) {
    for (final src in t.sourceStepIds) {
      if (skip.contains(src)) {
        return true;
      }
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
    if (s.kind == StepKind.join) {
      return false;
    }
    if (s.triggers.isEmpty) {
      return false;
    }
    final applicable = [
      for (final t in s.triggers)
        if (appliesToRun(t)) t,
    ];
    if (applicable.isEmpty) {
      return true;
    }
    final startBound = [
      for (final t in applicable)
        if (isStartBound(t)) t,
    ];
    final work = [
      for (final t in applicable)
        if (!isStartBound(t)) t,
    ];
    final startDead = startBound.isEmpty || startBound.every(triggerDead);
    final workDead = work.any(triggerDead);
    if (startBound.isEmpty) {
      return workDead;
    }
    if (work.isEmpty) {
      return startBound.every(triggerDead);
    }
    return workDead && startDead;
  }

  var changed = true;
  while (changed) {
    changed = false;
    for (final s in definition.steps) {
      if (s.kind == StepKind.trigger || s.kind == StepKind.terminal) {
        continue;
      }
      if (existSet.contains(s.id)) {
        continue;
      }
      if (!isDead(s)) {
        continue;
      }
      toSkip.add(s.id);
      existSet.add(s.id);
      skip.add(s.id);
      changed = true;
    }
  }

  final terminalSet = <String>{...completed, ...skip};

  final terminalReached = definition.steps.any(
    (s) =>
        s.kind == StepKind.terminal &&
        s.triggers.any(
          (t) =>
              t.sourceStepIds.isNotEmpty &&
              t.sourceStepIds.every(terminalSet.contains) &&
              // Reached only through a branch that genuinely completed; a wholly
              // skipped incoming edge must not finish the run.
              t.sourceStepIds.any(completed.contains),
        ),
  );

  bool triggerSatisfied(StepTrigger t) {
    if (!t.sourceStepIds.every(completed.contains)) {
      return false;
    }
    if (t.routeKey != null) {
      final src = t.sourceStepIds.isEmpty ? null : t.sourceStepIds.first;
      return src != null && chosenRoutes[src] == t.routeKey;
    }
    return true;
  }

  final toRun = <String>[];
  for (final s in definition.steps) {
    if (s.kind == StepKind.trigger || s.kind == StepKind.terminal) {
      continue;
    }
    // A resumable step owns a row but has never run to completion, so the
    // existing-row veto must not hide it: the row is what a re-fire executes ON,
    // not evidence that it already ran.
    if (existSet.contains(s.id) && !resumable.contains(s.id)) {
      continue;
    }
    if (s.triggers.isEmpty) {
      continue;
    }
    final bool ready;
    if (s.kind == StepKind.join) {
      ready = s.waitForStepIds.every(terminalSet.contains);
    } else {
      final applicable = [
        for (final t in s.triggers)
          if (appliesToRun(t)) t,
      ];
      if (applicable.isEmpty) {
        ready = false;
      } else {
        final startBound = [
          for (final t in applicable)
            if (isStartBound(t)) t,
        ];
        final work = [
          for (final t in applicable)
            if (!isStartBound(t)) t,
        ];
        final startOk =
            startBound.isNotEmpty && startBound.any(triggerSatisfied);
        final workOk = work.isNotEmpty && work.every(triggerSatisfied);
        if (startBound.isEmpty) {
          ready = workOk;
        } else if (work.isEmpty) {
          ready = startOk;
        } else {
          ready = startOk || workOk;
        }
      }
    }
    if (ready) {
      toRun.add(s.id);
    }
  }

  return DownstreamPlan(
    toSkip: toSkip,
    toRun: toRun,
    terminalReached: terminalReached,
  );
}
