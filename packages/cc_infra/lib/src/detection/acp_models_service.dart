import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show basicThinkingLevels, claudeThinkingLevels, openaiThinkingLevels;

/// Resolves the model catalog an adapter advertises via its CLI.
///
/// Each adapter CLI supports listing available models:
/// - OpenCode: `opencode models`
/// - Pi: `pi --list-models`
/// - Codex: `codex debug models` (JSON; carries reasoning levels)
/// - Gemini / Goose / Cursor / Claude Code: curated static catalog.
///
/// Use `cliPath` to invoke the binary at the exact path discovered by
/// `AdapterDetectionService`, avoiding PATH resolution issues at runtime.
/// Results are cached in memory for the lifetime of the service.
class AcpModelsService {
  /// Creates a new [Acp models service].
  AcpModelsService();

  final _cache = <String, List<AcpModel>>{};

  /// Returns the list of models advertised by the given [adapterId], using [cliPath] when available.
  Future<List<AcpModel>> listModels(String adapterId, {String? cliPath}) async {
    if (_cache.containsKey(adapterId)) {
      return _cache[adapterId]!;
    }

    List<AcpModel> models;
    try {
      models = await _fetchFromCli(adapterId, cliPath: cliPath);
    } catch (_) {
      models = _staticCatalog[adapterId] ?? const [];
    }
    _cache[adapterId] = models;
    return models;
  }

  Future<List<AcpModel>> _fetchFromCli(
    String adapterId, {
    String? cliPath,
  }) async {
    switch (adapterId) {
      case 'opencode':
        return _fetchOpenCodeModels(cliPath: cliPath);
      case 'pi-dev':
        return _fetchPiModels(cliPath: cliPath);
      case 'codex':
        return _fetchCodexModels(cliPath: cliPath);
      default:
        return _staticCatalog[adapterId] ?? const [];
    }
  }

