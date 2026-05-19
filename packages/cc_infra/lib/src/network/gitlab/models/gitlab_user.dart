/// A GitLab user, as embedded by nearly every REST v4 payload (`author`,
/// `assignees`, `reviewers`, `approved_by[].user`, `notes[].author`, …) and as
/// returned standalone by `GET /user` and `GET /users`.
///
/// A dumb wire holder: no domain semantics live here, the mapper owns those.
class GitLabUser {
  /// Creates a [GitLabUser].
  const GitLabUser({
    required this.id,
    required this.username,
    this.name = '',
    this.avatarUrl = '',
    this.webUrl = '',
    this.state = '',
  });

  /// Reads a [GitLabUser] off a decoded JSON object.
  factory GitLabUser.fromJson(Map<String, dynamic> json) => GitLabUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    username: json['username'] as String? ?? '',
    name: json['name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    webUrl: json['web_url'] as String? ?? '',
    state: json['state'] as String? ?? '',
  );

  /// Reads a [GitLabUser] from [raw] when it is a JSON object, else null.
  ///
  /// GitLab omits `author`/`assignee` entirely (rather than sending null) on
  /// some payloads, so every embedded-user read goes through this.
  static GitLabUser? maybeFromJson(Object? raw) =>
      raw is Map<String, dynamic> ? GitLabUser.fromJson(raw) : null;

  /// Reads a JSON array of users, skipping anything that is not an object.
  static List<GitLabUser> listFromJson(Object? raw) {
    if (raw is! List) {
      return const <GitLabUser>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(GitLabUser.fromJson)
        .toList(growable: false);
  }

  /// Numeric, instance-wide user id. This is what every `*_ids` write
  /// parameter (`assignee_ids`, `reviewer_ids`) expects.
  final int id;

  /// The `@handle` — GitLab's equivalent of a GitHub login.
  final String username;

  /// Display name (may be empty on minimal payloads).
  final String name;

  /// Absolute avatar URL. Empty when the user has no avatar set.
  final String avatarUrl;

  /// Link to the user's profile page.
  final String webUrl;

  /// Account state (`active`, `blocked`, …). Empty when not supplied.
  final String state;
}
