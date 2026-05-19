import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/fleet_tables.dart';
import 'package:drift/drift.dart';

part 'fleet_dao.g.dart';

/// Data access for the fleet (PRD 20): workers, jobs, and placement decisions.
///
/// **Workers are CROSS-WORKSPACE BY DESIGN** — a worker serves every workspace,
/// so worker reads are intentionally unscoped. Jobs and placement-log rows are
/// workspace-scoped and every read filters by `workspaceId` (isolation
/// invariant). The scheduler's lease/reap queries span workspaces by design
/// (they operate on the fleet, then fan out per job); those carry the
/// `CROSS-WORKSPACE BY DESIGN` note on the method.
@DriftAccessor(tables: [WorkersTable, JobsTable, PlacementLogTable])
class FleetDao extends DatabaseAccessor<GlobalDatabase> with _$FleetDaoMixin {
  /// Creates a [FleetDao].
  FleetDao(super.db);

  // ── Workers (CROSS-WORKSPACE BY DESIGN — workers serve all workspaces) ──

  /// Inserts or updates a worker (deterministic id → PK upsert).
  Future<void> upsertWorker(WorkersTableCompanion entry) =>
      into(workersTable).insertOnConflictUpdate(entry);

  /// All workers (fleet panel). CROSS-WORKSPACE BY DESIGN — workers are global.
  Future<List<WorkersTableData>> allWorkers() =>
      (select(workersTable)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  /// Live worker list. CROSS-WORKSPACE BY DESIGN — workers are global.
  Stream<List<WorkersTableData>> watchWorkers() => (select(
    workersTable,
  )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// One worker by id, or null.
  Future<WorkersTableData?> workerById(String id) =>
      (select(workersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Workers eligible to receive leases (online, not draining/revoked).
  /// CROSS-WORKSPACE BY DESIGN — the scheduler matches across the whole fleet.
  Future<List<WorkersTableData>> eligibleWorkers() =>
      (select(workersTable)..where((t) => t.status.equals('online'))).get();

  /// Records a heartbeat at server time [now] and marks the worker online
  /// (unless draining/revoked, which the caller decides before calling).
  Future<void> recordHeartbeat(String workerId, DateTime now) =>
      (update(workersTable)..where((t) => t.id.equals(workerId))).write(
        WorkersTableCompanion(lastHeartbeatAt: Value(now)),
      );

  /// Sets a worker's status (drain/offline/revoke/incompatible).
  Future<void> setWorkerStatus(
    String workerId,
    String status, {
    DateTime? drainedAt,
    DateTime? revokedAt,
    String? lastError,
  }) => (update(workersTable)..where((t) => t.id.equals(workerId))).write(
    WorkersTableCompanion(
      status: Value(status),
      drainedAt: drainedAt == null ? const Value.absent() : Value(drainedAt),
      revokedAt: revokedAt == null ? const Value.absent() : Value(revokedAt),
      lastError: lastError == null ? const Value.absent() : Value(lastError),
    ),
  );

  /// Removes a worker row entirely (operator "remove" control).
  Future<void> deleteWorker(String workerId) =>
      (delete(workersTable)..where((t) => t.id.equals(workerId))).go();

  // ── Jobs (workspace-scoped) ──

  /// Inserts or updates a job (deterministic id → PK upsert).
  Future<void> upsertJob(JobsTableCompanion entry) =>
      into(jobsTable).insertOnConflictUpdate(entry);

  /// One job by id within [workspaceId], or null.
  Future<JobsTableData?> jobById(String workspaceId, String id) =>
      (select(jobsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// One job by id, workspace-agnostic. CROSS-WORKSPACE BY DESIGN — used only
  /// by the scheduler/reaper which then re-scopes; do not use for reads that
  /// return data to a workspace client.
  Future<JobsTableData?> jobByIdGlobal(String id) =>
      (select(jobsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Jobs in [workspaceId] with the given [status], newest first.
  Future<List<JobsTableData>> jobsByStatus(String workspaceId, String status) =>
      (select(jobsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.status.equals(status),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Live jobs for [workspaceId] (all statuses), newest first.
  Stream<List<JobsTableData>> watchJobs(String workspaceId) =>
      (select(jobsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Queued jobs across all workspaces, priority then FIFO. CROSS-WORKSPACE BY
  /// DESIGN — the scheduler picks the next placement across the whole fleet's
  /// queue; each result is re-scoped to its own `workspaceId` on lease.
  Future<List<JobsTableData>> queuedJobsGlobal() =>
      (select(jobsTable)
            ..where((t) => t.status.equals('queued'))
            ..orderBy([
              (t) => OrderingTerm.desc(t.priority),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .get();

  /// Jobs currently leased whose lease has expired at [now].
  /// CROSS-WORKSPACE BY DESIGN — the reaper scans the whole fleet then reaps
  /// per job.
  Future<List<JobsTableData>> expiredLeasedJobs(DateTime now) =>
      (select(jobsTable)..where(
            (t) =>
                (t.status.equals('leased') | t.status.equals('running')) &
                t.leaseExpiresAt.isSmallerThanValue(now),
          ))
          .get();

  /// Jobs leased to / running on [workerId] (used when a worker is revoked).
  /// CROSS-WORKSPACE BY DESIGN — a worker spans workspaces.
  Future<List<JobsTableData>> activeJobsForWorker(String workerId) =>
      (select(jobsTable)..where(
            (t) =>
                t.workerId.equals(workerId) &
                (t.status.equals('leased') | t.status.equals('running')),
          ))
          .get();

  /// Atomically leases [jobId] to [workerId] with expiry [leaseExpiresAt],
  /// only if the job is still queued (guards against double-lease races).
  /// Returns true when the lease was taken. Workspace-agnostic write keyed by
  /// the unique job id; the scheduler already validated placement.
  Future<bool> tryLeaseJob(
    String jobId,
    String workerId,
    DateTime leaseExpiresAt,
    DateTime now,
  ) async {
    final updated =
        await (update(
          jobsTable,
        )..where((t) => t.id.equals(jobId) & t.status.equals('queued'))).write(
          JobsTableCompanion(
            status: const Value('leased'),
            workerId: Value(workerId),
            leaseExpiresAt: Value(leaseExpiresAt),
            leasedAt: Value(now),
            attempts: const Value.absent(),
          ),
        );
    return updated > 0;
  }

  /// Renews the lease on a running/leased job (cheap, frequent — see spec:
  /// short TTLs + cheap renewal). No-op if the job is no longer active.
  Future<void> renewLease(
    String jobId,
    DateTime leaseExpiresAt, {
    int? lastAckedSeq,
  }) =>
      (update(jobsTable)..where(
            (t) =>
                t.id.equals(jobId) &
                (t.status.equals('leased') | t.status.equals('running')),
          ))
          .write(
            JobsTableCompanion(
              leaseExpiresAt: Value(leaseExpiresAt),
              lastAckedSeq: lastAckedSeq == null
                  ? const Value.absent()
                  : Value(lastAckedSeq),
            ),
          );

  /// Marks a job running (worker reported start).
  Future<void> markJobRunning(String jobId, DateTime now) =>
      (update(jobsTable)..where((t) => t.id.equals(jobId))).write(
        JobsTableCompanion(
          status: const Value('running'),
          startedAt: Value(now),
        ),
      );

  /// Marks a job terminal (`done`/`failed`/`cancelled`).
  Future<void> markJobTerminal(
    String jobId,
    String status,
    DateTime now, {
    String? resultJson,
    String? error,
    int? costCents,
  }) => (update(jobsTable)..where((t) => t.id.equals(jobId))).write(
    JobsTableCompanion(
      status: Value(status),
      finishedAt: Value(now),
      workerId: const Value.absent(),
      leaseExpiresAt: const Value(null),
      resultJson: resultJson == null ? const Value.absent() : Value(resultJson),
      error: error == null ? const Value.absent() : Value(error),
      costCents: costCents == null ? const Value.absent() : Value(costCents),
    ),
  );

  /// Requeues a reaped job for retry (increments attempts, clears the lease).
  Future<void> requeueJob(String jobId, int attempts) =>
      (update(jobsTable)..where((t) => t.id.equals(jobId))).write(
        JobsTableCompanion(
          status: const Value('queued'),
          workerId: const Value(null),
          leaseExpiresAt: const Value(null),
          attempts: Value(attempts),
        ),
      );

  // ── Placement log (workspace-scoped) ──

  /// Appends a placement decision.
  Future<void> logPlacement(PlacementLogTableCompanion entry) =>
      into(placementLogTable).insert(entry);

  /// Placement decisions for [jobId] within [workspaceId], newest first.
  Future<List<PlacementLogTableData>> placementsForJob(
    String workspaceId,
    String jobId,
  ) =>
      (select(placementLogTable)
            ..where(
              (t) => t.workspaceId.equals(workspaceId) & t.jobId.equals(jobId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Live placement decisions for [jobId] within [workspaceId].
  Stream<List<PlacementLogTableData>> watchPlacementsForJob(
    String workspaceId,
    String jobId,
  ) =>
      (select(placementLogTable)
            ..where(
              (t) => t.workspaceId.equals(workspaceId) & t.jobId.equals(jobId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();
}
