// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_write_ledger_dao.dart';

// ignore_for_file: type=lint
mixin _$TicketWriteLedgerDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $TicketWriteLedgerTableTable get ticketWriteLedgerTable =>
      attachedDatabase.ticketWriteLedgerTable;
  TicketWriteLedgerDaoManager get managers => TicketWriteLedgerDaoManager(this);
}

class TicketWriteLedgerDaoManager {
  final _$TicketWriteLedgerDaoMixin _db;
  TicketWriteLedgerDaoManager(this._db);
  $$TicketWriteLedgerTableTableTableManager get ticketWriteLedgerTable =>
      $$TicketWriteLedgerTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketWriteLedgerTable,
      );
}
