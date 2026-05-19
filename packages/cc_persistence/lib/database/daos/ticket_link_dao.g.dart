// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_link_dao.dart';

// ignore_for_file: type=lint
mixin _$TicketLinkDaoMixin on DatabaseAccessor<AppDatabase> {
  $TicketLinksTableTable get ticketLinksTable =>
      attachedDatabase.ticketLinksTable;
  TicketLinkDaoManager get managers => TicketLinkDaoManager(this);
}

class TicketLinkDaoManager {
  final _$TicketLinkDaoMixin _db;
  TicketLinkDaoManager(this._db);
  $$TicketLinksTableTableTableManager get ticketLinksTable =>
      $$TicketLinksTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketLinksTable,
      );
}
