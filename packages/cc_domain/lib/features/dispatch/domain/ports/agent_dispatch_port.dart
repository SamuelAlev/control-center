import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show AgentRunLog;
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart'
    show ClaudeAccountRefusal;
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';

/// Handle returned by `AgentDispatchPort.start`, allowing per-dispatch
/// lifecycle control without affecting other concurrent dispatches.
class DispatchHandle {
  /// Creates a handle for the given dispatch.
  DispatchHandle({required this.dispatchId, required this.events, this.onStop});

  /// Unique identifier for this dispatch.
  final String dispatchId;

  /// Stream of agent process events.
  final Stream<AgentProcessEvent> events;

  /// Called when `stopDispatch` is invoked for this handle.
  final Future<void> Function()? onStop;
}

/// Port for dispatching agent CLI processes.
abstract interface class AgentDispatchPort {
  /// Starts a generic agent process.
  ///
  /// [environment] scopes credential-broker tokens to this run.
  /// [runLogId] is the [AgentRunLog] id; sandboxed runs write the PID once known.
  /// [ticketId] is stamped on the log and [WakeContext] when set.
  /// [wakeContext] is why the agent was woken, also copied into the CLI env.
  /// [silenceTimeoutMinutes] overrides the per-mode default; null keeps it.
  /// [agentConfigDir] is mounted read-only beside writable [workingDirectory]
  /// so overlay symlinks resolve and the agent cannot edit its own config;
  /// null mounts [workingDirectory] only.
  /// [agentName] stamps the git author as `<name> (agent)`; null uses the agent id.
  /// [requestedByUserId] sets the co-author trailer and credential lane; null
  /// attributes the run to the server owner.
  /// [userText] is the verbatim message for slash detection (`/plan`, `/goal`,
  /// `/loop`, `/skill:<name>`). [prompt] arrives wrapped in `<context>`, so a
  /// leading-slash test against it never matches; null [userText] falls back
  /// to [prompt].
  /// [costCapCents] is the priced spend cap (a goal run passes its remaining
  /// budget). Null keeps the dispatcher default; adapters that cannot price
  /// usage ignore it.
  /// [claudeConfigDir] names the Claude credential directory; other adapters
  /// ignore it. Null lets the CLI find its own account, which on macOS reads
  /// as logged out because the sandbox denies the keychain.
  /// Returns a [DispatchHandle] whose `dispatchId` stops only this dispatch.
  DispatchHandle start({
    required String cliName,
    required String prompt,
    required String workingDirectory,
    String? userText,
    String? modelId,
    String? agentId,
    String? agentName,
    String? workspaceId,
    String? conversationId,
    String? spaceId,
    String? runLogId,
    String? ticketId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    Mode? mode,
    int? silenceTimeoutMinutes,
    Map<String, String>? environment,
    List<String>? imagePaths,
    String? effortLevel,
    String? agentConfigDir,
    List<String>? adapterArgsOverride,
    Map<String, String>? adapterEnvOverride,
    String? claudeConfigDir,
    List<({String accountId, String configDir})>? claudeAccounts,
    Future<void> Function({required String accountId, DateTime? resetsAt})?
    onClaudeAccountExhausted,
    Future<void> Function({required String accountId, String? reason})?
    onClaudeAccountAuthFailed,
    ClaudeAccountRefusal? claudeAccountsSpent,
    Future<List<String>?> Function({
      String? workspaceId,
      String? agentId,
      required String providerId,
      required List<String> credentialIds,
    })?
    onResolveHarnessRotation,
    Future<void> Function({
      required String providerId,
      required String credentialId,
    })?
    onHarnessCredentialExhausted,
    int? costCapCents,
  });

  /// Stops the specific dispatch identified by [dispatchId].
  /// Other concurrent dispatches are unaffected.
  Future<void> stopDispatch(String dispatchId);

  /// Stops all dispatches for the given [agentId].
  Future<void> stopAllForAgent(String agentId);

  /// Delivers a mid-run steering [message] to the dispatch identified by
  /// [dispatchId] (built-in harness only). The message is injected at the next
  /// safe turn boundary so a user can nudge a running agent without starting a
  /// new dispatch; [followUp] true routes it to run only once the agent would
  /// otherwise stop. Returns true when a live dispatch received it.
  Future<bool> steerDispatch(
    String dispatchId,
    String message, {
    bool followUp = false,
  });

  /// Pauses the dispatch's built-in harness loop at its next clean turn
  /// boundary (take-over, PRD 16 §8). Returns true when a pausable live run
  /// accepted it; false for finished runs or external-CLI transports (no
  /// safe boundary — callers fall back to stopping).
  Future<bool> pauseDispatch(String dispatchId);

  /// Releases a paused dispatch (hand-back). Returns true when a live
  /// dispatch received it.
  Future<bool> resumeDispatch(String dispatchId);

  /// Stops ALL running dispatches. Prefer [stopDispatch] when the
  /// dispatch id is known, to avoid cross-killing concurrent dispatches.
  Future<void> stop();
}
