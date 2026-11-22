import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';

/// How a pipeline's `goal.pursue` step starts and finds the durable goal it
/// waits on. The server binds it to the goal supervisor's structured start,
/// which stores the step with the goal (`AgentGoalRun.pipeline`): from that
/// row the goal's settlement resumes the step, its runs are charged to the
/// pipeline run, and its segments stop at an orchestration's cap.
abstract interface class GoalPursuitPort {
  /// Starts a goal for [agentId] in [conversationId] for step [stepId] of
  /// pipeline run [pipelineRunId] and returns it as stored. Never parses
  /// slash text: [objective], [contract] and the limits come from the
  /// step's checked configuration. [requestedByUserId] is the pipeline run's
  /// requester (null: nobody asked). Throws `GoalAlreadyActiveException`
  /// when the agent already pursues a goal.
  Future<AgentGoalRun> startPursuit({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required String objective,
    required GoalContract? contract,
    required int costCapMicros,
    required int? maxRuns,
    required DateTime? deadlineAt,
    required String? requestedByUserId,
    required String pipelineRunId,
    required String stepId,
  });

  /// The goal [goalId] in [workspaceId] that step [stepId] of
  /// [pipelineRunId] started, read again after a restart. Null when there is
  /// no such goal in the workspace, or its stored step is another one.
  Future<AgentGoalRun?> attach({
    required String workspaceId,
    required String goalId,
    required String pipelineRunId,
    required String stepId,
  });
}
