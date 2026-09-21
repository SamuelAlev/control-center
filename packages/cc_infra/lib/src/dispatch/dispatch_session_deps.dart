import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
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
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart' show FileSearchPort;
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/harness/ast_parser_provider.dart';
import 'package:cc_infra/src/harness/cc_natives_file_search_port.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';

/// Shared dependencies for a `DispatchSession`.
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
  /// per dispatch and switches on its transport (acp / claudeCli / harness).
  final BackendRegistry backendRegistry;

  /// The process-wide [SandboxManager] used to wrap the ACP transport through
  /// the OS sandbox. Null when the backend is `none` (opt-out / unsupported) —
  /// ACP then spawns bare but still gets env sanitization + universal command
  /// preflight. The claudeCli transport sandboxes through
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
  /// `browser_use` / `computer_use` / `mobile_use` / `ios_use`, rendered output).
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
  /// loop resolves each tool's declared `HarnessTool.actionClasses` against the
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
  final Future<({String name, String email})?> Function(
    String? userId, {
    String? workspaceId,
  })?
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
