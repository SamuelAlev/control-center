import 'dart:async';
import 'dart:math' as math;

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/ports/job_executor_port.dart';
import 'package:cc_domain/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:cc_domain/features/fleet/domain/services/job_scheduler.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Resolves the executor that runs a job on a chosen [Worker] (PRD 20 §2).
///
/// The implicit local worker resolves to an in-process `LocalJobExecutor` (a
/// code seam, no self-RPC); a remote worker resolves to a `RemoteJobExecutor`
/// bound to that worker's transport. Returns null when no executor is wired for
/// the worker (the job is then failed loudly, never silently lost).
typedef JobExecutorResolver = JobExecutorPort? Function(Worker worker);

/// The fixed id of the implicit local worker (the server host itself).
const String kLocalWorkerId = 'local';

/// The server-side fleet scheduler (PRD 20 §2, §8).
///
/// Submits become [Job] rows; a deterministic [JobScheduler] places each queued
/// job onto an eligible worker (pin → prefer → spill); the chosen executor
/// runs it while the scheduler holds/renews the lease and relays the event
/// stream. On a solo install the only worker is the implicit local one and the
/// job dispatches in-process — byte-identical to the pre-fleet path.
class FleetSchedulerService {
  /// Creates a [FleetSchedulerService].
  FleetSchedulerService({
    required FleetRepository repository,
    required JobExecutorResolver executorResolver,
    JobScheduler scheduler = const JobScheduler(),
    DateTime Function()? now,
    String Function()? newId,
    Duration leaseTtl = const Duration(minutes: 2),
    Duration renewInterval = const Duration(seconds: 30),
    void Function(AgentProcessEvent event, Job job)? onJobEvent,
  }) : _repo = repository,
       _resolveExecutor = executorResolver,
       _scheduler = scheduler,
       _now = now ?? DateTime.now,
       _newId = newId ?? _defaultId,
       _leaseTtl = leaseTtl,
       _renewInterval = renewInterval,
       _onJobEvent = onJobEvent;

  final FleetRepository _repo;
  final JobExecutorResolver _resolveExecutor;
  final JobScheduler _scheduler;
  final DateTime Function() _now;
  final String Function() _newId;
  final Duration _leaseTtl;
  final Duration _renewInterval;
  final void Function(AgentProcessEvent event, Job job)? _onJobEvent;

  /// Live executions keyed by job id (for cancellation / lease renewal).
  final Map<String, JobExecution> _executions = {};
  final Map<String, Timer> _renewTimers = {};

  bool _ticking = false;
  bool _tickAgain = false;

  static int _idCounter = 0;
  static String _defaultId() =>
      'job-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  /// Registers (or refreshes) the implicit local worker — the server host
  /// doubling as a zero-config worker. Always-on and unbounded concurrency.
  Future<Worker> ensureLocalWorker(
    WorkerCapabilities caps, {
    String name = 'this machine',
  }) async {
    final existing = await _repo.workerById(kLocalWorkerId);
    final worker = Worker(
      id: kLocalWorkerId,
      name: existing?.name ?? name,
      capabilities: caps,
      status: WorkerStatus.online,
      protocolVersion: kFleetProtocolVersion,
      lastHeartbeatAt: _now(),
      createdAt: existing?.createdAt ?? _now(),
    );
    await _repo.upsertWorker(worker);
    return worker;
  }

