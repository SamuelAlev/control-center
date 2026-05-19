/// The verdict of auditing indexed file paths against the real trees on disk.
class CodeGraphPathAudit {
  /// Creates an audit result.
  const CodeGraphPathAudit({
    required this.presentForCaller,
    required this.goneFromIndexedTree,
  });

  /// Paths that exist in the tree THIS caller reads — the conversation's
  /// self-contained repo copy when the call is conversation-scoped, otherwise
  /// the workspace's linked checkout. Anything absent here is a path the caller
  /// cannot open, so serving it only starts a guess-and-retry loop.
  final Set<String> presentForCaller;

  /// Paths gone from the tree the INDEX was built from (the searched checkout
  /// partition's tree). These rows are provably stale — the file they describe
  /// no longer exists where it was indexed — so they are safe to prune.
  ///
  /// Deliberately distinct from [presentForCaller]: a file that is missing from
  /// a conversation's copy (checked out at another revision) but still present
  /// in the indexed checkout must be hidden from that caller and NOT pruned,
  /// or one conversation's branch would erase the shared index.
  final Set<String> goneFromIndexedTree;
}

/// Resolves the on-disk trees behind the code graph and reports which indexed
/// paths still exist in them.
///
/// The code graph is keyed `(workspaceId, repoId, checkoutId)` — one partition
/// per checkout (the linked checkout plus one per conversation/PR worktree) —
/// so it drifts as soon as that checkout changes, and without this port the
/// code-graph tools answer confidently with paths that exist nowhere; see the
/// `search_code` → `read` loop this fixes.
///
/// Implemented server-side (`cc_server_core`) over the repo + isolated-worktree
/// registries; the MCP tools take it as a typed constructor parameter and fail
/// OPEN when it is absent or throws, so a host without it behaves exactly as
/// before rather than returning nothing.
abstract interface class CodeGraphTreePort {
  /// The checkout partition a code-graph call should search: the
  /// conversation's isolated worktree `isolated_repos` row id when
  /// [conversationId] is set and the conversation has a worktree for [repoId],
  /// else null (the linked checkout's partition).
  ///
  /// A resolvable-but-vanished worktree directory still returns its id — its
  /// graph partition lives until the registry row is deleted, and the audit
  /// heals any stale rows against the linked checkout as caller tree fallback.
  Future<String?> checkoutIdFor({
    required String workspaceId,
    required String repoId,
    String? conversationId,
  });

  /// Audits [paths] (repo-relative) for [repoId] in [workspaceId].
  ///
  /// [conversationId] selects the caller's tree: the conversation's isolated
  /// repo copy when set and resolvable, else the linked checkout.
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
    String? conversationId,
    String? checkoutId,
  });
}
