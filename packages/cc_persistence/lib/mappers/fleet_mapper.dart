import 'dart:convert';

import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/placement_record.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:drift/drift.dart';

/// Maps between the fleet (PRD 20) table rows — [WorkersTableData],
/// [JobsTableData], [PlacementLogTableData] — and their domain entities.
class FleetMapper {
  /// Creates a [FleetMapper].
  const FleetMapper();

  /// Worker row to domain.
  Worker workerFromRow(WorkersTableData row) => Worker(
    id: row.id,
    name: row.name,
    capabilities: WorkerCapabilities.fromJsonString(row.capsJson),
    status: WorkerStatus.fromWire(row.status),
    protocolVersion: row.protocolVersion,
    credentialRef: row.credentialRef,
    pairedDeviceId: row.pairedDeviceId,
    registeredBy: row.registeredBy,
    lastHeartbeatAt: row.lastHeartbeatAt,
    drainedAt: row.drainedAt,
    revokedAt: row.revokedAt,
    lastError: row.lastError,
    createdAt: row.createdAt,
  );

  /// Worker to companion. The `platform` display column is derived from the
  /// declared capabilities (the entity has no separate platform field).
  WorkersTableCompanion workerToCompanion(Worker w) => WorkersTableCompanion(
    id: Value(w.id),
    name: Value(w.name),
    capsJson: Value(w.capabilities.toJsonString()),
    platform: Value(w.capabilities.os),
    credentialRef: Value(w.credentialRef),
    pairedDeviceId: Value(w.pairedDeviceId),
    protocolVersion: Value(w.protocolVersion),
    status: Value(w.status.wire),
    lastHeartbeatAt: Value(w.lastHeartbeatAt),
    registeredBy: Value(w.registeredBy),
    drainedAt: Value(w.drainedAt),
    revokedAt: Value(w.revokedAt),
    lastError: Value(w.lastError),
    createdAt: Value(w.createdAt),
  );

  /// Job row to domain. The `kind` column selects the concrete [JobSpec] parsed
  /// from the `specJson` payload; capability columns are JSON string arrays.
  Job jobFromRow(JobsTableData row) {
    final kind = JobKind.fromWire(row.kind);
    return Job(
      id: row.id,
      workspaceId: row.workspaceId,
      kind: kind,
      spec: JobSpec.fromJsonString(kind, row.specJson),
      status: JobStatus.fromWire(row.status),
      requiredCaps: _decodeCaps(row.requiredCapsJson),
      preferredCaps: _decodeCaps(row.preferredCapsJson),
      priority: row.priority,
      pinnedWorkerId: row.pinnedWorkerId,
      workerId: row.workerId,
      leaseExpiresAt: row.leaseExpiresAt,
      submittedBy: row.submittedBy,
      costCents: row.costCents,
      attempts: row.attempts,
      maxAttempts: row.maxAttempts,
      lastAckedSeq: row.lastAckedSeq,
      resultJson: row.resultJson,
      error: row.error,
      agentId: row.agentId,
      conversationId: row.conversationId,
      createdAt: row.createdAt,
      leasedAt: row.leasedAt,
      startedAt: row.startedAt,
      finishedAt: row.finishedAt,
    );
  }

  /// Job to companion. `kind` stores the wire name and `specJson` the payload;
  /// capability sets are encoded as sorted JSON arrays for deterministic rows.
  JobsTableCompanion jobToCompanion(Job j) => JobsTableCompanion(
    id: Value(j.id),
    workspaceId: Value(j.workspaceId),
    kind: Value(j.kind.wire),
    specJson: Value(j.spec.toJsonString()),
    requiredCapsJson: Value(_encodeCaps(j.requiredCaps)),
    preferredCapsJson: Value(_encodeCaps(j.preferredCaps)),
    status: Value(j.status.wire),
    workerId: Value(j.workerId),
    pinnedWorkerId: Value(j.pinnedWorkerId),
    leaseExpiresAt: Value(j.leaseExpiresAt),
    priority: Value(j.priority),
    submittedBy: Value(j.submittedBy),
    costCents: Value(j.costCents),
    attempts: Value(j.attempts),
    maxAttempts: Value(j.maxAttempts),
    lastAckedSeq: Value(j.lastAckedSeq),
    resultJson: Value(j.resultJson),
    error: Value(j.error),
    agentId: Value(j.agentId),
    conversationId: Value(j.conversationId),
    createdAt: Value(j.createdAt),
    leasedAt: Value(j.leasedAt),
    startedAt: Value(j.startedAt),
    finishedAt: Value(j.finishedAt),
  );

  /// Placement-log row to domain.
  PlacementRecord placementFromRow(PlacementLogTableData row) =>
      PlacementRecord(
        id: row.id,
        workspaceId: row.workspaceId,
        jobId: row.jobId,
        workerId: row.workerId,
        code: PlacementCode.fromWire(row.decision),
        reason: row.reason,
        createdAt: row.createdAt,
      );

  /// Decodes a JSON string array of capability keys into a set.
  static Set<String> _decodeCaps(String raw) {
    if (raw.trim().isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toSet();
    }
    return const {};
  }

  /// Encodes capability keys as a sorted JSON string array (deterministic).
  static String _encodeCaps(Set<String> caps) =>
      jsonEncode(caps.toList()..sort());
}
