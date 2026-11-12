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

  /// The entry for `(workspaceId, key)`, claimed or completed, or null.
  Future<WriteLedgerTableData?> find(String workspaceId, String key) =>
      (select(writeLedgerTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.idempotencyKey.equals(key),
          ))
          .getSingleOrNull();

  /// Claims `(workspaceId, key)` by inserting [entry] (with no result) only if
  /// no row holds the key yet. Returns whether this call inserted it: false
  /// means another call claimed or completed the key first.
  Future<bool> claim(WriteLedgerTableCompanion entry) async =>
      await into(
        writeLedgerTable,
      ).insertReturningOrNull(entry, mode: InsertMode.insertOrIgnore) !=
      null;

  /// Stores [resultJson] on the claimed key. Returns false when no unfinished
  /// claim holds it (it was released, dropped or already completed).
  Future<bool> complete(
    String workspaceId,
    String key,
    String resultJson,
    DateTime completedAt,
  ) async =>
      await (update(writeLedgerTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.idempotencyKey.equals(key) &
                t.resultJson.isNull(),
          ))
          .write(
            WriteLedgerTableCompanion(
              resultJson: Value(resultJson),
              createdAt: Value(completedAt),
            ),
          ) !=
      0;

  /// Releases an unfinished claim on `(workspaceId, key)` so a retry can run
  /// the handler. A completed row is never released.
  Future<int> release(String workspaceId, String key) =>
      (delete(writeLedgerTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.idempotencyKey.equals(key) &
                t.resultJson.isNull(),
          ))
          .go();

  /// Drops every unfinished claim in [workspaceId]. Returns the rows deleted.
  Future<int> dropUnfinished(String workspaceId) =>
      (delete(writeLedgerTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.resultJson.isNull(),
          ))
          .go();

  /// Prunes entries older than [cutoff]. Returns the number of rows deleted.
  Future<int> deleteOlderThan(DateTime cutoff) => (delete(
    writeLedgerTable,
  )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
}
