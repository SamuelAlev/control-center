/// Per-provider generation defaults: the sampling recipe and output ceiling to
/// use for every run on one endpoint.
///
/// **Why per provider.** The harness shipped a single hard-coded 8192-token
/// output ceiling and sent no sampling parameters at all, which is wrong in both
/// directions. Open-weights models publish required recipes — Qwen-family
/// reasoning models ship `temperature`/`top_p`/`top_k` together and serving one
/// at other values degrades it, sometimes out of its own tool-call dialect — and
/// they publish output ceilings that differ from each other by an order of
/// magnitude. A frontier API and a local 35B quant cannot share one number.
///
/// Every field is nullable and null means "do not send it, let the endpoint
/// decide". That keeps the default behavior byte-identical to before for anyone
/// who never opens the setting, so this adds a capability without changing an
/// existing run.
class ProviderGenerationDefaults {
  /// Creates a [ProviderGenerationDefaults].
  const ProviderGenerationDefaults({
    this.maxTokens,
    this.temperature,
    this.topP,
    this.topK,
  }) : assert(maxTokens == null || maxTokens > 0, 'maxTokens must be positive'),
       assert(
         temperature == null || (temperature >= 0 && temperature <= 2),
         'temperature must be in [0, 2]',
       ),
       assert(
         topP == null || (topP > 0 && topP <= 1),
         'topP must be in (0, 1]',
       ),
       assert(topK == null || topK > 0, 'topK must be positive');

  /// Rebuilds from a persisted / wire map. Out-of-range and wrong-typed values
  /// are dropped rather than thrown: a hand-edited config file must not make the
  /// provider unusable.
  factory ProviderGenerationDefaults.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProviderGenerationDefaults();
    }
    final maxTokens = (json['maxTokens'] as num?)?.toInt();
    final temperature = (json['temperature'] as num?)?.toDouble();
    final topP = (json['topP'] as num?)?.toDouble();
    final topK = (json['topK'] as num?)?.toInt();
    return ProviderGenerationDefaults(
      maxTokens: maxTokens != null && maxTokens > 0 ? maxTokens : null,
      temperature: temperature != null && temperature >= 0 && temperature <= 2
          ? temperature
          : null,
      topP: topP != null && topP > 0 && topP <= 1 ? topP : null,
      topK: topK != null && topK > 0 ? topK : null,
    );
  }

  /// Maximum output tokens per turn, or null for the harness default.
  final int? maxTokens;

  /// Sampling temperature, or null to let the endpoint decide.
  final double? temperature;

  /// Nucleus-sampling cutoff, or null to let the endpoint decide.
  final double? topP;

  /// Top-k cutoff, or null to let the endpoint decide. Not every
  /// OpenAI-compatible server accepts it.
  final int? topK;

  /// Whether nothing is configured — the caller should change no request field.
  bool get isEmpty =>
      maxTokens == null && temperature == null && topP == null && topK == null;

  /// Whether at least one field is configured.
  bool get isNotEmpty => !isEmpty;

  /// Returns a copy with the given overrides. Pass a `clear*` flag to unset a
  /// field, since a null argument means "leave unchanged".
  ProviderGenerationDefaults copyWith({
    int? maxTokens,
    double? temperature,
    double? topP,
    int? topK,
    bool clearMaxTokens = false,
    bool clearTemperature = false,
    bool clearTopP = false,
    bool clearTopK = false,
  }) => ProviderGenerationDefaults(
    maxTokens: clearMaxTokens ? null : (maxTokens ?? this.maxTokens),
    temperature: clearTemperature ? null : (temperature ?? this.temperature),
    topP: clearTopP ? null : (topP ?? this.topP),
    topK: clearTopK ? null : (topK ?? this.topK),
  );

  /// Serializes to a JSON-ready map, omitting unset fields.
  Map<String, dynamic> toJson() => {
    if (maxTokens != null) 'maxTokens': maxTokens,
    if (temperature != null) 'temperature': temperature,
    if (topP != null) 'topP': topP,
    if (topK != null) 'topK': topK,
  };

  @override
  bool operator ==(Object other) =>
      other is ProviderGenerationDefaults &&
      other.maxTokens == maxTokens &&
      other.temperature == temperature &&
      other.topP == topP &&
      other.topK == topK;

  @override
  int get hashCode => Object.hash(maxTokens, temperature, topP, topK);

  @override
  String toString() => 'ProviderGenerationDefaults(${toJson()})';
}
