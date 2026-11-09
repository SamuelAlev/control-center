part of '../cc_server_runtime.dart';

/// People's forge credentials and the only way the server gets an
/// authenticated GitHub client over them.
///
/// GitHub is person-only (each member's own sign-in, nothing else); GitLab
/// and Bitbucket keep pasted tokens, with the owner's pasted token then the
/// environment for background work. Automation reaches GitHub through
/// one-repository tokens bounded by the workspace's accountable human.
Future<({ForgeCredentials forgeCredentials, GitHubClients githubClients})>
_wireGitHubIdentity({
  required Map<String, String> serverEnv,
  required UserCredentialsStore userCredentials,
  required String? ownerUserId,
  required DaoWorkspaceRepository workspaceRepository,
  required CachingWorkspaceMembershipRepository membershipRepository,
  required DomainEventBus eventBus,
  required ProviderSignInService providerSignIn,
  required ProviderAppSettings providerApps,
  required WorkspaceGitHubAppSettings workspaceGitHub,
  required ConnectSettings connectSettings,
  required ConnectClient connectClient,
}) async {
  final forgeCredentials = ForgeCredentials(
    env: (name) => serverEnv[name],
    users: userCredentials,
    serverOwnerUserId: () async => ownerUserId,
    viewerProbe: probeForgeViewer,
  );
  forgeCredentials.workspaceLookup = workspaceRepository.getById;
  // Renews an expiring GitHub sign-in in place. Only a refused grant clears
  // it; Connect or GitHub being down keeps it for the next call.
  forgeCredentials.refreshUserToken =
      (userId, forge, expired, {workspaceId}) async => forge == ForgeHost.github
      ? providerSignIn.refresh(
          ConnectOAuthLane.github,
          expired,
          slot: workspaceId,
          workspaceId: workspaceId,
        )
      : const RefreshUnavailable();
  // A sealed grant is usable only by the install identity it was sealed to,
  // towards the Connect that sealed it.
  forgeCredentials.currentSealInstallId = (origin) async {
    final choice = await connectSettings.choice();
    if (!choice.enabled || canonicalConnectBaseUrl(choice.baseUrl) != origin) {
      return null;
    }
    return (await connectClient.identity())?.installId;
  };
  final githubClients = GitHubClients(
    credentials: forgeCredentials,
    apps: providerApps,
    workspaceApps: workspaceGitHub,
    workspaceLookup: workspaceRepository.getById,
    members: membershipRepository,
    connect: connectClient,
    isLinkedRepo: (workspaceId, owner, repo) async =>
        await _linkedGitHubRepo(
          workspaceRepository,
          workspaceId,
          '$owner/$repo',
        ) !=
        null,
  );
  final purgedTokens = await workspaceGitHub.purgeLegacyTokens();
  if (purgedTokens > 0) {
    CcHostLog.info(
      'cc_server: deleted $purgedTokens stored GitHub personal access '
      'token(s); GitHub is sign-in only',
    );
  }
  // A removed member stops bounding automation in that workspace at once:
  // their cached one-repository tokens there are dropped and revoked.
  eventBus.on<WorkspaceMemberRemoved>().listen(
    (e) => unawaited(githubClients.forgetMember(e.workspaceId, e.userId)),
  );
  eventBus.on<WorkspaceMemberRoleChanged>().listen(
    (e) => unawaited(githubClients.forgetMember(e.workspaceId, e.userId)),
  );
  // A new or removed own GitHub App is a different identity: nothing the
  // old one minted is served again.
  providerApps.addListener((provider) {
    if (provider == ProviderApp.github) {
      githubClients.forgetAll();
    }
  });
  providerSignIn.register(
    GitHubSignInLane(
      apps: providerApps,
      workspaceApps: workspaceGitHub,
      workspaceLookup: workspaceRepository.getById,
      credentials: forgeCredentials,
      connect: connectClient,
    ),
  );
  return (forgeCredentials: forgeCredentials, githubClients: githubClients);
}

/// What automation needs from [GitHubClients] beyond a client: the
/// attribution its posts carry and one-repository tokens as strings.
final class _GitHubAutomation {
  _GitHubAutomation(this._clients, this._userCredentials);

  final GitHubClients _clients;
  final UserCredentialsStore _userCredentials;

  /// On Connect's shared App, automation's one-repository tokens are children
  /// of the accountable human's own user token, so what it posts lands under
  /// that person's account. Naming Control Center (and on whose behalf) keeps
  /// the findings from reading as the person's own words, and is what the PR
  /// conversation bridge recognises as its own thread. App lanes post as the
  /// bot, which needs no prefix.
  Future<String Function(String body)?> reviewAttribution({
    required String workspaceId,
    required String owner,
    String? actingUserId,
  }) async {
    if (await _clients.laneFor(workspaceId) != GitHubLane.connect) {
      return null;
    }
    final human = await _clients.accountableHuman(
      workspaceId,
      actingUserId: actingUserId,
    );
    if (human == null) {
      return null;
    }
    final token = await _userCredentials.forgeToken(human, ForgeHost.github);
    final login = token?.accountLogin ?? '';
    if (login.isEmpty) {
      return null;
    }
    return (body) => GitHubPrConversationBridge.attributed(login, body);
  }

