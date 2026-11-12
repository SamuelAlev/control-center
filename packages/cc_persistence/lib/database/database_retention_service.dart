import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/services/cache_kind_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/src/server_database.dart';
import 'package:drift/drift.dart';

/// Keeps every database file the server writes from growing without bound.
///
/// Workspace pass, per live workspace file, sequentially through
/// [CrossWorkspaceQueries.forEachWorkspace] (a read-only workspace is
/// skipped there): `activity_log`, `webhook_deliveries`, `cron_executions`,
/// `user_activity`, `write_ledger`, subagent `transcripts`, the declared
/// [CacheKindRegistry] kinds in `caches`, finished `index_code` pipeline runs
/// (with their `workspace_routes` rows) and finished `agent_run_logs`.
///
/// Global pass: `rss_articles`, terminal fleet `jobs` and their
/// `placement_log`. `server_audit` is the owner's accountability trail and is
/// never pruned here.
///
/// After its deletes each file hands its freed pages back
/// ([ConvergedDatabase.reclaimFreePages]), refreshes planner statistics and
/// truncates its write-ahead log. Pre-upgrade copies past
/// [upgradeSnapshotRetention] are removed, the newest always kept. Separately,
/// [statisticsInterval] refreshes planner statistics on the files already
/// open, so a long-running server does not plan with week-old row counts.
class DatabaseRetentionService {
  /// Creates a retention service over [workspaces] and the global database.
  ///
  /// The data directory is where the `pre_upgrade/` directories live; without it (an
  /// in-memory server) no copies are pruned. [interval] is the sweep cadence;
  /// [now] is injectable for tests.
  DatabaseRetentionService({
    required WorkspaceDatabaseManager workspaces,
    required this._global,
    this._dataDir,
    this.activityLogRetention = const Duration(days: 90),
    this.webhookRetention = const Duration(days: 30),
    this.cronRetention = const Duration(days: 30),
    this.userActivityRetention = const Duration(days: 180),
    this.writeLedgerRetention = const Duration(days: 7),
    this.runTranscriptRetention = const Duration(days: 30),
    this.codeIndexRunRetention = const Duration(days: 7),
    this.codeIndexRunsKept = 50,
    this.agentRunLogRetention = const Duration(days: 180),
    this.rssArticleRetention = const Duration(days: 90),
    this.rssArticlesKeptPerFeed = 200,
    this.fleetJobRetention = const Duration(days: 30),
    this.upgradeSnapshotRetention = const Duration(days: 30),
    this.interval = const Duration(hours: 24),
    this.statisticsInterval = const Duration(hours: 1),
    DateTime Function()? now,
    this._onError,
  }) : _workspaces = workspaces,
       _cross = CrossWorkspaceQueries(workspaces),
       _now = now ?? DateTime.now;

  final WorkspaceDatabaseManager _workspaces;
  final CrossWorkspaceQueries _cross;
  final GlobalDatabase _global;
  final String? _dataDir;

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

  /// How long a finished run's activity transcript is kept. A transcript
  /// holds the run's whole tool/reasoning timeline and runs orders of
  /// magnitude fatter per row than the run-log row it hangs off, so it goes
  /// long before the run does. Unfinished recordings are always spared, and
  /// so is a space turn's transcript, which belongs to its message.
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

  /// How long a FINISHED `agent_run_logs` row is kept.
  ///
  /// Long, because a run row is the unit of cost and usage: the usage
  /// dashboard's widest window and every budget period sit well inside half
  /// a year, so pruning past it never changes a number anyone reads. A run
  /// something still points at is spared at any age: one an approval links,
  /// a ticket's latest run (the ticket shows it), a run of a pipeline run
  /// that still exists, an eval recording's source, the parent or retry
  /// origin of a kept run, and a goal's or agent's current run.
  final Duration agentRunLogRetention;

  /// How long an unsaved `rss_articles` row is kept, measured from when it
  /// was published (or ingested, when the feed gave no date).
  ///
  /// The newsfeed is a reading list, not an archive: three months covers a
  /// holiday's backlog. [rssArticlesKeptPerFeed] keeps a slow feed from
  /// emptying, whichever of the two keeps more. Saved articles are the
  /// reader's own archive and are never pruned.
  final Duration rssArticleRetention;

  /// How many of each feed's newest articles survive [rssArticleRetention].
  ///
  /// Matches the newsfeed's page size, so a feed that publishes monthly
  /// still fills the list, and stays above what a feed document usually
  /// lists, so a pruned article is not ingested again as new.
  final int rssArticlesKeptPerFeed;

  /// How long a TERMINAL fleet `jobs` row (done, failed, cancelled) and the
  /// `placement_log` decisions about it are kept.
  ///
  /// A month answers "why did that run there" for any job someone still
  /// remembers; the worker that ran it is often gone by then. A job that is
  /// queued, leased, running or reaped is never pruned: it is still
  /// someone's work.
  final Duration fleetJobRetention;

