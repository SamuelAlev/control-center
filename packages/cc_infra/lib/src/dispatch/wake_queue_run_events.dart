part of 'wake_queue_service.dart';

/// What the queue does when a run drains a pushed wake, and when a run
/// settles: the lane bookkeeping, a person's stop, a server stop's recovery.
extension _WakeQueueRunEvents on WakeQueueService {
  void _listen(SteeringQueue queue) {
    if (_listening[queue] ?? false) {
      return;
    }
    _listening[queue] = true;
    final previous = queue.onDrained;
    queue.onDrained = (message) {
      previous?.call(message);
      _onDrained(message);
    };
  }

  void _onDrained(SteeringMessage message) {
    final ref = message.ref;
    if (ref == null || !ref.startsWith(WakeQueueService._refPrefix)) {
      return;
    }
    final entry = _inLane.remove(
      ref.substring(WakeQueueService._refPrefix.length),
    );
    if (entry == null) {
      return;
    }
    // At once, before the run's turn can end and read its chain.
    final chain = entry.wake.chain;
    if (chain.isNotEmpty) {
      chainCarried?.call(entry.workspaceId, entry.runId, chain);
    }
    unawaited(() async {
      try {
        final ws = entry.workspaceId;
        final id = entry.wake.id;
        // The run's record first, so its settlement names the wake.
        await _ledger.addWakeIds(ws, entry.runId, [id]);
        final moved = await _wakes.markDelivered(
          ws,
          ids: [id],
          runId: entry.runId,
          now: _clock(),
        );
        if (moved == 1) {
          await _settled(entry.wake, WakeState.delivered, runId: entry.runId);
        }
      } on Object catch (e, st) {
        CcInfraLog.error('WakeQueueService: drain record failed', e, st);
      }
    }());
  }

  void _heardSettled(AgentRunSettled event) {
    // Before anything awaits: a push racing this run's end sees it.
    _settledRuns[event.runId] = event.endReason;
    if (_settledRuns.length > 512) {
      _settledRuns.remove(_settledRuns.keys.first);
    }
    final handling = _onRunSettled(event);
    _settling.add(handling);
    unawaited(handling.whenComplete(() => _settling.remove(handling)));
  }

  Future<void> _onRunSettled(AgentRunSettled event) async {
    if (_stopped) {
      return;
    }
    final ws = event.workspaceId;
    final conv = event.conversationId;
    try {
      // Wakes in the run's lane it never took go back to pending, and a
      // new run delivers them.
      final undrained = <String>[];
      for (final entry in _inLane.entries.toList()) {
        if (entry.value.runId != event.runId) {
          continue;
        }
        if (entry.value.queue.removeByRef(WakeQueueService._ref(entry.key))) {
          undrained.add(entry.key);
        }
        _inLane.remove(entry.key);
      }
      _nonceByRun.remove(event.runId);
      _pushedTo.removeWhere((_, runId) => runId == event.runId);
      if (undrained.isNotEmpty) {
        await _wakes.releaseClaim(ws, ids: undrained);
        _workspaces.add(ws);
      }
      if (conv == null) {
        return;
      }
      switch (event.endReason) {
        case RunEndReason.stoppedByUser:
          // A person stopped the run: nothing of that agent here starts
          // again until they release it (a goal's wakes are the goal's).
          await hold(
            ws,
            conversationId: conv,
            agentId: event.agentId,
            reason: WakeStateReasons.stopped,
          );
        case RunEndReason.serverStopped:
          await _recoverStopped(event, conv);
        case _:
          break;
      }
      _workspaces.add(ws);
      if (_halted || !_started) {
        // Shutdown, or the boot reaper before [start]: state only.
        return;
      }
      await _deliverKey(ws, conv, event.agentId, afterRun: true);
      await _arm();
    } on Object catch (e, st) {
      CcInfraLog.error('WakeQueueService: settled ${event.runId}', e, st);
    }
  }

  /// A server stop ended [event]'s run: every wake it took is delivered
  /// again by a new run (claims a restart left between the run row and its
  /// delivery included), up to [WakeQueueService.maxAttempts]; a run a
  /// person started also leaves a held recovery wake for their Resume.
  Future<void> _recoverStopped(AgentRunSettled event, String conv) async {
    final ws = event.workspaceId;
    final now = _clock();
    final ids = event.wakeIds;
    if (ids.isNotEmpty) {
      final mine = _dispatching[ws] ?? const <String>{};
      final claimed = <String>[];
      for (final id in ids) {
        final wake = await _wakes.getById(ws, id);
        if (wake?.state == WakeState.claimed &&
            !mine.contains(id) &&
            !_inLane.containsKey(id)) {
          claimed.add(id);
        }
      }
      if (claimed.isNotEmpty) {
        await _wakes.releaseClaim(ws, ids: claimed);
      }
      await _wakes.reopenDelivered(
        ws,
        ids: ids,
        reason: WakeStateReasons.serverStopped,
      );
      final spent = <Wake>[];
      for (final id in ids) {
        final wake = await _wakes.getById(ws, id);
        if (wake != null &&
            wake.state == WakeState.pending &&
            wake.attempt >= WakeQueueService.maxAttempts) {
          spent.add(wake);
        }
      }
      await _skip(ws, spent, WakeStateReasons.attempts, now);
    }
    final person = event.requestedByUserId;
    final spaceId = event.spaceId;
    if (event.wakeReason != WakeReason.userMessage ||
        person == null ||
        spaceId == null) {
      return;
    }
    // A person who left the workspace has nothing to resume: their run was
    // stopped because they left, and a held wake would wait for ever.
    if (!await _ports.isMember(ws, person)) {
      return;
    }
    // A person's run parked at its provider's usage limit already has the
    // wake that resumes it after the reset: no second one.
    final parked = await _wakes.getByDedupKey(
      ws,
      LimitPark.dedupKey(event.runId),
    );
    if (parked != null && !parked.state.isSettled) {
      return;
    }
    // A person's run: a held recovery wake waits for their Resume. It
    // continues the stopped run, so it carries that run's lineage, as every
    // enqueued wake does.
    await _wakes.insertIfAbsent(
      await carryWakeLineage(
        Wake(
          id: _newId(),
          workspaceId: ws,
          spaceId: spaceId,
          conversationId: conv,
          agentId: event.agentId,
          reason: WakeReason.recovery,
          payload: '',
          detail: WakeDetail(sourceRunId: event.runId),
          dedupKey: 'recovery:${event.runId}',
          notBefore: now,
          requestedByUserId: person,
          state: WakeState.held,
          stateReason: WakeStateReasons.serverRestarted,
          createdAt: now,
        ),
        lineageRootOfRuns,
      ),
    );
  }
}

class _LaneEntry {
  _LaneEntry({
    required this.workspaceId,
    required this.runId,
    required this.queue,
    required this.wake,
  });

  final String workspaceId;
  final String runId;
  final SteeringQueue queue;
  final Wake wake;
}

/// The settlements of one delivery, held until it left its key's chain. A
/// settlement made after that (a timer the delivery armed) is not held.
class _SettlementBuffer {
  static final Object zoneKey = Object();

  final List<WakeSettlement> _held = [];
  bool _open = true;

  /// Holds [settlement]; false once the buffer is closed.
  bool add(WakeSettlement settlement) {
    if (!_open) {
      return false;
    }
    _held.add(settlement);
    return true;
  }

  /// Closes the buffer and returns what it held.
  List<WakeSettlement> close() {
    _open = false;
    return List.of(_held);
  }
}
