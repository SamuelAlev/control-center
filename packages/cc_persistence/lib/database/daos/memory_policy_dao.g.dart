// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_policy_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryPolicyDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $MemoryPoliciesTableTable get memoryPoliciesTable =>
      attachedDatabase.memoryPoliciesTable;
  MemoryPolicyDaoManager get managers => MemoryPolicyDaoManager(this);
}

class MemoryPolicyDaoManager {
  final _$MemoryPolicyDaoMixin _db;
  MemoryPolicyDaoManager(this._db);
  $$MemoryPoliciesTableTableTableManager get memoryPoliciesTable =>
      $$MemoryPoliciesTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryPoliciesTable,
      );
}
