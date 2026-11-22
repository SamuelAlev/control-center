/// A settled domain event a wake rule can watch (`on:<event>`).
enum WakeEventKind {
  /// Every check on the conversation's pull request finished.
  prChecks,

  /// A review decision or a reply on the conversation's pull request.
  prReview,

  /// The conversation's pull request merged.
  prMerged,

  /// A task of the conversation's environment exited, or the
  /// environment became ready.
  environment,

  /// A ticket (named by the rule's target id) settled.
  ticket,

  /// A pipeline run (named by the rule's target id) settled.
  pipelineRun,
}

/// Wire names for [WakeEventKind] (persisted as TEXT).
extension WakeEventKindWire on WakeEventKind {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeEventKind.prChecks => 'pr_checks',
    WakeEventKind.prReview => 'pr_review',
    WakeEventKind.prMerged => 'pr_merged',
    WakeEventKind.environment => 'environment',
    WakeEventKind.ticket => 'ticket',
    WakeEventKind.pipelineRun => 'pipeline_run',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in WakeEventKind.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeEventKind? tryParse(String? raw) {
    for (final value in WakeEventKind.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Lifecycle of a wake rule.
enum WakeRuleStatus {
  /// Producing wakes.
  active,

  /// Kept, producing nothing until a person resumes it.
  paused,

  /// Finished for good; [WakeRuleEndReason] says why.
  ended,
}

/// Wire names for [WakeRuleStatus] (persisted as TEXT).
extension WakeRuleStatusWire on WakeRuleStatus {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeRuleStatus.active => 'active',
    WakeRuleStatus.paused => 'paused',
    WakeRuleStatus.ended => 'ended',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in WakeRuleStatus.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeRuleStatus? tryParse(String? raw) {
    for (final value in WakeRuleStatus.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Why a wake rule ended.
enum WakeRuleEndReason {
  /// A one-off rule fired.
  fired,

  /// Its expiry passed.
  expired,

  /// It started as many runs as `maxRuns` allows.
  runCap,

  /// Its runs spent its cost cap.
  costCap,

  /// The goal it was bound to ended.
  goalEnded,

  /// A person or the agent cancelled it.
  cancelled,

  /// The person accountable for it left the workspace.
  memberRemoved,

  /// Its stored row broke a rule of the entity (an import or a hand edit),
  /// so the repository ended it when it read it.
  invalidRow,
}

/// Wire names for [WakeRuleEndReason] (persisted as TEXT).
extension WakeRuleEndReasonWire on WakeRuleEndReason {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeRuleEndReason.fired => 'fired',
    WakeRuleEndReason.expired => 'expired',
    WakeRuleEndReason.runCap => 'run_cap',
    WakeRuleEndReason.costCap => 'cost_cap',
    WakeRuleEndReason.goalEnded => 'goal_ended',
    WakeRuleEndReason.cancelled => 'cancelled',
    WakeRuleEndReason.memberRemoved => 'member_removed',
    WakeRuleEndReason.invalidRow => 'invalid_row',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in WakeRuleEndReason.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeRuleEndReason? tryParse(String? raw) {
    for (final value in WakeRuleEndReason.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// What a wake rule does when it fires.
enum WakeDeliver {
  /// Wakes the agent (starts a run, or enters its live run).
  run,

  /// Posts the note and notifies the person, without running the agent.
  notify,
}

/// Wire names for [WakeDeliver] (persisted as TEXT).
extension WakeDeliverWire on WakeDeliver {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeDeliver.run => 'run',
    WakeDeliver.notify => 'notify',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in WakeDeliver.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeDeliver? tryParse(String? raw) {
    for (final value in WakeDeliver.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// What a firing rule does when a run of its agent is live in the
/// conversation.
enum WakeWhenBusy {
  /// The slot is skipped and recorded.
  skip,

  /// The wake goes to the live run's follow-up lane.
  queue,
}

/// Wire names for [WakeWhenBusy] (persisted as TEXT).
extension WakeWhenBusyWire on WakeWhenBusy {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeWhenBusy.skip => 'skip',
    WakeWhenBusy.queue => 'queue',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in WakeWhenBusy.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeWhenBusy? tryParse(String? raw) {
    for (final value in WakeWhenBusy.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Who created a wake rule.
enum WakeRuleOrigin {
  /// An agent, with `wake_me`.
  agent,

  /// A person, with a command or the Schedules screen.
  person,
}

/// Wire names for [WakeRuleOrigin] (persisted as TEXT).
extension WakeRuleOriginWire on WakeRuleOrigin {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeRuleOrigin.agent => 'agent',
    WakeRuleOrigin.person => 'person',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in WakeRuleOrigin.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeRuleOrigin? tryParse(String? raw) {
    for (final value in WakeRuleOrigin.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// The active-rule limit that refused a new rule
/// (`WakeRuleRepository.insertWithinLimits`).
enum WakeRuleLimit {
  /// Too many rules for the agent in the conversation.
  conversation,

  /// Too many rules for the agent.
  agent,

  /// Too many rules in the workspace.
  workspace,

  /// The lineage the rule would join spent its runs or its cost.
  lineage,
}

/// What a lineage may spend in all, checked when a rule joins it: its root
/// `rootRuleId`, the root's run cap (or `WakeRuleBounds.lineageMaxRuns`) and
/// cost cap.
typedef WakeLineageCap = ({String rootRuleId, int maxRuns, int costCapMicros});

/// The runs and cost of a lineage's rules together (the root's and every
/// rule naming it as root, whatever their status).
typedef WakeLineageTotals = ({int runs, int costMicros});

/// The slot a rule fires at for [instant]: the same instant in UTC, cut to
/// the whole second.
///
/// Every slot a rule writes is made here, because a rule's slot is compared
/// with what its row reads back, and the row stores whole seconds. Compare
/// slots with [DateTime.isAtSameMomentAs] or by their dedup key, never with
/// `==` (which also compares the zone flag).
DateTime wakeSlotOf(DateTime instant) {
  final micros = instant.microsecondsSinceEpoch;
  final cut = micros - micros % Duration.microsecondsPerSecond;
  return DateTime.fromMicrosecondsSinceEpoch(cut, isUtc: true);
}

/// Whether [a] and [b] are the same instant (both null included): how the
/// wake entities compare times, whatever zone flag a value carries.
bool sameWakeInstant(DateTime? a, DateTime? b) =>
    a == null ? b == null : b != null && a.isAtSameMomentAs(b);
