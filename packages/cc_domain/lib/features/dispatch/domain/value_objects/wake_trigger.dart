import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';

/// When a wake rule fires: once at an instant, every interval, on a cron
/// schedule, at a delay the agent picks after each run, or when a watched
/// event settles.
///
/// Stored in the `wake_rules.trigger_*` columns; the mapper builds the
/// subtype from `trigger_kind`.
sealed class WakeTrigger {
  const WakeTrigger();

  /// The `trigger_kind` column value: `at`, `every`, `cron`, `self_paced`,
  /// `event`.
  String get kind;

  /// Every `trigger_kind` value, for the stored-value check.
  static const List<String> kinds = [
    OnceAt.kindName,
    Every.kindName,
    Cron.kindName,
    SelfPaced.kindName,
    OnEvent.kindName,
  ];

  /// Whether the trigger fires more than once.
  bool get repeats => this is! OnceAt;
}

/// Fires once at [at] (`in:<duration>`, `at:<ISO time>`).
final class OnceAt extends WakeTrigger {
  /// Creates a one-off trigger at [at] (kept as a slot: UTC, whole
  /// seconds, [wakeSlotOf]).
  OnceAt(DateTime at) : at = wakeSlotOf(at);

  /// The `trigger_kind` value.
  static const String kindName = 'at';

  /// When it fires, in UTC.
  final DateTime at;

  @override
  String get kind => kindName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnceAt && at.isAtSameMomentAs(other.at);

  @override
  int get hashCode => Object.hash(OnceAt, at);

  @override
  String toString() => 'OnceAt($at)';
}

/// Fires every [interval], in epoch-aligned slots (`every:<duration>`).
final class Every extends WakeTrigger {
  /// Creates a repeating trigger. Throws [ArgumentError] for an interval
  /// below [minInterval] or not a whole number of seconds.
  Every(this.interval) {
    if (interval < minInterval) {
      throw ArgumentError.value(
        interval,
        'interval',
        'must be at least ${minInterval.inSeconds} seconds',
      );
    }
    if (interval.inMicroseconds % Duration.microsecondsPerSecond != 0) {
      throw ArgumentError.value(
        interval,
        'interval',
        'must be a whole number of seconds',
      );
    }
  }

  /// The shortest interval a rule may repeat at.
  static const Duration minInterval = Duration(seconds: 60);

  /// The `trigger_kind` value.
  static const String kindName = 'every';

  /// Time between slots.
  final Duration interval;

  @override
  String get kind => kindName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Every && interval == other.interval;

  @override
  int get hashCode => Object.hash(Every, interval);

  @override
  String toString() => 'Every($interval)';
}

/// Fires on a five-field cron [expression] in the IANA [timeZone], with the
/// existing `CronSchedule` semantics (`cron:<five fields>`).
final class Cron extends WakeTrigger {
  /// Creates a cron trigger. Throws [ArgumentError] for an empty expression
  /// or time zone. The expression's syntax is checked by `CronSchedule`
  /// where the rule is created.
  Cron(this.expression, this.timeZone) {
    if (expression.trim().isEmpty) {
      throw ArgumentError.value(expression, 'expression', 'must not be empty');
    }
    if (timeZone.trim().isEmpty) {
      throw ArgumentError.value(timeZone, 'timeZone', 'must not be empty');
    }
  }

  /// The `trigger_kind` value.
  static const String kindName = 'cron';

  /// The five-field cron expression.
  final String expression;

  /// The IANA time zone the expression is read in.
  final String timeZone;

  @override
  String get kind => kindName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cron &&
          expression == other.expression &&
          timeZone == other.timeZone;

  @override
  int get hashCode => Object.hash(Cron, expression, timeZone);

  @override
  String toString() => 'Cron($expression, $timeZone)';
}

/// Self-paced (`next`): the agent chooses the delay at the end of each run,
/// 1 minute to 1 hour, and [defaultDelay] when it says nothing. The chosen
/// delay is the rule's `nextDelaySeconds`.
final class SelfPaced extends WakeTrigger {
  /// Creates a self-paced trigger.
  const SelfPaced();

  /// The `trigger_kind` value.
  static const String kindName = 'self_paced';

  /// The shortest delay an agent may choose.
  static const Duration minDelay = Duration(minutes: 1);

  /// The longest delay an agent may choose.
  static const Duration maxDelay = Duration(hours: 1);

