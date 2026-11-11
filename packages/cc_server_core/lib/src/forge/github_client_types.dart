/// The value types `GitHubClients` hands out: lanes, minted grants, bot
/// presence and refusals.
library;

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectErrorCode, GitHubTokenScope, globalWorkspaceScope;
import 'package:cc_server_core/src/connect/connect_settings.dart'
    show ConnectTarget;

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

  /// The App is installed on the owner, but its installation does not
  /// include this repository.
  repoNotSelected('repo_not_selected'),

  /// The installation is suspended.
  suspended('suspended'),

  /// GitHub or Connect is unreachable or failing; transient.
  providerUnavailable('provider_unavailable'),

  /// Too many requests (GitHub's primary or secondary rate limit, which it
  /// answers with 403 as often as 429); transient, never cached, never
  /// recorded as blocking.
  rateLimited('rate_limited'),

  /// The repository's organization enforces SAML single sign-on and the
  /// person's sign-in has no active SSO session for it: they sign in to
  /// GitHub again (through the organization's SSO) and it works.
  ssoRequired('sso_required'),

  /// A shared Connect App's bot was asked to change code (push, create a
  /// branch, open or edit a pull request). On Connect the bot only reads and
  /// comments; that work needs a person who asked for it, on their own
  /// one-repository token.
  needsRequester('needs_requester'),

  /// Connect refused this server outright.
  installBlocked('install_blocked'),

  /// The linked repository's owner/name now names a different repository on
  /// GitHub than the one linked (another repository id): nothing is minted
  /// for it until an admin relinks it.
  repoReplaced('repo_replaced'),

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
    ConnectErrorCode.repoNotSelected => repoNotSelected,
    ConnectErrorCode.suspended => suspended,
    ConnectErrorCode.rateLimited => rateLimited,
    ConnectErrorCode.needsRequester => needsRequester,
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
  const GitHubScopeRefused(this.code, this.message, {this.installUrl});

  /// What kind of refusal.
  final GitHubRefusal code;

  /// What a person can do about it.
  final String message;

  /// Where an admin fixes it, when the refusal knows: the installation's
  /// repository selection for [GitHubRefusal.repoNotSelected].
  final Uri? installUrl;

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
    this.connectTarget,
    this.appClient,
    this.requestId = '',
  });

  /// The bearer token: `ghs_` for the App's bot (an own App's installation,
  /// or Connect `as: app`), `ghu_` for a person's narrowed sign-in (an own
  /// App downscope, or Connect `as: user`).
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

  /// On Connect, the Connect that minted it: a revoke goes there, even after
  /// the workspace moved to another.
  final ConnectTarget? connectTarget;

  /// For a person downscope on an App lane, the client credentials of the
  /// App that narrowed it, held in memory only: it is revoked with them,
  /// even after that App was rotated or removed.
  final ({String clientId, String clientSecret})? appClient;

  /// GitHub's `x-github-request-id` for the mint, or ''.
  final String requestId;
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
