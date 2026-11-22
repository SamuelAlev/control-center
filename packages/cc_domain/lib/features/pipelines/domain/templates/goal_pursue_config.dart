import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';

/// The `goal.pursue` step body: it starts a durable goal and waits for it.
/// Declared here, not in `builtin_template_seeds.dart` (a frozen file).
const String kGoalPursueBodyKey = 'goal.pursue';

/// The reserved state-key prefix under which a `goal.pursue` step records
/// the goal it started (`__goal__<stepId>` → goal id). Written only by the
/// step body; read back on a restart to re-attach.
const String kGoalPursueStateKeyPrefix = '__goal__';

/// The state key of step [stepId]'s goal.
String goalPursueStateKey(String stepId) => '$kGoalPursueStateKeyPrefix$stepId';

/// A `goal.pursue` node's configuration, checked. Read from the node:
///
/// - `agentId`: the agent that pursues the goal (required);
/// - `prompt`: the objective, `{{key}}` placeholders allowed (required);
/// - `outputKey`: where `{summary, verdict}` lands (required);
/// - `extras.contract`: a `GoalContract` JSON object (optional);
/// - `extras.budgetMicros`: the goal's cost cap, 1 to [maxBudgetMicros]
///   (required);
/// - `extras.maxRuns`: the run budget, 1 to [maxRunsLimit] (optional);
/// - `extras.deadlineHours`: hours from the start, 1 to
///   [maxDeadlineHours] (optional).
///
/// The room is resolved like every conversation step (prior attempt's room,
/// `extras.spaceId`, the run's room) and the goal runs in the step's own
/// named conversation (`extras.conversationTitle`, else the label or the
/// step id).
class GoalPursueConfig {
  GoalPursueConfig._({
    required this.agentId,
    required this.objective,
    required this.outputKey,
    required this.contract,
    required this.budgetMicros,
    required this.maxRuns,
    required this.deadlineHours,
  });

  /// The highest cost cap, in micro-dollars (USD 1,000).
  static const int maxBudgetMicros = 1000000000;

  /// The highest run budget.
  static const int maxRunsLimit = 1000;

  /// The latest deadline, in hours (90 days).
  static const int maxDeadlineHours = 2160;

  /// Reads [config]. Throws [FormatException] naming the first problem.
  static GoalPursueConfig parse(PipelineNodeConfig config) {
    final errors = errorsOf(config);
    if (errors.isNotEmpty) {
      throw FormatException(errors.first);
    }
    final extras = config.extras;
    return GoalPursueConfig._(
      agentId: config.agentId!.trim(),
      objective: config.prompt!.trim(),
      outputKey: config.outputKey!.trim(),
      contract: extras['contract'] == null
          ? null
          : GoalContract.fromJson(extras['contract']),
      budgetMicros: extras['budgetMicros'] as int,
      maxRuns: extras['maxRuns'] as int?,
      deadlineHours: extras['deadlineHours'] as int?,
    );
  }

  /// Every problem with [config] as a `goal.pursue` node, for the editor's
  /// save-time validation. Empty when it is valid.
  static List<String> errorsOf(PipelineNodeConfig config) {
    final errors = <String>[];
    if (config.agentId?.trim().isEmpty ?? true) {
      errors.add('goal.pursue needs an agentId: the agent that pursues it');
    }
    if (config.prompt?.trim().isEmpty ?? true) {
      errors.add('goal.pursue needs a prompt: the objective');
    }
    if (config.outputKey?.trim().isEmpty ?? true) {
      errors.add('goal.pursue needs an outputKey for {summary, verdict}');
    }
    final extras = config.extras;
    final contract = extras['contract'];
    if (contract != null) {
      try {
        GoalContract.fromJson(contract);
      } on FormatException catch (e) {
        errors.add('goal.pursue contract: ${e.message}');
      } on ArgumentError catch (e) {
        errors.add('goal.pursue contract: ${e.message}');
      }
    }
    _bounded(
      errors,
      extras['budgetMicros'],
      name: 'budgetMicros',
      max: maxBudgetMicros,
      required: true,
    );
    _bounded(errors, extras['maxRuns'], name: 'maxRuns', max: maxRunsLimit);
    _bounded(
      errors,
      extras['deadlineHours'],
      name: 'deadlineHours',
      max: maxDeadlineHours,
    );
    return errors;
  }

  static void _bounded(
    List<String> errors,
    Object? value, {
    required String name,
    required int max,
    bool required = false,
  }) {
    if (value == null) {
      if (required) {
        errors.add('goal.pursue needs extras.$name');
      }
      return;
    }
    if (value is! int || value < 1 || value > max) {
      errors.add('goal.pursue extras.$name must be a whole number, 1 to $max');
    }
  }

  /// The agent that pursues the goal.
  final String agentId;

  /// The objective template.
  final String objective;

  /// The state key of the step's output.
  final String outputKey;

  /// What done means, if written down.
  final GoalContract? contract;

  /// The goal's cost cap, in micro-dollars.
  final int budgetMicros;

  /// The run budget, if any.
  final int? maxRuns;

  /// The deadline in hours from the start, if any.
  final int? deadlineHours;
}

/// What a `goal.pursue` step does once its goal is [goal]: a completed goal
/// completes the step with `{summary, verdict}` under [outputKey]; a failed,
/// cancelled or budget-exhausted goal fails it with the reason; a goal that
/// is still active or paused (`needsReview` included) keeps it suspended.
StepResult goalPursueOutcome(
  AgentGoalRun goal, {
  required String stepId,
  required String outputKey,
}) {
  final link = {goalPursueStateKey(stepId): goal.id};
  switch (goal.status) {
    case AgentGoalStatus.completed:
      return StepResult.ok(
        mutatedState: {...link, outputKey: goalPursueOutput(goal)},
      );
    case AgentGoalStatus.failed:
    case AgentGoalStatus.cancelled:
    case AgentGoalStatus.budgetExhausted:
      final summary = goal.summary?.trim();
      return StepResult.failed(
        'goal.pursue: the goal ended ${goal.status.wire}'
        '${summary == null || summary.isEmpty ? '' : ': $summary'}',
      );
    case AgentGoalStatus.active:
    case AgentGoalStatus.paused:
      return StepResult.suspendUntilTasksComplete([
        goal.id,
      ], mutatedState: link);
  }
}

/// What step [step] does once its goal is [goal] ([goalPursueOutcome] with
/// the node's `outputKey`): how the server settles the step from the goal's
/// settlement. A node whose configuration no longer parses fails the step.
StepResult goalPursueSettlement(
  AgentGoalRun goal,
  PipelineStepDefinition step,
) {
  final GoalPursueConfig config;
  try {
    config = GoalPursueConfig.parse(step.config);
  } on FormatException catch (e) {
    return StepResult.failed(e.message);
  }
  return goalPursueOutcome(goal, stepId: step.id, outputKey: config.outputKey);
}

/// The step's output for a completed [goal]: `{summary, verdict}`, the
/// verdict being the reviewer's (`{verdict, items, concerns}`) or null when
/// a person approved the completion without one.
Map<String, Object?> goalPursueOutput(AgentGoalRun goal) => {
  'summary': goal.summary ?? '',
  'verdict': goal.verification?.verdict?.toJson(),
};
