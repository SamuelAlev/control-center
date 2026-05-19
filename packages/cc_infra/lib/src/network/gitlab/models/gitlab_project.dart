/// A group reference, as GitLab spells it in two different places.
///
/// `GET /projects/:id` reports groups a project is shared with under
/// `shared_with_groups` with `group_`-prefixed keys, while an approval rule
/// reports the same concept under `groups` with bare keys. Both are read here
/// so the mapper sees one shape.
class GitLabGroupRef {
  /// Creates a [GitLabGroupRef].
  const GitLabGroupRef({
    required this.id,
    required this.name,
    required this.fullPath,
    this.avatarUrl = '',
    this.webUrl = '',
  });

  /// Reads the bare shape (`{id, name, full_path}`), used by approval rules
  /// and by `GET /groups`.
  factory GitLabGroupRef.fromJson(Map<String, dynamic> json) => GitLabGroupRef(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    fullPath: json['full_path'] as String? ?? json['path'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    webUrl: json['web_url'] as String? ?? '',
  );

  /// Reads the `shared_with_groups` shape (`{group_id, group_name,
  /// group_full_path}`).
  factory GitLabGroupRef.fromShareJson(Map<String, dynamic> json) =>
      GitLabGroupRef(
        id: (json['group_id'] as num?)?.toInt() ?? 0,
        name: json['group_name'] as String? ?? '',
        fullPath: json['group_full_path'] as String? ?? '',
      );

  /// Reads an array of the bare shape.
  static List<GitLabGroupRef> listFromJson(Object? raw) {
    if (raw is! List) {
      return const <GitLabGroupRef>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(GitLabGroupRef.fromJson)
        .toList(growable: false);
  }

  /// Reads an array of the `shared_with_groups` shape.
  static List<GitLabGroupRef> listFromShareJson(Object? raw) {
    if (raw is! List) {
      return const <GitLabGroupRef>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(GitLabGroupRef.fromShareJson)
        .toList(growable: false);
  }

  /// Numeric group id.
  final int id;

  /// Display name (`Platform`).
  final String name;

  /// Slash-separated path (`acme/platform`) — the stable slug used as the
  /// team key everywhere in this adapter.
  final String fullPath;

  /// Group avatar URL. Empty when unset or not supplied.
  final String avatarUrl;

  /// Link to the group page. Empty when not supplied.
  final String webUrl;
}

/// The namespace (user or group) a project lives under.
class GitLabNamespace {
  /// Creates a [GitLabNamespace].
  const GitLabNamespace({
    required this.id,
    required this.name,
    required this.fullPath,
    required this.kind,
    this.avatarUrl = '',
  });

  /// Reads a [GitLabNamespace] off a decoded JSON object.
  factory GitLabNamespace.fromJson(Map<String, dynamic> json) =>
      GitLabNamespace(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        fullPath: json['full_path'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
      );

  /// Numeric namespace id.
  final int id;

  /// Display name.
  final String name;

  /// Slash-separated path (`acme/platform`).
  final String fullPath;

  /// `group` or `user`. Only a `group` namespace can act as a reviewer team.
  final String kind;

  /// Namespace avatar URL. Empty when unset.
  final String avatarUrl;
}

/// A GitLab project, as returned by `GET /projects/:id`.
///
/// Fetched for three things this adapter cannot derive: the web base URL an
/// upload path hangs off, the default branch, and the groups the project is
/// shared with (which stand in for GitHub's reviewer teams).
class GitLabProject {
  /// Creates a [GitLabProject].
  const GitLabProject({
    required this.id,
    required this.pathWithNamespace,
    required this.webUrl,
    this.name = '',
    this.defaultBranch = '',
    this.namespace,
    this.sharedWithGroups = const <GitLabGroupRef>[],
  });

  /// Reads a [GitLabProject] off a decoded JSON object.
  factory GitLabProject.fromJson(Map<String, dynamic> json) => GitLabProject(
    id: (json['id'] as num?)?.toInt() ?? 0,
    pathWithNamespace: json['path_with_namespace'] as String? ?? '',
    webUrl: json['web_url'] as String? ?? '',
    name: json['name'] as String? ?? '',
    defaultBranch: json['default_branch'] as String? ?? '',
    namespace: json['namespace'] is Map<String, dynamic>
        ? GitLabNamespace.fromJson(json['namespace'] as Map<String, dynamic>)
        : null,
    sharedWithGroups: GitLabGroupRef.listFromShareJson(
      json['shared_with_groups'],
    ),
  );

  /// Numeric project id.
  final int id;

  /// `namespace/project`, the human-readable project coordinate.
  final String pathWithNamespace;

  /// Absolute URL of the project's web page, without a trailing slash. Upload
  /// URLs are relative to this.
  final String webUrl;

  /// Project display name.
  final String name;

  /// Default branch name (`main`).
  final String defaultBranch;

  /// The namespace the project lives under, when supplied.
  final GitLabNamespace? namespace;

  /// Groups the project has been shared with.
  final List<GitLabGroupRef> sharedWithGroups;
}
