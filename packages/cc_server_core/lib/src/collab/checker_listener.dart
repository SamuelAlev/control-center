import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_checker_repository.dart';

/// The checker-agent role (PRD 16 §13): one agent works, another reviews it,
/// both visible in-thread.
///
/// A space may name a **checker** ([SpaceCheckerRepository]). When any OTHER
/// agent's main run
/// completes in that space, the checker is auto-dispatched into the same
/// conversation with a review brief — its turn streams into the thread like
/// any participant's. Loop-safe: the checker's own completions never
/// re-trigger it and a per-space cooldown absorbs completion bursts.
class CheckerDispatchListener {
  /// Creates the listener. Call [start].
  CheckerDispatchListener({
    required this._eventBus,
    required this._checkers,
    required this._runLogs,
    required this._dispatchChecker,
    this.cooldown = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DomainEventBus _eventBus;
  final SpaceCheckerRepository _checkers;
  final AgentRunLogRepository _runLogs;
  final Future<void> Function({
    required String spaceId,
    required String? conversationId,
    required String agentId,
    required String prompt,
    required String workspaceId,
  })
  _dispatchChecker;

  /// Minimum spacing between checker dispatches per space.
  final Duration cooldown;

  final DateTime Function() _now;
  final Map<String, DateTime> _lastDispatch = {};
  StreamSubscription<AgentRunCompleted>? _sub;

  /// Begins listening for completed runs.
  void start() {
    _sub ??= _eventBus.on<AgentRunCompleted>().listen(
      (event) => unawaited(_onRunCompleted(event)),
    );
  }

  Future<void> _onRunCompleted(AgentRunCompleted event) async {
    try {
      await _reviewCompletedRun(event);
    } on DeletedWorkspaceException {
      // The run outlived its workspace: there is no thread left to review.
    }
  }

  Future<void> _reviewCompletedRun(AgentRunCompleted event) async {
    final workspaceId = event.workspaceId;
    final runId = event.runId;
    if (workspaceId == null || workspaceId.isEmpty || runId == null) {
      return;
    }
    // The event names the run's conversation, and a conversation id is never
    // a space id: the space a run worked in is on its log.
    final run = await _runLogs.getById(workspaceId, runId);
    final spaceId = run?.spaceId;
    if (run == null || spaceId == null || spaceId.isEmpty) {
      return;
    }
    // Only MAIN runs trigger a review (subagents/advisors are internals).
    if (run.role != AgentRunRole.main) {
      return;
    }
    final checkerId = await _checkers.checkerOf(workspaceId, spaceId);
    if (checkerId == null || checkerId.isEmpty) {
      return;
    }
    // Never review yourself — that is the loop guard, not a heuristic.
    if (event.agentId == checkerId) {
      return;
    }
    final last = _lastDispatch[spaceId];
    if (last != null && _now().difference(last) < cooldown) {
      return;
    }
    _lastDispatch[spaceId] = _now();
    await _dispatchChecker(
      spaceId: spaceId,
      conversationId: run.conversationId ?? event.conversationId,
      agentId: checkerId,
      workspaceId: workspaceId,
      prompt:
          'You are this channel\'s checker (second pair of eyes). Another '
          'agent just finished a run in this conversation. Re-read the '
          'recent messages and its transcript, review the work critically '
          '(correctness, missed requirements, risky changes) and post a '
          'concise review. If everything is sound, say so briefly — do not '
          'invent problems.',
    );
  }

  /// Stops listening.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
