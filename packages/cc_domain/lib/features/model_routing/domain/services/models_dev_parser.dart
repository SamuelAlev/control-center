// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:convert';
import 'dart:math' as math;

import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';
import 'package:cc_harness/provider.dart';

/// Parses the canonical [models.dev](https://models.dev) `api.json` document
/// into the catalog's `{providerId: ProviderEntry}` shape.
///
/// The document is `{providerId: {id, name, env, npm, doc, models: {...}}}`;
/// each model carries cost, limits, modalities, reasoning options and status.
/// Unknown / malformed entries are skipped rather than throwing so a partial or
/// drifted upstream document still yields a usable catalog.
///
/// It is parsed as it is read and never held decoded: each provider is built
/// the moment its closing brace is read, and what was decoded for it is
/// dropped there. The document is several megabytes describing about ten
/// thousand models. Decoded in one piece it is tens of megabytes of maps that
/// exist only to be read once, and a process that allocated them keeps the
/// room for them: measured, a server held 67 MB more after loading the
/// catalog that way than it does after loading it provider by provider.
abstract final class ModelsDevParser {
  /// Parses the document's JSON text. Providers start [ProviderDisabled];
  /// enablement is resolved later (it depends on the host's env/accounts).
  ///
  /// Throws [FormatException] when [source] is not JSON.
  static Map<String, ProviderEntry> parse(String source) =>
      _parseAsRead((reviver) => JsonDecoder(reviver).convert(source));

  /// [parse] for the document's UTF-8 [bytes], which also skips building the
  /// text.
  static Map<String, ProviderEntry> parseUtf8(List<int> bytes) => _parseAsRead(
    (reviver) => const Utf8Decoder().fuse(JsonDecoder(reviver)).convert(bytes),
  );

  static Map<String, ProviderEntry> _parseAsRead(
    Object? Function(Object? Function(Object? key, Object? value) reviver)
    decode,
  ) {
    // The decoder calls this with each value as soon as it is complete. A
    // provider is the only object in the document that holds a `models`
    // object, so that is the moment to swap what was decoded for it with the
    // entry built from it.
    Object? asRead(Object? key, Object? value) {
      if (key is String && value is Map && value['models'] is Map) {
        return _parseProvider(
          (value['id'] as String?) ?? key,
          value.cast<String, dynamic>(),
        );
      }
      return value;
    }

    final document = decode(asRead);
    if (document is! Map) {
      return {};
    }
    final out = <String, ProviderEntry>{};
    for (final entry in document.entries) {
      final value = entry.value;
      if (value is ProviderEntry) {
        out[value.provider.id] = value;
      } else if (value is Map) {
        // A provider with no `models` object is kept, with none.
        final providerId = (value['id'] as String?) ?? entry.key.toString();
        final parsed = _parseProvider(
          providerId,
          value.cast<String, dynamic>(),
        );
        if (parsed != null) {
          out[providerId] = parsed;
        }
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
    final cost = costRaw is Map ? _cost(costRaw.cast<String, dynamic>()) : null;

    // Catalog prices can rise when the request crosses a context threshold.
    // Keep the base rate for ordinary estimates and a separate ceiling for
    // strict per-call admission. Never silently discard an unparseable tier.
    final reasoning = raw['reasoning'] == true;
    final thinking = reasoning
        ? _thinking(providerId, raw['reasoning_options'])
        : null;

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

  static ModelCost _cost(Map<String, dynamic> raw) {
    final input = (raw['input'] as num?)?.toDouble() ?? 0;
    final output = (raw['output'] as num?)?.toDouble() ?? 0;
    final cacheRead = (raw['cache_read'] as num?)?.toDouble() ?? 0;
    final cacheWrite = (raw['cache_write'] as num?)?.toDouble() ?? 0;
    var maxInput = input;
    var maxOutput = output;
    var maxCacheRead = cacheRead;
    var maxCacheWrite = cacheWrite;
    var complete = true;
    final contextTiers = <ModelContextCostTier>[];

    void include(Object? tier, int? threshold) {
      if (tier is! Map ||
          threshold == null ||
          threshold <= 0 ||
          tier['input'] is! num ||
          tier['output'] is! num ||
          (tier.containsKey('cache_read') && tier['cache_read'] is! num) ||
          (tier.containsKey('cache_write') && tier['cache_write'] is! num)) {
        complete = false;
        return;
      }
      final rate = ModelCost(
        input: (tier['input'] as num).toDouble(),
        output: (tier['output'] as num).toDouble(),
        cacheRead: (tier['cache_read'] as num?)?.toDouble() ?? cacheRead,
        cacheWrite: (tier['cache_write'] as num?)?.toDouble() ?? cacheWrite,
      );
      if (!rate.input.isFinite ||
          rate.input <= 0 ||
          !rate.output.isFinite ||
          rate.output <= 0 ||
          !rate.cacheRead.isFinite ||
          rate.cacheRead < 0 ||
          !rate.cacheWrite.isFinite ||
          rate.cacheWrite < 0) {
        complete = false;
        return;
      }
      contextTiers.add(
        ModelContextCostTier(thresholdTokens: threshold, cost: rate),
      );
      maxInput = math.max(maxInput, rate.input);
      maxOutput = math.max(maxOutput, rate.output);
      maxCacheRead = math.max(maxCacheRead, rate.cacheRead);
      maxCacheWrite = math.max(maxCacheWrite, rate.cacheWrite);
    }

    if (raw.containsKey('tiers')) {
      final tiers = raw['tiers'];
      if (tiers is List) {
        for (final tier in tiers) {
          final rule = tier is Map ? tier['tier'] : null;
          final threshold =
              rule is Map && rule['type'] == 'context' && rule['size'] is num
              ? (rule['size'] as num).toInt()
              : null;
          include(tier, threshold);
        }
      } else {
        complete = false;
      }
    } else if (raw.containsKey('context_over_200k')) {
      // Structured tiers supersede the legacy shorthand, including its
      // imprecise threshold for newer models.
      include(raw['context_over_200k'], 200000);
    }
    contextTiers.sort((a, b) => a.thresholdTokens.compareTo(b.thresholdTokens));
    final elevated =
        maxInput != input ||
        maxOutput != output ||
        maxCacheRead != cacheRead ||
        maxCacheWrite != cacheWrite;
    return ModelCost(
      input: input,
      output: output,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      contextTiers: contextTiers,
      pricingComplete: complete,
      reservationCeiling: elevated
          ? ModelCost(
              input: maxInput,
              output: maxOutput,
              cacheRead: maxCacheRead,
              cacheWrite: maxCacheWrite,
            )
          : null,
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

  static ThinkingConfig? _thinking(
    String providerId,
    Object? reasoningOptions,
  ) {
    if (reasoningOptions is! List) {
      // Reasoning model with no documented effort vocabulary: still flag it as
      // reasoning-capable, but with the PROVIDER's wire vocabulary rather than
      // a flat low/medium/high — the flat fallback hid Anthropic's `xhigh`
      // (and let `ThinkingConfig.resolve` clamp a chosen xhigh down to high)
      // and OpenAI's `minimal` on every model models.dev doesn't annotate.
      final efforts = defaultProviderEfforts(providerId);
      return ThinkingConfig(
        efforts: efforts,
        defaultLevel: efforts.contains(ReasoningEffort.medium)
            ? ReasoningEffort.medium
            : efforts.first,
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
      // Options present but none parseable: same provider-aware fallback as a
      // missing block, so a drifted upstream shape cannot shrink the knob.
      efforts.addAll(defaultProviderEfforts(providerId));
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
