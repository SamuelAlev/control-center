// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_action_policy_dao.dart';

// ignore_for_file: type=lint
mixin _$ManagedActionPolicyDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $UsersTableTable get usersTable => attachedDatabase.usersTable;
  $ManagedActionPoliciesTableTable get managedActionPoliciesTable =>
      attachedDatabase.managedActionPoliciesTable;
  ManagedActionPolicyDaoManager get managers =>
      ManagedActionPolicyDaoManager(this);
}

class ManagedActionPolicyDaoManager {
  final _$ManagedActionPolicyDaoMixin _db;
  ManagedActionPolicyDaoManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db.attachedDatabase, _db.usersTable);
  $$ManagedActionPoliciesTableTableTableManager
  get managedActionPoliciesTable =>
      $$ManagedActionPoliciesTableTableTableManager(
        _db.attachedDatabase,
        _db.managedActionPoliciesTable,
      );
}
