import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/placement_record.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/ports/job_executor_port.dart';
import 'package:cc_domain/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_infra/src/fleet/fleet_scheduler_service.dart';
import 'package:test/test.dart';

/// Minimal in-memory FleetRepository.
class _FakeFleetRepo implements FleetRepository {
  final Map<String, Worker> workers = {};
  final Map<String, Job> jobs = {};
  final Map<String, List<PlacementRecord>> placements = {};
  bool tryLeaseReturns = true;

  void add(Job job) {
    jobs[job.id] = job;
    placements.putIfAbsent(job.id, () => []);
  }

  @override
  Future<void> upsertWorker(Worker worker) async {
    workers[worker.id] = worker;
  }

  @override
  Future<List<Worker>> allWorkers() async => workers.values.toList();

  @override
  Stream<List<Worker>> watchWorkers() async* {
    yield workers.values.toList();
  }

  @override
  Future<Worker?> workerById(String id) async => workers[id];

  @override
  Future<List<Worker>> eligibleWorkers() async =>
      workers.values.where((w) => w.isSchedulable).toList();

  @override
  Future<void> recordHeartbeat(String workerId, DateTime now) async {}

  @override
  Future<void> deleteWorker(String workerId) async {
    workers.remove(workerId);
  }

  @override
  Future<void> upsertJob(Job job) async {
    jobs[job.id] = job;
  }

  @override
  Future<Job?> jobById(String workspaceId, String id) async => jobs[id];

  @override
  Future<Job?> jobByIdGlobal(String id) async => jobs[id];

  @override
  Future<List<Job>> jobsByStatus(String workspaceId, JobStatus status) async =>
      jobs.values.where((j) => j.status == status).toList();

  @override
  Stream<List<Job>> watchJobs(String workspaceId) async* {
    yield jobs.values.where((j) => j.workspaceId == workspaceId).toList();
  }

  @override
  Future<List<Job>> queuedJobsGlobal() async {
    final list = jobs.values
        .where((j) => j.status == JobStatus.queued)
        .toList();
    list.sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  Future<List<Job>> expiredLeasedJobs(DateTime now) async => jobs.values
      .where(
        (j) =>
            (j.status == JobStatus.leased || j.status == JobStatus.running) &&
            j.leaseExpired(now),
      )
      .toList();

  @override
  Future<List<Job>> activeJobsForWorker(String workerId) async => jobs.values
      .where((j) => j.workerId == workerId && j.status.isActive)
      .toList();

  @override
  Future<bool> tryLeaseJob(
    String jobId,
    String workerId,
    DateTime leaseExpiresAt,
    DateTime now,
  ) async {
    final job = jobs[jobId];
    if (job == null || job.status != JobStatus.queued || !tryLeaseReturns) {
      return false;
    }
    jobs[jobId] = _copy(
      job,
      status: JobStatus.leased,
      workerId: workerId,
      leaseExpiresAt: leaseExpiresAt,
    );
    return true;
  }

  @override
  Future<void> renewLease(
    String jobId,
    DateTime leaseExpiresAt, {
    int? lastAckedSeq,
  }) async {}

  @override
  Future<void> markJobRunning(String jobId, DateTime now) async {
    final job = jobs[jobId];
    if (job != null) {
      jobs[jobId] = _copy(job, status: JobStatus.running, startedAt: now);
    }
  }

  @override
  Future<void> markJobTerminal(
    String jobId,
    JobStatus status,
    DateTime now, {
    String? resultJson,
    String? error,
    int? costCents,
  }) async {
    final job = jobs[jobId];
    if (job != null) {
      jobs[jobId] = _copy(
        job,
        status: status,
        finishedAt: now,
        resultJson: resultJson,
        error: error,
        costCents: costCents,
      );
    }
  }

  @override
  Future<void> requeueJob(String jobId, int attempts) async {
    final job = jobs[jobId];
    if (job != null) {
      jobs[jobId] = _copy(
        job,
        status: JobStatus.queued,
        attempts: attempts,
        clearWorkerId: true,
        clearLease: true,
      );
    }
  }

  @override
  Future<void> logPlacement({
    required String workspaceId,
    required String jobId,
    required PlacementDecision decision,
    required DateTime now,
  }) async {
    placements.putIfAbsent(jobId, () => []);
    placements[jobId]!.add(
      PlacementRecord(
        id: '$jobId-${placements[jobId]!.length}',
        workspaceId: workspaceId,
        jobId: jobId,
        code: decision.code,
        reason: decision.reason,
        workerId: decision.workerId,
        createdAt: now,
      ),
    );
  }

  @override
  Future<List<PlacementRecord>> placementsForJob(
    String workspaceId,
    String jobId,
  ) async => placements[jobId] ?? const [];

  @override
  Stream<List<PlacementRecord>> watchPlacementsForJob(
    String workspaceId,
    String jobId,
  ) async* {
    yield placements[jobId] ?? const [];
  }
}

Job _copy(
  Job job, {
  JobStatus? status,
  String? workerId,
  DateTime? leaseExpiresAt,
  DateTime? startedAt,
  DateTime? finishedAt,
  int? attempts,
  String? resultJson,
  String? error,
  int? costCents,
  bool clearWorkerId = false,
  bool clearLease = false,
}) => Job(
  id: job.id,
  workspaceId: job.workspaceId,
  kind: job.kind,
  spec: job.spec,
  status: status ?? job.status,
  requiredCaps: job.requiredCaps,
  preferredCaps: job.preferredCaps,
  priority: job.priority,
  pinnedWorkerId: job.pinnedWorkerId,
  workerId: clearWorkerId ? null : (workerId ?? job.workerId),
  leaseExpiresAt: clearLease ? null : (leaseExpiresAt ?? job.leaseExpiresAt),
  submittedBy: job.submittedBy,
  costCents: costCents ?? job.costCents,
  attempts: attempts ?? job.attempts,
  maxAttempts: job.maxAttempts,
  agentId: job.agentId,
  conversationId: job.conversationId,
  createdAt: job.createdAt,
  leasedAt: job.leasedAt,
  startedAt: startedAt ?? job.startedAt,
  finishedAt: finishedAt ?? job.finishedAt,
  resultJson: resultJson ?? job.resultJson,
  error: error ?? job.error,
);

/// A scripted JobExecution whose result and event stream are pre-wired.
class _ScriptedExecution implements JobExecution {
  _ScriptedExecution(this._jobId);

