import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';

/// `owner/name` → the workspaces that have that repo linked.
///
/// The notification poller asks this per repo on every tick. Answering it by
/// listing every workspace and then every workspace's repo list is
/// O(workspaces) queries per repo per tick — on a host with a dozen workspaces
/// and a handful of watched repos that is a steady trickle of database work on
/// the server's one shared connection, all to re-derive a mapping that changes
/// only when someone registers or unlinks a repo.
///
/// Rebuilt on a TTL rather than invalidated by events: a repo link is a rare,
/// user-initiated action, and a lookup that is at most [ttl] stale can only
/// delay a notification fan-out by that much (the next tick picks it up).
class RepoWorkspaceIndex {
  /// Creates an index over [_workspaces].
  RepoWorkspaceIndex(this._workspaces, {this.ttl = const Duration(minutes: 5)});

  final WorkspaceRepository _workspaces;

  /// How long a built index is served before it is rebuilt.
  final Duration ttl;

  Map<String, List<String>>? _index;
  DateTime? _builtAt;
  Future<Map<String, List<String>>>? _building;

  /// The workspace ids that have [repoFullName] (`owner/name`) linked.
  Future<List<String>> workspacesFor(String repoFullName) async {
    final index = await _ensure();
    return index[repoFullName.toLowerCase()] ?? const [];
  }

  /// Drops the index so the next lookup rebuilds it.
  void invalidate() {
    _index = null;
    _builtAt = null;
  }

  Future<Map<String, List<String>>> _ensure() {
    final built = _index;
    final at = _builtAt;
    if (built != null && at != null && DateTime.now().difference(at) < ttl) {
      return Future.value(built);
    }
    // Single-flight: a burst of lookups on a cold index must not each start
    // their own full rebuild.
    return _building ??= _build().whenComplete(() => _building = null);
  }

  Future<Map<String, List<String>>> _build() async {
    final index = <String, List<String>>{};
    // CROSS-WORKSPACE BY DESIGN: a forge notification names a repo, not a
    // workspace, so resolving it has to consider every workspace that could
    // have linked that repo.
    final workspaces = await _workspaces.watchAll().first;
    for (final workspace in workspaces) {
      final linked = await _workspaces
          .watchReposForWorkspace(workspace.id)
          .first;
      for (final repo in linked) {
        if (!repo.hasForgeRemote) {
          continue;
        }
        (index[repo.fullName.toLowerCase()] ??= <String>[]).add(workspace.id);
      }
    }
    _index = index;
    _builtAt = DateTime.now();
    return index;
  }
}
