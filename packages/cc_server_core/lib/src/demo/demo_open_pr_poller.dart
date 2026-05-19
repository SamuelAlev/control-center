import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';

/// A fetch port that answers nothing, because a demo container dials nothing.
///
/// It is never actually consulted — [DemoOpenPrPoller] never sweeps — but a
/// non-null port is required to construct the service, and one that returns
/// empty rather than throwing keeps a stray call harmless.
class _OfflineOpenPrFetchPort implements OpenPrFetchPort {
  const _OfflineOpenPrFetchPort();

  @override
  Future<({bool changed, String? etag})> probeRepo(Repo repo, String? etag) async =>
      (changed: false, etag: etag);

  @override
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos) async =>
      (groups: const <OpenPrGroup>[], resolvedRepoIds: const <String>{});

  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos,
  ) async => const {};

  @override
  Future<bool?> wasMerged(Repo repo, int prNumber) async => null;

  @override
  Future<PrMergeableState> mergeState(Repo repo, int prNumber) async =>
      PrMergeableState.unknown;

  @override
  Future<String?> latestApprover(Repo repo, int prNumber) async => null;

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  ) async => null;
}

/// The demo's open-PR poller: a real [OpenPrPollingService] that never polls.
///
/// `pr.watchOpenForWorkspace` is a WatchQuery, and with a NULL poller it
/// short-circuits to `{'authenticated': false, 'repos': []}` **before it ever
/// reads the cache** — so seeding the snapshot row alone would show a demo
/// visitor an empty, signed-out PR list. Supplying a poller makes the watch
/// follow `caches(kind: openPrList, key: v1)`, which is exactly the row the
/// seeder writes.
///
/// Both sweep entry points are neutered:
///  * [start] never arms the periodic timer, so nothing sweeps on a schedule;
///  * [pollSoon] is a no-op, which matters because `watchOpenForWorkspace`
///    fires it on every subscribe — the inherited implementation would try a
///    real sweep and overwrite the seeded snapshot with an empty one.
class DemoOpenPrPoller extends OpenPrPollingService {
  /// Creates the poller over the demo's databases.
  DemoOpenPrPoller({
    required super.workspaceRepository,
    required super.workspaceDbs,
    required super.changeSignals,
    required super.prToWire,
    super.eventBus,
  }) : super(fetchPort: const _OfflineOpenPrFetchPort());

  @override
  void start() {
    // Deliberately empty: no sweep loop on a demo host.
  }

  @override
  Future<void> pollSoon(String workspaceId) async {
    // Deliberately empty — see the class doc. A sweep here would replace the
    // seeded snapshot with an empty one the moment anyone opened the PR list.
  }
}

/// Type alias kept for readability at the wiring site.
typedef DemoWorkspaceDbs = WorkspaceDatabaseManager;

/// Type alias kept for readability at the wiring site.
typedef DemoPrChangeSignals = PrChangeSignals;
