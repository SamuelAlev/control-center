part of 'goal_supervisor.dart';

/// What happens when a goal's segment ends (plan section 8, "What happens
/// when a segment ends"): the settlement's routing (a review run to the
/// verifier, a claim to its verification, a stop, a server stop, a usage
/// limit, a failure) and the decision after a normal end (the budget wall,
/// what the agent is owed, progress and strikes).
extension _GoalSegmentEnd on GoalSupervisor {
  Future<void> _onRunSettled(AgentRunSettled event) async {
    if (await _verifier.onRunSettled(event)) {
      return;
    }
    final goal = await _segmentGoalOf(
      event.workspaceId,
      event.runId,
      conversationId: event.conversationId,
      agentId: event.agentId,
    );
    if (goal == null || goal.agentId != event.agentId) {
      return;
    }
    // The segment's cost counts whatever the goal's status. One atomic
    // write, and only once per segment.
    if (!await _store.goals.recordSegmentEnd(
      goal.workspaceId,
      goal.id,
      runId: event.runId,
      costMicros: event.costMicros,
      at: _store.now(),
    )) {
      return;
    }
    final counted = await _store.goals.getById(goal.workspaceId, goal.id);
    if (counted == null || counted.status != AgentGoalStatus.active) {
      _progress.activity.take(
        workspaceId: goal.workspaceId,
        runId: event.runId,
      );
      return;
    }
    if (counted.hold == GoalHold.verifying) {
      _progress.activity.take(
        workspaceId: goal.workspaceId,
        runId: event.runId,
      );
      if (event.endReason == RunEndReason.stoppedByUser) {
        await _pauseStopped(counted, claimPending: true);
        return;
      }
      // A server stop starts nothing: the claim stays pending and the
      // sweep at boot verifies it.
      if (event.endReason != RunEndReason.serverStopped) {
        await _verify(counted);
      }
      return;
    }
    switch (event.endReason) {
      case RunEndReason.stoppedByUser:
        _progress.activity.take(
          workspaceId: goal.workspaceId,
          runId: event.runId,
        );
        await _pauseStopped(counted, claimPending: false);
      case RunEndReason.serverStopped:
        // The server went away under the segment: not the agent's failure,
        // and nothing starts during a shutdown. The goal keeps its state;
        // the sweep at boot gives it its continuation.
        _progress.activity.take(
          workspaceId: goal.workspaceId,
          runId: event.runId,
        );
        await _clearPersonHold(counted);
      case RunEndReason.usageLimit:
        _progress.activity.take(
          workspaceId: goal.workspaceId,
          runId: event.runId,
        );
        await onLimitReached(counted, event);
      case RunEndReason.error || RunEndReason.silence:
        _progress.activity.take(
          workspaceId: goal.workspaceId,
          runId: event.runId,
        );
        await _segmentFailed(counted, event);
      case RunEndReason.completed || RunEndReason.budget:
        await _segmentEnded(counted, event);
    }
  }

  /// A failed segment (an error, silence, a usage limit today): a failure
  /// more and the backoff, or the goal fails at [GoalSupervisor.maxConsecutiveFailures].
  Future<void> _segmentFailed(AgentGoalRun goal, AgentRunSettled event) async {
    final failed = await _store.transition(
      goal,
      (g) => !GoalSupervisor._segmentEndApplies(g)
          ? null
          : GoalSupervisor._withoutPersonHold(g).copyWith(
              consecutiveFailures: g.consecutiveFailures + 1,
              updatedAt: _store.now(),
            ),
    );
    if (failed == null) {
      return;
    }
    final wall = budgetWall(failed);
    if (wall != null) {
      await _terminate(
        failed,
        AgentGoalStatus.budgetExhausted,
        'Durable /goal stopped: $wall.',
      );
      return;
    }
    final failures = failed.consecutiveFailures;
    if (failures >= GoalSupervisor.maxConsecutiveFailures) {
      await _terminate(
        failed,
        AgentGoalStatus.failed,
        'Durable /goal failed: $failures segments in a row ended in error '
        '(${event.endReason.wire}). Giving up.',
      );
      return;
    }
    final delay = GoalSupervisor.backoff(failures);
    await _store.say(
      failed,
      'Durable /goal: segment ${failed.runCount} ended in error '
      '(${event.endReason.wire}); retrying in ${GoalSupervisor._seconds(delay)} '
      '(failure $failures of ${GoalSupervisor.maxConsecutiveFailures}).',
    );
    await _store.insertSegmentWake(failed, notBefore: _store.now().add(delay));
  }

