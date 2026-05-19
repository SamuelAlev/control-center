import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_belief.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

/// Maps [db.MemoryBeliefsTableData] rows to [MemoryBelief] entities.
class MemoryBeliefMapper {
  /// Creates a const [MemoryBeliefMapper].
  const MemoryBeliefMapper();

  /// Converts a row to a [MemoryBelief].
  MemoryBelief toDomain(db.MemoryBeliefsTableData row) {
    return MemoryBelief(
      id: row.id,
      workspaceId: row.workspaceId,
      topic: row.topic,
      content: row.content,
      confidence: row.confidence,
      harmonyScore: row.harmonyScore,
      provenanceFactIds: _decodeList(row.provenanceFactIds),
      provenanceAgentIds: _decodeList(row.provenanceAgentIds),
      clusterId: row.clusterId,
      action: row.action,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  List<String> _decodeList(String raw) {
    if (raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    return decoded is List ? List<String>.from(decoded) : const [];
  }
}