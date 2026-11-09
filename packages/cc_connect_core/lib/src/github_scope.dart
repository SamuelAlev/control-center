/// The GitHub REST API version Connect pins (`x-github-api-version`). The
/// server side keeps the same value as `gitHubRestApiVersion` in
/// `cc_domain`; bump both together.
const String githubApiVersion = '2022-11-28';

/// What a single-repository GitHub token minted for Control Center may do.
///
/// Every token is for exactly one repository. Which scope a caller receives
/// is clamped to the role the accountable human holds on that repository, so
/// a mint never grants more than the person behind it already has.
enum GitHubTokenScope {
  /// Read code, PRs and CI. Agent sandboxes, pipeline steps, clones.
  read('read', {
    'metadata': 'read',
    'contents': 'read',
    'pull_requests': 'read',
    'checks': 'read',
    'actions': 'read',
    'statuses': 'read',
  }),

  /// [read] plus PR reviews and comments. Agent sandboxes whose human can
  /// push.
  review('review', {
    'metadata': 'read',
    'contents': 'read',
    'pull_requests': 'write',
    'checks': 'read',
    'actions': 'read',
    'statuses': 'read',
  }),

  /// Issue and PR comments for automated replies. Held by the server, never
  /// placed in an agent's environment.
  bot('bot', {'metadata': 'read', 'issues': 'write', 'pull_requests': 'write'}),

  /// Push and open PRs. The agent run gateway and human terminal rigs.
  write('write', {
    'metadata': 'read',
    'contents': 'write',
    'pull_requests': 'write',
  });

  const GitHubTokenScope(this.wire, this.permissions);

  /// The wire spelling.
  final String wire;

  /// The exact GitHub permission map requested for this scope.
  final Map<String, String> permissions;

  /// Parses a wire value; null when unknown.
  static GitHubTokenScope? fromWire(String? wire) {
    for (final scope in values) {
      if (scope.wire == wire) {
        return scope;
      }
    }
    return null;
  }

  /// Whether this scope can write anything.
  bool get writes => this != read;
}

/// A person's role on a repository, from GitHub's `permissions` object.
enum GitHubRepoRole {
  /// No access.
  none,

  /// `pull`.
  pull,

  /// `triage`.
  triage,

  /// `push`.
  push,

  /// `maintain`.
  maintain,

  /// `admin`.
  admin;

  /// The highest role GitHub's `repo.permissions` map reports.
  static GitHubRepoRole fromPermissions(Object? permissions) {
    if (permissions is! Map) {
      return none;
    }
    bool has(String key) => permissions[key] == true;
    if (has('admin')) {
      return admin;
    }
    if (has('maintain')) {
      return maintain;
    }
    if (has('push')) {
      return push;
    }
    if (has('triage')) {
      return triage;
    }
    if (has('pull')) {
      return pull;
    }
    return none;
  }

  /// Whether this role includes push.
  bool get canPush => index >= push.index;
}

/// The highest scope at or below [requested] that [role] allows, or null
/// when the role allows nothing.
///
/// Any scope that writes needs `push`, because App permissions are coarser
/// than repository roles. Reading a public repository through the app needs
/// `triage`, so the shared app is never a free read token for any public
/// repository on GitHub.
GitHubTokenScope? clampGitHubScope({
  required GitHubTokenScope requested,
  required GitHubRepoRole role,
  required bool repoIsPublic,
}) {
  if (requested.writes && role.canPush) {
    return requested;
  }
  final readFloor = repoIsPublic ? GitHubRepoRole.triage : GitHubRepoRole.pull;
  if (role.index >= readFloor.index) {
    return GitHubTokenScope.read;
  }
  return null;
}

/// Whether a `/applications/{client_id}/token/scoped` answer is the token
/// that was asked for: exactly [permissions], and nothing that says it
/// reaches more than repository [repoId]. A selection other than `selected`
/// or a repository list other than `[repoId]` refuses it.
bool scopedTokenMatches(
  Map<Object?, Object?> json, {
  required int repoId,
  required Map<String, String> permissions,
}) {
  final installation = json['installation'];
  final scoped = installation is Map
      ? installation['permissions']
      : json['permissions'];
  if (scoped is! Map || scoped.length != permissions.length) {
    return false;
  }
  for (final entry in permissions.entries) {
    if (scoped[entry.key] != entry.value) {
      return false;
    }
  }
  final selection =
      json['repository_selection'] ??
      (installation is Map ? installation['repository_selection'] : null);
  if (selection != null && selection != 'selected') {
    return false;
  }
  final repositories =
      json['repositories'] ??
      (installation is Map ? installation['repositories'] : null);
  if (repositories != null) {
    if (repositories is! List || repositories.length != 1) {
      return false;
    }
    final only = repositories.single;
    if ((only is Map ? only['id'] : only) != repoId) {
      return false;
    }
  }
  return true;
}

/// A GitHub owner or repository name segment: no `..`, slashes, percent
/// escapes or anything GitHub itself would refuse (`.github` is fine).
bool isGitHubSegment(String value) =>
    value.isNotEmpty &&
    value.length <= 100 &&
    RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value) &&
    value != '.' &&
    !value.contains('..');
