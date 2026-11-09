part of '../cc_server_runtime.dart';

/// The Google, Linear and Klipy lanes, each resolved per workspace: the
/// workspace's own app ([WorkspaceProviderAppSettings]) when it has one and
/// nothing else, else this server's own app, else Control Center Connect.
///
/// Google Calendar: the server owns the connection; a member's account per
/// workspace connects through the browser sign-in (`google` lane) and the
/// server syncs it, clients only read the synced events. Linear:
/// a member's own account (`linear`) for what they do, and each workspace's
/// Control Center app actor (`linear_app`) for what automation does; public
/// PKCE in every mode, so Connect never sees a Linear token. Klipy: the
/// composer's GIF search (the thin client holds no key; with nothing
/// configured the `gif.*` ops return empty).
///
/// A workspace that changes or leaves its own app loses every grant the old
/// one issued there: they answer "sign in again" rather than keep working
/// under another client.
({
  ServerCalendar serverCalendar,
  LinearClients linearClients,
  KlipyGifs klipyGifs,
})
_wireProviderAppLanes({
  required DaoCalendarRepository calendarRepository,
  required DaoWorkspaceRepository workspaceRepository,
  required DomainEventBus eventBus,
  required FileSecretsStore secrets,
  required ProviderSignInService providerSignIn,
  required ProviderAppSettings providerApps,
  required WorkspaceProviderAppSettings workspaceApps,
  required UserCredentialsStore userCredentials,
  required ConnectClient connectClient,
  required String klipyAppKey,
}) {
  final serverCalendar = buildServerCalendar(
    calendarRepository: calendarRepository,
    workspaceRepository: workspaceRepository,
    eventBus: eventBus,
    // Google credentials are `google_*` keys in the same secrets file as the
    // device PSKs: the shared store, not a second cache of the same map.
    secrets: secrets,
    signIn: providerSignIn,
    connect: connectClient,
    apps: providerApps,
    workspaceApps: workspaceApps,
  );
  providerSignIn.register(
    GoogleSignInLane(
      apps: providerApps,
      workspaceApps: workspaceApps,
      accounts: serverCalendar.accounts,
    ),
  );
  final linearAppGrants = LinearAppGrants(secrets);
  final linearLanes = [
    for (final lane in [ConnectOAuthLane.linear, ConnectOAuthLane.linearApp])
      LinearSignInLane(
        lane: lane,
        apps: providerApps,
        workspaceApps: workspaceApps,
        people: userCredentials,
        workspaces: linearAppGrants,
      ),
  ];
  linearLanes.forEach(providerSignIn.register);
  final linearClients = LinearClients(
    people: userCredentials,
    workspaces: linearAppGrants,
    apps: providerApps,
    workspaceApps: workspaceApps,
    refresh: (lane, token, {slot}) =>
        providerSignIn.refresh(lane, token, slot: slot, workspaceId: slot),
    revoke: linearLanes.first.revoke,
  );
  workspaceApps.addListener((workspaceId, provider) {
    switch (provider) {
      case WorkspaceAppProvider.google:
        unawaited(serverCalendar.tokens.revalidateWorkspace(workspaceId));
      case WorkspaceAppProvider.linear:
        unawaited(linearClients.resetWorkspace(workspaceId));
      case WorkspaceAppProvider.klipy:
        // A key, not a grant: the next search reads the new one.
        break;
    }
  });
  final klipyGifs = KlipyGifs(
    connect: connectClient,
    ownAppKey: klipyAppKey,
    workspaceApps: workspaceApps,
  );
  return (
    serverCalendar: serverCalendar,
    linearClients: linearClients,
    klipyGifs: klipyGifs,
  );
}
