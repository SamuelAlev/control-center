import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/placement_record.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_persistence/database/daos/fleet_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/mappers/fleet_mapper.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift-backed [FleetRepository] (PRD 20).
///
/// Delegates every operation to [FleetDao] and maps rows↔entities with
/// [FleetMapper]. Workers are server-global; jobs and placement rows are
/// workspace-scoped and the workspace id is threaded to the DAO.
class DaoFleetRepository implements FleetRepository {
  /// Creates a [DaoFleetRepository].
  DaoFleetRepository(this._dao);

  final FleetDao _dao;
  final FleetMapper _mapper = const FleetMapper();

  // ── Workers (global) ──

  @override
  Future<void> upsertWorker(Worker worker) =>
      _dao.upsertWorker(_mapper.workerToCompanion(worker));

  @override
  Future<List<Worker>> allWorkers() async =>
      (await _dao.allWorkers()).map(_mapper.workerFromRow).toList();

  @override
  Stream<List<Worker>> watchWorkers() => _dao.watchWorkers().map(
    (rows) => rows.map(_mapper.workerFromRow).toList(),
  );

  @override
  Future<Worker?> workerById(String id) async {
    final row = await _dao.workerById(id);
    return row == null ? null : _mapper.workerFromRow(row);
  }

  @override
  Future<List<Worker>> eligibleWorkers() async =>
      (await _dao.eligibleWorkers()).map(_mapper.workerFromRow).toList();

  @override
  Future<void> recordHeartbeat(String workerId, DateTime now) =>
      _dao.recordHeartbeat(workerId, now);

  @override
  Future<void> deleteWorker(String workerId) => _dao.deleteWorker(workerId);

  // ── Jobs (workspace-scoped) ──

  @override
  Future<void> upsertJob(Job job) =>
      _dao.upsertJob(_mapper.jobToCompanion(job));

  @override
  Future<Job?> jobById(String workspaceId, String id) async {
    final row = await _dao.jobById(workspaceId, id);
    return row == null ? null : _mapper.jobFromRow(row);
  }

  @override
  Future<Job?> jobByIdGlobal(String id) async {
    final row = await _dao.jobByIdGlobal(id);
    return row == null ? null : _mapper.jobFromRow(row);
  }

  @override
  Future<List<Job>> jobsByStatus(String workspaceId, JobStatus status) async =>
      (await _dao.jobsByStatus(
        workspaceId,
        status.wire,
      )).map(_mapper.jobFromRow).toList();

  @override
  Stream<List<Job>> watchJobs(String workspaceId) => _dao
      .watchJobs(workspaceId)
      .map((rows) => rows.map(_mapper.jobFromRow).toList());

  @override
  Future<List<Job>> queuedJobsGlobal() async =>
      (await _dao.queuedJobsGlobal()).map(_mapper.jobFromRow).toList();

  @override
  Future<List<Job>> expiredLeasedJobs(DateTime now) async =>
      (await _dao.expiredLeasedJobs(now)).map(_mapper.jobFromRow).toList();

  @override
  Future<List<Job>> activeJobsForWorker(String workerId) async =>
      (await _dao.activeJobsForWorker(
        workerId,
      )).map(_mapper.jobFromRow).toList();

  @override
  Future<bool> tryLeaseJob(
    String jobId,
    String workerId,
    DateTime leaseExpiresAt,
    DateTime now,
  ) => _dao.tryLeaseJob(jobId, workerId, leaseExpiresAt, now);

  @override
  Future<bool> renewLease(
    String jobId,
    String workerId,
    DateTime leaseExpiresAt, {
    int? lastAckedSeq,
  }) => _dao.renewLease(
    jobId,
    workerId,
    leaseExpiresAt,
    lastAckedSeq: lastAckedSeq,
  );

  @override
  Future<bool> markJobRunning(String jobId, String workerId, DateTime now) =>
      _dao.markJobRunning(jobId, workerId, now);

  @override
  Future<bool> markJobTerminal(
    String jobId,
    JobStatus status,
    DateTime now, {
    required Set<JobStatus> from,
    String? leasedTo,
    String? resultJson,
    String? error,
    int? costMicros,
  }) => _dao.markJobTerminal(
    jobId,
    status.wire,
    now,
    from: [for (final s in from) s.wire],
    leasedTo: leasedTo,
    resultJson: resultJson,
    error: error,
    costMicros: costMicros,
  );

  @override
  Future<bool> requeueJob(
    String jobId,
    int attempts, {
    required JobStatus from,
    required String? leasedTo,
  }) => _dao.requeueJob(jobId, attempts, from: from.wire, leasedTo: leasedTo);

  // ── Placement log (workspace-scoped) ──

  @override
  Future<void> logPlacement({
    required String workspaceId,
    required String jobId,
    required PlacementDecision decision,
    required DateTime now,
  }) => _dao.logPlacement(
    PlacementLogTableCompanion(
      id: Value(const Uuid().v4()),
      workspaceId: Value(workspaceId),
      jobId: Value(jobId),
      workerId: Value(decision.workerId),
      decision: Value(decision.code.wire),
      reason: Value(decision.reason),
      createdAt: Value(now),
    ),
  );

  @override
  Future<List<PlacementRecord>> placementsForJob(
    String workspaceId,
    String jobId,
  ) async => (await _dao.placementsForJob(
    workspaceId,
    jobId,
  )).map(_mapper.placementFromRow).toList();

  @override
  Stream<List<PlacementRecord>> watchPlacementsForJob(
    String workspaceId,
    String jobId,
  ) => _dao
      .watchPlacementsForJob(workspaceId, jobId)
      .map((rows) => rows.map(_mapper.placementFromRow).toList());
}
