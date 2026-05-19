/// Context passed to each step body closure during execution.
///
/// Carries the mutable pipeline state, identifiers and trigger payload.
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
    Future<T> Function<T>(Future<T> Function() action)? idleRunner,
  }) : _idleRunner = idleRunner;

  /// Supplied by the engine so [whileWaiting] can hand the step's concurrency
  /// permit back. Null when a body runs outside an engine (tests, direct
  /// invocation), where there is no budget to give up.
  final Future<T> Function<T>(Future<T> Function() action)? _idleRunner;

  /// Runs [action] WITHOUT holding the engine's step-concurrency permit, and
  /// re-takes one before returning.
  ///
  /// The engine caps how many step bodies execute at once, across every
  /// workspace on the host, to bound how much real work is in flight. A body
  /// that is merely *waiting* on something it did not start is not work, and a
  /// permit held through the wait turns that cap into head-of-line blocking:
  /// enough steps parked in a three-minute checkout poll and every other
  /// pipeline on the host queues behind them, deterministic ones included.
  ///
  /// Use it ONLY for genuinely idle waits — polling, watching for an external
  /// signal. Do not wrap work that consumes the machine (a subprocess, a
  /// dispatch that starts agents): the cap exists to bound exactly that, and
  /// releasing a permit for it is how a fan-out dispatches everything at once.
  ///
  /// Re-acquisition can itself block when the host is busy, which is the
  /// intended back-pressure: the body resumes when there is budget for it. The
  /// permit is always re-taken, including when [action] throws, so the engine's
  /// own release stays balanced.
  Future<T> whileWaiting<T>(Future<T> Function() action) {
    final runner = _idleRunner;
    return runner == null ? action() : runner(action);
  }

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

  /// State map used for `{{placeholder}}` rendering in node prompts and bash
  /// scripts: the run-context identifiers (`workspaceId`, `pipelineRunId`,
  /// `stepId`) as a base layer, overlaid by the mutable [state] so a real
  /// state key always wins.
  ///
  /// These identifiers live on the context — not in [state] or
  /// [triggerPayload] — yet node prompts routinely reference `{{workspace_id}}`
  /// (and declare it in `inputKeys`). Exposing them here is the single place
  /// that makes those placeholders resolve; without it `{{workspace_id}}` is an
  /// unresolved placeholder and the step fails. Returns a fresh map, so it
  /// never mutates [state] (bodies still read/write [state] for persistence).
  Map<String, dynamic> get renderState => {
    'workspace_id': workspaceId,
    'pipeline_run_id': pipelineRunId,
    'step_id': stepId,
    ...state,
  };

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
      throw StateError('Pipeline state "$key" not int (got ${v.runtimeType})');
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
      throw StateError('Pipeline state "$key" not $T (got ${v.runtimeType})');
    }
    return v;
  }
}
