import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_belief.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_belief_repository.dart';
import 'package:cc_persistence/database/app_database.dart' as db;
import 'package:cc_persistence/database/daos/memory_belief_dao.dart';
import 'package:cc_persistence/mappers/memory_belief_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for harmonized beliefs.
class DaoMemoryBeliefRepository implements MemoryBeliefRepository {
  /// Creates a [DaoMemoryBeliefRepository].
  DaoMemoryBeliefRepository(this._dao);

  final MemoryBeliefDao _dao;
  final MemoryBeliefMapper _mapper = const MemoryBeliefMapper();

  @override
  Future<void> replaceWorkspace(
    String workspaceId,
    List<MemoryBelief> beliefs,
  ) =>
      _dao.replaceWorkspace(
        workspaceId,
        [
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
        ],
      );

  @override
  Stream<List<MemoryBelief>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Future<List<MemoryBelief>> getByWorkspace(String workspaceId) =>
      _dao.getByWorkspace(workspaceId).then(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );
}