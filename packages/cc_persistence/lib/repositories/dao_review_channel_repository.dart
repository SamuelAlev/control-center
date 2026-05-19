import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/review_channel_dao.dart';
import 'package:cc_persistence/mappers/review_channel_mapper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift DAO-backed implementation of [ReviewChannelRepository].
class DaoReviewChannelRepository implements ReviewChannelRepository {
  /// Creates a new [DaoReviewChannelRepository].
  DaoReviewChannelRepository(this._dao);

  final ReviewChannelDao _dao;

  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prNodeId,
  ) => _dao
      .watchByPr(workspaceId, prNodeId)
      .asyncMap((row) async => row == null ? null : toDomain(row));

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(String channelId) => _dao
      .watchByChannel(channelId)
      .asyncMap((row) async => row == null ? null : toDomain(row));

  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(toDomainList);

  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prNodeId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final data = ReviewChannelsTableCompanion(
      id: drift.Value(id),
      channelId: drift.Value(channelId),
      workspaceId: drift.Value(workspaceId),
      prNodeId: drift.Value(prNodeId),
      prNumber: drift.Value(prNumber),
      repoFullName: drift.Value(repoFullName),
      status: drift.Value(statusToString(ReviewChannelStatus.requested)),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await _dao.insertAssociation(data);
    final row = await _dao.getById(id);
    if (row == null) {
      throw StateError('Failed to create review channel association');
    }
    return toDomain(row);
  }

  @override
  Future<void> updateStatus(String id, ReviewChannelStatus status) =>
      _dao.updateStatus(id, statusToString(status));
}
