import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/repositories/repo_script_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// RPC-backed [RepoScriptRepository] — the client half. Reads and writes the
/// per-repo lifecycle scripts over `repos.getScripts` / `repos.setScripts` and
/// watches recorded runs over `repos.watchScriptRuns`. The host owns
/// persistence and execution; this client never touches a database or a
/// shell.
class RpcRepoScriptRepository implements RepoScriptRepository {
  /// Creates a [RpcRepoScriptRepository] over the RPC client.
  RpcRepoScriptRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<RepoScripts> getScripts(String workspaceId, String repoId) async {
    final data = await _client.call('repos.getScripts', {
      'workspace_id': workspaceId,
      'repo_id': repoId,
    });
    return RepoScripts.fromJson(
      (data['scripts'] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  Future<void> setScripts(
    String workspaceId,
    String repoId,
    RepoScripts scripts,
  ) => _client.call('repos.setScripts', {
    'workspace_id': workspaceId,
    'repo_id': repoId,
    'scripts': scripts.toJson(),
  });

  @override
  Future<String> testScript(
    String workspaceId,
    String repoId,
    RepoScriptKind kind,
    String body,
  ) async {
    final data = await _client.call('repos.testScript', {
      'workspace_id': workspaceId,
      'repo_id': repoId,
      'kind': kind.wireName,
      'script': body,
    });
    return data['run_id'] as String;
  }

  @override
  Stream<List<RepoScriptRun>> watchRuns(String workspaceId, {String? repoId}) {
    return _client
        .subscribe('repos.watchScriptRuns', {
          'workspace_id': workspaceId,
          'repo_id': ?repoId,
        })
        .map((data) {
          final runs = data['runs'];
          if (runs is! List) {
            return const <RepoScriptRun>[];
          }
          return [
            for (final run in runs)
              if (run is Map)
                RepoScriptRun.fromJson(run.cast<String, dynamic>()),
          ].whereType<RepoScriptRun>().toList();
        });
  }
}