  /// Registers (or refreshes) a paired remote worker from its self-report.
  ///
  /// Applies the protocol handshake: a version mismatch marks the worker
  /// `incompatible` (leases withheld) rather than guessing the wire format.
  /// Returns the resolved worker id.
  Future<String> registerWorker({
    required String workerId,
    required WorkerRegistration registration,
    String? registeredBy,
    String? pairedDeviceId,
    String? credentialRef,
  }) async {
    final existing = await _repo.workerById(workerId);
    final caps = WorkerCapabilities.fromJsonString(registration.capsJson);
    final compatible = registration.protocolVersion == kFleetProtocolVersion;
    final worker = Worker(
      id: workerId,
      name: registration.name,
      capabilities: caps,
      status: compatible ? WorkerStatus.online : WorkerStatus.incompatible,
      protocolVersion: registration.protocolVersion,
      credentialRef: credentialRef ?? existing?.credentialRef,
      pairedDeviceId: pairedDeviceId ?? existing?.pairedDeviceId,
      registeredBy: registeredBy ?? existing?.registeredBy,
      lastHeartbeatAt: _now(),
      createdAt: existing?.createdAt ?? _now(),
    );
    await _repo.upsertWorker(worker);
    if (compatible) {
      unawaited(tick());
    }
    return workerId;
  }

  /// Submits a job and kicks the scheduler. Returns the new job id.
  Future<String> submit({
    required String workspaceId,
    required JobSpec spec,
    int priority = 0,
    String? pinnedWorkerId,
    Set<String> extraRequiredCaps = const {},
    Set<String> extraPreferredCaps = const {},
    String? submittedBy,
    String? agentId,
    String? conversationId,
    int maxAttempts = 1,
  }) async {
    final id = _newId();
    final job = Job(
      id: id,
      workspaceId: workspaceId,
      kind: spec.kind,
      spec: spec,
      status: JobStatus.queued,
      requiredCaps: {...spec.defaultRequiredCaps, ...extraRequiredCaps},
      preferredCaps: {...spec.defaultPreferredCaps, ...extraPreferredCaps},
      priority: priority,
      pinnedWorkerId: pinnedWorkerId,
      submittedBy: submittedBy,
      agentId: agentId,
      conversationId: conversationId,
      maxAttempts: maxAttempts,
      createdAt: _now(),
    );
    await _repo.upsertJob(job);
    unawaited(tick());
    return id;
  }

  /// Runs one scheduling pass over the global queue. Re-entrancy-guarded: a
  /// concurrent call just requests another pass after the current one.
  Future<void> tick() async {
    if (_ticking) {
      _tickAgain = true;
      return;
    }
    _ticking = true;
    try {
      do {
        _tickAgain = false;
        await _scheduleOnce();
      } while (_tickAgain);
    } finally {
      _ticking = false;
    }
  }

  Future<void> _scheduleOnce() async {
    final queued = await _repo.queuedJobsGlobal();
    if (queued.isEmpty) {
      return;
    }
    final snapshot = await _buildSnapshot();
    final placedNow = <String>{};
    for (final job in queued) {
      // A job placed earlier in this pass may have consumed a worker's slot.
      final liveSnapshot = FleetSnapshot(
        workers: snapshot.workers,
        busyWorkerIds: {...snapshot.busyWorkerIds, ...placedNow},
        cacheWarmWorkerIds: snapshot.cacheWarmWorkerIds,
      );
      final decision = _scheduler.place(job, liveSnapshot);
      await _repo.logPlacement(
        workspaceId: job.workspaceId,
        jobId: job.id,
        decision: decision,
        now: _now(),
      );
      if (!decision.placed) {
        continue;
      }
      final workerId = decision.workerId!;
      final leaseExpiresAt = _now().add(_leaseTtl);
      final leased = await _repo.tryLeaseJob(
        job.id,
        workerId,
        leaseExpiresAt,
        _now(),
      );
      if (!leased) {
        continue;
      }
      // A single-slot worker is now busy for the rest of this pass.
      final worker = snapshot.workers.firstWhere((w) => w.id == workerId);
      if (_capacityOf(worker) == 1) {
        placedNow.add(workerId);
      }
      final leasedJob = await _repo.jobByIdGlobal(job.id);
      if (leasedJob != null) {
        unawaited(_startExecution(leasedJob, worker));
      }
    }
  }

  Future<FleetSnapshot> _buildSnapshot() async {
    final workers = await _repo.allWorkers();
    final busy = <String>{};
    final countByWorker = <String, int>{};
    for (final w in workers) {
      final active = await _repo.activeJobsForWorker(w.id);
      countByWorker[w.id] = active.length;
      if (active.length >= _capacityOf(w)) {
        busy.add(w.id);
      }
    }
    return FleetSnapshot(workers: workers, busyWorkerIds: busy);
  }

