// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_sync_dao.dart';

// ignore_for_file: type=lint
mixin _$TicketSyncDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $TicketSyncConfigsTableTable get ticketSyncConfigsTable =>
      attachedDatabase.ticketSyncConfigsTable;
  $TicketSyncLinksTableTable get ticketSyncLinksTable =>
      attachedDatabase.ticketSyncLinksTable;
  $TicketSyncLogTableTable get ticketSyncLogTable =>
      attachedDatabase.ticketSyncLogTable;
  TicketSyncDaoManager get managers => TicketSyncDaoManager(this);
}

class TicketSyncDaoManager {
  final _$TicketSyncDaoMixin _db;
  TicketSyncDaoManager(this._db);
  $$TicketSyncConfigsTableTableTableManager get ticketSyncConfigsTable =>
      $$TicketSyncConfigsTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketSyncConfigsTable,
      );
  $$TicketSyncLinksTableTableTableManager get ticketSyncLinksTable =>
      $$TicketSyncLinksTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketSyncLinksTable,
      );
  $$TicketSyncLogTableTableTableManager get ticketSyncLogTable =>
      $$TicketSyncLogTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketSyncLogTable,
      );
}
