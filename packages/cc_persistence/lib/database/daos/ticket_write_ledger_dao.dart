import 'package:cc_persistence/database/tables/ticket_write_ledger_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'ticket_write_ledger_dao.g.dart';

/// Data access for the agent-write idempotency ledger. Workspace-scoped: the
/// composite key is `(workspace_id, write_id)`.
@DriftAccessor(tables: [TicketWriteLedgerTable])
class TicketWriteLedgerDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$TicketWriteLedgerDaoMixin {
  /// Creates a [TicketWriteLedgerDao].
  TicketWriteLedgerDao(super.db);

  /// The recorded entry for `(workspaceId, writeId)`, or null.
  Future<TicketWriteLedgerTableData?> find(
    String workspaceId,
    String writeId,
  ) =>
      (select(ticketWriteLedgerTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.writeId.equals(writeId),
          ))
          .getSingleOrNull();

  /// Records a completed write. Idempotent on `(workspaceId, writeId)`.
  Future<void> record(TicketWriteLedgerTableCompanion entry) =>
      into(ticketWriteLedgerTable).insertOnConflictUpdate(entry);
}
