// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_audit_dao.dart';

// ignore_for_file: type=lint
mixin _$ServerAuditDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $ServerAuditTableTable get serverAuditTable =>
      attachedDatabase.serverAuditTable;
  ServerAuditDaoManager get managers => ServerAuditDaoManager(this);
}

class ServerAuditDaoManager {
  final _$ServerAuditDaoMixin _db;
  ServerAuditDaoManager(this._db);
  $$ServerAuditTableTableTableManager get serverAuditTable =>
      $$ServerAuditTableTableTableManager(
        _db.attachedDatabase,
        _db.serverAuditTable,
      );
}
