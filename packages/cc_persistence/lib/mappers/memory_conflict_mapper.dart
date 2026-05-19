import 'package:cc_domain/core/domain/entities/memory_conflict.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

/// Maps [db.MemoryConflictsTableData] rows to [MemoryConflict] entities.
class MemoryConflictMapper {
  /// Creates a const [MemoryConflictMapper].
  const MemoryConflictMapper();

  /// Converts a row to a [MemoryConflict].
  MemoryConflict toDomain(db.MemoryConflictsTableData row) => MemoryConflict(
        id: row.id,
        workspaceId: row.workspaceId,
        factAId: row.factAId,
        factBId: row.factBId,
        conflictType: row.conflictType,
        resolution: row.resolution,
        winningFactId: row.winningFactId,
        resolvedAt: row.resolvedAt,
        createdAt: row.createdAt,
      );
}