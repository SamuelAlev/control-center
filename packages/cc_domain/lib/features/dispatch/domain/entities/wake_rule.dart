import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';
import 'package:cc_domain/features/pipelines/domain/services/schedule_spec.dart';

/// A rule that produces wakes for one agent in one conversation
/// (`wake_rules`): a schedule (`/loop`, `/schedule`, `wake_me` with a time)
/// or a watch (`wake_me` with `on:<event>`).
///
/// Each active time rule keeps exactly one pending wake for its next slot
/// (key `rule:<id>:<slot>`); delivering or skipping it writes the next one.
/// Rules are bounded in the runtime: a 60-second minimum interval, a
/// required expiry, a run cap and a cost cap.
///
/// An `every:` or `cron:` rule is a [ScheduleSpec]: its slots come from the
/// same arithmetic as a pipeline's scheduled trigger.
class WakeRule implements ScheduleSpec {
  /// Creates a rule. Every time is kept in UTC, and [nextFireAt] as a slot
  /// (whole seconds, [wakeSlotOf]). Throws [ArgumentError] for an empty id
  /// or target, a [note] over [maxNoteLength], a non-positive cost cap or
  /// run cap, a negative counter, an [expiresAt] not after [createdAt], a
  /// [nextDelaySeconds] outside the self-paced range or on another trigger,
  /// or a status and end reason that disagree (only an ended rule has one).
  WakeRule({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.trigger,
    required this.note,
    this.deliver = WakeDeliver.run,
    this.whenBusy = WakeWhenBusy.skip,
    this.maxRuns,
    required this.costCapMicros,
    required DateTime expiresAt,
    this.runCount = 0,
    this.skipCount = 0,
    this.costMicros = 0,
    DateTime? lastFiredAt,
    DateTime? nextFireAt,
    this.nextDelaySeconds,
    this.goalId,
    this.rootRuleId,
    required this.origin,
    this.createdByRunId,
    this.createdByUserId,
    this.requestedByUserId,
    this.noteEditedByUserId,
    this.status = WakeRuleStatus.active,
    this.endReason,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : expiresAt = expiresAt.toUtc(),
       lastFiredAt = lastFiredAt?.toUtc(),
       nextFireAt = nextFireAt == null ? null : wakeSlotOf(nextFireAt),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc() {
    for (final (value, name) in [
      (id, 'id'),
      (workspaceId, 'workspaceId'),
      (spaceId, 'spaceId'),
      (conversationId, 'conversationId'),
      (agentId, 'agentId'),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
    final root = rootRuleId;
    if (root != null && (root.isEmpty || root == id || goalId != null)) {
      throw ArgumentError.value(
        root,
        'rootRuleId',
        'names another rule, and never on a goal-bound rule',
      );
    }
    if (note.length > maxNoteLength) {
      throw ArgumentError.value(
        note.length,
        'note',
        'must be at most $maxNoteLength characters',
      );
    }
    if (costCapMicros <= 0) {
      throw ArgumentError.value(
        costCapMicros,
        'costCapMicros',
        'must be positive',
      );
    }
    final runs = maxRuns;
    if (runs != null && runs <= 0) {
      throw ArgumentError.value(runs, 'maxRuns', 'must be positive');
    }
    for (final (value, name) in [
      (runCount, 'runCount'),
      (skipCount, 'skipCount'),
      (costMicros, 'costMicros'),
    ]) {
      if (value < 0) {
        throw ArgumentError.value(value, name, 'must not be negative');
      }
    }
    if (!expiresAt.isAfter(createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must be after createdAt',
      );
    }
    final delay = nextDelaySeconds;
    if (delay != null) {
      if (trigger is! SelfPaced) {
        throw ArgumentError.value(
          delay,
          'nextDelaySeconds',
          'only a self-paced rule has a chosen delay',
        );
      }
      if (delay < SelfPaced.minDelay.inSeconds ||
          delay > SelfPaced.maxDelay.inSeconds) {
        throw ArgumentError.value(
          delay,
          'nextDelaySeconds',
          'must be between ${SelfPaced.minDelay.inSeconds} and '
              '${SelfPaced.maxDelay.inSeconds}',
        );
      }
    }
    if ((status == WakeRuleStatus.ended) != (endReason != null)) {
      throw ArgumentError.value(
        endReason,
        'endReason',
        'an ended rule has an end reason and no other rule has one',
      );
    }
  }

  /// The longest note, in characters.
  static const int maxNoteLength = 4000;

  /// Unique rule id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Space of the target conversation.
  final String spaceId;

  /// Target conversation.
  final String conversationId;

  /// Target agent.
  final String agentId;

  /// When it fires.
  final WakeTrigger trigger;

  /// What the agent's future self needs; comes back as the agent's own note
  /// (or the person's prompt for a rule a person made). Data, not
  /// instructions.
  final String note;

  /// Whether a fire runs the agent or only notifies.
  final WakeDeliver deliver;

  /// What a fire does when the agent is busy in the conversation.
  final WakeWhenBusy whenBusy;

  /// The most runs it may start; null for no run cap (a one-off rule).
  final int? maxRuns;

  /// The total the runs it starts may spend, in micro-dollars.
  final int costCapMicros;

  /// When it ends by itself.
  final DateTime expiresAt;

  /// Runs it started.
  final int runCount;

  /// Slots it skipped (missed, or the agent was busy).
  final int skipCount;

  /// What its runs spent, in micro-dollars.
  final int costMicros;

  /// When it last fired.
  final DateTime? lastFiredAt;

  /// When it fires next (the pending wake's `notBefore`); null for a watch
  /// and an ended rule.
  final DateTime? nextFireAt;

  /// The delay a self-paced rule's agent chose for the next fire, in
  /// seconds; null when it chose none.
  final int? nextDelaySeconds;

  /// The goal it is bound to: it spends the goal's budget and ends with it.
  final String? goalId;

  /// The first rule of its lineage, when a run that another rule's wake
  /// started created it (plan section 9, "Chains"): it shares that root's
  /// expiry, and its runs and cost count against the root's caps. Null for
  /// a root, a person's rule and a goal's.
  final String? rootRuleId;

  /// The person who last changed the note, when one did: the note is then
  /// their words, not those of the rule's creator.
  final String? noteEditedByUserId;

  /// Who created it.
  final WakeRuleOrigin origin;

  /// The run in which an agent created it.
  final String? createdByRunId;

  /// The person who created it.
  final String? createdByUserId;

  /// The accountable person (the creator, or the requester of the run that
  /// created it), checked again at every fire; null for the bot.
  final String? requestedByUserId;

  /// Lifecycle.
  final WakeRuleStatus status;

  /// Why it ended; set exactly when [status] is ended.
  final WakeRuleEndReason? endReason;

  /// When it was created.
  final DateTime createdAt;

  /// When it was last changed.
  final DateTime updatedAt;

  /// The period of an `every:` rule in seconds; null for any other trigger.
  @override
  int? get intervalSeconds => switch (trigger) {
    Every(:final interval) => interval.inSeconds,
    _ => null,
  };

  /// The parsed expression of a `cron:` rule; null for any other trigger (or
  /// an expression that no longer parses).
  @override
  CronSchedule? get cronSchedule => switch (trigger) {
    Cron(:final expression) => CronSchedule.tryParse(expression),
    _ => null,
  };

  /// The time zone of a `cron:` rule; null for any other trigger.
  @override
  String? get timezone => switch (trigger) {
    Cron(:final timeZone) => timeZone,
    _ => null,
  };

  /// Whether it is producing wakes.
  bool get isActive => status == WakeRuleStatus.active;

  /// Whether it is a watch.
  bool get isWatch => trigger is OnEvent;

  /// Whether its run cap is reached.
  bool get runCapReached {
    final cap = maxRuns;
    return cap != null && runCount >= cap;
  }

  /// Whether its cost cap is reached.
  bool get costCapReached => costMicros >= costCapMicros;

  /// Whether it is past its expiry at [now].
  bool expiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// A copy with the given fields replaced.
  WakeRule copyWith({
    String? id,
    String? workspaceId,
    String? spaceId,
    String? conversationId,
    String? agentId,
    WakeTrigger? trigger,
    String? note,
    WakeDeliver? deliver,
    WakeWhenBusy? whenBusy,
    int? maxRuns,
    bool removeMaxRuns = false,
    int? costCapMicros,
    DateTime? expiresAt,
    int? runCount,
    int? skipCount,
    int? costMicros,
    DateTime? lastFiredAt,
    bool removeLastFiredAt = false,
    DateTime? nextFireAt,
    bool removeNextFireAt = false,
    int? nextDelaySeconds,
    bool removeNextDelaySeconds = false,
    String? goalId,
    bool removeGoalId = false,
    String? rootRuleId,
    String? noteEditedByUserId,
    WakeRuleOrigin? origin,
    String? createdByRunId,
    String? createdByUserId,
    String? requestedByUserId,
    bool removeRequestedByUserId = false,
    WakeRuleStatus? status,
    WakeRuleEndReason? endReason,
    bool removeEndReason = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WakeRule(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    spaceId: spaceId ?? this.spaceId,
    conversationId: conversationId ?? this.conversationId,
    agentId: agentId ?? this.agentId,
    trigger: trigger ?? this.trigger,
    note: note ?? this.note,
    deliver: deliver ?? this.deliver,
    whenBusy: whenBusy ?? this.whenBusy,
    maxRuns: removeMaxRuns ? null : (maxRuns ?? this.maxRuns),
    costCapMicros: costCapMicros ?? this.costCapMicros,
    expiresAt: expiresAt ?? this.expiresAt,
    runCount: runCount ?? this.runCount,
    skipCount: skipCount ?? this.skipCount,
    costMicros: costMicros ?? this.costMicros,
    lastFiredAt: removeLastFiredAt ? null : (lastFiredAt ?? this.lastFiredAt),
    nextFireAt: removeNextFireAt ? null : (nextFireAt ?? this.nextFireAt),
    nextDelaySeconds: removeNextDelaySeconds
        ? null
        : (nextDelaySeconds ?? this.nextDelaySeconds),
    goalId: removeGoalId ? null : (goalId ?? this.goalId),
    rootRuleId: rootRuleId ?? this.rootRuleId,
    noteEditedByUserId: noteEditedByUserId ?? this.noteEditedByUserId,
    origin: origin ?? this.origin,
    createdByRunId: createdByRunId ?? this.createdByRunId,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    requestedByUserId: removeRequestedByUserId
        ? null
        : (requestedByUserId ?? this.requestedByUserId),
    status: status ?? this.status,
    endReason: removeEndReason ? null : (endReason ?? this.endReason),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WakeRule &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          spaceId == other.spaceId &&
          conversationId == other.conversationId &&
          agentId == other.agentId &&
          trigger == other.trigger &&
          note == other.note &&
          deliver == other.deliver &&
          whenBusy == other.whenBusy &&
          maxRuns == other.maxRuns &&
          costCapMicros == other.costCapMicros &&
          sameWakeInstant(expiresAt, other.expiresAt) &&
          runCount == other.runCount &&
          skipCount == other.skipCount &&
          costMicros == other.costMicros &&
          sameWakeInstant(lastFiredAt, other.lastFiredAt) &&
          sameWakeInstant(nextFireAt, other.nextFireAt) &&
          nextDelaySeconds == other.nextDelaySeconds &&
          goalId == other.goalId &&
          rootRuleId == other.rootRuleId &&
          noteEditedByUserId == other.noteEditedByUserId &&
          origin == other.origin &&
          createdByRunId == other.createdByRunId &&
          createdByUserId == other.createdByUserId &&
          requestedByUserId == other.requestedByUserId &&
          status == other.status &&
          endReason == other.endReason &&
          sameWakeInstant(createdAt, other.createdAt) &&
          sameWakeInstant(updatedAt, other.updatedAt);

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    spaceId,
    conversationId,
    agentId,
    trigger,
    note,
    deliver,
    whenBusy,
    maxRuns,
    costCapMicros,
    expiresAt,
    runCount,
    skipCount,
    costMicros,
    lastFiredAt,
    nextFireAt,
    nextDelaySeconds,
    goalId,
    rootRuleId,
    noteEditedByUserId,
    origin,
    createdByRunId,
    createdByUserId,
    requestedByUserId,
    status,
    endReason,
    createdAt,
    updatedAt,
  ]);

  @override
  String toString() =>
      'WakeRule($id, ${trigger.kind} for $agentId in $conversationId, '
      '${status.wire})';
}
