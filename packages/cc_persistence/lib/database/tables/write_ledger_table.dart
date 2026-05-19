import 'package:drift/drift.dart';

/// The universal idempotency ledger (PRD 19 §3): one row per completed
/// mutating `repo/call` that carried an idempotency key. A retry with the same
/// key replays the stored result instead of applying the change twice.
///
/// Workspace-scoped — a key is unique per workspace — so the composite primary
/// key is `(workspace_id, idempotency_key)`. Pruned to a bounded window by
/// `DatabaseRetentionService`. Generalizes the ticketing `write_ledger`
/// (`ticket_write_ledger`) to every dispatcher mutation.
class WriteLedgerTable extends Table {
  /// Workspace scope.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// Client-minted key for one logical action (UUIDv7).
  TextColumn get idempotencyKey => text()();

  /// The op that ran (e.g. `tickets.assign`).
  TextColumn get opName => text()();

  /// JSON-encoded result `data` envelope that was returned on first apply.
  TextColumn get resultJson => text()();

  /// When the mutation completed.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'write_ledger';

  @override
  Set<Column> get primaryKey => {workspaceId, idempotencyKey};
}
