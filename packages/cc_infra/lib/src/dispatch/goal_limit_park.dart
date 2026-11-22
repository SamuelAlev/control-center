part of 'goal_supervisor.dart';

/// A goal's park at a provider's usage limit (plan section 11, D23).
///
/// A segment that ended on `usageLimit` with a reported reset at most
/// [LimitPark.maxWait] away writes a `limitReset` wake for the reset plus
/// [LimitPark.resetSlack] (`limit:<runId>`), then holds the goal (`hold:
/// limit`, `holdUntil` the reset, `parkCount + 1`), in that order: a crash
/// between the two leaves a wake without a hold, never a hold without a
/// wake. Neither a strike nor a failure is counted. The park after the
/// [LimitPark.maxGoalParks]th pauses the goal for a person
/// (`needsReview`, [LimitPark.goalHoldDetail]). With no reset to honour the
/// segment fails as any other failed segment does.
extension _GoalLimitPark on GoalSupervisor {
  Future<void> _parkAtLimit(AgentGoalRun goal, AgentRunSettled event) async {
    if (_store.queue.stopping) {
      // A limit reported while the server stops is not a park: nothing
      // starts during a shutdown, and the boot sweep resumes the goal (as
      // for a `serverStopped` segment).
      await _clearPersonHold(goal);
      return;
    }
    final now = _store.now();
    final reset = LimitPark.honouredReset(event.limitResetsAt, now);
    if (reset == null) {
      await _segmentFailed(goal, event);
      return;
    }
    if (goal.parkCount >= LimitPark.maxGoalParks) {
      await _pauseAtParkLimit(goal);
      return;
    }
    final log = await _runLogs.getById(goal.workspaceId, event.runId);
    final provider = LimitPark.providerLabel(
      adapter: log?.adapter,
      modelId: log?.modelId,
    );
    final wake = await _store.insertLimitWake(
      goal,
      runId: event.runId,
      reset: reset,
      provider: provider,
    );
    if (wake == null) {
      // No wake, no park: a hold nothing resumes would strand the goal.
      await _segmentFailed(goal, event);
      return;
    }
    final parked = await _store.transition(
      goal,
      (g) => !GoalSupervisor._segmentEndApplies(g)
          ? null
          : GoalSupervisor._withoutPersonHold(g).copyWith(
              hold: GoalHold.limit,
              holdUntil: reset,
              removeHoldDetail: true,
              parkCount: g.parkCount + 1,
              updatedAt: now,
            ),
    );
    if (parked == null) {
      // The goal moved meanwhile (a person paused or ended it): its wake
      // must not resume it before the person does.
      await _store.cancelWakes(goal, GoalWakeReasons.stopped);
      return;
    }
    await _store.say(
      parked,
      'Durable /goal: segment ${parked.runCount} reached the $provider usage '
      'limit. It resumes after the reset, at '
      '${LimitPark.stamp(LimitPark.resumeAt(reset))} (park '
      '${parked.parkCount} of ${LimitPark.maxGoalParks}).',
    );
  }

  Future<void> _pauseAtParkLimit(AgentGoalRun goal) async {
    final paused = await _store.transition(
      goal,
      (g) => !GoalSupervisor._segmentEndApplies(g)
          ? null
          : GoalSupervisor._withoutPersonHold(g).copyWith(
              status: AgentGoalStatus.paused,
              hold: GoalHold.needsReview,
              holdDetail: LimitPark.goalHoldDetail,
              removeHoldUntil: true,
              updatedAt: _store.now(),
            ),
    );
    if (paused == null) {
      return;
    }
    await _store.cancelWakes(paused, GoalWakeReasons.stopped);
    const summary =
        'The provider usage limit stopped the goal '
        '${LimitPark.maxGoalParks + 1} times. Resume it to let it wait for '
        'the next reset again.';
    await _store.say(paused, 'Durable /goal waits for a person: $summary');
    _store.publishSettled(paused, summary: summary);
  }

  /// Whether the guard holds [wake] back for [goal]'s hold: every hold but
  /// `waiting` does, except `limit` for the goal's own `limitReset` wake.
  bool _heldFor(AgentGoalRun goal, Wake wake) {
    final hold = goal.hold;
    if (hold == null || hold == GoalHold.waiting) {
      return false;
    }
    return !(hold == GoalHold.limit && wake.reason == WakeReason.limitReset);
  }

  /// A goal's `limitReset` wake that someone other than the goal cancelled
  /// (a person's `wakes.cancel`): the goal does not resume by itself, so it
  /// is paused as a person's pause is. True when [settled] was such a wake.
  Future<bool> _limitWakeCancelled(WakeSettlement settled) async {
    final wake = settled.wake;
    final goalId = wake.detail.goalId;
    if (wake.reason != WakeReason.limitReset ||
        goalId == null ||
        settled.state != WakeState.cancelled) {
      return false;
    }
    if ((settled.reason ?? '').startsWith('goal_')) {
      return true; // The goal's own cancel: it already moved on.
    }
    final goal = await _store.goals.getById(wake.workspaceId, goalId);
    if (goal == null ||
        goal.status != AgentGoalStatus.active ||
        goal.hold != GoalHold.limit) {
      return true;
    }
    await _pauseStopped(goal, claimPending: false);
    return true;
  }

  /// The sweep's view of a goal parked at a limit: nothing while its wake
  /// is open or before the reset; with no open wake after the reset (none
  /// should be missing: the wake is written before the hold, and a skipped
  /// or cancelled one pauses the goal), the hold is cleared and the next
  /// segment's wake written.
  Future<void> _sweepLimit(AgentGoalRun goal) async {
    final until = goal.holdUntil;
    final now = _store.now();
    if ((until != null && LimitPark.resumeAt(until).isAfter(now)) ||
        (await _store.openWakes(goal)).isNotEmpty) {
      return;
    }
    final resumed = await _store.transition(
      goal,
      (g) => g.status != AgentGoalStatus.active || g.hold != GoalHold.limit
          ? null
          : g.copyWith(removeHold: true, removeHoldUntil: true, updatedAt: now),
    );
    if (resumed != null) {
      await _store.insertSegmentWake(resumed);
    }
  }
}
