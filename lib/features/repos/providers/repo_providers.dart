import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registers a repo by inspecting a git checkout at a path on the SERVER's
/// filesystem over RPC, returning the new repo id.
///
/// The desktop add-repo form inspects a local checkout directly (it shares the
/// server's machine); the web form has no local filesystem, so it asks the
/// host — which owns the checkout — to inspect + register the repo, then links
/// it to the active workspace. The op fires `RepoAdded` host-side, so the same
/// server-side code-indexing pipeline runs either way.
final addRepoFromServerPathProvider =
    Provider<Future<String> Function(String path)>((ref) {
  final client = ref.watch(rpcClientProvider);
  return (path) async {
    final repo = await RemoteRepoRepository(client).addFromPath(path.trim());
    return repo.id;
  };
});

/// Browses the SERVER's filesystem over RPC (`fs.browseDirectory`) for the web
/// add-repo folder picker. The server constrains navigation to its configured
/// roots; the client treats every returned path as an opaque server-side token.
final directoryBrowserProvider = Provider<DirectoryBrowserPort>((ref) {
  return RpcDirectoryBrowserPort(ref.watch(rpcClientProvider));
});

/// Watches all registered repos.
final reposProvider = StreamProvider<List<Repo>>((ref) {
  final repository = ref.watch(repoRepositoryProvider);
  return repository.watchAll();
});

/// Watches the repos linked to a specific workspace.
final reposForWorkspaceProvider = StreamProvider.family<List<Repo>, String>((
  ref,
  workspaceId,
) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.watchReposForWorkspace(workspaceId);
});
