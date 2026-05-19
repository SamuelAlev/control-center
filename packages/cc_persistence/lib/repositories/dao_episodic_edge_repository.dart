import 'package:cc_domain/core/domain/entities/episodic_edge.dart';
import 'package:cc_domain/features/memory/domain/repositories/episodic_edge_repository.dart';
import 'package:cc_persistence/database/app_database.dart' as db;
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
import 'package:cc_persistence/mappers/episodic_edge_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for episodic edges.
class DaoEpisodicEdgeRepository implements EpisodicEdgeRepository {
  /// Creates a [DaoEpisodicEdgeRepository].
  DaoEpisodicEdgeRepository(this._dao);

  final EpisodicEdgeDao _dao;
  final EpisodicEdgeMapper _mapper = const EpisodicEdgeMapper();

  @override
  Future<void> upsert(EpisodicEdge edge) => _dao.upsert(
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
      _dao.getByWorkspace(workspaceId).then(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Future<List<String>> findRelated(
    String workspaceId,
    String seedFactId, {
    int depth = 2,
    String? edgeType,
    double minWeight = 0.0,
  }) async {
    final hops = await _dao.findRelated(
      workspaceId,
      seedFactId,
      depth: depth,
      edgeType: edgeType,
      minWeight: minWeight,
    );
    return hops.map((h) => h.factId).toList();
  }
}