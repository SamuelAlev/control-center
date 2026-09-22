import 'package:cc_domain/cc_domain.dart' show PrFileDto, RpcErrorCodes;
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a conversation's working-tree diff request. The `spaceId` scopes
/// the diff to the conversation's isolated CoW worktree (the tree agents/
/// code-server edit); when null the original linked-repo checkout is used.
typedef RepoChangesArgs = ({
  String workspaceId,
  String repoId,
  String? spaceId,
});

/// The uncommitted working-tree diff (vs HEAD, incl. untracked) for a repo,
/// WITH patch hunks.
///
/// The desktop is a thin client — it owns neither the checkouts nor the git
/// binary to diff them — so this is computed on the SERVER (which owns the CoW
/// worktrees) via the `repos.changes` op and returned as the same `List<PrFile>`
/// the IDE Source Control panel + `PrDiffView` render. When [RepoChangesArgs.
/// spaceId] is set, the server diffs the conversation's isolated CoW worktree
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
          if (args.spaceId != null) 'space_id': args.spaceId,
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
///
/// `statusKnown` is false when the connected server does not report branch
/// status (an older binary). `ahead` / `behind` then stay at 0 and the panel
/// must not invent a Publish or Sync button from them.
typedef RepoChanges = ({
  List<PrFile> staged,
  List<PrFile> unstaged,
  bool hasUpstream,
  int ahead,
  int behind,
  int aheadOfBase,
  bool aheadOfBaseKnown,
  bool statusKnown,
});

/// Empty buckets and unknown branch status — the value the panel shows while
/// the grouped read has not resolved, and the degrade when the op is absent.
const RepoChanges kEmptyRepoChanges = (
  staged: <PrFile>[],
  unstaged: <PrFile>[],
  hasUpstream: false,
  ahead: 0,
  behind: 0,
  aheadOfBase: 0,
  aheadOfBaseKnown: false,
  statusKnown: false,
);

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
              if (args.spaceId != null) 'space_id': args.spaceId,
            });
        List<PrFile> parse(String key) => ((data[key] as List?) ?? const [])
            .whereType<Map>()
            .map((f) => _fileFromWire(f.cast<String, dynamic>()))
            .toList();
        final known = data.containsKey('hasUpstream');
        return (
          staged: parse('staged'),
          unstaged: parse('unstaged'),
          hasUpstream: data['hasUpstream'] as bool? ?? false,
          ahead: (data['ahead'] as num?)?.toInt() ?? 0,
          behind: (data['behind'] as num?)?.toInt() ?? 0,
          aheadOfBase: (data['aheadOfBase'] as num?)?.toInt() ?? 0,
          aheadOfBaseKnown: data.containsKey('aheadOfBase'),
          statusKnown: known,
        );
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return kEmptyRepoChanges;
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
