import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// The coarse lifecycle phase of a dispatched **task** (one agent run).
///
/// Mirrors the unified task event stream consumed by remote clients. Wire
/// strings are snake_case so they map 1:1 onto the `notifications/task_*`
/// frames the server forwards.
enum TaskPhase {
  /// Accepted, not yet dispatched.
  queued,

  /// Handed to a backend/runtime for execution.
  dispatch,

  /// Producing output.
  running,

  /// Parked because another task holds the on-disk path lock it needs.
  waitingLocalDirectory,

  /// Mid-run progress checkpoint.
  progress,

  /// Finished successfully.
  completed,

  /// Finished with an error.
  failed,

  /// Stopped before completion.
  cancelled;

  /// Snake_case wire string (e.g. `waiting_local_directory`).
  String get wire => switch (this) {
    TaskPhase.queued => 'queued',
    TaskPhase.dispatch => 'dispatch',
    TaskPhase.running => 'running',
    TaskPhase.waitingLocalDirectory => 'waiting_local_directory',
    TaskPhase.progress => 'progress',
    TaskPhase.completed => 'completed',
    TaskPhase.failed => 'failed',
    TaskPhase.cancelled => 'cancelled',
  };
}

/// The kind of a `task:message` payload.
enum TaskMessageType {
  /// Assistant text.
  text,

  /// Reasoning / thinking output.
  thinking,

  /// A tool invocation.
  toolUse,

  /// The result of a tool invocation.
  toolResult,

  /// An error message.
  error;

  /// Snake_case wire string (e.g. `tool_use`).
  String get wire => switch (this) {
    TaskMessageType.text => 'text',
    TaskMessageType.thinking => 'thinking',
    TaskMessageType.toolUse => 'tool_use',
    TaskMessageType.toolResult => 'tool_result',
    TaskMessageType.error => 'error',
  };
}

/// Base type for the unified task-lifecycle event stream.
///
/// A "task" here is one dispatched agent run, keyed by its run-log id
/// ([taskId]). Every event carries a monotonically increasing [seq] within the
/// task so clients can order and de-duplicate frames over an unreliable link.
sealed class TaskLifecycleEvent implements DomainEvent {
  /// The run-log id of the dispatched task.
  String get taskId;

  /// Owning workspace.
  ///
  /// A task is a run of an agent and `Agent.workspaceId` is non-null, so a
  /// lifecycle frame that cannot name its workspace is a frame nothing can
  /// route or filter. Every production construction site already passed one;
  /// the parameter is now `required` so a new one cannot quietly not.
  ///
  /// `required` but still nullable, and the second half is deliberate rather
  /// than forgotten: the DISPATCH CHAIN cannot yet prove non-null.
  /// `AgentDispatchPort.start` takes `String? workspaceId` and
  /// `DispatchSession` stores it as `String?`, so tightening the event without
  /// tightening that chain would only move the `!` to the publisher. What `required` buys today is that a publisher has to SAY
  /// `null` rather than omit the argument, which is what let sites drift.
  String? get workspaceId;

  /// The dispatched agent, if known.
  String? get agentId;

  /// Monotonic sequence within the task.
  int get seq;

  /// The coarse phase this event represents.
  TaskPhase get phase;

  /// A flat wire payload shared by all lifecycle frames.
  Map<String, dynamic> toWire() => {
    'task_id': taskId,
    if (workspaceId != null) 'workspace_id': workspaceId,
    if (agentId != null) 'agent_id': agentId,
    'seq': seq,
    'phase': phase.wire,
    'occurred_at': occurredAt.toIso8601String(),
  };
}

/// The task was accepted into the queue.
class TaskQueued extends TaskLifecycleEvent {
  /// Creates a [TaskQueued].
  TaskQueued({
    required this.taskId,
    required this.seq,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });
  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;
  @override
  TaskPhase get phase => TaskPhase.queued;
}

