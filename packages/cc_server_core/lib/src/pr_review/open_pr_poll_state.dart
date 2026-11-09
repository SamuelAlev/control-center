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

/// One repo's access bookkeeping: consecutive access-denied probe failures
/// and the parked ("inaccessible") state they escalate into.
class _RepoAccessState {
  _RepoAccessState({required this.repoFullName});

  /// The repo's `owner/name` at the last observation, for the wire entry.
  String repoFullName;

  /// Consecutive access-denied probe failures. Reset by any successful probe.
  int consecutiveFailures = 0;

  /// Whether the repo is parked: probed on the slow retry cadence only and
  /// excluded from fetches, because its denial is deterministic until a human
  /// installs the app there or fixes the access.
  bool parked = false;

  /// The `NetworkException.code` that parked it (`not_found` /
  /// `auth_error` / `installation_suspended`).
  String reason = '';

  /// When the repo was parked.
  DateTime? since;

  /// Last slow-cadence retry, so parked repos are probed sparsely.
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

  /// Access bookkeeping per repo id. A repo is present here once a probe has
  /// been denied; it leaves the map the moment a probe succeeds again.
  final Map<String, _RepoAccessState> accessByRepoId = {};

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
