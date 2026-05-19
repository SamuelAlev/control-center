import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/placement_record.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/fleet/remote_execution_registry.dart';

/// Mints the short-lived, job-scoped credential env for a worker lease (PRD 20
/// §5). Returns the env map to inject on the worker (never the owner's PAT).
typedef LeaseCredentialMinter = Future<Map<String, String>> Function(Job job);

/// Serializes a [Worker] to the fleet wire map.
Map<String, dynamic> workerToWire(Worker w) => {
  'id': w.id,
  'name': w.name,
  'caps': w.capabilities.toJson(),
  'capabilityKeys': w.capabilityKeys.toList()..sort(),
  'status': w.status.wire,
  'protocolVersion': w.protocolVersion,
  'lastHeartbeatAt': w.lastHeartbeatAt?.toIso8601String(),
  'registeredBy': w.registeredBy,
  'drainedAt': w.drainedAt?.toIso8601String(),
  'revokedAt': w.revokedAt?.toIso8601String(),
  'lastError': w.lastError,
  'createdAt': w.createdAt.toIso8601String(),
};

/// Serializes a [Job] to the fleet wire map.
Map<String, dynamic> jobToWire(Job j) => {
  'id': j.id,
  'workspaceId': j.workspaceId,
  'kind': j.kind.wire,
  'status': j.status.wire,
  'requiredCaps': j.requiredCaps.toList()..sort(),
  'preferredCaps': j.preferredCaps.toList()..sort(),
  'priority': j.priority,
  'pinnedWorkerId': j.pinnedWorkerId,
  'workerId': j.workerId,
  'leaseExpiresAt': j.leaseExpiresAt?.toIso8601String(),
  'costCents': j.costCents,
  'attempts': j.attempts,
  'maxAttempts': j.maxAttempts,
  'error': j.error,
  'agentId': j.agentId,
  'conversationId': j.conversationId,
  'createdAt': j.createdAt.toIso8601String(),
  'startedAt': j.startedAt?.toIso8601String(),
  'finishedAt': j.finishedAt?.toIso8601String(),
};

/// Serializes a [PlacementRecord] to the fleet wire map.
Map<String, dynamic> placementToWire(PlacementRecord p) => {
  'id': p.id,
  'jobId': p.jobId,
  'workerId': p.workerId,
  'decision': p.code.wire,
  'reason': p.reason,
  'createdAt': p.createdAt.toIso8601String(),
};

