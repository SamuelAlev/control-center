import 'package:cc_harness/provider.dart';
import 'package:collection/collection.dart';

/// Lifecycle status of a model, mirroring models.dev's `status` field.
enum ModelStatus {
  /// Generally available and recommended.
  active,

  /// Early-access / experimental.
  alpha,

  /// Public preview.
  beta,

  /// Superseded; should be hidden from default pickers.
  deprecated;

  /// Parses a models.dev status string. Absent / unknown → [active].
  static ModelStatus fromRaw(String? raw) => switch (raw) {
    'alpha' => ModelStatus.alpha,
    'beta' => ModelStatus.beta,
    'deprecated' => ModelStatus.deprecated,
    _ => ModelStatus.active,
  };
}

/// An input or output modality a model supports.
enum ModelModality {
  /// Plain text.
  text,

  /// Raster images.
  image,

  /// Audio clips.
  audio,

  /// Video clips.
  video,

  /// PDF documents.
  pdf;

  /// Parses a models.dev modality token; null for unknown tokens.
  static ModelModality? fromRaw(String raw) => switch (raw) {
    'text' => ModelModality.text,
    'image' => ModelModality.image,
    'audio' => ModelModality.audio,
    'video' => ModelModality.video,
    'pdf' => ModelModality.pdf,
    _ => null,
  };
}

/// Per-million-token pricing for a model. All fields are USD per 1M tokens.
class ModelCost {
  /// Creates a [ModelCost].
  const ModelCost({
    this.input = 0,
    this.output = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
  });

  /// Non-cached input tokens.
  final double input;

  /// Output (text + reasoning + tool-args) tokens.
  final double output;

  /// Cache-read tokens.
  final double cacheRead;

  /// Cache-write tokens.
  final double cacheWrite;

  /// The blended input+output rate used by the small-model heuristic.
  double get blended => input + output;

  /// Whether any non-zero rate is known (a free/unknown model scores 0).
  bool get isKnown => input > 0 || output > 0;

  /// Estimates the USD cost of a request given token counts.
  double estimate({
    int inputTokens = 0,
    int outputTokens = 0,
    int cacheReadTokens = 0,
    int cacheWriteTokens = 0,
  }) =>
      (inputTokens * input +
          outputTokens * output +
          cacheReadTokens * cacheRead +
          cacheWriteTokens * cacheWrite) /
      1000000.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelCost &&
          input == other.input &&
          output == other.output &&
          cacheRead == other.cacheRead &&
          cacheWrite == other.cacheWrite;

  @override
  int get hashCode => Object.hash(input, output, cacheRead, cacheWrite);
}

/// Token limits for a model.
class ModelLimits {
  /// Creates a [ModelLimits].
  const ModelLimits({this.context, this.maxInput, this.maxOutput});

  /// Total context window in tokens (input + output), if documented.
  final int? context;

  /// Maximum input tokens, if separately documented.
  final int? maxInput;

  /// Maximum output tokens, if documented.
  final int? maxOutput;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelLimits &&
          context == other.context &&
          maxInput == other.maxInput &&
          maxOutput == other.maxOutput;

  @override
  int get hashCode => Object.hash(context, maxInput, maxOutput);
}

/// Reasoning capability metadata for a model.
///
/// [effortRouting] remaps a unified
/// effort to a *different upstream model id* (e.g. a high-effort variant);
/// [effortBudgets] gives explicit thinking-token budgets per effort.
class ThinkingConfig {
  /// Creates a [ThinkingConfig].
  const ThinkingConfig({
    this.efforts = const [],
    this.defaultLevel,
    this.effortRouting = const {},
    this.effortBudgets = const {},
    this.requiresEffort = false,
  });

  /// User-facing effort levels this model accepts, least → most intensive.
  final List<ReasoningEffort> efforts;

  /// The effort to use when the user has not chosen one.
  final ReasoningEffort? defaultLevel;

  /// Per-effort remap to a different upstream model id (smart routing).
  final Map<ReasoningEffort, String> effortRouting;

  /// Per-effort explicit thinking-token budget.
  final Map<ReasoningEffort, int> effortBudgets;

  /// When true, reasoning is mandatory — the model rejects a no-thinking call.
  final bool requiresEffort;

  /// Whether this model exposes any reasoning control at all.
  bool get isReasoning => efforts.isNotEmpty;

