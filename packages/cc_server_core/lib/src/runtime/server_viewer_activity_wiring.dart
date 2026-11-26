part of '../cc_server_runtime.dart';

/// One viewer-activity poller per person signed in to GitHub in a live
/// workspace, each reading with that person's own token and routing only into
/// the workspaces they belong to. Nobody else's inbox is ever polled with
/// another member's credential.
///
/// A person signed in to a workspace's own App has a separate grant there, so
/// pollers are keyed by `(person, grant slot)`. The set is rescanned
/// periodically, so a sign-in, sign-out or membership change applies within a
/// rescan.
final class ViewerActivityPollers {
  /// Creates the set. [start] arms it.
  ViewerActivityPollers({
    required this._signedIn,
    required this._build,
    this._rescanEvery = const Duration(minutes: 2),
  });

  /// `(userId, slot) → workspaces` for everyone signed in right now. The slot
  /// is a workspace id for a workspace-App grant, else empty.
  final Future<Map<({String userId, String slot}), Set<String>>> Function()
  _signedIn;

  final GitHubViewerActivityPollingService Function(
    String userId,
    String slot,
    Set<String> workspaceIds,
  )
  _build;

  final Duration _rescanEvery;

  final Map<
    ({String userId, String slot}),
    ({GitHubViewerActivityPollingService poller, Set<String> workspaces})
  >
  _pollers = {};
  Timer? _timer;
  bool _disposed = false;
  Future<void>? _scanning;

  /// Starts polling and the periodic rescan.
  void start() {
    unawaited(rescan());
    _timer ??= Timer.periodic(_rescanEvery, (_) => unawaited(rescan()));
  }

  /// Re-reads who is signed in and adds, replaces or drops pollers.
  Future<void> rescan() => _scanning ??= _scan().whenComplete(() {
    _scanning = null;
  });

  Future<void> _scan() async {
    if (_disposed) {
      return;
    }
    final Map<({String userId, String slot}), Set<String>> wanted;
    try {
      wanted = await _signedIn();
    } on Object catch (e) {
      CcHostLog.warning(
        'viewer_activity: listing signed-in members failed: $e',
      );
      return;
    }
    if (_disposed) {
      return;
    }
    for (final key in _pollers.keys.toList()) {
      final current = _pollers[key]!;
      final next = wanted[key];
      if (next == null || !_sameSet(next, current.workspaces)) {
        current.poller.dispose();
        _pollers.remove(key);
      }
    }
    for (final entry in wanted.entries) {
      if (_pollers.containsKey(entry.key)) {
        continue;
      }
      final poller = _build(entry.key.userId, entry.key.slot, entry.value)
        ..start();
      _pollers[entry.key] = (poller: poller, workspaces: entry.value);
    }
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  /// Stops every poller and the rescan.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final entry in _pollers.values) {
      entry.poller.dispose();
    }
    _pollers.clear();
  }
}

ViewerActivityPollers _buildViewerActivityPollers({
  required GitHubClients githubClients,
  required ForgeCredentials forgeCredentials,
  required DaoWorkspaceRepository workspaceRepository,
  required WorkspaceMembershipRepository membershipRepository,
  required DomainEventBus eventBus,
  required PrChangeSignals prChangeSignals,
  required RepoWorkspaceIndex repoWorkspaceIndex,
  required OpenPrPollingService openPrPoller,
  required GlobalDatabase globalDb,
}) {
  // Viewer-activity poll: a person's PR activity (pending reviews incl. team,
  // mentions, merges) as four aliased GraphQL searches per sweep →
  // `PrReviewRequested` + targeted refresh of linked-repo open streams.
  // `search` works on a user token; there is no inbox fallback and no
  // background identity — each person is polled on their own sign-in.
  return ViewerActivityPollers(
    signedIn: () async {
      final out = <({String userId, String slot}), Set<String>>{};
      for (final workspace in await workspaceRepository.watchAll().first) {
        if (workspace.deletedAt != null) {
          continue;
        }
        for (final member in await membershipRepository.getForWorkspace(
          workspace.id,
        )) {
          final stored = await forgeCredentials.storedCredential(
            ForgeHost.github,
            member.userId,
            workspaceId: workspace.id,
          );
          if (stored == null) {
            continue;
          }
          final key = (userId: member.userId, slot: stored.workspaceId ?? '');
          (out[key] ??= <String>{}).add(workspace.id);
        }
      }
      return out;
    },
    build: (userId, slot, workspaceIds) {
      final slotWorkspace = slot.isEmpty ? null : slot;
      final client = githubClients.asPerson(userId, workspaceId: slotWorkspace);
      final dedupeKey = slot.isEmpty
          ? 'githubActivityDedupe:$userId'
          : 'githubActivityDedupe:$userId:$slot';
      return GitHubViewerActivityPollingService(
        githubClient: client,
        shouldPoll: () =>
            githubClients.isSignedIn(userId, workspaceId: slotWorkspace),
        eventBus: eventBus,
        changeSignals: prChangeSignals,
        // The comment lane resolves a mention down to the comment that
        // carries it, so the notification names the file and line.
        viewerLogin: () => forgeCredentials.viewerLogin(
          ForgeHost.github,
          userId: userId,
          workspaceId: slotWorkspace,
        ),
        commentFetch: GitHubViewerCommentFetchAdapter(
          prClient: client.pr,
          graphqlClient: client.graphql,
        ),
        forUserId: userId,
        // Only workspaces this person belongs to (and whose grant this is).
        workspacesForRepo: (repoFullName) async => [
          for (final id in await repoWorkspaceIndex.workspacesFor(repoFullName))
            if (workspaceIds.contains(id)) id,
        ],
        onWorkspaceTouched: (workspaceId) =>
            unawaited(openPrPoller.pollSoon(workspaceId)),
        onPrsActive: openPrPoller.syncPullRequests,
        // A person's activity spans workspaces, so the dedupe store lives in
        // global.db's server_meta, one key per person and grant.
        loadDedupeState: () => globalDb.workspaceRouteDao.meta(dedupeKey),
        saveDedupeState: (state) =>
            globalDb.workspaceRouteDao.setMeta(dedupeKey, state),
      );
    },
  );
}
