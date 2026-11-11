import 'dart:convert';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/services/environment_definition_validator.dart';
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

Map<String, dynamic> _cli([Map<String, dynamic> extra = const {}]) => {
  'kind': 'cli',
  'id': 'tool',
  'verbs': {
    'create': ['acme', 'up', '{name}'],
    'status': ['acme', 'status', '{name}', '--json'],
    'destroy': ['acme', 'down', '{name}'],
  },
  ...extra,
};

Map<String, dynamic> _app([Map<String, dynamic> extra = const {}]) => {
  'kind': 'app',
  'id': 'desktop',
  'command': ['dist/studio'],
  ...extra,
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

    test('malformed shapes throw their issues, never TypeErrors', () {
      for (final (bad, path) in <(Map<String, dynamic>, String)>[
        ({}, 'components'),
        ({..._minimal(), 'repos': {}}, 'repos'),
        (
          {
            ..._minimal(),
            'repos': {'a': 1},
          },
          'repos.a',
        ),
        (
          {
            ..._minimal(),
            'components': [
              {'kind': 'nope', 'id': 'x'},
            ],
          },
          'components[0].kind',
        ),
        (
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
          'components[0].when[0]',
        ),
      ]) {
        expect(
          () => EnvironmentDefinition.fromJson(bad),
          throwsA(
            isA<EnvironmentDefinitionException>().having(
              (error) => error.issues.map((issue) => issue.path),
              'paths',
              contains(path),
            ),
          ),
          reason: path,
        );
      }
    });

    test('the declared default role, never another one present', () {
      final definition = EnvironmentDefinition.fromJson(_full());
      final deps = definition.component('deps')!;
      final test = definition.component('test')!;
      expect(definition.roleFor(deps, {'app', 'e2e'}), 'app');
      expect(definition.roleFor(deps, {'e2e'}), isNull);
      expect(definition.roleFor(test, {'app', 'e2e'}), 'e2e');
      expect(definition.roleFor(test, {'app'}), isNull);
    });

    test('a definition of worktree tasks only has no stack', () {
      final definition = EnvironmentDefinition.fromJson({
        'contract': 1,
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
      final issues = parseEnvironmentDefinition({
        ..._minimal(),
        'repos': {
          'app': {'anchor': true},
          'bound': {'repoId': 'repo-1'},
          'tests': <String, dynamic>{},
        },
      }).issues;
      expect(issues, const [
        EnvironmentDefinitionIssue('repos.app.repoId', 'Pick a repo'),
        EnvironmentDefinitionIssue('repos.tests.repoId', 'Pick a repo'),
      ]);
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

    test('after waits only for an earlier component that starts', () {
      List<String> issuesOf(List<Map<String, dynamic>> components) {
        final json = _minimal()..['components'] = components;
        return validateEnvironmentDefinition(
          EnvironmentDefinition.fromJson(json),
        ).map((issue) => issue.message).toList();
      }

      final web = {
        'kind': 'process',
        'id': 'web',
        'port': 'web',
        'command': ['a'],
      };
      expect(
        issuesOf([
          {
            ...web,
            'after': ['web'],
          },
        ]),
        contains(contains('can not wait for itself')),
      );
      expect(
        issuesOf([
          {
            ...web,
            'after': ['ghost'],
          },
        ]),
        contains(contains('Unknown component ghost')),
      );
      // A forward reference is also the only way to write a cycle.
      expect(
        issuesOf([
          {
            ...web,
            'after': ['api'],
          },
          {
            'kind': 'process',
            'id': 'api',
            'port': 'api',
            'command': ['b'],
            'after': ['web'],
          },
        ]),
        contains(contains('api is declared after this component')),
      );
      expect(
        issuesOf([
          {
            'kind': 'task',
            'id': 'deps',
            'when': ['provision'],
            'command': ['npm', 'ci'],
          },
          {
            ...web,
            'after': ['deps'],
          },
        ]),
        contains(contains('never starts with the stack')),
      );
      expect(
        issuesOf([
          {'kind': 'compose', 'id': 'db'},
          {
            ...web,
            'after': ['db'],
          },
        ]),
        isEmpty,
      );
    });

    test('an environment runs one compose component', () {
      final json = _minimal()
        ..['components'] = [
          {'kind': 'compose', 'id': 'one'},
          {'kind': 'compose', 'id': 'two'},
        ];
      expect(
        validateEnvironmentDefinition(
          EnvironmentDefinition.fromJson(json),
        ).map((issue) => issue.path),
        contains('components[1]'),
      );
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

  group('strict parsing', () {
    List<EnvironmentDefinitionIssue> shape(Map<String, dynamic> json) =>
        parseEnvironmentDefinition(json).issues;
    List<String> shapePaths(Map<String, dynamic> json) =>
        shape(json).map((issue) => issue.path).toList();
    List<String> allPaths(Map<String, dynamic> json) =>
        checkEnvironmentDefinition(json).map((issue) => issue.path).toList();
    Map<String, dynamic> withComponents(List<Map<String, dynamic>> list) =>
        _minimal()..['components'] = list;
    Map<String, dynamic> process(Map<String, dynamic> extra) => {
      'kind': 'process',
      'id': 'web',
      'port': 'web',
      'command': ['vite'],
      ...extra,
    };

    test('every definition here parses with no issue', () {
      expect(shape(_minimal()), isEmpty);
      expect(shape(_full()), isEmpty);
      expect(shape(withComponents([_cli()])), isEmpty);
    });

    test('an unknown field is named, with the field it is close to', () {
      final issues = shape({..._minimal(), 'polcy': <String, dynamic>{}});
      expect(issues.single.path, 'polcy');
      expect(issues.single.message, contains('Did you mean "policy"'));
      expect(
        shapePaths(
          withComponents([
            {
              'kind': 'compose',
              'id': 'stack',
              'servics': ['db'],
            },
          ]),
        ),
        ['components[0].servics'],
      );
    });

    test(r'only the top level tolerates $schema', () {
      expect(
        shape({..._minimal(), r'$schema': 'https://acme.test/s'}),
        isEmpty,
      );
      expect(
        shapePaths({
          ..._minimal(),
          'policy': {r'$schema': 'x'},
        }),
        [r'policy.$schema'],
      );
    });

    test('collects every issue in one pass', () {
      expect(
        shapePaths({
          'name': 3,
          'repos': {
            'app': {'repoId': 'r', 'anchor': 'yes'},
          },
          'placement': 'vm',
          'components': [
            {'kind': 'compose'},
          ],
        }),
        containsAll([
          'contract',
          'name',
          'repos.app.anchor',
          'placement',
          'components[0].id',
        ]),
      );
    });

    test('a misspelt choice names the allowed values', () {
      for (final (json, path) in <(Map<String, dynamic>, String)>[
        ({..._minimal(), 'placement': 'vm'}, 'placement'),
        (
          {
            ..._minimal(),
            'routing': {'mode': 'tools'},
          },
          'routing.mode',
        ),
        (
          {
            ..._minimal(),
            'repos': {
              'app': {'repoId': 'r', 'anchor': true, 'whenMissing': 'add'},
            },
          },
          'repos.app.whenMissing',
        ),
        (
          {
            ..._minimal(),
            'policy': {'autoCreate': 'prspaces'},
          },
          'policy.autoCreate',
        ),
        (
          {
            ..._minimal(),
            'policy': {'forkPrs': 'vm'},
          },
          'policy.forkPrs',
        ),
        (
          withComponents([
            process({'restart': 'on_failure'}),
          ]),
          'components[0].restart',
        ),
        (
          withComponents([
            _app({'input': 'fg'}),
          ]),
          'components[0].input',
        ),
        (
          withComponents([
            _app({'isolate': 'tmp'}),
          ]),
          'components[0].isolate',
        ),
        (
          {
            ..._minimal(),
            'options': [
              {'key': 'seed', 'type': 'boolean'},
            ],
          },
          'options[0].type',
        ),
        (
          withComponents([
            {
              'kind': 'task',
              'id': 'deps',
              'when': ['provison'],
              'command': ['pnpm', 'i'],
            },
          ]),
          'components[0].when[0]',
        ),
      ]) {
        final issues = shape(json);
        expect(issues.map((issue) => issue.path), [path], reason: path);
        expect(issues.single.message, contains('Use one of'), reason: path);
      }
      expect(
        shape(
          withComponents([
            {
              'kind': 'task',
              'id': 'deps',
              'when': ['provison'],
              'command': ['pnpm', 'i'],
            },
          ]),
        ).single.message,
        contains('Did you mean "provision"'),
      );
    });

    test('a bool is a real bool', () {
      expect(
        shapePaths({
          ..._minimal(),
          'repos': {
            'app': {'repoId': 'r', 'anchor': 'true'},
          },
          'routing': {'mode': 'tool', 'tls': 'yes'},
          'components': [
            process({
              'endpoint': {'role': 'web', 'primary': 'true'},
            }),
          ],
        }),
        ['repos.app.anchor', 'routing.tls', 'components[0].endpoint.primary'],
      );
    });

    test('a missing id is an issue at its path', () {
      expect(
        shapePaths({
          ..._minimal(),
          'checks': [
            {
              'label': 'Docker',
              'command': ['docker', 'info'],
            },
          ],
          'components': [
            {'kind': 'compose'},
          ],
        }),
        ['checks[0].id', 'components[0].id'],
      );
    });

    test('contract is required and must be 1', () {
      expect(shapePaths({..._minimal()}..remove('contract')), ['contract']);
      expect(shapePaths({..._minimal(), 'contract': '1'}), ['contract']);
      expect(allPaths({..._minimal(), 'contract': 2}), ['contract']);
    });

    test('role names are lower-case identifiers', () {
      for (final key in ['App', 'web-ui', '1st']) {
        expect(
          shapePaths({
            ..._minimal(),
            'repos': {
              key: {'repoId': 'r', 'anchor': true},
            },
          }),
          ['repos.$key'],
          reason: key,
        );
      }
    });

    test('env values are strings', () {
      expect(
        shapePaths({
          ..._minimal(),
          'env': {'PORT_COUNT': 3},
          'components': [
            {
              'kind': 'compose',
              'id': 'stack',
              'env': {'DEBUG': true},
            },
          ],
        }),
        ['env.PORT_COUNT', 'components[0].env.DEBUG'],
      );
    });

    test('a port is a name in port, or names in ports', () {
      expect(
        shapePaths(
          withComponents([
            process({'port': 3000}),
          ]),
        ),
        ['components[0].port'],
      );
      expect(
        shapePaths(
          withComponents([
            process({
              'port': ['web'],
            }),
          ]),
        ),
        ['components[0].port'],
      );
      expect(
        shapePaths(
          withComponents([
            process({
              'port': 'web',
              'ports': ['hmr'],
            }),
          ]),
        ),
        isEmpty,
      );
    });

    test('compose and cli refuse the ports they would ignore', () {
      expect(
        shapePaths(
          withComponents([
            {'kind': 'compose', 'id': 'stack', 'port': 'db'},
          ]),
        ),
        ['components[0].port'],
      );
      expect(
        shapePaths(
          withComponents([
            _cli({
              'ports': ['web'],
            }),
          ]),
        ),
        ['components[0].ports'],
      );
    });

    test('an app refuses after, which it would ignore', () {
      expect(
        shapePaths(
          withComponents([
            {'kind': 'compose', 'id': 'stack'},
            _app({
              'after': ['stack'],
            }),
          ]),
        ),
        ['components[1].after'],
      );
    });

    test('window matching is gone', () {
      expect(
        shapePaths(
          withComponents([
            _app({
              'window': {
                'match': {'bundleId': 'com.acme.studio'},
              },
            }),
          ]),
        ),
        ['components[0].window'],
      );
    });

    test('a component runs command or script, as a list of lines', () {
      expect(
        shapePaths(
          withComponents([
            {
              'kind': 'task',
              'id': 'seed',
              'when': ['create'],
              'script': 'pnpm seed',
            },
          ]),
        ),
        ['components[0].script'],
      );
      expect(
        shapePaths(
          withComponents([
            {
              'kind': 'task',
              'id': 'seed',
              'when': ['create'],
              'script': ['pnpm seed'],
              'command': ['pnpm', 'seed'],
            },
          ]),
        ),
        ['components[0].script'],
      );
      expect(
        shapePaths(
          withComponents([
            {
              'kind': 'task',
              'id': 'seed',
              'when': ['create'],
            },
          ]),
        ),
        ['components[0].command'],
      );
      expect(
        shapePaths(
          withComponents([
            process({
              'command': [
                'vite',
                {'if': 'opt.x'},
              ],
            }),
          ]),
        ),
        ['components[0].command[1].args'],
      );
    });

    test('a tool maps the verbs it can not do without', () {
      final cli = _cli();
      (cli['verbs'] as Map).remove('destroy');
      expect(shapePaths(withComponents([cli])), [
        'components[0].verbs.destroy',
      ]);
    });

    test('timeouts are positive', () {
      expect(
        allPaths(
          withComponents([
            {'kind': 'compose', 'id': 'stack', 'timeout': 0},
            {
              'kind': 'task',
              'id': 'seed',
              'when': ['create'],
              'command': ['seed'],
              'timeout': 0,
            },
            process({
              'ready': {'timeout': 0},
            }),
          ]),
        ),
        containsAll([
          'components[0].timeout',
          'components[1].timeout',
          'components[2].ready.timeout',
        ]),
      );
      expect(
        allPaths(
          withComponents([
            _cli({
              'readyTimeout': 0,
              'timeouts': {'status': 0},
            }),
          ]),
        ),
        ['components[0].timeouts.status', 'components[0].readyTimeout'],
      );
    });

    test('policy numbers stay in range', () {
      expect(
        allPaths({
          ..._minimal(),
          'policy': {'idleStopMinutes': -1, 'maxRunning': -1, 'rigTtlHours': 0},
        }),
        ['policy.idleStopMinutes', 'policy.maxRunning', 'policy.rigTtlHours'],
      );
      expect(
        allPaths({
          ..._minimal(),
          'policy': {'rigTtlHours': 721},
        }),
        ['policy.rigTtlHours'],
      );
      expect(
        allPaths({
          ..._minimal(),
          'policy': {'idleStopMinutes': 0, 'maxRunning': 0, 'rigTtlHours': 720},
        }),
        isEmpty,
      );
      expect(
        allPaths({
          ..._minimal(),
          'naming': {'maxLength': 64},
        }),
        ['naming.maxLength'],
      );
    });

    test('regular expressions compile at save', () {
      expect(
        allPaths({
          ..._minimal(),
          'checks': [
            {
              'id': 'docker',
              'command': ['docker', 'info'],
              'expectOutput': '(unclosed',
            },
          ],
          'components': [
            process({
              'ready': {'logMatch': '[ready'},
            }),
          ],
        }),
        ['checks[0].expectOutput', 'components[0].ready.logMatch'],
      );
    });

    test('check ids are unique', () {
      Map<String, dynamic> check() => {
        'id': 'docker',
        'command': ['docker', 'info'],
      };
      expect(
        allPaths({
          ..._minimal(),
          'checks': [check(), check()],
        }),
        ['checks[1].id'],
      );
    });

    test('ready probes are a URL and a host:port', () {
      List<String> ready(Map<String, dynamic> probe) => allPaths(
        withComponents([
          process({'ready': probe}),
        ]),
      );

      expect(ready({'http': '/health'}), ['components[0].ready.http']);
      expect(ready({'tcp': '{port.web}'}), ['components[0].ready.tcp']);
      expect(
        ready({
          'http': 'http://127.0.0.1:{port.web}/health',
          'tcp': '127.0.0.1:{port.web}',
        }),
        isEmpty,
      );
      expect(ready({'tcp': 'localhost:5432'}), isEmpty);
    });

    test('endpoint roles are slugs, unique, with one primary', () {
      expect(
        allPaths(
          withComponents([
            process({
              'endpoint': {'role': 'Web'},
            }),
          ]),
        ),
        ['components[0].endpoint.role'],
      );
      expect(
        allPaths(
          withComponents([
            process({
              'endpoint': {'role': 'web', 'primary': true},
            }),
            {
              'kind': 'process',
              'id': 'api',
              'port': 'api',
              'command': ['api'],
              'endpoint': {'role': 'web', 'primary': true},
            },
          ]),
        ),
        ['components[1].endpoint.role', 'components[1].endpoint.primary'],
      );
    });

    test('option defaults fit the option', () {
      List<String> option(Map<String, dynamic> json) => allPaths({
        ..._minimal(),
        'options': [
          {'key': 'x', ...json},
        ],
      });

      expect(option({'type': 'bool', 'default': 'yes'}), [
        'options[0].default',
      ]);
      expect(option({'type': 'string', 'agentDefault': 3}), [
        'options[0].agentDefault',
      ]);
      expect(option({'type': 'enum'}), ['options[0].values']);
      expect(
        option({
          'type': 'enum',
          'values': ['a', 'b'],
          'default': 'c',
        }),
        ['options[0].default'],
      );
      expect(
        option({
          'type': 'multi',
          'values': ['a', 'b'],
          'default': 'a',
          'agentDefault': ['a', 'c'],
        }),
        ['options[0].default', 'options[0].agentDefault'],
      );
      expect(
        option({
          'type': 'string',
          'values': ['a'],
        }),
        ['options[0].values'],
      );
      expect(
        option({
          'type': 'multi',
          'values': ['a', 'b'],
          'default': ['a'],
          'agentDefault': <String>[],
        }),
        isEmpty,
      );
    });

    test('routing.domain is checked in every mode, the tool fields only fit '
        'tool mode', () {
      expect(
        allPaths({
          ..._minimal(),
          'routing': {
            'domain': 'example.com',
            'upstream': '127.0.0.1:443',
            'tls': true,
            'caFile': '~/.acme/ca.crt',
          },
        }),
        ['routing.domain', 'routing.upstream', 'routing.tls', 'routing.caFile'],
      );
      expect(
        allPaths({
          ..._minimal(),
          'routing': {'domain': 'acme.test'},
        }),
        isEmpty,
      );
    });

    test('a statusMap is checked at save', () {
      final issues = shape(
        withComponents([
          _cli({
            'statusMap': {
              'state': [
                {
                  'when': {'path': '/status/ready', 'equal': true},
                  'state': 'ready',
                },
                {'state': 'up'},
                {
                  'when': {'path': 'status/phase', 'equals': 'failed'},
                  'state': 'failed',
                },
                {
                  'when': {'any': '/containers', 'none': '/containers'},
                  'state': 'stopped',
                },
              ],
              'endpoints': [
                {'role': '', 'url': '/urls/app'},
                {'role': 'db'},
              ],
              'services': 'containers/*/service',
            },
          }),
        ]),
      );
      const map = 'components[0].statusMap';
      expect(issues.map((issue) => issue.path), [
        '$map.state[0].when.equal',
        '$map.state[1].state',
        '$map.state[2].when.path',
        '$map.state[3].when',
        '$map.endpoints[0].role',
        '$map.endpoints[1]',
        '$map.services',
      ]);
      expect(issues.first.message, contains('Did you mean "equals"'));
    });

    test('a statusMap on its own throws its issues', () {
      expect(
        () => EnvironmentStatusMap.fromJson({
          'state': [
            {'state': 'bogus'},
          ],
        }),
        throwsA(
          isA<EnvironmentDefinitionException>().having(
            (error) => error.issues.single.path,
            'path',
            'statusMap.state[0].state',
          ),
        ),
      );
    });

    test('a definition that is not an object is one issue', () {
      expect(parseEnvironmentDefinition([]).issues, const [
        EnvironmentDefinitionIssue('', 'A definition must be a JSON object'),
      ]);
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

  group('the default role', () {
    List<(String, String)> issuesOf(
      List<Map<String, dynamic>> components, {
      bool appRequired = false,
      bool otherAnchor = true,
    }) {
      final json = _minimal()
        ..['repos'] = {
          'app': {'repoId': 'repo-1', 'anchor': true, 'required': appRequired},
          'e2e': {'repoId': 'repo-2', 'anchor': otherAnchor, 'required': true},
        }
        ..['components'] = components;
      return [
        for (final issue in validateEnvironmentDefinition(
          EnvironmentDefinition.fromJson(json),
        ))
          (issue.path, issue.message),
      ];
    }

    test('relying on an optional first role is an issue there', () {
      expect(
        issuesOf([
          {
            'kind': 'task',
            'id': 'named',
            'when': ['start'],
            'cwd': {'role': 'e2e'},
            'command': ['a'],
          },
          {
            'kind': 'task',
            'id': 'seed',
            'when': ['start'],
            'command': ['a'],
          },
        ]),
        [
          (
            'components[1]',
            'Runs in app, which a space may not have. Name a role in cwd, or '
                'make app required',
          ),
        ],
      );
    });

    test('a required first role, the one anchor, a named role or a worktree '
        'task is fine', () {
      final seed = {
        'kind': 'task',
        'id': 'seed',
        'when': ['start'],
        'command': ['a'],
      };
      expect(issuesOf([seed], appRequired: true), isEmpty);
      // The one anchor: no space starts this without it.
      expect(issuesOf([seed], otherAnchor: false), isEmpty);
      expect(
        issuesOf([
          {
            ...seed,
            'cwd': {'role': 'app'},
          },
          {
            'kind': 'task',
            'id': 'deps',
            'when': ['provision'],
            'command': ['a'],
          },
        ]),
        isEmpty,
      );
    });
  });
}
