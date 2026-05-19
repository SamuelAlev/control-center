import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/capability_preamble.dart';
import 'package:cc_domain/features/dispatch/domain/services/harness_cost_calculator.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/edit/file_edit_service.dart';
import 'package:cc_infra/src/harness/cc_natives_file_search_port.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:cc_infra/src/harness/mcp_tool_bridge.dart';
import 'package:cc_infra/src/harness/tools/apply_patch_tool.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:cc_infra/src/sandboxing/env_sanitizer.dart';
import 'package:cc_infra/src/sandboxing/run_log_writer.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Shared dependencies for a [DispatchSession].
class SandboxDispatchDeps {
  /// Creates [SandboxDispatchDeps].
  SandboxDispatchDeps({
    required this.sandbox,
    required this.broker,
    required this.agentRepo,
    required this.runLogRepo,
    required this.defaultCaps,
    required this.eventBus,
    required this.backendRegistry,
    this.todoRepo,
    this.runTranscriptRecorder,
    this.mcpConfigPathResolver,
    this.protectedPathsResolver,
    this.sandboxManager,
    this.confirmationPort,
    this.actionGuard,
    this.mcpRegistry,
    this.harnessCredentialStore,
    this.harnessCredentialRefresher,
    this.modelResolver,
    this.harnessProviderFactory = const HarnessProviderFactory(),
    this.agentLoop = const AgentLoopRunner(),
    this.resolveGitIdentity,
    this.resolveUserGitHubToken,
    this.autonomyResolver,
    FileSearchPort? fileSearch,
  }) : fileSearch = fileSearch ?? CcNativesFileSearchPort();

  /// Fuzzy file search shared by the harness `read` (did-you-mean recovery)
  /// and `file_search` tools. Defaults to the fff-backed adapter; the server
  /// injects its long-lived instance so scan caches are shared.
  final FileSearchPort fileSearch;

  /// OS-level sandbox used to run sandboxed CLI adapters (e.g. Pi).
  /// Resolves the per-channel autonomy dial for (workspaceId, channelId,
  /// agentId) (PRD 16 §12): `proposeOnly` | `actWithApproval` | `actFreely`, or
  /// null for the default (act with approval — the fail-closed gate).
  ///
  /// The workspace is part of the key because the channel row lives in that
  /// workspace's database; a channel id alone names nothing.
  final Future<String?> Function(
    String workspaceId,
    String channelId,
    String agentId,
  )?
  autonomyResolver;

  /// The sandbox port isolating this dispatch session.
  final SandboxPort sandbox;

  /// Credential broker that mints per-run scoped tokens.
  final CredentialBrokerPort broker;

  /// Agent repository (capability lookup).
  final AgentRepository agentRepo;

  /// Optional run-log repository.
  final AgentRunLogRepository? runLogRepo;

  /// Records a subagent run's own activity timeline: folds the child loop's
  /// events into transcript segments, streams them live under the CHILD run id,
  /// and throttle-flushes them for replay.
  ///
  /// Null on a host with no dispatch stack / no live registry — subagent activity
  /// then stays unrecorded (the pre-existing behavior) and the child still runs.
  final RunTranscriptRecorder? runTranscriptRecorder;

  /// Optional per-conversation todo repository. When set, `/goal` records the
  /// invocation as the conversation's working goal (surfaced in the General
  /// pane with the todos nested beneath it). Null skips goal persistence.
  final TodoRepository? todoRepo;

  /// Default capabilities when an agent has none.
  final AgentCapabilities defaultCaps;

  /// Optional domain event bus.
  final DomainEventBus? eventBus;

  /// Resolves the MCP config file path to point the spawned `claude`/Pi/ACP
  /// adapter at the Control Center MCP server (`--mcp-config`), or null when
  /// unavailable. Takes the per-session cwd plus the dispatch identity scope
  /// (workspace / agent / conversation) so the derived client config is
  /// written into `<cwd>/.mcp.json` (server-derived from `mcp_config.json` at
  /// dispatch time, carrying the live port/token) with `X-CC-*` scope headers
  /// that the MCP HTTP server enforces (workspace_id forced, agent/
  /// conversation ids filled when omitted). Injected at the composition root
  /// because the writer is host-specific (cc_server's `ServerMcpControl`),
  /// keeping this package free of `package:control_center`. When null the
  /// adapter runs without `--mcp-config` (the agent sees no `mcp__*` tools).
  final Future<String?> Function(
    String cwd, {
    String? workspaceId,
    String? agentId,
    String? conversationId,
  })?
  mcpConfigPathResolver;

  /// Resolves host paths that must never be writable inside any sandbox for a
  /// workspace — the ORIGINAL registered repo checkouts (`repos.path`). They
  /// become sandbox deny-write rules in every mode; agents only ever write in
  /// their per-conversation CoW worktrees. Null (or a failed lookup) degrades
  /// to no extra denies. Injected at the composition root (cc_server owns the
  /// repo registry).
  final Future<List<String>> Function(String workspaceId)?
  protectedPathsResolver;

  /// Maps CLI names to their execution backend. The session resolves a backend
  /// per dispatch and switches on its transport (acp / structuredCli /
  /// claudeCli).
  final BackendRegistry backendRegistry;

  /// The process-wide [SandboxManager] used to wrap the ACP transport through
  /// the OS sandbox. Null when the backend is `none` (opt-out / unsupported) —
  /// ACP then spawns bare but still gets env sanitization + universal command
  /// preflight. The structuredCli / claudeCli transports sandbox through
  /// [SandboxDispatchDeps.sandbox] directly, not this manager.
  final SandboxManager? sandboxManager;

  /// Optional [ConfirmationPort] for synchronous UAC approval of prompt-tier
  /// commands. When null, prompt decisions proceed with a warning (Phase 3.5
  /// degrades gracefully when no approver is wired).
  final ConfirmationPort? confirmationPort;

  /// The shared PRD 24 action-guardrail service. When set, the built-in harness
  /// loop resolves each tool's declared [HarnessTool.actionClasses] against the
  /// workspace policy before dispatch — the effect net that finally covers the
  /// built-in agent loop (bridged MCP tools call `McpTool.call()` directly, so
  /// the MCP dispatcher's guard never sees them). Null skips the gate; the
  /// autonomy dial + fail-closed approval remain the residual net.
  final ActionGuardService? actionGuard;

  /// The MCP tool registry, exposing CC's orchestration tools to the built-in
  /// harness loop as first-class tools. Null disables MCP tools in the harness
  /// (only the built-in filesystem tools are available).
  final McpToolRegistry? mcpRegistry;

  /// Resolves LLM provider credentials for the harness. Null falls back to env
  /// vars / per-adapter env overrides only.
  final ProviderCredentialStore? harnessCredentialStore;

  /// Refreshes an expiring OAuth credential before a harness run. Null skips
  /// refresh (API-key providers are unaffected).
  final ProviderCredentialRefresher? harnessCredentialRefresher;

  /// Resolves a qualified `provider/model` id to its catalog [ModelInfo], used
  /// by the harness for reasoning-effort clamping, USD cost pricing, and
  /// context-window sizing. Null → effort passes unclamped, cost stays 0, and
  /// compaction falls back to a conservative default window.
  final ModelInfo? Function(String qualifiedId)? modelResolver;

  /// Builds the harness [LlmProviderPort] from a provider id + model + key.
  final HarnessProviderFactory harnessProviderFactory;

  /// The harness agent loop implementation.
  final AgentLoop agentLoop;

  /// Resolves the git author identity of the human a run executes for, used to
  /// build the commit co-author trailer. Called with the run's
  /// `requestedByUserId` (null resolves to the server owner). Injected at the
  /// composition root, which owns the user repository; null skips the trailer.
  final Future<({String name, String email})?> Function(String? userId)?
  resolveGitIdentity;

  /// Resolves a member's own stored GitHub token so a run requested by that
  /// member uses THEIR credential instead of the owner's. Null (or a null
  /// return) keeps the broker-minted/env token.
  final Future<String?> Function(String userId)? resolveUserGitHubToken;
}

/// A session that dispatches and manages a single sandboxed agent run.
/// Default per-run priced cost cap, in cents: what one unattended segment of
/// an autonomous command (/goal, /loop) may burn before the loop's external
/// budget check stops it mid-run. The goal supervisor threads a goal's
/// REMAINING budget (capped at this default) via
/// [DispatchSession.costCapCents] so an explicit `/goal --budget` is never
/// overshot by a whole segment.
const defaultRunCostCapCents = 500;

