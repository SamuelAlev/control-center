import 'dart:async';

import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Periodically prunes append-only audit/log tables so the database does not
/// grow without bound. These tables are pure history — old rows have no
/// functional purpose beyond a retention window:
///  * `activity_log` — the audit feed (UI only ever shows recent entries)
///  * `webhook_deliveries` — inbound webhook receipts (idempotency + debugging)
///  * `cron_executions` — the cron-fire idempotency ledger
///  * `user_activity` — the per-user accountability trail
///  * `run_transcripts` — finished runs' activity timelines
///  * `pipeline_runs`, for `index_code` ONLY — the code-graph watcher publishes
///    one run per background reindex, which is the only pipeline that fires by
///    itself often enough to need a window (every other template's history is
///    the operator's and is never pruned)
///
/// All of these tables are workspace-scoped, so a sweep visits every workspace's
/// database in turn — including workspaces nobody has opened this session and
/// soft-deleted ones, whose files are still on disk and would otherwise never be
/// pruned. The visits are sequential (via
/// [CrossWorkspaceQueries.forEachWorkspace]) so a sweep does not fire ten write
/// transactions at once while the server is trying to serve.
///
/// Runs once shortly after start and then on a daily tick. Best-effort: a prune
/// failure is logged (via the `onError` callback) and retried on the next tick,
/// never throwing into the caller. Retention windows are generous by default so
/// legitimate recent history is always kept.
class DatabaseRetentionService {
  /// Creates a retention service over every workspace database in [workspaces].
  ///
  /// [activityLogRetention]/[webhookRetention]/[cronRetention] set how far back
  /// each table is kept. [interval] is the sweep cadence; [now] is injectable
  /// for tests.
  DatabaseRetentionService({
    required WorkspaceDatabaseManager workspaces,
    this.activityLogRetention = const Duration(days: 90),
    this.webhookRetention = const Duration(days: 30),
    this.cronRetention = const Duration(days: 30),
    this.userActivityRetention = const Duration(days: 180),
    this.writeLedgerRetention = const Duration(days: 7),
    this.cacheRetention = const Duration(days: 21),
    this.runTranscriptRetention = const Duration(days: 30),
    this.codeIndexRunRetention = const Duration(days: 7),
    this.codeIndexRunsKept = 50,
    this.interval = const Duration(hours: 24),
    DateTime Function()? now,
    void Function(String message)? onError,
  }) : _cross = CrossWorkspaceQueries(workspaces),
       _now = now ?? DateTime.now,
       _onError = onError;

  final CrossWorkspaceQueries _cross;

  /// How long `activity_log` rows are kept.
  final Duration activityLogRetention;

  /// How long `webhook_deliveries` rows are kept.
  final Duration webhookRetention;

  /// How long `cron_executions` rows are kept.
  final Duration cronRetention;

  /// How long `user_activity` rows are kept. Longer than the agent feed:
  /// this is the accountability trail for human actions.
  final Duration userActivityRetention;

  /// How long `write_ledger` idempotency rows are kept (PRD 19 §3). Short: the
  /// ledger only needs to outlive plausible retries (reconnect, offline flush),
  /// not serve as a permanent audit — that is `user_activity`.
  final Duration writeLedgerRetention;

  /// How long untouched `caches` (SWR) rows are kept. These are pure staleness
  /// buffers — a stale-but-old entry is refetched anyway, while PR diff/file
  /// blobs left behind by closed PRs can run to megabytes per row.
  final Duration cacheRetention;

  /// How long a finished run's activity transcript is kept. Unlike the run-log
  /// row it hangs off — which is never pruned — a transcript holds the run's
  /// whole tool/reasoning timeline and runs orders of magnitude fatter per row,
  /// so it needs a window of its own. Unfinished recordings are always spared.
  final Duration runTranscriptRetention;

  /// How long a FINISHED `index_code` run row is kept.
  ///
  /// Short, because these are machine-generated: the code-graph watcher
  /// publishes a run per background reindex, so an active day writes hundreds
  /// while the runs list streams the table in full. A week is enough to answer
  /// "what has been indexing and how long did it take"; older than that, the
  /// current checkpoint is the answer.
  final Duration codeIndexRunRetention;

  /// How many recent `index_code` runs survive regardless of age, so a
  /// workspace nobody has touched in a month still shows its last indexes
  /// instead of an empty history.
  final int codeIndexRunsKept;

  /// Cadence of the retention sweep.
  final Duration interval;

  final DateTime Function() _now;
  final void Function(String message)? _onError;
  Timer? _timer;

  /// Starts the periodic sweep (with an immediate first run on the next tick of
  /// the event loop, so construction stays synchronous).
  void start() {
    _timer?.cancel();
    unawaited(Future<void>.microtask(runOnce));
    _timer = Timer.periodic(interval, (_) => unawaited(runOnce()));
  }

  /// Stops the periodic sweep.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Runs one retention pass over every managed table in every workspace.
  /// Returns the total rows deleted. Never throws — each table is pruned
  /// independently and failures are reported via `onError`.
  Future<int> runOnce() async {
    final now = _now();
    var total = 0;
    await _cross.forEachWorkspace(
      (db) async {
        total += await _pruneWorkspace(db, now);
      },
      onError: (workspaceId, error) => _onError?.call(
        'retention sweep of workspace $workspaceId failed: $error',
      ),
    );
    return total;
  }

  /// Prunes every managed table in one workspace's database.
  Future<int> _pruneWorkspace(WorkspaceDatabase db, DateTime now) async {
    var total = 0;
    total += await _prune(
      'activity_log',
      () =>
          db.activityLogDao.deleteOlderThan(now.subtract(activityLogRetention)),
    );
    total += await _prune(
      'webhook_deliveries',
      () =>
          db.webhookDeliveryDao.deleteOlderThan(now.subtract(webhookRetention)),
    );
    total += await _prune(
      'cron_executions',
      () => db.cronExecutionDao.deleteOlderThan(now.subtract(cronRetention)),
    );
    total += await _prune(
      'user_activity',
      () => db.userActivityDao.deleteOlderThan(
        now.subtract(userActivityRetention),
      ),
    );
    total += await _prune(
      'write_ledger',
      () =>
          db.writeLedgerDao.deleteOlderThan(now.subtract(writeLedgerRetention)),
    );
    total += await _prune(
      'caches',
      () => db.cacheDao.deleteOlderThan(now.subtract(cacheRetention)),
    );
    total += await _prune(
      'run_transcripts',
      () => db.runTranscriptDao.pruneCompletedBefore(
        now.subtract(runTranscriptRetention),
      ),
    );
    total += await _prune(
      'pipeline_runs (index_code)',
      () => db.pipelineDao.deleteFinishedRunsForTemplate(
        templateId: IndexCodeTemplate.id,
        cutoff: now.subtract(codeIndexRunRetention),
        keepAtLeast: codeIndexRunsKept,
      ),
    );
    // Reclaim free pages and refresh query-planner stats while we are already
    // touching this file. Cheap and it is the only moment in normal operation
    // when a workspace database is guaranteed to be visited.
    await _prune('optimize', () async {
      await db.customStatement('PRAGMA optimize');
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      return 0;
    });
    return total;
  }

  Future<int> _prune(String table, Future<int> Function() prune) async {
    try {
      return await prune();
    } catch (e) {
      _onError?.call('retention prune of $table failed: $e');
      return 0;
    }
  }
}
