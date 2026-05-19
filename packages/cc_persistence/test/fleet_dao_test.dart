import 'package:cc_persistence/database/global/global_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Drift stores [DateTime] in local time, so a UTC [DateTime] round-trips as
/// the same instant with `isUtc == false`. `DateTime.==` also compares
/// `isUtc`, so we compare instants instead.
Matcher sameInstant(DateTime expected) => predicate<DateTime>(
  (d) => d.toUtc() == expected.toUtc(),
  'is the same instant as $expected',
);

void main() {
  late GlobalDatabase db;
  // Fixed "now" so the lease-expiry math and ordering assertions are stable.
  final now = DateTime.utc(2026, 7, 13, 12);
  final soon = now.add(const Duration(minutes: 5));
  final later = now.add(const Duration(minutes: 10));
  // Distinct, increasing timestamps so createdAt ordering is deterministic
  // (Drift stores DateTime at second resolution).
  DateTime t(int i) => DateTime.utc(2026, 7, 13, 12, 0, i);

  setUp(() async {
    db = createTestGlobalDatabase();
    // Seed two workspaces so we can assert job/placement workspace isolation.
    for (final w in ['w-1', 'w-2']) {
      await db
          .into(db.workspacesTable)
          .insert(WorkspacesTableCompanion.insert(id: w, name: w));
    }
  });

  tearDown(() async {
    await db.close();
  });

  // Helper: insert one job (queued by default) into a workspace.
  Future<void> seedJob(
    String id,
    String ws, {
    String kind = 'agentRun',
    String status = 'queued',
    int priority = 0,
    int attempts = 0,
    String? workerId,
    DateTime? leaseExpiresAt,
    DateTime? createdAt,
  }) => db.fleetDao.upsertJob(
    JobsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      kind: kind,
      status: Value(status),
      priority: Value(priority),
      attempts: Value(attempts),
      workerId: workerId == null ? const Value.absent() : Value(workerId),
      leaseExpiresAt: leaseExpiresAt == null
          ? const Value.absent()
          : Value(leaseExpiresAt),
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    ),
  );

  group('FleetDao workers (CROSS-WORKSPACE BY DESIGN)', () {
    test('upsertWorker inserts then replaces on the same id', () async {
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(
          id: 'wk-1',
          name: 'mac-studio',
          status: const Value('online'),
        ),
      );
      expect(db.fleetDao.workerById('wk-1'), completion(isNotNull));

      // Upsert on the same PK id replaces the name.
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(
          id: 'wk-1',
          name: 'mac-studio-2',
          status: const Value('online'),
        ),
      );
      final row = await db.fleetDao.workerById('wk-1');
      expect(row?.name, 'mac-studio-2');
    });

    test('workerById returns null for an unknown worker', () async {
      expect(db.fleetDao.workerById('nope'), completion(isNull));
    });

    test('allWorkers returns rows ordered by name', () async {
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(id: 'wk-b', name: 'bravo'),
      );
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(id: 'wk-a', name: 'alpha'),
      );
      final rows = await db.fleetDao.allWorkers();
      expect(rows.map((w) => w.name), ['alpha', 'bravo']);
    });

    test('watchWorkers emits live updates', () async {
      final first = await db.fleetDao.watchWorkers().first;
      expect(first, isEmpty);
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(id: 'wk-1', name: 'alpha'),
      );
      final second = await db.fleetDao.watchWorkers().first;
      expect(second.single.id, 'wk-1');
    });

    test('recordHeartbeat stamps lastHeartbeatAt', () async {
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(id: 'wk-1', name: 'alpha'),
      );
      await db.fleetDao.recordHeartbeat('wk-1', now);
      final row = await db.fleetDao.workerById('wk-1');
      expect(row?.lastHeartbeatAt, sameInstant(now));
    });

    test('eligibleWorkers returns only online workers', () async {
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(
          id: 'wk-1',
          name: 'a',
          status: const Value('online'),
        ),
      );
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(
          id: 'wk-2',
          name: 'b',
          status: const Value('draining'),
        ),
      );
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(
          id: 'wk-3',
          name: 'c',
          status: const Value('offline'),
        ),
      );
      final rows = await db.fleetDao.eligibleWorkers();
      expect(rows.map((w) => w.id), ['wk-1']);
    });

    test(
      'setWorkerStatus drains and records drainedAt/revokedAt/lastError',
      () async {
        await db.fleetDao.upsertWorker(
          WorkersTableCompanion.insert(id: 'wk-1', name: 'a'),
        );
        await db.fleetDao.setWorkerStatus('wk-1', 'draining', drainedAt: now);
        var row = await db.fleetDao.workerById('wk-1');
        expect(row?.status, 'draining');
        expect(row?.drainedAt, sameInstant(now));

        await db.fleetDao.setWorkerStatus(
          'wk-1',
          'revoked',
          revokedAt: later,
          lastError: 'policy violation',
        );
        row = await db.fleetDao.workerById('wk-1');
        expect(row?.status, 'revoked');
        expect(row?.revokedAt, sameInstant(later));
        expect(row?.lastError, 'policy violation');
      },
    );

    test('deleteWorker removes the row', () async {
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(id: 'wk-1', name: 'a'),
      );
      await db.fleetDao.deleteWorker('wk-1');
      expect(db.fleetDao.workerById('wk-1'), completion(isNull));
    });
  });

  group('FleetDao jobs (workspace-scoped)', () {
    test('jobById returns the job within its workspace', () async {
      await seedJob('j-1', 'w-1');
      final row = await db.fleetDao.jobById('w-1', 'j-1');
      expect(row?.id, 'j-1');
      expect(row?.kind, 'agentRun');
      expect(row?.status, 'queued');
    });

    test('jobById does not surface a job from another workspace', () async {
      await seedJob('j-1', 'w-1');
      expect(db.fleetDao.jobById('w-2', 'j-1'), completion(isNull));
    });

    test('jobByIdGlobal finds the job regardless of workspace', () async {
      await seedJob('j-1', 'w-1');
      final row = await db.fleetDao.jobByIdGlobal('j-1');
      expect(row?.workspaceId, 'w-1');
    });

    test('upsertJob replaces on the same id', () async {
      await seedJob('j-1', 'w-1', kind: 'agentRun');
      await db.fleetDao.upsertJob(
        JobsTableCompanion.insert(
          id: 'j-1',
          workspaceId: 'w-1',
          kind: 'benchmark',
        ),
      );
      final row = await db.fleetDao.jobById('w-1', 'j-1');
      expect(row?.kind, 'benchmark');
    });

    test('jobsByStatus is workspace-scoped and newest-first', () async {
      await seedJob('j-old', 'w-1', status: 'done', createdAt: t(1));
      await seedJob('j-new', 'w-1', status: 'done', createdAt: t(2));
      // Same status in another workspace — must not leak.
      await seedJob('j-other', 'w-2', status: 'done', createdAt: t(3));
      final rows = await db.fleetDao.jobsByStatus('w-1', 'done');
      expect(rows.map((j) => j.id), ['j-new', 'j-old']);
    });

    test('watchJobs is workspace-scoped and emits live', () async {
      await seedJob('j-1', 'w-1', createdAt: t(1));
      await seedJob('j-2', 'w-1', createdAt: t(2));
      // A job in another workspace must not appear.
      await seedJob('j-other', 'w-2', createdAt: t(3));
      final rows = await db.fleetDao.watchJobs('w-1').first;
      expect(rows.map((j) => j.id), ['j-2', 'j-1']);
    });
  });

  group('FleetDao scheduler queries (CROSS-WORKSPACE BY DESIGN)', () {
    test(
      'queuedJobsGlobal orders by priority desc then createdAt asc',
      () async {
        // Across both workspaces. Priority 5 group first; ties break FIFO
        // (createdAt asc), then the lower-priority job.
        await seedJob('j-high', 'w-2', priority: 5, createdAt: t(1));
        await seedJob('j-mid', 'w-1', priority: 5, createdAt: t(2));
        await seedJob('j-low', 'w-1', priority: 1, createdAt: t(3));
        final rows = await db.fleetDao.queuedJobsGlobal();
        expect(rows.map((j) => j.id), ['j-high', 'j-mid', 'j-low']);
      },
    );

    test('queuedJobsGlobal ignores non-queued jobs', () async {
      await seedJob('j-1', 'w-1', status: 'leased');
      await seedJob('j-2', 'w-1', status: 'running');
      await seedJob('j-3', 'w-1', status: 'done');
      expect(db.fleetDao.queuedJobsGlobal(), completion(isEmpty));
    });

    test(
      'expiredLeasedJobs returns leased/running jobs past their expiry',
      () async {
        await seedJob(
          'j-dead',
          'w-1',
          status: 'leased',
          leaseExpiresAt: now.subtract(const Duration(minutes: 1)),
        );
        await seedJob(
          'j-running-dead',
          'w-1',
          status: 'running',
          leaseExpiresAt: now.subtract(const Duration(minutes: 1)),
        );
        await seedJob(
          'j-alive',
          'w-1',
          status: 'leased',
          leaseExpiresAt: later,
        );
        await seedJob('j-queued', 'w-1', status: 'queued');
        final rows = await db.fleetDao.expiredLeasedJobs(later);
        expect(
          rows.map((j) => j.id),
          containsAll(['j-dead', 'j-running-dead']),
        );
        expect(rows.any((j) => j.id == 'j-alive'), isFalse);
        expect(rows.any((j) => j.id == 'j-queued'), isFalse);
      },
    );

    test(
      'activeJobsForWorker returns leased/running jobs for that worker',
      () async {
        await seedJob('j-1', 'w-1', status: 'leased', workerId: 'wk-1');
        await seedJob('j-2', 'w-2', status: 'running', workerId: 'wk-1');
        await seedJob('j-3', 'w-1', status: 'queued', workerId: 'wk-1');
        await seedJob('j-4', 'w-1', status: 'leased', workerId: 'wk-2');
        final rows = await db.fleetDao.activeJobsForWorker('wk-1');
        expect(rows.map((j) => j.id).toSet(), {'j-1', 'j-2'});
      },
    );
  });

  group('FleetDao lease lifecycle', () {
    test(
      'tryLeaseJob succeeds on a queued job and stamps lease fields',
      () async {
        await seedJob('j-1', 'w-1');
        final ok = await db.fleetDao.tryLeaseJob('j-1', 'wk-1', soon, now);
        expect(ok, isTrue);
        final row = await db.fleetDao.jobByIdGlobal('j-1');
        expect(row?.status, 'leased');
        expect(row?.workerId, 'wk-1');
        expect(row?.leaseExpiresAt, sameInstant(soon));
        expect(row?.leasedAt, sameInstant(now));
      },
    );

    test(
      'tryLeaseJob returns false (CAS conflict) when the job is not queued',
      () async {
        await seedJob('j-1', 'w-1', status: 'leased');
        final ok = await db.fleetDao.tryLeaseJob('j-1', 'wk-1', soon, now);
        expect(ok, isFalse);
        // No mutation on conflict: the seeded leased job had no workerId.
        final row = await db.fleetDao.jobByIdGlobal('j-1');
        expect(row?.workerId, isNull);
      },
    );

    test('renewLease extends the expiry on an active job', () async {
      await seedJob('j-1', 'w-1');
      await db.fleetDao.tryLeaseJob('j-1', 'wk-1', soon, now);
      await db.fleetDao.renewLease('j-1', later, lastAckedSeq: 7);
      final row = await db.fleetDao.jobByIdGlobal('j-1');
      expect(row?.leaseExpiresAt, sameInstant(later));
      expect(row?.lastAckedSeq, 7);
    });

    test('renewLease is a no-op on a terminal job', () async {
      await seedJob('j-1', 'w-1', status: 'done');
      await db.fleetDao.renewLease('j-1', later);
      final row = await db.fleetDao.jobByIdGlobal('j-1');
      expect(row?.leaseExpiresAt, isNull);
    });

    test('markJobRunning stamps startedAt and status=running', () async {
      await seedJob('j-1', 'w-1');
      await db.fleetDao.tryLeaseJob('j-1', 'wk-1', soon, now);
      await db.fleetDao.markJobRunning('j-1', now);
      final row = await db.fleetDao.jobByIdGlobal('j-1');
      expect(row?.status, 'running');
      expect(row?.startedAt, sameInstant(now));
    });

    test(
      'markJobTerminal clears the lease and records result/error/cost',
      () async {
        await seedJob('j-1', 'w-1');
        await db.fleetDao.tryLeaseJob('j-1', 'wk-1', soon, now);
        await db.fleetDao.markJobTerminal(
          'j-1',
          'done',
          now,
          resultJson: '{"branch":"main"}',
          costCents: 42,
        );
        final row = await db.fleetDao.jobByIdGlobal('j-1');
        expect(row?.status, 'done');
        expect(row?.finishedAt, sameInstant(now));
        // `markJobTerminal` passes `workerId: Value.absent()` (leaves the
        // assignment alone) but `leaseExpiresAt: Value(null)` (clears the lease).
        expect(row?.leaseExpiresAt, isNull);
        expect(row?.resultJson, '{"branch":"main"}');
        expect(row?.costCents, 42);
      },
    );

    test('markJobTerminal records the error on failure', () async {
      await seedJob('j-1', 'w-1');
      await db.fleetDao.markJobTerminal('j-1', 'failed', now, error: 'boom');
      final row = await db.fleetDao.jobByIdGlobal('j-1');
      expect(row?.status, 'failed');
      expect(row?.error, 'boom');
    });

    test(
      'requeueJob moves a reaped job back to queued with incremented attempts',
      () async {
        await seedJob('j-1', 'w-1', status: 'leased', workerId: 'wk-1');
        await db.fleetDao.requeueJob('j-1', 2);
        final row = await db.fleetDao.jobByIdGlobal('j-1');
        expect(row?.status, 'queued');
        expect(row?.workerId, isNull);
        expect(row?.leaseExpiresAt, isNull);
        expect(row?.attempts, 2);
      },
    );
  });

  group('FleetDao placement log (workspace-scoped)', () {
    Future<void> log(
      String id,
      String ws,
      String jobId, {
      String? workerId,
      String decision = 'queued',
      String reason = '',
      DateTime? createdAt,
    }) => db.fleetDao.logPlacement(
      PlacementLogTableCompanion.insert(
        id: id,
        workspaceId: ws,
        jobId: jobId,
        workerId: workerId == null ? const Value.absent() : Value(workerId),
        decision: Value(decision),
        reason: Value(reason),
        createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
      ),
    );

    test(
      'placementsForJob returns decisions newest-first, workspace-scoped',
      () async {
        await log('p-1', 'w-1', 'j-1', decision: 'queued', createdAt: t(1));
        await log(
          'p-2',
          'w-1',
          'j-1',
          workerId: 'wk-1',
          decision: 'preferred',
          createdAt: t(2),
        );
        // A decision for the same job id in another workspace must not leak.
        await log('p-3', 'w-2', 'j-1', decision: 'spill', createdAt: t(3));
        final rows = await db.fleetDao.placementsForJob('w-1', 'j-1');
        expect(rows.map((p) => p.id), ['p-2', 'p-1']);
      },
    );

    test(
      'placementsForJob stays scoped — foreign workspace sees nothing',
      () async {
        await log('p-1', 'w-1', 'j-1');
        expect(db.fleetDao.placementsForJob('w-2', 'j-1'), completion(isEmpty));
      },
    );

    test('watchPlacementsForJob emits live and workspace-scoped', () async {
      await log('p-1', 'w-1', 'j-1', decision: 'queued');
      await log('p-2', 'w-2', 'j-1', decision: 'spill');
      final rows = await db.fleetDao.watchPlacementsForJob('w-1', 'j-1').first;
      expect(rows.single.id, 'p-1');
    });

    test('logPlacement stores workerId/decision/reason verbatim', () async {
      await log(
        'p-1',
        'w-1',
        'j-1',
        workerId: 'wk-1',
        decision: 'preferred',
        reason: 'had flutter',
      );
      final rows = await db.fleetDao.placementsForJob('w-1', 'j-1');
      expect(rows.single.workerId, 'wk-1');
      expect(rows.single.decision, 'preferred');
      expect(rows.single.reason, 'had flutter');
    });
  });

  group('FleetDao workspace isolation', () {
    test(
      'a job in w-2 is invisible to w-1 queries across all job reads',
      () async {
        await seedJob('j-1', 'w-2', status: 'queued');
        expect(db.fleetDao.jobById('w-1', 'j-1'), completion(isNull));
        expect(db.fleetDao.jobsByStatus('w-1', 'queued'), completion(isEmpty));
        expect(db.fleetDao.watchJobs('w-1').first, completion(isEmpty));
      },
    );

    test('workers are NOT workspace-scoped (global by design)', () async {
      // Workers carry no workspaceId; reads return them regardless of any
      // workspace context (there is none to pass).
      await db.fleetDao.upsertWorker(
        WorkersTableCompanion.insert(id: 'wk-1', name: 'alpha'),
      );
      final all = await db.fleetDao.allWorkers();
      final byId = await db.fleetDao.workerById('wk-1');
      final eligible = await db.fleetDao.eligibleWorkers();
      expect(all.single.id, 'wk-1');
      expect(byId?.id, 'wk-1');
      expect(eligible, isEmpty); // default status is 'offline', not 'online'
    });
  });
}
