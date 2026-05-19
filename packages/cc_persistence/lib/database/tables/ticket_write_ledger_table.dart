import 'package:drift/drift.dart';

/// Idempotency ledger for agent ticket writes. A completed write keyed by its
/// `write_id` is recorded here so a retry replays the cached result instead of
/// applying the change twice. Workspace-scoped: a `write_id` is unique per
/// workspace, so the composite primary key is `(workspace_id, write_id)`.
class TicketWriteLedgerTable extends Table {
  /// Workspace scope.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// Caller-supplied idempotency token (UUID).
  TextColumn get writeId => text()();

  /// The operation that ran (e.g. `comment_add`, `status_set`).
  TextColumn get operation => text()();

  /// JSON-encoded result that was returned.
  TextColumn get resultJson => text()();

  /// When the write completed.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'ticket_write_ledger';

  @override
  Set<Column> get primaryKey => {workspaceId, writeId};
}
