/// A repository registered with the app.
///
/// Repos live globally (managed in Settings → Repositories) and can be
/// linked to any number of workspaces via the workspace-repos relation.
class Repo {
  /// Creates a new [Repo].
  Repo({
    required this.id,
    required this.name,
    required this.path,
    required this.githubOwner,
    required this.githubRepoName,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(name.isNotEmpty, 'Repo name must not be empty'),
       assert(path.isNotEmpty, 'Repo path must not be empty');

  /// Unique identifier.
  final String id;

  /// Human-readable name (defaults to `owner/repo`).
  final String name;

  /// Absolute path to the local working tree.
  final String path;

  /// GitHub owner parsed from the `origin` remote.
  final String githubOwner;

  /// GitHub repo name parsed from the `origin` remote.
  final String githubRepoName;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// True when both [githubOwner] and [githubRepoName] are set.
  bool get hasGitHubRemote =>
      githubOwner.isNotEmpty && githubRepoName.isNotEmpty;

  /// `owner/repo` when known, otherwise the local path.
  String get fullName =>
      hasGitHubRemote ? '$githubOwner/$githubRepoName' : path;

  /// Copy with.
  Repo copyWith({
    String? id,
    String? name,
    String? path,
    String? githubOwner,
    String? githubRepoName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Repo(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      githubOwner: githubOwner ?? this.githubOwner,
      githubRepoName: githubRepoName ?? this.githubRepoName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Repo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
