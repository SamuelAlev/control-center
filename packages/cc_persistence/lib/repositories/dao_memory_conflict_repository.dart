import 'package:cc_domain/core/domain/entities/memory_conflict.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_conflict_repository.dart';
import 'package:cc_persistence/database/daos/memory_conflict_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/memory_conflict_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory conflicts.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).memoryConflictDao` per call: conflicts live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoMemoryConflictRepository implements MemoryConflictRepository {
  /// Creates a [DaoMemoryConflictRepository] over the per-workspace databases.
  DaoMemoryConflictRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final MemoryConflictMapper _mapper = const MemoryConflictMapper();

  MemoryConflictDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).memoryConflictDao;

  @override
  Future<void> record(MemoryConflict conflict) =>
      _dao(conflict.workspaceId).upsert(
        db.MemoryConflictsTableCompanion(
          id: Value(conflict.id),
          workspaceId: Value(conflict.workspaceId),
          factAId: Value(conflict.factAId),
          factBId: Value(conflict.factBId),
          conflictType: Value(conflict.conflictType),
          resolution: Value(conflict.resolution),
          winningFactId: Value(conflict.winningFactId),
          resolvedAt: Value(conflict.resolvedAt),
          createdAt: Value(conflict.createdAt),
        ),
      );

  @override
  Stream<List<MemoryConflict>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<MemoryConflict>> getByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .getByWorkspace(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<MemoryConflict>> getUnresolved(String workspaceId) =>
      _dao(workspaceId)
          .getUnresolved(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());
}
