import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';
import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/placement_record.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/src/fleet/fleet_scheduler_service.dart';
import 'package:cc_server_core/src/fleet/fleet_rpc_ops.dart';
import 'package:cc_server_core/src/fleet/remote_execution_registry.dart';
import 'package:test/test.dart';

/// Map-backed [FleetRepository] fake. Records every call so the ops can assert
/// what the handlers forwarded; unused members route through [noSuchMethod].
class _FakeFleetRepository implements FleetRepository {
  final Map<String, Worker> workers = {};
  final Map<String, Job> jobs = {};
  final List<PlacementRecord> placements = [];
  final List<String> renewLeaseCalls = [];

  @override
  Future<Worker?> workerById(String id) async => workers[id];

  @override
  Future<List<Worker>> allWorkers() async => workers.values.toList();

  @override
  Stream<List<Worker>> watchWorkers() => Stream.value(workers.values.toList());

  @override
  Future<List<Worker>> eligibleWorkers() async =>
      workers.values.where((w) => w.isSchedulable).toList();

  @override
  Future<void> upsertWorker(Worker worker) async {
    workers[worker.id] = worker;
  }

  @override
  Future<void> recordHeartbeat(String workerId, DateTime now) async {}

  @override
  Future<void> deleteWorker(String workerId) async {
    workers.remove(workerId);
  }

  @override
  Future<Job?> jobById(String workspaceId, String id) async =>
      jobs[id] != null && jobs[id]!.workspaceId == workspaceId
      ? jobs[id]
      : null;

  @override
  Future<Job?> jobByIdGlobal(String id) async => jobs[id];

  @override
  Future<List<Job>> jobsByStatus(String workspaceId, JobStatus status) async =>
      jobs.values
          .where((j) => j.workspaceId == workspaceId && j.status == status)
          .toList();

  @override
  Stream<List<Job>> watchJobs(String workspaceId) => Stream.value(
    jobs.values.where((j) => j.workspaceId == workspaceId).toList(),
  );

  @override
  Future<List<Job>> queuedJobsGlobal() async =>
      jobs.values.where((j) => j.status == JobStatus.queued).toList();

