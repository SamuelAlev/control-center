import 'package:cc_domain/core/domain/entities/episodic_edge.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

/// Maps [db.EpisodicEdgesTableData] rows to [EpisodicEdge] entities.
class EpisodicEdgeMapper {
  /// Creates a const [EpisodicEdgeMapper].
  const EpisodicEdgeMapper();

  /// Converts a row to an [EpisodicEdge].
  EpisodicEdge toDomain(db.EpisodicEdgesTableData row) => EpisodicEdge(
        id: row.id,
        workspaceId: row.workspaceId,
        sourceFactId: row.sourceFactId,
        targetFactId: row.targetFactId,
        edgeType: row.edgeType,
        weight: row.weight,
        createdAt: row.createdAt,
      );
}