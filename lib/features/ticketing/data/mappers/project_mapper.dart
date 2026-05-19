import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:drift/drift.dart';

/// Maps between [Project] domain entities and their Drift rows.
class ProjectMapper {
  /// Creates a [ProjectMapper].
  const ProjectMapper();

  /// Full companion writing every column (insert / update).
  ProjectsTableCompanion toCompanion(Project p) {
    return ProjectsTableCompanion(
      id: Value(p.id),
      workspaceId: Value(p.workspaceId),
      name: Value(p.name),
      description: Value(p.description),
      color: Value(p.color.toStorageString()),
      status: Value(p.status.toStorageString()),
      createdAt: Value(p.createdAt),
      updatedAt: Value(p.updatedAt),
    );
  }

  /// Builds a domain [Project] from a row.
  Project fromRow(ProjectsTableData row) {
    return Project(
      id: row.id,
      workspaceId: row.workspaceId,
      name: row.name,
      description: row.description,
      color: ProjectColor.fromStorage(row.color),
      status: ProjectStatus.fromStorage(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
