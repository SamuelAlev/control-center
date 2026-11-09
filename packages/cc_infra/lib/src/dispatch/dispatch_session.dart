import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart'
    as domain_purpose;
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/capability_preamble.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart'
    show AgentPromptParts, DeliveredPromptContext;
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_approval_copy.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart'
    show kProposeOnlyReason;
import 'package:cc_domain/features/guardrails/domain/services/action_request_extractor.dart';
import 'package:cc_domain/features/guardrails/domain/services/autonomy_composition.dart';
import 'package:cc_domain/features/guardrails/domain/services/shell_action_classifier.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/claude_idle_compactor.dart';
import 'package:cc_infra/src/dispatch/claude_refusal_message.dart';
import 'package:cc_infra/src/dispatch/claude_run_state.dart';
import 'package:cc_infra/src/dispatch/claude_subagent_runs.dart';
import 'package:cc_infra/src/dispatch/dispatch_session_deps.dart';
import 'package:cc_infra/src/dispatch/harness_run_controller.dart';
import 'package:cc_infra/src/dispatch/read_media_capture.dart';
import 'package:cc_infra/src/dispatch/render_media_image_refs.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/dispatch/subagent_pilot_gate.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/harness/harness_run_accounting.dart';
import 'package:cc_infra/src/harness/harness_run_factory.dart';
import 'package:cc_infra/src/harness/harness_system_prompt.dart';
import 'package:cc_infra/src/harness/harness_tool_registry_builder.dart';
import 'package:cc_infra/src/harness/harness_tool_surface.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/media/media_read_scope.dart';
import 'package:cc_infra/src/messaging/prompt_attachments.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/sandboxing/claude_native_session.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/run_log_writer.dart';
import 'package:cc_infra/src/skills/active_repo_tracker.dart';
import 'package:cc_infra/src/skills/repo_skill_projector.dart';
import 'package:cc_infra/src/util/command_redaction.dart';
import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

export 'package:cc_infra/src/dispatch/dispatch_session_deps.dart';

part 'dispatch_session_acp.dart';
part 'dispatch_session_harness.dart';
part 'dispatch_session_subagent.dart';
part 'dispatch_session_claude_cli.dart';
part 'dispatch_session_claude_control.dart';
part 'dispatch_session_claude_credentials.dart';
part 'dispatch_session_gateway.dart';
part 'dispatch_session_run_context.dart';
part 'dispatch_session_account_pool.dart';

/// Default per-run priced cost cap, in cents: what one unattended segment of
/// an autonomous command (/goal, /loop) may burn before the loop's external
/// budget check stops it mid-run. The goal supervisor threads a goal's
/// REMAINING budget (capped at this default) via
/// [DispatchSession.costCapCents] so an explicit `/goal --budget` is never
/// overshot by a whole segment.
const defaultRunCostCapCents = 500;

/// The run summary for a run a person stopped, whichever stop path ran: the
/// dispatch session's terminate and the dispatch service's run-row close.
const kRunStoppedByUserSummary = 'Stopped by user';

/// The run-log reason for runs still in flight when the server shut down.
const kRunStoppedByShutdownSummary = 'Stopped: the server shut down';

/// A session that dispatches and manages a single sandboxed agent run.
class DispatchSession implements SteeringSessionView {
  /// Creates a [DispatchSession] for launching and monitoring a sandboxed
  /// agent process.
  DispatchSession({
    required this.deps,
    required this.onResolveHandle,
    required this.onScheduleCooldown,
    required this.dispatchId,
    required this.cliName,
    required this.prompt,
    this.userText,
    this.promptParts,
    this.claudeResumeReset = false,
    DateTime? runStartedAt,
    this.promptImageRefs = const [],
    required this.agentDirHostPath,
    required this.modelId,
    required this.callerEnv,
    required this.agentId,
    required this.workspaceId,
    required this.conversationId,
    this.spaceId,
    required this.runLogId,
    required this.mode,
    this.agentName,
    this.requestedByUserId,
    this.ticketId,
    this.wakeContext,
    this.silenceTimeoutMinutes,
    this.effortLevel,
    this.contextWindowTokens,
    this.agentConfigDir,
    this.adapterArgsOverride = const [],
    this.adapterEnvOverride = const {},
    this.claudeConfigDir,
    this.claudeAccounts = const [],
    this.onClaudeAccountExhausted,
    this.onClaudeAccountAuthFailed,
    this.claudeAccountsSpent,
    this.onResolveHarnessRotation,
    this.onHarnessCredentialExhausted,
    this.costCapCents,
    this.resolveBinary = resolveBinaryPath,
  }) : runStartedAt = runStartedAt ?? DateTime.now();

  /// Fired once per run, the moment this session's steering queue becomes
  /// drainable: at the top of [_runHarness], or once a `claude -p` run's stdin
  /// lane is open. The steering queue service uses it to attach drain
  /// notifications and flush persisted queued rows into the run.
  ///
  /// Late-bound (mutable) because the adapter assigns it right after
  /// constructing the session — the natural wiring point lives after the
  /// variable's own declaration.
  void Function()? onHarnessStarted;

  /// Per-run priced cost cap override, in cents. The goal supervisor threads
  /// the goal's REMAINING budget (capped at the default) so an explicit
  /// `/goal --budget` cannot be overshot by a full segment. Null keeps
  /// [defaultRunCostCapCents].
  final int? costCapCents;

  /// Per-agent silence-timeout override in minutes. When null the per-mode
  /// default applies.
  final int? silenceTimeoutMinutes;

  /// Shared sandbox and credential dependencies.
  final SandboxDispatchDeps deps;

  /// The agent's GLOBAL config dir (AGENTS.md + `.agents` source), mounted
  /// read-only alongside the writable [agentDirHostPath] cwd so the per-agent
  /// overlay's symlinks resolve and the agent cannot tamper with its own
  /// config/skills at runtime. Null (e.g. oneshot / fallback) mounts only the
  /// cwd.
  final String? agentConfigDir;

  /// Resolves a sandbox handle for the session.
  final Future<SandboxHandle> Function({
    required String sessionId,
    required SandboxSpec spec,
    required void Function(AgentProcessEvent) emit,
  })
  onResolveHandle;

  /// Called to schedule a cooldown period after the session ends.
  final void Function(String sessionId) onScheduleCooldown;

  /// Unique identifier for this dispatch.
  final String dispatchId;

  /// CLI binary name (e.g. the agent CLI like `claude`).
  final String cliName;

  /// Prompt text sent to the agent.
  final String prompt;

  /// Blob references (`blob:sha256:<hex>`) for images the human attached to
  /// the message that triggered this run — a pasted screenshot.
  ///
  /// References rather than bytes: the composer already uploaded them, so the
  /// dispatch path re-reads them from the workspace's own blob directory
  /// instead of carrying base64 through the dispatch port.
  final List<String> promptImageRefs;

  /// The user's message verbatim, before context layering.
  ///
  /// [prompt] arrives wrapped as `<context>…</context>\n\n<text>` (see
  /// `PromptBuilder.build`), so testing IT for a leading slash always fails.
  /// Built-in slash commands are parsed from this field; null falls back to
  /// [prompt] for callers that do no layering.
  final String? userText;

  /// The structured prompt this dispatch was prepared from: standing brief,
  /// per-turn context and the conversation window, each with a revision
  /// fingerprint.
  ///
  /// When — and only when — a persisted native Claude session exists whose
  /// scope matches this run, the session resumes it with `--resume <id>` and
  /// sends the delta built by [AgentPromptParts.deltaPromptFor] against the
  /// conversation revision THAT session has already been delivered: the new
  /// per-turn context, the user's message, and the conversation window again if
  /// it changed while this session was parked. With no matching session (or no
  /// cursor to trust) the full [prompt] is sent instead, so context can never be
  /// lost on a first turn or after a fork.
  ///
  /// Null means never resume — the pre-resume behaviour, byte for byte.
  final AgentPromptParts? promptParts;

  /// When the RUN started, shared by every runner.
  ///
  /// The zero for offset-based stage timings, and the same instant the run log
  /// persists as `startedAt` — so an adapter that only launches after a
  /// directory-lock wait reports latency against the run's beginning rather
  /// than restarting the clock. Initialized once, here, so nothing can move it.
  final DateTime runStartedAt;

  /// Drops any persisted native session for this scope before deciding whether
  /// to resume, so this dispatch starts (and then records) a fresh native
  /// session. This is the explicit RESET/FORK switch: a new conversation
  /// already forks by scope, but a caller that wants a fresh session inside
  /// the same conversation asks for it here rather than silently inheriting
  /// one.
  final bool claudeResumeReset;

  /// Host-side path to the agent's working directory.
  final String agentDirHostPath;

  /// Optional model identifier to pass to the CLI.
  final String? modelId;

  /// Environment variables from the calling context.
  final Map<String, String> callerEnv;

  /// Optional agent identifier for capability lookup.
  final String? agentId;

  /// The agent's display name for lifecycle events and operator prompts.
  final String? agentName;

  /// The human on whose behalf this run executes. Resolves the Git author and
  /// committer, attribution preference and forge credential scope; null uses
  /// the server owner.
  final String? requestedByUserId;

  /// Optional workspace identifier.
  @override
  final String? workspaceId;

  /// Optional conversation identifier for scoped credential minting.
  @override
  final String? conversationId;

  /// The space that conversation lives in. Threaded separately because a
  /// conversation owns its own uuid: it is what the MCP call scope fills
  /// `space_id` from, and guardrail resolution keys on the space.
  @override
  final String? spaceId;

  /// Optional run-log identifier for persistent logging.
  @override
  final String? runLogId;

  /// Conversation mode (e.g. `plan` or `execute`).
  final Mode mode;

  /// Optional ticketing system ticket identifier.
  final String? ticketId;

  /// Optional wake context for agent resumption.
  final WakeContext? wakeContext;

  /// Resolved reasoning-effort level id (e.g. 'low', 'xhigh'), from the
  /// agent's model-driven effort. Passed to the backend's buildArgs.
  final String? effortLevel;

  /// The agent's configured context window in tokens, or null to use the
  /// model's. The built-in harness caps its own window here; for Claude Code,
  /// whose window comes from the `--model` id, it is only what readings are
  /// measured against.
  final int? contextWindowTokens;

  /// Per-adapter argv appended after the backend's own args (e.g. YOLO /
  /// skip-permissions flags).
  final List<String> adapterArgsOverride;

  /// Per-adapter env override (e.g. API keys). Merged on top of the backend's
  /// default env; caller/broker env still wins for security-critical keys.
  final Map<String, String> adapterEnvOverride;

  /// The Control-Center-managed `CLAUDE_CONFIG_DIR` this run's Claude Code
  /// account lives in. Null runs the CLI on whatever it would find itself.
  ///
  /// It is threaded as a typed field rather than left to [adapterEnvOverride]
  /// because it has to reach TWO places that must agree: the child's
  /// environment AND the sandbox's writable set
  /// ([SandboxSpec.runnerStateDirs]). Setting only the first is the bug this
  /// exists to fix — on macOS the Seatbelt profile denies reads under
  /// `~/Library/Keychains`, and a denied keychain lookup does not error, it
  /// reports "item not found", so Claude Code says `Not logged in · Please run
  /// /login` on a machine where the operator is signed in.
  final String? claudeConfigDir;

  /// Every account this run may use, best first — the pool resolved for this
  /// dispatch. [claudeConfigDir] is the first one's directory.
  ///
  /// Empty keeps the single-account behaviour. More than one entry is what
  /// makes a usage limit survivable: the run re-executes on the next account
  /// rather than ending the turn, which is what lets a `/goal` keep going.
  final List<({String accountId, String configDir})> claudeAccounts;

