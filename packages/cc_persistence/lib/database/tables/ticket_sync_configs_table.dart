import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// A workspace's sync connection to one external vendor (Linear / Jira / GitHub
/// Issues). Workspace-scoped; one row per vendor, which
/// `uq_ticket_sync_configs_vendor` holds and `TicketSyncDao.upsertConfig`
/// writes against.
///
/// The credential itself is never stored here — only [credentialRef], which the
/// infra layer resolves against the secure store. [fieldMapping] holds the
/// per-field conflict policy JSON; [webhookSecretRef] names where the shared
/// secret that verifies inbound webhook signatures is kept in the server's
/// secrets store, so no snapshot or export of this file carries it.
@TableIndex(
  name: 'uq_ticket_sync_configs_vendor',
  columns: {#vendor},
  unique: true,
)
class TicketSyncConfigsTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// Vendor identifier (`linear` | `jira` | `github`). Open set: the ids of
  /// the registered sync adapters.
  TextColumn get vendor => text()();

  /// Vendor-side project / board / repo identifier.
  TextColumn get vendorProjectId => text().withDefault(const Constant(''))();

  /// Allowed sync direction: a `SyncDirection` name.
  TextColumn get direction => text()
      .check(
        // ignore: recursive_getters
        direction.isIn(AgentsStoredValues.syncDirection),
      )
      .withDefault(const Constant('bidirectional'))();

  /// Per-field conflict-resolution policy, as a JSON object.
  TextColumn get fieldMapping => text()
      // ignore: recursive_getters
      .check(isJsonObject(fieldMapping))
      .withDefault(const Constant('{}'))();

  /// Opaque reference to the vendor credential (never the secret).
  TextColumn get credentialRef => text().nullable()();

  /// Secrets-store reference of the shared secret that verifies inbound
  /// webhook signatures (`WebhookSecretVault.ticketSyncRef`); never the secret.
  /// Null when none is configured.
  TextColumn get webhookSecretRef => text().nullable()();

  /// Whether the connection is active.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last-modified timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'ticket_sync_configs';

  @override
  Set<Column> get primaryKey => {id};
}