/// The operator-facing fleet RPC ops (PRD 20 §7) — worker listing, job
/// submission/cancellation, and worker drain/resume/revoke/remove controls.
List<RepoOp> buildFleetOperatorOps({
  required FleetSchedulerService scheduler,
  required FleetRepository fleetRepository,
}) {
  return [
    RepoOp(
      name: 'fleet.workers',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final workers = await fleetRepository.allWorkers();
        return {'workers': workers.map(workerToWire).toList()};
      },
    ),
    RepoOp(
      name: 'fleet.jobs',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final ws = ctx.workspaceId!;
        final statusArg = ctx.args['status'] as String?;
        final jobs = statusArg == null
            ? await _allJobs(fleetRepository, ws)
            : await fleetRepository.jobsByStatus(
                ws,
                JobStatus.fromWire(statusArg),
              );
        return {'jobs': jobs.map(jobToWire).toList()};
      },
    ),
    RepoOp(
      name: 'fleet.submitJob',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['kind'],
      handler: (ctx) async {
        final ws = ctx.workspaceId!;
        final kind = JobKind.fromWire(ctx.args['kind'] as String);
        final specMap =
            (ctx.args['spec'] as Map?)?.cast<String, dynamic>() ?? const {};
        final spec = JobSpec.fromJson(kind, specMap);
        final id = await scheduler.submit(
          workspaceId: ws,
          spec: spec,
          priority: (ctx.args['priority'] as num?)?.toInt() ?? 0,
          pinnedWorkerId: ctx.args['pinned_worker_id'] as String?,
          extraRequiredCaps: ((ctx.args['required_caps'] as List?) ?? const [])
              .cast<String>()
              .toSet(),
          extraPreferredCaps:
              ((ctx.args['preferred_caps'] as List?) ?? const [])
                  .cast<String>()
                  .toSet(),
          submittedBy: ctx.userId,
          maxAttempts: (ctx.args['max_attempts'] as num?)?.toInt() ?? 1,
        );
        return {'jobId': id};
      },
    ),
    RepoOp(
      name: 'fleet.cancelJob',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['job_id'],
      handler: (ctx) async {
        await scheduler.cancelJob(
          ctx.workspaceId!,
          ctx.args['job_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'fleet.placements',
      kind: RepoOpKind.read,
      requiredArgs: const ['job_id'],
      handler: (ctx) async {
        final placements = await fleetRepository.placementsForJob(
          ctx.workspaceId!,
          ctx.args['job_id'] as String,
        );
        return {'placements': placements.map(placementToWire).toList()};
      },
    ),
    RepoOp(
      name: 'fleet.drainWorker',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['worker_id'],
      handler: (ctx) async {
        await scheduler.drainWorker(ctx.args['worker_id'] as String);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'fleet.resumeWorker',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['worker_id'],
      handler: (ctx) async {
        await scheduler.resumeWorker(ctx.args['worker_id'] as String);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'fleet.revokeWorker',
      kind: RepoOpKind.destructive,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['worker_id'],
      handler: (ctx) async {
        await scheduler.revokeWorker(ctx.args['worker_id'] as String);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'fleet.removeWorker',
      kind: RepoOpKind.destructive,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['worker_id'],
      handler: (ctx) async {
        await scheduler.removeWorker(ctx.args['worker_id'] as String);
        return {'ok': true};
      },
    ),
  ];
}

/// The worker-facing fleet RPC ops (PRD 20 §1, §3, §8) — how a paired
/// `cc_worker` registers, heartbeats, pulls leases, streams events, and reports
/// completion. Every call is on an authenticated paired-device session; the
/// server treats the streamed events as untrusted input (redaction happens
/// server-side before persistence).
List<RepoOp> buildFleetWorkerOps({
  required FleetSchedulerService scheduler,
  required FleetRepository fleetRepository,
  required RemoteExecutionRegistry remoteRegistry,
  LeaseCredentialMinter? mintLeaseCredentials,
}) {
  return [
    RepoOp(
      name: 'fleet.registerWorker',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: const ['registration'],
      handler: (ctx) async {
        final reg = WorkerRegistration.fromJson(
          (ctx.args['registration'] as Map).cast<String, dynamic>(),
        );
        final workerId = ctx.args['worker_id'] as String? ?? ctx.deviceId;
        // Anti-hijack (PRD 20 §5): a device may not (re-)register a worker id
        // that another device already owns.
        final existing = await fleetRepository.workerById(workerId);
        if (existing != null &&
            existing.pairedDeviceId != null &&
            existing.pairedDeviceId != ctx.deviceId) {
          throw const AuthException(
            'Worker id is already registered to a different device.',
          );
        }
        await scheduler.registerWorker(
          workerId: workerId,
          registration: reg,
          registeredBy: ctx.userId,
          pairedDeviceId: ctx.deviceId,
        );
        return {
          'workerId': workerId,
          'serverProtocolVersion': kFleetProtocolVersion,
          'compatible': reg.protocolVersion == kFleetProtocolVersion,
        };
      },
    ),
    RepoOp(
      name: 'fleet.workerHeartbeat',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: const ['worker_id'],
      handler: (ctx) async {
        final workerId = ctx.args['worker_id'] as String;
        await _assertDeviceOwnsWorker(fleetRepository, ctx.deviceId, workerId);
        final capsJson = ctx.args['caps_json'] as String?;
        await scheduler.recordHeartbeat(
          workerId,
          protocolVersion: (ctx.args['protocol_version'] as num?)?.toInt(),
          caps: capsJson == null
              ? null
              : WorkerCapabilitiesFromJson(capsJson).value,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'fleet.workerPoll',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: const ['worker_id'],
      handler: (ctx) async {
        final workerId = ctx.args['worker_id'] as String;
        // Authz (PRD 20 §5): only the owning device may pull this worker's
        // leases — they span workspaces and carry job-scoped credentials.
        await _assertDeviceOwnsWorker(fleetRepository, ctx.deviceId, workerId);
        final activeJobIds = ((ctx.args['active_job_ids'] as List?) ?? const [])
            .cast<String>()
            .toSet();
        final active = await fleetRepository.activeJobsForWorker(workerId);
        final leases = <Map<String, dynamic>>[];
        for (final job in active) {
          if (activeJobIds.contains(job.id)) {
            continue;
          }
          final env = mintLeaseCredentials == null
              ? const <String, String>{}
              : await mintLeaseCredentials(job);
          leases.add(_leaseOfferFor(job, env).toJson());
        }
        // Jobs the worker still thinks it runs but that the server terminated
        // (cancelled/reaped) — tell it to stop.
        final cancelled = <String>[];
        for (final id in activeJobIds) {
          final job = await fleetRepository.jobByIdGlobal(id);
          if (job == null ||
              job.status.isTerminal ||
              job.status == JobStatus.reaped ||
              job.workerId != workerId) {
            cancelled.add(id);
          }
        }
        return {'leases': leases, 'cancelledJobIds': cancelled};
      },
    ),
    RepoOp(
      name: 'fleet.workerEvents',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: const ['frames'],
      handler: (ctx) async {
        final frames = ((ctx.args['frames'] as List?) ?? const [])
            .cast<Map<dynamic, dynamic>>();
        var lastAcked = 0;
        String? jobId;
        for (final raw in frames) {
          final frame = WorkerEventFrame.fromJson(raw.cast<String, dynamic>());
          // Authz (PRD 20 §5): a device may only stream events for a job leased
          // to a worker it owns — never inject into another workspace's run.
          await _assertDeviceOwnsJob(
            fleetRepository,
            ctx.deviceId,
            frame.jobId,
          );
          jobId = frame.jobId;
          lastAcked = remoteRegistry.pushEvent(frame);
        }
        if (jobId != null) {
          await fleetRepository.renewLease(
            jobId,
            DateTime.now().add(const Duration(minutes: 2)),
            lastAckedSeq: lastAcked,
          );
        }
        return {'ackedSeq': lastAcked};
      },
    ),
    RepoOp(
      name: 'fleet.workerComplete',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: const ['report'],
      handler: (ctx) async {
        final report = JobCompletionReport.fromJson(
          (ctx.args['report'] as Map).cast<String, dynamic>(),
        );
        // Authz (PRD 20 §5): only the device owning the job's worker may
        // report its completion.
        await _assertDeviceOwnsJob(fleetRepository, ctx.deviceId, report.jobId);
        await remoteRegistry.complete(report);
        return {'ok': true};
      },
    ),
  ];
}

/// The fleet reactive queries (PRD 20 §7): live worker list, live job list, and
/// live placement log per job.
List<WatchQuery> buildFleetWatchQueries({
  required FleetRepository fleetRepository,
}) {
  return [
    WatchQuery(
      name: 'fleet.watchWorkers',
      workspaceScoped: false,
      handler: (ctx) => fleetRepository.watchWorkers().map(
        (workers) => {'workers': workers.map(workerToWire).toList()},
      ),
    ),
    WatchQuery(
      name: 'fleet.watchJobs',
      handler: (ctx) => fleetRepository
          .watchJobs(ctx.workspaceId!)
          .map((jobs) => {'jobs': jobs.map(jobToWire).toList()}),
    ),
    WatchQuery(
      name: 'fleet.watchPlacements',
      handler: (ctx) => fleetRepository
          .watchPlacementsForJob(
            ctx.workspaceId!,
            ctx.args['job_id'] as String? ?? '',
          )
          .map((rows) => {'placements': rows.map(placementToWire).toList()}),
    ),
  ];
}

/// Asserts the calling [deviceId] owns [workerId] (PRD 20 §5 authz). A paired
/// device may only act as the worker it registered (its `pairedDeviceId`);
/// otherwise it could pull another worker's cross-workspace leases. Throws
/// [AuthException] on a mismatch (surfaced verbatim to the caller).
Future<void> _assertDeviceOwnsWorker(
  FleetRepository repo,
  String deviceId,
  String workerId,
) async {
  final worker = await repo.workerById(workerId);
  if (deviceId.isEmpty || worker == null || worker.pairedDeviceId != deviceId) {
    throw const AuthException('Not authorized to act as this worker.');
  }
}

/// Asserts the calling [deviceId] owns the worker the job identified by [jobId]
/// is leased to. Guards the event/completion push paths (which are keyed by job
/// id) so a device cannot inject into another workspace's run.
Future<void> _assertDeviceOwnsJob(
  FleetRepository repo,
  String deviceId,
  String jobId,
) async {
  final job = await repo.jobByIdGlobal(jobId);
  final workerId = job?.workerId;
  if (workerId == null) {
    throw const AuthException('Not authorized to stream this job.');
  }
  await _assertDeviceOwnsWorker(repo, deviceId, workerId);
}

Future<List<Job>> _allJobs(FleetRepository repo, String workspaceId) async {
  final result = <Job>[];
  for (final status in JobStatus.values) {
    result.addAll(await repo.jobsByStatus(workspaceId, status));
  }
  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

LeaseOffer _leaseOfferFor(Job job, Map<String, String> env) {
  final spec = job.spec;
  String? repoRemote;
  String? headSha;
  if (spec is AgentRunJobSpec) {
    repoRemote = spec.repoRemote;
    headSha = spec.headSha;
  } else if (spec is CodeIndexJobSpec) {
    repoRemote = spec.repoRemote;
    headSha = spec.headSha;
  } else if (spec is GoldenRenderJobSpec) {
    repoRemote = spec.repoRemote;
    headSha = spec.headSha;
  }
  return LeaseOffer(
    jobId: job.id,
    workspaceId: job.workspaceId,
    kind: job.kind.wire,
    specJson: job.spec.toJsonString(),
    leaseExpiresAtIso:
        (job.leaseExpiresAt ?? DateTime.now().add(const Duration(minutes: 2)))
            .toIso8601String(),
    env: env,
    repoRemote: repoRemote,
    headSha: headSha,
    branch: 'cc/job/${job.id}',
  );
}

/// Small helper so a caps JSON string parses inline without a local var lint.
extension WorkerCapabilitiesFromJson on String {
  /// Parses this string as `WorkerCapabilities`.
  WorkerCapabilities get value => WorkerCapabilities.fromJsonString(this);
}