  /// A segment that ended normally (or at its own cap): the budget wall,
  /// then what the agent is owed, then progress (plan section 8).
  Future<void> _segmentEnded(AgentGoalRun goal, AgentRunSettled event) async {
    final log = await _runLogs.getById(goal.workspaceId, event.runId);
    final wall = budgetWall(goal);
    if (wall != null) {
      _progress.activity.take(
        workspaceId: goal.workspaceId,
        runId: event.runId,
      );
      final wrapUp = log?.summary?.trim();
      await _terminate(
        goal,
        AgentGoalStatus.budgetExhausted,
        'Durable /goal stopped: $wall.'
        '${wrapUp == null || wrapUp.isEmpty ? '' : '\n\n$wrapUp'}',
        summary: wrapUp == null || wrapUp.isEmpty ? null : wrapUp,
      );
      return;
    }
    final observed = await _progress.observe(
      goal,
      runId: event.runId,
      runStartedAt: log?.startedAt,
    );
    final owed = await _owed.of(goal);
    final now = _store.now();
    final mark = GoalProgressMarks.markOf(
      fingerprint: observed.fingerprint,
      checklist: observed.checklistDigest,
      activity: observed.activityDigest,
    );
    var progressed = false;
    final next = await _store.transition(goal, (g) {
      if (!GoalSupervisor._segmentEndApplies(g)) {
        return null;
      }
      final seen = g.progressMarks ?? GoalProgressMarks.empty;
      // A state the goal has had before is no progress, however it differs
      // from the last segment's.
      progressed = observed.progressed && !seen.seen(mark);
      var marks = seen.remember(mark);
      final base = GoalSupervisor._withoutPersonHold(g).copyWith(
        consecutiveFailures: 0,
        lastFingerprint: observed.fingerprint,
        lastActivityDigest: observed.activityDigest,
        updatedAt: now,
      );
      if (owed.isOwed) {
        // Waiting is not a strike: a goal that watches or asks makes no
        // progress of its own between answers. But the waiting stretch is
        // the goal's, whatever it waits on: each wait without progress
        // doubles the fallback, and a day of it, or six waits on work it
        // set up anew (answers arriving never count), stops the goal for a
        // person.
        marks = marks.waited(ids: owed.setUp, progressed: progressed, now: now);
        final streak = progressed ? 0 : g.noProgressStreak;
        if (marks.stalled(now)) {
          return base.copyWith(
            status: AgentGoalStatus.paused,
            hold: GoalHold.needsReview,
            holdDetail: GoalHoldDetails.stalledWaiting,
            noProgressStreak: streak,
            progressMarks: marks,
          );
        }
        final detail = owed.describe();
        return base.copyWith(
          hold: GoalHold.waiting,
          holdDetail: detail.length > AgentGoalRun.maxHoldDetailLength
              ? detail.substring(0, AgentGoalRun.maxHoldDetailLength)
              : detail,
          holdUntil: now.add(marks.fallback),
          noProgressStreak: streak,
          progressMarks: marks,
        );
      }
      marks = marks.endWait();
      if (progressed) {
        return base.copyWith(noProgressStreak: 0, progressMarks: marks);
      }
      final strikes = g.noProgressStreak + 1;
      if (strikes >= goalMaxNoProgressSegments) {
        return base.copyWith(
          status: AgentGoalStatus.paused,
          hold: GoalHold.needsReview,
          holdDetail: GoalHoldDetails.stalled,
          noProgressStreak: strikes,
          progressMarks: marks,
        );
      }
      return base.copyWith(noProgressStreak: strikes, progressMarks: marks);
    });
    if (next == null) {
      return;
    }
    if (next.hold == GoalHold.waiting) {
      final fallback = (next.progressMarks ?? GoalProgressMarks.empty).fallback;
      await _store.say(
        next,
        'Durable /goal waits for ${next.holdDetail}. It continues with the '
        'first wake that arrives, or in ${fallback.inMinutes} minutes.',
      );
      await _store.insertSegmentWake(next, notBefore: now.add(fallback));
      return;
    }
    if (next.status == AgentGoalStatus.paused) {
      final summary = next.holdDetail == GoalHoldDetails.stalledWaiting
          ? stalledWaitingSummary(
              next.progressMarks ?? GoalProgressMarks.empty,
              now,
            )
          : 'No progress was observed in $goalMaxNoProgressSegments segments '
                'in a row. Decide: continue, edit the contract, or close the '
                'goal.';
      await _store.say(next, 'Durable /goal waits for a person: $summary');
      _store.publishSettled(next, summary: summary);
      return;
    }
    if (progressed) {
      await _store.insertSegmentWake(next);
      return;
    }
    final delay =
        GoalSupervisor.strikeDelays[(next.noProgressStreak - 1).clamp(
          0,
          GoalSupervisor.strikeDelays.length - 1,
        )];
    await _store.say(
      next,
      'Durable /goal: no progress observed in segment ${next.runCount} '
      '(strike ${next.noProgressStreak} of $goalMaxNoProgressSegments); '
      'continuing in ${GoalSupervisor._seconds(delay)}.',
    );
    await _store.insertSegmentWake(next, notBefore: now.add(delay));
  }

