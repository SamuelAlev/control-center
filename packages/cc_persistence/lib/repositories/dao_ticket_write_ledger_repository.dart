import 'package:cc_domain/features/ticketing/domain/writes/ticket_write_ledger.dart';
import 'package:cc_persistence/database/daos/ticket_write_ledger_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [TicketWriteLedgerRepository].
///
/// The ledger is per-workspace, so a `writeId` is only ever replayed against
/// the workspace that recorded it: the id resolves inside that workspace's
/// database file and nowhere else.
class DaoTicketWriteLedgerRepository implements TicketWriteLedgerRepository {
  /// Creates a [DaoTicketWriteLedgerRepository] over the per-workspace
  /// databases.
  DaoTicketWriteLedgerRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  TicketWriteLedgerDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).ticketWriteLedgerDao;

  @override
  Future<TicketWriteLedgerEntry?> find(
    String workspaceId,
    String writeId,
  ) async {
    final row = await _dao(workspaceId).find(workspaceId, writeId);
    if (row == null) {
      return null;
    }
    return TicketWriteLedgerEntry(
      workspaceId: row.workspaceId,
      writeId: row.writeId,
      operation: row.operation,
      resultJson: row.resultJson,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<void> record(TicketWriteLedgerEntry entry) =>
      _dao(entry.workspaceId).record(
        TicketWriteLedgerTableCompanion(
          workspaceId: Value(entry.workspaceId),
          writeId: Value(entry.writeId),
          operation: Value(entry.operation),
          resultJson: Value(entry.resultJson),
          createdAt: Value(entry.createdAt),
        ),
      );
}
