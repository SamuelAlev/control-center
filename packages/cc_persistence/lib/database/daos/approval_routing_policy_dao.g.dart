// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_routing_policy_dao.dart';

// ignore_for_file: type=lint
mixin _$ApprovalRoutingPolicyDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ApprovalRoutingPoliciesTableTable get approvalRoutingPoliciesTable =>
      attachedDatabase.approvalRoutingPoliciesTable;
  ApprovalRoutingPolicyDaoManager get managers =>
      ApprovalRoutingPolicyDaoManager(this);
}

class ApprovalRoutingPolicyDaoManager {
  final _$ApprovalRoutingPolicyDaoMixin _db;
  ApprovalRoutingPolicyDaoManager(this._db);
  $$ApprovalRoutingPoliciesTableTableTableManager
  get approvalRoutingPoliciesTable =>
      $$ApprovalRoutingPoliciesTableTableTableManager(
        _db.attachedDatabase,
        _db.approvalRoutingPoliciesTable,
      );
}
