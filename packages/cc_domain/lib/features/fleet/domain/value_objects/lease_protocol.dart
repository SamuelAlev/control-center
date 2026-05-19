import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';

/// The fleet wire-protocol version (PRD 20 Clarifications).
///
/// Worker and server exchange this at pairing and on every reconnect; a
/// mismatch marks the worker `incompatible` and withholds leases — never a
/// wire-format guess. Workers version with the server release (no compat
/// window, per the pre-1.0 no-compat rule).
const int kFleetProtocolVersion = 1;

/// A worker's self-description sent at registration and heartbeat (PRD 20 §1).
class WorkerRegistration {
  /// Creates a [WorkerRegistration].
  const WorkerRegistration({
    required this.name,
    required this.capsJson,
    required this.protocolVersion,
    this.platform = 'unknown',
  });

  /// Parses from a wire map.
  factory WorkerRegistration.fromJson(Map<String, dynamic> json) =>
      WorkerRegistration(
        name: json['name'] as String? ?? 'worker',
        capsJson: json['capsJson'] as String? ?? '{}',
        protocolVersion: (json['protocolVersion'] as num?)?.toInt() ?? 0,
        platform: json['platform'] as String? ?? 'unknown',
      );

  /// Operator-facing worker name.
  final String name;

  /// JSON-encoded `WorkerCapabilities`.
  final String capsJson;

  /// The worker's wire protocol version.
  final int protocolVersion;

  /// Coarse platform string.
  final String platform;

  /// Serializes to a wire map.
  Map<String, dynamic> toJson() => {
    'name': name,
    'capsJson': capsJson,
    'protocolVersion': protocolVersion,
    'platform': platform,
  };
}

/// A lease handed to a worker: everything it needs to run one job (PRD 20 §2).
///
/// Secrets are the job-scoped, short-lived credentials in [env] (never the
/// owner's PAT) — held in memory, expired at job end (PRD 20 §5).
class LeaseOffer {
  /// Creates a [LeaseOffer].
  const LeaseOffer({
    required this.jobId,
    required this.workspaceId,
    required this.kind,
    required this.specJson,
    required this.leaseExpiresAtIso,
    this.env = const {},
    this.repoRemote,
    this.headSha,
    this.branch,
  });

  /// Parses from a wire map.
  factory LeaseOffer.fromJson(Map<String, dynamic> json) => LeaseOffer(
    jobId: json['jobId'] as String? ?? '',
    workspaceId: json['workspaceId'] as String? ?? '',
    kind: json['kind'] as String? ?? 'agentRun',
    specJson: json['specJson'] as String? ?? '{}',
    leaseExpiresAtIso: json['leaseExpiresAt'] as String? ?? '',
    env: ((json['env'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    ),
    repoRemote: json['repoRemote'] as String?,
    headSha: json['headSha'] as String?,
    branch: json['branch'] as String?,
  );

  /// The job id.
  final String jobId;

  /// The owning workspace.
  final String workspaceId;

  /// The job kind wire string.
  final String kind;

  /// The kind-specific spec payload JSON.
  final String specJson;

  /// Lease expiry (server clock, ISO-8601). The worker keeps executing until
  /// this instant if it loses contact (short TTL; cheap renewal).
  final String leaseExpiresAtIso;

  /// Job-scoped credential env to inject (held in memory only).
  final Map<String, String> env;

  /// Canonical remote to materialize the worktree from.
  final String? repoRemote;

  /// Pinned SHA to materialize at.
  final String? headSha;

  /// Branch to check the worktree out on.
  final String? branch;

  /// Serializes to a wire map.
  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'workspaceId': workspaceId,
    'kind': kind,
    'specJson': specJson,
    'leaseExpiresAt': leaseExpiresAtIso,
    if (env.isNotEmpty) 'env': env,
    if (repoRemote != null) 'repoRemote': repoRemote,
    if (headSha != null) 'headSha': headSha,
    if (branch != null) 'branch': branch,
  };
}

/// A sequenced event a worker streams back for a running job (PRD 20 §3, §4).
///
/// The [seq] is monotonic per job so the server acks a high-water mark and the
/// worker replays from `lastAckedSeq` on reconnect (bounded ring buffer).
class WorkerEventFrame {
  /// Creates a [WorkerEventFrame].
  const WorkerEventFrame({
    required this.jobId,
    required this.seq,
    required this.event,
  });

  /// Parses from a wire map (reconstructs the typed event).
  factory WorkerEventFrame.fromJson(Map<String, dynamic> json) =>
      WorkerEventFrame(
        jobId: json['jobId'] as String? ?? '',
        seq: (json['seq'] as num?)?.toInt() ?? 0,
        event: AgentProcessEventCodec.fromWire(
          (json['event'] as Map).cast<String, dynamic>(),
        ),
      );

  /// The job the event belongs to.
  final String jobId;

  /// Monotonic per-job sequence number.
  final int seq;

  /// The typed process event.
  final AgentProcessEvent event;

  /// Serializes to a wire map.
  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'seq': seq,
    'event': AgentProcessEventCodec.toWire(event),
  };
}

/// A worker's terminal report for a job (PRD 20 §8).
class JobCompletionReport {
  /// Creates a [JobCompletionReport].
  const JobCompletionReport({
    required this.jobId,
    required this.success,
    this.resultJson,
    this.error,
    this.costCents = 0,
    this.eventsLost = 0,
    this.lastSeq = 0,
  });

  /// Parses from a wire map.
  factory JobCompletionReport.fromJson(Map<String, dynamic> json) =>
      JobCompletionReport(
        jobId: json['jobId'] as String? ?? '',
        success: json['success'] as bool? ?? false,
        resultJson: json['resultJson'] as String?,
        error: json['error'] as String?,
        costCents: (json['costCents'] as num?)?.toInt() ?? 0,
        eventsLost: (json['eventsLost'] as num?)?.toInt() ?? 0,
        lastSeq: (json['lastSeq'] as num?)?.toInt() ?? 0,
      );

  /// The job id.
  final String jobId;

  /// Whether the job succeeded.
  final bool success;

  /// Result payload JSON on success.
  final String? resultJson;

  /// Failure reason on failure.
  final String? error;

  /// Metered cost in cents.
  final int costCents;

  /// Events dropped during a disconnect (surfaced, never silent).
  final int eventsLost;

  /// The last event sequence emitted (final ack point).
  final int lastSeq;

  /// Serializes to a wire map.
  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'success': success,
    if (resultJson != null) 'resultJson': resultJson,
    if (error != null) 'error': error,
    'costCents': costCents,
    'eventsLost': eventsLost,
    'lastSeq': lastSeq,
  };
}
