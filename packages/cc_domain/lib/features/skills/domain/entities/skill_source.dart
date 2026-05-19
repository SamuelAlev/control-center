/// A GitHub repository the operator registered as a skill source.
///
/// Sources are workspace-scoped (skills install into a workspace, so the
/// catalogs you browse in one workspace never leak into another). The row is
/// provenance + cache metadata only: it never grants trust — every install
/// still passes the mandatory scan gate over the fetched bytes.
class SkillSource {
  /// Creates a [SkillSource].
  const SkillSource({
    required this.id,
    required this.workspaceId,
    required this.owner,
    required this.repo,
    required this.url,
    required this.createdAt,
    this.description = '',
    this.defaultBranch = '',
    this.starCount = 0,
    this.skillCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  /// Row id (UUID).
  final String id;

  /// Workspace scope (required — isolation invariant).
  final String workspaceId;

  /// GitHub owner (user or org login).
  final String owner;

  /// GitHub repository name.
  final String repo;

  /// The URL the operator entered (normalized `https://github.com/o/r`).
  final String url;

  /// Repository description (untrusted, captured at add/sync time).
  final String description;

  /// The repo's default branch (the browsing ref).
  final String defaultBranch;

  /// Star count at add/sync time (untrusted popularity signal).
  final int starCount;

  /// Skills discovered at the last sync (0 = never synced or none found).
  final int skillCount;

  /// When the catalog was last listed.
  final DateTime? lastSyncedAt;

  /// The last sync's error, if any (surfaced in the UI rail).
  final String? lastError;

  /// Row creation time.
  final DateTime createdAt;

  /// `owner/repo`.
  String get fullName => '$owner/$repo';

  SkillSource copyWith({
    String? description,
    String? defaultBranch,
    int? starCount,
    int? skillCount,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearLastError = false,
    bool clearLastSyncedAt = false,
  }) => SkillSource(
    id: id,
    workspaceId: workspaceId,
    owner: owner,
    repo: repo,
    url: url,
    createdAt: createdAt,
    description: description ?? this.description,
    defaultBranch: defaultBranch ?? this.defaultBranch,
    starCount: starCount ?? this.starCount,
    skillCount: skillCount ?? this.skillCount,
    lastSyncedAt: clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
    lastError: clearLastError ? null : (lastError ?? this.lastError),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillSource &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          owner == other.owner &&
          repo == other.repo;

  @override
  int get hashCode => Object.hash(id, workspaceId, owner, repo);

  @override
  String toString() => 'SkillSource($workspaceId, $fullName)';
}
