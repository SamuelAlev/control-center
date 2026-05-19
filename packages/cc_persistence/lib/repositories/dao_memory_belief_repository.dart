import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_belief.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_belief_repository.dart';
import 'package:cc_persistence/database/daos/memory_belief_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/memory_belief_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for harmonized beliefs.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).memoryBeliefDao` per call: beliefs live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoMemoryBeliefRepository implements MemoryBeliefRepository {
  /// Creates a [DaoMemoryBeliefRepository] over the per-workspace databases.
  DaoMemoryBeliefRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final MemoryBeliefMapper _mapper = const MemoryBeliefMapper();

  MemoryBeliefDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).memoryBeliefDao;

  @override
  Future<void> replaceWorkspace(
    String workspaceId,
    List<MemoryBelief> beliefs,
  ) => _dao(workspaceId).replaceWorkspace(workspaceId, [
    for (final b in beliefs)
      db.MemoryBeliefsTableCompanion(
        id: Value(b.id),
        workspaceId: Value(b.workspaceId),
        topic: Value(b.topic),
        content: Value(b.content),
        confidence: Value(b.confidence),
        harmonyScore: Value(b.harmonyScore),
        provenanceFactIds: Value(jsonEncode(b.provenanceFactIds)),
        provenanceAgentIds: Value(jsonEncode(b.provenanceAgentIds)),
        clusterId: Value(b.clusterId),
        action: Value(b.action),
        createdAt: Value(b.createdAt),
        updatedAt: Value(b.updatedAt),
      ),
  ]);

  @override
  Stream<List<MemoryBelief>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<MemoryBelief>> getByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .getByWorkspace(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());
}
