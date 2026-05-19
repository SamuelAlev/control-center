import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_persistence/database/app_database.dart';

/// Maps a review channel database row to a [ReviewChannelAssociation] domain entity.
ReviewChannelAssociation toDomain(ReviewChannelsTableData row) =>
    ReviewChannelAssociation(
      id: row.id,
      channelId: row.channelId,
      workspaceId: row.workspaceId,
      prNodeId: row.prNodeId,
      prNumber: row.prNumber,
      repoFullName: row.repoFullName,
      status: parseStatus(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

/// Maps a list of review channel database rows to domain entities.
List<ReviewChannelAssociation> toDomainList(
  List<ReviewChannelsTableData> rows,
) => rows.map(toDomain).toList(growable: false);

/// Parses a status string from the database into a [ReviewChannelStatus] enum value.
ReviewChannelStatus parseStatus(String value) {
  switch (value) {
    case 'requested':
      return ReviewChannelStatus.requested;
    case 'in_progress':
      return ReviewChannelStatus.inProgress;
    case 'awaiting_approval':
      return ReviewChannelStatus.awaitingApproval;
    case 'completed':
      return ReviewChannelStatus.completed;
    default:
      return ReviewChannelStatus.requested;
  }
}

/// Converts a [ReviewChannelStatus] enum value to its database string representation.
String statusToString(ReviewChannelStatus status) {
  switch (status) {
    case ReviewChannelStatus.requested:
      return 'requested';
    case ReviewChannelStatus.inProgress:
      return 'in_progress';
    case ReviewChannelStatus.awaitingApproval:
      return 'awaiting_approval';
    case ReviewChannelStatus.completed:
      return 'completed';
  }
}
