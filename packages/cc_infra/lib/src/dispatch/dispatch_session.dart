import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:cc_infra/src/sandboxing/claude_relay.dart';
import 'package:cc_infra/src/sandboxing/env_sanitizer.dart';
import 'package:cc_infra/src/sandboxing/run_log_writer.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';

import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
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
    this.claudeRelayFactory = ClaudeRelay.new,
    this.mcpConfigPathResolver,
    this.sandboxManager,
    this.confirmationPort,
  });

  /// OS-level sandbox used to run sandboxed CLI adapters (e.g. Pi).
  final SandboxPort sandbox;

  /// Credential broker that mints per-run scoped tokens.
  final CredentialBrokerPort broker;

  /// Agent repository (capability lookup).
  final AgentRepository agentRepo;

  /// Optional run-log repository.
  final AgentRunLogRepository? runLogRepo;

  /// Default capabilities when an agent has none.
  final AgentCapabilities defaultCaps;

  /// Optional domain event bus.
  final DomainEventBus? eventBus;

  /// Factory for the Claude Code subscription relay (the claude-relay port). Used
  /// when the resolved adapter's CLI is `claude` — that path NEVER uses
  /// metered `claude -p`. Overridable for tests.
  final ClaudeRelay Function() claudeRelayFactory;

  /// Resolves the MCP config file path to point the spawned `claude` at the
  /// Control Center MCP server (`--mcp-config`), or null when unavailable.
  /// Injected at the composition root because the path is host-specific (the
  /// desktop resolves `mcpConfigFile()`; the headless server resolves its own),
  /// keeping this package free of `package:control_center`. When null the relay
  /// runs without `--mcp-config` (the agent sees no `mcp__*` tools).
  final Future<String?> Function()? mcpConfigPathResolver;

  /// Maps CLI names to their execution backend. The session resolves a backend
  /// per dispatch and switches on its transport (acp / structuredCli / relay).
  final BackendRegistry backendRegistry;

  /// The process-wide [SandboxManager] used to wrap relay + ACP transports
  /// through the OS sandbox. Null when the backend is `none` (opt-out /
  /// unsupported) — relay/acp then spawn bare but still get env sanitization
  /// + universal command preflight.
  final SandboxManager? sandboxManager;

  /// Optional [ConfirmationPort] for synchronous UAC approval of prompt-tier
  /// commands. When null, prompt decisions proceed with a warning (Phase 3.5
  /// degrades gracefully when no approver is wired).
  final ConfirmationPort? confirmationPort;
}

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
    required this.agentDirHostPath,
    required this.modelId,
    required this.callerEnv,
    required this.agentId,
    required this.workspaceId,
    required this.conversationId,
    required this.runLogId,
    required this.mode,
    this.ticketId,
    this.wakeContext,
    this.silenceTimeoutMinutes,
    this.effortLevel,
    this.adapterArgsOverride = const [],
    this.adapterEnvOverride = const {},
  });

  /// Per-agent silence-timeout override in minutes. When null the per-mode
  /// default applies.
  final int? silenceTimeoutMinutes;

  /// Shared sandbox and credential dependencies.
  final SandboxDispatchDeps deps;

  /// Resolves a sandbox handle for the session.
  final Future<SandboxHandle> Function({
    required String sessionId,
    required SandboxSpec spec,
    required void Function(AgentProcessEvent) emit,
  }) onResolveHandle;

  /// Called to schedule a cooldown period after the session ends.
  final void Function(String sessionId) onScheduleCooldown;

  /// Unique identifier for this dispatch.
  final String dispatchId;
  /// CLI binary name (e.g. `pi` or `claude`).
  final String cliName;
  /// Prompt text sent to the agent.
  final String prompt;
  /// Host-side path to the agent's working directory.
  final String agentDirHostPath;
  /// Optional model identifier to pass to the CLI.
  final String? modelId;
  /// Environment variables from the calling context.
  final Map<String, String> callerEnv;
  /// Optional agent identifier for capability lookup.
  final String? agentId;
  /// Optional workspace identifier.
  final String? workspaceId;
  /// Optional conversation identifier for scoped credential minting.
  final String? conversationId;
  /// Optional run-log identifier for persistent logging.
  final String? runLogId;
  /// Conversation mode (e.g. `plan` or `execute`).
  final ConversationMode mode;
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
  /// PID of the forked sandbox process, set once available.
  int? pid;

  /// Active Claude subscription relay, when [cliName] is `claude`. Held so the
  /// session can tear it down on terminate / silence timeout.
  ClaudeRelay? _claudeRelay;

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
  static const Map<ConversationMode, int> _perModeSilenceMinutes = {
    ConversationMode.chat: 15,
    ConversationMode.review: 10,
    ConversationMode.plan: 10,
    ConversationMode.orchestrate: 15,
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

  /// Prefix used when constructing sandbox session identifiers.
  static const String agentSessionPrefix = 'agent-';

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

  /// Starts the agent process and manages its lifecycle.
  ///
  /// Resolves the execution backend for [cliName] from the registry and
  /// switches on its transport: `relay` (claude-relay), `structuredCli`
  /// (sandboxed `pi --mode json`), or `acp` (JSON-RPC over stdio). An unknown
  /// cliName emits a clear error + DoneEvent and exits 127 — never throws.
  Future<void> run() async {
    try {
      final caps = await _capabilitiesFor(agentId);

      final scoped = await deps.broker.mint(
        conversationId: conversationId ?? 'unknown',
        capabilities: caps,
      );
      credHandle = scoped.handle;

      final wsId = workspaceId ?? '';
      final agentKey =
          (agentId != null && agentId!.isNotEmpty) ? agentId! : 'oneshot';
      final convKey = conversationId ?? 'no-conv';
      final sandboxSessionId =
          '$agentSessionPrefix$agentKey::$convKey::${mode.name}';


      await _openRunLog(caps: caps);

      final backend = deps.backendRegistry.backendFor(cliName);
      if (backend == null) {
        addEvent(ErrorEvent(
          content: '[sandbox] No execution backend for "$cliName". '
              'Install the CLI or pick a supported adapter in '
              'Settings → Adapters.',
        ));
        unawaited(_closeRunLog(exitCode: 127));
        addEvent(DoneEvent());
        _completeRun();
        return;
      }

      switch (backend.transport) {
        case AdapterTransport.relay:
          await _runClaudeRelay(
            caps: caps,
            scopedEnv: scoped.environment,
            scopedNotes: scoped.notes,
          );
        case AdapterTransport.structuredCli:
          await _runStructuredCli(
            caps: caps,
            scoped: scoped,
            sandboxSessionId: sandboxSessionId,
            wsId: wsId,
          );
        case AdapterTransport.acp:
          await _runAcp(
            caps: caps,
            scopedNotes: scoped.notes,
          );
      }
      onScheduleCooldown(sandboxSessionId);
    } on Object catch (e) {
      unawaited(_closeRunLog(error: e));
      addEvent(ErrorEvent(
        content: '[sandbox] dispatch failed: $e',
      ));
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

    final cliPath = await resolveBinaryPath(cliName);
    if (cliPath == null) {
      addEvent(ErrorEvent(
        content: '[sandbox] "$cliName" not found. Install it on your host '
            'or check Settings → Adapters for the detected path.',
      ));
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    final handle = await onResolveHandle(
      sessionId: sandboxSessionId,
      spec: SandboxSpec(
        sessionId: sandboxSessionId,
        workspaceId: wsId,
        agentId: agentId,
        bindMounts: [
          SandboxBindMount(
            hostPath: agentDirHostPath,
            guestPath: agentDirHostPath,
          ),
        ],
        guestWorkdir: agentDirHostPath,
        networkEnabled: caps.canAccessNetwork,
        mode: mode,
        capabilities: caps,
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
      ...adapterArgsOverride,
    ];

    if (!await _preflightCommand(argv)) return;
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
        addEvent(DebugEvent(
          content: '[sandbox] $cliName running (pid $forkedPid)',
        ));
      },
      stdinInput: prompt,
    );
    unawaited(_closeRunLog(exitCode: exitCode));

    if (exitCode == 127) {
      addEvent(ErrorEvent(
        content: '[sandbox] "$cliName" not found on PATH. Install it on your '
            'host or disable sandboxing in Settings → Sandboxing.',
      ));
    } else if (exitCode != 0) {
      addEvent(ErrorEvent(
        content: '[sandbox] $cliName exited with code $exitCode',
      ));
    } else {
      addEvent(DebugEvent(
        content: '[sandbox] $cliName exited cleanly (code 0)',
      ));
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

    final cliPath = await resolveBinaryPath(cliName);
    if (cliPath == null) {
      addEvent(ErrorEvent(
        content: '[acp] "$cliName" not found. Install it on your host '
            'or check Settings → Adapters for the detected path.',
      ));
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    final mcpConfigPath = await deps.mcpConfigPathResolver?.call();
    final argv = <String>[
      cliPath,
      if (backend.acpArgs != null && backend.acpArgs!.isNotEmpty)
        backend.acpArgs!,
      ...adapterArgsOverride,
    ];

    if (!await _preflightCommand(argv)) return;
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
        final config = await _buildSandboxConfig(caps, isPty: false);
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
    addEvent(DebugEvent(content: '[acp] $cliName running (pid ${process.pid})'));

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
      await client.close();
      _acpProcess?.kill();
      _acpProcess = null;
      addEvent(DoneEvent());
      _completeRun();
    }
  }

  /// Builds the merged environment for a dispatch. Precedence (later wins):
  /// caller → broker → backend default → per-adapter override → capability.
  Map<String, String> _mergedEnv({
    required AgentCapabilities caps,
    required Map<String, String> scopedEnv,
    required Map<String, String> backendEnv,
  }) =>
      <String, String>{
        ...callerEnv,
        ...scopedEnv,
        ...backendEnv,
        ...adapterEnvOverride,
        ...capabilityEnv(caps),
        if (wakeContext != null) ...wakeContext!.toEnvironment(),
        'CC_DISABLE_PROJECT_CONFIG': 'true',
        'OPENCODE_DISABLE_PROJECT_CONFIG': 'true',
      };

  /// Builds a [SandboxConfig] for the current dispatch using the policy
  /// resolver + config builder. Shared by the relay + ACP transports.
  Future<SandboxConfig> _buildSandboxConfig(
    AgentCapabilities caps, {
    bool isPty = false,
  }) async {
    final home = Platform.environment['HOME'] ?? '';
    final wsId = workspaceId ?? '';
    final agentKey =
        (agentId != null && agentId!.isNotEmpty) ? agentId! : 'oneshot';
    final convKey = conversationId ?? 'no-conv';
    final sessionId =
        '$agentSessionPrefix$agentKey::$convKey::${mode.name}';
    final spec = SandboxSpec(
      sessionId: sessionId,
      workspaceId: wsId,
      agentId: agentId,
      bindMounts: [
        SandboxBindMount(
          hostPath: agentDirHostPath,
          guestPath: agentDirHostPath,
        ),
      ],
      guestWorkdir: agentDirHostPath,
      networkEnabled: caps.canAccessNetwork,
      mode: mode,
      capabilities: caps,
    );
    final policy = const SandboxPolicyResolver().resolve(
      spec: spec,
      capabilities: caps,
      homeDir: home.isNotEmpty ? home : null,
      runDir: '$agentDirHostPath/.cc-runs/$sessionId',
      isPty: isPty,
    );
    return buildSandboxConfigFromPolicy(policy);
  }

  /// Universal command preflight (Phase 2.3). Evaluates the resolved
  /// command string against the mode's [CommandPolicy] before spawning.
  /// Returns `true` when the spawn should proceed, `false` when denied.
  /// `prompt` decisions log a warning and proceed (synchronous UAC wiring
  /// is Phase 3).
  Future<bool> _preflightCommand(List<String> argv) async {
    if (argv.isEmpty) return true;
    final command = argv.join(' ');
    final policy = commandPolicyForMode(mode);
    final decision = policy.evaluate(command);
    switch (decision) {
      case CommandDecision.allow:
        return true;
      case CommandDecision.deny:
        addEvent(ErrorEvent(
          content: '[sandbox] command denied by policy: $command',
        ));
        unawaited(_closeRunLog(exitCode: 126));
        addEvent(DoneEvent());
        _completeRun();
        return false;
      case CommandDecision.prompt:
        final port = deps.confirmationPort;
        if (port == null) {
          addEvent(ErrorEvent(
            content: '[sandbox] command requires approval but no approver '
                'is connected — denying: $command',
          ));
          unawaited(_closeRunLog(exitCode: 126));
          addEvent(DoneEvent());
          _completeRun();
          return false;
        }
        final approved = await port.requestApproval(ConfirmationRequest(
          conversationId: conversationId ?? '',
          title: 'Approve command',
          detail: 'An agent is about to run:',
          command: command,
          severity: ConfirmationSeverity.warning,
          kind: ConfirmationKind.command,
        ));
        if (!approved) {
          addEvent(ErrorEvent(
            content: '[sandbox] command denied by user: $command',
          ));
          unawaited(_closeRunLog(exitCode: 126));
          addEvent(DoneEvent());
          _completeRun();
          return false;
        }
        return true;
    }
  }

  /// Maps a [ConversationMode] to Claude Code's `--permission-mode`. `plan`
  /// keeps Claude in read-only/plan mode; `review` borrows it (Claude has no
  /// pure read-only flag, and plan mode blocks edits); `chat` uses the default.
  static String? _claudePermissionMode(ConversationMode mode) {
    switch (mode) {
      case ConversationMode.plan:
      case ConversationMode.review:
      case ConversationMode.orchestrate:
        // orchestrate is read-mostly like plan: research + propose only.
        return 'plan';
      case ConversationMode.chat:
        return null;
    }
  }

  /// Runs Claude Code through the claude-relay, translating its
  /// structured events into [AgentProcessEvent]s. Never uses `claude -p`.
  Future<void> _runClaudeRelay({
    required AgentCapabilities caps,
    required Map<String, String> scopedEnv,
    required List<String> scopedNotes,
  }) async {
    for (final note in scopedNotes) {
      addEvent(DebugEvent(
        content: '[claude-relay] $note',
      ));
    }

    final claudePath = await resolveBinaryPath('claude');
    if (claudePath == null) {
      addEvent(ErrorEvent(
        content: '[claude-relay] "claude" not found on PATH. Install Claude Code: '
            'https://docs.anthropic.com/en/docs/claude-code',
      ));
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    // Point the spawned `claude` at the Control Center MCP server explicitly.
    // Relying on the symlinked project `.mcp.json` alone leaves the agent with
    // zero `mcp__*` tools (Claude won't auto-load project MCP servers without
    // approval), so it can't call complete_ticket/fail_ticket and pipeline
    // steps that need structured output fail. The path is host-specific, so it
    // comes from the injected resolver (null → no --mcp-config).
    final mcpConfigPath = await deps.mcpConfigPathResolver?.call();
    final args = ClaudeRelay.buildClaudeArgs(
      modelId: modelId,
      permissionMode: _claudePermissionMode(mode),
      mcpConfigPath: mcpConfigPath,
    );

    // Preflight the claude invocation (NOT the prompt — it's free-form text
    // that could contain shell operators). The agent's own Bash commands are
    // checked by the Claude hook (Phase 4).
    if (!await _preflightCommand([claudePath, ...args])) return;
    final env = <String, String>{
      ...callerEnv,
      ...scopedEnv,
      ...capabilityEnv(caps),
      if (wakeContext != null) ...wakeContext!.toEnvironment(),
      'CC_DISABLE_PROJECT_CONFIG': 'true',
    };

    addEvent(DebugEvent(
      content: '[claude-relay] launching claude via subscription relay…',
    ));

    final relay = deps.claudeRelayFactory();
    _claudeRelay = relay;

    final callbacks = ClaudeRelayCallbacks(
      onText: (delta) => addEvent(TextEvent(content: delta)),
      onThinking: (delta) => addEvent(ThinkingEvent(content: delta)),
      onToolCall: (tu) => addEvent(ToolCallEvent(
        toolName: tu.name,
        toolCallId: tu.id,
        inputs: tu.input as Map<String, dynamic>?,
      )),
      onToolResult: (tr) => addEvent(ToolResultEvent(
        toolCallId: tr.toolUseId,
        outputs: tr.content,
        isError: tr.isError,
      )),
      onError: (m) => addEvent(ErrorEvent(content: m)),
      onDebug: (m) => addEvent(DebugEvent(content: m)),
      onPid: _onPidAvailable,
      onStatus: (status, waitingFor) {},
    );

    int exitCode;
    final manager = deps.sandboxManager;
    if (manager != null) {
      // Route through the OS sandbox. The relay proxy's dynamic loopback
      // port is covered by the PTY-only loopback allow in the profile.
      final config = await _buildSandboxConfig(caps, isPty: true);
      final wrap = await manager.wrap(
        config: config,
        argv: [claudePath, ...args, prompt],
        workingDirectory: agentDirHostPath,
      );
      exitCode = await relay.run(
        claudePath: claudePath,
        args: args,
        prompt: prompt,
        environment: {...env, ...wrap.environment},
        workingDirectory: agentDirHostPath,
        callbacks: callbacks,
        wrappedExecutable: wrap.executable,
        wrappedArgv: wrap.argv,
      );
    } else {
      CcInfraLog.warning(
        '[claude-relay] No native sandbox available; '
        'spawning claude with env sanitization only.',
      );
      exitCode = await relay.run(
        claudePath: claudePath,
        args: args,
        prompt: prompt,
        environment: env,
        workingDirectory: agentDirHostPath,
        callbacks: callbacks,
      );
    }
    _claudeRelay = null;
    unawaited(_closeRunLog(exitCode: exitCode));

    // 143 = relay torn down by user request / silence watchdog; not an error.
    if (exitCode != 0 && exitCode != 143) {
      addEvent(ErrorEvent(
        content: '[claude-relay] claude relay exited with code $exitCode',
      ));
    } else {
      addEvent(DebugEvent(
        content: '[claude-relay] claude relay finished (code $exitCode)',
      ));
    }
    addEvent(DoneEvent());
    _completeRun();
  }

  /// Gracefully stops the session by shutting down the relay, revoking
  /// credentials, and closing the event controller.
  Future<void> stop() async {
    _cancelSilenceWatchdog();
    unawaited(_claudeRelay?.shutdown());
    _claudeRelay = null;
    await _teardownAcp();
    final cred = credHandle;
    if (cred != null) {
      await deps.broker.revoke(cred);
      credHandle = null;
    }
    _closeController();
  }

  /// Forcefully terminates the session by stopping the relay, marking the
  /// run as failed, revoking credentials, cancelling event subscriptions,
  /// and closing the controller.
  Future<void> terminate() async {
    _cancelSilenceWatchdog();
    unawaited(_claudeRelay?.shutdown());
    _claudeRelay = null;
    await _teardownAcp();
    addEvent(DebugEvent(
      content: '[sandbox] dispatch $dispatchId terminated by request',
    ));
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
      if (last != null &&
          DateTime.now().difference(last) >= threshold) {
        _cancelSilenceWatchdog();
        addEvent(ErrorEvent(
          content: '[sandbox] Agent silent for '
              '${threshold.inMinutes} min — terminating',
        ));
        unawaited(_claudeRelay?.shutdown());
        _claudeRelay = null;
        _failRun('Silent run (no output for '
            '${threshold.inMinutes} min)');
      }
    });
  }

  void _forwardSandboxEvent(SandboxEvent event) {
    switch (event.type) {
      case SandboxEventType.stdout:
        _tryParseStructuredOutput(event.content);
        break;
      case SandboxEventType.stderr:
        addEvent(ErrorEvent(
          content: event.content,
        ));
        break;
      case SandboxEventType.exit:
        _completeRun();
        break;
      case SandboxEventType.killed:
        addEvent(ErrorEvent(
          content: event.content.isNotEmpty
              ? event.content
              : '[sandbox] killed',
        ));
        _completeRun();
        break;
      case SandboxEventType.starting:
        addEvent(DebugEvent(
          content: '[sandbox] booting sandbox session…',
        ));
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
        addEvent(SandboxViolationEvent(
          content: summary,
          action: v?.action,
          target: v?.target,
          suggestedCapability: v?.suggestedCapability,
        ));
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
          addEvent(TextEvent(
            content: delta,
          ));
        } else if (subType == 'thinking_delta') {
          addEvent(ThinkingEvent(
            content: delta,
          ));
        }
        break;
      case 'tool_execution_start':
        addEvent(ToolCallEvent(
          toolName: json['toolName'] as String? ?? '',
          toolCallId: json['toolCallId'] as String? ?? '',
          inputs: json['args'] as Map<String, dynamic>?,
        ));
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
              addEvent(ToolResultEvent(
                toolCallId: json['toolCallId'] as String? ?? '',
                outputs: text,
                toolName: json['toolName'] as String? ?? '',
                isPartial: true,
              ));
            }
          }
        }
        break;
      case 'tool_execution_end':
        final isError = json['isError'] as bool? ?? false;
        addEvent(ToolResultEvent(
          toolCallId: json['toolCallId'] as String? ?? '',
          outputs: json['result'] != null
              ? jsonEncode(json['result'])
              : json['toolName'] as String? ?? '',
          toolName: json['toolName'] as String? ?? '',
          isError: isError,
        ));
        break;
      case 'agent_end':
        addEvent(DoneEvent());
        break;
      default:
        break;
    }
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
  }

  void _updateRunLogPidAndStart(int forkedPid) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    if (id == null || repo == null) {
      return;
    }
    unawaited(() async {
      try {
        final existing = await repo.getById(id);
        if (existing == null) {
          _failRun('Run log $id missing when PID $forkedPid arrived');
          return;
        }
        await repo.upsert(
          existing.copyWith(
            pid: forkedPid,
            status: RunStatus.running,
          ),
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

  void _updateRunLogPath(String path) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    if (id == null || repo == null) {
      return;
    }
    unawaited(() async {
      try {
        final existing = await repo.getById(id);
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

  void _failRun(String message) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    if (id != null && repo != null) {
      unawaited(() async {
        try {
          final existing = await repo.getById(id);
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
    addEvent(ErrorEvent(
      content: message,
    ));
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
  }

  void _updateRunLogLastOutput() {
    final id = runLogId;
    final repo = deps.runLogRepo;
    if (id == null || repo == null) {
      return;
    }
    unawaited(() async {
      try {
        final existing = await repo.getById(id);
        if (existing == null) {
          return;
        }
        await repo.upsert(
          existing.copyWith(lastOutputAt: lastOutputAt),
        );
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

  Future<void> _closeRunLog({int? exitCode, Object? error}) async {
    await _logWriter.close(exitCode: exitCode, error: error);
  }

  void _closeController() {
    if (!controller.isClosed) {
      controller.close();
    }
  }

  Future<AgentCapabilities> _capabilitiesFor(String? agentId) async {
    if (agentId != null) {
      try {
        final agent = await deps.agentRepo.getById(agentId);
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
