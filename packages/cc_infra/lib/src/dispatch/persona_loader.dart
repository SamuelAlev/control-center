import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/persona/agent_persona.dart';
import 'package:yaml/yaml.dart';

/// Thrown when a persona file's frontmatter is missing or invalid.
class PersonaParseException implements Exception {
  /// Creates a [PersonaParseException] with an explanatory [message] and an
  /// optional [filePath] identifying the offending source.
  const PersonaParseException(this.message, {this.filePath});

  /// A human-readable description of why parsing failed.
  final String message;

  /// The path of the file that failed to parse, if known.
  final String? filePath;

  @override
  String toString() {
    if (filePath != null) {
      return 'PersonaParseException($filePath): $message';
    }
    return 'PersonaParseException: $message';
  }
}

/// Loads [AgentPersona] definitions from markdown + YAML frontmatter files and
/// discovers them from `.cc/agents/` directories.
///
/// Discovery precedence is highest-wins: project `<cwd>/.cc/agents/` >
/// user `<home>/.cc/agents/` > bundled. Personas are de-duplicated by
/// [AgentPersona.name].
class PersonaLoader {
  /// Creates a [PersonaLoader].
  const PersonaLoader();

  /// The directory name (under `.cc/`) that holds persona files.
  static const String agentsDirName = 'agents';

  /// Parses a single persona from raw file [content].
  ///
  /// The content must begin with a `---` fenced YAML frontmatter block
  /// (defining at least `name` and `description`) followed by a markdown body
  /// that becomes [AgentPersona.systemPrompt]. The `model` field tolerates
  /// either a single string or a list of strings.
  ///
  /// Throws a [PersonaParseException] when the frontmatter is missing or a
  /// required field is absent.
  AgentPersona parsePersona(
    String content, {
    required AgentPersonaSource source,
    String? filePath,
  }) {
    final frontmatter = _extractFrontmatter(content, filePath);
    final body = _extractMarkdownBody(content);

    final name = frontmatter['name'];
    if (name is! String || name.isEmpty) {
      throw PersonaParseException(
        'Missing or empty required field "name"',
        filePath: filePath,
      );
    }

    final description = frontmatter['description'];
    if (description is! String || description.isEmpty) {
      throw PersonaParseException(
        'Missing or empty required field "description"',
        filePath: filePath,
      );
    }

    return AgentPersona(
      name: name,
      description: description,
      tools: _parseStringList(frontmatter['tools']),
      spawns: _parseStringScalar(frontmatter['spawns']) ?? '',
      models: _parseModels(frontmatter['model']),
      thinkingLevel: _parseStringScalar(frontmatter['thinkingLevel']),
      blocking: _parseBool(frontmatter['blocking'], orElse: false),
      readSummarize: _parseBool(frontmatter['readSummarize'], orElse: true),
      autoloadSkills: _parseStringList(frontmatter['autoloadSkills']),
      systemPrompt: body,
      source: source,
      filePath: filePath,
    );
  }

  /// Discovers personas across the project root, user home, and [bundled]
  /// defaults, applying precedence and de-duplication by name.
  ///
  /// Reads `*.md` files from `<cwd>/.cc/agents/` (as
  /// [AgentPersonaSource.project]) then `<home>/.cc/agents/` (as
  /// [AgentPersonaSource.user], defaulting [home] to the `HOME` environment
  /// variable), then appends [bundled]. Within a directory, files are visited
  /// in sorted order for determinism. Missing directories and unparseable
  /// files are skipped. The first persona seen for a given name wins, so a
  /// project persona shadows a same-named user persona, which shadows a
  /// bundled one.
  Future<List<AgentPersona>> discover({
    required String cwd,
    String? home,
    List<AgentPersona> bundled = const [],
  }) async {
    final resolvedHome = home ?? Platform.environment['HOME'];

    final discovered = <AgentPersona>[];

    final projectDir = _agentsDir(cwd);
    discovered.addAll(
      await loadFromDir(projectDir, AgentPersonaSource.project),
    );

    if (resolvedHome != null && resolvedHome.isNotEmpty) {
      final userDir = _agentsDir(resolvedHome);
      discovered.addAll(await loadFromDir(userDir, AgentPersonaSource.user));
    }

    discovered.addAll(bundled);

    final seen = <String>{};
    final result = <AgentPersona>[];
    for (final persona in discovered) {
      if (seen.add(persona.name)) {
        result.add(persona);
      }
    }
    return result;
  }

  /// Loads every parseable `*.md` persona from [dir], tagging each with
  /// [source].
  ///
  /// Files are visited in sorted order. A missing directory yields an empty
  /// list; individual files that fail to parse are skipped.
  Future<List<AgentPersona>> loadFromDir(
    String dir,
    AgentPersonaSource source,
  ) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      return const [];
    }

    final files = <File>[];
    await for (final entity in directory.list(followLinks: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.md')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));

    final personas = <AgentPersona>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        personas.add(
          parsePersona(content, source: source, filePath: file.path),
        );
      } catch (_) {
        // Tolerate unreadable or unparseable files; skip and continue.
      }
    }
    return personas;
  }

  String _agentsDir(String root) {
    final normalized = root.endsWith(Platform.pathSeparator)
        ? root.substring(0, root.length - Platform.pathSeparator.length)
        : root;
    return '$normalized${Platform.pathSeparator}.cc'
        '${Platform.pathSeparator}$agentsDirName';
  }

  Map _extractFrontmatter(String content, String? filePath) {
    final trimmed = content.trimLeft();
    if (!trimmed.startsWith('---')) {
      throw PersonaParseException(
        'No YAML frontmatter found (expected leading "---" fence)',
        filePath: filePath,
      );
    }

    final secondDelim = trimmed.indexOf('---', 3);
    if (secondDelim == -1) {
      throw PersonaParseException(
        'Unterminated YAML frontmatter (missing closing "---" fence)',
        filePath: filePath,
      );
    }

    final yamlStr = trimmed.substring(3, secondDelim).trim();
    final dynamic parsed = yamlStr.isEmpty ? null : loadYaml(yamlStr);
    if (parsed is YamlMap) {
      return parsed;
    }
    if (parsed is Map) {
      return parsed;
    }
    throw PersonaParseException(
      'Frontmatter is not a mapping',
      filePath: filePath,
    );
  }

  String _extractMarkdownBody(String content) {
    final trimmed = content.trimLeft();
    if (!trimmed.startsWith('---')) {
      return content.trim();
    }

    final secondDelim = trimmed.indexOf('---', 3);
    if (secondDelim == -1) {
      return content.trim();
    }

    return trimmed.substring(secondDelim + 3).trim();
  }

  List<String> _parseStringList(Object? value) {
    if (value is YamlList) {
      return value.map((dynamic e) => e.toString()).toList();
    }
    if (value is List) {
      return value.map((dynamic e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const [];
  }

  List<String> _parseModels(Object? value) {
    if (value is YamlList) {
      return value
          .map((dynamic e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is List) {
      return value
          .map((dynamic e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const [];
  }

  String? _parseStringScalar(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  bool _parseBool(Object? value, {required bool orElse}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') {
        return true;
      }
      if (lower == 'false') {
        return false;
      }
    }
    return orElse;
  }
}
