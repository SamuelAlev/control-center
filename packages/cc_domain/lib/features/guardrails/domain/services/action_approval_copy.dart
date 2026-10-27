import 'package:cc_domain/features/guardrails/domain/services/shell_action_classifier.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/shell_command_parser.dart';
import 'package:cc_harness/tools.dart' show ActionClass;

/// Operator-facing description of an attempted action. This is display copy,
/// not a policy input: classifying and deciding still happen at the caller.
class ActionApprovalCopy {
  /// Uses only declared effects and targets that are actually present. The
  /// shared command-policy parser exposes conventional shell invocations; an
  /// unrecognised or implicit target is never presented as a known branch.
  factory ActionApprovalCopy.describe({
    required Set<ActionClass> classes,
    ActionRequest request = ActionRequest.empty,
    String? command,
    String? rationale,
  }) {
    final script = command ?? request.command;
    final effects = {...classes, ...request.classes};
    if (script != null && script.isNotEmpty) {
      effects.addAll(const ShellActionClassifier().classify(script));
    }
    final commands = script == null
        ? const <List<String>>[]
        : [
            for (final part in parseShellCommand(script))
              normalizeCommandTokens(part),
          ];
    final refs = request.refs
        .where((ref) => _safeTarget(ref) && ref != 'HEAD' && !ref.contains('*'))
        .map(_branch)
        .toSet();
    final deletedRefs = <String>[];
    var forcePush = false;
    var unknownPush = false;
    if (effects.contains(ActionClass.gitPush)) {
      for (final tokens in commands) {
        if (!matchesTokenizedCommandRule(tokens, const ['git', 'push'])) {
          continue;
        }
        if (tokens.length < 4) {
          unknownPush = true;
          continue;
        }
        // Only the uncomplicated `git push <remote> <refspec>` shape names a
        // destination unambiguously. HEAD and omitted refs are not branches.
        final push = tokens.indexOf('push');
        final args = tokens.skip(push + 1).toList();
        final deleting = args.remove('--delete') || args.remove('-d');
        forcePush =
            forcePush ||
            args.contains('-f') ||
            args.contains('--force') ||
            args.contains('--force-with-lease');
        args.removeWhere(
          const {
            '-u',
            '--set-upstream',
            '-f',
            '--force',
            '--force-with-lease',
            '--atomic',
          }.contains,
        );
        var namedDestination = false;
        if (args.length == 2 &&
            !args.any((arg) => arg.startsWith('-') && arg != '-') &&
            args.last != 'HEAD') {
          final refspec = args.last;
          final ref = _branch(
            refspec.contains(':') ? refspec.split(':').last : refspec,
          );
          if (_safeTarget(ref) && ref != 'HEAD' && !ref.contains('*')) {
            if (deleting || refspec.startsWith(':')) {
              deletedRefs.add(ref);
            } else {
              refs.add(ref);
            }
            namedDestination = true;
          }
        }
        if (!namedDestination) {
          unknownPush = true;
        }
      }
      // The request's refs include deletions too; name those only as such.
      refs.removeAll(deletedRefs);
    }
    final packages = <String>[];
    if (effects.contains(ActionClass.packageInstall)) {
      for (final tokens in commands) {
        for (final prefix
            in ShellActionClassifier.rules[ActionClass.packageInstall]!) {
          final words = prefix.split(' ');
          if (!matchesTokenizedCommandRule(tokens, words) ||
              tokens.length <= words.length) {
            continue;
          }
          final names = tokens.skip(words.length).toList();
          if (names.every(
            (name) =>
                _safeTarget(name) &&
                !name.startsWith('-') &&
                !name.contains(RegExp(r'[*?\[\]{}]')),
          )) {
            packages.addAll(names);
          }
          break;
        }
      }
    }
    final paths = request.paths.where(_safeTarget).toList();
    if (paths.isEmpty && effects.contains(ActionClass.fileDelete)) {
      for (final tokens in commands) {
        if (tokens.isEmpty ||
            !const {'rm', 'rmdir', 'unlink'}.contains(tokens.first)) {
          continue;
        }
        // Shell word expansion, substitutions and options can change the
        // target; list only literal positional arguments in simple invocations.
        var operands = false;
        for (final token in tokens.skip(1)) {
          if (token == '--') {
            operands = true;
          } else if (operands || !token.startsWith('-')) {
            if (_safeTarget(token) && !token.contains(RegExp(r'[*?\[\]{}]'))) {
              paths.add(token);
            }
          }
        }
      }
    }
    final hosts = request.hosts.where(_safeTarget).toList();
    // The title counts several branches; the detail always lists their names.
    String push({required bool brief}) => [
      if (refs.isNotEmpty)
        '${forcePush ? 'force-push' : 'push'} to ${brief && refs.length > 1 ? '${refs.length} branches' : refs.join(', ')}',
      if (deletedRefs.isNotEmpty)
        brief && deletedRefs.length > 1
            ? 'delete ${deletedRefs.length} remote branches'
            : 'delete remote branch ${deletedRefs.join(', ')}',
      if (unknownPush || (refs.isEmpty && deletedRefs.isEmpty))
        'possibly push to a Git remote (destination branch not specified)',
    ].join(' and ');
    final ordered = ActionClass.values.where(effects.contains).toList();
    final all = [
      for (final effect in ordered)
        switch (effect) {
          ActionClass.gitPush => push(brief: false),
          ActionClass.fileDelete =>
            paths.isEmpty
                ? script != null
                      ? 'run a command that may delete files or directories'
                      : 'delete files or directories'
                : script != null
                ? 'run a command that may delete ${paths.join(', ')}'
                : 'delete ${paths.join(', ')}',
          ActionClass.packageInstall =>
            packages.isEmpty
                ? script != null
                      ? 'run a command that may install packages'
                      : 'install packages'
                : 'run a command that may install ${packages.join(', ')}',
          ActionClass.prCreate => 'create a pull request',
          ActionClass.prPublish => 'publish or change a pull request',
          ActionClass.vendorSyncWrite => 'change data in an external service',
          ActionClass.gitCommit => 'change Git history',
          ActionClass.networkEgress =>
            hosts.isEmpty
                ? 'connect to an external network'
                : 'connect to ${hosts.join(', ')}',
          ActionClass.fileWriteOutsideWorktree =>
            paths.isEmpty
                ? 'write files outside the worktree'
                : 'write files outside the worktree at ${paths.join(', ')}',
          ActionClass.secretAccess => 'access secrets or credentials',
          ActionClass.workspaceMutation =>
            'change workspace settings or structure',
          ActionClass.enclosureControl => 'control an enclosed environment',
          ActionClass.processSpawn => 'run a process',
        },
    ];
    // A process is a means, not the requested outcome, unless it is the only
    // classified effect. Still disclose it in the full list of effects.
    final primary = ordered
        .where((effect) => effect != ActionClass.processSpawn)
        .firstOrNull;
    final preferred =
        primary == ActionClass.fileDelete &&
            paths.isEmpty &&
            refs.isNotEmpty &&
            effects.contains(ActionClass.gitPush)
        ? ActionClass.gitPush
        : primary;
    final intent = preferred == ActionClass.gitPush
        ? push(brief: true)
        : preferred != null
        ? all[ordered.indexOf(preferred)]
        : script != null
        ? 'run a shell command'
        : effects.contains(ActionClass.processSpawn)
        ? 'run a process'
        : 'perform this action';
    final purpose = rationale?.trim();
    final safePurpose =
        purpose != null &&
        purpose.length <= 160 &&
        purpose.split(RegExp(r'\s+')).length >= 5 &&
        !RegExp(r'[\r\n`$;&|<>\\]').hasMatch(purpose) &&
        !RegExp(
          r'\b(?:git|rm|npm|python|curl|bash|pip|sh|gh|wget|pnpm|yarn|bun)\s+\S+',
          caseSensitive: false,
        ).hasMatch(purpose) &&
        (script == null || !script.contains(purpose));
    final detail = all.isEmpty
        ? 'Approving lets the agent proceed with this action.'
        : 'Approving lets the agent ${all.join('; ')}. '
              'Declining blocks this attempt.';
    return ActionApprovalCopy._(
      'Agent would like to $intent. Do you accept?',
      '$detail${safePurpose ? ' Agent’s stated purpose: $purpose.' : ''}',
    );
  }

  const ActionApprovalCopy._(this.title, this.detail);

  final String title;
  final String detail;

  static bool _safeTarget(String value) =>
      value.isNotEmpty &&
      value.length <= 160 &&
      !RegExp(r'[\r\n\t`$;&|<>\\]').hasMatch(value);

  static String _branch(String ref) {
    if (ref.startsWith('refs/heads/')) {
      return ref.substring('refs/heads/'.length);
    }
    return ref;
  }
}
