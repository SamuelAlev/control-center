import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_harness/provider.dart';

/// A synchronous, in-memory view of every provider's per-model overrides
/// ([ProviderModelOverride]), backed by the credential store.
///
/// Two consumers need overrides and neither can await: dispatch's
/// `modelResolver` (a sync lookup consulted for cost + the compaction window)
/// and the `providers.listModels` op (async, but answered on the hot RPC path).
/// So the store is read through this cache: refreshed at boot, kept current by
/// the `providers.saveModelOverride` / `providers.removeModelOverride` ops via
/// [setEntry], and reloaded wholesale by [refresh] when the provider set itself
/// changes (a custom provider added or removed).
class HarnessModelOverrideCache {
  /// Creates a cache over [credentials].
  HarnessModelOverrideCache({required ProviderCredentialStore credentials})
    : _credentials = credentials;

  final ProviderCredentialStore _credentials;

  /// providerId → (bare model id → override).
  final Map<String, Map<String, ProviderModelOverride>> _byProvider = {};

  /// The overrides stored for [providerId] (empty when none).
  Map<String, ProviderModelOverride> forProvider(String providerId) =>
      _byProvider[providerId] ?? const {};

  /// Reloads one provider's overrides from the store.
  Future<void> refreshProvider(String providerId) async {
    _byProvider[providerId] = await load(_credentials, providerId);
  }

  /// Reads one provider's merged overrides straight from [credentials] —
  /// overrides are provider-scoped state stored on credential rows, so the
  /// provider's rotation is merged, first stored row winning. Shared by the
  /// cache and the `providers.listModels` op so both merge identically.
  static Future<Map<String, ProviderModelOverride>> load(
    ProviderCredentialStore credentials,
    String providerId,
  ) async {
    final merged = <String, ProviderModelOverride>{};
    for (final cred in await credentials.credentialsFor(providerId)) {
      for (final entry in cred.modelOverrides.entries) {
        merged.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return merged;
  }

  /// Reloads every known provider (built-ins + stored custom definitions).
  Future<void> refresh() async {
    final ids = <String>{...harnessSupportedProviderIds};
    if (_credentials case final CustomProviderLister lister) {
      for (final def in await lister.customProviders()) {
        ids.add(def.providerId);
      }
    }
    for (final id in ids) {
      await refreshProvider(id);
    }
  }

  /// Drops all cached state for [providerId] (the provider was removed).
  void removeProvider(String providerId) {
    _byProvider.remove(providerId);
  }

  /// Upserts ([override] non-null) or removes (null) one entry.
  void setEntry(
    String providerId,
    String modelId,
    ProviderModelOverride? override,
  ) {
    final map = _byProvider.putIfAbsent(
      providerId,
      () => <String, ProviderModelOverride>{},
    );
    if (override == null) {
      map.remove(modelId);
    } else {
      map[modelId] = override;
    }
  }

  /// A drop-in `modelResolver`: resolves [qualifiedId] through [base] (the
  /// models.dev catalog), then lets the stored override win field by field.
  ///
  /// When the catalog does not know the model at all — every custom-provider
  /// model, or a built-in model newer than the bundled snapshot — an override
  /// is the only metadata there is, so a minimal [ModelInfo] is synthesized
  /// from it (no cost, no status: pricing stays unknown and the run is still
  /// attributed). With no override the base answer passes through untouched.
  ModelInfo? resolve(
    ModelInfo? Function(String qualifiedId) base,
    String qualifiedId,
  ) {
    final ref = ModelRef.parse(qualifiedId);
    final override = _byProvider[ref.providerId]?[ref.modelId];
    final resolved = base(qualifiedId);
    if (override == null) {
      return resolved;
    }
    if (resolved == null) {
      return ModelInfo(
        id: ref.modelId,
        providerId: ref.providerId,
        name: ref.modelId,
        limits: ModelLimits(
          context: override.contextWindow,
          maxOutput: override.maxOutputTokens,
        ),
        // An LLM endpoint's model is text-capable unless the override says
        // otherwise — an empty override list means "not stated", not "none".
        inputModalities: override.inputModalities.isEmpty
            ? const [ModelModality.text]
            : _modalities(override.inputModalities),
        outputModalities: override.outputModalities.isEmpty
            ? const [ModelModality.text]
            : _modalities(override.outputModalities),
      );
    }
    return resolved.copyWith(
      limits: ModelLimits(
        context: override.contextWindow ?? resolved.limits.context,
        maxInput: resolved.limits.maxInput,
        maxOutput: override.maxOutputTokens ?? resolved.limits.maxOutput,
      ),
      inputModalities: override.inputModalities.isEmpty
          ? null
          : _modalities(override.inputModalities),
      outputModalities: override.outputModalities.isEmpty
          ? null
          : _modalities(override.outputModalities),
    );
  }

  static List<ModelModality> _modalities(List<String> raw) => [
    for (final token in raw) ?ModelModality.fromRaw(token),
  ];
}
