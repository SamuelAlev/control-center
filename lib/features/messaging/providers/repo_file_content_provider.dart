import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a file-read request against a linked repo checkout.
typedef RepoFileContentArgs = ({
  String workspaceId,
  String repoId,
  String path,
});

/// A file's decoded content + binary flag, read SERVER-SIDE from a linked repo
/// checkout via the `repos.readFile` op (the SERVER owns the checkout; traversal
/// outside the repo root is rejected there). Backs the IDE FileViewer tab.
/// When the connected server doesn't expose the op, resolves to empty text
/// rather than surfacing an error.
final repoFileContentProvider =
    FutureProvider.autoDispose.family<
      ({String content, bool binary}),
      RepoFileContentArgs
    >((ref, args) async {
      try {
        final data = await ref
            .watch(rpcClientProvider)
            .call('repos.readFile', {
              'workspace_id': args.workspaceId,
              'repo_id': args.repoId,
              'path': args.path,
            });
        return (
          content: data['content'] as String? ?? '',
          binary: data['binary'] as bool? ?? false,
        );
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return (content: '', binary: false);
        }
        rethrow;
      }
    });
