import 'package:cc_harness/src/loop/agent_loop.dart' show AgentLoop;
import 'package:cc_harness/src/tools/subagent_profile.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// A port the `task` tool calls to run a nested agent loop to completion and
/// get its result.
///
/// The implementation is provided by the dispatch layer (where the provider
/// factory, run-log writer, and [AgentLoop] runner live), so the tool itself
/// stays free of infrastructure. Depth is capped by the implementation at
/// [maxSubagentDepth] levels: a subagent that has reached the cap is built with
/// a tool set that omits `task`, so it cannot nest further.
abstract interface class SubagentSpawner {
  /// Runs a subagent for [request] and returns its result.
  Future<SubagentResult> spawn(SubagentSpawnRequest request);
}

/// A request to spawn one ephemeral subagent.
class SubagentSpawnRequest {
  /// Creates a [SubagentSpawnRequest].
  const SubagentSpawnRequest({
    required this.description,
    required this.label,
    required this.type,
    required this.context,
    this.modelOverride,
    this.effortOverride,
    this.spawnToolCallId,
  });

  /// The task / prompt for the subagent.
  final String description;

  /// Short display label shown in the run tree (e.g. `reviews-scraper`).
  final String label;

  /// The subagent behaviour profile to use.
  final SubagentType type;

  /// The parent tool-call context (workspace, conversation, cwd, agent).
  final HarnessToolContext context;

  /// Optional `provider/model` override for the child.
  final String? modelOverride;

  /// Optional reasoning-effort override for the child.
  final String? effortOverride;

  /// Id of the parent's `task` tool call that is spawning this subagent, when
  /// known. Recorded on the child run so the tool row in the parent's transcript
  /// can open the child's activity.
  final String? spawnToolCallId;
}

/// The result of a subagent run.
class SubagentResult {
  /// Creates a [SubagentResult].
  const SubagentResult({
    required this.text,
    this.isError = false,
    this.childRunId,
  });

  /// The subagent's final assistant text (returned to the parent as the tool
  /// result).
  final String text;

  /// Whether the subagent ended in an error state.
  final bool isError;

  /// The child run-log id, when one was written.
  final String? childRunId;
}
