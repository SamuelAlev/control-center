import 'dart:io';

import 'package:yaml/yaml.dart';

/// Agent md parse result.
class AgentMdParseResult {
  /// Creates a new [AgentMdParseResult].
  const AgentMdParseResult({
    required this.name,
    required this.title,
    required this.reportsTo,
    required this.skills,
    required this.personaMarkdown,
    required this.agentMdPath,
  });

  /// The agent's unique name.
  final String name;

  /// The agent's display title.
  final String title;

  /// The name of the agent this one reports to.
  final String? reportsTo;

  /// The skills assigned to this agent.
  final List<String> skills;

  /// The markdown persona description.
  final String personaMarkdown;

  /// The file path to the agent's markdown definition.
  final String agentMdPath;
}

/// Team md parse result.
class TeamMdParseResult {
  /// Creates a new [TeamMdParseResult].
  const TeamMdParseResult({
    required this.name,
    required this.description,
    required this.slug,
    required this.managerPath,
    required this.includes,
    required this.tags,
    required this.teamMarkdown,
  });

  /// The team's display name.
  final String name;

  /// A short description of the team.
  final String description;

  /// The team's URL-friendly slug.
  final String slug;

  /// The file path to the team manager's markdown.
  final String? managerPath;

  /// Additional agent files included in this team.
  final List<String> includes;

  /// Tags associated with this team.
  final List<String> tags;

  /// The full markdown content of the team definition.
  final String teamMarkdown;
}

/// Agents md parser.
class AgentsMdParser {
  /// Discovers agents by scanning project directories for AGENTS.md files.
  Future<List<AgentMdParseResult>> discoverAgents(String projectPath) async {
    final agents = <AgentMdParseResult>[];
    final searchPaths = [
      '$projectPath/.kilo/agent',
      '$projectPath/agents',
      '$projectPath/.claude/agents',
      projectPath,
    ];

    for (final searchPath in searchPaths) {
      final dir = Directory(searchPath);
      if (!dir.existsSync()) {
        continue;
      }

      await for (final entity in dir.list(
        recursive: searchPath == projectPath,
      )) {
        if (entity is File && entity.path.endsWith('AGENTS.md')) {
          try {
            final result = parseAgentFile(entity.path);
            agents.add(result);
          } catch (_) {
            // Skip malformed files
          }
        }
      }
    }

    return agents;
  }

  /// Parse agent file.
  AgentMdParseResult parseAgentFile(String path) {
    final file = File(path);
    final content = file.readAsStringSync();

    final yamlDoc = _extractFrontmatter(content);
    final markdownBody = _extractMarkdownBody(content);

    if (yamlDoc == null) {
      throw const FormatException('No YAML frontmatter found');
    }

    final name = yamlDoc['name'] as String?;
    if (name == null || name.isEmpty) {
      throw const FormatException('Missing required "name" field');
    }

    return AgentMdParseResult(
      name: name,
      title: (yamlDoc['title'] as String?) ?? name,
      reportsTo: yamlDoc['reportsTo'] as String?,
      skills: _parseStringList(yamlDoc['skills']),
      personaMarkdown: markdownBody.trim(),
      agentMdPath: path,
    );
  }

  /// Parse team file.
  TeamMdParseResult? parseTeamFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }

    final content = file.readAsStringSync();
    final yamlDoc = _extractFrontmatter(content);
    final markdownBody = _extractMarkdownBody(content);

    if (yamlDoc == null) {
      return null;
    }

    final name = yamlDoc['name'] as String?;
    final slug = yamlDoc['slug'] as String?;
    if (name == null || slug == null) {
      return null;
    }

    return TeamMdParseResult(
      name: name,
      description: (yamlDoc['description'] as String?) ?? '',
      slug: slug,
      managerPath: yamlDoc['manager'] as String?,
      includes: _parseStringList(yamlDoc['includes']),
      tags: _parseStringList(yamlDoc['tags']),
      teamMarkdown: markdownBody.trim(),
    );
  }

  YamlMap? _extractFrontmatter(String content) {
    final trimmed = content.trim();
    if (!trimmed.startsWith('---')) {
      return null;
    }

    final secondDelim = trimmed.indexOf('---', 3);
    if (secondDelim == -1) {
      return null;
    }

    final yamlStr = trimmed.substring(3, secondDelim).trim();
    final parsed = loadYaml(yamlStr);

    if (parsed is YamlMap) {
      return parsed;
    }
    return null;
  }

  String _extractMarkdownBody(String content) {
    final trimmed = content.trim();
    if (!trimmed.startsWith('---')) {
      return trimmed;
    }

    final secondDelim = trimmed.indexOf('---', 3);
    if (secondDelim == -1) {
      return trimmed;
    }

    return trimmed.substring(secondDelim + 3).trim();
  }

  List<String> _parseStringList(dynamic value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}

