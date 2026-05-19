import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';

/// How a scheduled trigger treats fires it missed while the server was down.
enum CronCatchUpPolicy {
  /// Collapse every missed slot into a single fire on restart (the default —
  /// "run once, now"). Good for jobs where the latest run subsumes the misses.
  catchUpLatestOnly,

  /// Skip missed fires entirely and resume at the next future slot. Good for
  /// time-sensitive jobs where a late run is worse than a skipped one.
  skip;

  /// Parses a stored name, defaulting to [catchUpLatestOnly] for null/unknown.
  static CronCatchUpPolicy fromName(String? name) => CronCatchUpPolicy.values
      .firstWhere((p) => p.name == name, orElse: () => catchUpLatestOnly);
}

/// A declarative trigger that auto-starts a pipeline when a domain event fires,
/// on a schedule (interval or cron), or via an inbound signed webhook.
///
/// Triggers are per-workspace, default-off. When a matching event fires
/// and the trigger is enabled, the `PipelineTriggerDispatcher` calls
/// `PipelineEngine.start` with the event payload.
class PipelineTrigger {
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
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
  final String? timezone;

  /// The next wall-clock instant (UTC) this scheduled trigger is due to fire.
  /// Maintained by the scheduler; `null` until first computed.
  final DateTime? nextRunAt;

  /// Opaque secret path token for webhook triggers. An inbound POST to
  /// `/webhooks/<webhookToken>` is routed to this trigger; the request's HMAC
  /// signature is verified against this same token. `null` for non-webhook
  /// triggers.
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
  int? get intervalSeconds {
    final expr = cronExpression;
    if (expr == null || !expr.startsWith('every:')) {
      return null;
    }
    return int.tryParse(expr.substring(6).trim());
  }

  /// The parsed [CronSchedule] when [cronExpression] is a standard 5-field cron
  /// (not the `every:` interval form), or null.
  CronSchedule? get cronSchedule {
    final expr = cronExpression;
    if (expr == null || expr.startsWith('every:')) {
      return null;
    }
    return CronSchedule.tryParse(expr);
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
    bool clearNextRunAt = false,
    bool clearLastFiredAt = false,
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
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineTrigger &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventType == other.eventType &&
          templateId == other.templateId &&
          workspaceId == other.workspaceId &&
          enabled == other.enabled;

  @override
  int get hashCode =>
      Object.hash(id, eventType, templateId, workspaceId, enabled);
}
