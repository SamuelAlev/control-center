import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates projects over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one and
/// validates project ownership before touching a row (an id-only lookup is not
/// a scoping boundary). Mirrors the `project.*` ops + the
/// `project.watchForWorkspace` subscription in the host catalog.
class RemoteProjectRepository {
  /// Creates a [RemoteProjectRepository] over [_client].
  RemoteProjectRepository(this._client);

  final RemoteRpcClient _client;

  /// Inserts [project] (the host owns persistence).
  Future<void> insert(ProjectDto project) =>
      _client.call('project.insert', {'project': project.toJson()});

  /// Updates [project], scoped to the bound workspace server-side. Returns the
  /// number of rows written.
  Future<int> update(ProjectDto project) async {
    final data = await _client.call('project.update', {
      'project': project.toJson(),
    });
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  /// Deletes the project [projectId] (ownership-checked server-side against the
  /// bound workspace) and orphans its tickets. Returns the number of project
  /// rows deleted.
  Future<int> delete(String projectId) async {
    final data = await _client.call('project.delete', {
      'project_id': projectId,
    });
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  /// A single project by id (scoped to the bound workspace server-side), or
  /// null when it does not exist.
  Future<ProjectDto?> getById(String id) async {
    final data = await _client.call('project.getById', {'id': id});
    final project = data['project'];
    return project is Map
        ? ProjectDto.fromJson(project.cast<String, dynamic>())
        : null;
  }

  /// All projects in the bound workspace, newest first.
  Future<List<ProjectDto>> getForWorkspace() async {
    final data = await _client.call('project.getForWorkspace', const {});
    return _projects(data);
  }

  /// Live projects in the bound workspace — a fresh snapshot on every change,
  /// newest first.
  Stream<List<ProjectDto>> watchForWorkspace() => _client
      .subscribe('project.watchForWorkspace', const {})
      .map(_projects);

  List<ProjectDto> _projects(Map<String, dynamic> data) =>
      ((data['projects'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => ProjectDto.fromJson(p.cast<String, dynamic>()))
          .toList();
}
