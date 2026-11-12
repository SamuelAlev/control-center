import 'dart:async';
import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show ForgeRemote;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/llm_call_record_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart'
    show AgentPromptParts;
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_harness/context.dart' show ToolOutputStore;
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart' show FileSearchPort;
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/backend_registry.dart';
import 'package:cc_infra/src/dispatch/claude_idle_compactor.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/one_shot_confinement.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/harness/ast_parser_provider.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/media/media_read_scope.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:cc_infra/src/sandboxing/claude_mcp_discovery_cache.dart';
import 'package:cc_infra/src/sandboxing/claude_native_session.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// {@template sandboxed_agent_dispatch_adapter}
/// Adapter that dispatches agent runs inside sandboxed environments.
///
/// Uses a [SandboxPort] to provision and manage ephemeral sandboxes for each
/// dispatched agent session.
/// {@endtemplate}
class SandboxedAgentDispatchAdapter implements AgentDispatchPort {
  /// Creates a [SandboxedAgentDispatchAdapter].
  SandboxedAgentDispatchAdapter({
    required SandboxPort sandbox,
    required HostExecutionGate hostExecution,
    required AgentRepository agentRepository,
    AgentRunLogRepository? runLogRepository,
    LlmCallRecordRepository? llmCallRecordRepository,
    TodoRepository? todoRepository,
    RunTranscriptRecorder? runTranscriptRecorder,
    DomainEventBus? eventBus,
    Future<String?> Function(
      String, {
      String? workspaceId,
      String? agentId,
      String? conversationId,
      String? spaceId,
      String? runToken,
    })?
    mcpConfigPathResolver,
    Future<Map<String, Object?>?> Function({
      String? workspaceId,
      String? agentId,
      String? conversationId,
      String? spaceId,
      String? runToken,
    })?
    mcpServersResolver,
    Future<List<String>> Function(String workspaceId)? protectedPathsResolver,
    Future<List<String>> Function(
      String workspaceId,
      String spaceId,
      String? actingUserId,
    )?
    writableWorktrees,
    Future<List<ForgeRemote>> Function(String workspaceId, String spaceId)?
    spaceRepos,
    BackendRegistry? backendRegistry,
    this.sandboxManager,
    this.confirmationPort,
    this.execGrantService,
    AgentQuestionPort? agentQuestionPort,
    BlobStore? blobStore,
    MediaRenderPort? mediaRenderer,
    LspSupervisor? lspSupervisor,
    String? agentHooksRoot,
    AstParserProvider? astParsers,
    HarnessTranscriptStore? transcriptStore,
    ToolOutputStore? toolOutputStore,
    ClaudeNativeSessionStore? claudeSessionStore,
    ClaudeMcpDiscoveryCachePolicy claudeMcpDiscoveryCache =
        ClaudeMcpDiscoveryCachePolicy.disabled,
    Future<int?> Function(String? modelId)? claudeContextWindowOf,
    void Function(String configDir, List<SubscriptionWindow> windows)?
    onClaudeUsageWindows,
    ClaudeSessionSettings Function()? claudeSessionSettings,
    ClaudeIdleCompactor? claudeIdleCompactor,
    DebugSessionSupervisor? debugSupervisor,
    Future<KernelLauncher> Function({
      required String workingDirectory,
      required ToolProcessLauncher hostProcesses,
      String? workspaceId,
      String? conversationId,
    })?
    kernelLauncherFactory,
    this.autonomyResolver,
    ActionGuardService? actionGuard,
    AgentRunGateway? agentRunGateway,
    LateEnvironmentPort? environments,
    McpToolRegistry? mcpRegistry,
    SkillScanPort? skillScanner,
    ProviderCredentialStore? harnessCredentialStore,
    ProviderCredentialRefresher? harnessCredentialRefresher,
    RunCredentialGatePort? credentialGate,
    Future<bool> Function(String accountId)? syncClaudeCredential,
    ModelInfo? Function(String qualifiedId)? modelResolver,
    HarnessProviderFactory harnessProviderFactory =
        const HarnessProviderFactory(),
    AgentLoop agentLoop = const AgentLoopRunner(),
    Future<AgentCommitIdentity?> Function(
      String? userId, {
      String? workspaceId,
      String? runLogId,
      ForgeHost? forge,
    })?
    resolveCommitIdentity,
    GitRepoInspectorPort? repoInspector,
    ProcessControlPort? processControl,
    FileSearchPort? fileSearch,
    bool toolDeferralEnabled = true,
  }) : _sandbox = sandbox,
       _deps = SandboxDispatchDeps(
         sandbox: sandbox,
         hostExecution: hostExecution,
         agentRepo: agentRepository,
         runLogRepo: runLogRepository,
         llmCallRecordRepo: llmCallRecordRepository,
         todoRepo: todoRepository,
         runTranscriptRecorder: runTranscriptRecorder,
         eventBus: eventBus,
         mcpConfigPathResolver: mcpConfigPathResolver,
         mcpServersResolver: mcpServersResolver,
         protectedPathsResolver: protectedPathsResolver,
         writableWorktrees: writableWorktrees,
         spaceRepos: spaceRepos,
         backendRegistry: backendRegistry ?? buildBackendRegistry(),
         sandboxManager: sandboxManager,
         confirmationPort: confirmationPort,
         execGrantService: execGrantService,
         agentQuestionPort: agentQuestionPort,
         blobStore: blobStore,
         mediaRenderer: mediaRenderer,
         lspSupervisor: lspSupervisor,
         agentHooksRoot: agentHooksRoot,
         astParsers: astParsers,
         transcriptStore: transcriptStore,
         toolOutputStore: toolOutputStore,
         claudeSessionStore: claudeSessionStore,
         claudeMcpDiscoveryCache: claudeMcpDiscoveryCache,
         claudeContextWindowOf: claudeContextWindowOf,
         onClaudeUsageWindows: onClaudeUsageWindows,
         claudeSessionSettings: claudeSessionSettings,
         claudeIdleCompactor: claudeIdleCompactor,
         debugSupervisor: debugSupervisor,
         kernelLauncherFactory: kernelLauncherFactory,
         actionGuard: actionGuard,
         agentRunGateway: agentRunGateway,
         environments: environments,
         autonomyResolver: autonomyResolver,
         mcpRegistry: mcpRegistry,
         skillScanner: skillScanner,
         harnessCredentialStore: harnessCredentialStore,
         harnessCredentialRefresher: harnessCredentialRefresher,
         credentialGate: credentialGate,
         syncClaudeCredential: syncClaudeCredential,
         modelResolver: modelResolver,
         harnessProviderFactory: harnessProviderFactory,
         agentLoop: agentLoop,
         resolveCommitIdentity: resolveCommitIdentity,
         repoInspector: repoInspector,
         processControl: processControl,
         fileSearch: fileSearch,
         toolDeferralEnabled: toolDeferralEnabled,
       );

