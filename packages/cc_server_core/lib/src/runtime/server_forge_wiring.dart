part of '../cc_server_runtime.dart';

// The forge access wiring runCcServer composes: which HTTP client each
// GitLab/Bitbucket call rides, how a denied repository is classified, how a
// link is verified, how agents open and comment on pull requests, and the
// per-person reads (merged history, review requests, live notifications)
// that PR visibility gates.

/// The authenticated HTTP client one repository's forge client rides, where
/// [actingUserId] picks whose name the calls carry. Without an actor, GitHub
/// work (GraphQL included) rides that one repository's installation-lane
/// tokens bounded by the workspace's accountable human (never a person's own
/// token), and GitLab/Bitbucket work the repository's automation token (a
/// bot); that is only correct for work with no human behind it. [viaPerson]
/// is an agent's work published for [actingUserId]: their own sign-in
/// narrowed to this one repository (on GitLab/Bitbucket, their own token).
RhttpClient _forgeRepoHttp(
  GitHubClients github,
  _ForgeHttpClients forge,
  Repo repo, {
  required String workspaceId,
  required String? actingUserId,
  required bool viaPerson,
}) {
  final person = actingUserId != null && actingUserId.isNotEmpty;
  if (repo.forge != ForgeHost.github) {
    if (!person) {
      return ForgeAutomationTokens.supports(repo.forge)
          ? forge.automationForRepo(workspaceId, repo)
          : forge.forActor(null, workspaceId: workspaceId).of(repo.forge);
    }
    return forge.personForRepo(workspaceId, repo, actingUserId);
  }
  if (!person) {
    return github.httpForRepo(workspaceId, repo.remoteOwner, repo.remoteName);
  }
  return viaPerson
      ? github.httpForRepo(
          workspaceId,
          repo.remoteOwner,
          repo.remoteName,
          actingUserId: actingUserId,
          viaPerson: true,
        )
      : github.personHttp(actingUserId, workspaceId: workspaceId);
}

/// The GitLab and Bitbucket HTTP clients the server's forge clients ride.
class _ForgeHttpClients {
  _ForgeHttpClients({
    required this._credentials,
    required this._automationTokens,
    required this._pins,
  });

  final ForgeCredentials _credentials;
  final ForgeAutomationTokens _automationTokens;
  final ForgeRepoPins _pins;
  final ForgeClientCache<String, RhttpClient> _automationClients =
      ForgeClientCache.http();
  final ForgeClientCache<String, RhttpClient> _personRepoClients =
      ForgeClientCache.http();
  final ForgeClientCache<String, ForgeHttpClientFactory> _actorFactories =
      ForgeClientCache.factories();

  /// Whether [close] ran.
  bool get isClosed => _closed;
  var _closed = false;

  /// Releases every client. Nothing may be built afterwards.
  void close() {
    _closed = true;
    _automationClients.close();
    _personRepoClients.close();
    _actorFactories.close();
  }

  /// A repository's clients are keyed by its id and its path: a link that
  /// moved with its repository gets a client confined to the new path.
  static String _repoKey(String workspaceId, Repo repo, [String user = '']) =>
      [
        workspaceId,
        repo.forge.wire,
        repo.id,
        repo.remoteOwner,
        repo.remoteName,
        user,
      ].join('\u0000');

  /// One automation client per (workspace, repository): the token is read
  /// per request, so a token saved or cleared applies on the next call, and
  /// every request first confirms the repository is still the one linked
  /// ([ForgeRepoPins.confirmRequest]).
  RhttpClient automationForRepo(String workspaceId, Repo repo) =>
      _automationClients.get(
        _repoKey(workspaceId, repo),
        () => ForgeHttpClientFactory(
          tokenLookup: (forge) async {
            final token = await _automationTokens.tokenForRepo(
              workspaceId,
              repo,
            );
            if (token == null) {
              throw ForgeCredentialUnavailable.automationTokenMissing(
                ForgeAutomationTokens.missingMessage(repo),
              );
            }
            await _pins.confirmRequest(workspaceId, repo, token);
            return token;
          },
          // Confined to this repository, and never an approval.
          requestGuard: (forge, method, url, _) => refuseForgeAutomationRequest(
            forge,
            repo.remoteOwner,
            repo.remoteName,
            method,
            url,
            workspaceId: workspaceId,
          ),
        ).of(repo.forge),
      );

