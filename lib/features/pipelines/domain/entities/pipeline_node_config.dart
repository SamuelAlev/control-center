import 'package:collection/collection.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart' show PipelineStepDefinition;

/// Per-node configuration carried inside a [PipelineStepDefinition].
///
/// Both built-in nodes (those bound to a code-registered `bodyKey`) and
/// custom nodes (rendered through the generic `pipeline.promptAgent` body)
/// share this shape. Each body reads only the fields it cares about; the
/// rest stay null.
///
/// Stored as the per-node `config` blob inside the template `nodesJson`
/// column and re-hydrated by the template repository.
class PipelineNodeConfig {

  /// Decodes a [PipelineNodeConfig] from JSON.
  factory PipelineNodeConfig.fromJson(Map<String, dynamic> json) {
    return PipelineNodeConfig(
      prompt: json['prompt'] as String?,
      script: json['script'] as String?,
      agentId: json['agentId'] as String?,
      inputKeys: (json['inputKeys'] as List?)?.cast<String>() ?? const [],
      outputKey: json['outputKey'] as String?,
      label: json['label'] as String?,
      outputSchema:
          (json['outputSchema'] as Map?)?.cast<String, dynamic>(),
      reducer: json['reducer'] as String?,
      retryPolicy: json['retryPolicy'] is Map
          ? StepRetryPolicy.fromJson(
              (json['retryPolicy'] as Map).cast<String, dynamic>())
          : null,
      continueOnFail: json['continueOnFail'] as bool? ?? false,
      timeoutMs: (json['timeoutMs'] as num?)?.toInt(),
      teamId: json['teamId'] as String?,
      dispatchMode: json['dispatchMode'] as String?,
      extras: (json['extras'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
  /// Creates a [PipelineNodeConfig].
  const PipelineNodeConfig({
    this.prompt,
    this.script,
    this.agentId,
    this.inputKeys = const [],
    this.outputKey,
    this.label,
    this.outputSchema,
    this.reducer,
    this.retryPolicy,
    this.continueOnFail = false,
    this.timeoutMs,
    this.teamId,
    this.dispatchMode,
    this.extras = const {},
  });

  /// Empty configuration — used by nodes that read everything from
  /// pipeline state / trigger payload.
  static const PipelineNodeConfig empty = PipelineNodeConfig();

  /// Prompt template. Supports `{{key}}` substitution against pipeline state
  /// and trigger payload at execution time. Used by `pipeline.promptAgent`
  /// and by reviewer prompt nodes.
  final String? prompt;

  /// Bash script body. Supports `{{key}}` substitution against pipeline
  /// state and trigger payload at execution time. Used by the
  /// `pipeline.bashScript` body to run agentless shell steps (e.g. cloning
  /// the PR branch, running a build, kicking off `gh` commands).
  final String? script;

  /// Workspace-scoped agent id (UUID) this node dispatches. The body
  /// fetches the agent directly via the repository — no role/skill
  /// matching, no name lookups. Required for prompt-based nodes.
  final String? agentId;

  /// State keys this node consumes as input. Used both for `{{key}}`
  /// substitution and to surface dependencies in the editor.
  final List<String> inputKeys;

  /// State key under which this node's stdout is written. Downstream
  /// nodes can pick it up via [inputKeys].
  final String? outputKey;

  /// Optional human label shown on the canvas (defaults to the step ID).
  final String? label;

  /// Optional JSON Schema (subset) the node's output value (the value written
  /// under [outputKey]) must satisfy. Validated by the engine before the
  /// value is merged into pipeline state. Null means no validation.
  final Map<String, dynamic>? outputSchema;

  /// Optional merge strategy applied when this node writes [outputKey] and a
  /// value already exists for that key (e.g. parallel branches writing the
  /// same key). One of `append`, `mergeLists`, `mergeMaps`, `sum`, or
  /// `override` (default). Null behaves like `override`.
  final String? reducer;

  /// Optional retry policy applied when this node's body fails. Null disables
  /// retries (a single attempt).
  final StepRetryPolicy? retryPolicy;

  /// When true, a terminal failure of this node (after retries) does not fail
  /// the whole run; the error is stashed under `state['_stepErrors'][stepId]`
  /// and downstream evaluation continues.
  final bool continueOnFail;

  /// Optional wall-clock timeout for the node body in milliseconds. When the
  /// body does not settle within this window the step fails (feeding the
  /// retry policy). Null means no timeout.
  final int? timeoutMs;

  /// For `team.dispatch` nodes: the workspace-scoped team id to dispatch.
  /// Mutually exclusive with [agentId].
  final String? teamId;

  /// For `team.dispatch` nodes: how the team executes —
  /// `allParallel` (one task per member, suspend until all complete),
  /// `sequential`, or `manager` (dispatch the leader with delegation).
  final String? dispatchMode;

  /// Free-form extras for body-specific config (e.g. clone target path
  /// override, comment template). Round-trips through JSON unchanged.
  final Map<String, dynamic> extras;

  /// JSON-encodes this config.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (prompt != null) {
      json['prompt'] = prompt;
    }
    if (script != null) {
      json['script'] = script;
    }
    if (agentId != null) {
      json['agentId'] = agentId;
    }
    if (inputKeys.isNotEmpty) {
      json['inputKeys'] = inputKeys;
    }
    if (outputKey != null) {
      json['outputKey'] = outputKey;
    }
    if (label != null) {
      json['label'] = label;
    }
    if (outputSchema != null) {
      json['outputSchema'] = outputSchema;
    }
    if (reducer != null) {
      json['reducer'] = reducer;
    }
    if (retryPolicy != null) {
      json['retryPolicy'] = retryPolicy!.toJson();
    }
    if (continueOnFail) {
      json['continueOnFail'] = true;
    }
    if (timeoutMs != null) {
      json['timeoutMs'] = timeoutMs;
    }
    if (teamId != null) {
      json['teamId'] = teamId;
    }
    if (dispatchMode != null) {
      json['dispatchMode'] = dispatchMode;
    }
    if (extras.isNotEmpty) {
      json['extras'] = extras;
    }
    return json;
  }

  /// Returns a new config with the given fields overridden.
  PipelineNodeConfig copyWith({
    String? prompt,
    String? script,
    String? agentId,
    List<String>? inputKeys,
    String? outputKey,
    String? label,
    Map<String, dynamic>? outputSchema,
    String? reducer,
    StepRetryPolicy? retryPolicy,
    bool? continueOnFail,
    int? timeoutMs,
    String? teamId,
    String? dispatchMode,
    Map<String, dynamic>? extras,
  }) {
    return PipelineNodeConfig(
      prompt: prompt ?? this.prompt,
      script: script ?? this.script,
      agentId: agentId ?? this.agentId,
      inputKeys: inputKeys ?? this.inputKeys,
      outputKey: outputKey ?? this.outputKey,
      label: label ?? this.label,
      outputSchema: outputSchema ?? this.outputSchema,
      reducer: reducer ?? this.reducer,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      continueOnFail: continueOnFail ?? this.continueOnFail,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      teamId: teamId ?? this.teamId,
      dispatchMode: dispatchMode ?? this.dispatchMode,
      extras: extras ?? this.extras,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineNodeConfig &&
          prompt == other.prompt &&
          script == other.script &&
          agentId == other.agentId &&
          const DeepCollectionEquality()
              .equals(inputKeys, other.inputKeys) &&
          outputKey == other.outputKey &&
          label == other.label &&
          const DeepCollectionEquality()
              .equals(outputSchema, other.outputSchema) &&
          reducer == other.reducer &&
          retryPolicy == other.retryPolicy &&
          continueOnFail == other.continueOnFail &&
          timeoutMs == other.timeoutMs &&
          teamId == other.teamId &&
          dispatchMode == other.dispatchMode &&
          const DeepCollectionEquality().equals(extras, other.extras);

  @override
  int get hashCode => Object.hashAll([
        prompt,
        script,
        agentId,
        const DeepCollectionEquality().hash(inputKeys),
        outputKey,
        label,
        const DeepCollectionEquality().hash(outputSchema),
        reducer,
        retryPolicy,
        continueOnFail,
        timeoutMs,
        teamId,
        dispatchMode,
        const DeepCollectionEquality().hash(extras),
      ]);
}

/// Retry behaviour for a failing node body.
class StepRetryPolicy {
  /// Creates a [StepRetryPolicy].
  const StepRetryPolicy({
    this.maxAttempts = 1,
    this.backoff = 'exponential',
    this.initialDelayMs = 1000,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be >= 1');

  /// Decodes from JSON.
  factory StepRetryPolicy.fromJson(Map<String, dynamic> json) {
    return StepRetryPolicy(
      maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 1,
      backoff: json['backoff'] as String? ?? 'exponential',
      initialDelayMs: (json['initialDelayMs'] as num?)?.toInt() ?? 1000,
    );
  }

  /// Total attempts including the first (so 3 = 1 try + 2 retries).
  final int maxAttempts;

  /// Backoff curve between attempts: `linear` or `exponential`.
  final String backoff;

  /// Delay before the first retry, in milliseconds. Subsequent delays grow
  /// per [backoff].
  final int initialDelayMs;

  /// Delay before the retry that follows [attempt] (1-based).
  Duration delayForAttempt(int attempt) {
    final factor = backoff == 'linear' ? attempt : (1 << (attempt - 1));
    return Duration(milliseconds: initialDelayMs * factor);
  }

  /// JSON-encodes this policy.
  Map<String, dynamic> toJson() => {
        'maxAttempts': maxAttempts,
        'backoff': backoff,
        'initialDelayMs': initialDelayMs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepRetryPolicy &&
          maxAttempts == other.maxAttempts &&
          backoff == other.backoff &&
          initialDelayMs == other.initialDelayMs;

  @override
  int get hashCode => Object.hash(maxAttempts, backoff, initialDelayMs);
}
