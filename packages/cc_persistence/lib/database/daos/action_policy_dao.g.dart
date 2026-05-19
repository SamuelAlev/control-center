// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_policy_dao.dart';

// ignore_for_file: type=lint
mixin _$ActionPolicyDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ActionPoliciesTableTable get actionPoliciesTable =>
      attachedDatabase.actionPoliciesTable;
  ActionPolicyDaoManager get managers => ActionPolicyDaoManager(this);
}

class ActionPolicyDaoManager {
  final _$ActionPolicyDaoMixin _db;
  ActionPolicyDaoManager(this._db);
  $$ActionPoliciesTableTableTableManager get actionPoliciesTable =>
      $$ActionPoliciesTableTableTableManager(
        _db.attachedDatabase,
        _db.actionPoliciesTable,
      );
}
