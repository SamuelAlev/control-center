import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

/// Maps [db.MemoryPoliciesTableData] rows to [MemoryPolicy] domain entities.
class MemoryPolicyMapper {
  /// Creates a const [MemoryPolicyMapper].
  const MemoryPolicyMapper();

  /// Converts a [db.MemoryPoliciesTableData] row to a [MemoryPolicy].
  MemoryPolicy toDomain(db.MemoryPoliciesTableData row) {
    final decoded = row.sourceFactIds.isNotEmpty
        ? jsonDecode(row.sourceFactIds)
        : null;
    final factIds = decoded is List ? List<String>.from(decoded) : <String>[];
    return MemoryPolicy(
      id: row.id,
      workspaceId: row.workspaceId,
      domain: row.domain,
      rule: row.rule,
      sourceFactIds: factIds,
      requiredRole: AgentRole.tryParse(row.requiredRole),
      active: row.active,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
