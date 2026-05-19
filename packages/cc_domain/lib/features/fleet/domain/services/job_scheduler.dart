import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';

/// The current runtime view of the fleet a placement is computed against.
///
/// Pure data — the scheduler takes a snapshot and never touches the DB, so the
/// same snapshot + same job always yields the same [PlacementDecision]
/// (determinism invariant, PRD 20 design tenet 4).
class FleetSnapshot {
  /// Creates a [FleetSnapshot].
  const FleetSnapshot({
    required this.workers,
    this.busyWorkerIds = const {},
    this.cacheWarmWorkerIds = const {},
  });

  /// Every known worker (any status).
  final List<Worker> workers;

  /// Worker ids currently at capacity (cannot take another job now).
  final Set<String> busyWorkerIds;

  /// Worker ids whose repo cache is already warm for the job's repo.
  final Set<String> cacheWarmWorkerIds;
}

/// The deterministic, capability-matched job scheduler (PRD 20 §2).
///
/// Placement is by declared capability + explicit policy, never load-balancer
/// vibes: pin → prefer → spill. Given the same [FleetSnapshot] and [Job], the
/// decision is identical every time (ties break on worker id). The scheduler is
/// a pure function; leasing, streaming and side effects live in the server.
class JobScheduler {
  /// Creates a [JobScheduler].
  const JobScheduler();

  /// Decides where (if anywhere) [job] should run given [snapshot].
  PlacementDecision place(Job job, FleetSnapshot snapshot) {
    final schedulable = snapshot.workers.where((w) => w.isSchedulable).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // 1. Explicit pin wins, unconditionally and deterministically.
    if (job.isPinned) {
      return _placePinned(job, snapshot, schedulable);
    }

    // 2. Which schedulable workers can run this job at all?
    final capable = schedulable
        .where((w) => w.capabilityKeys.containsAll(job.requiredCaps))
        .toList();
    if (capable.isEmpty) {
      // Distinguish "no worker anywhere can" from "some can but are offline".
      final anyCapableAtAll = snapshot.workers.any(
        (w) => w.capabilityKeys.containsAll(job.requiredCaps),
      );
      if (!anyCapableAtAll) {
        final missing = _missingCaps(job, snapshot.workers);
        return PlacementDecision.queued(
          missing.isEmpty
              ? 'No worker in the fleet can run this job.'
              : 'No worker advertises required capability '
                    '${missing.join(", ")}.',
          code: PlacementCode.noCapableWorker,
        );
      }
      return const PlacementDecision.queued(
        'Capable workers exist but none are online.',
      );
    }

    // 3. Among capable workers, only the free ones can take it now.
    final free = capable
        .where((w) => !snapshot.busyWorkerIds.contains(w.id))
        .toList();
    if (free.isEmpty) {
      return PlacementDecision.queued(
        '${capable.length} capable worker(s), all busy — queued for the next '
        'free one.',
      );
    }

    // 4. Rank free workers: prefer preferred-cap matches, then cache-warm,
    //    then stable worker id. Highest score wins; ties break on id.
    Worker? best;
    var bestScore = -1;
    for (final w in free) {
      final satisfiesPreferred =
          job.preferredCaps.isNotEmpty &&
          w.capabilityKeys.containsAll(job.preferredCaps);
      final cacheWarm = snapshot.cacheWarmWorkerIds.contains(w.id);
      final score = (satisfiesPreferred ? 100 : 0) + (cacheWarm ? 10 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = w;
      }
    }
    final chosen = best!;
    final satisfiesPreferred =
        job.preferredCaps.isNotEmpty &&
        chosen.capabilityKeys.containsAll(job.preferredCaps);
    final cacheWarm = snapshot.cacheWarmWorkerIds.contains(chosen.id);
    final cacheNote = cacheWarm ? '' : ' (warming repo cache)';

    if (satisfiesPreferred) {
      return PlacementDecision(
        code: PlacementCode.preferred,
        workerId: chosen.id,
        reason:
            'Ran on ${chosen.name} — matched preferred '
            '${job.preferredCaps.join(", ")}$cacheNote.',
      );
    }
    return PlacementDecision(
      code: PlacementCode.spill,
      workerId: chosen.id,
      reason: 'Ran on ${chosen.name} — first free capable worker$cacheNote.',
    );
  }

  PlacementDecision _placePinned(
    Job job,
    FleetSnapshot snapshot,
    List<Worker> schedulable,
  ) {
    final pinId = job.pinnedWorkerId!;
    Worker? pinned;
    for (final w in schedulable) {
      if (w.id == pinId) {
        pinned = w;
        break;
      }
    }
    if (pinned == null) {
      return PlacementDecision.queued(
        'Pinned worker $pinId is not online — queued until it returns.',
        code: PlacementCode.pinnedWorkerUnavailable,
      );
    }
    if (!pinned.capabilityKeys.containsAll(job.requiredCaps)) {
      final missing =
          job.requiredCaps.difference(pinned.capabilityKeys).toList()..sort();
      return PlacementDecision.queued(
        'Pinned worker ${pinned.name} lacks required capability '
        '${missing.join(", ")}.',
        code: PlacementCode.pinnedWorkerUnavailable,
      );
    }
    if (snapshot.busyWorkerIds.contains(pinned.id)) {
      return PlacementDecision.queued(
        'Pinned worker ${pinned.name} is busy — queued for it specifically.',
      );
    }
    return PlacementDecision(
      code: PlacementCode.pinned,
      workerId: pinned.id,
      reason: 'Ran on ${pinned.name} — explicitly pinned.',
    );
  }

  /// The required capability keys that no worker in [workers] advertises.
  Set<String> _missingCaps(Job job, List<Worker> workers) {
    final advertised = <String>{};
    for (final w in workers) {
      advertised.addAll(w.capabilityKeys);
    }
    return job.requiredCaps.difference(advertised);
  }
}