  /// One person's client for one GitLab or Bitbucket repository: their own
  /// token ([forActor]'s), and every request first confirms the repository
  /// is still the one linked ([ForgeRepoPins.confirmRequest]).
  RhttpClient personForRepo(String workspaceId, Repo repo, String userId) =>
      _personRepoClients.get(
        _repoKey(workspaceId, repo, userId),
        () => _personFactory(userId, workspaceId, pinned: repo).of(repo.forge),
      );

  /// Per-actor GitLab and Bitbucket HTTP clients: a person's action carries
  /// that person's own token and nobody else's. Without an actor there is no
  /// repository to pick an automation token for, so such a call is refused
  /// locally (automation goes through [automationForRepo]). GitHub never
  /// rides this factory — a person goes through [GitHubClients.personHttp]
  /// and automation through [GitHubClients.httpForOwner] — so its lookup
  /// sends no credential at all. A person with no token of their own on that
  /// forge is refused locally as `needs_sign_in` (lane: the forge wire):
  /// nothing goes out anonymously.
  ///
  /// Memoized per user; the token is still read per request in the
  /// interceptor so a sign-in or sign-out applies on the next call.
  ForgeHttpClientFactory forActor(String? userId, {String? workspaceId}) =>
      _actorFactories.get(
        '${userId ?? ''}\u0000${workspaceId ?? ''}',
        () => _personFactory(userId, workspaceId),
      );

  /// The one person's-own-token factory behind [forActor] and
  /// [personForRepo]. Every request first confirms that the repository it
  /// is about is still the one linked: [pinned] when given
  /// ([ForgeRepoPins.confirmRequest]), else whichever linked repository the
  /// request names ([ForgeRepoPins.confirmPersonRequest]).
  ForgeHttpClientFactory _personFactory(
    String? userId,
    String? workspaceId, {
    Repo? pinned,
  }) {
    final person = userId == null || userId.isEmpty ? null : userId;
    Future<String?> token(ForgeHost forge) async {
      if (person == null && forge != ForgeHost.github && forge.isSupported) {
        throw ForgeCredentialUnavailable.automationTokenMissing(
          'Automation on ${forge.displayName} needs a repository and its '
          'automation token.',
        );
      }
      return person == null
          ? null
          : await _personToken(forge, person, workspaceId);
    }

    return ForgeHttpClientFactory(
      tokenLookup: token,
      requestTokenLookup: (forge, method, url, jsonBody) async {
        final value = await token(forge);
        if (value != null && pinned != null) {
          await _pins.confirmRequest(workspaceId ?? '', pinned, value);
        } else {
          await _pins.confirmPersonRequest(
            workspaceId ?? '',
            forge,
            url,
            jsonBody,
            value,
          );
        }
        return value;
      },
    );
  }

  /// [userId]'s own token on [forge]; refused locally as `needs_sign_in`
  /// when they have none. Null (no credential) for GitHub and any forge
  /// without tokens.
  Future<String?> _personToken(
    ForgeHost forge,
    String userId,
    String? workspaceId,
  ) async {
    if (forge == ForgeHost.github || !forge.isSupported) {
      return null;
    }
    final token = await _credentials.tokenFor(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    );
    if (token == null || token.isEmpty) {
      throw ForgeCredentialUnavailable.needsSignIn(
        forge.wire,
        ForgeCredentials.signInRequiredMessage(forge),
      );
    }
    return token;
  }
}