  /// Records that an account hit its plan limit, so later dispatches skip it
  /// until the reported reset. Null disables the memory, and each run then
  /// rediscovers the limit — wasting one turn per dispatch.
  final Future<void> Function({required String accountId, DateTime? resetsAt})?
  onClaudeAccountExhausted;

  /// Records that an account's credential no longer authenticates (a `401`
  /// from an expired OAuth token, a signed-out directory), so later dispatches
  /// stop leading with it and the operator is told which account to sign back
  /// in. Null disables the memory, and every dispatch then spends a turn
  /// rediscovering it.
  final Future<void> Function({required String accountId, String? reason})?
  onClaudeAccountAuthFailed;

  /// Orders a provider's stored credentials for THIS run — the harness half of
  /// account pools.
  ///
  /// Given every credential the store holds for the provider, it returns them
  /// in the order this dispatch should spend them: the workspace's (or the
  /// agent's) attached set, in its configured order, with the round-robin
  /// position and any cooling-off keys already applied. Null leaves the chain
  /// exactly as it was before pools existed.
  final Future<AccountPoolOrder> Function({
    String? workspaceId,
    String? agentId,
    required String providerId,
    required List<String> credentialIds,
  })?
  onResolveHarnessRotation;

  /// Records that a harness credential ran out of quota, so later dispatches
  /// start elsewhere instead of rediscovering it at the cost of a request.
  final Future<void> Function({
    required String providerId,
    required String credentialId,
  })?
  onHarnessCredentialExhausted;

  /// Set when every attached Claude Code account is out of plan headroom.
  ///
  /// Checked inside the Claude transport only, so a workspace whose pool is
  /// spent can still run an agent on a different adapter — the pool describes
  /// one runner's credentials, not the workspace's ability to work.
  final AccountPoolRefusal? claudeAccountsSpent;

  /// Resolves a CLI binary name to its absolute path. Defaults to the real
  /// [resolveBinaryPath] host probe; tests inject a stub so the dispatch flow
  /// can be exercised without the adapter binary (e.g. `claude`) installed.
  final Future<String?> Function(String binary) resolveBinary;

  /// Active ACP client and the agent's stdin lane, when the resolved backend
  /// is ACP. Held so stdout routes to the client and a stop can end the turn.
  AcpClient? _acpClient;
  // Closed by the ACP transport and by [_teardownAcp].
  // ignore: close_sinks
  StreamController<String>? _acpStdin;

  /// Stream controller for [AgentProcessEvent]s emitted by this session.
  final StreamController<AgentProcessEvent> controller =
      StreamController<AgentProcessEvent>();

  /// Handle to the scoped credential minted for this run.
  String? credHandle;

  /// This run's registration with the agent run gateway: the push proxy and
  /// the Claude Code hook endpoint that put the action policy between the
  /// agent's shell and the forge. Null when no gateway is wired or reachable;
  /// Claude then installs a blocking Bash hook instead of skipping policy.
  AgentRunLease? _gatewayLease;

  /// What this run resolved once at its start; see [_RunContext].
  _RunContext _run = _RunContext.beforeStart;

  /// Subscription to sandbox events from the underlying process.
  StreamSubscription<SandboxEvent>? eventsSub;

  /// Whether a [DoneEvent] has been emitted.
  bool emittedDone = false;

  /// Monotonic sequence for this task's lifecycle events (run-log scoped).
  int _taskSeq = 0;

  /// Whether [TaskRunning] has been emitted for this run.
  bool _emittedTaskRunning = false;

  /// The most recent error message seen, so completion can emit [TaskFailed].
  String? _lastTaskError;

  /// Whether the CLI attempt currently running has already written to stderr.
  ///
  /// Set by [_forwardSandboxEvent], reset before every `exec`. A CLI that
  /// explains itself ("Error: Unknown option: --mcp-config") and then exits 1
  /// does not also need `[sandbox] claude exited with code 1` under it — the
  /// generic line adds a second scary row saying strictly less than the first.
  /// It stays an [ErrorEvent] when the process died SILENTLY, because then it
  /// is the only thing the operator gets; otherwise it degrades to a
  /// [DebugEvent] (still in the run log, out of the transcript).
  bool _sawProcessStderr = false;

  /// PID of the forked sandbox process, set once available.
  int? pid;

  /// The sandbox the CLI transports are currently executing in.
  ///
  /// Held so [terminate] and the silence watchdog can actually STOP the child.
  /// Both used to only stamp the run row as failed: the CLI kept running, the
  /// `run()` future stayed parked on `process.exitCode`, and the cooldown
  /// destroy (which is scheduled only after `run()` completes) therefore never
  /// fired — the handle stayed in the adapter's map for the process lifetime.
  SandboxHandle? _activeHandle;

  /// The `claude -p` transport's per-run state.
  final ClaudeRunState _claude = ClaudeRunState();

  /// Timestamp of the most recent output from the agent.
  DateTime? lastOutputAt;

  /// Periodic timer that checks for silence and terminates if exceeded.
  Timer? silenceTimer;

  /// Only waits from this run may suspend its inactivity watchdog.
  final Set<String> _pendingHumanWaitIds = {};
  StreamSubscription<AgentAwaitingInput>? _humanWaitStartSub;
  StreamSubscription<AgentInputResolved>? _humanWaitEndSub;

  /// Closing the last wait gives the agent a full silence window to resume,
  /// even if its most recent output predates the time it spent waiting.
  DateTime? _lastHumanWaitResolvedAt;

  /// Interval between silence checks.
  static const Duration silenceCheckInterval = Duration(seconds: 30);

  /// Duration of silence after which the session is terminated.
  static const Duration defaultSilenceThreshold = Duration(minutes: 15);

  /// Per-mode silence defaults (review/plan/orchestrate are read-mostly and
  /// should give up sooner than a free-form chat session).
  static const Map<Mode, int> _perModeSilenceMinutes = {
    Mode.chat: 15,
    Mode.review: 10,
    Mode.plan: 10,
    Mode.orchestrate: 15,
  };

  /// The effective silence threshold: per-agent override → per-mode default
  /// → 15 minutes.
  Duration get silenceThreshold {
    final override = silenceTimeoutMinutes;
    if (override != null && override >= 1) {
      return Duration(minutes: override);
    }
    return Duration(minutes: _perModeSilenceMinutes[mode] ?? 15);
  }

  final RunLogWriter _logWriter = RunLogWriter();

  /// Cancels the built-in harness loop (and any in-flight subagent loops, which
  /// share this token) when the session is terminated.
  final CancellationTokenSource _cancelSource = CancellationTokenSource();

  /// File-read authority shared by the run's built-in and MCP media tools.
  MediaReadScope? get mediaReadScope {
    if (_cancelSource.isCancelled || controller.isClosed) {
      return null;
    }
    return MediaReadScope(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
      abandoned: _cancelSource.token.whenCancelled,
    );
  }

  /// Mid-run steering inbox. A client can push a message here while a run is
  /// active (via [steer]); the built-in harness drains it at the next turn
  /// boundary and a `claude -p` run writes it to the process's stdin as it
  /// arrives, so the user can nudge a running agent without starting a new
  /// dispatch. Unused by ACP.
  final SteeringQueue _steering = SteeringQueue();

  /// The run's steering inbox, exposed for the host's queue surgery: the
  /// steering queue service pushes ref-carrying messages, reorders them and
  /// attaches drain notifications through this handle. Mutating it is safe
  /// between turns; the loop reads it only at turn boundaries.
  @override
  SteeringQueue get steeringQueue => _steering;

  /// The built-in harness loop's turn-boundary control: its pause gate
  /// (take-over, PRD 16 §8), whether it is live, and what it restored and
  /// activated. Unused by external-CLI transports.
  final HarnessRunController _harness = HarnessRunController();

  /// Whether a built-in harness loop is currently driving this session (the
  /// only transport that can pause at a turn boundary).
  bool get isHarnessActive => _harness.isActive;

  /// Whether a message pushed into [steeringQueue] now will reach the run:
  /// a built-in harness loop is driving the session, or a `claude -p` turn
  /// still has its stdin open. Steering gates on this so ACP (and a Claude
  /// turn that already ended) reports "cannot" instead of accepting a message
  /// into a queue nobody reads.
  @override
  bool get acceptsSteering => _harness.isActive || _claude.stdin != null;

  /// Lets sibling subagents of one prompt shape read the cache entry the
  /// first of them writes; see [SubagentPilotGate].
  final SubagentPilotGate _subagentPilots = SubagentPilotGate();

  /// The resident set every subagent gets, whatever its profile.
  ///
  /// Deliberately profile-INDEPENDENT. A child's resident block is the head of
  /// its cache prefix, and prefixes are shared per workspace, so every child
  /// that emits the same one reads an entry some earlier child already wrote.
  /// Varying it per profile would fragment that into one cold prefix per
  /// profile for no gain — the profile already decided what the child may call
  /// before this ever runs.
  static ToolResidencySpec _childResidency({required bool enabled}) =>
      ToolResidencySpec(
        enabled: enabled,
        residentNames: {
          ...ModeToolPolicy.residentBuiltins,
          ...ModeToolPolicy.residentDiscovery,
          ...ModeToolPolicy.residentMcpTools,
        },
      );

  /// Requests a turn-boundary pause. Returns false when no pausable
  /// (built-in harness) run is live — external CLI transports have no safe
  /// boundary; callers fall back to stopping the run.
  bool pauseHarness() => _harness.pause();

  /// Releases a paused loop (hand-back). Idempotent.
  void resumeHarness() => _harness.resume();

  /// Queues a mid-run steering message for the active run.
  ///
  /// [channel] selects the lane: [SteeringChannel.steering] (default) is
  /// injected at the next turn boundary; [SteeringChannel.aside] is a passive
  /// note; [SteeringChannel.followUp] runs only once the agent would otherwise
  /// stop. Returns true when the run will take it ([acceptsSteering]); FALSE —
  /// with nothing enqueued — otherwise, since ACP has no input lane (accepting
  /// the message would park it in a queue nobody reads: the
  /// silently-swallowed steering bug).
  bool steer(
    String content, {
    SteeringChannel channel = SteeringChannel.steering,
    String? ref,
  }) {
    if (content.trim().isEmpty) {
      return false;
    }
    if (!acceptsSteering) {
      return false;
    }
    _steering.enqueue(
      SteeringMessage(
        content: content.trim(),
        channel: channel,
        enqueuedAt: DateTime.now(),
        ref: ref,
      ),
    );
    return true;
  }

  /// Monotonic counter used to disambiguate concurrent subagent run ids.
  int _subagentSeq = 0;

  /// Prefix used when constructing sandbox session identifiers.
  static const String agentSessionPrefix = 'agent-';

  /// Tools that ARE the user interaction, so the harness must not wrap them in a
  /// second approval prompt (they gather the user's answer themselves).
  static const Set<String> _harnessInteractionTools = {
    // `ask_user` IS the user interaction: it renders a form in the
    // conversation and blocks on the human's answer. Wrapping it in an
    // approval prompt would put a dialog in front of a dialog, and — worse —
    // fail closed with no approver connected, so an agent that asked a
    // question would be denied the act of asking.
    'ask_user',
  };

  /// Env var carrying the co-author trailer to the spawned agent CLI, so any
  /// tooling in the run can stamp it onto commit messages.
  static const String coAuthorTrailerEnvKey = 'CC_GIT_COAUTHOR_TRAILER';

