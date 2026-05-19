import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_persistence/database/app_database.dart';

/// Maps database rows to [Workspace] domain entities.
class WorkspaceMapper {
  /// Creates a const [WorkspaceMapper].
  const WorkspaceMapper();

  /// To domain.
  Workspace toDomain(WorkspacesTableData row) {
    return Workspace(
      id: row.id,
      name: row.name,
      logoPath: row.logoPath,

      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      reviewConcurrency: row.reviewConcurrency,
      deletedAt: row.deletedAt,
    );
  }

  /// To domain list.
  List<Workspace> toDomainList(List<WorkspacesTableData> rows) =>
      rows.map(toDomain).toList(growable: false);
}
