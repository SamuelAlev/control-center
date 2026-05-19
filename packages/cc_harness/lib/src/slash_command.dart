/// Parses a leading `/command` from a user message for the built-in harness.
///
/// Built-in commands (`/plan`, `/goal`, `/loop`) change how the run behaves;
/// `/compact` folds the conversation history and is intercepted before any
/// dispatch; any other `/name` is resolved against the agent's skills (invoke
/// a skill by name). An unrecognized `/name` is treated as plain text — never
/// an error.
library;

/// A parsed leading slash command.
class ParsedSlashCommand {
  /// Creates a [ParsedSlashCommand].
  const ParsedSlashCommand({this.command, this.args = ''});

  /// The command token (without the leading `/`), or null when the message is
  /// not a slash command.
  final String? command;

  /// Everything after the command token, trimmed.
  final String args;

  /// Whether the message began with a `/command`.
  bool get isCommand => command != null;
}

/// The built-in harness commands with runtime effects (everything else is a
/// skill name). `compact` never reaches the harness: it is handled by the
/// messaging layer (a forced compaction pass, no turn dispatched).
const Set<String> harnessBuiltinCommands = {'plan', 'goal', 'loop', 'compact'};

final RegExp _commandPattern = RegExp(r'^/([A-Za-z0-9_:.-]+)\s*([\s\S]*)$');

/// Parses [message]; returns a non-command result when it does not start with
/// `/` or is just a bare slash.
ParsedSlashCommand parseSlashCommand(String message) {
  final trimmed = message.trimLeft();
  if (!trimmed.startsWith('/') || trimmed.length < 2) {
    return const ParsedSlashCommand();
  }
  final match = _commandPattern.firstMatch(trimmed);
  if (match == null) {
    return const ParsedSlashCommand();
  }
  return ParsedSlashCommand(
    command: match.group(1),
    args: (match.group(2) ?? '').trim(),
  );
}