  /// Resolves policy-owned identity before any transport starts.
  /// Forge credentials remain the broker's, never the member's PAT.
  Future<_RunIdentity> _resolveRunIdentity() async {
    final creditAgent =
        await deps.resolveAgentAttribution?.call(
          requestedByUserId,
          workspaceId: workspaceId,
        ) ??
        true;
    final identity = await deps.resolveCommitIdentity?.call(
      requestedByUserId,
      workspaceId: workspaceId,
    );
    if (identity == null) {
      throw StateError('The requester has no Git identity.');
    }
    final coAuthorTrailer = creditAgent
        ? 'Co-Authored-By: Control Center <hi@usectrl.dev>'
        : null;
    return _RunIdentity(
      commitIdentity: identity,
      gitEnv: Map.unmodifiable({
        ...identity.environment,
        // This policy-owned key also masks stale caller and inherited
        // trailers.
        coAuthorTrailerEnvKey: coAuthorTrailer ?? '',
      }),
      coAuthorTrailer: coAuthorTrailer,
    );
  }

  /// Writable bind-mount host paths this session could grant exec on (RO mounts
  /// excluded — opening them would widen the sandbox with no binary to run).
  List<String> _execGrantCandidateRoots() => [
    for (final m in _bindMounts())
      if (!m.readOnly && m.hostPath.isNotEmpty) m.hostPath,
  ];

  /// The space root this session's cwd is an overlay of, or null when the cwd
  /// is not a provisioner overlay (fallback/oneshot runs, where the cwd is the
  /// agent's own durable dir).
  ///
  /// Two corroborations, neither of them a path the agent can name: the cwd
  /// parses as `<root>/agents/<overlay>` ([spaceRootForOverlay], the layout the
  /// provisioner creates) AND `<root>/repos` exists ([_reposDir], the same
  /// existence check [_bindMounts] mounts on).
  String? get _spaceRoot {
    final reposDir = _reposDir;
    if (reposDir == null) {
      return null;
    }
    final root = p.dirname(reposDir);
    return spaceRootForOverlay(agentDirHostPath) == root ? root : null;
  }

  /// Server-created disposable trees whose exec authority is implicit — see
  /// `SandboxExecGrantService.approvedRoots`.
  ///
  /// A grant keyed on the per-conversation overlay path could never be reused:
  /// every new conversation is a new path, so the operator was asked again
  /// about a copy the server had just made for that run. The space root covers
  /// the overlay AND the shared worktrees, and empty on the fallback path keeps
  /// the agent's durable dir approval-gated, as it always was.
  ///
  /// A root that touches a protected path — the workspace's ORIGINAL repo
  /// checkouts — is never implicit: nothing about the disposable-copy
  /// provenance holds for a tree that overlaps a real source mount, so that
  /// run falls back to asking.
  Future<List<String>> _managedExecGrantRoots() async {
    final root = _spaceRoot;
    if (root == null) {
      return const [];
    }
    for (final path in await _protectedPaths()) {
      if (path.isEmpty) {
        continue;
      }
      if (path == root ||
          path.startsWith('$root/') ||
          root.startsWith('$path/')) {
        return const [];
      }
    }
    return [root];
  }

  /// Resolves the operator-approved exec roots for this session, asking once
  /// per undecided tree. Returns empty when no grant service is wired, which
  /// leaves the exec block fully closed.
  ///
  /// Also the harness `bash` tool's resolver (per command, so an answer lands
  /// on the next one): the tool's own cwd is deliberately NOT the candidate —
  /// it is a subdirectory of these roots, and naming it would make each `cd` a
  /// fresh unknown tree and re-ask on it.
  Future<List<String>> _resolveExecGrantRoots(String wsId) async {
    final service = deps.execGrantService;
    if (service == null || wsId.isEmpty) {
      return const [];
    }
    try {
      return await service.approvedRoots(
        workspaceId: wsId,
        candidateRoots: _execGrantCandidateRoots(),
        managedRoots: await _managedExecGrantRoots(),
        spaceId: spaceId,
      );
    } on Object catch (e) {
      // A failed lookup must not take the dispatch down with it: the run
      // proceeds under the stricter, pre-grant rules.
      CcInfraLog.warning(
        'dispatch $dispatchId: exec-grant resolution failed, '
        'continuing without grants: $e',
      );
      return const [];
    }
  }

  /// Per-dispatch bind mounts (cross-agent isolation).
  ///
  /// Overlay: cwd **rw**; agent config **ro**; `<convRoot>/repos` **rw** when
  /// present; space `attachments/` **ro** when present (harness uses
  /// [_workspaceSharedRoots] with no RO mode — convention only). Fallback/
  /// oneshot: single writable cwd. Sibling agent dirs never mounted.
  List<SandboxBindMount> _bindMounts() {
    final cwd = agentDirHostPath;
    final layout = _layout;
    if (!layout.isOverlay) {
      return [SandboxBindMount(hostPath: cwd, guestPath: cwd)];
    }
    final configDir = agentConfigDir!;
    final reposPath = layout.reposDir;
    final attachmentsPath = layout.attachmentsDir;
    return [
      SandboxBindMount(hostPath: cwd, guestPath: cwd),
      SandboxBindMount(
        hostPath: configDir,
        guestPath: configDir,
        readOnly: true,
      ),
      // Writable so the overlay `repos` symlink resolves in the guest
      // namespace (identical host/guest paths).
      if (reposPath != null)
        SandboxBindMount(hostPath: reposPath, guestPath: reposPath),
      if (attachmentsPath != null)
        SandboxBindMount(
          hostPath: attachmentsPath,
          guestPath: attachmentsPath,
          readOnly: true,
        ),
    ];
  }

  /// Where this dispatch's directories are, derived once.
  ///
  /// Resolved when the run starts ([run]) and reused by every consumer —
  /// mounts, the harness's shared roots, link roots, repo scoping, the space
  /// root, ACP's `fs/*` — which each used to re-derive it with their own
  /// `existsSync` probes, up to six times per run. The sandbox profile is
  /// fixed at the start, so a layout read later would describe directories
  /// the sandbox does not have anyway. Read before the run starts (a media
  /// scope lookup), it is derived then, once.
  _OverlayLayout get _layout => _layoutCache ??= _OverlayLayout.resolve(
    cwd: agentDirHostPath,
    configDir: agentConfigDir,
  );

  _OverlayLayout? _layoutCache;

  /// Memoized original-checkout paths for this session's workspace. Resolved
  /// once per dispatch and folded into every [SandboxSpec] as deny-write
  /// rules; failures degrade to no extra denies (the CoW isolation and the
  /// harness path sandbox still hold).
  List<String>? _protectedPathsCache;

  Future<List<String>> _protectedPaths() async {
    final cached = _protectedPathsCache;
    if (cached != null) {
      return cached;
    }
    final resolver = deps.protectedPathsResolver;
    final wsId = workspaceId;
    if (resolver == null || wsId == null || wsId.isEmpty) {
      return _protectedPathsCache = const [];
    }
    try {
      return _protectedPathsCache = List.unmodifiable(await resolver(wsId));
    } on Object catch (e) {
      CcInfraLog.warning('protected-paths lookup failed for $wsId: $e');
      return _protectedPathsCache = const [];
    }
  }

  /// Extra workspace roots for the in-process harness file tools: the shared
  /// conversation worktrees dir (`<convRoot>/repos`) and the conversation's
  /// materialized attachments, when this session's cwd is a per-agent overlay.
  /// Without the first, the tools refuse the worktrees' real paths — the
  /// overlay only reaches them through its `repos` symlink, whose target is
  /// lexically outside the cwd. Without the second, the paths this run's own
  /// prompt names are unreadable to the tools that were given them. Derived
  /// from the directory layout (mirrors [_bindMounts]), never from the
  /// agent-writable symlink itself.
  List<String> _workspaceSharedRoots() => [
    ?_layout.reposDir,
    ?_layout.attachmentsDir,
  ];

  /// The space's shared worktree dir, or null when this session's cwd is not a
  /// per-agent overlay (the fallback path, where there are no worktrees).
  String? get _reposDir => _layout.reposDir;

  /// The server-managed directories whose symlinks the context loaders may
  /// follow.
  ///
  /// Everything the overlay offers is a symlink — its `AGENTS.md` points at the
  /// agent's global profile and its attached skills point into the workspace
  /// skills dir — and a `followLinks: false` listing types a symlink as neither
  /// a `File` nor a `Directory`. Without these roots the loaders find nothing
  /// at all, which is why the instructions block has been empty on every
  /// space-scoped run.
  List<String> _permittedLinkRoots() {
    final configDir = agentConfigDir;
    final reposDir = _reposDir;
    return [
      if (configDir != null && configDir.isNotEmpty) ...[
        configDir,
        // `syncAgentSkillLinks` links an agent's skills to `<wsRoot>/skills`,
        // one level above the agent dir.
        p.join(p.dirname(p.dirname(configDir)), 'skills'),
      ],
      ?reposDir,
    ];
  }

  /// Tracks which repo the agent is working in, and swaps the projected skills
  /// when that changes. Null when the session has no worktrees to scope to.
  ActiveRepoTracker? _repoTracker;
  RepoSkillProjector? _repoProjector;

  /// Prepares repo-scoped skills for this run and projects them.
  ///
  /// Every checked-out repo's skills are linked into the overlay, because
  /// Claude Code's Skill tool only sees `.claude/skills` in the working
  /// directory and will not follow `repos/` out of it. A space with one repo
  /// is seeded as active before the first turn; with several, the first file
  /// the agent touches decides whose instructions are inlined. The links
  /// themselves do not wait for that.
  Future<void> _initRepoScoping(String wsId) async {
    final reposDir = _reposDir;
    final scanner = deps.skillScanner;
    if (reposDir == null || scanner == null) {
      return;
    }
    final repos = <String>[];
    try {
      for (final entity in Directory(reposDir).listSync(followLinks: false)) {
        if (entity is Directory) {
          repos.add(p.basename(entity.path));
        }
      }
    } on FileSystemException catch (e) {
      CcInfraLog.warning('repo scoping: cannot list $reposDir: $e');
      return;
    }
    if (repos.isEmpty) {
      return;
    }
    final tracker = ActiveRepoTracker(
      reposDir: reposDir,
      knownRepos: repos.toSet(),
    );
    final projector = RepoSkillProjector(
      workspaceId: wsId,
      overlayDir: agentDirHostPath,
      reposDir: reposDir,
      scanner: scanner,
      onWarning: CcInfraLog.warning,
    );
    _repoTracker = tracker;
    _repoProjector = projector;
    if (repos.length == 1) {
      tracker.seed(repos.single);
    }
    await projector.project(tracker.active);
  }

  /// Observes one tool call and re-projects when the agent has moved to a
  /// different repo.
  ///
  /// Called from [addEvent], which every transport funnels through — the
  /// built-in harness, the Claude CLI's stream-json and the ACP bridge all
  /// emit a [ToolCallEvent] — so path inference works the same on an external
  /// CLI as it does in-process, without parsing four event formats.
  void _observeRepoTouch(ToolCallEvent event) {
    final tracker = _repoTracker;
    final projector = _repoProjector;
    if (tracker == null || projector == null) {
      return;
    }
    final switched = tracker.observe(event.toolName, event.inputs ?? const {});
    if (switched == null) {
      return;
    }
    // Fire-and-forget: the projection is disk state the next turn reads, and
    // blocking the event stream on it would stall the transcript.
    unawaited(() async {
      try {
        final projection = await projector.project(switched);
        // The system prompt is frozen for the life of a run, so the swap is
        // announced instead — on the STEERING lane, because an `aside` is a
        // system-role message and compaction drops those, which would silently
        // lose the index mid-run.
        steer(projection.announcement);
      } on Object catch (e) {
        CcInfraLog.warning('repo skill projection failed for $switched: $e');
      }
    }());
  }

