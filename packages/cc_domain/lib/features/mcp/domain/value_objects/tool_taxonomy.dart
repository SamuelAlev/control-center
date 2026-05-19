/// Groups tool names into human-readable categories for the prompt's index of
/// deferred tools.
///
/// A flat list of ~100 names reads as noise; the same names under eight
/// headings read as a map of what the run can do, which is what lets a model
/// pick a name directly instead of searching. Anthropic's own guidance for
/// deferred tool surfaces is to name the categories in the system prompt for
/// exactly this reason.
///
/// Deliberately a RULE TABLE rather than an exhaustive name→category map: a map
/// would silently rot the day someone registers a tool and forgets to add it,
/// and the failure mode (a tool quietly filed under "other") is invisible. Rules
/// keyed on the vocabulary the names already use stay correct for tools that do
/// not exist yet.
library;

/// A tool category, ordered as it should appear in the prompt.
enum ToolCategory {
  /// Files, shell, search — the built-in working vocabulary.
  workspace('Files, shell and search'),

  /// Tickets, projects and their relations.
  ticketing('Tickets and projects'),

  /// Durable memory: facts, policies, observations, notes.
  memory('Memory and knowledge'),

  /// Code review: findings, verdicts, publication.
  review('Code review'),

  /// Pull requests and the forge.
  forge('Pull requests and forges'),

  /// The code graph: symbols, callers, impact.
  codeGraph('Code graph'),

  /// Plans, orchestrations, pipelines, playbooks, goals.
  orchestration('Plans and orchestration'),

  /// Spaces, messages, other agents, delegation.
  collaboration('Messaging and agents'),

  /// Artifacts an agent publishes back to a human.
  artifacts('Artifacts and outputs'),

  /// Skills, capabilities and their supply chain.
  skills('Skills'),

  /// Enclosures: desktop, browser and phone rigs.
  rigs('Virtual machines (rigs)'),

  /// Meetings, calendars and transcripts.
  meetings('Meetings and calendar'),

  /// Workspaces, repos and server settings.
  administration('Workspaces, repos and settings'),

  /// Anything the rules do not recognise.
  other('Other');

  const ToolCategory(this.label);

  /// Heading shown in the prompt.
  final String label;
}

/// Built-in tool names that form the loop's working vocabulary.
const Set<String> _workspaceTools = {
  'read',
  'write',
  'edit',
  'apply_patch',
  'search',
  'find',
  'search_files',
  'bash',
  'lsp',
  'lsp_rename',
  'ast_grep',
  'ast_edit',
  'resolve',
  'checkpoint',
  'rewind',
  'web_fetch',
  'web_search',
};

/// Ordered rules: the first whose predicate matches wins.
///
/// Order encodes precedence where vocabularies overlap — `ticket_pr_link`
/// is ticketing before it is forge, and `publish_review_to_github` is review
/// before it is forge.
final List<(ToolCategory, bool Function(String))> _rules = [
  (ToolCategory.workspace, _workspaceTools.contains),
  (ToolCategory.ticketing, (n) => n.contains('ticket') || n.contains('todo')),
  (ToolCategory.review, (n) => n.contains('review') || n.contains('finding')),
  // Before memory, and that ordering is load-bearing: "artifact" contains
  // "fact", so the memory rule would otherwise file every artifact tool under
  // knowledge.
  (
    ToolCategory.artifacts,
    (n) => n.contains('artifact') || n.contains('output'),
  ),
  (
    ToolCategory.memory,
    (n) =>
        n.contains('memory') ||
        n.contains('fact') ||
        n.contains('polic') ||
        n.contains('belief') ||
        n.contains('observation') ||
        n.contains('notes') ||
        n.contains('remember') ||
        n.contains('decision'),
  ),
  (ToolCategory.codeGraph, (n) => n.startsWith('code_') || n == 'search_code'),
  (
    ToolCategory.orchestration,
    (n) =>
        n.contains('orchestration') ||
        n.contains('plan') ||
        n.contains('playbook') ||
        n.contains('pipeline') ||
        n.contains('goal') ||
        n.contains('project'),
  ),
  (
    ToolCategory.forge,
    (n) =>
        n.contains('_pr') ||
        n.contains('pr_') ||
        n.contains('pull_request') ||
        n.contains('github') ||
        n.contains('gitlab') ||
        n.contains('merge'),
  ),
  (
    ToolCategory.collaboration,
    (n) =>
        n.contains('message') ||
        n.contains('space') ||
        n.contains('agent') ||
        n.contains('delegate') ||
        n.contains('consult') ||
        n.contains('team') ||
        n.contains('ask_user') ||
        // Spawning a subagent is delegation, whatever the verb is called.
        n == 'task',
  ),
  (ToolCategory.skills, (n) => n.contains('skill')),
  (
    ToolCategory.rigs,
    (n) =>
        n.contains('rig') ||
        n.contains('computer_use') ||
        n.contains('browser') ||
        n.contains('phone'),
  ),
  (
    ToolCategory.meetings,
    (n) =>
        n.contains('meeting') ||
        n.contains('calendar') ||
        n.contains('transcript'),
  ),
  (
    ToolCategory.administration,
    (n) =>
        n.contains('workspace') ||
        n.contains('repo') ||
        n.contains('setting') ||
        n.contains('tool'),
  ),
];

/// The category [toolName] belongs to.
///
/// Bridged external MCP tools (`mcp__server__tool`) are classified on the part
/// after the server prefix, so a GitHub server's `create_pull_request` files
/// under forges rather than under whatever its server happens to be called.
ToolCategory toolCategoryFor(String toolName) {
  var name = toolName.toLowerCase();
  if (name.startsWith('mcp__')) {
    final parts = name.substring('mcp__'.length).split('__');
    if (parts.length >= 2) {
      name = parts.sublist(1).join('__');
    }
  }
  for (final (category, matches) in _rules) {
    if (matches(name)) {
      return category;
    }
  }
  return ToolCategory.other;
}

/// Groups [toolNames] by category, preserving input order inside each group and
/// returning categories in enum order.
Map<ToolCategory, List<String>> groupToolsByCategory(
  Iterable<String> toolNames,
) {
  final grouped = <ToolCategory, List<String>>{};
  for (final name in toolNames) {
    grouped.putIfAbsent(toolCategoryFor(name), () => []).add(name);
  }
  return {
    for (final category in ToolCategory.values)
      if (grouped.containsKey(category)) category: grouped[category]!,
  };
}
