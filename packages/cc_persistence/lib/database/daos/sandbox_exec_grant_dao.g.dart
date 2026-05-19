// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sandbox_exec_grant_dao.dart';

// ignore_for_file: type=lint
mixin _$SandboxExecGrantDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SandboxExecGrantsTableTable get sandboxExecGrantsTable =>
      attachedDatabase.sandboxExecGrantsTable;
  SandboxExecGrantDaoManager get managers => SandboxExecGrantDaoManager(this);
}

class SandboxExecGrantDaoManager {
  final _$SandboxExecGrantDaoMixin _db;
  SandboxExecGrantDaoManager(this._db);
  $$SandboxExecGrantsTableTableTableManager get sandboxExecGrantsTable =>
      $$SandboxExecGrantsTableTableTableManager(
        _db.attachedDatabase,
        _db.sandboxExecGrantsTable,
      );
}
