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
  /// Read code, PRs and CI. Pipeline steps, clones, pollers.
  read('read', {
    'metadata': 'read',
    'contents': 'read',
    'pull_requests': 'read',
    'checks': 'read',
    'actions': 'read',
    'statuses': 'read',
  }),

  /// What an agent run reads GitHub with: [read] plus reading issues, and
  /// nothing that writes. Minted when the run's git or `gh` first asks its
  /// server for a repository it works on, and revoked when the run ends.
  ///
  /// An agent comments on its own pull request through the server
  /// (`comment_on_pull_request`, as the bot), opens one through the server
  /// (`open_pull_request`, on the requesting person's own token) and
  /// publishes reviews through `publish_review_to_github`: nothing in the
  /// sandbox can post, label, lock, edit or open anything on GitHub.
  review('review', {
    'metadata': 'read',
    'contents': 'read',
    'issues': 'read',
    'pull_requests': 'read',
    'checks': 'read',
    'actions': 'read',
    'statuses': 'read',
  }),

  /// Conversation on issues and pull requests, as the bot: comments on the
  /// conversation, labels, assignees and reactions through the issues API.
  /// Nothing that reviews, approves or changes a pull request. What the
  /// shared Connect App's bot holds for every server ([connectBotMayHold]).
  comment('comment', {'metadata': 'read', 'issues': 'write'}),

  /// Issue and PR conversation, as the bot: AI review comments and reviews,
  /// automated replies, reactions, labels, agent comments on their own pull
  /// request. Held by the server, never placed in an agent's environment.
  ///
  /// GitHub lets `pull_requests: write` do more than that (approve, dismiss
  /// reviews, open a pull request from an existing branch, edit, close or
  /// retitle one, edit others' comments), and an installation token is not
  /// clamped to the person who asked for it. The server never approves with
  /// it, and its request policy (REST and allowlisted GraphQL mutations)
  /// sends opening or changing a pull request, dismissals and comment edits
  /// only at [write]. On a shared Connect App the bot holds it only for the
  /// installs the Connect operator lists (`CONNECT_GITHUB_REVIEW_BOT_INSTALLS`);
  /// every other server publishes reviews on the person's own token
  /// (`as: user`), which GitHub clamps to the person.
  bot('bot', {'metadata': 'read', 'issues': 'write', 'pull_requests': 'write'}),

  /// Push and open or edit PRs. The agent run gateway, pull requests agents
  /// open, stacks and human terminal rigs. On a Connect lane only a person's
  /// own token (`as: user`) carries it ([connectBotMayHold]).
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
  bool get writes => permissions.values.contains('write');

  /// Whether the App's bot (`as: app`) may hold this scope on a shared
  /// Connect App (hosted or custom) for any server: a scope that writes
  /// nothing but issues ([read], [review], [comment]).
  ///
  /// Nothing binds an organization's installation of a shared App to one
  /// Control Center server, and any server may be anyone's script, so the
  /// bot there never pushes, opens or reviews pull requests for a server
  /// the Connect operator has not listed: [bot] only for listed installs
  /// ([connectBotNeedsListing]), [write] never. Those need the person who
  /// asked for them, on their own one-repository token (`as: user`). A
  /// server's or workspace's own App is the organization's own and keeps
  /// every scope.
  bool get connectBotMayHold => permissions.entries.every(
    (entry) => entry.value != 'write' || entry.key == 'issues',
  );

  /// Whether the shared Connect App's bot holds this scope only for an
  /// install the Connect operator lists in
  /// `CONNECT_GITHUB_REVIEW_BOT_INSTALLS` ([bot]). Any other install's
  /// `as: app` mint of it answers `needs_requester`.
  bool get connectBotNeedsListing => this == bot;
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
    // A read-only scope stays what was asked; a write the role cannot hold
    // falls to plain reads.
    return requested.writes ? GitHubTokenScope.read : requested;
  }
  return null;
}

/// Whether a mint answer is the token that was asked for: exactly
/// [permissions], a `selected` repository selection, and nothing that says
/// it reaches more than repository [repoId].
///
/// A missing selection or permission map refuses it. [requireRepositories]
/// also refuses an answer without the repository list: an installation
/// token's answer (`/app/installations/{id}/access_tokens`) and a Connect
/// answer always carry one. GitHub's own `/applications/{client_id}/token/
/// scoped` answer has none (only `installation.repository_selection`), so
/// that one check passes [requireRepositories] false and proves the rest.
bool scopedTokenMatches(
  Map<Object?, Object?> json, {
  required int repoId,
  required Map<String, String> permissions,
  bool requireRepositories = true,
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
  if (selection != 'selected') {
    return false;
  }
  final repositories =
      json['repositories'] ??
      (installation is Map ? installation['repositories'] : null);
  if (repositories == null) {
    return !requireRepositories;
  }
  if (repositories is! List || repositories.length != 1) {
    return false;
  }
  final only = repositories.single;
  return (only is Map ? only['id'] : only) == repoId;
}

/// A GitHub owner or repository name segment: no `..`, slashes, percent
/// escapes or anything GitHub itself would refuse (`.github` is fine).
bool isGitHubSegment(String value) =>
    value.isNotEmpty &&
    value.length <= 100 &&
    RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value) &&
    value != '.' &&
    !value.contains('..');
