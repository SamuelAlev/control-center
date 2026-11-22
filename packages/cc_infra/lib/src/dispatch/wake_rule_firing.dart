part of 'wake_rule_service.dart';

/// The firing half of [WakeRuleService]: the admission guard, the settled
/// handler, the slot arithmetic, cost, goal and member endings, and the
/// boot scan.
extension on WakeRuleService {
  // ------------------------------------------------------------- arming

  /// Writes the rule's pending wake for the slot of [at] (cut to the whole
  /// second). The rule row already names that slot as its `nextFireAt`.
  /// Returns whether a wake was written.
  Future<bool> _armSlot(WakeRule rule, DateTime at) async {
    final slot = wakeSlotOf(at);
    final now = _clock().toUtc();
    final wake = Wake(
      id: _newId(),
      workspaceId: rule.workspaceId,
      spaceId: rule.spaceId,
      conversationId: rule.conversationId,
      agentId: rule.agentId,
      reason: WakeReason.schedule,
      payload: rule.note,
      detail: WakeDetail(
        ruleId: rule.id,
        slot: slot,
        fields: _ruleFields(rule),
      ),
      runOptions: WakeRunOptions(
        costCapMicros: await _perRunCapInLineage(rule),
      ),
      dedupKey: wakeRuleDedupKey(rule.id, slot),
      notBefore: slot,
      expiresAt: _wakeExpiry(rule, slot),
      requestedByUserId: rule.requestedByUserId,
      createdAt: now,
    );
    try {
      return await _queue.enqueue(wake);
    } on WorkspaceMismatchException catch (e) {
      CcInfraLog.warning('WakeRuleService: rule ${rule.id} not armed: $e');
      return false;
    }
  }

  /// A run's cost cap: what is left of the rule's budget, at most
  /// [WakeRuleBounds.perRunCostCapMicros]. A rule's wake carries the
  /// smaller of this and what its lineage has left
  /// ([_perRunCapInLineage]).
  int _perRunCap(WakeRule rule) {
    final remaining = rule.costCapMicros - rule.costMicros;
    return remaining <= 0
        ? 1
        : remaining < WakeRuleBounds.perRunCostCapMicros
        ? remaining
        : WakeRuleBounds.perRunCostCapMicros;
  }

  Map<String, Object?> _ruleFields(WakeRule rule) => {
    WakeFields.origin: rule.origin.wire,
    WakeFields.setAt: rule.createdAt.toUtc().toIso8601String(),
    WakeFields.trigger: formatWakeWhen(rule.trigger),
    WakeFields.run: rule.runCount + 1,
    if (rule.maxRuns != null) WakeFields.maxRuns: rule.maxRuns,
  };

  /// When a rule's wake for [slot] stops being worth delivering: a one-off
  /// after a day; with `when_busy: skip` after the grace; with `queue` at
  /// the next slot (it waited for a live run that long).
  DateTime _wakeExpiry(WakeRule rule, DateTime slot) {
    if (rule.trigger is OnceAt) {
      return slot.add(WakeRuleBounds.oneOffGrace);
    }
    if (rule.whenBusy == WakeWhenBusy.queue) {
      final next = rule.trigger is SelfPaced
          ? slot.add(WakeRuleService._delayOf(rule))
          : _scheduler.nextSlotAfter(rule, slot);
      if (next != null) {
        return next;
      }
    }
    return slot.add(_grace(rule, slot));
  }

  /// How late the fire for [slot] may still be: a day for a one-off, else
  /// the smaller of half the gap to the next slot (the delay of a loop) and
  /// ten minutes.
  Duration _grace(WakeRule rule, DateTime slot) {
    final Duration gap;
    switch (rule.trigger) {
      case OnceAt():
        return WakeRuleBounds.oneOffGrace;
      case SelfPaced():
        gap = WakeRuleService._delayOf(rule);
      case Every() || Cron():
        final next = _scheduler.nextSlotAfter(rule, slot);
        gap = next == null
            ? WakeRuleBounds.repeatingGraceCeiling * 2
            : next.difference(slot);
      case OnEvent():
        return WakeRuleBounds.watchMaxDelay;
    }
    final half = gap ~/ 2;
    return half < WakeRuleBounds.repeatingGraceCeiling
        ? half
        : WakeRuleBounds.repeatingGraceCeiling;
  }

  // ------------------------------------------------------------- guard

