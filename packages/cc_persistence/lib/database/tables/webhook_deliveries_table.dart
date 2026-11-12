import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_triggers_table.dart';
import 'package:drift/drift.dart';

/// Log of inbound webhook deliveries: an allow-listed subset of the request
/// headers, the signature verification outcome and what the server did.
///
/// The request body is not kept. It reaches the pipeline run it starts and
/// nothing reads it back from here, while a provider's payload can carry
/// private repository content that every snapshot and export of this file
/// would otherwise copy.
///
/// A dedupe key is held by at most one delivery per trigger that is in flight
/// (`queued`) or was dispatched: that delivery's provider retries are answered
/// as duplicates. A delivery that failed, was rejected or was ignored holds
/// nothing, so the provider's retry of a failed dispatch runs again. The
/// claim (`WebhookDeliveryDao.claim`) is an insert whose conflict target is
/// exactly this index, so two concurrent identical deliveries cannot both
/// dispatch.
///
/// A trigger's deliveries go with the trigger; a delivery outlives the
/// pipeline run it started. The retention sweep deletes by [createdAt]
/// (`idx_webhook_deliveries_created`).
@TableIndex(
  name: 'idx_webhook_deliveries_trigger',
  columns: {#triggerId, #createdAt},
)
@TableIndex(name: 'idx_webhook_deliveries_created', columns: {#createdAt})
@TableIndex(name: 'idx_webhook_deliveries_run', columns: {#runId})
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_webhook_deliveries_dedupe '
  'ON webhook_deliveries (trigger_id, dedupe_key) '
  'WHERE dedupe_key IS NOT NULL '
  "AND status IN ('queued', 'dispatched')",
)
class WebhookDeliveriesTable extends Table {
  /// Unique delivery id.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The trigger this delivery was routed to.
  TextColumn get triggerId => text().references(
    PipelineTriggersTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Delivery status: a `WebhookDeliveryStatus` name.
  TextColumn get status => text().check(
    // ignore: recursive_getters
    status.isIn(AgentsStoredValues.webhookDeliveryStatus),
  )();

  /// Signature verification: a `WebhookSignatureStatus` name.
  TextColumn get signatureStatus => text().check(
    // ignore: recursive_getters
    signatureStatus.isIn(AgentsStoredValues.webhookSignatureStatus),
  )();

  /// Idempotency key extracted from the request, if any.
  TextColumn get dedupeKey => text().nullable()();

  /// Where [dedupeKey] came from (e.g. the header name).
  TextColumn get dedupeSource => text().nullable()();

  /// The declared event action (e.g. `push`), matched against event filters.
  TextColumn get eventAction => text().nullable()();

  /// JSON object of the allow-listed request headers (content type, user
  /// agent, the provider's event and delivery-id headers). Never credentials,
  /// cookies or signatures.
  TextColumn get headersJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(headersJson))
      .withDefault(const Constant('{}'))();

  /// HTTP status the server replied with.
  IntColumn get responseStatus => integer().nullable()();

  /// Response body the server replied with.
  TextColumn get responseBody => text().nullable()();

  /// The pipeline run this delivery started, if any. `SET NULL`: the log
  /// outlives a pruned run.
  TextColumn get runId => text().nullable().references(
    PipelineRunsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// When the delivery was received.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'webhook_deliveries';

  @override
  Set<Column> get primaryKey => {id};
}
