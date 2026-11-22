import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:path/path.dart' as p;

// The smallest honest adapters a goal attempt gives the product's
// `GoalStore`, `GoalVerifier`, `GoalCheckRunner`, `GoalChanges` and
// `GoalTurnTexts`: one goal, one agent, one conversation, in memory. Each
// answers what the product classes ask on the verification path and refuses
// anything else by name, so a product change that starts asking for more
// fails loudly instead of reading an empty answer.

/// Refuses [invocation] of a member the [adapter] does not answer.
Never _refuse(String adapter, Invocation invocation) => throw UnsupportedError(
  'the evaluation goal $adapter does not answer '
  '${invocation.memberName}: a goal attempt holds one goal, one agent '
  'and one conversation in memory',
);

/// The one goal of an attempt.
class EvaluationGoalRows implements AgentGoalRunRepository {
  AgentGoalRun? _goal;

  /// The goal as stored now.
  AgentGoalRun get current =>
      _goal ?? (throw StateError('the attempt has no goal yet'));

  bool _is(String workspaceId, String id) =>
      _goal != null && _goal!.workspaceId == workspaceId && _goal!.id == id;

  @override
  Future<AgentGoalRun?> getById(String workspaceId, String id) async =>
      _is(workspaceId, id) ? _goal : null;

  @override
  Future<List<AgentGoalRun>> listByWorkspace(String workspaceId) async => [
    if (_goal?.workspaceId == workspaceId) _goal!,
  ];

  @override
  Future<List<AgentGoalRun>> listActive() async => [
    if (_goal != null && !_goal!.status.isTerminal) _goal!,
  ];

  @override
  Future<AgentGoalRun?> getActiveForAgent(
    String workspaceId,
    String agentId,
  ) async =>
      _goal != null &&
          _goal!.workspaceId == workspaceId &&
          _goal!.agentId == agentId &&
          _goal!.status == AgentGoalStatus.active
      ? _goal
      : null;

  @override
  Future<List<AgentGoalRun>> listHeld(
    String workspaceId, {
    GoalHold? hold,
  }) async => [
    if (_goal != null &&
        _goal!.workspaceId == workspaceId &&
        _goal!.hold != null &&
        (hold == null || _goal!.hold == hold) &&
        (_goal!.status == AgentGoalStatus.active ||
            _goal!.status == AgentGoalStatus.paused))
      _goal!,
  ];

  @override
  Future<AgentGoalRun?> getByActiveRunId(
    String workspaceId,
    String runId,
  ) async => _goal?.workspaceId == workspaceId && _goal?.activeRunId == runId
      ? _goal
      : null;

  @override
  Future<void> upsert(AgentGoalRun goal) async => _goal = goal;

  @override
  Future<bool> replaceIf(
    AgentGoalRun next, {
    required AgentGoalRun expected,
  }) async {
    if (_goal != expected) {
      return false;
    }
    _goal = next;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => _refuse('rows', invocation);
}

/// The wake queue of an attempt: every wake the product's goal store writes
/// (a segment's, a review's) is kept for the attempt to act on, in order;
/// nothing is delivered on its own.
class EvaluationWakeCapture implements WakeQueueService {
  final List<Wake> _written = [];

  /// Takes the oldest wake written and not yet taken; null when none.
  Wake? take() => _written.isEmpty ? null : _written.removeAt(0);

  @override
  Future<bool> enqueue(Wake input) async {
    _written.add(input);
    return true;
  }

  @override
  Future<int> cancelWhere(
    String workspaceId, {
    String? goalId,
    String? ruleId,
    String? askId,
    String? conversationId,
    String? requestedByUserId,
    required String reason,
  }) async {
    final before = _written.length;
    _written.removeWhere(
      (wake) =>
          wake.workspaceId == workspaceId &&
          (goalId == null || wake.detail.goalId == goalId) &&
          (conversationId == null || wake.conversationId == conversationId),
    );
    return before - _written.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _refuse('wake queue', invocation);
}

/// The wake rows: an attempt keeps no wake rows (its wakes are captured, not
/// queued), so every read refuses.
class EvaluationNoWakeRows implements WakeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _refuse('wake rows', invocation);
}

/// The attempt's one agent: the worker, who is also its own reviewer (a
/// goal with no checker reviews with a fresh run of its own agent).
class EvaluationGoalAgents implements AgentRepository {
  /// Creates the repository holding [agent].
  EvaluationGoalAgents(this.agent);

  /// The agent.
  final Agent agent;

  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      agent.workspaceId == workspaceId && agent.id == id ? agent : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => _refuse('agents', invocation);
}

/// The review runs of an attempt, as the verifier reads them back.
class EvaluationReviewRuns implements AgentRunLogRepository {
  final Map<String, AgentRunLog> _runs = {};

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final run = _runs[id];
    return run?.workspaceId == workspaceId ? run : null;
  }

  @override
  Future<void> upsert(AgentRunLog log) async => _runs[log.id] = log;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _refuse('run logs', invocation);
}

/// The attempt's one conversation, in its space.
class EvaluationGoalConversations implements ConversationRepository {
  /// Creates the repository holding [conversation].
  EvaluationGoalConversations(this.conversation);

  /// The conversation.
  final Conversation conversation;

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async =>
      conversation.workspaceId == workspaceId &&
          conversation.id == conversationId
      ? conversation
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _refuse('conversations', invocation);
}

/// Where the attempt's space is: the directory whose `repos/` holds the
/// task workspace, so the product finds the workspace as a space's only
/// checkout.
class EvaluationSpaceFiles implements WorkspaceFilesystemPort {
  /// Creates the port over [directory].
  EvaluationSpaceFiles(this.directory);

  /// The space directory.
  final String directory;

  @override
  Future<String> spaceDir(String workspaceId, String spaceId) async =>
      directory;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _refuse('filesystem', invocation);
}

/// Starts a goal check's process the way the evaluation's own `bash` tool
/// runs its commands ([ChildProcess.start] with the toolchain, inside the
/// task workspace), and refuses a check anywhere else.
///
/// That is the evaluation's process boundary: the agent's `bash` runs
/// unconfined in a throwaway copy of the task, so its checks run there too,
/// as the product runs a goal's checks where the owner turned the sandbox
/// off for every run (`HostExecutionPosture.offByOwner`).
Future<Process> Function(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Map<String, String> environment,
})
evaluationCheckStarter(String workspaceRoot) =>
    (executable, arguments, {required workingDirectory, required environment}) {
      if (!p.equals(workingDirectory, workspaceRoot) &&
          !p.isWithin(workspaceRoot, workingDirectory)) {
        throw StateError(
          'a goal check runs inside the task workspace $workspaceRoot, not '
          'in $workingDirectory',
        );
      }
      return ChildProcess.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        toolchain: true,
      );
    };
