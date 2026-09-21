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

/// Operator grant to exec inside a writable tree (exception to the sandbox
/// writable-dir exec block).
///
/// macOS denies `process-exec` under `$HOME`/`/tmp` (closes TOCTOU); CoW
/// worktrees need a per-tree grant after ask. Widens to agent-written binaries
/// too. [path] is symlink-resolved (kernel matching).
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
