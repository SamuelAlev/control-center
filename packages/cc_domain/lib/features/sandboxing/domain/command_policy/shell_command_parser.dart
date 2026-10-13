/// Shell command parser and rule matcher, ported from the reference
/// sandbox runtime's command policy engine.
///
/// Pure Dart (no dart:io) so it lives in the domain layer and is shared
/// by the universal preflight (Phase 2.3), the MCP dispatcher gate
/// (Phase 2.4) and the Claude hook (Phase 4).
library;

final _loopHeader = RegExp(r'^(for|select)\s');
final _controlPrefix = RegExp(
  r'^(?:(?:then|do|else|if|elif|while|until|!)\s+|\{\s*)+',
);

/// Splits conventional shell command lines at unquoted control operators,
/// including line breaks, and exposes commands inside subshells and shell -c.
///
/// This is a best-effort command policy parser, not an interpreter for shell
/// scripts. It does not evaluate substitutions, aliases, functions or files.
List<String> parseShellCommand(String command) {
  final commands = <String>[];
  final current = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var escaped = false;
  var parenDepth = 0;

  void flush() {
    final text = current.toString().trim();
    if (text.isNotEmpty) {
      commands.add(text);
    }
    current.clear();
  }

  for (var i = 0; i < command.length; i++) {
    final char = command[i];
    if (escaped) {
      current.write(char);
      escaped = false;
      continue;
    }
    if (char == '\\' && !inSingleQuote) {
      if (i + 1 < command.length && command[i + 1] == '\n') {
        i++;
        continue;
      }
      current.write(char);
      escaped = true;
      continue;
    }
    if (char == "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
    } else if (char == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
    } else if (!inSingleQuote && !inDoubleQuote) {
      if (char == '(') {
        parenDepth++;
      }
      if (char == ')' && parenDepth > 0) {
        parenDepth--;
      }
      if (parenDepth == 0 &&
          (char == ';' ||
              char == '\n' ||
              char == '|' ||
              (char == '&' &&
                  (i == 0 ||
                      (command[i - 1] != '>' && command[i - 1] != '<')) &&
                  (i + 1 == command.length || command[i + 1] != '>')))) {
        flush();
        if (i + 1 < command.length &&
            ((char == '|' && command[i + 1] == '|') ||
                (char == '&' && command[i + 1] == '&'))) {
          i++;
        }
        continue;
      }
    }
    current.write(char);
  }
  flush();

  final expanded = <String>[];
  for (final part in commands) {
    var text = part;
    // Headers (`for name in ...`) are shell data, not executable commands.
    if (_loopHeader.hasMatch(text)) {
      continue;
    }
    text = text.replaceFirst(_controlPrefix, '').trim();
    if (text.isEmpty || text == 'done' || text == 'fi' || text == '}') {
      continue;
    }
    // A whole parenthesized group is a subshell. Reparse its interior rather
    // than treating the opening parenthesis as an executable name.
    if (text.startsWith('(') && text.endsWith(')')) {
      expanded.addAll(parseShellCommand(text.substring(1, text.length - 1)));
    } else {
      expanded.addAll(expandShellInvocation(text));
    }
  }
  return expanded;
}

/// Extracts the command string from a conventional shell `-c` invocation.
/// Returns the outer command too, for policy rules on the shell itself.
List<String> expandShellInvocation(String command) {
  command = command.trim();
  if (command.isEmpty) {
    return [];
  }
  final tokens = normalizeCommandTokens(command);
  if (tokens.length < 3 ||
      !const {'sh', 'bash', 'zsh', 'ksh', 'dash', 'fish'}.contains(tokens[0])) {
    return [command];
  }
  for (var i = 1; i < tokens.length - 1; i++) {
    final flag = tokens[i];
    if (flag.startsWith('-') &&
        !flag.startsWith('--') &&
        flag.substring(1).contains('c')) {
      return [command, ...parseShellCommand(tokens[i + 1])];
    }
  }
  return [command];
}

/// Tokenizes words while removing shell quoting. Escaped spaces and quotes
/// remain within their word, rather than becoming control operators.
List<String> tokenizeCommand(String command) {
  final tokens = <String>[];
  final current = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var escaped = false;
  var started = false;

  void flush() {
    if (started) {
      tokens.add(current.toString());
    }
    current.clear();
    started = false;
  }

  for (final c in command.runes) {
    final char = String.fromCharCode(c);
    if (escaped) {
      current.write(char);
      escaped = false;
      continue;
    }
    if (char == '\\' && !inSingleQuote) {
      escaped = true;
      started = true;
      continue;
    }
    if (char == "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      started = true;
      continue;
    }
    if (char == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      started = true;
      continue;
    }
    if ((char == ' ' || char == '\t' || char == '\n') &&
        !inSingleQuote &&
        !inDoubleQuote) {
      flush();
    } else {
      current.write(char);
      started = true;
    }
  }
  if (escaped) {
    current.write('\\');
  }
  flush();
  return tokens;
}

final _assignment = RegExp(r'^[a-zA-Z_][a-zA-Z_0-9]*=');

