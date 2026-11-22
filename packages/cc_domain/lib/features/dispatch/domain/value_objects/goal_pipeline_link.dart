/// The pipeline step a goal was started for (`goal.pursue`): the goal's
/// settlement settles that step, its runs are charged to that pipeline run,
/// and its segments stop at the cap of the orchestration that owns the run.
///
/// Stored with the goal (`agent_goal_runs.pipeline_run_id` and
/// `pipeline_step_id`), in the goal's own workspace database: the run and the
/// goal always share a workspace. Set once, at the start, and never changed.
/// Wire form: `{pipeline_run_id, pipeline_step_id}`.
class GoalPipelineLink {
  /// Creates a link. Throws [ArgumentError] on an empty id.
  GoalPipelineLink({required this.pipelineRunId, required this.stepId}) {
    if (pipelineRunId.isEmpty) {
      throw ArgumentError('pipelineRunId must not be empty');
    }
    if (stepId.isEmpty) {
      throw ArgumentError('stepId must not be empty');
    }
  }

  /// The link of a stored row: null when the row has neither column, or
  /// only one of them (a link is both or nothing).
  static GoalPipelineLink? tryOf(String? pipelineRunId, String? stepId) {
    if (pipelineRunId == null ||
        pipelineRunId.isEmpty ||
        stepId == null ||
        stepId.isEmpty) {
      return null;
    }
    return GoalPipelineLink(pipelineRunId: pipelineRunId, stepId: stepId);
  }

  /// The pipeline run whose step pursues the goal.
  final String pipelineRunId;

  /// The `goal.pursue` step of [pipelineRunId].
  final String stepId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalPipelineLink &&
          pipelineRunId == other.pipelineRunId &&
          stepId == other.stepId;

  @override
  int get hashCode => Object.hash(pipelineRunId, stepId);

  @override
  String toString() => 'GoalPipelineLink($pipelineRunId, $stepId)';
}
