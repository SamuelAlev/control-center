part of '../cc_server_runtime.dart';

/// The space stack service (`stack_*` tools and ops): pushes and opens each
/// layer's pull request on the repository's own forge, as the person who
/// asked (their own token) or, when nobody did, the repository's automation.
SpaceStackService _wireSpaceStackService({
  required DaoIsolatedRepoRepository isolatedRepoRepository,
  required DaoSpaceStackRepository spaceStackRepository,
  required DaoRepoRepository repoRepository,
  required WorkspaceDatabaseManager workspaceDbs,
  required _GitHubAutomation githubAutomation,
  required ForgeCredentials forgeCredentials,
  required ForgeAutomationTokens forgeAutomationTokens,
  required AgentPrClientFor forgePrClientForRepo,
  required AgentPrRequesters agentPrRequesters,
  required AgentCommitIdentities agentCommitIdentities,
  required WorkspaceMembershipRepository members,
}) => SpaceStackService(
  isolatedRepos: isolatedRepoRepository,
  // A person's publish holds commits authored as the agent to the agent rule.
  agentsOf: agentCommitIdentities.agentsOf,
  stacks: spaceStackRepository,
  repos: repoRepository,
  pinnedBase: (workspaceId, spaceId, repoId) async {
    final branches = await workspaceDbs
        .of(workspaceId)
        .spaceRepoDao
        .repoBranchesForSpace(workspaceId, spaceId);
    final branch = branches[repoId];
    if (branch == null || branch.trim().isEmpty) {
      return null;
    }
    return branch;
  },
  tokenFor: (repo, actingUserId, workspaceId) => repo.forge == ForgeHost.github
      ? githubAutomation.repoToken(
          workspaceId,
          repo.remoteOwner,
          repo.remoteName,
          GitHubTokenScope.write,
          actingUserId: actingUserId,
          // A stack a person pushes rides their own one-repository token,
          // so GitHub's own pusher and author rules see them.
          viaPerson: actingUserId != null && actingUserId.isNotEmpty,
        )
      // A person's stack rides their own GitLab/Bitbucket token, or asks
      // them to connect one; nobody's work borrows another's. A stack
      // nobody requested rides the repository's automation token (a bot),
      // and without one it stops here with the repository paused.
      : actingUserId != null && actingUserId.isNotEmpty
      ? forgeCredentials.requirePersonToken(
          repo.forge,
          actingUserId,
          workspaceId: workspaceId,
        )
      : !ForgeAutomationTokens.supports(repo.forge)
      ? Future<String?>.value()
      : forgeAutomationTokens.tokenForRepo(workspaceId, repo).then((token) {
          if (token == null) {
            throw ValidationException(
              ForgeAutomationTokens.missingMessage(repo),
            );
          }
          return token;
        }),
  // A person's publish pushes only where they hold the write grant.
  mayPush: (workspaceId, repo, userId) =>
      holdsRepoWriteGrant(members, workspaceId, userId, repo.id),
  stacksSupported: (repo) => kForgeCapabilities[repo.forge]?.stacks ?? false,
  openPullRequest:
      ({
        required repo,
        required workspaceId,
        required title,
        required body,
        required head,
        required base,
        required draft,
        actingUserId,
        required approvalOwnerUserIds,
      }) async {
        final client = forgePrClientForRepo(
          repo,
          actingUserId: actingUserId,
          workspaceId: workspaceId,
          viaPerson: true,
        );
        String? requesterLogin;
        if (actingUserId != null && actingUserId.isNotEmpty) {
          try {
            requesterLogin = await forgeCredentials.viewerLogin(
              repo.forge,
              userId: actingUserId,
              workspaceId: workspaceId,
            );
          } on Object catch (_) {
            // The marker then names no login.
          }
        }
        // A stack layer is the agent's work published for this person:
        // they may not approve it themselves (see AgentPrRequesters).
        final pr = await agentPrRequesters.open(
          repo: repo,
          head: head,
          approvalOwnerUserIds: approvalOwnerUserIds,
          create: () => client.createPullRequest(
            title: title,
            body: withAgentPullRequestMarker(
              body,
              requesterLogin: requesterLogin,
            ),
            headBranch: head,
            baseBranch: base,
            draft: draft,
          ),
        );
        return (number: pr.number, externalId: pr.externalId);
      },
  groupStack:
      ({
        required repo,
        required workspaceId,
        required prNumbers,
        actingUserId,
      }) async {
        // The requester's own sign-in narrowed to this one repository, as
        // for opening the layers: never their whole sign-in while an agent
        // drives (nor for a person, who needs no more than the one repo).
        final client = forgePrClientForRepo(
          repo,
          actingUserId: actingUserId,
          workspaceId: workspaceId,
          viaPerson: true,
        );
        final existing = await client.listStacks(prNumber: prNumbers.first);
        if (existing.isEmpty) {
          await client.createStack(prNumbers: prNumbers);
          return;
        }
        final have = existing.first.pullRequests
            .map((entry) => entry.number)
            .toSet();
        final missing = [
          for (final number in prNumbers)
            if (!have.contains(number)) number,
        ];
        if (missing.isNotEmpty) {
          await client.addToStack(
            stackNumber: existing.first.number,
            prNumbers: missing,
          );
        }
      },
);
