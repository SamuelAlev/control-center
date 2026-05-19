/// Frontmatter-based agent persona definitions and read-only tool
/// classification.
///
/// A persona is an agent definition expressed as markdown with YAML
/// frontmatter, discovered from `.cc/agents/` directories (see the infra
/// `PersonaLoader`). The frontmatter describes the agent's identity and
/// capabilities; the markdown body becomes the [AgentPersona.systemPrompt].
///
/// This file is pure Dart with no `dart:io` dependency so it can live in the
/// domain layer.
library;

/// Where an [AgentPersona] was discovered from.
///
/// Precedence is highest-wins in the order [project] > [user] > [bundled]:
/// a project-level persona shadows a user-level one with the same name, which
/// in turn shadows a bundled persona.
enum AgentPersonaSource {
  /// Discovered from the project's `.cc/agents/` directory.
  project,

  /// Discovered from the user's `~/.cc/agents/` directory.
  user,

  /// Shipped with the application as a built-in default.
  bundled,
}

/// A file-based agent persona parsed from markdown + YAML frontmatter.
///
/// Frontmatter fields map to:
/// `name`, `description`, `tools`, `spawns`, `model` (a single string or a
/// list, normalized into [models]), `thinkingLevel`, `blocking`,
/// `readSummarize`, and `autoloadSkills`. The markdown body becomes
/// [systemPrompt].
class AgentPersona {
  /// Creates an [AgentPersona].
  ///
  /// [name] and [description] are required and [name] must be non-empty. All
  /// list fields default to empty, [spawns] defaults to `''`, [blocking]
  /// defaults to `false`, and [readSummarize] defaults to `true`.
  AgentPersona({
    required this.name,
    required this.description,
    this.tools = const [],
    this.spawns = '',
    this.models = const [],
    this.thinkingLevel,
    this.blocking = false,
    this.readSummarize = true,
    this.autoloadSkills = const [],
    this.systemPrompt = '',
    this.source = AgentPersonaSource.bundled,
    this.filePath,
  }) : assert(name.isNotEmpty, 'AgentPersona.name must be non-empty');

  /// The persona's unique name. Used as the dedup key during discovery.
  final String name;

  /// A short description of what this persona does.
  final String description;

  /// The tool names this persona is permitted to use.
  ///
  /// An empty list conventionally means "no explicit restriction".
  final List<String> tools;

  /// The persona name(s) this persona may spawn, or `'*'` for "any".
  ///
  /// Empty (`''`) means the persona may not spawn other agents.
  final String spawns;

  /// The model identifier(s) for this persona.
  ///
  /// The frontmatter `model` field may be a single string or a list; both are
  /// normalized into this list. The first entry is the primary model and any
  /// remaining entries act as ordered fallbacks. See [model] for the primary.
  final List<String> models;

  /// The reasoning/thinking effort level for this persona, if specified.
  final String? thinkingLevel;

  /// Whether spawning this persona blocks the spawner until it completes.
  final bool blocking;

  /// Whether this persona's read tool outputs should be summarized.
  final bool readSummarize;

  /// Skills to autoload into this persona's context at spawn time.
  final List<String> autoloadSkills;

  /// The markdown body of the persona file, used as the system prompt.
  final String systemPrompt;

  /// Where this persona was discovered from.
  final AgentPersonaSource source;

  /// The absolute path of the file this persona was parsed from, if any.
  final String? filePath;

  /// The primary model for this persona, or `null` when none is specified.
  ///
  /// This is the first entry of [models].
  String? get model {
    if (models.isEmpty) {
      return null;
    }
    return models.first;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentPersona &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          _listEquals(tools, other.tools) &&
          spawns == other.spawns &&
          _listEquals(models, other.models) &&
          thinkingLevel == other.thinkingLevel &&
          blocking == other.blocking &&
          readSummarize == other.readSummarize &&
          _listEquals(autoloadSkills, other.autoloadSkills) &&
          systemPrompt == other.systemPrompt &&
          source == other.source &&
          filePath == other.filePath;

  @override
  int get hashCode => Object.hash(
    name,
    description,
    Object.hashAll(tools),
    spawns,
    Object.hashAll(models),
    thinkingLevel,
    blocking,
    readSummarize,
    Object.hashAll(autoloadSkills),
    systemPrompt,
    source,
    filePath,
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Canonical set of read-only tool names, lower-cased.
///
/// A persona whose entire toolset is read-only (see [isReadOnlyToolset]) may
/// be safely run in plan/review modes, where mutating the workspace is
/// disallowed. This set gates that classification, so it intentionally lists
/// only tools that cannot write to the filesystem, run commands, or otherwise
/// cause side effects.
const Set<String> kReadOnlyToolNames = {
  'read',
  'grep',
  'find',
  'ls',
  'glob',
  'search',
  'list',
  'view',
  'cat',
  'web_fetch',
  'web_search',
};

/// Returns `true` when [name] is a known read-only tool, case-insensitively.
bool isReadOnlyTool(String name) {
  return kReadOnlyToolNames.contains(name.toLowerCase());
}

/// Returns `true` when every tool in [tools] is read-only.
///
/// An empty toolset is considered read-only (there is nothing that can
/// mutate). See [kReadOnlyToolNames] for the classification.
bool isReadOnlyToolset(Iterable<String> tools) {
  for (final tool in tools) {
    if (!isReadOnlyTool(tool)) {
      return false;
    }
  }
  return true;
}
