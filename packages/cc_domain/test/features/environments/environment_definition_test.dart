import 'dart:convert';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_glob.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_naming.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status_map.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:test/test.dart';

Map<String, dynamic> _minimal() => {
  'contract': 1,
  'name': 'Shop',
  'repos': {
    'app': {'repoId': 'repo-1', 'anchor': true, 'required': true},
  },
  'components': [
    {'kind': 'compose', 'id': 'stack'},
  ],
};

Map<String, dynamic> _full() => {
  'contract': 1,
  'name': 'Full',
  'repos': {
    'app': {'repoId': 'repo-1', 'anchor': true, 'required': true},
    'e2e': {'repoId': 'repo-2', 'whenMissing': 'addToSpace'},
  },
  'naming': {'template': '{branch}', 'project': 'shop'},
  'seedFiles': ['.env.local'],
  'options': [
    {'key': 'seed', 'type': 'bool', 'default': true},
  ],
  'env': {
    'DATABASE_URL': 'postgres://127.0.0.1:{port.postgres.5432}/app',
    'BASE_URL': '{url.web}',
  },
  'checks': [
    {
      'id': 'docker',
      'label': 'Docker',
      'command': ['docker', 'info'],
    },
    {'id': 'seed', 'label': 'Seed', 'file': '{source.app}/seed.sh'},
  ],
  'components': [
    {
      'kind': 'task',
      'id': 'deps',
      'when': ['provision', 'change'],
      'onChange': ['pnpm-lock.yaml'],
      'command': ['pnpm', 'install'],
    },
    {
      'kind': 'compose',
      'id': 'infra',
      'services': ['postgres'],
      'healthchecks': {
        'postgres': ['pg_isready'],
      },
    },
    {
      'kind': 'task',
      'id': 'seed',
      'enabledWhen': 'opt.seed',
      'when': ['create'],
      'script': ['pnpm seed', 'echo done'],
    },
    {
      'kind': 'process',
      'id': 'web',
      'port': 'web',
      'endpoint': {'role': 'web', 'primary': true},
      'command': ['vite', '--port', '{port.web}'],
      'ready': {'http': 'http://127.0.0.1:{port.web}/', 'timeout': 60},
      'restartOn': ['vite.config.ts'],
    },
    {
      'kind': 'task',
      'id': 'test',
      'cwd': {'role': 'e2e'},
      'port': 'e2e',
      'when': ['manual'],
      'command': ['pnpm', 'test'],
    },
    {
      'kind': 'app',
      'id': 'desktop',
      'prepare': 'test',
      'command': ['target/debug/app'],
      'isolate': 'home',
    },
  ],
};