/// The task was handed to a backend for execution.
class TaskDispatched extends TaskLifecycleEvent {
  /// Creates a [TaskDispatched].
  TaskDispatched({
    required this.taskId,
    required this.seq,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });
  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;
  @override
  TaskPhase get phase => TaskPhase.dispatch;
}

/// The task started producing output.
class TaskRunning extends TaskLifecycleEvent {
  /// Creates a [TaskRunning].
  TaskRunning({
    required this.taskId,
    required this.seq,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });
  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;
  @override
  TaskPhase get phase => TaskPhase.running;
}

/// The task is parked because another task owns the on-disk path lock it needs.
class TaskWaitingLocalDirectory extends TaskLifecycleEvent {
  /// Creates a [TaskWaitingLocalDirectory].
  TaskWaitingLocalDirectory({
    required this.taskId,
    required this.seq,
    required this.lockedPath,
    this.holderTaskId,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });

  /// The on-disk path the task is waiting to acquire.
  final String lockedPath;

  /// The task currently holding the lock, if known.
  final String? holderTaskId;

  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;
  @override
  TaskPhase get phase => TaskPhase.waitingLocalDirectory;

  @override
  Map<String, dynamic> toWire() => {
    ...super.toWire(),
    'locked_path': lockedPath,
    if (holderTaskId != null) 'holder_task_id': holderTaskId,
  };
}

/// A mid-run progress checkpoint.
class TaskProgress extends TaskLifecycleEvent {
  /// Creates a [TaskProgress].
  TaskProgress({
    required this.taskId,
    required this.seq,
    this.note,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });

  /// Optional short human-readable progress note.
  final String? note;

  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;
  @override
  TaskPhase get phase => TaskPhase.progress;

  @override
  Map<String, dynamic> toWire() => {
    ...super.toWire(),
    if (note != null) 'note': note,
  };
}

/// The task finished successfully.
class TaskCompleted extends TaskLifecycleEvent {
  /// Creates a [TaskCompleted].
  TaskCompleted({
    required this.taskId,
    required this.seq,
    this.summary,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });

  /// Optional terminal summary.
  final String? summary;

  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;
  @override
  TaskPhase get phase => TaskPhase.completed;

  @override
  Map<String, dynamic> toWire() => {
    ...super.toWire(),
    if (summary != null) 'summary': summary,
  };
}

/// The task finished with an error.
class TaskFailed extends TaskLifecycleEvent {
  /// Creates a [TaskFailed].
  TaskFailed({
    required this.taskId,
    required this.seq,
    required this.errorMessage,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });

  /// The failure message.
  final String errorMessage;

  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;
  @override
  TaskPhase get phase => TaskPhase.failed;

  @override
  Map<String, dynamic> toWire() => {
    ...super.toWire(),
    'error_message': errorMessage,
  };
}

/// The task was cancelled before completion.
class TaskCancelled extends TaskLifecycleEvent {
  /// Creates a [TaskCancelled].
  TaskCancelled({
    required this.taskId,
    required this.seq,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });
  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;
  @override
  TaskPhase get phase => TaskPhase.cancelled;
}

/// A streamed message produced by the task (text/thinking/tool/error), with a
/// per-message [seq] so clients can order and de-duplicate the transcript.
class TaskMessage extends TaskLifecycleEvent {
  /// Creates a [TaskMessage].
  TaskMessage({
    required this.taskId,
    required this.seq,
    required this.messageType,
    required this.content,
    required this.workspaceId,
    this.agentId,
    required this.occurredAt,
  });

  /// The kind of message.
  final TaskMessageType messageType;

  /// The message payload.
  final String content;

  @override
  final String taskId;
  @override
  final int seq;
  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final DateTime occurredAt;

  /// A `task:message` is reported under the [TaskPhase.progress] phase.
  @override
  TaskPhase get phase => TaskPhase.progress;

  @override
  Map<String, dynamic> toWire() => {
    ...super.toWire(),
    'message_type': messageType.wire,
    'content': content,
  };
}
