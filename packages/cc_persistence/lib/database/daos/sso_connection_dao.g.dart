// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sso_connection_dao.dart';

// ignore_for_file: type=lint
mixin _$SsoConnectionDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $SsoConnectionsTableTable get ssoConnectionsTable =>
      attachedDatabase.ssoConnectionsTable;
  SsoConnectionDaoManager get managers => SsoConnectionDaoManager(this);
}

class SsoConnectionDaoManager {
  final _$SsoConnectionDaoMixin _db;
  SsoConnectionDaoManager(this._db);
  $$SsoConnectionsTableTableTableManager get ssoConnectionsTable =>
      $$SsoConnectionsTableTableTableManager(
        _db.attachedDatabase,
        _db.ssoConnectionsTable,
      );
}
