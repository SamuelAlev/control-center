/// GitHub App bot accounts use the `login[bot]` convention (e.g.
/// `renovate[bot]`, `dependabot[bot]`, `github-actions[bot]`). GraphQL
/// `user(login:)` cannot resolve them — they are `Bot` nodes, not `User`.
bool isGitHubBotLogin(String login) => login.toLowerCase().endsWith('[bot]');

/// Login, plus GitHub display name in parentheses when it differs from [login].
///
/// Used by reviewer/assignee pickers so `octocat (The Octocat)` is
/// distinguishable from a bare login. Empty, whitespace-only, or identical
/// names (case-insensitive) are omitted.
String formatGitHubLoginWithName(String login, String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return login;
  }
  if (trimmed.toLowerCase() == login.toLowerCase()) {
    return login;
  }
  return '$login ($trimmed)';
}

/// Typed representation of a GitHub user (login, avatar, optional display
/// name).
///
/// Lives in the shared kernel because it is used across many features on both
/// sides of the RPC boundary — the server-side GitHub network models embed it,
/// and the client renders it (org-member pickers, reviewer/assignee flyouts,
/// user profiles). Keeping it here means client presentation no longer reaches
/// into the server-only `cc_infra` package for the type (FINDINGS §20.9).
class GitHubUser {
  /// Creates a [GitHubUser].
  const GitHubUser({required this.login, required this.avatarUrl, this.name});

  /// Creates a [GitHubUser] from a JSON map (GitHub REST shape).
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

  /// [login], plus display name in parentheses when it differs from [login].
  String get loginWithName => formatGitHubLoginWithName(login, name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubUser &&
          other.login == login &&
          other.avatarUrl == avatarUrl &&
          other.name == name;

  @override
  int get hashCode => Object.hash(login, avatarUrl, name);
}
