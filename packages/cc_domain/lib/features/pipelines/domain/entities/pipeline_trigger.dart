/// A declarative trigger that auto-starts a pipeline when a domain event fires.
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
    this.match = const {},
    this.lastFiredAt,
    DateTime? createdAt,
  })  : assert(eventType.isNotEmpty, 'eventType must not be empty'),
        assert(templateId.isNotEmpty, 'templateId must not be empty'),
        createdAt = createdAt ?? DateTime.now();

  /// Synthetic event type used for time-based (scheduled) triggers.
  static const String scheduleEventType = 'schedule';

  /// Synthetic event type marking a template as runnable by hand from the
  /// manual run page. Manual triggers never fire on a domain event; their
  /// presence (enabled) simply opts the template into the run picker, and the
  /// run form is built from the template's declared inputs.
  static const String manualEventType = 'manual';

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
  /// [scheduleEventType]). Supported form: `every:<seconds>`.
  final String? cronExpression;

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

  /// Creates a copy with updated fields.
  PipelineTrigger copyWith({
    bool? enabled,
    String? cronExpression,
    Map<String, dynamic>? match,
    DateTime? lastFiredAt,
  }) {
    return PipelineTrigger(
      id: id,
      eventType: eventType,
      templateId: templateId,
      workspaceId: workspaceId,
      enabled: enabled ?? this.enabled,
      cronExpression: cronExpression ?? this.cronExpression,
      match: match ?? this.match,
      lastFiredAt: lastFiredAt ?? this.lastFiredAt,
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
  int get hashCode => Object.hash(id, eventType, templateId, workspaceId, enabled);
}
