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
/// host — which owns the checkout — to inspect + register the repo. The repo is
/// created inside the named workspace (repos are workspace-scoped), and the op
/// fires `RepoAdded` host-side, so the same server-side code-indexing pipeline
/// runs either way.
final addRepoFromServerPathProvider =
    Provider<Future<String> Function(String workspaceId, String path)>((ref) {
      final client = ref.watch(rpcClientProvider);
      return (workspaceId, path) async {
        final repo = await RemoteRepoRepository(
          client,
        ).addFromPath(workspaceId, path.trim());
        return repo.id;
      };
    });

/// Browses the SERVER's filesystem over RPC (`fs.browseDirectory`) for the web
/// add-repo folder picker. The server constrains navigation to its configured
/// roots; the client treats every returned path as an opaque server-side token.
final directoryBrowserProvider = Provider<DirectoryBrowserPort>((ref) {
  return RpcDirectoryBrowserPort(ref.watch(rpcClientProvider));
});

/// Watches a workspace's repos, in the operator's manual drag-to-reorder order.
///
/// There is no all-repos-on-this-server provider: a repo belongs to a
/// workspace, so every repo list names the workspace it is listing.
final reposForWorkspaceProvider = StreamProvider.family<List<Repo>, String>((
  ref,
  workspaceId,
) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.watchReposForWorkspace(workspaceId);
});