  /// The GitHub account [userId] signed in with for [workspaceId], or null
  /// when they have none or GitHub cannot say.
  Future<GitHubUser?> personAccount(String userId, String? workspaceId) async {
    if (!await _clients.isSignedIn(userId, workspaceId: workspaceId)) {
      return null;
    }
    try {
      return await _clients
          .asPerson(userId, workspaceId: workspaceId)
          .content
          .getAuthenticatedUser();
    } on Object catch (e) {
      CcHostLog.warning(
        'agent commit identity: GitHub account lookup failed: $e',
      );
      return null;
    }
  }

  final _prConversationGateways = <String, GitHubPrConversationGateway>{};

  /// One PR conversation gateway per workspace: its bot and lane, its
  /// one-repository tokens (reads bounded by the accountable human, replies
  /// by the member who asked), and members' own sign-ins for the 👀 claim.
  /// Two workspaces on the same App never share one, and a reply rides the
  /// workspace the question arrived in.
  GitHubPrConversationGateway prConversationGateway(String workspaceId) =>
      _prConversationGateways.putIfAbsent(
        workspaceId,
        () => WorkspaceGitHubPrConversationGateway(
          presence: () => _clients.botPresence(workspaceId),
          lane: () => _clients.laneFor(workspaceId),
          clientForOwner: (owner, {actingUserId}) =>
              _clients.forOwner(workspaceId, owner, actingUserId: actingUserId),
          personClient: (userId) =>
              _clients.asPerson(userId, workspaceId: workspaceId),
          mint: (owner, repo, {required scope, required actingUserId}) =>
              _clients.mintScoped(
                workspaceId: workspaceId,
                owner: owner,
                repo: repo,
                scope: scope,
                actingUserId: actingUserId,
              ),
          onWarning: CcHostLog.warning,
        ),
      );

  /// A one-repository token as a string, for the few places that hand one to
  /// git. A refusal is logged and answers null; there is no fallback.
  Future<String?> repoToken(
    String workspaceId,
    String owner,
    String repo,
    GitHubTokenScope scope, {
    String? actingUserId,
    bool viaPerson = false,
  }) async {
    try {
      return (await _clients.mintScoped(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        scope: scope,
        actingUserId: actingUserId,
        viaPerson: viaPerson,
      )).token;
    } on GitHubScopeRefused catch (e) {
      CcHostLog.warning(
        'github: no ${scope.wire} token for $owner/$repo in workspace '
        '$workspaceId (${e.code})',
      );
      return null;
    }
  }
}

/// The GitHub repository [repoFullName] (`owner/name`) when it is linked to
/// [workspaceId], else null: what a pipeline shell step may get a read token
/// for.
Future<({String owner, String name})?> _linkedGitHubRepo(
  DaoWorkspaceRepository workspaces,
  String workspaceId,
  String repoFullName,
) async {
  final repos = await workspaces.watchReposForWorkspace(workspaceId).first;
  final wanted = repoFullName.toLowerCase();
  for (final repo in repos) {
    if (repo.forge == ForgeHost.github &&
        repo.hasForgeRemote &&
        repo.fullName.toLowerCase() == wanted) {
      return (owner: repo.remoteOwner, name: repo.remoteName);
    }
  }
  return null;
}

/// Re-checks every linked GitHub repository against its workspace's
/// accountable human shortly after boot and then daily, pausing automation
/// for the ones they lost access to ([GitHubClients.sweepLinks]). Returns the
/// timers' cancels.
List<void Function()> _scheduleRepoLinkSweep(
  GitHubClients github,
  DaoWorkspaceRepository workspaces,
) {
  Future<void> sweep() async {
    try {
      var paused = 0;
      for (final workspace in await workspaces.getAll()) {
        final repos = await workspaces.watchReposForWorkspace(workspace.id).first;
        paused += await github.sweepLinks(workspace.id, [
          for (final repo in repos)
            if (repo.forge == ForgeHost.github && repo.hasForgeRemote)
              (owner: repo.remoteOwner, repo: repo.remoteName),
        ]);
      }
      if (paused > 0) {
        CcHostLog.info('github: $paused repository link(s) paused');
      }
    } on Object catch (e) {
      CcHostLog.warning('github: re-checking repository links failed ($e)');
    }
  }

  final boot = Timer(const Duration(minutes: 3), sweep);
  final daily = Timer.periodic(
    const Duration(days: 1),
    (_) => unawaited(sweep()),
  );
  return [boot.cancel, daily.cancel];
}

/// Renews Linear grants before their refresh tokens' thirty idle days run
/// out: every grant older than twenty, shortly after boot and then daily.
/// Returns the timers' cancels.
List<void Function()> _scheduleLinearRenewal(LinearClients linear) {
  Future<void> renew() async {
    try {
      final renewed = await linear.refreshAging();
      if (renewed > 0) {
        CcHostLog.info('linear: renewed $renewed aging grant(s)');
      }
    } on Object catch (e) {
      CcHostLog.warning('linear: renewing aging grants failed ($e)');
    }
  }

  final boot = Timer(const Duration(minutes: 2), renew);
  final daily = Timer.periodic(
    const Duration(days: 1),
    (_) => unawaited(renew()),
  );
  return [boot.cancel, daily.cancel];
}
