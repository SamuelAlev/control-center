part of 'open_pr_polling_service.dart';

// Which repositories a sweep may read and report: access probes and their
// registry record, the open-PR follow-up, and dropping the snapshot rows of
// repos that were unlinked or cannot be reached.

/// What a denied probe means for a repository: the [RepoAccessRegistry] state
/// to record, a person-readable message and, for App installation problems,
/// where to fix it.
typedef RepoAccessVerdict = ({
  RepoAccessState state,
  String message,
  String? installUrl,
});

/// Classifies a probe of [repo] in [workspaceId] that the forge denied
/// ([error] is an access denial, never a transient failure). On GitHub App
/// lanes a 404 is whatever the one-repository mint reports; on GitLab and
/// Bitbucket it is the repository's automation token (its own, else the
/// workspace's) that is missing, refused or cannot read the repo.
typedef RepoAccessClassifier =
    Future<RepoAccessVerdict> Function(
      String workspaceId,
      Repo repo,
      NetworkException error,
    );

/// The verdict when no lane-aware classifier is wired: a suspended
/// installation or a missing automation token says so, any other denial
/// means the accountable person's credential could not see the repository.
Future<RepoAccessVerdict> _defaultVerdict(
  String workspaceId,
  Repo repo,
  NetworkException error,
) async => switch (error.code) {
  kGitHubInstallationSuspendedCode => (
    state: RepoAccessState.installationSuspended,
    message:
        'The GitHub App installation on ${repo.remoteOwner} is '
        'suspended.',
    installUrl: null,
  ),
  kAutomationTokenMissingCode => (
    state: RepoAccessState.automationTokenMissing,
    message: error.message,
    installUrl: null,
  ),
  _ => (
    state: RepoAccessState.ownerCannotSee,
    message:
        'The workspace\'s accountable person cannot see '
        '${repo.fullName} on ${repo.forge.displayName}.',
    installUrl: null,
  ),
};

/// The access-denial carried by [error], or null when the failure is
/// transient. GitHub answers a credential that cannot see a repo with 404
/// (not 403) to avoid leaking its existence — for a registered repo that is
/// an access problem, not a missing resource. A GitLab or Bitbucket repo
/// with no automation token is refused locally the same way.
NetworkException? _accessDenial(Object error) {
  if (error is! NetworkException) {
    return null;
  }
  return switch (error.code) {
    'not_found' ||
    'auth_error' ||
    kGitHubInstallationSuspendedCode ||
    kAutomationTokenMissingCode => error,
    _ => null,
  };
}

extension _RepoAccessProbes on OpenPrPollingService {
  /// Hands every resolved repository's open pull requests to
  /// [_onOpenPrsRead]. A repository with no group answered with no open pull
  /// requests at all, which is a complete list too.
  Future<void> _reportOpenPrs(
    String workspaceId,
    List<Repo> resolved,
    List<OpenPrGroup> groups,
  ) async {
    final report = _onOpenPrsRead;
    if (report == null) {
      return;
    }
    final byRepoId = {for (final g in groups) g.repo.id: g};
    for (final repo in resolved) {
      final group = byRepoId[repo.id];
      try {
        await report(
          workspaceId,
          repo,
          group?.prs ?? const [],
          complete: !(group?.hasMore ?? false),
        );
      } on Object catch (e) {
        CcHostLog.warning(
          'open_pr_poll: open-PR follow-up failed for ${repo.fullName} in '
          '$workspaceId: $e',
        );
      }
    }
  }

