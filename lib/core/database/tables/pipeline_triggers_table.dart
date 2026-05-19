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

  /// Optional cron expression. When set (and [eventType] is the synthetic
  /// `schedule` type), a periodic ticker starts the template on this schedule.
  TextColumn get cronExpression => text().nullable()();

  /// Optional JSON object of `payloadKey -> allowed value(s)` applied to the
  /// triggering event's payload before the trigger fires (e.g.
  /// `{"status":["merged","closed"]}`). Empty/`{}` fires on every event.
  TextColumn get matchJson => text().withDefault(const Constant('{}'))();

  /// When the scheduled trigger last fired (null until first firing).
  DateTimeColumn get lastFiredAt => dateTime().nullable()();

  /// When this trigger was created.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
