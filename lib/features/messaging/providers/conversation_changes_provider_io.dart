import 'package:cc_domain/cc_domain.dart' show PrFileDto, RpcErrorCodes;
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a conversation's working-tree diff request.
typedef ConversationChangesArgs = ({String workspaceId, String channelId});

/// The uncommitted working-tree diff across a conversation's isolated worktrees.
///
/// The desktop is a thin client — it owns neither the database (to resolve the
/// worktrees) nor the checkouts — so this is computed on the SERVER (which owns
/// them) via the `conversation.changes` op and returned as the same
/// `List<PrFile>` the UI renders. When the connected server doesn't expose the
/// op (e.g. a remote headless server that never created these worktrees), this
/// resolves to an empty list — "no changes" — rather than surfacing an error.
final conversationChangesProvider =
    FutureProvider.autoDispose.family<List<PrFile>, ConversationChangesArgs>(
  (ref, args) async {
    try {
      final data = await ref
          .watch(rpcClientProvider)
          .call('conversation.changes', {'channel_id': args.channelId});
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
