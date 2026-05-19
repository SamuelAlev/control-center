/// Typed representation of a GitHub user.
/// Typed representation of a GitHub user.
class GitHubUser {
  /// Creates a [GitHubUser].
  const GitHubUser({
    required this.login,
    required this.avatarUrl,
    this.name,
  });

  /// Creates a [GitHubUser] from a JSON map.
  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      login: json['login'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      name: json['name'] as String?,
    );
  }

  /// Serializes this user back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'login': login,
    'avatar_url': avatarUrl,
    if (name != null) 'name': name,
  };

  /// The user's login name.
  final String login;

  /// URL to the user's avatar image.
  final String avatarUrl;

  /// The user's display name (may be null from some API endpoints).
  final String? name;
}