  /// The delay when the agent chose none.
  static const Duration defaultDelay = Duration(minutes: 20);

  @override
  String get kind => kindName;

  @override
  bool operator ==(Object other) => other is SelfPaced;

  @override
  int get hashCode => (SelfPaced).hashCode;

  @override
  String toString() => 'SelfPaced()';
}

/// Fires when a watched event settles (`on:<event>`). [targetId] names the
/// ticket or pipeline run for those kinds; a pull request watch may name one
/// pull request (`owner/name#12`, [WakePullRequestRef]) and otherwise
/// watches the pull request of the rule's space; an environment watch
/// watches the space's environment.
final class OnEvent extends WakeTrigger {
  /// Creates a watch. Throws [ArgumentError] when a `ticket` or
  /// `pipelineRun` watch has no target, a pull request watch's target is not
  /// `owner/name#number`, or an environment watch has one.
  OnEvent(this.eventKind, {this.targetId}) {
    final target = targetId;
    if (needsTarget(eventKind) && (target == null || target.isEmpty)) {
      throw ArgumentError.value(
        targetId,
        'targetId',
        'a ${eventKind.wire} watch names its target',
      );
    }
    if (target != null &&
        !needsTarget(eventKind) &&
        !(isPullRequest(eventKind) &&
            WakePullRequestRef.tryParse(target)?.toString() == target)) {
      throw ArgumentError.value(
        targetId,
        'targetId',
        isPullRequest(eventKind)
            ? 'a ${eventKind.wire} watch names a pull request as '
                  'owner/name#number'
            : 'a ${eventKind.wire} watch has no target',
      );
    }
  }

  /// The `trigger_kind` value.
  static const String kindName = 'event';

  /// Whether a watch of [kind] names its target.
  static bool needsTarget(WakeEventKind kind) =>
      kind == WakeEventKind.ticket || kind == WakeEventKind.pipelineRun;

  /// Whether [kind] watches a pull request.
  static bool isPullRequest(WakeEventKind kind) =>
      kind == WakeEventKind.prChecks ||
      kind == WakeEventKind.prReview ||
      kind == WakeEventKind.prMerged;

  /// The watched event.
  final WakeEventKind eventKind;

  /// The ticket or pipeline run id, or the named pull request
  /// (`owner/name#number`), for those kinds.
  final String? targetId;

  /// The pull request a pull request watch names; null for the space's own.
  WakePullRequestRef? get pullRequest => isPullRequest(eventKind)
      ? WakePullRequestRef.tryParse(targetId ?? '')
      : null;

  @override
  String get kind => kindName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnEvent &&
          eventKind == other.eventKind &&
          targetId == other.targetId;

  @override
  int get hashCode => Object.hash(OnEvent, eventKind, targetId);

  @override
  String toString() => 'OnEvent(${eventKind.wire}, $targetId)';
}

/// One pull request a watch names: `owner/name#number` (a GitLab group path
/// keeps its slashes in [owner]).
final class WakePullRequestRef {
  /// Creates a reference. Throws [ArgumentError] for an empty part or a
  /// number below 1.
  WakePullRequestRef(this.owner, this.name, this.number) {
    if (owner.isEmpty || name.isEmpty || number < 1) {
      throw ArgumentError.value('$owner/$name#$number', 'pullRequest');
    }
  }

  /// Reads `owner/name#number`; null for anything else.
  static WakePullRequestRef? tryParse(String raw) {
    final m = _re.firstMatch(raw.trim());
    final number = m == null ? null : int.tryParse(m.group(3)!);
    if (m == null || number == null || number < 1) {
      return null;
    }
    return WakePullRequestRef(m.group(1)!, m.group(2)!, number);
  }

  static final RegExp _re = RegExp(
    r'^([A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*)/([A-Za-z0-9_.-]+)#(\d{1,9})$',
  );

  /// The repository's owner (or group path).
  final String owner;

  /// The repository's name.
  final String name;

  /// The pull request's number.
  final int number;

  /// Whether this names pull request [prNumber] of `repoOwner/repoName`
  /// (owner and name compared without case, as the forges do).
  bool names(String repoOwner, String repoName, int prNumber) =>
      number == prNumber &&
      owner.toLowerCase() == repoOwner.toLowerCase() &&
      name.toLowerCase() == repoName.toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is WakePullRequestRef && other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => '$owner/$name#$number';
}
