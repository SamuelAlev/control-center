import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/ports/credential_broker_port.dart';
import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/sandbox_handle.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:control_center/features/sandboxing/data/adapters/dispatch_session.dart';

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
    AgentCapabilities defaultCapabilities = AgentCapabilities.safeDefault,
    DomainEventBus? eventBus,
  })  : _sandbox = sandbox,
        _deps = SandboxDispatchDeps(
          sandbox: sandbox,
          broker: credentialBroker,
          agentRepo: agentRepository,
          runLogRepo: runLogRepository,
          defaultCaps: defaultCapabilities,
          eventBus: eventBus,
        );

  final SandboxPort _sandbox;
  final SandboxDispatchDeps _deps;

  static const Duration _idleCooldown = Duration(minutes: 5);

  final Map<String, SandboxHandle> _handles = {};
  final Map<String, Timer> _cooldownTimers = {};
  final Map<String, DispatchSession> _dispatchSessions = {};

  @override
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
  }) {
    final dispatchId = '${DateTime.now().millisecondsSinceEpoch}-'
        '${(agentId ?? 'agent').hashCode.abs().toRadixString(36)}';
    final session = DispatchSession(
      deps: _deps,
      onResolveHandle: _resolveHandle,
      onScheduleCooldown: _scheduleCooldown,
      dispatchId: dispatchId,
      cliName: cliName,
      prompt: prompt,
      agentDirHostPath: workingDirectory,
      modelId: modelId,
      callerEnv: environment ?? const {},
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      runLogId: runLogId,
      ticketId: ticketId,
      wakeContext: wakeContext,
      mode: mode ?? ConversationMode.chat,
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
        AppLog.w('SandboxedAgentDispatchAdapter', 'Sandbox destroy failed');
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
    emit(DebugEvent(content: '[sandbox] starting sandbox session for ${spec.agentId}…'));
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
          AppLog.w('SandboxedAgentDispatchAdapter', 'Cooldown sandbox destroy failed');
        }
      }
    });
  }
}