/// A session that dispatches and manages a single sandboxed agent run.
class DispatchSession {
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
    required this.agentDirHostPath,
    required this.modelId,
    required this.callerEnv,
    required this.agentId,
    required this.workspaceId,
    required this.conversationId,
    required this.runLogId,
    required this.mode,
    this.agentName,
    this.requestedByUserId,
    this.ticketId,
    this.wakeContext,
    this.silenceTimeoutMinutes,
    this.effortLevel,
    this.agentConfigDir,
    this.adapterArgsOverride = const [],
    this.adapterEnvOverride = const {},
    this.costCapCents,
    this.resolveBinary = resolveBinaryPath,
  });

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

  /// The user's message verbatim, before context layering.
  ///
  /// [prompt] arrives wrapped as `<context>…</context>\n\n<text>` (see
  /// `PromptBuilder.build`), so testing IT for a leading slash always fails.
  /// Built-in slash commands are parsed from this field; null falls back to
  /// [prompt] for callers that do no layering.
  final String? userText;

  /// Host-side path to the agent's working directory.
  final String agentDirHostPath;

  /// Optional model identifier to pass to the CLI.
  final String? modelId;

  /// Environment variables from the calling context.
  final Map<String, String> callerEnv;

  /// Optional agent identifier for capability lookup.
  final String? agentId;

  /// The agent's display name, used to stamp the per-run git author identity.
  /// Null falls back to a repo lookup by [agentId], then to the id itself.
  final String? agentName;

  /// The human on whose behalf this run executes. Drives the commit co-author
  /// trailer and per-user GitHub credential selection; null attributes the run
  /// to the server owner.
  final String? requestedByUserId;

  /// Optional workspace identifier.
  final String? workspaceId;

  /// Optional conversation identifier for scoped credential minting.
  final String? conversationId;

  /// Optional run-log identifier for persistent logging.
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

  /// Per-adapter argv appended after the backend's own args (e.g. YOLO /
  /// skip-permissions flags).
  final List<String> adapterArgsOverride;

  /// Per-adapter env override (e.g. API keys). Merged on top of the backend's
  /// default env; caller/broker env still wins for security-critical keys.
  final Map<String, String> adapterEnvOverride;

  /// Resolves a CLI binary name to its absolute path. Defaults to the real
  /// [resolveBinaryPath] host probe; tests inject a stub so the dispatch flow
  /// can be exercised without the adapter binary (e.g. `pi`) installed.
  final Future<String?> Function(String binary) resolveBinary;

  /// Active ACP subprocess + client, when the resolved backend is ACP. Held so
  /// the session can tear them down on terminate / silence timeout.
  Process? _acpProcess;
  AcpClient? _acpClient;
  StreamSubscription<AgentProcessEvent>? _acpEventsSub;

  /// Stream controller for [AgentProcessEvent]s emitted by this session.
  final StreamController<AgentProcessEvent> controller =
      StreamController<AgentProcessEvent>();

  /// Handle to the scoped credential minted for this run.
  String? credHandle;

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

  /// PID of the forked sandbox process, set once available.
  int? pid;

  /// Active Claude stream-json parser, when [cliName] is `claude`. Held so
  /// parsed stdout lines route to it from the shared sandbox-event forwarder.
  ClaudeStreamJsonParser? _claudeParser;

  /// Timestamp of the most recent output from the agent.
  DateTime? lastOutputAt;

  /// Periodic timer that checks for silence and terminates if exceeded.
  Timer? silenceTimer;

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

  /// Mid-run steering inbox for the built-in harness. A client can push a
  /// message here while a run is active (via [steer]); the loop drains it at the
  /// next turn boundary, so the user can nudge a running agent without starting
  /// a new dispatch. Unused by the external-CLI transports.
  final SteeringQueue _steering = SteeringQueue();

  /// Pauses the built-in harness loop at the next clean turn boundary
  /// (take-over, PRD 16 §8). Subagent loops share the gate, so a take-over
  /// holds the whole conversation. Unused by external-CLI transports.
  final PauseGate _pauseGate = PauseGate();

  /// Whether a built-in harness loop is currently driving this session (the
  /// only transport that can pause at a turn boundary).
  bool _harnessActive = false;

  /// Requests a turn-boundary pause. Returns false when no pausable
  /// (built-in harness) run is live — external CLI transports have no safe
  /// boundary; callers fall back to stopping the run.
  bool pauseHarness() {
    if (!_harnessActive) {
      return false;
    }
    _pauseGate.pause();
    return true;
  }

  /// Releases a paused loop (hand-back). Idempotent.
  void resumeHarness() => _pauseGate.resume();

  /// Queues a mid-run steering message for the active built-in harness run.
  ///
  /// [channel] selects the lane: [SteeringChannel.steering] (default) is
  /// injected at the next turn boundary; [SteeringChannel.aside] is a passive
  /// note; [SteeringChannel.followUp] runs only once the agent would otherwise
  /// stop. No-op for non-harness transports.
  void steer(
    String content, {
    SteeringChannel channel = SteeringChannel.steering,
  }) {
    if (content.trim().isEmpty) {
      return;
    }
    _steering.enqueue(
      SteeringMessage(
        content: content.trim(),
        channel: channel,
        enqueuedAt: DateTime.now(),
      ),
    );
  }

  /// Monotonic counter used to disambiguate concurrent subagent run ids.
  int _subagentSeq = 0;

  /// Prefix used when constructing sandbox session identifiers.
  static const String agentSessionPrefix = 'agent-';

  /// Tools that ARE the user interaction, so the harness must not wrap them in a
  /// second approval prompt (they gather the user's answer themselves).
  static const Set<String> _harnessInteractionTools = {
    'ask_user_question',
    'request_confirmation',
  };

  /// A short, human-readable summary of the salient tool arguments (URL, path,
  /// command) so an approval prompt shows *what* is being approved, not just the
  /// tool name. Returns an empty string when there is nothing worth showing.
  static String _approvalArgsSummary(Map<String, dynamic> args) {
    for (final key in const ['url', 'command', 'path', 'query', 'file']) {
      final value = args[key];
      if (value is String && value.trim().isNotEmpty) {
        final v = value.length > 200 ? '${value.substring(0, 200)}…' : value;
        return '\n$key: $v';
      }
    }
    return '';
  }

  /// Per-run git author/committer identity + co-author trailer env, computed
  /// once by [_prepareRunIdentity] before any transport launches. Commits an
  /// agent makes are authored AS the agent (never impersonating a human), with
  /// the requesting human credited via a co-author trailer.
  Map<String, String> _gitIdentityEnv = const {};

  /// The `Co-Authored-By: Name <email>` trailer for the requesting human's
  /// git identity, or null when no resolver is wired / resolution failed.
  String? _coAuthorTrailer;

  /// The requesting member's own GitHub token, when they stored one. Overrides
  /// the broker-provided token in the merged env so the member's runs act
  /// under THEIR GitHub identity, not the owner's.
  String? _memberGitHubToken;

  /// Env var carrying the co-author trailer to the spawned agent CLI, so any
  /// tooling in the run can stamp it onto commit messages.
  static const String coAuthorTrailerEnvKey = 'CC_GIT_COAUTHOR_TRAILER';

  /// Resolves the per-run identity surface (best-effort — a failure never
  /// blocks dispatch):
  ///
  /// - `GIT_AUTHOR_*` / `GIT_COMMITTER_*` name the AGENT (display name plus an
  ///   " (agent)" suffix; a stable synthetic address keyed by agent id), so
  ///   `git log` attributes machine commits honestly.
  /// - [coAuthorTrailerEnvKey] carries the requesting human's
  ///   `Co-Authored-By:` line (owner fallback when no requester is known).
  /// - The requester's own GitHub token is fetched for the env merge.
  ///
  /// Keys the caller env already sets are left alone — an explicit caller
  /// identity always wins.
  Future<void> _prepareRunIdentity() async {
    final env = <String, String>{};

    // Agent identity: threaded display name, else a repo lookup, else the id.
    var name = agentName;
    final identityWorkspaceId = workspaceId;
    if ((name == null || name.trim().isEmpty) &&
        agentId != null &&
        agentId!.isNotEmpty &&
        identityWorkspaceId != null &&
        identityWorkspaceId.isNotEmpty) {
      try {
        final agent = await deps.agentRepo.getById(
          identityWorkspaceId,
          agentId!,
        );
        name = agent?.name;
      } catch (_) {
        // Lookup is best-effort; fall through to the id.
      }
    }
    final displayName = (name == null || name.trim().isEmpty)
        ? (agentId ?? 'agent')
        : name.trim();
    final idSlug = (agentId ?? 'oneshot').toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '-',
    );
    final authorName = '$displayName (agent)';
    final authorEmail = '$idSlug@agents.control-center.local';
    env['GIT_AUTHOR_NAME'] = authorName;
    env['GIT_COMMITTER_NAME'] = authorName;
    env['GIT_AUTHOR_EMAIL'] = authorEmail;
    env['GIT_COMMITTER_EMAIL'] = authorEmail;

    // Requesting human → co-author trailer (owner fallback when null).
    final resolveIdentity = deps.resolveGitIdentity;
    if (resolveIdentity != null) {
      try {
        final human = await resolveIdentity(requestedByUserId);
        if (human != null) {
          _coAuthorTrailer = 'Co-Authored-By: ${human.name} <${human.email}>';
          env[coAuthorTrailerEnvKey] = _coAuthorTrailer!;
        }
      } catch (e) {
        CcInfraLog.warning(
          'DispatchSession: git co-author resolution failed: $e',
        );
      }
    }

    // Caller env wins: drop any key the caller explicitly set.
    env.removeWhere((key, _) => callerEnv.containsKey(key));
    _gitIdentityEnv = env;

    // Requesting member's own GitHub token (never logged).
    final requester = requestedByUserId;
    final resolveToken = deps.resolveUserGitHubToken;
    if (requester != null && requester.isNotEmpty && resolveToken != null) {
      try {
        final token = await resolveToken(requester);
        if (token != null && token.isNotEmpty) {
          _memberGitHubToken = token;
        }
      } catch (e) {
        CcInfraLog.warning(
          'DispatchSession: per-user GitHub token lookup failed: $e',
        );
      }
    }
  }

  /// Translates capabilities into environment variables for the sandboxed
  /// process (e.g. disabling git push when not permitted).
  static Map<String, String> capabilityEnv(AgentCapabilities caps) {
    final env = <String, String>{};
    if (!caps.canPushToRepo) {
      env['GIT_ASKPASS'] = '/usr/bin/false';
      env['GIT_TERMINAL_PROMPT'] = '0';
    }
    return env;
  }

  /// Builds the per-dispatch bind-mount set — the cross-agent isolation
  /// boundary.
  ///
  /// Normal per-agent overlay dispatch mounts THREE paths:
  /// - [agentDirHostPath] (the overlay cwd) — **rw**: own scratch + derived
  ///   `.mcp.json`.
  /// - [agentConfigDir] (the agent's global config dir) — **ro**: AGENTS.md +
  ///   `.agents` symlink targets (writes blocked).
  /// - `<convRoot>/repos` — **rw**: the shared conversation worktrees (the
  ///   overlay's `repos → ../../repos` symlink resolves through this). Only
  ///   mounted when it exists on disk.
  ///
  /// Fallback / oneshot (no overlay — the cwd IS the agent dir, or no config
  /// dir was threaded): a single writable cwd mount (unchanged behaviour).
  /// Sibling agent folders are never mounted, so an agent cannot reach another
  /// agent's config/skills.
  List<SandboxBindMount> _bindMounts() {
    final cwd = agentDirHostPath;
    final configDir = agentConfigDir;
    if (configDir == null || configDir.isEmpty || p.equals(configDir, cwd)) {
      return [SandboxBindMount(hostPath: cwd, guestPath: cwd)];
    }
    final mounts = <SandboxBindMount>[
      SandboxBindMount(hostPath: cwd, guestPath: cwd),
      SandboxBindMount(
        hostPath: configDir,
        guestPath: configDir,
        readOnly: true,
      ),
    ];
    // cwd nests as <convRoot>/agents/<slug>, so the shared repos dir is two
    // levels up. Mount it writable when present so the overlay `repos` symlink
    // resolves in the guest namespace (identical host/guest paths).
    final reposPath = p.join(p.dirname(p.dirname(cwd)), 'repos');
    if (Directory(reposPath).existsSync()) {
      mounts.add(SandboxBindMount(hostPath: reposPath, guestPath: reposPath));
    }
    return mounts;
  }

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
  /// conversation worktrees dir (`<convRoot>/repos`) when this session's cwd
  /// is a per-agent overlay. Without it the tools refuse the worktrees' real
  /// paths — the overlay only reaches them through its `repos` symlink, whose
  /// target is lexically outside the cwd. Derived from the directory layout
  /// (mirrors [_bindMounts]), never from the agent-writable symlink itself.
  List<String> _workspaceSharedRoots() {
    final cwd = agentDirHostPath;
    final configDir = agentConfigDir;
    if (configDir == null || configDir.isEmpty || p.equals(configDir, cwd)) {
      return const [];
    }
    final reposPath = p.join(p.dirname(p.dirname(cwd)), 'repos');
    return Directory(reposPath).existsSync() ? [reposPath] : const [];
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
    );
  }

  /// Starts the agent process and manages its lifecycle.
  ///
  /// Resolves the execution backend for [cliName] from the registry and
  /// switches on its transport: `claudeCli` (sandboxed `claude -p` emitting
  /// stream-json NDJSON), `structuredCli` (sandboxed `--mode json` NDJSON
  /// CLI), or `acp` (JSON-RPC over stdio). An unknown cliName emits a clear
  /// error + DoneEvent and exits 127 — never throws.
  Future<void> run() async {
    try {
      final caps = await _capabilitiesFor(agentId);

      final scoped = await deps.broker.mint(
        conversationId: conversationId ?? 'unknown',
        capabilities: caps,
      );
      credHandle = scoped.handle;

      // Resolve the per-run git identity + requester credentials before any
      // transport launches, so every merged env carries them. (After the
      // mint: callers may fail a stalled mint to abort the run early.)
      await _prepareRunIdentity();

      final wsId = workspaceId ?? '';
      final agentKey = (agentId != null && agentId!.isNotEmpty)
          ? agentId!
          : 'oneshot';
      final convKey = conversationId ?? 'no-conv';
      final sandboxSessionId =
          '$agentSessionPrefix$agentKey::$convKey::${mode.name}';

      await _openRunLog(caps: caps);

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
        unawaited(_closeRunLog(exitCode: 127));
        addEvent(DoneEvent());
        _completeRun();
        return;
      }

      switch (backend.transport) {
        case AdapterTransport.claudeCli:
          await _runClaudeCli(
            caps: caps,
            scoped: scoped,
            sandboxSessionId: sandboxSessionId,
            wsId: wsId,
          );
        case AdapterTransport.structuredCli:
          await _runStructuredCli(
            caps: caps,
            scoped: scoped,
            sandboxSessionId: sandboxSessionId,
            wsId: wsId,
          );
        case AdapterTransport.acp:
          await _runAcp(caps: caps, scopedNotes: scoped.notes);
        case AdapterTransport.harness:
          await _runHarness(caps: caps, scoped: scoped, wsId: wsId);
      }
      onScheduleCooldown(sandboxSessionId);
    } on Object catch (e) {
      unawaited(_closeRunLog(error: e));
      addEvent(ErrorEvent(content: '[sandbox] dispatch failed: $e'));
      _closeController();
    }
  }

  /// Runs a structured-CLI adapter (Pi's `--mode json`) inside the OS
  /// sandbox: resolves the binary, provisions a sandbox handle, builds the
  /// argv via the backend, merges env (caller → broker → backend default →
  /// adapter override → capability), and streams NDJSON events.
  Future<void> _runStructuredCli({
    required AgentCapabilities caps,
    required ScopedCredentials scoped,
    required String sandboxSessionId,
    required String wsId,
  }) async {
    final backend = deps.backendRegistry.backendFor(cliName)!;
    for (final note in scoped.notes) {
      addEvent(DebugEvent(content: '[sandbox] $note'));
    }

    final cliPath = await resolveBinary(cliName);
    if (cliPath == null) {
      addEvent(
        ErrorEvent(
          content:
              '[sandbox] "$cliName" not found. Install it on your host '
              'or check Settings → Adapters for the detected path.',
        ),
      );
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    // Point the structured adapter (Pi) at the Control Center MCP server.
    // Resolving the path is what WRITES `<cwd>/.mcp.json` and force-starts the
    // loopback MCP endpoint (the resolver's side effects) — exactly like the
    // ACP and Claude transports. Without this the structured adapter gets zero
    // `mcp__*` tools (no memory writes, no `submit_output`). Pi's mcp-adapter
    // loads the file both from `--mcp-config` and as the project-scoped
    // `<cwd>/.mcp.json`; we pass the flag explicitly for parity with Claude and
    // to be independent of project-config discovery. A missing/unreadable file
    // degrades to "no CC tools" rather than failing the turn.
    var mcpConfigPath = await _resolveMcpConfigPath();
    if (mcpConfigPath != null && !File(mcpConfigPath).existsSync()) {
      addEvent(
        DebugEvent(
          content:
              '[sandbox] MCP config not found at $mcpConfigPath — running '
              'without the control-center tools.',
        ),
      );
      mcpConfigPath = null;
    }

    final handle = await onResolveHandle(
      sessionId: sandboxSessionId,
      spec: SandboxSpec(
        sessionId: sandboxSessionId,
        workspaceId: wsId,
        agentId: agentId,
        bindMounts: _bindMounts(),
        guestWorkdir: agentDirHostPath,
        networkEnabled: caps.canAccessNetwork,
        mode: mode,
        capabilities: caps,
        protectedPaths: await _protectedPaths(),
      ),
      emit: addEvent,
    );

    if (handle.state == SandboxState.error) {
      throw StateError('sandbox launch failed: ${handle.error}');
    }

    eventsSub = deps.sandbox.events(handle).listen(_forwardSandboxEvent);

    final argv = <String>[
      cliPath,
      ...backend.buildArgs(modelId: modelId, effortLevel: effortLevel),
      if (mcpConfigPath != null) ...['--mcp-config', mcpConfigPath],
      ...adapterArgsOverride,
    ];

    if (!await _preflightCommand(argv)) {
      return;
    }
    final scopedEnv = scoped.environment;
    final mergedEnv = _mergedEnv(
      caps: caps,
      scopedEnv: scopedEnv,
      backendEnv: backend.defaultEnv(),
    );

    addEvent(DebugEvent(content: '[sandbox] launching $cliName…'));
    final exitCode = await deps.sandbox.exec(
      handle,
      argv,
      env: mergedEnv,
      onPid: (forkedPid) {
        _onPidAvailable(forkedPid);
        addEvent(
          DebugEvent(content: '[sandbox] $cliName running (pid $forkedPid)'),
        );
      },
      stdinInput: prompt,
    );
    unawaited(_closeRunLog(exitCode: exitCode));

    if (exitCode == 127) {
      addEvent(
        ErrorEvent(
          content:
              '[sandbox] "$cliName" not found on PATH. Install it on your '
              'host or disable sandboxing in Settings → Sandboxing.',
        ),
      );
    } else if (exitCode != 0) {
      addEvent(
        ErrorEvent(content: '[sandbox] $cliName exited with code $exitCode'),
      );
    } else {
      addEvent(
        DebugEvent(content: '[sandbox] $cliName exited cleanly (code 0)'),
      );
    }
    _completeRun();
  }

  /// Runs an ACP adapter (OpenCode/Gemini/Goose/Cursor/Codex): spawns
  /// `<cliPath> <acpArgs> <argsOverride>` as a subprocess, speaks JSON-RPC 2.0
  /// over stdio, and translates `session/update` notifications into events.
  Future<void> _runAcp({
    required AgentCapabilities caps,
    required List<String> scopedNotes,
  }) async {
    final backend = deps.backendRegistry.backendFor(cliName)!;
    for (final note in scopedNotes) {
      addEvent(DebugEvent(content: '[acp] $note'));
    }

    final cliPath = await resolveBinary(cliName);
    if (cliPath == null) {
      addEvent(
        ErrorEvent(
          content:
              '[acp] "$cliName" not found. Install it on your host '
              'or check Settings → Adapters for the detected path.',
        ),
      );
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    final mcpConfigPath = await _resolveMcpConfigPath();
    final argv = <String>[
      cliPath,
      if (backend.acpArgs != null && backend.acpArgs!.isNotEmpty)
        backend.acpArgs!,
      ...adapterArgsOverride,
    ];

    if (!await _preflightCommand(argv)) {
      return;
    }
    final mergedEnv = _mergedEnv(
      caps: caps,
      scopedEnv: const {},
      backendEnv: backend.defaultEnv(),
    );

    addEvent(DebugEvent(content: '[acp] launching $cliName…'));

    late Process process;
    try {
      final manager = deps.sandboxManager;
      final sanitizedParent = const EnvSanitizer().hardenPlatform({});
      if (manager != null) {
        // Route through the OS sandbox (sandbox-exec / bwrap).
        final config = await _buildSandboxConfig(caps);
        final wrap = await manager.wrap(
          config: config,
          argv: argv,
          workingDirectory: agentDirHostPath,
        );
        process = await Process.start(
          wrap.executable,
          wrap.argv,
          workingDirectory: agentDirHostPath,
          environment: {...sanitizedParent, ...wrap.environment, ...mergedEnv},
          includeParentEnvironment: false,
          runInShell: false,
        );
      } else {
        CcInfraLog.warning(
          '[acp] No native sandbox available; '
          'spawning $cliName with env sanitization only.',
        );
        process = await Process.start(
          cliPath,
          argv.skip(1).toList(),
          workingDirectory: agentDirHostPath,
          environment: {...sanitizedParent, ...mergedEnv},
          includeParentEnvironment: false,
          runInShell: false,
        );
      }
    } on Object catch (e) {
      addEvent(ErrorEvent(content: '[acp] failed to start $cliName: $e'));
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }
    _acpProcess = process;
    pid = process.pid;
    _onPidAvailable(process.pid);
    addEvent(
      DebugEvent(content: '[acp] $cliName running (pid ${process.pid})'),
    );

    final client = AcpClient(
      send: (line) {
        try {
          process.stdin.writeln(line);
        } on Object catch (_) {
          // stdin may already be closed after a crash; ignore.
        }
      },
      onDone: () {},
    );
    _acpClient = client;

    // Pipe stdout → newline-delimited JSON-RPC lines into the client.
    final lineStream = process.stdout
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter());
    final stdoutSub = lineStream.listen(client.feedLine);
    process.stderr
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen((line) => addEvent(ErrorEvent(content: '[acp] $line')));

    // Forward structured events to the session stream.
    _acpEventsSub = client.events.listen(addEvent);

    try {
      await client.initialize();
      final sessionId = await client.sessionNew(
        cwd: agentDirHostPath,
        model: modelId,
        mcpConfigPath: mcpConfigPath,
      );
      await client.sessionPrompt(sessionId: sessionId, prompt: prompt);
      unawaited(_closeRunLog(exitCode: 0));
      addEvent(DebugEvent(content: '[acp] $cliName turn complete'));
    } on Object catch (e) {
      addEvent(ErrorEvent(content: '[acp] $cliName failed: $e'));
      unawaited(_closeRunLog(exitCode: 1, error: e));
    } finally {
      await stdoutSub.cancel();
      await _acpEventsSub?.cancel();
      _acpEventsSub = null;
      await client.close();
      _acpProcess?.kill();
      _acpProcess = null;
      addEvent(DoneEvent());
      _completeRun();
    }
  }

  /// Runs Control Center's built-in agent loop (the harness transport).
  ///
  /// No external process is spawned: a provider is built for the agent's
  /// model + credential, the built-in + MCP tools are assembled and filtered by
  /// mode, and [AgentLoop] events are translated into [AgentProcessEvent]s so
  /// the harness streams to the UI and run log exactly like the CLI/ACP
  /// transports.
  Future<void> _runHarness({
    required AgentCapabilities caps,
    required ScopedCredentials scoped,
    required String wsId,
  }) async {
    _harnessActive = true;
    for (final note in scoped.notes) {
      addEvent(DebugEvent(content: '[harness] $note'));
    }

    // 1. Resolve provider + model + credential. A modelId may carry a fallback
    //    chain: `primary/model|fallback/model|…`.
    final factory = deps.harnessProviderFactory;
    final modelSpecs = (modelId ?? '')
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final parsed = factory.parseModel(
      modelSpecs.isEmpty ? modelId : modelSpecs.first,
    );
    final providerId = parsed.providerId;
    final credential = await _resolveHarnessCredential(providerId);
    final hasSecret =
        credential?.secret != null && credential!.secret!.isNotEmpty;
    // A provider is runnable with a secret, or when its credential says no
    // auth is needed (a keyless custom endpoint, method `none`).
    final authSatisfied =
        hasSecret || credential?.method == HarnessAuthMethod.none;
    if (!authSatisfied) {
      final envHint =
          (EnvProviderCredentialStore.envKeys[providerId] ?? const <String>[])
              .join(' or ');
      addEvent(
        ErrorEvent(
          content:
              '[harness] No credential for provider "$providerId". Connect '
              'an account in Settings → Providers'
              "${envHint.isEmpty ? '' : ' or set $envHint'}.",
          source: 'harness',
        ),
      );
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    final LlmProviderPort provider;
    try {
      provider = await _buildHarnessProvider(
        factory: factory,
        primaryProviderId: providerId,
        primaryModel: parsed.model,
        primaryCredential: credential,
        extraSpecs: modelSpecs.length > 1 ? modelSpecs.sublist(1) : const [],
      );
    } on Object catch (e) {
      addEvent(ErrorEvent(content: '[harness] $e', source: 'harness'));
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    // 1b. Slash commands: /plan, /goal, /loop change how the run behaves;
    //     /<skill> injects that skill's instructions; anything else is plain
    //     text.
    //
    //     Parsed from `userText` (the user's message verbatim), NOT `prompt`:
    //     a channel dispatch layers `prompt` into `<context>…</context>\n\n…`,
    //     which has no leading slash, so parsing it made every built-in
    //     command silently inert on the path that matters most.
    final parsedCommand = parseSlashCommand(userText ?? prompt);
    var effectiveMode = mode;
    var effectivePrompt = prompt;
    // No turn ceiling anywhere: interactive and autonomous runs alike end
    // when the model stops, a budget bites, or a human stops them — the
    // doom-loop repetition guard is the bound on a spinning run, not an
    // arbitrary iteration count.
    int? commandMaxTurns;
    final commandDirectives = StringBuffer();
    if (parsedCommand.isCommand) {
      final applied = await _applySlashCommand(parsedCommand);
      effectiveMode = applied.mode ?? mode;
      // Strip the command itself from the prompt while KEEPING every context
      // layer: the layered prompt ends with the raw user text, so only that
      // tail is replaced. Splicing (rather than using the bare args) is what
      // keeps identity/memory/conversation context intact for `/plan do X`.
      effectivePrompt = _spliceUserText(applied.userTextOverride);
      commandMaxTurns = applied.maxTurns;
      if (applied.directive != null) {
        commandDirectives.writeln(applied.directive);
      }
      if (applied.notice != null) {
        addEvent(DebugEvent(content: '[harness] ${applied.notice}'));
      }
    }

    // The base system prompt (AGENTS.md + skills) — computed early so it can be
    // reused for subagents spawned via the `task` tool.
    final baseSystem = await _harnessSystemPrompt(wsId);

    // 3. Approval gate (write/exec tools; bash self-guards via the policy).
    //    The user-interaction tools ARE the confirmation — never wrap them in a
    //    second approval prompt. Subagents inherit this same callback.
    final port = deps.confirmationPort;
    final guard = deps.actionGuard;
    // The mode's capability profile — the single declaration the tool surface,
    // the completion contract, the guard preset, the sandbox, and the generated
    // prompt preamble all project from.
    final profile = profileFor(effectiveMode);
    final ToolApprovalCallback? approval = port == null
        ? null
        : (tool, args) async {
            if (_harnessInteractionTools.contains(tool.name)) {
              return const ToolGateDecision.allow();
            }
            // A mode's own output verb is never deniable. Without this,
            // orchestrate mode denied `propose_orchestration` (it declares
            // `vendorSyncWrite`, which the read-only preset denies) — the mode
            // was structurally unable to produce its only deliverable.
            if (profile.pinnedVerbs.contains(tool.name)) {
              return const ToolGateDecision.allow();
            }
            // Per-channel autonomy dial (PRD 16 §12), graduated and visible:
            //  * proposeOnly — gated tools are DENIED outright; the agent can
            //    only propose (its message explains why).
            //  * actWithApproval / unset — the fail-closed approval gate.
            //  * actFreely — pre-approved (the operator granted autonomy).
            String? autonomy;
            final resolveAutonomy = deps.autonomyResolver;
            final autonomyWorkspaceId = workspaceId;
            if (resolveAutonomy != null &&
                conversationId != null &&
                agentId != null &&
                autonomyWorkspaceId != null &&
                autonomyWorkspaceId.isNotEmpty) {
              autonomy = await resolveAutonomy(
                autonomyWorkspaceId,
                conversationId!,
                agentId!,
              );
            }
            if (autonomy == 'proposeOnly') {
              addEvent(
                DebugEvent(
                  content:
                      '[harness] "${tool.name}" denied: autonomy in this '
                      'channel is propose-only.',
                ),
              );
              return const ToolGateDecision.deny(
                reason: 'this channel\'s autonomy is set to propose-only',
                remediation:
                    'Propose the action in a message instead and let '
                    'the operator run it.',
              );
            }

            // Unified action guardrails (PRD 24 §3) — the effect net that
            // finally covers the BUILT-IN harness loop. Bridged MCP tools call
            // `McpTool.call()` directly (bypassing the MCP dispatcher's guard),
            // so gating here is load-bearing, not redundant. Resolve the policy
            // decision purely, then compose with the autonomy dial: a hard
            // `deny` rule always blocks (even under actFreely); actFreely
            // pre-approves anything else; otherwise a `prompt` decision surfaces
            // exactly ONE confirmation through the shared port.
            if (guard != null && tool.actionClasses.isNotEmpty) {
              final resolution = await guard.resolve(
                workspaceId: wsId,
                classes: tool.actionClasses,
                channelId: conversationId,
                agentId: agentId,
                mode: effectiveMode,
              );
              if (resolution.decision == ActionDecision.deny) {
                addEvent(
                  DebugEvent(
                    content:
                        '[harness] "${tool.name}" denied by action '
                        'policy: ${resolution.driving.reason}',
                  ),
                );
                // Hand the model the policy's own reason plus the sanctioned
                // alternative, so it can replan instead of narrating defeat.
                return ToolGateDecision.deny(
                  reason: resolution.driving.reason,
                  remediation: _remediationFor(profile),
                );
              }
              if (autonomy == 'actFreely' ||
                  resolution.decision == ActionDecision.allow) {
                return const ToolGateDecision.allow();
              }
              final approved = await port.requestApproval(
                ConfirmationRequest(
                  conversationId: conversationId ?? '',
                  title: 'Approve ${tool.name}',
                  detail:
                      '${resolution.driving.reason}'
                      '${_approvalArgsSummary(args)}',
                  kind: tool.approvalTier == ToolApprovalTier.exec
                      ? ConfirmationKind.command
                      : ConfirmationKind.fileWrite,
                ),
              );
              return approved
                  ? const ToolGateDecision.allow()
                  : const ToolGateDecision.deny(
                      reason: 'the operator declined this action',
                    );
            }

            // Tools without declared effect classes (or no guard wired): the
            // existing autonomy + generic approval net.
            if (autonomy == 'actFreely') {
              return const ToolGateDecision.allow();
            }
            final approved = await port.requestApproval(
              ConfirmationRequest(
                conversationId: conversationId ?? '',
                title: 'Approve ${tool.name}',
                detail:
                    'An agent wants to run the "${tool.name}" tool.'
                    '${_approvalArgsSummary(args)}',
                kind: tool.approvalTier == ToolApprovalTier.exec
                    ? ConfirmationKind.command
                    : ConfirmationKind.fileWrite,
              ),
            );
            return approved
                ? const ToolGateDecision.allow()
                : const ToolGateDecision.deny(
                    reason: 'the operator declined this action',
                  );
          };

    // The harness spawns no CLI process, so the built-in bash tool's base env
    // carries the per-run identity surface directly: agent git author/
    // committer identity + co-author trailer, with the requesting member's own
    // GitHub token winning over the broker env (member token > broker env,
    // same precedence as the CLI transports' merged env).
    final harnessToolEnv = <String, String>{
      ..._gitIdentityEnv,
      ...scoped.environment,
      if (_memberGitHubToken != null) ...{
        'GH_TOKEN': _memberGitHubToken!,
        'GITHUB_TOKEN': _memberGitHubToken!,
      },
    };

    // 2. Assemble tools: built-ins first (so they win on name collisions),
    //    then CC's MCP tools, filtered by conversation mode. The top-level run
    //    also gets the `task` tool so it can spawn subagents; each child gets
    //    one too until the `maxSubagentDepth` cap is reached, at which point the
    //    tool is simply absent from that run's registry.
    final registry = _buildHarnessRegistry(
      mode: effectiveMode,
      caps: caps,
      env: harnessToolEnv,
    );

    registry.register(
      TaskTool(
        _ClosureSubagentSpawner(
          (req) => _spawnSubagent(
            req,
            // The top-level run is depth 0; its children are level 1.
            depth: 1,
            // No subagent profile above the top-level run, so no read-only
            // parent ceiling to inherit — the conversation mode already
            // decided this run's surface.
            parentType: null,
            parentRunId: runLogId,
            baseCaps: caps,
            env: harnessToolEnv,
            parentProvider: provider,
            parentProviderId: providerId,
            baseSystemPrompt: baseSystem,
            approval: approval,
          ),
        ),
      ),
    );
    final surface = profile.toToolSurfaceSpec();
    final tools = registry.toolsFor(surface);

    // 4. Run the loop, translating events to AgentProcessEvents.
    final qualifiedModel =
        '$providerId/${parsed.model ?? provider.defaultModel}';
    final modelInfo = deps.modelResolver?.call(qualifiedModel);
    final costCalc = HarnessCostCalculator(
      (pid, m) => deps.modelResolver?.call('$pid/$m')?.cost,
    );
    // The mode's capability block is GENERATED from the materialized tool list,
    // so the prompt can never advertise a tool this run does not have (nor omit
    // the verb that delivers its output). It goes in the SYSTEM prompt, not the
    // user message: cache-stable, weighted as rules, and immune to the
    // `<context>`-wrapping that made the old `/plan` directive unreachable.
    final capabilityBlock = buildCapabilityPreamble(
      profile,
      materializedToolNames: [for (final t in tools) t.name],
    );
    final systemPrompt = [
      baseSystem,
      capabilityBlock,
      if (commandDirectives.isNotEmpty) commandDirectives.toString().trim(),
    ].where((part) => part.trim().isNotEmpty).join('\n\n');
    _recordRunComposition(
      toolNames: [for (final t in tools) t.name],
      mode: effectiveMode.name,
      model: qualifiedModel,
      adapter: 'cc-harness',
      systemPrompt: systemPrompt,
    );

    // Opt-in loop extensions from `.agents/harness.json` (stream rules, advisor,
    // shell hooks). Absent file → all off.
    final runConfig = await HarnessRunConfig.load([
      agentDirHostPath,
      agentConfigDir,
    ]);
    WatchdogAdvisor? advisor;
    if (runConfig.advisorEnabled) {
      // A cheap second model watches the run; feed it the project's standing
      // conventions (AGENTS.md/CLAUDE.md) and any WATCHDOG.md attention block.
      final watchdogContext = await loadWatchdogContext(
        agentDirHostPath,
        agentConfigDir: agentConfigDir,
      );
      advisor = WatchdogAdvisor(
        provider,
        model: runConfig.advisorModel,
        attention: watchdogContext.attention,
        projectContext: watchdogContext.projectContext,
        extraInstructions: runConfig.advisorInstructions,
      );
    }
    final hooks = runConfig.hasHooks
        ? ShellAgentLoopHooks(
            cwd: agentDirHostPath,
            sessionStartScript: runConfig.hookSessionStart,
            preToolScript: runConfig.hookPreTool,
            postToolScript: runConfig.hookPostTool,
          )
        : null;

    // The provider's own generation recipe. A frontier API and a local quant
    // cannot share one output ceiling, and models that publish a required
    // sampling recipe degrade — sometimes out of their own tool-call dialect —
    // when served at other values. Unset fields keep the historical behavior
    // exactly: the harness default ceiling, and no sampling fields on the wire.
    final generation =
        credential?.generation ?? const ProviderGenerationDefaults();
    // Priced spend of THIS run, accumulated from usage events. Autonomous
    // commands (/goal, /loop) are bounded by the in-session cost cap below —
    // enforced mid-run via externalBudgetExceeded, not just between
    // segments. (0-cost providers never reach the cap; their automatic
    // bounds are the doom-loop repetition guard, the advisor, and the
    // supervisor's give-up + the human's stop.) The goal supervisor threads
    // the goal's remaining budget as [costCapCents] so a segment can never
    // overshoot an explicit `/goal --budget`; cross-segment continuation is
    // the supervisor's job.
    final sessionCostCapCents = costCapCents ?? defaultRunCostCapCents;
    var runCostCents = 0;
    final config = AgentLoopConfig(
      systemPrompt: systemPrompt,
      model: parsed.model,
      maxTurns: commandMaxTurns,
      maxTokens: generation.maxTokens ?? defaultHarnessMaxTokens,
      temperature: generation.temperature,
      topP: generation.topP,
      topK: generation.topK,
      effort: _resolveHarnessEffort(modelInfo),
      cacheKey: conversationId,
      approvalCallback: approval,
      // Fail closed: if no approver is wired, deny write/exec rather than run
      // ungated. The server always supplies a (remote-aware) ConfirmationPort,
      // so this only bites a genuinely approver-less run.
      autoApprove: false,
      pauseGate: _pauseGate,
      // The deliverable this run owes, projected from the mode profile. Plan and
      // orchestrate mode each declare exactly one output verb; chat and review
      // owe nothing and get null — byte-identical to the historical behavior,
      // which is what keeps recorded sessions replayable.
      contract: profile.toCompletionContract(),
      // No wall-clock ceiling either: autonomous runs (/goal, /loop) are
      // bounded by cost (see externalBudgetExceeded) and the supervisor's
      // goal budget; interactive runs by the human. The doom-loop repetition
      // guard inside the loop catches a spinning model long before any
      // iteration count would.
      budget: const HarnessBudget(),
      // Autonomous commands get the in-session cost guard: the loop stops
      // mid-run (not just between segments) once the priced spend crosses
      // the cap. Interactive turns stay unbounded, as before.
      externalBudgetExceeded: switch (parsedCommand.command) {
        'goal' || 'loop' => () => runCostCents >= sessionCostCapCents,
        _ => null,
      },
      // Soft steer at 80% of the cap: the loop asks the model to wrap up and
      // leave a clean handoff BEFORE the hard check kills the run mid-task.
      externalBudgetPressure: switch (parsedCommand.command) {
        'goal' ||
        'loop' => () => runCostCents >= (sessionCostCapCents * 0.8).round(),
        _ => null,
      },
      streamRules: runConfig.streamRules,
      advisor: advisor,
      advisorEveryTurns: runConfig.advisorEveryTurns,
      hooks: hooks,
      // Mid-run steering: a client can push a message via [steer] while this run
      // is active; the loop drains it at the next turn boundary.
      steering: _steering,
      // Context management: compact when history nears the model window (falls
      // back to a conservative 128k when the catalog lacks the model). The
      // summarizer reuses the run's provider, with a deterministic fallback.
      contextWindow: modelInfo?.limits.context ?? 128000,
      compactor: DefaultHarnessCompactor(
        summarizer: LlmHarnessSummarizer(provider),
      ),
    );
    final context = HarnessToolContext(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );

    var exitCode = 0;
    // Set when the loop ends owing a deliverable, so the run row can record it.
    CompletionContract? contractUnmet;
    // The row was written `pending` at dispatch; this is the point where it is
    // genuinely executing, so `pending` can mean "queued" everywhere else.
    _markRunStarted();

    // One uncapped segment: the loop ends when the model stops on its own,
    // the in-session cost cap bites (externalBudgetExceeded), the human
    // stops it, or an error does. Autonomous objectives (/goal, /loop) are
    // re-dispatched across segments and restarts by the goal supervisor —
    // no in-session chaining anymore.
    try {
      await for (final event in deps.agentLoop.run(
        history: <HarnessMessage>[],
        userMessage: effectivePrompt,
        tools: tools,
        provider: provider,
        context: context,
        config: config,
        cancel: _cancelSource.token,
      )) {
        switch (event) {
          case LoopTextDelta(:final text):
            addEvent(TextEvent(content: text));
          case LoopThinkingDelta(:final thinking):
            addEvent(ThinkingEvent(content: thinking));
          case LoopToolCallStart(
            :final toolName,
            :final toolUseId,
            :final args,
          ):
            addEvent(
              ToolCallEvent(
                toolName: toolName,
                toolCallId: toolUseId,
                inputs: args,
              ),
            );
          case LoopToolCallResult(
            :final toolName,
            :final toolUseId,
            :final result,
          ):
            addEvent(
              ToolResultEvent(
                toolCallId: toolUseId,
                outputs: result.content,
                toolName: toolName,
                isError: result.isError,
              ),
            );
          case LoopUsage(:final usage):
            // Price the model that actually served (may differ under fallback).
            final servedProvider = provider is FallbackProvider
                ? provider.lastServedProviderId
                : providerId;
            final servedModel = provider is FallbackProvider
                ? provider.lastServedModel
                : (parsed.model ?? provider.defaultModel);
            final rc = costCalc.cost(
              providerId: servedProvider,
              modelId: servedModel,
              usage: usage,
            );
            runCostCents += rc.estimatedCostCents;
            addEvent(
              UsageEvent(
                usage: RunUsage(
                  inputTokens: usage.inputTokens,
                  outputTokens: usage.outputTokens,
                  thoughtTokens: usage.thoughtTokens,
                  cachedReadTokens: usage.cacheReadTokens,
                  cachedWriteTokens: usage.cacheWriteTokens,
                  estimatedCostCents: rc.estimatedCostCents,
                ),
              ),
            );
          case LoopNotice(:final message):
            addEvent(DebugEvent(content: '[harness] $message'));
          case LoopAdvisorNote(:final note, :final severity):
            addEvent(
              DebugEvent(
                content: '[harness] advisor (${severity.name}): $note',
              ),
            );
          case LoopCompaction(
            :final summarized,
            :final messagesFolded,
            :final tokensBefore,
            :final tokensAfter,
          ):
            addEvent(
              DebugEvent(
                content:
                    '[harness] context '
                    '${summarized ? 'compacted' : 'pruned'}: '
                    '$messagesFolded messages folded, '
                    '$tokensBefore→$tokensAfter tokens.',
              ),
            );
          case LoopError(:final message, :final code):
            exitCode = 1;
            addEvent(
              ErrorEvent(content: message, code: code, source: 'harness'),
            );
          case LoopDone(:final reason, :final unmetContractId):
            if (reason == LoopDoneReason.budgetExhausted) {
              addEvent(
                DebugEvent(content: '[harness] stopped: budget exhausted.'),
              );
            } else if (reason == LoopDoneReason.providerOutputLost) {
              // The provider generated the answer and then dropped it. That is
              // an infrastructure fault, not a model or user one, so the run is
              // marked failed rather than left looking merely unproductive.
              exitCode = 1;
              addEvent(
                DebugEvent(
                  content:
                      '[harness] stopped: the provider discarded this '
                      "turn's output (truncated mid-tool-call).",
                ),
              );
            }
            // A run that owed a deliverable and produced none must never end
            // silently. This is the exact failure the user had to notice by
            // hand ("you didn't write the plan?"), so it becomes a visible
            // message plus a marked run row.
            final unmet = unmetContractId == null
                ? null
                : profile.toCompletionContract();
            if (unmet != null) {
              contractUnmet = unmet;
              addEvent(TextEvent(content: '\n\n_${unmet.unmetSummary}_'));
              addEvent(
                DebugEvent(
                  content:
                      '[harness] completion contract "$unmetContractId" '
                      'unmet after ${reason.name}.',
                ),
              );
            }
          case LoopTurnComplete():
            break;
        }
      }
      // `status` stays `completed` — the process did exit cleanly. The truth
      // about the missing deliverable rides on liveness/errorFamily/summary, so
      // pipeline and ticket state machines are untouched.
      final unmetAtClose = contractUnmet;
      if (unmetAtClose != null) {
        await _markContractUnmet(unmetAtClose);
      }
      unawaited(_closeRunLog(exitCode: exitCode));
    } on Object catch (e) {
      addEvent(ErrorEvent(content: '[harness] $e', source: 'harness'));
      unawaited(_closeRunLog(exitCode: 1, error: e));
    } finally {
      _harnessActive = false;
      _pauseGate.resume();
      addEvent(DoneEvent());
      _completeRun();
    }
  }

  /// Builds the base harness tool registry (built-in filesystem/command tools
  /// first, then bridged CC MCP tools) for a given [mode]/[caps]/[env]. The
  /// `task` tool is NOT added here — the top-level run adds it explicitly, and
  /// subagents deliberately omit it so nesting is capped at one level.
  HarnessToolRegistry _buildHarnessRegistry({
    required Mode mode,
    required AgentCapabilities caps,
    required Map<String, String> env,
  }) {
    final commandRunner = SandboxedHarnessCommandRunner(
      mode: mode,
      capabilities: caps,
      sandboxManager: deps.sandboxManager,
      confirmationPort: deps.confirmationPort,
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      baseEnv: env,
      protectedPaths: _protectedPaths,
    );
    // Shared hashline edit service: `read` snapshots content into it and
    // `apply_patch` recovers against those snapshots (drift-tolerant edits).
    final fileEditService = FileEditService();
    final registry = HarnessToolRegistry()
      ..registerAll([
        ReadTool(
          onRead: fileEditService.recordSnapshot,
          hashOf: fileEditService.computeHashFor,
          // fff-backed: a read of a missing path answers with the closest
          // fuzzy matches instead of a bare not-found.
          fileSearch: deps.fileSearch,
        ),
        WriteTool(),
        EditTool(),
        ApplyPatchTool(fileEditService),
        SearchTool(),
        FindTool(),
        FileSearchTool(fileSearch: deps.fileSearch),
        // `todo_write` comes from the bridged MCP `TodoWriteTool` (persisted,
        // per-conversation); the bridge injects `conversation_id`.
        // Web tools honor the agent's network capability and block SSRF targets.
        WebFetchTool(allowNetwork: caps.canAccessNetwork),
        WebSearchTool(allowNetwork: caps.canAccessNetwork),
        CheckpointTool(),
        RewindTool(),
        BashTool(commandRunner),
      ]);
    final mcpRegistry = deps.mcpRegistry;
    if (mcpRegistry != null) {
      for (final toolName in mcpRegistry.toolNames) {
        final mcpTool = mcpRegistry.lookup(toolName);
        if (mcpTool != null) {
          registry.register(McpToolBridge(mcpTool));
        }
      }
    }
    return registry;
  }

  /// Runs an ephemeral subagent to completion and returns its result. Blocks
  /// Writes the running cost total onto a subagent's row mid-flight.
  ///
  /// Without this a live subagent's activity view reads zero tokens, zero cost
  /// and a zero context gauge until the run ends, because the child's spend is
  /// otherwise only persisted at finalization. Best-effort: a lost mid-run
  /// update is corrected by the final write.
  Future<void> _updateSubagentCost({
    required String runId,
    required RunCost cost,
    required AgentRunLogRepository? repo,
  }) async {
    // The child run lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to update.
    final ws = workspaceId;
    if (repo == null || ws == null || ws.isEmpty) {
      return;
    }
    try {
      final row = await repo.getById(ws, runId);
      if (row != null) {
        await repo.upsert(row.copyWith(cost: cost));
      }
    } catch (_) {
      // Progress telemetry, not the run's result — never fail a run over it.
    }
  }

  /// the parent's tool call. Writes a child [AgentRunLog] linked to
  /// [parentRunId] (role `sub`) so the conversation run tree can render it live,
  /// and rolls the child's cost up into the parent's `childCostCents`.
  Future<SubagentResult> _spawnSubagent(
    SubagentSpawnRequest req, {
    required int depth,
    required SubagentType? parentType,
    required String? parentRunId,
    required AgentCapabilities baseCaps,
    required Map<String, String> env,
    required LlmProviderPort parentProvider,
    required String parentProviderId,
    required String baseSystemPrompt,
    required ToolApprovalCallback? approval,
  }) async {
    // Hard depth stop. The registry omission further down is the real
    // enforcement (the model never sees a `task` tool it may not use), so
    // arriving here means a wiring bug — refuse loudly instead of recursing.
    if (depth > maxSubagentDepth) {
      return SubagentResult(
        text:
            'Refused: subagent nesting is capped at $maxSubagentDepth '
            'levels, and this request would be level $depth.',
        isError: true,
      );
    }
    // Privilege ceiling: a read-only parent may not reach write/exec tools
    // through a more privileged child. `task` is read-tier, so it survives the
    // read-only clamp and this is the only thing standing between an `explore`
    // subagent and a worktree-mutating grandchild.
    if (parentType != null &&
        !subagentProfileFor(parentType).admitsChildType(req.type)) {
      return SubagentResult(
        text:
            'Refused: a "${parentType.name}" subagent is read-only and may '
            'not spawn a "${req.type.name}" subagent, which would grant it '
            'write/exec tools its own surface denies. Use explore or plan.',
        isError: true,
      );
    }
    final subProfile = subagentProfileFor(req.type);
    final childRunId =
        '${runLogId ?? 'run'}-sub-${_subagentSeq++}-${const Uuid().v4()}';

    // Child tools = base registry, filtered by the profile's own tool surface
    // and clamped to its approval tiers. The `task` tool is added below, but
    // only while this child is still inside the depth cap.
    //
    // The registry is built for the child's effective mode purely so the
    // sandboxed command runner and MCP bridging match its posture; the surface
    // that actually filters is the subagent profile's.
    final childRegistry = _buildHarnessRegistry(
      mode: subProfile.surface.maxTier == ToolApprovalTier.exec
          ? Mode.chat
          : Mode.plan,
      caps: baseCaps,
      env: env,
    );

    // Resolve the child provider — reuse the parent unless a model override was
    // requested (falls back to the parent on any resolution failure).
    var childProvider = parentProvider;
    var childProviderId = parentProviderId;
    String? childModel;
    final override = req.modelOverride;
    if (override != null && override.isNotEmpty) {
      try {
        final factory = deps.harnessProviderFactory;
        final parsed = factory.parseModel(override);
        final cred = await _resolveHarnessCredential(parsed.providerId);
        childProvider = await _buildHarnessProvider(
          factory: factory,
          primaryProviderId: parsed.providerId,
          primaryModel: parsed.model,
          primaryCredential: cred,
          extraSpecs: const [],
        );
        childProviderId = parsed.providerId;
        childModel = parsed.model;
      } on Object catch (e) {
        addEvent(
          DebugEvent(
            content:
                '[harness] subagent "${req.label}" model override failed '
                '($e); using parent model.',
          ),
        );
        childProvider = parentProvider;
        childProviderId = parentProviderId;
        childModel = null;
      }
    }
    // Resolved against whichever provider the child actually ended up on — the
    // override may have failed and fallen back to the parent.
    final childCredential = await _resolveHarnessCredential(childProviderId);

    // Depth enforcement, structural: this child gets a `task` tool only while
    // it is not yet the last permitted level, so a grandchild at the cap is
    // built with no way to nest at all. Registered here rather than with the
    // rest of the registry because the nested spawner has to hand its own
    // children the provider THIS child actually resolved onto (a model override
    // may have moved it off the parent's), and `baseSystemPrompt` is passed
    // through unchanged so profile addenda never stack down the chain.
    final canSpawn = depth < maxSubagentDepth;
    if (canSpawn) {
      childRegistry.register(
        TaskTool(
          _ClosureSubagentSpawner(
            (r) => _spawnSubagent(
              r,
              depth: depth + 1,
              parentType: subProfile.type,
              parentRunId: childRunId,
              baseCaps: baseCaps,
              env: env,
              parentProvider: childProvider,
              parentProviderId: childProviderId,
              baseSystemPrompt: baseSystemPrompt,
              approval: approval,
            ),
          ),
        ),
      );
    }
    final childTools = subProfile.filterTools(
      childRegistry.toolsFor(subProfile.surface),
    );

    final childAgentId = agentId ?? 'subagent';
    final startedAt = DateTime.now();
    final repo = deps.runLogRepo;

    // Start recording the child's own activity BEFORE the run row is written, so
    // a client that opens the activity tab the instant the row appears finds a
    // live stream rather than an empty replay.
    final ws = workspaceId;
    final recording = (ws != null && ws.isNotEmpty)
        ? deps.runTranscriptRecorder?.begin(
            runId: childRunId,
            workspaceId: ws,
            startedAt: startedAt,
          )
        : null;

    // Open the child run log (running) so the run tree shows it live.
    if (repo != null) {
      try {
        await repo.upsert(
          AgentRunLog(
            id: childRunId,
            agentId: childAgentId,
            workspaceId: workspaceId,
            conversationId: conversationId,
            startedAt: startedAt,
            status: RunStatus.running,
            summary: req.label,
            adapter: 'harness',
            modelId: childModel ?? childProviderId,
            role: AgentRunRole.sub,
            parentRunId: parentRunId,
            spawnToolCallId: req.spawnToolCallId,
          ),
        );
      } catch (e) {
        // Best-effort run-log tracking — the subagent still runs, but a lost
        // start row means the UI won't show it, so surface why.
        CcInfraLog.warning(
          'Failed to write subagent start run-log for "${req.label}": $e',
        );
      }
    }

    addEvent(
      DebugEvent(
        content:
            '[harness] subagent "${req.label}" (${req.type.name}) started.',
      ),
    );

    final costCalc = HarnessCostCalculator(
      (pid, m) => deps.modelResolver?.call('$pid/$m')?.cost,
    );
    final childModelInfo = childModel == null
        ? null
        : deps.modelResolver?.call('$childProviderId/$childModel');
    // A subagent runs on the same endpoint, so it inherits that endpoint's
    // recipe too — otherwise a child would silently ignore a ceiling the parent
    // respects.
    final childGeneration =
        childCredential?.generation ?? const ProviderGenerationDefaults();
    final config = AgentLoopConfig(
      systemPrompt: subProfile.buildSystemPrompt(
        baseSystemPrompt,
        canSpawn: canSpawn,
      ),
      model: childModel,
      maxTurns: subProfile.maxTurns,
      maxTokens: childGeneration.maxTokens ?? defaultHarnessMaxTokens,
      temperature: childGeneration.temperature,
      topP: childGeneration.topP,
      topK: childGeneration.topK,
      effort: _resolveHarnessEffort(childModelInfo),
      approvalCallback: approval,
      autoApprove: false,
      // A child is already running inside the parent's fan-out, so its own
      // waves stay narrower than the top level's: nesting multiplies, and the
      // worst case has to stay something a provider (or a local endpoint) can
      // actually serve. Top-level 4 × this 2 bounds grandchildren at 8 in
      // flight rather than 16.
      maxParallelToolCalls: 2,
      pauseGate: _pauseGate,
      // Subagents get the same context management as the parent so a long child
      // run compacts instead of blowing the window and losing its work.
      contextWindow: childModelInfo?.limits.context ?? 128000,
      compactor: DefaultHarnessCompactor(
        summarizer: LlmHarnessSummarizer(childProvider),
      ),
    );
    final childContext = HarnessToolContext(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
      agentId: childAgentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );

    final buf = StringBuffer();
    var lastText = '';
    var inputTokens = 0;
    var outputTokens = 0;
    var thoughtTokens = 0;
    var cachedRead = 0;
    var cachedWrite = 0;
    var costCents = 0;
    var isError = false;

    /// The child's accumulated spend, stamped with how long it has been running.
    ///
    /// `durationMs` is measured here rather than left null: a subagent has no
    /// process of its own for the liveness reaper to time, so this is the only
    /// place its duration is known.
    RunCost costSoFar({DateTime? completedAt}) => RunCost(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      thoughtTokens: thoughtTokens,
      cachedReadTokens: cachedRead,
      cachedWriteTokens: cachedWrite,
      estimatedCostCents: costCents,
      durationMs: (completedAt ?? DateTime.now())
          .difference(startedAt)
          .inMilliseconds,
    );

    try {
      await for (final event in deps.agentLoop.run(
        history: <HarnessMessage>[],
        userMessage: req.description,
        tools: childTools,
        provider: childProvider,
        context: childContext,
        config: config,
        cancel: _cancelSource.token,
      )) {
        // Every event the child emits is folded into ITS OWN transcript
        // (`recording`), keyed by the child run id — that is what makes a
        // subagent's activity openable. The parent's stream keeps getting the
        // same coarse DebugEvent breadcrumbs it always did: they are the NDJSON
        // trail and are dropped from the parent's transcript anyway.
        switch (event) {
          case LoopTextDelta(:final text):
            buf.write(text);
            recording?.add(TextEvent(content: text));
          case LoopThinkingDelta(:final thinking):
            recording?.add(ThinkingEvent(content: thinking));
          case LoopTurnComplete(:final message):
            final text = message.textContent;
            if (text.trim().isNotEmpty) {
              lastText = text;
            }
          case LoopUsage(:final usage):
            final rc = costCalc.cost(
              providerId: childProviderId,
              modelId: childModel ?? childProvider.defaultModel,
              usage: usage,
            );
            inputTokens += usage.inputTokens;
            outputTokens += usage.outputTokens;
            thoughtTokens += usage.thoughtTokens;
            cachedRead += usage.cacheReadTokens;
            cachedWrite += usage.cacheWriteTokens;
            costCents += rc.estimatedCostCents;
            // Push the running total onto the child row so a live activity view
            // shows real tokens/cost/context instead of zeros. Usage arrives
            // once per turn (not per token), so this is a handful of writes.
            unawaited(
              _updateSubagentCost(
                runId: childRunId,
                cost: costSoFar(),
                repo: repo,
              ),
            );
          case LoopToolCallStart(
            :final toolName,
            :final toolUseId,
            :final args,
          ):
            recording?.add(
              ToolCallEvent(
                toolName: toolName,
                toolCallId: toolUseId,
                inputs: args,
              ),
            );
            addEvent(
              DebugEvent(
                content: '[harness] subagent "${req.label}": $toolName',
              ),
            );
          case LoopToolCallResult(
            :final toolName,
            :final toolUseId,
            :final result,
          ):
            recording?.add(
              ToolResultEvent(
                toolCallId: toolUseId,
                outputs: result.content,
                toolName: toolName,
                isError: result.isError,
              ),
            );
          case LoopError(:final message):
            isError = true;
            recording?.add(ErrorEvent(content: message, source: 'harness'));
            addEvent(
              DebugEvent(
                content: '[harness] subagent "${req.label}" error: $message',
              ),
            );
          default:
            break;
        }
      }
    } on Object catch (e) {
      isError = true;
      recording?.add(ErrorEvent(content: '[harness] $e', source: 'harness'));
      addEvent(
        DebugEvent(content: '[harness] subagent "${req.label}" crashed: $e'),
      );
    }

    // Close the recording BEFORE the run row flips terminal, so a client never
    // sees `completed` next to a half-written transcript. Runs on the cancel and
    // throw paths too — an interrupted subagent must still leave a readable
    // timeline, with its in-flight tool marked interrupted.
    await recording?.finish(
      isError ? TurnOutcome.failed : TurnOutcome.completed,
    );

    final finalText = lastText.trim().isNotEmpty
        ? lastText.trim()
        : buf.toString().trim();
    final completedAt = DateTime.now();
    final cost = costSoFar(completedAt: completedAt);

    // Finalize the child run log. Both writes live in this session's workspace
    // — a subagent never crosses the isolation boundary — and a workspace-less
    // session has no run-log row to finalize.
    final runLogWorkspaceId = workspaceId;
    if (repo != null &&
        runLogWorkspaceId != null &&
        runLogWorkspaceId.isNotEmpty) {
      try {
        final existing = await repo.getById(runLogWorkspaceId, childRunId);
        final base =
            existing ??
            AgentRunLog(
              id: childRunId,
              agentId: childAgentId,
              workspaceId: workspaceId,
              conversationId: conversationId,
              startedAt: startedAt,
              status: RunStatus.running,
              role: AgentRunRole.sub,
              parentRunId: parentRunId,
              spawnToolCallId: req.spawnToolCallId,
            );
        await repo.upsert(
          base.copyWith(
            status: isError ? RunStatus.error : RunStatus.completed,
            completedAt: completedAt,
            summary: finalText.isEmpty ? req.label : _clip(finalText, 2000),
            cost: cost,
          ),
        );
      } catch (e) {
        // Best-effort: the subagent already finished; a lost completion row
        // leaves the run appearing "running" in the UI, so log the cause.
        CcInfraLog.warning(
          'Failed to write subagent completion run-log for "${req.label}": $e',
        );
      }
    }

    // Roll the child's cost up into the parent run.
    if (repo != null &&
        runLogWorkspaceId != null &&
        runLogWorkspaceId.isNotEmpty &&
        parentRunId != null &&
        costCents > 0) {
      try {
        final parent = await repo.getById(runLogWorkspaceId, parentRunId);
        if (parent != null) {
          await repo.upsert(
            parent.copyWith(childCostCents: parent.childCostCents + costCents),
          );
        }
      } catch (_) {}
    }

    addEvent(
      DebugEvent(
        content:
            '[harness] subagent "${req.label}" '
            '${isError ? 'failed' : 'done'}.',
      ),
    );

    return SubagentResult(
      text: finalText.isEmpty
          ? (isError
                ? 'Subagent failed with no output.'
                : 'Subagent finished with no output.')
          : finalText,
      isError: isError,
      childRunId: childRunId,
    );
  }

  /// Applies a parsed slash command, returning the resolved run parameters.
  /// Replaces the user-text tail of the layered [prompt] with [replacement],
  /// preserving every context layer above it.
  ///
  /// A channel dispatch hands us `<context>…</context>\n\n$userText`. When a
  /// slash command is stripped we must put the remaining text back *in place*
  /// — using the bare args as the whole prompt would silently discard the
  /// agent's identity, memory, and conversation context. Falls back to the
  /// untouched prompt whenever the tail cannot be located (e.g. a caller that
  /// did no layering, where `userText == prompt`).
  String _spliceUserText(String? replacement) {
    if (replacement == null) {
      return prompt;
    }
    final raw = userText;
    if (raw == null || raw.isEmpty) {
      return replacement;
    }
    if (!prompt.endsWith(raw)) {
      // No layering (or a mismatch): the prompt IS the user text.
      return prompt == raw ? replacement : prompt;
    }
    return prompt.substring(0, prompt.length - raw.length) + replacement;
  }

  /// Built-in commands (`plan`/`goal`/`loop`) set a mode/directive; any other
  /// name is looked up as a skill; an unrecognized name falls through to plain
  /// text (the original prompt, no directive).
  ///
  /// No command sets a turn ceiling anymore: autonomous commands (/goal,
  /// /loop) are bounded by their cost budget and the doom-loop repetition
  /// guard, interactive ones by the human watching them.
  Future<
    ({
      Mode? mode,
      String? userTextOverride,
      int? maxTurns,
      String? directive,
      String? notice,
    })
  >
  _applySlashCommand(ParsedSlashCommand cmd) async {
    final name = cmd.command!;
    // Empty args (a bare `/plan`) leaves the user text as-is; the directive
    // already carries the intent.
    final String? body = cmd.args.isEmpty ? null : cmd.args;
    switch (name) {
      case 'plan':
        return (
          mode: Mode.plan,
          userTextOverride: body,
          maxTurns: null,
          // No directive: setting the mode is enough. The capability preamble
          // is generated from plan mode's profile + materialized tool list, and
          // the mode prompt block carries the authoring guidance. A hand-written
          // directive here would be a second, drift-prone copy — the previous
          // one was the ONLY place `submit_plan` was ever named, and it was
          // unreachable because the prompt is `<context>`-wrapped before slash
          // parsing.
          directive: null,
          notice: 'plan mode',
        );
      case 'goal':
        // Record the invocation as the conversation's working goal, so the
        // General pane surfaces it as an accordion the todos nest beneath.
        // Best-effort: a persistence failure must not block the run.
        final ws = workspaceId;
        final conv = conversationId;
        final goalText = (body ?? '').trim();
        if (deps.todoRepo != null &&
            ws != null &&
            ws.isNotEmpty &&
            conv != null &&
            conv.isNotEmpty &&
            goalText.isNotEmpty) {
          try {
            await deps.todoRepo!.setGoal(ws, conv, goalText);
          } on Object catch (e) {
            CcInfraLog.warning('Failed to set conversation goal: $e');
          }
        }
        return (
          mode: null,
          userTextOverride: body,
          maxTurns: null,
          directive:
              'The user invoked /goal. Treat the request as a goal to '
              'accomplish end-to-end: keep working across tool calls until it '
              'is achieved, then report what you did. Do not stop after a '
              'single step. The goal is DURABLE: the supervisor keeps the '
              'objective alive across segments and server restarts until you '
              'declare completion with the complete_goal MCP tool, passing a '
              'summary of what was achieved. There is no turn limit: the run '
              'is bounded by its cost budget, and a repetition guard steers '
              'you if you start looping, so spend turns on real progress. '
              'Checkpoint relentlessly (commit work, write notes and memory, '
              'update tickets) because every segment starts from durable '
              'state. Decompose large goals into tickets or plan nodes '
              'instead of one monolithic run.',
          notice: 'goal mode',
        );
      case 'loop':
        return (
          mode: null,
          userTextOverride: body,
          maxTurns: null,
          directive:
              'The user invoked /loop. Work the task iteratively: after '
              'each pass, re-evaluate and continue refining until it is fully '
              'complete. Do not stop early. There is no turn limit — the run '
              'is bounded by its cost budget, and a repetition guard steers '
              'you if you start cycling without progress. When it is fully '
              'complete, declare completion with the complete_goal MCP tool, '
              'passing a summary of what was achieved.',
          notice: 'loop mode',
        );
      default:
        final skill = await _loadSkillBody(name);
        if (skill != null) {
          return (
            mode: null,
            userTextOverride: body ?? 'Apply the "$name" skill.',
            maxTurns: null,
            directive:
                'The user invoked the "$name" skill. Follow these '
                'instructions:\n\n$skill',
            notice: 'skill: $name',
          );
        }
        return (
          mode: null,
          userTextOverride: null,
          maxTurns: null,
          directive: null,
          notice: null,
        );
    }
  }

  /// Reads a skill's `SKILL.md` body (frontmatter stripped) by name, or null
  /// when no such skill exists.
  Future<String?> _loadSkillBody(String name) async {
    try {
      final skills = await const HarnessSkillScanner().scan([
        agentConfigDir,
        agentDirHostPath,
      ]);
      for (final s in skills) {
        if (s.name == name) {
          return _stripFrontmatter(await File(s.path).readAsString());
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('DispatchSession: skill load failed: $e');
    }
    return null;
  }

  static String _stripFrontmatter(String md) {
    final t = md.trimLeft();
    if (t.startsWith('---')) {
      final end = t.indexOf('\n---', 3);
      if (end != -1) {
        final nl = t.indexOf('\n', end + 1);
        return nl == -1 ? '' : t.substring(nl + 1).trim();
      }
    }
    return md.trim();
  }

  /// Resolves the reasoning effort for a harness run: the agent's configured
  /// [effortLevel] (default medium) clamped to what the model accepts. Returns
  /// null only when the model is known to expose no reasoning; when the catalog
  /// is unavailable ([info] null) it keeps thinking on with the requested level.
  ReasoningEffort? _resolveHarnessEffort(ModelInfo? info) {
    final requested =
        ReasoningEffort.fromId(effortLevel) ?? ReasoningEffort.medium;
    if (info == null) {
      return requested;
    }
    final thinking = info.thinking;
    if (thinking == null) {
      return null;
    }
    return thinking.resolve(requested);
  }

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
    final primary = factory.create(
      providerId: primaryProviderId,
      model: primaryModel,
      credential: primaryCredential,
      tokenResolver: _tokenResolverFor(primaryCredential),
    );
    final entries = <FallbackEntry>[
      FallbackEntry(
        providerId: primaryProviderId,
        model: primaryModel ?? primary.defaultModel,
        build: () => primary,
      ),
    ];

    // Multi-key rotation: other stored credentials for the same provider.
    final store = deps.harnessCredentialStore;
    if (store != null) {
      try {
        for (final cred in await store.credentialsFor(primaryProviderId)) {
          if (_sameCredential(cred, primaryCredential)) {
            continue;
          }
          // One resolver per credential, bound outside the lazy build so the
          // entry cannot end up with a holder that starts from a spent token.
          final resolver = _tokenResolverFor(cred);
          entries.add(
            FallbackEntry(
              providerId: primaryProviderId,
              model: primaryModel ?? primary.defaultModel,
              build: () => factory.create(
                providerId: primaryProviderId,
                model: primaryModel,
                credential: cred,
                tokenResolver: resolver,
              ),
            ),
          );
        }
      } on Object catch (_) {
        // Rotation is best-effort; the primary still works.
      }
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
      onFallback: (from, to, reason) => addEvent(
        DebugEvent(
          content: '[harness] provider fallback $from → $to ($reason)',
        ),
      ),
    );
  }

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
          accountLabel: 'adapter:$key',
        );
      }
      final fromCaller = callerEnv[key];
      if (fromCaller != null && fromCaller.isNotEmpty) {
        return ProviderCredential(
          providerId: providerId,
          method: HarnessAuthMethod.apiKey,
          apiKey: fromCaller,
          accountLabel: 'caller:$key',
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
  /// persona, workspace context, and task are carried in [prompt] (assembled by
  /// the dispatch pipeline) and delivered as the user message; this is the
  /// stable operating brief that belongs in the system prompt.
  Future<String> _harnessSystemPrompt(String wsId) async {
    final buffer = StringBuffer()
      ..write(
        'You are a capable coding agent running inside Control Center. '
        'Use the available tools to read, search, edit, and run code to '
        'accomplish the task. Prefer the MCP tools (memory, messaging, '
        'tickets, agents, PRs) for orchestration and the built-in tools '
        '(read, write, edit, bash, search, find, search_files) for the '
        'filesystem. Work in the current directory. Be concise and report '
        'what you did.',
      );
    if (wsId.isNotEmpty) {
      buffer.write(' Workspace: $wsId.');
    }

    // Credit the requesting human on machine commits: the commit is authored
    // by the agent (per-run GIT_AUTHOR_* env), and the trailer records who
    // asked for the work.
    final trailer = _coAuthorTrailer;
    if (trailer != null) {
      buffer.write(
        '\n\nWhen you create git commits, append this trailer line to the '
        'commit message: $trailer',
      );
    }

    // Repo operating instructions (AGENTS.md, root + nested).
    try {
      final agentsMd = await const AgentsMdContextLoader().load(
        agentDirHostPath,
      );
      if (agentsMd.isNotEmpty) {
        buffer
          ..write('\n\n# Repository instructions (AGENTS.md)\n\n')
          ..write(agentsMd);
      }
    } on Object catch (e) {
      CcInfraLog.warning('DispatchSession: AGENTS.md load failed: $e');
    }

    // Skills: autoload frontmatter; the agent reads the SKILL.md body on demand.
    try {
      final skills = await const HarnessSkillScanner().scan([
        agentConfigDir,
        agentDirHostPath,
      ]);
      if (skills.isNotEmpty) {
        buffer.write(
          '\n\n# Available skills\n\nLoad a skill by reading its SKILL.md '
          'with the read tool.\n',
        );
        for (final skill in skills) {
          final desc = skill.description.isEmpty
              ? ''
              : ' — ${skill.description}';
          buffer.write('\n- ${skill.name}$desc (${skill.path})');
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('DispatchSession: skill scan failed: $e');
    }

    return buffer.toString();
  }

  /// Builds the merged environment for a dispatch. Precedence (later wins):
  /// git identity → caller → broker → member GitHub token → backend default →
  /// per-adapter override → capability.
  ///
  /// The per-run git author/committer identity sits FIRST so an explicit
  /// caller-provided identity wins (and [_prepareRunIdentity] already dropped
  /// any key the caller set). The requesting member's own GitHub token sits
  /// right after the broker env: member token > broker env. The broker's
  /// output does not distinguish a per-run scoped mint from its raw-PAT
  /// fallback here, so the member's own credential deliberately wins in both
  /// cases — a member-requested run must act as that member on GitHub, never
  /// as the owner.
  Map<String, String> _mergedEnv({
    required AgentCapabilities caps,
    required Map<String, String> scopedEnv,
    required Map<String, String> backendEnv,
  }) => <String, String>{
    ..._gitIdentityEnv,
    ...callerEnv,
    ...scopedEnv,
    if (_memberGitHubToken != null) ...{
      'GH_TOKEN': _memberGitHubToken!,
      'GITHUB_TOKEN': _memberGitHubToken!,
    },
    ...backendEnv,
    ...adapterEnvOverride,
    ...capabilityEnv(caps),
    if (wakeContext != null) ...wakeContext!.toEnvironment(),
    'CC_DISABLE_PROJECT_CONFIG': 'true',
    'OPENCODE_DISABLE_PROJECT_CONFIG': 'true',
  };

  /// Builds a [SandboxConfig] for the current dispatch using the policy
  /// resolver + config builder. Used by the ACP transport.
  Future<SandboxConfig> _buildSandboxConfig(AgentCapabilities caps) async {
    final home = Platform.environment['HOME'] ?? '';
    final wsId = workspaceId ?? '';
    final agentKey = (agentId != null && agentId!.isNotEmpty)
        ? agentId!
        : 'oneshot';
    final convKey = conversationId ?? 'no-conv';
    final sessionId = '$agentSessionPrefix$agentKey::$convKey::${mode.name}';
    final spec = SandboxSpec(
      sessionId: sessionId,
      workspaceId: wsId,
      agentId: agentId,
      bindMounts: _bindMounts(),
      guestWorkdir: agentDirHostPath,
      networkEnabled: caps.canAccessNetwork,
      mode: mode,
      capabilities: caps,
      protectedPaths: await _protectedPaths(),
    );
    final policy = const SandboxPolicyResolver().resolve(
      spec: spec,
      capabilities: caps,
      homeDir: home.isNotEmpty ? home : null,
      runDir: '$agentDirHostPath/.cc-runs/$sessionId',
    );
    return buildSandboxConfigFromPolicy(policy);
  }

  /// Universal command preflight (Phase 2.3). Evaluates the resolved
  /// command string against the mode's [CommandPolicy] before spawning.
  /// Returns `true` when the spawn should proceed, `false` when denied.
  /// `prompt` decisions log a warning and proceed (synchronous UAC wiring
  /// is Phase 3).
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
        unawaited(_closeRunLog(exitCode: 126));
        addEvent(DoneEvent());
        _completeRun();
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
          unawaited(_closeRunLog(exitCode: 126));
          addEvent(DoneEvent());
          _completeRun();
          return false;
        }
        final approved = await port.requestApproval(
          ConfirmationRequest(
            conversationId: conversationId ?? '',
            title: 'Approve command',
            detail: 'An agent is about to run:',
            command: command,
            severity: ConfirmationSeverity.warning,
            kind: ConfirmationKind.command,
          ),
        );
        if (!approved) {
          addEvent(
            ErrorEvent(content: '[sandbox] command denied by user: $command'),
          );
          unawaited(_closeRunLog(exitCode: 126));
          addEvent(DoneEvent());
          _completeRun();
          return false;
        }
        return true;
    }
  }

  /// Maps a [Mode] to Claude Code's `--permission-mode`. `plan`
  /// keeps Claude in read-only/plan mode; `review` borrows it (Claude has no
  /// pure read-only flag, and plan mode blocks edits); `chat` uses the default.
  static String? _claudePermissionMode(Mode mode) {
    switch (mode) {
      case Mode.plan:
      case Mode.review:
      case Mode.orchestrate:
        // orchestrate is read-mostly like plan: research + propose only.
        return 'plan';
      case Mode.chat:
        return null;
    }
  }

  /// Runs Claude Code directly via `claude -p --output-format stream-json`,
  /// spawned inside the OS sandbox exactly like a structured-CLI adapter
  /// (Pi). Stdout NDJSON is parsed by [ClaudeStreamJsonParser] into
  /// [AgentProcessEvent]s; the prompt is fed via stdin. `claude -p` draws
  /// from the same Claude Code subscription quota as interactive mode.
  Future<void> _runClaudeCli({
    required AgentCapabilities caps,
    required ScopedCredentials scoped,
    required String sandboxSessionId,
    required String wsId,
  }) async {
    for (final note in scoped.notes) {
      addEvent(DebugEvent(content: '[claude] $note'));
    }

    final claudePath = await resolveBinary('claude');
    if (claudePath == null) {
      addEvent(
        ErrorEvent(
          content:
              '[claude] "claude" not found on PATH. Install Claude Code: '
              'https://docs.anthropic.com/en/docs/claude-code',
        ),
      );
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    // Point `claude` at the Control Center MCP server explicitly. The derived
    // client config (`<cwd>/.mcp.json`, written per-session from the live
    // `mcp_config.json` posture) is the ONE config `--strict-mcp-config` loads,
    // so the agent reliably gets the `mcp__*` tool surface (incl.
    // `submit_output`, which writes a pipeline run's structured output so the
    // step resume listener can harvest it). Null resolver → no `--mcp-config`.
    var mcpConfigPath = await _resolveMcpConfigPath();
    // `--strict-mcp-config` makes `claude` treat a missing/unreadable config
    // file as FATAL: it exits 1 before emitting any stream event ("nothing
    // visible, then exited with code 1"). If the resolver handed back a path
    // that isn't actually on disk, drop the MCP flags and run without the CC
    // tool surface (degraded, like Pi) rather than killing the whole turn.
    if (mcpConfigPath != null && !File(mcpConfigPath).existsSync()) {
      addEvent(
        DebugEvent(
          content:
              '[claude] MCP config not found at $mcpConfigPath — running '
              'without the control-center tools.',
        ),
      );
      mcpConfigPath = null;
    }
    final claudeFlags = ClaudeCliBackend.buildClaudeArgs(
      modelId: modelId,
      permissionMode: _claudePermissionMode(mode),
      mcpConfigPath: mcpConfigPath,
    );

    final handle = await onResolveHandle(
      sessionId: sandboxSessionId,
      spec: SandboxSpec(
        sessionId: sandboxSessionId,
        workspaceId: wsId,
        agentId: agentId,
        bindMounts: _bindMounts(),
        guestWorkdir: agentDirHostPath,
        networkEnabled: caps.canAccessNetwork,
        mode: mode,
        capabilities: caps,
        protectedPaths: await _protectedPaths(),
      ),
      emit: addEvent,
    );

    if (handle.state == SandboxState.error) {
      throw StateError('sandbox launch failed: ${handle.error}');
    }

    eventsSub = deps.sandbox.events(handle).listen(_forwardSandboxEvent);

    final argv = <String>[claudePath, ...claudeFlags, ...adapterArgsOverride];

    // Preflight the claude invocation (NOT the prompt — it's free-form text
    // that could contain shell operators). The agent's own Bash commands are
    // checked by Claude's own permission layer.
    if (!await _preflightCommand(argv)) {
      return;
    }

    _claudeParser = ClaudeStreamJsonParser(
      ClaudeStreamJsonCallbacks(
        onText: (delta) => addEvent(TextEvent(content: delta)),
        onThinking: (delta) => addEvent(ThinkingEvent(content: delta)),
        onToolCall: (tu) => addEvent(
          ToolCallEvent(
            toolName: tu.name,
            toolCallId: tu.id,
            inputs: tu.input as Map<String, dynamic>?,
          ),
        ),
        onError: (message) =>
            addEvent(ErrorEvent(content: '[claude] $message')),
      ),
    );

    final mergedEnv = _mergedEnv(
      caps: caps,
      scopedEnv: scoped.environment,
      backendEnv: const {},
    );

    addEvent(DebugEvent(content: '[claude] launching claude -p…'));
    final exitCode = await deps.sandbox.exec(
      handle,
      argv,
      env: mergedEnv,
      onPid: (forkedPid) {
        _onPidAvailable(forkedPid);
        addEvent(
          DebugEvent(content: '[claude] claude running (pid $forkedPid)'),
        );
      },
      stdinInput: prompt,
    );
    _claudeParser = null;
    unawaited(_closeRunLog(exitCode: exitCode));

    if (exitCode == 127) {
      addEvent(
        ErrorEvent(
          content:
              '[claude] "claude" not found on PATH. Install Claude Code: '
              'https://docs.anthropic.com/en/docs/claude-code',
        ),
      );
    } else if (exitCode != 0) {
      addEvent(
        ErrorEvent(content: '[claude] claude exited with code $exitCode'),
      );
    } else {
      addEvent(DebugEvent(content: '[claude] claude exited cleanly (code 0)'));
    }
    addEvent(DoneEvent());
    _completeRun();
  }

  /// Gracefully stops the session by revoking credentials and closing the
  /// event controller.
  Future<void> stop() async {
    _cancelSilenceWatchdog();
    _claudeParser = null;
    await _teardownAcp();
    final cred = credHandle;
    if (cred != null) {
      await deps.broker.revoke(cred);
      credHandle = null;
    }
    _closeController();
  }

  /// Forcefully terminates the session by marking the run as failed,
  /// revoking credentials, cancelling event subscriptions, and closing the
  /// controller.
  Future<void> terminate() async {
    _cancelSilenceWatchdog();
    // Cancel the built-in harness loop and any in-flight subagent loops (they
    // share this token) before tearing the session down.
    _cancelSource.cancel('terminated');
    _claudeParser = null;
    await _teardownAcp();
    addEvent(
      DebugEvent(
        content: '[sandbox] dispatch $dispatchId terminated by request',
      ),
    );
    _failRun('Terminated by user request');
    final cred = credHandle;
    if (cred != null) {
      await deps.broker.revoke(cred);
      credHandle = null;
    }
    unawaited(eventsSub?.cancel());
    eventsSub = null;
    _closeController();
  }

  /// Tears down an active ACP subprocess (cancel the turn, close the client,
  /// kill the process). A no-op when no ACP run is active.
  Future<void> _teardownAcp() async {
    final client = _acpClient;
    final process = _acpProcess;
    final sub = _acpEventsSub;
    _acpClient = null;
    _acpProcess = null;
    _acpEventsSub = null;
    await sub?.cancel();
    await client?.close();
    process?.kill();
  }

  void _cancelSilenceWatchdog() {
    silenceTimer?.cancel();
    silenceTimer = null;
  }

  void _startSilenceWatchdog() {
    _cancelSilenceWatchdog();
    final threshold = silenceThreshold;
    silenceTimer = Timer.periodic(silenceCheckInterval, (_) {
      final last = lastOutputAt;
      if (last != null && DateTime.now().difference(last) >= threshold) {
        _cancelSilenceWatchdog();
        addEvent(
          ErrorEvent(
            content:
                '[sandbox] Agent silent for '
                '${threshold.inMinutes} min — terminating',
          ),
        );
        _failRun(
          'Silent run (no output for '
          '${threshold.inMinutes} min)',
        );
      }
    });
  }

  void _forwardSandboxEvent(SandboxEvent event) {
    switch (event.type) {
      case SandboxEventType.stdout:
        _tryParseStructuredOutput(event.content);
        break;
      case SandboxEventType.stderr:
        addEvent(ErrorEvent(content: event.content));
        break;
      case SandboxEventType.exit:
        _completeRun();
        break;
      case SandboxEventType.killed:
        addEvent(
          ErrorEvent(
            content: event.content.isNotEmpty
                ? event.content
                : '[sandbox] killed',
          ),
        );
        _completeRun();
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
            : '[sandbox] denied ${v.action} on ${v.target}'
                  '${v.suggestedCapability == null ? '' : ' '
                            '(grant ${v.suggestedCapability} to allow)'}';
        addEvent(
          SandboxViolationEvent(
            content: summary,
            action: v?.action,
            target: v?.target,
            suggestedCapability: v?.suggestedCapability,
          ),
        );
        break;
    }
  }

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
    final claudeParser = _claudeParser;
    if (claudeParser != null) {
      claudeParser.process(json);
      return;
    }
    _handlePiEvent(json);
  }

  void _handlePiEvent(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    switch (type) {
      case 'message_update':
        final assistantEvent =
            json['assistantMessageEvent'] as Map<String, dynamic>?;
        if (assistantEvent == null) {
          return;
        }
        final subType = assistantEvent['type'] as String? ?? '';
        final delta = assistantEvent['delta'] as String? ?? '';
        if (delta.isEmpty) {
          return;
        }
        if (subType == 'text_delta') {
          addEvent(TextEvent(content: delta));
        } else if (subType == 'thinking_delta') {
          addEvent(ThinkingEvent(content: delta));
        }
        break;
      case 'tool_execution_start':
        addEvent(
          ToolCallEvent(
            toolName: json['toolName'] as String? ?? '',
            toolCallId: json['toolCallId'] as String? ?? '',
            inputs: json['args'] as Map<String, dynamic>?,
          ),
        );
        break;
      case 'tool_execution_update':
        final partialResult = json['partialResult'];
        if (partialResult is Map<String, dynamic>) {
          final contentList = partialResult['content'];
          if (contentList is List) {
            final text = contentList
                .whereType<Map<String, dynamic>>()
                .where((b) => b['type'] == 'text')
                .map((b) => b['text'] as String? ?? '')
                .join();
            if (text.isNotEmpty) {
              addEvent(
                ToolResultEvent(
                  toolCallId: json['toolCallId'] as String? ?? '',
                  outputs: text,
                  toolName: json['toolName'] as String? ?? '',
                  isPartial: true,
                ),
              );
            }
          }
        }
        break;
      case 'tool_execution_end':
        final isError = json['isError'] as bool? ?? false;
        addEvent(
          ToolResultEvent(
            toolCallId: json['toolCallId'] as String? ?? '',
            outputs: json['result'] != null
                ? jsonEncode(json['result'])
                : json['toolName'] as String? ?? '',
            toolName: json['toolName'] as String? ?? '',
            isError: isError,
          ),
        );
        break;
      case 'message_end':
      case 'turn_end':
        // A turn/message that ended in a provider error carries the failure on
        // the assistant message's `stopReason`/`errorMessage` — Pi does NOT
        // emit a dedicated error event. Surface it (once, on message_end) as an
        // ErrorEvent so the failure reaches the transcript instead of being
        // dropped, leaving an empty "done" turn. (User messages also end here,
        // but only assistant errors set stopReason == 'error'.)
        if (type == 'message_end') {
          final message = json['message'];
          if (message is Map<String, dynamic> &&
              message['stopReason'] == 'error') {
            addEvent(
              ErrorEvent(
                content: _formatPiError(message['errorMessage'] as String?),
              ),
            );
          }
        }
        break;
      case 'error':
        // Defensive: a top-level error event (rare — provider errors normally
        // arrive via the message stopReason above).
        addEvent(
          ErrorEvent(
            content: _formatPiError(
              (json['errorMessage'] ?? json['message'] ?? json['error'])
                  as String?,
            ),
          ),
        );
        break;
      case 'agent_end':
        addEvent(DoneEvent());
        break;
      default:
        break;
    }
  }

  /// Extracts a human-readable message from a Pi `errorMessage`. Pi formats
  /// provider failures as `"<status> <json>"` (e.g.
  /// `400 {"error":{"message":"…"}}`); pull out the inner `error.message` when
  /// present, otherwise fall back to the raw string.
  String _formatPiError(String? raw) {
    final message = raw?.trim() ?? '';
    if (message.isEmpty) {
      return 'Agent run ended in an error with no message.';
    }
    final braceIdx = message.indexOf('{');
    if (braceIdx >= 0) {
      try {
        final decoded = jsonDecode(message.substring(braceIdx));
        if (decoded is Map<String, dynamic>) {
          final err = decoded['error'];
          if (err is Map<String, dynamic> && err['message'] is String) {
            return err['message'] as String;
          }
          if (decoded['message'] is String) {
            return decoded['message'] as String;
          }
        }
      } catch (_) {
        // Not JSON we recognise — fall through to the raw string.
      }
    }
    return message;
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
    final cred = credHandle;
    if (cred != null) {
      unawaited(deps.broker.revoke(cred));
      credHandle = null;
    }
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
        final existing = await repo.getById(ws, id);
        if (existing == null) {
          _failRun('Run log $id missing when PID $forkedPid arrived');
          return;
        }
        await repo.upsert(
          existing.copyWith(pid: forkedPid, status: RunStatus.running),
        );
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
        final existing = await repo.getById(ws, id);
        // Never resurrect a row that already reached a terminal state (a stop
        // that landed during startup), and never clobber a status something else
        // has already advanced.
        if (existing == null ||
            existing.completedAt != null ||
            existing.status != RunStatus.pending) {
          return;
        }
        await repo.upsert(existing.copyWith(status: RunStatus.running));
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
        final existing = await repo.getById(ws, id);
        if (existing == null) {
          _failRun('Run log $id missing when log path arrived');
          return;
        }
        await repo.upsert(existing.copyWith(logPath: path));
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
  /// the loop, the mode profile, the model, and the size of the assembled system
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
  /// repo contents and memory facts, and a run log is not the place for a copy
  /// of them. The digest is still enough to tell two runs apart.
  void _recordRunComposition({
    required List<String> toolNames,
    required String mode,
    required String model,
    required String adapter,
    required String systemPrompt,
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
      'toolCount': toolNames.length,
      'tools': toolNames,
      'systemPromptChars': systemPrompt.length,
      'systemPromptSha256': sha256
          .convert(utf8.encode(systemPrompt))
          .toString(),
    });
    unawaited(() async {
      try {
        final existing = await repo.getById(ws, id);
        if (existing == null) {
          return;
        }
        await repo.upsert(existing.copyWith(contextSnapshotJson: snapshot));
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
            await repo.upsert(
              existing.copyWith(
                status: RunStatus.error,
                summary: message,
                completedAt: DateTime.now(),
              ),
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

  /// Emits an [AgentProcessEvent] to the session stream, updates the last
  /// output timestamp, and logs the event for persistence.
  void addEvent(AgentProcessEvent event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
    lastOutputAt = DateTime.now();
    _updateRunLogLastOutput();
    _logWriter.logEvent(event);
    _emitTaskLifecycle(event);
  }

  /// Mirrors the dispatch stream onto the typed task-lifecycle event bus so
  /// remote clients see `task:running → task:progress → task:completed` (plus
  /// typed `task:message` frames). Coarse by design — the per-token text stream
  /// stays on the dispatch channel; this feed carries discrete milestones.
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

  void _updateRunLogLastOutput() {
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
        final existing = await repo.getById(ws, id);
        if (existing == null) {
          return;
        }
        await repo.upsert(existing.copyWith(lastOutputAt: lastOutputAt));
      } catch (_) {}
    }());
  }

  Future<void> _openRunLog({required AgentCapabilities caps}) async {
    await _logWriter.open(
      agentDirHostPath: agentDirHostPath,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      ticketId: ticketId,
      cliName: cliName,
      modelId: modelId,
      capabilities: caps,
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
  /// `status` deliberately stays `completed`: the process exited cleanly, and
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
      final existing = await repo.getById(ws, id);
      if (existing == null) {
        return;
      }
      await repo.upsert(
        existing.copyWith(
          liveness: RunLiveness.empty,
          errorFamily: RunErrorFamily.silentRun,
          summary: contract.unmetSummary,
        ),
      );
    } on Object catch (e) {
      CcInfraLog.warning('Failed to mark run $id contract-unmet: $e');
    }
  }

  Future<void> _closeRunLog({int? exitCode, Object? error}) async {
    await _logWriter.close(exitCode: exitCode, error: error);
  }

  void _closeController() {
    if (!controller.isClosed) {
      controller.close();
    }
  }

  Future<AgentCapabilities> _capabilitiesFor(String? agentId) async {
    final ws = workspaceId;
    if (agentId != null && ws != null && ws.isNotEmpty) {
      try {
        final agent = await deps.agentRepo.getById(ws, agentId);
        if (agent?.capabilities != null) {
          return agent!.capabilities!;
        }
      } catch (_) {
        CcInfraLog.warning(
          'DispatchSession: Failed to fetch agent capabilities: $agentId',
        );
      }
    }
    return deps.defaultCaps;
  }
}

/// A [SubagentSpawner] backed by a closure, so the `task` tool can spawn a
/// subagent without the tool holding a reference to the whole dispatch session.
class _ClosureSubagentSpawner implements SubagentSpawner {
  _ClosureSubagentSpawner(this._run);

  final Future<SubagentResult> Function(SubagentSpawnRequest request) _run;

  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) => _run(request);
}
