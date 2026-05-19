import 'package:cc_domain/cc_domain.dart' show FileSearchHit, RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a workspace-scoped fuzzy file-search request.
typedef RepoFileSearchArgs = ({String workspaceId, String query});

/// One file hit paired with the linked repo it belongs to.
typedef RepoFileHit = ({FileSearchHit hit, String repoId});

/// Calls the server's `repos.searchFiles` op and decodes its hits.
///
/// The single client-side decode site for that op — every file-search surface
/// (the IDE Explorer via [repoFileSearchProvider], the composer's `@` file
/// mentions) goes through here, so no client ever searches the filesystem
/// itself. When the connected server doesn't expose the op (it owns no
/// checkouts), resolves to an empty list rather than throwing.
Future<List<RepoFileHit>> fetchRepoFileSearch(
  RemoteRpcClient client, {
  required String workspaceId,
  required String query,
}) async {
  try {
    final data = await client.call('repos.searchFiles', {
      'workspace_id': workspaceId,
      'query': query,
    });
    return ((data['hits'] as List?) ?? const []).whereType<Map>().map((h) {
      final w = h.cast<String, dynamic>();
      return (
        hit: FileSearchHit.fromJson(w),
        repoId: w['repoId'] as String? ?? '',
      );
    }).toList();
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return const [];
    }
    rethrow;
  }
}

/// Calls `repos.searchFiles` on demand, for surfaces that query per keystroke
/// rather than per rebuild (the composer's `@` file mentions).
///
/// Resolving the RPC client lazily — inside the returned closure — matters:
/// [rpcClientProvider] throws until the composition root overrides it with the
/// connected client, so a widget must be able to hold this function before the
/// handshake completes.
final repoFileSearchFnProvider =
    Provider<Future<List<RepoFileHit>> Function(String, String)>(
      (ref) =>
          (workspaceId, query) => fetchRepoFileSearch(
            ref.read(rpcClientProvider),
            workspaceId: workspaceId,
            query: query,
          ),
    );

/// Server-side fuzzy file search across a workspace's linked repo roots.
///
/// The desktop is a thin client — fff/the file walk run on the SERVER over the
/// CoW checkouts it owns (works identically on web + desktop) via the
/// `repos.searchFiles` op. The op attaches `repoId` to each hit (matched by
/// `rootPath` → linked repo), so the value is a typed wrapper
/// `({FileSearchHit hit, String repoId})` the IDE Explorer uses to group/open
/// files per-repo. An empty query yields the full cached entry tree; a
/// non-empty query yields a scored fuzzy list.
final repoFileSearchProvider = FutureProvider.autoDispose
    .family<List<RepoFileHit>, RepoFileSearchArgs>(
      (ref, args) => fetchRepoFileSearch(
        ref.watch(rpcClientProvider),
        workspaceId: args.workspaceId,
        query: args.query,
      ),
    );
