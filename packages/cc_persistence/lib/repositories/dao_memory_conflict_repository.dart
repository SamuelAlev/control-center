import 'package:cc_domain/core/domain/entities/memory_conflict.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_conflict_repository.dart';
import 'package:cc_persistence/database/app_database.dart' as db;
import 'package:cc_persistence/database/daos/memory_conflict_dao.dart';
import 'package:cc_persistence/mappers/memory_conflict_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory conflicts.
class DaoMemoryConflictRepository implements MemoryConflictRepository {
  /// Creates a [DaoMemoryConflictRepository].
  DaoMemoryConflictRepository(this._dao);

  final MemoryConflictDao _dao;
  final MemoryConflictMapper _mapper = const MemoryConflictMapper();

  @override
  Future<void> record(MemoryConflict conflict) => _dao.upsert(
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
      _dao.watchByWorkspace(workspaceId).map(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Future<List<MemoryConflict>> getByWorkspace(String workspaceId) =>
      _dao.getByWorkspace(workspaceId).then(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Future<List<MemoryConflict>> getUnresolved(String workspaceId) =>
      _dao.getUnresolved(workspaceId).then(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );
}