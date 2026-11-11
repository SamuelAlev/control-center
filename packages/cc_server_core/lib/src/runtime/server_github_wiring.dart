part of '../cc_server_runtime.dart';

/// People's forge credentials and the only way the server gets an
/// authenticated GitHub client over them.
///
/// GitHub is person-only (each member's own sign-in, nothing else); GitLab
/// and Bitbucket keep pasted tokens for people, and background work there
/// uses only the repository's or workspace's automation token
/// ([ForgeAutomationTokens]; no person, server-owner or environment
/// fallback). Automation reaches GitHub through one-repository
/// tokens bounded by the workspace's accountable human, and records what it
/// cannot reach in [repoAccess].
Future<({ForgeCredentials forgeCredentials, GitHubClients githubClients})>
_wireGitHubIdentity({
  required UserCredentialsStore userCredentials,
  required RepoAccessRegistry repoAccess,
  required ForgeRepoPins forgeRepoPins,
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
    users: userCredentials,
    viewerProbe: probeForgeViewer,
    personTokenCheck: checkPersonForgeToken,
  );
  // A workspace keeps its own GitHub slot only while its sign-in target
  // differs from the server's (`ConnectRoute.workspaceSlot`); otherwise its
  // members' global sign-ins apply there.
  forgeCredentials.workspaceOwnsSlot = (workspaceId) async =>
      (await connectSettings.routeFor(workspaceId)).workspaceSlot;
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
  forgeCredentials.currentSealInstallId = connectClient.installIdFor;
  // An own-App sign-in is usable only while its slot still signs in with the
  // App that issued it: the workspace's own App for its slot, the server's
  // for the global one. A rotated or replaced App asks people to sign in
  // again instead of serving the old App's tokens.
  forgeCredentials.currentGitHubClientId = ({workspaceId}) async {
    try {
      return workspaceId == null
          ? (await providerApps.oauthCredentials(ProviderApp.github))?.clientId
          : (await workspaceGitHub.storedOAuthCredentials(
              workspaceId,
            ))?.clientId;
    } on OwnAppIncomplete {
      return null;
    }
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
    mayReadRepo: (workspaceId, userId, owner, repo) async {
      final linked = await _findLinkedGitHubRepo(
        workspaceRepository,
        workspaceId,
        '$owner/$repo',
      );
      return linked != null &&
          await _memberMayReadRepo(
            membershipRepository,
            workspaceId,
            userId,
            linked.id,
          );
    },
    repoAccess: repoAccess,
    confirmRepo: forgeRepoPins.confirm,
    confirmPersonRequest: forgeRepoPins.confirmPersonRequest,
  );
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
      unawaited(githubClients.forgetAll());
    }
  });
  // Likewise another Connect or install key, whether chosen in Settings or
  // by `cc_server connect` from another process (noticed on the next
  // config read).
  connectSettings.addListener(() => unawaited(githubClients.forgetAll()));
  // Likewise another Connect choice in one workspace: what that workspace's
  // lanes minted or cached belongs to another identity now.
  connectSettings.addWorkspaceListener(
    (workspaceId) => unawaited(githubClients.forgetWorkspace(workspaceId)),
  );
  // Likewise a workspace's own App: a saved (rotated) key or a deleted
  // workspace drops and revokes what that workspace's App minted.
  workspaceGitHub.addListener(
    (workspaceId) => unawaited(githubClients.forgetWorkspace(workspaceId)),
  );
  final githubSignIn = GitHubSignInLane(
    apps: providerApps,
    workspaceApps: workspaceGitHub,
    workspaceLookup: workspaceRepository.getById,
    credentials: forgeCredentials,
    users: userCredentials,
    connect: connectClient,
  );
  providerSignIn.register(githubSignIn);
  _wireGitHubSlotResets(
    lane: githubSignIn,
    connectSettings: connectSettings,
    workspaceRepository: workspaceRepository,
    workspaceGitHub: workspaceGitHub,
  );
  return (forgeCredentials: forgeCredentials, githubClients: githubClients);
}

