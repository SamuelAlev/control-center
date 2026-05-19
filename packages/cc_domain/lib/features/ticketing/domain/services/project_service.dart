import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:uuid/uuid.dart';

/// Creates and manages projects. Pure domain: depends only on the
/// [ProjectRepository]. Every by-id mutation is workspace-scoped and rejects
/// cross-workspace access loudly with a [WorkspaceMismatchException].
class ProjectService {
  /// Creates a [ProjectService].
  ProjectService({required this.repository});

  /// Project persistence.
  final ProjectRepository repository;

  static const _uuid = Uuid();

  /// Creates a project.
  Future<Project> create({
    required String workspaceId,
    required String name,
    String? description,
    ProjectColor color = ProjectColor.gray,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Project name must not be empty');
    }
    final now = DateTime.now();
    final project = Project(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      name: trimmed,
      description: (description?.trim().isEmpty ?? true)
          ? null
          : description!.trim(),
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insert(project);
    return project;
  }

  /// Updates a project's editable fields. A clear-description is expressed by
  /// passing an empty string. Cross-workspace updates are rejected.
  Future<Project?> update(
    String projectId, {
    required String workspaceId,
    String? name,
    String? description,
    ProjectColor? color,
    ProjectStatus? status,
  }) async {
    final project = await _load(projectId, workspaceId);
    if (project == null) {
      return null;
    }
    final next = project.copyWith(
      name: name?.trim().isEmpty ?? true ? null : name!.trim(),
      description: description?.trim(),
      removeDescription: description != null && description.trim().isEmpty,
      color: color,
      status: status,
      updatedAt: DateTime.now(),
    );
    await repository.update(next);
    return next;
  }

  /// Archives a project (hides it from the default sidebar list).
  Future<Project?> archive(String projectId, {required String workspaceId}) =>
      update(projectId, workspaceId: workspaceId, status: ProjectStatus.archived);

  /// Deletes a project, orphaning its tickets (their `projectId` is cleared).
  /// A no-op when the project is already gone; cross-workspace deletes are
  /// rejected.
  Future<void> delete(String projectId, {required String workspaceId}) async {
    final project = await repository.getById(projectId);
    if (project == null) {
      return;
    }
    _assertWorkspace(projectId, project.workspaceId, workspaceId);
    await repository.delete(projectId, workspaceId: workspaceId);
  }

  Future<Project?> _load(String projectId, String workspaceId) async {
    final project = await repository.getById(projectId);
    if (project == null) {
      return null;
    }
    _assertWorkspace(projectId, project.workspaceId, workspaceId);
    return project;
  }

  void _assertWorkspace(
    String projectId,
    String projectWorkspaceId,
    String expectedWorkspaceId,
  ) {
    if (projectWorkspaceId != expectedWorkspaceId) {
      throw WorkspaceMismatchException(
        'Project $projectId belongs to a different workspace.',
      );
    }
  }
}