  /// Resolves the derived MCP client config path for THIS session's cwd
  /// (`<cwd>/.mcp.json`), or null when no resolver is wired. The resolver
  /// (cc_server's `ServerMcpControl`) writes a fresh token-bearing config from
  /// the live `mcp_config.json` posture on every dispatch, stamped with this
  /// session's identity scope so the MCP server pins every tool call to this
  /// workspace/agent/conversation.
  Future<String?> _resolveMcpConfigPath() async {
    final resolver = deps.mcpConfigPathResolver;
    if (resolver == null) {
      return null;
    }
    return resolver(
      agentDirHostPath,
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      spaceId: spaceId,
      runToken: _gatewayLease?.secret,
    );
  }

  /// Starts the agent process and manages its lifecycle.
  ///
  /// Resolves the execution backend for [cliName] from the registry and
  /// switches on its transport: `claudeCli` (sandboxed `claude -p` emitting
  /// stream-json NDJSON), `acp` (JSON-RPC over stdio), or `harness` (in-process
  /// agent loop). An unknown cliName emits a clear error + DoneEvent and exits
  /// 127 — never throws.
  Future<void> run() async {
    try {
      // FIRST, before anything that can fail: a failure in the mint, the
      // identity or the lease used to end the run with no NDJSON log at all.
      await _openRunLog();
      _layoutCache = _OverlayLayout.resolve(
        cwd: agentDirHostPath,
        configDir: agentConfigDir,
      );
      final networkEnabled = await _resolveNetworkEnabled();

      // Resolve the worktree's GitHub coordinates so the broker can mint a
      // fine-grained App installation token scoped to exactly this repo.
      // Without them the App mint is skipped and the broker falls back to the
      // environment PAT — so a cwd that is not a GitHub checkout still
      // dispatches, it just carries no repo-scoped credential.
      String? repoOwner;
      String? repoName;
      final inspector = deps.repoInspector;
      if (inspector != null) {
        try {
          final info = await inspector.inspect(agentDirHostPath);
          if (info.forge == ForgeHost.github) {
            repoOwner = info.owner;
            repoName = info.repoName;
          }
        } on Object {
          // Best-effort: not a git worktree / no supported origin remote.
        }
      }

      // The REVIEW scope cannot push. Shell preflight always checks push
      // policy, and gateway-routed pushes independently authorize the actual
      // refs using a server-held token.
      final scoped = await deps.broker.mint(
        conversationId: conversationId ?? 'unknown',
        scope: ForgeTokenScope.review,
        repoOwner: repoOwner,
        repoName: repoName,
        // The member who asked for this run. It bounds the run's forge
        // credential to THEIR access rather than the server owner's, so a
        // read-only collaborator cannot dispatch a pushing agent and have it
        // succeed on someone else's reach.
        actingUserId: requestedByUserId,
        workspaceId: workspaceId,
      );
      credHandle = scoped.handle;

      // Resolve the per-run Git identity and co-author policy before any
      // transport launches, so every merged env carries them. (After the
      // mint: callers may fail a stalled mint to abort the run early.) Before
      // the lease too: the gateway signs only as this identity.
      final identity = await _resolveRunIdentity();

      final environment = await _openGatewayLease(
        repoOwner: repoOwner,
        repoName: repoName,
        identity: identity.commitIdentity,
      );
      // Everything a transport or its sandbox reads from here on is fixed.
      _run = _RunContext(
        networkEnabled: networkEnabled,
        identity: identity,
        environment: environment,
      );

      final wsId = workspaceId ?? '';
      final sandboxSessionId = _sandboxSessionId;

      final backend = deps.backendRegistry.backendFor(cliName);
      if (backend == null) {
        addEvent(
          ErrorEvent(
            content:
                '[sandbox] No execution backend for "$cliName". '
                'Install the CLI or pick a supported adapter in '
                'Settings → Adapters.',
          ),
        );
        _finish(exitCode: 127);
        return;
      }

      // Before any transport starts: the projected skills are on-disk state
      // every adapter discovers for itself, so this has to land before the
      // CLI boots or the harness assembles its system prompt.
      await _initRepoScoping(wsId);

      switch (backend.transport) {
        case AdapterTransport.claudeCli:
          await _runClaudeCli(
            scoped: scoped,
            sandboxSessionId: sandboxSessionId,
            wsId: wsId,
          );
        case AdapterTransport.acp:
          await _runAcp(
            scoped: scoped,
            sandboxSessionId: sandboxSessionId,
            wsId: wsId,
          );
        case AdapterTransport.harness:
          await _runHarness(scoped: scoped, wsId: wsId);
      }
      onScheduleCooldown(sandboxSessionId);
    } on Object catch (e, st) {
      // A stop already recorded why the run ended; whatever the dying
      // transport threw on its way out is not a second reason.
      if (!_cancelSource.isCancelled) {
        CcInfraLog.error('dispatch $dispatchId failed', e, st);
        // Redacted: this event reaches the transcript recorder and the client
        // over RPC. A failed authenticated git/HTTP call embeds
        // `https://x-access-token:ghp_…@github.com` in its message — the
        // NDJSON run log already redacts, the live stream did not.
        _failRun(redactSecrets('[sandbox] dispatch failed: $e'));
      }
      _finish(error: e);
    }
  }

  /// This run's diagnostics ledger: what the agent has already been told
  /// about each file, so an edit reports only what it newly broke.
  final DiagnosticsLedger _diagnosticsLedger = DiagnosticsLedger();

  /// Staged changes for this session — one store, so a change staged by
  /// `ast_edit` is the one `resolve` commits. Per session rather than per
  /// registry build: the model stages in one turn and resolves in the next,
  /// and a fresh store between them would lose the change.
  final StagedEditStore _stagedEdits = StagedEditStore();

  /// Live `eval` interpreters for this session, one per language.
  ///
  /// Per session and torn down with it: a kernel is a shell that remembers,
  /// and one still holding a dataframe (and a process) after the conversation
  /// ended is the leak the enclosure rules exist to prevent.
  final Map<KernelLanguage, EvalKernel> _kernels = {};

  /// The director's background workers, when `/vibe` turned the mode on.
  ///
  /// Per session, and torn down with it: a background worker still editing
  /// files after the conversation that started it has moved on is the failure
  /// this feature must not have.
  VibeRoster? _vibeRoster;

  /// Where this run's history is persisted, or null when it is not.
  ///
  /// Keyed by AGENT as well as conversation: two agents in one conversation
  /// hold two different histories — they saw different tool results and were
  /// given different system prompts, so merging them would hand each the
  /// other's reasoning as its own.
  String? get _transcriptKey {
    final workspace = workspaceId;
    final conversation = conversationId;
    if (deps.transcriptStore == null ||
        workspace == null ||
        workspace.isEmpty ||
        conversation == null ||
        conversation.isEmpty) {
      return null;
    }
    return '$workspace/$conversation#$agentId';
  }

  /// Builds the base harness tool registry (built-in filesystem/command tools
  /// first, then bridged CC MCP tools) for a given [mode]/[env]. The
  /// `task` tool is NOT added here — the top-level run adds it explicitly and
  /// subagents deliberately omit it so nesting is capped at one level.
  HarnessToolRegistry _buildHarnessRegistry({
    required Mode mode,
    required Map<String, String> env,
  }) {
    // The `eval` bridge resolves tools against the registry being built, which
    // is why this is a block: a cell's `tool(...)` call must hit the SAME
    // registry a model-issued call does, wrappers and guardrails included.
    late final HarnessToolRegistry registry;
    registry = buildHarnessToolRegistry(
      mode: mode,
      networkEnabled: _run.networkEnabled,
      loopbackPorts: _gatewayLoopbackPorts,
      environmentScope: _run.environment.scope,
      env: env,
      toolOutputStore: deps.toolOutputStore,
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      sandboxManager: deps.sandboxManager,
      confirmationPort: deps.confirmationPort,
      // The SAME resolution the CLI profile uses, so both adapters get the
      // same scoped exec roots — and the tool's own cwd never enters into it.
      execGrantRootsResolver: () => _execGrants(workspaceId ?? ''),
      // The operator's own `commandPrefix` rules reach the bash gate through
      // this — before it, they were stored, resolvable, editable in the
      // what-if probe, and never consulted at runtime.
      actionGuard: deps.actionGuard,
      fileSearch: deps.fileSearch,
      mcpRegistry: deps.mcpRegistry,
      protectedPaths: _protectedPaths,
      // `ask_user` renders in this run's conversation within its space.
      // Both scopes must reach the tool so the answer returns to this run.
      agentQuestionPort: deps.agentQuestionPort,
      spaceId: spaceId,
      // The question names this run, so only this run's watchdog pauses.
      runLogId: runLogId,
      // Diagnostics + navigation. The ledger is PER RUN (a new run should hear
      // the current state of the world once), while the supervisor is shared
      // (its cost is indexing).
      lspSupervisor: deps.lspSupervisor,
      diagnosticsLedger: _diagnosticsLedger,
      lspWorkingDirectory: agentDirHostPath,
      // Structural search + rewrite. Null when the grammars are not staged, in
      // which case the tools are not advertised at all.
      treeSitterParser: deps.astParsers?.parserIfReady,
      stagedEditStore: _stagedEdits,
      debugSupervisor: deps.debugSupervisor,
      evalKernelFor: deps.kernelLauncherFactory == null
          ? null
          : (language) => _kernelFor(language, registryForBridge: registry),
    );
    return registry;
  }

