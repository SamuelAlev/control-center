import 'dart:convert';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';

class MemoryPolicyMapper {
  const MemoryPolicyMapper();

  MemoryPolicy toDomain(db.MemoryPoliciesTableData row) {
    final factIds = (row.sourceFactIds.isNotEmpty)
        ? List<String>.from(jsonDecode(row.sourceFactIds) as List)
        : <String>[];
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
