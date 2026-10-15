part of '../cc_server_runtime.dart';

GitHubViewerActivityPollingService _buildViewerActivityPoller({
  required ForgeHttpClientFactory ownerForgeHttpClientFactory,
  required ForgeCredentials forgeCredentials,
  required String ownerUserId,
  required DaoWorkspaceRepository workspaceRepository,
  required DomainEventBus eventBus,
  required PrChangeSignals prChangeSignals,
  required RepoWorkspaceIndex repoWorkspaceIndex,
  required OpenPrPollingService openPrPoller,
  required GlobalDatabase globalDb,
}) {
  // Viewer-activity poll: owner's PR activity (pending reviews incl. team,
  // mentions, merges) as four aliased GraphQL searches per sweep →
  // `PrReviewRequested` + targeted refresh of linked-repo open streams.
  //
  // Replaced `GET /notifications` (user-only; GitHub App tokens 403). `search`
  // works for every credential kind; no inbox fallback.
  //
  // Gated per pass on the OWNER'S OWN credential (not bare `ghToken`): app
  // identity / `GITHUB_TOKEN` made `ghToken` non-empty with nobody signed in,
  // and a boot-time gate never started after late onboarding / never stopped
  // after sign-out.
  return GitHubViewerActivityPollingService(
    githubClient: GitHubApiClient(
      ownerForgeHttpClientFactory.of(ForgeHost.github),
    ),
    shouldPoll: () async {
      final token = await forgeCredentials.tokenFor(
        ForgeHost.github,
        userId: ownerUserId,
      );
      if (token == null || token.isEmpty) {
        return false;
      }
      // Nowhere to route a notification to. Every PR would be resolved
      // against the repo→workspace index and dropped, so this is a request
      // per minute for a guaranteed no-op.
      final workspaces = await workspaceRepository.watchAll().first;
      return workspaces.any((w) => w.deletedAt == null);
    },
    eventBus: eventBus,
    changeSignals: prChangeSignals,
    // The comment lane: resolves a mention down to the comment that carries
    // it, so the notification names the file and line and the deep link lands
    // on the comment. Runs on the OPERATOR's credential, which is why it lives
    // here and not in the bot's conversation poller — that one holds app
    // installation tokens and cannot see a human mentioning this person on a
    // repo the app is not installed on.
    viewerLogin: () =>
        forgeCredentials.viewerLogin(ForgeHost.github, userId: ownerUserId),
    commentFetch: GitHubViewerCommentFetchAdapter(
      prClient: GitHubApiClient(
        ownerForgeHttpClientFactory.of(ForgeHost.github),
      ).pr,
      graphqlClient: GitHubApiClient(
        ownerForgeHttpClientFactory.of(ForgeHost.github),
      ).graphql,
    ),
    forUserId: ownerUserId,
    // Answered from a maintained `repo full name → workspace ids` index
    // instead of re-reading every workspace and then every workspace's
    // repo list on each lookup (O(workspaces) queries per repo per ~60s
    // tick). Repo↔workspace links change rarely, so the index is rebuilt on
    // a TTL rather than per lookup.
    workspacesForRepo: repoWorkspaceIndex.workspacesFor,
    onWorkspaceTouched: (workspaceId) =>
        unawaited(openPrPoller.pollSoon(workspaceId)),
    // The viewer's activity is cross-workspace, so the dedupe store lives in
    // global.db's server_meta — not in any workspace file. A fresh key: the
    // v1 store under `githubNotificationDedupe` was keyed by notification
    // thread id, which has no meaning for a search-derived sweep.
    loadDedupeState: () =>
        globalDb.workspaceRouteDao.meta('githubActivityDedupe'),
    saveDedupeState: (state) =>
        globalDb.workspaceRouteDao.setMeta('githubActivityDedupe', state),
  );
}