/// How the open-PR poller reads a denied probe of a repository: on GitLab
/// and Bitbucket, the repository's automation token check; on GitHub, what
/// automation meets there ([GitHubClients.classifyRepo]), without a mint.
RepoAccessClassifier _classifyRepoAccess({
  required ForgeAutomationTokens forgeAutomationTokens,
  required GitHubClients githubClients,
}) => (workspaceId, repo, error) async {
  if (repo.forge != ForgeHost.github) {
    // GitLab/Bitbucket sweeps ride the repository's automation token
    // only: none, one the forge refuses, or one that cannot read the
    // repository all pause it until an admin adds a working one.
    final issue = await forgeAutomationTokens.check(workspaceId, repo);
    return (
      state: issue?.state ?? RepoAccessState.transient,
      message:
          issue?.message ??
          '${repo.forge.displayName} did not answer for '
              '${repo.fullName}; retrying.',
      installUrl: null,
    );
  }
  // On GitHub a 404 is usually the App not reaching the repository (not
  // installed there, the repository not selected, suspended) or the
  // accountable person not seeing it: read it from the App's installations
  // and the person's own view, minting nothing.
  final found = await githubClients.classifyRepo(
    workspaceId,
    repo.remoteOwner,
    repo.remoteName,
  );
  if (found.isEmpty) {
    // The App reaches it and the person sees it, yet GitHub answered "not
    // found" to the poll.
    return (
      state: RepoAccessState.ownerCannotSee,
      message: 'GitHub does not show ${repo.fullName} to this workspace.',
      installUrl: null,
    );
  }
  final first = found.first;
  return (
    state: first.state,
    message: first.message,
    installUrl: first.installUrl,
  );
};

/// Verifies a repository link for the linking member. Hard refusals (the
/// linker cannot see it, or is not signed in) throw; what automation will
/// meet comes back as warnings and is recorded in the repo access registry,
/// with the forge's durable id for the repository as the linker's read saw
/// it (what the link is pinned to).
VerifyRepoLink _repoLinkVerifier({
  required GitHubClients githubClients,
  required ForgeLinkChecker forgeLinkChecker,
  required ForgeAutomationTokens forgeAutomationTokens,
  required RepoAccessRegistry repoAccess,
}) => ({required workspaceId, required userId, required repo}) async {
  const nothing = (forgeRepoId: '', warnings: <RepoAccessIssue>[]);
  if (!repo.hasForgeRemote) {
    return nothing;
  }
  if (repo.forge == ForgeHost.github) {
    try {
      return await githubClients.verifyLink(
        workspaceId,
        userId,
        repo.remoteOwner,
        repo.remoteName,
        repoId: repo.id,
      );
    } on GitHubScopeRefused catch (e) {
      throw ValidationException(e.message);
    }
  }
  if (!repo.forge.isSupported) {
    return nothing;
  }
  final (issue: linker, :forgeRepoId) = await forgeLinkChecker.check(
    workspaceId,
    repo.forge,
    repo.remoteOwner,
    repo.remoteName,
    userId: userId,
  );
  if (linker != null) {
    throw linker.state == RepoAccessState.ownerNotSignedIn
        ? NeedsSignInException(repo.forge.wire, linker.message)
        : ValidationException(linker.message);
  }
  // What automation will meet: the repository's (or workspace's)
  // automation token, never the linker's or anyone else's.
  final automation = await forgeAutomationTokens.check(workspaceId, repo);
  await recordForgeLinkCheck(
    repoAccess,
    workspaceId,
    repo.forge,
    repo.remoteOwner,
    repo.remoteName,
    automation,
    repoId: repo.id,
  );
  return (forgeRepoId: forgeRepoId, warnings: [?automation]);
};

