import 'dart:convert';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';

/// Maps [db.MemoryFactsTableData] rows to [MemoryFact] domain entities.
class MemoryFactMapper {
  /// Creates a const [MemoryFactMapper].
  const MemoryFactMapper();

  /// Converts a [db.MemoryFactsTableData] row to a [MemoryFact].
  MemoryFact toDomain(db.MemoryFactsTableData row) {
    final decoded = row.sourceObservationIds.isNotEmpty
        ? jsonDecode(row.sourceObservationIds)
        : null;
    final sourceIds = decoded is List ? List<String>.from(decoded) : <String>[];
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
