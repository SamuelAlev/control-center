import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show basicThinkingLevels, claudeThinkingLevels, openaiThinkingLevels;
import 'package:cc_infra/src/process/binary_resolver.dart';

/// The combined result of one catalog-listing CLI invocation.
typedef _CliResult = ({int exitCode, String stdout, String stderr});

/// Resolves the model catalog an adapter advertises via its CLI.
///
/// Each adapter CLI supports listing available models:
/// - OpenCode: `opencode models`
/// - NDJSON (`--mode json`) adapter: `--list-models`
/// - Codex: `codex debug models` (JSON; carries reasoning levels)
/// - Cursor: `cursor-agent --list-models` (per-account catalog)
/// - Gemini / Goose / Claude Code: curated static catalog.
///
/// Use `cliPath` to invoke the binary at the exact path discovered by
/// `AdapterDetectionService`, avoiding PATH resolution issues at runtime.
/// Results are cached in memory for the lifetime of the service.
class AcpModelsService {
  /// Creates a new [Acp models service].
  AcpModelsService();

  final _cache = <String, List<AcpModel>>{};

  /// Returns the list of models advertised by the given [adapterId], using
  /// [cliPath] when available.
  ///
  /// Falls back to the curated [_staticCatalog] whenever the CLI yields nothing
  /// usable — which covers TWO cases, not one. The CLI failing (absent binary,
  /// non-zero exit) throws and is caught. But a CLI can also succeed and list no
  /// models at all: `pi --list-models` exits 0 with "No models available. Use
  /// /login…" when the user has not authenticated a provider. Treating that as
  /// "this adapter has no models" left the model picker empty and unusable, so an
  /// empty result falls back the same way a failure does.
  ///
  /// A negative result is never cached, so a CLI that logs in (or a transient
  /// failure) is picked up on the next call rather than for the process lifetime.
  Future<List<AcpModel>> listModels(String adapterId, {String? cliPath}) async {
    final cached = _cache[adapterId];
    if (cached != null) {
      return cached;
    }

    List<AcpModel> models;
    try {
      models = await _fetchFromCli(adapterId, cliPath: cliPath);
    } catch (_) {
      models = const [];
    }
    if (models.isEmpty) {
      models = _staticCatalog[adapterId] ?? const [];
    }
    if (models.isNotEmpty) {
      _cache[adapterId] = models;
    }
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
      case 'cursor':
        return _fetchCursorModels(cliPath: cliPath);
      default:
        return _staticCatalog[adapterId] ?? const [];
    }
  }

  /// Resolves the binary to invoke for [cliName].
  ///
  /// `acp.listModels` deliberately ignores any client-supplied `cli_path` (an
  /// attacker-chosen executable is an arbitrary-execution vector), so the host
  /// arrives here with [cliPath] null and has to find the binary itself. A bare
  /// name would be looked up in the process PATH — which a bundled `.app` or
  /// `.desktop` launch inherits from `launchd`/`xdg` WITHOUT Homebrew, Nix or
  /// `~/.local/bin`. That is why an installed CLI could still fall through to
  /// the curated catalog: the listing command never ran.
  Future<String?> _resolve(String cliName, String? cliPath) async =>
      cliPath ?? await resolveBinaryPath(cliName);

  Future<List<AcpModel>> _fetchOpenCodeModels({String? cliPath}) async {
    final executable = await _resolve('opencode', cliPath);
    if (executable == null) {
      return const [];
    }
    final result = await _runCli(executable, ['models']);

    if (result.exitCode != 0) {
      throw Exception(
        'opencode models failed with exit code ${result.exitCode}',
      );
    }

    final stdout = result.stdout.trim();
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
    final executable = await _resolve('pi', cliPath);
    if (executable == null) {
      return const [];
    }
    final result = await _runCli(executable, ['--list-models']);

    if (result.exitCode != 0) {
      throw Exception(
        'pi --list-models failed with exit code ${result.exitCode}',
      );
    }

    // The model table is written to stderr.
    final output = result.stdout.isEmpty ? result.stderr : result.stdout;
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
      models.add(AcpModel(id: id, name: id, contextWindow: contextWindow));
    }
    return models;
  }

  /// `codex debug models` emits a JSON object `{ models: [...] }` where each
  /// entry carries `slug`, `display_name`, `supported_reasoning_levels` (an
  /// array of `{effort}`) and `default_reasoning_level`. Levels are
  /// auto-inferred as OpenAI-style for any gpt/codex id without explicit levels.
  Future<List<AcpModel>> _fetchCodexModels({String? cliPath}) async {
    final executable = await _resolve('codex', cliPath);
    if (executable == null) {
      return const [];
    }
    final result = await _runCli(executable, ['debug', 'models']);
    if (result.exitCode != 0) {
      throw Exception(
        'codex debug models failed with exit code ${result.exitCode}',
      );
    }
    final raw = result.stdout.trim();
    if (raw.isEmpty) {
      return const [];
    }
    return _parseCodexModelsJson(raw);
  }

  /// Cursor's catalog is per-ACCOUNT (a Pro plan sees models a free one does
  /// not) and it is large — hundreds of entries, because Cursor bakes the
  /// reasoning effort into the model id (`gpt-5.6-sol-xhigh-fast`) rather than
  /// exposing it as a separate control. A curated list is therefore both wrong
  /// and hopeless to maintain, so the CLI is asked.
  ///
  /// `--list-models` is preferred over the equivalent `models` subcommand:
  /// releases from before the dedicated flag treat an unknown positional
  /// argument as an agent PROMPT, so `cursor-agent models` would start a
  /// (billable) turn instead of printing a table. Those older releases only
  /// exposed the catalog through the invalid-model error, which is the second
  /// attempt — skipped when the CLI has said it is not logged in, since that is
  /// a real answer and not a format we failed to parse.
  Future<List<AcpModel>> _fetchCursorModels({String? cliPath}) async {
    final executable = await _resolve('cursor-agent', cliPath);
    if (executable == null) {
      return const [];
    }
    final result = await _runCli(executable, ['--list-models']);
    final output = '${result.stdout}\n${result.stderr}';
    final models = parseCursorModelList(output);
    if (models.isNotEmpty || _cursorNeedsLogin(output)) {
      return models;
    }
    final legacy = await _runCli(executable, ['--model', '--help']);
    return parseCursorModelList('${legacy.stdout}\n${legacy.stderr}');
  }

  static bool _cursorNeedsLogin(String output) => RegExp(
    r'authentication required|not logged in|please log in',
    caseSensitive: false,
  ).hasMatch(output);

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
        .map(
          (l) => ThinkingLevel(
            id: l,
            label: l == 'xhigh' ? 'Extra High' : _titleize(l),
          ),
        )
        .toList();
    final defaultLevel = entry['default_reasoning_level'] as String?;
    // Auto-inference: any gpt-5/codex id with no explicit levels gets the
    // OpenAI vocabulary and a 'low' default.
    final inferred = _withOpenAiThinking(id, levels, defaultLevel);
    return AcpModel(
      id: id,
      name:
          (entry['display_name'] as String?) ??
          (entry['name'] as String?) ??
          id,
      thinkingLevels: inferred.levels,
      defaultThinkingLevel: inferred.defaultLevel,
    );
  }

  /// Returns the OpenAI reasoning vocabulary when [id] looks like an OpenAI model and declared no explicit levels.
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

  /// Runs a catalog-listing command and returns its exit code and both streams.
  ///
  /// stdin is CLOSED immediately rather than left as an open pipe. `Process.run`
  /// keeps the child's stdin pipe open for the process's lifetime, and an
  /// interactive-first CLI (`cursor-agent`) blocks reading it instead of
  /// printing its catalog and exiting — so the listing hangs until the timeout
  /// and the picker silently falls back to the curated list.
  ///
  /// Both streams are captured because these commands are not consistent about
  /// which one the table lands on (`pi` writes it to stderr), and the whole run
  /// is bounded: a wedged binary must not hold an RPC handler open.
  Future<_CliResult> _runCli(
    String executable,
    List<String> args, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final process = await Process.start(executable, args);
    try {
      await process.stdin.close();
    } on Object catch (_) {
      // The child may have exited already; its stdin is then a broken pipe.
    }
    final out = StringBuffer();
    final err = StringBuffer();
    final drained = Future.wait([
      process.stdout.transform(utf8.decoder).forEach(out.write),
      process.stderr.transform(utf8.decoder).forEach(err.write),
    ]);
    var exitCode = -1;
    try {
      await drained.timeout(timeout);
      exitCode = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
    }
    return (exitCode: exitCode, stdout: out.toString(), stderr: err.toString());
  }

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
    'claude-code': _claudeCodeCatalog,
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
    // Cursor's real catalog is per-account and comes from `--list-models`; this
    // is only what to offer when the binary is absent or not logged in. It is
    // deliberately just `auto` — a guessed id that Cursor does not serve is
    // worse than one entry that always works, because the picker accepts free
    // text and a wrong id fails at dispatch time.
    'cursor': [AcpModel(id: 'auto', name: 'Auto (Cursor picks)')],
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

