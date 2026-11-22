import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';

/// The run among [sessions] (the agent [agentId]'s in workspace [ws]) that
/// is live only for its Claude Code turn's background tasks
/// ([BackgroundHoldView]) and must yield for [wakes]: one of them cannot
/// join it (a rule's or a goal's wake, run options other than [pushable]
/// ones, a read-only or fresh run, another person, a run that takes no
/// more input). Null when there is none, or every wake can join it.
///
/// [afterRun]: the settlement's delivery, which a run that already yielded
/// and is still listed (its session ends after the settlement is
/// published) does not hold back ([yieldedHeldRun]).
BackgroundHoldView? heldRunToYield(
  Iterable<SteeringSessionView> sessions, {
  required String ws,
  required String agentId,
  required List<Wake> wakes,
  required bool afterRun,
  required bool Function(WakeRunOptions? options) pushable,
}) {
  for (final s in sessions) {
    if (s is! BackgroundHoldView ||
        s.workspaceId != ws ||
        s.agentId != agentId ||
        (afterRun && yieldedHeldRun(s))) {
      continue;
    }
    final held = s as BackgroundHoldView;
    if (!held.heldForBackgroundOnly) {
      continue;
    }
    final waits = wakes.any(
      (w) =>
          w.detail.ruleId != null ||
          w.detail.goalId != null ||
          !s.acceptsSteering ||
          !pushable(w.runOptions) ||
          s.readOnly ||
          s.freshHistory ||
          w.requestedByUserId != s.requestedByUserId,
    );
    return waits ? held : null;
  }
  return null;
}

/// Whether [s] is a run that yielded its background hold: it takes no more
/// input and ends by itself.
bool yieldedHeldRun(SteeringSessionView s) =>
    s is BackgroundHoldView &&
    (s as BackgroundHoldView).heldForBackgroundOnly &&
    !s.acceptsSteering;

/// Whether [sessions] hold a live run of [agentId] in [ws] that makes it
/// busy for a wake: any but one live only for its turn's background tasks,
/// which yields instead. True when none is listed (the run log said live).
bool busyBeyondBackgroundHold(
  Iterable<SteeringSessionView> sessions, {
  required String ws,
  required String agentId,
}) {
  final runs = [
    for (final s in sessions)
      if (s.workspaceId == ws && s.agentId == agentId && s.runLogId != null) s,
  ];
  return runs.isEmpty ||
      runs.any(
        (s) =>
            !(s is BackgroundHoldView &&
                (s as BackgroundHoldView).heldForBackgroundOnly),
      );
}