  /// How long a `pre_upgrade/` copy is kept. The newest copy of each file
  /// survives at any age: it is the only way back from an upgrade that went
  /// wrong, however long ago that upgrade was.
  final Duration upgradeSnapshotRetention;

  /// Cadence of the retention sweep.
  final Duration interval;

  /// Cadence of the planner-statistics refresh over the files already open.
  final Duration statisticsInterval;

  final DateTime Function() _now;
  final void Function(String message)? _onError;
  Timer? _timer;
  Timer? _statisticsTimer;

  static const _terminalJobStatuses = "('done', 'failed', 'cancelled')";

  /// Starts the periodic sweep (with an immediate first run on the next tick of
  /// the event loop, so construction stays synchronous) and the statistics
  /// refresh.
  void start() {
    stop();
    unawaited(Future<void>.microtask(runOnce));
    _timer = Timer.periodic(interval, (_) => unawaited(runOnce()));
    _statisticsTimer = Timer.periodic(
      statisticsInterval,
      (_) => unawaited(refreshStatistics()),
    );
  }

  /// Stops the periodic sweep and the statistics refresh.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _statisticsTimer?.cancel();
    _statisticsTimer = null;
  }

  /// Runs one retention pass over every workspace and the global database.
  /// Returns the total rows deleted. Never throws — each table is pruned
  /// independently and failures are reported via `onError`.
  Future<int> runOnce() async {
    final now = _now();
    var total = 0;
    await _cross.forEachWorkspace(
      (db) async {
        total += await _pruneWorkspace(db, now);
        _pruneUpgradeSnapshots(
          _dataDir == null
              ? null
              : workspaceUpgradeSnapshotDir(_dataDir, db.workspaceId),
          now,
        );
      },
      onError: (workspaceId, error) => _onError?.call(
        'retention sweep of workspace $workspaceId failed: $error',
      ),
      backgroundWriter: 'retention',
    );
    total += await _pruneGlobal(now);
    _pruneUpgradeSnapshots(
      _dataDir == null ? null : globalUpgradeSnapshotDir(_dataDir),
      now,
    );
    return total;
  }

  /// Refreshes planner statistics on the global database and on every
  /// workspace database already open. A closed file is not opened for this:
  /// it gets the same refresh when it next closes, and opening hundreds of
  /// idle files hourly would cost more than stale statistics do.
  Future<void> refreshStatistics() async {
    await _prune('optimize (global)', () async {
      await _global.optimize();
      return 0;
    });
    // CROSS-WORKSPACE BY DESIGN: a per-file statistics refresh over the
    // files this process already holds open, which is the point: the helper
    // would open every live workspace, and this must open none.
    for (final id in _workspaces.openIds.toList()) {
      // CROSS-WORKSPACE BY DESIGN: the same open set, re-checked because a
      // file can close (idle) between the snapshot and its turn.
      if (!_workspaces.openIds.contains(id) ||
          _workspaces.integrityFailure(id) != null) {
        continue;
      }
      // Transient: a file a fan-out opened stays the fan-out's to close,
      // where `of` would claim it and keep it open.
      await _prune('optimize ($id)', () async {
        await _workspaces.useTransiently(id, (db) => db.optimize());
        return 0;
      });
    }
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
    // Only declared kinds, each by its own window: a kind nobody declared
    // may be state someone wrote into the cache table, and a sweep that
    // guessed would delete it.
    for (final kind in CacheKindRegistry.declared) {
      total += await _prune(
        'caches (${kind.name})',
        () => db.cacheDao.deleteKindOlderThan(
          kind.name,
          now.subtract(kind.retention),
        ),
      );
    }
    total += await _prune(
      'transcripts (runs)',
      () => db.runTranscriptDao.pruneCompletedBefore(
        now.subtract(runTranscriptRetention),
      ),
    );
    total += await _prune('pipeline_runs (index_code)', () async {
      final deleted = await db.pipelineDao.deleteFinishedRunsForTemplate(
        templateId: IndexCodeTemplate.id,
        cutoff: now.subtract(codeIndexRunRetention),
        keepAtLeast: codeIndexRunsKept,
      );
      // A run's deep-link route outliving the run resolves to a not-found
      // the pre-auth path cannot tell from a forged id.
      for (final id in deleted) {
        await _global.workspaceRouteDao.remove(
          WorkspaceRouteKind.pipelineRun,
          id,
        );
      }
      return deleted.length;
    });
    total += await _prune(
      'agent_run_logs',
      () => _pruneRunLogs(db, now.subtract(agentRunLogRetention)),
    );
    await _compact(db, 'workspace ${db.workspaceId}');
    return total;
  }

  /// Deletes finished runs older than [cutoff] that nothing points at; see
  /// [agentRunLogRetention] for what is spared. Transcripts and pending PR
  /// replies go with their run (foreign-key cascade). A run still naming a
  /// pipeline run is one whose pipeline run exists: deleting that clears the
  /// key.
  Future<int> _pruneRunLogs(WorkspaceDatabase db, DateTime cutoff) =>
      db.customUpdate(
        '''
        DELETE FROM agent_run_logs
        WHERE status IN ('completed', 'error')
          AND COALESCE(completed_at, started_at) < ?1
          AND id NOT IN (
            SELECT linked_entity_id FROM approvals
            WHERE linked_entity_id IS NOT NULL)
          AND id NOT IN (SELECT run_log_id FROM session_recordings)
          AND id NOT IN (
            SELECT active_run_id FROM agent_goal_runs
            WHERE active_run_id IS NOT NULL)
          AND id NOT IN (
            SELECT current_run_id FROM agent_runtime_state
            WHERE current_run_id IS NOT NULL)
          AND id NOT IN (
            SELECT parent_run_id FROM agent_run_logs
            WHERE parent_run_id IS NOT NULL)
          AND id NOT IN (
            SELECT retry_of_run_id FROM agent_run_logs
            WHERE retry_of_run_id IS NOT NULL)
          AND pipeline_run_id IS NULL
          AND (ticket_id IS NULL OR id IS NOT (
            SELECT latest.id FROM agent_run_logs latest
            WHERE latest.ticket_id = agent_run_logs.ticket_id
            ORDER BY latest.started_at DESC, latest.id DESC
            LIMIT 1))
        ''',
        variables: [Variable<DateTime>(cutoff)],
        updates: {db.agentRunLogsTable},
        updateKind: UpdateKind.delete,
      );

  /// The `rss_articles` sweep: unsaved articles past the cutoff (`?1`),
  /// except each feed's newest `?2`. The ranking reads
  /// `idx_rss_articles_feed_published` in order rather than sorting the
  /// table.
  static const String rssArticlesSweepSql = '''
        DELETE FROM rss_articles
        WHERE saved = 0
          AND COALESCE(published_at, created_at) < ?1
          AND id NOT IN (
            SELECT id FROM (
              SELECT id, ROW_NUMBER() OVER (
                PARTITION BY feed_id
                ORDER BY COALESCE(published_at, created_at) DESC, id DESC
              ) AS position
              FROM rss_articles)
            WHERE position <= ?2)
        ''';

  /// Prunes the server-global tables, then compacts `global.db`.
  Future<int> _pruneGlobal(DateTime now) async {
    var total = 0;
    total += await _prune(
      'rss_articles',
      () => _global.customUpdate(
        rssArticlesSweepSql,
        variables: [
          Variable<DateTime>(now.subtract(rssArticleRetention)),
          Variable<int>(rssArticlesKeptPerFeed),
        ],
        updates: {_global.rssArticlesTable},
        updateKind: UpdateKind.delete,
      ),
    );
    final jobCutoff = now.subtract(fleetJobRetention);
    total += await _prune(
      'jobs',
      () => _global.customUpdate(
        'DELETE FROM jobs WHERE status IN $_terminalJobStatuses '
        'AND COALESCE(finished_at, created_at) < ?1',
        variables: [Variable<DateTime>(jobCutoff)],
        updates: {_global.jobsTable},
        updateKind: UpdateKind.delete,
      ),
    );
    // After the jobs: a decision about a job that is gone is history of
    // nothing, and one about a live job explains work still in flight.
    total += await _prune(
      'placement_log',
      () => _global.customUpdate(
        'DELETE FROM placement_log WHERE created_at < ?1 '
        'AND job_id NOT IN (SELECT id FROM jobs '
        'WHERE status NOT IN $_terminalJobStatuses)',
        variables: [Variable<DateTime>(jobCutoff)],
        updates: {_global.placementLogTable},
        updateKind: UpdateKind.delete,
      ),
    );
    await _compact(_global, 'global');
    return total;
  }

  /// Hands the pages the deletes freed back to the file system, then
  /// refreshes planner statistics and truncates the write-ahead log.
  ///
  /// `PRAGMA optimize` only refreshes statistics; without the incremental
  /// vacuum a pruned file keeps its size forever and only reuses the pages
  /// for later inserts.
  Future<void> _compact(ConvergedDatabase db, String label) =>
      _prune('compact ($label)', () async {
        await db.reclaimFreePages();
        await db.optimize();
        await db.checkpoint();
        return 0;
      });

  /// Removes `.db` copies in [directory] older than
  /// [upgradeSnapshotRetention], always keeping the newest.
  void _pruneUpgradeSnapshots(String? directory, DateTime now) {
    if (directory == null) {
      return;
    }
    try {
      final dir = Directory(directory);
      if (!dir.existsSync()) {
        return;
      }
      final copies = [
        for (final entry in dir.listSync())
          if (entry is File && entry.path.endsWith('.db'))
            (file: entry, modified: entry.statSync().modified),
      ]..sort((a, b) => b.modified.compareTo(a.modified));
      final cutoff = now.subtract(upgradeSnapshotRetention);
      for (final copy in copies.skip(1)) {
        if (copy.modified.isBefore(cutoff)) {
          copy.file.deleteSync();
        }
      }
    } on FileSystemException catch (e) {
      _onError?.call('retention prune of $directory failed: $e');
    }
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
