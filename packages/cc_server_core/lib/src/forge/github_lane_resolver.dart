import 'package:cc_connect_core/cc_connect_core.dart' show GitHubLaneConfig;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_server_core/src/connect/connect_client.dart';
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

/// Whether [workspace] runs GitHub on its own App: then it never inherits
/// the server's lane, its people sign in to that App only, and their grants
/// live in the workspace slot.
bool workspaceOwnsGitHubApp(Workspace? workspace) =>
    workspace?.githubAuthMode == GithubAuthMode.app;

/// The GitHub lane [workspace]'s automation runs on, given the server's
/// own-App state and whether Connect offers GitHub.
GitHubLane githubLaneFor(
  Workspace? workspace, {
  required OwnAppState serverApp,
  required bool connectOffers,
}) {
  if (workspaceOwnsGitHubApp(workspace)) {
    return GitHubLane.workspaceApp;
  }
  return switch (appLanePrecedence(serverApp, connectOffers: connectOffers)) {
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
}

/// Resolves which GitHub lane a workspace is on and the App behind it.
final class GitHubLaneResolver {
  /// Creates the resolver.
  GitHubLaneResolver({
    required this.apps,
    required this.workspaceApps,
    required this.workspaceLookup,
    required this.connect,
  });

  /// The server's own apps.
  final ProviderAppSettings apps;

  /// Per-workspace GitHub Apps.
  final WorkspaceGitHubAppSettings workspaceApps;

  /// Loads a workspace.
  final Future<Workspace?> Function(String workspaceId) workspaceLookup;

  /// Connect.
  final ConnectClient connect;

  /// The lane and App [workspaceId]'s automation runs on right now.
  Future<GitHubLaneIdentity> resolve(String workspaceId) async {
    final workspace = workspaceId.isEmpty
        ? null
        : await workspaceLookup(workspaceId);
    if (workspaceOwnsGitHubApp(workspace)) {
      return GitHubLaneIdentity(
        GitHubLane.workspaceApp,
        workspace!.githubAppId.trim(),
      );
    }
    final status = await apps.status(ProviderApp.github);
    final connectGitHub = status.effectiveState == OwnAppState.none
        ? await this.connectGitHub()
        : null;
    final lane = githubLaneFor(
      workspace,
      serverApp: status.effectiveState,
      connectOffers: connectGitHub != null,
    );
    return GitHubLaneIdentity(lane, switch (lane) {
      GitHubLane.ownApp => status.appId,
      GitHubLane.connect => '${connectGitHub!.appId}',
      GitHubLane.workspaceApp || GitHubLane.none => '',
    });
  }

  /// Connect's GitHub lane, when Connect is usable and offers one.
  Future<GitHubLaneConfig?> connectGitHub() async =>
      (await connect.usableConfig())?.github;

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
