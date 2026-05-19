import 'package:cc_harness/tools.dart';

/// Spawns a disposable subagent to handle a focused sub-task.
///
/// The subagent runs its own agent loop with its own system prompt + tool set
/// (chosen by `subagent_type`) and returns a result summary to the parent. The
/// call BLOCKS the parent turn until the subagent finishes. Nesting is capped at
/// `maxSubagentDepth` levels: a child that has reached the cap is built without
/// this tool, so the ceiling is structural rather than advisory. The child's own
/// system prompt states whether it may spawn, so the two can never disagree.
///
/// Read-tier + self-guarding: spawning never prompts. Gating happens on the
/// child's individual tools (which inherit the parent's approval callback).
class TaskTool extends HarnessTool {
  /// Creates a [TaskTool] over [_spawner].
  TaskTool(this._spawner);

  final SubagentSpawner _spawner;

  @override
  String get name => 'task';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  bool get selfGuards => true;

  // Sibling `task` calls in one turn run concurrently. Self-guarding would
  // otherwise exclude the tool from the loop's parallel batch and serialize a
  // fan-out the model explicitly asked for; nothing here needs ordering,
  // because each child gates its own tools.
  @override
  bool get parallelSafe => true;

  @override
  String get description =>
      'Spawn a disposable subagent to handle a focused sub-task. The subagent '
      'runs its own agent loop with its own tools and returns a result '
      'summary. Use it for parallelizable exploration/planning or bounded '
      'sub-tasks. Nesting is capped: a subagent only receives this tool while '
      'it is still within the depth limit, so plan for shallow delegation.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'description': {
        'type': 'string',
        'description': 'The task / prompt for the subagent.',
      },
      'label': {
        'type': 'string',
        'description':
            'Short name shown in the run tree (e.g. "reviews-scraper").',
      },
      'subagent_type': {
        'type': 'string',
        'enum': ['general', 'explore', 'plan'],
        'description':
            'Prompt profile + tool set. general = read/write/exec; '
            'explore = read-only investigation; plan = read-only planning. '
            'Default general.',
      },
      'model': {
        'type': 'string',
        'description': 'Optional provider/model override for the subagent.',
      },
      'effort': {
        'type': 'string',
        'enum': ['low', 'medium', 'high', 'xhigh'],
        'description': 'Optional reasoning-effort override.',
      },
    },
    'required': ['description', 'label'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final description = (args['description'] as String?)?.trim() ?? '';
    final label = (args['label'] as String?)?.trim() ?? '';
    if (description.isEmpty || label.isEmpty) {
      return HarnessToolResult.error(
        'task requires non-empty "description" and "label".',
      );
    }
    final result = await _spawner.spawn(
      SubagentSpawnRequest(
        description: description,
        label: label,
        type: SubagentType.fromId(args['subagent_type'] as String?),
        modelOverride: (args['model'] as String?)?.trim(),
        effortOverride: (args['effort'] as String?)?.trim(),
        context: context,
        spawnToolCallId: context.toolCallId,
      ),
    );
    return result.isError
        ? HarnessToolResult.error(result.text)
        : HarnessToolResult.success(result.text);
  }
}
