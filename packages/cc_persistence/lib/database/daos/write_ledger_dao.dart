import 'package:cc_persistence/database/tables/write_ledger_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'write_ledger_dao.g.dart';

/// Data access for the universal idempotency ledger (PRD 19 §3). Workspace-
/// scoped: the composite key is `(workspace_id, idempotency_key)`.
@DriftAccessor(tables: [WriteLedgerTable])
class WriteLedgerDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$WriteLedgerDaoMixin {
  /// Creates a [WriteLedgerDao].
  WriteLedgerDao(super.db);

  /// The recorded entry for `(workspaceId, key)`, or null.
  Future<WriteLedgerTableData?> find(String workspaceId, String key) =>
      (select(writeLedgerTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.idempotencyKey.equals(key),
          ))
          .getSingleOrNull();

  /// Records a completed mutation. Idempotent on `(workspaceId, key)` — a
  /// concurrent double-apply keeps the first row (insert-or-ignore) so the two
  /// racers still converge on one stored result.
  Future<void> record(WriteLedgerTableCompanion entry) =>
      into(writeLedgerTable).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Prunes entries older than [cutoff]. Returns the number of rows deleted.
  Future<int> deleteOlderThan(DateTime cutoff) => (delete(
    writeLedgerTable,
  )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
}
