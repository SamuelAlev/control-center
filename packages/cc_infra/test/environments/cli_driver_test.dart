import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status_map.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_infra/src/environments/cli_driver.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

void main() {
  late List<EnvironmentCommandResult> statuses;
  late Map<String, EnvironmentCommandResult> verbs;
  late FakeCommandRunner runner;
  late CliDriver driver;

  EnvironmentCommand verb(List<Object> items) =>
      EnvironmentCommand.fromJson(items, path: 'verb');

  final statusMap = EnvironmentStatusMap.fromJson({
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
    'detail': 'post-start: {/status/postStart}',
    'warnings': [
      {
        'when': {'path': '/status/dns', 'equals': false},
        'message': 'Not resolvable on this host',
      },
    ],
    'endpoints': [
      {'role': 'app', 'url': '/urls/app', 'primary': true},
      {'role': 'evil', 'url': '/urls/evil'},
      {'role': 'dev', 'hostPort': '/port'},
    ],
    'services': '/status/containers/*/service',
    'list': '/*/slug',
    'missingErrorCodes': ['env.not-found'],
  });

  CliEnvironmentComponent component({
    EnvironmentStatusMap? map,
    bool withStart = true,
    int readyTimeout = 1,
    Map<String, int> timeouts = const {},
  }) => CliEnvironmentComponent(
    id: 'tool',
    label: 'Tool',
    verbs: {
      'create': verb([
        'tool',
        'env',
        'create',
        '{name}',
        {
          'if': 'repo.web',
          'args': ['--web', '{repo.web}'],
        },
        {
          'if': '!opt.dns',
          'args': ['--no-hosts'],
        },
      ]),
      if (withStart) 'start': verb(['tool', 'env', 'start', '{name}']),
      'stop': verb(['tool', 'env', 'stop', '{name}']),
      'destroy': verb(['tool', 'env', 'destroy', '{name}', '--yes']),
      'reset': verb(['tool', 'env', 'reset-db', '{name}']),
      'status': verb(['tool', 'env', 'status', '{name}', '--json']),
      'list': verb(['tool', 'env', 'ls', '--json']),
      'logs': verb([
        'tool',
        'logs',
        '{name}',
        {
          'if': 'service',
          'args': ['{service}'],
        },
        '--tail',
        '{tail}',
        {
          'if': 'follow',
          'args': ['--follow'],
        },
      ]),
      'exec': verb(['tool', 'exec', '{name}', '{service}', '{command}']),
    },
    statusMap: map,
    readyTimeoutSeconds: readyTimeout,
    timeouts: timeouts,
  );

  CliContext context({
    CliEnvironmentComponent? tool,
    String? domain = 'acme.test',
    EnvironmentValues? values,
  }) => CliContext(
    component: tool ?? component(map: statusMap),
    values:
        values ??
        const EnvironmentValues({'name': 'fix-login', 'opt.dns': 'false'}),
    workingDirectory: '/worktree',
    environment: const {'CC_ENV_NAME': 'fix-login'},
    routingDomain: domain,
  );

  EnvironmentCommandResult status(Map<String, Object?> json) =>
      ok(jsonEncode(json));

  final ready = status({
    'status': {
      'ready': true,
      'postStart': 'succeeded',
      'containers': [
        {'service': 'app', 'state': 'running'},
      ],
    },
    'urls': {
      'app': 'https://fix-login.acme.test',
      'evil': 'https://attacker.example',
    },
    'port': 49213,
  });
  final stopped = status({
    'status': {'containers': <Object>[]},
  });
  final starting = status({
    'status': {
      'containers': [
        {'state': 'running'},
      ],
    },
  });
  final broken = status({
    'status': {
      'postStart': 'failed',
      'containers': [
        {'state': 'running'},
      ],
    },
  });
  final missing = failed(
    1,
    error: const EnvironmentError(
      code: 'env.not-found',
      message: 'Environment does not exist',
      exitCode: 1,
    ),
  );

  setUp(() {
    statuses = [ready];
    verbs = {};
    runner = FakeCommandRunner((call) {
      if (call.argv.contains('status')) {
        return statuses.length > 1 ? statuses.removeAt(0) : statuses.single;
      }
      final name = call.argv.firstWhere(
        (word) => verbs.containsKey(word),
        orElse: () => '',
      );
      return verbs[name] ?? ok();
    });
    driver = CliDriver(
      runner: runner,
      pollInterval: const Duration(milliseconds: 5),
    );
  });

  Matcher failsWith(String code, [Object? extra]) => throwsA(
    isA<EnvironmentDriverException>()
        .having((e) => e.error.code, 'code', code)
        .having((e) => e.error, 'error', extra ?? anything),
  );

  List<String> verbCalls() => [
    for (final call in runner.calls)
      if (!call.argv.contains('status')) call.line,
  ];

  group('status', () {
    test('maps the tool\'s JSON', () async {
      final report = await driver.status(context());
      expect(report.state, EnvironmentReportedState.ready);
      expect(report.detail, 'post-start: succeeded');
      expect(report.services, ['app']);
      expect(report.endpoints.first.primary, isTrue);
    });

    test('runs the verb with the values, env, cwd and timeout', () async {
      await driver.status(
        context(
          tool: component(map: statusMap, timeouts: const {'status': 7}),
        ),
      );
      final call = runner.calls.single;
      expect(call.argv, ['tool', 'env', 'status', 'fix-login', '--json']);
      expect(call.workingDirectory, '/worktree');
      expect(call.environment['CC_ENV_NAME'], 'fix-login');
      expect(call.timeout, const Duration(seconds: 7));
    });

    test('status defaults to a short timeout', () async {
      await driver.status(context());
      expect(runner.calls.single.timeout, const Duration(seconds: 30));
    });

    test('reads the native contract with no statusMap', () async {
      statuses = [
        status({
          'state': 'starting',
          'detail': 'pulling',
          'endpoints': [
            {'role': 'pg', 'hostPort': 49213},
          ],
          'needsRecreate': true,
          'unknown': 'ignored',
        }),
      ];
      final report = await driver.status(context(tool: component()));
      expect(report.state, EnvironmentReportedState.starting);
      expect(report.needsRecreate, isTrue);
      expect(report.endpoints.single.hostPort, 49213);
    });

    test('parses raw output, not the redacted copy', () async {
      statuses = [
        EnvironmentCommandResult(
          exitCode: 0,
          display: 'tool',
          stdout: 'broken by redaction',
          rawStdout: jsonEncode({'state': 'ready'}),
        ),
      ];
      final report = await driver.status(context(tool: component()));
      expect(report.state, EnvironmentReportedState.ready);
    });

    test('unparsed output is redacted before it is shown', () async {
      statuses = [ok('oops --token=hunter2')];
      final report = await driver.status(context(tool: component()));
      expect(report.detail, isNot(contains('hunter2')));
    });

    test('bad JSON is degraded with the raw text', () async {
      statuses = [ok('Welcome to tool!')];
      final report = await driver.status(context());
      expect(report.state, EnvironmentReportedState.degraded);
      expect(report.detail, 'Welcome to tool!');
    });

    test('bad JSON is degraded on the native path too', () async {
      statuses = [ok('Welcome to tool!')];
      final report = await driver.status(context(tool: component()));
      expect(report.state, EnvironmentReportedState.degraded);
    });

    test('a missing code means missing', () async {
      statuses = [missing];
      final report = await driver.status(context());
      expect(report.state, EnvironmentReportedState.missing);
      expect(report.error, isNull);
    });

    test('any other failure is failed, with the error', () async {
      statuses = [failed(1, stderr: 'kaboom')];
      final report = await driver.status(context());
      expect(report.state, EnvironmentReportedState.failed);
      expect(report.error?.message, 'kaboom');
    });

    group('endpoints', () {
      test('outside the domain are dropped and logged', () async {
        final logged = <String>[];
        final previous = CcInfraLog.sink;
        CcInfraLog.sink = (level, message, [error, stack]) =>
            logged.add(message);
        addTearDown(() => CcInfraLog.sink = previous);

        final report = await driver.status(context());
        expect(report.endpoints.map((e) => e.role), ['app', 'dev']);
        expect(logged.join(), contains('attacker.example'));
      });

      test('keep the rest of the report', () async {
        statuses = [
          status({
            'status': {
              'ready': true,
              'dns': false,
              'containers': [
                {'service': 'app', 'state': 'running'},
              ],
            },
            'urls': {'evil': 'https://attacker.example'},
          }),
        ];
        final report = await driver.status(context());
        expect(report.state, EnvironmentReportedState.ready);
        expect(report.warnings, ['Not resolvable on this host']);
        expect(report.services, ['app']);
      });

      test('with no domain only loopback survives', () async {
        final report = await driver.status(context(domain: null));
        expect(report.endpoints.map((e) => e.role), ['dev']);
      });
    });
  });

  group('up', () {
    test('ready is reused and nothing runs', () async {
      final report = await driver.up(context());
      expect(report.state, EnvironmentReportedState.ready);
      expect(verbCalls(), isEmpty);
    });

    test('missing runs create, with conditionals applied', () async {
      statuses = [missing, starting, ready];
      await driver.up(context());
      expect(verbCalls(), ['tool env create fix-login --no-hosts']);
    });

    test('a repo role switches its arguments on', () async {
      statuses = [missing, ready];
      await driver.up(
        context(
          values: const EnvironmentValues({
            'name': 'fix-login',
            'opt.dns': 'true',
            'repo.web': '/w/web',
          }),
        ),
      );
      expect(verbCalls(), ['tool env create fix-login --web /w/web']);
    });

    test('stopped runs start', () async {
      statuses = [stopped, ready];
      await driver.up(context());
      expect(verbCalls(), ['tool env start fix-login']);
    });

    test('stopped with no start verb runs create', () async {
      statuses = [stopped, ready];
      await driver.up(
        context(tool: component(map: statusMap, withStart: false)),
      );
      expect(verbCalls().single, startsWith('tool env create'));
    });

    test('failed gets one start', () async {
      statuses = [broken, ready];
      await driver.up(context());
      expect(verbCalls(), ['tool env start fix-login']);
    });

    test('failed with no start verb fails', () async {
      statuses = [broken];
      await expectLater(
        driver.up(context(tool: component(map: statusMap, withStart: false))),
        failsWith('failed'),
      );
    });

    test('starting is waited for, with no verb', () async {
      statuses = [starting, starting, ready];
      await driver.up(context());
      expect(verbCalls(), isEmpty);
    });

    test('an unreadable first status stops right there', () async {
      statuses = [ok('Welcome')];
      await expectLater(driver.up(context()), failsWith('status-unreadable'));
      expect(verbCalls(), isEmpty);
    });

    test('progress reaches the caller', () async {
      statuses = [missing, ready];
      await driver.up(context(), onEvent: (_) {});
      expect(verbCalls(), hasLength(1));
    });

    test('a stopped report after create is not the end', () async {
      statuses = [missing, stopped, stopped, ready];
      final report = await driver.up(context());
      expect(report.state, EnvironmentReportedState.ready);
    });

    test('a rule\'s own message leads, with the detail as its hint', () async {
      final worded = EnvironmentStatusMap.fromJson({
        ...statusMap.toJson(),
        'state': [
          {
            'when': {'path': '/status/postStart', 'equals': 'failed'},
            'state': 'failed',
            'message': 'The post-start script failed ({/status/postStart})',
          },
          {'state': 'starting'},
        ],
      });
      statuses = [stopped, starting, broken];
      await expectLater(
        driver.up(context(tool: component(map: worded))),
        failsWith(
          'failed',
          isA<EnvironmentError>()
              .having(
                (e) => e.message,
                'message',
                'The post-start script failed (failed)',
              )
              .having((e) => e.hint, 'hint', 'post-start: failed'),
        ),
      );
    });

    test('failed after start ends the wait with the detail', () async {
      statuses = [stopped, starting, broken];
      await expectLater(
        driver.up(context()),
        failsWith(
          'failed',
          isA<EnvironmentError>().having(
            (e) => e.message,
            'message',
            contains('post-start: failed'),
          ),
        ),
      );
    });

    test('a timeout carries the last detail', () async {
      statuses = [starting];
      driver = CliDriver(
        runner: runner,
        pollInterval: const Duration(milliseconds: 100),
      );
      await expectLater(
        driver.up(context(tool: component(map: statusMap))),
        failsWith(
          'ready-timeout',
          isA<EnvironmentError>().having(
            (e) => e.message,
            'message',
            allOf(contains('after 1 s'), contains('post-start')),
          ),
        ),
      );
    });

    for (final code in const [3, 4, 5]) {
      test('exit $code from a verb surfaces with its command', () async {
        statuses = [missing];
        final error = EnvironmentError(
          code: 'host',
          message: 'Needs a hosts line',
          command: 'sudo tool hosts add',
          exitCode: code,
        );
        verbs['create'] = failed(code, error: error);
        await expectLater(driver.up(context()), failsWith('host', error));
      });

      test('exit $code from status surfaces too', () async {
        final error = EnvironmentError(
          code: 'login',
          message: 'Sign in',
          command: 'tool login',
          exitCode: code,
        );
        statuses = [failed(code, error: error)];
        await expectLater(driver.up(context()), failsWith('login', error));
      });
    }

    test('any other failed verb throws too', () async {
      statuses = [missing];
      verbs['create'] = failed(1, stderr: 'no');
      await expectLater(driver.up(context()), failsWith('command-failed'));
    });
  });

  group('other verbs', () {
    test('stop', () async {
      await driver.stop(context());
      expect(verbCalls(), ['tool env stop fix-login']);
    });

    test('reset', () async {
      await driver.reset(context());
      expect(verbCalls(), ['tool env reset-db fix-login']);
    });

    test('a per-verb timeout applies', () async {
      await driver.stop(
        context(
          tool: component(map: statusMap, timeouts: const {'stop': 9}),
        ),
      );
      expect(runner.calls.single.timeout, const Duration(seconds: 9));
    });

    test('a verb the definition lacks is a clear error', () async {
      final tool = CliEnvironmentComponent(
        id: 'tool',
        verbs: {
          'create': verb(['tool']),
          'status': verb(['tool']),
          'destroy': verb(['tool']),
        },
      );
      await expectLater(
        driver.stop(context(tool: tool)),
        failsWith('verb-missing'),
      );
    });

    test('destroy passes --yes through', () async {
      await driver.destroy(context());
      expect(verbCalls(), ['tool env destroy fix-login --yes']);
    });

    test('destroying what is already gone is success', () async {
      verbs['destroy'] = missing;
      await driver.destroy(context());
    });

    test('a failed destroy throws', () async {
      verbs['destroy'] = failed(1, stderr: 'busy');
      await expectLater(driver.destroy(context()), failsWith('command-failed'));
    });

    test('list reads names through the map', () async {
      verbs['ls'] = ok(
        jsonEncode([
          {'slug': 'a'},
          {'slug': 'b'},
        ]),
      );
      expect(await driver.list(context()), ['a', 'b']);
    });

    test('list reads strings and {name} natively', () async {
      verbs['ls'] = ok(
        jsonEncode([
          'a',
          {'name': 'b'},
        ]),
      );
      expect(await driver.list(context(tool: component())), ['a', 'b']);
    });

    test('logs fills {tail} and skips what isn\'t set', () async {
      verbs['logs'] = ok('hello');
      expect(await driver.logs(context(), tail: 50), 'hello');
      expect(verbCalls(), ['tool logs fix-login --tail 50']);
    });

    test('logs names a service', () async {
      await driver.logs(context(), service: 'app');
      expect(verbCalls(), ['tool logs fix-login app --tail 200']);
    });

    test('followLogs streams until cancelled', () async {
      runner = FakeStreamingRunner();
      driver = CliDriver(runner: runner);
      final lines = <String>[];
      final subscription = driver
          .followLogs(context(), service: 'app')
          .listen(lines.add);
      await Future<void>.delayed(Duration.zero);
      final stream = runner.streams.single;
      expect(stream.call.line, 'tool logs fix-login app --tail 200 --follow');
      stream.emit('hello');
      await Future<void>.delayed(Duration.zero);
      expect(lines, ['hello']);
      await subscription.cancel();
      expect(stream.cancelled, isTrue);
    });

    test('exec joins the command into one argument', () async {
      verbs['exec'] = failed(2, stdout: 'out', stderr: 'err');
      final result = await driver.exec(
        context(),
        service: 'app',
        command: ['php', 'composer.phar', 'a b'],
      );
      expect(runner.calls.single.argv, [
        'tool',
        'exec',
        'fix-login',
        'app',
        "php composer.phar 'a b'",
      ]);
      expect((result.exitCode, result.stdout), (2, 'out'));
    });
  });
}

/// Runs `start` through [startArgv], where [FakeCommandRunner] records streams.
class FakeStreamingRunner extends FakeCommandRunner {
  FakeStreamingRunner() : super((_) => ok());
}
