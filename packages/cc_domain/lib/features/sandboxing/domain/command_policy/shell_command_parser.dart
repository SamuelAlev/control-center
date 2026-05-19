/// Shell command parser and rule matcher, ported from the reference
/// sandbox runtime's command policy engine.
///
/// Pure Dart (no dart:io) so it lives in the domain layer and is shared
/// by the universal preflight (Phase 2.3), the MCP dispatcher gate
/// (Phase 2.4), and the Claude hook (Phase 4).
library;

/// Splits a shell command string into individual sub-commands.
///
/// Handles: pipes (`|`), logical operators (`&&`, `||`), semicolons (`;`),
/// and subshells (`()`). Respects single/double-quote state. Then expands
/// nested shell invocations (`bash -c 'git push'`).
List<String> parseShellCommand(String command) {
  final commands = <String>[];
  final current = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var parenDepth = 0;

  final runes = command.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    final c = runes[i];
    final char = String.fromCharCode(c);

    // Handle quotes.
    if (char == "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      current.write(char);
      continue;
    }
    if (char == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      current.write(char);
      continue;
    }

    // Skip splitting inside quotes.
    if (inSingleQuote || inDoubleQuote) {
      current.write(char);
      continue;
    }

    // Handle parentheses (subshells).
    if (char == '(') {
      parenDepth++;
      current.write(char);
      continue;
    }
    if (char == ')') {
      parenDepth--;
      current.write(char);
      continue;
    }

    // Skip splitting inside subshells.
    if (parenDepth > 0) {
      current.write(char);
      continue;
    }

    // Handle shell operators.
    switch (char) {
      case '|':
        if (i + 1 < runes.length && runes[i + 1] ==('|'.codeUnitAt(0))) {
          // ||
          final s = current.toString().trim();
          if (s.isNotEmpty) commands.add(s);
          current.clear();
          i++; // Skip second |
        } else {
          // Just a pipe.
          final s = current.toString().trim();
          if (s.isNotEmpty) commands.add(s);
          current.clear();
        }
      case '&':
        if (i + 1 < runes.length && runes[i + 1] ==('&'.codeUnitAt(0))) {
          // &&
          final s = current.toString().trim();
          if (s.isNotEmpty) commands.add(s);
          current.clear();
          i++; // Skip second &
        } else {
          // Background operator — keep in current command.
          current.write(char);
        }
      case ';':
        final s = current.toString().trim();
        if (s.isNotEmpty) commands.add(s);
        current.clear();
      default:
        current.write(char);
    }
  }

  // Add remaining command.
  final s = current.toString().trim();
  if (s.isNotEmpty) commands.add(s);

  // Handle nested shell invocations like "bash -c 'git push'".
  final expanded = <String>[];
  for (final cmd in commands) {
    expanded.addAll(expandShellInvocation(cmd));
  }

  return expanded;
}

/// Detects patterns like `bash -c 'cmd'` or `sh -lc 'cmd'` and extracts the
/// inner command for checking. Recognizes all 6 shells. Returns both the
/// outer command and the inner commands (we check both for safety).
List<String> expandShellInvocation(String command) {
  command = command.trim();
  if (command.isEmpty) return [];

  final tokens = tokenizeCommand(command);
  if (tokens.length < 3) return [command];

  // Check for shell -c pattern.
  final shell = basename(tokens[0]);
  final isShell = const {'sh', 'bash', 'zsh', 'ksh', 'dash', 'fish'}.contains(shell);

  if (!isShell) return [command];

  // Look for -c flag (could be combined with other flags like -lc, -ic, etc.).
  for (var i = 1; i < tokens.length - 1; i++) {
    final flag = tokens[i];
    // Check for -c, -lc, -ic, -ilc, etc. (any flag containing 'c').
    if (flag.startsWith('-') && flag.contains('c')) {
      // Next token is the command string.
      final innerCmd = tokens[i + 1];
      // Recursively parse the inner command.
      final innerCommands = parseShellCommand(innerCmd);
      // Return both the outer command and inner commands (we check both).
      final result = <String>[command];
      result.addAll(innerCommands);
      return result;
    }
  }

  return [command];
}

/// Splits a command string into tokens, respecting quotes.
List<String> tokenizeCommand(String command) {
  final tokens = <String>[];
  final current = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;

  for (final c in command.runes) {
    final char = String.fromCharCode(c);
    switch (char) {
      case "'" when !inDoubleQuote:
        inSingleQuote = !inSingleQuote;
      case '"' when !inSingleQuote:
        inDoubleQuote = !inDoubleQuote;
      case ' ' || '\t' when !inSingleQuote && !inDoubleQuote:
        if (current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
        }
      default:
        current.write(char);
    }
  }

  if (current.isNotEmpty) {
    tokens.add(current.toString());
  }

  return tokens;
}

/// Normalizes a command for matching: strips leading path from the
/// executable token (e.g. `/usr/bin/git` → `git`).
List<String> normalizeCommandTokens(String command) {
  command = command.trim();
  if (command.isEmpty) return [];

  final tokens = tokenizeCommand(command);
  if (tokens.isEmpty) return [];

  tokens[0] = basename(tokens[0]);
  return tokens;
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
  if (actualTokens[0] != ruleTokens[0]) return false;

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
      if (!matched) return false;
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
      if (next != '--' && !next.startsWith('-') && next != firstSubcommandToken) {
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
