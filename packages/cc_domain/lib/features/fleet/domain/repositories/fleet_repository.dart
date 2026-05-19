import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/placement_record.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';

/// Persistence contract for the fleet (PRD 20).
///
/// Workers are **server-global** (a worker serves every workspace); jobs and
/// placement records are **workspace-scoped**. The scheduler/reaper methods
/// that intentionally span workspaces are marked in their doc comments and back
/// the `CROSS-WORKSPACE BY DESIGN` DAO queries.
abstract interface class FleetRepository {
  // ── Workers (global) ──

  /// Inserts or updates a worker.
  Future<void> upsertWorker(Worker worker);

  /// Every worker (fleet panel). Global by design.
  Future<List<Worker>> allWorkers();

  /// Live worker list. Global by design.
  Stream<List<Worker>> watchWorkers();

  /// One worker by id, or null.
  Future<Worker?> workerById(String id);

  /// Workers eligible to receive leases. Global by design.
  Future<List<Worker>> eligibleWorkers();

  /// Records a heartbeat at server time [now].
  Future<void> recordHeartbeat(String workerId, DateTime now);

  /// Removes a worker row (operator "remove").
  Future<void> deleteWorker(String workerId);

  // ── Jobs (workspace-scoped) ──

  /// Inserts or updates a job.
  Future<void> upsertJob(Job job);

  /// One job by id within [workspaceId], or null.
  Future<Job?> jobById(String workspaceId, String id);

  /// One job by id, workspace-agnostic. CROSS-WORKSPACE — scheduler/reaper only.
  Future<Job?> jobByIdGlobal(String id);

  /// Jobs in [workspaceId] with [status], newest first.
  Future<List<Job>> jobsByStatus(String workspaceId, JobStatus status);

  /// Live jobs for [workspaceId] (all statuses).
  Stream<List<Job>> watchJobs(String workspaceId);

  /// Queued jobs across the fleet, priority then FIFO. CROSS-WORKSPACE — the
  /// scheduler picks the next placement across the whole queue.
  Future<List<Job>> queuedJobsGlobal();

  /// Active jobs whose lease expired at [now]. CROSS-WORKSPACE — reaper scan.
  Future<List<Job>> expiredLeasedJobs(DateTime now);

  /// Active jobs on [workerId] (used on revoke). CROSS-WORKSPACE.
  Future<List<Job>> activeJobsForWorker(String workerId);

  /// Atomically leases [jobId] to [workerId] if still queued. Returns whether
  /// the lease was taken (guards double-lease races).
  Future<bool> tryLeaseJob(
    String jobId,
    String workerId,
    DateTime leaseExpiresAt,
    DateTime now,
  );

  /// Renews the lease on an active job (cheap, frequent).
  Future<void> renewLease(
    String jobId,
    DateTime leaseExpiresAt, {
    int? lastAckedSeq,
  });

  /// Marks a job running.
  Future<void> markJobRunning(String jobId, DateTime now);

  /// Marks a job terminal (`done`/`failed`/`cancelled`).
  Future<void> markJobTerminal(
    String jobId,
    JobStatus status,
    DateTime now, {
    String? resultJson,
    String? error,
    int? costCents,
  });

  /// Requeues a reaped job for retry (increments attempts).
  Future<void> requeueJob(String jobId, int attempts);

  // ── Placement log (workspace-scoped) ──

  /// Appends a placement decision for [jobId] within [workspaceId].
  Future<void> logPlacement({
    required String workspaceId,
    required String jobId,
    required PlacementDecision decision,
    required DateTime now,
  });

  /// Placement decisions for [jobId] within [workspaceId], newest first.
  Future<List<PlacementRecord>> placementsForJob(
    String workspaceId,
    String jobId,
  );

  /// Live placement decisions for [jobId] within [workspaceId].
  Stream<List<PlacementRecord>> watchPlacementsForJob(
    String workspaceId,
    String jobId,
  );
}
