import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_infra/src/environments/compose_driver.dart';
import 'package:cc_infra/src/environments/compose_plan.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_lease_allocator.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'helpers/environment_fakes.dart';

const _envId = '3f2a9c1e-7b41-4c1d-9e55-000000000001';

void main() {
  late Directory dir;
  late String worktree;
  late String stateDir;
  late Map<String, dynamic> model;
  late List<String> psOutputs;
  late Map<String, int> gitExits;
  late FakeCommandRunner runner;
  late ComposeDriver driver;

  final lease = EnvironmentLease(
    block: 0,
    firstPort: 42000,
    size: 32,
    workspaceId: 'ws-1',
    spaceId: 'space-1',
    definitionId: 'def',
    createdAt: DateTime(2026),
  );

  EnvironmentCommandResult answer(FakeCall call) {
    final argv = call.argv;
    if (argv.first == 'git') {
      return EnvironmentCommandResult(
        exitCode: gitExits[argv.last] ?? 1,
        display: 'git',
      );
    }
    if (argv.contains('config')) {
      return ok(jsonEncode(model));
    }
    if (argv.contains('ps')) {
      final next = psOutputs.length > 1 ? psOutputs.removeAt(0) : psOutputs[0];
      return ok(next);
    }
    if (argv.contains('logs')) {
      return ok('last words');
    }
    return ok();
  }

  setUp(() {
    dir = tempDir(addTearDown);
    worktree = '${dir.path}/worktree';
    stateDir = '${dir.path}/state';
    Directory(worktree).createSync();
    File('$worktree/compose.yaml').writeAsStringSync('services: {}\n');
    model = {
      'name': 'shop',
      'services': <String, dynamic>{
        'db': {
          'image': 'postgres',
          'container_name': 'shop-db',
          'ports': [
            {'target': 5432, 'published': '5432', 'protocol': 'tcp'},
          ],
        },
        'cache': {
          'image': 'redis',
          'ports': [
            {'target': 6379, 'protocol': 'tcp'},
          ],
        },
        'web': {
          'image': 'nginx',
          'depends_on': {
            'db': {'condition': 'service_started'},
          },
          'ports': [
            {'target': 80, 'published': '8080', 'protocol': 'tcp'},
            {'target': 53, 'published': '53', 'protocol': 'udp'},
          ],
        },
      },
    };
    psOutputs = [''];
    gitExits = {};
    runner = FakeCommandRunner(answer);
    driver = ComposeDriver(
      runner: runner,
      pollInterval: const Duration(milliseconds: 10),
      httpProbe: (uri) async => null,
    );
  });

  ComposeContext context({
    ComposeEnvironmentComponent? component,
    bool untrusted = false,
    List<String>? roots,
  }) => ComposeContext(
    component: component ?? ComposeEnvironmentComponent(id: 'stack'),
    environmentId: _envId,
    workspaceId: 'ws-1',
    spaceId: 'space-1',
    stateDir: stateDir,
    workingDirectory: worktree,
    environment: const {'CC_ENV_NAME': 'fix-login'},
    allowedRoots: roots ?? [worktree],
    untrusted: untrusted,
  );

  Future<ComposePlan> plan({
    ComposeEnvironmentComponent? component,
    Map<String, int> existing = const {},
    bool untrusted = false,
    List<String>? roots,
  }) => driver.plan(
    context(component: component, untrusted: untrusted, roots: roots),
    lease: lease,
    existingPorts: existing,
  );

  Matcher failsWith(String code, [Object? message]) => throwsA(
    isA<EnvironmentDriverException>()
        .having((e) => e.error.code, 'code', code)
        .having((e) => e.error.message, 'message', message ?? anything),
  );

  group('names', () {
    test('project is cc- and the first 12 of the id', () {
      expect(composeProjectName(_envId), 'cc-3f2a9c1e-7b4');
    });

    test('COMPOSE_FILE is absolute, in order, with the platform separator', () {
      expect(
        composeVariables(
          environmentId: _envId,
          stateDir: '/state',
          composeFile: '/w/compose.yaml',
          pathSeparator: ':',
        ),
        {
          'COMPOSE_PROJECT_NAME': 'cc-3f2a9c1e-7b4',
          'COMPOSE_FILE': '/w/compose.yaml:/state/compose.override.yaml',
        },
      );
      expect(
        composeVariables(
          environmentId: _envId,
          stateDir: '/state',
          composeFile: '/w/compose.yaml',
          pathSeparator: ';',
        )['COMPOSE_FILE'],
        contains(';'),
      );
    });
  });

  group('discovery', () {
    test('prefers names in compose\'s own order', () {
      File('$worktree/compose.yaml').deleteSync();
      for (final name in composeFileNames.reversed) {
        File('$worktree/$name').writeAsStringSync('');
        expect(discoverComposeFile(worktree), '$worktree/$name');
      }
    });

    test('an explicit file wins and must exist', () {
      File('$worktree/ops.yaml').writeAsStringSync('');
      expect(
        discoverComposeFile(worktree, explicit: 'ops.yaml'),
        '$worktree/ops.yaml',
      );
      expect(
        () => discoverComposeFile(worktree, explicit: 'nope.yaml'),
        failsWith('compose-file-missing'),
      );
    });

    test('an explicit file can\'t climb out', () {
      expect(
        () => discoverComposeFile(worktree, explicit: '../compose.yaml'),
        failsWith('compose-file-invalid'),
      );
    });

    test('no file names what it looked for', () {
      File('$worktree/compose.yaml').deleteSync();
      expect(
        () => discoverComposeFile(worktree),
        failsWith('compose-file-missing', contains('docker-compose.yml')),
      );
    });
  });

  group('remote resources', () {
    Future<void> expectRefused(String yaml) async {
      File('$worktree/compose.yaml').writeAsStringSync(yaml);
      await expectLater(plan(), failsWith('compose-remote-include'));
      expect(runner.calls, isEmpty, reason: 'refused before config fetches');
    }

    test(
      'oci include',
      () => expectRefused('''
include:
  - oci://registry.example/shop:latest
services: {}
'''),
    );

    test(
      'git include in the long form',
      () => expectRefused('''
include:
  - path: https://example.test/acme/shop.git
services: {}
'''),
    );

    test(
      'include with a list of paths',
      () => expectRefused('''
include:
  - path:
      - base.yaml
      - git@example.test:acme/shop.git
services: {}
'''),
    );

    test(
      'remote extends',
      () => expectRefused('''
services:
  web:
    extends:
      file: oci://registry.example/shop:latest
      service: web
'''),
    );

    test('behind a local include', () async {
      File('$worktree/base.yaml').writeAsStringSync('''
include:
  - oci://registry.example/shop:latest
''');
      await expectRefused('''
include:
  - base.yaml
services: {}
''');
    });

    test('a local include is fine, even a cycle', () async {
      File('$worktree/base.yaml').writeAsStringSync('include: [compose.yaml]');
      File('$worktree/compose.yaml').writeAsStringSync('''
include:
  - base.yaml
services: {}
''');
      await plan();
      expect(runner.callsWith('config'), hasLength(1));
    });

    test(
      'compose itself is told to refuse, for what a scan can\'t see',
      () async {
        await plan();
        final environment = runner.callsWith('config').single.environment;
        expect(environment['COMPOSE_EXPERIMENTAL_OCI_REMOTE'], '0');
        expect(environment['COMPOSE_EXPERIMENTAL_GIT_REMOTE'], '0');
      },
    );
  });

  group('plan', () {
    test('resolves the model with the project and in the worktree', () async {
      await plan();
      final call = runner.callsWith('config').single;
      expect(call.argv, [
        'docker',
        'compose',
        '-p',
        'cc-3f2a9c1e-7b4',
        '-f',
        '$worktree/compose.yaml',
        'config',
        '--format',
        'json',
      ]);
      expect(call.workingDirectory, worktree);
      expect(call.environment['CC_ENV_NAME'], 'fix-login');
    });

    test('a config failure says why', () async {
      runner.handler = (_) =>
          failed(1, stderr: 'env file .env.local not found');
      await expectLater(
        plan(),
        failsWith('compose-config-failed', contains('.env.local')),
      );
    });

    test('every service by default', () async {
      expect((await plan()).services, ['db', 'cache', 'web']);
    });

    test('selected services bring their dependencies, nothing else', () async {
      final result = await plan(
        component: ComposeEnvironmentComponent(
          id: 'stack',
          services: const ['web'],
        ),
      );
      expect(result.services, ['db', 'web']);
      expect(result.overrideYaml, isNot(contains('cache')));
      expect(result.ports.keys, isNot(contains('cache.6379')));
    });

    test('an unknown service is an error naming the real ones', () async {
      await expectLater(
        plan(
          component: ComposeEnvironmentComponent(
            id: 'stack',
            services: const ['nope'],
          ),
        ),
        failsWith('compose-unknown-service', contains('cache')),
      );
    });

    test('assigns every published target, sorted, published or not', () async {
      final result = await plan();
      expect(result.ports, {
        'cache.6379': 42000,
        'db.5432': 42001,
        'web.53': 42002,
        'web.80': 42003,
      });
    });

    test('existing assignments never move', () async {
      final result = await plan(
        existing: const {'db.5432': 42010, 'named': 42000},
      );
      expect(result.ports['db.5432'], 42010);
      expect(result.ports['named'], 42000);
      expect(result.ports['cache.6379'], 42001);
    });

    test('fixed ports with replicas are refused', () async {
      ((model['services'] as Map)['web'] as Map)['deploy'] = {'replicas': 3};
      await expectLater(
        plan(),
        failsWith('compose-replicas-ports', contains('3 replicas')),
      );
    });

    test('replicas with no published port are fine', () async {
      (model['services'] as Map)['cache'] = {
        'image': 'redis',
        'deploy': {'replicas': 3},
      };
      await plan();
    });

    test('parses what redaction would have broken', () async {
      ((model['services'] as Map)['web'] as Map)['environment'] = {
        'AUTH': 'Authorization: Bearer abc',
      };
      runner.handler = (call) => call.argv.contains('config')
          ? EnvironmentCommandResult(
              exitCode: 0,
              display: 'docker',
              stdout: 'redacted and broken',
              rawStdout: jsonEncode(model),
            )
          : answer(call);
      expect((await plan()).services, contains('web'));
    });

    test('a full block is a clear error', () async {
      await expectLater(
        driver.plan(
          context(),
          lease: EnvironmentLease(
            block: 0,
            firstPort: 42000,
            size: 2,
            workspaceId: 'ws-1',
            spaceId: 'space-1',
            definitionId: 'def',
            createdAt: DateTime(2026),
          ),
        ),
        throwsA(isA<EnvironmentLeaseException>()),
      );
    });

    test('a healthcheck for an unselected service is a warning', () async {
      final result = await plan(
        component: ComposeEnvironmentComponent(
          id: 'stack',
          services: const ['db'],
          healthchecks: const {
            'cache': ['redis-cli', 'ping'],
          },
        ),
      );
      expect(result.warnings.single, contains('cache'));
      expect(result.overrideYaml, isNot(contains('redis-cli')));
    });
  });

  group('override', () {
    test('has the exact shape compose needs', () async {
      final result = await plan(
        component: ComposeEnvironmentComponent(
          id: 'stack',
          services: const ['db'],
          healthchecks: const {
            'db': ['pg_isready', '-U', 'postgres'],
          },
          timeoutSeconds: 60,
        ),
      );
      expect(result.overrideYaml, '''
# Generated by Control Center. Changes are overwritten.
services:
  "db":
    container_name: !reset null
    labels:
      cc.env: "$_envId"
      cc.workspace: "ws-1"
      cc.space: "space-1"
    ports: !override
      - "127.0.0.1:42000:5432"
    healthcheck:
      test: ["CMD","pg_isready","-U","postgres"]
      interval: 2s
      retries: 30
''');
    });

    test('binds loopback only, and keeps the protocol', () async {
      final result = await plan();
      expect(result.overrideYaml, contains('"127.0.0.1:42003:80"'));
      expect(result.overrideYaml, contains('"127.0.0.1:42002:53/udp"'));
      expect(
        RegExp(
          r'^\s+- "(?!127\.0\.0\.1:)',
          multiLine: true,
        ).hasMatch(result.overrideYaml),
        isFalse,
      );
    });

    test('a service with no ports gets no ports key', () async {
      (model['services'] as Map)['cache'] = {'image': 'redis'};
      final result = await plan(
        component: ComposeEnvironmentComponent(
          id: 'stack',
          services: const ['cache'],
        ),
      );
      expect(result.overrideYaml, isNot(contains('ports')));
    });

    test('is valid YAML whatever a value holds', () async {
      final result = await plan(
        component: ComposeEnvironmentComponent(
          id: 'stack',
          services: const ['db'],
          healthchecks: const {
            'db': ['sh', '-c', 'echo "a: b" # not a comment\n'],
          },
        ),
      );
      final yaml = loadYaml(result.overrideYaml) as YamlMap;
      final service = (yaml['services'] as YamlMap)['db'] as YamlMap;
      expect(
        ((service['healthcheck'] as YamlMap)['test'] as YamlList).last,
        'echo "a: b" # not a comment\n',
      );
    });
  });

  group('preflight', () {
    void bindSource(String source, {String service = 'web'}) {
      final services = model['services'] as Map;
      (services[service] as Map)['volumes'] = [
        {'type': 'bind', 'source': source, 'target': '/data'},
      ];
    }

    test('a missing gitignored bind names the file and the fix', () async {
      final source = '$worktree/docker/seed.sh';
      bindSource(source);
      gitExits[source] = 0;
      final result = await driver.preflight(await plan());
      expect(result.ok, isFalse);
      final bind = result.missingBinds.single;
      expect(bind.gitignored, isTrue);
      expect(bind.message, contains('docker/seed.sh'));
      expect(bind.message, contains('gitignored'));
      expect(bind.message, contains('seedFiles'));
      expect(
        result.throwIfBlocked,
        failsWith('compose-missing-bind', contains('Service web')),
      );
      final check = runner.callsWith('check-ignore').single;
      expect(check.workingDirectory, worktree);
    });

    test('a missing tracked bind says so', () async {
      bindSource('$worktree/data.txt');
      gitExits['$worktree/data.txt'] = 1;
      final bind = (await driver.preflight(await plan())).missingBinds.single;
      expect(bind.gitignored, isFalse);
      expect(bind.message, contains('not gitignored'));
    });

    test('outside a git repo it can\'t tell, and doesn\'t pretend', () async {
      bindSource('$worktree/data.txt');
      gitExits['$worktree/data.txt'] = 128;
      final bind = (await driver.preflight(await plan())).missingBinds.single;
      expect(bind.gitignored, isNull);
    });

    test('an existing bind passes', () async {
      File('$worktree/data.txt').writeAsStringSync('');
      bindSource('$worktree/data.txt');
      final result = await driver.preflight(await plan());
      expect(result.ok, isTrue);
      expect(result.warnings, isEmpty);
    });

    test('only planned services are checked', () async {
      bindSource('$worktree/absent', service: 'cache');
      final result = await driver.preflight(
        await plan(
          component: ComposeEnvironmentComponent(
            id: 'stack',
            services: const ['web'],
          ),
        ),
      );
      expect(result.missingBinds, isEmpty);
    });

    group('policy', () {
      Future<List<String>> rules(Map<String, Object?> settings) async {
        (model['services'] as Map)['web'] = {'image': 'nginx', ...settings};
        final result = await driver.preflight(await plan());
        return result.warnings.map((finding) => finding.rule).toList();
      }

      test('privileged', () async {
        expect(await rules({'privileged': true}), ['privileged']);
      });

      test('host namespaces', () async {
        expect(
          await rules({'pid': 'host', 'network_mode': 'host', 'ipc': 'host'}),
          ['host-pid', 'host-network', 'host-ipc'],
        );
      });

      test('devices', () async {
        expect(
          await rules({
            'devices': [
              {'source': '/dev/kvm', 'target': '/dev/kvm'},
            ],
          }),
          ['devices'],
        );
      });

      test('the Docker socket, which needn\'t exist to count', () async {
        final services = await rules({
          'volumes': [
            {
              'type': 'bind',
              'source': '/nonexistent/run/docker.sock',
              'target': '/var/run/docker.sock',
            },
          ],
        });
        expect(services, ['docker-socket']);
      });

      test('a bind outside the worktrees', () async {
        expect(
          await rules({
            'volumes': [
              {'type': 'bind', 'source': '/etc', 'target': '/host-etc'},
            ],
          }),
          ['bind-outside-worktree'],
        );
      });

      test('a link in the worktree pointing out', () async {
        Link('$worktree/link').createSync('/etc');
        expect(
          await rules({
            'volumes': [
              {'type': 'bind', 'source': '$worktree/link', 'target': '/x'},
            ],
          }),
          ['bind-outside-worktree'],
        );
      });

      test('a named volume that is really a bind', () async {
        model['volumes'] = {
          'host': {
            'driver_opts': {'type': 'none', 'o': 'bind', 'device': '/etc'},
          },
        };
        expect(
          await rules({
            'volumes': [
              {'type': 'volume', 'source': 'host', 'target': '/x'},
            ],
          }),
          ['bind-outside-worktree'],
        );
      });

      test('joining another container\'s namespaces', () async {
        expect(
          await rules({
            'network_mode': 'container:other',
            'pid': 'container:other',
            'ipc': 'container:other',
          }),
          everyElement('container-namespace'),
        );
      });

      test('the remaining host namespaces', () async {
        expect(
          await rules({'userns_mode': 'host', 'cgroup': 'host', 'uts': 'host'}),
          ['host-userns', 'host-cgroup', 'host-uts'],
        );
      });

      test('volumes_from', () async {
        expect(
          await rules({
            'volumes_from': ['other'],
          }),
          ['volumes-from'],
        );
      });

      test('capabilities that open the host, in any spelling', () async {
        for (final capability in [
          'SYS_ADMIN',
          'DAC_READ_SEARCH',
          'ALL',
          'cap_sys_admin',
          'CAP_SYS_MODULE',
        ]) {
          expect(
            await rules({
              'cap_add': [capability],
            }),
            ['capability'],
            reason: capability,
          );
        }
      });

      test('security options that turn confinement off', () async {
        for (final option in [
          'seccomp=unconfined',
          'seccomp:unconfined',
          'apparmor=unconfined',
          'systempaths=unconfined',
          'label=disable',
        ]) {
          expect(
            await rules({
              'security_opt': [option],
            }),
            ['security-opt'],
            reason: option,
          );
        }
      });

      test('a build outside the worktrees', () async {
        expect(
          await rules({
            'build': {'context': '/etc'},
          }),
          ['build-context'],
        );
        expect(
          await rules({
            'build': {
              'context': worktree,
              'additional_contexts': {'home': '/Users/me'},
            },
          }),
          ['build-context'],
        );
      });

      test('a build from a URL can\'t pass for a path', () async {
        expect(
          await rules({
            'build': {'context': 'https://example.com/repo.git'},
          }),
          ['build-context'],
        );
      });

      test('a build inside the worktrees, and image contexts', () async {
        expect(
          await rules({
            'build': {
              'context': '$worktree/app',
              'additional_contexts': {
                'base': 'docker-image://alpine:3',
                'tools': 'service:tools',
                'shared': '$worktree/shared',
              },
            },
          }),
          isEmpty,
        );
      });

      test('a build that asks for more than a build', () async {
        expect(
          await rules({
            'build': {
              'context': worktree,
              'ssh': ['default'],
              'privileged': true,
              'entitlements': ['network.host'],
              'network': 'host',
            },
          }),
          ['build-ssh', 'privileged', 'build-entitlement', 'host-network'],
        );
      });

      test('a secret or config read from outside the worktrees', () async {
        model['secrets'] = {
          'key': {'file': '/Users/me/.ssh/id_ed25519'},
        };
        model['configs'] = {
          'inside': {'file': '$worktree/app.conf'},
        };
        final subject = await driver.preflight(await plan());
        expect(subject.warnings.single.rule, 'secret-file');
        expect(subject.warnings.single.service, isNull);
        expect(subject.warnings.single.message, startsWith('The stack reads'));
      });

      test('an external volume', () async {
        model['volumes'] = {
          'shared': {'name': 'cc-other_data', 'external': true},
        };
        expect(await rules({}), ['external-volume']);
      });

      test('GPUs through deploy', () async {
        expect(
          await rules({
            'deploy': {
              'resources': {
                'reservations': {
                  'devices': [
                    {
                      'capabilities': ['gpu'],
                    },
                  ],
                },
              },
            },
          }),
          ['devices'],
        );
      });

      test(
        'a trusted stack can keep what only the allowlist refuses',
        () async {
          model['networks'] = {
            'proxy': {'name': 'traefik', 'external': true},
          };
          expect(
            await rules({
              'use_api_socket': false,
              'gpus': 'all',
              'network_mode': 'proxy',
              'logging': {'driver': 'syslog'},
              'security_opt': ['seccomp=profile.json'],
            }),
            isEmpty,
          );
        },
      );

      test('a plain named volume and cap_add are fine', () async {
        model['volumes'] = {'data': <String, Object?>{}};
        expect(
          await rules({
            'cap_add': ['IPC_LOCK'],
            'volumes': [
              {'type': 'volume', 'source': 'data', 'target': '/x'},
            ],
          }),
          isEmpty,
        );
      });

      group('of an untrusted stack', () {
        Future<List<String>> refused(Map<String, Object?> settings) async {
          (model['services'] as Map)['web'] = {'image': 'nginx', ...settings};
          final result = await driver.preflight(await plan(untrusted: true));
          return result.refusals.map((finding) => finding.rule).toList();
        }

        test('an ordinary dev stack passes', () async {
          Directory('$worktree/src').createSync();
          File('$worktree/.env.dev').createSync();
          model['networks'] = {
            'default': {'name': 'shop_default', 'ipam': <String, Object?>{}},
          };
          model['volumes'] = {
            'data': {'name': 'shop_data'},
          };
          model['configs'] = {
            'motd': {'name': 'shop_motd', 'content': 'hello'},
          };
          expect(
            await refused({
              'build': {
                'context': worktree,
                'dockerfile': 'Dockerfile.dev',
                'args': {'NODE_VERSION': '22'},
                'target': 'dev',
                'cache_from': ['ghcr.io/acme/shop:cache'],
              },
              'command': ['npm', 'run', 'dev'],
              'entrypoint': ['/entrypoint.sh'],
              'environment': {'NODE_ENV': 'development'},
              'env_file': [
                {'path': '$worktree/.env.dev'},
              ],
              'ports': [
                {'target': 3000, 'protocol': 'tcp'},
              ],
              'expose': ['3000'],
              'depends_on': {
                'db': {'condition': 'service_healthy', 'required': true},
              },
              'healthcheck': {
                'test': ['CMD', 'true'],
                'interval': '2s',
              },
              'labels': {'app': 'shop'},
              'volumes': [
                {'type': 'bind', 'source': '$worktree/src', 'target': '/src'},
                {'type': 'volume', 'source': 'data', 'target': '/data'},
                {'type': 'tmpfs', 'target': '/tmp/x'},
              ],
              'networks': {'default': null},
              'configs': [
                {'source': 'motd'},
              ],
              'restart': 'unless-stopped',
              'user': 'node',
              'working_dir': '/src',
              'init': true,
              'tty': true,
              'stdin_open': true,
              'cap_add': ['IPC_LOCK', 'NET_BIND_SERVICE'],
              'cap_drop': ['ALL'],
              'security_opt': ['no-new-privileges:true'],
              'ulimits': {'nofile': 65536},
              'logging': {'driver': 'json-file'},
              'network_mode': 'bridge',
              'x-note': 'mine',
            }),
            isEmpty,
          );
        });

        test('a setting nobody has read yet is refused', () async {
          expect(await refused({'use_api_socket': true}), ['key-not-allowed']);
          expect(await refused({'some_future_key': 1}), ['key-not-allowed']);
          expect(
            await refused({
              'post_start': [
                {
                  'command': ['id'],
                  'privileged': true,
                },
              ],
            }),
            ['key-not-allowed'],
          );
          expect(
            await refused({
              'build': {'context': worktree, 'output': 'type=local,dest=/x'},
            }),
            ['key-not-allowed'],
          );
        });

        test('so is a top-level one, naming no service', () async {
          model['models'] = {'llm': <String, Object?>{}};
          final result = await driver.preflight(await plan(untrusted: true));
          expect(result.refusals.single.rule, 'key-not-allowed');
          expect(result.refusals.single.service, isNull);
        });

        test('a secret file is refused even inside the worktree', () async {
          model['secrets'] = {
            'key': {'file': '$worktree/key'},
          };
          expect(await refused({}), ['secret-file']);
        });

        test('a secret from the server\'s environment is refused', () async {
          model['secrets'] = {
            'key': {'environment': 'GITHUB_TOKEN'},
          };
          expect(await refused({}), ['key-not-allowed']);
        });

        test('an env file outside the worktrees', () async {
          expect(
            await refused({
              'env_file': [
                {'path': '/Users/me/.aws/credentials'},
              ],
            }),
            ['env-file-outside-worktree'],
          );
        });

        test('an env file is seen even once config has folded it', () async {
          (model['services'] as Map)['web'] = {'image': 'nginx'};
          runner.handler = (call) {
            if (!call.argv.contains('--no-env-resolution')) {
              return answer(call);
            }
            return ok(
              jsonEncode({
                ...model,
                'services': {
                  ...model['services'] as Map,
                  'web': {
                    'image': 'nginx',
                    'env_file': [
                      {'path': '/Users/me/.aws/credentials'},
                    ],
                  },
                },
              }),
            );
          };
          final subject = await plan(untrusted: true);
          expect(subject.envFiles['web'], ['/Users/me/.aws/credentials']);
          final result = await driver.preflight(subject);
          expect(result.refusals.single.rule, 'env-file-outside-worktree');
          expect(
            (await driver.preflight(
              subject.withEnvironment(const {}),
            )).refusals,
            hasLength(1),
          );
        });

        test('a Compose that can\'t show env files stops the start', () async {
          runner.handler = (call) => call.argv.contains('--no-env-resolution')
              ? failed(1, stderr: 'unknown flag: --no-env-resolution')
              : answer(call);
          await expectLater(
            plan(untrusted: true),
            failsWith('compose-config-failed'),
          );
        });

        test('a trusted stack costs no second config', () async {
          await plan();
          expect(runner.callsWith('config'), hasLength(1));
          expect(
            runner.callsWith('config').single.argv,
            isNot(contains('--no-env-resolution')),
          );
        });

        test('a Dockerfile outside the worktrees', () async {
          expect(
            await refused({
              'build': {'context': worktree, 'dockerfile': '../../etc/passwd'},
            }),
            ['build-context'],
          );
        });

        test('a build cache on the host', () async {
          expect(
            await refused({
              'build': {
                'context': worktree,
                'cache_to': ['type=local,dest=/Users/me/x'],
              },
            }),
            ['build-cache'],
          );
        });

        test('security options it wrote itself', () async {
          expect(
            await refused({
              'security_opt': ['seccomp=$worktree/open.json'],
            }),
            ['security-opt'],
          );
        });

        test('a network mode that names someone else\'s network', () async {
          expect(await refused({'network_mode': 'cc-other_default'}), [
            'network-mode',
          ]);
          expect(await refused({'network_mode': 'service:db'}), isEmpty);
          expect(await refused({'network_mode': 'none'}), isEmpty);
        });

        test('a name outside the project is an external by stealth', () async {
          model['volumes'] = {
            'data': {'name': 'cc-other_data'},
          };
          model['networks'] = {
            'default': {'name': 'cc-other_default'},
          };
          expect(
            await refused({}),
            unorderedEquals(['volume-name', 'network-name']),
          );
        });

        test('external networks and other drivers', () async {
          model['networks'] = {
            'edge': {'name': 'edge', 'external': true},
            'open': {'name': 'shop_open', 'driver': 'host'},
          };
          expect(
            await refused({}),
            unorderedEquals(['external-network', 'network-driver']),
          );
        });

        test('volumes that mount something else', () async {
          model['volumes'] = {
            'share': {
              'name': 'shop_share',
              'driver_opts': {
                'type': 'nfs',
                'o': 'addr=10.0.0.1',
                'device': ':/x',
              },
            },
            'plugin': {'name': 'shop_plugin', 'driver': 'rexray'},
          };
          expect(await refused({}), ['volume-driver', 'volume-driver']);
        });

        test('a bind volume inside the worktree stays fine', () async {
          model['volumes'] = {
            'data': {
              'name': 'shop_data',
              'driver_opts': {
                'type': 'none',
                'o': 'bind',
                'device': '$worktree/data',
              },
            },
          };
          expect(
            await refused({
              'volumes': [
                {'type': 'volume', 'source': 'data', 'target': '/x'},
              ],
            }),
            isEmpty,
          );
        });

        test('a logging driver that ships logs elsewhere', () async {
          expect(
            await refused({
              'logging': {'driver': 'syslog'},
            }),
            ['logging-driver'],
          );
        });

        test('a volume type that isn\'t a plain mount', () async {
          expect(
            await refused({
              'volumes': [
                {'type': 'npipe', 'source': 'x', 'target': '/x'},
              ],
            }),
            ['volume-type'],
          );
        });
      });

      test('warns on a trusted space, refuses on an untrusted one', () async {
        (model['services'] as Map)['web'] = {
          'image': 'nginx',
          'privileged': true,
        };
        final trusted = await driver.preflight(await plan());
        expect(trusted.ok, isTrue);
        expect(trusted.warnings.single.message, contains('privileged'));

        final untrusted = await driver.preflight(await plan(untrusted: true));
        expect(untrusted.ok, isFalse);
        expect(untrusted.warnings, isEmpty);
        expect(untrusted.refusals.single.service, 'web');
        expect(
          untrusted.throwIfBlocked,
          failsWith('compose-policy-refused', contains('Service web')),
        );
      });
    });
  });

  group('up', () {
    test('writes the override and runs up -d --build, never --wait', () async {
      final subject = await plan();
      await driver.up(subject);
      final call = runner.callsWith('up').single;
      expect(call.argv, [
        'docker',
        'compose',
        '-p',
        'cc-3f2a9c1e-7b4',
        '-f',
        '$stateDir/compose.resolved.json',
        '-f',
        '$stateDir/compose.override.yaml',
        'up',
        '-d',
        '--build',
        'db',
        'cache',
        'web',
      ]);
      expect(call.argv, isNot(contains('--wait')));
      expect(
        File('$stateDir/compose.override.yaml').readAsStringSync(),
        subject.overrideYaml,
      );
    });

    test('starts what was checked, not what the worktree holds now', () async {
      (model['services'] as Map)['web'] = {
        'image': 'nginx',
        'environment': {'GREETING': r'a$$b'},
      };
      final subject = await plan(untrusted: true);
      // What a container with a bind on the worktree could do after planning.
      File('$worktree/compose.yaml').writeAsStringSync('''
services:
  web:
    image: nginx
    privileged: true
''');
      await driver.up(subject);

      final file =
          jsonDecode(File('$stateDir/compose.resolved.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(file, subject.model);
      expect(
        runner.callsWith('up').single.argv,
        isNot(contains('$worktree/compose.yaml')),
      );
    });

    test('a profile that was on when resolved stays on', () async {
      (model['services'] as Map)['web'] = {
        'image': 'nginx',
        'profiles': ['dev'],
      };
      final subject = await plan();
      await driver.up(subject);
      final file =
          jsonDecode(File('$stateDir/compose.resolved.json').readAsStringSync())
              as Map<String, dynamic>;
      expect((file['services'] as Map)['web'], {'image': 'nginx'});
      expect((subject.model['services'] as Map)['web'], contains('profiles'));
    });

    test('the resolved file is its owner\'s', () async {
      await driver.up(await plan());
      final mode = File('$stateDir/compose.resolved.json').statSync().mode;
      expect(mode & 0x1ff, 0x180);
    }, testOn: '!windows');

    test('COMPOSE_FILE never reaches the driver\'s own calls', () async {
      final subject = (await plan()).withEnvironment(const {
        'COMPOSE_FILE': '/worktree/compose.yaml',
      });
      await driver.up(subject);
      expect(
        runner.callsWith('up').single.environment,
        isNot(contains('COMPOSE_FILE')),
      );
    });

    test('a refresh applies the new model from the state directory', () async {
      final first = await plan();
      await driver.up(first);
      (model['services'] as Map)['web'] = {'image': 'nginx:next'};
      final result = await driver.refresh(
        context(),
        lease: lease,
        existingPorts: first.ports,
      );
      expect(result.changed, isTrue);
      expect(runner.callsWith('up').last.argv, [
        ...runner.callsWith('up').first.argv,
      ]);
      expect(
        File('$stateDir/compose.resolved.json').readAsStringSync(),
        contains('nginx:next'),
      );
    });

    test('build: false in the component leaves --build out', () async {
      await driver.up(
        await plan(
          component: ComposeEnvironmentComponent(id: 's', build: false),
        ),
      );
      expect(runner.callsWith('up').single.argv, isNot(contains('--build')));
    });

    test('a preflight block stops it before Docker hears anything', () async {
      (model['services'] as Map)['web'] = {
        'image': 'nginx',
        'privileged': true,
      };
      await expectLater(
        driver.up(await plan(untrusted: true)),
        failsWith('compose-policy-refused'),
      );
      expect(runner.callsWith('up'), isEmpty);
    });

    test('returns warnings', () async {
      (model['services'] as Map)['web'] = {
        'image': 'nginx',
        'privileged': true,
      };
      expect(await driver.up(await plan()), [contains('privileged')]);
    });

    test('a failed up carries stderr', () async {
      final subject = await plan();
      runner.handler = (call) => call.argv.contains('up')
          ? failed(1, stderr: 'port is already allocated')
          : answer(call);
      await expectLater(
        driver.up(subject),
        failsWith('compose-up-failed', contains('already allocated')),
      );
    });

    test('withEnvironment reaches the command', () async {
      final subject = (await plan()).withEnvironment(const {'LATE': 'yes'});
      await driver.up(subject);
      final environment = runner.callsWith('up').single.environment;
      expect(environment['LATE'], 'yes');
      expect(environment['COMPOSE_PROJECT_NAME'], 'cc-3f2a9c1e-7b4');
    });
  });

  group('readiness', () {
    String row(
      String service,
      String state, {
      String health = '',
      int exit = 0,
    }) => jsonEncode({
      'Service': service,
      'State': state,
      'Health': health,
      'ExitCode': exit,
    });

    Future<ComposePlan> planOf(List<String> services) async {
      model['services'] = {
        for (final service in services) service: {'image': 'x'},
      };
      return plan();
    }

    test('running with no health, healthy, and exit 0 all settle', () async {
      final subject = await planOf(['a', 'b', 'c']);
      psOutputs = [
        [
          row('a', 'running'),
          row('b', 'running', health: 'healthy'),
          row('c', 'exited'),
        ].join('\n'),
      ];
      final states = await driver.waitReady(subject);
      expect(states.map((s) => s.state), ['ready', 'ready', 'completed']);
    });

    test('waits through starting and unhealthy', () async {
      final subject = await planOf(['a']);
      psOutputs = [
        row('a', 'created'),
        row('a', 'running', health: 'starting'),
        row('a', 'running', health: 'unhealthy'),
        row('a', 'running', health: 'healthy'),
      ];
      final states = await driver.waitReady(subject);
      expect(states.single.state, 'ready');
      expect(runner.callsWith('ps'), hasLength(4));
    });

    test('reads the old single-array format', () async {
      final subject = await planOf(['a']);
      psOutputs = ['[${row('a', 'running')}]'];
      expect((await driver.waitReady(subject)).single.state, 'ready');
    });

    test('exit non-zero fails with that service\'s last lines', () async {
      final subject = await planOf(['a', 'b']);
      psOutputs = [
        [row('a', 'running'), row('b', 'exited', exit: 2)].join('\n'),
      ];
      await expectLater(
        driver.waitReady(subject),
        failsWith(
          'compose-service-failed',
          allOf(
            contains('Service b exited with code 2'),
            contains('last words'),
          ),
        ),
      );
      final logs = runner.callsWith('logs').single;
      expect(
        logs.argv,
        containsAllInOrder(['--no-color', '--tail', '20', 'b']),
      );
    });

    test('a timeout names what it was waiting for', () async {
      final subject = await planOf(['a', 'b', 'c']);
      psOutputs = [
        [
          row('a', 'running'),
          row('b', 'running', health: 'starting'),
        ].join('\n'),
      ];
      await expectLater(
        driver.waitReady(subject, timeout: const Duration(milliseconds: 40)),
        failsWith(
          'compose-timeout',
          allOf(
            contains('b (running, starting)'),
            contains('c'),
            isNot(contains('a (')),
          ),
        ),
      );
    });

    test('the worst replica decides', () async {
      final subject = await planOf(['a']);
      psOutputs = [
        [
          row('a', 'running'),
          row('a', 'running', health: 'starting'),
        ].join('\n'),
        [row('a', 'running'), row('a', 'running')].join('\n'),
      ];
      await driver.waitReady(subject);
      expect(runner.callsWith('ps'), hasLength(2));
    });

    test('docker events wake the loop and stop with it', () async {
      driver = ComposeDriver(
        runner: runner,
        pollInterval: const Duration(minutes: 5),
      );
      final subject = await planOf(['a']);
      psOutputs = [row('a', 'created'), row('a', 'running')];
      final done = driver.waitReady(subject);
      await pumpEventQueue();
      final events = runner.streams.single;
      expect(
        events.call.argv,
        containsAllInOrder([
          'events',
          '--filter',
          'label=com.docker.compose.project=cc-3f2a9c1e-7b4',
        ]),
      );
      events.emit('{"status":"start"}');
      expect((await done).single.state, 'ready');
      expect(events.cancelled, isTrue);
    });

    test('events are cancelled on failure too', () async {
      final subject = await planOf(['a']);
      psOutputs = [row('a', 'exited', exit: 1)];
      await expectLater(driver.waitReady(subject), throwsException);
      expect(runner.streams.single.cancelled, isTrue);
    });

    test('toJson has the component state shape', () {
      expect(
        const ComposeServiceState(
          service: 'a',
          state: 'ready',
          health: 'healthy',
        ).toJson(ports: const [42000]),
        {
          'name': 'a',
          'state': 'ready',
          'health': 'healthy',
          'ports': [42000],
        },
      );
    });
  });

  group('endpoints', () {
    List<ComposeServiceState> running(Iterable<String> services) => [
      for (final service in services)
        ComposeServiceState(service: service, state: 'ready'),
    ];

    test('one probe per tcp port, and an answer means a URL', () async {
      final probed = <Uri>[];
      driver = ComposeDriver(
        runner: runner,
        httpProbe: (uri) async {
          probed.add(uri);
          return uri.port == 42003 ? 200 : null;
        },
      );
      final subject = await plan();
      final endpoints = await driver.detectEndpoints(
        subject,
        running(['db', 'cache', 'web']),
      );
      expect(probed.map((uri) => uri.port), [42001, 42000, 42003]);
      expect(probed.first.host, '127.0.0.1');
      final web = endpoints.firstWhere((e) => e.role == 'web-80');
      expect(web.url, 'http://127.0.0.1:42003');
      expect(web.hostPort, 42003);
      final db = endpoints.firstWhere((e) => e.role == 'db');
      expect(db.url, isNull);
      expect(db.hostPort, 42001);
      final udp = endpoints.firstWhere((e) => e.role == 'web-53');
      expect(udp.url, isNull);
    });

    test('`http` replaces the guess', () async {
      var probes = 0;
      driver = ComposeDriver(
        runner: runner,
        httpProbe: (uri) async {
          probes++;
          return 200;
        },
      );
      final subject = await plan(
        component: ComposeEnvironmentComponent(
          id: 'stack',
          http: const ['cache'],
        ),
      );
      final endpoints = await driver.detectEndpoints(
        subject,
        running(['db', 'cache']),
      );
      expect(probes, 0);
      expect(endpoints.firstWhere((e) => e.role == 'cache').url, isNotNull);
      expect(endpoints.firstWhere((e) => e.role == 'db').url, isNull);
    });

    test('a one-shot that finished has no endpoint', () async {
      final endpoints = await driver.detectEndpoints(await plan(), const [
        ComposeServiceState(service: 'db', state: 'completed'),
      ]);
      expect(endpoints, isEmpty);
    });
  });

  group('operations', () {
    late ComposePlan subject;

    setUp(() async {
      subject = await plan();
      runner.calls.clear();
    });

    /// Everything after `docker compose -p <project>` and any file flags.
    List<String> tailOf(FakeCall call) {
      final start = call.argv.lastIndexOf('-f');
      return call.argv.sublist(start < 0 ? 4 : start + 2);
    }

    test('only up reads a file: the rest go by project name', () async {
      await driver.logs(subject, 'web');
      await driver.exec(subject, 'web', ['ls']);
      await driver.restart(subject, 'web');
      await driver.stop(subject);
      await driver.destroy(subject);
      await driver.status(subject);
      expect(runner.calls, hasLength(6));
      for (final call in runner.calls) {
        expect(call.argv.take(4), [
          'docker',
          'compose',
          '-p',
          'cc-3f2a9c1e-7b4',
        ]);
        expect(call.argv, isNot(contains('-f')), reason: '${call.argv}');
      }
    });

    test('logs', () async {
      expect(await driver.logs(subject, 'web', tail: 50), 'last words');
      expect(tailOf(runner.calls.single), [
        'logs',
        '--no-color',
        '--tail',
        '50',
        'web',
      ]);
    });

    test('exec', () async {
      runner.handler = (_) => failed(3, stderr: 'nope', stdout: 'partial');
      final result = await driver.exec(subject, 'web', ['ls', '-la']);
      expect(tailOf(runner.calls.single), ['exec', '-T', 'web', 'ls', '-la']);
      expect(
        (result.exitCode, result.stdout, result.stderr),
        (3, 'partial', 'nope'),
      );
    });

    test('restart', () async {
      await driver.restart(subject, 'web');
      expect(tailOf(runner.calls.single), ['restart', 'web']);
    });

    test('stop keeps containers', () async {
      await driver.stop(subject);
      expect(tailOf(runner.calls.single), ['stop']);
    });

    test('start is up -d with no build', () async {
      await driver.start(subject);
      expect(tailOf(runner.callsWith('up').single), [
        'up',
        '-d',
        'db',
        'cache',
        'web',
      ]);
    });

    test('reset is down -v, then up', () async {
      await driver.reset(subject);
      final lines = runner.calls
          .where((call) => call.argv.first == 'docker')
          .map(tailOf)
          .map((argv) => argv.take(2).join(' '));
      expect(lines, ['down -v', 'up -d']);
    });

    test('destroy removes volumes, orphans and local images', () async {
      await driver.destroy(subject);
      expect(tailOf(runner.calls.single), [
        'down',
        '-v',
        '--remove-orphans',
        '--rmi',
        'local',
      ]);
    });

    test('destroyProject needs no compose file', () async {
      await driver.destroyProject(_envId);
      expect(runner.calls.single.argv, [
        'docker',
        'compose',
        '-p',
        'cc-3f2a9c1e-7b4',
        'down',
        '-v',
        '--remove-orphans',
      ]);
    });

    test('a failed stop throws', () async {
      runner.handler = (_) => failed(1, stderr: 'daemon gone');
      await expectLater(
        driver.stop(subject),
        failsWith('compose-stop-failed', contains('daemon gone')),
      );
    });

    test('followers of a service share one process', () async {
      final first = <String>[];
      final second = <String>[];
      final a = driver.followLogs(subject, 'web').listen(first.add);
      final b = driver.followLogs(subject, 'web').listen(second.add);
      expect(runner.streams, hasLength(1));
      final stream = runner.streams.single;
      expect(stream.call.argv, containsAllInOrder(['--follow', 'web']));

      stream.emit('hello');
      await pumpEventQueue();
      expect(first, ['hello']);
      expect(second, ['hello']);

      await a.cancel();
      expect(stream.cancelled, isFalse);
      await b.cancel();
      expect(stream.cancelled, isTrue);

      final c = driver.followLogs(subject, 'web').listen((_) {});
      expect(runner.streams, hasLength(2), reason: 'a new one after the last');
      await c.cancel();
    });

    test('followers hear the end when logs --follow exits', () async {
      final done = Completer<void>();
      driver.followLogs(subject, 'web').listen((_) {}, onDone: done.complete);
      runner.streams.single.result.complete(ok());
      await done.future;
      driver.followLogs(subject, 'web').listen((_) {});
      expect(runner.streams, hasLength(2), reason: 'a fresh process');
    });

    test('a null service means every service', () async {
      await driver.restart(subject, null);
      await driver.logs(subject, null, tail: 5);
      expect(runner.calls.map(tailOf), [
        ['restart'],
        ['logs', '--no-color', '--tail', '5'],
      ]);
    });
  });

  group('refresh', () {
    test('an unchanged config leaves everything alone', () async {
      final subject = await plan();
      await driver.up(subject);
      runner.calls.clear();
      final result = await driver.refresh(
        context(),
        lease: lease,
        existingPorts: subject.ports,
      );
      expect(result.changed, isFalse);
      expect(runner.callsWith('up'), isEmpty);
    });

    test('a change rebuilds, keeps ports, and adds new ones', () async {
      final subject = await plan();
      await driver.up(subject);
      runner.calls.clear();

      (model['services'] as Map)['admin'] = {
        'image': 'nginx',
        'ports': [
          {'target': 8080, 'protocol': 'tcp'},
        ],
      };
      final result = await driver.refresh(
        context(),
        lease: lease,
        existingPorts: subject.ports,
      );
      expect(result.changed, isTrue);
      expect(runner.callsWith('--build'), hasLength(1));
      for (final entry in subject.ports.entries) {
        expect(result.plan.ports[entry.key], entry.value);
      }
      expect(result.plan.ports['admin.8080'], 42004);
    });

    test('never applied counts as changed', () async {
      final result = await driver.refresh(
        context(),
        lease: lease,
        existingPorts: const {},
      );
      expect(result.changed, isTrue);
    });

    test('a key order change is not a change', () async {
      final subject = await plan();
      await driver.up(subject);
      model = {'services': model['services'], 'name': model['name']};
      final result = await driver.refresh(
        context(),
        lease: lease,
        existingPorts: subject.ports,
      );
      expect(result.changed, isFalse);
    });
  });

  group('orphans', () {
    String container(String env, {String id = 'c1'}) => jsonEncode({
      'ID': id,
      'Names': 'cc-x-web-1',
      'State': 'running',
      'Labels':
          'com.docker.compose.project=cc-x,cc.env=$env,cc.space=s1,'
          'com.docker.compose.project.config_files=/a,/b,cc.workspace=w1',
    });

    test('lists containers by label, and parses the labels', () async {
      runner.handler = (_) => ok(container('env-1'));
      final owned = await driver.ownedContainers();
      expect(
        runner.calls.single.argv,
        containsAllInOrder(['ps', '-a', '--filter', 'label=cc.env']),
      );
      final item = owned.single;
      expect(item.environmentId, 'env-1');
      expect(item.workspaceId, 'w1');
      expect(item.spaceId, 's1');
      expect(item.project, 'cc-x');
      expect(item.state, 'running');
    });

    test('orphans are those the database doesn\'t know', () async {
      runner.handler = (_) =>
          ok([container('env-1'), container('env-2', id: 'c2')].join('\n'));
      final orphans = await driver.orphans({'env-1'});
      expect(orphans.map((item) => item.id), ['c2']);
    });
  });

  group('versionCheck', () {
    Future<bool> check(String version) async {
      runner.handler = (_) => ok('$version\n');
      return (await driver.versionCheck()).ok;
    }

    test('needs 2.24', () async {
      expect(await check('5.5.0'), isTrue);
      expect(await check('2.24.4'), isTrue);
      expect(await check('2.24.3'), isFalse);
      expect(await check('2.29.1'), isTrue);
      expect(await check('2.23.3'), isFalse);
      expect(await check('1.29.2'), isFalse);
    });

    test('reports a missing Compose', () async {
      runner.handler = (_) => failed(1);
      final result = await driver.versionCheck();
      expect(result.ok, isFalse);
      expect(result.hint, contains('2.24.4'));
    });
  });
}

Future<void> pumpEventQueue() =>
    Future<void>.delayed(const Duration(milliseconds: 5));
