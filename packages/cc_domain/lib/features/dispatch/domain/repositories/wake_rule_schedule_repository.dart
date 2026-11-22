import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';

/// A schedule, loop or watch as a person sees it (`wakeRules.*` ops): whose
/// it is, what wakes it, when it fires next, how far it got and where it
/// stands. The note is the person's or agent's own text.
class WakeRuleView {
  /// Creates a view. Throws [ArgumentError] for an empty id or target.
  WakeRuleView({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.origin,
    required this.trigger,
    required this.triggerKind,
    required this.note,
    required this.deliver,
    required this.whenBusy,
    required this.runCount,
    required this.skipCount,
    required this.costMicros,
    required this.costCapMicros,
    required this.status,
    required DateTime expiresAt,
    required DateTime createdAt,
    required this.canChange,
    required this.noteAuthor,
    required List<DateTime> nextFires,
    this.noteEditedByUserId,
    this.rootRuleId,
    this.lineageRunsLeft,
    DateTime? lineageEndsAt,
    this.ownerUserId,
    this.createdByUserId,
    this.createdByRunId,
    this.timeZone,
    DateTime? nextFireAt,
    DateTime? lastFiredAt,
    this.maxRuns,
    this.goalId,
    this.endReason,
  }) : expiresAt = expiresAt.toUtc(),
       createdAt = createdAt.toUtc(),
       nextFireAt = nextFireAt?.toUtc(),
       nextFires = List.unmodifiable([for (final f in nextFires) f.toUtc()]),
       lastFiredAt = lastFiredAt?.toUtc(),
       lineageEndsAt = lineageEndsAt?.toUtc() {
    for (final (name, value) in [
      ('id', id),
      ('workspaceId', workspaceId),
      ('conversationId', conversationId),
      ('agentId', agentId),
      ('trigger', trigger),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
  }

  /// The rule's id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The conversation's space.
  final String spaceId;

  /// The conversation it wakes.
  final String conversationId;

  /// The agent it wakes.
  final String agentId;

  /// The person it acts for; null for a bot's rule.
  final String? ownerUserId;

  /// The person who made it, when a person did.
  final String? createdByUserId;

  /// The run that made it, when an agent did.
  final String? createdByRunId;

  /// A person's or an agent's.
  final WakeRuleOrigin origin;

  /// What wakes it, in the `when` grammar (`every:30m`, `on:pr_checks`).
  final String trigger;

  /// The trigger's kind (`at`, `every`, `cron`, `self_paced`, `on_event`).
  final String triggerKind;

  /// A cron rule's time zone.
  final String? timeZone;

  /// What its runs start from.
  final String note;

  /// Whose words [note] is: the agent's own (data, never a person's
  /// request) or a person's (its creator's, or [noteEditedByUserId]'s after
  /// an edit).
  final WakeRuleOrigin noteAuthor;

  /// The person who last edited [note], when one did.
  final String? noteEditedByUserId;

  /// The first rule of the chain of wakes this rule belongs to (a rule set
  /// in a run another rule's wake started); null outside a chain. A rule in
  /// a chain is extended through its root.
  final String? rootRuleId;

  /// The runs the chain has left in all, when the rule is in one.
  final int? lineageRunsLeft;

  /// When the chain ends, when the rule is in one.
  final DateTime? lineageEndsAt;

  /// Start a run or only notify.
  final WakeDeliver deliver;

  /// What a fire that finds the agent busy does.
  final WakeWhenBusy whenBusy;

  /// When it fires next (none for a watch or an ended rule).
  final DateTime? nextFireAt;

  /// A cron rule's next fire times (UTC, at most three), as the server
  /// computed them with its zone rules when it sent the rule: only slots
  /// the rule can still fire. Empty for every other rule. A reader drops
  /// the ones already past.
  final List<DateTime> nextFires;

  /// When it last fired.
  final DateTime? lastFiredAt;

  /// Runs so far.
  final int runCount;

  /// Its run cap, when it has one.
  final int? maxRuns;

  /// Fires skipped (busy or missed).
  final int skipCount;

  /// What its runs cost so far, in micro-dollars.
  final int costMicros;

  /// Its cost cap, in micro-dollars.
  final int costCapMicros;

  /// The goal it is bound to, when it is.
  final String? goalId;

  /// Active, paused or ended.
  final WakeRuleStatus status;

  /// Why it ended, when it did.
  final WakeRuleEndReason? endReason;

  /// It ends at this time.
  final DateTime expiresAt;

  /// When it was made.
  final DateTime createdAt;

  /// Whether the viewer may resume it or change its note and limits (its
  /// own person; a workspace admin for a bot's rule). Pausing and deleting
  /// are open to every member who sees it.
  final bool canChange;

  @override
  bool operator ==(Object other) =>
      other is WakeRuleView &&
      other.id == id &&
      other.workspaceId == workspaceId &&
      other.status == status &&
      other.nextFireAt == nextFireAt &&
      _sameInstants(other.nextFires, nextFires) &&
      other.runCount == runCount &&
      other.skipCount == skipCount &&
      other.costMicros == costMicros &&
      other.note == note &&
      other.endReason == endReason &&
      other.expiresAt == expiresAt &&
      other.maxRuns == maxRuns &&
      other.costCapMicros == costCapMicros &&
      other.whenBusy == whenBusy &&
      other.canChange == canChange &&
      other.noteAuthor == noteAuthor &&
      other.noteEditedByUserId == noteEditedByUserId &&
      other.rootRuleId == rootRuleId &&
      other.lineageRunsLeft == lineageRunsLeft &&
      other.lineageEndsAt == lineageEndsAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    status,
    nextFireAt,
    Object.hashAll(nextFires),
    runCount,
    skipCount,
    costMicros,
    note,
    endReason,
    expiresAt,
    maxRuns,
    costCapMicros,
    whenBusy,
    canChange,
    noteAuthor,
    noteEditedByUserId,
    rootRuleId,
    lineageRunsLeft,
    lineageEndsAt,
  ]);
}

