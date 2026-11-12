import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:drift/drift.dart';

/// The universal idempotency ledger (PRD 19 §3): one row per mutating
/// `repo/call` that carried an idempotency key. The row is claimed (inserted
/// with no result) before the handler runs and completed with the result once
/// it returns, so a concurrent duplicate sees the claim and never runs the
/// handler a second time; a later retry replays the stored result.
///
/// Workspace-scoped — a key is unique per workspace — so the composite primary
/// key is `(idempotency_key, workspace_id)`. Pruned to a bounded window by
/// `DatabaseRetentionService`, which deletes by [createdAt]. Generalizes the
/// ticketing `write_ledger` (`ticket_write_ledger`) to every dispatcher
/// mutation.
@TableIndex(name: 'idx_write_ledger_created', columns: {#createdAt})
class WriteLedgerTable extends Table {
  /// Workspace scope.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// Client-minted key for one logical action (UUIDv7).
  TextColumn get idempotencyKey => text()();

  /// The op that ran (e.g. `tickets.assign`).
  TextColumn get opName => text()();

  /// JSON-encoded result `data` envelope that was returned on first apply.
  /// Null while the call that claimed the key is still running.
  TextColumn get resultJson =>
      // ignore: recursive_getters
      text().nullable().check(isJson(resultJson))();

  /// When the key was claimed, then when the mutation completed.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'write_ledger';

  @override
  Set<Column> get primaryKey => {idempotencyKey, workspaceId};
}