  Future<AgentGoalRun> _clearPersonHold(AgentGoalRun goal) async {
    if (goal.hold != GoalHold.person) {
      return goal;
    }
    return await _store.transition(
          goal,
          (g) => g.hold != GoalHold.person
              ? null
              : GoalSupervisor._withoutPersonHold(
                  g,
                ).copyWith(updatedAt: _store.now()),
        ) ??
        goal;
  }

  Future<void> _pauseStopped(
    AgentGoalRun goal, {
    required bool claimPending,
  }) async {
    final paused = await _store.transition(
      goal,
      (g) => g.status != AgentGoalStatus.active
          ? null
          : g.copyWith(
              status: AgentGoalStatus.paused,
              hold: GoalHold.byPerson,
              holdDetail: claimPending
                  ? GoalSupervisor.claimPendingDetail
                  : null,
              removeHoldDetail: !claimPending,
              removeHoldUntil: true,
              updatedAt: _store.now(),
            ),
    );
    if (paused == null) {
      return;
    }
    await _store.cancelWakes(paused, GoalWakeReasons.stopped);
    await _store.say(
      paused,
      'Durable /goal paused: its run was stopped. Resume it to keep it '
      'running.',
    );
  }
}

/// The person-visible reason of a `stalled_waiting` stop: how long the goal
/// waited without progress, over how many segments, and in how many of them
/// it set up new work to wait on (when that is what stopped it).
String stalledWaitingSummary(GoalProgressMarks marks, DateTime now) {
  final waited = marks.waitedFor(now);
  final span = waited.inHours >= 1
      ? '${waited.inHours} h ${waited.inMinutes % 60} min'
      : '${waited.inMinutes} min';
  final fresh = marks.freshWaits >= GoalProgressMarks.maxFreshWaits
      ? ', setting up new work to wait on in ${marks.freshWaits} of them'
      : '';
  return 'The goal waited $span over ${marks.waits} segments without '
      'progress$fresh. Decide: continue, edit the contract, or close the '
      'goal.';
}
