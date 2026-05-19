// ignore_for_file: avoid_classes_with_only_static_members

import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';
import 'package:cc_harness/provider.dart';

/// Parses the canonical [models.dev](https://models.dev) `api.json` document
/// into the catalog's `{providerId: ProviderEntry}` shape.
///
/// The document is `{providerId: {id, name, env, npm, doc, models: {...}}}`;
/// each model carries cost, limits, modalities, reasoning options, and status.
/// Unknown / malformed entries are skipped rather than throwing so a partial or
/// drifted upstream snapshot still yields a usable catalog.
abstract final class ModelsDevParser {
  /// Parses the full document. Providers start [ProviderDisabled]; enablement
  /// is resolved later (it depends on the host's env/accounts).
  static Map<String, ProviderEntry> parse(Map<String, dynamic> json) {
    final out = <String, ProviderEntry>{};
    for (final entry in json.entries) {
      final raw = entry.value;
      if (raw is! Map) {
        continue;
      }
      final providerId = (raw['id'] as String?) ?? entry.key;
      final parsed = _parseProvider(providerId, raw.cast<String, dynamic>());
      if (parsed != null) {
        out[providerId] = parsed;
      }
    }
    return out;
  }

  static ProviderEntry? _parseProvider(
    String providerId,
    Map<String, dynamic> raw,
  ) {
    final envKeys =
        (raw['env'] as List?)?.whereType<String>().toList() ?? const <String>[];
    final provider = ModelProvider(
      id: providerId,
      name: (raw['name'] as String?) ?? providerId,
      description: raw['description'] as String?,
      envKeys: envKeys,
      docUrl: raw['doc'] as String?,
      npm: raw['npm'] as String?,
      enablement: ProviderDisabled(missingEnv: envKeys),
    );

    final models = <String, ModelInfo>{};
    final rawModels = raw['models'];
    if (rawModels is Map) {
      for (final m in rawModels.entries) {
        final mv = m.value;
        if (mv is! Map) {
          continue;
        }
        final modelId = (mv['id'] as String?) ?? m.key.toString();
        final model = _parseModel(
          providerId,
          modelId,
          mv.cast<String, dynamic>(),
        );
        models[modelId] = model;
      }
    }
    return ProviderEntry(provider: provider, models: models);
  }

  static ModelInfo _parseModel(
    String providerId,
    String modelId,
    Map<String, dynamic> raw,
  ) {
    final modalities = raw['modalities'];
    final inputModalities = _modalities(modalities, 'input');
    final outputModalities = _modalities(modalities, 'output');

    final limitRaw = raw['limit'];
    final limits = limitRaw is Map
        ? ModelLimits(
            context: (limitRaw['context'] as num?)?.toInt(),
            maxInput: (limitRaw['input'] as num?)?.toInt(),
            maxOutput: (limitRaw['output'] as num?)?.toInt(),
          )
        : const ModelLimits();

    final costRaw = raw['cost'];
    final cost = costRaw is Map
        ? ModelCost(
            input: (costRaw['input'] as num?)?.toDouble() ?? 0,
            output: (costRaw['output'] as num?)?.toDouble() ?? 0,
            cacheRead: (costRaw['cache_read'] as num?)?.toDouble() ?? 0,
            cacheWrite: (costRaw['cache_write'] as num?)?.toDouble() ?? 0,
          )
        : null;

    final reasoning = raw['reasoning'] == true;
    final thinking = reasoning ? _thinking(raw['reasoning_options']) : null;

    return ModelInfo(
      id: modelId,
      providerId: providerId,
      name: (raw['name'] as String?) ?? modelId,
      family: raw['family'] as String?,
      reasoning: reasoning,
      supportsTools: raw['tool_call'] == true,
      supportsTemperature: raw['temperature'] == true,
      inputModalities: inputModalities,
      outputModalities: outputModalities,
      cost: cost,
      limits: limits,
      status: ModelStatus.fromRaw(raw['status'] as String?),
      releasedAt: _date(raw['release_date']),
      lastUpdatedAt: _date(raw['last_updated']),
      knowledgeCutoff: _date(raw['knowledge']),
      thinking: thinking,
    );
  }

  static List<ModelModality> _modalities(Object? modalities, String key) {
    if (modalities is Map) {
      final list = modalities[key];
      if (list is List) {
        final parsed = list
            .whereType<String>()
            .map(ModelModality.fromRaw)
            .whereType<ModelModality>()
            .toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    }
    // Default: text-only.
    return const [ModelModality.text];
  }

  static ThinkingConfig? _thinking(Object? reasoningOptions) {
    if (reasoningOptions is! List) {
      // Reasoning model with no documented effort vocabulary: still flag it as
      // reasoning-capable with the conventional low/medium/high knob.
      return const ThinkingConfig(
        efforts: [
          ReasoningEffort.low,
          ReasoningEffort.medium,
          ReasoningEffort.high,
        ],
        defaultLevel: ReasoningEffort.medium,
      );
    }
    final efforts = <ReasoningEffort>[];
    final budgets = <ReasoningEffort, int>{};
    var requires = false;
    for (final opt in reasoningOptions) {
      if (opt is! Map) {
        continue;
      }
      final type = opt['type'];
      if (type == 'effort') {
        final values = opt['values'];
        if (values is List) {
          for (final v in values.whereType<String>()) {
            final e = ReasoningEffort.fromId(v);
            if (e != null && !efforts.contains(e)) {
              efforts.add(e);
            }
          }
        }
        if (opt['required'] == true) {
          requires = true;
        }
      }
      // `budget_tokens` only carries a global min; CC keeps the model's own
      // budget semantics, so we don't synthesize per-effort budgets here.
    }
    if (efforts.isEmpty) {
      efforts.addAll(const [
        ReasoningEffort.low,
        ReasoningEffort.medium,
        ReasoningEffort.high,
      ]);
    }
    efforts.sort((a, b) => a.index.compareTo(b.index));
    return ThinkingConfig(
      efforts: efforts,
      defaultLevel: efforts.contains(ReasoningEffort.medium)
          ? ReasoningEffort.medium
          : efforts.first,
      effortBudgets: budgets,
      requiresEffort: requires,
    );
  }

  static DateTime? _date(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
