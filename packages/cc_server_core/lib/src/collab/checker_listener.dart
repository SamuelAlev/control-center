import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_checker_repository.dart';

/// The checker-agent role (PRD 16 §13): one agent works, another reviews it,
/// both visible in-thread.
///
/// A space may name a **checker** ([SpaceCheckerRepository]). When any OTHER
/// agent's main run completes in that space, the checker is woken (a
/// `peerMessage` wake through the wake queue) in the same conversation with
/// a review brief — its turn streams into the thread like any participant's. Loop-safe: the checker's own completions never
/// re-trigger it and a per-space cooldown absorbs completion bursts.
///
/// A run's end is read from `AgentRunSettled`. A run a person or the server
/// stopped is not reviewed, and neither is a goal's segment or the review of
/// a goal's claim ([_isGoalRun]: the goal supervisor decides what follows a
/// segment, a review of a half-done segment decides nothing, and a goal's
/// review is already the independent check).
class CheckerDispatchListener {
  /// Creates the listener. Call [start].
  CheckerDispatchListener({
    required this._eventBus,
    required this._checkers,
    required this._runLogs,
    required this._dispatchChecker,
    required this._isGoalRun,
    this.cooldown = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DomainEventBus _eventBus;
  final SpaceCheckerRepository _checkers;
  final AgentRunLogRepository _runLogs;
  /// Asks the checker `agentId` to review: wired to a `peerMessage` wake
  /// whose source is the run that settled (`sourceAgentId`, `sourceRunId`).
  final Future<void> Function({
    required String spaceId,
    required String? conversationId,
    required String agentId,
    required String prompt,
    required String workspaceId,
    required String sourceAgentId,
    required String sourceRunId,
  })
  _dispatchChecker;

  /// Whether a run is a goal's segment or a goal review
  /// (`GoalSupervisor.isGoalRun`).
  final Future<bool> Function({
    required String workspaceId,
    required String runId,
  })
  _isGoalRun;

  /// Minimum spacing between checker dispatches per space.
  final Duration cooldown;

  final DateTime Function() _now;
  final Map<String, DateTime> _lastDispatch = {};
  StreamSubscription<AgentRunSettled>? _sub;

  /// Begins listening for settled runs.
  void start() {
    _sub ??= _eventBus.on<AgentRunSettled>().listen(
      (event) => unawaited(_onRunSettled(event)),
    );
  }

  Future<void> _onRunSettled(AgentRunSettled event) async {
    try {
      await _reviewSettledRun(event);
    } on DeletedWorkspaceException {
      // The run outlived its workspace: there is no thread left to review.
    }
  }

  Future<void> _reviewSettledRun(AgentRunSettled event) async {
    // A stopped run is not finished work: the person (or the server) ended
    // it, and there is nothing to review.
    if (event.endReason == RunEndReason.stoppedByUser ||
        event.endReason == RunEndReason.serverStopped) {
      return;
    }
    final workspaceId = event.workspaceId;
    final runId = event.runId;
    // The space a run worked in is on the event (from its log); a
    // conversation id is never a space id.
    final spaceId = event.spaceId;
    if (spaceId == null || spaceId.isEmpty) {
      return;
    }
    if (await _isGoalRun(workspaceId: workspaceId, runId: runId)) {
      return;
    }
    final run = await _runLogs.getById(workspaceId, runId);
    if (run == null) {
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
      sourceAgentId: event.agentId,
      sourceRunId: runId,
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
