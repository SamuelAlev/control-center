part of '../cc_server_runtime.dart';

/// Routes each workspace's provider lanes through its own Connect choice
/// (`workspaceConnect.set`), and drops a deleted workspace's custom-Connect
/// trust (pins, cached config) with it.
void _wireWorkspaceConnect({
  required ConnectSettings connectSettings,
  required ConnectClient connectClient,
  required DaoWorkspaceRepository workspaceRepository,
  required WorkspaceGitHubAppSettings workspaceGitHub,
}) {
  connectSettings
    ..workspaceLookup = workspaceRepository.getById
    ..workspaceList = workspaceRepository.getAll;
  workspaceGitHub.addDeletionListener((workspaceId) async {
    await connectSettings.deleteWorkspaceTrust(workspaceId);
    connectClient.invalidateWorkspace(workspaceId);
  });
}

/// Slack's shared Control Center app, installed through Connect: its events
/// arrive as references on one long-poll per Connect origin in use (the
/// workspace's Connect when it chose one, else the server's). Another server
/// Connect moves every inheriting workspace's relay, and another workspace
/// choice moves that workspace's; a workspace's own Slack app connection
/// depends on neither. Null in demo, which has no Connect.
ConnectSlackGrants? _wireSlackConnectGrants({
  required ConnectSettings connectSettings,
  required ConnectClient connectClient,
  required bool demo,
}) {
  if (demo) {
    return null;
  }
  final grants = ConnectSlackGrants(connect: connectClient);
  connectSettings
    ..addListener(() => unawaited(grants.relay.rehome()))
    ..addWorkspaceListener(
      (workspaceId) => unawaited(grants.relay.rehome(workspaceId)),
    );
  return grants;
}
