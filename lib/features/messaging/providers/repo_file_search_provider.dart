import 'package:cc_domain/cc_domain.dart' show FileSearchHit, RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a workspace-scoped fuzzy file-search request.
typedef RepoFileSearchArgs = ({String workspaceId, String query});

/// Server-side fuzzy file search across a workspace's linked repo roots.
///
/// The desktop is a thin client — fff/the file walk run on the SERVER over the
/// CoW checkouts it owns (works identically on web + desktop) via the
/// `repos.searchFiles` op. The op attaches `repoId` to each hit (matched by
/// `rootPath` → linked repo), so the value is a typed wrapper
/// `({FileSearchHit hit, String repoId})` the IDE Explorer uses to group/open
/// files per-repo. An empty query yields the full cached entry tree; a
/// non-empty query yields a scored fuzzy list. When the connected server
/// doesn't expose the op (no checkouts owned), resolves to an empty list.
final repoFileSearchProvider =
    FutureProvider.autoDispose.family<
      List<({FileSearchHit hit, String repoId})>,
      RepoFileSearchArgs
    >((ref, args) async {
      try {
        final data = await ref
            .watch(rpcClientProvider)
            .call('repos.searchFiles', {
              'workspace_id': args.workspaceId,
              'query': args.query,
            });
        return ((data['hits'] as List?) ?? const [])
            .whereType<Map>()
            .map((h) {
              final w = h.cast<String, dynamic>();
              return (
                hit: FileSearchHit.fromJson(w),
                repoId: w['repoId'] as String? ?? '',
              );
            })
            .toList();
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return const [];
        }
        rethrow;
      }
    });
