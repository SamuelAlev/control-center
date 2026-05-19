import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_persistence/database/daos/review_space_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/review_space_mapper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift DAO-backed implementation of [ReviewSpaceRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).reviewSpaceDao` per call: an association ties a PR
/// to a space, both of which live in one workspace, so the workspace id picks
/// the file before any SQL runs.
class DaoReviewSpaceRepository implements ReviewSpaceRepository {
  /// Creates a [DaoReviewSpaceRepository] over the per-workspace databases.
  DaoReviewSpaceRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ReviewSpaceDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).reviewSpaceDao;

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => _dao(workspaceId)
      .watchByPr(workspaceId, prExternalId)
      .asyncMap((row) async => row == null ? null : toDomain(row));

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => _dao(workspaceId)
      .watchBySpace(spaceId)
      .asyncMap((row) async => row == null ? null : toDomain(row));

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => _dao(
    workspaceId,
  ).watchAllBySpace(workspaceId, spaceId).map(toDomainList);

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(toDomainList);

  @override
  Future<ReviewSpaceAssociation> create({
    required String spaceId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final data = ReviewSpacesTableCompanion(
      id: drift.Value(id),
      spaceId: drift.Value(spaceId),
      workspaceId: drift.Value(workspaceId),
      prExternalId: drift.Value(prExternalId),
      prNumber: drift.Value(prNumber),
      repoFullName: drift.Value(repoFullName),
      status: drift.Value(statusToString(ReviewSpaceStatus.requested)),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await _dao(workspaceId).insertAssociation(data);
    final row = await _dao(workspaceId).getById(id);
    if (row == null) {
      throw StateError('Failed to create review channel association');
    }
    return toDomain(row);
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
  ) => _dao(workspaceId).updateStatus(id, statusToString(status));
}
