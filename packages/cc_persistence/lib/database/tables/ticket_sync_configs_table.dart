import 'package:drift/drift.dart';

/// A workspace's sync connection to one external vendor (Linear / Jira / GitHub
/// Issues). Workspace-scoped; one row per `(workspace_id, vendor)`.
///
/// The credential itself is never stored here — only [credentialRef], which the
/// infra layer resolves against the secure store. [fieldMapping] holds the
/// per-field conflict policy JSON; [webhookSecret] is the shared secret used to
/// verify inbound webhook signatures.
@TableIndex(
  name: 'uq_ticket_sync_configs_ws_vendor',
  columns: {#workspaceId, #vendor},
  unique: true,
)
class TicketSyncConfigsTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// Vendor identifier (`linear` | `jira` | `github`).
  TextColumn get vendor => text()();

  /// Vendor-side project / board / repo identifier.
  TextColumn get vendorProjectId => text().withDefault(const Constant(''))();

  /// Allowed sync direction (`push` | `pull` | `bidirectional`).
  TextColumn get direction =>
      text().withDefault(const Constant('bidirectional'))();

  /// Per-field conflict-resolution policy, as JSON.
  TextColumn get fieldMapping => text().withDefault(const Constant('{}'))();

  /// Opaque reference to the vendor credential (never the secret).
  TextColumn get credentialRef => text().nullable()();

  /// Shared secret for verifying inbound webhook signatures.
  TextColumn get webhookSecret => text().nullable()();

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
