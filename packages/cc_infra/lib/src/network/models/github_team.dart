/// Typed representation of a GitHub team (used as a PR review-request target).
///
/// `slug` — not `name` — is the identifier the REST `requested_reviewers`
/// endpoint expects in its `team_reviewers` array and what `onBehalfOf` /
/// CODEOWNERS reference. `name` is the human label shown in the UI.
class GitHubTeam {
  /// Creates a [GitHubTeam].
  const GitHubTeam({
    required this.name,
    required this.slug,
    this.avatarUrl = '',
  });

  /// Creates a [GitHubTeam] from a JSON map.
  factory GitHubTeam.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final slug = json['slug'] as String? ?? '';
    return GitHubTeam(
      name: name.isNotEmpty ? name : slug,
      slug: slug,
      avatarUrl: githubTeamAvatarUrlFromJson(json),
    );
  }

  /// Serializes this team back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'slug': slug,
    if (avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
  };

  /// Human-readable team name (e.g. "Frontend platform").
  final String name;

  /// URL-safe team identifier (e.g. "frontend-platform").
  final String slug;

  /// Team logo URL. Empty when the payload had neither `avatar_url` /
  /// `avatarUrl` nor a numeric `id` to synthesize the CDN path from.
  final String avatarUrl;
}

/// GitHub serves team logos (and identicons) at this CDN path, keyed by
/// numeric team id. REST payloads expose `id` but not `avatar_url`; GraphQL
/// `Team.avatarUrl` already returns this URI.
String githubTeamAvatarUrl(int teamId) =>
    teamId > 0 ? 'https://avatars.githubusercontent.com/t/$teamId' : '';

/// Resolves a team avatar from a REST or GraphQL JSON map.
///
/// Prefers an explicit `avatar_url` / `avatarUrl`, then synthesizes the CDN
/// URL from GraphQL `databaseId` or REST `id`.
String githubTeamAvatarUrlFromJson(Map<String, dynamic> json) {
  final direct =
      json['avatar_url'] as String? ?? json['avatarUrl'] as String? ?? '';
  if (direct.isNotEmpty) {
    return direct;
  }
  return githubTeamAvatarUrl(_jsonInt(json['databaseId'] ?? json['id']));
}

int _jsonInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
