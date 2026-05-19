import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_persistence/database/daos/review_channel_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/review_channel_mapper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift DAO-backed implementation of [ReviewChannelRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).reviewChannelDao` per call: an association ties a PR
/// to a channel, both of which live in one workspace, so the workspace id picks
/// the file before any SQL runs.
class DaoReviewChannelRepository implements ReviewChannelRepository {
  /// Creates a [DaoReviewChannelRepository] over the per-workspace databases.
  DaoReviewChannelRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ReviewChannelDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).reviewChannelDao;

  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => _dao(workspaceId)
      .watchByPr(workspaceId, prExternalId)
      .asyncMap((row) async => row == null ? null : toDomain(row));

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  ) => _dao(workspaceId)
      .watchByChannel(channelId)
      .asyncMap((row) async => row == null ? null : toDomain(row));

  @override
  Stream<List<ReviewChannelAssociation>> watchAllByChannel(
    String workspaceId,
    String channelId,
  ) => _dao(
    workspaceId,
  ).watchAllByChannel(workspaceId, channelId).map(toDomainList);

  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(toDomainList);

  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final data = ReviewChannelsTableCompanion(
      id: drift.Value(id),
      channelId: drift.Value(channelId),
      workspaceId: drift.Value(workspaceId),
      prExternalId: drift.Value(prExternalId),
      prNumber: drift.Value(prNumber),
      repoFullName: drift.Value(repoFullName),
      status: drift.Value(statusToString(ReviewChannelStatus.requested)),
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
    ReviewChannelStatus status,
  ) => _dao(workspaceId).updateStatus(id, statusToString(status));
}
