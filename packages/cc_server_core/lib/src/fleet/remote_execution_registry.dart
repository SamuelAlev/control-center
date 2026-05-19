import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/ports/job_executor_port.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';

/// Bridges a remote worker's RPC callbacks to the scheduler's [JobExecution]
/// (PRD 20 §4).
///
/// When the scheduler leases a job to a remote worker, [RemoteJobExecutor]
/// registers a pending execution here. The worker learns of the lease by
/// polling, executes and streams events + a completion report back over RPC;
/// those inbound calls resolve into [pushEvent]/[complete] here, which feed the
/// same event stream and result future the scheduler already awaits — so a
/// remote run drives run logs / transcripts identically to a local one.
class RemoteExecutionRegistry {
  final Map<String, _PendingExecution> _pending = {};

  /// Registers a pending execution for [job] and returns its live handle.
  JobExecution register(Job job) {
    // Closed in `_close` (via the `_pending` map) on completion/cancel.
    // ignore: close_sinks
    final controller = StreamController<AgentProcessEvent>.broadcast();
    final completer = Completer<JobResult>();
    final pending = _PendingExecution(controller, completer);
    _pending[job.id] = pending;
    return JobExecution(
      jobId: job.id,
      events: controller.stream,
      result: completer.future,
      cancel: () async {
        pending.cancelled = true;
        await _close(job.id);
      },
    );
  }

  /// Whether [jobId] has been observed as cancelled (worker should stop).
  bool isCancelled(String jobId) => _pending[jobId]?.cancelled ?? true;

  /// Pushes a worker-streamed event into the job's stream. Returns the highest
  /// sequence acked so far (for the worker's reconnect replay).
  int pushEvent(WorkerEventFrame frame) {
    final pending = _pending[frame.jobId];
    if (pending == null) {
      return 0;
    }
    if (frame.seq <= pending.lastSeq) {
      // Duplicate/replayed frame after a reconnect — already applied.
      return pending.lastSeq;
    }
    pending.lastSeq = frame.seq;
    if (!pending.controller.isClosed) {
      pending.controller.add(frame.event);
    }
    return pending.lastSeq;
  }

  /// Completes the job with the worker's terminal [report].
  Future<void> complete(JobCompletionReport report) async {
    final pending = _pending[report.jobId];
    if (pending == null) {
      return;
    }
    if (!pending.completer.isCompleted) {
      pending.completer.complete(
        report.success
            ? JobResult(
                success: true,
                resultJson: report.resultJson,
                costCents: report.costCents,
                eventsLost: report.eventsLost,
              )
            : JobResult(
                success: false,
                error: report.error ?? 'Worker reported failure.',
                costCents: report.costCents,
                eventsLost: report.eventsLost,
              ),
      );
    }
    await _close(report.jobId);
  }

  Future<void> _close(String jobId) async {
    final pending = _pending.remove(jobId);
    if (pending == null) {
      return;
    }
    if (!pending.completer.isCompleted) {
      pending.completer.complete(
        const JobResult.failure('Execution closed before completion.'),
      );
    }
    await pending.controller.close();
  }

  /// Whether a pending execution exists for [jobId].
  bool has(String jobId) => _pending.containsKey(jobId);
}

class _PendingExecution {
  _PendingExecution(this.controller, this.completer);

  final StreamController<AgentProcessEvent> controller;
  final Completer<JobResult> completer;
  int lastSeq = 0;
  bool cancelled = false;
}

/// Executor for remote workers: leases resolve into a pending [JobExecution]
/// driven by the worker's inbound RPC callbacks via [RemoteExecutionRegistry].
class RemoteJobExecutor implements JobExecutorPort {
  /// Creates a [RemoteJobExecutor].
  RemoteJobExecutor(this._registry);

  final RemoteExecutionRegistry _registry;

  @override
  bool canExecute(Job job) => true;

  @override
  Future<JobExecution> execute(Job job) async => _registry.register(job);
}
