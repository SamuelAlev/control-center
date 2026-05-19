/// How an isolated subagent's changes are captured and merged back.
enum IsolationMergeMode {
  /// Commit the changes onto a `cc/task/<id>` branch, merged back by cherry
  /// pick / merge. Preserves history.
  branch,

  /// Capture the changes as a `<id>.patch` artifact, applied with `git apply`.
  patch,
}

/// The git baseline an isolated spawn is diffed against — captured once before
/// any spawn mutates the worktree.
class WorktreeBaseline {
  /// Creates a [WorktreeBaseline].
  const WorktreeBaseline({required this.repoRoot, required this.headSha});

  /// Absolute path to the git repository root.
  final String repoRoot;

  /// The `HEAD` commit sha at baseline capture.
  final String headSha;
}

/// Resolved repo + baseline shared by every isolated spawn in one call.
class IsolationContext {
  /// Creates an [IsolationContext].
  const IsolationContext({required this.repoRoot, required this.baseline});

  /// Absolute path to the git repository root.
  final String repoRoot;

  /// The baseline isolated spawns are diffed against.
  final WorktreeBaseline baseline;
}

/// Outcome of running one subagent inside an isolation worktree and capturing
/// its changes.
class IsolatedRunResult {
  /// Creates an [IsolatedRunResult].
  const IsolatedRunResult({
    required this.agentId,
    required this.exitCode,
    this.aborted = false,
    this.branchName,
    this.patchPath,
    this.nestedPatches = const [],
    this.error,
    this.description,
  });

  /// Stable id of the isolated spawn.
  final String agentId;

  /// Exit code of the work that ran inside the worktree.
  final int exitCode;

  /// Whether the run was aborted before completing.
  final bool aborted;

  /// Branch holding the captured commit (branch mode), or null.
  final String? branchName;

  /// Path to the captured `.patch` artifact (patch mode), or null.
  final String? patchPath;

  /// Paths of captured nested-repo patches (reserved; empty for now).
  final List<String> nestedPatches;

  /// Failure detail when capture failed despite a clean run.
  final String? error;

  /// Human description carried onto the branch commit (branch mode).
  final String? description;

  /// Whether the work itself succeeded (exit 0, not aborted, no capture error).
  bool get succeeded => exitCode == 0 && !aborted && error == null;
}

/// Result of merging an [IsolatedRunResult] back into the parent repo.
class IsolationMergeOutcome {
  /// Creates an [IsolationMergeOutcome].
  const IsolationMergeOutcome({
    required this.summary,
    required this.changesApplied,
    required this.hadChanges,
  });

  /// Trailing summary appended to the subagent's result text.
  final String summary;

  /// Tri-state apply outcome: `true` = merged (or nothing to apply) cleanly;
  /// `false` = attempted and failed (artifacts preserved); `null` = the caller
  /// skipped merging entirely.
  final bool? changesApplied;

  /// Whether any real change was applied to the parent repo.
  final bool hadChanges;
}

/// Per-subagent copy-on-write worktree isolation with merge-back.
///
/// Lifecycle: [prepareContext] (capture baseline) → [runIsolated] (spawn in a
/// throwaway worktree, capture branch/patch, tear the worktree down) →
/// [mergeChanges] (apply the captured changes to the parent repo). Makes "spawn
/// N writers in parallel on the same repo" safe for orchestrate / pipeline
/// modes.
abstract interface class WorktreeIsolationRunner {
  /// Resolves the git repo root for [cwd] and captures the worktree baseline.
  /// Throws when [cwd] is not inside a git repository.
  Future<IsolationContext> prepareContext(String cwd);

  /// Runs [run] inside a fresh worktree checked out at the baseline, then
  /// captures its changes per [mergeMode] (a `cc/task/<agentId>` branch, or a
  /// `<agentId>.patch` written under [artifactsDir]). The worktree is always
  /// torn down before returning.
  Future<IsolatedRunResult> runIsolated({
    required IsolationContext context,
    required String agentId,
    required IsolationMergeMode mergeMode,
    required String artifactsDir,
    required Future<int> Function(String worktreeDir) run,
    String? description,
  });

  /// Applies the changes captured by [runIsolated] back to the parent repo. On
  /// a branch-mode conflict the branch is preserved for manual resolution.
  Future<IsolationMergeOutcome> mergeChanges({
    required IsolatedRunResult result,
    required String repoRoot,
    required IsolationMergeMode mergeMode,
  });
}
