/// Graduated membership role of a human user inside one workspace.
///
/// Roles are ordered by privilege ([rank]); every access decision at the op
/// chokepoint reduces to "is the caller's role at least X". The five levels
/// are the whole role model — per-object ACLs beyond the per-repo grants are
/// deliberately out of scope.
enum WorkspaceRole {
  /// Full control, including workspace deletion and ownership transfer.
  /// Exactly one member holds this per workspace (`Workspace.ownerUserId`).
  owner(4),

  /// Manages members, invites, settings, and destructive operations.
  admin(3),

  /// Day-to-day read-write collaborator: messages, tickets, agent runs.
  member(2),

  /// Read-only across the workspace; may not mutate anything.
  viewer(1),

  /// Read-only like [viewer], but additionally subject to secret-exclusion
  /// globs and per-repo grant checks on every code-bearing surface.
  guest(0);

  const WorkspaceRole(this.rank);

  /// Privilege order: higher outranks lower.
  final int rank;

  /// Whether this role grants at least [other]'s privileges.
  bool atLeast(WorkspaceRole other) => rank >= other.rank;

  /// Whether this role may perform ordinary mutations (send messages,
  /// create tickets, run agents).
  bool get canWrite => atLeast(WorkspaceRole.member);

  /// Whether this role may administer the workspace (members, invites,
  /// settings, destructive operations).
  bool get isAdmin => atLeast(WorkspaceRole.admin);

  /// Whether this role is read-only ([viewer] or [guest]).
  bool get isReadOnly => !canWrite;

  /// The value persisted in the database and sent over the wire.
  String get wireName => name;

  /// Parses a stored/wire value; returns null for unknown values so callers
  /// decide whether to deny or default.
  static WorkspaceRole? fromWire(String? value) {
    for (final role in WorkspaceRole.values) {
      if (role.name == value) {
        return role;
      }
    }
    return null;
  }
}