  final SandboxPort _sandbox;
  final SandboxDispatchDeps _deps;

  /// Where an ACP one-shot may run: the confinement this adapter's runs get.
  OneShotConfinement get oneShotConfinement => OneShotConfinement.of(_deps);

  /// The process-wide OS sandbox manager, or null when unavailable.
  final SandboxManager? sandboxManager;

  /// Confirmation port for UAC prompts, or null when no approver is wired.
  final ConfirmationPort? confirmationPort;

  /// Asks the operator whether agents may run programs from inside their
  /// worktree; null leaves the sandbox's writable-dir exec block fully closed.
  final SandboxExecGrantService? execGrantService;

  /// Resolves the per-space autonomy dial (PRD 16 §12); threaded into each
  /// session's approval gate. Keyed by workspace as well as space, because the
  /// space row lives in that workspace's database.
  final Future<String?> Function(
    String workspaceId,
    String spaceId,
    String agentId,
  )?
  autonomyResolver;

  static const Duration _idleCooldown = Duration(minutes: 5);

  final Map<String, SandboxHandle> _handles = {};
  final Map<String, Timer> _cooldownTimers = {};
  final Map<String, DispatchSession> _dispatchSessions = {};

  /// Fires at the top of a session's harness transport — the moment its
  /// steering queue becomes drainable. The steering queue service attaches
  /// drain notifications and flushes persisted queued rows here. Late-bound
  /// (mutable field) because the wiring happens at the runtime composition
  /// root, after both this adapter and the queue service exist.
  void Function(SteeringSessionView session)? onSessionHarnessStarted;

  /// Live dispatch sessions attached to [conversationId], the steering
  /// queue's delivery targets.
  List<SteeringSessionView> sessionsForConversation(String conversationId) => [
    for (final s in _dispatchSessions.values)
      if (s.conversationId == conversationId) s,
  ];

  /// Resolves only the authenticated caller's active execution filesystem.
  ///
  /// Reusing the live session preserves the exact Read boundary, including
  /// per-conversation overlays and the roots shared with nested subagents.
  MediaReadScope? mediaReadScopeFor(MediaRenderRequest request) {
    MediaReadScope? result;
    for (final session in _dispatchSessions.values) {
      if (session.workspaceId != request.workspaceId ||
          session.agentId != request.agentId ||
          session.spaceId != request.spaceId ||
          session.conversationId != request.conversationId) {
        continue;
      }
      final scope = session.mediaReadScope;
      if (scope == null) {
        continue;
      }
      if (result != null) {
        return null;
      }
      result = scope;
    }
    return result;
  }

