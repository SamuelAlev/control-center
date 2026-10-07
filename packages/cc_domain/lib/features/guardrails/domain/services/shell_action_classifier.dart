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
/// This is the SOFT half of shell enforcement: it recognises the conventional
/// spelling of an effect, and an agent determined to hide one (`eval`, a
/// script file, a raw API call) can. The hard half is credential possession —
/// the token in an agent's environment cannot push, and every push goes
/// through the agent run gateway. That is why `git push` is NOT classified
/// here: the gateway asks at the moment the push actually happens, and a
/// second question from the shell layer would ask the operator twice about one
/// push.
///
/// Compound commands are split (`&&`, `|`, `;`, subshells, `bash -c '…'`) and
/// every part contributes, so `git add -A && gh pr create` is a commit-free
/// pull request, and `cd x && git commit` is a commit.
class ShellActionClassifier {
  /// Creates a [ShellActionClassifier].
  const ShellActionClassifier();

  /// Command prefixes per class, in the same prefix vocabulary the command
  /// policy uses (`git -C dir commit` still matches `git commit`).
  static const Map<ActionClass, List<String>> rules = {
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
          if (matchesTokenizedCommandRule(tokens, prefix.split(' '))) {
            classes.add(cls);
            break;
          }
        }
      }
    }
    return classes;
  }
}
