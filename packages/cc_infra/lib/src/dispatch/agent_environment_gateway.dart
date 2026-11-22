import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_harness/tools.dart' show ActionClass, PersonWaitListener;
import 'package:cc_infra/src/environments/environment_host_approval.dart';
import 'package:cc_infra/src/harness/script_approval_check.dart'
    show checkWithinScriptApprovals;
import 'package:meta/meta.dart';

/// Who is asking, taken from the run's lease and never from the request.
class AgentEnvironmentCaller {
  /// Creates an [AgentEnvironmentCaller].
  const AgentEnvironmentCaller({
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.runId,
    required this.scriptApprovals,
    this.agentId,
    this.mode,
    this.actingUserId,
    this.autonomy,
    this.onPersonWait,
    this.onDecided,
  });

  /// Workspace of the run.
  final String workspaceId;

  /// Space of the run. Environment commands have no other way to name one.
  final String spaceId;

  /// Conversation of the run.
  final String conversationId;

  /// The run's `agent_run_logs` row: what its guard rows name.
  final String? runId;

  /// The agent.
  final String? agentId;

  /// The run's mode.
  final Mode? mode;

  /// The member it acts for.
  final String? actingUserId;

  /// The run's space autonomy dial when the command was asked, or null.
  final AutonomyLevel? autonomy;

  /// The calling tool's person-wait listener, when the command came from a
  /// tool call still registered on its run: told while an approval card
  /// waits on a person, so that call's clocks stop for the wait. It only
  /// reaches the guard's `onPersonWait`; it never changes a decision. Null
  /// when the command named no call, or one the run does not know.
  final PersonWaitListener? onPersonWait;

  /// Hears what was decided about this command's request when it was denied
  /// or a person approved it (`checkWithinScriptApprovals`'s `onDecided`),
  /// so the tool call that ran the command is recorded with the decision. It
  /// never changes one. Null when the request names no registered command.
  final void Function(bool approved)? onDecided;

  /// The approval budgets of the run's code mode scripts in flight when the
  /// command was asked: a card this command raises counts against each, and
  /// none is raised once one of them refuses. Empty when no script runs.
  final List<ScriptApprovalBudget> scriptApprovals;

  /// The principal changes are attributed to.
  Principal get principal => AgentPrincipal(agentId ?? runId ?? conversationId);
}

