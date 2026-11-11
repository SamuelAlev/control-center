import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Why automation cannot reach one linked repository, as the server's repo
/// access registry records it (the `repo_access` wire).
enum RepoAccessState {
  /// The workspace's GitHub App is not installed on the repository's owner.
  appNotInstalled('app_not_installed'),

  /// The App is installed on the owner, but this repository is not among
  /// the installation's selected repositories.
  repoNotSelected('repo_not_selected'),

  /// GitHub suspended the installation covering the repository.
  installationSuspended('installation_suspended'),

  /// The workspace's accountable person can no longer see the repository,
  /// so automation that acts on their behalf is paused.
  ownerCannotSee('owner_cannot_see'),

  /// The workspace's accountable person is not signed in to the forge, so
  /// automation that acts on their behalf is paused.
  ownerNotSignedIn('owner_not_signed_in'),

  /// A GitLab or Bitbucket repository has no automation token (its own or
  /// the workspace's) that can read it, so work with no person behind it is
  /// paused there until an admin adds one.
  automationTokenMissing('automation_token_missing'),

  /// The repository's owner/name now names a different repository on the
  /// forge than the one linked (deleted or moved, and another created at
  /// that path): nothing is sent to it until an admin relinks it.
  repoReplaced('repo_replaced'),

  /// The forge did not answer the last check; it is being retried.
  transient('transient');

  const RepoAccessState(this.wire);

  /// The wire spelling.
  final String wire;

  /// Whether automation on the repository is paused until a person acts.
  /// Everything but [transient].
  bool get blocksAutomation => this != transient;

  /// Parses [wire]; null for anything unknown, so a state this client does
  /// not know is dropped rather than shown as a different one.
  static RepoAccessState? fromWire(Object? wire) {
    for (final s in values) {
      if (s.wire == wire) {
        return s;
      }
    }
    return null;
  }
}

/// One linked repository automation cannot reach, and why.
///
/// A client value object: the server owns the record and its checks; the
/// client only renders it and offers the fix ([installUrl]).
class RepoAccessIssue {
  /// Creates a [RepoAccessIssue].
  RepoAccessIssue({
    required this.forge,
    required this.owner,
    required this.name,
    required this.state,
    String? repoFullName,
    this.repoId,
    this.since,
    this.checkedAt,
    this.message = '',
    this.installUrl,
  }) : repoFullName = repoFullName == null || repoFullName.isEmpty
           ? '$owner/$name'
           : repoFullName {
    if (owner.isEmpty || name.isEmpty) {
      throw ArgumentError('A repo access issue names its owner and repo');
    }
  }

  /// Reads one `repo_access` entry; null when it is malformed or names a
  /// state this client does not know.
  static RepoAccessIssue? tryParse(Map<String, dynamic> json) {
    final state = RepoAccessState.fromWire(json['state']);
    final owner = json['owner'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    if (state == null || owner.isEmpty || name.isEmpty) {
      return null;
    }
    final repoId = json['repo_id'] as String?;
    final installUrl = json['install_url'] as String?;
    return RepoAccessIssue(
      forge: ForgeHost.fromWire(json['forge'] as String?),
      owner: owner,
      name: name,
      state: state,
      repoFullName: json['repo_full_name'] as String?,
      repoId: repoId == null || repoId.isEmpty ? null : repoId,
      since: DateTime.tryParse(json['since'] as String? ?? '')?.toUtc(),
      checkedAt: DateTime.tryParse(
        json['checked_at'] as String? ?? '',
      )?.toUtc(),
      message: json['message'] as String? ?? '',
      installUrl: installUrl == null || installUrl.isEmpty ? null : installUrl,
    );
  }

  /// The forge hosting the repository.
  final ForgeHost forge;

  /// The repository's owner (account or organization; a GitLab group path).
  final String owner;

  /// The repository's name.
  final String name;

  /// `owner/name`.
  final String repoFullName;

  /// The linked repo's id in this workspace, when the server named it.
  final String? repoId;

  /// Why automation cannot reach it.
  final RepoAccessState state;

  /// When the problem was first seen.
  final DateTime? since;

  /// When it was last checked.
  final DateTime? checkedAt;

  /// The server's explanation, already phrased for a person; empty when it
  /// gave none.
  final String message;

  /// Where an admin installs the App or adds the repository to it, for
  /// [RepoAccessState.appNotInstalled] and [RepoAccessState.repoNotSelected].
  final String? installUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoAccessIssue &&
          forge == other.forge &&
          owner == other.owner &&
          name == other.name &&
          repoFullName == other.repoFullName &&
          repoId == other.repoId &&
          state == other.state &&
          since == other.since &&
          checkedAt == other.checkedAt &&
          message == other.message &&
          installUrl == other.installUrl;

  @override
  int get hashCode => Object.hash(
    forge,
    owner,
    name,
    repoFullName,
    repoId,
    state,
    since,
    checkedAt,
    message,
    installUrl,
  );
}

/// A problem found while linking a repository that did not stop the link
/// (`repos.upsert` / `repos.addFromPath` `access_warnings`).
class RepoAccessWarning {
  /// Creates a [RepoAccessWarning].
  const RepoAccessWarning({
    required this.state,
    this.message = '',
    this.installUrl,
  });

