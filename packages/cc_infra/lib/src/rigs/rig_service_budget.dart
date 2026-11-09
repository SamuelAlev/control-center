part of 'rig_service.dart';

/// What bounds the machines a host keeps: the reaper (idle park, idle
/// close, hard TTL) and the resident-memory budget that evicts the least
/// recently used machine to make room.
extension _RigServiceBudget on RigService {
  /// Parks idle rigs, closes long-idle and expired ones.
  Future<void> _reap() async {
    if (_disposed || _reaping) {
      return;
    }
    _reaping = true;
    try {
      await _reapOnce();
    } finally {
      _reaping = false;
    }
  }

  Future<void> _reapOnce() async {
    final now = DateTime.now();
    for (final live in _live.values.toList()) {
      final rig = live.rig;
      // Someone may be using the app with no rig action in sight, and closing
      // the rig would reclaim nothing. Its opener owns its lifetime.
      if (rig.surface == RigSurface.window) {
        continue;
      }
      try {
        if (rig.isExpired(now)) {
          await _teardown(live, RigCloseReason.ttlExpired);
          _publishReaped(rig, RigCloseReason.ttlExpired);
          continue;
        }
        if (live.isInUse) {
          // Somebody has a terminal open or is watching the guest. The hard
          // TTL above still applies — a pin cannot make a rig immortal — but
          // idling it out from under a live consumer is what this exists to
          // prevent.
          continue;
        }
        final idleFor = now.difference(rig.lastActivityAt);
        if (idleFor > rig.spec.idleTimeout * 2) {
          await _teardown(live, RigCloseReason.idleTimeout);
          _publishReaped(rig, RigCloseReason.idleTimeout);
          continue;
        }
        if (idleFor > rig.spec.idleTimeout &&
            live.machine != null &&
            !live.machine!.parked) {
          // Park first, close later. Parking costs the user nothing (the next
          // action wakes it) and buys back the CPU; closing costs them their
          // machine, so it waits for twice the idle window.
          await _parkMachine(live.machine!);
          await _updateStatus(live, const RigParked(RigParkKind.idle));
          CcInfraLog.info(
            'rig/${rig.id}: parked after ${idleFor.inMinutes}m idle',
          );
        }
      } on Object catch (e) {
        CcInfraLog.warning('rig/${rig.id}: reap step failed: $e');
      }
    }
  }

  void _publishReaped(Rig rig, RigCloseReason reason) {
    _eventBus?.publish(
      RigReaped(
        workspaceId: rig.workspaceId,
        rigId: rig.id,
        reason: reason,
        agentId: rig.agentId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  /// Committed megabytes right now: every live machine plus every reservation
  /// an in-flight open is holding.
  int get _committedMb =>
      _live.values.fold<int>(0, (sum, l) => sum + l.residentMb) + _reservedMb;

  /// Makes room for [wantedMb] and RESERVES it, atomically.
  ///
  /// The check and the reservation have to happen under one lock because the
  /// check itself awaits evictions. Split, two concurrent opens for different
  /// conversations both read a total that excluded the other, both passed, and
  /// the host committed twice its budget — the `_opening` join only dedupes
  /// the same conversation and kind, so it never saw them.
  ///
  /// Throws (and reserves nothing) when even after evicting everything
  /// evictable there is not enough room.
  Future<void> _reserveResident(int wantedMb) {
    final previous = _budgetGate;
    final done = Completer<void>();
    _budgetGate = done.future;
    return previous.then((_) async {
      try {
        await _enforceResidentBudget(wantedMb);
        _reservedMb += wantedMb;
      } finally {
        // Released whatever happened: a failed reservation must not wedge
        // every later open behind a gate that never opens.
        done.complete();
      }
    });
  }

  /// Frees memory until `wantedMb` fits under the budget.
  ///
  /// Callers go through [_reserveResident], which holds a lock across this and
  /// the reservation that follows it.
  ///
  /// The budget counts RESIDENT megabytes, not sessions. A parked VM has
  /// stopped vCPUs and still holds every byte of its RAM, so counting sessions
  /// would let eight parked 2 GB desktops sit on 16 GB of a laptop and call it
  /// idle.
  Future<void> _enforceResidentBudget(int wantedMb) async {
    if (_committedMb + wantedMb <= _maxResidentMb) {
      return;
    }
    // Evict least-recently-used first, and never evict one a human is driving.
    final candidates = _live.values.toList()
      ..sort((a, b) => a.rig.lastActivityAt.compareTo(b.rig.lastActivityAt));
    for (final live in candidates) {
      if (_committedMb + wantedMb <= _maxResidentMb) {
        return;
      }
      // Never evict one somebody is driving, has a terminal in, or is
      // watching: reclaiming memory from under an open viewer trades a
      // measurable resource for an unexplainable disappearance.
      if (live.rig.isHumanControlled ||
          live.isInUse ||
          live.rig.surface == RigSurface.window) {
        continue;
      }
      CcInfraLog.info(
        'rig/${live.rig.id}: evicting to make room '
        '(${_committedMb}MB committed, ${_maxResidentMb}MB budget)',
      );
      // Recomputed from `_live` AFTER the teardown rather than deducted
      // before it: `_teardown` is what removes the entry, so a running tally
      // decremented up front counted memory as reclaimed while the eviction
      // was still in flight.
      await _teardown(live, RigCloseReason.memoryPressure);
      _publishReaped(live.rig, RigCloseReason.memoryPressure);
    }
    if (_committedMb + wantedMb > _maxResidentMb) {
      throw StateError(
        'Not enough memory budget for a ${wantedMb}MB rig: ${_committedMb}MB '
        'of ${_maxResidentMb}MB is already committed to rigs a person is '
        'using. Close one first.',
      );
    }
  }
}