void main() {
  group('EnvironmentDefinitionRecord.toRedactedJson', () {
    EnvironmentDefinitionRecord record({String? overrides}) =>
        EnvironmentDefinitionRecord(
          id: 'def-1',
          workspaceId: 'ws-a',
          name: 'Shop',
          definitionJson: jsonEncode({
            'contract': 1,
            'name': 'Shop',
            'env': {'DATABASE_URL': 'postgres://secret@db'},
            'repos': {
              'app': {'repoId': 'repo-a', 'anchor': true},
            },
            'components': [
              {
                'kind': 'process',
                'id': 'web',
                'command': ['pnpm', 'dev'],
                'env': {'API_KEY': 'secret'},
              },
            ],
          }),
          overridesJson: overrides,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );

    test('hides every env value and keeps the names', () {
      final json = record().toRedactedJson();
      expect(jsonEncode(json), isNot(contains('secret')));
      final definition = json['definition'] as Map;
      expect(definition['env'], {'DATABASE_URL': kEnvironmentRedactedValue});
      expect(((definition['components'] as List).single as Map)['env'], {
        'API_KEY': kEnvironmentRedactedValue,
      });
    });

    test('hides every leaf of overrides, however deep', () {
      final json = record(
        overrides: jsonEncode({
          'env': {'A': 'secret'},
          'nested': [
            {'b': 'secret', 'c': 3},
          ],
        }),
      ).toRedactedJson();
      expect(json['overrides'], {
        'env': {'A': kEnvironmentRedactedValue},
        'nested': [
          {'b': kEnvironmentRedactedValue, 'c': kEnvironmentRedactedValue},
        ],
      });
    });

    test('leaves out overrides nobody set', () {
      expect(record().toRedactedJson(), isNot(contains('overrides')));
    });

    test('still parses, so a member sees what a definition starts', () {
      final json = record().toRedactedJson();
      final parsed = EnvironmentDefinition.fromJson(
        Map<String, dynamic>.from(json['definition'] as Map),
      );
      expect(parsed.components.single.id, 'web');
    });

    test('leaves the admin form alone', () {
      expect(jsonEncode(record().toJson()), contains('secret'));
    });

    test('what it hides is recognisable when it comes back', () {
      expect(environmentHoldsRedaction(record().toJson()), isFalse);
      expect(environmentHoldsRedaction(record().toRedactedJson()), isTrue);
      expect(environmentHoldsRedaction(null), isFalse);
    });
  });

  group('EnvironmentDefinition', () {
    test('the smallest definition parses and validates', () {
      final definition = EnvironmentDefinition.fromJson(_minimal());
      expect(validateEnvironmentDefinition(definition), isEmpty);
      expect(definition.naming.template, '{branch}');
      expect(definition.routing.mode, EnvironmentRoutingMode.router);
      expect(definition.placement, EnvironmentPlacement.host);
      expect(definition.hasStack, isTrue);
    });

    test('a full definition validates and survives a round trip', () {
      final definition = EnvironmentDefinition.fromJson(_full());
      expect(validateEnvironmentDefinition(definition), isEmpty);
      final again = EnvironmentDefinition.fromJson(
        jsonDecode(jsonEncode(definition.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), definition.toJson());
      expect(definition.namedPorts, {'web', 'e2e'});
    });

    test('malformed shapes are FormatExceptions, never TypeErrors', () {
      for (final bad in <Map<String, dynamic>>[
        {},
        {'name': 'x', 'repos': {}, 'components': []},
        {
          'name': 'x',
          'repos': {'a': 1},
          'components': [],
        },
        {
          ..._minimal(),
          'components': [
            {'kind': 'nope', 'id': 'x'},
          ],
        },
        {
          ..._minimal(),
          'components': [
            {
              'kind': 'task',
              'id': 'x',
              'when': ['never'],
              'command': ['a'],
            },
          ],
        },
      ]) {
        expect(
          () => EnvironmentDefinition.fromJson(bad),
          throwsFormatException,
        );
      }
    });

    test('the first present role is the default working directory', () {
      final definition = EnvironmentDefinition.fromJson(_full());
      final deps = definition.component('deps')!;
      final test = definition.component('test')!;
      expect(definition.roleFor(deps, {'app', 'e2e'}), 'app');
      expect(definition.roleFor(deps, {'e2e'}), 'e2e');
      expect(definition.roleFor(test, {'app'}), 'e2e');
    });

    test('a definition of worktree tasks only has no stack', () {
      final definition = EnvironmentDefinition.fromJson({
        'name': 'Setup only',
        'repos': {
          'app': {'repoId': 'r'},
        },
        'components': [
          {
            'kind': 'task',
            'id': 'setup',
            'when': ['provision'],
            'command': 'pnpm i',
          },
        ],
      });
      expect(definition.hasStack, isFalse);
      expect(validateEnvironmentDefinition(definition), isEmpty);
    });

    test('rig eligibility decides the fork default', () {
      expect(
        EnvironmentDefinition.fromJson(_minimal()).forkPolicy,
        EnvironmentForkPolicy.rig,
      );
      expect(
        EnvironmentDefinition.fromJson(_full()).forkPolicy,
        EnvironmentForkPolicy.approval,
      );
    });
  });

  group('validateEnvironmentDefinition', () {
    List<String> paths(Map<String, dynamic> json, {Set<String>? linked}) =>
        validateEnvironmentDefinition(
          EnvironmentDefinition.fromJson(json),
          linkedRepoIds: linked,
        ).map((issue) => issue.path).toList();

    test('rejects useSource with rig placement or forkPrs: rig', () {
      Map<String, dynamic> withSource(Map<String, dynamic> extra) => {
        ..._minimal(),
        'repos': {
          'app': {'repoId': 'r1', 'anchor': true, 'required': true},
          'tools': {'repoId': 'r2', 'whenMissing': 'useSource'},
        },
        'components': [
          {'kind': 'compose', 'id': 'stack'},
        ],
        ...extra,
      };
      expect(paths(withSource({'placement': 'rig'})), contains('repos.tools'));
      expect(
        paths(
          withSource({
            'policy': {'forkPrs': 'rig'},
          }),
        ),
        contains('repos.tools'),
      );
      expect(paths(withSource({})), isNot(contains('repos.tools')));
    });

    test('rejects env that changes what code a process loads', () {
      for (final key in [
        'LD_PRELOAD',
        'LD_LIBRARY_PATH',
        'DYLD_INSERT_LIBRARIES',
        'NODE_OPTIONS',
        'BASH_ENV',
        'ENV',
        'GIT_SSH_COMMAND',
        'GIT_CONFIG_GLOBAL',
        'PYTHONPATH',
        'PERL5OPT',
        'RUBYOPT',
        'JAVA_TOOL_OPTIONS',
      ]) {
        expect(
          paths({
            ..._minimal(),
            'env': {key: 'x'},
          }),
          contains('env.$key'),
          reason: key,
        );
      }
    });

    test('names every role with no repo', () {
      expect(
        () => EnvironmentDefinition.fromJson({
          'repos': {
            'app': {'anchor': true},
            'bound': {'repoId': 'repo-1'},
            'tests': <String, dynamic>{},
          },
          'components': <Object?>[],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Pick a repo for: app, tests',
          ),
        ),
      );
    });

    test('NODE_OPTIONS may set heap limits and nothing else', () {
      List<String> withValue(String value) => paths({
        ..._minimal(),
        'env': {'NODE_OPTIONS': value},
      });

      expect(
        withValue('--max-old-space-size=4096'),
        isNot(contains('env.NODE_OPTIONS')),
      );
      expect(
        withValue('--max-old-space-size=4096 --max-semi-space-size=64'),
        isNot(contains('env.NODE_OPTIONS')),
      );
      for (final value in [
        '--require ./x.js',
        '--max-old-space-size=4096 --import ./x.mjs',
        '{opt.flags}',
      ]) {
        expect(withValue(value), contains('env.NODE_OPTIONS'), reason: value);
      }
    });

    test('rejects placeholders in any interpreter\'s inline code', () {
      List<String> withCommand(List<String> argv) => paths({
        ..._minimal(),
        'options': [
          {'key': 'name', 'type': 'string'},
        ],
        'components': [
          {'kind': 'compose', 'id': 'stack'},
          {
            'kind': 'task',
            'id': 'seed',
            'when': ['create'],
            'command': argv,
          },
        ],
      });

      for (final argv in [
        ['python3.12', '-c', 'print("{opt.name}")'],
        ['node', '--eval', 'run("{opt.name}")'],
        ['perl', '-e', 'print "{opt.name}"'],
        ['/usr/bin/ruby', '-e', 'puts "{opt.name}"'],
        ['pwsh', '-Command', 'echo {opt.name}'],
      ]) {
        expect(
          withCommand(argv),
          contains('components[1]'),
          reason: argv.join(' '),
        );
      }
      expect(
        withCommand(['node', 'seed.js', '{opt.name}']),
        isNot(contains('components[1]')),
      );
    });

    test('rejects those in a component\'s env too, in any case', () {
      expect(
        paths({
          ..._minimal(),
          'components': [
            {
              'kind': 'compose',
              'id': 'stack',
              'env': {'ld_preload': 'x'},
            },
          ],
        }),
        contains('components[0].env.ld_preload'),
      );
    });

    test('ordinary variables stay fine', () {
      for (final key in [
        'DATABASE_URL',
        'NODE_ENV',
        'NODE_EXTRA_CA_CERTS',
        'LDFLAGS',
        'ENVIRONMENT',
        'COMPOSE_PROFILES',
      ]) {
        expect(
          paths({
            ..._minimal(),
            'env': {key: 'x'},
          }),
          isEmpty,
          reason: key,
        );
      }
    });

    group('placeholders in a shell script', () {
      Map<String, dynamic> task(Object? command) => {
        ..._minimal(),
        'options': [
          {'key': 'seed', 'type': 'string'},
        ],
        'components': [
          {'kind': 'compose', 'id': 'stack'},
          {
            'kind': 'task',
            'id': 'seed',
            'when': ['create'],
            'command': command,
          },
        ],
      };

      test('are refused, whatever spells the flag', () {
        for (final argv in [
          ['sh', '-c', 'seed {opt.seed}'],
          ['bash', '-c', 'seed {opt.seed}'],
          ['zsh', '-c', 'seed {opt.seed}'],
          ['dash', '-c', 'seed {opt.seed}'],
          ['/bin/bash', '-lc', 'seed {opt.seed}'],
          ['bash', '-ec', 'seed {opt.seed}'],
          ['bash', '-euc', 'seed {opt.seed}'],
          ['bash', '-o', 'pipefail', '-c', 'seed {opt.seed}'],
          ['bash', '--noprofile', '-c', 'seed {opt.seed}'],
          ['bash', '-c', '--', 'seed {opt.seed}'],
          ['bash', '-c', '{opt.seed}'],
          ['bash', '-c', '-{opt.seed}'],
          ['env', 'sh', '-c', 'seed {opt.seed}'],
          ['docker', 'compose', 'exec', 'web', 'sh', '-c', 'seed {name}'],
        ]) {
          expect(
            paths(task(argv)),
            contains('components[1]'),
            reason: argv.join(' '),
          );
        }
      });

      test('behind a condition too', () {
        expect(
          paths(
            task([
              'sh',
              '-c',
              {
                'if': 'opt.seed',
                'args': ['seed {opt.seed}'],
              },
            ]),
          ),
          contains('components[1]'),
        );
      });

      test('in a check too', () {
        expect(
          paths({
            ..._minimal(),
            'checks': [
              {
                'id': 'ready',
                'label': 'Ready',
                'command': ['sh', '-c', 'test -d {home}'],
              },
            ],
          }),
          contains('checks[0]'),
        );
      });

      test('pass as the script\'s own arguments, or outside any shell', () {
        for (final argv in [
          ['sh', '-c', 'seed "\$1"', 'sh', '{opt.seed}'],
          ['bash', '-lc', 'seed "\$1"', 'bash', '{opt.seed}'],
          ['sh', 'seed.sh', '{opt.seed}'],
          ['seed', '-c', '{opt.seed}'],
          ['tool', 'bash', '{opt.seed}'],
        ]) {
          expect(
            paths(task(argv)),
            isNot(contains('components[1]')),
            reason: argv.join(' '),
          );
        }
      });
    });

    test('rejects a required repo unlinked from the workspace', () {
      expect(paths(_minimal(), linked: {'other'}), contains('repos.app'));
    });

    test('rejects env that shadows PATH, HOME or CC_*', () {
      for (final key in ['PATH', 'HOME', 'CC_ENV_NAME']) {
        expect(
          paths({
            ..._minimal(),
            'env': {key: 'x'},
          }),
          contains('env.$key'),
        );
      }
    });

    test('rejects seed files that climb out of the repo', () {
      for (final file in ['../x', '/etc/passwd', '~/.ssh/id', r'a\b']) {
        expect(
          paths({
            ..._minimal(),
            'seedFiles': [file],
          }),
          contains('seedFiles[0]'),
        );
      }
    });

    test('rejects an unknown placeholder', () {
      final json = _minimal()..['env'] = {'A': '{port.nope}'};
      expect(paths(json), contains('env.A'));
    });

    test('leaves Docker Go templates alone', () {
      final json = _minimal()
        ..['checks'] = [
          {
            'id': 'c',
            'label': 'C',
            'command': ['docker', 'inspect', '-f', '{{.State.Running}}', 'x'],
          },
        ];
      expect(paths(json), isEmpty);
    });

    test('worktree tasks can not read environment values', () {
      final json = _minimal()
        ..['components'] = [
          {
            'kind': 'process',
            'id': 'web',
            'port': 'web',
            'command': ['a'],
          },
          {
            'kind': 'task',
            'id': 'bad',
            'when': ['provision'],
            'command': ['echo', '{port.web}', '{name}'],
          },
        ];
      final issues = validateEnvironmentDefinition(
        EnvironmentDefinition.fromJson(json),
      ).map((issue) => issue.message);
      expect(issues, contains(contains('{port.web}')));
      expect(issues, contains(contains('{name}')));
    });

    test('worktree tasks can not be gated by options', () {
      final json = _minimal()
        ..['options'] = [
          {'key': 'x', 'type': 'bool'},
        ]
        ..['components'] = [
          {
            'kind': 'task',
            'id': 't',
            'enabledWhen': 'opt.x',
            'when': ['archive'],
            'command': ['a'],
          },
        ];
      expect(paths(json), contains('components[0].enabledWhen'));
    });

    test('tool routing must stay on a private suffix and loopback', () {
      final bad = _minimal()
        ..['routing'] = {
          'mode': 'tool',
          'domain': 'example.com',
          'upstream': '10.0.0.1:443',
          'caFile': '/etc/ssl/ca.pem',
        };
      expect(
        paths(bad),
        containsAll(['routing.domain', 'routing.upstream', 'routing.caFile']),
      );
      final good = _minimal()
        ..['routing'] = {
          'mode': 'tool',
          'domain': 'acme.test',
          'upstream': '127.0.0.1:443',
          'caFile': '~/.acme/ca.crt',
        };
      expect(paths(good), isEmpty);
    });

    test('rig placement refuses components that can not move', () {
      final json = _full()..['placement'] = 'rig';
      expect(paths(json), contains('placement'));
    });

    test('duplicate ids and ports are refused', () {
      final json = _minimal()
        ..['components'] = [
          {
            'kind': 'process',
            'id': 'a',
            'port': 'p',
            'command': ['x'],
          },
          {
            'kind': 'process',
            'id': 'a',
            'port': 'p',
            'command': ['x'],
          },
        ];
      expect(
        paths(json),
        containsAll(['components[1].id', 'components[1].port']),
      );
    });

    test('an endpoint needs a declared port', () {
      final json = _minimal()
        ..['components'] = [
          {
            'kind': 'process',
            'id': 'a',
            'endpoint': {'role': 'web'},
            'command': ['x'],
          },
        ];
      expect(paths(json), contains('components[0].endpoint'));
    });
  });

  group('EnvironmentValues', () {
    const values = EnvironmentValues({
      'name': 'fix',
      'opt.seed': 'true',
      'opt.off': 'false',
      'opt.mode': 'web',
      'port.web': '42000',
    });

    test('expands placeholders and refuses unknown ones', () {
      expect(values.expand('{name}:{port.web}'), 'fix:42000');
      expect(
        () => values.expand('{nope}'),
        throwsA(isA<EnvironmentTemplateException>()),
      );
    });

    test('leaves double braces and shell expansions alone', () {
      expect(values.expand('{{.State}}'), '{{.State}}');
      expect(EnvironmentValues.placeholdersIn('{{.State}}'), isEmpty);
    });

    test('evaluates conditions', () {
      expect(values.evaluate('opt.seed'), isTrue);
      expect(values.evaluate('opt.off'), isFalse);
      expect(values.evaluate('!opt.off'), isTrue);
      expect(values.evaluate('repo.none'), isFalse);
      expect(values.evaluate('opt.mode == web'), isTrue);
      expect(values.evaluate('opt.mode != web'), isFalse);
      expect(environmentConditionKey('!opt.x'), 'opt.x');
      expect(environmentConditionKey('opt.mode == web'), 'opt.mode');
    });
  });

  group('EnvironmentCommand', () {
    test('argv conditionals drop out, and values stay single arguments', () {
      final command =
          EnvironmentCommand.fromJson([
                'tool',
                '{name}',
                {
                  'if': 'repo.web',
                  'args': ['--web', '{repo.web}'],
                },
                {
                  'if': '!opt.a',
                  'args': ['--no-a'],
                },
              ], path: 'x')
              as ArgvEnvironmentCommand;
      expect(
        command.resolve(
          const EnvironmentValues({'name': 'a b; rm -rf /', 'opt.a': 'true'}),
        ),
        ['tool', 'a b; rm -rf /'],
      );
      expect(
        command.resolve(
          const EnvironmentValues({'name': 'n', 'repo.web': '/w'}),
        ),
        ['tool', 'n', '--web', '/w', '--no-a'],
      );
    });

    test('shell bodies are not template-expanded', () {
      final command = EnvironmentCommand.fromJson(r'echo ${HOME}', path: 'x');
      expect(command, isA<ShellEnvironmentCommand>());
      expect(command.templates, isEmpty);
    });

    test('verbs accept the shell object form', () {
      expect(
        EnvironmentCommand.fromJson({'shell': 'ls'}, path: 'x'),
        isA<ShellEnvironmentCommand>(),
      );
    });
  });

  group('EnvironmentStatusMap', () {
    final map = EnvironmentStatusMap.fromJson({
      'state': [
        {
          'when': {'path': '/status/ready', 'equals': true},
          'state': 'ready',
        },
        {
          'when': {
            'none': '/status/containers',
            'where': {'state': 'running'},
          },
          'state': 'stopped',
        },
        {
          'when': {'path': '/status/postStart', 'equals': 'failed'},
          'state': 'failed',
        },
        {'state': 'starting'},
      ],
      'detail': 'post-start: {/status/postStart}, http {/status/http}',
      'warnings': [
        {
          'when': {'path': '/status/dns', 'equals': false},
          'message': 'Not resolvable',
        },
      ],
      'endpoints': [
        {'role': 'app', 'url': '/urls/app', 'primary': true},
        {'role': 'dev', 'hostPort': '/web/port'},
        {'role': 'gone', 'url': '/urls/nope'},
      ],
      'services': '/status/containers/*/service',
      'list': '/*/slug',
    });

    Map<String, dynamic> status({
      bool ready = false,
      List<Map<String, String>> containers = const [],
      String postStart = 'running',
    }) => {
      'urls': {'app': 'https://a.acme.test'},
      'web': {'port': 8085},
      'status': {
        'ready': ready,
        'containers': containers,
        'postStart': postStart,
        'dns': false,
      },
    };

    test('first matching rule wins', () {
      const running = [
        {'service': 'app', 'state': 'running'},
      ];
      expect(
        map.evaluate(status(ready: true)).state,
        EnvironmentReportedState.ready,
      );
      expect(map.evaluate(status()).state, EnvironmentReportedState.stopped);
      expect(
        map.evaluate(status(containers: running, postStart: 'failed')).state,
        EnvironmentReportedState.failed,
      );
      expect(
        map.evaluate(status(containers: running)).state,
        EnvironmentReportedState.starting,
      );
    });

    test('reads details, warnings, endpoints and services', () {
      final report = map.evaluate(
        status(
          containers: const [
            {'service': 'app', 'state': 'running'},
          ],
        ),
      );
      expect(report.detail, 'post-start: running, http -');
      expect(report.warnings, ['Not resolvable']);
      expect(report.endpoints.map((e) => e.role), ['app', 'dev']);
      expect(report.endpoints.last.hostPort, 8085);
      expect(report.services, ['app']);
    });

    test('reads names from list output', () {
      expect(
        map.names([
          {'slug': 'a'},
          {'slug': 'b'},
        ]),
        ['a', 'b'],
      );
    });
  });

  group('EnvironmentStatusReport', () {
    test('tolerates junk instead of failing', () {
      final report = EnvironmentStatusReport.parse('Welcome!');
      expect(report.state, EnvironmentReportedState.degraded);
      expect(report.detail, 'Welcome!');
    });

    test('ignores unknown fields and bad endpoints', () {
      final report = EnvironmentStatusReport.parse(
        jsonEncode({
          'state': 'ready',
          'x': 1,
          'endpoints': [
            {'role': 'a', 'url': 'http://a.localhost'},
            {'role': 'b'},
            'nope',
          ],
        }),
      );
      expect(report.state, EnvironmentReportedState.ready);
      expect(report.endpoints, hasLength(1));
    });
  });

  group('EnvironmentEndpoint', () {
    EnvironmentEndpoint url(String value) =>
        EnvironmentEndpoint(role: 'a', url: value);

    test('tool output can not become an arbitrary URL', () {
      expect(url('https://x.acme.test').isAllowedFor('acme.test'), isTrue);
      expect(url('https://acme.test').isAllowedFor('acme.test'), isTrue);
      expect(url('http://127.0.0.1:1').isAllowedFor(null), isTrue);
      expect(url('http://a.localhost:1').isAllowedFor(null), isTrue);
      expect(url('https://evil.example').isAllowedFor('acme.test'), isFalse);
      expect(url('https://notacme.test').isAllowedFor('acme.test'), isFalse);
      expect(
        EnvironmentEndpoint(role: 'p', hostPort: 5432).isAllowedFor(null),
        isTrue,
      );
    });
  });

  group('naming', () {
    test('slugs are DNS-safe and bounded', () {
      expect(environmentSlug('Feat/Fix_Login'), 'feat-fix-login');
      expect(environmentSlug('///'), 'env');
      final long = environmentSlug('a' * 80, maxLength: 31);
      expect(long.length, lessThanOrEqualTo(31));
      expect(isValidEnvironmentLabel(long), isTrue);
      expect(
        environmentSlug('${'a' * 40}x'),
        isNot(environmentSlug('${'a' * 40}y')),
      );
    });

    test('PR spaces use the number', () {
      expect(
        environmentNameFor(template: '{branch}', branch: 'x', prNumber: 7),
        'pr-7',
      );
      expect(
        environmentNameFor(template: 'a-{branch}', branch: 'Fix'),
        'a-fix',
      );
    });

    test('router labels stay one valid label', () {
      final label = environmentRouterLabel(
        endpoint: 'web',
        name: 'fix-login',
        project: 'shop',
      );
      expect(label, 'web--fix-login--shop');
      final long = environmentRouterLabel(
        endpoint: 'dashboard',
        name: 'a' * 60,
        project: 'marketplace',
      );
      expect(long.length, lessThanOrEqualTo(63));
      expect(isValidEnvironmentLabel(long), isTrue);
    });
  });

  group('globs', () {
    test('* stays in a segment and ** crosses', () {
      expect(
        environmentGlobMatches(['pnpm-lock.yaml'], 'pnpm-lock.yaml'),
        isTrue,
      );
      expect(
        environmentGlobMatches([
          'packages/*/package.json',
        ], 'packages/a/package.json'),
        isTrue,
      );
      expect(
        environmentGlobMatches([
          'packages/*/package.json',
        ], 'packages/a/b/package.json'),
        isFalse,
      );
      expect(environmentGlobMatches(['app/**'], 'app/a/b.ts'), isTrue);
      expect(
        environmentGlobMatches(['**/migrations/**'], 'db/migrations/1.sql'),
        isTrue,
      );
      expect(
        environmentGlobMatches(['**/migrations/**'], 'migrations/1.sql'),
        isTrue,
      );
      expect(environmentGlobMatches(['a.b'], 'axb'), isFalse);
    });
  });

  group('records', () {
    test('overrides merge into objects', () {
      expect(
        mergeEnvironmentOverrides(
          {
            'a': 1,
            'policy': {'x': 1, 'y': 2},
          },
          {
            'policy': {'y': 3},
          },
        ),
        {
          'a': 1,
          'policy': {'x': 1, 'y': 3},
        },
      );
    });

    test('a space environment survives the wire', () {
      final now = DateTime.utc(2026, 11, 6);
      final environment = SpaceEnvironment(
        id: 'e',
        workspaceId: 'w',
        spaceId: 's',
        definitionId: 'd',
        name: 'n',
        status: EnvironmentStatus.ready,
        ports: const {'web': 42000},
        endpoints: [
          EnvironmentEndpoint(
            role: 'web',
            url: 'http://a.localhost',
            primary: true,
          ),
        ],
        components: [
          EnvironmentComponentState(id: 'web', kind: 'process', state: 'ready'),
        ],
        createdBy: 'u',
        createdAt: now,
        lastUsedAt: now,
      );
      expect(
        SpaceEnvironment.fromJson(
          jsonDecode(jsonEncode(environment.toJson())) as Map<String, dynamic>,
        ),
        environment,
      );
      expect(environment.primaryEndpoint?.role, 'web');
    });
  });

  test('task timeouts follow the trigger', () {
    expect(
      TaskEnvironmentComponent(
        id: 'a',
        command: ShellEnvironmentCommand('x'),
        when: {EnvironmentTaskTrigger.archive},
      ).timeoutSeconds,
      120,
    );
    expect(
      TaskEnvironmentComponent(
        id: 'a',
        command: ShellEnvironmentCommand('x'),
        when: {EnvironmentTaskTrigger.provision},
      ).timeoutSeconds,
      300,
    );
  });
}
