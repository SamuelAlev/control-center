part of 'open_pr_polling_service.dart';

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

/// Per-workspace poller state.
class _WorkspacePollState {
  /// Active `pr.watchOpenForWorkspace` subscriptions (fast cadence when > 0).
  int interest = 0;

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
}
