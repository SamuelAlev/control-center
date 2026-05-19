/// A project or group member, as returned by `GET /projects/:id/members/all`
/// and `GET /groups/:id/members/all`.
///
/// Shaped like a user with an access level bolted on — GitLab inlines the user
/// fields rather than nesting a `user` object, which is why this is its own
/// model rather than a `GitLabUser`.
class GitLabMember {
  /// Creates a [GitLabMember].
  const GitLabMember({
    required this.id,
    required this.username,
    this.name = '',
    this.avatarUrl = '',
    this.webUrl = '',
    this.state = '',
    this.accessLevel = 0,
  });

  /// Reads a [GitLabMember] off a decoded JSON object.
  factory GitLabMember.fromJson(Map<String, dynamic> json) => GitLabMember(
    id: (json['id'] as num?)?.toInt() ?? 0,
    username: json['username'] as String? ?? '',
    name: json['name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    webUrl: json['web_url'] as String? ?? '',
    state: json['state'] as String? ?? '',
    accessLevel: (json['access_level'] as num?)?.toInt() ?? 0,
  );

  /// Access level below which a member cannot be assigned or asked to review
  /// (GitLab's Reporter level). Guests are excluded by this floor.
  static const int reporterAccessLevel = 20;

  /// Numeric user id.
  final int id;

  /// The `@handle`.
  final String username;

  /// Display name.
  final String name;

  /// Avatar URL. Empty when unset.
  final String avatarUrl;

  /// Link to the profile page.
  final String webUrl;

  /// Account state (`active`, `blocked`, …).
  final String state;

  /// GitLab access level: 10 Guest, 20 Reporter, 30 Developer, 40 Maintainer,
  /// 50 Owner.
  final int accessLevel;

  /// Whether this member can be an assignee or reviewer: an active account at
  /// Reporter or above.
  bool get isAssignable =>
      accessLevel >= reporterAccessLevel &&
      username.isNotEmpty &&
      (state.isEmpty || state == 'active');
}