/// A run a rule's wake started, as a rule's history shows it. Times are
/// UTC.
class WakeRuleRunFactsView {
  /// Creates a run view.
  WakeRuleRunFactsView({
    required this.id,
    required this.status,
    required this.costMicros,
    required DateTime startedAt,
    this.endReason,
    DateTime? endedAt,
  }) : startedAt = startedAt.toUtc(),
       endedAt = endedAt?.toUtc();

  /// The run's id.
  final String id;

  /// `pending`, `running`, `completed` or `error`.
  final String status;

  /// Why it ended (`completed`, `usage_limit`, …); null while it runs.
  final String? endReason;

  /// What it cost in micro-dollars, its subagents' included.
  final int costMicros;

  /// When it started.
  final DateTime startedAt;

  /// When it ended; null while it runs.
  final DateTime? endedAt;

  /// Whether it is still going.
  bool get isLive => endedAt == null;

  @override
  bool operator ==(Object other) =>
      other is WakeRuleRunFactsView &&
      other.id == id &&
      other.status == status &&
      other.endReason == endReason &&
      other.costMicros == costMicros &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt;

  @override
  int get hashCode =>
      Object.hash(id, status, endReason, costMicros, startedAt, endedAt);
}

/// One wake of a rule (`wakeRules.listRuns`): what it was for (its slot, or
/// a watch's event), what became of it and, when it started one, the run.
/// Times are UTC.
class WakeRuleRunView {
  /// Creates a view. Throws [ArgumentError] for an empty id.
  WakeRuleRunView({
    required this.wakeId,
    required this.reason,
    required this.state,
    required DateTime dueAt,
    required DateTime createdAt,
    this.stateReason,
    DateTime? slot,
    this.eventKind,
    this.status,
    this.subject,
    this.item,
    this.exitCode,
    this.events,
    DateTime? settledAt,
    this.run,
  }) : dueAt = dueAt.toUtc(),
       createdAt = createdAt.toUtc(),
       slot = slot?.toUtc(),
       settledAt = settledAt?.toUtc() {
    if (wakeId.isEmpty) {
      throw ArgumentError.value(wakeId, 'wakeId', 'must not be empty');
    }
  }

  /// The wake's id.
  final String wakeId;

  /// `schedule`, `watch` or `limit_reset`.
  final String reason;

  /// `pending`, `held`, `claimed`, `delivered`, `skipped`, `expired` or
  /// `cancelled`.
  final String state;

  /// Why it reached [state] (`rule_busy`, `missed`, …), when recorded.
  final String? stateReason;

  /// The slot a schedule's wake was for.
  final DateTime? slot;

  /// A watch's event kind (`pr_checks`, `environment`, …).
  final String? eventKind;

  /// A watch's event status (`failed`, `commented`, `exited`, …).
  final String? status;

  /// What the event was about (`acme/shop-ui#12`).
  final String? subject;

  /// The one thing it points at (the failing check, the process).
  final String? item;

  /// A watched process's exit code.
  final int? exitCode;

  /// How many events the wake gathered.
  final int? events;

  /// When it was due.
  final DateTime dueAt;

  /// When it was written.
  final DateTime createdAt;

  /// When it settled.
  final DateTime? settledAt;

  /// The run it started; null for one that started none.
  final WakeRuleRunFactsView? run;

  @override
  bool operator ==(Object other) =>
      other is WakeRuleRunView &&
      other.wakeId == wakeId &&
      other.state == state &&
      other.stateReason == stateReason &&
      other.settledAt == settledAt &&
      other.events == events &&
      other.run == run;

  @override
  int get hashCode =>
      Object.hash(wakeId, state, stateReason, settledAt, events, run);
}

