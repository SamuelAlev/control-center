import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart'
    show CronCatchUpPolicy;
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/pipeline_templates_table.dart';
import 'package:drift/drift.dart';

/// Triggers that auto-start pipelines when domain events fire.
///
/// Unique on (template_id, event_type): one trigger per event for a
/// template. The key also indexes the template foreign key.
@TableIndex(
  name: 'uq_pipeline_triggers',
  columns: {#templateId, #eventType},
  unique: true,
)
@TableIndex(
  name: 'idx_pipeline_triggers_enabled_eventType',
  columns: {#enabled, #eventType},
)
@TableIndex(
  name: 'uq_pipeline_triggers_webhook_token_ref',
  columns: {#webhookTokenRef},
  unique: true,
)
class PipelineTriggersTable extends Table {
  /// Unique trigger identifier (UUID v4).
  TextColumn get id => text()();

  /// Fully-qualified domain event type (e.g. 'ExternalPrDetected').
  TextColumn get eventType => text()();

  /// Pipeline template to start. `CASCADE`: a trigger is part of its
  /// template's configuration and means nothing without it.
  TextColumn get templateId => text().references(
    PipelineTemplatesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

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

  /// Where this webhook trigger's token is kept in the server's secrets store
  /// (`WebhookSecretVault.pipelineTriggerRef`); never the token itself, which
  /// is both the `/webhooks/<token>` path and the HMAC secret, so no snapshot
  /// or export of this file carries it. Unique: one token, one trigger. Null
  /// for a trigger with no token.
  TextColumn get webhookTokenRef => text().nullable()();

  /// Optional JSON object of per-event action filters for webhook triggers
  /// (e.g. `{"events":["push","pull_request"]}`). Empty/`{}` fires on every
  /// delivery.
  TextColumn get eventFiltersJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(eventFiltersJson))
      .withDefault(const Constant('{}'))();

  /// Optional JSON object of `payloadKey -> allowed value(s)` applied to the
  /// triggering event's payload before the trigger fires (e.g.
  /// `{"status":["merged","closed"]}`). Empty/`{}` fires on every event.
  TextColumn get matchJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(matchJson))
      .withDefault(const Constant('{}'))();

  /// When the scheduled trigger last fired (null until first firing).
  DateTimeColumn get lastFiredAt => dateTime().nullable()();

  /// How missed scheduled fires (server downtime) are handled — the
  /// [CronCatchUpPolicy] name (`catchUpLatestOnly` default, or `skip`).
  TextColumn get catchUpPolicy => text()
      // ignore: recursive_getters
      .check(catchUpPolicy.isIn(AgentsStoredValues.cronCatchUpPolicy))
      .withDefault(const Constant('catchUpLatestOnly'))();

  /// JSON array of every member who armed this trigger, or edited it (or
  /// its pipeline) while armed; `[]` when disarmed. Server-written only.
  TextColumn get armedByUserIdsJson => text()
      .named('armed_by_user_ids')
      // ignore: recursive_getters
      .check(isJsonArray(armedByUserIdsJson))
      .withDefault(const Constant('[]'))();

  /// When this trigger was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'pipeline_triggers';

  @override
  Set<Column> get primaryKey => {id};
}