/// Revokes and deletes a workspace's GitHub slot grants whenever its sign-in
/// target changes, as Linear and Google already are:
///
/// - its Connect choice changed (or its custom Connect's pins were
///   confirmed): every grant in its slot;
/// - its own App was saved, rotated or removed while it is on its own apps:
///   the grants another client issued (a saved key with the same client
///   keeps them);
/// - the server's choice changed: the slot of every workspace that no
///   longer owns one (a `hosted` workspace on a server now also `hosted`),
///   since those grants are never read again.
void _wireGitHubSlotResets({
  required GitHubSignInLane lane,
  required ConnectSettings connectSettings,
  required DaoWorkspaceRepository workspaceRepository,
  required WorkspaceGitHubAppSettings workspaceGitHub,
}) {
  connectSettings.addWorkspaceListener(
    (workspaceId) => _runSlotReset(
      'github',
      workspaceId,
      () => lane.resetWorkspaceSlot(workspaceId),
    ),
  );
  workspaceGitHub.addListener((workspaceId) {
    _runSlotReset('github', workspaceId, () async {
      if (!(await connectSettings.routeFor(workspaceId)).workspaceOwnApps) {
        return;
      }
      final clientId = (await workspaceGitHub.storedOAuthCredentials(
        workspaceId,
      ))?.clientId;
      await lane.resetWorkspaceSlot(
        workspaceId,
        where: (token) =>
            token.isSealed || clientId == null || token.appId != clientId,
      );
    });
  });
  connectSettings.addListener(() {
    _runSlotReset('github', null, () async {
      for (final workspace in await workspaceRepository.getAll()) {
        if (workspace.isDeleted) {
          continue;
        }
        if (!(await connectSettings.routeFor(workspace.id)).workspaceSlot) {
          await lane.resetWorkspaceSlot(workspace.id);
        }
      }
    });
  });
}

/// What automation needs from [GitHubClients] beyond a client: the
/// attribution its posts carry and one-repository tokens as strings.
final class _GitHubAutomation {
  _GitHubAutomation(this._clients, this._workspaces);

  final GitHubClients _clients;
  final DaoWorkspaceRepository _workspaces;

  /// Automation posts as the App's bot on every lane. When a person asked
  /// for the post (an AI review they requested, a reply to them), naming
  /// them keeps the bot's words tied to who it acted for, and is what the PR
  /// conversation bridge recognises as its own thread. A post nobody asked
  /// for (a schedule, a webhook) is the bot's own and carries no prefix.
  Future<String Function(String body)?> reviewAttribution({
    required String workspaceId,
    required String owner,
    String? actingUserId,
  }) async {
    if (actingUserId == null ||
        actingUserId.isEmpty ||
        await _clients.laneFor(workspaceId) == GitHubLane.none) {
      return null;
    }
    final human = await _clients.accountableHuman(
      workspaceId,
      actingUserId: actingUserId,
    );
    if (human == null) {
      return null;
    }
    // The sign-in in the slot this workspace keeps them in: its own when it
    // overrides the server's Connect choice, else the person's global one.
    final stored = await _clients.credentials.storedCredential(
      ForgeHost.github,
      human,
      workspaceId: workspaceId,
    );
    final login = stored?.token.accountLogin ?? '';
    if (login.isEmpty) {
      return null;
    }
    return (body) => GitHubPrConversationBridge.attributed(login, body);
  }

  /// The GitHub account [userId] signed in with for [workspaceId], or null
  /// when they have no usable sign-in. A sign-in records the account's id
  /// and login; a grant without them is not a usable sign-in.
  Future<GitHubUser?> personAccount(String userId, String? workspaceId) async {
    final credential = await _clients.credentials.personCredential(
      ForgeHost.github,
      userId,
      workspaceId: workspaceId,
    );
    if (credential == null || credential.accessToken.isEmpty) {
      return null;
    }
    final id = int.tryParse(credential.accountId) ?? 0;
    if (id <= 0 || credential.accountLogin.isEmpty) {
      return null;
    }
    return GitHubUser(login: credential.accountLogin, avatarUrl: '', id: id);
  }

  final _prConversationGateways = <String, GitHubPrConversationGateway>{};

  /// One PR conversation gateway per workspace: its bot and lane, and its
  /// one-repository bot tokens (searches and reads bounded by the
  /// accountable human, replies and the 👀 claim by the member who asked).
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
          clientForRepo: (owner, repo) =>
              _clients.forRepo(workspaceId, owner, repo),
          linkedRepos: () async => [
            for (final repo
                in await _workspaces.watchReposForWorkspace(workspaceId).first)
              if (repo.forge == ForgeHost.github && repo.hasForgeRemote)
                (owner: repo.remoteOwner, repo: repo.remoteName),
          ],
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
  /// git. A refusal is logged and answers null; there is no fallback. A
  /// person's own action ([viaPerson]) without a usable GitHub sign-in throws
  /// [NeedsSignInException] instead, so the client offers the sign-in.
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
      if (viaPerson && e.code == GitHubRefusal.needsSignIn) {
        throw NeedsSignInException('github', e.message);
      }
      if (e.code == GitHubRefusal.needsRequester) {
        // Say why instead of letting git fail unauthenticated: on Connect
        // the bot does not push, and nobody asked for this push.
        throw ValidationException(e.message);
      }
      CcHostLog.warning(
        'github: no ${scope.wire} token for $owner/$repo in workspace '
        '$workspaceId (${e.code.wire})',
      );
      return null;
    }
  }
}