/// Normalizes the executable name and conventional assignment/env/command
/// prefixes, without mistaking their argument values for an executable.
List<String> normalizeCommandTokens(String command) {
  final tokens = tokenizeCommand(command.trim());
  var index = 0;
  while (index < tokens.length) {
    if (_assignment.hasMatch(tokens[index])) {
      index++;
      continue;
    }
    final wrapper = basename(tokens[index]);
    if (wrapper == 'command') {
      index++;
      while (index < tokens.length &&
          (tokens[index] == '-p' || tokens[index] == '--')) {
        index++;
      }
      // `command -v` and `-V` only look up a command; they do not run it.
      if (index < tokens.length &&
          (tokens[index] == '-v' || tokens[index] == '-V')) {
        return ['command', ...tokens.skip(index)];
      }
      continue;
    }
    if (wrapper == 'env') {
      index++;
      while (index < tokens.length) {
        final token = tokens[index];
        if (_assignment.hasMatch(token) ||
            const {
              '-i',
              '--ignore-environment',
              '-0',
              '--null',
              '--',
            }.contains(token)) {
          index++;
        } else if (const {'-u', '--unset', '-C', '--chdir'}.contains(token)) {
          index += 2;
        } else if (token.startsWith('--unset=') ||
            token.startsWith('--chdir=')) {
          index++;
        } else {
          break;
        }
      }
      continue;
    }
    break;
  }
  if (index >= tokens.length) {
    return [];
  }
  return [basename(tokens[index]), ...tokens.skip(index + 1)];
}

/// Applies command-prefix semantics to normalized token slices.
///
/// Semantics:
/// - The executable token is always matched positionally.
/// - Tokens ending in `=` act as presence checks that may appear later in the
///   remaining argv.
/// - Before the first subcommand-like rule token, leading actual argv flags
///   are skipped so rules like `docker run --privileged` still match
///   `docker --debug run --privileged`.
/// - Other tokens remain positional.
bool matchesTokenizedCommandRule(
  List<String> actualTokens,
  List<String> ruleTokens,
) {
  if (actualTokens.isEmpty ||
      ruleTokens.isEmpty ||
      actualTokens.length < ruleTokens.length) {
    return false;
  }
  if (actualTokens[0] != ruleTokens[0]) {
    return false;
  }

  var positionalIndex = 1;
  var allowLeadingGlobalFlags = true;

  for (final want in ruleTokens.skip(1)) {
    // Presence-check tokens (ending in '=').
    if (want.endsWith('=')) {
      var matched = false;
      for (final got in actualTokens.skip(positionalIndex)) {
        if (got.startsWith(want)) {
          matched = true;
          break;
        }
      }
      if (!matched) {
        return false;
      }
      continue;
    }

    // Skip leading global flags before the first subcommand token.
    if (allowLeadingGlobalFlags && isSubcommandLikeRuleToken(want)) {
      positionalIndex = skipLeadingGlobalFlagTokens(
        actualTokens,
        positionalIndex,
        want,
      );
      allowLeadingGlobalFlags = false;
    }

    if (positionalIndex >= actualTokens.length ||
        actualTokens[positionalIndex] != want) {
      return false;
    }
    positionalIndex++;
  }

  return true;
}

/// Checks if a token looks like a subcommand (not a flag, not `--`, not a
/// presence check).
bool isSubcommandLikeRuleToken(String token) {
  return token.isNotEmpty &&
      token != '--' &&
      !token.startsWith('-') &&
      !token.endsWith('=');
}

/// Skips leading global flag tokens (and their values) before the first
/// subcommand-like token.
int skipLeadingGlobalFlagTokens(
  List<String> actualTokens,
  int positionalIndex,
  String firstSubcommandToken,
) {
  while (positionalIndex < actualTokens.length) {
    final token = actualTokens[positionalIndex];
    if (token == '--' || !token.startsWith('-')) {
      return positionalIndex;
    }

    positionalIndex++;

    // Some leading global flags accept a separate value. If the next token
    // is a non-flag and is not the subcommand we're trying to match, treat
    // it as an option value and continue scanning.
    if (leadingGlobalFlagConsumesNextToken(token) &&
        positionalIndex < actualTokens.length) {
      final next = actualTokens[positionalIndex];
      if (next != '--' &&
          !next.startsWith('-') &&
          next != firstSubcommandToken) {
        positionalIndex++;
      }
    }
  }

  return positionalIndex;
}

/// Returns true when a leading global flag token consumes the next argv
/// slot as its value.
bool leadingGlobalFlagConsumesNextToken(String token) {
  if (token.startsWith('--')) {
    return !token.contains('=');
  }
  // Single short options (e.g. -C /path, -c key=value) often take a
  // separate value. Deliberately skip collapsed bundles like -abc.
  if (token.length == 2 && token.startsWith('-')) {
    return true;
  }
  return false;
}

/// Returns the basename of a path (last segment after `/` or `\`).
String basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final idx = normalized.lastIndexOf('/');
  return idx < 0 ? normalized : normalized.substring(idx + 1);
}
