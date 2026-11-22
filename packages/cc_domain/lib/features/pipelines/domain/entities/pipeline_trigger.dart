import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';
import 'package:cc_domain/features/pipelines/domain/services/schedule_spec.dart';
import 'package:collection/collection.dart';

const DeepCollectionEquality _deepEquality = DeepCollectionEquality();

/// How a scheduled trigger treats fires it missed while the server was down.
enum CronCatchUpPolicy {
  /// Collapse every missed slot into a single fire on restart (the default —
  /// "run once, now"). Good for jobs where the latest run subsumes the misses.
  catchUpLatestOnly,

  /// Skip missed fires entirely and resume at the next future slot. Good for
  /// time-sensitive jobs where a late run is worse than a skipped one.
  skip;

  /// Parses a stored name. Null (never set) is [catchUpLatestOnly], the
  /// documented default; an unknown name is logged and also reads as
  /// [catchUpLatestOnly] — the policy that never silently drops a fire.
  static CronCatchUpPolicy fromName(String? name) {
    if (name == null || name.isEmpty) {
      return catchUpLatestOnly;
    }
    for (final p in CronCatchUpPolicy.values) {
      if (p.name == name) {
        return p;
      }
    }
    CcDomainLog.warning(
      'CronCatchUpPolicy: unknown policy "$name"; using catchUpLatestOnly',
    );
    return catchUpLatestOnly;
  }
}

/// A declarative trigger that auto-starts a pipeline when a domain event fires,
/// on a schedule (interval or cron), or via an inbound signed webhook.
///
/// Triggers are per-workspace, default-off. When a matching event fires
/// and the trigger is enabled, the `PipelineTriggerDispatcher` calls
/// `PipelineEngine.start` with the event payload.
class PipelineTrigger implements ScheduleSpec {
  /// Creates a [PipelineTrigger].
  PipelineTrigger({
    required this.id,
    required this.eventType,
    required this.templateId,
    required this.workspaceId,
    this.enabled = false,
    this.cronExpression,
    this.timezone,
    this.nextRunAt,
    this.webhookToken,
    this.eventFilters = const {},
    this.match = const {},
    this.lastFiredAt,
    this.catchUpPolicy = CronCatchUpPolicy.catchUpLatestOnly,
    Set<String> armedByUserIds = const {},
    DateTime? createdAt,
  }) : armedByUserIds = Set.unmodifiable({
         for (final id in armedByUserIds)
           if (id.isNotEmpty) id,
       }),
       createdAt = createdAt ?? DateTime.now() {
    if (eventType.isEmpty) {
      throw ArgumentError('eventType must not be empty');
    }
    if (templateId.isEmpty) {
      throw ArgumentError('templateId must not be empty');
    }
  }

  /// Synthetic event type used for time-based (scheduled) triggers.
  static const String scheduleEventType = 'schedule';

  /// Synthetic event type marking a template as runnable by hand from the
  /// manual run page. Manual triggers never fire on a domain event; their
  /// presence (enabled) simply opts the template into the run picker and the
  /// run form is built from the template's declared inputs.
  static const String manualEventType = 'manual';

  /// Synthetic event type for triggers fired by an inbound signed webhook.
  static const String webhookEventType = 'webhook';

  /// Unique trigger identifier.
  final String id;

  /// Fully-qualified domain event type name (e.g. 'ExternalPrDetected').
  final String eventType;

  /// Pipeline template to start when the event fires.
  final String templateId;

  /// Workspace scope.
  final String workspaceId;

  /// Whether this trigger is active.
  final bool enabled;

  /// Schedule expression for time-based triggers ([eventType] ==
  /// [scheduleEventType]). Two accepted forms:
  /// * `every:<seconds>` — a fixed interval (parsed by [intervalSeconds]).
  /// * a standard 5-field cron expression `m h dom mon dow` (parsed by
  ///   [cronSchedule]), evaluated in [timezone].
  final String? cronExpression;

  /// IANA timezone name the [cronExpression] is evaluated in (e.g.
  /// `America/New_York`). `null` / empty means UTC.
  @override
  final String? timezone;

  /// The next wall-clock instant (UTC) this scheduled trigger is due to fire.
  /// Maintained by the scheduler; `null` until first computed.
  final DateTime? nextRunAt;

  /// Opaque secret path token for webhook triggers. An inbound POST to
  /// `/webhooks/<webhookToken>` is routed to this trigger; the request's HMAC
  /// signature is verified against this same token. `null` for non-webhook
  /// triggers, and for one whose stored secret is gone (its next save mints a
  /// new token). The server keeps it in its secrets store, never in a
  /// database row.
  final String? webhookToken;

  /// Per-event action filters for webhook triggers (e.g.
  /// `{"events": ["push", "pull_request"]}`). The webhook delivery handler only
  /// fires the pipeline when the inbound event's declared action is allowed.
  /// Empty fires on every delivery.
  final Map<String, dynamic> eventFilters;

  /// Optional value filter applied to the event payload before the trigger
  /// fires. Each entry is `payloadKey -> allowed value(s)`; the trigger only
  /// fires when the payload's value for that key matches (equals a scalar, or
  /// is contained in a list). Empty means "fire on every matching event".
  ///
  /// Example: `{'status': ['merged', 'closed']}` on a `PullRequestStatusChanged`
  /// trigger fires only when the PR transitions to merged or closed.
  final Map<String, dynamic> match;

  /// When this scheduled trigger last fired (null until first firing).
  final DateTime? lastFiredAt;