/// How agent runs open pull requests (`open_pull_request`, `stack_publish`),
/// edit their own (`update_pull_request`) and comment on them
/// (`comment_on_pull_request`).
///
/// Opening and editing: as the person who requested the run, read from the
/// run's gateway grant. Commenting: its own token only reads, so the
/// server posts as the bot (bounded by the run's requester, with the
/// attribution prefix). An edit or a comment lands only on a pull request
/// whose head branch is the run's own in a repo linked to its workspace
/// ([AgentRunPullRequestScope]).
({
  AgentPullRequestService pullRequests,
  AgentPullRequestCommentService comments,
})
_wireAgentPullRequests({
  required AgentRunsLookup openRuns,
  required DaoWorkspaceRepository workspaceRepository,
  required WorkspaceDatabaseManager workspaceDbs,
  required WorkspaceMembershipRepository membershipRepository,
  required AgentPrClientFor clientFor,
  required AgentPrRequesters requesters,
  required ForgeCredentials forgeCredentials,
  required DaoAgentRunLogRepository agentRunLogRepository,
  required PipelineRunRepositoryImpl pipelineRunRepository,
  required GitHubClients githubClients,
  required _GitHubAutomation githubAutomation,
}) {
  Future<List<Repo>> linkedRepos(String workspaceId) =>
      workspaceRepository.watchReposForWorkspace(workspaceId).first;
  Future<Map<String, String>> spaceBranches(
    String workspaceId,
    String spaceId,
  ) => workspaceDbs
      .of(workspaceId)
      .spaceRepoDao
      .repoBranchesForSpace(workspaceId, spaceId);
  Future<bool> isMember(String workspaceId, String userId) async =>
      await membershipRepository.getMember(workspaceId, userId) != null;
  Future<bool> mayRead(String workspaceId, String userId, Repo repo) =>
      _memberMayReadRepo(membershipRepository, workspaceId, userId, repo.id);
  final scope = AgentRunPullRequestScope(
    openRuns: openRuns,
    linkedRepos: linkedRepos,
    spaceBranches: spaceBranches,
    spaceBranchHead: spaceBranchHeadIn(DaoIsolatedRepoRepository(workspaceDbs)),
    isMember: isMember,
    mayRead: mayRead,
  );
  final pullRequests = AgentPullRequestService(
    scope: scope,
    clientFor: clientFor,
    requesters: requesters,
    viewerLogin: (forge, userId, workspaceId) => forgeCredentials.viewerLogin(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    ),
    // A run nobody requested was started by an armed trigger's pipeline:
    // the engine recorded everyone who armed it on the pipeline run.
    armedBy: (workspaceId, conversationId) async {
      final armers = <String>{};
      for (final log in await agentRunLogRepository.activeByConversation(
        workspaceId,
        conversationId,
      )) {
        final pipelineRunId = log.pipelineRunId;
        if (pipelineRunId == null || pipelineRunId.isEmpty) {
          continue;
        }
        final run = await pipelineRunRepository.getRun(pipelineRunId);
        if (run == null || run.workspaceId != workspaceId) {
          continue;
        }
        armers.addAll(pipelineArmedByOf(run.triggerPayload));
      }
      return armers;
    },
  );
  final comments = AgentPullRequestCommentService(
    scope: scope,
    clientFor:(repo, {required workspaceId, actingUserId}) =>
        repo.forge == ForgeHost.github
        ? forgePrClientBuilder(
            repo.forge,
            githubClients.httpForRepo(
              workspaceId,
              repo.remoteOwner,
              repo.remoteName,
              actingUserId: actingUserId,
            ),
            approvalGuard: requesters.guardFor,
          )(repo, workspaceId: workspaceId, actingUserId: actingUserId)
        // GitLab/Bitbucket: the repository's automation token.
        : clientFor(repo, workspaceId: workspaceId),
    attribution: (repo, {required workspaceId, actingUserId}) async =>
        repo.forge == ForgeHost.github
        ? githubAutomation.reviewAttribution(
            workspaceId: workspaceId,
            owner: repo.remoteOwner,
            actingUserId: actingUserId,
          )
        : null,
  );
  return (pullRequests: pullRequests, comments: comments);
}

/// GitHub's merged-history search: ONE search per chunk of repos under the
/// person's own sign-in.
MergedPrSearch _githubMergedSearch(GitHubClients githubClients) =>
    ({
      required login,
      required repos,
      required mergedSince,
      required userId,
      required workspaceId,
    }) async {
      final byName = {for (final r in repos) r.fullName.toLowerCase(): r};
      final hits = await githubClients
          .asPerson(userId, workspaceId: workspaceId)
          .pr
          .searchMergedPullRequestsByAuthor(
            author: login,
            repoFullNames: [for (final r in repos) r.fullName],
            mergedSince: mergedSince,
          );
      return [
        for (final hit in hits)
          if (byName[hit.repoFullName.toLowerCase()] case final repo?)
            (
              repo: repo,
              pr: pullRequestFromGitHub(hit.pr, repoFullName: repo.fullName),
            ),
      ];
    };

