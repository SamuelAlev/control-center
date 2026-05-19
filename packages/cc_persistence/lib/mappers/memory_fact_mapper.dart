import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

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
    final tagsRaw = row.temporalTags;
    final tagsDecoded =
        (tagsRaw != null && tagsRaw.isNotEmpty) ? jsonDecode(tagsRaw) : null;
    final temporalTags =
        tagsDecoded is List ? List<String>.from(tagsDecoded) : <String>[];
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
      memoryType: MemoryType.parse(row.memoryType),
      veracity: MemoryVeracity.parse(row.veracity),
      validUntil: row.validUntil,
      recallCount: row.recallCount,
      lastRecalledAt: row.lastRecalledAt,
      temporalTags: temporalTags,
      mentionCount: row.mentionCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}