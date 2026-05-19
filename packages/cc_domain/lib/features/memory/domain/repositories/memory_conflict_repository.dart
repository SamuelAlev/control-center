import 'package:cc_domain/core/domain/entities/memory_conflict.dart';

/// Repository for [MemoryConflict] persistence (workspace-scoped).
abstract class MemoryConflictRepository {
  /// Records (inserts or updates) a conflict.
  Future<void> record(MemoryConflict conflict);

  /// Watches conflicts in a workspace, newest first.
  Stream<List<MemoryConflict>> watchByWorkspace(String workspaceId);

  /// Reads conflicts in a workspace, newest first.
  Future<List<MemoryConflict>> getByWorkspace(String workspaceId);

  /// Reads unresolved conflicts in a workspace.
  Future<List<MemoryConflict>> getUnresolved(String workspaceId);
}