  /// The live kernel for [language], created on first use.
  ///
  /// **The bridge re-enters the registry, it does not go around it.** A
  /// `tool(...)` call from inside a cell resolves against the SAME tool
  /// registry a model-issued call does, so `ActionClass` guardrails, the
  /// approval callback and every wrapper (diagnostics-on-write included) apply
  /// identically. A bridge that reached past the registry would be a hole in
  /// the guardrails shaped exactly like "write a Python one-liner".
  EvalKernel _kernelFor(
    KernelLanguage language, {
    required HarnessToolRegistry registryForBridge,
  }) => _kernels.putIfAbsent(
    language,
    () => EvalKernel(
      language: language,
      launcher: LazyKernelLauncher(
        () => deps.kernelLauncherFactory!(
          workingDirectory: agentDirHostPath,
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
      ),
      bridge: (name, arguments) async {
        final tool = registryForBridge.findByName(name);
        if (tool == null) {
          return (content: 'Unknown tool: $name', isError: true);
        }
        final result = await tool.execute(
          arguments,
          HarnessToolContext(
            workingDirectory: agentDirHostPath,
            sharedRoots: _workspaceSharedRoots(),
            agentId: agentId,
            workspaceId: workspaceId,
            conversationId: conversationId,
            spaceId: spaceId,
          ),
        );
        return (content: result.content, isError: result.isError);
      },
    ),
  );

  SubagentCatalog? _catalogMemo;

  /// Builds the harness provider, assembling a fallback chain when more than one
  /// target is available: the primary, then other stored credentials for the
  /// same provider (multi-key rotation), then any cross-provider `extraSpecs`
  /// from the `a/b|c/d` model syntax. A single target returns the plain
  /// provider; otherwise a [FallbackProvider] advances on auth/quota errors.
  Future<LlmProviderPort> _buildHarnessProvider({
    required HarnessProviderFactory factory,
    required String primaryProviderId,
    required String? primaryModel,
    required ProviderCredential? primaryCredential,
    required List<String> extraSpecs,
  }) async {
    // Which stored credentials this run may spend, and which one LEADS.
    //
    // Without a pool this is the store's own order behind the store's active
    // credential — the behaviour before pools existed. With one, the workspace
    // (or the agent) has said which keys are attached, in what order, and
    // whether to drain them one at a time or spread runs across them; the
    // resolver applies that and hands back a settled order.
    var leadCredential = primaryCredential;
    var rotation = <ProviderCredential>[];
    final store = deps.harnessCredentialStore;
    if (store != null) {
      try {
        final stored = await store.credentialsFor(primaryProviderId);
        final usable = [
          for (final cred in stored)
            // A secret-less definition placeholder (created by
            // `providers.saveGenerationDefaults` before any key existed) is not
            // a rotation target — failing over to it would 401 with no account
            // to blame. Custom-provider definitions (dialect-carrying) are
            // exempt: their none-method credential IS the endpoint.
            if (cred.method != HarnessAuthMethod.none || cred.dialect != null)
              cred,
        ];
        rotation = await _orderRotation(primaryProviderId, usable);
        // The pool may put a different key in front — that IS round robin.
        // Only take it when the pool actually said something; otherwise the
        // store's active credential keeps leading.
        // A key the adapter or caller handed this run explicitly is never
        // demoted: stored keys are its fallbacks, not its replacement.
        if (rotation.isNotEmpty &&
            primaryCredential != null &&
            !_isExplicitRunCredential(primaryCredential)) {
          final leadsPool = _sameCredential(rotation.first, primaryCredential);
          if (!leadsPool) {
            leadCredential = rotation.first;
          }
        }
      } on _AccountPoolRefused {
        // Not best-effort: the pool said this run must not start.
        rethrow;
      } on Object catch (_) {
        // Rotation is best-effort; the primary still works.
        rotation = const [];
      }
    }

    final primary = factory.create(
      providerId: primaryProviderId,
      model: primaryModel,
      credential: leadCredential,
      tokenResolver: _tokenResolverFor(leadCredential),
    );
    final entries = <FallbackEntry>[
      FallbackEntry(
        providerId: primaryProviderId,
        model: primaryModel ?? primary.defaultModel,
        credentialId: leadCredential?.credentialId,
        build: () => primary,
      ),
    ];

    for (final cred in rotation) {
      if (_sameCredential(cred, leadCredential)) {
        continue;
      }
      // One resolver per credential, bound outside the lazy build so the
      // entry cannot end up with a holder that starts from a spent token.
      final resolver = _tokenResolverFor(cred);
      entries.add(
        FallbackEntry(
          providerId: primaryProviderId,
          model: primaryModel ?? primary.defaultModel,
          credentialId: cred.credentialId,
          build: () => factory.create(
            providerId: primaryProviderId,
            model: primaryModel,
            credential: cred,
            tokenResolver: resolver,
          ),
        ),
      );
    }

    // Cross-provider fallback from the pipe syntax.
    for (final spec in extraSpecs) {
      final p = factory.parseModel(spec);
      final cred = await _resolveHarnessCredential(p.providerId);
      final resolver = _tokenResolverFor(cred);
      entries.add(
        FallbackEntry(
          providerId: p.providerId,
          model: p.model ?? '',
          build: () => factory.create(
            providerId: p.providerId,
            model: p.model,
            credential: cred,
            tokenResolver: resolver,
          ),
        ),
      );
    }

    if (entries.length == 1) {
      return primary;
    }
    return FallbackProvider(
      entries,
      onFallback: (from, to, reason, {fromCredentialId, capacity = false}) {
        if (capacity && fromCredentialId != null) {
          // Remember WHICH key ran out. Without this the next dispatch walks
          // into the same exhausted credential and pays another 429 to learn
          // what this turn already found out.
          unawaited(
            onHarnessCredentialExhausted?.call(
                  providerId: from,
                  credentialId: fromCredentialId,
                ) ??
                Future<void>.value(),
          );
        }
        addEvent(
          DebugEvent(
            content: '[harness] provider fallback $from → $to ($reason)',
          ),
        );
      },
    );
  }

  /// Whether [credential] came from this run's adapter or caller env — an
  /// explicit choice made for this run, which outranks any stored pool.
  static bool _isExplicitRunCredential(ProviderCredential credential) {
    final label = credential.accountLabel ?? '';
    return label.startsWith(_adapterCredentialLabel) ||
        label.startsWith(_callerCredentialLabel);
  }

  static const _adapterCredentialLabel = 'adapter:';
  static const _callerCredentialLabel = 'caller:';

  bool _sameCredential(ProviderCredential a, ProviderCredential? b) =>
      b != null && a.method == b.method && a.secret == b.secret;

  /// A just-in-time bearer for [credential], or null when the credential holds
  /// a static secret (API key / no auth).
  ///
  /// OAuth access tokens are short — a Kimi Code token lives ~15 minutes — and
  /// a run lasts as long as the work does. Resolving the token when the provider
  /// is built therefore guarantees a 401 partway through any real run, so the
  /// provider is handed a resolver that refreshes at request time instead. One
  /// holder per credential: refresh tokens rotate, so each entry in the fallback
  /// chain has to carry its own latest credential forward.
  ProviderTokenResolver? _tokenResolverFor(ProviderCredential? credential) {
    final refresher = deps.harnessCredentialRefresher;
    if (credential == null ||
        refresher == null ||
        credential.method != HarnessAuthMethod.oauth) {
      return null;
    }
    return RefreshingCredential(refresher, credential).resolve;
  }

  /// Whether [credential] can actually start a run: it carries a secret, or it
  /// says none is needed (a keyless custom endpoint, method `none`).
  static bool _harnessAuthSatisfied(ProviderCredential? credential) =>
      (credential?.secret != null && credential!.secret!.isNotEmpty) ||
      credential?.method == HarnessAuthMethod.none;

  /// Parks this run until a credential for [providerId] exists, and returns
  /// whatever the store holds afterwards.
  ///
  /// Returns the still-missing credential unchanged when no gate is wired, when
  /// the operator cancels, or when the wait times out — so every one of those
  /// falls through to the failure the run had before this existed.
  Future<ProviderCredential?> _gateOnHarnessCredential({
    required String providerId,
    required String detail,
  }) async {
    final gate = deps.credentialGate;
    if (gate == null) {
      return null;
    }
    // Said out loud in the transcript, not only in the dialog. A turn that goes
    // quiet for minutes with nothing in it reads as a hung agent, and the
    // person who can unblock it may be looking at the conversation rather than
    // at the surface holding the modal.
    addEvent(
      DebugEvent(
        content:
            '[harness] waiting for a credential for "$providerId" — '
            'the run continues as soon as one is connected.',
      ),
    );
    final outcome = await gate.awaitCredentials(
      RunCredentialBlockRequest(
        lane: RunCredentialLane.harness,
        reason: RunCredentialReason.noCredential,
        detail: detail,
        runLogId: runLogId,
        providerId: providerId,
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        agentName: agentName,
      ),
      recheck: () async =>
          _harnessAuthSatisfied(await _resolveHarnessCredential(providerId)),
    );
    if (outcome != RunCredentialOutcome.resolved) {
      return null;
    }
    return _resolveHarnessCredential(providerId);
  }

  /// Resolves the full credential for a harness provider (API key or OAuth):
  /// per-adapter env override → caller env → server credential store → process
  /// environment. The store may return an OAuth credential; the provider factory
  /// then builds a bearer-auth provider from it.
  Future<ProviderCredential?> _resolveHarnessCredential(
    String providerId,
  ) async {
    final envKeys =
        EnvProviderCredentialStore.envKeys[providerId] ?? const <String>[];
    for (final key in envKeys) {
      final fromAdapter = adapterEnvOverride[key];
      if (fromAdapter != null && fromAdapter.isNotEmpty) {
        return ProviderCredential(
          providerId: providerId,
          method: HarnessAuthMethod.apiKey,
          apiKey: fromAdapter,
          accountLabel: '$_adapterCredentialLabel$key',
        );
      }
      final fromCaller = callerEnv[key];
      if (fromCaller != null && fromCaller.isNotEmpty) {
        return ProviderCredential(
          providerId: providerId,
          method: HarnessAuthMethod.apiKey,
          apiKey: fromCaller,
          accountLabel: '$_callerCredentialLabel$key',
        );
      }
    }
    final store = deps.harnessCredentialStore;
    if (store != null) {
      final cred = await store.activeCredential(providerId);
      if (cred != null &&
          ((cred.secret != null && cred.secret!.isNotEmpty) ||
              cred.method == HarnessAuthMethod.none)) {
        final refresher = deps.harnessCredentialRefresher;
        return refresher == null ? cred : await refresher.refreshIfNeeded(cred);
      }
    }
    for (final key in envKeys) {
      final value = Platform.environment[key];
      if (value != null && value.isNotEmpty) {
        return ProviderCredential(
          providerId: providerId,
          method: HarnessAuthMethod.apiKey,
          apiKey: value,
          accountLabel: 'env:$key',
        );
      }
    }
    return null;
  }

  /// Assembles the harness system prompt: base operating instructions + the
  /// repo's AGENTS.md hierarchy (root + nested) + available skills. The agent's
  /// persona, workspace context and task are carried in [prompt] (assembled by
  /// the dispatch pipeline) and delivered as the user message; this is the
  /// stable operating brief that belongs in the system prompt.
  Future<String> _harnessSystemPrompt(String wsId) async {
    final parts = await const HarnessSystemPromptBuilder().build(
      workspaceId: wsId,
      workingDirectory: agentDirHostPath,
      agentConfigDir: agentConfigDir,
      coAuthorTrailer: _run.identity.coAuthorTrailer,
      permittedLinkRoots: _permittedLinkRoots(),
      onWarning: CcInfraLog.warning,
    );
    return parts.assemble();
  }

  /// Builds the merged environment for a dispatch. Adapter defaults cannot
  /// replace the resolved attribution policy or the broker's forge credentials.
  ///
  /// Caller and adapter settings cannot replace the requesting human's identity.
  /// The run's GitHub credential is always the broker's, never the requesting
  /// member's token.
  Map<String, String> _mergedEnv({
    required Map<String, String> scopedEnv,
    required Map<String, String> backendEnv,
  }) {
    final merged = <String, String>{
      ...callerEnv,
      ...scopedEnv,
      ...backendEnv,
      ...adapterEnvOverride,
      if (wakeContext != null) ...wakeContext!.toEnvironment(),
      // Which Claude Code account this run signs in as. It is the LAST word on
      // the config dir — an `adapterEnvOverride` naming a different one would
      // point the CLI somewhere the sandbox never made writable, which fails
      // as a mid-run token refresh error rather than as a visible mistake.
      if (claudeConfigDir != null && claudeConfigDir!.isNotEmpty)
        'CLAUDE_CONFIG_DIR': claudeConfigDir!,
    };
    // …and it survives the re-assertion below, because the broker's scoped env
    // carries forge credentials, never a runner config dir.
    // Re-assert the credential keys LAST. The spread order above lets an
    // adapter's configured env win for its own keys (which is the point of
    // `adapterEnvOverride`), but it also let it silently replace a
    // broker-minted, scoped, revocable credential with a static one — while
    // `adapterEnvOverride`'s own doc promised the opposite ("caller/broker env
    // still wins for security-critical keys"). Now it does.
    merged.addAll(scopedEnv);
    merged.addAll(_run.identity.gitEnv);
    // Append gateway routing after adapter config. Shell preflight remains
    // necessary: explicit URLs or command-local Git config can avoid rewrites.
    final lease = _gatewayLease;
    if (lease != null) {
      merged.addAll(_leaseEnvironment(lease, merged));
    }
    return merged;
  }

  /// Directories the runner keeps its own state in, writable in every mode.
  ///
  /// Only the Claude Code config dir today. It is listed for EVERY transport,
  /// not just `claudeCli`: an ACP agent or a structured CLI may shell out to
  /// `claude`, and a run that can read the credential but not refresh it fails
  /// later and more confusingly than one that cannot read it at all.
  List<String> get _runnerStateDirs => {
    if (claudeConfigDir != null && claudeConfigDir!.isNotEmpty)
      claudeConfigDir!,
    // EVERY pooled account, not just the active one: the sandbox profile is
    // generated once, before the spawn, and a failover re-run inside the same
    // session would otherwise land on a directory the profile never opened.
    for (final a in claudeAccounts)
      if (a.configDir.isNotEmpty) a.configDir,
  }.toList();

  /// The sandbox session id a dispatch's CLI transports share: one per
  /// agent, conversation and mode, so a follow-up turn can reuse it warm.
  String get _sandboxSessionId {
    final agentKey = (agentId != null && agentId!.isNotEmpty)
        ? agentId!
        : 'oneshot';
    final convKey = conversationId ?? 'no-conv';
    return '$agentSessionPrefix$agentKey::$convKey::${mode.name}';
  }

  /// The ONE sandbox spec this dispatch's process transports (Claude Code,
  /// ACP) run under. Every input is a value resolved at run start, so two
  /// transports of one run can never be sandboxed differently — the ACP path
  /// used to build its own, without process-group supervision.
  Future<SandboxSpec> _sandboxSpec(
    String sandboxSessionId,
    String wsId,
  ) async => processSandboxSpec(
    sessionId: sandboxSessionId,
    workspaceId: wsId,
    agentId: agentId,
    bindMounts: _bindMounts(),
    workdir: agentDirHostPath,
    networkEnabled: _run.networkEnabled,
    mode: mode,
    protectedPaths: await _protectedPaths(),
    runnerStateDirs: _runnerStateDirs,
    execGrantRoots: await _execGrants(wsId),
    loopbackPorts: _gatewayLoopbackPorts,
    environmentScope: _run.environment.scope,
    superviseProcessGroup: true,
  );

  /// Resolves this run's sandbox handle and starts listening to nothing yet:
  /// the caller subscribes. An error-state handle is destroyed before the
  /// throw — it is already in the adapter's map, and the throw skips the
  /// cooldown that would otherwise clean it up.
  Future<SandboxHandle> _launchSandbox(
    String sandboxSessionId,
    String wsId,
  ) async {
    final handle = await onResolveHandle(
      sessionId: sandboxSessionId,
      spec: await _sandboxSpec(sandboxSessionId, wsId),
      emit: addEvent,
    );
    if (handle.state == SandboxState.error) {
      try {
        await deps.sandbox.destroy(handle);
      } on Object catch (e, st) {
        CcInfraLog.error(
          'dispatch $dispatchId: destroy after launch failure also failed',
          e,
          st,
        );
      }
      throw StateError('sandbox launch failed: ${handle.error}');
    }
    _activeHandle = handle;
    return handle;
  }

  /// The space's autonomy dial for this run, read per decision (an operator
  /// can turn it mid-run), or null when there is no space or no resolver.
  /// Never throws: a failed read keeps the default, fail-closed posture.
  Future<AutonomyLevel?> _resolveAutonomy() async {
    final resolve = deps.autonomyResolver;
    final ws = workspaceId;
    final space = spaceId;
    final agent = agentId;
    if (resolve == null ||
        ws == null ||
        ws.isEmpty ||
        space == null ||
        agent == null) {
      return null;
    }
    try {
      return AutonomyLevel.tryFromWire(await resolve(ws, space, agent));
    } on Object catch (e, st) {
      CcInfraLog.error('dispatch $dispatchId: autonomy lookup failed', e, st);
      return null;
    }
  }

  /// Universal command preflight. Evaluates the resolved command string
  /// against the mode's [CommandPolicy] before spawning. Returns `true` when
  /// the spawn should proceed, `false` when it was refused — in which case the
  /// run has already finished. A `prompt` decision asks the operator through
  /// the [ConfirmationPort] and fails closed without one.
  Future<bool> _preflightCommand(List<String> argv) async {
    if (argv.isEmpty) {
      return true;
    }
    final command = argv.join(' ');
    final policy = commandPolicyForMode(mode);
    final decision = policy.evaluate(command);
    switch (decision) {
      case CommandDecision.allow:
        return true;
      case CommandDecision.deny:
        addEvent(
          ErrorEvent(content: '[sandbox] command denied by policy: $command'),
        );
        _finish(exitCode: 126);
        return false;
      case CommandDecision.prompt:
        final port = deps.confirmationPort;
        if (port == null) {
          addEvent(
            ErrorEvent(
              content:
                  '[sandbox] command requires approval but no approver '
                  'is connected — denying: $command',
            ),
          );
          _finish(exitCode: 126);
          return false;
        }
        final copy = ActionApprovalCopy.describe(
          classes: {
            ActionClass.processSpawn,
            ...const ShellActionClassifier().classify(command),
          },
          command: command,
        );
        final approved = await port.requestApproval(
          ConfirmationRequest(
            spaceId: spaceId ?? '',
            conversationId: conversationId,
            workspaceId: workspaceId,
            title: copy.title,
            detail: copy.detail,
            command: command,
            severity: ConfirmationSeverity.warning,
            kind: ConfirmationKind.command,
          ),
        );
        if (!approved) {
          addEvent(
            ErrorEvent(content: '[sandbox] command denied by user: $command'),
          );
          _finish(exitCode: 126);
          return false;
        }
        return true;
    }
  }

  /// Stops the session for a server shutdown: cancels the run, kills its
  /// child, revokes its credentials, closes its run log and the event stream.
  ///
  /// Quiet on purpose — no transcript rows, no terminal event: the server is
  /// going away and the run row is reconciled by the orphan reaper at the next
  /// boot. It used to only revoke and close, leaving the child (an ACP agent
  /// in particular, which no sandbox supervises) running with nobody reading
  /// its output.
  Future<void> stop() async {
    _cancelSilenceWatchdog();
    _abortLogError ??= kRunStoppedByShutdownSummary;
    _lastTaskError ??= kRunStoppedByShutdownSummary;
    _cancelSource.cancel('shutdown');
    try {
      _claude.parser = null;
      unawaited(_bestEffort('subagent close', _closeClaudeSubagents));
      await _bestEffort('ACP teardown', _teardownAcp);
      await _bestEffort('process kill', () => _killActiveProcess('shutdown'));
      await _bestEffort('run-log close', _closeRunLog);
    } finally {
      await _bestEffort('credential release', _releaseRunCredentials);
      _closeController();
    }
  }

  /// Forcefully terminates the session at a user's request: the run is
  /// recorded as stopped, its child killed, its credentials revoked and its
  /// stream finished.
  Future<void> terminate() => _abortRun(
    reason: 'terminate',
    failure: kRunStoppedByUserSummary,
    logError: kRunStoppedByUserSummary,
    debugLine: '[sandbox] dispatch $dispatchId stopped by request',
  );

  /// The one stop sequence for a run ended from outside its process: a user
  /// [terminate] or the silence watchdog. [failure] is the run's only
  /// transcript error. [debugLine] stays in the run log; emitting it as an
  /// error too rendered two error rows for one stop.
  ///
  /// Every step is guarded: a throw from the interrupt, the ACP teardown or
  /// the kill used to skip the terminal event, and the watchdog's
  /// `unawaited(_abortRun(...))` then left the run hung with nothing to end it.
  Future<void> _abortRun({
    required String reason,
    required String failure,
    required String logError,
    required String debugLine,
  }) async {
    if (_abortStarted) {
      return;
    }
    _abortStarted = true;
    _cancelSilenceWatchdog();
    // The stop's reason wins the run log over whatever the dying transport
    // closes it with (a harness that sees the cancel exits 0).
    _abortLogError ??= logError;
    // Cancel the built-in harness loop and any in-flight subagent loops (they
    // share this token) before tearing the session down. The CLI runners also
    // read it to drop the dying process's `exited with code -15` line.
    _cancelSource.cancel(reason);
    // Record the stop before yielding: killing the child can complete `run()`
    // and close the transcript while process teardown is still in progress.
    if (!emittedDone) {
      _failRun(failure);
    }
    try {
      await _bestEffort('turn interrupt', _interruptClaudeTurn);
      _claude.parser = null;
      unawaited(_bestEffort('subagent close', _closeClaudeSubagents));
      await _bestEffort('ACP teardown', _teardownAcp);
      addEvent(DebugEvent(content: debugLine));
      // Actually stop the agent. `_failRun` only stamps the DB row; without
      // this the CLI kept running after the stop, ignored by everything.
      await _bestEffort('process kill', () => _killActiveProcess(reason));
    } finally {
      await _bestEffort('credential release', _releaseRunCredentials);
      // Closes the run log too: it finalizes the DEBOUNCED `lastOutputAt`
      // write and writes the NDJSON `end` record.
      _finish(error: logError);
      await _finishing;
    }
  }

  /// Set once [_abortRun] has begun; a second stop is a no-op.
  bool _abortStarted = false;

  /// Why an outside stop ended the run, once one did. [_closeRunLog] records
  /// this rather than the exit code the dying transport reports.
  String? _abortLogError;

  /// The pending run-log close of the terminal sequence, once it began.
  Future<void>? _finishing;

  /// The ONE terminal sequence: closes the run log, emits the [DoneEvent] and
  /// completes the run (lifecycle events, credential release, stream close).
  ///
  /// Every ending goes through here — a refused preflight, a missing binary,
  /// a transport that ran to completion, a stop — so none of them can skip a
  /// step the others take. Idempotent: the first caller's outcome stands, and
  /// later callers change nothing. Never throws; [_finishing] is the pending
  /// run-log close for a caller that must wait for it.
  void _finish({int? exitCode, Object? error}) {
    if (_finishing != null) {
      return;
    }
    _finishing = _bestEffort(
      'run-log close',
      () => _closeRunLog(exitCode: exitCode, error: error),
    );
    if (!emittedDone) {
      addEvent(DoneEvent());
      _completeRun();
    }
  }

  /// Runs one teardown step, logging (with its stack) instead of throwing.
  Future<void> _bestEffort(String what, Future<void> Function() step) async {
    try {
      await step();
    } on Object catch (e, st) {
      CcInfraLog.error('dispatch $dispatchId: $what failed', e, st);
    }
  }

  /// Ends an active ACP turn (close the client and the agent's stdin); the
  /// child itself is stopped by [_killActiveProcess]. A no-op when no ACP run
  /// is active.
  Future<void> _teardownAcp() async {
    final client = _acpClient;
    final stdin = _acpStdin;
    _acpClient = null;
    _acpStdin = null;
    await client?.close();
    await stdin?.close();
  }

  /// Stops whatever the agent is running, best-effort, in the order that
  /// actually works: kill the recorded child pid (so a shared/reused sandbox
  /// keeps serving other work), then destroy the sandbox if we own a handle.
  ///
  /// Never throws — this runs on teardown paths where the child is frequently
  /// gone already.
  Future<void> _killActiveProcess(String reason) async {
    final childPid = pid;
    if (childPid != null) {
      try {
        await deps.processControl?.kill(childPid);
      } on Object catch (e) {
        CcInfraLog.warning(
          'dispatch $dispatchId: kill pid $childPid failed: $e',
        );
      }
    }
    final handle = _activeHandle;
    _activeHandle = null;
    if (handle != null) {
      try {
        await deps.sandbox.destroy(handle);
      } on Object catch (e) {
        CcInfraLog.warning(
          'dispatch $dispatchId: sandbox destroy after $reason failed: $e',
        );
      }
    }
  }

  void _cancelSilenceWatchdog() {
    silenceTimer?.cancel();
    silenceTimer = null;
    unawaited(_humanWaitStartSub?.cancel());
    unawaited(_humanWaitEndSub?.cancel());
    _humanWaitStartSub = null;
    _humanWaitEndSub = null;
    _pendingHumanWaitIds.clear();
    _lastHumanWaitResolvedAt = null;
  }

  void _startSilenceWatchdog() {
    _cancelSilenceWatchdog();
    final bus = deps.eventBus;
    if (bus != null &&
        workspaceId?.isNotEmpty == true &&
        conversationId?.isNotEmpty == true &&
        agentId?.isNotEmpty == true) {
      _humanWaitStartSub = bus.on<AgentAwaitingInput>().listen((event) {
        // A question that names its run pauses only that run: a concurrent
        // run by the same agent in the same conversation keeps its watchdog.
        // Questions from the external MCP lane carry no run id, so those
        // fall back to the agent + conversation match.
        final eventRun = event.runId;
        if (event.kind != AgentInputKind.question ||
            event.workspaceId != workspaceId ||
            event.conversationId != conversationId ||
            event.agentId != agentId ||
            (eventRun != null && runLogId != null && eventRun != runLogId)) {
          return;
        }
        _pendingHumanWaitIds.add(event.waitId);
      });
      _humanWaitEndSub = bus.on<AgentInputResolved>().listen((event) {
        if (event.workspaceId != workspaceId ||
            !_pendingHumanWaitIds.remove(event.waitId)) {
          return;
        }
        if (_pendingHumanWaitIds.isEmpty) {
          _lastHumanWaitResolvedAt = clock.now();
        }
      });
    }
    final threshold = silenceThreshold;
    // The baseline: a run that never prints anything is silent from the
    // moment the watchdog starts, not exempt from it.
    final startedAt = clock.now();
    silenceTimer = Timer.periodic(silenceCheckInterval, (_) {
      if (_pendingHumanWaitIds.isNotEmpty) {
        return;
      }
      var activeSince = startedAt;
      for (final mark in [lastOutputAt, _lastHumanWaitResolvedAt]) {
        if (mark != null && mark.isAfter(activeSince)) {
          activeSince = mark;
        }
      }
      if (clock.now().difference(activeSince) >= threshold) {
        final minutes = threshold.inMinutes;
        unawaited(
          _abortRun(
            reason: 'silence watchdog',
            failure: 'Silent run (no output for $minutes min)',
            logError: 'silent for $minutes min',
            debugLine: '[sandbox] Agent silent for $minutes min — terminating',
          ),
        );
      }
    });
  }

  /// Exec targets already being asked about, so a retry storm inside one run
  /// raises ONE prompt. The persisted decision covers every later run; this
  /// only covers the window before the first answer lands.
  final Set<String> _execGrantAsksInFlight = <String>{};

  /// Offers a grant for a `process-exec` denial the sandbox reported.
  ///
  /// Deliberately AFTER the fact and deliberately not blocking: a Seatbelt
  /// profile is fixed when the process starts, so the exec that was just
  /// refused cannot be retried under a new answer. The approval applies from
  /// the next command (the harness rebuilds its profile per command) or the
  /// next dispatch — which the confirmation copy says outright, rather than
  /// letting the operator approve and watch it fail again.
  Future<void> _maybeOfferExecGrant(SandboxViolation v) async {
    final service = deps.execGrantService;
    final wsId = workspaceId ?? '';
    final action = v.action;
    final target = v.target;
    if (service == null ||
        wsId.isEmpty ||
        !action.startsWith('process-exec') ||
        target.isEmpty ||
        !_execGrantAsksInFlight.add(target)) {
      return;
    }
    try {
      final granted = await service.recordDeniedExec(
        workspaceId: wsId,
        deniedPath: target,
        candidateRoots: _execGrantCandidateRoots(),
        managedRoots: await _managedExecGrantRoots(),
        spaceId: spaceId,
      );
      if (granted != null) {
        addEvent(
          DebugEvent(
            content:
                '[sandbox] allowed running programs under $granted — '
                'takes effect on the next command',
          ),
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning(
        'dispatch $dispatchId: exec-grant prompt failed for $target: $e',
      );
    } finally {
      _execGrantAsksInFlight.remove(target);
    }
  }

  void _forwardSandboxEvent(SandboxEvent event) {
    // The stop path owns completion. Late output from the dying process must
    // not replace its reason or leak unparsed stream-json into the transcript.
    // The one exception is the `result` of a turn being interrupted, which
    // carries what the turn spent.
    if (_cancelSource.isCancelled) {
      if (_claude.stdinClosed != null &&
          event.type == SandboxEventType.stdout) {
        _readInterruptedClaudeResult(event.content);
      }
      return;
    }
    final acp = _acpClient;
    switch (event.type) {
      case SandboxEventType.stdout:
        if (acp != null) {
          acp.feedLine(event.content);
        } else {
          _tryParseStructuredOutput(event.content);
        }
        break;
      case SandboxEventType.stderr:
        _sawProcessStderr = true;
        addEvent(
          ErrorEvent(
            content: acp != null ? '[acp] ${event.content}' : event.content,
          ),
        );
        break;
      case SandboxEventType.exit:
        // A process exit ends one `exec`, not the dispatch. Claude Code
        // reports a dead sign-in on the `result` line and then exits; the
        // runner turns that into the transcript (or parks the run on the
        // sign-in dialog) only after `exec` returns. Closing here dropped
        // that error — the turn finished as an empty bubble — and cancelled
        // the event subscription, so a failover onto the next account ran
        // without anyone listening.
        break;
      case SandboxEventType.killed:
        final reason = event.content.isNotEmpty
            ? event.content
            : '[sandbox] killed';
        addEvent(ErrorEvent(content: reason));
        _finish(error: reason);
        break;
      case SandboxEventType.starting:
        addEvent(DebugEvent(content: '[sandbox] booting sandbox session…'));
        break;
      case SandboxEventType.ready:
        break;
      case SandboxEventType.violation:
        final v = event.violation;
        final summary = v == null
            ? '[sandbox] denied operation'
            : '[sandbox] denied ${v.action} on ${v.target}';
        addEvent(
          SandboxViolationEvent(
            content: summary,
            action: v?.action,
            target: v?.target,
          ),
        );
        if (v != null) {
          unawaited(_maybeOfferExecGrant(v));
        }
        break;
    }
  }

  /// Yields until every sandbox event already queued for [eventsSub] has been
  /// handled.
  ///
  /// The adapters emit each line before `exec` returns, but a broadcast stream
  /// hands them to its listener one microtask at a time; the event-queue turn
  /// this waits for runs only once that microtask chain is empty.
  Future<void> _drainSandboxEvents() => Future<void>.delayed(Duration.zero);

  void _tryParseStructuredOutput(String line) {
    if (line.isEmpty) {
      return;
    }
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      }
    } catch (_) {
      addEvent(TextEvent(content: line));
      return;
    }
    if (json == null) {
      return;
    }
    final claudeParser = _claude.parser;
    if (claudeParser != null) {
      // The first stdout byte of this attempt: the one transport boundary the
      // adapter can honestly time (the CLI hides the provider request).
      _noteClaudeFirstStdout();
      claudeParser.process(json);
      return;
    }
    addEvent(TextEvent(content: line));
  }

  void _completeRun() {
    if (emittedDone) {
      return;
    }
    emittedDone = true;
    _cancelSilenceWatchdog();
    if (agentId != null) {
      deps.eventBus?.publish(
        AgentRunCompleted(
          agentId: agentId!,
          workspaceId: workspaceId,
          conversationId: conversationId,
          occurredAt: DateTime.now(),
          runId: runLogId,
        ),
      );
    }
    final taskId = runLogId;
    if (taskId != null) {
      final error = _lastTaskError;
      deps.eventBus?.publish(
        error != null
            ? TaskFailed(
                taskId: taskId,
                seq: _taskSeq++,
                errorMessage: error,
                workspaceId: workspaceId,
                agentId: agentId,
                occurredAt: DateTime.now(),
              )
            : TaskCompleted(
                taskId: taskId,
                seq: _taskSeq++,
                workspaceId: workspaceId,
                agentId: agentId,
                occurredAt: DateTime.now(),
              ),
      );
    }
    unawaited(_releaseRunCredentials());
    unawaited(eventsSub?.cancel());
    eventsSub = null;
    _closeController();
  }

  void _onPidAvailable(int forkedPid) {
    pid = forkedPid;
    _startSilenceWatchdog();
    _updateRunLogPidAndStart(forkedPid);
    final id = runLogId;
    if (id != null) {
      deps.eventBus?.publish(
        TaskDispatched(
          taskId: id,
          seq: _taskSeq++,
          workspaceId: workspaceId,
          agentId: agentId,
          occurredAt: DateTime.now(),
        ),
      );
    }
  }

  void _updateRunLogPidAndStart(int forkedPid) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    if (id == null || repo == null || ws == null || ws.isEmpty) {
      return;
    }
    unawaited(() async {
      try {
        final updated = await repo.updateRuntime(
          ws,
          id,
          pid: forkedPid,
          markRunning: true,
        );
        if (!updated) {
          _failRun('Run log $id missing when PID $forkedPid arrived');
        }
      } on Object catch (e, st) {
        CcInfraLog.error(
          'DispatchSession: Failed to persist PID $forkedPid for $id',
          e,
          st,
        );
        _failRun('Failed to persist PID: $e');
      }
    }());
  }

