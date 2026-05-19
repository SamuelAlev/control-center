import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_persistence/database/app_database.dart';

/// Pr lifecycle mapper.
class PrLifecycleMapper {
  /// PrLifecycleMapper.
  const PrLifecycleMapper();

  /// To domain.
  PrGeneration toDomain(PullRequestsTableData row) {
    return PrGeneration(
      id: row.id,
      workspaceId: row.workspaceId,
      status: PrGenerationStatus.fromName(row.status),
      title: row.title,
      body: row.body,
      branch: null,
      createdAt: row.createdAt,
      updatedAt: row.createdAt,
    );
  }

  /// To domain list.
  List<PrGeneration> toDomainList(List<PullRequestsTableData> rows) =>
      rows.map(toDomain).toList(growable: false);
}
