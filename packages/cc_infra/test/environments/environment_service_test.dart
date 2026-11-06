import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/events/environment_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/worktree_task_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_service_ports.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';
import 'helpers/environment_service_harness.dart';

void main() {
  late String root;
  late ServiceHarness h;

  setUp(() {
    root = tempDir(addTearDown).path;
    h = ServiceHarness(root);
    addTearDown(() => h.service.stopListening());
  });

  Matcher driverError(String code) => throwsA(
    isA<EnvironmentDriverException>().having((e) => e.error.code, 'code', code),
  );

  Matcher invalid(Object message) => throwsA(
    isA<ValidationException>().having((e) => e.message, 'message', message),
  );

  SpaceEnvironment row([String space = 'space-1']) =>
      h.environments.rows.values.firstWhere((item) => item.spaceId == space);

  EnvironmentComponentState component(String id, [String space = 'space-1']) =>
      row(space).components.firstWhere((item) => item.id == id);

  group('ensure', () {
    test('every port and URL resolves before anything starts', () async {
      h.store(
        definitionJson(
          [composeJson(), webJson()],
          extra: {
            'env': {
              'DB': 'postgres://127.0.0.1:{port.db.5432}/app',
              'BASE_URL': '{url.web}',
            },
          },
        ),
      );
      final env = await h.ensure();
      expect(env.status, EnvironmentStatus.ready);
      expect(env.name, 'fix-space-1');
      expect(env.ports.keys, unorderedEquals(['web', 'db.5432', 'site.80']));

      final session = h.terminals.last;
      expect(session.arguments, ['dev', '--port', '${env.ports['web']}']);
      expect(
        session.environment['DB'],
        'postgres://127.0.0.1:${env.ports['db.5432']}/app',
      );
      expect(
        session.environment['BASE_URL'],
        'http://web--fix-space-1--shop.localhost:7355',
      );
      expect(session.environment['PORT'], '${env.ports['web']}');
      expect(session.environment['COMPOSE_PROJECT_NAME'], startsWith('cc-'));
      expect(env.primaryEndpoint?.url, session.environment['BASE_URL']);
    });

    test('registers router routes for processes and HTTP compose', () async {
      h.store(definitionJson([composeJson(), webJson()]));
      h.httpPorts.add(42000 + 2);
      final env = await h.ensure();
      final routes = h.routing.routes[env.id]!;
      final web = routes['web--fix-space-1--shop.localhost']!;
      expect(web.workspaceId, 'ws-a');
      expect(web.host, '127.0.0.1');
      expect(web.port, env.ports['web']);
      expect(routes.keys, hasLength(1 + h.httpPorts.length));
      final byRole = {for (final e in env.endpoints) e.role: e};
      expect(byRole['db']?.url, isNull);
      expect(byRole['db']?.hostPort, env.ports['db.5432']);
    });

    test('a declared endpoint keeps its name over a compose port', () async {
      h.model = {
        'services': <String, dynamic>{
          'web': {
            'ports': [
              {'target': 80, 'protocol': 'tcp'},
            ],
          },
        },
      };
      h.store(definitionJson([composeJson(), webJson()]));
      final env = await h.ensure();
      h.httpPorts.add(env.ports['web.80']!);
      final endpoint = env.endpoints.single;
      expect(endpoint.primary, isTrue);
      expect(endpoint.hostPort, env.ports['web']);
      expect(
        h.routing.routes[env.id]!['web--fix-space-1--shop.localhost']?.port,
        env.ports['web'],
      );
    });

    test('a compose HTTP endpoint gets a router URL', () async {
      h.model = {
        'services': <String, dynamic>{
          'site': {
            'ports': [
              {'target': 80, 'protocol': 'tcp'},
            ],
          },
        },
      };
      h.store(definitionJson([composeJson()]));
      h.httpPorts.add(42000);
      final env = await h.ensure();
      expect(
        env.endpoints.single.url,
        'http://site--fix-space-1--shop.localhost:7355',
      );
      expect(
        h.routing.routes[env.id]!['site--fix-space-1--shop.localhost']?.port,
        42000,
      );
    });

    test('runs components in order, waiting for each', () async {
      h.store(
        definitionJson([
          taskJson('first', ['start']),
          composeJson(),
          taskJson('second', ['start']),
          taskJson('never', ['manual']),
        ]),
      );
      await h.ensure();
      expect(h.commands, [
        'tool first',
        'compose up -d db site',
        'tool second',
      ]);
    });

    test('`after` replaces waiting for the previous one', () async {
      final held = Completer<void>();
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('slow')) {
          await held.future;
        }
      };
      h.store(
        definitionJson([
          taskJson('base', ['start']),
          taskJson('slow', ['start']),
          taskJson(
            'quick',
            ['start'],
            extra: {
              'after': ['base'],
            },
          ),
        ]),
      );
      final done = h.ensure();
      await h.until(() => h.commands.contains('tool quick'));
      expect(row().status, isNot(EnvironmentStatus.ready));
      held.complete();
      expect((await done).status, EnvironmentStatus.ready);
    });

    test('enabledWhen leaves a component out', () async {
      h.store(
        definitionJson(
          [
            taskJson('seed', ['start'], extra: {'enabledWhen': 'opt.seed'}),
            taskJson('always', ['start']),
          ],
          extra: {
            'options': [
              {'key': 'seed', 'type': 'bool', 'default': false},
            ],
          },
        ),
      );
      final env = await h.ensure();
      expect(h.commands, ['tool always']);
      expect(env.components.map((c) => c.id), ['always']);
    });

    test('an app waits for Launch and does not gate ready', () async {
      h.store(
        definitionJson([
          webJson(),
          {
            'kind': 'app',
            'id': 'desktop',
            'command': ['tool', 'open'],
          },
        ]),
      );
      final env = await h.ensure();
      expect(env.status, EnvironmentStatus.ready);
      expect(h.terminals.sessions, hasLength(1));
      expect(component('desktop').state, 'closed');
    });

    test('a ready environment is reused', () async {
      h.store(definitionJson([composeJson()]));
      final first = await h.ensure();
      h.runner.calls.clear();
      h.now = h.now.add(const Duration(hours: 1));
      final second = await h.ensure();
      expect(second.id, first.id);
      expect(h.commands, isEmpty);
      expect(second.lastUsedAt, h.now);
    });

    test('a stopped environment starts and keeps its ports', () async {
      h.store(definitionJson([composeJson(), webJson()]));
      final first = await h.ensure();
      await h.service.stop('ws-a', 'space-1', by: principal);
      expect(row().status, EnvironmentStatus.stopped);
      expect(h.routing.routes[first.id], isNull);
      h.runner.calls.clear();

      final second = await h.ensure();
      expect(second.id, first.id);
      expect(second.ports, first.ports);
      expect(second.status, EnvironmentStatus.ready);
      expect(h.commands, ['compose up -d db site']);
      expect(h.routing.routes[first.id], isNotEmpty);
    });

    test('create tasks run on the first start and after reset only', () async {
      h.store(
        definitionJson([
          taskJson('migrate', ['create']),
          taskJson('warm', ['start']),
        ]),
      );
      await h.ensure();
      await h.service.stop('ws-a', 'space-1', by: principal);
      await h.ensure();
      expect(h.commands, ['tool migrate', 'tool warm', 'tool warm']);
      h.runner.calls.clear();
      await h.service.reset('ws-a', 'space-1', by: principal);
      expect(h.commands, ['tool migrate', 'tool warm']);
    });

    test(
      'a create task that failed runs again, one that worked does not',
      () async {
        h.store(
          definitionJson([
            taskJson('one', ['create']),
            taskJson('two', ['create']),
          ]),
        );
        h.tool['two'] = failed(1, stderr: 'broke');
        expect((await h.ensure()).status, EnvironmentStatus.failed);
        h.tool.remove('two');
        h.runner.calls.clear();
        expect((await h.ensure()).status, EnvironmentStatus.ready);
        expect(h.commands, ['tool two']);
      },
    );

    test('a failure stops the chain and says which and why', () async {
      h.store(
        definitionJson([
          taskJson('migrate', ['start']),
          taskJson('later', ['start']),
        ]),
      );
      h.tool['migrate'] = failed(
        3,
        error: const EnvironmentError(
          code: 'host',
          message: 'Needs a hosts line',
          command: 'sudo tool hosts',
          exitCode: 3,
        ),
      );
      final env = await h.ensure();
      expect(env.status, EnvironmentStatus.failed);
      expect(env.lastError?.code, 'host');
      expect(env.lastError?.command, 'sudo tool hosts');
      expect(h.commands, ['tool migrate']);
      expect(component('migrate').state, 'failed');
    });

    test('a compose failure fails it with the service', () async {
      h.ps = (_) =>
          jsonEncode({'Service': 'db', 'State': 'exited', 'ExitCode': 1});
      h.store(definitionJson([composeJson()]));
      final env = await h.ensure();
      expect(env.status, EnvironmentStatus.failed);
      expect(env.lastError?.code, 'compose-service-failed');
    });

    test('preflight refuses before any component runs', () async {
      h.model = {
        'services': <String, dynamic>{
          'db': {
            'volumes': [
              {
                'type': 'bind',
                'source': '$root/worktrees/space-1/seed.sh',
                'target': '/seed',
              },
            ],
          },
        },
      };
      h.store(
        definitionJson([
          taskJson('first', ['start']),
          composeJson(),
        ]),
      );
      await expectLater(h.ensure(), driverError('compose-missing-bind'));
      expect(h.commands, isEmpty, reason: 'not half started');
      expect(h.environments.rows, isEmpty);
      expect(h.leases.leases, isEmpty, reason: 'nothing leaks');
    });

    test('a policy finding on a trusted space is a warning', () async {
      h.model = {
        'services': <String, dynamic>{
          'db': {'privileged': true},
        },
      };
      h.store(definitionJson([composeJson()]));
      final env = await h.ensure();
      expect(env.status, EnvironmentStatus.ready);
      expect(env.warnings.single, contains('privileged'));
    });

    test('the contract reaches tasks and tools', () async {
      h.store(
        definitionJson([
          {
            ...taskJson('migrate', ['start']),
            'env': {'LOCAL': 'yes'},
          },
        ]),
      );
      final env = await h.ensure();
      final call = h.runner.calls.firstWhere((c) => c.argv.first == 'tool');
      expect(call.environment['CC_ENV_ID'], env.id);
      expect(call.environment['LOCAL'], 'yes');
      expect(call.workingDirectory, '$root/worktrees/space-1');
    });

    test('a state dir is a real path', () async {
      h.store(
        definitionJson([
          taskJson('t', ['start']),
        ]),
      );
      final env = await h.ensure();
      final call = h.runner.calls.firstWhere((c) => c.argv.first == 'tool');
      expect(
        call.environment['CC_ENV_STATE_DIR'],
        Directory(
          '$root/data/ws-a/environments/${env.id}',
        ).resolveSymbolicLinksSync(),
      );
    });

    test('PR spaces are named pr-<n>', () async {
      h.addSpace('space-pr', prNumber: 42, prRepo: 'acme/shop', kind: 'pr');
      h.store(definitionJson([composeJson()]));
      expect((await h.ensure(space: 'space-pr')).name, 'pr-42');
    });

    test('two spaces on one branch get different names', () async {
      h.addSpace('space-2', branch: 'same');
      h.addSpace('space-3', branch: 'same');
      h.store(definitionJson([composeJson()]));
      final first = await h.ensure(space: 'space-2');
      final second = await h.ensure(space: 'space-3');
      expect(first.name, 'same');
      expect(second.name, isNot('same'));
    });

    test('a pool names from its slot', () async {
      h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'naming': {
              'project': 'shop',
              'pool': {'names': 'cc{n}', 'size': 2},
            },
          },
        ),
      );
      expect((await h.ensure()).name, 'cc1');
      expect(h.leases.leases.single.poolSlot, 1);
    });

    group('roles', () {
      const e2eRepo = EnvironmentSpaceRepo(
        repoId: 'repo-e2e',
        name: 'E2E',
        slug: 'e2e',
        worktreePath: '/tmp',
        sourcePath: '/tmp',
      );

      test('addToSpace adds the repo', () async {
        h.directory.addable['repo-e2e'] = e2eRepo;
        h.store(
          definitionJson(
            [
              taskJson('t', ['start']),
            ],
            repos: {
              'app': {'repoId': 'repo-app', 'anchor': true},
              'e2e': {'repoId': 'repo-e2e', 'whenMissing': 'addToSpace'},
            },
          ),
        );
        await h.ensure();
        expect(h.directory.added, ['repo-e2e']);
        final call = h.runner.calls.firstWhere((c) => c.argv.first == 'tool');
        expect(call.environment['CC_REPO_PATH_E2E'], '/tmp');
      });

      test('useSource passes the registered checkout', () async {
        h.store(
          definitionJson(
            [
              taskJson('t', ['start']),
            ],
            repos: {
              'app': {'repoId': 'repo-app', 'anchor': true},
              'e2e': {'repoId': 'repo-e2e', 'whenMissing': 'useSource'},
            },
          ),
        );
        await h.ensure();
        final call = h.runner.calls.firstWhere((c) => c.argv.first == 'tool');
        expect(call.environment['CC_REPO_PATH_E2E'], '$root/source-e2e');
        expect(h.directory.added, isEmpty);
      });

      test('skip leaves the variable unset', () async {
        h.store(
          definitionJson(
            [
              taskJson('t', ['start']),
            ],
            repos: {
              'app': {'repoId': 'repo-app', 'anchor': true},
              'e2e': {'repoId': 'repo-e2e', 'whenMissing': 'skip'},
            },
          ),
        );
        await h.ensure();
        final call = h.runner.calls.firstWhere((c) => c.argv.first == 'tool');
        expect(call.environment.keys, isNot(contains('CC_REPO_PATH_E2E')));
      });

      test('a required role that can\'t be had stops it', () async {
        h.store(
          definitionJson(
            [
              taskJson('t', ['start']),
            ],
            repos: {
              'app': {'repoId': 'repo-app', 'anchor': true},
              'e2e': {
                'repoId': 'repo-e2e',
                'required': true,
                'whenMissing': 'skip',
              },
            },
          ),
        );
        await expectLater(h.ensure(), driverError('role-missing'));
      });

      test('a space with no anchor can\'t start it', () async {
        h.store(
          definitionJson(
            [
              taskJson('t', ['start']),
            ],
            repos: {
              'e2e': {'repoId': 'repo-e2e', 'anchor': true},
            },
          ),
        );
        await expectLater(
          h.ensure(),
          invalid(contains('No environment definition fits')),
        );
      });

      test('two that fit are the caller\'s choice', () async {
        final json = definitionJson([composeJson()]);
        h
          ..store(json, id: 'def-1')
          ..store(json, id: 'def-2');
        await expectLater(h.ensure(), invalid(contains('Pick one of')));
        final env = await h.ensure(definitionId: 'def-2');
        expect(env.definitionId, 'def-2');
      });
    });

    group('tool routing', () {
      Map<String, dynamic> cliJson() => {
        'kind': 'cli',
        'id': 'tool',
        'verbs': {
          'create': ['tool', 'create', '{name}'],
          'status': ['tool', 'status', '{name}'],
          'destroy': ['tool', 'destroy', '{name}'],
          'stop': ['tool', 'stop', '{name}'],
          'exec': ['tool', 'exec', '{service}', '{command}'],
          'list': ['tool', 'ls'],
        },
      };

      void reportReady() {
        h.tool['status'] = ok(
          jsonEncode({
            'state': 'ready',
            'endpoints': [
              {'role': 'app', 'url': 'https://fix.acme.test', 'primary': true},
              {'role': 'evil', 'url': 'https://attacker.example'},
            ],
          }),
        );
      }

      test('routes hostnames from status through the upstream', () async {
        File('$root/ca.crt').writeAsStringSync(testCaPem);
        reportReady();
        h.store(
          definitionJson(
            [cliJson()],
            extra: {
              'routing': {
                'mode': 'tool',
                'domain': 'acme.test',
                'upstream': '127.0.0.1:443',
                'tls': true,
                'caFile': '~/ca.crt',
              },
            },
          ),
        );
        final env = await h.ensure();
        expect(env.status, EnvironmentStatus.ready);
        final routes = h.routing.routes[env.id]!;
        expect(routes.keys, ['fix.acme.test']);
        final route = routes['fix.acme.test']!;
        expect((route.host, route.port), ('127.0.0.1', 443));
        expect(route.tlsContext, isNotNull);
        expect(env.endpoints.map((e) => e.role), ['app']);
      });

      test('create when the tool has none, nothing when it is ready', () async {
        reportReady();
        h.store(definitionJson([cliJson()]));
        await h.ensure();
        expect(h.commands.where((line) => line.contains('create')), isEmpty);
      });

      test('a tool that lost it goes through create', () async {
        final statuses = [
          failed(
            1,
            error: const EnvironmentError(
              code: 'env.not-found',
              message: 'No such env',
              exitCode: 1,
            ),
          ),
          ok(jsonEncode({'state': 'ready'})),
        ];
        h.runner.handler = (call) => call.argv.contains('status')
            ? (statuses.length > 1 ? statuses.removeAt(0) : statuses.first)
            : h.answer(call);
        h.store(
          definitionJson([
            {
              ...cliJson(),
              'statusMap': {
                'state': [
                  {'state': 'ready'},
                ],
                'missingErrorCodes': ['env.not-found'],
              },
            },
          ]),
        );
        await h.ensure();
        expect(h.commands, contains('tool create fix-space-1'));
      });
    });
  });

  group('one mutation at a time', () {
    test('concurrent ensures share one start and one result', () async {
      h.store(definitionJson([composeJson()]));
      final results = await Future.wait([h.ensure(), h.ensure(), h.ensure()]);
      expect(results.map((env) => env.id).toSet(), hasLength(1));
      expect(h.commands, ['compose up -d db site']);
    });

    test('a stop waits for the start in flight', () async {
      final held = Completer<void>();
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('up')) {
          await held.future;
        }
      };
      h.store(definitionJson([composeJson()]));
      final starting = h.ensure();
      await h.until(() => h.commands.isNotEmpty);
      final stopping = h.service.stop('ws-a', 'space-1', by: principal);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.commands, ['compose up -d db site']);
      held.complete();
      await starting;
      await stopping;
      expect(row().status, EnvironmentStatus.stopped);
    });

    test('a second space does not wait for the first', () async {
      h.addSpace('space-2');
      final held = Completer<void>();
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('up') &&
            call.workingDirectory!.endsWith('space-1')) {
          await held.future;
        }
      };
      h.store(definitionJson([composeJson()]));
      final first = h.ensure();
      await h.until(() => h.commands.isNotEmpty);
      final second = await h.ensure(space: 'space-2');
      expect(second.status, EnvironmentStatus.ready);
      held.complete();
      await first;
    });
  });

  group('options', () {
    setUp(() {
      h.store(
        definitionJson(
          [
            taskJson('t', ['start']),
          ],
          extra: {
            'options': [
              {
                'key': 'dns',
                'type': 'bool',
                'default': true,
                'agentDefault': false,
              },
              {
                'key': 'mode',
                'type': 'enum',
                'values': ['web', 'desktop'],
                'default': 'web',
              },
              {
                'key': 'services',
                'type': 'multi',
                'values': ['a', 'b'],
                'default': ['a'],
              },
            ],
          },
        ),
      );
    });

    test('a person gets default', () async {
      expect((await h.ensure()).options, {
        'dns': true,
        'mode': 'web',
        'services': ['a'],
      });
    });

    test('an agent gets agentDefault', () async {
      final env = await h.ensure(by: const AgentPrincipal('agent-1'));
      expect(env.options['dns'], isFalse);
      expect(env.options['mode'], 'web');
    });

    test('given values win', () async {
      final env = await h.ensure(options: {'mode': 'desktop'});
      expect(env.options['mode'], 'desktop');
    });

    test('an unknown key is refused', () async {
      await expectLater(
        h.ensure(options: {'nope': 1}),
        invalid(contains('options.nope')),
      );
      expect(h.environments.rows, isEmpty);
    });

    test('an enum value outside values is refused', () async {
      await expectLater(
        h.ensure(options: {'mode': 'tv'}),
        invalid(contains('options.mode')),
      );
    });

    test('so is a multi value', () async {
      await expectLater(
        h.ensure(
          options: {
            'services': ['a', 'z'],
          },
        ),
        invalid(contains('options.services')),
      );
    });

    test('a stopped environment keeps its options', () async {
      await h.ensure(options: {'mode': 'desktop'});
      await h.service.stop('ws-a', 'space-1', by: principal);
      expect((await h.ensure()).options['mode'], 'desktop');
    });
  });

  group('fork PRs', () {
    late Map<String, dynamic> json;

    setUp(() {
      h.addSpace('fork', prNumber: 7, prRepo: 'acme/shop', isFork: true);
    });

    void policy(String value) {
      json = definitionJson(
        [webJson()],
        extra: {
          'policy': {'forkPrs': value},
        },
      );
      h.store(json);
    }

    test('deny refuses', () async {
      policy('deny');
      await expectLater(h.ensure(space: 'fork'), driverError('fork-denied'));
      expect(h.terminals.sessions, isEmpty);
    });

    test('approval refuses a member', () async {
      policy('approval');
      await expectLater(
        h.ensure(space: 'fork'),
        driverError('fork-needs-admin'),
      );
    });

    test('approval lets an admin start it', () async {
      policy('approval');
      h.admin = true;
      expect((await h.ensure(space: 'fork')).status, EnvironmentStatus.ready);
    });

    test('rig uses the rig host and nothing on the host', () async {
      final rig = FakeRigHost();
      h = ServiceHarness(root, rigHost: rig);
      h.addSpace('fork', prNumber: 7, prRepo: 'acme/shop', isFork: true);
      h.store(
        definitionJson(
          [
            composeJson(),
            taskJson('migrate', ['start']),
          ],
          extra: {
            'policy': {'forkPrs': 'rig'},
          },
        ),
      );
      final env = await h.ensure(space: 'fork');
      expect(env.status, EnvironmentStatus.ready);
      expect(env.placement, 'rig');
      expect(env.rigId, 'rig-env');
      expect(rig.calls, ['start']);
      expect(rig.execs, [
        ['tool', 'migrate'],
      ]);
      expect(h.commands, isEmpty);
    });

    test('rig with no rig host is a clear error', () async {
      h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'policy': {'forkPrs': 'rig'},
          },
        ),
      );
      await expectLater(
        h.ensure(space: 'fork'),
        driverError('rig-unavailable'),
      );
    });

    test('placement rig with no rig host is a clear error too', () async {
      h.store(definitionJson([composeJson()], extra: {'placement': 'rig'}));
      await expectLater(h.ensure(), driverError('rig-unavailable'));
    });

    test('seedFiles are never copied', () async {
      File('${h.sourcePath}/.env.local').writeAsStringSync('SECRET=1');
      h.admin = true;
      h.store(
        definitionJson(
          [webJson()],
          extra: {
            'seedFiles': ['.env.local'],
            'policy': {'forkPrs': 'approval'},
          },
        ),
      );
      await h.ensure(space: 'fork');
      expect(File('$root/worktrees/fork/.env.local').existsSync(), isFalse);
    });

    test('compose refuses policy findings for a fork', () async {
      h.model = {
        'services': <String, dynamic>{
          'db': {'privileged': true},
        },
      };
      h.admin = true;
      h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'policy': {'forkPrs': 'approval'},
          },
        ),
      );
      await expectLater(
        h.ensure(space: 'fork'),
        driverError('compose-policy-refused'),
      );
    });
  });

  group('maxRunning', () {
    setUp(() {
      h.addSpace('space-2');
      h.addSpace('space-3');
      h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'policy': {'maxRunning': 2},
          },
        ),
      );
    });

    test('names the least recently used, and starts nothing', () async {
      await h.ensure();
      h.now = h.now.add(const Duration(minutes: 1));
      await h.ensure(space: 'space-2');
      h.runner.calls.clear();

      await expectLater(
        h.ensure(space: 'space-3'),
        throwsA(
          isA<EnvironmentDriverException>()
              .having((e) => e.error.code, 'code', 'max-running')
              .having(
                (e) => e.error.message,
                'message',
                contains('fix-space-1'),
              ),
        ),
      );
      expect(h.commands, isEmpty);
      expect(h.environments.rows, hasLength(2));
    });

    test('parallel starts can\'t both take the last slot', () async {
      await h.ensure();
      final results = await Future.wait([
        h.ensure(space: 'space-2').then((_) => 'ok', onError: (_) => 'no'),
        h.ensure(space: 'space-3').then((_) => 'ok', onError: (_) => 'no'),
      ]);
      expect(results, unorderedEquals(['ok', 'no']));
    });

    test('a stopped one does not count', () async {
      await h.ensure();
      await h.ensure(space: 'space-2');
      await h.service.stop('ws-a', 'space-1', by: principal);
      expect(
        (await h.ensure(space: 'space-3')).status,
        EnvironmentStatus.ready,
      );
    });

    test('restarting its own does not count', () async {
      await h.ensure();
      await h.ensure(space: 'space-2');
      await h.service.stop('ws-a', 'space-1', by: principal);
      expect((await h.ensure()).status, EnvironmentStatus.ready);
    });
  });

  group('worktree tasks', () {
    late String worktree;

    setUp(() => worktree = '$root/worktrees/space-1');

    WorktreeTaskContext context({
      bool isForkPr = false,
      String? spaceId = 'space-1',
    }) => WorktreeTaskContext(
      workspaceId: 'ws-a',
      repoId: 'repo-app',
      worktreePath: worktree,
      sourcePath: h.sourcePath,
      spaceId: spaceId,
      isForkPr: isForkPr,
    );

    test('a fork gets no seed files when the caller does not say so', () async {
      h.addSpace('fork', prNumber: 7, prRepo: 'acme/shop', isFork: true);
      final forkTree = '$root/worktrees/fork';
      File('${h.sourcePath}/.env.local').writeAsStringSync('KEY=1');
      h.store(
        definitionJson(
          [
            taskJson('deps', ['provision']),
          ],
          extra: {
            'seedFiles': ['.env.local'],
            'policy': {'forkPrs': 'deny'},
          },
        ),
      );
      await h.service.runProvision(
        WorktreeTaskContext(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          worktreePath: forkTree,
          sourcePath: h.sourcePath,
          spaceId: 'fork',
        ),
      );
      expect(File('$forkTree/.env.local').existsSync(), isFalse);
      expect(h.commands, isEmpty);
    });

    test('archive still runs for a deleted space on a branch', () async {
      h.store(
        definitionJson([
          taskJson('clean', ['archive']),
        ]),
      );
      await h.service.runArchive(
        WorktreeTaskContext(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          worktreePath: worktree,
          sourcePath: h.sourcePath,
          spaceId: 'gone',
        ),
      );
      expect(h.commands, ['tool clean']);
    });

    test('archive is skipped for a deleted PR space', () async {
      h.store(
        definitionJson([
          taskJson('clean', ['archive']),
        ]),
      );
      await h.service.runArchive(
        WorktreeTaskContext(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          worktreePath: worktree,
          sourcePath: h.sourcePath,
          spaceId: 'gone',
          isPrWorktree: true,
        ),
      );
      expect(h.commands, isEmpty);
    });

    test('seed files, then provision tasks, with no environment', () async {
      File('${h.sourcePath}/.env.local').writeAsStringSync('KEY=1');
      var seededFirst = false;
      h.runner.beforeAnswer = (call) async {
        seededFirst = File('$worktree/.env.local').existsSync();
      };
      h.store(
        definitionJson(
          [
            taskJson('deps', ['provision']),
          ],
          extra: {
            'seedFiles': ['.env.local'],
          },
        ),
      );
      expect(await h.service.hasProvisionTasks('ws-a', 'repo-app'), isTrue);
      await h.service.runProvision(context());
      expect(h.commands, ['tool deps']);
      expect(seededFirst, isTrue);
      expect(h.environments.rows, isEmpty);
    });

    test('nothing to do says so', () async {
      expect(await h.service.hasProvisionTasks('ws-a', 'repo-app'), isFalse);
      await h.service.runProvision(context());
    });

    test('sees only the 7.1 variables', () async {
      h.store(
        definitionJson(
          [
            taskJson('deps', ['provision']),
          ],
          extra: {
            'env': {'SECRET_URL': 'x'},
          },
        ),
      );
      await h.service.runProvision(context());
      final environment = h.runner.calls.single.environment;
      expect(environment, {
        'CC_WORKSPACE_PATH': worktree,
        'CC_ROOT_PATH': h.sourcePath,
        'CC_SPACE_ID': 'space-1',
        'CC_SPACE_NAME': 'Space space-1',
        'CC_SPACE_KIND': 'space',
        'CC_REPO_NAME': 'Shop',
        'NO_COLOR': '1',
      });
    });

    test('runs in the worktree, recorded against the repo', () async {
      h.store(
        definitionJson([
          taskJson('deps', ['provision']),
        ]),
      );
      await h.service.runProvision(context());
      expect(h.runner.calls.single.workingDirectory, worktree);
      final run = h.runs.runs.values.single;
      expect(run.repoId, 'repo-app');
      expect(run.environmentId, isNull);
    });

    test('a failure throws WorktreeTaskException', () async {
      h.tool['deps'] = failed(1, stderr: 'lockfile out of date');
      h.store(
        definitionJson([
          taskJson('deps', ['provision']),
        ]),
      );
      await expectLater(
        h.service.runProvision(context()),
        throwsA(
          isA<WorktreeTaskException>().having(
            (e) => e.message,
            'message',
            contains('lockfile out of date'),
          ),
        ),
      );
    });

    test('a task for another role leaves this repo alone', () async {
      h.store(
        definitionJson(
          [
            taskJson(
              'deps',
              ['provision'],
              extra: {
                'cwd': {'role': 'e2e'},
              },
            ),
          ],
          repos: {
            'app': {'repoId': 'repo-app', 'anchor': true},
            'e2e': {'repoId': 'repo-e2e'},
          },
        ),
      );
      await h.service.runProvision(context());
      expect(h.commands, isEmpty);
    });

    test('one owner per repo in saveDefinition', () async {
      await h.service.saveDefinition(
        workspaceId: 'ws-a',
        definition: definitionJson([
          taskJson('deps', ['provision']),
        ]),
        by: principal,
      );
      await expectLater(
        h.service.saveDefinition(
          workspaceId: 'ws-a',
          definition: definitionJson([
            taskJson('more', ['archive']),
          ]),
          by: principal,
        ),
        invalid(contains('repo-app')),
      );
    });

    test('re-saving the owner is fine', () async {
      final record = await h.service.saveDefinition(
        workspaceId: 'ws-a',
        definition: definitionJson([
          taskJson('deps', ['provision']),
        ]),
        by: principal,
      );
      await h.service.saveDefinition(
        workspaceId: 'ws-a',
        definitionId: record.id,
        definition: definitionJson([
          taskJson('deps2', ['provision']),
        ]),
        by: principal,
      );
    });

    test('one owner per repo at run time', () async {
      final json = definitionJson([
        taskJson('deps', ['provision']),
      ]);
      h
        ..store(json, id: 'def-1')
        ..store(json, id: 'def-2');
      await expectLater(
        h.service.runProvision(context()),
        throwsA(isA<WorktreeTaskException>()),
      );
      expect(h.commands, isEmpty);
    });

    test('an invalid row fails provisioning and runs nothing', () async {
      h.store({
        ...definitionJson([
          taskJson('deps', ['provision']),
        ]),
        'contract': 99,
      });
      await expectLater(
        h.service.runProvision(context()),
        throwsA(
          isA<WorktreeTaskException>().having(
            (e) => e.message,
            'message',
            contains('contract'),
          ),
        ),
      );
      expect(h.commands, isEmpty);
    });

    test('a seed escape is a WorktreeTaskException', () async {
      Link('${h.sourcePath}/.env.local').createSync('/etc/hosts');
      h.store(
        definitionJson(
          [
            taskJson('deps', ['provision']),
          ],
          extra: {
            'seedFiles': ['.env.local'],
          },
        ),
      );
      await expectLater(
        h.service.runProvision(context()),
        throwsA(isA<WorktreeTaskException>()),
      );
    });

    test('forks skip provision and archive tasks and seed files', () async {
      File('${h.sourcePath}/.env.local').writeAsStringSync('KEY=1');
      h.store(
        definitionJson(
          [
            taskJson('deps', ['provision']),
            taskJson('clean', ['archive']),
          ],
          extra: {
            'seedFiles': ['.env.local'],
            'policy': {'forkPrs': 'approval'},
          },
        ),
      );
      await h.service.runProvision(context(isForkPr: true));
      await h.service.runArchive(context(isForkPr: true));
      expect(h.commands, isEmpty);
      expect(File('$worktree/.env.local').existsSync(), isFalse);
    });

    test('forks under rig run them in the rig', () async {
      final rig = FakeRigHost();
      h = ServiceHarness(root, rigHost: rig);
      h.store(
        definitionJson(
          [
            taskJson('deps', ['provision']),
          ],
          extra: {
            'policy': {'forkPrs': 'rig'},
          },
        ),
      );
      await h.service.runProvision(context(isForkPr: true));
      expect(rig.execs, [
        ['tool', 'deps'],
      ]);
      expect(h.commands, isEmpty);
    });

    test('forks under rig with no rig host fail clearly', () async {
      h.store(
        definitionJson(
          [
            taskJson('deps', ['provision']),
          ],
          extra: {
            'policy': {'forkPrs': 'rig'},
          },
        ),
      );
      await expectLater(
        h.service.runProvision(context(isForkPr: true)),
        throwsA(
          isA<WorktreeTaskException>().having(
            (e) => e.message,
            'message',
            contains('rig'),
          ),
        ),
      );
    });

    test('archive runs its tasks and never throws', () async {
      h.tool['clean'] = failed(1, stderr: 'nope');
      h.store(
        definitionJson([
          taskJson('clean', ['archive']),
        ]),
      );
      await h.service.runArchive(context());
      expect(h.commands, ['tool clean']);
      expect(h.runs.runs.values.single.status, EnvironmentRunStatus.failed);
    });

    test('archive survives even a broken directory', () async {
      h.directory.repos.remove('ws-a');
      await h.service.runArchive(context());
    });

    test('archive survives a space that went first', () async {
      h.directory.spaces.remove('space-1');
      h.store(
        definitionJson([
          taskJson('clean', ['archive']),
        ]),
      );
      await h.service.runArchive(context());
      expect(h.commands, ['tool clean']);
    });

    test('a null space is a throwaway test', () async {
      h.store(
        definitionJson([
          taskJson('deps', ['provision']),
        ]),
      );
      await h.service.runProvision(context(spaceId: null));
      expect(h.commands, ['tool deps']);
    });
  });

  group('beforeRelease', () {
    test('stops, destroys, releases, removes, then returns', () async {
      h.store(definitionJson([composeJson(), webJson()]));
      final env = await h.ensure();
      final state = Directory('$root/data/ws-a/environments/${env.id}');
      expect(state.existsSync(), isTrue);
      final session = h.terminals.last;

      await h.service.beforeRelease('ws-a', 'space-1');

      expect(session.exit.isCompleted, isTrue);
      expect(
        h.commands,
        contains('compose down -v --remove-orphans --rmi local'),
      );
      expect(h.leases.leases, isEmpty);
      expect(state.existsSync(), isFalse);
      expect(h.environments.rows, isEmpty);
      expect(h.routing.routes[env.id], isNull);
    });

    test('idempotent, and fine with nothing there', () async {
      await h.service.beforeRelease('ws-a', 'space-1');
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      await h.service.beforeRelease('ws-a', 'space-1');
      await h.service.beforeRelease('ws-a', 'space-1');
      expect(h.environments.rows, isEmpty);
    });

    test('never throws, and still releases what it can', () async {
      h.store(definitionJson([composeJson()]));
      final env = await h.ensure();
      h.runner.handler = (call) => call.argv.contains('down')
          ? failed(1, stderr: 'daemon gone')
          : h.answer(call);
      await h.service.beforeRelease('ws-a', 'space-1');
      expect(h.environments.rows, isEmpty);
      expect(h.leases.leases, isEmpty);
      expect(h.routing.routes[env.id], isNull);
    });

    test('an invalid definition still loses CC\'s own resources', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.store({
        ...definitionJson([composeJson()]),
        'contract': 99,
      });
      await h.service.beforeRelease('ws-a', 'space-1');
      expect(h.environments.rows, isEmpty);
      expect(
        h.runner.calls.any(
          (call) => call.argv.contains('down') && !call.argv.contains('-f'),
        ),
        isTrue,
      );
    });

    test('a tool\'s destroy runs when the definition is sound', () async {
      h.tool['status'] = ok(jsonEncode({'state': 'ready'}));
      h.store(
        definitionJson([
          {
            'kind': 'cli',
            'id': 'tool',
            'verbs': {
              'create': ['tool', 'create'],
              'status': ['tool', 'status'],
              'destroy': ['tool', 'destroy', '{name}'],
            },
          },
        ]),
      );
      await h.ensure();
      await h.service.beforeRelease('ws-a', 'space-1');
      expect(h.commands.last, 'tool destroy fix-space-1');
    });

    test('in another workspace it does nothing', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      await h.service.beforeRelease('ws-b', 'space-1');
      expect(h.environments.rows, hasLength(1));
      expect(h.leases.leases, hasLength(1));
    });

    test('waits for a start in flight', () async {
      final held = Completer<void>();
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('up')) {
          await held.future;
        }
      };
      h.store(definitionJson([composeJson()]));
      final starting = h.ensure();
      await h.until(() => h.commands.isNotEmpty);
      final releasing = h.service.beforeRelease('ws-a', 'space-1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      held.complete();
      await starting;
      await releasing;
      expect(h.environments.rows, isEmpty);
    });
  });

  group('lifecycle listeners', () {
    SpaceProvisioningChanged provisioned(String space) =>
        SpaceProvisioningChanged(
          workspaceId: 'ws-a',
          spaceId: space,
          status: SpaceProvisioningStatus.ready,
          occurredAt: h.now,
        );

    PrHeadChanged headMoved() => PrHeadChanged(
      repoOwner: 'acme',
      repoName: 'shop',
      prNumber: 7,
      prTitle: 'Fix',
      previousHeadSha: 'a',
      headSha: 'b',
      workspaceId: 'ws-a',
      occurredAt: h.now,
    );

    group('autoCreate', () {
      void definition(String mode) => h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'policy': {'autoCreate': mode},
          },
        ),
      );

      test('allSpaces starts it', () async {
        definition('allSpaces');
        await h.service.start(runRecovery: false);
        h.events.publish(provisioned('space-1'));
        await h.until(
          () =>
              h.environments.rows.isNotEmpty &&
              row().status == EnvironmentStatus.ready,
        );
      });

      test('prSpaces leaves a plain space alone', () async {
        definition('prSpaces');
        await h.service.start(runRecovery: false);
        h.events.publish(provisioned('space-1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(h.environments.rows, isEmpty);
      });

      test('prSpaces starts a PR space', () async {
        definition('prSpaces');
        h.addSpace('pr', prNumber: 7, prRepo: 'acme/shop', kind: 'pr');
        await h.service.start(runRecovery: false);
        h.events.publish(provisioned('pr'));
        await h.until(() => h.environments.rows.isNotEmpty);
      });

      test('off does nothing', () async {
        definition('off');
        await h.service.start(runRecovery: false);
        h.events.publish(provisioned('space-1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(h.environments.rows, isEmpty);
      });

      test('only on ready', () async {
        definition('allSpaces');
        await h.service.start(runRecovery: false);
        h.events.publish(
          SpaceProvisioningChanged(
            workspaceId: 'ws-a',
            spaceId: 'space-1',
            status: SpaceProvisioningStatus.values.firstWhere(
              (status) => status != SpaceProvisioningStatus.ready,
            ),
            occurredAt: h.now,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(h.environments.rows, isEmpty);
      });

      test('a refused start is a log line, not a crash', () async {
        h.addSpace('fork', prNumber: 7, prRepo: 'acme/shop', isFork: true);
        h.store(
          definitionJson(
            [composeJson()],
            extra: {
              'policy': {'autoCreate': 'allSpaces', 'forkPrs': 'deny'},
            },
          ),
        );
        await h.service.start(runRecovery: false);
        h.events.publish(provisioned('fork'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(h.environments.rows, isEmpty);
      });
    });

    group('PR head', () {
      setUp(() {
        h.addSpace('pr', prNumber: 7, prRepo: 'acme/shop', kind: 'pr');
        h.store(
          definitionJson([
            composeJson(),
            taskJson(
              'migrate',
              ['change'],
              extra: {
                'onChange': ['db/**'],
              },
            ),
            taskJson(
              'other',
              ['change'],
              extra: {
                'onChange': ['docs/**'],
              },
            ),
            webJson(
              extra: {
                'restartOn': ['vite.config.ts'],
              },
            ),
          ]),
        );
      });

      test('syncs, re-plans, runs matches, restarts matches', () async {
        await h.ensure(space: 'pr');
        await h.service.start(runRecovery: false);
        h.runner.calls.clear();
        final before = h.terminals.sessions.length;
        h.changedPaths = ['db/001.sql', 'vite.config.ts'];
        (h.model['services'] as Map)['extra'] = {
          'ports': [
            {'target': 9000, 'protocol': 'tcp'},
          ],
        };
        h.events.publish(headMoved());
        await h.until(() => h.terminals.sessions.length > before);
        expect(h.commands, contains('tool migrate'));
        expect(h.commands, isNot(contains('tool other')));
        expect(h.commands.first, startsWith('compose up -d --build'));
        await h.until(() => row('pr').ports.containsKey('extra.9000'));
      });

      test('a worktree that isn\'t clean is left alone', () async {
        await h.ensure(space: 'pr');
        await h.service.start(runRecovery: false);
        h.runner.calls.clear();
        h.changedPaths = null;
        h.events.publish(headMoved());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(h.commands, isEmpty);
      });

      test('followPrHead: false ignores it', () async {
        h.store(
          definitionJson(
            [composeJson()],
            extra: {
              'policy': {'followPrHead': false},
            },
          ),
        );
        await h.ensure(space: 'pr');
        await h.service.start(runRecovery: false);
        h.runner.calls.clear();
        h.changedPaths = ['x'];
        h.events.publish(headMoved());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(h.commands, isEmpty);
      });

      test('another PR is not this one', () async {
        await h.ensure();
        await h.service.start(runRecovery: false);
        h.runner.calls.clear();
        h.events.publish(headMoved());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(h.commands, isEmpty);
      });

      test('no sync callback degrades to a log', () async {
        h = ServiceHarness(root)..withSync = false;
        h.addSpace('pr', prNumber: 7, prRepo: 'acme/shop', kind: 'pr');
        h.store(definitionJson([composeJson()]));
        await h.ensure(space: 'pr');
        await h.service.start(runRecovery: false);
        addTearDown(h.service.stopListening);
        h.runner.calls.clear();
        h.events.publish(headMoved());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(h.commands, isEmpty);
      });
    });

    group('stopping when unused', () {
      Map<String, dynamic> idle(int minutes) => definitionJson(
        [composeJson()],
        extra: {
          'policy': {'idleStopMinutes': minutes},
        },
      );

      Map<String, dynamic> destructive() => definitionJson(
        [
          {
            'kind': 'cli',
            'id': 'tool',
            'keepsDataOnStop': false,
            'verbs': {
              'create': ['tool', 'create'],
              'status': ['tool', 'status'],
              'destroy': ['tool', 'destroy'],
              'stop': ['tool', 'stop'],
            },
          },
        ],
        extra: {
          'policy': {'idleStopMinutes': 1},
        },
      );

      test('SpaceArchived stops it', () async {
        h.store(definitionJson([composeJson()]));
        await h.ensure();
        await h.service.start(runRecovery: false);
        h.events.publish(
          SpaceArchived(
            spaceId: 'space-1',
            workspaceId: 'ws-a',
            occurredAt: h.now,
          ),
        );
        await h.until(() => row().status == EnvironmentStatus.stopped);
      });

      test('SpaceArchived leaves what can\'t stop, and says so', () async {
        h.tool['status'] = ok(jsonEncode({'state': 'ready'}));
        h.store(destructive());
        await h.ensure();
        await h.service.start(runRecovery: false);
        h.events.publish(
          SpaceArchived(
            spaceId: 'space-1',
            workspaceId: 'ws-a',
            occurredAt: h.now,
          ),
        );
        await h.until(() => row().warnings.isNotEmpty);
        expect(row().warnings.single, contains('archived'));
        expect(row().status, EnvironmentStatus.ready);
      });

      test('idle stop after idleStopMinutes', () async {
        h.store(idle(30));
        await h.ensure();
        h.now = h.now.add(const Duration(minutes: 29));
        await h.service.runMaintenance();
        expect(row().status, EnvironmentStatus.ready);
        h.now = h.now.add(const Duration(minutes: 2));
        await h.service.runMaintenance();
        expect(row().status, EnvironmentStatus.stopped);
      });

      test('recent activity keeps it up', () async {
        h.store(idle(30));
        await h.ensure();
        h.now = h.now.add(const Duration(hours: 1));
        h.activity = h.now.subtract(const Duration(minutes: 5));
        await h.service.runMaintenance();
        expect(row().status, EnvironmentStatus.ready);
      });

      test('a watching client keeps it up', () async {
        h.store(idle(30));
        await h.ensure();
        final subscription = h.service.watch('ws-a', 'space-1').listen((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 5));
        h.now = h.now.add(const Duration(hours: 1));
        await h.service.runMaintenance();
        expect(row().status, EnvironmentStatus.ready);
        await subscription.cancel();
      });

      test('idleStopMinutes: 0 means never', () async {
        h.store(idle(0));
        await h.ensure();
        h.now = h.now.add(const Duration(days: 30));
        await h.service.runMaintenance();
        expect(row().status, EnvironmentStatus.ready);
      });

      test('never when stopping loses data', () async {
        h.tool['status'] = ok(jsonEncode({'state': 'ready'}));
        h.store(destructive());
        await h.ensure();
        h.now = h.now.add(const Duration(days: 1));
        await h.service.runMaintenance();
        expect(row().status, EnvironmentStatus.ready);
        expect(h.commands, isNot(contains('tool stop')));
      });

      test('never while an app runs', () async {
        h.store(
          definitionJson(
            [
              webJson(),
              {
                'kind': 'app',
                'id': 'desktop',
                'command': ['tool', 'open'],
              },
            ],
            extra: {
              'policy': {'idleStopMinutes': 1},
            },
          ),
        );
        await h.ensure();
        await h.service.start(runRecovery: false);
        await h.service.launchApp('ws-a', 'space-1', 'desktop', by: principal);
        await h.until(() => component('desktop').state == 'running');
        h.now = h.now.add(const Duration(days: 1));
        await h.service.runMaintenance();
        expect(row().status, EnvironmentStatus.ready);
      });
    });

    group('repo set changes', () {
      void withRoles(Map<String, dynamic> roles) {
        final worktree = '$root/worktrees/e2e';
        Directory(worktree).createSync(recursive: true);
        File('$worktree/compose.yaml').writeAsStringSync('services: {}');
        h.addSpace(
          'multi',
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
        h.store(definitionJson([composeJson()], repos: roles));
      }

      test('dropping a required role destroys', () async {
        withRoles({
          'app': {'repoId': 'repo-app', 'anchor': true},
          'e2e': {'repoId': 'repo-e2e', 'required': true},
        });
        await h.ensure(space: 'multi');
        h.addSpace('multi');
        await h.service.runMaintenance();
        expect(h.environments.rows, isEmpty);
      });

      test('dropping the last anchor destroys', () async {
        withRoles({
          'e2e': {'repoId': 'repo-e2e', 'anchor': true},
          'app': {'repoId': 'repo-app'},
        });
        await h.ensure(space: 'multi');
        h.addSpace('multi');
        await h.service.runMaintenance();
        expect(h.environments.rows, isEmpty);
      });

      test('dropping another role asks for a Recreate', () async {
        withRoles({
          'app': {'repoId': 'repo-app', 'anchor': true},
          'e2e': {'repoId': 'repo-e2e'},
        });
        await h.ensure(space: 'multi');
        h.addSpace('multi');
        await h.service.runMaintenance();
        expect(row('multi').status, EnvironmentStatus.degraded);
        expect(row('multi').needsRecreate, isTrue);
      });

      test('provisioning finishing notices it too', () async {
        withRoles({
          'app': {'repoId': 'repo-app', 'anchor': true},
          'e2e': {'repoId': 'repo-e2e', 'required': true},
        });
        await h.ensure(space: 'multi');
        await h.service.start(runRecovery: false);
        h.addSpace('multi');
        h.events.publish(provisioned('multi'));
        await h.until(() => h.environments.rows.isEmpty);
      });
    });

    test('SpaceDeleted tears down', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      await h.service.start(runRecovery: false);
      h.events.publish(
        SpaceDeleted(
          spaceId: 'space-1',
          workspaceId: 'ws-a',
          occurredAt: h.now,
        ),
      );
      await h.until(() => h.environments.rows.isEmpty);
    });

    test('a process crash degrades, and recovery clears it', () async {
      h.store(definitionJson([webJson()]));
      await h.ensure();
      await h.service.start(runRecovery: false);
      final exited = <EnvironmentProcessExited>[];
      h.events.on<EnvironmentProcessExited>().listen(exited.add);
      h.terminals.last.exit.complete(1);
      await h.until(() => row().status == EnvironmentStatus.degraded);
      await h.until(() => row().status == EnvironmentStatus.ready);
      expect(exited.single.componentId, 'web');
      expect(component('web').restarts, 1);
    });

    test('events report status and readiness', () async {
      final statuses = <String>[];
      final ready = <EnvironmentReady>[];
      h.events.on<EnvironmentStatusChanged>().listen(
        (event) => statuses.add(event.status),
      );
      h.events.on<EnvironmentReady>().listen(ready.add);
      h.store(definitionJson([webJson()]));
      await h.ensure();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(statuses, ['creating', 'ready']);
      expect(ready.single.url, contains('.localhost:7355'));
    });
  });

  group('recover', () {
    SpaceEnvironment stored(
      EnvironmentStatus status, {
      String id = 'env-1',
      String space = 'space-1',
      List<EnvironmentComponentState> components = const [],
      Map<String, int> ports = const {},
    }) {
      final row = SpaceEnvironment(
        id: id,
        workspaceId: 'ws-a',
        spaceId: space,
        definitionId: 'def-1',
        name: 'shop',
        status: status,
        components: components,
        ports: ports,
        createdBy: 'user:member',
        createdAt: h.now,
        lastUsedAt: h.now,
      );
      h.environments.rows[id] = row;
      return row;
    }

    String container(String env, String ws, String space) => jsonEncode({
      'ID': 'c-$env',
      'Names': 'cc-$env-web-1',
      'State': 'running',
      'Labels': 'cc.env=$env,cc.workspace=$ws,cc.space=$space',
    });

    test('a ready environment gets its processes back', () async {
      h.store(definitionJson([webJson()]));
      stored(EnvironmentStatus.ready, ports: {'web': 42000});
      await h.service.recover();
      expect(h.terminals.sessions, hasLength(1));
      expect(h.terminals.last.arguments, ['dev', '--port', '42000']);
    });

    test('routes come back, on the router\'s new port', () async {
      h.store(definitionJson([webJson()]));
      final row = stored(EnvironmentStatus.ready, ports: {'web': 42000});
      h.environments.rows['env-1'] = row.copyWith(
        endpoints: [
          EnvironmentEndpoint(
            role: 'web',
            url: 'http://web--shop--shop.localhost:9999',
            hostPort: 42000,
          ),
        ],
      );
      await h.service.recover();
      expect(
        h.environments.rows['env-1']!.endpoints.single.url,
        'http://web--shop--shop.localhost:7355',
      );
      expect(h.routing.routes['env-1'], isNotEmpty);
    });

    test('a process someone stopped stays stopped', () async {
      h.store(definitionJson([webJson()]));
      stored(
        EnvironmentStatus.ready,
        ports: {'web': 42000},
        components: [
          EnvironmentComponentState(
            id: 'web',
            kind: 'process',
            state: 'stopped',
          ),
        ],
      );
      await h.service.recover();
      expect(h.terminals.sessions, isEmpty);
    });

    test('apps stay down', () async {
      h.store(
        definitionJson([
          {
            'kind': 'app',
            'id': 'desktop',
            'command': ['tool', 'open'],
          },
        ]),
      );
      stored(
        EnvironmentStatus.ready,
        components: [
          EnvironmentComponentState(
            id: 'desktop',
            kind: 'app',
            state: 'running',
          ),
        ],
      );
      await h.service.recover();
      expect(h.terminals.sessions, isEmpty);
      expect(h.environments.rows['env-1']!.components.single.state, 'closed');
    });

    test('survivors are reaped first', () async {
      h.store(definitionJson([webJson()]));
      stored(EnvironmentStatus.ready, ports: {'web': 42000});
      final pids = File('$root/data/ws-a/environments/env-1/pids/web')
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode({'group': 4242, 'startTime': 'then'}));
      h.groups
        ..startTimes[4242] = 'then'
        ..groups[4242] = [4242];
      await h.service.recover();
      expect(h.groups.signals.first.$1, 4242);
      expect(pids.existsSync(), isTrue, reason: 'the new process wrote it');
    });

    test('an invalid row fails and runs nothing', () async {
      h.store({
        ...definitionJson([webJson()]),
        'contract': 99,
      });
      stored(EnvironmentStatus.ready, ports: {'web': 42000});
      await h.service.recover();
      expect(h.terminals.sessions, isEmpty);
      final row = h.environments.rows['env-1']!;
      expect(row.status, EnvironmentStatus.failed);
      expect(row.lastError?.message, contains('contract'));
    });

    test('mid-flight rows settle', () async {
      h.store(definitionJson([webJson()]));
      stored(EnvironmentStatus.starting, id: 'a');
      stored(EnvironmentStatus.stopping, id: 'b');
      await h.service.recover();
      expect(h.environments.rows['a']!.status, EnvironmentStatus.failed);
      expect(h.environments.rows['a']!.lastError?.code, 'interrupted');
      expect(h.environments.rows['b']!.status, EnvironmentStatus.stopped);
    });

    test('a row whose space is gone is torn down', () async {
      h.store(definitionJson([composeJson()]));
      h.addSpace('gone');
      stored(EnvironmentStatus.ready, space: 'gone', ports: {'web.80': 42000});
      h.directory.spaces.remove('gone');
      await h.service.recover();
      expect(h.environments.rows, isEmpty);
      expect(h.runner.calls.any((call) => call.argv.contains('down')), isTrue);
    });

    test('a tool in a space that is gone still gets its destroy', () async {
      h.store(
        definitionJson([
          {
            'kind': 'cli',
            'id': 'tool',
            'verbs': {
              'create': ['tool', 'create'],
              'status': ['tool', 'status'],
              'destroy': ['tool', 'destroy', '{name}'],
            },
          },
        ]),
      );
      h.addSpace('gone');
      stored(EnvironmentStatus.stopped, space: 'gone');
      h.directory.spaces.remove('gone');
      await h.service.recover();
      expect(h.commands, contains('tool destroy shop'));
    });

    test('a tool that no longer lists it means gone', () async {
      h.tool['ls'] = ok(jsonEncode(['other']));
      h.store(
        definitionJson([
          {
            'kind': 'cli',
            'id': 'tool',
            'verbs': {
              'create': ['tool', 'create'],
              'status': ['tool', 'status'],
              'destroy': ['tool', 'destroy'],
              'list': ['tool', 'ls'],
            },
          },
        ]),
      );
      stored(EnvironmentStatus.stopped);
      await h.service.recover();
      expect(h.environments.rows['env-1']!.status, EnvironmentStatus.gone);
    });

    group('orphans', () {
      test('of a space that no longer exists are destroyed', () async {
        h.tool['orphans'] = ok(container('env-9', 'ws-a', 'long-gone'));
        await h.service.recover();
        expect(
          h.runner.calls
              .where((call) => call.argv.contains('down'))
              .single
              .argv,
          contains('cc-env-9'),
        );
      });

      test('of a space that exists are left alone', () async {
        h.tool['orphans'] = ok(container('env-9', 'ws-a', 'space-1'));
        await h.service.recover();
        expect(
          h.runner.calls.where((call) => call.argv.contains('down')),
          isEmpty,
        );
      });

      test('of another server\'s workspace are left alone', () async {
        h.tool['orphans'] = ok(container('env-9', 'ws-elsewhere', 'any'));
        await h.service.recover();
        expect(
          h.runner.calls.where((call) => call.argv.contains('down')),
          isEmpty,
        );
      });

      test('a known environment is not an orphan', () async {
        h.store(definitionJson([composeJson()]));
        stored(EnvironmentStatus.stopped);
        h.tool['orphans'] = ok(container('env-1', 'ws-a', 'long-gone'));
        await h.service.recover();
        expect(
          h.runner.calls.where((call) => call.argv.contains('down')),
          isEmpty,
        );
      });

      test('Docker being down costs a log line', () async {
        h.tool['orphans'] = failed(1, stderr: 'no daemon');
        await h.service.recover();
      });
    });

    group('leases', () {
      EnvironmentLease lease(String ws, String space, int block) =>
          EnvironmentLease(
            block: block,
            firstPort: 42000 + block * 32,
            size: 32,
            workspaceId: ws,
            spaceId: space,
            definitionId: 'def-1',
            createdAt: h.now,
          );

      test('of a space that is gone are released', () async {
        h.leases.leases.add(lease('ws-a', 'long-gone', 0));
        await h.service.recover();
        expect(h.leases.leases, isEmpty);
      });

      test('of a live space stay, environment or not', () async {
        h.leases.leases.add(lease('ws-a', 'space-1', 0));
        await h.service.recover();
        expect(h.leases.leases, hasLength(1));
      });

      test('of a workspace that no longer exists are released', () async {
        h.leases.leases.add(lease('ws-elsewhere', 'any', 0));
        await h.service.recover();
        expect(h.leases.leases, isEmpty);
      });
    });

    test('interrupted runs are closed', () async {
      await h.service.recover();
      expect(h.runs.interruptedSweeps, unorderedEquals(['ws-a', 'ws-b']));
    });
  });

  group('status polling', () {
    Map<String, dynamic> cliJson() => definitionJson(
      [
        {
          'kind': 'cli',
          'id': 'tool',
          'verbs': {
            'create': ['tool', 'create'],
            'status': ['tool', 'status'],
            'destroy': ['tool', 'destroy'],
          },
        },
      ],
      extra: {
        'routing': {
          'mode': 'tool',
          'domain': 'acme.test',
          'upstream': '127.0.0.1:443',
        },
      },
    );

    int polls() =>
        h.runner.calls.where((call) => call.argv.contains('status')).length;

    setUp(() => h.tool['status'] = ok(jsonEncode({'state': 'ready'})));

    test('every 5 minutes when nobody watches', () async {
      h.store(cliJson());
      await h.ensure();
      await h.service.runMaintenance();
      final first = polls();
      h.now = h.now.add(const Duration(minutes: 4));
      await h.service.runMaintenance();
      expect(polls(), first);
      h.now = h.now.add(const Duration(minutes: 2));
      await h.service.runMaintenance();
      expect(polls(), first + 1);
    });

    test('every 10 s while watched', () async {
      h.store(cliJson());
      await h.ensure();
      final subscription = h.service.watch('ws-a', 'space-1').listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await h.service.runMaintenance();
      final first = polls();
      h.now = h.now.add(const Duration(seconds: 5));
      await h.service.runMaintenance();
      expect(polls(), first);
      h.now = h.now.add(const Duration(seconds: 6));
      await h.service.runMaintenance();
      expect(polls(), first + 1);
      await subscription.cancel();
    });

    test('watch can be cancelled at its first event', () async {
      h.store(cliJson());
      await h.ensure();
      final first = await h.service.watch('ws-a', 'space-1').first;
      expect(first.single.status, EnvironmentStatus.ready);
    });

    test('watch emits at once, on change, and not on a no-op', () async {
      h.store(cliJson());
      await h.ensure();
      final seen = <List<SpaceEnvironment>>[];
      final subscription = h.service.watch('ws-a', 'space-1').listen(seen.add);
      await h.until(() => seen.length == 1);

      await h.service.runMaintenance();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(seen, hasLength(1), reason: 'nothing changed');

      h.now = h.now.add(const Duration(minutes: 6));
      h.tool['status'] = ok(jsonEncode({'state': 'starting', 'detail': 'x'}));
      await h.service.runMaintenance();
      await h.until(() => seen.length > 1);
      expect(seen.last.single.status, EnvironmentStatus.degraded);
      await subscription.cancel();
    });

    test('endpoints outside the domain never land', () async {
      h.store(cliJson());
      await h.ensure();
      h.now = h.now.add(const Duration(minutes: 6));
      h.tool['status'] = ok(
        jsonEncode({
          'state': 'ready',
          'endpoints': [
            {'role': 'app', 'url': 'https://a.acme.test'},
            {'role': 'evil', 'url': 'https://attacker.example'},
          ],
        }),
      );
      await h.service.runMaintenance();
      expect(row().endpoints.map((e) => e.role), ['app']);
      expect(h.routing.routes[row().id]!.keys, ['a.acme.test']);
    });

    group('a create the tool refused', () {
      setUp(() {
        h.store(
          definitionJson([
            {
              'kind': 'cli',
              'id': 'tool',
              'verbs': {
                'create': ['tool', 'create'],
                'status': ['tool', 'status'],
                'destroy': ['tool', 'destroy'],
                'list': ['tool', 'ls'],
              },
              'statusMap': {
                'state': [
                  {'state': 'starting'},
                ],
                'list': '/*/name',
                'missingErrorCodes': ['env.not-found'],
              },
            },
          ]),
        );
        h.tool['status'] = failed(
          1,
          error: const EnvironmentError(
            code: 'env.not-found',
            message: 'No such environment',
          ),
        );
        h.tool['create'] = failed(
          3,
          error: const EnvironmentError(
            code: 'hosts',
            message: 'Adding the hostnames needs sudo',
            command: 'tool create',
            exitCode: 3,
          ),
        );
      });

      test('keeps the row and the reason through a poll', () async {
        await h.ensure();
        expect(row().status, EnvironmentStatus.failed);

        h.now = h.now.add(const Duration(minutes: 6));
        await h.service.runMaintenance();

        expect(row().status, EnvironmentStatus.failed);
        expect(row().lastError?.needsHostSetup, isTrue);
        expect(row().components.single.state, 'failed');
      });

      test('keeps them through a restart too', () async {
        await h.ensure();
        h.tool['ls'] = ok('[]');

        await h.service.recover();

        expect(row().status, EnvironmentStatus.failed);
      });

      test('leaves the attempt in the space\'s runs', () async {
        await h.ensure();

        final run = (await h.runs.forSpace('ws-a', 'space-a')).single;
        expect(run.kind, EnvironmentRunKind.start);
        expect(run.status, EnvironmentRunStatus.failed);
        expect(run.exitCode, 3);
        expect(run.error, 'Adding the hostnames needs sudo');
      });
    });

    group('what a definition holds', () {
      test('names each space and leaves out gone rows', () async {
        h.store(definitionJson([composeJson()]));
        h.addSpace('space-2');
        await h.ensure();
        await h.ensure(space: 'space-2');
        final gone = (await h.environments.forSpace('ws-a', 'space-2')).single;
        await h.environments.save(
          gone.copyWith(status: EnvironmentStatus.gone),
        );

        final held = await h.service.definitionEnvironments('ws-a', 'def-1');

        expect(held.map((item) => item.environment.spaceId), ['space-1']);
        expect(held.single.spaceName, isNotNull);
      });

      test('never crosses into another workspace', () async {
        h.store(definitionJson([composeJson()]));
        await h.ensure();

        expect(
          await h.service.definitionEnvironments('ws-b', 'def-1'),
          isEmpty,
        );
      });

      test('a space that went still shows, so it can be destroyed', () async {
        h.store(definitionJson([composeJson()]));
        await h.ensure();
        h.directory.spaces.remove('space-1');

        final held = await h.service.definitionEnvironments('ws-a', 'def-1');

        expect(held.single.spaceName, isNull);
      });
    });

    group('finishing a start on a terminal', () {
      void definition({bool setup = true}) => h.store(
        definitionJson([
          {
            'kind': 'cli',
            'id': 'tool',
            'verbs': {
              'create': ['tool', 'create', '--json'],
              'status': ['tool', 'status'],
              'destroy': ['tool', 'destroy'],
              if (setup) 'setup': ['tool', 'create', '{name}'],
            },
            'statusMap': {
              'state': [
                {
                  'when': {'path': '/up', 'equals': true},
                  'state': 'ready',
                },
                {'state': 'starting'},
              ],
              'missingErrorCodes': ['env.not-found'],
            },
          },
        ]),
      );

      Future<void> stoppedForSetup() async {
        h.tool['status'] = failed(
          1,
          error: const EnvironmentError(
            code: 'env.not-found',
            message: 'No such environment',
          ),
        );
        h.tool['create'] = failed(
          3,
          error: const EnvironmentError(
            code: 'hosts',
            message: 'Adding the hostnames needs sudo',
            command: 'printed by the tool --do-not-run-me',
            exitCode: 3,
          ),
        );
        await h.ensure();
      }

      Future<String> start() =>
          h.service.startSetup('ws-a', 'space-1', by: principal);

      test('runs the definition\'s verb, not what the tool printed', () async {
        definition();
        await stoppedForSetup();

        await start();

        expect(h.terminals.last.executable, '/usr/bin/tool');
        expect(h.terminals.last.arguments, ['create', row().name]);
        expect(h.terminals.last.environment['TERM'], 'xterm-256color');
      });

      test('a second press opens the same terminal', () async {
        definition();
        await stoppedForSetup();

        final first = await start();

        expect(await start(), first);
        expect(h.terminals.sessions, hasLength(1));
      });

      test('the start carries on when it succeeds', () async {
        definition();
        await stoppedForSetup();
        await start();
        h.tool['status'] = ok(jsonEncode({'up': true}));

        h.terminals.last.exit.complete(0);
        for (var i = 0; i < 200 && !row().status.isRunning; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        expect(row().status, EnvironmentStatus.ready);
        expect(row().lastError, isNull);
      });

      test('a failure stays where it was, and leaves a run', () async {
        definition();
        await stoppedForSetup();
        await start();

        h.terminals.last.print('sudo: 3 incorrect password attempts\n');
        h.terminals.last.exit.complete(1);
        await pumpEventQueue();

        expect(row().status, EnvironmentStatus.failed);
        expect(row().lastError?.needsHostSetup, isTrue);
        final run = (await h.runs.forSpace(
          'ws-a',
          'space-1',
        )).firstWhere((item) => item.label == 'setup');
        expect(run.status, EnvironmentRunStatus.failed);
        expect(run.output, contains('incorrect password attempts'));
      });

      test('refuses when nothing is waiting on a person', () async {
        definition();
        h.tool['status'] = ok(jsonEncode({'up': true}));
        await h.ensure();

        await expectLater(start(), throwsA(isA<Exception>()));
        expect(h.terminals.sessions, isEmpty);
      });

      test('refuses a definition without the verb', () async {
        definition(setup: false);
        await stoppedForSetup();

        await expectLater(start(), throwsA(isA<Exception>()));
        expect(h.terminals.sessions, isEmpty);
      });

      test('a fork never gets a password prompt on this machine', () async {
        definition();
        await stoppedForSetup();
        final space = h.directory.spaces['space-1']!;
        h.directory.spaces['space-1'] = EnvironmentSpaceInfo(
          id: space.id,
          workspaceId: space.workspaceId,
          name: space.name,
          branch: space.branch,
          repos: space.repos,
          isFork: true,
        );

        await expectLater(start(), throwsA(isA<Exception>()));
        expect(h.terminals.sessions, isEmpty);
      });

      test('destroying it ends a terminal nobody will answer', () async {
        definition();
        await stoppedForSetup();
        await start();
        h.tool['destroy'] = ok();

        await h.service.destroy('ws-a', 'space-1', by: principal);

        expect(h.terminals.last.killed, isTrue);
      });
    });

    test('a tool that lost it marks it gone', () async {
      h.store(
        definitionJson([
          {
            'kind': 'cli',
            'id': 'tool',
            'verbs': {
              'create': ['tool', 'create'],
              'status': ['tool', 'status'],
              'destroy': ['tool', 'destroy'],
            },
          },
        ]),
      );
      await h.ensure();
      h.now = h.now.add(const Duration(minutes: 6));
      h.tool['status'] = ok(jsonEncode({'state': 'missing'}));
      await h.service.runMaintenance();
      expect(row().status, EnvironmentStatus.gone);
    });

    test('compose services are read from ps', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.now = h.now.add(const Duration(minutes: 6));
      h.ps = (_) => [
        jsonEncode({'Service': 'db', 'State': 'exited', 'ExitCode': 1}),
        jsonEncode({'Service': 'site', 'State': 'running', 'Health': ''}),
      ].join('\n');
      await h.service.runMaintenance();
      expect(row().status, EnvironmentStatus.degraded);
      expect(component('stack').services.first['state'], 'failed');
    });

    test('a mutation in flight is left alone', () async {
      final held = Completer<void>();
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('stop')) {
          await held.future;
        }
      };
      final stopping = h.service.stop('ws-a', 'space-1', by: principal);
      await h.until(() => row().status == EnvironmentStatus.stopping);
      h.now = h.now.add(const Duration(minutes: 6));
      h.runner.calls.clear();
      await h.service.runMaintenance();
      expect(h.runner.calls.where((c) => c.argv.contains('ps')), isEmpty);
      held.complete();
      await stopping;
    });
  });

  group('definitions', () {
    test('saveDefinition stores what validates', () async {
      final record = await h.service.saveDefinition(
        workspaceId: 'ws-a',
        definition: definitionJson([composeJson()]),
        by: principal,
      );
      expect(record.name, 'Shop');
      expect(record.createdBy, 'user:member');
      expect(await h.service.definition('ws-a', record.id), record);
      expect(await h.service.listDefinitions('ws-a'), [record]);
    });

    test('saveDefinition lists path: message lines', () async {
      await expectLater(
        h.service.saveDefinition(
          workspaceId: 'ws-a',
          definition: {
            ...definitionJson(
              [composeJson()],
              extra: {
                'env': {'PATH': '/x'},
              },
            ),
            'contract': 2,
          },
          by: principal,
        ),
        invalid(allOf(contains('contract: '), contains('env'), contains('\n'))),
      );
      expect(h.definitions.records, isEmpty);
    });

    test('saveDefinition checks repo ids against the workspace', () async {
      await expectLater(
        h.service.saveDefinition(
          workspaceId: 'ws-a',
          definition: definitionJson(
            [composeJson()],
            repos: {
              'app': {'repoId': 'repo-b', 'anchor': true, 'required': true},
            },
          ),
          by: principal,
        ),
        invalid(contains('repos.app: ')),
      );
    });

    test('malformed JSON shape is a validation error', () async {
      await expectLater(
        h.service.saveDefinition(
          workspaceId: 'ws-a',
          definition: {'name': 'x'},
          by: principal,
        ),
        invalid(startsWith('definition: ')),
      );
    });

    test('a definition in use can\'t be deleted', () async {
      final id = h.store(definitionJson([composeJson()]));
      await h.ensure();
      await expectLater(
        h.service.deleteDefinition('ws-a', id),
        invalid(contains('fix-space-1')),
      );
      await h.service.destroy('ws-a', 'space-1', by: principal);
      await h.service.deleteDefinition('ws-a', id);
      expect(h.definitions.records, isEmpty);
    });

    group('source', () {
      String fileAt(Map<String, dynamic> json) => jsonEncode(json);

      void onBranch(String text, String hash) {
        h.git['show'] = ok(text);
        h.git['rev-parse'] = ok('$hash\n');
      }

      test('approveSource reads the default branch, nothing else', () async {
        onBranch(fileAt(definitionJson([composeJson()])), 'blob1');
        final record = await h.service.approveSource(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          path: '.cc/environment.json',
          by: principal,
        );
        expect(record.approvedBlobHash, 'blob1');
        expect(record.sourcePath, '.cc/environment.json');
        final gits = h.runner.calls.where((c) => c.argv.first == 'git');
        expect(gits.map((c) => c.argv.sublist(1)), [
          ['rev-parse', 'main:.cc/environment.json'],
          ['show', 'main:.cc/environment.json'],
        ]);
        expect(gits.first.workingDirectory, h.sourcePath);
      });

      test('overrides merge over the file', () async {
        onBranch(fileAt(definitionJson([composeJson()])), 'blob1');
        final record = await h.service.approveSource(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          path: 'env.json',
          overrides: {
            'policy': {'maxRunning': 1},
          },
          by: principal,
        );
        final definition = await h.service.definitionFor('ws-a', 'space-1');
        expect(definition?.policy.maxRunning, 1);
        expect(record.definitionJson, isNot(contains('maxRunning')));
      });

      test('approval refuses a file that changed since review', () async {
        onBranch(fileAt(definitionJson([composeJson()])), 'blob2');
        await expectLater(
          h.service.approveSource(
            workspaceId: 'ws-a',
            repoId: 'repo-app',
            path: 'env.json',
            expectedBlobHash: 'blob1',
            by: principal,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('re-approving the stored blob keeps its text', () async {
        onBranch(fileAt(definitionJson([composeJson()])), 'blob1');
        final first = await h.service.approveSource(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          path: 'env.json',
          by: principal,
        );
        onBranch(
          fileAt(
            definitionJson([
              taskJson('x', ['manual']),
            ]),
          ),
          'blob2',
        );
        final again = await h.service.approveSource(
          workspaceId: 'ws-a',
          definitionId: first.id,
          repoId: 'repo-app',
          path: 'env.json',
          expectedBlobHash: 'blob1',
          overrides: {
            'policy': {'maxRunning': 1},
          },
          by: principal,
        );
        expect(again.approvedBlobHash, 'blob1');
        expect(again.definitionJson, first.definitionJson);
      });

      test('a file change changes nothing until approved', () async {
        onBranch(fileAt(definitionJson([composeJson()])), 'blob1');
        final record = await h.service.approveSource(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          path: 'env.json',
          by: principal,
        );
        onBranch(
          fileAt(
            definitionJson([
              taskJson('evil', ['start']),
            ]),
          ),
          'blob2',
        );

        final update = await h.service.sourceUpdate('ws-a', record.id);
        expect(update?['update_available'], isTrue);
        expect(update?['blob_hash'], 'blob2');
        expect(update?['approved_blob_hash'], 'blob1');

        await h.ensure();
        expect(h.commands, isNot(contains('tool evil')));

        await h.service.destroy('ws-a', 'space-1', by: principal);
        await h.service.approveSource(
          workspaceId: 'ws-a',
          definitionId: record.id,
          repoId: 'repo-app',
          path: 'env.json',
          by: principal,
        );
        await h.ensure();
        expect(h.commands, contains('tool evil'));
      });

      test('sourceUpdate with no change says so', () async {
        onBranch(fileAt(definitionJson([composeJson()])), 'blob1');
        final record = await h.service.approveSource(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          path: 'env.json',
          by: principal,
        );
        final update = await h.service.sourceUpdate('ws-a', record.id);
        expect(update?['update_available'], isFalse);
      });

      test('sourceUpdate of a plain definition is null', () async {
        final id = h.store(definitionJson([composeJson()]));
        expect(await h.service.sourceUpdate('ws-a', id), isNull);
      });

      test('a bad file is refused', () async {
        onBranch('{"contract": 1', 'blob1');
        await expectLater(
          h.service.approveSource(
            workspaceId: 'ws-a',
            repoId: 'repo-app',
            path: 'env.json',
            by: principal,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('a file missing from the branch is refused', () async {
        h.git['show'] = failed(128, stderr: 'no such path');
        await expectLater(
          h.service.approveSource(
            workspaceId: 'ws-a',
            repoId: 'repo-app',
            path: 'env.json',
            by: principal,
          ),
          invalid(contains('does not exist on main')),
        );
      });

      test('a path can\'t climb out', () async {
        await expectLater(
          h.service.approveSource(
            workspaceId: 'ws-a',
            repoId: 'repo-app',
            path: '../secret',
            by: principal,
          ),
          invalid(contains('source.path')),
        );
        expect(h.runner.calls, isEmpty);
      });

      test('a repo of another workspace is refused', () async {
        await expectLater(
          h.service.approveSource(
            workspaceId: 'ws-a',
            repoId: 'repo-b',
            path: 'env.json',
            by: principal,
          ),
          invalid(contains('not linked')),
        );
      });

      test('saveDefinition routes a source form here', () async {
        onBranch(fileAt(definitionJson([composeJson()])), 'blob1');
        final record = await h.service.saveDefinition(
          workspaceId: 'ws-a',
          definition: {
            'source': {'repoId': 'repo-app', 'path': 'env.json'},
          },
          by: principal,
        );
        expect(record.approvedBlobHash, 'blob1');
      });
    });

    test('draftDefinition reads the draft files from the checkout', () async {
      File('${h.sourcePath}/compose.yaml').writeAsStringSync('services: {}');
      File('${h.sourcePath}/package.json').writeAsStringSync(
        jsonEncode({
          'scripts': {'dev': 'vite'},
        }),
      );
      File('${h.sourcePath}/pnpm-lock.yaml').writeAsStringSync('');
      Link('${h.sourcePath}/Procfile').createSync('/etc/hosts');
      final draft = await h.service.draftDefinition('ws-a', 'repo-app');
      final definition = draft['definition'] as Map;
      final kinds = [
        for (final component in definition['components'] as List)
          (component as Map)['kind'],
      ];
      expect(kinds, containsAll(['compose', 'task']));
      expect(jsonEncode(draft), isNot(contains('localhost')));
      expect(h.definitions.records, isEmpty, reason: 'nothing is stored');
    });

    group('check', () {
      test('runs commands and file checks, with built-ins', () async {
        File('$root/ca.crt').writeAsStringSync('x');
        h.tool['--version'] = ok('v24.1.0');
        final id = h.store(
          definitionJson(
            [composeJson()],
            extra: {
              'checks': [
                {
                  'id': 'tool',
                  'label': 'Tool',
                  'command': ['tool', '--version'],
                  'expectOutput': r'^v24\.',
                },
                {
                  'id': 'old',
                  'label': 'Old',
                  'command': ['tool', '--version'],
                  'expectOutput': r'^v99\.',
                  'hint': 'Upgrade',
                  'fix': 'tool upgrade',
                },
                {'id': 'ca', 'label': 'CA', 'file': '{home}/ca.crt'},
                {'id': 'no', 'label': 'No', 'file': '{home}/absent'},
              ],
            },
          ),
        );
        h.runner.handler = (call) =>
            call.argv.contains('version') ? ok('5.5.0') : h.answer(call);
        final results = await h.service.check('ws-a', id);
        final byId = {for (final row in results) row.id: row};
        expect(byId['tool']?.ok, isTrue);
        expect(byId['old']?.ok, isFalse);
        expect(byId['old']?.fix, 'tool upgrade');
        expect(byId['ca']?.ok, isTrue);
        expect(byId['no']?.ok, isFalse);
        expect(byId['compose-version']?.ok, isTrue);
        expect(byId['free-ports']?.ok, isTrue);
      });
    });

    test('eligibleDefinitions needs an anchor and a stack', () async {
      h.store(definitionJson([composeJson()]), id: 'fits');
      h.store(
        definitionJson(
          [composeJson()],
          repos: {
            'e2e': {'repoId': 'repo-e2e', 'anchor': true},
          },
        ),
        id: 'other',
      );
      h.store(
        definitionJson([
          taskJson('deps', ['provision']),
        ]),
        id: 'no-stack',
      );
      final eligible = await h.service.eligibleDefinitions('ws-a', 'space-1');
      expect(eligible.map((record) => record.id), ['fits']);
    });
  });

  group('testDefinition', () {
    late List<String> disposed;

    Future<EnvironmentRun> finished(String id) async {
      await h.until(
        () => h.runs.runs[id]?.status != EnvironmentRunStatus.running,
      );
      return h.runs.runs[id]!;
    }

    void withClone() {
      disposed = [];
      h = ServiceHarness(root)
        ..testClone = (ws, definition) async {
          final worktree = '$root/clones/test';
          Directory(worktree).createSync(recursive: true);
          File('$worktree/compose.yaml').writeAsStringSync('services: {}');
          return EnvironmentTestClone(
            space: EnvironmentSpaceInfo(
              id: 'test-space',
              workspaceId: ws,
              name: 'Test',
              branch: 'test',
              repos: [
                EnvironmentSpaceRepo(
                  repoId: 'repo-app',
                  name: 'Shop',
                  slug: 'shop',
                  worktreePath: worktree,
                  sourcePath: h.sourcePath,
                ),
              ],
            ),
            dispose: () async => disposed.add('clone'),
          );
        };
    }

    test('returns at once, then checks, starts, destroys', () async {
      withClone();
      final held = Completer<void>();
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('up')) {
          await held.future;
        }
      };
      final id = h.store(
        definitionJson([
          composeJson(),
          taskJson('migrate', ['start']),
        ]),
      );
      final runId = await h.service.testDefinition('ws-a', id);
      expect(h.runs.runs[runId]?.status, EnvironmentRunStatus.running);
      expect(h.runs.runs[runId]?.kind, EnvironmentRunKind.test);
      held.complete();

      final run = await finished(runId);
      expect(run.status, EnvironmentRunStatus.succeeded);
      expect(run.output, allOf(contains('Starting'), contains('Destroying')));
      expect(h.environments.rows, isEmpty);
      expect(h.leases.leases, isEmpty);
      expect(disposed, ['clone']);
      expect(
        h.commands,
        contains('compose down -v --remove-orphans --rmi local'),
      );

      final task = h.runner.calls.firstWhere((c) => c.argv.first == 'tool');
      expect(task.environment['CC_ENV_TEST'], '1');
      expect(task.environment['CC_SCRIPT_TEST'], '1');
    });

    test('runs provision and archive with CC_SCRIPT_TEST', () async {
      withClone();
      final id = h.store(
        definitionJson([
          taskJson('deps', ['provision']),
          taskJson('clean', ['archive']),
        ]),
      );
      final run = await finished(await h.service.testDefinition('ws-a', id));
      expect(run.status, EnvironmentRunStatus.succeeded);
      expect(h.commands, ['tool deps', 'tool clean']);
      expect(h.runner.calls.first.environment['CC_SCRIPT_TEST'], '1');
    });

    test('a failed check stops it before any clone', () async {
      withClone();
      final id = h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'checks': [
              {'id': 'no', 'label': 'Nope', 'file': '{home}/absent'},
            ],
          },
        ),
      );
      final run = await finished(await h.service.testDefinition('ws-a', id));
      expect(run.status, EnvironmentRunStatus.failed);
      expect(run.error, contains('Nope'));
      expect(disposed, isEmpty);
    });

    test('a failed start is recorded, and still cleans up', () async {
      withClone();
      h.tool['migrate'] = failed(1, stderr: 'no database');
      final id = h.store(
        definitionJson([
          taskJson('migrate', ['start']),
        ]),
      );
      final run = await finished(await h.service.testDefinition('ws-a', id));
      expect(run.status, EnvironmentRunStatus.failed);
      expect(run.error, contains('no database'));
      expect(h.environments.rows, isEmpty);
      expect(disposed, ['clone']);
    });

    test('no clone provider is a recorded refusal', () async {
      final id = h.store(definitionJson([composeJson()]));
      final run = await finished(await h.service.testDefinition('ws-a', id));
      expect(run.status, EnvironmentRunStatus.failed);
      expect(run.error, contains('not available'));
    });
  });

  group('read-time validation', () {
    late String id;

    setUp(() {
      id = h.store({
        ...definitionJson([composeJson(), webJson()]),
        'contract': 99,
      });
    });

    test('an invalid row fails with its issues and runs nothing', () async {
      await expectLater(
        h.ensure(definitionId: id),
        invalid(contains('contract: ')),
      );
      expect(h.commands, isEmpty);
      expect(h.terminals.sessions, isEmpty);
      expect(h.environments.rows, isEmpty);
    });

    test('with no id named, it surfaces rather than saying no match', () async {
      await expectLater(h.ensure(), invalid(contains('contract: ')));
    });

    test('an unparseable row too', () async {
      h.definitions.records[id] = h.definitions.records[id]!;
      h.store({'name': 'x'}, id: 'junk');
      await expectLater(
        h.ensure(definitionId: 'junk'),
        invalid(startsWith('definition: ')),
      );
    });

    test('every run path re-validates', () async {
      await expectLater(
        h.service.check('ws-a', id),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        h.service.testDefinition('ws-a', id),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a row going bad stops what would run next', () async {
      final good = h.store(
        definitionJson([
          composeJson(),
          taskJson('lint', ['manual']),
        ]),
        id: 'good',
      );
      await h.ensure(definitionId: good);
      h.store({
        ...definitionJson([
          composeJson(),
          taskJson('lint', ['manual']),
        ]),
        'contract': 99,
      }, id: good);
      h.runner.calls.clear();
      await expectLater(
        h.service.runTask('ws-a', 'space-1', 'lint', by: principal),
        invalid(contains('contract: ')),
      );
      expect(h.commands, isEmpty);
    });
  });

  group('sandbox and terminals', () {
    test('sandboxLoopbackPorts takes no lease', () async {
      h.store(definitionJson([composeJson()]));
      expect(await h.service.sandboxLoopbackPorts('ws-a', 'space-1'), isEmpty);
      expect(h.leases.leases, isEmpty);
    });

    test('nor a pool slot', () async {
      h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'naming': {
              'project': 'shop',
              'pool': {'names': 'cc{n}', 'size': 1},
            },
          },
        ),
      );
      await h.service.sandboxLoopbackPorts('ws-a', 'space-1');
      await h.service.sandboxLoopbackPorts('ws-a', 'space-1');
      expect(h.leases.leases, isEmpty);
    });

    test('sandboxLoopbackPorts gives the lease the space holds', () async {
      h.store(definitionJson([composeJson()]));
      final env = await h.ensure();
      final ports = await h.service.sandboxLoopbackPorts('ws-a', 'space-1');
      expect(ports, hasLength(32));
      expect(ports, containsAll(env.ports.values));
    });

    test('nothing for a space that can\'t run one', () async {
      h.store(
        definitionJson(
          [composeJson()],
          repos: {
            'e2e': {'repoId': 'repo-e2e', 'anchor': true},
          },
        ),
      );
      expect(await h.service.sandboxLoopbackPorts('ws-a', 'space-1'), isEmpty);
      expect(h.leases.leases, isEmpty);
    });

    test('sandboxHosts pins each CC name to its own port', () async {
      h.store(definitionJson([webJson()]));
      final env = await h.ensure();
      expect(await h.service.sandboxHosts('ws-a', 'space-1'), {
        'web--fix-space-1--shop.localhost': '127.0.0.1:${env.ports['web']}',
      });
    });

    test('sandboxHosts never pins to the shared router port', () async {
      h.store(definitionJson([composeJson(), webJson()]));
      h.httpPorts.add(42002);
      await h.ensure();
      final hosts = await h.service.sandboxHosts('ws-a', 'space-1');
      expect(hosts, isNotEmpty);
      expect(hosts.values, isNot(contains('127.0.0.1:7355')));
    });

    test('sandboxHosts pins nothing of a tool\'s', () async {
      h.tool['status'] = ok(
        jsonEncode({
          'state': 'ready',
          'endpoints': [
            {'role': 'app', 'url': 'https://fix.acme.test'},
          ],
        }),
      );
      h.store(
        definitionJson(
          [
            {
              'kind': 'cli',
              'id': 'tool',
              'verbs': {
                'create': ['tool', 'create'],
                'status': ['tool', 'status'],
                'destroy': ['tool', 'destroy'],
              },
            },
          ],
          extra: {
            'routing': {
              'mode': 'tool',
              'domain': 'acme.test',
              'upstream': '127.0.0.1:443',
            },
          },
        ),
      );
      await h.ensure();
      expect(await h.service.sandboxHosts('ws-a', 'space-1'), isEmpty);
    });

    test('sandboxHosts is empty with nothing running', () async {
      h.store(definitionJson([webJson()]));
      await h.ensure();
      await h.service.stop('ws-a', 'space-1', by: principal);
      expect(await h.service.sandboxHosts('ws-a', 'space-1'), isEmpty);
    });

    test('terminalEnvironment is empty with no environment', () async {
      h.store(definitionJson([composeJson()]));
      expect(await h.service.terminalEnvironment('ws-a', 'space-1'), isEmpty);
    });

    test('terminalEnvironment is the contract, with COMPOSE_*', () async {
      h.store(definitionJson([composeJson(), webJson()]));
      final env = await h.ensure();
      final variables = await h.service.terminalEnvironment('ws-a', 'space-1');
      expect(variables['CC_ENV_ID'], env.id);
      expect(variables['CC_ENV_PORT_WEB'], '${env.ports['web']}');
      expect(variables['COMPOSE_PROJECT_NAME'], startsWith('cc-'));
      expect(
        variables['COMPOSE_FILE'],
        allOf(
          contains('$root/worktrees/space-1/compose.yaml'),
          contains('compose.override.yaml'),
        ),
      );
      expect(variables['CC_ENV_URL'], contains('.localhost:7355'));
    });

    test('with no compose there is no COMPOSE_*', () async {
      h.store(definitionJson([webJson()]));
      await h.ensure();
      final variables = await h.service.terminalEnvironment('ws-a', 'space-1');
      expect(variables.keys, isNot(contains('COMPOSE_FILE')));
    });

    test('an invalid definition gives a terminal nothing', () async {
      h.store(definitionJson([webJson()]));
      await h.ensure();
      h.store({
        ...definitionJson([webJson()]),
        'contract': 99,
      });
      expect(await h.service.terminalEnvironment('ws-a', 'space-1'), isEmpty);
    });

    group('agentShimTools', () {
      test('empty when nothing can run here', () async {
        expect(await h.service.agentShimTools('ws-a', 'space-1'), isEmpty);
      });

      test('empty for a definition with no stack', () async {
        h.store(
          definitionJson([
            taskJson('deps', ['provision']),
          ]),
        );
        expect(await h.service.agentShimTools('ws-a', 'space-1'), isEmpty);
      });

      test('empty without an anchor here', () async {
        h.store(
          definitionJson(
            [composeJson()],
            repos: {
              'e2e': {'repoId': 'repo-e2e', 'anchor': true},
            },
          ),
        );
        expect(await h.service.agentShimTools('ws-a', 'space-1'), isEmpty);
      });

      test('cc-env alone for a process stack', () async {
        h.store(definitionJson([webJson()]));
        expect(await h.service.agentShimTools('ws-a', 'space-1'), {'cc-env'});
      });

      test('docker with compose', () async {
        h.store(definitionJson([composeJson()]));
        expect(await h.service.agentShimTools('ws-a', 'space-1'), {
          'cc-env',
          'docker',
        });
      });

      test('each passthrough binary', () async {
        h.store(
          definitionJson([
            composeJson(),
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
                    'argv': ['env', 'ls'],
                    'maps': 'status',
                  },
                ],
              },
            },
          ]),
        );
        expect(await h.service.agentShimTools('ws-a', 'space-1'), {
          'cc-env',
          'docker',
          'tool',
        });
      });
    });
  });

  group('operations', () {
    test('runTask runs manual tasks only, with arguments', () async {
      h.store(
        definitionJson([
          composeJson(),
          taskJson('lint', ['manual']),
          taskJson('deps', ['start']),
        ]),
      );
      await h.ensure();
      h.runner.calls.clear();
      final run = await h.service.runTask(
        'ws-a',
        'space-1',
        'lint',
        arguments: ['--fix'],
        by: principal,
      );
      expect(run.status, EnvironmentRunStatus.succeeded);
      expect(h.commands, ['tool lint --fix']);
      await expectLater(
        h.service.runTask('ws-a', 'space-1', 'deps', by: principal),
        invalid(contains('not a manual task')),
      );
    });

    test('restart reaches a process or a compose service', () async {
      h.store(definitionJson([composeJson(), webJson()]));
      await h.ensure();
      final sessions = h.terminals.sessions.length;
      await h.service.restart('ws-a', 'space-1', 'web', by: principal);
      expect(h.terminals.sessions.length, sessions + 1);
      h.runner.calls.clear();
      await h.service.restart('ws-a', 'space-1', 'db', by: principal);
      expect(h.commands, ['compose restart db']);
      await expectLater(
        h.service.restart('ws-a', 'space-1', 'nope', by: principal),
        invalid(contains('nope')),
      );
    });

    test('exec picks compose or the tool', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.runner.calls.clear();
      await h.service.exec(
        'ws-a',
        'space-1',
        service: 'db',
        command: ['ls'],
        by: principal,
      );
      expect(h.commands, ['compose exec -T db ls']);
    });

    test('logs of a process come from the supervisor', () async {
      h.store(definitionJson([webJson()]));
      await h.ensure();
      h.terminals.last.print('hello\r\n');
      expect(await h.service.logs('ws-a', 'space-1', target: 'web'), 'hello');
    });

    test('logs of a service come from compose', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.runner.calls.clear();
      await h.service.logs('ws-a', 'space-1', target: 'db', tail: 5);
      expect(h.commands, ['compose logs --no-color --tail 5 db']);
    });

    test('stopProcess stops one process', () async {
      h.store(definitionJson([webJson()]));
      await h.ensure();
      await h.service.stopProcess('ws-a', 'space-1', 'web', by: principal);
      expect(h.terminals.last.exit.isCompleted, isTrue);
    });

    test('destroy removes everything', () async {
      h.store(definitionJson([composeJson(), webJson()]));
      final destroyed = <EnvironmentDestroyed>[];
      h.events.on<EnvironmentDestroyed>().listen(destroyed.add);
      final env = await h.ensure();
      await h.service.destroy('ws-a', 'space-1', by: principal);
      expect(h.environments.rows, isEmpty);
      expect(h.leases.leases, isEmpty);
      expect(
        Directory('$root/data/ws-a/environments/${env.id}').existsSync(),
        isFalse,
      );
      await h.until(() => destroyed.isNotEmpty);
    });

    test('a failed destroy keeps the row, failed', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.runner.handler = (call) => call.argv.contains('down')
          ? failed(1, stderr: 'busy')
          : h.answer(call);
      await expectLater(
        h.service.destroy('ws-a', 'space-1', by: principal),
        throwsA(isA<EnvironmentDriverException>()),
      );
      expect(row().status, EnvironmentStatus.failed);
      expect(h.leases.leases, hasLength(1));
    });

    test('a space with no environment says so', () async {
      await expectLater(
        h.service.stop('ws-a', 'space-1', by: principal),
        throwsA(isA<NotFoundException>()),
      );
    });

    group('apps', () {
      setUp(() {
        h.store(
          definitionJson([
            webJson(),
            taskJson('build', ['manual']),
            {
              'kind': 'app',
              'id': 'desktop',
              'prepare': 'build',
              'input': 'foreground',
              'command': ['tool', 'open'],
            },
          ]),
        );
      });

      Future<void> launch({bool rebuild = false}) => h.service.launchApp(
        'ws-a',
        'space-1',
        'desktop',
        rebuild: rebuild,
        by: principal,
      );

      test('prepares, launches, opens a viewer on its pids', () async {
        await h.ensure();
        h.runner.calls.clear();
        await launch();
        expect(h.commands, ['tool build']);
        expect(h.terminals.last.owner, endsWith('/desktop'));
        expect(h.windows.opened, hasLength(1));
        expect(component('desktop').services.single['rig_id'], 'rig-window');
      });

      test('a launch of a running app does nothing', () async {
        await h.ensure();
        await launch();
        final sessions = h.terminals.sessions.length;
        await launch();
        expect(h.terminals.sessions.length, sessions);
      });

      test('rebuild stops, prepares, launches', () async {
        await h.ensure();
        await launch();
        final sessions = h.terminals.sessions.length;
        h.runner.calls.clear();
        await launch(rebuild: true);
        expect(h.commands, ['tool build']);
        expect(h.terminals.sessions.length, sessions + 1);
        expect(h.windows.closed, ['rig-window']);
      });

      test('a failed prepare launches nothing', () async {
        await h.ensure();
        h.tool['build'] = failed(1, stderr: 'no compiler');
        final sessions = h.terminals.sessions.length;
        await expectLater(launch(), throwsA(isA<EnvironmentDriverException>()));
        expect(h.terminals.sessions.length, sessions);
      });

      test('stopApp closes it and its viewer', () async {
        await h.ensure();
        await launch();
        await h.service.stopApp('ws-a', 'space-1', 'desktop', by: principal);
        expect(h.windows.closed, ['rig-window']);
        expect(h.terminals.last.exit.isCompleted, isTrue);
      });

      test('needs a running environment', () async {
        await h.ensure();
        await h.service.stop('ws-a', 'space-1', by: principal);
        await expectLater(launch(), driverError('not-running'));
      });
    });
  });

  group('agent context', () {
    test('answers for a space that hasn\'t started', () async {
      h.store(definitionJson([composeJson()]));
      expect((await h.service.definitionFor('ws-a', 'space-1'))?.name, 'Shop');
      expect(await h.service.nameFor('ws-a', 'space-1'), 'fix-space-1');
    });

    test('answers from the environment once there is one', () async {
      h.addSpace('space-2', branch: 'fix/space-1');
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      final env = await h.ensure(space: 'space-2');
      expect(await h.service.nameFor('ws-a', 'space-2'), env.name);
    });

    test('nothing for a space with nothing to run', () async {
      expect(await h.service.definitionFor('ws-a', 'space-1'), isNull);
      expect(await h.service.nameFor('ws-a', 'space-1'), isNull);
    });

    test('worktrees and working directory come from the space', () async {
      h.store(definitionJson([composeJson()]));
      expect(await h.service.worktreeRoots('ws-a', 'space-1'), [
        '$root/worktrees/space-1',
      ]);
      expect(
        await h.service.workingDirectory('ws-a', 'space-1'),
        '$root/worktrees/space-1',
      );
    });

    test('isInside follows links', () async {
      final inside = '$root/worktrees/space-1/file';
      File(inside).writeAsStringSync('');
      Link('$root/worktrees/space-1/out').createSync(root);
      final roots = ['$root/worktrees/space-1'];
      expect(await h.service.isInside(inside, roots), isTrue);
      expect(
        await h.service.isInside('$root/worktrees/space-1/out', roots),
        isFalse,
      );
    });
  });

  group('security review', () {
    group('fork re-admission on the host', () {
      Map<String, dynamic> forkDefinition({String policy = 'approval'}) =>
          definitionJson(
            [
              composeJson(),
              webJson(),
              taskJson('lint', ['manual']),
              {
                'kind': 'app',
                'id': 'desktop',
                'command': ['tool', 'open'],
              },
            ],
            extra: {
              'policy': {'forkPrs': policy},
            },
          );

      void forkAt(String sha) => h.addSpace(
        'fork',
        prNumber: 7,
        prRepo: 'acme/shop',
        kind: 'pr',
        isFork: true,
        prHeadSha: sha,
      );

      Future<void> startApproved() async {
        forkAt('sha1');
        h.store(forkDefinition());
        h.admin = true;
        expect((await h.ensure(space: 'fork')).status, EnvironmentStatus.ready);
        h.admin = false;
      }

      final entries = <String, Future<Object?> Function(ServiceHarness h)>{
        'reset': (h) => h.service.reset('ws-a', 'fork', by: principal),
        'refresh': (h) => h.service.refresh('ws-a', 'fork', by: principal),
        'restart': (h) =>
            h.service.restart('ws-a', 'fork', 'web', by: principal),
        'runTask': (h) =>
            h.service.runTask('ws-a', 'fork', 'lint', by: principal),
        'launchApp': (h) =>
            h.service.launchApp('ws-a', 'fork', 'desktop', by: principal),
        'exec': (h) => h.service.exec(
          'ws-a',
          'fork',
          service: 'db',
          command: const ['ls'],
          by: principal,
        ),
      };

      test('the approved head keeps running for members', () async {
        await startApproved();
        h.runner.calls.clear();
        await h.service.runTask('ws-a', 'fork', 'lint', by: principal);
        expect(h.commands, ['tool lint']);
      });

      for (final entry in entries.entries) {
        test('${entry.key} refuses once the head moved', () async {
          await startApproved();
          forkAt('sha2');
          h.runner.calls.clear();
          final sessions = h.terminals.sessions.length;
          await expectLater(entry.value(h), driverError('fork-needs-approval'));
          expect(h.commands, isEmpty);
          expect(h.terminals.sessions.length, sessions);
        });

        test('${entry.key} refuses once the policy says deny', () async {
          await startApproved();
          h.store(forkDefinition(policy: 'deny'));
          h.runner.calls.clear();
          await expectLater(entry.value(h), driverError('fork-denied'));
          expect(h.commands, isEmpty);
        });
      }

      test('a moved head stops it instead of syncing', () async {
        await startApproved();
        await h.service.start(runRecovery: false);
        h.runner.calls.clear();
        h.changedPaths = ['app.js'];
        h.events.publish(
          PrHeadChanged(
            repoOwner: 'acme',
            repoName: 'shop',
            prNumber: 7,
            prTitle: 'Fix',
            previousHeadSha: 'sha1',
            headSha: 'sha2',
            workspaceId: 'ws-a',
            occurredAt: h.now,
          ),
        );
        await h.until(() => row('fork').status == EnvironmentStatus.stopped);
        await h.until(() => row('fork').lastError != null);
        expect(row('fork').lastError?.code, 'fork-needs-approval');
        expect(h.syncs, 0);
        expect(h.commands, isNot(contains('compose up -d --build db site')));

        // The approval went with it, even for the head it was given for.
        await expectLater(
          h.service.reset('ws-a', 'fork', by: principal),
          driverError('fork-needs-approval'),
        );
      });

      group('a crashed process', () {
        Future<void> crashOnce() async {
          await h.service.start(runRecovery: false);
          h.terminals.last.exit.complete(1);
        }

        test('comes back on the approved head', () async {
          await startApproved();
          final sessions = h.terminals.sessions.length;
          await crashOnce();
          await h.until(() => h.terminals.sessions.length > sessions);
          expect(row('fork').lastError, isNull);
        });

        test('stays down once the head moved, and stops the rest', () async {
          await startApproved();
          forkAt('sha2');
          final sessions = h.terminals.sessions.length;
          h.runner.calls.clear();
          await crashOnce();
          await h.until(() => row('fork').lastError != null);
          expect(row('fork').status, EnvironmentStatus.stopped);
          expect(row('fork').lastError?.code, 'fork-needs-approval');
          expect(h.terminals.sessions.length, sessions);
          expect(component('web', 'fork').state, 'stopped');
          expect(h.commands, anyElement(endsWith(' stop')));
          await expectLater(
            h.service.reset('ws-a', 'fork', by: principal),
            driverError('fork-needs-approval'),
          );
        });

        test('stays down once the policy says deny', () async {
          await startApproved();
          h.store(forkDefinition(policy: 'deny'));
          final sessions = h.terminals.sessions.length;
          await crashOnce();
          await h.until(() => row('fork').lastError != null);
          expect(row('fork').lastError?.code, 'fork-denied');
          expect(h.terminals.sessions.length, sessions);
        });

        test('rides through while its start is still going', () async {
          final held = Completer<void>();
          h.runner.beforeAnswer = (call) async {
            if (call.argv.contains('slow')) {
              await held.future;
            }
          };
          forkAt('sha1');
          h.store(
            definitionJson(
              [
                webJson(),
                taskJson('slow', ['start']),
              ],
              extra: {
                'policy': {'forkPrs': 'approval'},
              },
            ),
          );
          h.admin = true;
          final starting = h.ensure(space: 'fork');
          await h.until(() => h.commands.contains('tool slow'));
          await crashOnce();
          await h.until(() => h.terminals.sessions.length == 2);
          held.complete();
          expect((await starting).status, EnvironmentStatus.ready);
          expect(row('fork').lastError, isNull);
        });
      });

      group('boot', () {
        // What a server finds after a reboot: a running row, no processes.
        Future<void> rebooted() async {
          await startApproved();
          await h.service.stop('ws-a', 'fork', by: principal);
          final stopped = row('fork');
          h.environments.rows[stopped.id] = stopped.copyWith(
            status: EnvironmentStatus.ready,
            components: [
              for (final state in stopped.components)
                state.copyWith(state: 'ready'),
            ],
          );
          h.runner.calls.clear();
        }

        test('brings back the approved head', () async {
          await rebooted();
          final sessions = h.terminals.sessions.length;
          await h.service.recover();
          expect(h.terminals.sessions.length, sessions + 1);
          expect(row('fork').status, EnvironmentStatus.ready);
        });

        test('never respawns a head nobody approved', () async {
          await rebooted();
          forkAt('sha2');
          final sessions = h.terminals.sessions.length;
          await h.service.recover();
          expect(h.terminals.sessions.length, sessions);
          expect(row('fork').status, EnvironmentStatus.stopped);
          expect(row('fork').lastError?.code, 'fork-needs-approval');
          // Containers outlive a server, so they go as well.
          expect(h.commands, anyElement(endsWith(' stop')));
        });

        test('never respawns once the policy says deny', () async {
          await rebooted();
          h.store(forkDefinition(policy: 'deny'));
          final sessions = h.terminals.sessions.length;
          await h.service.recover();
          expect(h.terminals.sessions.length, sessions);
          expect(row('fork').lastError?.code, 'fork-denied');
        });
      });

      group('moving the head', () {
        Future<bool> tryMove({String workspace = 'ws-a'}) async {
          var moved = false;
          await h.service.whileHeadMoves(workspace, 'fork', () async {
            moved = true;
          });
          return moved;
        }

        test('is refused while it runs on the host', () async {
          await startApproved();
          await expectLater(tryMove(), driverError('fork-running-on-host'));
          expect(row('fork').status, EnvironmentStatus.ready);
        });

        test(
          'is refused while a failed start may have left something',
          () async {
            await startApproved();
            final env = row('fork');
            h.environments.rows[env.id] = env.copyWith(
              status: EnvironmentStatus.failed,
            );
            await expectLater(tryMove(), driverError('fork-running-on-host'));
          },
        );

        test('is refused while a start is on its way', () async {
          final held = Completer<void>();
          h.runner.beforeAnswer = (call) async {
            if (call.argv.contains('config')) {
              await held.future;
            }
          };
          forkAt('sha1');
          h.store(forkDefinition());
          h.admin = true;
          final starting = h.ensure(space: 'fork');
          await h.until(() => h.runner.calls.isNotEmpty);
          await expectLater(tryMove(), driverError('fork-running-on-host'));
          held.complete();
          await starting;
        });

        test('goes ahead once it is stopped', () async {
          await startApproved();
          await h.service.stop('ws-a', 'fork', by: principal);
          expect(await tryMove(), isTrue);
        });

        test('goes ahead in a rig', () async {
          h = ServiceHarness(root, rigHost: FakeRigHost());
          forkAt('sha1');
          h.store(
            definitionJson(
              [composeJson()],
              extra: {
                'policy': {'forkPrs': 'rig'},
              },
            ),
          );
          await h.ensure(space: 'fork');
          expect(row('fork').placement, 'rig');
          expect(await tryMove(), isTrue);
        });

        test('goes ahead for a trusted PR on the host', () async {
          h.addSpace('fork', prNumber: 7, prRepo: 'acme/shop', kind: 'pr');
          h.store(forkDefinition());
          await h.ensure(space: 'fork');
          expect(await tryMove(), isTrue);
        });

        test('holds off a start until it is done', () async {
          forkAt('sha1');
          h.store(forkDefinition());
          h.admin = true;
          await h.service.whileHeadMoves('ws-a', 'fork', () async {
            await expectLater(
              h.ensure(space: 'fork'),
              driverError('head-moving'),
            );
          });
          expect(
            (await h.ensure(space: 'fork')).status,
            EnvironmentStatus.ready,
          );
        });

        test('a space of another workspace moves nothing', () async {
          await startApproved();
          await h.service.stop('ws-a', 'fork', by: principal);
          await expectLater(tryMove(workspace: 'ws-b'), throwsException);
        });

        test('what a start approves is the head it found last', () async {
          forkAt('sha1');
          h.store(forkDefinition());
          h.admin = true;
          h.onAdminCheck = () => forkAt('sha2');
          await h.ensure(space: 'fork');
          h
            ..onAdminCheck = null
            ..admin = false;
          await h.service.runTask('ws-a', 'fork', 'lint', by: principal);
        });
      });

      test('an admin start approves the new head', () async {
        await startApproved();
        await h.service.stop('ws-a', 'fork', by: principal);
        forkAt('sha2');
        h.admin = true;
        await h.ensure(space: 'fork');
        h.admin = false;
        await h.service.runTask('ws-a', 'fork', 'lint', by: principal);
      });
    });

    test('a rig never receives a source checkout', () async {
      final rig = FakeRigHost();
      h = ServiceHarness(root, rigHost: rig);
      h.addSpace('fork', prNumber: 7, prRepo: 'acme/shop', isFork: true);
      // No forkPrs: an eligible definition defaults to rig, which the
      // validator can't refuse on useSource's account.
      h.store(
        definitionJson(
          [composeJson()],
          repos: {
            'app': {'repoId': 'repo-app', 'anchor': true},
            'e2e': {'repoId': 'repo-e2e', 'whenMissing': 'useSource'},
          },
        ),
      );
      await h.ensure(space: 'fork');
      expect(rig.worktrees.single.keys, ['app']);
      expect(rig.worktrees.single.values, isNot(contains('$root/source-e2e')));
    });

    test('a definition with hidden values is refused, not saved', () async {
      h.store(definitionJson([webJson()]));
      final before = await h.service.listDefinitions('ws-a');
      final redacted = before.single.toRedactedJson();
      await expectLater(
        h.service.saveDefinition(
          workspaceId: 'ws-a',
          definitionId: before.single.id,
          definition: Map<String, dynamic>.from(redacted['definition'] as Map)
            ..['env'] = {'DATABASE_URL': kEnvironmentRedactedValue},
          by: principal,
        ),
        invalid(contains('hidden values')),
      );
      expect(await h.service.listDefinitions('ws-a'), before);
    });

    test('overrides with hidden values are refused, not approved', () async {
      await expectLater(
        h.service.approveSource(
          workspaceId: 'ws-a',
          repoId: 'repo-app',
          path: 'environment.json',
          overrides: {
            'env': {'SECRET_ID': kEnvironmentRedactedValue},
          },
          by: principal,
        ),
        invalid(contains('hidden values')),
      );
    });

    test('useSource with rig placement is refused when saved', () async {
      await expectLater(
        h.service.saveDefinition(
          workspaceId: 'ws-a',
          definition: definitionJson(
            [composeJson()],
            repos: {
              'app': {'repoId': 'repo-app', 'anchor': true},
              'e2e': {'repoId': 'repo-e2e', 'whenMissing': 'useSource'},
            },
            extra: {'placement': 'rig'},
          ),
          by: principal,
        ),
        invalid(contains('repos.e2e')),
      );
    });
  });

  group('correctness review', () {
    test('archive releases leases of what stopped', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      await h.service.start(runRecovery: false);
      h.events.publish(
        SpaceArchived(
          spaceId: 'space-1',
          workspaceId: 'ws-a',
          occurredAt: h.now,
        ),
      );
      await h.until(() => h.leases.leases.isEmpty);
      expect(row().status, EnvironmentStatus.stopped);
    });

    test('and keeps those of what still runs', () async {
      h.tool['status'] = ok(jsonEncode({'state': 'ready'}));
      h.store(
        definitionJson([
          {
            'kind': 'cli',
            'id': 'tool',
            'keepsDataOnStop': false,
            'verbs': {
              'create': ['tool', 'create'],
              'status': ['tool', 'status'],
              'destroy': ['tool', 'destroy'],
            },
          },
        ]),
      );
      await h.ensure();
      await h.service.start(runRecovery: false);
      h.events.publish(
        SpaceArchived(
          spaceId: 'space-1',
          workspaceId: 'ws-a',
          occurredAt: h.now,
        ),
      );
      await h.until(() => row().warnings.isNotEmpty);
      expect(h.leases.leases, hasLength(1));
    });

    test('a start after the lease moved gets ports in the new one', () async {
      h.addSpace('space-2');
      h.store(definitionJson([webJson()]));
      await h.ensure();
      await h.service.stop('ws-a', 'space-1', by: principal);
      await h.service.start(runRecovery: false);
      h.events.publish(
        SpaceArchived(
          spaceId: 'space-1',
          workspaceId: 'ws-a',
          occurredAt: h.now,
        ),
      );
      await h.until(() => h.leases.leases.isEmpty);
      await h.ensure(space: 'space-2');
      final env = await h.ensure();
      final lease = h.leases.leases.firstWhere(
        (item) => item.spaceId == 'space-1',
      );
      expect(lease.block, 1);
      expect(lease.ports, contains(env.ports['web']));
    });

    test('a release during a first start tears down what it wrote', () async {
      final held = Completer<void>();
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('config')) {
          await held.future;
        }
      };
      h.store(definitionJson([composeJson()]));
      final starting = h.ensure();
      await h.until(() => h.runner.calls.isNotEmpty);
      final releasing = h.service.beforeRelease('ws-a', 'space-1');
      await expectLater(h.ensure(), driverError('space-releasing'));
      held.complete();
      await starting;
      await releasing;
      expect(h.environments.rows, isEmpty);
      expect(h.leases.leases, isEmpty);
    });

    test('maintenance tears down a row whose space is gone', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.directory.spaces.remove('space-1');
      await h.service.runMaintenance();
      expect(h.environments.rows, isEmpty);
    });

    group('stop and destroy without a definition', () {
      setUp(() async {
        h.store(definitionJson([composeJson(), webJson()]));
        await h.ensure();
        h.store({
          ...definitionJson([composeJson(), webJson()]),
          'contract': 99,
        });
        h.runner.calls.clear();
      });

      bool byLabel(String verb) => h.runner.calls.any(
        (call) =>
            call.argv.contains(verb) &&
            !call.argv.contains('-f') &&
            call.argv.contains('-p'),
      );

      test('stop stops by project label', () async {
        final env = await h.service.stop('ws-a', 'space-1', by: principal);
        expect(byLabel('stop'), isTrue);
        expect(env.status, EnvironmentStatus.stopped);
        expect(env.warnings.last, contains('without its definition'));
        expect(h.terminals.last.exit.isCompleted, isTrue);
      });

      test('destroy destroys by project label', () async {
        await h.service.destroy('ws-a', 'space-1', by: principal);
        expect(byLabel('down'), isTrue);
        expect(h.environments.rows, isEmpty);
        expect(h.leases.leases, isEmpty);
      });
    });

    test('a vanished compose file still lets it stop', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      File('$root/worktrees/space-1/compose.yaml').deleteSync();
      h.runner.calls.clear();
      final env = await h.service.stop('ws-a', 'space-1', by: principal);
      expect(env.status, EnvironmentStatus.stopped);
    });

    test('recover goes on past a broken workspace', () async {
      h.environments.broken.add('ws-a');
      await h.service.recover();
      expect(h.runs.interruptedSweeps, contains('ws-b'));
    });

    test('start listens even when recovery fails', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.environments.broken.add('ws-b');
      h.directory.repos['ws-broken'] = const [];
      await h.service.start();
      h.events.publish(
        SpaceDeleted(
          spaceId: 'space-1',
          workspaceId: 'ws-a',
          occurredAt: h.now,
        ),
      );
      await h.until(() => h.environments.rows.isEmpty);
    });

    test('listeners are up before recovery runs', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      final held = Completer<void>();
      h.runner.beforeAnswer = (call) async {
        if (call.argv.length > 1 && call.argv[1] == 'ps') {
          await held.future;
        }
      };
      final starting = h.service.start();
      await h.until(
        () => h.runner.calls.any((c) => c.argv.length > 1 && c.argv[1] == 'ps'),
      );
      h.events.publish(
        SpaceDeleted(
          spaceId: 'space-1',
          workspaceId: 'ws-a',
          occurredAt: h.now,
        ),
      );
      await h.until(() => h.environments.rows.isEmpty);
      held.complete();
      await starting;
    });

    group('rigs that went away', () {
      late FakeRigHost rig;

      setUp(() async {
        rig = FakeRigHost();
        h = ServiceHarness(root, rigHost: rig);
        h.store(definitionJson([composeJson()], extra: {'placement': 'rig'}));
        await h.ensure();
        rig.running = false;
      });

      test('are noticed by maintenance', () async {
        await h.service.runMaintenance();
        expect(row().status, EnvironmentStatus.failed);
        expect(row().lastError?.code, 'rig-gone');
      });

      test('are noticed at boot', () async {
        await h.service.recover();
        expect(row().status, EnvironmentStatus.failed);
      });
    });

    test('a running task keeps an idle environment up', () async {
      h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'policy': {'idleStopMinutes': 30},
          },
        ),
      );
      final env = await h.ensure();
      await h.runs.start(
        EnvironmentRun(
          id: 'run-1',
          workspaceId: 'ws-a',
          spaceId: 'space-1',
          environmentId: env.id,
          kind: EnvironmentRunKind.task,
          status: EnvironmentRunStatus.running,
          startedAt: h.now,
        ),
      );
      h.now = h.now.add(const Duration(hours: 2));
      await h.service.runMaintenance();
      expect(row().status, EnvironmentStatus.ready);
    });

    test('a recent run counts as activity', () async {
      h.store(
        definitionJson(
          [composeJson()],
          extra: {
            'policy': {'idleStopMinutes': 30},
          },
        ),
      );
      final env = await h.ensure();
      h.now = h.now.add(const Duration(hours: 2));
      await h.runs.start(
        EnvironmentRun(
          id: 'run-1',
          workspaceId: 'ws-a',
          spaceId: 'space-1',
          environmentId: env.id,
          kind: EnvironmentRunKind.task,
          status: EnvironmentRunStatus.succeeded,
          startedAt: h.now.subtract(const Duration(minutes: 5)),
          completedAt: h.now.subtract(const Duration(minutes: 4)),
        ),
      );
      await h.service.runMaintenance();
      expect(row().status, EnvironmentStatus.ready);
    });

    test('refresh needs a running environment', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      await h.service.stop('ws-a', 'space-1', by: principal);
      h.runner.calls.clear();
      await expectLater(
        h.service.refresh('ws-a', 'space-1', by: principal),
        driverError('not-running'),
      );
      expect(h.commands, isEmpty);
    });

    test('refresh right after a start changes nothing', () async {
      h.store(definitionJson([composeJson()]));
      await h.ensure();
      h.runner.calls.clear();
      await h.service.refresh('ws-a', 'space-1', by: principal);
      expect(h.commands, isEmpty, reason: 'no needless --build');
    });

    test(
      'one invalid definition doesn\'t stop another\'s provisioning',
      () async {
        h.store(
          definitionJson([
            taskJson('deps', ['provision']),
          ]),
          id: 'owner',
        );
        h.store({
          ...definitionJson([composeJson()]),
          'contract': 99,
        }, id: 'broken');
        await h.service.runProvision(
          WorktreeTaskContext(
            workspaceId: 'ws-a',
            repoId: 'repo-app',
            worktreePath: '$root/worktrees/space-1',
            sourcePath: h.sourcePath,
            spaceId: 'space-1',
          ),
        );
        expect(h.commands, ['tool deps']);
      },
    );

    test(
      'compose plans first with stand-ins, then with the real values',
      () async {
        h.store(
          definitionJson(
            [composeJson()],
            extra: {
              'env': {'DB_URL': 'postgres://127.0.0.1:{port.db.5432}/app'},
            },
          ),
        );
        final env = await h.ensure();
        final configs = h.runner.calls
            .where((call) => call.argv.contains('config'))
            .map((call) => call.environment['DB_URL'])
            .toList();
        expect(configs, [
          'postgres://127.0.0.1:0/app',
          'postgres://127.0.0.1:${env.ports['db.5432']}/app',
        ]);
      },
    );

    test(
      'a failed readiness probe gets another go on the next Start',
      () async {
        final supervisor = h.supervisor;
        h.store(
          definitionJson([
            webJson(
              extra: {
                'ready': {'logMatch': 'listening', 'timeout': 1},
              },
            ),
          ]),
        );
        final first = await h.ensure();
        expect(first.status, EnvironmentStatus.failed);
        h.terminals.last.print('listening\r\n');
        final second = await h.ensure();
        expect(second.status, EnvironmentStatus.ready);
        expect(supervisor.stateOf(first.id, 'web')?.state, 'ready');
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });

  group('workspace isolation', () {
    // space-b lives in ws-b. Every call below names ws-a.
    const by = principal;
    final wrongWorkspace = throwsA(isA<WorkspaceMismatchException>());

    final calls = <String, Future<Object?> Function(ServiceHarness h)>{
      'eligibleDefinitions': (h) =>
          h.service.eligibleDefinitions('ws-a', 'space-b'),
      'environmentsFor': (h) => h.service.environmentsFor('ws-a', 'space-b'),
      'watch': (h) => h.service.watch('ws-a', 'space-b').first,
      'ensure': (h) =>
          h.service.ensure(workspaceId: 'ws-a', spaceId: 'space-b', by: by),
      'stop': (h) => h.service.stop('ws-a', 'space-b', by: by),
      'reset': (h) => h.service.reset('ws-a', 'space-b', by: by),
      'refresh': (h) => h.service.refresh('ws-a', 'space-b', by: by),
      'destroy': (h) => h.service.destroy('ws-a', 'space-b', by: by),
      'restart': (h) => h.service.restart('ws-a', 'space-b', 'web', by: by),
      'stopProcess': (h) =>
          h.service.stopProcess('ws-a', 'space-b', 'web', by: by),
      'exec': (h) => h.service.exec(
        'ws-a',
        'space-b',
        service: 'db',
        command: const ['ls'],
        by: by,
      ),
      'logs': (h) => h.service.logs('ws-a', 'space-b', target: 'web'),
      'followLogs': (h) =>
          h.service.followLogs('ws-a', 'space-b', target: 'web').first,
      'runTask': (h) => h.service.runTask('ws-a', 'space-b', 'lint', by: by),
      'runs': (h) => h.service.runs('ws-a', 'space-b'),
      'launchApp': (h) =>
          h.service.launchApp('ws-a', 'space-b', 'desktop', by: by),
      'stopApp': (h) => h.service.stopApp('ws-a', 'space-b', 'desktop', by: by),
      'terminalEnvironment': (h) =>
          h.service.terminalEnvironment('ws-a', 'space-b'),
      'sandboxLoopbackPorts': (h) =>
          h.service.sandboxLoopbackPorts('ws-a', 'space-b'),
      'agentShimTools': (h) => h.service.agentShimTools('ws-a', 'space-b'),
      'sandboxHosts': (h) => h.service.sandboxHosts('ws-a', 'space-b'),
      'definitionFor': (h) => h.service.definitionFor('ws-a', 'space-b'),
      'nameFor': (h) => h.service.nameFor('ws-a', 'space-b'),
      'worktreeRoots': (h) => h.service.worktreeRoots('ws-a', 'space-b'),
      'workingDirectory': (h) => h.service.workingDirectory('ws-a', 'space-b'),
      'runProvision': (h) => h.service.runProvision(
        const WorktreeTaskContext(
          workspaceId: 'ws-a',
          repoId: 'repo-b',
          worktreePath: '/w',
          sourcePath: '/s',
          spaceId: 'space-b',
        ),
      ),
    };

    Future<void> startEnvironmentInB() async {
      h.store(
        definitionJson(
          [composeJson(), webJson()],
          repos: {
            'app': {'repoId': 'repo-b', 'anchor': true, 'required': true},
          },
        ),
        workspace: 'ws-b',
      );
      await h.ensure(space: 'space-b');
    }

    for (final entry in calls.entries) {
      test('${entry.key} refuses a space of another workspace', () async {
        await startEnvironmentInB();
        h.runner.calls.clear();
        await expectLater(entry.value(h), wrongWorkspace);
        expect(h.commands, isEmpty);
      });
    }

    test('the list above covers the whole port', () {
      // Methods that take a space. Anything added to EnvironmentPort or
      // AgentEnvironmentContext with a spaceId belongs in `calls`.
      expect(calls, hasLength(26));
    });

    test('definitions are scoped too', () async {
      await startEnvironmentInB();
      expect(await h.service.listDefinitions('ws-a'), isEmpty);
      expect(await h.service.definition('ws-a', 'def-1'), isNull);
      await expectLater(
        h.service.check('ws-a', 'def-1'),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        h.service.testDefinition('ws-a', 'def-1'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('watch only hears its own space', () async {
      h.store(definitionJson([composeJson()]));
      await startEnvironmentInB();
      final seen = <List<SpaceEnvironment>>[];
      final subscription = h.service.watch('ws-a', 'space-1').listen(seen.add);
      await h.until(() => seen.length == 1);
      await h.service.stop('ws-b', 'space-b', by: by);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(seen, hasLength(1));
      await subscription.cancel();
    });

    test('routes carry the owning workspace', () async {
      await startEnvironmentInB();
      final routes = h.routing.routes.values.single.values;
      expect(routes.map((route) => route.workspaceId).toSet(), {'ws-b'});
    });
  });
}
