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
  ///
  /// Every branch that can return `true` needs at most a few dozen characters
  /// of the (trimmed) output, so this deliberately never materializes
  /// `outputs.trim().toLowerCase()`. Compaction re-classifies every surviving
  /// result on every turn; two full copies of each 20–60 KB result per turn is
  /// megabytes of churn per turn by the end of a long session.
  bool isUseless({
    required String toolName,
    required String outputs,
    required bool isError,
  }) {
    final normalizedTool = _normalize(toolName);
    if (pruneProtectedTools.contains(normalizedTool)) {
      return false;
    }

    final start = _trimStart(outputs);
    final end = _trimEnd(outputs, start);
    final trimmedLength = end - start;

    // A short output that is essentially just a timeout notice is uneventful.
    // Guard on length so a large result (e.g. a build log) that merely mentions
    // "timed out" somewhere is not silently blanked.
    if (trimmedLength < 200) {
      final lower = outputs.substring(start, end).toLowerCase();
      if (lower.contains('timed out') || lower.contains('timeout exceeded')) {
        return true;
      }
    }

    // A genuine error with a message is signal — keep it.
    if (isError) {
      return false;
    }

    // Empty / whitespace-only output.
    if (trimmedLength == 0) {
      return true;
    }

    // Search-family tools that matched nothing.
    if (_isSearchTool(normalizedTool)) {
      if (_looksEmptySearch(outputs, start, end)) {
        return true;
      }
    }

    // Generic "nothing happened" phrasings common to many tools. All are exact
    // matches, so anything longer than the longest phrase cannot be one.
    if (trimmedLength <= _longestEmptyPhrase + 1) {
      final lower = outputs.substring(start, end).toLowerCase();
      for (final phrase in _emptyPhrases) {
        if (lower == phrase || lower == '$phrase.') {
          return true;
        }
      }
    }

    return false;
  }

  static const List<String> _emptyPhrases = [
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

  /// Length of the longest entry in [_emptyPhrases] ('no matching files').
  static const int _longestEmptyPhrase = 17;

  /// Index of the first non-whitespace code unit, or `s.length` when blank.
  static int _trimStart(String s) {
    var i = 0;
    while (i < s.length && _isWhitespace(s.codeUnitAt(i))) {
      i++;
    }
    return i;
  }

  /// Index just past the last non-whitespace code unit at or after [start].
  static int _trimEnd(String s, int start) {
    var i = s.length;
    while (i > start && _isWhitespace(s.codeUnitAt(i - 1))) {
      i--;
    }
    return i;
  }

  /// The ASCII whitespace `String.trim` strips in practice for tool output.
  ///
  /// Deliberately narrower than `String.trim`'s Unicode White_Space set: an
  /// exotic leading space then leaves the measured length slightly LONGER,
  /// which can only skip a short-output branch and keep the result. This class
  /// is conservative by contract, so erring toward "keep" is correct.
  static bool _isWhitespace(int c) =>
      c == 0x20 ||
      c == 0x0A ||
      c == 0x0D ||
      c == 0x09 ||
      c == 0x0B ||
      c == 0x0C;

  bool _isSearchTool(String tool) =>
      tool == 'grep' ||
      tool == 'find' ||
      tool == 'search' ||
      tool == 'glob' ||
      tool.contains('search');

  /// Prefix/suffix probes over `outputs[start:end]` without copying the middle.
  bool _looksEmptySearch(String outputs, int start, int end) {
    final head = outputs
        .substring(start, start + 10 > end ? end : start + 10)
        .toLowerCase();
    if (head.startsWith('no matches') ||
        head.startsWith('no results') ||
        head.startsWith('no files')) {
      return true;
    }
    // Tools that print a trailing count line like "0 matches".
    const tailPhrase = 'found 0 matches';
    if (end - start == 9 &&
        outputs.substring(start, end).toLowerCase() == '0 matches') {
      return true;
    }
    if (end - start < tailPhrase.length) {
      return false;
    }
    return outputs.substring(end - tailPhrase.length, end).toLowerCase() ==
        tailPhrase;
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
