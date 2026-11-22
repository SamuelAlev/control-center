part of 'wake_rule_service.dart';

/// A rule's run parked at its provider's usage limit (plan section 11).
///
/// The run ended on `usageLimit` with a reported reset at most
/// [LimitPark.maxWait] away: a `limitReset` wake (`limit:<runId>`, due at
/// the reset plus [LimitPark.resetSlack]) carries the rule's wake payload
/// to a run after the reset, and the rule's next slot is withheld until
/// that wake is delivered or skipped. The wake is written first, then the
/// next slot is withheld (`nextFireAt` cleared, its armed wake cancelled):
/// a crash between the two leaves a slot that fires as usual, never a rule
/// with nothing to run it.
///
/// A goal-bound rule is left to its goal (the goal parks the run when it is
/// its segment). A run that carried several rules' wakes parks the first
/// rule's work; the others move on as before.
extension on WakeRuleService {
  /// Parks [event]'s run for [rule], whose wake [wake] the run carried.
  /// True when a park was written (the caller then writes no next slot).
  Future<bool> _parkRunAtLimit(
    WakeRule rule,
    Wake wake,
    AgentRunSettled event,
    DateTime now,
  ) async {
    if (_queue.stopping || rule.goalId != null) {
      return false;
    }
    final parkable =
        rule.isActive ||
        (rule.status == WakeRuleStatus.ended &&
            (rule.endReason == WakeRuleEndReason.fired ||
                rule.endReason == WakeRuleEndReason.runCap));
    if (!parkable) {
      return false;
    }
    final reset = LimitPark.honouredReset(event.limitResetsAt, now);
    if (reset == null) {
      return false;
    }
    final ws = rule.workspaceId;
    final key = LimitPark.dedupKey(event.runId);
    if (await _wakes.getByDedupKey(ws, key) != null) {
      return false; // Another owner (a second rule of the run) parked it.
    }
    final provider = await _ports.runProvider(ws, event.runId);
    final limitWake = Wake(
      id: _newId(),
      workspaceId: ws,
      spaceId: rule.spaceId,
      conversationId: rule.conversationId,
      agentId: rule.agentId,
      reason: WakeReason.limitReset,
      payload: wake.payload,
      detail: WakeDetail(
        ruleId: rule.id,
        sourceRunId: event.runId,
        fields: {
          WakeFields.origin: rule.origin.wire,
          WakeFields.trigger: formatWakeWhen(rule.trigger),
          ...LimitPark.wakeFields(provider: provider, reset: reset),
        },
      ),
      runOptions: WakeRunOptions(costCapMicros: _perRunCap(rule)),
      dedupKey: key,
      notBefore: LimitPark.resumeAt(reset),
      // An active rule's park ends with the rule: past its expiry the wake
      // expires and its settlement ends the rule as expired. The last run
      // of an ended rule is owed, whenever the reset comes.
      expiresAt: rule.isActive ? rule.expiresAt : null,
      requestedByUserId: rule.requestedByUserId,
      createdAt: now,
    );
    try {
      if (!await _queue.enqueue(limitWake)) {
        return false;
      }
    } on WorkspaceMismatchException catch (e) {
      CcInfraLog.warning('WakeRuleService: rule ${rule.id} not parked: $e');
      return false;
    }
    await _withholdNextSlot(rule, now);
    return true;
  }

