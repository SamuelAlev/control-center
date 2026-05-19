import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';

/// A registered fleet worker (PRD 20 §1).
///
/// A worker is a paired, principal-adjacent device that executes leased jobs
/// and holds no durable state. Workers are **server-global** — a worker serves
/// every workspace — so this entity carries no `workspaceId`.
class Worker {
  /// Creates a [Worker].
  const Worker({
    required this.id,
    required this.name,
    required this.capabilities,
    required this.status,
    this.protocolVersion = 0,
    this.credentialRef,
    this.pairedDeviceId,
    this.registeredBy,
    this.lastHeartbeatAt,
    this.drainedAt,
    this.revokedAt,
    this.lastError,
    required this.createdAt,
  }) : assert(id != '', 'Worker id must not be empty'),
       assert(name != '', 'Worker name must not be empty');

  /// Unique worker id.
  final String id;

  /// Operator-facing name.
  final String name;

  /// Declared capabilities (drives placement).
  final WorkerCapabilities capabilities;

  /// Lifecycle status.
  final WorkerStatus status;

  /// The wire protocol version handshaked at pairing/reconnect.
  final int protocolVersion;

  /// Reference to the paired-device credential (never the secret itself).
  final String? credentialRef;

  /// The backing paired-device row id (PRD 15).
  final String? pairedDeviceId;

  /// Principal that registered the worker.
  final String? registeredBy;

  /// Last heartbeat time (server clock).
  final DateTime? lastHeartbeatAt;

  /// When the operator put the worker into drain.
  final DateTime? drainedAt;

  /// When the worker was revoked.
  final DateTime? revokedAt;

  /// Last error surfaced by/about the worker.
  final String? lastError;

  /// Registration time.
  final DateTime createdAt;

  /// Whether this worker may currently be leased new jobs.
  bool get isSchedulable =>
      status.isSchedulable && revokedAt == null && drainedAt == null;

  /// The capability keys this worker satisfies (for scheduling).
  Set<String> get capabilityKeys => capabilities.keys;

  /// Whether the heartbeat has lapsed past [ttl] as of [now] (server clock).
  bool heartbeatExpired(DateTime now, Duration ttl) {
    final last = lastHeartbeatAt;
    if (last == null) {
      return true;
    }
    return now.difference(last) > ttl;
  }

  /// Returns a copy with the given fields replaced.
  Worker copyWith({
    String? name,
    WorkerCapabilities? capabilities,
    WorkerStatus? status,
    int? protocolVersion,
    String? credentialRef,
    String? pairedDeviceId,
    String? registeredBy,
    DateTime? lastHeartbeatAt,
    DateTime? drainedAt,
    DateTime? revokedAt,
    String? lastError,
  }) => Worker(
    id: id,
    name: name ?? this.name,
    capabilities: capabilities ?? this.capabilities,
    status: status ?? this.status,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    credentialRef: credentialRef ?? this.credentialRef,
    pairedDeviceId: pairedDeviceId ?? this.pairedDeviceId,
    registeredBy: registeredBy ?? this.registeredBy,
    lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
    drainedAt: drainedAt ?? this.drainedAt,
    revokedAt: revokedAt ?? this.revokedAt,
    lastError: lastError ?? this.lastError,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Worker &&
      other.id == id &&
      other.name == name &&
      other.capabilities == capabilities &&
      other.status == status &&
      other.protocolVersion == protocolVersion &&
      other.credentialRef == credentialRef &&
      other.pairedDeviceId == pairedDeviceId &&
      other.registeredBy == registeredBy &&
      other.lastHeartbeatAt == lastHeartbeatAt &&
      other.drainedAt == drainedAt &&
      other.revokedAt == revokedAt &&
      other.lastError == lastError &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    capabilities,
    status,
    protocolVersion,
    credentialRef,
    pairedDeviceId,
    registeredBy,
    lastHeartbeatAt,
    drainedAt,
    revokedAt,
    lastError,
    createdAt,
  );
}
