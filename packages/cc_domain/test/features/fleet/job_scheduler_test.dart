import 'dart:math';

import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/services/job_scheduler.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:test/test.dart';

/// Builds a worker with sensible scheduling defaults (online, macOS/arm64).
///
/// Only the fields the scheduler reads (id, name, capability keys, status) vary;
/// everything else is fixed so the fleet is fully determined by the arguments.
Worker _worker(
  String id, {
  bool flutter = false,
  bool ml = false,
  WorkerStatus status = WorkerStatus.online,
}) {
  return Worker(
    id: id,
    name: 'worker-$id',
    capabilities: WorkerCapabilities(
      os: FleetCaps.macos,
      arch: FleetCaps.arm64,
      cores: 8,
      ramMb: 16000,
      hasFlutter: flutter,
      hasMl: ml,
    ),
    status: status,
    createdAt: DateTime(2026),
  );
}

/// Builds a queued job with an [AgentRunJobSpec] default, overridable spec and
/// pin/capability routing knobs.
Job _job({
  String? pin,
  Set<String> requiredCaps = const {},
  Set<String> preferredCaps = const {},
  JobSpec spec = const AgentRunJobSpec(agentId: 'a'),
}) {
  return Job(
    id: 'job-1',
    workspaceId: 'ws-1',
    kind: spec.kind,
    spec: spec,
    status: JobStatus.queued,
    requiredCaps: requiredCaps,
    preferredCaps: preferredCaps,
    pinnedWorkerId: pin,
    createdAt: DateTime(2026),
  );
}

