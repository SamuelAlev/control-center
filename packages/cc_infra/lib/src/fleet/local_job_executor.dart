import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/ports/job_executor_port.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';

/// Runs one job in-process and returns its live [JobExecution].
typedef JobRunner = Future<JobExecution> Function(Job job);

/// The implicit local worker's executor (PRD 20 §2, Clarifications).
///
/// This is a **code seam, not a loopback hop** — on a solo install the job
/// dispatches straight into the in-process service (no self-RPC, no
/// serialization round-trip), so solo behaviour is byte-identical to the
/// pre-fleet path. Concrete per-kind runners are wired at the server
/// composition layer where the underlying services (dispatch, pipeline engine,
/// code indexer, golden render, eval runner) already live.
class LocalJobExecutor implements JobExecutorPort {
  /// Creates a [LocalJobExecutor] with an initial runner per supported
  /// [JobKind]. Further runners can be [register]ed after construction (e.g.
  /// the PRD 21 eval runner, once its service is built).
  LocalJobExecutor([Map<JobKind, JobRunner>? runners])
    : _runners = {...?runners};

  final Map<JobKind, JobRunner> _runners;

  /// Registers (or replaces) the runner for [kind].
  void register(JobKind kind, JobRunner runner) => _runners[kind] = runner;

  @override
  bool canExecute(Job job) => _runners.containsKey(job.kind);

  @override
  Future<JobExecution> execute(Job job) {
    final runner = _runners[job.kind];
    if (runner == null) {
      throw StateError('No local runner for job kind ${job.kind.wire}');
    }
    return runner(job);
  }
}