  @override
  DispatchHandle start({
    required String cliName,
    required String prompt,
    required String workingDirectory,
    AgentPromptParts? promptParts,
    DateTime? runStartedAt,
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
    int? contextWindowTokens,
    String? agentConfigDir,
    List<String>? adapterArgsOverride,
    Map<String, String>? adapterEnvOverride,
    String? claudeConfigDir,
    List<({String accountId, String configDir})>? claudeAccounts,
    Future<void> Function({required String accountId, DateTime? resetsAt})?
    onClaudeAccountExhausted,
    Future<void> Function({required String accountId, String? reason})?
    onClaudeAccountAuthFailed,
    AccountPoolRefusal? claudeAccountsSpent,
    Future<AccountPoolOrder> Function({
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
    int? costCapMicros,
  }) {
    if (_shutDown) {
      throw StateError('the agent dispatch adapter has shut down');
    }
    // Random, not `<millis>-<hash(agentId)>`: two dispatches of one agent in
    // the same millisecond shared an id, so they shared a `.cc-runs/<id>/bin`
    // shim directory, and the first to finish removed the OTHER's map entry.
    final dispatchId = const Uuid().v4();
    final session = DispatchSession(
      deps: _deps,
      onResolveHandle: _resolveHandle,
      onScheduleCooldown: _scheduleCooldown,
      dispatchId: dispatchId,
      cliName: cliName,
      prompt: prompt,
      // The structured prompt: the Claude CLI builds the resume delta from it
      // against the conversation revision its stored session has already seen.
      // Other backends ignore it.
      promptParts: promptParts,
      runStartedAt: runStartedAt,
      userText: userText,
      // Images the human attached to the message that triggered this run.
      // Carried as blob references (the store resolves them per workspace);
      // the session loads the bytes onto the user turn.
      promptImageRefs: imagePaths ?? const [],
      agentDirHostPath: workingDirectory,
      agentConfigDir: agentConfigDir,
      modelId: modelId,
      callerEnv: environment ?? const {},
      agentId: agentId,
      agentName: agentName,
      workspaceId: workspaceId,
      conversationId: conversationId,
      spaceId: spaceId,
      runLogId: runLogId,
      ticketId: ticketId,
      requestedByUserId: requestedByUserId,
      wakeContext: wakeContext,
      mode: mode ?? Mode.chat,
      silenceTimeoutMinutes: silenceTimeoutMinutes,
      effortLevel: effortLevel,
      contextWindowTokens: contextWindowTokens,
      adapterArgsOverride: adapterArgsOverride ?? const [],
      adapterEnvOverride: adapterEnvOverride ?? const {},
      claudeConfigDir: claudeConfigDir,
      claudeAccounts: claudeAccounts ?? const [],
      onClaudeAccountExhausted: onClaudeAccountExhausted,
      onClaudeAccountAuthFailed: onClaudeAccountAuthFailed,
      claudeAccountsSpent: claudeAccountsSpent,
      onResolveHarnessRotation: onResolveHarnessRotation,
      onHarnessCredentialExhausted: onHarnessCredentialExhausted,
      costCapMicros: costCapMicros,
    );
    session.onHarnessStarted = () => onSessionHarnessStarted?.call(session);
    // Registered BEFORE the run starts, and removed only if the entry is still
    // this session: an id is unique, but the guard keeps a late completion
    // from ever evicting a sibling.
    _dispatchSessions[dispatchId] = session;
    unawaited(
      session.run().whenComplete(() {
        if (identical(_dispatchSessions[dispatchId], session)) {
          _dispatchSessions.remove(dispatchId);
        }
      }),
    );
    return DispatchHandle(
      dispatchId: dispatchId,
      events: session.controller.stream,
      // The handle's stop IS [stopDispatch]: one stop sequence, whichever of
      // the two a caller holds.
      onStop: () => stopDispatch(dispatchId),
    );
  }

  @override
  Future<void> stopDispatch(String dispatchId) async {
    final session = _dispatchSessions.remove(dispatchId);
    if (session != null) {
      await session.terminate();
    }
  }

  @override
  Future<void> stopAllForAgent(String agentId) async {
    final matches = _dispatchSessions.values
        .where((s) => s.agentId == agentId)
        .toList();
    for (final s in matches) {
      _dispatchSessions.remove(s.dispatchId);
      await s.terminate();
    }
  }

  @override
  Future<bool> pauseDispatch(String dispatchId) async {
    final session = _dispatchSessions[dispatchId];
    return session != null && session.pauseHarness();
  }

  @override
  Future<bool> resumeDispatch(String dispatchId) async {
    final session = _dispatchSessions[dispatchId];
    if (session == null) {
      return false;
    }
    session.resumeHarness();
    return true;
  }

  @override
  Future<bool> steerDispatch(
    String dispatchId,
    String message, {
    bool followUp = false,
  }) async {
    final session = _dispatchSessions[dispatchId];
    if (session == null) {
      return false;
    }
    // The session's own verdict, not bare existence: a live external-CLI
    // dispatch has no steering lane, and returning true for it told the
    // caller a message was delivered that no process will ever read.
    return session.steer(
      message,
      channel: followUp ? SteeringChannel.followUp : SteeringChannel.steering,
    );
  }

  /// Stops every live run: each child is killed, its credentials revoked and
  /// its run log closed. Concurrent, so a server shutdown is bounded by the
  /// slowest run rather than by their sum.
  @override
  Future<void> stop() async {
    final sessions = List<DispatchSession>.from(_dispatchSessions.values);
    _dispatchSessions.clear();
    await Future.wait([
      for (final s in sessions)
        s.stop().catchError((Object e, StackTrace st) {
          CcInfraLog.error(
            'SandboxedAgentDispatchAdapter: stopping ${s.dispatchId} failed',
            e,
            st,
          );
        }),
    ]);
  }

  /// Server shutdown: refuses new dispatches, stops every live run, then
  /// destroys every warm sandbox. Without it a stopped server left its agents'
  /// children running — nothing supervised them any more.
  Future<void> shutdown() async {
    _shutDown = true;
    await stop();
    await destroyAll();
  }

  bool _shutDown = false;

  /// Destroys all active sandbox handles and cancels idle cooldown timers.
  Future<void> destroyAll() async {
    for (final t in _cooldownTimers.values) {
      t.cancel();
    }
    _cooldownTimers.clear();
    final handles = List<SandboxHandle>.from(_handles.values);
    _handles.clear();
    _handleSpecs.clear();
    for (final h in handles) {
      await _destroy(h, 'shutdown');
    }
  }

  Future<void> _destroy(SandboxHandle handle, String why) async {
    try {
      await _sandbox.destroy(handle);
    } on Object catch (e, st) {
      CcInfraLog.error(
        'SandboxedAgentDispatchAdapter: sandbox destroy ($why) failed for '
        '${handle.sessionId}',
        e,
        st,
      );
    }
  }

  /// The spec each warm handle was launched with.
  ///
  /// A sandbox's posture — network, the account dirs it may write, approved
  /// exec roots, loopback ports, mounts — is fixed when it launches. Reusing a
  /// warm handle across dispatches used to reuse that posture too, for up to
  /// the cooldown: a re-dispatch after the egress rule turned the network off
  /// kept it on. A handle is now reused only for an IDENTICAL spec.
  final Map<String, SandboxSpec> _handleSpecs = {};

  /// [_resolveHandle], for tests of warm-handle reuse.
  @visibleForTesting
  Future<SandboxHandle> resolveHandleForTesting({
    required String sessionId,
    required SandboxSpec spec,
    required void Function(AgentProcessEvent) emit,
  }) => _resolveHandle(sessionId: sessionId, spec: spec, emit: emit);

  Future<SandboxHandle> _resolveHandle({
    required String sessionId,
    required SandboxSpec spec,
    required void Function(AgentProcessEvent) emit,
  }) async {
    if (_shutDown) {
      throw StateError('the agent dispatch adapter has shut down');
    }
    _cooldownTimers.remove(sessionId)?.cancel();
    final existing = _handles[sessionId];
    if (existing != null) {
      final alive = await _sandbox.isAlive(existing);
      if (alive && _handleSpecs[sessionId] == spec) {
        emit(DebugEvent(content: '[sandbox] reusing warm sandbox session'));
        return existing;
      }
      _handles.remove(sessionId);
      _handleSpecs.remove(sessionId);
      if (alive) {
        emit(
          DebugEvent(
            content:
                '[sandbox] sandbox posture changed since the last run — '
                'starting a fresh sandbox session',
          ),
        );
        await _destroy(existing, 'posture change');
      }
    }
    emit(
      DebugEvent(
        content: '[sandbox] starting sandbox session for ${spec.agentId}…',
      ),
    );
    final fresh = await _sandbox.launch(spec);
    _handles[sessionId] = fresh;
    _handleSpecs[sessionId] = spec;
    return fresh;
  }

  void _scheduleCooldown(String sessionId) {
    _cooldownTimers.remove(sessionId)?.cancel();
    Future<void> expire() async {
      _cooldownTimers.remove(sessionId);
      _handleSpecs.remove(sessionId);
      final handle = _handles.remove(sessionId);
      if (handle != null) {
        await _destroy(handle, 'cooldown');
      }
    }

    if (_shutDown) {
      // A run that finished during shutdown keeps nothing warm.
      unawaited(expire());
      return;
    }
    _cooldownTimers[sessionId] = Timer(
      _idleCooldown,
      () => unawaited(expire()),
    );
  }
}