  Future<WakeAdmission> _admit(Wake wake, DateTime at) async {
    final ruleId = wake.detail.ruleId;
    if (ruleId != null && wake.reason == WakeReason.limitReset) {
      final answer = await _admitLimitWake(wake, ruleId, at.toUtc());
      final rule = await _rules.getById(wake.workspaceId, ruleId);
      return answer is WakeAdmit && rule != null
          ? _withinLineage(rule, answer)
          : answer;
    }
    if (ruleId == null || !_isRuleReason(wake.reason)) {
      return _admitCarried(wake, at.toUtc());
    }
    final ws = wake.workspaceId;
    final now = at.toUtc();
    final rule = await _rules.getById(ws, ruleId);
    if (rule == null || !rule.isActive) {
      await _settleQuietly(wake, 'inactive', now);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}inactive',
      );
    }
    if (!rule.isWatch && !_isCurrentSlot(rule, wake)) {
      await _settleQuietly(wake, 'superseded', now);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}superseded',
      );
    }
    if (rule.trigger is! OnceAt && rule.expiredAt(now)) {
      await end(ws, rule.id, WakeRuleEndReason.expired);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}ended',
      );
    }
    // Its lineage's runs are spent (by another rule of it): no more fires.
    final lineageLeft = await _lineageRunsLeft(rule);
    if (lineageLeft != null && lineageLeft <= 0) {
      await end(ws, rule.id, WakeRuleEndReason.runCap);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}ended',
      );
    }
    // Its lineage's cost cap is spent (by another rule of it, or by runs
    // wakes carrying it started): no more fires.
    if (await _lineageCostSpent(rule)) {
      await end(ws, rule.id, WakeRuleEndReason.costCap);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}ended',
      );
    }
    final goalId = rule.goalId;
    if (goalId != null && await _ports.goalTerminal(ws, goalId) != false) {
      await end(ws, rule.id, WakeRuleEndReason.goalEnded);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}ended',
      );
    }
    final slot = wake.detail.slot;
    // Late past the grace (the server was down): the queue posts one row
    // and the settled handler counts one skip and writes the next slot. A
    // wake the queue deferred (stateReason set) is bounded by its expiry.
    if (!rule.isWatch &&
        slot != null &&
        wake.stateReason == null &&
        now.isAfter(slot.add(_grace(rule, slot)))) {
      return const WakeAdmission.skip(wakeMissedKind);
    }
    if (rule.deliver == WakeDeliver.notify) {
      await _notify(rule, wake, now);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}notified',
      );
    }
    if (await _ports.agentBusy(ws, rule.conversationId, rule.agentId)) {
      // A watch's event is never dropped because the agent is busy: it
      // waits for the run, whatever `when_busy` says.
      if (rule.whenBusy == WakeWhenBusy.skip && !rule.isWatch) {
        final moved = await _wakes.markSkipped(
          ws,
          ids: [wake.id],
          reason: '${WakeRuleService.ownReasonPrefix}busy',
          now: now,
        );
        if (moved > 0) {
          await _advance(rule, wake, fired: false, now: now);
        }
        return const WakeAdmission.skip(
          '${WakeRuleService.ownReasonPrefix}busy',
        );
      }
      // `queue`: the queue holds it until the live run settles, then
      // starts its own run (a rule's wake is never pushed into a live run).
    }
    return _withinLineage(rule, const WakeAdmit());
  }

  /// [answer], with the run's cap lowered to what [rule]'s lineage has
  /// left now when that is less than [WakeRuleBounds.perRunCostCapMicros]
  /// (the wake was armed with what it had then).
  Future<WakeAdmission> _withinLineage(WakeRule rule, WakeAdmit answer) async {
    final left = await _lineageCostLeft(rule);
    if (left == null || left >= WakeRuleBounds.perRunCostCapMicros) {
      return answer;
    }
    final within = left < 1 ? 1 : left;
    final cap = answer.capMicros;
    return WakeAdmission.admitWithin(
      cap != null && cap < within ? cap : within,
    );
  }

  /// Whether [wake] is the wake of the slot [rule] names next: the rule's
  /// dedup key for its `nextFireAt`, never an instant comparison.
  static bool _isCurrentSlot(WakeRule rule, Wake wake) {
    final next = rule.nextFireAt;
    return next != null && wake.dedupKey == wakeRuleDedupKey(rule.id, next);
  }

  /// The scheduler's next slot after [after], as a slot ([wakeSlotOf]).
  DateTime? _slotAfter(WakeRule rule, DateTime after) {
    final next = _scheduler.nextSlotAfter(rule, after);
    return next == null ? null : wakeSlotOf(next);
  }

  Future<void> _settleQuietly(Wake wake, String why, DateTime now) =>
      _wakes.cancel(
        wake.workspaceId,
        ids: [wake.id],
        reason: '${WakeRuleService.ownReasonPrefix}$why',
        now: now,
      );

  /// `deliver: notify`: the note as a system row, the rule's person told,
  /// no run. The wake is marked delivered here, so the queue moves nothing.
  Future<void> _notify(WakeRule rule, Wake wake, DateTime now) async {
    final ws = rule.workspaceId;
    final moved = await _wakes.markDelivered(
      ws,
      ids: [wake.id],
      runId: null,
      now: now,
    );
    if (moved == 0) {
      return;
    }
    // The note is its author's words, carried as a quotation: the agent's
    // unless a person wrote or changed it, never the server's own sentence.
    final agentWords = wakeRuleNoteIsAgents(rule);
    final agentName = agentWords
        ? await _ports.agentName(ws, rule.agentId) ?? 'The agent'
        : null;
    String? messageId;
    try {
      messageId = await _ports.postRow(
        workspaceId: ws,
        spaceId: rule.spaceId,
        conversationId: rule.conversationId,
        content: wakeRuleNoteRowText(rule, agentName: agentName),
        metadata: {
          'kind': wakeRuleNoteRowKind,
          'ruleId': rule.id,
          'wakeId': wake.id,
          'agentId': rule.agentId,
          'noteAuthor': agentWords ? 'agent' : 'person',
          'noteAuthorUserId': ?(agentWords
              ? null
              : rule.noteEditedByUserId ?? rule.createdByUserId),
        },
      );
    } on Object catch (e) {
      CcInfraLog.warning('WakeRuleService: note row failed: $e');
    }
    final person = rule.requestedByUserId;
    if (person != null && person.isNotEmpty) {
      _eventBus.publish(
        MessageReceived(
          spaceId: rule.spaceId,
          messageId: messageId ?? wake.id,
          senderName: agentName ?? 'Schedule',
          contentPreview: '"${wakeRuleNoteGist(rule.note)}"',
          isAgentMessage: agentWords,
          workspaceId: ws,
          mentions: [UserPrincipal(person)],
          requestedByUserId: person,
          conversationId: rule.conversationId,
          occurredAt: now,
        ),
      );
    }
    await _advance(rule, wake, fired: true, now: now);
  }

  // ------------------------------------------------------------- settled

  Future<void> _settledWake(WakeSettlement settled) async {
    final wake = settled.wake;
    final ruleId = wake.detail.ruleId;
    if (ruleId != null && wake.reason == WakeReason.limitReset) {
      await _limitWakeSettled(settled, ruleId);
      return;
    }
    if (ruleId == null || !_isRuleReason(wake.reason)) {
      return;
    }
    if (settled.reason?.startsWith(WakeRuleService.ownReasonPrefix) ?? false) {
      return;
    }
    final ws = wake.workspaceId;
    final rule = await _rules.getById(ws, ruleId);
    if (rule == null || !rule.isActive) {
      return;
    }
    // A loop's run may settle, and write the next slot, before its delivery
    // is recorded here: the fire still counts (admission let only the
    // current slot's wake through).
    final loopFired =
        rule.trigger is SelfPaced && settled.state == WakeState.delivered;
    if (!rule.isWatch && !loopFired && !_isCurrentSlot(rule, wake)) {
      return;
    }
    final now = _clock().toUtc();
    switch (settled.state) {
      case WakeState.delivered:
        await _advance(rule, wake, fired: true, now: now);
      case WakeState.skipped:
        if (settled.reason == WakeStateReasons.personRemoved) {
          await end(ws, rule.id, WakeRuleEndReason.memberRemoved);
          return;
        }
        await _advance(rule, wake, fired: false, now: now);
      case WakeState.expired:
        await _advance(
          rule,
          wake,
          fired: false,
          now: now,
          onceEnd: WakeRuleEndReason.expired,
        );
      case WakeState.cancelled:
        await _advance(
          rule,
          wake,
          fired: false,
          now: now,
          onceEnd: WakeRuleEndReason.cancelled,
        );
      case WakeState.pending || WakeState.held || WakeState.claimed:
        return;
    }
  }

  /// Records a fire or a skip of [wake]'s slot and writes the rule's next
  /// pending wake: the one function that moves a rule on. The rule row is
  /// written first; the wake after it.
  Future<void> _advance(
    WakeRule rule,
    Wake wake, {
    required bool fired,
    required DateTime now,
    WakeRuleEndReason onceEnd = WakeRuleEndReason.expired,
  }) async {
    final ws = rule.workspaceId;
    final id = rule.id;
    final lineageLeft = fired ? await _lineageRunsLeft(rule) : null;
    final capAfterFire =
        (rule.maxRuns != null && rule.runCount + 1 >= rule.maxRuns!) ||
        (lineageLeft != null && lineageLeft <= 1);
    switch (rule.trigger) {
      case OnEvent(:final eventKind, :final targetId):
        if (!fired) {
          await _rules.recordSkip(ws, id: id, nextFireAt: null, now: now);
          return;
        }
        if (!await _fire(rule, nextFireAt: null, now: now)) {
          return;
        }
        if (OnEvent.needsTarget(eventKind) ||
            (targetId != null && eventKind == WakeEventKind.prMerged)) {
          // A ticket, a pipeline run or a named pull request settles once:
          // its watch is done.
          await end(ws, id, WakeRuleEndReason.fired);
        } else if (capAfterFire) {
          await end(ws, id, WakeRuleEndReason.runCap);
        }
      case OnceAt():
        if (fired) {
          if (await _fire(rule, nextFireAt: null, now: now)) {
            // The fire that spends its lineage's runs ends the lineage: the
            // person hears it once, as a run cap.
            await end(
              ws,
              id,
              capAfterFire && rule.rootRuleId != null
                  ? WakeRuleEndReason.runCap
                  : WakeRuleEndReason.fired,
            );
          }
        } else if (await _rules.recordSkip(
          ws,
          id: id,
          nextFireAt: null,
          now: now,
        )) {
          await end(ws, id, onceEnd);
        }
      case SelfPaced():
        if (fired) {
          // The next slot is written when this run settles, which may have
          // happened already: the fire leaves `nextFireAt` alone.
          if (await _rules.recordLoopFire(ws, id: id, firedAt: now) &&
              capAfterFire) {
            await end(ws, id, WakeRuleEndReason.runCap);
          }
          return;
        }
        final next = wakeSlotOf(now.add(WakeRuleService._delayOf(rule)));
        if (!next.isBefore(rule.expiresAt)) {
          await end(ws, id, WakeRuleEndReason.expired);
          return;
        }
        if (await _rules.recordSkip(ws, id: id, nextFireAt: next, now: now)) {
          await _armFresh(ws, id, next);
        }
      case Every() || Cron():
        final slot = wake.detail.slot ?? now;
        var next = _slotAfter(rule, slot);
        var missed = false;
        if (next != null && now.isAfter(next.add(_grace(rule, next)))) {
          // Slots passed while nothing could fire them: one skip, then the
          // next slot after now, however many were missed.
          next = _slotAfter(rule, now);
          missed = true;
        }
        final ok = fired
            ? await _fire(rule, nextFireAt: next, now: now)
            : await _rules.recordSkip(ws, id: id, nextFireAt: next, now: now);
        if (!ok) {
          return;
        }
        if (fired && missed) {
          await _rules.recordSkip(ws, id: id, nextFireAt: next, now: now);
        }
        if (fired && capAfterFire) {
          await end(ws, id, WakeRuleEndReason.runCap);
        } else if (next == null || !next.isBefore(rule.expiresAt)) {
          await end(ws, id, WakeRuleEndReason.expired);
        } else {
          await _armFresh(ws, id, next);
        }
    }
  }

  Future<bool> _fire(
    WakeRule rule, {
    required DateTime? nextFireAt,
    required DateTime now,
  }) => _rules.recordFire(
    rule.workspaceId,
    id: rule.id,
    costMicrosDelta: 0,
    nextFireAt: nextFireAt,
    firedAt: now,
  );

  /// Arms [slot] from the rule as stored now (its run count and cost).
  Future<void> _armFresh(String ws, String id, DateTime slot) async {
    final fresh = await _rules.getById(ws, id);
    if (fresh != null && fresh.isActive) {
      await _armSlot(fresh, slot);
    }
  }

  // ------------------------------------------------------------- events

  /// A run settled: add its cost to each rule whose wake it carried (a
  /// `limitReset` wake of a rule included) or, when it carried no rule's
  /// wake, to the lineage its wakes carry ([_chargeCarriedRun]); end a rule
  /// at its cost cap, park a run that reached its provider's usage limit,
  /// and write a self-paced loop's next slot.
  Future<void> _runSettled(AgentRunSettled event) async {
    final ws = event.workspaceId;
    final now = _clock().toUtc();
    // A run started with no wake is in a lineage only through the run that
    // started it by a direct dispatch (its `started_by_run_id`,
    // [_lineageOfRun]).
    if (event.wakeIds.isEmpty) {
      await _chargeCarriedRun(event, now);
      return;
    }
    final seen = <String>{};
    for (final wakeId in event.wakeIds) {
      final wake = await _wakes.getById(ws, wakeId);
      final ruleId = wake?.detail.ruleId;
      if (wake == null ||
          ruleId == null ||
          !(_isRuleReason(wake.reason) ||
              wake.reason == WakeReason.limitReset) ||
          !seen.add(ruleId)) {
        continue;
      }
      final total = await _rules.addCost(
        ws,
        id: ruleId,
        micros: event.costMicros < 0 ? 0 : event.costMicros,
        now: now,
      );
      final rule = await _rules.getById(ws, ruleId);
      if (rule == null) {
        continue;
      }
      // A goal-bound rule spends its goal's budget; the goal ends it.
      if (rule.isActive &&
          rule.goalId == null &&
          ((total != null && total >= rule.costCapMicros) ||
              await _lineageCostSpent(rule))) {
        await end(ws, ruleId, WakeRuleEndReason.costCap);
        continue;
      }
      if (event.endReason == RunEndReason.usageLimit &&
          await _parkRunAtLimit(rule, wake, event, now)) {
        continue;
      }
      if (!rule.isActive) {
        continue;
      }
      // A loop's next slot: written once, whether or not the delivered
      // handler recorded the fire yet ([WakeRuleRepository.setNextAfterRun]
      // writes only over no slot or the one this run's wake carried).
      final delivered = wake.reason == WakeReason.schedule
          ? wake.detail.slot
          : null;
      if (rule.trigger is SelfPaced &&
          event.endReason != RunEndReason.serverStopped &&
          (rule.nextFireAt == null ||
              (delivered != null &&
                  rule.nextFireAt!.isAtSameMomentAs(delivered)))) {
        final next = wakeSlotOf(
          event.occurredAt.add(WakeRuleService._delayOf(rule)),
        );
        if (!next.isBefore(rule.expiresAt)) {
          await end(ws, ruleId, WakeRuleEndReason.expired);
          continue;
        }
        if (await _rules.setNextAfterRun(
          ws,
          id: ruleId,
          delivered: delivered,
          nextFireAt: next,
          now: now,
        )) {
          await _armFresh(ws, ruleId, next);
        }
      }
    }
    if (seen.isEmpty) {
      await _chargeCarriedRun(event, now);
    }
  }

  /// A goal ended: every rule bound to it ends with it.
  Future<void> _goalSettled(GoalSettled event) async {
    if (!event.status.isTerminal) {
      return;
    }
    for (final rule in await _rules.listByGoal(
      event.workspaceId,
      event.goalId,
    )) {
      if (rule.status != WakeRuleStatus.ended) {
        await end(event.workspaceId, rule.id, WakeRuleEndReason.goalEnded);
      }
    }
  }

  /// A member left: every rule that acts for them ends (its pending wake is
  /// cancelled by the end).
  Future<void> _memberRemoved(WorkspaceMemberRemoved event) async {
    for (final rule in await _rules.listByRequester(
      event.workspaceId,
      event.userId,
    )) {
      if (rule.status != WakeRuleStatus.ended) {
        await end(event.workspaceId, rule.id, WakeRuleEndReason.memberRemoved);
      }
    }
  }

  // ------------------------------------------------------------- boot

  /// Gives every active time rule of every workspace its pending wake: ends
  /// an expired one, leaves one that has an open wake, re-arms the rest at
  /// their `nextFireAt` (a loop without one at its delay from now), and
  /// moves on a rule whose slot's wake settled before its next was written.
  Future<void> _rearmAll() async {
    // CROSS-WORKSPACE BY DESIGN: the boot scan re-arms every workspace's
    // rules; every read after this is workspace-scoped.
    for (final ws in await _rules.workspacesWithActiveRules()) {
      if (!await _ports.workspaceActive(ws)) {
        continue;
      }
      try {
        await _rearmWorkspace(ws);
      } on Object catch (e, st) {
        CcInfraLog.error('WakeRuleService: re-arm $ws', e, st);
      }
    }
  }

  Future<void> _rearmWorkspace(String ws) async {
    final now = _clock().toUtc();
    final openByConversation = <String, Set<String>>{};
    for (final rule in await _rules.listActive(ws)) {
      if (rule.isWatch) {
        continue;
      }
      if (rule.trigger is! OnceAt && rule.expiredAt(now)) {
        await end(ws, rule.id, WakeRuleEndReason.expired);
        continue;
      }
      final open = openByConversation[rule.conversationId] ??= {
        for (final w in await _wakes.listForConversation(
          ws,
          rule.conversationId,
          states: {WakeState.pending, WakeState.held, WakeState.claimed},
        ))
          ?w.detail.ruleId,
      };
      if (open.contains(rule.id)) {
        continue;
      }
      var slot = rule.nextFireAt;
      if (slot == null) {
        if (rule.trigger is! SelfPaced) {
          continue;
        }
        slot = wakeSlotOf(now.add(WakeRuleService._delayOf(rule)));
        if (!await _rules.setNext(
          ws,
          id: rule.id,
          nextFireAt: slot,
          nextDelaySeconds: rule.nextDelaySeconds,
          now: now,
        )) {
          continue;
        }
      }
      if (await _armSlot(rule, slot)) {
        continue;
      }
      // The slot's wake exists and settled, but the rule never moved on
      // (the server stopped between the two writes): move it on now.
      final settled = await _wakes.getByDedupKey(
        ws,
        wakeRuleDedupKey(rule.id, slot),
      );
      if (settled != null &&
          rule.trigger is SelfPaced &&
          settled.state == WakeState.delivered) {
        // The loop's run never settled (the server stopped under it): count
        // the fire if the delivery was not counted, and go on from now.
        final last = rule.lastFiredAt;
        if (last == null || last.isBefore(slot)) {
          await _rules.recordLoopFire(ws, id: rule.id, firedAt: now);
        }
        final next = wakeSlotOf(now.add(WakeRuleService._delayOf(rule)));
        if (await _rules.setNextAfterRun(
          ws,
          id: rule.id,
          delivered: slot,
          nextFireAt: next,
          now: now,
        )) {
          await _armFresh(ws, rule.id, next);
        }
        continue;
      }
      if (settled != null &&
          settled.state != WakeState.pending &&
          settled.state != WakeState.held &&
          settled.state != WakeState.claimed) {
        await _advance(
          rule,
          settled,
          fired: settled.state == WakeState.delivered,
          now: now,
        );
      }
    }
  }
}

