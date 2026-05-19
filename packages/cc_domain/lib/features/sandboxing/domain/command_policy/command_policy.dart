import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/shell_command_parser.dart';

/// Decision returned by [CommandPolicy.evaluate].
enum CommandDecision { allow, deny, prompt }

/// Command policy for a sandboxed agent. Evaluates a resolved command string
/// and returns allow / deny / prompt.
///
/// Precedence: **allow > deny > prompt > defaultAllow**. A command that
/// matches an `allow` rule is permitted even if it also matches a `deny` or
/// `prompt` rule — this lets per-agent overrides un-block a globally denied
/// command. Otherwise deny wins over prompt.
///
/// The `deny`, `prompt`, and `allow` lists use the command-prefix semantics
/// from [matchesTokenizedCommandRule]: the executable token is matched
/// positionally, `=`-suffix tokens are presence checks, and leading global
/// flags are skipped before the first subcommand token.
class CommandPolicy {
  /// Creates a [CommandPolicy].
  const CommandPolicy({
    this.deny = const [],
    this.allow = const [],
    this.prompt = const [],
  });

  /// Commands always denied (hard block). Multi-token like `git push`,
  /// single-token like `sudo`.
  final List<String> deny;

  /// Commands explicitly allowed (override deny/prompt). Per-agent overrides.
  final List<String> allow;

  /// Commands that require user consent (UAC prompt).
  final List<String> prompt;

  /// Evaluates [command] against the policy. Parses pipelines/chains/subshells
  /// and checks each sub-command independently. The most restrictive decision
  /// across all sub-commands wins (deny > prompt > allow).
  CommandDecision evaluate(String command) {
    final subCommands = parseShellCommand(command);
    if (subCommands.isEmpty) return CommandDecision.allow;

    var result = CommandDecision.allow;
    for (final sub in subCommands) {
      final decision = _evaluateSingle(sub);
      if (decision == CommandDecision.deny) return CommandDecision.deny;
      if (decision == CommandDecision.prompt && result != CommandDecision.deny) {
        result = CommandDecision.prompt;
      }
    }
    return result;
  }

  CommandDecision _evaluateSingle(String command) {
    final actualTokens = normalizeCommandTokens(command);
    if (actualTokens.isEmpty) return CommandDecision.allow;

    // Precedence: allow > deny > prompt > defaultAllow.
    for (final rule in allow) {
      if (_matchesRule(actualTokens, rule)) return CommandDecision.allow;
    }
    for (final rule in deny) {
      if (_matchesRule(actualTokens, rule)) return CommandDecision.deny;
    }
    for (final rule in prompt) {
      if (_matchesRule(actualTokens, rule)) return CommandDecision.prompt;
    }
    return CommandDecision.allow;
  }

  /// Matches a rule against actual tokens. Supports glob wildcards (`*`)
  /// in the executable token (e.g. `mkfs.*`).
  bool _matchesRule(List<String> actualTokens, String rule) {
    final ruleTokens = normalizeCommandTokens(rule);
    if (ruleTokens.isEmpty) return false;

    // Handle glob in the executable token (e.g. `mkfs.*`).
    if (ruleTokens[0].contains('*')) {
      if (!_globMatch(actualTokens[0], ruleTokens[0])) return false;
      // Check remaining tokens positionally (no global-flag skipping for
      // glob rules — keep it simple).
      if (actualTokens.length < ruleTokens.length) return false;
      for (var i = 1; i < ruleTokens.length; i++) {
        if (actualTokens[i] != ruleTokens[i]) return false;
      }
      return true;
    }

    return matchesTokenizedCommandRule(actualTokens, ruleTokens);
  }

  /// Simple glob match: `*` matches any sequence, `?` matches one char.
  bool _globMatch(String actual, String pattern) {
    final buf = StringBuffer('^');
    for (final c in pattern.split('')) {
      if (c == '*') {
        buf.write('.*');
      } else if (c == '?') {
        buf.write('.');
      } else if (RegExp(r'[.+^${}()|[\]\\]').hasMatch(c)) {
        buf.write('\\$c');
      } else {
        buf.write(c);
      }
    }
    buf.write(r'$');
    return RegExp(buf.toString()).hasMatch(actual);
  }
}

/// ---- Default policy lists (disjoint) ----

/// Commands always dangerous at any invocation — hard-denied in ALL modes.
const List<String> defaultDeny = [
  // Privilege escalation.
  'sudo',
  // System destruction.
  'rm -rf /',
  'rm -rf /*',
  'shutdown',
  'reboot',
  'halt',
  'poweroff',
  'init',
  'systemctl poweroff',
  'systemctl reboot',
  'systemctl halt',
  // Disk destruction.
  'mkfs.*',
  'fdisk',
  'parted',
  'dd if=',
  // Container escape.
  'docker run -v /:/',
  'docker run --privileged',
  // Namespace escape.
  'chroot',
  'unshare',
  'nsenter',
];

/// Commands that are elevated but consentable — prompt for user approval.
/// DISJOINT from [defaultDeny].
const List<String> defaultPrompt = [
  // Git remote state mutations.
  'git push',
  'git reset --hard',
  'git clean',
  // Package publishing.
  'npm publish',
  'pnpm publish',
  'yarn publish',
  'cargo publish',
  'twine upload',
  'gem push',
  // GitHub CLI mutations.
  'gh pr create',
  'gh pr merge',
  'gh pr close',
  'gh pr review',
  'gh release create',
  'gh release delete',
  'gh repo create',
  'gh repo fork',
  'gh repo delete',
  'gh secret set',
  'gh secret delete',
  'gh workflow run',
  // Container execution.
  'docker run',
  // Package installs.
  'npm install',
  'pip install',
  'cargo add',
  'bun add',
];

/// Commands that mutate the workspace — denied in read-only modes.
const List<String> mutatingCommands = [
  'git add',
  'git commit',
  'git push',
  'git reset',
  'git merge',
  'git rebase',
  'git clean',
  'git checkout --',
  // Package installs mutate the workspace.
  'npm install',
  'pip install',
  'cargo add',
  'bun add',
  // Infrastructure.
  'docker',
  'kubectl',
  'terraform',
];

/// Returns the command policy for a given conversation mode.
///
/// - **chat**: `deny=defaultDeny`, `prompt=defaultPrompt`.
/// - **plan/review/orchestrate**: `deny=defaultDeny ∪ defaultPrompt ∪
///   mutatingCommands`, `prompt=none` (read-only modes deny everything
///   mutating; only read/query commands pass).
CommandPolicy commandPolicyForMode(ConversationMode mode) {
  switch (mode) {
    case ConversationMode.chat:
      return const CommandPolicy(
        deny: defaultDeny,
        prompt: defaultPrompt,
      );
    case ConversationMode.review:
    case ConversationMode.plan:
    case ConversationMode.orchestrate:
      // Read-only modes: deny all mutating + dangerous commands.
      // Read/query commands (git log, git diff, npm ls, etc.) pass.
      return CommandPolicy(
        deny: <String>{
          ...defaultDeny,
          ...defaultPrompt,
          ...mutatingCommands,
        }.toList(),
      );
  }
}
