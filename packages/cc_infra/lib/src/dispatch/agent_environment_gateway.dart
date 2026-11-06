import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:meta/meta.dart';

/// Who is asking, taken from the run's lease and never from the request.
class AgentEnvironmentCaller {
  /// Creates an [AgentEnvironmentCaller].
  const AgentEnvironmentCaller({
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.runId,
    this.agentId,
    this.mode,
    this.actingUserId,
  });

  /// Workspace of the run.
  final String workspaceId;

  /// Space of the run. Environment commands have no other way to name one.
  final String spaceId;

  /// Conversation of the run.
  final String conversationId;

  /// The run.
  final String? runId;

  /// The agent.
  final String? agentId;

  /// The run's mode.
  final Mode? mode;

  /// The member it acts for.
  final String? actingUserId;

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
  Future<EnvironmentDefinition?> definitionFor(
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

/// Sub-commands of `docker compose` an agent may use.
const Set<String> kAgentComposeCommands = {
  'ps',
  'logs',
  'exec',
  'port',
  'restart',
  'top',
};

/// The only flags `docker compose exec` accepts here. An allowlist, because
/// a new Docker flag must not widen what an agent can do by default.
const Set<String> _allowedComposeExecFlags = {'-T', '--no-tty', '--no-TTY'};

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
    final verdict = await _guard.check(
      workspaceId: caller.workspaceId,
      classes: classes,
      spaceId: caller.spaceId,
      conversationId: caller.conversationId,
      agentId: caller.agentId,
      mode: caller.mode ?? Mode.chat,
      actionSummary: summary,
      onBehalfOfUserId: caller.actingUserId,
      runId: caller.runId,
      request: ActionRequest(classes: classes),
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
    final variables = await _environments.terminalEnvironment(
      caller.workspaceId,
      caller.spaceId,
    );
    final project = variables['COMPOSE_PROJECT_NAME'];
    final directory = await _context.workingDirectory(
      caller.workspaceId,
      caller.spaceId,
    );
    if (project == null || directory == null) {
      return const AgentEnvironmentResult(
        exitCode: 5,
        stderr: 'This space has no running compose environment',
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
    // By project name alone. This runs on the host with the operator's SSH
    // agent, and the worktree's compose file is the agent's to edit: naming it
    // would let `include: git@…` fetch from anywhere, outside sandbox egress.
    return _runHost(
      'docker',
      composeShimArguments(arguments, project: project),
      workingDirectory: directory,
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
      if (rule.denyFlags.contains(argument.split('=').first)) {
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
/// the sub-command: `-f`, `-p` or `--project-directory` there would point the
/// command at a stack that isn't this space's.
@visibleForTesting
AgentEnvironmentResult? validateComposeShim(List<String> arguments) {
  if (arguments.length < 2 ||
      arguments.first != 'compose' ||
      !kAgentComposeCommands.contains(arguments[1])) {
    return AgentEnvironmentResult.unavailable('docker ${arguments.join(' ')}');
  }
  final sub = arguments[1];
  final rest = arguments.sublist(2);
  if (sub == 'logs' && rest.any((a) => a == '-f' || a == '--follow')) {
    return const AgentEnvironmentResult(
      exitCode: 5,
      stderr: '--follow is not available in Control Center agent runs',
    );
  }
  if (sub == 'exec') {
    for (final argument in rest) {
      if (argument == '--') {
        break;
      }
      if (!argument.startsWith('-')) {
        break;
      }
      if (!_allowedComposeExecFlags.contains(argument)) {
        return AgentEnvironmentResult(
          exitCode: 5,
          stderr: '$argument is not available in Control Center agent runs',
        );
      }
    }
  }
  return null;
}

/// The argv the shim really runs: pinned to [project], and `exec` never gets a
/// TTY.
@visibleForTesting
List<String> composeShimArguments(
  List<String> arguments, {
  required String project,
}) => [
  'compose',
  '-p',
  project,
  arguments[1],
  if (arguments[1] == 'exec' && !arguments.contains('-T')) '-T',
  ...arguments.sublist(2),
];

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
/// serves `cc-env`, `docker` and each declared tool.
String agentShimScript({
  required String tokenHeader,
  required String tokenEnvKey,
  required String gatewayEnvKey,
}) =>
    '''
#!/bin/bash
tool=\$(basename "\$0")
out=\$(mktemp) || exit 1
head=\$(mktemp) || exit 1
trap 'rm -f "\$out" "\$head"' EXIT
if ! { [ \$# -eq 0 ] || printf '%s\\0' "\$@"; } | curl --disable --silent --show-error --noproxy '*' \\
  --connect-timeout 5 --max-time 3600 \\
  --header "$tokenHeader: \$$tokenEnvKey" \\
  --header "X-CC-Env-Tool: \$tool" \\
  --header 'Content-Type: application/octet-stream' \\
  --data-binary @- --dump-header "\$head" --output "\$out" \\
  "\$$gatewayEnvKey/agent/env"; then
  printf '%s\\n' 'Control Center gateway is unavailable.' >&2
  exit 5
fi
cat "\$out"
err=\$(sed -n 's/^[Xx]-[Cc][Cc]-[Ss]tderr: *//p' "\$head" | tr -d '\\r')
[ -n "\$err" ] && printf '%s' "\$err" | base64 -d >&2
code=\$(sed -n 's/^[Xx]-[Cc][Cc]-[Ee]xit-[Cc]ode: *//p' "\$head" | tr -d '\\r')
exit "\${code:-1}"
''';