/// Parses the catalog `cursor-agent` prints, in either format it has shipped.
///
/// The current format is a header line followed by `<id> - <display name>`
/// rows and a closing `Tip:` line:
///
/// ```text
/// Available models
///
/// auto - Auto (default)
/// gpt-5.3-codex - Codex 5.3
/// Tip: pass --model <id> to pick one
/// ```
///
/// Releases from before the dedicated `--list-models` flag only ever printed
/// the catalog as part of the invalid-model error, on ONE line:
/// `Available models: auto, gpt-5.3-codex, …`. Both are accepted because the
/// two are told apart by what follows the header, and an unrecognized output
/// yields an empty list rather than throwing — the caller falls back.
///
/// ANSI styling is stripped first: the CLI colorizes its table whenever it
/// believes it is attached to a terminal, and an escape sequence glued to the
/// first id would otherwise become part of the model id.
List<AcpModel> parseCursorModelList(String output) {
  final text = _stripAnsi(output);

  // `Available models` alone on its line — the tabular format. The `:` variant
  // is deliberately excluded here so it falls through to the legacy branch.
  final header = RegExp(
    r'(?:^|\n)[ \t]*Available models[ \t]*(?:\n|$)',
  ).firstMatch(text);
  if (header != null) {
    final models = <AcpModel>[];
    final seen = <String>{};
    for (final raw in text.substring(header.end).split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      // The trailing hint is prose, and everything after it is too.
      if (line.startsWith('Tip:')) {
        break;
      }
      final separator = line.indexOf(' - ');
      if (separator <= 0) {
        continue;
      }
      final id = line.substring(0, separator).trim();
      final name = line.substring(separator + 3).trim();
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      models.add(AcpModel(id: id, name: name.isEmpty ? id : name));
    }
    return models;
  }

  final legacy = RegExp(r'Available models:[ \t]*([^\n]+)').firstMatch(text);
  if (legacy == null) {
    return const [];
  }
  final models = <AcpModel>[];
  final seen = <String>{};
  for (final raw in legacy.group(1)!.split(',')) {
    final id = raw.trim();
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    models.add(AcpModel(id: id, name: id));
  }
  return models;
}

/// Removes CSI/OSC escape sequences from CLI output.
String _stripAnsi(String value) =>
    value.replaceAll(RegExp(r'\x1B(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*\x07)'), '');
