import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart'
    show CronCatchUpPolicy;
import 'package:drift/drift.dart';

/// Triggers that auto-start pipelines when domain events fire.
///
/// Unique on (workspace_id, event_type, template_id).
@TableIndex(
  name: 'uq_pipeline_triggers',
  columns: {#workspaceId, #eventType, #templateId},
  unique: true,
)
@TableIndex(
  name: 'idx_pipeline_triggers_enabled_eventType',
  columns: {#enabled, #eventType},
)
@TableIndex(
  name: 'idx_pipeline_triggers_webhookToken',
  columns: {#webhookToken},
)
class PipelineTriggersTable extends Table {
  /// Unique trigger identifier (UUID v4).
  TextColumn get id => text()();

  /// Fully-qualified domain event type (e.g. 'ExternalPrDetected').
  TextColumn get eventType => text()();

  /// Pipeline template to start.
  TextColumn get templateId => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Whether this trigger is active.
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  /// Optional schedule expression. When [eventType] is the synthetic
  /// `schedule` type this is either `every:<seconds>` (a fixed interval) or a
  /// standard 5-field cron expression evaluated in [timezone].
  TextColumn get cronExpression => text().nullable()();

  /// IANA timezone the cron [cronExpression] is evaluated in (null/empty = UTC).
  TextColumn get timezone => text().nullable()();

  /// The next instant (UTC) a cron trigger is due to fire. Maintained by the
  /// scheduler; null until first computed.
  DateTimeColumn get nextRunAt => dateTime().nullable()();

  /// Opaque secret path token for webhook triggers. An inbound POST to
  /// `/webhooks/<token>` is routed to this trigger and its HMAC verified
  /// against this token. Null for non-webhook triggers.
  TextColumn get webhookToken => text().nullable()();

  /// Optional JSON object of per-event action filters for webhook triggers
  /// (e.g. `{"events":["push","pull_request"]}`). Empty/`{}` fires on every
  /// delivery.
  TextColumn get eventFiltersJson => text().withDefault(const Constant('{}'))();

  /// Optional JSON object of `payloadKey -> allowed value(s)` applied to the
  /// triggering event's payload before the trigger fires (e.g.
  /// `{"status":["merged","closed"]}`). Empty/`{}` fires on every event.
  TextColumn get matchJson => text().withDefault(const Constant('{}'))();

  /// When the scheduled trigger last fired (null until first firing).
  DateTimeColumn get lastFiredAt => dateTime().nullable()();

  /// How missed scheduled fires (server downtime) are handled — the
  /// [CronCatchUpPolicy] name (`catchUpLatestOnly` default, or `skip`).
  TextColumn get catchUpPolicy =>
      text().withDefault(const Constant('catchUpLatestOnly'))();

  /// When this trigger was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