  /// Whether the registry holds an issue on [repo] that stops automation.
  Future<bool> _isBlocked(String workspaceId, Repo repo) async {
    try {
      final issue = await _access.issueFor(
        workspaceId,
        forge: repo.forge,
        owner: repo.remoteOwner,
        name: repo.remoteName,
      );
      return issue?.state.blocksAutomation ?? false;
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: access record unreadable for ${repo.fullName}: $e',
      );
      return false;
    }
  }

  /// Drops every snapshot trace of repos no longer linked to the workspace.
  /// Returns whether anything was removed.
  bool _pruneUnlinked(_WorkspacePollState st, Set<String> linkedIds) {
    final snapshot = st.snapshot;
    if (snapshot == null) {
      return false;
    }
    bool keep(Object? raw) =>
        raw is! Map ||
        raw['repo_id'] is! String ||
        linkedIds.contains(raw['repo_id']);
    final repos = (snapshot['repos'] as List?) ?? const [];
    final terminal = (snapshot['terminal_prs'] as List?) ?? const [];
    final baselined = snapshot[OpenPrPollingService._baselinedKey] as List?;
    final keptRepos = repos.where(keep).toList();
    final keptTerminal = terminal.where(keep).toList();
    final keptBaselined = baselined?.where(linkedIds.contains).toList();
    if (keptRepos.length == repos.length &&
        keptTerminal.length == terminal.length &&
        (baselined == null || keptBaselined!.length == baselined.length)) {
      return false;
    }
    st.snapshot = {
      ...snapshot,
      'repos': keptRepos,
      'terminal_prs': keptTerminal,
      OpenPrPollingService._baselinedKey: ?keptBaselined,
    };
    return true;
  }

  /// Removes the open rows and baseline marks of [repoIds] (repos the server
  /// cannot reach). Their merged/closed history stays: it is what the space
  /// panels read, and it was true when it was recorded. Returns whether
  /// anything was removed.
  bool _dropRepoRows(_WorkspacePollState st, Set<String> repoIds) {
    final snapshot = st.snapshot;
    if (snapshot == null || repoIds.isEmpty) {
      return false;
    }
    final repos = (snapshot['repos'] as List?) ?? const [];
    final baselined = snapshot[OpenPrPollingService._baselinedKey] as List?;
    final keptRepos = [
      for (final raw in repos)
        if (raw is! Map || !repoIds.contains(raw['repo_id'])) raw,
    ];
    final keptBaselined = baselined
        ?.where((id) => !repoIds.contains(id))
        .toList();
    if (keptRepos.length == repos.length &&
        (baselined == null || keptBaselined!.length == baselined.length)) {
      return false;
    }
    st.snapshot = {
      ...snapshot,
      'repos': keptRepos,
      OpenPrPollingService._baselinedKey: ?keptBaselined,
    };
    return true;
  }

  /// Records a successful probe of [repo]: its failure counters reset and
  /// any registry issue on it clears. Returns true when an issue that
  /// blocked it was cleared.
  Future<bool> _noteRepoReachable(
    String workspaceId,
    _WorkspacePollState st,
    Repo repo,
  ) async {
    st.probesByRepoId.remove(repo.id);
    final wasBlocked = await _isBlocked(workspaceId, repo);
    try {
      final cleared = await _access.recordReachable(
        workspaceId,
        forge: repo.forge,
        owner: repo.remoteOwner,
        name: repo.remoteName,
      );
      if (cleared && wasBlocked) {
        CcHostLog.info('open_pr_poll: ${repo.fullName} is accessible again');
      }
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: could not clear the access record of '
        '${repo.fullName}: $e',
      );
    }
    return wasBlocked;
  }

  /// Records a failed probe of [repo]. Returns true when the failure blocks
  /// the repo (an access denial that held through the threshold, recorded in
  /// the registry with what the lane says about it).
  ///
  /// A transient failure that holds through the threshold is recorded as
  /// [RepoAccessState.transient] (shown, never blocking) unless the repo
  /// already carries a blocking state, which a timeout does not disprove.
  Future<bool> _noteProbeFailure(
    String workspaceId,
    _WorkspacePollState st,
    Repo repo,
    Object error,
  ) async {
    final probe = st.probesByRepoId.putIfAbsent(repo.id, _RepoProbeState.new);
    final wasBlocked = await _isBlocked(workspaceId, repo);
    final denial = _accessDenial(error);
    if (denial == null) {
      probe
        ..consecutiveTransient += 1
        ..consecutiveDenials = 0;
      if (!wasBlocked) {
        CcHostLog.warning(
          'open_pr_poll: probe failed for ${repo.fullName}: $error',
        );
      }
      if (!wasBlocked && probe.consecutiveTransient >= accessFailureThreshold) {
        await _record(workspaceId, repo, (
          state: RepoAccessState.transient,
          message:
              '${repo.forge.displayName} did not answer for '
              '${repo.fullName}; retrying.',
          installUrl: null,
        ));
      }
      return wasBlocked;
    }
    probe
      ..consecutiveDenials += 1
      ..consecutiveTransient = 0;
    // A suspended installation or a missing automation token is a known
    // standing state, not a flaky answer: block on the first one.
    final threshold =
        denial.code == kGitHubInstallationSuspendedCode ||
            denial.code == kAutomationTokenMissingCode
        ? 1
        : accessFailureThreshold;
    if (!wasBlocked && probe.consecutiveDenials < threshold) {
      // Below the threshold: still worth a log line. Once blocked, the
      // state is surfaced in the UI instead of the log.
      CcHostLog.warning(
        'open_pr_poll: probe failed for ${repo.fullName}: $error',
      );
      return false;
    }
    RepoAccessVerdict verdict;
    try {
      verdict = await _classify(workspaceId, repo, denial);
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: could not classify the denial of ${repo.fullName}: $e',
      );
      verdict = await _defaultVerdict(workspaceId, repo, denial);
    }
    await _record(workspaceId, repo, verdict);
    if (!verdict.state.blocksAutomation) {
      return false;
    }
    probe.lastRetryAt = _now();
    if (!wasBlocked) {
      CcHostLog.warning(
        'open_pr_poll: parking ${repo.fullName} — ${verdict.state.wire} '
        'after ${probe.consecutiveDenials} denied probe(s); retrying every '
        '${inaccessibleRetryInterval.inMinutes}m.',
      );
    }
    return true;
  }

  Future<void> _record(
    String workspaceId,
    Repo repo,
    RepoAccessVerdict verdict,
  ) async {
    try {
      await _access.record(
        workspaceId,
        forge: repo.forge,
        owner: repo.remoteOwner,
        name: repo.remoteName,
        repoId: repo.id,
        state: verdict.state,
        message: verdict.message,
        installUrl: verdict.installUrl,
      );
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: could not record the access state of '
        '${repo.fullName}: $e',
      );
    }
  }
}
