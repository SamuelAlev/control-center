/// Status of the local GitHub CLI (`gh`) installation and auth state.
class GitHubCliStatus {
  /// Creates a [GitHubCliStatus] with optional defaults.
  const GitHubCliStatus({
    this.isInstalled = false,
    this.isAuthenticated = false,
    this.username = '',
    this.token = '',
  });

  /// Whether the `gh` binary is installed.
  final bool isInstalled;

  /// Whether `gh` is currently authenticated.
  final bool isAuthenticated;

  /// The GitHub username resolved from `gh auth status`.
  final String username;

  /// The token resolved from `gh auth token`.
  final String token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubCliStatus &&
          runtimeType == other.runtimeType &&
          isInstalled == other.isInstalled &&
          isAuthenticated == other.isAuthenticated &&
          username == other.username &&
          token == other.token;

  @override
  int get hashCode =>
      Object.hash(isInstalled, isAuthenticated, username, token);

  @override
  String toString() =>
      'GitHubCliStatus(isInstalled: $isInstalled, isAuthenticated: $isAuthenticated, username: $username, token: ****)';

  /// Copy with.
  GitHubCliStatus copyWith({
    bool? isInstalled,
    bool? isAuthenticated,
    String? username,
    String? token,
  }) {
    return GitHubCliStatus(
      isInstalled: isInstalled ?? this.isInstalled,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      token: token ?? this.token,
    );
  }
}

