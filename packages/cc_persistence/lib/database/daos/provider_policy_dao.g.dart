// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_policy_dao.dart';

// ignore_for_file: type=lint
mixin _$ProviderPolicyDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ProviderPoliciesTableTable get providerPoliciesTable =>
      attachedDatabase.providerPoliciesTable;
  ProviderPolicyDaoManager get managers => ProviderPolicyDaoManager(this);
}

class ProviderPolicyDaoManager {
  final _$ProviderPolicyDaoMixin _db;
  ProviderPolicyDaoManager(this._db);
  $$ProviderPoliciesTableTableTableManager get providerPoliciesTable =>
      $$ProviderPoliciesTableTableTableManager(
        _db.attachedDatabase,
        _db.providerPoliciesTable,
      );
}
