import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';

/// Maps a review space database row to a [ReviewSpaceAssociation] domain entity.
ReviewSpaceAssociation toDomain(ReviewSpacesTableData row) =>
    ReviewSpaceAssociation(
      id: row.id,
      spaceId: row.spaceId,
      workspaceId: row.workspaceId,
      prExternalId: row.prExternalId,
      prNumber: row.prNumber,
      repoFullName: row.repoFullName,
      status: parseStatus(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

/// Maps a list of review space database rows to domain entities.
List<ReviewSpaceAssociation> toDomainList(
  List<ReviewSpacesTableData> rows,
) => rows.map(toDomain).toList(growable: false);

/// Parses a status string from the database into a [ReviewSpaceStatus] enum value.
ReviewSpaceStatus parseStatus(String value) => ReviewSpaceStatus.values
    .firstWhere((s) => s.wire == value, orElse: () => ReviewSpaceStatus.requested);

/// Converts a [ReviewSpaceStatus] enum value to its database string representation.
String statusToString(ReviewSpaceStatus status) => status.wire;
