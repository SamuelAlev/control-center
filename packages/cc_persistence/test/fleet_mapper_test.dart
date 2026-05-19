import 'dart:convert';

import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/mappers/fleet_mapper.dart';
import 'package:test/test.dart';

/// Unit tests for [FleetMapper] — the bidirectional row↔entity mapping for the
/// three PRD 20 fleet tables (workers, jobs, placement log). The round-trip
/// (toCompanion → fromRow) is the load-bearing assertion: a field the mapper
/// forgets would silently reset on persist. Capability encode/decode and the
/// derived `platform` column are exercised too.
void main() {
  const mapper = FleetMapper();

  group('FleetMapper workers', () {
    final createdAt = DateTime.utc(2026, 7, 1, 9);
    final heartbeatAt = DateTime.utc(2026, 7, 1, 10);

    const caps = WorkerCapabilities(
      os: 'macos',
      arch: 'arm64',
      cores: 8,
      ramMb: 16384,
      hasFlutter: true,
      hasMl: false,
      alwaysOn: true,
      acceptsParallel: true,
      sandboxBackends: {'native-macos'},
      extra: {'gpu'},
    );

    final row = WorkersTableData(
      id: 'wk-1',
      name: 'mac-studio',
      capsJson: caps.toJsonString(),
      platform: 'macos',
      credentialRef: 'cred://ref',
      pairedDeviceId: 'device-1',
      protocolVersion: 3,
      status: 'online',
      lastHeartbeatAt: heartbeatAt,
      registeredBy: 'sam',
      drainedAt: null,
      revokedAt: null,
      lastError: null,
      createdAt: createdAt,
    );

    test('workerFromRow maps every field verbatim', () {
      final w = mapper.workerFromRow(row);
      expect(w.id, 'wk-1');
      expect(w.name, 'mac-studio');
      expect(w.capabilities, caps);
      expect(w.status, WorkerStatus.online);
      expect(w.protocolVersion, 3);
      expect(w.credentialRef, 'cred://ref');
      expect(w.pairedDeviceId, 'device-1');
      expect(w.registeredBy, 'sam');
      expect(w.lastHeartbeatAt, heartbeatAt);
      expect(w.drainedAt, isNull);
      expect(w.revokedAt, isNull);
      expect(w.lastError, isNull);
      expect(w.createdAt, createdAt);
    });

    test('workerFromRow defaults to offline on an unknown status wire', () {
      final offlineRow = WorkersTableData(
        id: 'wk-2',
        name: 'box',
        capsJson: caps.toJsonString(),
        platform: 'macos',
        protocolVersion: 1,
        status: 'bogus',
        createdAt: createdAt,
      );
      expect(mapper.workerFromRow(offlineRow).status, WorkerStatus.offline);
    });

    test('workerFromRow tolerates an empty capsJson', () {
      final emptyRow = WorkersTableData(
        id: 'wk-3',
        name: 'box',
        capsJson: '   ',
        platform: 'unknown',
        protocolVersion: 1,
        status: 'offline',
        createdAt: createdAt,
      );
      final w = mapper.workerFromRow(emptyRow);
      expect(w.capabilities.os, 'unknown');
      expect(w.capabilities.arch, 'unknown');
    });

    test(
      'workerToCompanion carries every field and derives platform from os',
      () {
        final worker = Worker(
          id: 'wk-1',
          name: 'mac-studio',
          capabilities: caps,
          status: WorkerStatus.online,
          protocolVersion: 3,
          credentialRef: 'cred://ref',
          pairedDeviceId: 'device-1',
          registeredBy: 'sam',
          lastHeartbeatAt: heartbeatAt,
          createdAt: createdAt,
        );
        final c = mapper.workerToCompanion(worker);
        expect(c.id.value, 'wk-1');
        expect(c.name.value, 'mac-studio');
        expect(c.capsJson.value, caps.toJsonString());
        expect(
          c.platform.value,
          'macos',
          reason: 'platform is derived from os',
        );
        expect(c.credentialRef.value, 'cred://ref');
        expect(c.pairedDeviceId.value, 'device-1');
        expect(c.protocolVersion.value, 3);
        expect(c.status.value, 'online');
        expect(c.lastHeartbeatAt.value, heartbeatAt);
        expect(c.registeredBy.value, 'sam');
        expect(c.drainedAt.value, isNull);
        expect(c.revokedAt.value, isNull);
        expect(c.lastError.value, isNull);
        expect(c.createdAt.value, createdAt);
      },
    );

    test('round-trip preserves every field', () {
      final worker = mapper.workerFromRow(row);
      final rebuilt = mapper.workerToCompanion(worker).toData();
      expect(rebuilt, row);
    });
  });

  group('FleetMapper jobs', () {
    final createdAt = DateTime.utc(2026, 7, 1, 9);
    final leasedAt = DateTime.utc(2026, 7, 1, 10);
    final startedAt = DateTime.utc(2026, 7, 1, 11);
    final finishedAt = DateTime.utc(2026, 7, 1, 12);
    final leaseExpiresAt = DateTime.utc(2026, 7, 1, 13);

    const spec = AgentRunJobSpec(
      agentId: 'agent-1',
      conversationId: 'conv-1',
      runLogId: 'log-1',
      prompt: 'do the thing',
      mode: 'review',
      repoRemote: 'git://repo',
      headSha: 'sha-abc',
      requestedByUserId: 'sam',
    );

    final row = JobsTableData(
      id: 'job-1',
      workspaceId: 'ws-1',
      kind: 'agentRun',
      specJson: spec.toJsonString(),
      requiredCapsJson: jsonEncode(['flutter', 'macos']),
      preferredCapsJson: jsonEncode(['parallel']),
      status: 'running',
      workerId: 'wk-1',
      pinnedWorkerId: 'wk-1',
      leaseExpiresAt: leaseExpiresAt,
      priority: 5,
      submittedBy: 'sam',
      costCents: 250,
      attempts: 1,
      maxAttempts: 3,
      lastAckedSeq: 7,
      resultJson: null,
      error: null,
      agentId: 'agent-1',
      conversationId: 'conv-1',
      createdAt: createdAt,
      leasedAt: leasedAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );

    test('jobFromRow maps every field verbatim and reconstructs the spec', () {
      final j = mapper.jobFromRow(row);
      expect(j.id, 'job-1');
      expect(j.workspaceId, 'ws-1');
      expect(j.kind, JobKind.agentRun);
      // JobSpec has no value equality — compare the serialized payload.
      expect(j.spec.toJsonString(), spec.toJsonString());
      expect(j.spec.kind, JobKind.agentRun);
      expect(j.status, JobStatus.running);
      expect(j.requiredCaps, {'flutter', 'macos'});
      expect(j.preferredCaps, {'parallel'});
      expect(j.priority, 5);
      expect(j.pinnedWorkerId, 'wk-1');
      expect(j.workerId, 'wk-1');
      expect(j.leaseExpiresAt, leaseExpiresAt);
      expect(j.submittedBy, 'sam');
      expect(j.costCents, 250);
      expect(j.attempts, 1);
      expect(j.maxAttempts, 3);
      expect(j.lastAckedSeq, 7);
      expect(j.resultJson, isNull);
      expect(j.error, isNull);
      expect(j.agentId, 'agent-1');
      expect(j.conversationId, 'conv-1');
      expect(j.createdAt, createdAt);
      expect(j.leasedAt, leasedAt);
      expect(j.startedAt, startedAt);
      expect(j.finishedAt, finishedAt);
    });

    test('jobFromRow falls back to agentRun on an unknown kind wire', () {
      final weirdRow = JobsTableData(
        id: 'job-2',
        workspaceId: 'ws-1',
        kind: 'nope',
        specJson: '',
        requiredCapsJson: '',
        preferredCapsJson: '',
        status: 'queued',
        priority: 0,
        costCents: 0,
        attempts: 0,
        maxAttempts: 1,
        lastAckedSeq: 0,
        createdAt: createdAt,
      );
      expect(mapper.jobFromRow(weirdRow).kind, JobKind.agentRun);
    });

    test('jobFromRow decodes empty/whitespace caps as the empty set', () {
      final blankRow = JobsTableData(
        id: 'job-3',
        workspaceId: 'ws-1',
        kind: 'agentRun',
        specJson: '',
        requiredCapsJson: '  ',
        preferredCapsJson: '',
        status: 'queued',
        priority: 0,
        costCents: 0,
        attempts: 0,
        maxAttempts: 1,
        lastAckedSeq: 0,
        createdAt: createdAt,
      );
      final j = mapper.jobFromRow(blankRow);
      expect(j.requiredCaps, isEmpty);
      expect(j.preferredCaps, isEmpty);
    });

    test('jobFromRow treats non-array caps JSON as the empty set', () {
      final malformedRow = JobsTableData(
        id: 'job-4',
        workspaceId: 'ws-1',
        kind: 'agentRun',
        specJson: '',
        requiredCapsJson: '"not-a-list"',
        preferredCapsJson: '42',
        status: 'queued',
        priority: 0,
        costCents: 0,
        attempts: 0,
        maxAttempts: 1,
        lastAckedSeq: 0,
        createdAt: createdAt,
      );
      final j = mapper.jobFromRow(malformedRow);
      expect(j.requiredCaps, isEmpty);
      expect(j.preferredCaps, isEmpty);
    });

    test(
      'jobToCompanion encodes caps as a sorted JSON array and kind as wire',
      () {
        final job = Job(
          id: 'job-1',
          workspaceId: 'ws-1',
          kind: JobKind.agentRun,
          spec: spec,
          status: JobStatus.running,
          requiredCaps: {'macos', 'flutter'}, // intentionally unsorted
          preferredCaps: {'parallel'},
          priority: 5,
          pinnedWorkerId: 'wk-1',
          workerId: 'wk-1',
          leaseExpiresAt: leaseExpiresAt,
          submittedBy: 'sam',
          costCents: 250,
          attempts: 1,
          maxAttempts: 3,
          lastAckedSeq: 7,
          agentId: 'agent-1',
          conversationId: 'conv-1',
          createdAt: createdAt,
          leasedAt: leasedAt,
          startedAt: startedAt,
          finishedAt: finishedAt,
        );
        final c = mapper.jobToCompanion(job);
        expect(c.id.value, 'job-1');
        expect(c.workspaceId.value, 'ws-1');
        expect(c.kind.value, 'agentRun');
        expect(c.specJson.value, spec.toJsonString());
        // Sorted and JSON-encoded for deterministic rows.
        expect(c.requiredCapsJson.value, jsonEncode(['flutter', 'macos']));
        expect(c.preferredCapsJson.value, jsonEncode(['parallel']));
        expect(c.status.value, 'running');
        expect(c.workerId.value, 'wk-1');
        expect(c.pinnedWorkerId.value, 'wk-1');
        expect(c.leaseExpiresAt.value, leaseExpiresAt);
        expect(c.priority.value, 5);
        expect(c.submittedBy.value, 'sam');
        expect(c.costCents.value, 250);
        expect(c.attempts.value, 1);
        expect(c.maxAttempts.value, 3);
        expect(c.lastAckedSeq.value, 7);
        expect(c.agentId.value, 'agent-1');
        expect(c.conversationId.value, 'conv-1');
        expect(c.createdAt.value, createdAt);
        expect(c.leasedAt.value, leasedAt);
        expect(c.startedAt.value, startedAt);
        expect(c.finishedAt.value, finishedAt);
      },
    );

    test('round-trip preserves every field', () {
      final job = mapper.jobFromRow(row);
      final rebuilt = mapper.jobToCompanion(job).toData();
      expect(rebuilt, row);
    });
  });

  group('FleetMapper placement log', () {
    final createdAt = DateTime.utc(2026, 7, 1, 9);

    final row = PlacementLogTableData(
      id: 'p-1',
      workspaceId: 'ws-1',
      jobId: 'job-1',
      workerId: 'wk-1',
      decision: 'preferred',
      reason: 'matched flutter cap',
      createdAt: createdAt,
    );

    test('placementFromRow maps every field verbatim', () {
      final p = mapper.placementFromRow(row);
      expect(p.id, 'p-1');
      expect(p.workspaceId, 'ws-1');
      expect(p.jobId, 'job-1');
      expect(p.workerId, 'wk-1');
      expect(p.code, PlacementCode.preferred);
      expect(p.reason, 'matched flutter cap');
      expect(p.createdAt, createdAt);
    });

    test('placementFromRow falls back to queued on an unknown wire', () {
      final weirdRow = PlacementLogTableData(
        id: 'p-2',
        workspaceId: 'ws-1',
        jobId: 'job-1',
        decision: 'bogus',
        reason: '',
        createdAt: createdAt,
      );
      expect(mapper.placementFromRow(weirdRow).code, PlacementCode.queued);
    });

    test('placementFromRow tolerates a null workerId', () {
      final queuedRow = PlacementLogTableData(
        id: 'p-3',
        workspaceId: 'ws-1',
        jobId: 'job-1',
        decision: 'queued',
        reason: 'no eligible worker',
        createdAt: createdAt,
      );
      expect(mapper.placementFromRow(queuedRow).workerId, isNull);
    });
  });
}

