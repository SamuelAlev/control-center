import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/repositories/dao_fleet_repository.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Drift stores [DateTime] in local time, so a UTC [DateTime] round-trips as
/// the same instant with `isUtc == false`. Compare instants instead of values.
Matcher sameInstant(DateTime expected) => predicate<DateTime>(
  (d) => d.toUtc() == expected.toUtc(),
  'is the same instant as $expected',
);

/// Exercises [DaoFleetRepository] against the real Drift database. The
/// repository is a thin mapper+delegate layer over the fleet DAO; these tests
/// assert the round-trip through the domain entities, the global vs
/// workspace-scoped read invariants, and the lease lifecycle.
void main() {
  late GlobalDatabase db;
  late DaoFleetRepository repo;

  // Fixed "now" so lease-expiry math and ordering assertions are stable.
  final now = DateTime.utc(2026, 7, 13, 12);
  final soon = now.add(const Duration(minutes: 5));
  final later = now.add(const Duration(minutes: 10));

  setUp(() async {
    db = createTestGlobalDatabase();
    repo = DaoFleetRepository(db.fleetDao);
    // Seed two workspaces so we can assert job/placement workspace isolation.
    for (final w in ['w-1', 'w-2']) {
      await db
          .into(db.workspacesTable)
          .insert(WorkspacesTableCompanion.insert(id: w, name: w));
    }
  });

  tearDown(() async => db.close());

  // Convenience constructors over the domain entities.
  Worker worker(
    String id, {
    String name = 'box',
    WorkerStatus status = WorkerStatus.online,
    String os = 'macos',
  }) => Worker(
    id: id,
    name: name,
    capabilities: WorkerCapabilities(
      os: os,
      arch: 'arm64',
      cores: 8,
      ramMb: 16384,
      hasFlutter: true,
    ),
    status: status,
    protocolVersion: 1,
    createdAt: now,
  );

  Job job(
    String id,
    String ws, {
    JobKind kind = JobKind.agentRun,
    JobStatus status = JobStatus.queued,
    int priority = 0,
    int attempts = 0,
    String? workerId,
    DateTime? leaseExpiresAt,
  }) => Job(
    id: id,
    workspaceId: ws,
    kind: kind,
    spec: const AgentRunJobSpec(agentId: 'a-1'),
    status: status,
    priority: priority,
    attempts: attempts,
    workerId: workerId,
    leaseExpiresAt: leaseExpiresAt,
    createdAt: now,
  );

  group('DaoFleetRepository workers (global)', () {
    test('upsertWorker + workerById round-trips the entity', () async {
      await repo.upsertWorker(worker('wk-1', name: 'mac-studio'));
      final w = await repo.workerById('wk-1');
      expect(w, isNotNull);
      expect(w!.name, 'mac-studio');
      expect(w.status, WorkerStatus.online);
      expect(w.capabilities.os, 'macos');
    });

    test('workerById returns null for an unknown worker', () async {
      expect(await repo.workerById('nope'), isNull);
    });

    test('allWorkers returns rows across the whole fleet', () async {
      await repo.upsertWorker(worker('wk-a', name: 'alpha'));
      await repo.upsertWorker(worker('wk-b', name: 'bravo'));
      expect((await repo.allWorkers()).map((w) => w.name), ['alpha', 'bravo']);
    });

    test('watchWorkers emits live updates', () async {
      expect(await repo.watchWorkers().first, isEmpty);
      await repo.upsertWorker(worker('wk-1'));
      expect((await repo.watchWorkers().first).single.id, 'wk-1');
    });

    test('eligibleWorkers returns only online workers', () async {
      await repo.upsertWorker(worker('wk-1', status: WorkerStatus.online));
      await repo.upsertWorker(worker('wk-2', status: WorkerStatus.draining));
      expect((await repo.eligibleWorkers()).single.id, 'wk-1');
    });

    test('recordHeartbeat stamps lastHeartbeatAt', () async {
      await repo.upsertWorker(worker('wk-1'));
      await repo.recordHeartbeat('wk-1', now);
      expect(
        (await repo.workerById('wk-1'))!.lastHeartbeatAt,
        sameInstant(now),
      );
    });

    test('deleteWorker removes the row', () async {
      await repo.upsertWorker(worker('wk-1'));
      await repo.deleteWorker('wk-1');
      expect(await repo.workerById('wk-1'), isNull);
    });
  });

  group('DaoFleetRepository jobs (workspace-scoped)', () {
    test('upsertJob + jobById round-trips the entity', () async {
      await repo.upsertJob(job('j-1', 'w-1'));
      final j = await repo.jobById('w-1', 'j-1');
      expect(j, isNotNull);
      expect(j!.id, 'j-1');
      expect(j.kind, JobKind.agentRun);
      expect(j.status, JobStatus.queued);
    });

    test('jobById does not surface a job from another workspace', () async {
      await repo.upsertJob(job('j-1', 'w-1'));
      expect(await repo.jobById('w-2', 'j-1'), isNull);
    });

    test('jobByIdGlobal finds the job regardless of workspace', () async {
      await repo.upsertJob(job('j-1', 'w-1'));
      expect((await repo.jobByIdGlobal('j-1'))?.workspaceId, 'w-1');
    });

    test('jobsByStatus is workspace-scoped', () async {
      await repo.upsertJob(job('j-1', 'w-1', status: JobStatus.done));
      await repo.upsertJob(job('j-2', 'w-2', status: JobStatus.done));
      expect((await repo.jobsByStatus('w-1', JobStatus.done)).single.id, 'j-1');
    });

    test('watchJobs emits only the workspace rows', () async {
      await repo.upsertJob(job('j-1', 'w-1'));
      await repo.upsertJob(job('j-2', 'w-2'));
      expect((await repo.watchJobs('w-1').first).single.id, 'j-1');
    });

    test('queuedJobsGlobal spans workspaces, priority then FIFO', () async {
      await repo.upsertJob(job('j-low', 'w-1', priority: 1));
      await repo.upsertJob(job('j-high', 'w-2', priority: 5));
      expect((await repo.queuedJobsGlobal()).map((j) => j.id), [
        'j-high',
        'j-low',
      ]);
    });

    test('expiredLeasedJobs returns leased jobs past their expiry', () async {
      await repo.upsertJob(
        job(
          'j-dead',
          'w-1',
          status: JobStatus.leased,
          leaseExpiresAt: now.subtract(const Duration(minutes: 1)),
        ),
      );
      await repo.upsertJob(
        job('j-alive', 'w-1', status: JobStatus.leased, leaseExpiresAt: later),
      );
      expect(
        (await repo.expiredLeasedJobs(later)).map((j) => j.id).single,
        'j-dead',
      );
    });

    test(
      'activeJobsForWorker returns leased/running jobs for that worker',
      () async {
        await repo.upsertJob(
          job('j-1', 'w-1', status: JobStatus.leased, workerId: 'wk-1'),
        );
        await repo.upsertJob(
          job('j-2', 'w-2', status: JobStatus.running, workerId: 'wk-1'),
        );
        expect(
          (await repo.activeJobsForWorker('wk-1')).map((j) => j.id).toSet(),
          {'j-1', 'j-2'},
        );
      },
    );
  });

  group('DaoFleetRepository lease lifecycle', () {
    test(
      'tryLeaseJob succeeds on a queued job and stamps lease fields',
      () async {
        await repo.upsertJob(job('j-1', 'w-1'));
        final ok = await repo.tryLeaseJob('j-1', 'wk-1', soon, now);
        expect(ok, isTrue);
        final j = await repo.jobByIdGlobal('j-1');
        expect(j!.status, JobStatus.leased);
        expect(j.workerId, 'wk-1');
        expect(j.leaseExpiresAt, sameInstant(soon));
      },
    );

    test('tryLeaseJob returns false when the job is not queued', () async {
      await repo.upsertJob(job('j-1', 'w-1', status: JobStatus.leased));
      expect(await repo.tryLeaseJob('j-1', 'wk-1', soon, now), isFalse);
    });

    test('renewLease extends the expiry', () async {
      await repo.upsertJob(job('j-1', 'w-1'));
      await repo.tryLeaseJob('j-1', 'wk-1', soon, now);
      await repo.renewLease('j-1', later, lastAckedSeq: 9);
      final j = await repo.jobByIdGlobal('j-1');
      expect(j!.leaseExpiresAt, sameInstant(later));
      expect(j.lastAckedSeq, 9);
    });

    test('markJobRunning stamps startedAt', () async {
      await repo.upsertJob(job('j-1', 'w-1'));
      await repo.tryLeaseJob('j-1', 'wk-1', soon, now);
      await repo.markJobRunning('j-1', now);
      expect((await repo.jobByIdGlobal('j-1'))!.status, JobStatus.running);
    });

    test('markJobTerminal clears the lease and records result/cost', () async {
      await repo.upsertJob(job('j-1', 'w-1'));
      await repo.tryLeaseJob('j-1', 'wk-1', soon, now);
      await repo.markJobTerminal(
        'j-1',
        JobStatus.done,
        now,
        resultJson: '{"branch": "main"}',
        costCents: 42,
      );
      final j = await repo.jobByIdGlobal('j-1');
      expect(j!.status, JobStatus.done);
      expect(j.leaseExpiresAt, isNull);
      expect(j.resultJson, '{"branch": "main"}');
      expect(j.costCents, 42);
    });

    test('markJobTerminal records the error on failure', () async {
      await repo.upsertJob(job('j-1', 'w-1'));
      await repo.markJobTerminal('j-1', JobStatus.failed, now, error: 'boom');
      expect((await repo.jobByIdGlobal('j-1'))!.error, 'boom');
    });

    test('requeueJob moves a reaped job back to queued', () async {
      await repo.upsertJob(
        job('j-1', 'w-1', status: JobStatus.leased, workerId: 'wk-1'),
      );
      await repo.requeueJob('j-1', 2);
      final j = await repo.jobByIdGlobal('j-1');
      expect(j!.status, JobStatus.queued);
      expect(j.workerId, isNull);
      expect(j.attempts, 2);
    });
  });

  group('DaoFleetRepository placement log (workspace-scoped)', () {
    test('logPlacement + placementsForJob round-trips the decision', () async {
      await repo.logPlacement(
        workspaceId: 'w-1',
        jobId: 'j-1',
        decision: const PlacementDecision(
          code: PlacementCode.preferred,
          workerId: 'wk-1',
          reason: 'matched flutter',
        ),
        now: now,
      );
      final rows = await repo.placementsForJob('w-1', 'j-1');
      expect(rows.single.workerId, 'wk-1');
      expect(rows.single.code, PlacementCode.preferred);
      expect(rows.single.reason, 'matched flutter');
    });

    test('placementsForJob is workspace-scoped', () async {
      await repo.logPlacement(
        workspaceId: 'w-1',
        jobId: 'j-1',
        decision: const PlacementDecision.queued('none free'),
        now: now,
      );
      await repo.logPlacement(
        workspaceId: 'w-2',
        jobId: 'j-1',
        decision: const PlacementDecision(
          code: PlacementCode.spill,
          workerId: 'wk-2',
          reason: 'overflow',
        ),
        now: now,
      );
      expect(
        (await repo.placementsForJob('w-1', 'j-1')).single.code,
        PlacementCode.queued,
      );
      expect(
        (await repo.placementsForJob('w-2', 'j-1')).single.code,
        PlacementCode.spill,
      );
    });

    test('watchPlacementsForJob emits only the workspace rows', () async {
      await repo.logPlacement(
        workspaceId: 'w-1',
        jobId: 'j-1',
        decision: const PlacementDecision.queued('none'),
        now: now,
      );
      await repo.logPlacement(
        workspaceId: 'w-2',
        jobId: 'j-1',
        decision: const PlacementDecision.queued('none'),
        now: now,
      );
      expect(
        (await repo.watchPlacementsForJob('w-1', 'j-1').first)
            .single
            .workspaceId,
        'w-1',
      );
    });

    test('placementsForJob returns empty for a foreign workspace', () async {
      await repo.logPlacement(
        workspaceId: 'w-1',
        jobId: 'j-1',
        decision: const PlacementDecision.queued('none'),
        now: now,
      );
      expect(await repo.placementsForJob('w-2', 'j-1'), isEmpty);
    });
  });
}
