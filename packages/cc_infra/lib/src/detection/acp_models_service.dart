import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show basicThinkingLevels, claudeThinkingLevels;

/// Resolves the model catalog an adapter advertises.
///
/// Claude Code has no listing command (`claude models` starts a session with
/// the word "models" as the prompt), so its vocabulary is curated.
///
/// Results are cached in memory for the lifetime of the service.
class AcpModelsService {
  /// Creates a new [Acp models service].
  AcpModelsService();

  final _cache = <String, List<AcpModel>>{};

  /// Returns the list of models advertised by the given [adapterId].
  ///
  /// A negative result is never cached.
  Future<List<AcpModel>> listModels(String adapterId) async {
    final cached = _cache[adapterId];
    if (cached != null) {
      return cached;
    }
    final models = _staticCatalog[adapterId] ?? const <AcpModel>[];
    if (models.isNotEmpty) {
      _cache[adapterId] = models;
    }
    return models;
  }

  static const Map<String, List<AcpModel>> _staticCatalog = {
    'claude-code': _claudeCodeCatalog,
  };

  /// Claude Code's model vocabulary, as its own `--model` accepts it.
  ///
  /// `claude` has NO listing command — `claude models` starts a session with
  /// the word "models" as the prompt, and an invalid `--model` answers with a
  /// 404 that names no alternatives — so this is curated rather than probed.
  /// It is the CLI's vocabulary, not the Anthropic API's: the aliases come
  /// first because they are what people actually type and they never go stale,
  /// `[1m]` selects the long-context variant of the same model, and `opusplan`
  /// is Opus while planning and Sonnet afterwards.
  ///
  /// Reasoning levels mirror `claude --effort` (low/medium/high/xhigh/max),
  /// which is why the Claude vocabulary is used rather than the three-level
  /// one every other adapter gets.
  static const List<AcpModel> _claudeCodeCatalog = [
    AcpModel(
      id: 'opus',
      name: 'Opus (latest)',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'sonnet',
      name: 'Sonnet (latest)',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'haiku',
      name: 'Haiku (latest)',
      contextWindow: 200000,
      thinkingLevels: basicThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'fable',
      name: 'Fable (latest)',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'best',
      name: 'Best available',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'opusplan',
      name: 'Opus in plan mode, else Sonnet',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'opus[1m]',
      name: 'Opus (1M context)',
      contextWindow: 1000000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'sonnet[1m]',
      name: 'Sonnet (1M context)',
      contextWindow: 1000000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'fable[1m]',
      name: 'Fable (1M context)',
      contextWindow: 1000000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-opus-5',
      name: 'Claude Opus 5',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-sonnet-5',
      name: 'Claude Sonnet 5',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-fable-5',
      name: 'Claude Fable 5',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-mythos-5',
      name: 'Claude Mythos 5',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-opus-4-8',
      name: 'Claude Opus 4.8',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-opus-4-7',
      name: 'Claude Opus 4.7',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-opus-4-6',
      name: 'Claude Opus 4.6',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-opus-4-5',
      name: 'Claude Opus 4.5',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-opus-4-1',
      name: 'Claude Opus 4.1',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-opus-4-0',
      name: 'Claude Opus 4',
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
      id: 'claude-sonnet-4-5',
      name: 'Claude Sonnet 4.5',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-sonnet-4-0',
      name: 'Claude Sonnet 4',
      contextWindow: 200000,
      thinkingLevels: claudeThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-haiku-4-5',
      name: 'Claude Haiku 4.5',
      contextWindow: 200000,
      thinkingLevels: basicThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-haiku-4-5-20251001',
      name: 'Claude Haiku 4.5 (2025-10-01)',
      contextWindow: 200000,
      thinkingLevels: basicThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-3-7-sonnet',
      name: 'Claude Sonnet 3.7',
      contextWindow: 200000,
      thinkingLevels: basicThinkingLevels,
      defaultThinkingLevel: 'medium',
    ),
    AcpModel(
      id: 'claude-3-5-sonnet',
      name: 'Claude Sonnet 3.5',
      contextWindow: 200000,
    ),
    AcpModel(
      id: 'claude-3-5-haiku',
      name: 'Claude Haiku 3.5',
      contextWindow: 200000,
    ),
  ];
}
