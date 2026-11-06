import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
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
  Future<String> startSetup(
    String workspaceId,
    String spaceId, {
    required Principal by,
  }) async => 'session-1';

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
  ) async => _harness.definition;

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
            ));
            return const AgentEnvironmentResult(exitCode: 0);
          },
    );
  }

  late final AgentEnvironmentGateway gateway;
  EnvironmentDefinition? definition;
  bool allow = true;
  final List<Set<ActionClass>> guarded = [];
  final List<
    ({String binary, List<String> arguments, Map<String, String> environment})
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

  test('the shim reads its own name and carries the run token', () {
    final script = agentShimScript(
      tokenHeader: 'X-Tok',
      tokenEnvKey: 'TOK',
      gatewayEnvKey: 'GW',
    );
    expect(script, contains(r'basename "$0"'));
    expect(script, contains(r'X-Tok: $TOK'));
    expect(script, contains(r'$GW/agent/env'));
    expect(script, contains("--noproxy '*'"));
  });
}