  /// Returns the requested effort if supported, otherwise the nearest supported
  /// effort (clamped by ordinal), otherwise [defaultLevel] / the first level.
  ReasoningEffort? resolve(ReasoningEffort? requested) {
    if (efforts.isEmpty) {
      return null;
    }
    if (requested == null) {
      return defaultLevel ?? efforts.first;
    }
    if (efforts.contains(requested)) {
      return requested;
    }
    // Nearest by ordinal distance.
    return efforts.reduce(
      (a, b) =>
          (a.index - requested.index).abs() <= (b.index - requested.index).abs()
          ? a
          : b,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThinkingConfig &&
          const ListEquality<ReasoningEffort>().equals(
            efforts,
            other.efforts,
          ) &&
          defaultLevel == other.defaultLevel &&
          const MapEquality<ReasoningEffort, String>().equals(
            effortRouting,
            other.effortRouting,
          ) &&
          const MapEquality<ReasoningEffort, int>().equals(
            effortBudgets,
            other.effortBudgets,
          ) &&
          requiresEffort == other.requiresEffort;

  @override
  int get hashCode => Object.hash(
    const ListEquality<ReasoningEffort>().hash(efforts),
    defaultLevel,
    const MapEquality<ReasoningEffort, String>().hash(effortRouting),
    const MapEquality<ReasoningEffort, int>().hash(effortBudgets),
    requiresEffort,
  );
}

/// A named capability preset for a model.
///
/// One model row can expose `fast` / `standard` / `high` presets without
/// duplicating the whole config. Selection is separate from the model id
/// (which can itself contain slashes).
class ModelVariant {
  /// Creates a [ModelVariant].
  const ModelVariant({
    required this.id,
    this.label,
    this.headers = const {},
    this.body = const {},
  });

  /// Variant id (e.g. `'high'`).
  final String id;

  /// Optional display label.
  final String? label;

  /// Extra request headers this variant injects.
  final Map<String, String> headers;

  /// Extra request-body fields this variant injects.
  final Map<String, dynamic> body;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelVariant &&
          id == other.id &&
          label == other.label &&
          const MapEquality<String, String>().equals(headers, other.headers) &&
          const DeepCollectionEquality().equals(body, other.body);

  @override
  int get hashCode => Object.hash(
    id,
    label,
    const MapEquality<String, String>().hash(headers),
    const DeepCollectionEquality().hash(body),
  );
}

/// A single model in the catalog, carrying cost, limits, capabilities, status,
/// reasoning config, variants, and an optional context-promotion target.
///
/// Equality is by ([providerId], [id]) — the catalog key. [enabled] is a
/// resolved flag set during catalog `finalize` (provider enablement ∧ policy).
class ModelInfo {
  /// Creates a [ModelInfo].
  const ModelInfo({
    required this.id,
    required this.providerId,
    required this.name,
    this.requestModelId,
    this.family,
    this.reasoning = false,
    this.supportsTools = false,
    this.supportsTemperature = false,
    this.inputModalities = const [ModelModality.text],
    this.outputModalities = const [ModelModality.text],
    this.cost,
    this.limits = const ModelLimits(),
    this.status = ModelStatus.active,
    this.releasedAt,
    this.lastUpdatedAt,
    this.knowledgeCutoff,
    this.contextPromotionTarget,
    this.priority,
    this.thinking,
    this.variants = const [],
    this.enabled = true,
  });

  /// Local model id (e.g. `claude-opus-4-5`). May contain slashes.
  final String id;

  /// Owning provider id (e.g. `anthropic`).
  final String providerId;

  /// Human-readable name.
  final String name;

  /// Wire id to send upstream when it differs from [id] (e.g. a long-context
  /// variant that attributes locally to [id]).
  final String? requestModelId;

  /// Model family (e.g. `claude-opus`).
  final String? family;

  /// Whether the model supports extended reasoning.
  final bool reasoning;

  /// Whether the model supports tool/function calls.
  final bool supportsTools;

  /// Whether the model honors a temperature parameter.
  final bool supportsTemperature;

  /// Accepted input modalities.
  final List<ModelModality> inputModalities;

  /// Produced output modalities.
  final List<ModelModality> outputModalities;

  /// Pricing, if known.
  final ModelCost? cost;

  /// Token limits.
  final ModelLimits limits;

  /// Lifecycle status.
  final ModelStatus status;

  /// Release date, if documented.
  final DateTime? releasedAt;

  /// Last-updated date, if documented.
  final DateTime? lastUpdatedAt;

  /// Knowledge cutoff date, if documented.
  final DateTime? knowledgeCutoff;

  /// The model id to escalate to when the context window fills (feature #7).
  final String? contextPromotionTarget;

  /// Sort priority (lower = higher priority). Null sorts after explicit values.
  final int? priority;

  /// Reasoning config, if the model exposes effort control.
  final ThinkingConfig? thinking;

  /// Named capability presets (feature #14).
  final List<ModelVariant> variants;

  /// Whether the model is selectable (provider enabled ∧ not policy-denied).
  final bool enabled;

  /// The fully-qualified catalog ref, `providerId/id`.
  String get qualifiedId => '$providerId/$id';

  /// The id to send on the wire (defaults to [id]).
  String get wireId => requestModelId ?? id;

  /// Whether the model accepts text in and emits text out (the small-model
  /// router's hard requirement).
  bool get isTextCapable =>
      inputModalities.contains(ModelModality.text) &&
      outputModalities.contains(ModelModality.text);

  /// Whether the model accepts image input (multimodal).
  bool get supportsImageInput => inputModalities.contains(ModelModality.image);

  /// Looks up a variant by id.
  ModelVariant? variant(String id) =>
      variants.firstWhereOrNull((v) => v.id == id);

  /// Returns a copy with selected fields overridden.
  ModelInfo copyWith({
    bool? enabled,
    ModelStatus? status,
    ThinkingConfig? thinking,
    List<ModelVariant>? variants,
    String? contextPromotionTarget,
    int? priority,
  }) => ModelInfo(
    id: id,
    providerId: providerId,
    name: name,
    requestModelId: requestModelId,
    family: family,
    reasoning: reasoning,
    supportsTools: supportsTools,
    supportsTemperature: supportsTemperature,
    inputModalities: inputModalities,
    outputModalities: outputModalities,
    cost: cost,
    limits: limits,
    status: status ?? this.status,
    releasedAt: releasedAt,
    lastUpdatedAt: lastUpdatedAt,
    knowledgeCutoff: knowledgeCutoff,
    contextPromotionTarget:
        contextPromotionTarget ?? this.contextPromotionTarget,
    priority: priority ?? this.priority,
    thinking: thinking ?? this.thinking,
    variants: variants ?? this.variants,
    enabled: enabled ?? this.enabled,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelInfo && id == other.id && providerId == other.providerId;

  @override
  int get hashCode => Object.hash(id, providerId);

  @override
  String toString() => 'ModelInfo($qualifiedId)';
}

/// A parsed reference to a model: `providerId/modelId` with an optional
/// variant. The model id may itself contain slashes, so only the first segment
/// is the provider.
class ModelRef {
  /// Creates a [ModelRef].
  const ModelRef({
    required this.providerId,
    required this.modelId,
    this.variant,
  });

  /// Parses `providerId/modelId[#variant]`. When no `/` is present the whole
  /// string is treated as the model id with an empty provider.
  static ModelRef parse(String input) {
    var rest = input;
    String? variant;
    final hash = rest.lastIndexOf('#');
    if (hash > 0) {
      variant = rest.substring(hash + 1);
      rest = rest.substring(0, hash);
    }
    final slash = rest.indexOf('/');
    if (slash < 0) {
      return ModelRef(providerId: '', modelId: rest, variant: variant);
    }
    return ModelRef(
      providerId: rest.substring(0, slash),
      modelId: rest.substring(slash + 1),
      variant: variant,
    );
  }

  /// The provider id (may be empty when the input had no `/`).
  final String providerId;

  /// The model id (may contain slashes).
  final String modelId;

  /// The selected variant id, if any.
  final String? variant;

  /// The canonical `providerId/modelId` form (without the variant suffix).
  String get qualifiedId =>
      providerId.isEmpty ? modelId : '$providerId/$modelId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelRef &&
          providerId == other.providerId &&
          modelId == other.modelId &&
          variant == other.variant;

  @override
  int get hashCode => Object.hash(providerId, modelId, variant);

  @override
  String toString() => variant == null ? qualifiedId : '$qualifiedId#$variant';
}
