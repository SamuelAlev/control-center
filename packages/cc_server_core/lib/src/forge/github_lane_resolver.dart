import 'package:cc_connect_core/cc_connect_core.dart' show GitHubLaneConfig;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';

/// Where a provider lane runs, from the server's own-app state and whether
/// Connect offers it: the one precedence every lane reader shares.
enum AppLaneSource {
  /// The server's own complete app.
  own,

  /// Control Center Connect.
  connect,

  /// Nothing: unset, or an own app half set up (never a Connect fallback).
  off,
}

/// The server-level precedence for one provider: a complete own app wins, a
/// partial one blocks everything, and only no own app at all lets Connect
/// run the lane.
AppLaneSource appLanePrecedence(
  OwnAppState ownApp, {
  required bool connectOffers,
}) => switch (ownApp) {
  OwnAppState.complete => AppLaneSource.own,
  OwnAppState.partial => AppLaneSource.off,
  OwnAppState.none => connectOffers ? AppLaneSource.connect : AppLaneSource.off,
};

/// The GitHub lane a workspace's automation runs on, given its [route], how
/// complete its own App is ([workspaceApp]), the server's own-App state as
/// lanes see it ([serverApp]) and whether the route's Connect offers GitHub.
///
/// On its own apps only the workspace's App counts (none is off, partial a
/// fail-closed App lane). Inheriting, the server's precedence applies. On a
/// Connect of its own, only that Connect.
GitHubLane githubLaneFor(
  ConnectRoute route, {
  required OwnAppState workspaceApp,
  required OwnAppState serverApp,
  required bool connectOffers,
}) {
  if (route.workspaceOwnApps) {
    return workspaceApp == OwnAppState.none
        ? GitHubLane.none
        : GitHubLane.workspaceApp;
  }
  final server = route.serverOwnApps ? serverApp : OwnAppState.none;
  return switch (appLanePrecedence(server, connectOffers: connectOffers)) {
    AppLaneSource.own => GitHubLane.ownApp,
    AppLaneSource.connect => GitHubLane.connect,
    AppLaneSource.off => GitHubLane.none,
  };
}

/// One workspace's GitHub lane and the App identity behind it.
final class GitHubLaneIdentity {
  /// Creates the identity.
  const GitHubLaneIdentity(this.lane, this.appId);

  /// The lane.
  final GitHubLane lane;

  /// The App id the lane mints through (the workspace's, the server's, or
  /// Connect's shared App); empty for [GitHubLane.none]. Part of every grant
  /// cache key, so a rotated App never serves its predecessor's tokens.
  final String appId;

  /// Whether [other] is the same lane through the same App.
  bool sameAs(GitHubLaneIdentity other) =>
      lane == other.lane && appId == other.appId;
}

