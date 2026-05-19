/// Typed representation of a GitHub team (used as a PR review-request target).
///
/// `slug` — not `name` — is the identifier the REST `requested_reviewers`
/// endpoint expects in its `team_reviewers` array, and what `onBehalfOf` /
/// CODEOWNERS reference. `name` is the human label shown in the UI.
class GitHubTeam {
  /// Creates a [GitHubTeam].
  const GitHubTeam({required this.name, required this.slug});

  /// Creates a [GitHubTeam] from a JSON map.
  factory GitHubTeam.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final slug = json['slug'] as String? ?? '';
    return GitHubTeam(name: name.isNotEmpty ? name : slug, slug: slug);
  }

  /// Serializes this team back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{'name': name, 'slug': slug};

  /// Human-readable team name (e.g. "Frontend platform").
  final String name;

  /// URL-safe team identifier (e.g. "frontend-platform").
  final String slug;
}
