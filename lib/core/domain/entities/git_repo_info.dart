/// Immutable metadata about a locally-checked-out Git repository.
///
/// Created by inspecting a repo path and parsing its remote origin.
class GitRepoInfo {
  /// Creates a [GitRepoInfo] from parsed remote and local path data.
  const GitRepoInfo({
    required this.path,
    required this.owner,
    required this.repoName,
    required this.branch,
  });

  /// Absolute path to the repository on disk.
  final String path;

  /// GitHub owner (organisation or user).
  final String owner;

  /// Repository name on GitHub.
  final String repoName;

  /// Current checked-out branch.
  final String branch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitRepoInfo &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          owner == other.owner &&
          repoName == other.repoName &&
          branch == other.branch;

  @override
  int get hashCode => Object.hash(path, owner, repoName, branch);
}

/// Thrown when a repo cannot be inspected or its remote is unrecognised.
class GitRepoInspectionException implements Exception {
  /// Creates a [GitRepoInspectionException] with [message].
  const GitRepoInspectionException(this.message);

  /// Human-readable failure reason.
  final String message;

  @override
  String toString() => message;
}

/// Parses a GitHub SSH or HTTPS remote [url] into `(owner, repoName)`.
///
/// Returns `null` when the URL does not point to GitHub.
(String, String)? parseGitHubRemote(String url) {
  final match = RegExp(
    r'github\.com[:/]+([^/]+)/([^/]+?)(?:\.git)?/?$',
  ).firstMatch(url);
  if (match == null) {
    return null;
  }

  return (match.group(1)!, match.group(2)!);
}