/// Rebuilds a [WorkersTableData] from a companion (round-trip check).
extension on WorkersTableCompanion {
  WorkersTableData toData() => WorkersTableData(
    id: id.value,
    name: name.value,
    capsJson: capsJson.value,
    platform: platform.value,
    credentialRef: credentialRef.present ? credentialRef.value : null,
    pairedDeviceId: pairedDeviceId.present ? pairedDeviceId.value : null,
    protocolVersion: protocolVersion.value,
    status: status.value,
    lastHeartbeatAt: lastHeartbeatAt.present ? lastHeartbeatAt.value : null,
    registeredBy: registeredBy.present ? registeredBy.value : null,
    drainedAt: drainedAt.present ? drainedAt.value : null,
    revokedAt: revokedAt.present ? revokedAt.value : null,
    lastError: lastError.present ? lastError.value : null,
    createdAt: createdAt.value,
  );
}

/// Rebuilds a [JobsTableData] from a companion (round-trip check).
extension on JobsTableCompanion {
  JobsTableData toData() => JobsTableData(
    id: id.value,
    workspaceId: workspaceId.value,
    kind: kind.value,
    specJson: specJson.value,
    requiredCapsJson: requiredCapsJson.value,
    preferredCapsJson: preferredCapsJson.value,
    status: status.value,
    workerId: workerId.present ? workerId.value : null,
    pinnedWorkerId: pinnedWorkerId.present ? pinnedWorkerId.value : null,
    leaseExpiresAt: leaseExpiresAt.present ? leaseExpiresAt.value : null,
    priority: priority.value,
    submittedBy: submittedBy.present ? submittedBy.value : null,
    costCents: costCents.value,
    attempts: attempts.value,
    maxAttempts: maxAttempts.value,
    lastAckedSeq: lastAckedSeq.value,
    resultJson: resultJson.present ? resultJson.value : null,
    error: error.present ? error.value : null,
    agentId: agentId.present ? agentId.value : null,
    conversationId: conversationId.present ? conversationId.value : null,
    createdAt: createdAt.value,
    leasedAt: leasedAt.present ? leasedAt.value : null,
    startedAt: startedAt.present ? startedAt.value : null,
    finishedAt: finishedAt.present ? finishedAt.value : null,
  );
}
