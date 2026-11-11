import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_infra/src/environments/environment_host_approval.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _caller = AgentEnvironmentCaller(
  workspaceId: 'ws-1',
  spaceId: 'space-1',
  conversationId: 'conversation-1',
  runId: 'run-1',
);

EnvironmentDefinition _passthroughDefinition(String maps) =>
    EnvironmentDefinition.fromJson({
      'contract': 1,
      'name': 'Shop',
      'repos': {
        'app': {'repoId': 'repo-1', 'anchor': true, 'required': true},
      },
      'components': [
        {
          'kind': 'cli',
          'id': 'tool',
          'verbs': {
            'create': ['tool', 'create'],
            'status': ['tool', 'status'],
            'destroy': ['tool', 'destroy'],
          },
          'agentPassthrough': {
            'binary': 'tool',
            'allow': [
              {
                'argv': ['show'],
                'maps': maps,
              },
            ],
          },
        },
      ],
    });

class _Environments implements EnvironmentPort {
  @override
  Future<List<EnvironmentInstance>> definitionEnvironments(
    String workspaceId,
    String definitionId,
  ) async => const [];

  @override
  Future<Map<String, String>> terminalEnvironment(
    String workspaceId,
    String spaceId,
  ) async => const {
    'COMPOSE_PROJECT_NAME': 'cc-mine',
    'COMPOSE_FILE': '/worktree/compose.yaml:/state/compose.override.yaml',
  };

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Context implements AgentEnvironmentContext {
  _Context(this._harness);

  final _Harness _harness;

  @override
  Future<EnvironmentDefinition?> definitionFor(
    String workspaceId,
    String spaceId,
  ) async {
    _harness.refuseUnapproved();
    return _harness.definition;
  }

  @override
  Future<AgentComposeProject?> hostComposeProject(
    String workspaceId,
    String spaceId,
  ) async {
    _harness.refuseUnapproved();
    return _harness.composeProject;
  }

  @override
  Future<bool> isInside(String path, List<String> roots) async => true;

  @override
  Future<String?> nameFor(String workspaceId, String spaceId) async => 'mine';

  @override
  Future<String?> workingDirectory(String workspaceId, String spaceId) async =>
      '/worktree';

  @override
  Future<List<String>> worktreeRoots(
    String workspaceId,
    String spaceId,
  ) async => const ['/worktree'];
}

class _Guard implements ActionGuardService {
  _Guard(this._harness);

  final _Harness _harness;