/// A draft cron's next fire times (UTC) as the server computed them, and
/// the server's verdict on its zone (`wakeRules.previewCron`).
typedef CronPreview = ({List<DateTime> nextFires, bool zoneKnown});

/// A page of a rule's wakes, newest first, and the cursor of the next page
/// (null on the last).
typedef WakeRuleRunPage = ({List<WakeRuleRunView> wakes, String? nextCursor});

bool _sameInstants(List<DateTime> a, List<DateTime> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (!a[i].isAtSameMomentAs(b[i])) {
      return false;
    }
  }
  return true;
}

/// What a person asks to create from the Schedules screen. Exactly one of
/// [when] (the `when` grammar) and [hour]/[minute] (the next such wall-clock
/// time in the zone).
class WakeRuleDraft {
  /// Creates a draft. Throws [ArgumentError] when neither or both of [when]
  /// and the clock are given, or the clock is out of range.
  WakeRuleDraft({
    required this.conversationId,
    required this.agentId,
    required this.note,
    this.when,
    this.hour,
    this.minute,
    this.timeZone,
    this.maxRuns,
    this.expiresIn,
    this.costCapMicros,
    this.whenBusy,
    this.deliver = WakeDeliver.run,
    this.fireNow = false,
  }) {
    final clock = hour != null || minute != null;
    if ((when == null) == !clock) {
      throw ArgumentError('Give either when or hour and minute');
    }
    if (clock &&
        (hour == null ||
            minute == null ||
            hour! < 0 ||
            hour! > 23 ||
            minute! < 0 ||
            minute! > 59)) {
      throw ArgumentError('hour is 0 to 23 and minute 0 to 59');
    }
  }

  /// The conversation to wake.
  final String conversationId;

  /// The agent to wake.
  final String agentId;

  /// What its runs start from.
  final String note;

  /// The `when` grammar.
  final String? when;

  /// The clock's hour.
  final int? hour;

  /// The clock's minute.
  final int? minute;

  /// A cron's or clock's IANA zone (default the workspace's).
  final String? timeZone;

  /// The run cap.
  final int? maxRuns;

  /// How long it lives, in the duration grammar (`30d`).
  final String? expiresIn;

  /// The cost cap, in micro-dollars.
  final int? costCapMicros;

  /// What a busy fire does (default by kind).
  final WakeWhenBusy? whenBusy;

  /// Start a run or only notify.
  final WakeDeliver deliver;

  /// Fire the first run at once (a loop).
  final bool fireNow;
}

/// A person's view of and controls over the workspace's schedules, loops and
/// watches (`wakeRules.*`). Every call names the workspace; the server
/// derives the rest from the rule's row.
abstract interface class WakeRuleScheduleRepository {
  /// The conversation's open rules, newest first, as they change.
  Stream<List<WakeRuleView>> watchForConversation(
    String workspaceId,
    String conversationId,
  );

  /// Every rule of the workspace in a space the viewer may read, newest
  /// first, as they change (the Schedules screen).
  Stream<List<WakeRuleView>> watchForWorkspace(String workspaceId);

  /// One rule.
  Future<WakeRuleView> get(String workspaceId, String ruleId);

  /// The rule's wakes, newest first, a page of at most 50 after [cursor]
  /// (the previous page's `nextCursor`), each with the run it started.
  Future<WakeRuleRunPage> listRuns(
    String workspaceId,
    String ruleId, {
    String? cursor,
  });

  /// Creates a rule for the viewer.
  Future<WakeRuleView> create(String workspaceId, WakeRuleDraft draft);

  /// Changes a rule's terms or limits (its own person's).
  Future<WakeRuleView> update(
    String workspaceId,
    String ruleId, {
    String? note,
    WakeWhenBusy? whenBusy,
    int? maxRuns,
    bool clearMaxRuns = false,
    int? costCapMicros,
    DateTime? expiresAt,
  });

  /// Pauses an active rule. False when it was not active.
  Future<bool> pause(String workspaceId, String ruleId);

  /// Resumes a paused rule (its own person's). False when it was not paused.
  Future<bool> resume(String workspaceId, String ruleId);

  /// Ends a rule; a second delete of an ended rule removes it.
  Future<bool> delete(String workspaceId, String ruleId);

  /// The workspace's limits.
  Future<WakeRuleLimits> limits(String workspaceId);

  /// Sets the workspace's limits (an admin's).
  Future<WakeRuleLimits> setLimits(String workspaceId, WakeRuleLimits limits);

  /// The next fire times (UTC, at most three) of a draft cron [expression]
  /// in [timeZone] (empty: the workspace's zone), computed by the server,
  /// and whether the server knows [timeZone] (true when it is empty). No
  /// times for an empty expression (a zone asked about alone), one that does
  /// not parse or never fires, or an unknown zone.
  Future<CronPreview> previewCron(
    String workspaceId, {
    required String expression,
    required String timeZone,
  });
}