  int _capacityOf(Worker worker) {
    if (worker.id == kLocalWorkerId) {
      // The local worker multiplexes dispatches exactly as the pre-fleet path.
      return 1 << 30;
    }
    if (worker.capabilities.acceptsParallel) {
      return math.max(1, worker.capabilities.cores);
    }
    return 1;
  }

  Future<void> _startExecution(Job job, Worker worker) async {
    final executor = _resolveExecutor(worker);
    if (executor == null) {
      CcInfraLog.warning(
        'FleetScheduler: no executor for worker ${worker.id}; failing '
        'job ${job.id}',
      );
      await _repo.markJobTerminal(
        job.id,
        JobStatus.failed,
        _now(),
        error: 'No executor wired for worker ${worker.name}.',
      );
      unawaited(tick());
      return;
    }
    try {
      final execution = await executor.execute(job);
      _executions[job.id] = execution;
      _armRenewTimer(job.id);
      var startedMarked = false;
      final sub = execution.events.listen((event) {
        if (!startedMarked) {
          startedMarked = true;
          unawaited(_repo.markJobRunning(job.id, _now()));
        }
        _onJobEvent?.call(event, job);
      });
      final result = await execution.result;
      await sub.cancel();
      _cancelRenewTimer(job.id);
      _executions.remove(job.id);
      if (result.success) {
        await _repo.markJobTerminal(
          job.id,
          JobStatus.done,
          _now(),
          resultJson: result.resultJson,
          costCents: result.costCents,
        );
      } else {
        await _failOrRetry(
          job,
          result.error ?? 'Job failed.',
          result.costCents,
        );
      }
    } on Object catch (e, st) {
      _cancelRenewTimer(job.id);
      _executions.remove(job.id);
      CcInfraLog.error('FleetScheduler: execution error for ${job.id}', e, st);
      await _failOrRetry(job, 'Execution error: $e', 0);
    }
    unawaited(tick());
  }

  Future<void> _failOrRetry(Job job, String error, int costCents) async {
    final current = await _repo.jobByIdGlobal(job.id);
    // A job the operator cancelled (or that another path already finalized)
    // must never be resurrected by an in-flight execution completing after the
    // fact — honour the terminal state and stop here.
    if (current == null || current.status.isTerminal) {
      return;
    }
    final attempts = (current.attempts) + 1;
    if (attempts < job.maxAttempts) {
      await _repo.requeueJob(job.id, attempts);
      CcInfraLog.warning(
        'FleetScheduler: retrying job ${job.id} (attempt $attempts/'
        '${job.maxAttempts}): $error',
      );
    } else {
      await _repo.markJobTerminal(
        job.id,
        JobStatus.failed,
        _now(),
        error: error,
        costCents: costCents,
      );
    }
  }

  void _armRenewTimer(String jobId) {
    _cancelRenewTimer(jobId);
    _renewTimers[jobId] = Timer.periodic(_renewInterval, (_) {
      unawaited(_repo.renewLease(jobId, _now().add(_leaseTtl)));
    });
  }

  void _cancelRenewTimer(String jobId) {
    _renewTimers.remove(jobId)?.cancel();
  }

  /// Reaps jobs whose lease expired (a worker vanished mid-run). Each is
  /// retried per its policy or surfaced as failed — never silently lost.
  Future<void> reapExpiredLeases() async {
    final expired = await _repo.expiredLeasedJobs(_now());
    for (final job in expired) {
      _cancelRenewTimer(job.id);
      await _repo.logPlacement(
        workspaceId: job.workspaceId,
        jobId: job.id,
        decision: PlacementDecision(
          code: PlacementCode.reaped,
          workerId: job.workerId,
          reason: 'Lease expired — worker ${job.workerId} went silent.',
        ),
        now: _now(),
      );
      final execution = _executions.remove(job.id);
      if (execution != null) {
        // A live execution owns this job's requeue/fail: cancelling completes
        // its result future so `_startExecution` runs `_failOrRetry` exactly
        // once (avoids the double-requeue / double-attempt race).
        await execution.cancel();
      } else {
        // No live execution (e.g. after a server restart) — finalize directly.
        await _failOrRetry(job, 'Lease expired (worker unreachable).', 0);
      }
    }
    if (expired.isNotEmpty) {
      unawaited(tick());
    }
  }

