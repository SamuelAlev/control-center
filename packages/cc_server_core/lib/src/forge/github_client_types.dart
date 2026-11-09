/// The value types `GitHubClients` hands out: lanes, minted grants, bot
/// presence and refusals.
library;

import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope, globalWorkspaceScope;

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

/// Why a scoped token could not be minted. Final: there is no PAT, owner or
/// environment fallback behind it.
final class GitHubScopeRefused implements Exception {
  /// Creates the refusal.
  const GitHubScopeRefused(this.code, this.message);

  /// A stable code: `needs_sign_in`, `access_denied`, `not_installed`,
  /// `installation_bound_elsewhere`, `suspended`, `provider_unavailable`,
  /// `not_configured`, `invalid_request`.
  final String code;

  /// What a person can do about it.
  final String message;

  @override
  String toString() => 'GitHubScopeRefused($code): $message';
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
