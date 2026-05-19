import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart' show ActionClass;

/// Derives an [ActionRequest] from a tool call's arguments.
///
/// Every chokepoint already holds the arguments and threw them away before
/// consulting policy, which is why a rule could only ever be about the VERB.
/// This reads the conventional argument names the tool surface actually uses
/// — one place, so a new tool inherits argument-level policy without
/// declaring anything.
///
/// It is deliberately conservative: a key it does not recognise contributes
/// nothing, and a request that carries no recognised argument stays
/// [ActionRequest.empty] — which a constrained rule does NOT match, so the
/// unconstrained rule (the pre-existing behavior) decides. An extractor that
/// guessed would be worse than one that abstains: a wrong path would make a
/// narrow "allow" cover a call it was never meant to.
class ActionRequestExtractor {
  /// Creates an [ActionRequestExtractor].
  const ActionRequestExtractor();

  /// Argument keys that name a filesystem path.
  static const pathKeys = <String>{
    'path',
    'file_path',
    'filePath',
    'paths',
    'file',
    'files',
    'file_paths',
    'target_path',
    'destination',
    'directory',
    'dir',
    'cwd',
  };

  /// Argument keys that name a git ref / branch.
  ///
  /// `push_branch` is here because `worktree.commitAndPush` names its ref
  /// that way — and a protected-branch rule that cannot see the branch is a
  /// rule that protects nothing. The resolver escalates rather than guessing
  /// when a ref is genuinely absent, so a missing key here costs a prompt,
  /// not a hole; it is still worth closing every one we know about.
  static const refKeys = <String>{
    'ref',
    'refs',
    'branch',
    'branches',
    'push_branch',
    'pushBranch',
    'branch_override',
    'base',
    'base_branch',
    'head',
    'head_branch',
    'target_branch',
    'target_ref',
  };

  /// Argument keys that name a network host or URL.
  static const hostKeys = <String>{'url', 'host', 'hosts', 'urls', 'endpoint'};

  /// Argument keys carrying a shell command.
  static const commandKeys = <String>{'command', 'cmd', 'script'};

  /// Argument keys carrying a countable magnitude.
  static const countKeys = <String>{'count', 'limit', 'max_files'};

  /// Extracts what policy can constrain from [args].
  ActionRequest extract(
    Map<String, dynamic> args, {
    Set<ActionClass> classes = const {},
  }) {
    final paths = <String>[];
    final refs = <String>[];
    final hosts = <String>[];
    String? command;
    int? magnitude;

    for (final entry in args.entries) {
      final key = entry.key;
      final value = entry.value;
      if (pathKeys.contains(key)) {
        paths.addAll(_strings(value));
      } else if (refKeys.contains(key)) {
        refs.addAll(_strings(value));
      } else if (hostKeys.contains(key)) {
        hosts.addAll(_strings(value).map(_hostOf).whereType<String>());
      } else if (commandKeys.contains(key)) {
        command ??= value is String && value.isNotEmpty ? value : null;
      } else if (countKeys.contains(key) && value is num) {
        magnitude ??= value.toInt();
      }
    }

    return ActionRequest(
      classes: classes,
      command: command,
      paths: paths,
      refs: refs,
      hosts: hosts,
      magnitude: magnitude,
    );
  }

  static List<String> _strings(Object? value) {
    if (value is String) {
      return value.isEmpty ? const [] : [value];
    }
    if (value is List) {
      return [
        for (final e in value)
          if (e is String && e.isNotEmpty) e,
      ];
    }
    return const [];
  }

  /// The host of a URL, or the value itself when it is already a bare host.
  /// An unparseable value contributes nothing rather than a guess.
  static String? _hostOf(String value) {
    if (!value.contains('://')) {
      return value.contains('/') ? null : value;
    }
    final uri = Uri.tryParse(value);
    final host = uri?.host;
    return host == null || host.isEmpty ? null : host;
  }
}
