import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';

/// An executable job the scheduler leases to a worker (PRD 20 §2).
///
/// Workspace-scoped: a job belongs to exactly one workspace even though the
/// workers that run it are server-global.
class Job {
  /// Creates a [Job].
  const Job({
    required this.id,
    required this.workspaceId,
    required this.kind,
    required this.spec,
    required this.status,
    this.requiredCaps = const {},
    this.preferredCaps = const {},
    this.priority = 0,
    this.pinnedWorkerId,
    this.workerId,
    this.leaseExpiresAt,
    this.submittedBy,
    this.costCents = 0,
    this.attempts = 0,
    this.maxAttempts = 1,
    this.lastAckedSeq = 0,
    this.resultJson,
    this.error,
    this.agentId,
    this.conversationId,
    required this.createdAt,
    this.leasedAt,
    this.startedAt,
    this.finishedAt,
  }) : assert(id != '', 'Job id must not be empty'),
       assert(workspaceId != '', 'Job workspaceId must not be empty');

  /// Unique job id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Job kind (matches [spec].kind).
  final JobKind kind;

  /// Kind-specific payload.
  final JobSpec spec;

  /// Lifecycle status.
  final JobStatus status;

  /// Capability keys a worker MUST have to run this job.
  final Set<String> requiredCaps;

  /// Capability keys preferred (tie-breaker) for placement.
  final Set<String> preferredCaps;

  /// Scheduling priority (higher runs first within a workspace).
  final int priority;

  /// Explicit pin: this job MUST run on this worker id.
  final String? pinnedWorkerId;

  /// The worker currently holding the lease.
  final String? workerId;

  /// Lease expiry (server clock).
  final DateTime? leaseExpiresAt;

  /// Principal that submitted the job.
  final String? submittedBy;

  /// Metered worker cost in cents.
  final int costCents;

  /// Attempt count.
  final int attempts;

  /// Max attempts before surfaced as failed.
  final int maxAttempts;

  /// Last event sequence the server acked (reconnect replay).
  final int lastAckedSeq;

  /// Result payload JSON when done.
  final String? resultJson;

  /// Failure reason when failed.
  final String? error;

  /// Correlated agent id, when applicable.
  final String? agentId;

  /// Correlated conversation id, when applicable.
  final String? conversationId;

  /// Submission time.
  final DateTime createdAt;

  /// When leased.
  final DateTime? leasedAt;

  /// When the worker reported start.
  final DateTime? startedAt;

  /// When terminal.
  final DateTime? finishedAt;

  /// Whether the job is explicitly pinned to a worker.
  bool get isPinned => pinnedWorkerId != null && pinnedWorkerId!.isNotEmpty;

  /// Whether the lease has expired as of [now] (server clock).
  bool leaseExpired(DateTime now) {
    final expiry = leaseExpiresAt;
    if (expiry == null) {
      return false;
    }
    return now.isAfter(expiry);
  }

  /// Whether another attempt is permitted after a reap.
  bool get canRetry => attempts < maxAttempts;

  @override
  bool operator ==(Object other) =>
      other is Job &&
      other.id == id &&
      other.status == status &&
      other.workerId == workerId &&
      other.attempts == attempts &&
      other.leaseExpiresAt == leaseExpiresAt &&
      other.costCents == costCents &&
      other.lastAckedSeq == lastAckedSeq;

  @override
  int get hashCode => Object.hash(
    id,
    status,
    workerId,
    attempts,
    leaseExpiresAt,
    costCents,
    lastAckedSeq,
  );
}
