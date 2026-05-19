/// Replacement text for a tool result that carried no usable signal.
const String elidedResultMarker = '[Uneventful result elided]';

/// Tools whose output must never be elided or pruned — losing them would break
/// the agent's working state (active skill instructions, plan file reads, the
/// current todo list). Both underscore and non-underscore spellings are listed
/// because tool names vary across surfaces (`todo_write` vs `todowrite`).
const Set<String> pruneProtectedTools = {
  'skill',
  'todo_write',
  'todowrite',
  'exit_plan_mode',
  'exitplanmode',
};

/// Detects tool results that are contextually useless and safe to blank: a
/// search that matched nothing, a job that timed out with no output, an empty
/// listing. Eliding these reclaims context without dropping any real signal —
/// the call itself stays in the transcript so the agent still sees that it ran.
///
/// This is deliberately conservative: when in doubt it returns `false` (keep
/// the output). It never flags an error result that carries a real message,
/// since the error text is signal.
class ToolResultElision {
  /// Creates a [ToolResultElision] classifier.
  const ToolResultElision();

  /// Whether [outputs] from [toolName] is an uneventful result worth eliding.
  bool isUseless({
    required String toolName,
    required String outputs,
    required bool isError,
  }) {
    final normalizedTool = _normalize(toolName);
    if (pruneProtectedTools.contains(normalizedTool)) {
      return false;
    }

    final trimmed = outputs.trim();
    final lower = trimmed.toLowerCase();

    // A short output that is essentially just a timeout notice is uneventful.
    // Guard on length so a large result (e.g. a build log) that merely mentions
    // "timed out" somewhere is not silently blanked.
    if (trimmed.length < 200 &&
        (lower.contains('timed out') || lower.contains('timeout exceeded'))) {
      return true;
    }

    // A genuine error with a message is signal — keep it.
    if (isError) {
      return false;
    }

    // Empty / whitespace-only output.
    if (trimmed.isEmpty) {
      return true;
    }

    // Search-family tools that matched nothing.
    if (_isSearchTool(normalizedTool)) {
      if (_looksEmptySearch(lower)) {
        return true;
      }
    }

    // Generic "nothing happened" phrasings common to many tools.
    const emptyPhrases = [
      'no matches found',
      'no results found',
      'no results',
      'no files found',
      'no matching files',
      'nothing to show',
      'no changes',
      '0 results',
      'empty result',
      '(no output)',
    ];
    for (final phrase in emptyPhrases) {
      if (lower == phrase || lower == '$phrase.') {
        return true;
      }
    }

    return false;
  }

  bool _isSearchTool(String tool) =>
      tool == 'grep' ||
      tool == 'find' ||
      tool == 'search' ||
      tool == 'glob' ||
      tool.contains('search');

  bool _looksEmptySearch(String lower) {
    if (lower.startsWith('no matches') ||
        lower.startsWith('no results') ||
        lower.startsWith('no files')) {
      return true;
    }
    // Tools that print a trailing count line like "0 matches".
    return lower == '0 matches' || lower.endsWith('found 0 matches');
  }

  String _normalize(String toolName) {
    var name = toolName.toLowerCase();
    if (name.startsWith('mcp__')) {
      final lastSep = name.lastIndexOf('__');
      if (lastSep >= 0 && lastSep + 2 < name.length) {
        name = name.substring(lastSep + 2);
      }
    }
    return name;
  }
}
