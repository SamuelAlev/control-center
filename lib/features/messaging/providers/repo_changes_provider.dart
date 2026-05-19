import 'package:cc_domain/cc_domain.dart' show PrFileDto, RpcErrorCodes;
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a linked repo's working-tree diff request.
typedef RepoChangesArgs = ({String workspaceId, String repoId});

/// The uncommitted working-tree diff (vs HEAD, incl. untracked) for a linked
/// repo, WITH patch hunks.
///
/// The desktop is a thin client — it owns neither the checkouts nor the git
/// binary to diff them — so this is computed on the SERVER (which owns the CoW
/// checkouts) via the `repos.changes` op and returned as the same `List<PrFile>`
/// the IDE Source Control panel + `PrDiffView` render. When the connected
/// server doesn't expose the op (e.g. a remote headless server that owns no
/// checkouts), this resolves to an empty list — "no changes" — rather than
/// surfacing an error.
final repoChangesProvider =
    FutureProvider.autoDispose.family<List<PrFile>, RepoChangesArgs>(
  (ref, args) async {
    try {
      final data = await ref
          .watch(rpcClientProvider)
          .call('repos.changes', {
            'workspace_id': args.workspaceId,
            'repo_id': args.repoId,
          });
      return ((data['files'] as List?) ?? const [])
          .whereType<Map>()
          .map((f) => _fileFromWire(f.cast<String, dynamic>()))
          .toList();
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  },
);

PrFile _fileFromWire(Map<String, dynamic> w) {
  final d = PrFileDto.fromJson(w);
  return PrFile(
    filename: d.filename,
    status: PrFileStatusExtension.fromString(d.status),
    additions: d.additions,
    deletions: d.deletions,
    patch: d.patch,
    previousFilename: d.previousFilename,
    viewerViewedState: PrFileViewedStateExtension.fromWireName(
      d.viewerViewedState,
    ),
  );
}