/// What a shim prints and exits with.
class AgentEnvironmentResult {
  /// Creates an [AgentEnvironmentResult].
  const AgentEnvironmentResult({
    required this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  /// The refusal every unsupported command gets.
  const AgentEnvironmentResult.unavailable(String command)
    : exitCode = 5,
      stdout = '',
      stderr = '$command is not available in Control Center agent runs';

  /// Exit code.
  final int exitCode;

  /// Standard output.
  final String stdout;

  /// Standard error.
  final String stderr;
}

/// Runs a real binary on the host: argv, no shell.
typedef AgentHostCommandRunner =
    Future<AgentEnvironmentResult> Function(
      String binary,
      List<String> arguments, {
      required String workingDirectory,
      Map<String, String> environment,
    });

/// What the gateway needs to know about a space.
abstract interface class AgentEnvironmentContext {
  /// The definition the space's environment uses, or the one it could start.
  ///
  /// A pass-through tool is that definition's, run on the host, so this
  /// throws `EnvironmentHostUnapprovedException` when the definition runs on
  /// the host and the current server owner has not approved it.
  Future<EnvironmentDefinition?> definitionFor(
    String workspaceId,
    String spaceId,
  );

  /// The compose project the `docker` shim may reach: that of the space's
  /// current environment, when it runs compose on this host. Null when there
  /// is none, or it runs in a rig. Throws `EnvironmentHostUnapprovedException`
  /// when the current server owner has not approved its definition.
  Future<AgentComposeProject?> hostComposeProject(
    String workspaceId,
    String spaceId,
  );

  /// The name a tool knows this space's environment by.
  Future<String?> nameFor(String workspaceId, String spaceId);

  /// Worktrees of the space. Pass-through paths must resolve inside these.
  Future<List<String>> worktreeRoots(String workspaceId, String spaceId);

  /// Where host commands run.
  Future<String?> workingDirectory(String workspaceId, String spaceId);

  /// Whether [path] canonicalizes to somewhere inside [roots].
  Future<bool> isInside(String path, List<String> roots);
}

/// The compose project the `docker` shim runs against.
class AgentComposeProject {
  /// Creates an [AgentComposeProject].
  const AgentComposeProject({required this.name, required this.directory});

  /// The project name, passed as `-p`.
  final String name;

  /// Where the shim runs: the environment's state directory, which the
  /// server writes and no agent can. Never a worktree, so no `compose.yaml`,
  /// override file or `.env` (which can set `COMPOSE_FILE`) an agent wrote
  /// is in the directory compose looks in.
  final String directory;
}

/// Sub-commands of `docker compose` an agent may use.
const Set<String> kAgentComposeCommands = {
  'ps',
  'logs',
  'exec',
  'port',
  'restart',
  'top',
};

/// The options each sub-command accepts here, and whether each takes a value.
///
/// An allowlist, because a new Docker flag must not widen what an agent can do
/// by default, and because compose's own options (`-f`, `-p`,
/// `--project-directory`, `--env-file`, `--profile`) would retarget the
/// command or read a host file wherever on the line they appear.
const Map<String, Map<String, bool>> kAgentComposeOptions = {
  'ps': {
    '-a': false,
    '--all': false,
    '-q': false,
    '--quiet': false,
    '--services': false,
    '--no-trunc': false,
    '--format': true,
    '--status': true,
  },
  'logs': {
    '-n': true,
    '--tail': true,
    '-t': false,
    '--timestamps': false,
    '--no-color': false,
    '--no-log-prefix': false,
    '--since': true,
    '--until': true,
  },
  'exec': _composeNoTtyFlags,
  'port': {'--protocol': true, '--index': true},
  'restart': {'-t': true, '--timeout': true, '--no-deps': false},
  'top': {},
};

/// The only flags `docker compose exec` accepts here, all of them "no TTY".
const Map<String, bool> _composeNoTtyFlags = {
  '-T': false,
  '--no-tty': false,
  '--no-TTY': false,
};

/// The action classes each environment operation carries.
///
/// Reads carry none: they inherit the tier default. This mirrors the RPC pack,
/// so an operation means the same thing whichever door it came through.
const Map<String, Set<ActionClass>> kEnvironmentOpClasses = {
  'status': {},
  'logs': {},
  'up': _stackClasses,
  'down': _stackClasses,
  'reset': _stackClasses,
  'destroy': _stackClasses,
  'restart': _stackClasses,
  'exec': {ActionClass.hostExecution, ActionClass.processSpawn},
  'run': {
    ActionClass.hostExecution,
    ActionClass.processSpawn,
    ActionClass.networkEgress,
  },
};

/// What every pass-through command carries, whatever it maps to. A rule's `maps`
/// says what the command means to the tool, not what running it does: the
/// binary starts in the agent's worktree, where `pnpm` loading `.pnpmfile.cjs`
/// is code execution even for a status read.
const Set<ActionClass> kPassthroughClasses = {
  ActionClass.hostExecution,
  ActionClass.processSpawn,
};

/// Everything that runs something carries `hostExecution`, which prompts by
/// default: the code that runs is the worktree's, which the agent can edit, so
/// without it `cc-env run test` would be a way out of the sandbox.
const Set<ActionClass> _stackClasses = {
  ActionClass.hostExecution,
  ActionClass.processSpawn,
  ActionClass.enclosureControl,
};

/// Serves `cc-env`, the `docker` shim and declared pass-through tools.
///
/// The sandbox denies the Docker socket and cloud credentials, so these run on
/// the host, after the same action policy every other agent effect goes
/// through. The space comes from the run's lease, so a run can only ever act
/// on its own environment.
class AgentEnvironmentGateway {
  /// Creates an [AgentEnvironmentGateway].
  AgentEnvironmentGateway({
    required this._environments,
    required this._context,
    required this._guard,
    required this._runHost,
  });

  final EnvironmentPort _environments;
  final AgentEnvironmentContext _context;
  final ActionGuardService _guard;
  final AgentHostCommandRunner _runHost;

  /// Handles one shim invocation.
  Future<AgentEnvironmentResult> handle(
    AgentEnvironmentCaller caller,
    String tool,
    List<String> arguments,
  ) async {
    try {
      if (tool == 'cc-env') {
        return await _ccEnv(caller, arguments);
      }
      if (tool == 'docker') {
        return await _docker(caller, arguments);
      }
      return await _passthrough(caller, tool, arguments);
    } on EnvironmentHostUnapprovedException catch (e) {
      return AgentEnvironmentResult(exitCode: 5, stderr: e.message);
    } on Exception catch (e) {
      return AgentEnvironmentResult(exitCode: 1, stderr: '$e');
    }
  }

  Future<AgentEnvironmentResult?> _authorize(
    AgentEnvironmentCaller caller,
    String op,
    String summary, {
    Set<ActionClass> also = const {},
  }) async {
    final classes = {...?kEnvironmentOpClasses[op], ...also};
    if (classes.isEmpty) {
      return null;
    }
    // The summary is the command line the agent ran: command rules see it,
    // the card shows it, and "Approve for 8 hours" covers exactly it. As
    // what runs (`executed`), the audit row digests all of it, cut or not.
    final request = ActionRequest(classes: classes, command: summary);
    final verdict = await checkWithinScriptApprovals(
      guard: _guard,
      approvals: caller.scriptApprovals,
      workspaceId: caller.workspaceId,
      classes: classes,
      request: request,
      actionSummary: summary,
      executed: summary,
      spaceId: caller.spaceId,
      agentId: caller.agentId,
      mode: caller.mode ?? Mode.chat,
      autonomy: caller.autonomy,
      onBehalfOfUserId: caller.actingUserId,
      runId: caller.runId,
      onPersonWait: caller.onPersonWait,
      onDecided: caller.onDecided,
      check: (onPersonWait, beforeCard) => _guard.check(
        workspaceId: caller.workspaceId,
        classes: classes,
        spaceId: caller.spaceId,
        conversationId: caller.conversationId,
        agentId: caller.agentId,
        mode: caller.mode ?? Mode.chat,
        actionSummary: summary,
        onBehalfOfUserId: caller.actingUserId,
        runId: caller.runId,
        request: request,
        autonomy: caller.autonomy,
        onPersonWait: onPersonWait,
        beforeCard: beforeCard,
        executed: summary,
      ),
    );
    if (verdict.allowed) {
      return null;
    }
    return AgentEnvironmentResult(
      exitCode: 1,
      stderr: 'Control Center policy: ${verdict.reason ?? 'denied'}',
    );
  }

  Future<AgentEnvironmentResult> _ccEnv(
    AgentEnvironmentCaller caller,
    List<String> arguments,
  ) async {
    if (arguments.isEmpty) {
      return const AgentEnvironmentResult(
        exitCode: 2,
        stderr:
            'usage: cc-env status|up|down|destroy|restart <process>|'
            'logs <name>|exec <service> -- <cmd>|run <task> -- <args>',
      );
    }
    final ws = caller.workspaceId;
    final space = caller.spaceId;
    final by = caller.principal;
    final verb = arguments.first;
    final rest = arguments.sublist(1);
    final op = switch (verb) {
      'status' || 'up' || 'down' || 'destroy' || 'reset' => verb,
      'restart' || 'logs' || 'exec' || 'run' => verb,
      _ => null,
    };
    if (op == null) {
      return AgentEnvironmentResult.unavailable('cc-env $verb');
    }
    final refused = await _authorize(
      caller,
      op,
      'cc-env ${arguments.join(' ')}',
    );
    if (refused != null) {
      return refused;
    }
    Future<AgentEnvironmentResult> report() async {
      final environments = await _environments.environmentsFor(ws, space);
      return AgentEnvironmentResult(
        exitCode: 0,
        stdout: jsonEncode([for (final e in environments) e.toJson()]),
      );
    }

    switch (verb) {
      case 'status':
        return report();
      case 'up':
        await _environments.ensure(workspaceId: ws, spaceId: space, by: by);
        return report();
      case 'down':
        await _environments.stop(ws, space, by: by);
        return report();
      case 'reset':
        await _environments.reset(ws, space, by: by);
        return report();
      case 'destroy':
        await _environments.destroy(ws, space, by: by);
        return const AgentEnvironmentResult(exitCode: 0);
      case 'restart':
        if (rest.isEmpty) {
          return const AgentEnvironmentResult(
            exitCode: 2,
            stderr: 'usage: cc-env restart <process>',
          );
        }
        await _environments.restart(ws, space, rest.first, by: by);
        return const AgentEnvironmentResult(exitCode: 0);
      case 'logs':
        if (rest.isEmpty) {
          return const AgentEnvironmentResult(
            exitCode: 2,
            stderr: 'usage: cc-env logs <name>',
          );
        }
        return AgentEnvironmentResult(
          exitCode: 0,
          stdout: await _environments.logs(ws, space, target: rest.first),
        );
      case 'exec':
        final split = splitAtDoubleDash(rest);
        if (split.before.length != 1 || split.after.isEmpty) {
          return const AgentEnvironmentResult(
            exitCode: 2,
            stderr: 'usage: cc-env exec <service> -- <cmd>',
          );
        }
        final result = await _environments.exec(
          ws,
          space,
          service: split.before.single,
          command: split.after,
          by: by,
        );
        return AgentEnvironmentResult(
          exitCode: result.exitCode,
          stdout: result.stdout,
          stderr: result.stderr,
        );
      case 'run':
        final split = splitAtDoubleDash(rest);
        if (split.before.length != 1) {
          return const AgentEnvironmentResult(
            exitCode: 2,
            stderr: 'usage: cc-env run <task> -- <args>',
          );
        }
        final run = await _environments.runTask(
          ws,
          space,
          split.before.single,
          arguments: split.after,
          by: by,
        );
        return AgentEnvironmentResult(
          exitCode: run.exitCode ?? 1,
          stdout: run.output,
          stderr: run.error ?? '',
        );
    }
    return AgentEnvironmentResult.unavailable('cc-env $verb');
  }

  Future<AgentEnvironmentResult> _docker(
    AgentEnvironmentCaller caller,
    List<String> arguments,
  ) async {
    final refusal = validateComposeShim(arguments);
    if (refusal != null) {
      return refusal;
    }
    final project = await _context.hostComposeProject(
      caller.workspaceId,
      caller.spaceId,
    );
    if (project == null) {
      return const AgentEnvironmentResult(
        exitCode: 5,
        stderr:
            'This space has no compose environment on this host. '
            'Use cc-env exec to reach one in a rig',
      );
    }
    final sub = arguments[1];
    final op = switch (sub) {
      'exec' => 'exec',
      'restart' => 'restart',
      _ => 'status',
    };
    final refused = await _authorize(
      caller,
      op,
      'docker ${arguments.join(' ')}',
    );
    if (refused != null) {
      return refused;
    }
    // By project name alone, from the state directory. This runs on the host
    // with the operator's SSH agent, and the worktree's compose file is the
    // agent's to edit: naming it would let `include: git@…` fetch from
    // anywhere, outside sandbox egress. The variables are these two over the
    // operator's own host environment; nothing here comes from the run.
    return _runHost(
      'docker',
      composeShimArguments(arguments, project: project.name),
      workingDirectory: project.directory,
      environment: const {
        'COMPOSE_EXPERIMENTAL_GIT_REMOTE': '0',
        'COMPOSE_EXPERIMENTAL_OCI_REMOTE': '0',
      },
    );
  }

  Future<AgentEnvironmentResult> _passthrough(
    AgentEnvironmentCaller caller,
    String tool,
    List<String> arguments,
  ) async {
    final definition = await _context.definitionFor(
      caller.workspaceId,
      caller.spaceId,
    );
    final passthrough = definition?.components
        .whereType<CliEnvironmentComponent>()
        .map((component) => component.agentPassthrough)
        .firstWhere((p) => p?.binary == tool, orElse: () => null);
    if (passthrough == null) {
      return AgentEnvironmentResult.unavailable(tool);
    }
    final rule = passthrough.ruleFor(arguments);
    if (rule == null) {
      return AgentEnvironmentResult.unavailable('$tool ${arguments.join(' ')}');
    }
    for (final argument in arguments) {
      final option = readOption(argument);
      if (option != null &&
          (rule.denyFlags.contains(option.name) ||
              option.shorts.any(rule.denyFlags.contains))) {
        return AgentEnvironmentResult(
          exitCode: 5,
          stderr: '$argument is not available in Control Center agent runs',
        );
      }
    }
    final name = await _context.nameFor(caller.workspaceId, caller.spaceId);
    final forced = forcePositionalName(arguments, rule, name);
    if (forced == null) {
      return const AgentEnvironmentResult(
        exitCode: 5,
        stderr: 'This space has no environment name yet',
      );
    }
    final roots = await _context.worktreeRoots(
      caller.workspaceId,
      caller.spaceId,
    );
    for (final value in pathFlagValues(forced, rule.pathFlags)) {
      if (!await _context.isInside(value, roots)) {
        return AgentEnvironmentResult(
          exitCode: 5,
          stderr: '$value is outside this run\'s worktrees',
        );
      }
    }
    final refused = await _authorize(
      caller,
      _opFor(rule.maps),
      '$tool ${forced.join(' ')}',
      also: kPassthroughClasses,
    );
    if (refused != null) {
      return refused;
    }
    final directory = await _context.workingDirectory(
      caller.workspaceId,
      caller.spaceId,
    );
    if (directory == null) {
      return const AgentEnvironmentResult(
        exitCode: 5,
        stderr: 'This space has no worktree',
      );
    }
    final result = await _runHost(
      tool,
      forced,
      workingDirectory: directory,
      environment: await _environments.terminalEnvironment(
        caller.workspaceId,
        caller.spaceId,
      ),
    );
    if (rule.nameFilter && name != null) {
      return AgentEnvironmentResult(
        exitCode: result.exitCode,
        stdout: filterJsonToName(result.stdout, name),
        stderr: result.stderr,
      );
    }
    return result;
  }

  /// An unknown mapping counts as the most dangerous op, never as a read: a
  /// typo in a definition must not become a free pass.
  static String _opFor(String maps) =>
      kEnvironmentOpClasses.containsKey(maps) ? maps : 'run';
}

/// Splits [arguments] at the first `--`.
@visibleForTesting
({List<String> before, List<String> after}) splitAtDoubleDash(
  List<String> arguments,
) {
  final index = arguments.indexOf('--');
  if (index < 0) {
    return (before: arguments, after: const []);
  }
  return (
    before: arguments.sublist(0, index),
    after: arguments.sublist(index + 1),
  );
}

/// Why a `docker` invocation is refused, or null when it may run.
///
/// Only `docker compose <allowed>` passes, with nothing between `compose` and
/// the sub-command, and after it only that sub-command's
/// [kAgentComposeOptions]: `-f`, `-p`, `--project-directory` or `--env-file`
/// anywhere would point the command at a stack that isn't this space's, or
/// read a host file. Everything else is a service name, a port, or (after
/// `exec`'s service) the command run inside that service's container.
@visibleForTesting
AgentEnvironmentResult? validateComposeShim(List<String> arguments) {
  if (arguments.length < 2 ||
      arguments.first != 'compose' ||
      !kAgentComposeCommands.contains(arguments[1])) {
    return AgentEnvironmentResult.unavailable('docker ${arguments.join(' ')}');
  }
  final sub = arguments[1];
  final options = kAgentComposeOptions[sub] ?? const {};
  final rest = arguments.sublist(2);
  for (var index = 0; index < rest.length; index++) {
    final argument = rest[index];
    final option = readOption(argument);
    if (option == null) {
      if (sub == 'exec' || argument == '--') {
        // The service, then its container's command; or only operands.
        break;
      }
      continue;
    }
    // A bundle or an attached value is never on the list: each option is
    // spelled out on its own.
    final takesValue = option.shorts.isEmpty ? options[option.name] : null;
    if (takesValue == null || (!takesValue && option.value != null)) {
      return AgentEnvironmentResult(
        exitCode: 5,
        stderr: '$argument is not available in Control Center agent runs',
      );
    }
    if (takesValue && option.value == null) {
      index++;
    }
  }
  return null;
}

/// How [argument] reads as an option, or null when it is an operand (`-`,
/// `--` or anything not starting with `-`).
///
/// `name` is everything before an `=`. A single-dash name longer than one
/// letter is also every short option it could be read as (`shorts`): a
/// bundle (`-abc` is `-a`, `-b`, `-c`) or a short option with its value
/// attached (`-Xvalue` starts with `-X`). Which it is depends on the tool, so
/// a refusal checks both and an allowlist accepts neither.
@visibleForTesting
({String name, String? value, List<String> shorts})? readOption(
  String argument,
) {
  if (argument == '-' || argument == '--' || !argument.startsWith('-')) {
    return null;
  }
  final equals = argument.indexOf('=');
  final name = equals > 0 ? argument.substring(0, equals) : argument;
  final value = equals > 0 ? argument.substring(equals + 1) : null;
  final single = !name.startsWith('--') && name.length > 2;
  return (
    name: name,
    value: value,
    shorts: single
        ? [for (final letter in name.substring(1).split('')) '-$letter']
        : const [],
  );
}

/// The argv the shim really runs: pinned to [project], and `exec` never gets a
/// TTY. Only the options before `exec`'s service count: a `-T` in the
/// container's command is that command's.
@visibleForTesting
List<String> composeShimArguments(
  List<String> arguments, {
  required String project,
}) {
  final rest = arguments.sublist(2);
  final options = rest.takeWhile((a) => a.startsWith('-') && a != '--');
  return [
    'compose',
    '-p',
    project,
    arguments[1],
    if (arguments[1] == 'exec' && !options.any(_composeNoTtyFlags.containsKey))
      '-T',
    ...rest,
  ];
}

/// [arguments] with the environment's name forced into position, or null when
/// the rule needs a name and none exists.
@visibleForTesting
List<String>? forcePositionalName(
  List<String> arguments,
  EnvironmentPassthroughRule rule,
  String? name,
) {
  final position = rule.positionalName;
  if (position == null) {
    return arguments;
  }
  if (name == null) {
    return null;
  }
  final forced = List<String>.of(arguments);
  if (forced.length > position && !forced[position].startsWith('-')) {
    forced[position] = name;
  } else {
    forced.insert(position, name);
  }
  return forced;
}

/// Values of [flags], in `--flag value` and `--flag=value` form.
@visibleForTesting
List<String> pathFlagValues(List<String> arguments, List<String> flags) {
  final values = <String>[];
  for (final (index, argument) in arguments.indexed) {
    final equals = argument.indexOf('=');
    if (equals > 0 && flags.contains(argument.substring(0, equals))) {
      values.add(argument.substring(equals + 1));
    } else if (flags.contains(argument) && index + 1 < arguments.length) {
      values.add(arguments[index + 1]);
    }
  }
  return values;
}

/// Keeps only the entries of a JSON array that belong to [name].
@visibleForTesting
String filterJsonToName(String stdout, String name) {
  final Object? json;
  try {
    json = jsonDecode(stdout);
  } on FormatException {
    return stdout;
  }
  if (json is! List) {
    return stdout;
  }
  return jsonEncode([
    for (final item in json)
      if (item is Map && item.values.contains(name)) item,
  ]);
}

/// The shim every name resolves to. It reads its own name, so one script
/// serves `cc-env`, `docker` and each declared tool, and hands the call to
/// the agent run client ([clientCommand], its command already quoted for
/// `sh`), which posts it to the gateway.
String agentShimScript({required String clientCommand}) =>
    '''
#!/bin/sh
exec $clientCommand env "\$(basename "\$0")" "\$@"
''';