  /// Cancels a job: revokes any lease and marks it cancelled. For a remote
  /// worker the revocation is observed on the worker's next heartbeat/tick.
  Future<void> cancelJob(String workspaceId, String jobId) async {
    final job = await _repo.jobById(workspaceId, jobId);
    if (job == null || job.status.isTerminal) {
      return;
    }
    _cancelRenewTimer(jobId);
    final execution = _executions.remove(jobId);
    if (execution != null) {
      await execution.cancel();
    }
    await _repo.markJobTerminal(jobId, JobStatus.cancelled, _now());
  }

  /// Records a worker heartbeat, applying the protocol-version handshake.
  Future<void> recordHeartbeat(
    String workerId, {
    int? protocolVersion,
    WorkerCapabilities? caps,
  }) async {
    final worker = await _repo.workerById(workerId);
    if (worker == null) {
      return;
    }
    if (protocolVersion != null && protocolVersion != kFleetProtocolVersion) {
      await _repo.upsertWorker(
        worker.copyWith(
          status: WorkerStatus.incompatible,
          protocolVersion: protocolVersion,
          lastHeartbeatAt: _now(),
        ),
      );
      return;
    }
    if (worker.status == WorkerStatus.revoked) {
      return;
    }
    final next = worker.copyWith(
      capabilities: caps,
      lastHeartbeatAt: _now(),
      status: worker.status == WorkerStatus.draining
          ? WorkerStatus.draining
          : WorkerStatus.online,
    );
    await _repo.upsertWorker(next);
    unawaited(tick());
  }

  /// Puts a worker into drain: finishes current jobs, takes no new leases.
  Future<void> drainWorker(String workerId) async {
    final worker = await _repo.workerById(workerId);
    if (worker == null) {
      return;
    }
    await _repo.upsertWorker(
      worker.copyWith(status: WorkerStatus.draining, drainedAt: _now()),
    );
  }

  /// Brings a drained worker back online.
  Future<void> resumeWorker(String workerId) async {
    final worker = await _repo.workerById(workerId);
    if (worker == null) {
      return;
    }
    await _repo.upsertWorker(worker.copyWith(status: WorkerStatus.online));
    unawaited(tick());
  }

  /// Revokes a worker: its live session must end and its active jobs reap.
  Future<void> revokeWorker(String workerId) async {
    final worker = await _repo.workerById(workerId);
    if (worker == null) {
      return;
    }
    await _repo.upsertWorker(
      worker.copyWith(status: WorkerStatus.revoked, revokedAt: _now()),
    );
    final active = await _repo.activeJobsForWorker(workerId);
    for (final job in active) {
      _cancelRenewTimer(job.id);
      final execution = _executions.remove(job.id);
      if (execution != null) {
        // Close the live execution (frees the registry stream/completer and
        // unparks `_startExecution`, which requeues/fails the job exactly once)
        // — never drop the handle without cancelling it.
        await execution.cancel();
      } else {
        await _failOrRetry(job, 'Worker revoked mid-run.', 0);
      }
    }
    unawaited(tick());
  }

  /// Removes a worker row entirely (must be revoked/offline first in the UI).
  Future<void> removeWorker(String workerId) async {
    await _repo.deleteWorker(workerId);
  }

  /// Cancels all renewal timers and in-flight tracking (server shutdown).
  void dispose() {
    for (final timer in _renewTimers.values) {
      timer.cancel();
    }
    _renewTimers.clear();
    _executions.clear();
  }
}