  /// Flips this run's row from `pending` to `running` as the harness loop starts.
  ///
  /// The PID-bearing transports get this from [_updateRunLogPidAndStart], but the
  /// built-in harness spawns no process and so has no PID — which left its row
  /// `pending` for the entire run. Anything reading status to tell "queued" apart
  /// from "working" (the sidebar's status dot, `deriveAgentLiveState` on the
  /// roster) therefore reported a busy agent as queued/idle until it finished.
  void _markRunStarted() {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    if (id == null || repo == null || ws == null || ws.isEmpty) {
      return;
    }
    unawaited(() async {
      try {
        await repo.updateRuntime(ws, id, markRunning: true);
      } on Object catch (e, st) {
        // Best-effort: a lost transition only mislabels the dot, so it must not
        // fail the run the way a lost PID does.
        CcInfraLog.warning(
          'DispatchSession: Failed to mark run $id running: $e\n$st',
        );
      }
    }());
  }

  void _updateRunLogPath(String path) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    if (id == null || repo == null || ws == null || ws.isEmpty) {
      return;
    }
    unawaited(() async {
      try {
        if (!await repo.updateRuntime(ws, id, logPath: path)) {
          _failRun('Run log $id missing when log path arrived');
        }
      } on Object catch (e, st) {
        CcInfraLog.error(
          'DispatchSession: Failed to persist log path $path for $id',
          e,
          st,
        );
        _failRun('Failed to persist log path: $e');
      }
    }());
  }

  /// Records what this run was actually composed of: the tool names handed to
  /// the loop, the mode profile, the model and the size of the assembled system
  /// prompt.
  ///
  /// This is the answer to "why did the agent not call the tool it was told to
  /// call?" — a question that previously required reading the SQLite file and
  /// replaying requests against the provider by hand, because the one column
  /// meant to hold it was never written. The tool list is the single most
  /// valuable field: nearly every mode-behavior bug reduces to a surface that
  /// did not contain what the prompt promised.
  ///
  /// The prompt is stored by length and digest, not verbatim — it can carry
  /// repo contents and memory facts and a run log is not the place for a copy
  /// of them. The digest is still enough to tell two runs apart.
  void _recordRunComposition({
    required List<String> toolNames,
    required String mode,
    required String model,
    required String adapter,
    required String systemPrompt,
    List<String> deferredToolNames = const [],
    int toolSchemaTokens = 0,
    String? effort,
  }) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    if (id == null || repo == null || ws == null || ws.isEmpty) {
      return;
    }
    final snapshot = jsonEncode({
      'mode': mode,
      'model': model,
      'adapter': adapter,
      'effort': effort ?? 'default',
      'toolCount': toolNames.length,
      'tools': toolNames,
      'deferredToolCount': deferredToolNames.length,
      'deferredTools': deferredToolNames,
      'toolSchemaTokens': toolSchemaTokens,
      'systemPromptChars': systemPrompt.length,
      'systemPromptSha256': sha256
          .convert(utf8.encode(systemPrompt))
          .toString(),
    });
    unawaited(() async {
      try {
        await repo.updateRuntime(
          ws,
          id,
          contextSnapshotJson: snapshot,
          modelId: model,
          effort: effort ?? 'default',
          taskFamily: mode,
        );
      } on Object catch (e, st) {
        // Diagnostics must never take the run down with them.
        CcInfraLog.error(
          'DispatchSession: Failed to persist run composition for $id',
          e,
          st,
        );
      }
    }());
  }

  void _failRun(String message) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to stamp — the
    // error event below is still emitted.
    final ws = workspaceId;
    if (id != null && repo != null && ws != null && ws.isNotEmpty) {
      unawaited(() async {
        try {
          final existing = await repo.getById(ws, id);
          if (existing != null && existing.completedAt == null) {
            await repo.completeIfActive(
              existing.copyWith(
                status: RunStatus.error,
                summary: message,
                completedAt: DateTime.now(),
              ),
              writeCost: false,
            );
          }
        } on Object catch (e, st) {
          CcInfraLog.error(
            'DispatchSession: Failed to mark run log $id as error',
            e,
            st,
          );
        }
      }());
    }
    addEvent(ErrorEvent(content: message));
  }

  late final _readMedia = ReadMediaCapture(
    emit: _emitEvent,
    workingDirectory: agentDirHostPath,
    workspaceId: workspaceId,
    store: deps.blobStore,
    renderer: deps.mediaRenderer,
    agentId: agentId,
    spaceId: spaceId,
    conversationId: conversationId,
  );

  /// Emits an [AgentProcessEvent] to the session stream, updates the last
  /// output timestamp and logs the event for persistence.
  void addEvent(AgentProcessEvent event) {
    if (event is ToolCallEvent) {
      _observeRepoTouch(event);
    }
    lastOutputAt = clock.now();
    _updateRunLogLastOutput();
    _readMedia.add(event);
  }

  void _emitEvent(AgentProcessEvent event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
    _logWriter.logEvent(event);
    _emitTaskLifecycle(event);
  }

  /// Mirrors the dispatch stream onto the typed task-lifecycle event bus so
  /// remote clients see `task:running → task:progress → task:completed` (plus
  /// typed `task:message` frames). Coarse by design — the per-token text stream
  /// stays on the dispatch space; this feed carries discrete milestones.
  void _emitTaskLifecycle(AgentProcessEvent event) {
    final bus = deps.eventBus;
    final id = runLogId;
    if (bus == null || id == null || event is DoneEvent) {
      return;
    }
    if (!_emittedTaskRunning) {
      _emittedTaskRunning = true;
      bus.publish(
        TaskRunning(
          taskId: id,
          seq: _taskSeq++,
          workspaceId: workspaceId,
          agentId: agentId,
          occurredAt: DateTime.now(),
        ),
      );
    }
    if (event is ToolCallEvent) {
      bus
        ..publish(
          TaskProgress(
            taskId: id,
            seq: _taskSeq++,
            note: 'tool: ${event.toolName}',
            workspaceId: workspaceId,
            agentId: agentId,
            occurredAt: DateTime.now(),
          ),
        )
        ..publish(_taskMessage(id, TaskMessageType.toolUse, event.toolName));
    } else if (event is ToolResultEvent) {
      bus.publish(
        _taskMessage(id, TaskMessageType.toolResult, _clip(event.outputs)),
      );
    } else if (event is ErrorEvent) {
      _lastTaskError = event.content;
      bus.publish(
        _taskMessage(id, TaskMessageType.error, _clip(event.content)),
      );
    }
  }

  TaskMessage _taskMessage(String id, TaskMessageType type, String content) =>
      TaskMessage(
        taskId: id,
        seq: _taskSeq++,
        messageType: type,
        content: content,
        workspaceId: workspaceId,
        agentId: agentId,
        occurredAt: DateTime.now(),
      );

  String _clip(String value, [int max = 500]) =>
      value.length <= max ? value : '${value.substring(0, max)}…';

  /// Minimum gap between `last_output_at` writes.
  ///
  /// This used to be a read-modify-write per streamed event. A model streaming
  /// at 20–50 deltas/sec produced 40–100 SQLite ops/sec per active run — each a
  /// full-row copy that fires the sync-feed trigger and its subscriber fan-out
  /// on the server's ONE shared DB connection, queueing every concurrent RPC
  /// read behind it. The value's only consumers are staleness/liveness checks
  /// measured in tens of seconds, so second-granularity is all it ever needed.
  static const Duration _lastOutputFlushInterval = Duration(seconds: 1);

  Timer? _lastOutputFlushTimer;
  DateTime? _pendingLastOutput;
  bool _lastOutputFlushInFlight = false;

  void _updateRunLogLastOutput() {
    if (!_canWriteRunLog) {
      return;
    }
    _pendingLastOutput = lastOutputAt;
    _lastOutputFlushTimer ??= Timer(_lastOutputFlushInterval, () {
      _lastOutputFlushTimer = null;
      unawaited(_flushLastOutput());
    });
  }

  bool get _canWriteRunLog {
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    return runLogId != null &&
        deps.runLogRepo != null &&
        ws != null &&
        ws.isNotEmpty;
  }

  /// Writes the buffered `lastOutputAt`, if any, and clears the pending mark.
  Future<void> _flushLastOutput() async {
    final stamp = _pendingLastOutput;
    final id = runLogId;
    final repo = deps.runLogRepo;
    final ws = workspaceId;
    if (stamp == null ||
        id == null ||
        repo == null ||
        ws == null ||
        ws.isEmpty ||
        _lastOutputFlushInFlight) {
      return;
    }
    _pendingLastOutput = null;
    _lastOutputFlushInFlight = true;
    try {
      await repo.updateRuntime(ws, id, lastOutputAt: stamp);
    } catch (_) {
    } finally {
      _lastOutputFlushInFlight = false;
    }
  }

  /// Cancels the debounce and writes whatever is still buffered. Called on
  /// teardown so the final `lastOutputAt` is never lost to the debounce window.
  Future<void> _finalizeLastOutput() async {
    _lastOutputFlushTimer?.cancel();
    _lastOutputFlushTimer = null;
    await _flushLastOutput();
  }

  Future<void> _openRunLog() async {
    await _logWriter.open(
      agentDirHostPath: agentDirHostPath,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      ticketId: ticketId,
      cliName: cliName,
      modelId: modelId,
    );
    final path = _logWriter.logPath;
    if (path != null) {
      _updateRunLogPath(path);
    }
  }

  /// The sanctioned alternative to offer when a policy denies a tool.
  ///
  /// A denial that only says "no" leaves a model to guess; naming the mode's own
  /// output verb turns the denial into a redirect.
  static String? _remediationFor(ModeCapabilityProfile profile) {
    if (profile.requiredVerbs.isEmpty) {
      return null;
    }
    final verbs = profile.requiredVerbs.map((v) => '`$v`').join(' or ');
    return 'In ${profile.mode.name} mode, deliver the '
        '${profile.deliverableNoun} with $verbs instead.';
  }

  /// Marks this run as having ended without its declared deliverable.
  ///
  /// `status` deliberately stays `completed`: the process exited cleanly and
  /// flipping it to `error` would ripple into pipeline-step failure and
  /// ticket-fail paths for no user benefit. The signal lives where consumers
  /// already look — `liveness` (surfaced by the agent live-state and team-member
  /// status views) and `errorFamily` — plus a plain-language summary.
  ///
  /// Best-effort: a failed write must never fail the run.
  Future<void> _markContractUnmet(CompletionContract contract) async {
    final repo = deps.runLogRepo;
    final id = runLogId;
    final ws = workspaceId;
    if (repo == null || id == null || ws == null || ws.isEmpty) {
      return;
    }
    try {
      await repo.updateRuntime(
        ws,
        id,
        liveness: RunLiveness.empty,
        errorFamily: RunErrorFamily.silentRun,
        summary: contract.unmetSummary,
      );
    } on Object catch (e) {
      CcInfraLog.warning('Failed to mark run $id contract-unmet: $e');
    }
  }

  /// Closes the NDJSON run log. The first close writes the `end` record; an
  /// outside stop's reason replaces whatever the transport closes with, so a
  /// harness that exits 0 on the cancel cannot record a stopped run as clean.
  Future<void> _closeRunLog({int? exitCode, Object? error}) async {
    await _readMedia.drained;
    await _finalizeLastOutput();
    final abort = _abortLogError;
    await _logWriter.close(
      exitCode: abort == null ? exitCode : null,
      error: abort ?? error,
    );
  }

  void _closeController() {
    _cancelSilenceWatchdog();
    // Close at once when no Read capture is in flight, so a caller that awaited
    // stop()/terminate() sees a closed stream; otherwise close only after the
    // queued events have been emitted.
    if (_readMedia.isIdle) {
      if (!controller.isClosed) {
        unawaited(controller.close());
      }
      return;
    }
    unawaited(
      _readMedia.drained.then((_) {
        if (!controller.isClosed) {
          unawaited(controller.close());
        }
      }),
    );
  }
}

