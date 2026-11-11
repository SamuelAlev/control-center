part of '../cc_server_runtime.dart';

/// The Google, Linear and Klipy lanes, each resolved per workspace through
/// its Connect route ([ConnectClient.routeFor]): the workspace's own apps
/// ([WorkspaceProviderAppSettings]) and nothing else when it chose them, the
/// server's own apps when it inherits a server on its own apps, else the
/// Control Center Connect it uses.
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
/// A workspace that changes its own app, or its Connect choice, loses every
/// grant the old one issued there: they answer "sign in again" rather than
/// keep working under another client.
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
      route: connectClient.routeFor,
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
        route: connectClient.routeFor,
      ),
  ];
  linearLanes.forEach(providerSignIn.register);
  final linearClients = LinearClients(
    people: userCredentials,
    workspaces: linearAppGrants,
    apps: providerApps,
    workspaceApps: workspaceApps,
    route: connectClient.routeFor,
    refresh: (lane, token, {slot}) =>
        providerSignIn.refresh(lane, token, slot: slot, workspaceId: slot),
    revoke: linearLanes.first.revoke,
  );
  workspaceApps.addListener((workspaceId, provider) {
    switch (provider) {
      case WorkspaceAppProvider.google:
        _runSlotReset(
          'google',
          workspaceId,
          () => serverCalendar.tokens.revalidateWorkspace(workspaceId),
        );
      case WorkspaceAppProvider.linear:
        _runSlotReset(
          'linear',
          workspaceId,
          () => linearClients.resetWorkspace(workspaceId),
        );
      case WorkspaceAppProvider.klipy:
        // A key, not a grant: the next search reads the new one.
        break;
    }
  });
  // Another Connect choice in one workspace: its Google and Linear grants
  // are checked against (or dropped for) the apps it uses now.
  connectClient.settings.addWorkspaceListener((workspaceId) {
    _runSlotReset(
      'google',
      workspaceId,
      () => serverCalendar.tokens.revalidateWorkspace(workspaceId),
    );
    _runSlotReset(
      'linear',
      workspaceId,
      () => linearClients.resetWorkspace(workspaceId),
    );
  });
  // Another server choice: a workspace that no longer owns a person slot
  // (its target is the server's now) reads its members' global Linear
  // grants, so the slot's grants go.
  connectClient.settings.addListener(() {
    _runSlotReset('linear', null, () async {
      for (final workspace in await workspaceRepository.getAll()) {
        if (!workspace.isDeleted &&
            !(await connectClient.routeFor(workspace.id)).workspaceSlot) {
          await linearClients.resetPersonSlot(workspace.id);
        }
      }
    });
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

/// Runs a slot reset a settings change set off, without awaiting it; a
/// failure is logged (`grant.reset_failed`) instead of vanishing: the grants
/// it meant to drop are still stored.
void _runSlotReset(
  String lane,
  String? workspaceId,
  Future<void> Function() reset,
) {
  unawaited(
    reset().catchError((Object e) {
      forgeAudit(ForgeAuditEvent.grantResetFailed, {
        'lane': lane,
        'workspace_id': workspaceId,
        'reason': errorKindOf(e),
      });
    }),
  );
}

/// Ends a leaving person's provider credentials through the one
/// [CredentialOffboarding] path: on member removal (an admin, SCIM
/// deactivation, leaving), on workspace deletion (before its secrets go),
/// and once at boot for anything a crash or an earlier build left behind.
void _wireCredentialOffboarding({
  required ProviderSignInService providerSignIn,
  required UserCredentialsStore userCredentials,
  required WorkspaceMembershipRepository membershipRepository,
  required DaoWorkspaceRepository workspaceRepository,
  required WorkspaceGitHubAppSettings workspaceGitHub,
  required CalendarAccountService calendarAccounts,
  required DomainEventBus eventBus,
}) {
  final offboarding = CredentialOffboarding(
    signIn: providerSignIn,
    users: userCredentials,
    members: membershipRepository,
    workspaces: workspaceRepository,
    calendar: calendarAccounts,
  );
  eventBus.on<WorkspaceMemberRemoved>().listen(
    (e) => _runSlotReset(
      'offboarding',
      e.workspaceId,
      () => offboarding.memberLeft(e.userId, e.workspaceId),
    ),
  );
  workspaceGitHub.offboardWorkspace = offboarding.workspaceDeleted;
  _runSlotReset('offboarding', null, offboarding.reconcile);
}
