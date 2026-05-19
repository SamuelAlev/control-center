// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dao.dart';

// ignore_for_file: type=lint
mixin _$TicketDaoMixin on DatabaseAccessor<AppDatabase> {
  $TicketsTableTable get ticketsTable => attachedDatabase.ticketsTable;
  $TicketCollaboratorsTableTable get ticketCollaboratorsTable =>
      attachedDatabase.ticketCollaboratorsTable;
  TicketDaoManager get managers => TicketDaoManager(this);
}

class TicketDaoManager {
  final _$TicketDaoMixin _db;
  TicketDaoManager(this._db);
  $$TicketsTableTableTableManager get ticketsTable =>
      $$TicketsTableTableTableManager(_db.attachedDatabase, _db.ticketsTable);
  $$TicketCollaboratorsTableTableTableManager get ticketCollaboratorsTable =>
      $$TicketCollaboratorsTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketCollaboratorsTable,
      );
}
