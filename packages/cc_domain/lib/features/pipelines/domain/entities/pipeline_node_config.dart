import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart'
    show PipelineStepDefinition;
import 'package:collection/collection.dart';

/// Per-node configuration carried inside a [PipelineStepDefinition].
///
/// Both built-in nodes (those bound to a code-registered `bodyKey`) and
/// custom nodes (rendered through the generic `conversation.promptAgent` body)
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
      repoIds: (json['repoIds'] as List?)?.cast<String>() ?? const [],
      outputKey: json['outputKey'] as String?,
      label: json['label'] as String?,
      outputSchema: (json['outputSchema'] as Map?)?.cast<String, dynamic>(),
      reducer: json['reducer'] as String?,
      retryPolicy: json['retryPolicy'] is Map
          ? StepRetryPolicy.fromJson(
              (json['retryPolicy'] as Map).cast<String, dynamic>(),
            )
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
    this.repoIds = const [],
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
  /// and trigger payload at execution time. Used by `conversation.promptAgent`
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

  /// Workspace-scoped repo ids to provision when this node starts its own
  /// conversation (the space clone/code-index scope).
  ///
  /// Empty (the default) keeps the legacy behavior: the conversation
  /// worktree clones every workspace repo, which is heavy on IO/FS for
  /// workspaces with many repos. A non-empty list scopes provisioning to the
  /// listed repos only. Entries support `{{key}}` substitution against
  /// pipeline state and trigger payload at execution time (e.g.
  /// `['{{repo_id}}']` clones only the repo the run is processing).
  ///
  /// Read by the node that OPENS a conversation (`messaging.createSpace`),
  /// because a conversation IS the checkout. An agent node joins a room it did
  /// not open, so a scope declared there is read by nothing — the validator
  /// rejects it rather than letting an author set it and watch it do nothing.
  ///
  /// An empty list means every workspace repo; `extras['allRepos']` asks for
  /// that explicitly. Entries support `{{key}}` placeholders, so one template
  /// can scope itself to whichever repo its trigger names.
  final List<String> repoIds;

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

  /// The existing conversation this node's agents must work in, when the node
  /// names one (`extras['spaceId']`).
  ///
  /// Generated orchestration / plan pipelines set it to the room the plan was
  /// authored in, so the work streams back where the operator is already
  /// watching. Null (the default) means the step gets its own hidden
  /// conversation.
  String? get spaceId {
    final raw = extras['spaceId'];
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Whether the node that OPENS a room (`messaging.createSpace`) also opens a
  /// conversation in it (`extras['createConversation']`), publishing its id
  /// under `pipelineConversationId`.
  ///
  /// Off by default, and that default is the point: a space and a conversation
  /// are different things — the space owns the checkout, the roster and the
  /// provisioning; conversations are flat streams inside it — so a fan-out
  /// whose steps each open their own named stream must not also be handed one
  /// nobody writes in. Turn it on for a run with a single agent step, naming
  /// the same [conversationTitle] that step uses: the room is then born holding
  /// the stream, instead of standing empty until the agent starts (a window in
  /// which any read of the room mints an untitled standing conversation).
  bool get createsConversation => extras['createConversation'] == true;

  /// The named stream this node works in (`extras['conversationTitle']`), or
  /// null to use the space's standing conversation.
  ///
  /// On an agent step it is the stream inside [spaceId] its agents write to. A
  /// fan-out of steps sharing one room gives each branch its own titled
  /// conversation, so the space keeps ONE checkout while each agent keeps a
  /// readable thread. Ignored when the node has no [spaceId] — a step that
  /// mints its own hidden room has nothing to share.
  ///
  /// On a `messaging.createSpace` node it names the conversation
  /// [createsConversation] opens, and is read only when that is on.
  String? get conversationTitle {
    final raw = extras['conversationTitle'];
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// The conversation mode this node's agents run under (`extras['mode']`:
  /// `chat` / `review` / `plan`), or null to inherit the body's default.
  ///
  /// Note the KEY: a node that writes any other spelling is silently ignored,
  /// which is how a generated orchestration step ends up read-only.
  ///
  /// It governs on the node that OPENS a room (`messaging.createSpace`). An
  /// agent step joins a room it did not create, and a room's mode belongs to
  /// whoever opened it — a step ending is no reason to re-permission a
  /// conversation its siblings are still working in. So a content-generating
  /// agent step needs `chat` on its SPACE node: `review`/`plan` map to
  /// Claude's read-only `--permission-mode plan`, and a step that must submit
  /// output cannot run under it.
  String? get modeName {
    final raw = extras['mode'];
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  /// The condition gating whether this node runs at all
  /// (`extras['runWhen']`), or null when the node always runs.
  ///
  /// Read by the engine before the step is dispatched. A node whose condition
  /// is unmet is recorded as skipped rather than omitted, so the run timeline
  /// says "deliberately not run" instead of quietly missing a step.
  StepRunCondition? get runWhen {
    final raw = extras['runWhen'];
    return raw is Map
        ? StepRunCondition.fromJson(raw.cast<String, dynamic>())
        : null;
  }

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
    if (repoIds.isNotEmpty) {
      json['repoIds'] = repoIds;
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
    List<String>? repoIds,
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
      repoIds: repoIds ?? this.repoIds,
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
          const DeepCollectionEquality().equals(inputKeys, other.inputKeys) &&
          const DeepCollectionEquality().equals(repoIds, other.repoIds) &&
          outputKey == other.outputKey &&
          label == other.label &&
          const DeepCollectionEquality().equals(
            outputSchema,
            other.outputSchema,
          ) &&
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
    const DeepCollectionEquality().hash(repoIds),
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

/// A declarative gate on whether a node runs, evaluated against the run's
/// state and trigger payload.
///
/// Exists so a template can vary its shape per run without the alternative:
/// one template per variant, each drifting from the others, or a router whose
/// single-branch semantics cannot express "this step runs for two of three
/// modes". The predicate is pure and closed — a value equality test against a
/// fixed list — because a step gate that could run arbitrary logic is a step
/// gate nobody can read off the canvas.
class StepRunCondition {
  /// Creates a [StepRunCondition].
  const StepRunCondition({
    required this.key,
    required this.allowed,
    this.skippedOutput,
  });

  /// Decodes from JSON. An absent or non-list `in` yields an empty allow-list,
  /// which allows nothing — a malformed gate closes rather than opens.
  factory StepRunCondition.fromJson(Map<String, dynamic> json) {
    final raw = json['in'];
    return StepRunCondition(
      key: json['key'] as String? ?? '',
      allowed: raw is List ? List<Object?>.unmodifiable(raw) : const [],
      skippedOutput: json['skippedOutput'] as String?,
    );
  }

  /// The state / trigger-payload key to read.
  final String key;

  /// The values that let the step run. A `null` entry means "runs when the key
  /// is absent", which is what makes a gate added to an existing template
  /// keep working for runs started before the key existed.
  final List<Object?> allowed;

  /// The value merged under the node's `outputKey` when the step is skipped.
  ///
  /// Without it a downstream `{{placeholder}}` naming this step's output would
  /// not resolve, and an unresolved placeholder fails its step — so a skipped
  /// optional reviewer would take the consolidation step down with it.
  final String? skippedOutput;

  /// Whether the step runs given [value] (the resolved key, null when absent).
  bool allows(Object? value) => allowed.contains(value);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'key': key,
    'in': allowed,
    if (skippedOutput != null) 'skippedOutput': skippedOutput,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepRunCondition &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          const DeepCollectionEquality().equals(allowed, other.allowed) &&
          skippedOutput == other.skippedOutput;

  @override
  int get hashCode => Object.hash(
    key,
    const DeepCollectionEquality().hash(allowed),
    skippedOutput,
  );
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