/// Whether [userId] is a member of [workspaceId] who may read the linked repo
/// [repoId] there: an admin, or a read grant on it.
Future<bool> _memberMayReadRepo(
  WorkspaceMembershipRepository members,
  String workspaceId,
  String userId,
  String repoId,
) async {
  final member = await members.getMember(workspaceId, userId);
  if (member == null) {
    return false;
  }
  if (member.role.isAdmin) {
    return true;
  }
  final grants = await members.getRepoGrants(workspaceId, userId);
  return (grants[repoId] ?? RepoGrantLevel.none).allowsRead;
}

/// The GitHub repository [repoFullName] (`owner/name`) when it is linked to
/// [workspaceId], else null: what a pipeline shell step may get a read token
/// for.
Future<({String owner, String name})?> _linkedGitHubRepo(
  DaoWorkspaceRepository workspaces,
  String workspaceId,
  String repoFullName,
) async {
  final repo = await _findLinkedGitHubRepo(
    workspaces,
    workspaceId,
    repoFullName,
  );
  return repo == null ? null : (owner: repo.remoteOwner, name: repo.remoteName);
}

/// The GitHub repository [repoFullName] linked to [workspaceId], or null:
/// the one lookup every "is it linked here?" question asks.
Future<Repo?> _findLinkedGitHubRepo(
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
      return repo;
    }
  }
  return null;
}

/// Re-checks every linked repository, on every forge, shortly after boot and
/// then daily, and records what automation meets there in [repoAccess]:
/// GitHub through [GitHubClients.sweepLinks] (accountable person, App
/// installation, repository selection), GitLab and Bitbucket by reading the
/// repository with its automation token ([ForgeAutomationTokens.check]; none
/// pauses it). Repository tokens of unlinked repositories are deleted on the
/// way. Returns the timers' cancels.
List<void Function()> _scheduleRepoLinkSweep(
  GitHubClients github,
  DaoWorkspaceRepository workspaces,
  RepoAccessRegistry repoAccess,
  ForgeAutomationTokens automationTokens,
) {
  Future<void> sweep() async {
    var blocked = 0;
    // Re-checked per workspace: a deleted one is never opened (that would
    // recreate its dropped database).
    await forEachLiveWorkspace(workspaces, (workspace) async {
      try {
        final repos = await workspaces
            .watchReposForWorkspace(workspace.id)
            .first;
        blocked += await github.sweepLinks(workspace.id, [
          for (final repo in repos)
            if (repo.forge == ForgeHost.github && repo.hasForgeRemote)
              (owner: repo.remoteOwner, repo: repo.remoteName),
        ]);
        await automationTokens.pruneUnlinked(workspace.id, repos);
        for (final repo in repos) {
          if (!ForgeAutomationTokens.supports(repo.forge) ||
              !repo.hasForgeRemote) {
            continue;
          }
          final issue = await automationTokens.check(workspace.id, repo);
          await recordForgeLinkCheck(
            repoAccess,
            workspace.id,
            repo.forge,
            repo.remoteOwner,
            repo.remoteName,
            issue,
            repoId: repo.id,
          );
          if (issue != null && issue.state.blocksAutomation) {
            blocked++;
          }
        }
      } on Object catch (e) {
        CcHostLog.warning(
          'forge: re-checking repository links in ${workspace.id} failed ($e)',
        );
      }
    });
    if (blocked > 0) {
      CcHostLog.info('forge: $blocked repository link(s) block automation');
    }
  }

  final boot = Timer(const Duration(minutes: 3), () => unawaited(sweep()));
  final daily = Timer.periodic(
    const Duration(days: 1),
    (_) => unawaited(sweep()),
  );
  return [boot.cancel, daily.cancel];
}

/// Renews Linear grants before their refresh tokens' thirty idle days run
/// out: every grant older than twenty, shortly after boot and then daily. A
/// deleted workspace's grants are left to lapse.
/// Returns the timers' cancels.
List<void Function()> _scheduleLinearRenewal(
  LinearClients linear,
  DaoWorkspaceRepository workspaces,
) {
  Future<void> renew() async {
    try {
      final renewed = await linear.refreshAging(
        isLiveWorkspace: (id) => isLiveWorkspace(workspaces, id),
      );
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
