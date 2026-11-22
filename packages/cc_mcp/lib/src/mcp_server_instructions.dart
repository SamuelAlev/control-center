import 'package:cc_domain/features/mcp/domain/value_objects/tool_taxonomy.dart';

/// The MCP `initialize` answer's `instructions`: what a client puts in its
/// system prompt at session start (Claude Code does), and so the one place
/// this server says how its tools are reached.
///
/// Claude Code keeps only the first [maxChars] characters, so the statement
/// a run must not miss comes first and the index is cut, never the rules.
// ignore: avoid_classes_with_only_static_members
abstract final class McpServerInstructions {
  /// What Claude Code keeps of a server's instructions, and of an upfront
  /// tool's description.
  static const int maxChars = 4096;

  /// For every caller without the script surface: what the tools cover and
  /// when to search for one. It names no tool, since the caller may have
  /// none of the discovery tools.
  static const String generic =
      'Control Center tools cover the workspace: agents and conversations, '
      'tickets and approvals, shared memory, the code index, pull requests '
      'and checklists. When a tool you need is not loaded, search for it by '
      'what it does before you tell the user a capability is missing.';

  /// For an attested run with `repl`: how its script-only tools are reached,
  /// and an index of [scriptOnlyNames] (first-party names only: an external
  /// server's names are a third party's text) by category, names sorted, so
  /// the same names in any order give the same bytes. When the index does
  /// not fit in [maxChars], whole categories are listed in order while they
  /// fit and one line counts the rest.
  static String forScripts(Iterable<String> scriptOnlyNames) {
    final names = {...scriptOnlyNames};
    final head =
        'Control Center tools for this run.\n'
        '\n'
        '`repl` is loaded. It runs a JavaScript script that calls Control '
        'Center tools as `await tools.<name>({...})`. ${names.length} tools '
        'are callable only that way: they are not in your tool list and tool '
        'search does not find them. When your instructions name a tool you do '
        'not have, call it from a `repl` script; never call it directly and '
        'never report it as missing. In a script, `await describeTool(name)` '
        "returns a tool's arguments and `await searchTools(query)` finds a "
        'tool from a plain-language description. Tell the user a capability '
        'is missing only after a `searchTools` came back empty.\n'
        '\n'
        'The Control Center tools in your tool list are called directly; tool '
        'search loads those that are not loaded yet.\n';
    if (names.isEmpty) {
      return head.trimRight();
    }
    final buf = StringBuffer('$head\nCallable only from a `repl` script:\n');
    var left = names.length;
    String cut(int k) => '- And $k more, found with `searchTools`.';
    for (final entry in groupToolsByCategory(names).entries) {
      final sorted = [...entry.value]..sort();
      final line =
          '- ${entry.key.label}: ${sorted.map((n) => '`$n`').join(', ')}';
      final rest = left - sorted.length;
      final after =
          buf.length + line.length + (rest == 0 ? 0 : 1 + cut(rest).length);
      if (after > maxChars) {
        break;
      }
      buf.writeln(line);
      left = rest;
    }
    if (left > 0) {
      buf.write(cut(left));
    }
    return buf.toString().trimRight();
  }
}
