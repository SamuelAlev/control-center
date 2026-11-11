import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RepoDto;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A repository registered into a workspace, and what automation cannot
/// reach there yet (the server's `access_warnings`, joined to the repo's
/// coordinates so they read like any other access issue).
typedef RepoRegistration = ({String repoId, List<RepoAccessIssue> issues});

/// [warnings] about the repo [dto] as [RepoAccessIssue]s. A repo with no
/// forge remote has nothing to warn about.
List<RepoAccessIssue> repoAccessIssuesOf(
  RepoDto dto,
  List<RepoAccessWarning> warnings,
) {
  if (dto.remoteOwner.isEmpty || dto.remoteName.isEmpty) {
    return const [];
  }
  return [
    for (final w in warnings)
      RepoAccessIssue(
        forge: ForgeHost.fromWire(dto.forge),
        owner: dto.remoteOwner,
        name: dto.remoteName,
        repoId: dto.id,
        state: w.state,
        message: w.message,
        installUrl: w.installUrl,
      ),
  ];
}

/// Registers a repo by inspecting a git checkout at a path on the SERVER's
/// filesystem over RPC, returning the new repo id and its access issues.
///
/// The desktop add-repo form inspects a local checkout directly (it shares the
/// server's machine); the web form has no local filesystem, so it asks the
/// host — which owns the checkout — to inspect + register the repo. The repo is
/// created inside the named workspace (repos are workspace-scoped) and the op
/// fires `RepoAdded` host-side, so the same server-side code-indexing pipeline
/// runs either way. The server refuses a repo the person's own forge account
/// cannot see, and asks them to sign in when they are not signed in to its
/// forge.
final addRepoFromServerPathProvider =
    Provider<
      Future<RepoRegistration> Function(String workspaceId, String path)
    >((ref) {
      final client = ref.watch(rpcClientProvider);
      return (workspaceId, path) async {
        final result = await RemoteRepoRepository(
          client,
        ).addFromPath(workspaceId, path.trim());
        return (
          repoId: result.repo.id,
          issues: repoAccessIssuesOf(result.repo, result.warnings),
        );
      };
    });

/// Saves `repo`'s forge link in a workspace (`repos.upsert`), returning what
/// automation cannot reach there yet. `relink` re-pins a repository whose
/// path now names a different repository on its forge.
final linkRepoProvider =
    Provider<
      Future<RepoRegistration> Function(
        String workspaceId,
        Repo repo, {
        bool relink,
      })
    >((ref) {
      final client = ref.watch(rpcClientProvider);
      return (workspaceId, repo, {relink = false}) async {
        final dto = RepoDto(
          id: repo.id,
          name: repo.name,
          path: repo.path,
          forge: repo.forge.wire,
          remoteOwner: repo.remoteOwner,
          remoteName: repo.remoteName,
          createdAt: repo.createdAt.toIso8601String(),
          updatedAt: repo.updatedAt.toIso8601String(),
        );
        final result = await RemoteRepoRepository(
          client,
        ).link(workspaceId, dto, relink: relink);
        return (
          repoId: result.repoId,
          issues: repoAccessIssuesOf(dto, result.warnings),
        );
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