  final String _jobId;
  final StreamController<AgentProcessEvent> _events =
      StreamController<AgentProcessEvent>();
  final Completer<JobResult> _result = Completer<JobResult>();
  bool cancelled = false;
  int completeCount = 0;

  void emit(AgentProcessEvent e) => _events.add(e);

  void complete(JobResult r) {
    completeCount++;
    if (!_result.isCompleted) {
      _result.complete(r);
    }
    if (!_events.isClosed) {
      _events.close();
    }
  }

  void fail(Object e) {
    if (!_result.isCompleted) {
      _result.completeError(e);
    }
    if (!_events.isClosed) {
      _events.close();
    }
  }

  @override
  String get jobId => _jobId;

  @override
  Stream<AgentProcessEvent> get events => _events.stream;

  @override
  Future<JobResult> get result => _result.future;

  @override
  Future<void> Function() get cancel => () async {
    cancelled = true;
    if (!_result.isCompleted) {
      _result.complete(const JobResult.failure('cancelled'));
    }
    if (!_events.isClosed) {
      await _events.close();
    }
  };
}

/// A scripted executor that creates a fresh [_ScriptedExecution] on each
/// `execute()` call (matching the real executor's behavior — each attempt gets
/// its own result future).
class _ScriptedExecutor implements JobExecutorPort {
  _ScriptedExecutor();
  final List<Job> started = [];
  final List<_ScriptedExecution> executions = [];

  /// The most recent execution created for [jobId], or null.
  _ScriptedExecution? lastFor(String jobId) {
    for (var i = executions.length - 1; i >= 0; i--) {
      if (executions[i].jobId == jobId) {
        return executions[i];
      }
    }
    return null;
  }

  @override
  bool canExecute(Job job) => true;