/// Where a dispatch's directories are: the per-agent overlay's shared
/// worktrees and attachments, derived from the directory layout the
/// provisioner creates — never from a path or symlink the agent could change.
class _OverlayLayout {
  const _OverlayLayout({
    required this.isOverlay,
    this.reposDir,
    this.attachmentsDir,
  });

  /// Whether the cwd is a per-agent overlay (a config dir distinct from it):
  /// `<convRoot>/agents/<slug>`, with the space's shared directories two
  /// levels up.
  final bool isOverlay;

  /// `<convRoot>/repos`, when the overlay has one.
  final String? reposDir;

  /// `<convRoot>/attachments`, when anything was attached to the space.
  final String? attachmentsDir;

  static bool _overlay(String cwd, String? configDir) =>
      configDir != null && configDir.isNotEmpty && !p.equals(configDir, cwd);

  static String _repos(String cwd) =>
      p.join(p.dirname(p.dirname(cwd)), 'repos');

  static String _attachments(String cwd) =>
      p.join(p.dirname(p.dirname(cwd)), SpacePromptAttachments.dirName);

  static _OverlayLayout resolve({
    required String cwd,
    required String? configDir,
  }) {
    if (!_overlay(cwd, configDir)) {
      return const _OverlayLayout(isOverlay: false);
    }
    final repos = _repos(cwd);
    final attachments = _attachments(cwd);
    return _OverlayLayout(
      isOverlay: true,
      reposDir: Directory(repos).existsSync() ? repos : null,
      attachmentsDir: Directory(attachments).existsSync() ? attachments : null,
    );
  }
}
