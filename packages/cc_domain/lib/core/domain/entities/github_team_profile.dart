/// A GitHub user who belongs to a team.
class GitHubTeamMember {
  /// Creates a team member.
  GitHubTeamMember({
    required this.login,
    required this.name,
    required this.avatarUrl,
  }) {
    if (login.trim().isEmpty) {
      throw ArgumentError.value(login, 'login', 'must not be empty');
    }
  }

  /// Creates a member from GitHub GraphQL or the flat RPC wire shape.
  factory GitHubTeamMember.fromJson(Map<String, dynamic> json) {
    return GitHubTeamMember(
      login: json['login'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl:
          json['avatar_url'] as String? ?? json['avatarUrl'] as String? ?? '',
    );
  }

  /// Flat map used by the `github.teamProfile` RPC operation.
  Map<String, dynamic> toWire() => <String, dynamic>{
    'login': login,
    'name': name,
    'avatar_url': avatarUrl,
  };

  /// GitHub login.
  final String login;

  /// Display name, empty when the member has not set one.
  final String name;

  /// Avatar URL.
  final String avatarUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubTeamMember &&
          other.login == login &&
          other.name == name &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(login, name, avatarUrl);
}

/// A GitHub organization team and the members visible to the caller.
class GitHubTeamProfile {
  /// Creates a team profile.
  GitHubTeamProfile({
    required this.organization,
    required this.slug,
    required this.name,
    required this.avatarUrl,
    required this.url,
    required this.members,
    this.description,
    this.memberCount,
  }) {
    if (organization.trim().isEmpty) {
      throw ArgumentError.value(
        organization,
        'organization',
        'must not be empty',
      );
    }
    if (slug.trim().isEmpty) {
      throw ArgumentError.value(slug, 'slug', 'must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (memberCount != null && memberCount! < members.length) {
      throw ArgumentError.value(
        memberCount,
        'memberCount',
        'must be at least the number of returned members',
      );
    }
  }

  /// Creates a profile from a GitHub GraphQL team node.
  factory GitHubTeamProfile.fromGraphQl(
    Map<String, dynamic> json, {
    required String organization,
  }) {
    final membersConnection = json['members'] as Map<String, dynamic>?;
    final rawMembers = membersConnection?['nodes'] as List?;
    final slug = json['slug'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    return GitHubTeamProfile(
      organization: organization,
      slug: slug,
      name: name.isNotEmpty ? name : slug,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      url: json['url'] as String? ?? '',
      memberCount: (membersConnection?['totalCount'] as num?)?.toInt(),
      members: [
        for (final raw in rawMembers ?? const [])
          if (raw is Map<String, dynamic> &&
              (raw['login'] as String? ?? '').isNotEmpty)
            GitHubTeamMember.fromJson(raw),
      ],
    );
  }

  /// Rebuilds a profile from its [toWire] map.
  factory GitHubTeamProfile.fromWire(Map<String, dynamic> json) {
    final members = json['members'] as List?;
    return GitHubTeamProfile(
      organization: json['organization'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? '',
      url: json['url'] as String? ?? '',
      memberCount: (json['member_count'] as num?)?.toInt(),
      members: [
        for (final raw in members ?? const [])
          if (raw is Map)
            GitHubTeamMember.fromJson(raw.cast<String, dynamic>()),
      ],
    );
  }

  /// Flat map used by the `github.teamProfile` RPC operation.
  Map<String, dynamic> toWire() => <String, dynamic>{
    'organization': organization,
    'slug': slug,
    'name': name,
    'description': ?description,
    'avatar_url': avatarUrl,
    'url': url,
    'member_count': memberCount ?? members.length,
    'members': [for (final member in members) member.toWire()],
  };

  /// Organization login that owns the team.
  final String organization;

  /// Stable team slug.
  final String slug;

  /// Human-readable team name.
  final String name;

  /// Team description.
  final String? description;

  /// Team avatar URL.
  final String avatarUrl;

  /// GitHub team page URL.
  final String url;

  /// Members returned by GitHub. This may be a prefix when the team is large.
  final List<GitHubTeamMember> members;

  /// Total team members reported by GitHub.
  final int? memberCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubTeamProfile &&
          other.organization == organization &&
          other.slug == slug &&
          other.name == name &&
          other.description == description &&
          other.avatarUrl == avatarUrl &&
          other.url == url &&
          other.memberCount == memberCount &&
          _membersEqual(other.members, members);

  @override
  int get hashCode => Object.hash(
    organization,
    slug,
    name,
    description,
    avatarUrl,
    url,
    memberCount,
    Object.hashAll(members),
  );
}

bool _membersEqual(List<GitHubTeamMember> a, List<GitHubTeamMember> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
