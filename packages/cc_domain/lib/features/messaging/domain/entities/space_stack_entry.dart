/// One layer of a space's branch stack, in one repo's checkout.
///
/// A space keeps a single worktree per repo. The stack is an ordered list of
/// branches inside that checkout: position 0 is the bottom (its pull request
/// targets [baseBranch], usually the repo default or the space's pinned base),
/// and each later layer's pull request targets the branch below it. No rows
/// exist until the first cut, so a space with one branch looks as it always has.
class SpaceStackEntry {
  /// Creates a [SpaceStackEntry].
  SpaceStackEntry({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.repoId,
    required this.position,
    required this.branch,
    required this.baseBranch,
    required this.createdAt,
    this.prNumber,
    this.prExternalId,
    this.rewritten = false,
  }) {
    if (workspaceId.isEmpty) {
      throw ArgumentError('SpaceStackEntry.workspaceId must not be empty');
    }
    if (spaceId.isEmpty) {
      throw ArgumentError('SpaceStackEntry.spaceId must not be empty');
    }
    if (repoId.isEmpty) {
      throw ArgumentError('SpaceStackEntry.repoId must not be empty');
    }
    if (position < 0) {
      throw ArgumentError('SpaceStackEntry.position must be >= 0');
    }
    if (branch.isEmpty) {
      throw ArgumentError('SpaceStackEntry.branch must not be empty');
    }
    if (baseBranch.isEmpty) {
      throw ArgumentError('SpaceStackEntry.baseBranch must not be empty');
    }
  }

  /// Row id.
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// The space this stack belongs to.
  final String spaceId;

  /// The repo whose checkout holds the stack.
  final String repoId;

  /// Order in the stack. 0 is the bottom.
  final int position;

  /// Branch name checked out for this layer.
  final String branch;

  /// The branch this layer's pull request targets.
  final String baseBranch;

  /// Forge pull-request number, filled when the layer is published.
  final int? prNumber;

  /// Forge-neutral pull-request id, filled when the layer is published.
  final String? prExternalId;

  /// True when a split rewrote this branch after it had been pushed, so the
  /// next publish must `--force-with-lease`.
  final bool rewritten;

  /// When the layer was recorded.
  final DateTime createdAt;

  /// Copy with overrides.
  SpaceStackEntry copyWith({
    int? position,
    String? branch,
    String? baseBranch,
    int? prNumber,
    String? prExternalId,
    bool? rewritten,
    bool clearPr = false,
  }) {
    return SpaceStackEntry(
      id: id,
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
      position: position ?? this.position,
      branch: branch ?? this.branch,
      baseBranch: baseBranch ?? this.baseBranch,
      createdAt: createdAt,
      prNumber: clearPr ? null : (prNumber ?? this.prNumber),
      prExternalId: clearPr ? null : (prExternalId ?? this.prExternalId),
      rewritten: rewritten ?? this.rewritten,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SpaceStackEntry &&
      other.id == id &&
      other.workspaceId == workspaceId &&
      other.spaceId == spaceId &&
      other.repoId == repoId &&
      other.position == position &&
      other.branch == branch &&
      other.baseBranch == baseBranch &&
      other.prNumber == prNumber &&
      other.prExternalId == prExternalId &&
      other.rewritten == rewritten;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    spaceId,
    repoId,
    position,
    branch,
    baseBranch,
    prNumber,
    prExternalId,
    rewritten,
  );
}
