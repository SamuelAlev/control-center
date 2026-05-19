// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_ledger_dao.dart';

// ignore_for_file: type=lint
mixin _$WriteLedgerDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $WriteLedgerTableTable get writeLedgerTable =>
      attachedDatabase.writeLedgerTable;
  WriteLedgerDaoManager get managers => WriteLedgerDaoManager(this);
}

class WriteLedgerDaoManager {
  final _$WriteLedgerDaoMixin _db;
  WriteLedgerDaoManager(this._db);
  $$WriteLedgerTableTableTableManager get writeLedgerTable =>
      $$WriteLedgerTableTableTableManager(
        _db.attachedDatabase,
        _db.writeLedgerTable,
      );
}
