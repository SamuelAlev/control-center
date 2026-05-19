import 'package:cc_domain/core/domain/entities/working_memory_item.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

/// Maps [db.WorkingMemoryItemsTableData] rows to [WorkingMemoryItem] entities.
class WorkingMemoryItemMapper {
  /// Creates a const [WorkingMemoryItemMapper].
  const WorkingMemoryItemMapper();

  /// Converts a row to a [WorkingMemoryItem].
  WorkingMemoryItem toDomain(db.WorkingMemoryItemsTableData row) =>
      WorkingMemoryItem(
        id: row.id,
        workspaceId: row.workspaceId,
        agentId: row.agentId,
        content: row.content,
        sessionId: row.sessionId,
        memoryType: MemoryType.parse(row.memoryType),
        veracity: MemoryVeracity.parse(row.veracity),
        importance: row.importance,
        createdAt: row.createdAt,
        expiresAt: row.expiresAt,
      );
}