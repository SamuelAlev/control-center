import 'dart:io';

import 'package:control_center/features/settings/domain/entities/acp_model.dart';

/// Resolves the model catalog an adapter advertises via its CLI.
///
/// Each adapter CLI supports listing available models:
/// - OpenCode: `opencode models`
/// - Pi: `pi --list-models`
/// - Claude Code: no CLI models command; uses static catalog.
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
      models.add(AcpModel(id: id, name: id));
    }
    return models;
  }

  static const Map<String, List<AcpModel>> _staticCatalog = {
    'opencode': [
      AcpModel(
        id: 'fireworks-ai/accounts/fireworks/models/deepseek-v4-pro',
        name: 'fireworks-ai/accounts/fireworks/models/deepseek-v4-pro',
      ),
      AcpModel(id: 'opencode/big-pickle', name: 'opencode/big-pickle'),
    ],
    'pi-dev': [
      AcpModel(
        id: 'anthropic/claude-opus-4-7',
        name: 'anthropic/claude-opus-4-7',
      ),
      AcpModel(
        id: 'anthropic/claude-sonnet-4-6',
        name: 'anthropic/claude-sonnet-4-6',
      ),
    ],
    'claude-code': [
      AcpModel(id: 'claude-opus-4-7', name: 'claude-opus-4-7'),
      AcpModel(id: 'claude-sonnet-4-6', name: 'claude-sonnet-4-6'),
      AcpModel(
        id: 'claude-haiku-4-5-20251001',
        name: 'claude-haiku-4-5-20251001',
      ),
    ],
  };
}

