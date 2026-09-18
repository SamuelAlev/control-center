import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/services/harness_thinking_levels.dart';
import 'package:cc_harness/provider.dart'
    show HarnessModelInfo, HarnessProviderInfo;
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/model_catalog_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One selectable row of the model browser: a model id plus everything the
/// picker can honestly say about it (provider, context window, output ceiling,
/// pricing, reasoning vocabulary).
///
/// Assembled from the same sources the agent form's inference runs on — the
/// live `providers.listModels` payload joined with the models.dev catalog for
/// the built-in harness, the curated ACP list for CLI adapters — so what the
/// browser displays and what a saved agent resolves cannot disagree.
class ModelBrowserEntry {
  /// Creates a [ModelBrowserEntry].
  const ModelBrowserEntry({
    required this.id,
    required this.name,
    required this.providerId,
    required this.providerName,
    this.contextWindow,
    this.maxOutput,
    this.inputCost,
    this.outputCost,
    this.thinkingLevels,
    this.defaultThinkingLevel,
    this.releasedAt,
  });

  /// The id stored on the agent (qualified `provider/model` for the harness).
  final String id;

  /// Human-readable model name.
  final String name;

  /// Owning provider id (an adapter id for CLI adapters).
  final String providerId;

  /// Human-readable provider name for the rail.
  final String providerName;

  /// Context window in tokens, when known.
  final int? contextWindow;

  /// Maximum output tokens per turn, when known.
  final int? maxOutput;

  /// Input price in USD per 1M tokens; null when unknown.
  final double? inputCost;

  /// Output price in USD per 1M tokens; null when unknown.
  final double? outputCost;

  /// The reasoning levels this model accepts; null when it has no effort knob.
  final List<ThinkingLevel>? thinkingLevels;

  /// The level id a never-touched agent runs at, when [thinkingLevels] is set.
  final String? defaultThinkingLevel;

  /// Release date, when the catalog documents one (drives newest-first sort).
  final DateTime? releasedAt;

  /// Whether the model exposes a reasoning-effort control.
  bool get reasoning => thinkingLevels?.isNotEmpty ?? false;

  /// Whether any pricing is known at all (a 0/0 price is "free", a null one
  /// is "unknown" — the two must not render the same).
  bool get hasKnownCost => inputCost != null || outputCost != null;

  /// Whether the model is priced at zero on both lanes.
  bool get isFree =>
      hasKnownCost && (inputCost ?? 0) == 0 && (outputCost ?? 0) == 0;

  /// Case-insensitive substring match over id, name and provider name.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    return id.toLowerCase().contains(q) ||
        name.toLowerCase().contains(q) ||
        providerName.toLowerCase().contains(q);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelBrowserEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          providerId == other.providerId;

  @override
  int get hashCode => Object.hash(id, providerId);
}

/// One provider's slice of the browser: the rail item and its models.
class ModelBrowserGroup {
  /// Creates a [ModelBrowserGroup].
  const ModelBrowserGroup({
    required this.id,
    required this.name,
    required this.models,
  });

  /// Provider id (an adapter id for CLI adapters).
  final String id;

  /// Human-readable provider name.
  final String name;

  /// This provider's models, newest first when release dates are known.
  final List<ModelBrowserEntry> models;

  /// How many models match [query]. An empty query matches every model.
  int matchCount(String query) => models.where((m) => m.matches(query)).length;
}

/// The model browser's data for an adapter: models grouped by provider.
///
/// The built-in harness adapter groups by the connected providers serving the
/// live model list; a CLI adapter is a single group under its own name (its
/// curated vocabulary all belongs to one vendor).
final modelBrowserGroupsProvider =
    FutureProvider.family<List<ModelBrowserGroup>, String?>((
      ref,
      adapterId,
    ) async {
      if (adapterId == null || adapterId.isEmpty) {
        return const [];
      }
      final detected = ref.read(detectedAdaptersProvider);
      final adapter = detected
          .where((d) => d.adapter.id == adapterId)
          .map((d) => d.adapter)
          .firstOrNull;
      if (adapter?.transport == AdapterTransport.harness) {
        final models = await ref.watch(harnessModelsProvider.future);
        final providers = await ref.watch(harnessProvidersProvider.future);
        // models.dev metadata is enrichment only, never a source of model ids
        // — same contract as `adapterModelsProvider`.
        ModelCatalog catalog;
        try {
          catalog = await ref.watch(rawModelCatalogProvider.future);
        } on Object {
          catalog = ModelCatalog.empty;
        }
        return _harnessGroups(models, providers, catalog);
      }
      final models = await ref
          .read(acpModelRepositoryProvider)
          .listModels(adapterId);
      if (models.isEmpty) {
        return const [];
      }
      final groupName = adapter?.name ?? adapterId;
      return [
        ModelBrowserGroup(
          id: adapterId,
          name: groupName,
          // Curated order is meaningful (aliases first, then pinned ids);
          // don't re-sort it.
          models: [for (final m in models) _acpEntry(adapterId, groupName, m)],
        ),
      ];
    });

List<ModelBrowserGroup> _harnessGroups(
  List<HarnessModelInfo> models,
  List<HarnessProviderInfo> providers,
  ModelCatalog catalog,
) {
  final providerNames = {for (final p in providers) p.id: p.displayName};
  final byProvider = <String, List<ModelBrowserEntry>>{};
  for (final m in models) {
    final info = catalog.resolve(m.id);
    final thinking = harnessThinkingLevels(info);
    final cost = info?.cost;
    byProvider
        .putIfAbsent(m.providerId, () => [])
        .add(
          ModelBrowserEntry(
            id: m.id,
            name: m.displayName ?? m.bareId,
            providerId: m.providerId,
            providerName: providerNames[m.providerId] ?? m.providerId,
            contextWindow: m.contextWindow ?? info?.limits.context,
            maxOutput: m.maxOutputTokens ?? info?.limits.maxOutput,
            inputCost: m.inputCostPerMTokens ?? cost?.input,
            outputCost: m.outputCostPerMTokens ?? cost?.output,
            thinkingLevels: thinking.levels,
            defaultThinkingLevel: thinking.defaultLevel,
            releasedAt: info?.releasedAt,
          ),
        );
  }
  int byRelease(ModelBrowserEntry a, ModelBrowserEntry b) {
    final ar = a.releasedAt;
    final br = b.releasedAt;
    if (ar != null && br != null && ar != br) {
      return br.compareTo(ar);
    }
    if ((ar == null) != (br == null)) {
      return ar == null ? 1 : -1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  final groups = [
    for (final e in byProvider.entries)
      ModelBrowserGroup(
        id: e.key,
        name: providerNames[e.key] ?? e.key,
        models: e.value..sort(byRelease),
      ),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return groups;
}

ModelBrowserEntry _acpEntry(String adapterId, String groupName, AcpModel m) =>
    ModelBrowserEntry(
      id: m.id,
      name: m.name,
      providerId: adapterId,
      providerName: groupName,
      contextWindow: m.contextWindow,
      thinkingLevels: m.thinkingLevels,
      defaultThinkingLevel: m.defaultThinkingLevel,
    );