  /// How missed scheduled fires (server downtime) are handled. Only meaningful
  /// for scheduled triggers; ignored for event/webhook/manual triggers.
  final CronCatchUpPolicy catchUpPolicy;

  /// Every member who armed this trigger (enabled it on an event, schedule
  /// or webhook) or edited it, or its pipeline, while it was armed. Set by
  /// the server, never by a client; emptied when it is disarmed. Runs it
  /// starts record them under `kPipelineArmedByKey`: not as requesters, but
  /// as who may not approve a pull request those runs' agents open.
  final Set<String> armedByUserIds;

  /// Whether [payload] satisfies this trigger's [match] filter. An empty
  /// filter always matches.
  bool matches(Map<String, dynamic> payload) {
    for (final entry in match.entries) {
      final actual = payload[entry.key];
      final expected = entry.value;
      if (expected is List) {
        if (!expected.contains(actual)) {
          return false;
        }
      } else if (actual != expected) {
        return false;
      }
    }
    return true;
  }

  /// When this trigger was created.
  final DateTime createdAt;

  /// The interval in seconds parsed from an `every:<seconds>` [cronExpression],
  /// or null if not an interval schedule.
  @override
  int? get intervalSeconds {
    final expr = cronExpression;
    if (expr == null || !expr.startsWith('every:')) {
      return null;
    }
    return int.tryParse(expr.substring(6).trim());
  }

  /// The parsed [CronSchedule] when [cronExpression] is a standard 5-field cron
  /// (not the `every:` interval form), or null.
  @override
  CronSchedule? get cronSchedule {
    final expr = cronExpression;
    if (expr == null || expr.startsWith('every:')) {
      return null;
    }
    return CronSchedule.tryParse(expr);
  }

  /// Why this trigger's schedule can never fire correctly, or null when it is
  /// valid (or this is not a scheduled trigger).
  ///
  /// An unparsable cron used to idle silently forever and `every:0` fired on
  /// every tick, so a schedule is checked when the trigger is written. The
  /// [timezone] is checked by the server, which holds the zone database.
  String? get scheduleError {
    if (eventType != scheduleEventType) {
      return null;
    }
    final expr = cronExpression?.trim() ?? '';
    if (expr.isEmpty) {
      return 'A scheduled trigger needs a schedule';
    }
    if (expr.startsWith('every:')) {
      final seconds = intervalSeconds;
      if (seconds == null || seconds <= 0) {
        return '"$expr" needs a positive number of seconds after "every:"';
      }
      return null;
    }
    final schedule = CronSchedule.tryParse(expr);
    if (schedule == null) {
      return '"$expr" is not a 5-field cron expression '
          '(minute hour day-of-month month day-of-week)';
    }
    if (schedule.nextAfter(DateTime.utc(2000)) == null) {
      return '"$expr" never matches a real date';
    }
    return null;
  }

  /// Whether this is a webhook trigger.
  bool get isWebhook =>
      eventType == webhookEventType ||
      (webhookToken != null && webhookToken!.isNotEmpty);

  /// Creates a copy with updated fields. Pass the matching `clear*` flag to
  /// reset a nullable field to null (since null means "leave unchanged").
  PipelineTrigger copyWith({
    bool? enabled,
    String? cronExpression,
    String? timezone,
    DateTime? nextRunAt,
    String? webhookToken,
    Map<String, dynamic>? eventFilters,
    Map<String, dynamic>? match,
    DateTime? lastFiredAt,
    CronCatchUpPolicy? catchUpPolicy,
    Set<String>? armedByUserIds,
    bool clearNextRunAt = false,
    bool clearLastFiredAt = false,
    bool clearArmedBy = false,
  }) {
    return PipelineTrigger(
      id: id,
      eventType: eventType,
      templateId: templateId,
      workspaceId: workspaceId,
      enabled: enabled ?? this.enabled,
      cronExpression: cronExpression ?? this.cronExpression,
      timezone: timezone ?? this.timezone,
      nextRunAt: clearNextRunAt ? null : (nextRunAt ?? this.nextRunAt),
      webhookToken: webhookToken ?? this.webhookToken,
      eventFilters: eventFilters ?? this.eventFilters,
      match: match ?? this.match,
      lastFiredAt: clearLastFiredAt ? null : (lastFiredAt ?? this.lastFiredAt),
      catchUpPolicy: catchUpPolicy ?? this.catchUpPolicy,
      armedByUserIds: clearArmedBy
          ? const {}
          : (armedByUserIds ?? this.armedByUserIds),
      createdAt: createdAt,
    );
  }

  /// Field-by-field, so a stream consumer comparing snapshots sees a schedule,
  /// filter or catch-up edit — not only an enable toggle.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineTrigger &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventType == other.eventType &&
          templateId == other.templateId &&
          workspaceId == other.workspaceId &&
          enabled == other.enabled &&
          cronExpression == other.cronExpression &&
          timezone == other.timezone &&
          nextRunAt == other.nextRunAt &&
          webhookToken == other.webhookToken &&
          _deepEquality.equals(eventFilters, other.eventFilters) &&
          _deepEquality.equals(match, other.match) &&
          lastFiredAt == other.lastFiredAt &&
          catchUpPolicy == other.catchUpPolicy &&
          _deepEquality.equals(armedByUserIds, other.armedByUserIds) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    eventType,
    templateId,
    workspaceId,
    enabled,
    cronExpression,
    timezone,
    nextRunAt,
    webhookToken,
    _deepEquality.hash(eventFilters),
    _deepEquality.hash(match),
    lastFiredAt,
    catchUpPolicy,
    _deepEquality.hash(armedByUserIds),
    createdAt,
  );
}