  @override
  Future<GuardVerdict> check({
    required String workspaceId,
    required Set<ActionClass> classes,
    String? command,
    String? spaceId,
    String? conversationId,
    String? agentId,
    Mode mode = Mode.chat,
    String actionSummary = '',
    String? approvalRationale,
    bool operatorInitiated = false,
    String? onBehalfOfUserId,
    String? runId,
    ActionRequest request = ActionRequest.empty,
    bool canOverride = false,
    String? overrideReason,
    AutonomyLevel? autonomy,
    bool autonomyGated = true,
    Future<void>? withdrawn,
  }) async {
    _harness.guarded.add(classes);
    return _harness.allow
        ? const GuardVerdict.allow()
        : const GuardVerdict.deny('denied');
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A gateway with every outside effect recorded.
class _Harness {
  _Harness() {
    gateway = AgentEnvironmentGateway(
      environments: _Environments(),
      context: _Context(this),
      guard: _Guard(this),
      runHost:
          (
            binary,
            arguments, {
            required workingDirectory,
            environment = const {},
          }) async {
            host.add((
              binary: binary,
              arguments: arguments,
              environment: environment,
              workingDirectory: workingDirectory,
            ));
            return const AgentEnvironmentResult(exitCode: 0);
          },
    );
  }

  late final AgentEnvironmentGateway gateway;
  EnvironmentDefinition? definition;
  AgentComposeProject? composeProject = const AgentComposeProject(
    name: 'cc-mine',
    directory: '/state/env-1',
  );
  bool approved = true;
  bool allow = true;

  void refuseUnapproved() {
    if (!approved) {
      throw const EnvironmentHostUnapprovedException();
    }
  }

  final List<Set<ActionClass>> guarded = [];
  final List<
    ({
      String binary,
      List<String> arguments,
      Map<String, String> environment,
      String workingDirectory,
    })
  >
  host = [];
}

void main() {
  group('docker shim', () {
    bool allowed(List<String> argv) => validateComposeShim(argv) == null;

    test('allows the read and restart verbs', () {
      for (final sub in kAgentComposeCommands) {
        expect(allowed(['compose', sub]), isTrue, reason: sub);
      }
    });

    test('refuses everything outside docker compose', () {
      for (final argv in [
        ['ps'],
        ['run', 'alpine'],
        ['exec', 'x', 'sh'],
        ['compose'],
        <String>[],
      ]) {
        final result = validateComposeShim(argv);
        expect(result?.exitCode, 5, reason: '$argv');
        expect(result?.stderr, contains('not available'));
      }
    });

    test('refuses compose commands that change the stack', () {
      for (final sub in ['up', 'down', 'run', 'rm', 'cp', 'build', 'pull']) {
        expect(allowed(['compose', sub]), isFalse, reason: sub);
      }
    });

    test('a flag before the verb can not retarget the project', () {
      for (final argv in [
        ['compose', '-p', 'other', 'ps'],
        ['compose', '-f', '/etc/x.yaml', 'logs'],
        ['compose', '--project-directory', '/x', 'ps'],
      ]) {
        expect(allowed(argv), isFalse, reason: '$argv');
      }
    });

    test('exec accepts only known flags before the service', () {
      expect(allowed(['compose', 'exec', 'db', 'psql']), isTrue);
      expect(allowed(['compose', 'exec', '-T', 'db', 'psql']), isTrue);
      for (final flag in ['--privileged', '-u', '--user=root', '-e', '-w']) {
        expect(
          allowed(['compose', 'exec', flag, 'db', 'sh']),
          isFalse,
          reason: flag,
        );
      }
      // After the service these belong to the command being run.
      expect(allowed(['compose', 'exec', 'db', 'psql', '-u', 'x']), isTrue);
    });

    test('logs can not follow', () {
      expect(allowed(['compose', 'logs', 'web']), isTrue);
      expect(allowed(['compose', 'logs', '-f', 'web']), isFalse);
      expect(allowed(['compose', 'logs', '--follow']), isFalse);
    });

    test('every sub-command has an option allowlist', () {
      expect(kAgentComposeOptions.keys.toSet(), kAgentComposeCommands);
    });

    test('after the verb no option can retarget the stack or read a host '
        'file', () {
      for (final sub in kAgentComposeCommands) {
        for (final option in [
          ['-f', '/etc/x.yaml'],
          ['--file', '/etc/x.yaml'],
          ['--file=/etc/x.yaml'],
          ['-p', 'other'],
          ['--project-name', 'other'],
          ['--project-directory', '/x'],
          ['--project-directory=/x'],
          ['--env-file', '/home/me/.env'],
          ['--profile', 'all'],
          ['--dry-run'],
          ['-aq'],
        ]) {
          final argv = ['compose', sub, ...option, if (sub == 'exec') 'db'];
          expect(allowed(argv), isFalse, reason: '$argv');
          if (sub != 'exec') {
            expect(
              allowed(['compose', sub, 'web', ...option]),
              isFalse,
              reason: '$sub web $option',
            );
          }
        }
      }
    });

    test('known options and their values pass', () {
      for (final argv in [
        ['compose', 'ps', '-a', '--format', 'json'],
        ['compose', 'ps', '--format={{.Name}}', 'web'],
        ['compose', 'logs', '--tail', '50', '-t', 'web'],
        ['compose', 'logs', '--since=10m', 'web', 'db'],
        ['compose', 'restart', '-t', '5', 'web'],
        ['compose', 'port', 'web', '3000'],
        ['compose', 'top', 'web'],
        ['compose', 'exec', '--no-TTY', 'db', 'psql', '-f', 'x.sql'],
      ]) {
        expect(allowed(argv), isTrue, reason: '$argv');
      }
      // A switch can not smuggle a value.
      expect(allowed(['compose', 'ps', '--all=/x']), isFalse);
      // An option's value is not read as an option.
      expect(allowed(['compose', 'logs', '--tail', '-f']), isTrue);
      // After `--` only operands follow.
      expect(allowed(['compose', 'ps', '--', '-f']), isTrue);
    });

    test('exec gets no TTY whatever its container command says', () {
      expect(
        composeShimArguments([
          'compose',
          'exec',
          'db',
          'tool',
          '-T',
        ], project: 'cc-mine'),
        ['compose', '-p', 'cc-mine', 'exec', '-T', 'db', 'tool', '-T'],
      );
      expect(
        composeShimArguments([
          'compose',
          'exec',
          '--no-tty',
          'db',
        ], project: 'cc-mine'),
        ['compose', '-p', 'cc-mine', 'exec', '--no-tty', 'db'],
      );
    });

    test('every command is pinned to the project, and exec gets no TTY', () {
      List<String> argv(List<String> arguments) =>
          composeShimArguments(arguments, project: 'cc-mine');
      expect(argv(['compose', 'exec', 'db', 'sh']), [
        'compose',
        '-p',
        'cc-mine',
        'exec',
        '-T',
        'db',
        'sh',
      ]);
      expect(argv(['compose', 'exec', '-T', 'db']), [
        'compose',
        '-p',
        'cc-mine',
        'exec',
        '-T',
        'db',
      ]);
      expect(argv(['compose', 'ps']), ['compose', '-p', 'cc-mine', 'ps']);
    });

    group('on the host', () {
      late _Harness h;

      setUp(() => h = _Harness());

      test('reads no compose file and turns remote resources off', () async {
        await h.gateway.handle(_caller, 'docker', ['compose', 'ps']);
        final call = h.host.single;
        expect(call.binary, 'docker');
        expect(call.arguments, ['compose', '-p', 'cc-mine', 'ps']);
        expect(call.arguments, isNot(contains('-f')));
        expect(call.environment, {
          'COMPOSE_EXPERIMENTAL_GIT_REMOTE': '0',
          'COMPOSE_EXPERIMENTAL_OCI_REMOTE': '0',
        });
      });

      test('runs from the state directory, never a worktree', () async {
        await h.gateway.handle(_caller, 'docker', ['compose', 'ps']);
        final directory = h.host.single.workingDirectory;
        expect(directory, '/state/env-1');
        for (final root in const ['/worktree']) {
          expect(
            directory == root || p.isWithin(root, directory),
            isFalse,
            reason: root,
          );
        }
      });

      test('an unapproved definition reaches nothing', () async {
        h.approved = false;
        final result = await h.gateway.handle(_caller, 'docker', [
          'compose',
          'ps',
        ]);
        expect(result.exitCode, 5);
        expect(result.stderr, contains('server owner has not approved'));
        expect(h.host, isEmpty);
        expect(h.guarded, isEmpty);
      });

      test(
        'a compose environment in a rig is not reached on the host',
        () async {
          h.composeProject = null;
          final result = await h.gateway.handle(_caller, 'docker', [
            'compose',
            'restart',
            'web',
          ]);
          expect(result.exitCode, 5);
          expect(result.stderr, contains('cc-env exec'));
          expect(h.host, isEmpty);
        },
      );

      test('a refused option runs nothing', () async {
        final result = await h.gateway.handle(_caller, 'docker', [
          'compose',
          'logs',
          '--project-directory',
          '/elsewhere',
        ]);
        expect(result.exitCode, 5);
        expect(h.host, isEmpty);
      });

      test('a read needs no approval, and exec does', () async {
        await h.gateway.handle(_caller, 'docker', ['compose', 'logs', 'web']);
        expect(h.guarded, isEmpty);

        await h.gateway.handle(_caller, 'docker', [
          'compose',
          'exec',
          'web',
          'ls',
        ]);
        expect(h.guarded.single, contains(ActionClass.hostExecution));
      });
    });
  });

  group('pass-through', () {
    const rule = EnvironmentPassthroughRule(
      argv: ['env', 'status'],
      maps: 'status',
      positionalName: 2,
    );

    test('the name is forced, whatever the agent typed', () {
      expect(forcePositionalName(['env', 'status', 'other'], rule, 'mine'), [
        'env',
        'status',
        'mine',
      ]);
      expect(forcePositionalName(['env', 'status'], rule, 'mine'), [
        'env',
        'status',
        'mine',
      ]);
      expect(forcePositionalName(['env', 'status', '--json'], rule, 'mine'), [
        'env',
        'status',
        'mine',
        '--json',
      ]);
    });

    test('a rule that needs a name refuses without one', () {
      expect(forcePositionalName(['env', 'status'], rule, null), isNull);
    });

    test('path flags are found in both spellings', () {
      expect(
        pathFlagValues(['--a', '/x', '--b=/y', '--c', '/z'], ['--a', '--b']),
        ['/x', '/y'],
      );
    });

    group('policy', () {
      late _Harness h;

      setUp(() => h = _Harness());

      test('a rule mapped to a read still carries hostExecution', () async {
        for (final maps in ['status', 'logs']) {
          h.guarded.clear();
          h.definition = _passthroughDefinition(maps);
          await h.gateway.handle(_caller, 'tool', ['show']);
          expect(h.guarded.single, contains(ActionClass.hostExecution));
        }
      });

      test('a rule keeps the classes of what it maps to', () async {
        h.definition = _passthroughDefinition('run');
        await h.gateway.handle(_caller, 'tool', ['show']);
        expect(
          h.guarded.single,
          containsAll([
            ActionClass.hostExecution,
            ActionClass.processSpawn,
            ActionClass.networkEgress,
          ]),
        );
      });

      test('an unapproved definition runs nothing', () async {
        h
          ..definition = _passthroughDefinition('status')
          ..approved = false;
        final result = await h.gateway.handle(_caller, 'tool', ['show']);
        expect(result.exitCode, 5);
        expect(result.stderr, contains('server owner has not approved'));
        expect(h.guarded, isEmpty);
        expect(h.host, isEmpty);
      });

      test('a refusal runs nothing, even for a read', () async {
        h
          ..definition = _passthroughDefinition('status')
          ..allow = false;
        final result = await h.gateway.handle(_caller, 'tool', ['show']);
        expect(result.exitCode, 1);
        expect(result.stderr, contains('Control Center policy'));
        expect(h.host, isEmpty);
      });
    });

    test('an option reads as its name, its value and the short options it '
        'could be', () {
      expect(readOption('web'), isNull);
      expect(readOption('-'), isNull);
      expect(readOption('--'), isNull);
      expect(readOption('--config=/x'), (
        name: '--config',
        value: '/x',
        shorts: const <String>[],
      ));
      expect(readOption('-X'), (
        name: '-X',
        value: null,
        shorts: const <String>[],
      ));
      expect(readOption('-Xvalue')?.shorts, contains('-X'));
      expect(readOption('-abX')?.shorts, ['-a', '-b', '-X']);
      expect(readOption('-X=v')?.name, '-X');
    });

    test(
      'every spelling of a denied flag is refused before anything runs',
      () async {
        final h = _Harness()
          ..definition = EnvironmentDefinition.fromJson({
            ..._passthroughDefinition('status').toJson(),
            'components': [
              {
                'kind': 'cli',
                'id': 'tool',
                'verbs': {
                  'create': ['tool', 'create'],
                  'status': ['tool', 'status'],
                  'destroy': ['tool', 'destroy'],
                },
                'agentPassthrough': {
                  'binary': 'tool',
                  'allow': [
                    {
                      'argv': ['show'],
                      'maps': 'status',
                      'denyFlags': ['-X', '--config'],
                    },
                  ],
                },
              },
            ],
          });
        for (final spelling in [
          '-X',
          '-Xvalue',
          '-X=value',
          '-aX',
          '-Xa',
          '--config',
          '--config=/etc/x',
        ]) {
          final result = await h.gateway.handle(_caller, 'tool', [
            'show',
            spelling,
          ]);
          expect(result.exitCode, 5, reason: spelling);
          expect(result.stderr, contains('not available'), reason: spelling);
        }
        expect(h.host, isEmpty);
        expect(h.guarded, isEmpty);

        await h.gateway.handle(_caller, 'tool', ['show', '-a', '--configs']);
        expect(h.host, hasLength(1));
      },
    );

    test('JSON output is filtered to this environment', () {
      expect(
        filterJsonToName('[{"slug":"mine"},{"slug":"other"}]', 'mine'),
        '[{"slug":"mine"}]',
      );
      expect(filterJsonToName('not json', 'mine'), 'not json');
    });
  });

  test('a double dash splits arguments once', () {
    final split = splitAtDoubleDash(['db', '--', 'psql', '--', 'x']);
    expect(split.before, ['db']);
    expect(split.after, ['psql', '--', 'x']);
  });

  test('every environment operation has reviewed action classes', () {
    expect(kEnvironmentOpClasses['status'], isEmpty);
    expect(kEnvironmentOpClasses['destroy'], isNotEmpty);
    expect(kEnvironmentOpClasses['exec'], isNotEmpty);
    expect(kEnvironmentOpClasses['run'], isNotEmpty);
  });

  test('the shim reads its own name and hands the call to the client', () {
    final script = agentShimScript(clientCommand: "'/opt/cc server' agent-run");
    expect(
      script,
      "#!/bin/sh\nexec '/opt/cc server' agent-run env \"\$(basename \"\$0\")\" "
      '"\$@"\n',
    );
  });
}
