import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/rig_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/repositories/rig_repository.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_host/cc_host.dart';

/// Tells the agent driving a rig when its machine changes underneath it.
///
/// Take-over is enforced at the `RigService.act` chokepoint, never by asking
/// nicely in a prompt — but enforcement alone leaves the agent to DISCOVER the
/// take-over through a refused click, mid-plan, with no idea why. Same for a
/// reap: a rig that vanishes turns every later action into an unexplained
/// error. This listener closes that gap by injecting a plain-language notice
/// into the running loop through the same steering lane the conversation-level
/// take-over/hand-back already uses (`TakeoverService`), so the agent reads it
/// at the next turn boundary and can narrate or wait instead of flailing.
///
/// It is a NOTICE, not a permission: nothing here grants or removes anything.
/// The chokepoint remains the enforcement.
///
/// Steering only reaches the built-in harness. An external-CLI run has no
/// mid-run injection space, so `steerRun` returns false and the agent keeps
/// learning the hard way — which is why the refusal message at the chokepoint
/// must stay self-explanatory regardless of this listener.
class RigEventListener {
  /// Creates the listener. Call [start].
  RigEventListener({
    required DomainEventBus eventBus,
    required RigRepository rigs,
    required AgentRunLogRepository runLogs,
    required Future<bool> Function(String runLogId, String message) steerRun,
  }) : _eventBus = eventBus,
       _rigs = rigs,
       _runLogs = runLogs,
       _steerRun = steerRun;

  final DomainEventBus _eventBus;
  final RigRepository _rigs;
  final AgentRunLogRepository _runLogs;
  final Future<bool> Function(String runLogId, String message) _steerRun;

  final List<StreamSubscription<Object?>> _subs = [];

  /// Begins listening. Idempotent per instance lifetime.
  void start() {
    if (_subs.isNotEmpty) {
      return;
    }
    _subs
      ..add(
        _eventBus.on<RigControlChanged>().listen(
          (e) => unawaited(_guard(() => onControlChanged(e))),
        ),
      )
      ..add(
        _eventBus.on<RigReaped>().listen(
          (e) => unawaited(_guard(() => onReaped(e))),
        ),
      )
      ..add(
        _eventBus.on<RigClosedEvent>().listen(
          (e) => unawaited(_guard(() => onClosed(e))),
        ),
      );
  }

  /// A human took the wheel, or gave it back.
  ///
  /// Visible for testing; [start] is what wires it to the bus.
  Future<void> onControlChanged(RigControlChanged event) async {
    final rig = await _rigs.getById(event.workspaceId, event.rigId);
    final agentId = rig?.agentId;
    if (agentId == null || agentId.isEmpty) {
      return;
    }
    final controller = event.controller;
    // An agent taking (or holding) its own rig's lock is not news to itself.
    if (controller != null && controller.isAgent && controller.id == agentId) {
      return;
    }
    final where = _describe(rig, event.rigId);
    final message = controller == null
        ? 'Control of $where was released. You may drive it again; the '
              'machine may have been changed while a person held it, so '
              'take a screenshot before acting on a stale plan.'
        : 'A human took control of $where. Mutating rig actions will be '
              'refused until control is released — observation '
              '(screenshots, extraction) still works, so keep narrating '
              'what you see rather than retrying the action.';
    await _steer(event.workspaceId, agentId, message);
  }

  /// The system reclaimed the machine (idle, TTL or memory-pressure eviction).
  ///
  /// Visible for testing.
  Future<void> onReaped(RigReaped event) async {
    final rig = await _rigs.getById(event.workspaceId, event.rigId);
    final agentId = event.agentId ?? rig?.agentId;
    if (agentId == null || agentId.isEmpty) {
      return;
    }
    await _steer(
      event.workspaceId,
      agentId,
      'The rig was closed: ${_reasonPhrase(event.reason)}. '
      '${_describe(rig, event.rigId)} no longer exists and every action '
      'against it will fail. Re-open it via rig.open if you still need it — '
      'anything you did not commit or read out of the guest is gone.',
    );
  }

  /// A rig closed. Only [RigCloseReason.backendFailure] steers.
  ///
  /// The idle/TTL closes are always published ALONGSIDE a [RigReaped] carrying
  /// the same reason plus the driving agent, so acting on both would inject
  /// the same notice twice; `requested` and `serverShutdown` are not news, and
  /// `conversationEnded`/`workspaceGone` mean the work the agent was doing is
  /// over anyway.
  ///
  /// Visible for testing.
  Future<void> onClosed(RigClosedEvent event) async {
    if (event.reason != RigCloseReason.backendFailure) {
      return;
    }
    final rig = await _rigs.getById(event.workspaceId, event.rigId);
    final agentId = rig?.agentId;
    if (agentId == null || agentId.isEmpty) {
      return;
    }
    await _steer(
      event.workspaceId,
      agentId,
      'The rig was closed: ${_reasonPhrase(event.reason)}. '
      '${_describe(rig, event.rigId)} is gone. Re-open it via rig.open if '
      'you still need it, and expect the guest to start from the base image.',
    );
  }

  /// Cancels every subscription.
  Future<void> dispose() async {
    await Future.wait(_subs.map((s) => s.cancel()));
    _subs.clear();
  }

  /// Resolves the agent's live run and pushes [message] onto its steering lane.
  ///
  /// No active run means there is nothing to interrupt — the agent will read
  /// the rig's state when it next asks for it.
  Future<void> _steer(
    String workspaceId,
    String agentId,
    String message,
  ) async {
    final run = await _runLogs.activeRunForAgent(workspaceId, agentId);
    if (run == null) {
      return;
    }
    await _steerRun(run.id, message);
  }

  /// A rig lookup or a steer failing must never take the event bus down with
  /// it: every other subscriber to the same event still has work to do.
  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (e) {
      CcHostLog.warning('RigEventListener: $e');
    }
  }

  static String _describe(Rig? rig, String rigId) =>
      rig == null ? 'rig $rigId' : 'the ${rig.surface.wire} rig $rigId';

  static String _reasonPhrase(RigCloseReason reason) => switch (reason) {
    RigCloseReason.requested => 'somebody closed it',
    RigCloseReason.idleTimeout =>
      'it was reclaimed after sitting idle (or to free memory for another '
          'machine)',
    RigCloseReason.ttlExpired => 'it reached its hard time limit',
    RigCloseReason.conversationEnded => 'the conversation that owned it ended',
    RigCloseReason.workspaceGone => 'the workspace went away',
    RigCloseReason.serverShutdown => 'the server is shutting down',
    RigCloseReason.backendFailure => 'the hypervisor failed underneath it',
  };
}
