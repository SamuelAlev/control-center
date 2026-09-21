/// The verdict of auditing indexed file paths against the real trees on disk.
class CodeGraphPathAudit {
  /// Creates an audit result.
  const CodeGraphPathAudit({
    required this.presentForCaller,
    required this.goneFromIndexedTree,
  });

  /// Paths that exist in the tree THIS caller reads — the space's
  /// self-contained repo copy when the call is space-scoped, otherwise the
  /// workspace's linked checkout. Anything absent here is a path the caller
  /// cannot open, so serving it only starts a guess-and-retry loop.
  final Set<String> presentForCaller;

  /// Paths gone from the tree the INDEX was built from (the searched checkout
  /// partition's tree). These rows are provably stale — the file they describe
  /// no longer exists where it was indexed — so they are safe to prune.
  ///
  /// Deliberately distinct from [presentForCaller]: a file that is missing from
  /// a space's copy (checked out at another revision) but still present in the
  /// indexed checkout must be hidden from that caller and NOT pruned, or one
  /// space's branch would erase the shared index.
  final Set<String> goneFromIndexedTree;
}

/// Resolves on-disk trees behind the code graph and which indexed paths exist.
///
/// Graph is keyed `(workspaceId, repoId, checkoutId)`. Scope is the SPACE
/// (`isolated_repos.space_id`) — a conversation id resolves to the linked
/// checkout and silently answers PR review from base. Fail-open when absent.
abstract interface class CodeGraphTreePort {
  /// The checkout partition a code-graph call should search: the space's
  /// isolated worktree `isolated_repos` row id when [spaceId] is set and the
  /// space has a worktree for [repoId], else null (the linked checkout's
  /// partition).
  ///
  /// A resolvable-but-vanished worktree directory still returns its id — its
  /// graph partition lives until the registry row is deleted and the audit
  /// heals any stale rows against the linked checkout as caller tree fallback.
  Future<String?> checkoutIdFor({
    required String workspaceId,
    required String repoId,
    String? spaceId,
  });

  /// Audits [paths] (repo-relative) for [repoId] in [workspaceId].
  ///
  /// [spaceId] selects the caller's tree: the space's isolated repo copy when
  /// set and resolvable, else the linked checkout.
  /// [checkoutId] is the graph partition the search ran against (as resolved
  /// by [checkoutIdFor]): when non-null the indexed tree is that worktree, so
  /// `goneFromIndexedTree` prunes rows provably dead in the partition actually
  /// searched; when null the indexed tree is the linked checkout. Returns null
  /// when no tree could be resolved at all — the signal for callers to serve
  /// results unfiltered rather than pretend the repo is empty.
  Future<CodeGraphPathAudit?> audit({
    required String workspaceId,
    required String repoId,
    required List<String> paths,
    String? spaceId,
    String? checkoutId,
  });
}