/// Resolves which GitHub lane a workspace is on and the App behind it.
final class GitHubLaneResolver {
  /// Creates the resolver.
  GitHubLaneResolver({
    required this.apps,
    required this.workspaceApps,
    required this.workspaceLookup,
    required this.connect,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// How long a resolved lane is reused before it is resolved again. Every
  /// change that moves a lane ([invalidate]) drops it sooner.
  static const Duration memo = Duration(seconds: 5);

  final DateTime Function() _now;
  final Map<String, ({GitHubLaneIdentity identity, DateTime at})> _memo = {};

  /// The last lane written to the log per workspace, so
  /// `github.lane.resolved` is written on a change only.
  final Map<String, GitHubLaneIdentity> _announced = {};
  int _generation = 0;

  /// The server's own apps.
  final ProviderAppSettings apps;

  /// Per-workspace GitHub Apps.
  final WorkspaceGitHubAppSettings workspaceApps;

  /// Loads a workspace.
  final Future<Workspace?> Function(String workspaceId) workspaceLookup;

  /// Connect.
  final ConnectClient connect;

  /// The lane and App [workspaceId]'s automation runs on right now
  /// (resolved at most [memo] ago).
  Future<GitHubLaneIdentity> resolve(String workspaceId) async {
    final hit = _memo[workspaceId];
    if (hit != null && _now().difference(hit.at) < memo) {
      return hit.identity;
    }
    final generation = _generation;
    final identity = await _resolve(workspaceId);
    if (generation == _generation) {
      _memo[workspaceId] = (identity: identity, at: _now());
    }
    final before = _announced[workspaceId];
    if (before == null || !before.sameAs(identity)) {
      _announced[workspaceId] = identity;
      forgeAudit(ForgeAuditEvent.githubLaneResolved, {
        'workspace_id': workspaceId,
        'lane': identity.lane.name,
        'app_id': identity.appId,
        'previous_lane': before?.lane.name,
        'previous_app_id': before?.appId,
      });
    }
    return identity;
  }

  /// Drops the remembered lane of [workspaceId], or of every workspace: an
  /// App, a Connect or a workspace's mode changed. A resolution in the air
  /// is not remembered either.
  void invalidate([String? workspaceId]) {
    _generation++;
    if (workspaceId == null) {
      _memo.clear();
    } else {
      _memo.remove(workspaceId);
    }
  }

  Future<GitHubLaneIdentity> _resolve(String workspaceId) async {
    final route = await connect.routeFor(
      workspaceId.isEmpty ? null : workspaceId,
    );
    if (route.workspaceOwnApps) {
      final workspace = await workspaceLookup(workspaceId);
      final state = workspace == null
          ? OwnAppState.none
          : (await workspaceApps.status(workspace)).state;
      final lane = githubLaneFor(
        route,
        workspaceApp: state,
        serverApp: OwnAppState.none,
        connectOffers: false,
      );
      return GitHubLaneIdentity(
        lane,
        lane == GitHubLane.workspaceApp ? workspace!.githubAppId.trim() : '',
      );
    }
    final status = route.serverOwnApps
        ? await apps.status(ProviderApp.github)
        : null;
    final serverState = status?.effectiveState ?? OwnAppState.none;
    final connectGitHub = serverState == OwnAppState.none
        ? await this.connectGitHub(route.target)
        : null;
    final lane = githubLaneFor(
      route,
      workspaceApp: OwnAppState.none,
      serverApp: serverState,
      connectOffers: connectGitHub != null,
    );
    return GitHubLaneIdentity(lane, switch (lane) {
      GitHubLane.ownApp => status!.appId,
      GitHubLane.connect => '${connectGitHub!.appId}',
      GitHubLane.workspaceApp || GitHubLane.none => '',
    });
  }

  /// [target]'s GitHub lane, when it is usable and offers one.
  Future<GitHubLaneConfig?> connectGitHub(ConnectTarget target) async =>
      (await connect.usableConfig(target))?.github;

  /// The App client behind an App [lane] in [workspaceId], or null.
  Future<GitHubAppClient?> appFor(String workspaceId, GitHubLane lane) async {
    switch (lane) {
      case GitHubLane.workspaceApp:
        final workspace = await workspaceLookup(workspaceId);
        return workspace == null ? null : workspaceApps.githubApp(workspace);
      case GitHubLane.ownApp:
        return apps.githubApp();
      case GitHubLane.connect || GitHubLane.none:
        return null;
    }
  }

  /// The OAuth client credentials of an App [lane] in [workspaceId], or null.
  Future<OAuthAppCredentials?> oauthFor(
    String workspaceId,
    GitHubLane lane,
  ) async {
    switch (lane) {
      case GitHubLane.workspaceApp:
        final workspace = await workspaceLookup(workspaceId);
        return workspace == null
            ? null
            : workspaceApps.oauthCredentials(workspace);
      case GitHubLane.ownApp:
        return apps.oauthCredentials(ProviderApp.github);
      case GitHubLane.connect || GitHubLane.none:
        return null;
    }
  }
}
