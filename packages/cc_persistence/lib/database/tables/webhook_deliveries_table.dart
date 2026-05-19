import 'package:drift/drift.dart';

/// Full log of inbound webhook deliveries: the raw request, its signature
/// verification outcome and what the server did with it.
@TableIndex(name: 'idx_webhook_deliveries_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_webhook_deliveries_trigger', columns: {#triggerId})
@TableIndex(
  name: 'idx_webhook_deliveries_dedupe',
  columns: {#triggerId, #dedupeKey},
)
class WebhookDeliveriesTable extends Table {
  /// Unique delivery id.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The trigger this delivery was routed to.
  TextColumn get triggerId => text()();

  /// Delivery status: `queued` | `dispatched` | `rejected` | `ignored` |
  /// `failed`.
  TextColumn get status => text()();

  /// Signature verification: `valid` | `invalid` | `missing` | `skipped`.
  TextColumn get signatureStatus => text()();

  /// Idempotency key extracted from the request, if any.
  TextColumn get dedupeKey => text().nullable()();

  /// Where [dedupeKey] came from (e.g. the header name).
  TextColumn get dedupeSource => text().nullable()();

  /// The declared event action (e.g. `push`), matched against event filters.
  TextColumn get eventAction => text().nullable()();

  /// The raw request body.
  TextColumn get rawBody => text().nullable()();

  /// JSON object of request headers.
  TextColumn get headersJson => text().withDefault(const Constant('{}'))();

  /// HTTP status the server replied with.
  IntColumn get responseStatus => integer().nullable()();

  /// Response body the server replied with.
  TextColumn get responseBody => text().nullable()();

  /// The pipeline run this delivery started, if any.
  TextColumn get runId => text().nullable()();

  /// When the delivery was received.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
