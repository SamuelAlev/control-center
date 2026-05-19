import 'dart:convert';

import 'package:cc_domain/features/governance/domain/repositories/approval_routing_policy_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Drift-backed [ApprovalRoutingPolicyRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves the DAO per call, so the
/// workspace id picks the database file before any SQL runs.
class DaoApprovalRoutingPolicyRepository
    implements ApprovalRoutingPolicyRepository {
  /// Creates a [DaoApprovalRoutingPolicyRepository] over the per-workspace
  /// databases.
  DaoApprovalRoutingPolicyRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<ApprovalRoutingPolicy?> get(String workspaceId) async {
    final raw = await _dbs
        .of(workspaceId)
        .approvalRoutingPolicyDao
        .read(workspaceId);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? ApprovalRoutingPolicy.fromJson(decoded)
          : null;
    } catch (_) {
      // A malformed row reads as unset; callers fall back to defaults rather
      // than failing every sweep forever.
      return null;
    }
  }

  @override
  Future<void> set(String workspaceId, ApprovalRoutingPolicy policy) => _dbs
      .of(workspaceId)
      .approvalRoutingPolicyDao
      .write(workspaceId, jsonEncode(policy.toJson()));
}
