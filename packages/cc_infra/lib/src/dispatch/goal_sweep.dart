part of 'goal_supervisor.dart';

/// The sweep ([GoalSupervisor.sweep]): every five minutes and once at boot,
/// each active goal that has nothing running, holding or queued is given
/// its next wake.
extension _GoalSweep on GoalSupervisor {
  Future<void> _sweepAll() async {
    if (_sweeping) {
      return;
    }
    _sweeping = true;
    try {
      for (final listed in await _store.goals.listActive()) {
        try {
          await _sweepOne(listed);
        } on Object catch (e, st) {
          CcInfraLog.error('goal ${listed.id}: sweep failed', e, st);
        }
      }
    } finally {
      _sweeping = false;
    }
  }

  Future<void> _sweepOne(AgentGoalRun listed) async {
    if (listed.status != AgentGoalStatus.active) {
      return;
    }
    var goal = listed;
    final active = goal.activeRunId;
    if (active != null) {
      _remember(goal.workspaceId, active, goal.id);
      final log = await _runLogs.getById(goal.workspaceId, active);
      if (log != null && log.isActive) {
        return;
      }
      final ended = log?.completedAt;
      // Its settlement is still being handled; a server stop's starts
      // nothing, so the sweep at boot continues it at once.
      if (ended != null &&
          log?.endReason != RunEndReason.serverStopped &&
          _store.now().difference(ended) < const Duration(minutes: 1)) {
        return;
      }
      // The segment ended while nothing listened: count it now. Whoever
      // records it first (this or its settlement) is the only one to.
      await _store.goals.recordSegmentEnd(
        goal.workspaceId,
        goal.id,
        runId: active,
        costMicros: log?.totalCostMicrosWithChildren ?? 0,
        at: _store.now(),
      );
      final reread = await _store.goals.getById(goal.workspaceId, goal.id);
      if (reread == null || reread.status != AgentGoalStatus.active) {
        return;
      }
      goal = await _clearPersonHold(reread);
    }
    switch (goal.hold) {
      case GoalHold.verifying:
        // The verifier settles what the verification already has (a review
        // that ended unapplied, a review wake that settled without a run)
        // before it starts a new pass. Never awaited: one goal's checks do
        // not hold up the others' recovery.
        if (goal.verification != null && !_verifying.contains(goal.id)) {
          _verifyLater(goal);
        }
        return;
      case GoalHold.waiting:
        if ((await _store.openWakes(goal)).isEmpty) {
          final due = goal.holdUntil;
          await _store.insertSegmentWake(
            goal,
            notBefore: due != null && due.isAfter(_store.now()) ? due : null,
          );
        }
        return;
      case GoalHold.limit:
        await _sweepLimit(goal);
        return;
      case GoalHold.person || GoalHold.byPerson || GoalHold.needsReview:
        return;
      case null:
        break;
    }
    final wall = budgetWall(goal);
    if (wall != null) {
      await _terminate(
        goal,
        AgentGoalStatus.budgetExhausted,
        'Durable /goal stopped: $wall.',
      );
      return;
    }
    if ((await _store.openWakes(goal)).isNotEmpty) {
      return;
    }
    await _store.insertSegmentWake(goal);
  }
}
