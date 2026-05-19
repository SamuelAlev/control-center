/// Parses a leading `/command` from a user message for the built-in harness.
///
/// Built-in commands (`/plan`, `/goal`, `/loop`) change how the run behaves and
/// `/compact` folds the conversation history before any dispatch. Skills live
/// under their own `/skill:` namespace — `/skill:<name>`, or
/// `/skill:<repo>:<name>` for one a checked-out repo ships. An unrecognized
/// `/name` is treated as plain text — never an error.
///
/// The namespace is what keeps the two vocabularies apart. Resolving a bare
/// `/name` against skills means every builtin permanently shadows a skill of
/// the same name: a skill called `plan` or `compact` was simply unreachable,
/// silently, and every skill added to a workspace narrowed the names a future
/// builtin could take.
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

/// The namespace every skill invocation carries: `/skill:<name>` or
/// `/skill:<repo>:<name>`.
const String skillCommandPrefix = 'skill:';

/// The skill [command] names, or null when it is not a skill invocation.
///
/// Returns the part after `skill:` — which may itself be `<repo>:<name>` and is
/// resolved further downstream. A BARE name is still accepted when it is not a
/// builtin, so messages and habits from before the namespace existed keep
/// working; the prefixed form is the one that always resolves.
String? skillNameFor(String command) {
  if (command.startsWith(skillCommandPrefix)) {
    final rest = command.substring(skillCommandPrefix.length);
    return rest.isEmpty ? null : rest;
  }
  return harnessBuiltinCommands.contains(command) ? null : command;
}

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
