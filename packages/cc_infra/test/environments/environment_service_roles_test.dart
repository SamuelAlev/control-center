import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_service_ports.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';
import 'helpers/environment_service_harness.dart';

/// Optional roles, what a component left out of an environment loses, and the
/// checks that keep agent input and placeholder typos from reaching a command.
void main() {
  late String root;
  late ServiceHarness h;

  setUp(() {
    root = tempDir(addTearDown).path;
    h = ServiceHarness(root);
    addTearDown(() => h.service.stopListening());
  });

  Matcher driverError(String code, [Object? message]) => throwsA(
    isA<EnvironmentDriverException>()
        .having((e) => e.error.code, 'code', code)
        .having((e) => e.error.message, 'message', message ?? anything),
  );

  Matcher unknownTarget() => throwsA(
    isA<ValidationException>().having(
      (e) => e.code,
      'code',
      'environment.unknown_target',
    ),
  );

  /// `app` is required, `e2e` is not, and `space-1` holds only `app`.
  const roles = {
    'app': {'repoId': 'repo-app', 'anchor': true, 'required': true},
    'e2e': {'repoId': 'repo-e2e'},
  };

  Map<String, dynamic> suiteJson({Map<String, dynamic> extra = const {}}) => {
    'kind': 'process',
    'id': 'suite',
    'port': 'suite',
    'endpoint': {'role': 'suite'},
    'cwd': {'role': 'e2e'},
    'command': ['tool', 'suite', '{port.suite}'],
    ...extra,
  };

  /// A space holding both roles.
  void addBoth() {
    final worktree = '$root/worktrees/both-e2e';
    Directory(worktree).createSync(recursive: true);
    h.addSpace(
      'both',
      extraRepos: [
        EnvironmentSpaceRepo(
          repoId: 'repo-e2e',
          name: 'E2E',
          slug: 'e2e',
          worktreePath: worktree,
          sourcePath: '$root/source-e2e',
        ),
      ],
    );
  }

  group('service names from agents', () {
    Map<String, dynamic> toolJson() => {
      'kind': 'cli',
      'id': 'tool',
      'verbs': {
        'create': ['tool', 'create', '{name}'],
        'status': ['tool', 'status', '{name}'],
        'destroy': ['tool', 'destroy', '{name}'],
        'logs': [
          'tool',
          'logs',
          '{name}',
          {
            'if': 'service',
            'args': ['{service}'],
          },
        ],
        'exec': ['tool', 'exec', '{name}', '{service}', '{command}'],
      },
    };

    List<String> toolCalls(String verb) => [
      for (final line in h.commands)
        if (line.startsWith('tool $verb')) line,
    ];

    test('an option never reaches the tool as a service', () async {
      h.tool['status'] = ok(
        jsonEncode({
          'state': 'ready',
          'services': ['api', 'worker'],
        }),
      );
      h.store(definitionJson([toolJson()]));
      final env = await h.ensure();
      expect(env.status, EnvironmentStatus.ready);

      for (final target in ['--env=other', 'db']) {
        await expectLater(
          h.service.logs('ws-a', 'space-1', target: target),
          unknownTarget(),
        );
        await expectLater(
          h.service.followLogs('ws-a', 'space-1', target: target).toList(),
          unknownTarget(),
        );
        await expectLater(
          h.service.exec(
            'ws-a',
            'space-1',
            service: target,
            command: ['ls'],
            by: principal,
          ),
          unknownTarget(),
        );
      }
      expect(toolCalls('logs'), isEmpty);
      expect(toolCalls('exec'), isEmpty);

      await h.service.logs('ws-a', 'space-1', target: 'api');
      await h.service.logs('ws-a', 'space-1', target: 'tool');
      expect(toolCalls('logs'), [
        'tool logs ${env.name} api',
        'tool logs ${env.name}',
      ]);
    });

    test('with no report, one plain word passes', () async {
      h.tool['status'] = ok(jsonEncode({'state': 'ready'}));
      h.store(definitionJson([toolJson()]));
      final env = await h.ensure();

      for (final target in ['-v', 'a b', 'api\u001b[2J', 'api\n']) {
        await expectLater(
          h.service.logs('ws-a', 'space-1', target: target),
          unknownTarget(),
          reason: jsonEncode(target),
        );
      }
      await h.service.logs('ws-a', 'space-1', target: 'api');
      expect(toolCalls('logs'), ['tool logs ${env.name} api']);
    });

    test('a rig exec takes no option for a service', () async {
      final rig = FakeRigHost();
      h = ServiceHarness(root, rigHost: rig);
      h.addSpace('fork', prNumber: 7, prRepo: 'acme/shop', isFork: true);
      h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'policy': {'forkPrs': 'rig'},
          },
        ),
      );
      await h.ensure(space: 'fork');
      await expectLater(
        h.service.exec(
          'ws-a',
          'fork',
          service: '--privileged',
          command: ['sh'],
          by: principal,
        ),
        unknownTarget(),
      );
      expect(rig.execs, isEmpty);
      await h.service.exec(
        'ws-a',
        'fork',
        service: 'db',
        command: ['ls'],
        by: principal,
      );
      expect(rig.execs.single, containsAllInOrder(['exec', '-T', 'db', 'ls']));
    });
  });

  group('roles', () {
    test('relying on an optional first role is refused', () async {
      h.store(
        definitionJson(
          [
            taskJson('t', ['start']),
          ],
          repos: {
            'app': {'repoId': 'repo-app', 'anchor': true},
            'e2e': {'repoId': 'repo-e2e', 'anchor': true},
          },
        ),
      );
      await expectLater(
        h.ensure(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('Runs in app, which a space may not have'),
          ),
        ),
      );
      expect(h.commands, isEmpty);
    });

    test(
      'the one anchor is a default every space that starts it has',
      () async {
        h.store(
          definitionJson(
            [
              taskJson('t', ['start']),
            ],
            repos: {
              'app': {'repoId': 'repo-app', 'anchor': true},
              'docs': {'repoId': 'repo-e2e'},
            },
          ),
        );

        expect((await h.ensure()).status, EnvironmentStatus.ready);
        expect(h.commands, ['tool t']);
      },
    );

    test(
      'a component in an optional role the space lacks is left out',
      () async {
        h.store(
          definitionJson([
            webJson(),
            suiteJson(),
            taskJson(
              'e2e-seed',
              ['start'],
              extra: {
                'cwd': {'role': 'e2e'},
              },
            ),
          ], repos: roles),
        );
        final env = await h.ensure();
        expect(env.status, EnvironmentStatus.ready);
        expect(env.components.map((c) => c.id), ['web']);
        expect(env.endpoints.map((e) => e.role), ['web']);
        expect(h.terminals.sessions, hasLength(1));
        expect(h.commands, isNot(contains('tool e2e-seed')));
        final variables = await h.service.terminalEnvironment(
          'ws-a',
          'space-1',
        );
        expect(variables, contains('CC_ENV_URL_WEB'));
        expect(variables, isNot(contains('CC_ENV_URL_SUITE')));
        expect(variables, isNot(contains('CC_ENV_PORT_SUITE')));
      },
    );

    test('the same component runs where the space has its role', () async {
      addBoth();
      h.store(definitionJson([webJson(), suiteJson()], repos: roles));
      final env = await h.ensure(space: 'both');
      expect(env.components.map((c) => c.id), ['web', 'suite']);
      expect(env.endpoints.map((e) => e.role), ['web', 'suite']);
      final suite = h.terminals.sessions.last;
      expect(suite.arguments, ['suite', '${env.ports['suite']}']);
    });

    test('a reference to a left-out component stops the start', () async {
      h.store(
        definitionJson([
          webJson(
            extra: {
              'env': {'SUITE_URL': '{url.suite}'},
            },
          ),
          suiteJson(),
        ], repos: roles),
      );
      await expectLater(
        h.ensure(),
        driverError(
          'unknown-placeholder',
          'web: Unknown placeholder {url.suite}',
        ),
      );
      expect(h.terminals.sessions, isEmpty);
      expect(h.environments.rows, isEmpty);
    });

    test('a disabled process has no URL or port in the contract', () async {
      h.store(
        definitionJson(
          [
            webJson(),
            suiteJson(
              extra: {
                'cwd': {'role': 'app'},
                'enabledWhen': 'opt.suite',
              },
            ),
          ],
          extra: {
            'options': [
              {'key': 'suite', 'type': 'bool', 'default': false},
            ],
          },
        ),
      );
      final env = await h.ensure();
      expect(env.endpoints.map((e) => e.role), ['web']);
      final variables = await h.service.terminalEnvironment('ws-a', 'space-1');
      expect(variables, isNot(contains('CC_ENV_URL_SUITE')));
      expect(variables, isNot(contains('CC_ENV_PORT_SUITE')));
    });

    test('an app in a role the space lacks can not be launched', () async {
      h.store(
        definitionJson([
          webJson(),
          {
            'kind': 'app',
            'id': 'desktop',
            'cwd': {'role': 'e2e'},
            'command': ['tool', 'open'],
          },
        ], repos: roles),
      );
      final env = await h.ensure();
      expect(env.components.map((c) => c.id), ['web']);
      await expectLater(
        h.service.launchApp('ws-a', 'space-1', 'desktop', by: principal),
        driverError('component-disabled'),
      );
    });
  });

  group('compose planning', () {
    List<String> configCalls() => [
      for (final call in h.runner.calls)
        if (call.argv.contains('config')) call.argv.join(' '),
    ];

    test('a disabled compose component is never planned', () async {
      // Neither the file nor Docker needs to be there for it.
      File('$root/worktrees/space-1/compose.yaml').deleteSync();
      h.store(
        definitionJson(
          [
            {...composeJson(), 'enabledWhen': 'opt.docker'},
            taskJson('t', ['start']),
          ],
          extra: {
            'options': [
              {'key': 'docker', 'type': 'bool', 'default': false},
            ],
          },
        ),
      );
      final env = await h.ensure();
      expect(env.status, EnvironmentStatus.ready);
      expect(configCalls(), isEmpty);
      expect(h.commands, ['tool t']);
    });

    test(
      'a compose component in a role the space lacks is not planned',
      () async {
        h.store(
          definitionJson([
            {
              ...composeJson(),
              'cwd': {'role': 'e2e'},
            },
            taskJson('t', ['start']),
          ], repos: roles),
        );
        final env = await h.ensure();
        expect(env.status, EnvironmentStatus.ready);
        expect(configCalls(), isEmpty);
        expect(env.components.map((c) => c.id), ['t']);
      },
    );
  });

  group('placeholders', () {
    test('a typo in a compose port stops the start before compose', () async {
      h.store(
        definitionJson([
          composeJson(),
          webJson(
            extra: {
              'env': {'DB': 'postgres://127.0.0.1:{port.postgres.5433}/app'},
            },
          ),
        ]),
      );
      await expectLater(
        h.ensure(),
        driverError(
          'unknown-placeholder',
          'web: Unknown placeholder {port.postgres.5433}',
        ),
      );
      expect(
        h.commands.where((line) => line.startsWith('compose up')),
        isEmpty,
      );
      expect(h.terminals.sessions, isEmpty);
      expect(h.environments.rows, isEmpty);
      expect(h.leases.leases, isEmpty);
    });

    test('a typo in a readiness probe stops it too', () async {
      h.store(
        definitionJson([
          composeJson(),
          webJson(
            extra: {
              'ready': {'tcp': '127.0.0.1:{port.db.5433}'},
            },
          ),
        ]),
      );
      await expectLater(
        h.ensure(),
        driverError(
          'unknown-placeholder',
          'web: Unknown placeholder {port.db.5433}',
        ),
      );
    });

    test('verb values and false conditions are not checked', () async {
      h.tool['status'] = ok(jsonEncode({'state': 'ready'}));
      h.store(
        definitionJson(
          [
            composeJson(),
            {
              'kind': 'cli',
              'id': 'tool',
              'verbs': {
                'create': ['tool', 'create', '{name}'],
                'status': ['tool', 'status', '{name}'],
                'destroy': ['tool', 'destroy', '{name}'],
                'logs': [
                  'tool',
                  'logs',
                  '{service}',
                  '--tail',
                  '{tail}',
                  {
                    'if': 'follow',
                    'args': ['--follow'],
                  },
                ],
                'exec': ['tool', 'exec', '{service}', '{command}'],
              },
            },
            webJson(
              extra: {
                'command': [
                  'pnpm',
                  'dev',
                  {
                    'if': 'opt.debug',
                    'args': ['--inspect={port.debugger.9229}'],
                  },
                ],
              },
            ),
          ],
          extra: {
            'options': [
              {'key': 'debug', 'type': 'bool', 'default': false},
            ],
          },
        ),
      );
      final env = await h.ensure();
      expect(env.status, EnvironmentStatus.ready);
      expect(h.terminals.sessions.single.arguments, ['dev']);
    });
  });
}
