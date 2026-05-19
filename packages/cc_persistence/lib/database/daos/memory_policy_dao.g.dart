// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_policy_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryPolicyDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $MemoryPoliciesTableTable get memoryPoliciesTable =>
      attachedDatabase.memoryPoliciesTable;
  MemoryPolicyDaoManager get managers => MemoryPolicyDaoManager(this);
}

class MemoryPolicyDaoManager {
  final _$MemoryPolicyDaoMixin _db;
  MemoryPolicyDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$MemoryPoliciesTableTableTableManager get memoryPoliciesTable =>
      $$MemoryPoliciesTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryPoliciesTable,
      );
}
