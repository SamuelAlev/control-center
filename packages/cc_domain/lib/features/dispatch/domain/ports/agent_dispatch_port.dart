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
  /// [silenceTimeoutMinutes] is the agent's per-agent silence-timeout
  /// override. When null the dispatcher falls back to the per-mode default.
  ///
  /// [agentConfigDir] is the agent's global config dir (AGENTS.md + `.agents`
  /// source). When provided, the dispatcher mounts it read-only alongside the
  /// writable [workingDirectory] (the per-agent overlay cwd) so the overlay's
  /// symlinks resolve and the agent cannot tamper with its own config/skills at
  /// runtime. Null falls back to mounting [workingDirectory] only.
  ///
  /// [agentName] is the agent's display name, used to stamp an honest per-run
  /// git author identity (`<name> (agent)`) into the process environment.
  /// Null falls back to the agent id.
  ///
  /// [requestedByUserId] is the human on whose behalf the run executes; it
  /// drives the commit co-author trailer and per-user credential selection.
  /// Null attributes the run to the server owner.
  ///
  /// [userText] is the user's message verbatim, before context layering.
  /// [prompt] arrives wrapped as `<context>…</context>\n\n<text>`, so a
  /// leading-slash test against it never matches — pass [userText] so built-in
  /// slash commands (`/plan`, `/goal`, `/loop`, `/skill:<name>`) are
  /// recognized.
  /// Null falls back to [prompt] (correct for callers that do no layering).
  ///
  /// [costCapCents] overrides the default per-run priced cost cap (dispatch
  /// adapters that can price usage mid-run stop the run once its spend
  /// crosses the cap). The goal supervisor threads the goal's remaining
  /// budget so a segment cannot overshoot an explicit `/goal --budget`.
  /// Null keeps the dispatcher's default cap; adapters that cannot price
  /// usage ignore it.
  ///
  /// [claudeConfigDir] selects which Claude Code account the run signs in as,
  /// by naming the directory the CLI reads its credential from. Adapters that
  /// do not drive Claude Code ignore it. Null means "whatever the CLI would
  /// find itself", which is only correct where Control Center manages no
  /// accounts — on macOS the sandbox denies the keychain the CLI would
  /// otherwise use, so a null here reads to the operator as being logged out.
  ///
  /// Returns a [DispatchHandle] containing the event stream and a unique
  /// `dispatchId` that can be used with `stopDispatch` to cancel only this
  /// specific dispatch without affecting other concurrent dispatches.
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
