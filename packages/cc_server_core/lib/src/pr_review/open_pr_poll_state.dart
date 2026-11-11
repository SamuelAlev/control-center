part of 'open_pr_polling_service.dart';

/// The workspace members' own logins on [forge], keyed by Control Center user
/// id. An empty login means that member has not connected the forge.
typedef MemberForgeLogins =
    Future<Map<String, String>> Function(String workspaceId, ForgeHost forge);

/// State that lives for ONE diff or checks pass, never longer.
///
/// Sweeps of different workspaces overlap (only one runs per workspace), so
/// anything held on the service would let one sweep reset another's budget
/// halfway through, or answer it with another workspace's member logins.
class _SweepContext {
  /// Targeted mergeability confirmations spent this pass.
  int mergeConfirms = 0;

  /// Targeted approver lookups spent this pass.
  int approverLookups = 0;

  /// Lower-cased login → member user id, per forge, read once per pass.
  final Map<ForgeHost, Map<String, String>> _membersByLogin = {};

  /// The member whose [forge] login is [author] (case-insensitively), or null
  /// when no member authored it.
  Future<String?> memberFor(
    ForgeHost forge,
    String author,
    Future<Map<String, String>> Function() load,
  ) async {
    final login = author.trim().toLowerCase();
    if (login.isEmpty) {
      return null;
    }
    var byLogin = _membersByLogin[forge];
    if (byLogin == null) {
      byLogin = {};
      try {
        for (final e in (await load()).entries) {
          final memberLogin = e.value.trim().toLowerCase();
          if (memberLogin.isNotEmpty) {
            byLogin[memberLogin] = e.key;
          }
        }
      } on Object catch (e) {
        CcHostLog.warning(
          'open_pr_poll: member ${forge.displayName} logins unavailable: $e',
        );
      }
      _membersByLogin[forge] = byLogin;
    }
    return byLogin[login];
  }
}

/// One repo's probe-failure bookkeeping. The published record of whether a
/// repo is reachable is the [RepoAccessRegistry]; this only counts the
/// consecutive failures that escalate into a registry entry, and paces the
/// slow re-probes of a repo the registry blocks.
class _RepoProbeState {
  /// Consecutive access-denied probe failures. Reset by any successful probe.
  int consecutiveDenials = 0;

  /// Consecutive transient probe failures (timeouts, 5xx, rate limits).
  int consecutiveTransient = 0;

  /// Last slow-cadence retry of a blocked repo, so it is probed sparsely.
  DateTime? lastRetryAt;

  bool isRetryDue(DateTime now, Duration interval) =>
      lastRetryAt == null || now.difference(lastRetryAt!) >= interval;
}

/// A branch whose history lookup keeps failing: no new attempt before
/// [retryAt].
class _BranchHistoryBackoff {
  _BranchHistoryBackoff({required this.failures, required this.retryAt});

  /// Consecutive failed lookups. Reset by a success (the entry is removed).
  final int failures;

  /// The earliest instant another lookup may go out.
  final DateTime retryAt;
}

/// Per-workspace poller state.
class _WorkspacePollState {
  /// Active `pr.watchOpenForWorkspace` subscriptions (fast cadence when > 0).
  int interest = 0;

  /// Fast-cadence ticks this workspace has been swept on; every
  /// `checksEvery`-th one includes the checks pass.
  int watchedTicks = 0;

  /// Last conditional-request ETag per repo id.
  final Map<String, String> etagByRepoId = {};

  /// Probe-failure bookkeeping per repo id. A repo is present here once a
  /// probe has failed or it has been re-probed while blocked.
  final Map<String, _RepoProbeState> probesByRepoId = {};

  /// The current snapshot in wire form (`{'authenticated', 'repos'}`), or null
  /// before the first successful sweep.
  Map<String, dynamic>? snapshot;

  /// Whether the persisted snapshot was already loaded from the cache table.
  bool snapshotLoaded = false;

  /// The sweep currently running for this workspace, or null when idle.
  /// Non-forced callers coalesce into it; forced callers chain behind it.
  Future<void>? inflight;

  /// A forced sweep already queued behind [inflight]. Concurrent forced
  /// refreshes share this one future instead of piling up sweeps.
  Future<void>? queuedForced;

  /// When the last explicit refresh was accepted, and its sweep. Refreshes
  /// inside `forcedRefreshMinGap` of it join that sweep instead of starting
  /// another.
  DateTime? lastForcedAt;
  Future<void>? lastForced;

  /// Whether a periodic tick has already queued this workspace's sweep (it
  /// waits for one of the tick's concurrency slots).
  bool tickQueued = false;

  /// Broadcast of sweep in-flight transitions (`true` on start, `false` on
  /// completion). `watchOpenForWorkspace` merges these into its stream so a
  /// client's refresh affordance can reflect the sweep that a subscribe (or a
  /// background tick) kicked — otherwise the slow GitHub fetch is invisible
  /// behind the instantly-pushed persisted snapshot.
  // Closed in OpenPrPollingService.dispose.
  // ignore: close_sinks
  final StreamController<bool> sweepingChanges =
      StreamController<bool>.broadcast();

  /// Sweeps tick the space branch feed even when the open-list ETag is
  /// unchanged: a PR can be opened and merged between two open-list probes.
  // Closed in OpenPrPollingService.dispose.
  // ignore: close_sinks
  final StreamController<void> historyRefresh =
      StreamController<void>.broadcast();

  DateTime? lastSweepAt;

  /// Branch history lookups that failed, by `[repo id, full name, branch]`
  /// key. Every sweep wakes every space feed, so without this a failure is
  /// re-asked once per branch per subscriber per sweep. A forced refresh
  /// clears it.
  final Map<String, _BranchHistoryBackoff> historyBackoff = {};
}
