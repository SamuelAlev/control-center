/// Per-model metadata overrides for one provider's model — the settings UI's
/// "edit model" payload.
///
/// **Why this exists.** Model metadata (context window, output ceiling,
/// modalities) normally comes from the provider's live endpoint, enriched by
/// the models.dev catalog. Both are sometimes wrong or missing: a proxy
/// fronting several deployments reports one window for all of them, a
/// brand-new model has no catalog entry yet, and a custom endpoint may not
/// implement `/models` at all. An override lets the operator state the truth
/// once; it wins over live and catalog data everywhere the model is resolved
/// (the settings list, the picker and dispatch's compaction window).
///
/// Every field is nullable and null means "inherit from the endpoint/catalog".
/// [manual] marks a model the user registered by hand — one the endpoint did
/// not report (or could not, because it has no list endpoint). A manual model
/// with no metadata fields set still exists as a list entry, so [isEmpty]
/// treats `manual` as content.
class ProviderModelOverride {
  /// Creates a [ProviderModelOverride].
  const ProviderModelOverride({
    this.contextWindow,
    this.maxOutputTokens,
    this.inputModalities = const [],
    this.outputModalities = const [],
    this.manual = false,
  }) : assert(
         contextWindow == null || contextWindow > 0,
         'contextWindow must be positive',
       ),
       assert(
         maxOutputTokens == null || maxOutputTokens > 0,
         'maxOutputTokens must be positive',
       );

  /// Rebuilds from a persisted / wire map. Out-of-range and wrong-typed values
  /// are dropped rather than thrown: a hand-edited credentials file must not
  /// make the provider unusable.
  factory ProviderModelOverride.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProviderModelOverride();
    }
    int? intField(String key) {
      final raw = json[key];
      if (raw is! num) {
        return null;
      }
      final value = raw.toInt();
      return value > 0 ? value : null;
    }

    List<String> stringList(String key) => [
      for (final v in (json[key] as List?) ?? const [])
        if (v is String && knownModalities.contains(v)) v,
    ];

    return ProviderModelOverride(
      contextWindow: intField('contextWindow'),
      maxOutputTokens: intField('maxOutputTokens'),
      inputModalities: stringList('inputModalities'),
      outputModalities: stringList('outputModalities'),
      manual: json['manual'] as bool? ?? false,
    );
  }

  /// The modality vocabulary shared with models.dev's `modalities` field.
  /// Kept as raw strings (not an enum) so an unknown token round-trips instead
  /// of throwing on parse.
  static const knownModalities = {'text', 'image', 'audio', 'video', 'pdf'};

  /// Total context window in tokens, or null to inherit.
  final int? contextWindow;

  /// Maximum output tokens per turn, or null to inherit.
  final int? maxOutputTokens;

  /// Accepted input modalities (models.dev tokens: `text`, `image`, …).
  /// Empty means "inherit".
  final List<String> inputModalities;

  /// Produced output modalities. Empty means "inherit".
  final List<String> outputModalities;

  /// Whether the user registered this model by hand (the endpoint did not
  /// report it). Manual models are listed even when the endpoint cannot be
  /// reached or has no list endpoint.
  final bool manual;

  /// Whether nothing is overridden and the model is not manual — such an
  /// entry should not be persisted at all.
  bool get isEmpty =>
      contextWindow == null &&
      maxOutputTokens == null &&
      inputModalities.isEmpty &&
      outputModalities.isEmpty &&
      !manual;

  /// Whether at least one field is set.
  bool get isNotEmpty => !isEmpty;

  /// Serializes to a JSON-ready map, omitting unset fields.
  Map<String, dynamic> toJson() => {
    if (contextWindow != null) 'contextWindow': contextWindow,
    if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
    if (inputModalities.isNotEmpty) 'inputModalities': inputModalities,
    if (outputModalities.isNotEmpty) 'outputModalities': outputModalities,
    if (manual) 'manual': true,
  };

  /// The RPC-argument form of [toJson]: the `providers.*` ops take snake_case
  /// keys while the credentials file persists camelCase.
  Map<String, dynamic> toWireArgs() => {
    if (contextWindow != null) 'context_window': contextWindow,
    if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
    if (inputModalities.isNotEmpty) 'input_modalities': inputModalities,
    if (outputModalities.isNotEmpty) 'output_modalities': outputModalities,
    if (manual) 'manual': true,
  };

  @override
  bool operator ==(Object other) =>
      other is ProviderModelOverride &&
      other.contextWindow == contextWindow &&
      other.maxOutputTokens == maxOutputTokens &&
      _listEquals(other.inputModalities, inputModalities) &&
      _listEquals(other.outputModalities, outputModalities) &&
      other.manual == manual;

  @override
  int get hashCode => Object.hash(
    contextWindow,
    maxOutputTokens,
    Object.hashAll(inputModalities),
    Object.hashAll(outputModalities),
    manual,
  );

  @override
  String toString() => 'ProviderModelOverride(${toJson()})';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
