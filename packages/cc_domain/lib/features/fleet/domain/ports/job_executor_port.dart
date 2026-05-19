import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/fleet/domain/entities/job.dart';

/// The terminal result of a job execution (PRD 20 §8).
class JobResult {
  /// Creates a [JobResult].
  const JobResult({
    required this.success,
    this.resultJson,
    this.error,
    this.costCents = 0,
    this.eventsLost = 0,
  });

  /// A successful result.
  const JobResult.ok({this.resultJson, this.costCents = 0})
    : success = true,
      error = null,
      eventsLost = 0;

  /// A failed result.
  const JobResult.failure(this.error, {this.costCents = 0})
    : success = false,
      resultJson = null,
      eventsLost = 0;

  /// Whether the job completed successfully.
  final bool success;

  /// Kind-specific result payload JSON (artifact refs, branch, grade).
  final String? resultJson;

  /// Failure reason when [success] is false.
  final String? error;

  /// Metered worker cost in cents.
  final int costCents;

  /// Count of events dropped during a disconnect blip (surfaced in the run log
  /// as "N events lost", never silently — spec Clarifications).
  final int eventsLost;
}

/// A live job execution: an event stream plus a terminal result and a cancel
/// hook (PRD 20 §4). Whether the job ran in-process (local worker) or on a
/// remote worker, callers see the same typed [AgentProcessEvent] stream.
class JobExecution {
  /// Creates a [JobExecution].
  const JobExecution({
    required this.jobId,
    required this.events,
    required this.result,
    required this.cancel,
  });

  /// The job being executed.
  final String jobId;

  /// The same typed events the in-process path emits.
  final Stream<AgentProcessEvent> events;

  /// Completes when the job reaches a terminal state.
  final Future<JobResult> result;

  /// Requests cancellation (propagates as a lease revocation for remote jobs).
  final Future<void> Function() cancel;
}

/// Executes a leased job (PRD 20 §2). Implemented twice: a `LocalJobExecutor`
/// (the implicit local worker — a pure in-process code seam, no self-RPC) and a
/// `RemoteJobExecutor` (leases to a paired worker over the PRD 15 transport and
/// relays its event stream back).
abstract interface class JobExecutorPort {
  /// Whether this executor can run [job] right now.
  bool canExecute(Job job);

  /// Begins executing [job]. The scheduler holds/renews the lease; the executor
  /// streams events and completes the returned future with a [JobResult].
  Future<JobExecution> execute(Job job);
}
