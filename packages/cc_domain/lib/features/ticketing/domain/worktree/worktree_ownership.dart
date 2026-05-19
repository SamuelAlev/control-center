/// How a worktree on disk relates to Control Center.
enum WorktreeOwnership {
  /// Created and tracked by Control Center (strong metadata or a tracked row).
  ccManaged,

  /// A git worktree Control Center did not create (a foreign checkout / another
  /// tool's worktree). Hidden from the dashboard by default.
  external,

  /// In a Control Center layout but with no tracking record or metadata — most
  /// likely a worktree from before tracking existed. Surfaced (it may be ours)
  /// but flagged so it can be reconciled or cleaned up.
  unknownLegacy;

  /// Parses a stored value, defaulting to [unknownLegacy].
  static WorktreeOwnership fromStorage(String? value) => switch (value) {
    'ccManaged' => WorktreeOwnership.ccManaged,
    'external' => WorktreeOwnership.external,
    'unknownLegacy' => WorktreeOwnership.unknownLegacy,
    _ => WorktreeOwnership.unknownLegacy,
  };

  /// Serializes for storage.
  String toStorageString() => name;
}

/// The signals a [WorktreeOwnershipClassifier] weighs. Strong CC metadata wins;
/// path heuristics against known layouts are the fallback.
class WorktreeOwnershipSignals {
  /// Creates a [WorktreeOwnershipSignals].
  const WorktreeOwnershipSignals({
    required this.path,
    this.trackedByCc = false,
    this.ccCreatedAt,
    this.createdWithAgent = false,
    this.pushTarget,
    this.ccWorktreeRoots = const [],
    this.legacyWorktreeRoots = const [],
  });

  /// Absolute path of the worktree on disk.
  final String path;

  /// Whether Control Center has a tracking row for this worktree.
  final bool trackedByCc;

  /// When Control Center created it, if recorded (strong CC-managed signal).
  final DateTime? ccCreatedAt;

  /// Whether it was created together with an agent (strong CC-managed signal).
  final bool createdWithAgent;

  /// The git push target, if known. A push target outside the workspace's repos
  /// is a hint the worktree is foreign.
  final String? pushTarget;

  /// Known Control Center worktree root directories for this workspace.
  final List<String> ccWorktreeRoots;

  /// Known older / legacy worktree root directories.
  final List<String> legacyWorktreeRoots;
}

/// Classifies a worktree as [WorktreeOwnership.ccManaged],
/// [WorktreeOwnership.external], or [WorktreeOwnership.unknownLegacy].
class WorktreeOwnershipClassifier {
  /// Creates a [WorktreeOwnershipClassifier].
  const WorktreeOwnershipClassifier();

  /// Classifies a worktree from its [signals].
  WorktreeOwnership classify(WorktreeOwnershipSignals signals) {
    // Strong metadata first: a tracking row or CC creation metadata is decisive.
    if (signals.trackedByCc ||
        signals.ccCreatedAt != null ||
        signals.createdWithAgent) {
      return WorktreeOwnership.ccManaged;
    }
    // Path heuristics: inside a current CC layout but untracked → legacy ours;
    // inside a known legacy root → legacy ours; anywhere else → foreign.
    final path = _normalize(signals.path);
    final inCcLayout = signals.ccWorktreeRoots.any(
      (root) => _under(_normalize(root), path),
    );
    if (inCcLayout) {
      return WorktreeOwnership.unknownLegacy;
    }
    final inLegacyLayout = signals.legacyWorktreeRoots.any(
      (root) => _under(_normalize(root), path),
    );
    if (inLegacyLayout) {
      return WorktreeOwnership.unknownLegacy;
    }
    return WorktreeOwnership.external;
  }

  static bool _under(String root, String path) =>
      path == root || path.startsWith('$root/');

  static String _normalize(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }
}

/// Decides which worktree ownership classes are shown on the dashboard.
///
/// Default: Control-Center-managed and legacy worktrees are shown; foreign
/// ("external") worktrees are hidden, so another tool's checkout never clutters
/// the agent fleet view.
class WorktreeVisibilityPolicy {
  /// Creates a [WorktreeVisibilityPolicy].
  const WorktreeVisibilityPolicy({
    this.showExternal = false,
    this.showUnknownLegacy = true,
  });

  /// Whether foreign worktrees are shown.
  final bool showExternal;

  /// Whether untracked legacy worktrees are shown.
  final bool showUnknownLegacy;

  /// Whether a worktree of [ownership] is visible on the dashboard.
  bool isVisible(WorktreeOwnership ownership) => switch (ownership) {
    WorktreeOwnership.ccManaged => true,
    WorktreeOwnership.external => showExternal,
    WorktreeOwnership.unknownLegacy => showUnknownLegacy,
  };
}
