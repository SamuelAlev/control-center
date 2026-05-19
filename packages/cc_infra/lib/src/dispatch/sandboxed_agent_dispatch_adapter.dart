import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart' show FileSearchPort;
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backend_registry.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';

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
    required CredentialBrokerPort credentialBroker,
    required AgentRepository agentRepository,
    AgentRunLogRepository? runLogRepository,
    TodoRepository? todoRepository,
    RunTranscriptRecorder? runTranscriptRecorder,
    AgentCapabilities defaultCapabilities = AgentCapabilities.safeDefault,
    DomainEventBus? eventBus,
    Future<String?> Function(
      String, {
      String? workspaceId,
      String? agentId,
      String? conversationId,
    })?
    mcpConfigPathResolver,
    Future<List<String>> Function(String workspaceId)? protectedPathsResolver,
    BackendRegistry? backendRegistry,
    this.sandboxManager,
    this.confirmationPort,
    this.autonomyResolver,
    ActionGuardService? actionGuard,
    McpToolRegistry? mcpRegistry,
    ProviderCredentialStore? harnessCredentialStore,
    ProviderCredentialRefresher? harnessCredentialRefresher,
    ModelInfo? Function(String qualifiedId)? modelResolver,
    HarnessProviderFactory harnessProviderFactory =
        const HarnessProviderFactory(),
    AgentLoop agentLoop = const AgentLoopRunner(),
    Future<({String name, String email})?> Function(String? userId)?
    resolveGitIdentity,
    Future<String?> Function(String userId)? resolveUserGitHubToken,
    ProcessControlPort? processControl,
    FileSearchPort? fileSearch,
  }) : _sandbox = sandbox,
       _deps = SandboxDispatchDeps(
         sandbox: sandbox,
         broker: credentialBroker,
         agentRepo: agentRepository,
         runLogRepo: runLogRepository,
         todoRepo: todoRepository,
         runTranscriptRecorder: runTranscriptRecorder,
         defaultCaps: defaultCapabilities,
         eventBus: eventBus,
         mcpConfigPathResolver: mcpConfigPathResolver,
         protectedPathsResolver: protectedPathsResolver,
         backendRegistry: backendRegistry ?? buildBackendRegistry(),
         sandboxManager: sandboxManager,
         confirmationPort: confirmationPort,
         actionGuard: actionGuard,
         autonomyResolver: autonomyResolver,
         mcpRegistry: mcpRegistry,
         harnessCredentialStore: harnessCredentialStore,
         harnessCredentialRefresher: harnessCredentialRefresher,
         modelResolver: modelResolver,
         harnessProviderFactory: harnessProviderFactory,
         agentLoop: agentLoop,
         resolveGitIdentity: resolveGitIdentity,
         resolveUserGitHubToken: resolveUserGitHubToken,
         processControl: processControl,
         fileSearch: fileSearch,
       );

  final SandboxPort _sandbox;
  final SandboxDispatchDeps _deps;

  /// The process-wide OS sandbox manager, or null when unavailable.
  final SandboxManager? sandboxManager;

  /// Confirmation port for UAC prompts, or null when no approver is wired.
  final ConfirmationPort? confirmationPort;

  /// Resolves the per-channel autonomy dial (PRD 16 §12); threaded into each
  /// session's approval gate. Keyed by workspace as well as channel, because the
  /// channel row lives in that workspace's database.
  final Future<String?> Function(
    String workspaceId,
    String channelId,
    String agentId,
  )?
  autonomyResolver;

  static const Duration _idleCooldown = Duration(minutes: 5);

  final Map<String, SandboxHandle> _handles = {};
  final Map<String, Timer> _cooldownTimers = {};
  final Map<String, DispatchSession> _dispatchSessions = {};

  @override
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
    int? costCapCents,
  }) {
    final dispatchId =
        '${DateTime.now().millisecondsSinceEpoch}-'
        '${(agentId ?? 'agent').hashCode.abs().toRadixString(36)}';
    final session = DispatchSession(
      deps: _deps,
      onResolveHandle: _resolveHandle,
      onScheduleCooldown: _scheduleCooldown,
      dispatchId: dispatchId,
      cliName: cliName,
      prompt: prompt,
      userText: userText,
      agentDirHostPath: workingDirectory,
      agentConfigDir: agentConfigDir,
      modelId: modelId,
      callerEnv: environment ?? const {},
      agentId: agentId,
      agentName: agentName,
      workspaceId: workspaceId,
      conversationId: conversationId,
      runLogId: runLogId,
      ticketId: ticketId,
      requestedByUserId: requestedByUserId,
      wakeContext: wakeContext,
      mode: mode ?? Mode.chat,
      silenceTimeoutMinutes: silenceTimeoutMinutes,
      effortLevel: effortLevel,
      adapterArgsOverride: adapterArgsOverride ?? const [],
      adapterEnvOverride: adapterEnvOverride ?? const {},
      costCapCents: costCapCents,
    );
    unawaited(
      session.run().whenComplete(() {
        _dispatchSessions.remove(dispatchId);
      }),
    );
    _dispatchSessions[dispatchId] = session;
    return DispatchHandle(
      dispatchId: dispatchId,
      events: session.controller.stream,
      onStop: () async {
        await session.stop();
      },
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
    session.steer(
      message,
      channel: followUp ? SteeringChannel.followUp : SteeringChannel.steering,
    );
    return true;
  }

  @override
  Future<void> stop() async {
    final sessions = List<DispatchSession>.from(_dispatchSessions.values);
    _dispatchSessions.clear();
    for (final s in sessions) {
      await s.stop();
    }
  }

  /// Destroys all active sandbox handles and cancels idle cooldown timers.
  Future<void> destroyAll() async {
    for (final t in _cooldownTimers.values) {
      t.cancel();
    }
    _cooldownTimers.clear();
    final handles = List<SandboxHandle>.from(_handles.values);
    _handles.clear();
    for (final h in handles) {
      try {
        await _sandbox.destroy(h);
      } catch (_) {
        CcInfraLog.warning(
          'SandboxedAgentDispatchAdapter: Sandbox destroy failed',
        );
      }
    }
  }

  Future<SandboxHandle> _resolveHandle({
    required String sessionId,
    required SandboxSpec spec,
    required void Function(AgentProcessEvent) emit,
  }) async {
    _cooldownTimers.remove(sessionId)?.cancel();
    final existing = _handles[sessionId];
    if (existing != null) {
      final alive = await _sandbox.isAlive(existing);
      if (alive) {
        emit(DebugEvent(content: '[sandbox] reusing warm sandbox session'));
        return existing;
      }
      _handles.remove(sessionId);
    }
    emit(
      DebugEvent(
        content: '[sandbox] starting sandbox session for ${spec.agentId}…',
      ),
    );
    final fresh = await _sandbox.launch(spec);
    _handles[sessionId] = fresh;
    return fresh;
  }

  void _scheduleCooldown(String sessionId) {
    _cooldownTimers.remove(sessionId)?.cancel();
    _cooldownTimers[sessionId] = Timer(_idleCooldown, () async {
      _cooldownTimers.remove(sessionId);
      final handle = _handles.remove(sessionId);
      if (handle != null) {
        try {
          await _sandbox.destroy(handle);
        } catch (_) {
          CcInfraLog.warning(
            'SandboxedAgentDispatchAdapter: Cooldown sandbox destroy failed',
          );
        }
      }
    });
  }
}
