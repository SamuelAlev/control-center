import 'package:cc_domain/features/sandboxing/domain/command_policy/shell_command_parser.dart';
import 'package:cc_harness/tools.dart' show ActionClass;

/// Reads a shell command line and names the policy rows it falls under.
///
/// A shell tool declares `processSpawn` and nothing else, so before this a rule
/// such as "Open a pull request: ask first" never saw `gh pr create` typed into
/// a shell — only the MCP tool that does the same thing. Both shell surfaces
/// that reach the policy (the harness `bash` runner and the Claude Code
/// PreToolUse hook) classify through here, so they cannot drift apart.
///
/// Shell effects are classified at preflight, regardless of whether a later
/// transport (such as the git push gateway) also authorizes the operation.
/// In particular, an explicit remote URL can bypass git's configured gateway
/// rewrite, so the shell policy must never rely on that rewrite to ask first.
///
/// This recognises conventional command syntax, not arbitrary scripts or
/// generated code. Unrecognised commands still require `processSpawn`.
class ShellActionClassifier {
  /// Creates a [ShellActionClassifier].
  const ShellActionClassifier();

  /// Command prefixes per class, in the same prefix vocabulary the command
  /// policy uses (`git -C dir commit` still matches `git commit`).
  static const Map<ActionClass, List<String>> rules = {
    ActionClass.gitPush: ['git push'],
    ActionClass.fileDelete: ['rm', 'rmdir', 'unlink', 'git rm', 'git clean'],
    ActionClass.gitCommit: [
      'git commit',
      'git merge',
      'git rebase',
      'git cherry-pick',
      'git revert',
      'git am',
    ],
    ActionClass.prCreate: ['gh pr create'],
    ActionClass.prPublish: [
      'gh pr merge',
      'gh pr review',
      'gh pr comment',
      'gh pr close',
      'gh pr edit',
      'gh pr ready',
      'gh pr reopen',
      'gh pr update-branch',
    ],
    ActionClass.vendorSyncWrite: [
      'gh issue create',
      'gh issue edit',
      'gh issue comment',
      'gh issue close',
    ],
    ActionClass.packageInstall: [
      'npm install',
      'npm i',
      'npm add',
      'pnpm add',
      'pnpm install',
      'yarn add',
      'bun add',
      'bun install',
      'pip install',
      'pip3 install',
      'uv add',
      'uv pip install',
      'cargo add',
      'cargo install',
      'gem install',
      'go get',
      'go install',
      'brew install',
      'dart pub add',
      'flutter pub add',
    ],
    ActionClass.networkEgress: ['curl', 'wget'],
  };

  /// The classes [command] effects. Empty for a command no rule recognises —
  /// the caller still declares `processSpawn` for running it at all.
  Set<ActionClass> classify(String command) {
    final classes = <ActionClass>{};
    for (final sub in parseShellCommand(command)) {
      final tokens = normalizeCommandTokens(sub);
      if (tokens.isEmpty) {
        continue;
      }
      for (final MapEntry(key: cls, value: prefixes) in rules.entries) {
        if (classes.contains(cls)) {
          continue;
        }
        for (final prefix in prefixes) {
          if (!matchesTokenizedCommandRule(tokens, prefix.split(' '))) {
            continue;
          }
          if (cls == ActionClass.fileDelete && _isDryRunDeletion(tokens)) {
            continue;
          }
          classes.add(cls);
          break;
        }
      }
      _classifyGhApi(tokens, classes);
    }
    return classes;
  }

  static bool _isDryRunDeletion(List<String> tokens) {
    if (tokens[0] != 'git') {
      return false;
    }
    final subcommand = matchesTokenizedCommandRule(tokens, const ['git', 'rm'])
        ? 'rm'
        : 'clean';
    final command = skipLeadingGlobalFlagTokens(tokens, 1, subcommand);
    if (command >= tokens.length || tokens[command] != subcommand) {
      return false;
    }
    final options = tokens.skip(command + 1).takeWhile((arg) => arg != '--');
    if (subcommand == 'rm' && options.contains('--cached')) {
      return true;
    }
    return options.any(
      (arg) =>
          arg == '-n' ||
          arg == '--dry-run' ||
          (arg.startsWith('-') &&
              !arg.startsWith('--') &&
              arg.substring(1).contains('n')),
    );
  }

  static final RegExp _prEndpoint = RegExp(
    r'^/?repos/[^/]+/[^/]+/pulls(?:/([^?]+))?/?(?:\?.*)?$',
  );

  static void _classifyGhApi(List<String> tokens, Set<ActionClass> classes) {
    if (tokens[0] != 'gh') {
      return;
    }
    final apiIndex = skipLeadingGlobalFlagTokens(tokens, 1, 'api');
    if (apiIndex >= tokens.length || tokens[apiIndex] != 'api') {
      return;
    }
    var method = 'GET';
    var fields = false;
    String? endpoint;
    for (var i = apiIndex + 1; i < tokens.length; i++) {
      final arg = tokens[i];
      if (arg == '-X' || arg == '--method') {
        if (i + 1 < tokens.length) {
          method = tokens[++i].toUpperCase();
        }
      } else if (arg.startsWith('--method=')) {
        method = arg.substring('--method='.length).toUpperCase();
      } else if (arg.startsWith('-X') && arg.length > 2) {
        method = arg.substring(2).toUpperCase();
      } else if (const {
        '-f',
        '-F',
        '--field',
        '--raw-field',
        '--input',
      }.contains(arg)) {
        fields = true;
        i++;
      } else if (arg.startsWith('--field=') ||
          arg.startsWith('--raw-field=') ||
          arg.startsWith('--input=') ||
          ((arg.startsWith('-f') || arg.startsWith('-F')) && arg.length > 2)) {
        fields = true;
      } else if (const {
        '-H',
        '--header',
        '--hostname',
        '-q',
        '--jq',
        '-t',
        '--template',
      }.contains(arg)) {
        i++;
      } else if (arg.startsWith('-')) {
        continue;
      } else {
        endpoint ??= arg;
      }
    }
    if (endpoint == null) {
      return;
    }
    // gh api uses POST when fields or an input body are supplied by default.
    if (method == 'GET' &&
        fields &&
        !tokens.any(
          (arg) =>
              arg == '-X' ||
              arg == '--method' ||
              arg.startsWith('-X') ||
              arg.startsWith('--method='),
        )) {
      method = 'POST';
    }
    if (const {'GET', 'HEAD', 'OPTIONS'}.contains(method)) {
      return;
    }
    final match = _prEndpoint.firstMatch(endpoint);
    if (match == null) {
      return;
    }
    final target = match.group(1);
    if (target == null && method == 'POST') {
      classes.add(ActionClass.prCreate);
    } else if (target != null) {
      classes.add(ActionClass.prPublish);
    }
  }
}
