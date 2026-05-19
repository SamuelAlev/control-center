import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';
import 'package:cc_domain/features/model_routing/domain/services/models_dev_parser.dart';
import 'package:cc_domain/features/model_routing/domain/services/provider_policy_engine.dart';
import 'package:cc_domain/features/model_routing/domain/services/small_model_router.dart';

/// Resolves a provider's enablement (env var set? account present?). Supplied
/// by the host — pure domain code never reads `Platform.environment` directly.
typedef ProviderEnablementResolver =
    ProviderEnablement Function(ModelProvider provider);

/// The unified, in-memory provider/model catalog and its query surface.
///
/// A `Map<providerID, {provider, models}>`
/// with `provider.{get,all,available}` and `model.{get,all,default,small}`.
/// Instances are immutable; [finalize] returns a new catalog with enablement
/// resolved and policy-denied providers removed.
class ModelCatalog {
  /// Creates a catalog from an ordered provider map.
  const ModelCatalog(this._providers, {this.defaultModel});

  /// Assembles a catalog from a parsed models.dev document plus optional
  /// per-provider overrides (merged shallowly onto the parsed models).
  factory ModelCatalog.fromModelsDev(
    Map<String, dynamic> modelsDevJson, {
    Map<String, ModelInfo> overrides = const {},
  }) {
    final providers = ModelsDevParser.parse(modelsDevJson);
    if (overrides.isEmpty) {
      return ModelCatalog(providers);
    }
    final merged = <String, ProviderEntry>{};
    for (final e in providers.entries) {
      final models = Map<String, ModelInfo>.from(e.value.models);
      merged[e.key] = ProviderEntry(provider: e.value.provider, models: models);
    }
    for (final ov in overrides.values) {
      final entry = merged[ov.providerId];
      if (entry != null) {
        entry.models[ov.id] = ov;
      }
    }
    return ModelCatalog(merged);
  }

  /// An empty catalog.
  static const ModelCatalog empty = ModelCatalog({});

  final Map<String, ProviderEntry> _providers;

  /// The catalog-wide default model, if one is pinned.
  final ModelRef? defaultModel;

  // ---- provider queries -----------------------------------------------------

  /// Returns the provider with [id], or null.
  ModelProvider? providerGet(String id) => _providers[id]?.provider;

  /// All providers, in catalog order.
  List<ModelProvider> providerAll() => [
    for (final e in _providers.values) e.provider,
  ];

  /// Only enabled providers.
  List<ModelProvider> providerAvailable() => [
    for (final e in _providers.values)
      if (e.provider.isEnabled) e.provider,
  ];

  // ---- model queries ---------------------------------------------------------

  /// Returns the model `providerId/modelId`, or null.
  ModelInfo? modelGet(String providerId, String modelId) =>
      _providers[providerId]?.models[modelId];

  /// Resolves a [ModelRef] (string or parsed) to a model, or null.
  ModelInfo? resolve(String qualifiedId) {
    final ref = ModelRef.parse(qualifiedId);
    return modelGet(ref.providerId, ref.modelId);
  }

  /// All models across all providers, sorted newest-released first.
  List<ModelInfo> modelAll() {
    final all = <ModelInfo>[
      for (final e in _providers.values) ...e.models.values,
    ];
    all.sort(_byReleaseDesc);
    return all;
  }

  /// Models from enabled providers, that are themselves enabled and not
  /// deprecated. Sorted newest-released first.
  List<ModelInfo> modelAvailable() {
    final all = <ModelInfo>[
      for (final e in _providers.values)
        if (e.provider.isEnabled)
          for (final m in e.models.values)
            if (m.enabled && m.status != ModelStatus.deprecated) m,
    ];
    all.sort(_byReleaseDesc);
    return all;
  }

  /// Models belonging to one provider, sorted newest-released first.
  List<ModelInfo> modelsForProvider(String providerId) {
    final entry = _providers[providerId];
    if (entry == null) {
      return const [];
    }
    final list = entry.models.values.toList()..sort(_byReleaseDesc);
    return list;
  }

  /// The default model: the pinned [defaultModel] if present and available,
  /// else the newest-released available model.
  ModelInfo? modelDefault() {
    final pinned = defaultModel;
    if (pinned != null) {
      final m = modelGet(pinned.providerId, pinned.modelId);
      if (m != null && m.enabled) {
        return m;
      }
    }
    final available = modelAvailable();
    return available.isEmpty ? null : available.first;
  }

  /// The cheapest recent text-capable model for utility tasks. Scoped to a
  /// provider when [providerId] is given, otherwise across all enabled
  /// providers. See [SmallModelRouter].
  ModelInfo? modelSmall({String? providerId, DateTime? now}) {
    final candidates = providerId != null
        ? modelsForProvider(providerId)
        : modelAll();
    return SmallModelRouter.pick(candidates, now: now);
  }

  // ---- mutation (returns new catalog) ---------------------------------------

  /// Resolves each provider's enablement and (when a [policy] is given) removes
  /// policy-denied providers and flips their models' [ModelInfo.enabled] flag.
  /// This is the catalog `finalize`.
  ModelCatalog finalize({
    required ProviderEnablementResolver enablement,
    ProviderPolicyEngine? policy,
  }) {
    final out = <String, ProviderEntry>{};
    for (final e in _providers.entries) {
      final denied =
          policy != null && !policy.allowsProvider(e.value.provider.id);
      if (denied) {
        continue; // policy-denied providers are unselectable (removed)
      }
      final resolvedProvider = e.value.provider.withEnablement(
        enablement(e.value.provider),
      );
      final providerEnabled = resolvedProvider.isEnabled;
      final models = <String, ModelInfo>{
        for (final m in e.value.models.entries)
          m.key: m.value.copyWith(enabled: providerEnabled),
      };
      out[e.key] = ProviderEntry(provider: resolvedProvider, models: models);
    }
    return ModelCatalog(out, defaultModel: defaultModel);
  }

  /// Returns a copy with a pinned [defaultModel].
  ModelCatalog withDefault(ModelRef? ref) =>
      ModelCatalog(_providers, defaultModel: ref);

  /// The number of providers in the catalog.
  int get providerCount => _providers.length;

  /// The total number of models in the catalog.
  int get modelCount =>
      _providers.values.fold(0, (n, e) => n + e.models.length);

  static int _byReleaseDesc(ModelInfo a, ModelInfo b) {
    // Explicit priority wins (lower = first).
    final pa = a.priority, pb = b.priority;
    if (pa != null || pb != null) {
      final cmp = (pa ?? 1 << 30).compareTo(pb ?? 1 << 30);
      if (cmp != 0) {
        return cmp;
      }
    }
    final ra = a.releasedAt, rb = b.releasedAt;
    if (ra != null && rb != null) {
      final cmp = rb.compareTo(ra); // newest first
      if (cmp != 0) {
        return cmp;
      }
    } else if (ra != null) {
      return -1;
    } else if (rb != null) {
      return 1;
    }
    return a.qualifiedId.compareTo(b.qualifiedId);
  }
}
