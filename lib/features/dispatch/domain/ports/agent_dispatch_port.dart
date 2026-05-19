import 'dart:async';

import 'package:control_center/core/domain/entities/agent_run_log.dart' show AgentRunLog;
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';

/// Handle returned by [AgentDispatchPort.start], allowing per-dispatch
/// lifecycle control without affecting other concurrent dispatches.
class DispatchHandle {
  DispatchHandle({
    required this.dispatchId,
    required this.events,
    this.onStop,
  });

  /// Unique identifier for this dispatch.
  final String dispatchId;

  /// Stream of agent process events.
  final Stream<AgentProcessEvent> events;

  /// Called when [stopDispatch] is invoked for this handle.
  final Future<void> Function()? onStop;
}

/// Port for dispatching agent CLI processes.
abstract interface class AgentDispatchPort {
  /// Starts a generic agent process.
  ///
  /// [environment] is an optional env var map injected into the process /
  /// sandbox at launch. Used by the credential broker to scope tokens to
  /// just this run.
  ///
  /// [runLogId] is the database id of the [AgentRunLog] row for this
  /// invocation. Dispatchers that discover the PID asynchronously (sandboxed
  /// runs) use it to update the log with the PID once it is known.
  ///
  /// [ticketId] is the ticket this dispatch is handling, if any. Propagated
  /// into the [AgentRunLog] and the [WakeContext] so the agent knows why it
  /// was woken.
  ///
  /// [wakeContext] is the context injected into the agent's prompt so it
  /// knows why it was dispatched. Also serialized to environment variables
  /// for the CLI process.
  ///
  /// Returns a [DispatchHandle] containing the event stream and a unique
  /// [dispatchId] that can be used with [stopDispatch] to cancel only this
  /// specific dispatch without affecting other concurrent dispatches.
  DispatchHandle start({
    required String cliName,
    required String prompt,
    required String workingDirectory,
    String? modelId,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? runLogId,
    String? ticketId,
    WakeContext? wakeContext,
    ConversationMode? mode,
    Map<String, String>? environment,
    List<String>? imagePaths,
  });

  /// Stops the specific dispatch identified by [dispatchId].
  /// Other concurrent dispatches are unaffected.
  Future<void> stopDispatch(String dispatchId);

  /// Stops all dispatches for the given [agentId].
  Future<void> stopAllForAgent(String agentId);

  /// Stops ALL running dispatches. Prefer [stopDispatch] when the
  /// dispatch id is known, to avoid cross-killing concurrent dispatches.
  Future<void> stop();
}
