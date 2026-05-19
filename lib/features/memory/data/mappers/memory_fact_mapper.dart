import 'dart:convert';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';

class MemoryFactMapper {
  const MemoryFactMapper();

  MemoryFact toDomain(db.MemoryFactsTableData row) {
    final sourceIds = (row.sourceObservationIds.isNotEmpty)
        ? List<String>.from(jsonDecode(row.sourceObservationIds) as List)
        : <String>[];
    return MemoryFact(
      id: row.id,
      workspaceId: row.workspaceId,
      domain: row.domain,
      topic: row.topic,
      content: row.content,
      sourceObservationIds: sourceIds,
      confidence: row.confidence,
      supersededBy: row.supersededBy,
      authoredByAgentId: row.authoredByAgentId,
      authoredByRole: AgentRole.tryParse(row.authoredByRole),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
