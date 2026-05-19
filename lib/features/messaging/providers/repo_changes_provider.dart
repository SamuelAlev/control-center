import 'package:cc_domain/cc_domain.dart' show PrFileDto, RpcErrorCodes;
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a conversation's working-tree diff request. The `channelId` scopes
/// the diff to the conversation's isolated CoW worktree (the tree agents/
/// code-server edit); when null the original linked-repo checkout is used.
typedef RepoChangesArgs = ({
  String workspaceId,
  String repoId,
  String? channelId,
});

/// The uncommitted working-tree diff (vs HEAD, incl. untracked) for a repo,
/// WITH patch hunks.
///
/// The desktop is a thin client — it owns neither the checkouts nor the git
/// binary to diff them — so this is computed on the SERVER (which owns the CoW
/// worktrees) via the `repos.changes` op and returned as the same `List<PrFile>`
/// the IDE Source Control panel + `PrDiffView` render. When [RepoChangesArgs.
/// channelId] is set, the server diffs the conversation's isolated CoW worktree
/// — the tree the conversation's agents/code-server edit — not the shared
/// linked-repo checkout. When the connected server doesn't expose the op (e.g.
/// a remote headless server that owns no checkouts), this resolves to an empty
/// list — "no changes" — rather than surfacing an error.
final repoChangesProvider = FutureProvider.autoDispose
    .family<List<PrFile>, RepoChangesArgs>((ref, args) async {
      try {
        final data = await ref.watch(rpcClientProvider).call('repos.changes', {
          'workspace_id': args.workspaceId,
          'repo_id': args.repoId,
          if (args.channelId != null) 'channel_id': args.channelId,
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
    });

/// A repo's changes split into git's staged (index vs HEAD) and unstaged
/// (worktree vs index + untracked) buckets — the VS Code Source Control model.
typedef RepoChanges = ({List<PrFile> staged, List<PrFile> unstaged});

/// The staged/unstaged split for a repo's worktree, computed on the SERVER
/// (`repos.changesGrouped`) — see [repoChangesProvider] for the scoping rules.
/// Degrades to empty buckets when the host doesn't expose the op.
final repoChangesGroupedProvider = FutureProvider.autoDispose
    .family<RepoChanges, RepoChangesArgs>((ref, args) async {
      try {
        final data = await ref
            .watch(rpcClientProvider)
            .call('repos.changesGrouped', {
              'workspace_id': args.workspaceId,
              'repo_id': args.repoId,
              if (args.channelId != null) 'channel_id': args.channelId,
            });
        List<PrFile> parse(String key) => ((data[key] as List?) ?? const [])
            .whereType<Map>()
            .map((f) => _fileFromWire(f.cast<String, dynamic>()))
            .toList();
        return (staged: parse('staged'), unstaged: parse('unstaged'));
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return (staged: const <PrFile>[], unstaged: const <PrFile>[]);
        }
        rethrow;
      }
    });

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
