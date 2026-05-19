import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates projects over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. A workspace id selects
/// the database file server-side, so every call names its `workspace_id` — an
/// id-only lookup is not a scoping boundary and a project id resolves only
/// inside its own workspace. Mirrors the `project.*` ops + the
/// `project.watchForWorkspace` subscription in the host catalog.
class RemoteProjectRepository {
  /// Creates a [RemoteProjectRepository] over [_client].
  RemoteProjectRepository(this._client);

  final RemoteRpcClient _client;

  /// Inserts [project] (the host owns persistence).
  Future<void> insert(ProjectDto project) =>
      _client.call('project.insert', {'project': project.toJson()});

  /// Updates [project], scoped by the `workspace_id` the request carries. Returns the
  /// number of rows written.
  Future<int> update(ProjectDto project) async {
    final data = await _client.call('project.update', {
      'project': project.toJson(),
    });
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  /// Deletes the project [projectId] from [workspaceId] and orphans its
  /// tickets. Returns the number of project rows deleted.
  Future<int> delete(String workspaceId, String projectId) async {
    final data = await _client.call('project.delete', {
      'workspace_id': workspaceId,
      'project_id': projectId,
    });
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  /// A single project by id within [workspaceId], or null when it does not
  /// exist there.
  Future<ProjectDto?> getById(String workspaceId, String id) async {
    final data = await _client.call('project.getById', {
      'workspace_id': workspaceId,
      'id': id,
    });
    final project = data['project'];
    return project is Map
        ? ProjectDto.fromJson(project.cast<String, dynamic>())
        : null;
  }

  /// All projects in [workspaceId], newest first.
  Future<List<ProjectDto>> getForWorkspace(String workspaceId) async {
    final data = await _client.call('project.getForWorkspace', {
      'workspace_id': workspaceId,
    });
    return _projects(data);
  }

  /// Live projects in [workspaceId] — a fresh snapshot on every change, newest
  /// first.
  Stream<List<ProjectDto>> watchForWorkspace(String workspaceId) => _client
      .subscribe('project.watchForWorkspace', {'workspace_id': workspaceId})
      .map(_projects);

  List<ProjectDto> _projects(Map<String, dynamic> data) =>
      ((data['projects'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => ProjectDto.fromJson(p.cast<String, dynamic>()))
          .toList();
}