bool _isRuleReason(WakeReason reason) =>
    reason == WakeReason.schedule || reason == WakeReason.watch;

/// The dedup key of a time rule's wake for [slot] (made a slot first,
/// [wakeSlotOf]): what a rule owns, compared instead of the instants.
String wakeRuleDedupKey(String ruleId, DateTime slot) =>
    'rule:$ruleId:${wakeSlotOf(slot).toIso8601String()}';

/// The skip kind of a slot that came past its grace.
const String wakeMissedKind = 'wake_missed';

/// The `kind` of the row a `deliver: notify` rule posts its note in.
const String wakeRuleNoteRowKind = 'wake_rule_note';

/// Whether [rule]'s note is its agent's words: an agent made the rule and no
/// person changed the note since.
bool wakeRuleNoteIsAgents(WakeRule rule) =>
    rule.origin == WakeRuleOrigin.agent && rule.noteEditedByUserId == null;

/// The row a `deliver: notify` rule posts: who said it ([agentName] for the
/// agent's words, else a person's reminder) and the note as a quotation.
String wakeRuleNoteRowText(WakeRule rule, {required String? agentName}) {
  final quoted = [
    for (final line in rule.note.trim().split('\n')) '> $line',
  ].join('\n');
  final when = formatWakeWhen(rule.trigger);
  return agentName != null
      ? '$agentName left a note for $when, in its own words:\n\n$quoted'
      : 'A reminder a person set for $when:\n\n$quoted';
}