  @override
  Future<JobExecution> execute(Job job) async {
    started.add(job);
    final e = _ScriptedExecution(job.id);
    executions.add(e);
    return e;
  }
}

/// Pumps the microtask queue [n] times so unawaited ticks/executions settle.
Future<void> _pump([int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

DateTime _t(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

WorkerCapabilities _caps({
  bool parallel = false,
  int cores = 1,
  Set<String> extra = const {},
}) => WorkerCapabilities(
  os: 'macos',
  arch: 'arm64',
  cores: cores,
  ramMb: 1024,
  acceptsParallel: parallel,
  extra: extra,
);

Job _job({
  required String id,
  String workspaceId = 'ws',
  JobKind kind = JobKind.agentRun,
  JobSpec? spec,
  JobStatus status = JobStatus.queued,
  int priority = 0,
  String? pinnedWorkerId,
  String? workerId,
  int maxAttempts = 1,
  int attempts = 0,
  Set<String> requiredCaps = const {},
  Set<String> preferredCaps = const {},
  DateTime? createdAt,
}) => Job(
  id: id,
  workspaceId: workspaceId,
  kind: kind,
  spec: spec ?? const AgentRunJobSpec(agentId: 'a'),
  status: status,
  requiredCaps: requiredCaps,
  preferredCaps: preferredCaps,
  priority: priority,
  pinnedWorkerId: pinnedWorkerId,
  workerId: workerId,
  maxAttempts: maxAttempts,
  attempts: attempts,
  createdAt: createdAt ?? _t(0),
);

void main() {
  group('FleetSchedulerService.ensureLocalWorker', () {
    test(
      'inserts local worker with given capabilities and online status',
      () async {
        final repo = _FakeFleetRepo();
        final svc = FleetSchedulerService(
          repository: repo,
          executorResolver: (_) => null,
          now: () => _t(100),
        );
        final w = await svc.ensureLocalWorker(_caps(cores: 8));
        expect(w.id, kLocalWorkerId);
        expect(w.name, 'this machine');
        expect(w.status, WorkerStatus.online);
        expect(w.protocolVersion, kFleetProtocolVersion);
        expect(w.createdAt, _t(100));
        expect(w.capabilities.cores, 8);
        expect(repo.workers[kLocalWorkerId], isNotNull);
      },
    );

    test('preserves existing name and createdAt on refresh', () async {
      final repo = _FakeFleetRepo();
      repo.workers[kLocalWorkerId] = Worker(
        id: kLocalWorkerId,
        name: 'existing-machine',
        capabilities: _caps(),
        status: WorkerStatus.draining,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(5),
      );
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(999),
      );
      final w = await svc.ensureLocalWorker(_caps());
      expect(w.name, 'existing-machine');
      expect(w.createdAt, _t(5));
      expect(w.lastHeartbeatAt, _t(999));
    });
  });

  group('FleetSchedulerService.registerWorker', () {
    test('compatible worker becomes online', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(50),
      );
      final id = await svc.registerWorker(
        workerId: 'w1',
        registration: const WorkerRegistration(
          name: 'remote-1',
          capsJson: '{"os":"linux","arch":"x64","cores":4,"ramMb":2048}',
          protocolVersion: kFleetProtocolVersion,
        ),
        registeredBy: 'op-1',
        pairedDeviceId: 'dev-1',
        credentialRef: 'cred-1',
      );
      expect(id, 'w1');
      final w = repo.workers['w1']!;
      expect(w.status, WorkerStatus.online);
      expect(w.protocolVersion, kFleetProtocolVersion);
      expect(w.credentialRef, 'cred-1');
      expect(w.pairedDeviceId, 'dev-1');
      expect(w.registeredBy, 'op-1');
      expect(w.capabilities.cores, 4);
    });

    test('incompatible protocol version marks worker incompatible', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(1),
      );
      await svc.registerWorker(
        workerId: 'w2',
        registration: const WorkerRegistration(
          name: 'old',
          capsJson: '{}',
          protocolVersion: 999,
        ),
      );
      expect(repo.workers['w2']!.status, WorkerStatus.incompatible);
    });

    test(
      'preserves credentialRef/pairedDeviceId on re-register if absent',
      () async {
        final repo = _FakeFleetRepo();
        repo.workers['w3'] = Worker(
          id: 'w3',
          name: 'old-name',
          capabilities: _caps(),
          status: WorkerStatus.online,
          protocolVersion: kFleetProtocolVersion,
          credentialRef: 'old-cred',
          pairedDeviceId: 'old-dev',
          createdAt: _t(2),
        );
        final svc = FleetSchedulerService(
          repository: repo,
          executorResolver: (_) => null,
          now: () => _t(3),
        );
        await svc.registerWorker(
          workerId: 'w3',
          registration: const WorkerRegistration(
            name: 'new-name',
            capsJson: '{}',
            protocolVersion: kFleetProtocolVersion,
          ),
        );
        final w = repo.workers['w3']!;
        expect(w.credentialRef, 'old-cred');
        expect(w.pairedDeviceId, 'old-dev');
        expect(w.createdAt, _t(2));
        expect(w.name, 'new-name');
      },
    );
  });

  group('FleetSchedulerService.submit', () {
    test('creates a queued job with computed caps and priority', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        newId: () => 'job-1',
        now: () => _t(7),
      );
      final id = await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(
          agentId: 'a',
          extraRequiredCaps: {'sandbox'},
          extraPreferredCaps: {'ml'},
        ),
        priority: 5,
        extraRequiredCaps: {'macos'},
        extraPreferredCaps: {'parallel'},
        submittedBy: 'u',
        agentId: 'a',
        conversationId: 'c',
        maxAttempts: 3,
      );
      expect(id, 'job-1');
      final job = repo.jobs['job-1']!;
      expect(job.status, JobStatus.queued);
      expect(job.priority, 5);
      expect(job.requiredCaps, containsAll(['sandbox', 'macos']));
      expect(job.preferredCaps, containsAll(['ml', 'parallel']));
      expect(job.submittedBy, 'u');
      expect(job.maxAttempts, 3);
      expect(job.createdAt, _t(7));
    });

    test('default caps from spec seed required/preferred', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        newId: () => 'g-1',
        now: () => _t(0),
      );
      await svc.submit(
        workspaceId: 'ws',
        spec: const GoldenRenderJobSpec(prNodeId: 'p', repoId: 'r'),
      );
      final job = repo.jobs['g-1']!;
      expect(job.requiredCaps, contains(FleetCaps.flutter));
    });

    test('default id generator yields unique ids', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      final id1 = await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
      );
      final id2 = await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'b'),
      );
      expect(id1, isNot(equals(id2)));
      expect(id1, startsWith('job-'));
    });
  });

  group('FleetSchedulerService.tick placement', () {
    test('places a queued job onto the local worker and starts it', () async {
      final repo = _FakeFleetRepo();
      final executor = _ScriptedExecutor();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'j',
        now: () => _t(0),
        renewInterval: const Duration(minutes: 5),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
      );
      await _pump();
      expect(repo.jobs['j']!.status, JobStatus.leased);
      expect(executor.started, hasLength(1));
      final execution = executor.lastFor('j')!;
      execution.emit(TextEvent(content: 'hello'));
      await _pump();
      expect(repo.jobs['j']!.status, JobStatus.running);
      execution.complete(
        const JobResult.ok(resultJson: '{"x":1}', costCents: 9),
      );
      await _pump();
      expect(repo.jobs['j']!.status, JobStatus.done);
      expect(repo.jobs['j']!.resultJson, '{"x":1}');
      expect(repo.jobs['j']!.costCents, 9);
    });

    test('no executor for worker fails the job loudly', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        newId: () => 'j2',
        now: () => _t(0),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
      );
      await _pump();
      expect(repo.jobs['j2']!.status, JobStatus.failed);
      expect(repo.jobs['j2']!.error, contains('No executor'));
    });

    test('failed execution with retries left requeues the job', () async {
      final repo = _FakeFleetRepo();
      final executor = _ScriptedExecutor();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'j3',
        now: () => _t(0),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
        maxAttempts: 3,
      );
      await _pump();
      await _pump();
      executor.lastFor('j3')!.complete(const JobResult.failure('boom'));
      await _pump();
      await _pump();
      // The job was requeued (attempts incremented) then re-leased by the
      // scheduler's recursive tick — so its status is active again, and a new
      // attempt's execution has been started.
      expect(repo.jobs['j3']!.attempts, 1);
      expect(repo.jobs['j3']!.status.isActive, isTrue);
      expect(
        executor.executions.where((e) => e.jobId == 'j3').length,
        greaterThanOrEqualTo(2),
      );
      // Second attempt succeeds on its own fresh execution.
      executor.lastFor('j3')!.complete(const JobResult.ok());
      await _pump();
      await _pump();
      expect(repo.jobs['j3']!.status, JobStatus.done);
    });

    test('failed execution with retries exhausted marks failed', () async {
      final repo = _FakeFleetRepo();
      final executor = _ScriptedExecutor();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'j4',
        now: () => _t(0),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
        maxAttempts: 1,
      );
      await _pump();
      await _pump();
      final execution = executor.lastFor('j4')!;
      execution.complete(const JobResult.failure('fatal', costCents: 5));
      await _pump();
      await _pump();
      expect(repo.jobs['j4']!.status, JobStatus.failed);
      expect(repo.jobs['j4']!.error, 'fatal');
      expect(repo.jobs['j4']!.costCents, 5);
    });

    test('execution error caught and requeued', () async {
      final repo = _FakeFleetRepo();
      final executor = _ScriptedExecutor();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'j5',
        now: () => _t(0),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
        maxAttempts: 2,
      );
      await _pump();
      await _pump();
      final firstExecution = executor.lastFor('j5')!;
      firstExecution.fail(StateError('boom'));
      await _pump();
      await _pump();
      // Requeued (attempts incremented) and a new execution started.
      expect(repo.jobs['j5']!.attempts, 1);
      expect(repo.jobs['j5']!.status.isActive, isTrue);
      final retryExecution = executor.lastFor('j5')!;
      expect(retryExecution, isNot(same(firstExecution)));
      retryExecution.complete(const JobResult.ok());
      await _pump();
      await _pump();
      expect(repo.jobs['j5']!.status, JobStatus.done);
    });

    test('onJobEvent receives events for a started job', () async {
      final repo = _FakeFleetRepo();
      final executor = _ScriptedExecutor();
      final events = <AgentProcessEvent>[];
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'j6',
        now: () => _t(0),
        onJobEvent: (e, _) => events.add(e),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
      );
      await _pump();
      final ev = TextEvent(content: 'e1');
      executor.lastFor('j6')!.emit(ev);
      await _pump();
      expect(events, contains(ev));
      executor.lastFor('j6')!.complete(const JobResult.ok());
      await _pump();
    });

    test(
      'queued job with no eligible worker stays queued and logs placement',
      () async {
        final repo = _FakeFleetRepo();
        final svc = FleetSchedulerService(
          repository: repo,
          executorResolver: (_) => null,
          newId: () => 'j7',
          now: () => _t(0),
        );
        await svc.ensureLocalWorker(_caps());
        await svc.submit(
          workspaceId: 'ws',
          spec: const AgentRunJobSpec(agentId: 'a'),
          extraRequiredCaps: {'nonexistent'},
        );
        await _pump();
        expect(repo.jobs['j7']!.status, JobStatus.queued);
        expect(repo.placements['j7']!, isNotEmpty);
      },
    );

    test('tryLeaseJob returning false leaves the job queued', () async {
      final repo = _FakeFleetRepo();
      repo.tryLeaseReturns = false;
      final executor = _ScriptedExecutor();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'j8',
        now: () => _t(0),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
      );
      await _pump();
      expect(repo.jobs['j8']!.status, JobStatus.queued);
      expect(executor.started, isEmpty);
    });

    test(
      're-entrancy guard: a concurrent tick runs again after the first',
      () async {
        final repo = _FakeFleetRepo();
        final svc = FleetSchedulerService(
          repository: repo,
          executorResolver: (_) => null,
          newId: () => 'j9',
          now: () => _t(0),
        );
        await svc.ensureLocalWorker(_caps());
        await svc.submit(
          workspaceId: 'ws',
          spec: const AgentRunJobSpec(agentId: 'a'),
        );
        await Future.wait([svc.tick(), svc.tick()]);
        await _pump();
        expect(repo.jobs['j9']!.status, JobStatus.failed);
      },
    );
  });

  group('FleetSchedulerService.reapExpiredLeases', () {
    test(
      'reaps a leased job with no live execution, fails when no retries',
      () async {
        final repo = _FakeFleetRepo();
        final svc = FleetSchedulerService(
          repository: repo,
          executorResolver: (_) => null,
          newId: () => 'r1',
          now: () => _t(1000),
        );
        repo.add(
          _job(id: 'r1', status: JobStatus.leased, workerId: kLocalWorkerId),
        );
        final orig = repo.jobs['r1']!;
        repo.jobs['r1'] = _copy(orig, leaseExpiresAt: _t(10));
        await svc.reapExpiredLeases();
        await _pump();
        expect(repo.jobs['r1']!.status, JobStatus.failed);
      },
    );

    test('reaped job with a live execution cancels the execution', () async {
      final repo = _FakeFleetRepo();
      final executor = _ScriptedExecutor();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'r2',
        now: () => _t(100),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
      );
      await _pump();
      final leased = repo.jobs['r2']!;
      repo.jobs['r2'] = _copy(leased, leaseExpiresAt: _t(0));
      await svc.reapExpiredLeases();
      await _pump();
      expect(executor.lastFor('r2')!.cancelled, isTrue);
    });

    test('no expired leases is a no-op', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(100),
      );
      await svc.reapExpiredLeases();
      expect(repo.jobs, isEmpty);
    });
  });

  group('FleetSchedulerService.cancelJob', () {
    test('cancels a queued job', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      repo.add(_job(id: 'c1', status: JobStatus.queued));
      await svc.cancelJob('ws', 'c1');
      expect(repo.jobs['c1']!.status, JobStatus.cancelled);
    });

    test('cancels a leased job and stops its execution', () async {
      final repo = _FakeFleetRepo();
      final executor = _ScriptedExecutor();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'c2',
        now: () => _t(0),
      );
      await svc.ensureLocalWorker(_caps());
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
      );
      await _pump();
      await svc.cancelJob('ws', 'c2');
      await _pump();
      expect(executor.lastFor('c2')!.cancelled, isTrue);
      expect(repo.jobs['c2']!.status, JobStatus.cancelled);
    });

    test('cancel of missing job is a no-op', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      await svc.cancelJob('ws', 'missing');
      expect(repo.jobs, isEmpty);
    });

    test('cancel of an already-terminal job is a no-op', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      repo.add(_job(id: 'c3', status: JobStatus.done));
      await svc.cancelJob('ws', 'c3');
      expect(repo.jobs['c3']!.status, JobStatus.done);
    });
  });

  group('FleetSchedulerService.recordHeartbeat', () {
    test('missing worker is ignored', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      await svc.recordHeartbeat('nope');
      expect(repo.workers, isEmpty);
    });

    test('protocol mismatch marks worker incompatible', () async {
      final repo = _FakeFleetRepo();
      repo.workers['w'] = Worker(
        id: 'w',
        name: 'w',
        capabilities: _caps(),
        status: WorkerStatus.online,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(0),
      );
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(99),
      );
      await svc.recordHeartbeat('w', protocolVersion: 42);
      expect(repo.workers['w']!.status, WorkerStatus.incompatible);
      expect(repo.workers['w']!.protocolVersion, 42);
    });

    test('revoked worker is not changed', () async {
      final repo = _FakeFleetRepo();
      repo.workers['w'] = Worker(
        id: 'w',
        name: 'w',
        capabilities: _caps(),
        status: WorkerStatus.revoked,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(0),
      );
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(99),
      );
      await svc.recordHeartbeat('w', protocolVersion: kFleetProtocolVersion);
      expect(repo.workers['w']!.status, WorkerStatus.revoked);
    });

    test('draining worker stays draining', () async {
      final repo = _FakeFleetRepo();
      repo.workers['w'] = Worker(
        id: 'w',
        name: 'w',
        capabilities: _caps(),
        status: WorkerStatus.draining,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(0),
      );
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(99),
      );
      await svc.recordHeartbeat('w', protocolVersion: kFleetProtocolVersion);
      expect(repo.workers['w']!.status, WorkerStatus.draining);
    });

    test('online worker refreshes caps and heartbeat', () async {
      final repo = _FakeFleetRepo();
      repo.workers['w'] = Worker(
        id: 'w',
        name: 'w',
        capabilities: _caps(),
        status: WorkerStatus.online,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(0),
      );
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(99),
      );
      await svc.recordHeartbeat(
        'w',
        protocolVersion: kFleetProtocolVersion,
        caps: _caps(cores: 16),
      );
      expect(repo.workers['w']!.lastHeartbeatAt, _t(99));
      expect(repo.workers['w']!.capabilities.cores, 16);
    });
  });

  group('FleetSchedulerService drain/resume/remove/revoke worker', () {
    test('drainWorker sets draining status and drainedAt', () async {
      final repo = _FakeFleetRepo();
      repo.workers['w'] = Worker(
        id: 'w',
        name: 'w',
        capabilities: _caps(),
        status: WorkerStatus.online,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(0),
      );
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(20),
      );
      await svc.drainWorker('w');
      expect(repo.workers['w']!.status, WorkerStatus.draining);
      expect(repo.workers['w']!.drainedAt, _t(20));
    });

    test('drainWorker missing worker is a no-op', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      await svc.drainWorker('missing');
      expect(repo.workers, isEmpty);
    });

    test('resumeWorker brings a drained worker back online', () async {
      final repo = _FakeFleetRepo();
      repo.workers['w'] = Worker(
        id: 'w',
        name: 'w',
        capabilities: _caps(),
        status: WorkerStatus.draining,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(0),
      );
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      await svc.resumeWorker('w');
      expect(repo.workers['w']!.status, WorkerStatus.online);
    });

    test('resumeWorker missing is a no-op', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      await svc.resumeWorker('missing');
      expect(repo.workers, isEmpty);
    });

    test('removeWorker deletes the worker', () async {
      final repo = _FakeFleetRepo();
      repo.workers['w'] = Worker(
        id: 'w',
        name: 'w',
        capabilities: _caps(),
        status: WorkerStatus.revoked,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(0),
      );
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      await svc.removeWorker('w');
      expect(repo.workers['w'], isNull);
    });

    test(
      'revokeWorker marks revoked and fails active jobs with no execution',
      () async {
        final repo = _FakeFleetRepo();
        repo.workers['w'] = Worker(
          id: 'w',
          name: 'w',
          capabilities: _caps(),
          status: WorkerStatus.online,
          protocolVersion: kFleetProtocolVersion,
          createdAt: _t(0),
        );
        repo.add(
          _job(
            id: 'rj',
            status: JobStatus.running,
            workerId: 'w',
            maxAttempts: 1,
          ),
        );
        final svc = FleetSchedulerService(
          repository: repo,
          executorResolver: (_) => null,
          now: () => _t(10),
        );
        await svc.revokeWorker('w');
        await _pump();
        expect(repo.workers['w']!.status, WorkerStatus.revoked);
        expect(repo.workers['w']!.revokedAt, _t(10));
        expect(repo.jobs['rj']!.status, JobStatus.failed);
      },
    );

    test('revokeWorker cancels a live execution for an active job', () async {
      final repo = _FakeFleetRepo();
      repo.workers['w'] = Worker(
        id: 'w',
        name: 'w',
        capabilities: _caps(),
        status: WorkerStatus.online,
        protocolVersion: kFleetProtocolVersion,
        createdAt: _t(0),
      );
      final executor = _ScriptedExecutor();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == 'w' ? executor : null,
        newId: () => 'rx',
        now: () => _t(0),
      );
      // Pin the job to worker w.
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
        pinnedWorkerId: 'w',
      );
      await _pump();
      expect(repo.jobs['rx']!.workerId, 'w');
      await svc.revokeWorker('w');
      await _pump();
      expect(executor.lastFor('rx')!.cancelled, isTrue);
    });

    test('revokeWorker missing is a no-op', () async {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      await svc.revokeWorker('missing');
      expect(repo.workers, isEmpty);
    });
  });

  group('FleetSchedulerService.dispose', () {
    test('disposes cleanly', () {
      final repo = _FakeFleetRepo();
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (_) => null,
        now: () => _t(0),
      );
      svc.dispose();
      expect(true, isTrue);
    });
  });

  group('FleetSchedulerService local worker capacity', () {
    test('local worker multiplexes multiple jobs (no busy cap)', () async {
      final repo = _FakeFleetRepo();
      final executor = _ScriptedExecutor();
      var counter = 0;
      final svc = FleetSchedulerService(
        repository: repo,
        executorResolver: (w) => w.id == kLocalWorkerId ? executor : null,
        newId: () => 'cap-${counter++}',
        now: () => _t(0),
      );
      await svc.ensureLocalWorker(_caps(cores: 1));
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'a'),
      );
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'b'),
      );
      await svc.submit(
        workspaceId: 'ws',
        spec: const AgentRunJobSpec(agentId: 'c'),
      );
      await _pump(30);
      expect(executor.started.length, greaterThanOrEqualTo(3));
      for (final id in ['cap-0', 'cap-1', 'cap-2']) {
        executor.lastFor(id)!.complete(const JobResult.ok());
      }
      await _pump();
    });
  });
}