  Future<List<AcpModel>> _fetchOpenCodeModels({String? cliPath}) async {
    final executable = cliPath ?? 'opencode';
    final result = await Process.run(executable, ['models']);

    if (result.exitCode != 0) {
      throw Exception('opencode models failed with exit code ${result.exitCode}');

    }

    final stdout = (result.stdout as String).trim();
    if (stdout.isEmpty) {
      return const [];
    }

    return stdout
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('{'))
        .map((id) => AcpModel(id: id, name: id))
        .toList();
  }

  Future<List<AcpModel>> _fetchPiModels({String? cliPath}) async {
    final executable = cliPath ?? 'pi';
    final result = await Process.run(executable, ['--list-models']);

    if (result.exitCode != 0) {
      throw Exception('pi --list-models failed with exit code ${result.exitCode}');
    }

    // pi outputs the model table to stderr.
    final output =
        ((result.stdout as String).isEmpty ? result.stderr : result.stdout)
            as String;
    final text = output.trim();
    if (text.isEmpty) {
      return const [];
    }

    final lines = text.split('\n');
    if (lines.isEmpty) {
      return const [];
    }

    // Skip header line; parse data lines.
    // Columns: provider, model, context, max-out, thinking, images
    final models = <AcpModel>[];
    for (final line in lines.skip(1)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final parts = trimmed.split(RegExp(r'\s{2,}'));
      if (parts.length < 2) {
        continue;
      }

      final id = '${parts[0]}/${parts[1]}';
      // Column 2 is the context window (tokens) when present.
      final contextWindow = parts.length > 2 ? int.tryParse(parts[2]) : null;
      models.add(AcpModel(
        id: id,
        name: id,
        contextWindow: contextWindow,
      ));
    }
    return models;
  }

  /// `codex debug models` emits a JSON object `{ models: [...] }` where each
  /// entry carries `slug`, `display_name`, `supported_reasoning_levels` (an
  /// array of `{effort}`), and `default_reasoning_level`. Levels are
  /// auto-inferred as OpenAI-style for any gpt/codex id without explicit levels.
  Future<List<AcpModel>> _fetchCodexModels({String? cliPath}) async {
    final executable = cliPath ?? 'codex';
    final result = await Process.run(executable, ['debug', 'models']);
    if (result.exitCode != 0) {
      throw Exception(
        'codex debug models failed with exit code ${result.exitCode}',
      );
    }
    final raw = (result.stdout as String).trim();
    if (raw.isEmpty) {
      return const [];
    }
    return _parseCodexModelsJson(raw);
  }

  List<AcpModel> _parseCodexModelsJson(String raw) {
    // Be defensive: the command may print non-JSON banner lines; isolate the
    // first JSON value in the output.
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      return const [];
    }
    final slice = raw.substring(start, end + 1);
    final Map<String, dynamic> decoded;
    try {
      decoded = (jsonDecode(slice) as Map).cast<String, dynamic>();
    } catch (_) {
      return const [];
    }
    final modelsField = decoded['models'];
    if (modelsField is! List) {
      return const [];
    }
    return modelsField
        .whereType<Map>()
        .map(_codexEntryToModel)
        .whereType<AcpModel>()
        .toList();
  }

  AcpModel? _codexEntryToModel(Map entry) {
    final id = entry['slug'] ?? entry['id'] ?? entry['model'];
    if (id is! String || id.isEmpty) {
      return null;
    }
    // `supported_reasoning_levels` is an array of `{effort}`.
    final levels = (entry['supported_reasoning_levels'] as List?)
        ?.whereType<Map>()
        .map((m) => m['effort'])
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .map((l) => ThinkingLevel(
              id: l,
              label: l == 'xhigh' ? 'Extra High' : _titleize(l),
            ))
        .toList();
    final defaultLevel = entry['default_reasoning_level'] as String?;
    // Auto-inference: any gpt-5/codex id with no explicit levels gets the
    // OpenAI vocabulary and a 'low' default.
    final inferred = _withOpenAiThinking(id, levels, defaultLevel);
    return AcpModel(
      id: id,
      name: (entry['display_name'] as String?) ??
          (entry['name'] as String?) ??
          id,
      thinkingLevels: inferred.levels,
      defaultThinkingLevel: inferred.defaultLevel,
    );
  }

  /// Returns the OpenAI reasoning vocabulary when [id] looks like an OpenAI
  /// model and declared no explicit levels. Ports Orca's `withOpenAiThinking`.
  ({List<ThinkingLevel>? levels, String? defaultLevel}) _withOpenAiThinking(
    String id,
    List<ThinkingLevel>? declared,
    String? declaredDefault,
  ) {

    if (declared != null && declared.isNotEmpty) {
      return (levels: declared, defaultLevel: declaredDefault ?? 'low');
    }
    if (RegExp(r'(gpt-5|codex)', caseSensitive: false).hasMatch(id)) {
      return (levels: openaiThinkingLevels, defaultLevel: 'low');
    }
    return (levels: declared, defaultLevel: declaredDefault);
  }

  String _titleize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static const Map<String, List<AcpModel>> _staticCatalog = {
    'opencode': [
      AcpModel(
        id: 'fireworks-ai/accounts/fireworks/models/deepseek-v4-pro',
        name: 'DeepSeek V4 Pro (Fireworks)',
      ),
      AcpModel(
        id: 'fireworks-ai/accounts/fireworks/models/deepseek-v4-flash-free',
        name: 'DeepSeek V4 Flash (free)',
      ),
    ],
    'pi-dev': [
      AcpModel(
        id: 'anthropic/claude-opus-4-7',
        name: 'Claude Opus 4.7',
        contextWindow: 200000,
        thinkingLevels: claudeThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
      AcpModel(
        id: 'anthropic/claude-sonnet-4-6',
        name: 'Claude Sonnet 4.6',
        contextWindow: 200000,
        thinkingLevels: claudeThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
    ],
    'claude-code': [
      AcpModel(
        id: 'claude-opus-4-7',
        name: 'Claude Opus 4.7',
        contextWindow: 200000,
        thinkingLevels: claudeThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
      AcpModel(
        id: 'claude-sonnet-4-6',
        name: 'Claude Sonnet 4.6',
        contextWindow: 200000,
        thinkingLevels: claudeThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
      AcpModel(
        id: 'claude-haiku-4-5-20251001',
        name: 'Claude Haiku 4.5',
        contextWindow: 200000,
        thinkingLevels: basicThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
    ],
    // Codex static fallback (used when `codex debug models` is unavailable).
    // Reasoning levels are the OpenAI vocabulary (low/medium/high/xhigh).
    'codex': [
      AcpModel(
        id: 'gpt-5.5',
        name: 'GPT-5.5',
        thinkingLevels: openaiThinkingLevels,
        defaultThinkingLevel: 'low',
      ),
      AcpModel(
        id: 'gpt-5.4',
        name: 'GPT-5.4',
        thinkingLevels: openaiThinkingLevels,
        defaultThinkingLevel: 'low',
      ),
      AcpModel(
        id: 'gpt-5.4-mini',
        name: 'GPT-5.4 Mini',
        thinkingLevels: openaiThinkingLevels,
        defaultThinkingLevel: 'low',
      ),
      AcpModel(
        id: 'gpt-5.2',
        name: 'GPT-5.2',
        thinkingLevels: openaiThinkingLevels,
        defaultThinkingLevel: 'low',
      ),
    ],
    // Gemini CLI. Context window 1M tokens per Gemini vendor docs.
    'gemini': [
      AcpModel(
        id: 'gemini-3-pro',
        name: 'Gemini 3 Pro',
        contextWindow: 1000000,
        thinkingLevels: basicThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
      AcpModel(
        id: 'gemini-3-flash',
        name: 'Gemini 3 Flash',
        contextWindow: 1000000,
        thinkingLevels: basicThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
    ],
    'goose': [
      AcpModel(
        id: 'gpt-5.1',
        name: 'GPT-5.1',
        thinkingLevels: openaiThinkingLevels,
        defaultThinkingLevel: 'low',
      ),
      AcpModel(
        id: 'anthropic/claude-sonnet-4-6',
        name: 'Claude Sonnet 4.6',
        contextWindow: 200000,
        thinkingLevels: claudeThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
    ],
    'cursor': [
      AcpModel(
        id: 'cursor-small',
        name: 'Cursor Small',
        thinkingLevels: basicThinkingLevels,
        defaultThinkingLevel: 'medium',
      ),
      AcpModel(
        id: 'gpt-5.1',
        name: 'GPT-5.1',
        thinkingLevels: openaiThinkingLevels,
        defaultThinkingLevel: 'low',
      ),
    ],
  };
}
