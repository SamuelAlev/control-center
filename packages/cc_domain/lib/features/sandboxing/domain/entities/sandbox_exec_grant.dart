/// What the operator decided about executing binaries under a path.
enum SandboxExecGrantDecision {
  /// Binaries under the granted root may be executed.
  allow,

  /// Kept blocked, and do not ask again. Distinct from having no grant at
  /// all — an absent row means "ask", a `deny` row means "already asked".
  deny;

  /// The wire/storage name.
  String get wire => name;

  /// Parses a stored wire name, defaulting to the safe direction.
  static SandboxExecGrantDecision fromWire(String? value) =>
      SandboxExecGrantDecision.values.firstWhere(
        (d) => d.wire == value,
        orElse: () => SandboxExecGrantDecision.deny,
      );
}

/// An operator decision about running executables from inside a writable
/// directory tree — the exception to the sandbox's writable-dir exec block.
///
/// The macOS profile denies `process-exec` across all of `$HOME` and `/tmp`,
/// which closes the TOCTOU where a binary is copied or symlinked somewhere
/// writable and run from there. An agent's CoW worktree lives under `$HOME`, so
/// that block also catches every tool a checked-out repo installs for itself
/// (`node_modules/.bin/husky`, `.venv/bin/pytest`, …). A grant re-opens exec
/// for one worktree, and only after the operator was asked.
///
/// **A grant is a real widening.** It covers binaries the AGENT writes into
/// that tree, not only ones the package manager installed — which is precisely
/// the case the blanket block exists to stop. It is contained to a disposable
/// worktree rather than the user's own checkout, and it is per-workspace and
/// revocable, but it is not free and the confirmation copy says so.
///
/// [path] is stored **symlink-resolved**, because that is the spelling the
/// kernel matches an exec rule against; a grant written against an unresolved
/// path would emit a rule that never fires.
class SandboxExecGrant {
  /// Creates a [SandboxExecGrant].
  SandboxExecGrant({
    required this.id,
    required this.workspaceId,
    required this.path,
    required this.decision,
    required this.createdAt,
    this.createdBy,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'must not be empty — grants are workspace-scoped',
      );
    }
    if (path.isEmpty || !path.startsWith('/')) {
      throw ArgumentError.value(
        path,
        'path',
        'must be an absolute, symlink-resolved path',
      );
    }
  }

  /// Unique row id.
  final String id;

  /// Owning workspace. Grants never span workspaces: the same checkout
  /// registered in two workspaces is two decisions.
  final String workspaceId;

  /// The absolute, symlink-resolved directory tree the decision covers.
  final String path;

  /// Whether exec under [path] is allowed or kept blocked.
  final SandboxExecGrantDecision decision;

  /// Principal that made the decision.
  final String? createdBy;

  /// When the decision was made.
  final DateTime createdAt;

  /// Whether this grant covers [candidate] — the path itself or anything
  /// beneath it. Compares on segment boundaries so a grant on `/a/repo` does
  /// not swallow `/a/repo-secrets`.
  bool covers(String candidate) =>
      candidate == path || candidate.startsWith(path.endsWith('/') ? path : '$path/');

  /// Returns a copy with the given overrides.
  SandboxExecGrant copyWith({
    SandboxExecGrantDecision? decision,
    String? createdBy,
    DateTime? createdAt,
  }) => SandboxExecGrant(
    id: id,
    workspaceId: workspaceId,
    path: path,
    decision: decision ?? this.decision,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is SandboxExecGrant &&
      other.id == id &&
      other.workspaceId == workspaceId &&
      other.path == path &&
      other.decision == decision;

  @override
  int get hashCode => Object.hash(id, workspaceId, path, decision);

  @override
  String toString() =>
      'SandboxExecGrant($id, $workspaceId, $path, ${decision.wire})';
}