  @override
  Future<List<Job>> expiredLeasedJobs(DateTime now) async => const [];

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
    if (job == null || job.status != JobStatus.queued) {
      return false;
    }
    jobs[jobId] = Job(
      id: job.id,
      workspaceId: job.workspaceId,
      kind: job.kind,
      spec: job.spec,
      status: JobStatus.leased,
      requiredCaps: job.requiredCaps,
      preferredCaps: job.preferredCaps,
      priority: job.priority,
      pinnedWorkerId: job.pinnedWorkerId,
      workerId: workerId,
      leaseExpiresAt: leaseExpiresAt,
      submittedBy: job.submittedBy,
      costCents: job.costCents,
      attempts: job.attempts,
      maxAttempts: job.maxAttempts,
      lastAckedSeq: job.lastAckedSeq,
      resultJson: job.resultJson,
      error: job.error,
      agentId: job.agentId,
      conversationId: job.conversationId,
      createdAt: job.createdAt,
      leasedAt: job.leasedAt,
      startedAt: job.startedAt,
      finishedAt: job.finishedAt,
    );
    return true;
  }

  @override
  Future<void> renewLease(
    String jobId,
    DateTime leaseExpiresAt, {
    int? lastAckedSeq,
  }) async {
    renewLeaseCalls.add(jobId);
  }

  @override
  Future<void> markJobRunning(String jobId, DateTime now) async {}

  @override
  Future<void> markJobTerminal(
    String jobId,
    JobStatus status,
    DateTime now, {
    String? resultJson,
    String? error,
    int? costCents,
  }) async {}

  @override
  Future<void> requeueJob(String jobId, int attempts) async {}

  @override
  Future<void> logPlacement({
    required String workspaceId,
    required String jobId,
    required PlacementDecision decision,
    required DateTime now,
  }) async {
    placements.add(
      PlacementRecord(
        id: 'p-${placements.length}',
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
  ) async => placements
      .where((p) => p.workspaceId == workspaceId && p.jobId == jobId)
      .toList();

  @override
  Stream<List<PlacementRecord>> watchPlacementsForJob(
    String workspaceId,
    String jobId,
  ) => Stream.value(
    placements
        .where((p) => p.workspaceId == workspaceId && p.jobId == jobId)
        .toList(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Stub [FleetSchedulerService]: every operator/worker-facing method the ops
/// call is overridden to record its arguments so handlers can be tested without
/// the real scheduling loop. The base constructor is given a no-op resolver.
class _StubScheduler extends FleetSchedulerService {
  _StubScheduler(FleetRepository repo)
    : super(repository: repo, executorResolver: (_) => null, now: _fixedClock);

  static DateTime _fixedClock() => DateTime.utc(2026, 1, 1);

  final submits =
      <({String workspaceId, JobSpec spec, int priority, int maxAttempts})>[];
  final cancelledJobs = <({String workspaceId, String jobId})>[];
  final registered = <WorkerRegistration>[];
  final heartbeats =
      <({String workerId, int? protocolVersion, WorkerCapabilities? caps})>[];
  final drained = <String>[];
  final resumed = <String>[];
  final revoked = <String>[];
  final removed = <String>[];
  int _submitId = 0;

  @override
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
    submits.add((
      workspaceId: workspaceId,
      spec: spec,
      priority: priority,
      maxAttempts: maxAttempts,
    ));
    return 'job-${_submitId++}';
  }

  @override
  Future<void> cancelJob(String workspaceId, String jobId) async {
    cancelledJobs.add((workspaceId: workspaceId, jobId: jobId));
  }

  @override
  Future<String> registerWorker({
    required String workerId,
    required WorkerRegistration registration,
    String? registeredBy,
    String? pairedDeviceId,
    String? credentialRef,
  }) async {
    registered.add(registration);
    return workerId;
  }

  @override
  Future<void> recordHeartbeat(
    String workerId, {
    int? protocolVersion,
    WorkerCapabilities? caps,
  }) async {
    heartbeats.add((
      workerId: workerId,
      protocolVersion: protocolVersion,
      caps: caps,
    ));
  }

  @override
  Future<void> drainWorker(String workerId) async {
    drained.add(workerId);
  }

  @override
  Future<void> resumeWorker(String workerId) async {
    resumed.add(workerId);
  }

  @override
  Future<void> revokeWorker(String workerId) async {
    revoked.add(workerId);
  }

  @override
  Future<void> removeWorker(String workerId) async {
    removed.add(workerId);
  }
}

RepoOpContext _ctx(
  Map<String, dynamic> args, {
  String? workspaceId = 'ws-1',
  String deviceId = 'device-1',
  String userId = 'user-1',
}) => RepoOpContext(
  args: args,
  workspaceId: workspaceId,
  deviceId: deviceId,
  userId: userId,
);

WatchQueryContext _watchCtx(
  Map<String, dynamic> args, {
  String? workspaceId = 'ws-1',
}) => WatchQueryContext(
  args: args,
  workspaceId: workspaceId,
  deviceId: 'device-1',
  userId: 'user-1',
);

Worker _worker({
  String id = 'w-1',
  String name = 'node-1',
  WorkerStatus status = WorkerStatus.online,
  String? pairedDeviceId,
  DateTime? createdAt,
}) => Worker(
  id: id,
  name: name,
  capabilities: const WorkerCapabilities(
    os: 'linux',
    arch: 'x64',
    cores: 8,
    ramMb: 16384,
  ),
  status: status,
  protocolVersion: kFleetProtocolVersion,
  pairedDeviceId: pairedDeviceId,
  createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
);

void main() {
  group('fleet wire mappers', () {
    test('workerToWire serializes every field', () {
      final w = Worker(
        id: 'w-1',
        name: 'node-1',
        capabilities: const WorkerCapabilities(
          os: 'macos',
          arch: 'arm64',
          cores: 4,
          ramMb: 8192,
          hasFlutter: true,
        ),
        status: WorkerStatus.online,
        protocolVersion: 2,
        lastHeartbeatAt: DateTime.utc(2026, 1, 2),
        registeredBy: 'user-1',
        drainedAt: DateTime.utc(2026, 1, 3),
        revokedAt: DateTime.utc(2026, 1, 4),
        lastError: 'boom',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final wire = workerToWire(w);
      expect(wire['id'], 'w-1');
      expect(wire['name'], 'node-1');
      expect((wire['caps'] as Map)['os'], 'macos');
      expect(wire['capabilityKeys'], ['arm64', 'flutter', 'macos']);
      expect(wire['status'], 'online');
      expect(wire['protocolVersion'], 2);
      expect(wire['lastHeartbeatAt'], contains('2026-01-02'));
      expect(wire['registeredBy'], 'user-1');
      expect(wire['drainedAt'], contains('2026-01-03'));
      expect(wire['revokedAt'], contains('2026-01-04'));
      expect(wire['lastError'], 'boom');
      expect(wire['createdAt'], contains('2026-01-01'));
    });

    test('jobToWire and placementToWire serialize every field', () {
      final job = Job(
        id: 'j-1',
        workspaceId: 'ws-1',
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(agentId: 'a-1'),
        status: JobStatus.running,
        requiredCaps: const {'x64', 'linux'},
        preferredCaps: const {'flutter'},
        priority: 5,
        pinnedWorkerId: 'w-2',
        workerId: 'w-1',
        leaseExpiresAt: DateTime.utc(2026, 1, 5),
        costCents: 42,
        attempts: 1,
        maxAttempts: 3,
        error: 'nope',
        agentId: 'a-1',
        conversationId: 'c-1',
        createdAt: DateTime.utc(2026, 1, 1),
        startedAt: DateTime.utc(2026, 1, 2),
        finishedAt: DateTime.utc(2026, 1, 3),
      );
      final jobWire = jobToWire(job);
      expect(jobWire['id'], 'j-1');
      expect(jobWire['kind'], 'agentRun');
      expect(jobWire['status'], 'running');
      expect(jobWire['requiredCaps'], ['linux', 'x64']);
      expect(jobWire['preferredCaps'], ['flutter']);
      expect(jobWire['priority'], 5);
      expect(jobWire['pinnedWorkerId'], 'w-2');
      expect(jobWire['workerId'], 'w-1');
      expect(jobWire['costCents'], 42);
      expect(jobWire['attempts'], 1);
      expect(jobWire['maxAttempts'], 3);
      expect(jobWire['error'], 'nope');
      expect(jobWire['agentId'], 'a-1');
      expect(jobWire['conversationId'], 'c-1');

      final placement = PlacementRecord(
        id: 'p-1',
        workspaceId: 'ws-1',
        jobId: 'j-1',
        workerId: 'w-1',
        code: PlacementCode.spill,
        reason: 'spilled',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final pWire = placementToWire(placement);
      expect(pWire['id'], 'p-1');
      expect(pWire['jobId'], 'j-1');
      expect(pWire['workerId'], 'w-1');
      expect(pWire['decision'], 'spill');
      expect(pWire['reason'], 'spilled');
      expect(pWire['createdAt'], contains('2026-01-01'));
    });
  });

  group('buildFleetOperatorOps', () {
    late _FakeFleetRepository repo;
    late _StubScheduler scheduler;
    late List<RepoOp> ops;

    setUp(() {
      repo = _FakeFleetRepository();
      scheduler = _StubScheduler(repo);
      ops = buildFleetOperatorOps(scheduler: scheduler, fleetRepository: repo);
    });

    RepoOp op0(String name) {
      final op = ops.firstWhere((o) => o.name == name);
      const globalOps = {
        'fleet.workers',
        'fleet.drainWorker',
        'fleet.resumeWorker',
        'fleet.revokeWorker',
        'fleet.removeWorker',
      };
      expect(
        op.workspaceScoped,
        globalOps.contains(name) ? isFalse : isTrue,
        reason: '$name scoping',
      );
      return op;
    }

    test('the catalog declares the expected operator ops', () {
      expect(
        ops.map((o) => o.name),
        containsAll([
          'fleet.workers',
          'fleet.jobs',
          'fleet.submitJob',
          'fleet.cancelJob',
          'fleet.placements',
          'fleet.drainWorker',
          'fleet.resumeWorker',
          'fleet.revokeWorker',
          'fleet.removeWorker',
        ]),
      );
    });

    test('fleet.workers lists every worker', () async {
      repo.workers['w-1'] = _worker(id: 'w-1');
      repo.workers['w-2'] = _worker(id: 'w-2', name: 'node-2');
      final result = await op0('fleet.workers').handler(_ctx({}));
      expect(result['workers'] as List, hasLength(2));
      expect((result['workers'] as List).map((w) => (w as Map)['id']).toSet(), {
        'w-1',
        'w-2',
      });
    });

    test(
      'fleet.jobs lists every status when no status filter is given',
      () async {
        repo.jobs['j-1'] = Job(
          id: 'j-1',
          workspaceId: 'ws-1',
          kind: JobKind.agentRun,
          spec: const AgentRunJobSpec(agentId: 'a-1'),
          status: JobStatus.done,
          createdAt: DateTime.utc(2026, 1, 2),
        );
        repo.jobs['j-2'] = Job(
          id: 'j-2',
          workspaceId: 'ws-1',
          kind: JobKind.agentRun,
          spec: const AgentRunJobSpec(agentId: 'a-1'),
          status: JobStatus.queued,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        // A job in another workspace is excluded by the repository scoping.
        repo.jobs['j-other'] = Job(
          id: 'j-other',
          workspaceId: 'ws-other',
          kind: JobKind.agentRun,
          spec: const AgentRunJobSpec(agentId: 'a-1'),
          status: JobStatus.queued,
          createdAt: DateTime.utc(2026, 1, 1),
        );

        final result = await op0(
          'fleet.jobs',
        ).handler(_ctx({'workspace_id': 'ws-1'}));
        final ids = (result['jobs'] as List)
            .map((j) => (j as Map)['id'])
            .toList();
        expect(ids, ['j-1', 'j-2']);
      },
    );

    test('fleet.jobs filters by a status argument', () async {
      repo.jobs['j-1'] = Job(
        id: 'j-1',
        workspaceId: 'ws-1',
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(agentId: 'a-1'),
        status: JobStatus.done,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      repo.jobs['j-2'] = Job(
        id: 'j-2',
        workspaceId: 'ws-1',
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(agentId: 'a-1'),
        status: JobStatus.queued,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final result = await op0(
        'fleet.jobs',
      ).handler(_ctx({'workspace_id': 'ws-1', 'status': 'done'}));
      final ids = (result['jobs'] as List)
          .map((j) => (j as Map)['id'])
          .toList();
      expect(ids, ['j-1']);
    });

    test(
      'fleet.submitJob forwards the spec and defaults to the handler',
      () async {
        final result = await op0('fleet.submitJob').handler(
          _ctx({
            'workspace_id': 'ws-1',
            'kind': 'agentRun',
            'spec': {'agentId': 'a-1'},
            'priority': 7,
            'required_caps': ['linux'],
            'preferred_caps': ['flutter'],
            'max_attempts': 4,
          }),
        );

        expect(result['jobId'], 'job-0');
        expect(scheduler.submits, hasLength(1));
        expect(scheduler.submits.single.workspaceId, 'ws-1');
        expect(scheduler.submits.single.spec.kind, JobKind.agentRun);
        expect(scheduler.submits.single.priority, 7);
        expect(scheduler.submits.single.maxAttempts, 4);
      },
    );

    test('fleet.cancelJob delegates to the scheduler', () async {
      final result = await op0(
        'fleet.cancelJob',
      ).handler(_ctx({'workspace_id': 'ws-1', 'job_id': 'j-9'}));
      expect(result['ok'], isTrue);
      expect(scheduler.cancelledJobs.single.jobId, 'j-9');
      expect(scheduler.cancelledJobs.single.workspaceId, 'ws-1');
    });

    test('fleet.placements returns the placement log for a job', () async {
      await repo.logPlacement(
        workspaceId: 'ws-1',
        jobId: 'j-1',
        decision: const PlacementDecision(
          code: PlacementCode.spill,
          workerId: 'w-1',
          reason: 'spilled',
        ),
        now: DateTime.utc(2026, 1, 1),
      );
      final result = await op0(
        'fleet.placements',
      ).handler(_ctx({'workspace_id': 'ws-1', 'job_id': 'j-1'}));
      final placements = result['placements'] as List;
      expect(placements, hasLength(1));
      expect((placements.first as Map)['decision'], 'spill');
    });

    test('the worker lifecycle ops each delegate to the scheduler', () async {
      expect(
        await op0(
          'fleet.drainWorker',
        ).handler(_ctx({'worker_id': 'w-1'}, workspaceId: null)),
        {'ok': true},
      );
      expect(
        await op0(
          'fleet.resumeWorker',
        ).handler(_ctx({'worker_id': 'w-1'}, workspaceId: null)),
        {'ok': true},
      );
      expect(
        await op0(
          'fleet.revokeWorker',
        ).handler(_ctx({'worker_id': 'w-1'}, workspaceId: null)),
        {'ok': true},
      );
      expect(
        await op0(
          'fleet.removeWorker',
        ).handler(_ctx({'worker_id': 'w-1'}, workspaceId: null)),
        {'ok': true},
      );

      expect(scheduler.drained, ['w-1']);
      expect(scheduler.resumed, ['w-1']);
      expect(scheduler.revoked, ['w-1']);
      expect(scheduler.removed, ['w-1']);
    });
  });

  group('buildFleetWorkerOps', () {
    late _FakeFleetRepository repo;
    late _StubScheduler scheduler;
    late RemoteExecutionRegistry remoteRegistry;
    late List<RepoOp> ops;

    setUp(() {
      repo = _FakeFleetRepository();
      scheduler = _StubScheduler(repo);
      remoteRegistry = RemoteExecutionRegistry();
      ops = buildFleetWorkerOps(
        scheduler: scheduler,
        fleetRepository: repo,
        remoteRegistry: remoteRegistry,
      );
    });

    RepoOp op0(String name) => ops.firstWhere((o) => o.name == name);

    test('the catalog declares the expected worker ops', () {
      expect(
        ops.map((o) => o.name),
        containsAll([
          'fleet.registerWorker',
          'fleet.workerHeartbeat',
          'fleet.workerPoll',
          'fleet.workerEvents',
          'fleet.workerComplete',
        ]),
      );
      // Every worker op is a global mutate op.
      for (final op in ops) {
        expect(op.workspaceScoped, isFalse, reason: op.name);
      }
    });

    group('fleet.registerWorker', () {
      test('registers a new worker under the calling device', () async {
        final result = await op0('fleet.registerWorker').handler(
          _ctx({
            'registration': {
              'name': 'ci-1',
              'capsJson': '{"os":"linux","arch":"x64"}',
              'protocolVersion': kFleetProtocolVersion,
            },
            'worker_id': 'w-1',
          }, workspaceId: null),
        );

        expect(result['workerId'], 'w-1');
        expect(result['serverProtocolVersion'], kFleetProtocolVersion);
        expect(result['compatible'], isTrue);
        expect(scheduler.registered.single.name, 'ci-1');
      });

      test(
        'falls back to the device id when no worker id is supplied',
        () async {
          final result = await op0('fleet.registerWorker').handler(
            _ctx(
              {
                'registration': {
                  'name': 'ci-1',
                  'capsJson': '{}',
                  'protocolVersion': kFleetProtocolVersion,
                },
              },
              workspaceId: null,
              deviceId: 'device-7',
            ),
          );

          expect(result['workerId'], 'device-7');
        },
      );

      test('marks a protocol mismatch as incompatible', () async {
        final result = await op0('fleet.registerWorker').handler(
          _ctx({
            'registration': {
              'name': 'ci-1',
              'capsJson': '{}',
              'protocolVersion': 999,
            },
            'worker_id': 'w-1',
          }, workspaceId: null),
        );

        expect(result['compatible'], isFalse);
      });

      test(
        'refuses to re-register a worker another device already owns',
        () async {
          repo.workers['w-1'] = _worker(
            id: 'w-1',
            pairedDeviceId: 'device-owner',
          );
          await expectLater(
            op0('fleet.registerWorker').handler(
              _ctx(
                {
                  'registration': {
                    'name': 'ci-1',
                    'capsJson': '{}',
                    'protocolVersion': kFleetProtocolVersion,
                  },
                  'worker_id': 'w-1',
                },
                workspaceId: null,
                deviceId: 'device-hijack',
              ),
            ),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test('allows the owning device to re-register', () async {
        repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
        final result = await op0('fleet.registerWorker').handler(
          _ctx(
            {
              'registration': {
                'name': 'ci-1',
                'capsJson': '{}',
                'protocolVersion': kFleetProtocolVersion,
              },
              'worker_id': 'w-1',
            },
            workspaceId: null,
            deviceId: 'device-1',
          ),
        );
        expect(result['workerId'], 'w-1');
      });
    });

    group('fleet.workerHeartbeat', () {
      test(
        'records the heartbeat with capabilities and protocol version',
        () async {
          repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
          final result = await op0('fleet.workerHeartbeat').handler(
            _ctx({
              'worker_id': 'w-1',
              'protocol_version': kFleetProtocolVersion,
              'caps_json': '{"os":"linux","arch":"x64","cores":4}',
            }, workspaceId: null),
          );

          expect(result['ok'], isTrue);
          expect(scheduler.heartbeats.single.workerId, 'w-1');
          expect(
            scheduler.heartbeats.single.protocolVersion,
            kFleetProtocolVersion,
          );
          expect(scheduler.heartbeats.single.caps, isNotNull);
        },
      );

      test('records a heartbeat without capabilities', () async {
        repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
        await op0(
          'fleet.workerHeartbeat',
        ).handler(_ctx({'worker_id': 'w-1'}, workspaceId: null));
        expect(scheduler.heartbeats.single.caps, isNull);
      });

      test('rejects a device that does not own the worker', () async {
        repo.workers['w-1'] = _worker(
          id: 'w-1',
          pairedDeviceId: 'device-owner',
        );
        await expectLater(
          op0('fleet.workerHeartbeat').handler(
            _ctx(
              {'worker_id': 'w-1'},
              workspaceId: null,
              deviceId: 'device-other',
            ),
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('fleet.workerPoll', () {
      test(
        'offers leases for active jobs and skips ones already known',
        () async {
          repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
          repo.jobs['j-active'] = Job(
            id: 'j-active',
            workspaceId: 'ws-1',
            kind: JobKind.agentRun,
            spec: const AgentRunJobSpec(
              agentId: 'a-1',
              repoRemote: 'git@x',
              headSha: 'sha1',
            ),
            status: JobStatus.leased,
            workerId: 'w-1',
            leaseExpiresAt: DateTime.utc(2026, 1, 10),
            createdAt: DateTime.utc(2026, 1, 1),
          );
          repo.jobs['j-known'] = Job(
            id: 'j-known',
            workspaceId: 'ws-1',
            kind: JobKind.agentRun,
            spec: const AgentRunJobSpec(agentId: 'a-1'),
            status: JobStatus.running,
            workerId: 'w-1',
            createdAt: DateTime.utc(2026, 1, 1),
          );

          final result = await op0('fleet.workerPoll').handler(
            _ctx({
              'worker_id': 'w-1',
              'active_job_ids': ['j-known'],
            }, workspaceId: null),
          );

          final leases = result['leases'] as List;
          expect(leases, hasLength(1));
          final lease = leases.first as Map;
          expect(lease['jobId'], 'j-active');
          expect(lease['repoRemote'], 'git@x');
          expect(lease['headSha'], 'sha1');
          expect(lease['branch'], 'cc/job/j-active');
          // The already-known job is withheld.
          expect(
            leases.map((l) => (l as Map)['jobId']),
            isNot(contains('j-known')),
          );
        },
      );

      test('reports cancelled jobs the worker still thinks it runs', () async {
        repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
        repo.jobs['j-cancelled'] = Job(
          id: 'j-cancelled',
          workspaceId: 'ws-1',
          kind: JobKind.agentRun,
          spec: const AgentRunJobSpec(agentId: 'a-1'),
          status: JobStatus.cancelled,
          workerId: 'w-1',
          createdAt: DateTime.utc(2026, 1, 1),
        );

        final result = await op0('fleet.workerPoll').handler(
          _ctx({
            'worker_id': 'w-1',
            'active_job_ids': ['j-cancelled', 'j-missing'],
          }, workspaceId: null),
        );

        expect(result['cancelledJobIds'], ['j-cancelled', 'j-missing']);
        expect(result['leases'], isEmpty);
      });

      test(
        'mints job-scoped lease credentials when a minter is wired',
        () async {
          repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
          repo.jobs['j-cred'] = Job(
            id: 'j-cred',
            workspaceId: 'ws-1',
            kind: JobKind.codeIndex,
            spec: const CodeIndexJobSpec(
              repoId: 'r-1',
              repoRemote: 'git@x',
              headSha: 's',
            ),
            status: JobStatus.leased,
            workerId: 'w-1',
            leaseExpiresAt: DateTime.utc(2026, 1, 10),
            createdAt: DateTime.utc(2026, 1, 1),
          );

          final localOps = buildFleetWorkerOps(
            scheduler: scheduler,
            fleetRepository: repo,
            remoteRegistry: remoteRegistry,
            mintLeaseCredentials: (job) async => {'TOKEN': 'secret-${job.id}'},
          );
          final result = await localOps
              .firstWhere((o) => o.name == 'fleet.workerPoll')
              .handler(_ctx({'worker_id': 'w-1'}, workspaceId: null));

          final lease = (result['leases'] as List).single as Map;
          expect(lease['env'], {'TOKEN': 'secret-j-cred'});
          // The code-index spec carries repo metadata on the lease.
          expect(lease['repoRemote'], 'git@x');
          expect(lease['headSha'], 's');
        },
      );

      test('rejects a device that does not own the worker', () async {
        repo.workers['w-1'] = _worker(
          id: 'w-1',
          pairedDeviceId: 'device-owner',
        );
        await expectLater(
          op0('fleet.workerPoll').handler(
            _ctx(
              {'worker_id': 'w-1'},
              workspaceId: null,
              deviceId: 'device-other',
            ),
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test(
        'the lease offer carries repo metadata for a golden-render spec',
        () async {
          repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
          repo.jobs['j-golden'] = Job(
            id: 'j-golden',
            workspaceId: 'ws-1',
            kind: JobKind.goldenRender,
            spec: const GoldenRenderJobSpec(
              prNodeId: 'pr-1',
              repoId: 'r-1',
              repoRemote: 'git@g',
              headSha: 'shag',
            ),
            status: JobStatus.leased,
            workerId: 'w-1',
            leaseExpiresAt: DateTime.utc(2026, 1, 10),
            createdAt: DateTime.utc(2026, 1, 1),
          );
          final result = await op0(
            'fleet.workerPoll',
          ).handler(_ctx({'worker_id': 'w-1'}, workspaceId: null));
          final lease = (result['leases'] as List).single as Map;
          expect(lease['repoRemote'], 'git@g');
          expect(lease['headSha'], 'shag');
        },
      );
    });

    group('fleet.workerEvents', () {
      Map<String, dynamic> frame(String jobId, int seq, String content) => {
        'jobId': jobId,
        'seq': seq,
        'event': {
          'kind': 'text',
          'ts': '2026-01-01T00:00:00',
          'content': content,
        },
      };

      test('acks streamed frames and renews the lease', () async {
        // Register a pending execution so the registry can ack frames, and
        // bind it to a worker this device owns.
        repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
        repo.jobs['j-1'] = Job(
          id: 'j-1',
          workspaceId: 'ws-1',
          kind: JobKind.agentRun,
          spec: const AgentRunJobSpec(agentId: 'a-1'),
          status: JobStatus.running,
          workerId: 'w-1',
          createdAt: DateTime.utc(2026, 1, 1),
        );
        remoteRegistry.register(repo.jobs['j-1']!);

        final result = await op0('fleet.workerEvents').handler(
          _ctx({
            'frames': [frame('j-1', 1, 'hello'), frame('j-1', 2, 'world')],
          }, workspaceId: null),
        );

        expect(result['ackedSeq'], 2);
        expect(repo.renewLeaseCalls, ['j-1']);
      });

      test(
        'a missing frames argument acks zero and skips the lease renew',
        () async {
          final result = await op0(
            'fleet.workerEvents',
          ).handler(_ctx({}, workspaceId: null));
          expect(result['ackedSeq'], 0);
          expect(repo.renewLeaseCalls, isEmpty);
        },
      );

      test('rejects a device that does not own the job worker', () async {
        repo.workers['w-1'] = _worker(
          id: 'w-1',
          pairedDeviceId: 'device-owner',
        );
        repo.jobs['j-1'] = Job(
          id: 'j-1',
          workspaceId: 'ws-1',
          kind: JobKind.agentRun,
          spec: const AgentRunJobSpec(agentId: 'a-1'),
          status: JobStatus.running,
          workerId: 'w-1',
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await expectLater(
          op0('fleet.workerEvents').handler(
            _ctx(
              {
                'frames': [frame('j-1', 1, 'hello')],
              },
              workspaceId: null,
              deviceId: 'device-other',
            ),
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('fleet.workerComplete', () {
      test('completes a job the owning device reports', () async {
        repo.workers['w-1'] = _worker(id: 'w-1', pairedDeviceId: 'device-1');
        repo.jobs['j-1'] = Job(
          id: 'j-1',
          workspaceId: 'ws-1',
          kind: JobKind.agentRun,
          spec: const AgentRunJobSpec(agentId: 'a-1'),
          status: JobStatus.running,
          workerId: 'w-1',
          createdAt: DateTime.utc(2026, 1, 1),
        );
        remoteRegistry.register(repo.jobs['j-1']!);

        final result = await op0('fleet.workerComplete').handler(
          _ctx({
            'report': {
              'jobId': 'j-1',
              'success': true,
              'resultJson': '{}',
              'costCents': 9,
              'eventsLost': 0,
              'lastSeq': 5,
            },
          }, workspaceId: null),
        );

        expect(result['ok'], isTrue);
      });

      test('rejects a device that does not own the job worker', () async {
        repo.workers['w-1'] = _worker(
          id: 'w-1',
          pairedDeviceId: 'device-owner',
        );
        repo.jobs['j-1'] = Job(
          id: 'j-1',
          workspaceId: 'ws-1',
          kind: JobKind.agentRun,
          spec: const AgentRunJobSpec(agentId: 'a-1'),
          status: JobStatus.running,
          workerId: 'w-1',
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await expectLater(
          op0('fleet.workerComplete').handler(
            _ctx(
              {
                'report': {'jobId': 'j-1', 'success': true},
              },
              workspaceId: null,
              deviceId: 'device-other',
            ),
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });

  group('buildFleetWatchQueries', () {
    late _FakeFleetRepository repo;
    late List<WatchQuery> queries;

    setUp(() {
      repo = _FakeFleetRepository();
      queries = buildFleetWatchQueries(fleetRepository: repo);
    });

    WatchQuery query(String name) => queries.firstWhere((q) => q.name == name);

    test('fleet.watchWorkers emits a workers snapshot', () async {
      repo.workers['w-1'] = _worker(id: 'w-1');
      final snapshot = await query(
        'fleet.watchWorkers',
      ).handler(_watchCtx({}, workspaceId: null)).first;
      expect(snapshot['workers'] as List, hasLength(1));
    });

    test('fleet.watchJobs emits a jobs snapshot for the workspace', () async {
      repo.jobs['j-1'] = Job(
        id: 'j-1',
        workspaceId: 'ws-1',
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(agentId: 'a-1'),
        status: JobStatus.queued,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final snapshot = await query(
        'fleet.watchJobs',
      ).handler(_watchCtx({})).first;
      expect(snapshot['jobs'] as List, hasLength(1));
    });

    test('fleet.watchPlacements emits the placement log for a job', () async {
      await repo.logPlacement(
        workspaceId: 'ws-1',
        jobId: 'j-1',
        decision: const PlacementDecision(
          code: PlacementCode.pinned,
          workerId: 'w-1',
          reason: 'pinned',
        ),
        now: DateTime.utc(2026, 1, 1),
      );
      final snapshot = await query(
        'fleet.watchPlacements',
      ).handler(_watchCtx({'job_id': 'j-1'})).first;
      expect(snapshot['placements'] as List, hasLength(1));
    });

    test('fleet.watchPlacements defaults to an empty job id', () async {
      final snapshot = await query(
        'fleet.watchPlacements',
      ).handler(_watchCtx({})).first;
      expect(snapshot['placements'] as List, isEmpty);
    });
  });

  test('a TextEvent round-trips through the codec used by worker frames', () {
    // Sanity check that the wire shape the test builds matches the codec.
    final wire = AgentProcessEventCodec.toWire(TextEvent(content: 'hi'));
    final back = WorkerEventFrame.fromJson({
      'jobId': 'j-1',
      'seq': 1,
      'event': wire,
    });
    expect(back.event.content, 'hi');
    // The serialized frame is JSON-stable.
    expect(
      (jsonDecode(jsonEncode(back.toJson())) as Map<String, dynamic>)['jobId'],
      'j-1',
    );
  });
}