void main() {
  const scheduler = JobScheduler();

  group('determinism', () {
    test('same job + same snapshot yields an identical decision', () {
      final snapshot = FleetSnapshot(
        workers: [_worker('w1', flutter: true), _worker('w2', flutter: true)],
      );
      final job = _job(requiredCaps: {FleetCaps.flutter});

      final first = scheduler.place(job, snapshot);
      for (var i = 0; i < 10; i++) {
        expect(scheduler.place(job, snapshot), first);
      }
    });

    test('decision is stable regardless of worker list order (ties break '
        'on the lexicographically smaller worker id)', () {
      final workers = [
        _worker('w3', flutter: true),
        _worker('w1', flutter: true),
        _worker('w4', flutter: true),
        _worker('w2', flutter: true),
      ];
      final job = _job(requiredCaps: {FleetCaps.flutter});

      final ordered = scheduler.place(job, FleetSnapshot(workers: workers));
      // All four qualify, tie on score → smallest id wins.
      expect(ordered.workerId, 'w1');

      for (var seed = 0; seed < 25; seed++) {
        final shuffled = [...workers]..shuffle(Random(seed));
        final decision = scheduler.place(job, FleetSnapshot(workers: shuffled));
        expect(decision, ordered);
        expect(decision.workerId, 'w1');
      }
    });
  });

  group('capability routing', () {
    final goldenJob = _job(
      requiredCaps: {FleetCaps.flutter},
      spec: const GoldenRenderJobSpec(prExternalId: 'pr-1', repoId: 'repo-1'),
    );

    test('golden render lands on the flutter-capable worker, not the VPS', () {
      final snapshot = FleetSnapshot(
        workers: [_worker('workstation', flutter: true), _worker('vps')],
      );

      final decision = scheduler.place(goldenJob, snapshot);

      expect(decision.workerId, 'workstation');
      expect(
        decision.code,
        anyOf(PlacementCode.preferred, PlacementCode.spill),
      );
      expect(decision.placed, isTrue);
      expect(decision.reason, contains('worker-workstation'));
    });

    test('no flutter worker anywhere → noCapableWorker naming the cap', () {
      final snapshot = FleetSnapshot(
        workers: [_worker('vps-a'), _worker('vps-b')],
      );

      final decision = scheduler.place(goldenJob, snapshot);

      expect(decision.code, PlacementCode.noCapableWorker);
      expect(decision.placed, isFalse);
      expect(decision.workerId, isNull);
      expect(decision.reason, contains(FleetCaps.flutter));
    });
  });

  group('pinned', () {
    test('places on the pinned worker even when another is free', () {
      final snapshot = FleetSnapshot(workers: [_worker('w1'), _worker('w2')]);

      final decision = scheduler.place(_job(pin: 'w2'), snapshot);

      expect(decision.code, PlacementCode.pinned);
      expect(decision.workerId, 'w2');
      expect(decision.reason, contains('worker-w2'));
    });

    test('pinned to an offline worker → queued pinnedWorkerUnavailable', () {
      final snapshot = FleetSnapshot(
        workers: [
          _worker('w1'),
          _worker('w2', status: WorkerStatus.offline),
        ],
      );

      final decision = scheduler.place(_job(pin: 'w2'), snapshot);

      expect(decision.code, PlacementCode.pinnedWorkerUnavailable);
      expect(decision.placed, isFalse);
      expect(decision.workerId, isNull);
    });

    test(
      'pinned to a worker lacking a required cap → pinnedWorkerUnavailable',
      () {
        final snapshot = FleetSnapshot(
          workers: [_worker('w1'), _worker('w2', flutter: true)],
        );

        // w1 is online but has no flutter; pinning there cannot satisfy the job.
        final decision = scheduler.place(
          _job(pin: 'w1', requiredCaps: {FleetCaps.flutter}),
          snapshot,
        );

        expect(decision.code, PlacementCode.pinnedWorkerUnavailable);
        expect(decision.placed, isFalse);
        expect(decision.reason, contains(FleetCaps.flutter));
      },
    );
  });

  group('prefer over spill', () {
    test('a worker satisfying preferredCaps wins with code preferred', () {
      final snapshot = FleetSnapshot(
        workers: [
          _worker('w1', flutter: true),
          _worker('w2', flutter: true, ml: true),
        ],
      );

      final decision = scheduler.place(
        _job(requiredCaps: {FleetCaps.flutter}, preferredCaps: {FleetCaps.ml}),
        snapshot,
      );

      expect(decision.code, PlacementCode.preferred);
      expect(decision.workerId, 'w2');
      expect(decision.reason, contains(FleetCaps.ml));
    });

    test('when none satisfy preferred, code is spill', () {
      final snapshot = FleetSnapshot(
        workers: [_worker('w1', flutter: true), _worker('w2', flutter: true)],
      );

      final decision = scheduler.place(
        _job(requiredCaps: {FleetCaps.flutter}, preferredCaps: {FleetCaps.ml}),
        snapshot,
      );

      expect(decision.code, PlacementCode.spill);
      expect(decision.placed, isTrue);
      // Tie on score → smallest id.
      expect(decision.workerId, 'w1');
    });
  });

  group('all busy', () {
    test(
      'capable workers exist but all busy → queued, reason mentions busy',
      () {
        final snapshot = FleetSnapshot(
          workers: [_worker('w1', flutter: true), _worker('w2', flutter: true)],
          busyWorkerIds: {'w1', 'w2'},
        );

        final decision = scheduler.place(
          _job(requiredCaps: {FleetCaps.flutter}),
          snapshot,
        );

        expect(decision.code, PlacementCode.queued);
        expect(decision.placed, isFalse);
        expect(decision.workerId, isNull);
        expect(decision.reason, contains('busy'));
      },
    );
  });

  group('cache note', () {
    test('a cold chosen worker mentions warming repo cache', () {
      final snapshot = FleetSnapshot(workers: [_worker('w1', flutter: true)]);

      final decision = scheduler.place(
        _job(requiredCaps: {FleetCaps.flutter}),
        snapshot,
      );

      expect(decision.workerId, 'w1');
      expect(decision.reason, contains('warming repo cache'));
    });

    test('a cache-warm chosen worker omits the warming note', () {
      final snapshot = FleetSnapshot(
        workers: [_worker('w1', flutter: true)],
        cacheWarmWorkerIds: {'w1'},
      );

      final decision = scheduler.place(
        _job(requiredCaps: {FleetCaps.flutter}),
        snapshot,
      );

      expect(decision.workerId, 'w1');
      expect(decision.reason, isNot(contains('warming repo cache')));
    });
  });

  group('non-schedulable workers', () {
    test(
      'a draining worker holding the only capability leaves the job queued',
      () {
        final snapshot = FleetSnapshot(
          workers: [
            _worker('w1', flutter: true, status: WorkerStatus.draining),
          ],
        );

        final decision = scheduler.place(
          _job(requiredCaps: {FleetCaps.flutter}),
          snapshot,
        );

        expect(decision.placed, isFalse);
        expect(decision.workerId, isNull);
        // The cap exists in the fleet, so it is "none online", not "no capable".
        expect(decision.code, PlacementCode.queued);
      },
    );

    test(
      'a revoked worker holding the only capability leaves the job queued',
      () {
        final snapshot = FleetSnapshot(
          workers: [_worker('w1', flutter: true, status: WorkerStatus.revoked)],
        );

        final decision = scheduler.place(
          _job(requiredCaps: {FleetCaps.flutter}),
          snapshot,
        );

        expect(decision.placed, isFalse);
        expect(decision.workerId, isNull);
        expect(decision.code, PlacementCode.queued);
      },
    );
  });
}
