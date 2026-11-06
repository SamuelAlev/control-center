/// Identifies one worktree a task runs against.
class WorktreeTaskContext {
  /// Creates a [WorktreeTaskContext].
  const WorktreeTaskContext({
    required this.workspaceId,
    required this.repoId,
    required this.worktreePath,
    required this.sourcePath,
    this.spaceId,
    this.isForkPr = false,
    this.isPrWorktree = false,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The repo.
  final String repoId;

  /// The provisioned worktree.
  final String worktreePath;

  /// The registered source checkout.
  final String sourcePath;

  /// The space, or null for a throwaway test.
  final String? spaceId;

  /// Whether this worktree holds a fork PR's code.
  final bool isForkPr;

  /// Whether this is a PR worktree at all. By the time `archive` tasks run the
  /// space may be gone, and this is what's left to tell a PR from a branch.
  final bool isPrWorktree;
}

/// Thrown when a `provision` task fails, which fails provisioning.
class WorktreeTaskException implements Exception {
  /// Creates a [WorktreeTaskException].
  const WorktreeTaskException(this.message);

  /// Client-safe explanation.
  final String message;

  @override
  String toString() => message;
}

/// What the worktree provisioner calls when a worktree appears or goes away.
///
/// A worktree outlives any environment, so this runs with or without one.
abstract interface class WorktreeTaskPort {
  /// Whether [repoId] has `provision` tasks, so the provisioner can skip its
  /// visible step for repos with nothing to run.
  Future<bool> hasProvisionTasks(String workspaceId, String repoId);

  /// Repos bound to a definition with a stack. A space holding one needs its
  /// worktree before any agent joins, because Start needs it.
  Future<Set<String>> reposWithEnvironments(String workspaceId);

  /// Copies `seedFiles`, then runs `provision` tasks.
  ///
  /// [onOutput] receives what the tasks print, as they print it.
  ///
  /// Throws [WorktreeTaskException] on failure, which fails provisioning.
  Future<void> runProvision(
    WorktreeTaskContext context, {
    void Function(String line)? onOutput,
  });

  /// Runs `archive` tasks. Never throws: these run on GC paths with no one to
  /// answer, so a failure is recorded and deletion proceeds.
  Future<void> runArchive(WorktreeTaskContext context);

  /// Tears down the space's environment before its worktrees go away. Never
  /// throws, and is safe to call when there is nothing to tear down.
  Future<void> beforeRelease(String workspaceId, String spaceId);
}