/// GitLab's merged-history search: ONE search across every project under the
/// person's own token, then filtered to the linked ones.
MergedPrSearch _gitlabMergedSearch(
  ForgeHttpClientFactory Function(String? userId, {String? workspaceId})
  factoryForActor,
) =>
    ({
      required login,
      required repos,
      required mergedSince,
      required userId,
      required workspaceId,
    }) async {
      final byPath = {for (final r in repos) r.fullName.toLowerCase(): r};
      final hits = await GitLabApiClient(
        factoryForActor(userId, workspaceId: workspaceId).of(ForgeHost.gitlab),
      ).listMergedMergeRequestsByAuthor(login, updatedAfter: mergedSince);
      return [
        for (final hit in hits)
          if (byPath[hit.projectPath.toLowerCase()] case final repo?)
            (
              repo: repo,
              pr: pullRequestFromGitLab(hit.mr, repoFullName: repo.fullName),
            ),
      ];
    };

/// Dashboard `review-requested:<viewer>` search, resolved per call for the
/// acting user: an empty login is an empty result, and the next call asks
/// again.
ReviewRequestedFetcher _reviewRequestedFetcher({
  required ViewerGitHubIdentityCache Function(
    String userId, {
    required String workspaceId,
  })
  identityFor,
  required GitHubApiClient Function(String userId, {String? workspaceId})
  clientFor,
}) => (repos, actingUserId, {required workspaceId}) async {
  final login =
      (await identityFor(
        actingUserId,
        workspaceId: workspaceId,
      ).user())?.login ??
      '';
  if (login.isEmpty) {
    return const <({Repo repo, PullRequest pr})>[];
  }
  final nodes = await clientFor(actingUserId, workspaceId: workspaceId).graphql
      .searchReviewRequestedPullRequests(
        reviewerLogin: login,
        repos: [
          for (final r in repos) (owner: r.remoteOwner, name: r.remoteName),
        ],
      );
  final byFullName = {for (final r in repos) r.fullName.toLowerCase(): r};
  final out = <({Repo repo, PullRequest pr})>[];
  for (final node in nodes) {
    final mapped = priorityReviewFromSearchNode(node);
    if (mapped == null) {
      continue;
    }
    final repo = byFullName[mapped.repoFullName.toLowerCase()];
    if (repo == null) {
      continue;
    }
    out.add((repo: repo, pr: mapped.pr));
  }
  return out;
};

/// The PR-list "reviewed by me" key set — what drives the inbox's "Waiting
/// for author" section.
ReviewedByFetcher _reviewedByFetcher({
  required ViewerGitHubIdentityCache Function(
    String userId, {
    required String workspaceId,
  })
  identityFor,
  required GitHubApiClient Function(String userId, {String? workspaceId})
  clientFor,
}) => (repos, actingUserId, {required workspaceId}) async {
  final login =
      (await identityFor(
        actingUserId,
        workspaceId: workspaceId,
      ).user())?.login ??
      '';
  if (login.isEmpty) {
    return const <String>{};
  }
  final pairs = await clientFor(actingUserId, workspaceId: workspaceId).graphql
      .searchReviewedByPullRequests(
        reviewerLogin: login,
        repos: [
          for (final r in repos) (owner: r.remoteOwner, name: r.remoteName),
        ],
      );
  return {for (final p in pairs) '${p.repoFullName}#${p.number}'};
};

/// Live notification frames pass the durable feed's rule per frame
/// ([notificationDeliveryCheck], the web push check), so a frame never shows
/// what the feed would not.
Future<bool> Function(
  String workspaceId,
  String userId,
  String method,
  Map<String, dynamic> params,
)
_notificationViewCheck(
  Future<bool> Function(NotificationFeedItem item, String userId) canView,
) => (workspaceId, userId, method, params) => canView(
  NotificationFeedItem(
    id: 'live',
    workspaceId: workspaceId,
    method: method,
    params: params,
    createdAt: DateTime.now(),
  ),
  userId,
);