  /// Reads one `access_warnings` entry; null for an unknown state.
  static RepoAccessWarning? tryParse(Map<String, dynamic> json) {
    final state = RepoAccessState.fromWire(json['state']);
    if (state == null) {
      return null;
    }
    final installUrl = json['install_url'] as String?;
    return RepoAccessWarning(
      state: state,
      message: json['message'] as String? ?? '',
      installUrl: installUrl == null || installUrl.isEmpty ? null : installUrl,
    );
  }

  /// Reads a result's `access_warnings` list (absent = none).
  static List<RepoAccessWarning> listOf(Object? raw) => [
    for (final entry in raw is List ? raw : const [])
      if (entry is Map) ?tryParse(entry.cast<String, dynamic>()),
  ];

  /// What is wrong.
  final RepoAccessState state;

  /// The server's explanation; empty when it gave none.
  final String message;

  /// Where an admin fixes it, when there is such a page.
  final String? installUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoAccessWarning &&
          state == other.state &&
          message == other.message &&
          installUrl == other.installUrl;

  @override
  int get hashCode => Object.hash(state, message, installUrl);
}

/// Why linked repositories are left out of a person's pull request views.
enum HiddenRepoReason {
  /// The person is not signed in to the repositories' forge here.
  signInRequired('sign_in_required'),

  /// Their own forge account cannot read the repositories.
  noForgeAccess('no_forge_access'),

  /// They are not an admin and hold no read grant on the repositories.
  noGrant('no_grant'),

  /// Their access has not been checked yet.
  checking('checking');

  const HiddenRepoReason(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses [wire]; null for anything unknown.
  static HiddenRepoReason? fromWire(Object? wire) {
    for (final r in values) {
      if (r.wire == wire) {
        return r;
      }
    }
    return null;
  }
}

/// How many of a workspace's linked repositories on one [forge] are left
/// out of the caller's pull request views for one [reason]
/// (`hidden_repos`). Counts only: the server never names a repository the
/// caller cannot see.
class HiddenRepos {
  /// Creates a [HiddenRepos] summary.
  HiddenRepos({
    required this.forge,
    required this.reason,
    required this.count,
  }) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'must be at least 1');
    }
  }

  /// Reads one `hidden_repos` entry; null when malformed or empty.
  static HiddenRepos? tryParse(Map<String, dynamic> json) {
    final reason = HiddenRepoReason.fromWire(json['reason']);
    final count = (json['count'] as num?)?.toInt() ?? 0;
    if (reason == null || count < 1) {
      return null;
    }
    return HiddenRepos(
      forge: ForgeHost.fromWire(json['forge'] as String?),
      reason: reason,
      count: count,
    );
  }

  /// Reads a frame's `hidden_repos` list (absent = nothing hidden).
  static List<HiddenRepos> listOf(Object? raw) => [
    for (final entry in raw is List ? raw : const [])
      if (entry is Map) ?tryParse(entry.cast<String, dynamic>()),
  ];

  /// The forge the hidden repositories live on.
  final ForgeHost forge;

  /// Why they are hidden.
  final HiddenRepoReason reason;

  /// How many.
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiddenRepos &&
          forge == other.forge &&
          reason == other.reason &&
          count == other.count;

  @override
  int get hashCode => Object.hash(forge, reason, count);
}

/// Why a member just granted a repository still cannot open its code or pull
/// requests (`members.setRepoGrant` `access_warning`). The grant is saved
/// either way; their own forge sign-in decides what they can read.
enum RepoGrantAccessWarning {
  /// They are not signed in to the repository's forge.
  notSignedIn('not_signed_in'),

  /// Their forge account cannot read the repository.
  cannotRead('cannot_read'),

  /// The forge could not confirm their access right now.
  unconfirmed('unconfirmed');

  const RepoGrantAccessWarning(this.wire);

  /// The wire spelling.
  final String wire;

  /// Reads a `members.setRepoGrant` result's `access_warning`; null when it
  /// is absent or names a state this client does not know.
  static RepoGrantAccessWarning? fromResult(Object? accessWarning) {
    if (accessWarning is! Map) {
      return null;
    }
    for (final w in values) {
      if (w.wire == accessWarning['state']) {
        return w;
      }
    }
    return null;
  }
}
