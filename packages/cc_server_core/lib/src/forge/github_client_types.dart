/// The value types `GitHubClients` hands out: lanes, minted grants, bot
/// presence and refusals.
library;

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectErrorCode, GitHubTokenScope, globalWorkspaceScope;

/// Which GitHub lane a workspace's automation runs on.
enum GitHubLane {
  /// The workspace's own GitHub App (fail-closed when incomplete).
  workspaceApp,

  /// The server's own complete GitHub App.
  ownApp,

  /// Control Center Connect's shared App, via `/v1/github/scope`.
  connect,

  /// Nothing configured.
  none;

  /// The wire spelling.
  String get wire => switch (this) {
    workspaceApp => 'workspace_app',
    ownApp => 'own_app',
    connect => 'connect',
    none => 'none',
  };
}

/// Why GitHub work was refused: the closed set [GitHubScopeRefused] carries.
enum GitHubRefusal {
  /// The accountable person must sign in (again).
  needsSignIn('needs_sign_in'),

  /// The person cannot see or do this on GitHub, or it is not linked here.
  accessDenied('access_denied'),

  /// The App is not installed on the repository's owner.
  notInstalled('not_installed'),

  /// The shared App's installation there belongs to other servers.
  installationBoundElsewhere('installation_bound_elsewhere'),

  /// The installation is suspended.
  suspended('suspended'),

  /// GitHub or Connect is unreachable or failing; transient.
  providerUnavailable('provider_unavailable'),

  /// Too many requests; transient.
  rateLimited('rate_limited'),

  /// Connect refused this server outright.
  installBlocked('install_blocked'),

  /// No GitHub lane, or an incomplete own App.
  notConfigured('not_configured'),

  /// A malformed request (not a repository name, the wrong lane).
  invalidRequest('invalid_request');

  const GitHubRefusal(this.wire);

  /// The wire spelling, as logs and callers that cross a wire see it.
  final String wire;

  /// The refusal a Connect failure amounts to.
  static GitHubRefusal fromConnect(ConnectErrorCode code) => switch (code) {
    ConnectErrorCode.needsSignIn => needsSignIn,
    ConnectErrorCode.accessDenied ||
    ConnectErrorCode.notAdmin ||
    ConnectErrorCode.teamBoundElsewhere => accessDenied,
    ConnectErrorCode.notInstalled => notInstalled,
    ConnectErrorCode.installationBoundElsewhere => installationBoundElsewhere,
    ConnectErrorCode.suspended => suspended,
    ConnectErrorCode.rateLimited => rateLimited,
    ConnectErrorCode.installBlocked => installBlocked,
    ConnectErrorCode.invalidRequest ||
    ConnectErrorCode.codeMismatch => invalidRequest,
    ConnectErrorCode.providerUnavailable ||
    ConnectErrorCode.staleRequest => providerUnavailable,
  };

  /// Whether retrying later may succeed with nothing changed.
  bool get isTransient => this == providerUnavailable || this == rateLimited;
}

/// Why a scoped token could not be minted. Final: there is no PAT, owner or
/// environment fallback behind it.
final class GitHubScopeRefused implements Exception {
  /// Creates the refusal.
  const GitHubScopeRefused(this.code, this.message);

  /// What kind of refusal.
  final GitHubRefusal code;

  /// What a person can do about it.
  final String message;

  @override
  String toString() => 'GitHubScopeRefused(${code.wire}): $message';
}

/// One minted single-repository token.
final class GitHubScopedGrant {
  /// Creates the grant.
  const GitHubScopedGrant({
    required this.token,
    required this.scope,
    required this.expiresAt,
    required this.lane,
    required this.workspaceId,
    required this.owner,
    required this.repo,
    this.accountableUserId,
    this.connectSeal = '',
    this.connectSealScope = '',
  });

  /// The bearer token (`ghs_` from an own App, `ghu_` child from Connect or
  /// a person downscope).
  final String token;

  /// The scope actually granted (clamped to the human's role).
  final GitHubTokenScope scope;

  /// When it stops working.
  final DateTime expiresAt;

  /// Which lane minted it.
  final GitHubLane lane;

  /// The workspace.
  final String workspaceId;

  /// Repository owner.
  final String owner;

  /// Repository name.
  final String repo;

  /// The human whose access bounds it, when one does.
  final String? accountableUserId;

  /// On Connect, the parent grant's seal: revoking the child proves with it
  /// that this server holds the grant, even after the person signed out.
  final String connectSeal;

  /// The workspace slot [connectSeal] is bound to ([globalWorkspaceScope]
  /// for a person's global grant).
  final String connectSealScope;
}

/// Whether [owner]/[repo] is a repository linked to [workspaceId].
typedef LinkedRepoLookup =
    Future<bool> Function(String workspaceId, String owner, String repo);

/// Where one workspace's GitHub bot lives right now.
final class GitHubBotPresence {
  /// Creates the presence.
  const GitHubBotPresence({
    required this.botLogin,
    required this.slug,
    required this.owners,
    this.suspendedOwners = const {},
  });

  /// The bot account (`<slug>[bot]`).
  final String botLogin;

  /// The App's public slug (`@<slug>`).
  final String slug;

  /// Accounts the App is installed on, as GitHub spells them.
  final List<String> owners;

  /// Lower-cased accounts whose installation is suspended.
  final Set<String> suspendedOwners;

  /// Whether every installation is suspended. None at all is a missing
  /// identity, not a paused one.
  bool get allSuspended =>
      owners.isNotEmpty &&
      owners.every((o) => suspendedOwners.contains(o.toLowerCase()));
}

/// Picks the accountable human for automation in a workspace when the
/// caller did not name one.
typedef AccountableHumanFallback = Future<String?> Function(String workspaceId);
