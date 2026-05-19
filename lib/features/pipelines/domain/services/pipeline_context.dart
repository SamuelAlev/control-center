/// Context passed to each step body closure during execution.
///
/// Carries the mutable pipeline state, identifiers, and trigger payload.
///
/// State is a `Map<String, dynamic>` to keep the engine generic. Use the
/// typed accessors ([requireString], [requireInt], [optional]) at body
/// boundaries so a typo or missing value fails loudly instead of silently
/// reading null.
class PipelineContext {
  /// Creates a [PipelineContext].
  const PipelineContext({
    required this.pipelineRunId,
    required this.templateId,
    required this.stepId,
    required this.stepRunId,
    required this.workspaceId,
    required this.state,
    this.triggerPayload,
    this.dryRun = false,
  });

  /// The running pipeline instance.
  final String pipelineRunId;

  /// Template this run is based on.
  final String templateId;

  /// The step definition ID currently executing.
  final String stepId;

  /// The step-run row id — bodies can stream intermediate output back into
  /// the run-detail card by updating `pipeline_step_runs.outputJson` via
  /// the repository while they execute (e.g. live bash stdout).
  final String stepRunId;

  /// Workspace where this pipeline is executing.
  final String workspaceId;

  /// Mutable state bag. Step bodies read from and write to this map.
  /// The engine merges mutations back after each step completes.
  ///
  /// Prefer namespaced writes (`{stepId: {...}}`) over flat keys so parallel
  /// branches can't collide on the same name.
  final Map<String, dynamic> state;

  /// Payload from the domain event that triggered this pipeline run.
  final Map<String, dynamic>? triggerPayload;

  /// When true, side-effecting bodies (bash, agent dispatch, network, ticket
  /// creation) should skip the real action and echo what they would have done.
  final bool dryRun;

  /// Returns a non-empty String state value at [key], or throws.
  String requireString(String key) {
    final v = state[key] ?? triggerPayload?[key];
    if (v is! String || v.isEmpty) {
      throw StateError(
        'Pipeline state "$key" not a non-empty String (got ${v.runtimeType})',
      );
    }
    return v;
  }

  /// Returns an int state value at [key], or throws.
  int requireInt(String key) {
    final v = state[key] ?? triggerPayload?[key];
    if (v is! int) {
      throw StateError(
        'Pipeline state "$key" not int (got ${v.runtimeType})',
      );
    }
    return v;
  }

  /// Returns the value at [key] cast to `T`, or null if absent.
  T? optional<T>(String key) {
    final v = state[key] ?? triggerPayload?[key];
    if (v == null) {
      return null;
    }
    if (v is! T) {
      throw StateError(
        'Pipeline state "$key" not $T (got ${v.runtimeType})',
      );
    }
    return v;
  }
}
