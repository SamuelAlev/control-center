import 'package:cc_data/src/repositories/remote_project_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ProjectRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `project.*` ops + the
/// `project.watchForWorkspace` subscription, mapping the [ProjectDto] wire
/// shape back to [Project]. The host owns persistence and validates project
/// ownership against the bound workspace; this client never touches a database.
class RpcProjectRepository implements ProjectRepository {
  /// Creates an [RpcProjectRepository] over [client].
  RpcProjectRepository(RemoteRpcClient client)
    : _remote = RemoteProjectRepository(client);

  final RemoteProjectRepository _remote;

  /// Rebuilds a [Project] from its wire DTO. Enum fields are encoded as
  /// `.name`; timestamps are ISO-8601 strings.
  static Project _fromDto(ProjectDto d) => Project(
    id: d.id,
    workspaceId: d.workspaceId,
    name: d.name,
    description: d.description,
    color: ProjectColor.fromStorage(d.color),
    status: ProjectStatus.fromStorage(d.status),
    createdAt: DateTime.parse(d.createdAt),
    updatedAt: DateTime.parse(d.updatedAt),
  );

  static ProjectDto _toDto(Project p) => ProjectDto(
    id: p.id,
    workspaceId: p.workspaceId,
    name: p.name,
    description: p.description,
    color: p.color.toStorageString(),
    status: p.status.toStorageString(),
    createdAt: p.createdAt.toIso8601String(),
    updatedAt: p.updatedAt.toIso8601String(),
  );

  @override
  Future<void> insert(Project project) => _remote.insert(_toDto(project));

  @override
  Future<int> update(Project project) => _remote.update(_toDto(project));

  @override
  Future<int> delete(String projectId, {required String workspaceId}) =>
      _remote.delete(projectId);

  @override
  Future<Project?> getById(String id) async {
    try {
      final dto = await _remote.getById(id);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<Project>> getForWorkspace(String workspaceId) async {
    final dtos = await _remote.getForWorkspace();
    return dtos.map(_fromDto).toList();
  }

  @override
  Stream<List<Project>> watchForWorkspace(String workspaceId) =>
      _remote.watchForWorkspace().map((dtos) => dtos.map(_fromDto).toList());
}
