import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
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
import 'package:cc_domain/features/guardrails/domain/services/action_request_extractor.dart';
import 'package:cc_domain/features/guardrails/domain/services/autonomy_composition.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/context/snapcompact_compactor.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/claude_refusal_message.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/harness/ast_parser_provider.dart';
import 'package:cc_infra/src/harness/cc_natives_file_search_port.dart';
import 'package:cc_infra/src/harness/harness_system_prompt.dart';
import 'package:cc_infra/src/harness/harness_tool_registry_builder.dart';
import 'package:cc_infra/src/harness/harness_tool_surface.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/messaging/prompt_attachments.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:cc_infra/src/sandboxing/env_sanitizer.dart';
import 'package:cc_infra/src/sandboxing/run_log_writer.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/skills/active_repo_tracker.dart';
import 'package:cc_infra/src/skills/repo_skill_projector.dart';
import 'package:cc_infra/src/util/command_redaction.dart';
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
    this.execGrantService,
    this.agentQuestionPort,
    this.blobStore,
    this.lspSupervisor,
    this.astParsers,
    this.transcriptStore,
    this.debugSupervisor,
    this.kernelLauncherFactory,
    this.actionGuard,
    this.mcpRegistry,
    this.skillScanner,
    this.harnessCredentialStore,
    this.harnessCredentialRefresher,
    this.credentialGate,
    this.syncClaudeCredential,
    this.modelResolver,
    this.harnessProviderFactory = const HarnessProviderFactory(),
    this.agentLoop = const AgentLoopRunner(),
    this.resolveGitIdentity,
    this.repoInspector,
    this.autonomyResolver,
    this.processControl,
    this.toolDeferralEnabled = true,
    FileSearchPort? fileSearch,
  }) : fileSearch = fileSearch ?? CcNativesFileSearchPort();

  /// Whether a harness run withholds the schemas of tools it is unlikely to
  /// need until it asks for them (`--tool-deferral`, default on).
  ///
  /// The field kill switch. False makes every admitted tool resident, which is
  /// the pre-deferral behaviour byte for byte — so if a model ever handles the
  /// two-tier surface badly, the fix is a flag rather than a release.
  final bool toolDeferralEnabled;

  /// Fuzzy file search shared by the harness `read` (did-you-mean recovery)
  /// and `file_search` tools. Defaults to the fff-backed adapter; the server
  /// injects its long-lived instance so scan caches are shared.
  final FileSearchPort fileSearch;

  /// OS-level sandbox used to run sandboxed CLI adapters (e.g. Pi).
  /// Resolves the per-space autonomy dial for (workspaceId, spaceId,
  /// agentId) (PRD 16 §12): `proposeOnly` | `actWithApproval` | `actFreely`, or
  /// null for the default (act with approval — the fail-closed gate).
  ///
  /// The workspace is part of the key because the space row lives in that
  /// workspace's database; a space id alone names nothing.
  final Future<String?> Function(
    String workspaceId,
    String spaceId,
    String agentId,
  )?
  autonomyResolver;

  /// The sandbox port isolating this dispatch session.
  final SandboxPort sandbox;

  /// Kills the agent's OS process on terminate / silence-watchdog expiry.
  ///
  /// Optional: a host that wires none still tears the SANDBOX down (which
  /// takes the child with it on the isolating backends), it just cannot stop a
  /// single pid inside a shared one.
  final ProcessControlPort? processControl;

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
    String? spaceId,
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

  /// Asks the operator whether agents may run programs from inside their
  /// worktree, and turns the answers into the sandbox's exec-grant roots.
  ///
  /// Null leaves the writable-dir exec block fully closed — the behaviour
  /// before grants existed. It is never inferred: a tree is opened only by an
  /// answer, so a host with no approver wired grants nothing.
  final SandboxExecGrantService? execGrantService;

  /// The host's language-server pool, or null when the host runs without one.
  ///
  /// Shared across runs by design: a language server's cost is its indexing,
  /// so a per-run supervisor would re-index the project on every dispatch.
  final LspSupervisor? lspSupervisor;

  /// Shared tree-sitter parser for the structural tools, or null when the
  /// grammars are not staged (the tools are then simply not registered).
  final AstParserProvider? astParsers;

  /// Debug adapters for the `debug` tool, or null when debugging is off.
  final DebugSessionSupervisor? debugSupervisor;

  /// Where an `eval` kernel runs for a conversation — the enclosure when it
  /// has one, the host otherwise. Null turns `eval` off entirely.
  ///
  /// A factory rather than a launcher because the decision is per
  /// conversation and is made when a cell is first run, not when the tool
  /// surface is assembled.
  final Future<KernelLauncher> Function({
    required String workingDirectory,
    String? workspaceId,
    String? conversationId,
  })?
  kernelLauncherFactory;

  /// Where a conversation's harness history is persisted, so the next run
  /// continues it for real instead of re-reading a summary of it. Null keeps
  /// the historical behaviour: every run starts from an empty history.
  final HarnessTranscriptStore? transcriptStore;

  /// Content-addressed storage for images a tool returned (screenshots from
  /// `browser_use` / `computer_use` / `mobile_use`, rendered output).
  ///
  /// Without it those images reach the MODEL — the harness and both providers
  /// already carry them — and are then dropped on the floor at the transcript
  /// boundary, so the human watching the run sees a tool call that says
  /// "screenshot taken" and no screenshot. Null keeps that old behaviour.
  final BlobStore? blobStore;

  /// Optional [AgentQuestionPort] backing the `ask_user` tool: the agent asks
  /// a structured question and blocks until a human answers it in the
  /// conversation. Distinct from [confirmationPort], which is a yes/no gate on
  /// an action the agent has already decided to take — this is for a decision
  /// the agent cannot make alone ("which of these three?").
  ///
  /// Null removes the tool from the surface entirely rather than offering one
  /// that can only fail: an agent that asks and is never answered burns its
  /// whole timeout on a question nobody saw.
  final AgentQuestionPort? agentQuestionPort;

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

  /// The skills supply-chain scan gate. Required for a repo's own skills to be
  /// projected into the agent's overlay: those come from a cloned repository
  /// and their frontmatter is autoloaded into a prompt, so they pass the same
  /// verdict an installed skill does. Null disables repo-skill projection
  /// entirely rather than admitting ungated content.
  final SkillScanPort? skillScanner;

  /// Resolves LLM provider credentials for the harness. Null falls back to env
  /// vars / per-adapter env overrides only.
  final ProviderCredentialStore? harnessCredentialStore;

  /// Parks a harness run that has no credential for its provider until someone
  /// connects one, instead of ending the turn.
  ///
  /// Only the harness lane is gated here. The Claude Code lane is gated one
  /// layer up, in `AgentDispatchService`, because its account plan feeds the
  /// sandbox profile and has to be re-resolved before the profile is built.
  ///
  /// Null keeps the pre-gate behaviour: a missing credential fails the run
  /// immediately, with the same message.
  final RunCredentialGatePort? credentialGate;

  /// Re-mirrors a Claude Code account's keychain credential into its directory,
  /// reporting whether the directory ends up holding one.
  ///
  /// Wired only for the gate's sign-in probe, and it is what makes that probe
  /// work AT ALL on macOS: `claude auth login` writes to the Keychain, never to
  /// the account directory, so a run watching only the file would wait out its
  /// whole deadline beside a login that had already succeeded. The mirror is
  /// the bridge, and it is safe to re-run — it refuses to clobber a newer
  /// credential.
  ///
  /// Null (and every non-macOS host, where the CLI writes the file directly)
  /// leaves the probe reading the directory, which is the same answer.
  final Future<bool> Function(String accountId)? syncClaudeCredential;

  /// Refreshes an expiring OAuth credential before a harness run. Null skips
  /// refresh (API-key providers are unaffected).
  final ProviderCredentialRefresher? harnessCredentialRefresher;

  /// Resolves a qualified `provider/model` id to its catalog [ModelInfo], used
  /// by the harness for reasoning-effort clamping, USD cost pricing and
  /// context-window sizing. Null → effort passes unclamped, cost stays 0 and
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

  /// Inspects a run's working directory for its `origin` forge coordinates so
  /// the credential broker can mint a fine-grained GitHub App installation
  /// token scoped to exactly that repository. Null — or a cwd that is not a
  /// forge checkout — mints with no coordinates, which skips the App mint and
  /// leaves the broker's environment fallback.
  ///
  /// A run's GitHub credential is deliberately never a member's personal
  /// token: agent work is authored on the forge as the server's App identity,
  /// and only a write a human drives from the UI rides that human's own
  /// credential (the per-actor RPC lane in `cc_server_runtime`). The
  /// requesting human is still credited on commits via the co-author trailer.
  final GitRepoInspectorPort? repoInspector;
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
  });

  /// Fired once, at the top of [_runHarness], the moment this session's
  /// steering queue becomes drainable. The steering queue service uses it to
  /// attach drain notifications and flush persisted queued rows into the run.
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
  final Future<List<String>?> Function({
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
  final ClaudeAccountRefusal?
  claudeAccountsSpent;

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

  /// Whether the CLI attempt currently running has already written to stderr.
  ///
  /// Set by [_forwardSandboxEvent], reset before every `exec`. A CLI that
  /// explains itself ("Error: Unknown option: --mcp-config") and then exits 1
  /// does not also need `[sandbox] pi exited with code 1` under it — the
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

  /// Active Claude stream-json parser, when [cliName] is `claude`. Held so
  /// parsed stdout lines route to it from the shared sandbox-event forwarder.
  ClaudeStreamJsonParser? _claudeParser;

  /// Tool name per in-flight `tool_use` id: a `tool_result` block names only
  /// the id it answers, and a result with no tool name renders as `tool`.
  final Map<String, String> _claudeToolNames = {};

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

  /// The run's steering inbox, exposed for the host's queue surgery: the
  /// steering queue service pushes ref-carrying messages, reorders them and
  /// attaches drain notifications through this handle. Mutating it is safe
  /// between turns; the loop reads it only at turn boundaries.
  @override
  SteeringQueue get steeringQueue => _steering;

  /// Pauses the built-in harness loop at the next clean turn boundary
  /// (take-over, PRD 16 §8). Subagent loops share the gate, so a take-over
  /// holds the whole conversation. Unused by external-CLI transports.
  final PauseGate _pauseGate = PauseGate();

  /// Whether a built-in harness loop is currently driving this session (the
  /// only transport that can pause at a turn boundary).
  bool _harnessActive = false;

  /// Whether a built-in harness loop is currently driving this session.
  ///
  /// The mid-run affordances that only the harness can honor — pause, and
  /// steering that will actually be drained — gate on this so an
  /// external-CLI transport reports "cannot" instead of accepting a message
  /// into a queue nobody reads.
  @override
  bool get isHarnessActive => _harnessActive;

  /// Deferred tools this run pulled in, in activation order.
  ///
  /// Recorded on the run row so the question "did the agent ever find the tool
  /// it needed?" is answerable from the log rather than by re-running it.
  final List<String> _activatedToolNames = [];

  /// One in-flight "pilot" per identical child prompt prefix.
  ///
  /// A provider's cache entry only becomes readable once the request that
  /// writes it has begun responding, so N children launched in the same
  /// instant each pay the full write premium for a prefix they all share. The
  /// first child of a given shape becomes the pilot; its siblings wait for it
  /// to start streaming and then read what it wrote. The wait is bounded — a
  /// slow pilot must cost a cache hit, never the fan-out itself.
  final Map<String, Completer<void>> _subagentPilots = {};

  static const Duration _subagentPilotWait = Duration(seconds: 8);

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
  /// stop. Returns true when a harness loop will drain it; FALSE — with
  /// nothing enqueued — for non-harness transports, whose one-shot CLI
  /// processes have no input lane (accepting the message would park it in a
  /// queue nobody reads: the silently-swallowed steering bug).
  bool steer(
    String content, {
    SteeringChannel channel = SteeringChannel.steering,
    String? ref,
  }) {
    if (content.trim().isEmpty) {
      return false;
    }
    if (!_harnessActive) {
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
  ///
  /// The requesting human's credit stops at the trailer: the run's GitHub
  /// CREDENTIAL is the broker's (App installation token or environment
  /// fallback), never the member's own — an agent must act on the forge as
  /// the app, not as the person who asked.
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
  /// Normal per-agent overlay dispatch mounts FOUR paths:
  /// - [agentDirHostPath] (the overlay cwd) — **rw**: own scratch + derived
  ///   `.mcp.json`.
  /// - [agentConfigDir] (the agent's global config dir) — **ro**: AGENTS.md +
  ///   `.agents` symlink targets (writes blocked).
  /// - `<convRoot>/repos` — **rw**: the shared conversation worktrees (the
  ///   overlay's `repos → ../../repos` symlink resolves through this). Only
  ///   mounted when it exists on disk.
  /// - `<convRoot>/attachments` — **ro**: what the humans in this conversation
  ///   attached to their messages, materialized from the blob store so the
  ///   paths in the prompt resolve. Read-only because these are the human's
  ///   inputs, not the agent's scratch — a CLI adapter is held to that by the
  ///   mount; the in-process harness reaches it through [_workspaceSharedRoots]
  ///   instead, which has no read-only mode, so there the restraint is
  ///   convention. Only mounted when it exists.
  ///
  /// Fallback / oneshot (no overlay — the cwd IS the agent dir, or no config
  /// dir was threaded): a single writable cwd mount (unchanged behaviour).
  /// Sibling agent folders are never mounted, so an agent cannot reach another
  /// agent's config/skills.
  /// The worktree roots this session could be granted exec on: its WRITABLE
  /// bind mounts, which is exactly the tree the `$HOME` exec block closes and
  /// the tree a repo installs its tooling into. Read-only mounts are excluded —
  /// nothing writes a binary into one, so opening it would widen the sandbox
  /// without fixing anything.
  List<String> _execGrantCandidateRoots() => [
    for (final m in _bindMounts())
      if (!m.readOnly && m.hostPath.isNotEmpty) m.hostPath,
  ];

  /// Resolves the operator-approved exec roots for this session, asking once
  /// per undecided tree. Returns empty when no grant service is wired, which
  /// leaves the exec block fully closed.
  Future<List<String>> _resolveExecGrantRoots(String wsId) async {
    final service = deps.execGrantService;
    if (service == null || wsId.isEmpty) {
      return const [];
    }
    try {
      return await service.approvedRoots(
        workspaceId: wsId,
        candidateRoots: _execGrantCandidateRoots(),
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
    final attachmentsPath = _attachmentsDir;
    if (attachmentsPath != null) {
      mounts.add(
        SandboxBindMount(
          hostPath: attachmentsPath,
          guestPath: attachmentsPath,
          readOnly: true,
        ),
      );
    }
    return mounts;
  }

  /// The conversation's materialized attachments dir, or null when it does not
  /// exist yet (no one has attached anything to this space).
  ///
  /// Derived from the directory layout, exactly like the repos dir beside it —
  /// never from a path the agent could influence.
  String? get _attachmentsDir {
    final cwd = agentDirHostPath;
    final configDir = agentConfigDir;
    if (configDir == null || configDir.isEmpty || p.equals(configDir, cwd)) {
      return null;
    }
    final path = p.join(
      p.dirname(p.dirname(cwd)),
      SpacePromptAttachments.dirName,
    );
    return Directory(path).existsSync() ? path : null;
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
  /// conversation worktrees dir (`<convRoot>/repos`) and the conversation's
  /// materialized attachments, when this session's cwd is a per-agent overlay.
  /// Without the first, the tools refuse the worktrees' real paths — the
  /// overlay only reaches them through its `repos` symlink, whose target is
  /// lexically outside the cwd. Without the second, the paths this run's own
  /// prompt names are unreadable to the tools that were given them. Derived
  /// from the directory layout (mirrors [_bindMounts]), never from the
  /// agent-writable symlink itself.
  List<String> _workspaceSharedRoots() {
    final cwd = agentDirHostPath;
    final configDir = agentConfigDir;
    if (configDir == null || configDir.isEmpty || p.equals(configDir, cwd)) {
      return const [];
    }
    final reposPath = p.join(p.dirname(p.dirname(cwd)), 'repos');
    return [if (Directory(reposPath).existsSync()) reposPath, ?_attachmentsDir];
  }

  /// The space's shared worktree dir, or null when this session's cwd is not a
  /// per-agent overlay (the fallback path, where there are no worktrees).
  ///
  /// Computed rather than read off [_workspaceSharedRoots]: that list now
  /// carries the attachments dir too, and taking its first entry would hand
  /// callers the wrong directory on a space that has attachments but no
  /// worktrees.
  String? get _reposDir {
    final cwd = agentDirHostPath;
    final configDir = agentConfigDir;
    if (configDir == null || configDir.isEmpty || p.equals(configDir, cwd)) {
      return null;
    }
    final reposPath = p.join(p.dirname(p.dirname(cwd)), 'repos');
    return Directory(reposPath).existsSync() ? reposPath : null;
  }

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

  /// Prepares repo-scoped skills for this run and projects the starting repo.
  ///
  /// A space checks every linked repo out side by side, but an agent works in
  /// one at a time — so only that one's skills are ever loaded. When the space
  /// holds a single repo the answer is known before the first turn and is
  /// seeded here; otherwise the first file the agent touches decides.
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

      // Resolve the worktree's GitHub coordinates so the broker can mint a
      // fine-grained App installation token scoped to exactly this repo.
      // Without them the App mint is skipped and the broker falls back to the
      // environment PAT — so a cwd that is not a GitHub checkout still
      // dispatches, it just carries no repo-scoped credential.
      String? repoOwner;
      String? repoName;
      final inspector = deps.repoInspector;
      if (inspector != null && (caps.canCallGitHubApi || caps.canPushToRepo)) {
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

      final scoped = await deps.broker.mint(
        conversationId: conversationId ?? 'unknown',
        capabilities: caps,
        repoOwner: repoOwner,
        repoName: repoName,
        // The member who asked for this run. It bounds the run's forge
        // credential to THEIR access rather than the server owner's, so a
        // read-only collaborator cannot dispatch a pushing agent and have it
        // succeed on someone else's reach.
        actingUserId: requestedByUserId,
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

      // Before any transport starts: the projected skills are on-disk state
      // every adapter discovers for itself, so this has to land before the
      // CLI boots or the harness assembles its system prompt.
      await _initRepoScoping(wsId);

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
      // Redacted: this event reaches the transcript recorder and the client
      // over RPC. A failed authenticated git/HTTP call embeds
      // `https://x-access-token:ghp_…@github.com` in its message — the NDJSON
      // run log already redacts, the live stream did not.
      addEvent(
        ErrorEvent(content: redactSecrets('[sandbox] dispatch failed: $e')),
      );
      _closeController();
    }
  }

  /// Runs a structured-CLI adapter (Pi's `--mode json`) inside the OS
  /// sandbox: resolves the binary, provisions a sandbox handle, builds the
  /// argv via the backend, merges env (caller → broker → backend default →
  /// adapter override → capability) and streams NDJSON events.
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

    // Point the structured adapter (Pi) at the Control Center MCP server by
    // WRITING `<cwd>/.mcp.json` and force-starting the loopback MCP endpoint —
    // both are side effects of resolving the path, exactly like the ACP and
    // Claude transports. Without it the structured adapter gets zero `mcp__*`
    // tools (no memory writes, no `submit_output`).
    //
    // The path is deliberately NOT passed as `--mcp-config`. That flag belongs
    // to the `pi-mcp-adapter` EXTENSION (`pi.registerFlag('mcp-config')`), not
    // to pi itself, and pi's option parser rejects an unknown flag before
    // anything runs — so on a host whose pi has no MCP extension installed
    // EVERY turn died with `Error: Unknown option: --mcp-config` instead of
    // merely running without the CC tools. The same extension discovers the
    // project-scoped `<cwd>/.mcp.json` on its own (its precedence list names
    // it), so writing the file is both necessary and sufficient: extension
    // installed → the tools appear, not installed → the turn runs degraded.
    final mcpConfigPath = await _resolveMcpConfigPath();
    if (mcpConfigPath != null && !File(mcpConfigPath).existsSync()) {
      addEvent(
        DebugEvent(
          content:
              '[sandbox] MCP config not found at $mcpConfigPath — running '
              'without the control-center tools.',
        ),
      );
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
        runnerStateDirs: _runnerStateDirs,
        execGrantRoots: await _resolveExecGrantRoots(wsId),
      ),
      emit: addEvent,
    );

    if (handle.state == SandboxState.error) {
      // Destroy before throwing: the handle is already registered in the
      // adapter's map, and the throw skips the cooldown scheduling that would
      // otherwise clean it up — so an error-state handle (plus its broadcast
      // controller) was retained until a same-session re-dispatch.
      try {
        await deps.sandbox.destroy(handle);
      } on Object catch (e) {
        CcInfraLog.warning(
          'dispatch $dispatchId: destroy after launch '
          'failure also failed: $e',
        );
      }
      throw StateError('sandbox launch failed: ${handle.error}');
    }

    _activeHandle = handle;
    eventsSub = deps.sandbox.events(handle).listen(_forwardSandboxEvent);

    final argv = <String>[
      cliPath,
      ...backend.buildArgs(modelId: modelId, effortLevel: effortLevel),
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
    _sawProcessStderr = false;
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
      // The CLI already said why on stderr — don't stack a vaguer sentence on
      // top of it. See [_sawProcessStderr].
      final content = '[sandbox] $cliName exited with code $exitCode';
      addEvent(
        _sawProcessStderr
            ? DebugEvent(content: content)
            : ErrorEvent(content: content),
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
  /// over stdio and translates `session/update` notifications into events.
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
  /// mode and [AgentLoop] events are translated into [AgentProcessEvent]s so
  /// the harness streams to the UI and run log exactly like the CLI/ACP
  /// transports.
  Future<void> _runHarness({
    required AgentCapabilities caps,
    required ScopedCredentials scoped,
    required String wsId,
  }) async {
    _harnessActive = true;
    // The moment a harness loop becomes drainable: the steering queue service
    // wires this session's drain notifications and flushes any
    // persisted-but-undelivered steering rows into the run here (a queued row
    // written while the session was between transports, or before this
    // dispatch existed, has no other delivery path).
    onHarnessStarted?.call();
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
    var credential = await _resolveHarnessCredential(providerId);
    if (!_harnessAuthSatisfied(credential)) {
      final envHint =
          (EnvProviderCredentialStore.envKeys[providerId] ?? const <String>[])
              .join(' or ');
      final detail =
          '[harness] No credential for provider "$providerId". Connect '
          'an account in Settings → Providers'
          "${envHint.isEmpty ? '' : ' or set $envHint'}.";
      // Park the turn rather than spending it, when a human can be asked.
      // Unlike the Claude lane this gate lives IN the session: a harness
      // credential reaches the provider in-process, so nothing about the
      // already-built sandbox profile has to change for the run to continue on
      // a key that was pasted a moment ago.
      credential = await _gateOnHarnessCredential(
        providerId: providerId,
        detail: detail,
      );
      if (!_harnessAuthSatisfied(credential)) {
        addEvent(ErrorEvent(content: detail, source: 'harness'));
        unawaited(_closeRunLog(exitCode: 127));
        addEvent(DoneEvent());
        _completeRun();
        return;
      }
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
    //     /skill:<name> (or /skill:<repo>:<name>) injects that skill's
    //     instructions; anything else is plain text.
    //
    //     Parsed from `userText` (the user's message verbatim), NOT `prompt`:
    //     a space dispatch layers `prompt` into `<context>…</context>\n\n…`,
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

    // Magic keywords: a standalone lowercase word in the user's own prose that
    // attaches a hidden instruction to THIS turn. Matched against `userText`,
    // never the layered prompt — the context blocks are full of paths and
    // identifiers, which is exactly what the boundary rules exist to ignore.
    //
    // The visible message is deliberately left alone: the user sees the word
    // they typed and the instruction rides alongside, so the transcript never
    // disagrees with what they wrote.
    final magic = detectMagicKeywords(userText ?? prompt);
    if (magic.isNotEmpty) {
      commandDirectives.writeln(magicKeywordDirective(magic));
      addEvent(
        DebugEvent(content: '[harness] ${magic.map((k) => k.word).join(', ')}'),
      );
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
    // the completion contract, the guard preset, the sandbox and the generated
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
            // Per-space autonomy dial (PRD 16 §12), graduated and visible:
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
                      'space is propose-only.',
                ),
              );
              return const ToolGateDecision.deny(
                reason: 'this space\'s autonomy is set to propose-only',
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
                spaceId: conversationId,
                agentId: agentId,
                mode: effectiveMode,
                // The call's own arguments, so a rule can be about the paths
                // it writes or the refs it pushes rather than only the verb.
                request: const ActionRequestExtractor().extract(
                  args,
                  classes: tool.actionClasses,
                ),
              );
              // Every branch below reports what it APPLIED to the audit
              // trail. `resolve` is a pure read, so without this the busiest
              // agent surface in the product would be the one lane the
              // "every verdict is recorded" claim did not cover.
              void auditOutcome(ActionDecision applied, {bool asked = false}) {
                guard.recordOutcome(
                  workspaceId: wsId,
                  resolution: resolution,
                  applied: applied,
                  classes: tool.actionClasses,
                  agentId: agentId,
                  spaceId: conversationId,
                  actionSummary: tool.name,
                  prompted: asked,
                  onBehalfOfUserId: requestedByUserId,
                  runId: runLogId,
                );
              }

              if (resolution.decision == ActionDecision.deny) {
                auditOutcome(ActionDecision.deny);
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
              // Policy × the dial, through the ONE shared rule (the deny
              // above is the same floor `AutonomyComposition` enforces, kept
              // here so the model gets the policy's own reason verbatim).
              final outcome = const AutonomyComposition().compose(
                decision: resolution.decision,
                autonomy: AutonomyLevel.tryFromWire(autonomy),
              );
              if (outcome == AutonomyOutcome.allow) {
                auditOutcome(ActionDecision.allow);
                return const ToolGateDecision.allow();
              }
              if (outcome == AutonomyOutcome.deny) {
                auditOutcome(ActionDecision.deny);
                return ToolGateDecision.deny(
                  reason: resolution.driving.reason,
                  remediation: _remediationFor(profile),
                );
              }
              final approved = await port.requestApproval(
                ConfirmationRequest(
                  spaceId: spaceId ?? '',
                  workspaceId: workspaceId,
                  title: 'Approve ${tool.name}',
                  detail:
                      '${resolution.driving.reason}'
                      '${_approvalArgsSummary(args)}',
                  kind: tool.approvalTier == ToolApprovalTier.exec
                      ? ConfirmationKind.command
                      : ConfirmationKind.fileWrite,
                ),
              );
              auditOutcome(
                approved ? ActionDecision.allow : ActionDecision.deny,
                asked: true,
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
                spaceId: spaceId ?? '',
                workspaceId: workspaceId,
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
    // committer identity + co-author trailer, with the broker's scoped
    // credential winning (same precedence as the CLI transports' merged env —
    // an agent acts on GitHub as the App, never as the requesting member).
    final harnessToolEnv = <String, String>{
      ..._gitIdentityEnv,
      ...scoped.environment,
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

    // The catalog is what puts file-defined agents in the tool's schema; the
    // model cannot ask for one it was never told about.
    final subagentCatalog = await _subagentCatalog();
    registry.register(
      TaskTool(
        catalog: subagentCatalog,
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
    // Resident tools ride every request; the rest stay callable by name and
    // load their schema on first use. Same assembly the context explorer runs,
    // so what it reports is what a run actually gets.
    final partition = materializeHarnessToolSurface(
      registry: registry,
      surface: surface,
      residency: profile.toToolResidencySpec(enabled: deps.toolDeferralEnabled),
    );
    var tools = partition.resident;
    var deferredTools = partition.deferred;

    // ---- Vibe mode: the session directs rather than does ----
    // The toolset drop is the mechanism, not the prompt. A director that can
    // still grep and edit will do the work itself under pressure — so the only
    // way it can affect the repo becomes a worker, and the only way it can
    // know what happened becomes reading the files a worker touched.
    final vibeRoster = _vibeRoster;
    if (vibeRoster != null) {
      final vibeTools = buildVibeTools(
        roster: vibeRoster,
        runner: _ClosureVibeRunner((worker, brief, ctx, type, model) async {
          // A worker is an ordinary subagent underneath: same depth cap, same
          // guardrail policy, same run-log child. Vibe changes who drives it,
          // not what it is allowed to do.
          return _spawnSubagent(
            SubagentSpawnRequest(
              description: brief,
              label: 'vibe:${worker.label}',
              type: type,
              context: ctx,
              modelOverride: model,
            ),
            depth: 1,
            parentType: null,
            parentRunId: runLogId,
            baseCaps: caps,
            env: harnessToolEnv,
            parentProvider: provider,
            parentProviderId: providerId,
            baseSystemPrompt: baseSystem,
            approval: approval,
          );
        }),
      );
      tools = [
        // Read-tier only: everything that changes the world goes through a
        // worker.
        for (final tool in partition.resident)
          if (tool.approvalTier == ToolApprovalTier.read && tool.name != 'task')
            tool,
        ...vibeTools,
      ];
      // Nothing is deferred in vibe mode: the surface is small enough to ride
      // every request, and a director that has to search for its own verbs is
      // paying a round trip to learn something the prompt already told it.
      deferredTools = const [];
    }

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
    // user message: cache-stable, weighted as rules and immune to the
    // `<context>`-wrapping that made the old `/plan` directive unreachable.
    final capabilityBlock = buildCapabilityPreamble(
      profile,
      materializedToolNames: [for (final t in tools) t.name],
      deferredToolNames: [for (final t in deferredTools) t.name],
    );
    final systemPrompt = [
      baseSystem,
      capabilityBlock,
      if (commandDirectives.isNotEmpty) commandDirectives.toString().trim(),
    ].where((part) => part.trim().isNotEmpty).join('\n\n');
    _recordRunComposition(
      toolNames: [for (final t in tools) t.name],
      deferredToolNames: [for (final t in deferredTools) t.name],
      mode: effectiveMode.name,
      model: qualifiedModel,
      adapter: 'cc-harness',
      systemPrompt: systemPrompt,
      // What the tool block actually costs on the wire, by the same estimator
      // the loop budgets compaction with. Without it, "the surface got
      // smaller" is a claim nobody can check against a real run.
      toolSchemaTokens: estimateToolSchemaTokens(tools),
    );

    // Opt-in loop extensions from `.agents/harness.json` (stream rules, advisor,
    // shell hooks). Absent file → all off.
    final runConfig = await HarnessRunConfig.load(
      [agentDirHostPath, agentConfigDir],
      // Only the USER-OWNED agent config dir may declare shell hooks. The
      // working tree is a cloned repository: honoring its `.agents/harness.json`
      // hooks meant that cloning a hostile repo and dispatching an agent in it
      // executed that repo's scripts on the host, ungated — the opposite of the
      // fail-closed posture the skills gate enforces for skill content.
      hookTrustedBases: [agentConfigDir],
    );
    if (runConfig.droppedHookBase != null) {
      addEvent(
        DebugEvent(
          content:
              '[harness] ignoring shell hooks declared by '
              '${runConfig.droppedHookBase}/.agents/harness.json — hooks are '
              'only honored from your own agent config dir, never from a '
              "repository's working tree.",
        ),
      );
    }
    Advisor? advisor;
    if (runConfig.advisorEnabled) {
      // A cheap second model watches the run; feed it the project's standing
      // conventions (AGENTS.md/CLAUDE.md) and any WATCHDOG.md attention block.
      final watchdogContext = await loadWatchdogContext(
        agentDirHostPath,
        agentConfigDir: agentConfigDir,
      );
      // A project may declare a ROSTER (`WATCHDOG.yml`) instead of relying on
      // one general-purpose reviewer: separate advisors, each with one job and
      // often a different model, because the questions worth asking about a
      // turn are different in kind and a single reviewer answers whichever it
      // noticed first. With no roster this is exactly the previous behaviour.
      final roster = await const WatchdogRosterLoader().load(
        agentDirHostPath,
        agentConfigDir: agentConfigDir,
      );
      String attentionFor(String extra) {
        final parts = [
          if (watchdogContext.attention case final a? when a.isNotEmpty) a,
          if (roster.shared.isNotEmpty) roster.shared,
          if (extra.isNotEmpty) extra,
        ];
        return parts.join('\n\n');
      }

      if (roster.advisors.isEmpty) {
        advisor = WatchdogAdvisor(
          provider,
          model: runConfig.advisorModel,
          attention: attentionFor(''),
          projectContext: watchdogContext.projectContext,
          extraInstructions: runConfig.advisorInstructions,
        );
      } else {
        advisor = AdvisorPanel([
          for (final entry in roster.advisors)
            WatchdogAdvisor(
              provider,
              // Each advisor may name its own model; without one it shares the
              // run's advisor model.
              model: entry.model ?? runConfig.advisorModel,
              attention: attentionFor(entry.instructions),
              projectContext: watchdogContext.projectContext,
              extraInstructions: runConfig.advisorInstructions,
            ),
        ]);
        addEvent(
          DebugEvent(
            content:
                '[harness] advisor panel: '
                '${roster.advisors.map((a) => a.name).join(', ')}',
          ),
        );
      }
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
    // cannot share one output ceiling and models that publish a required
    // sampling recipe degrade — sometimes out of their own tool-call dialect —
    // when served at other values. Unset fields keep the historical behavior
    // exactly: the harness default ceiling and no sampling fields on the wire.
    final generation =
        credential?.generation ?? const ProviderGenerationDefaults();
    // Priced spend of THIS run, accumulated from usage events. Autonomous
    // commands (/goal, /loop) are bounded by the in-session cost cap below —
    // enforced mid-run via externalBudgetExceeded, not just between
    // segments. (0-cost providers never reach the cap; their automatic
    // bounds are the doom-loop repetition guard, the advisor and the
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
      // `ultrathink` overrides the configured effort for THIS turn only —
      // that is the whole point of typing it mid-sentence. It only ever
      // raises: a keyword asking for more thought must never quietly buy less
      // than the agent was already configured for.
      effort: _raiseEffort(
        _resolveHarnessEffort(modelInfo),
        magicKeywordEffort(magic),
      ),
      cacheKey: conversationId,
      // Kernel-level ceiling on ONE tool call. The tools that own a process
      // self-limit (bash clamps its model-supplied timeout), but a bridged
      // MCP tool or a wedged FFI call has no such promise — without this the
      // turn waits forever on it. Deliberately generous: the point is that
      // "forever" stops being reachable, not to police slow tools.
      toolTimeout: const Duration(minutes: 30),
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
      // Snapshot compaction wraps the summarizer rather than replacing it.
      // Two things have to stay true: it must degrade to a summary when the
      // reader has no vision (rendering text nothing can look at is a deleted
      // conversation, not a degraded one), and overflow RECOVERY must not need
      // a model call — because on a forced compaction the call the summarizer
      // makes is the one that just overflowed.
      compactor: SnapcompactCompactor(
        fallback: DefaultHarnessCompactor(
          summarizer: LlmHarnessSummarizer(provider),
        ),
        modelId: qualifiedModel,
        readerHasVision: modelInfo?.supportsImageInput ?? false,
      ),
      // Persisted at every turn boundary, so the next run continues this
      // conversation rather than being told about it — and so a `checkpoint`
      // label survives a restart, which is the only way `rewind` means
      // anything across one.
      transcriptStore: deps.transcriptStore,
      transcriptKey: _transcriptKey,
      initialCheckpoints: _resumedCheckpoints,
    );
    final context = HarnessToolContext(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      spaceId: spaceId,
    );

    // ---- Resume ----
    // The conversation's real history, when one was persisted. This is the
    // difference between a resume and a re-tell: with it the model reads its
    // own earlier reasoning and the actual bytes its tools returned, instead
    // of a `<context>` summary describing them.
    final resumed = await _loadResumeTranscript();
    final history = <HarnessMessage>[...?resumed?.messages];
    // When history carries the context, the layered `<context>` block would
    // state it a second time — in a shorter, lossier form, directly before the
    // user's message, where the model weighs it most. So a resumed run sends
    // the user's words alone.
    final bareUserText = userText;
    final promptForRun =
        history.isEmpty || bareUserText == null || bareUserText.isEmpty
        ? effectivePrompt
        : bareUserText;

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
        history: history,
        userMessage: promptForRun,
        // A screenshot the human pasted rides the user turn alongside the
        // text, so the model sees the picture and the question together.
        userImages: await _loadPromptImages(),
        tools: tools,
        deferredTools: deferredTools,
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
                // The screenshot the model just looked at, kept for the human
                // watching. Stored as blob refs, never inline base64.
                images: await _externalizeToolImages(result.images),
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
          case LoopToolsActivated(:final names, :final trigger):
            // The search → activate → call funnel, in the run's own log. A
            // search that activates nothing is a retrieval miss, and a miss is
            // otherwise invisible: the agent just does something adjacent and
            // plausible instead of saying it could not find the tool.
            _activatedToolNames.addAll(names);
            addEvent(
              DebugEvent(
                content:
                    '[harness] loaded ${names.length} deferred tool'
                    '${names.length == 1 ? '' : 's'} via $trigger: '
                    '${names.join(', ')}',
              ),
            );
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
      // A worker never outlives the mode. A background agent still editing
      // files after the conversation that started it has moved on is the one
      // failure this feature cannot have.
      // A kernel is a shell that remembers: one still holding a process after
      // the run ended is exactly the leak the enclosure rules exist for.
      for (final kernel in _kernels.values) {
        unawaited(kernel.dispose());
      }
      _kernels.clear();
      final killed = _vibeRoster?.killAll() ?? 0;
      if (killed > 0) {
        addEvent(
          TextEvent(content: '\n[vibe] stopped $killed worker(s) on exit.\n'),
        );
      }
      _vibeRoster = null;
      addEvent(DoneEvent());
      _completeRun();
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

  /// Checkpoint labels restored from the persisted transcript, as indices into
  /// the history this run seeded.
  Map<String, int> _resumedCheckpoints = const {};

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

  /// Loads and trims the persisted history for this conversation.
  ///
  /// Trimmed rather than restored whole: a resumed run pays for every message
  /// it carries on EVERY turn, and the tail is where the work is. The trim cuts
  /// at a message boundary that is not an orphaned tool result, because a
  /// `tool_result` whose `tool_use` was dropped is a request no provider
  /// accepts — a transcript that cannot be sent is worse than a short one.
  Future<HarnessTranscript?> _loadResumeTranscript() async {
    final store = deps.transcriptStore;
    final key = _transcriptKey;
    if (store == null || key == null) {
      return null;
    }
    try {
      final loaded = await store.load(key);
      if (loaded == null || loaded.messages.isEmpty) {
        return null;
      }
      final trimmed = trimTranscriptForResume(loaded);
      _resumedCheckpoints = trimmed.checkpoints;
      return trimmed;
    } on Object catch (e) {
      CcInfraLog.warning('transcript resume failed: $e');
      return null;
    }
  }

  /// The stronger of two efforts, treating null as "unset".
  ///
  /// A magic keyword may only RAISE: `ultrathink` on an agent already
  /// configured for maximum reasoning must be a no-op, never a downgrade.
  static ReasoningEffort? _raiseEffort(
    ReasoningEffort? configured,
    ReasoningEffort? requested,
  ) {
    if (requested == null) {
      return configured;
    }
    if (configured == null) {
      return requested;
    }
    return requested.index > configured.index ? requested : configured;
  }

  /// Loads the human's attached images from the blob store as harness image
  /// blocks, so a pasted screenshot reaches the model on the user turn.
  ///
  /// Best-effort, and deliberately so: an image that cannot be read is dropped
  /// and the prompt still runs. The text the person typed is the message; the
  /// picture is context, and losing the whole turn over a missing blob would
  /// be a worse trade than answering without it.
  Future<List<HarnessImageBlock>> _loadPromptImages() async {
    final store = deps.blobStore;
    final ws = workspaceId;
    if (store == null || ws == null || ws.isEmpty || promptImageRefs.isEmpty) {
      return const [];
    }
    final blocks = <HarnessImageBlock>[];
    for (final ref in promptImageRefs) {
      final hash = blobHashOf(ref);
      if (hash == null) {
        continue;
      }
      try {
        final bytes = await store.read(ws, hash);
        if (bytes == null || bytes.isEmpty) {
          continue;
        }
        blocks.add(
          HarnessImageBlock(
            data: base64Encode(bytes),
            mediaType: await store.mediaTypeFor(ws, hash),
          ),
        );
      } on Object catch (e) {
        CcInfraLog.warning('Failed to load prompt image $ref: $e');
      }
    }
    return blocks;
  }

  /// Moves a tool result's images into the blob store and returns their
  /// references, so the transcript carries pointers instead of base64.
  ///
  /// Best-effort by design: an image that fails to store is dropped rather than
  /// failing the tool call. The model already has the picture (it travelled on
  /// the provider wire); losing the transcript copy costs the human a preview,
  /// while throwing here would cost the run its result.
  Future<List<ToolImageRef>> _externalizeToolImages(
    List<HarnessImageBlock> images,
  ) async {
    final store = deps.blobStore;
    // A blob is workspace-scoped storage, so a run with no workspace has
    // nowhere isolated to put one. That is a real state (bare test harnesses),
    // and dropping the preview beats writing outside the isolation boundary.
    final ws = workspaceId;
    if (store == null || ws == null || ws.isEmpty || images.isEmpty) {
      return const [];
    }
    final refs = <ToolImageRef>[];
    for (final image in images) {
      try {
        final stored = await store.putBase64(
          ws,
          image.data,
          mediaType: image.mediaType,
        );
        if (stored != null) {
          refs.add(
            ToolImageRef(
              ref: stored.ref,
              mediaType: stored.mediaType,
              bytes: stored.bytes,
            ),
          );
        }
      } on Object catch (e) {
        CcInfraLog.warning('Failed to store tool-result image: $e');
      }
    }
    return refs;
  }

  /// Builds the base harness tool registry (built-in filesystem/command tools
  /// first, then bridged CC MCP tools) for a given [mode]/[caps]/[env]. The
  /// `task` tool is NOT added here — the top-level run adds it explicitly and
  /// subagents deliberately omit it so nesting is capped at one level.
  HarnessToolRegistry _buildHarnessRegistry({
    required Mode mode,
    required AgentCapabilities caps,
    required Map<String, String> env,
  }) {
    // The `eval` bridge resolves tools against the registry being built, which
    // is why this is a block: a cell's `tool(...)` call must hit the SAME
    // registry a model-issued call does, wrappers and guardrails included.
    late final HarnessToolRegistry registry;
    registry = buildHarnessToolRegistry(
      mode: mode,
      caps: caps,
      env: env,
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      sandboxManager: deps.sandboxManager,
      confirmationPort: deps.confirmationPort,
      execGrantService: deps.execGrantService,
      // The operator's own `commandPrefix` rules reach the bash gate through
      // this — before it, they were stored, resolvable, editable in the
      // what-if probe, and never consulted at runtime.
      actionGuard: deps.actionGuard,
      fileSearch: deps.fileSearch,
      mcpRegistry: deps.mcpRegistry,
      protectedPaths: _protectedPaths,
      // `ask_user` renders into the run's SPACE (where the human is watching),
      // never its conversation id — the same distinction the MCP bridge draws
      // when it injects `space_id`.
      agentQuestionPort: deps.agentQuestionPort,
      spaceId: spaceId,
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
          return (content: 'Unknown tool: \$name', isError: true);
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
            'levels and this request would be level $depth.',
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
    // A file-defined agent resolves to a profile that only NARROWS its base:
    // extra prompt, tighter tool list, its own model. The tier ceiling above
    // is still checked against `req.type`, which is the base — so a definition
    // on disk can never buy reach the built-ins do not already grant.
    final custom = (await _subagentCatalog()).customFor(req.typeName);
    final subProfile = custom?.resolve() ?? subagentProfileFor(req.type);
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
    // may have moved it off the parent's) and `baseSystemPrompt` is passed
    // through unchanged so profile addenda never stack down the chain.
    final canSpawn = depth < maxSubagentDepth;
    if (canSpawn) {
      childRegistry.register(
        TaskTool(
          catalog: await _subagentCatalog(),
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
    // Tier filter first (the ceiling), then the definition's own allowlist —
    // an intersection, never a union, so a file can only take tools away.
    final childAdmitted = custom != null
        ? custom.filterTools(childRegistry.toolsFor(subProfile.surface))
        : subProfile.filterTools(childRegistry.toolsFor(subProfile.surface));
    // Children inherit the two-tier surface. A subagent is where the surplus
    // hurts most: it runs on one narrow task, so nearly the whole catalogue is
    // noise for it — and its resident prefix, being identical across every
    // child of the same profile, is the one the provider's cache reuses best.
    final childPartition = materializeHarnessToolSurface(
      registry: HarnessToolRegistry.of(childAdmitted),
      surface: const ToolSurfaceSpec.unrestricted(),
      residency: _childResidency(enabled: deps.toolDeferralEnabled),
    );
    final childTools = childPartition.resident;
    final childDeferredTools = childPartition.deferred;

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
      // Kernel-level ceiling on ONE tool call. The tools that own a process
      // self-limit (bash clamps its model-supplied timeout), but a bridged
      // MCP tool or a wedged FFI call has no such promise — without this the
      // turn waits forever on it. Deliberately generous: the point is that
      // "forever" stops being reachable, not to police slow tools.
      toolTimeout: const Duration(minutes: 30),
      approvalCallback: approval,
      autoApprove: false,
      // A child is already running inside the parent's fan-out, so its own
      // waves stay narrower than the top level's: nesting multiplies and the
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
      spaceId: spaceId,
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

    // Children of the same shape share a prompt prefix byte for byte, so only
    // ONE of them should pay to write it. Siblings launched in the same instant
    // would each miss and each pay the write premium — the whole point of the
    // shared prefix, lost precisely when the fan-out is widest. The first
    // child through becomes the pilot; the rest wait for it to start streaming
    // (bounded) and then read what it wrote.
    final pilotKey =
        '${subProfile.type.name}|$childProviderId|'
        '${childModel ?? childProvider.defaultModel}';
    final existingPilot = _subagentPilots[pilotKey];
    Completer<void>? ownedPilot;
    if (existingPilot == null) {
      ownedPilot = Completer<void>();
      _subagentPilots[pilotKey] = ownedPilot;
    } else {
      // A slow pilot must cost a cache hit, never the fan-out: on timeout this
      // child simply proceeds and writes its own entry.
      await existingPilot.future
          .timeout(_subagentPilotWait)
          .catchError((Object _) {});
    }
    // Released whichever way this child leaves, so a crashed pilot never
    // strands its siblings for the whole timeout.
    void releasePilot() {
      if (ownedPilot != null && !ownedPilot.isCompleted) {
        ownedPilot.complete();
      }
      if (identical(_subagentPilots[pilotKey], ownedPilot)) {
        _subagentPilots.remove(pilotKey);
      }
    }

    try {
      await for (final event in deps.agentLoop.run(
        history: <HarnessMessage>[],
        userMessage: req.description,
        tools: childTools,
        deferredTools: childDeferredTools,
        provider: childProvider,
        context: childContext,
        config: config,
        cancel: _cancelSource.token,
      )) {
        // The first event means the provider began responding, which is the
        // moment its cache entry becomes readable — so this is exactly when
        // the siblings should be let go, not when the child finishes.
        releasePilot();
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
                // A subagent's screenshots belong in ITS activity timeline the
                // same way — the child run is what the human opens to see what
                // the delegate actually did.
                images: await _externalizeToolImages(result.images),
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
    } finally {
      // A pilot that dies before its first event must not hold its siblings
      // for the whole timeout.
      releasePilot();
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
  /// A space dispatch hands us `<context>…</context>\n\n$userText`. When a
  /// slash command is stripped we must put the remaining text back *in place*
  /// — using the bare args as the whole prompt would silently discard the
  /// agent's identity, memory and conversation context. Falls back to the
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
          // is generated from plan mode's profile + materialized tool list and
          // the mode prompt block carries the authoring guidance. A hand-written
          // directive here would be a second, drift-prone copy — the previous
          // one was the ONLY place `submit_plan` was ever named and it was
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
              'is bounded by its cost budget and a repetition guard steers '
              'you if you start looping, so spend turns on real progress. '
              'Checkpoint relentlessly (commit work, write notes and memory, '
              'update tickets) because every segment starts from durable '
              'state. Decompose large goals into tickets or plan nodes '
              'instead of one monolithic run.\n\n'
              // The audit is what stops the expensive failure: an autonomous
              // loop that decides it is done, reports success and stops,
              // while the thing it was asked to do does not work.
              '$goalCompletionAudit',
          notice: 'goal mode',
        );
      case 'vibe':
        // A DIRECTIVE plus a tool swap, not a persisted space mode: vibe is a
        // property of one run (the human said `/vibe` on this message), not of
        // the conversation, and persisting it would leave the next message
        // silently unable to edit anything.
        _vibeRoster = VibeRoster();
        return (
          mode: null,
          userTextOverride: body,
          maxTurns: null,
          directive: vibeDirectorPrompt,
          notice: 'vibe mode',
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
              'is bounded by its cost budget and a repetition guard steers '
              'you if you start cycling without progress. When it is fully '
              'complete, declare completion with the complete_goal MCP tool, '
              'passing a summary of what was achieved.\n\n'
              '$goalCompletionAudit',
          notice: 'loop mode',
        );
      default:
        // A user-authored slash command comes FIRST: it is a shortcut the
        // human invoked deliberately, with arguments, so it should win over a
        // skill that merely happens to share the name. Its body is expanded
        // with whatever followed the command.
        final command = await _loadUserCommand(name);
        if (command != null) {
          return (
            mode: null,
            userTextOverride: command.render(cmd.args),
            maxTurns: null,
            // No wrapper directive: the command body IS the instruction, and
            // wrapping it would put the author's words behind ours.
            directive: null,
            notice: 'command: $name',
          );
        }
        // Skills live under `/skill:<name>` (or `/skill:<repo>:<name>`) so they
        // share no namespace with the builtins above — without that, a skill
        // called `plan` or `compact` is silently unreachable forever.
        final skillName = skillNameFor(name);
        final skill = skillName == null
            ? null
            : await _loadSkillBody(skillName);
        if (skill != null) {
          return (
            mode: null,
            userTextOverride: body ?? 'Apply the "$skillName" skill.',
            maxTurns: null,
            directive:
                'The user invoked the "$skillName" skill. Follow these '
                'instructions:\n\n$skill',
            notice: 'skill: $skillName',
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

  /// The subagent types this run may spawn: the built-ins plus whatever agent
  /// definitions the workspace and the agent's config dir declare.
  ///
  /// Scanned once per session and memoized — the `task` tool's schema is built
  /// from it, and re-reading the directory on every spawn would put a
  /// filesystem walk on the delegation path.
  Future<SubagentCatalog> _subagentCatalog() async {
    final cached = _catalogMemo;
    if (cached != null) {
      return cached;
    }
    try {
      final agents = await const HarnessAgentScanner().scan([
        agentDirHostPath,
        agentConfigDir,
      ]);
      return _catalogMemo = SubagentCatalog(custom: agents);
    } on Object catch (e) {
      CcInfraLog.warning('Failed to scan agent definitions: $e');
      return _catalogMemo = const SubagentCatalog();
    }
  }

  SubagentCatalog? _catalogMemo;

  /// Finds a user-authored slash command by name, or null.
  ///
  /// Searched in the same bases as skills, project before home, so a repo can
  /// override a personal command.
  Future<HarnessCommandInfo?> _loadUserCommand(String name) async {
    try {
      final commands = await const HarnessCommandScanner().scan([
        agentDirHostPath,
        agentConfigDir,
      ]);
      for (final command in commands) {
        if (command.name == name.toLowerCase()) {
          return command;
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('Failed to scan slash commands: $e');
    }
    return null;
  }

  /// Reads a skill's `SKILL.md` body (frontmatter stripped) by name, or null
  /// when no such skill exists.
  ///
  /// Scans the same bases and follows the same links as the index in the system
  /// prompt: a `/name` the agent was told about has to resolve, or the command
  /// silently falls through to plain text.
  Future<String?> _loadSkillBody(String name) async {
    try {
      final skills = await const HarnessSkillScanner().scan([
        agentConfigDir,
        agentDirHostPath,
      ], permittedLinkRoots: _permittedLinkRoots());
      for (final s in skills) {
        if (s.name == name) {
          return _stripFrontmatter(await File(s.path).readAsString());
        }
      }
      // Not in what the agent carries — try ANY repo in the space. The agent
      // only ever holds the repo it is working in, because an always-loaded
      // index costs context on every turn and a sibling service's skill is
      // actively misleading. A human naming one is a single explicit act with
      // no such cost, so the composer is not held to that scoping.
      final entry = await _repoProjector?.catalog.resolve(name);
      if (entry != null) {
        return _stripFrontmatter(await File(entry.path).readAsString());
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
        if (rotation.isNotEmpty && primaryCredential != null) {
          final leadsPool = _sameCredential(rotation.first, primaryCredential);
          if (!leadsPool) {
            leadCredential = rotation.first;
          }
        }
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

  /// Orders [stored] according to the workspace's pool for [providerId].
  ///
  /// Returns the list unchanged when no resolver is wired or the pool is
  /// unconfigured — which is what keeps every existing install on the exact
  /// chain it had before pools existed. The resolver is the ONLY thing that
  /// knows about workspaces, strategies and cooldowns; this layer just spends
  /// the order it is given.
  Future<List<ProviderCredential>> _orderRotation(
    String providerId,
    List<ProviderCredential> stored,
  ) async {
    final resolve = onResolveHarnessRotation;
    if (resolve == null || stored.length < 2) {
      return stored;
    }
    final order = await resolve(
      workspaceId: workspaceId,
      agentId: agentId,
      providerId: providerId,
      credentialIds: [for (final c in stored) c.credentialId],
    );
    if (order == null || order.isEmpty) {
      return stored;
    }
    final byId = {for (final c in stored) c.credentialId: c};
    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
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

  /// Parks this run until this account's directory holds a credential again,
  /// and reports whether it does.
  ///
  /// False when no gate is wired, when the operator cancels, or when the wait
  /// times out — every one of which falls through to the failure the run had
  /// before the gate existed.
  Future<bool> _gateOnClaudeSignIn({required String detail}) async {
    final gate = deps.credentialGate;
    if (gate == null) {
      return false;
    }
    addEvent(
      DebugEvent(
        content:
            '[claude] waiting for a sign-in on $claudeConfigDir — '
            'the run continues as soon as one lands.',
      ),
    );
    final outcome = await gate.awaitCredentials(
      RunCredentialBlockRequest(
        lane: RunCredentialLane.claudeCode,
        reason: RunCredentialReason.signedOut,
        detail: detail,
        runLogId: runLogId,
        accountIds: [for (final a in claudeAccounts) a.accountId],
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        agentName: agentName,
      ),
      // The credential lands as a FILE in the account directory — written
      // directly by the CLI off macOS or by an in-sandbox refresh, and mirrored
      // there from the Keychain otherwise. The mirror has to be re-run for the
      // Keychain case; without it the probe would watch a file that a
      // successful `claude auth login` never touches.
      recheck: () async {
        final sync = deps.syncClaudeCredential;
        final accountId = claudeAccounts.firstOrNull?.accountId;
        if (sync != null && accountId != null) {
          await sync(accountId);
        }
        return _claudeAccountHasCredential();
      },
    );
    return outcome == RunCredentialOutcome.resolved;
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
  /// persona, workspace context and task are carried in [prompt] (assembled by
  /// the dispatch pipeline) and delivered as the user message; this is the
  /// stable operating brief that belongs in the system prompt.
  Future<String> _harnessSystemPrompt(String wsId) async {
    final parts = await const HarnessSystemPromptBuilder().build(
      workspaceId: wsId,
      workingDirectory: agentDirHostPath,
      agentConfigDir: agentConfigDir,
      coAuthorTrailer: _coAuthorTrailer,
      permittedLinkRoots: _permittedLinkRoots(),
      onWarning: CcInfraLog.warning,
    );
    return parts.assemble();
  }

  /// Builds the merged environment for a dispatch. Precedence (later wins):
  /// git identity → caller → broker → backend default → per-adapter override
  /// → capability, with the broker env re-asserted last.
  ///
  /// The per-run git author/committer identity sits FIRST so an explicit
  /// caller-provided identity wins (and [_prepareRunIdentity] already dropped
  /// any key the caller set). The run's GitHub credential is ONLY ever the
  /// broker's (a repo-scoped App installation token, or its environment
  /// fallback) — never the requesting member's own token, so nothing an agent
  /// does on the forge is authored as the human who asked for the run.
  Map<String, String> _mergedEnv({
    required AgentCapabilities caps,
    required Map<String, String> scopedEnv,
    required Map<String, String> backendEnv,
  }) {
    final merged = <String, String>{
      ..._gitIdentityEnv,
      ...callerEnv,
      ...scopedEnv,
      ...backendEnv,
      ...adapterEnvOverride,
      ...capabilityEnv(caps),
      if (wakeContext != null) ...wakeContext!.toEnvironment(),
      'CC_DISABLE_PROJECT_CONFIG': 'true',
      'OPENCODE_DISABLE_PROJECT_CONFIG': 'true',
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
    return merged;
  }

  /// Whether the Claude Code account this run will use has something to
  /// authenticate with.
  ///
  /// Only answerable when Control Center owns the config dir; with none set the
  /// CLI resolves its own credential (a keychain item, `~/.claude`) and this
  /// returns true rather than guessing. A token in the environment counts:
  /// `CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY` both authenticate the
  /// CLI without any file in the config dir, so treating an empty dir as
  /// signed-out would refuse a run that would have worked.
  bool _claudeAccountHasCredential() {
    final dir = claudeConfigDir;
    if (dir == null || dir.isEmpty) {
      return true;
    }
    for (final key in const ['CLAUDE_CODE_OAUTH_TOKEN', 'ANTHROPIC_API_KEY']) {
      final fromCaller = callerEnv[key] ?? adapterEnvOverride[key];
      if (fromCaller != null && fromCaller.isNotEmpty) {
        return true;
      }
      final fromHost = Platform.environment[key];
      if (fromHost != null && fromHost.isNotEmpty) {
        return true;
      }
    }
    return File('$dir/.credentials.json').existsSync();
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
      runnerStateDirs: _runnerStateDirs,
      execGrantRoots: await _resolveExecGrantRoots(wsId),
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
            spaceId: spaceId ?? '',
            workspaceId: workspaceId,
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
  /// pure read-only flag and plan mode blocks edits); `chat` uses the default.
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

    final spent = claudeAccountsSpent;
    if (spent != null) {
      // Refuse before spawning. Claude would reach the same conclusion and
      // charge a turn for it; the useful part is the time, not the failure.
      //
      // Reaching here means the credential gate is off, was declined, or ran
      // out of patience — the gate itself runs one layer up, in
      // `AgentDispatchService`, where the account plan can still be re-resolved
      // before the sandbox profile is built from it. This is the terminal
      // report, and it shares its sentence with what the gate showed.
      addEvent(ErrorEvent(content: claudeRefusalDetail(spent)));
      unawaited(_closeRunLog(exitCode: 126));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    if (!_claudeAccountHasCredential()) {
      // Fail here rather than let the CLI do it. Spawned logged-out, `claude
      // -p` prints `Not logged in · Please run /login` on stdout and exits 0 —
      // so the turn "succeeds", the sentence lands in the transcript looking
      // like something the agent said, and the operator is told to run a slash
      // command in a CLI they never opened. Naming the account and where to
      // sign it in is the whole difference.
      final detail =
          '[claude] this Claude Code account is signed out '
          '($claudeConfigDir). Sign in from Settings → Adapters → '
          'Claude Code, or run `claude auth login` with '
          'CLAUDE_CONFIG_DIR set to that directory.';
      // Signed-out is the one Claude verdict this session can gate itself: the
      // account is already resolved, so its directory is in the sandbox's
      // writable set and a `claude auth login` into that SAME directory lands
      // somewhere the run can already read. Nothing has to be re-resolved, so
      // nothing about the profile can be stale. The spent case above is the
      // opposite — no account was resolved at all — which is why it is gated
      // one layer up instead.
      if (!await _gateOnClaudeSignIn(detail: detail)) {
        addEvent(ErrorEvent(content: detail));
        unawaited(_closeRunLog(exitCode: 126));
        addEvent(DoneEvent());
        _completeRun();
        return;
      }
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
        runnerStateDirs: _runnerStateDirs,
        execGrantRoots: await _resolveExecGrantRoots(wsId),
      ),
      emit: addEvent,
    );

    if (handle.state == SandboxState.error) {
      // Destroy before throwing: the handle is already registered in the
      // adapter's map, and the throw skips the cooldown scheduling that would
      // otherwise clean it up — so an error-state handle (plus its broadcast
      // controller) was retained until a same-session re-dispatch.
      try {
        await deps.sandbox.destroy(handle);
      } on Object catch (e) {
        CcInfraLog.warning(
          'dispatch $dispatchId: destroy after launch '
          'failure also failed: $e',
        );
      }
      throw StateError('sandbox launch failed: ${handle.error}');
    }

    _activeHandle = handle;
    eventsSub = deps.sandbox.events(handle).listen(_forwardSandboxEvent);

    final argv = <String>[claudePath, ...claudeFlags, ...adapterArgsOverride];

    // Preflight the claude invocation (NOT the prompt — it's free-form text
    // that could contain shell operators). The agent's own Bash commands are
    // checked by Claude's own permission layer.
    if (!await _preflightCommand(argv)) {
      return;
    }

    final mergedEnv = _mergedEnv(
      caps: caps,
      scopedEnv: scoped.environment,
      backendEnv: const {},
    );

    // One attempt per attached account, best first. A `claude -p` process owns
    // its own credential, so there is no swapping it mid-stream the way the
    // harness does — a plan that runs out can only be answered by running the
    // turn again on the next account. That is what lets a `/goal` carry on
    // across a usage limit instead of stopping at one.
    final attempts = claudeAccounts.isEmpty
        ? <({String accountId, String configDir})>[
            (accountId: '', configDir: claudeConfigDir ?? ''),
          ]
        : claudeAccounts;

    var exitCode = 0;
    // Whether the attempt that ended the loop already explained itself, so the
    // trailing exit-code line does not repeat it. See [_sawProcessStderr].
    var explained = false;
    for (var i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      ClaudeTerminalError? terminal;
      var producedOutput = false;

      _claudeToolNames.clear();
      _claudeParser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(
          onText: (delta) {
            producedOutput = true;
            addEvent(TextEvent(content: delta));
          },
          onThinking: (delta) => addEvent(ThinkingEvent(content: delta)),
          onToolCall: (tu) {
            producedOutput = true;
            _claudeToolNames[tu.id] = tu.name;
            addEvent(
              ToolCallEvent(
                toolName: tu.name,
                toolCallId: tu.id,
                inputs: tu.input as Map<String, dynamic>?,
              ),
            );
          },
          onToolResult: (tr) => addEvent(
            ToolResultEvent(
              toolCallId: tr.id,
              outputs: tr.outputs,
              toolName: _claudeToolNames.remove(tr.id),
              isError: tr.isError,
            ),
          ),
          // `claude` prices itself, so this path does NOT go through
          // [HarnessCostCalculator]: the CLI already knows which model served
          // (including the auxiliary calls it makes on its own) and reports the
          // total, where a models.dev lookup would have to guess. Deliberately
          // NOT gated on `producedOutput` — usage is accounting, not output, and
          // an attempt that spent tokens and then failed over to the next
          // account must still be counted. The accumulator downstream sums
          // per-attempt events, which is what makes that add up.
          onUsage: (u) => addEvent(
            UsageEvent(
              usage: RunUsage(
                inputTokens: u.inputTokens,
                outputTokens: u.outputTokens,
                cachedReadTokens: u.cacheReadTokens,
                cachedWriteTokens: u.cacheWriteTokens,
                estimatedCostCents: u.costCents,
              ),
              durationMs: u.durationMs,
            ),
          ),
          // Held, not emitted: a capacity failure we are about to retry is not
          // something to show as an error, and the decision needs the exit code
          // that has not arrived yet.
          onTerminalError: (e) => terminal = e,
        ),
      );

      addEvent(DebugEvent(content: '[claude] launching claude -p…'));
      _sawProcessStderr = false;
      exitCode = await deps.sandbox.exec(
        handle,
        argv,
        env: {
          ...mergedEnv,
          if (attempt.configDir.isNotEmpty)
            'CLAUDE_CONFIG_DIR': attempt.configDir,
        },
        onPid: (forkedPid) {
          _onPidAvailable(forkedPid);
          addEvent(
            DebugEvent(content: '[claude] claude running (pid $forkedPid)'),
          );
        },
        stdinInput: prompt,
      );
      _claudeParser = null;

      final failure = terminal;
      final hasNext = i + 1 < attempts.length;
      // Is this failure about the ACCOUNT rather than the run? Two shapes
      // qualify — a spent plan and a credential that no longer authenticates —
      // and only those retry. Any other terminal error (a bad model id, a
      // rejected MCP config) would fail identically on every account, and a
      // turn that already streamed work would be duplicated by a re-run rather
      // than continued.
      final accountFailure =
          failure != null && (failure.isCapacity || failure.isAuth);
      if (accountFailure && !producedOutput && hasNext) {
        if (attempt.accountId.isNotEmpty) {
          await _reportClaudeAccountFailure(attempt.accountId, failure);
        }
        final next = attempts[i + 1];
        // Same shape as the harness's `[harness] provider fallback X → Y`,
        // deliberately: one vocabulary for "the run moved to another
        // credential", whichever transport moved it.
        addEvent(
          DebugEvent(
            content:
                '[claude] account fallback ${attempt.accountId} → '
                '${next.accountId} '
                '(${failure.isCapacity ? 'out of plan headroom' : 'credential expired'})',
          ),
        );
        continue;
      }
      if (failure != null) {
        if (accountFailure && attempt.accountId.isNotEmpty) {
          // Last account, or the turn had already produced work: record the
          // failure anyway so the NEXT dispatch starts somewhere usable.
          await _reportClaudeAccountFailure(attempt.accountId, failure);
        }
        addEvent(
          ErrorEvent(content: redactSecrets('[claude] ${failure.message}')),
        );
        explained = true;
      }
      break;
    }

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
      final content = '[claude] claude exited with code $exitCode';
      addEvent(
        explained || _sawProcessStderr
            ? DebugEvent(content: content)
            : ErrorEvent(content: content),
      );
    } else {
      addEvent(DebugEvent(content: '[claude] claude exited cleanly (code 0)'));
    }
    addEvent(DoneEvent());
    _completeRun();
  }

  /// Reports an account-scoped Claude Code failure to the host so the NEXT
  /// dispatch does not lead with an account this one just proved unusable.
  ///
  /// The two lanes are deliberately not merged. A spent plan is temporary and
  /// self-healing, so it becomes a cooldown that expires. An expired
  /// credential is neither — nothing but a human running `claude auth login`
  /// fixes it — so parking it as "rate limited until 30 minutes from now"
  /// would both lie in Settings and hand the account back to the rotation on a
  /// timer, to fail again every half hour.
  Future<void> _reportClaudeAccountFailure(
    String accountId,
    ClaudeTerminalError failure,
  ) async {
    if (failure.isCapacity) {
      await onClaudeAccountExhausted?.call(
        accountId: accountId,
        resetsAt: failure.resetsAt,
      );
      return;
    }
    await onClaudeAccountAuthFailed?.call(
      accountId: accountId,
      reason: redactSecrets(failure.message),
    );
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
  /// revoking credentials, cancelling event subscriptions and closing the
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
    // Actually stop the agent. `_failRun` only stamps the DB row; without this
    // the CLI kept running after "terminate", ignored by everything.
    await _killActiveProcess('terminate');
    // Close the run log too: it finalizes the DEBOUNCED `lastOutputAt` write
    // (otherwise the last timestamp dies in the debounce window) and writes the
    // NDJSON `end` record. Idempotent — the normal completion path calls it too.
    await _closeRunLog(error: 'terminated by user request');
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
        // "terminating" has to mean it: kill the child before stamping the
        // run, or the silent CLI keeps running (and holding its sandbox)
        // forever while the UI shows the run as failed.
        unawaited(() async {
          await _killActiveProcess('silence watchdog');
          // Finalizes the debounced `lastOutputAt` + writes the NDJSON `end`.
          await _closeRunLog(error: 'silent for ${threshold.inMinutes} min');
          _failRun(
            'Silent run (no output for '
            '${threshold.inMinutes} min)',
          );
          _closeController();
        }());
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
    switch (event.type) {
      case SandboxEventType.stdout:
        _tryParseStructuredOutput(event.content);
        break;
      case SandboxEventType.stderr:
        _sawProcessStderr = true;
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
        if (v != null) {
          unawaited(_maybeOfferExecGrant(v));
        }
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
        // that landed during startup) and never clobber a status something else
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
  /// output timestamp and logs the event for persistence.
  void addEvent(AgentProcessEvent event) {
    if (event is ToolCallEvent) {
      _observeRepoTouch(event);
    }
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
      final existing = await repo.getById(ws, id);
      if (existing == null) {
        return;
      }
      await repo.upsert(existing.copyWith(lastOutputAt: stamp));
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
    await _finalizeLastOutput();
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
/// Adapts a closure to [VibeWorkerRunner], so the roster tools stay free of
/// the dispatch layer exactly as `task` does.
class _ClosureVibeRunner implements VibeWorkerRunner {
  _ClosureVibeRunner(this._run);

  final Future<SubagentResult> Function(
    VibeWorker worker,
    String brief,
    HarnessToolContext context,
    SubagentType type,
    String? modelOverride,
  )
  _run;

  @override
  Future<SubagentResult> run({
    required VibeWorker worker,
    required String brief,
    required HarnessToolContext context,
    required SubagentType type,
    String? modelOverride,
  }) => _run(worker, brief, context, type, modelOverride);
}

class _ClosureSubagentSpawner implements SubagentSpawner {
  _ClosureSubagentSpawner(this._run);

  final Future<SubagentResult> Function(SubagentSpawnRequest request) _run;

  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) => _run(request);
}