  /// The rule's own admission of its `limitReset` wake: an active rule must
  /// be unexpired and its lineage not spent (else it ends, and the wake is
  /// skipped); an ended rule's parked last run (`fired`, `runCap`) is owed
  /// and goes on; any other end skips it.
  Future<WakeAdmission> _admitLimitWake(
    Wake wake,
    String ruleId,
    DateTime now,
  ) async {
    final ws = wake.workspaceId;
    final rule = await _rules.getById(ws, ruleId);
    if (rule == null) {
      await _dropLimitWake(wake);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}inactive',
      );
    }
    if (!rule.isActive) {
      final owed =
          rule.status == WakeRuleStatus.ended &&
          (rule.endReason == WakeRuleEndReason.fired ||
              rule.endReason == WakeRuleEndReason.runCap);
      if (owed) {
        return const WakeAdmission.admit();
      }
      await _dropLimitWake(wake);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}inactive',
      );
    }
    if (rule.expiredAt(now)) {
      await end(ws, rule.id, WakeRuleEndReason.expired);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}ended',
      );
    }
    final lineageLeft = await _lineageRunsLeft(rule);
    if (lineageLeft != null && lineageLeft <= 0) {
      await end(ws, rule.id, WakeRuleEndReason.runCap);
      return const WakeAdmission.skip(
        '${WakeRuleService.ownReasonPrefix}ended',
      );
    }
    return const WakeAdmission.admit();
  }

  /// Withdraws a limit wake its rule no longer owes, quietly (no "not
  /// delivered" row) but through the queue, so its settlement is heard: the
  /// park's held cards become their person's.
  Future<void> _dropLimitWake(Wake wake) => _queue.cancel(
    wake.workspaceId,
    wake.id,
    reason: '${WakeRuleService.ownReasonPrefix}inactive',
  );

  /// Clears an active time rule's `nextFireAt` and cancels the wake armed
  /// for it, so nothing fires before the parked run's wake.
  Future<void> _withholdNextSlot(WakeRule rule, DateTime now) async {
    final slot = rule.nextFireAt;
    if (!rule.isActive || rule.isWatch || slot == null) {
      return;
    }
    final ws = rule.workspaceId;
    if (!await _rules.setNext(
      ws,
      id: rule.id,
      nextFireAt: null,
      nextDelaySeconds: rule.trigger is SelfPaced
          ? rule.nextDelaySeconds
          : null,
      now: now,
    )) {
      return;
    }
    final armed = await _wakes.getByDedupKey(
      ws,
      wakeRuleDedupKey(rule.id, slot),
    );
    if (armed != null && !armed.state.isSettled) {
      // A claim under way cannot be cancelled; its admission finds the slot
      // superseded (the rule names no next slot now).
      await _queue.cancel(
        ws,
        armed.id,
        reason: '${WakeRuleService.ownReasonPrefix}limit_parked',
      );
    }
  }

  /// A rule's `limitReset` wake settled: once it is delivered or skipped,
  /// the rule's next slot is written again (after now). A self-paced
  /// loop's delivered wake writes it when its run settles, as any loop
  /// run does. The rule's own cancels (a pause, an end) write nothing.
  Future<void> _limitWakeSettled(WakeSettlement settled, String ruleId) async {
    if (settled.reason?.startsWith(WakeRuleService.ownReasonPrefix) ?? false) {
      return;
    }
    final ws = settled.wake.workspaceId;
    final rule = await _rules.getById(ws, ruleId);
    if (rule == null ||
        !rule.isActive ||
        rule.isWatch ||
        rule.nextFireAt != null) {
      return;
    }
    final now = _clock().toUtc();
    DateTime? next;
    switch (rule.trigger) {
      case SelfPaced():
        if (settled.state == WakeState.delivered) {
          return;
        }
        next = wakeSlotOf(now.add(WakeRuleService._delayOf(rule)));
      case Every() || Cron():
        next = _slotAfter(rule, now);
        // The slot withheld by the park keeps its (cancelled) wake's key:
        // the next slot without a wake is the one to arm.
        for (var i = 0; next != null && i < 8; i++) {
          if (await _wakes.getByDedupKey(ws, wakeRuleDedupKey(rule.id, next)) ==
              null) {
            break;
          }
          next = _slotAfter(rule, next);
        }
      case OnceAt() || OnEvent():
        return;
    }
    if (next == null || !next.isBefore(rule.expiresAt)) {
      await end(ws, rule.id, WakeRuleEndReason.expired);
      return;
    }
    if (await _rules.setNext(
      ws,
      id: rule.id,
      nextFireAt: next,
      nextDelaySeconds: rule.trigger is SelfPaced
          ? rule.nextDelaySeconds
          : null,
      now: now,
    )) {
      await _armFresh(ws, rule.id, next);
    }
  }
}
