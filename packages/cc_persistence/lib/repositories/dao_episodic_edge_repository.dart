import 'package:cc_domain/core/domain/entities/episodic_edge.dart';
import 'package:cc_domain/features/memory/domain/repositories/episodic_edge_repository.dart';
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/episodic_edge_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for episodic edges.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).episodicEdgeDao` per call: an episodic edge joins two
/// facts inside one workspace, so both endpoints and the edge itself live in
/// that workspace's own database file.
class DaoEpisodicEdgeRepository implements EpisodicEdgeRepository {
  /// Creates a [DaoEpisodicEdgeRepository] over the per-workspace databases.
  DaoEpisodicEdgeRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final EpisodicEdgeMapper _mapper = const EpisodicEdgeMapper();

  EpisodicEdgeDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).episodicEdgeDao;

  @override
  Future<void> upsert(EpisodicEdge edge) =>
      // The edge carries its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(edge.workspaceId).upsert(
        db.EpisodicEdgesTableCompanion(
          id: Value(edge.id),
          workspaceId: Value(edge.workspaceId),
          sourceFactId: Value(edge.sourceFactId),
          targetFactId: Value(edge.targetFactId),
          edgeType: Value(edge.edgeType),
          weight: Value(edge.weight),
          createdAt: Value(edge.createdAt),
        ),
      );

  @override
  Future<List<EpisodicEdge>> getByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .getByWorkspace(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<String>> findRelated(
    String workspaceId,
    String seedFactId, {
    int depth = 2,
    String? edgeType,
    double minWeight = 0.0,
  }) async {
    final hops = await _dao(workspaceId).findRelated(
      workspaceId,
      seedFactId,
      depth: depth,
      edgeType: edgeType,
      minWeight: minWeight,
    );
    return hops.map((h) => h.factId).toList();
  }
}
