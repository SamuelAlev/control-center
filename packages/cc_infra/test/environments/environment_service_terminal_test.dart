import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_service_ports.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';
import 'helpers/environment_service_harness.dart';

/// A start that needs a person: what happens when someone is there to answer
/// on a terminal, and what happens when nobody is.
void main() {
  late ServiceHarness h;

  setUp(() {
    h = ServiceHarness(tempDir(addTearDown).path);
    addTearDown(() => h.service.stopListening());
  });

  SpaceEnvironment row() => h.environments.rows.values.single;

  EnvironmentComponentState tool() => row().components.single;

  const missing = EnvironmentError(
    code: 'env.not-found',
    message: 'No such environment',
  );

  const needsSudo = EnvironmentError(
    code: 'hosts',
    message: 'Adding the hostnames needs sudo',
    command: 'printed by the tool --do-not-run-me',
    exitCode: 3,
  );

  void definition({List<String> interactive = const ['create']}) => h.store(
    definitionJson([
      {
        'kind': 'cli',
        'id': 'tool',
        'verbs': {
          'create': [
            'tool',
            'create',
            '{name}',
            // Only a verb that can run on a terminal may ask whether it does.
            if (interactive.contains('create'))
              {
                'if': '!interactive',
                'args': ['--json'],
              },
          ],
          'start': ['tool', 'start'],
          'reset': ['tool', 'reset'],
          'status': ['tool', 'status'],
          'destroy': ['tool', 'destroy'],
        },
        if (interactive.isNotEmpty) 'interactive': interactive,
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

  /// The tool has no environment yet, and its `create` wants a password.
  void createNeedsSudo() {
    h.tool['status'] = failed(1, error: missing);
    h.tool['create'] = failed(3, error: needsSudo);
  }

  /// Completes once the start waits on a terminal.
  Future<void> waiting() => h.until(
    () => h.environments.rows.isNotEmpty && row().interactiveComponent != null,
  );

  /// The person answered: the tool finishes on the terminal and comes up.
  void answer() {
    h.tool['status'] = ok(jsonEncode({'up': true}));
    h.terminals.last.exit.complete(0);
  }

  group('with someone there to answer', () {
    test('the same start waits on a terminal and carries on', () async {
      definition();
      createNeedsSudo();

      final starting = h.ensure(attended: true);
      await waiting();

      expect(row().status, EnvironmentStatus.creating);
      expect(row().lastError, isNull);
      expect(tool().phase, EnvironmentComponentPhase.interactive);
      expect(tool().sessionId, 'session-1');
      expect(tool().detail, 'Adding the hostnames needs sudo');

      answer();
      final started = await starting;

      expect(started.status, EnvironmentStatus.ready);
      expect(started.lastError, isNull);
      expect(tool().phase, EnvironmentComponentPhase.ready);
      expect(tool().sessionId, isNull);
      final runs = await h.runs.forSpace('ws-a', 'space-1');
      expect(runs.single.kind, EnvironmentRunKind.start);
      expect(runs.single.status, EnvironmentRunStatus.succeeded);
    });

    test('runs the definition\'s verb, not what the tool printed', () async {
      definition();
      createNeedsSudo();

      final starting = h.ensure(attended: true);
      await waiting();

      final session = h.terminals.last;
      expect(session.executable, '/usr/bin/tool');
      // The same argv as through the pipe, minus what `!interactive` guards.
      expect(session.arguments, ['create', row().name]);
      expect(session.environment['CC_ENV_INTERACTIVE'], '1');
      expect(session.environment['TERM'], 'xterm-256color');
      expect(session.owner, 'environment:${row().id}/terminal');
      expect(h.runner.callsWith('create').single.argv, [
        'tool',
        'create',
        row().name,
        '--json',
      ]);

      answer();
      await starting;
    });

    test('what the terminal printed reaches the run record', () async {
      definition();
      createNeedsSudo();

      final starting = h.ensure(attended: true);
      await waiting();
      h.terminals.last.print('Password:\nhosts updated\n');
      answer();
      await starting;

      final run = (await h.runs.forSpace('ws-a', 'space-1')).single;
      expect(run.output, contains('Adding the hostnames needs sudo'));
      expect(run.output, contains('hosts updated'));
    });

    test('a verb that fails on the terminal fails the start', () async {
      definition();
      createNeedsSudo();

      final starting = h.ensure(attended: true);
      await waiting();
      h.terminals.last.exit.complete(1);
      final ended = await starting;

      // The terminal was the place to answer, so this is no longer waiting.
      expect(ended.status, EnvironmentStatus.failed);
      expect(ended.lastError?.code, 'terminal-failed');
      expect(ended.lastError?.blocker, isNull);
      expect(ended.lastError?.hint, 'Adding the hostnames needs sudo');
      // What the tool suggested stays, for whoever does it by hand.
      expect(ended.lastError?.command, needsSudo.command);
      expect(tool().phase, EnvironmentComponentPhase.failed);
      expect(tool().sessionId, isNull);
      final run = (await h.runs.forSpace('ws-a', 'space-1')).single;
      expect(run.status, EnvironmentRunStatus.failed);
    });

    test('nobody answering in time leaves it waiting for someone', () async {
      h.terminalTimeout = const Duration(milliseconds: 30);
      definition();
      createNeedsSudo();

      final ended = await h.ensure(attended: true);

      expect(h.terminals.last.killed, isTrue);
      expect(ended.status, EnvironmentStatus.blocked);
      expect(ended.lastError?.blocker, EnvironmentBlocker.input);
      expect(ended.lastError?.message, 'Adding the hostnames needs sudo');
      expect(tool().sessionId, isNull);
    });

    test('stop ends the terminal and takes its turn', () async {
      definition();
      createNeedsSudo();

      final starting = h.ensure(attended: true);
      await waiting();
      await h.service.stop('ws-a', 'space-1', by: principal);

      expect(h.terminals.last.killed, isTrue);
      expect((await starting).lastError?.code, 'cancelled');
      expect(row().status, EnvironmentStatus.stopped);
    });

    test('destroy ends the terminal too', () async {
      definition();
      createNeedsSudo();

      final starting = h.ensure(attended: true);
      await waiting();
      await h.service.destroy('ws-a', 'space-1', by: principal);
      await starting;

      expect(h.terminals.last.killed, isTrue);
      expect(h.environments.rows, isEmpty);
    });

    test('a space being deleted does not wait for an answer', () async {
      definition();
      createNeedsSudo();

      final starting = h.ensure(attended: true);
      await waiting();
      await h.service.beforeRelease('ws-a', 'space-1');
      await starting;

      expect(h.terminals.last.killed, isTrue);
      expect(h.environments.rows, isEmpty);
    });

    test('reset can carry on at a terminal as well', () async {
      definition(interactive: const ['create', 'reset']);
      h.tool['status'] = ok(jsonEncode({'up': true}));
      await h.ensure();
      h.tool['reset'] = failed(3, error: needsSudo);

      final resetting = h.service.reset(
        'ws-a',
        'space-1',
        attended: true,
        by: principal,
      );
      await waiting();

      expect(row().status, EnvironmentStatus.starting);
      expect(h.terminals.last.arguments, ['reset']);

      h.terminals.last.exit.complete(0);
      expect((await resetting).status, EnvironmentStatus.ready);
    });
  });

  group('never on a terminal', () {
    Future<SpaceEnvironment> blockedStart({
      bool attended = true,
      Principal by = principal,
    }) async {
      final ended = await h.ensure(attended: attended, by: by);
      expect(h.terminals.sessions, isEmpty);
      expect(ended.status, EnvironmentStatus.blocked);
      expect(ended.lastError?.blocker, isNotNull);
      return ended;
    }

    test('when nobody said they are there', () async {
      definition();
      createNeedsSudo();

      final ended = await blockedStart(attended: false);

      expect(ended.lastError?.command, needsSudo.command);
      expect(tool().phase, EnvironmentComponentPhase.failed);
      final run = (await h.runs.forSpace('ws-a', 'space-1')).single;
      expect(run.status, EnvironmentRunStatus.blocked);
      expect(run.exitCode, 3);
      expect(run.error, 'Adding the hostnames needs sudo');
    });

    test('for an agent, whatever it says', () async {
      definition();
      createNeedsSudo();

      await blockedStart(by: const AgentPrincipal('agent-1'));
    });

    test('for a sign-in, which is another command to run', () async {
      definition();
      h.tool['status'] = failed(1, error: missing);
      h.tool['create'] = failed(
        4,
        error: const EnvironmentError(
          code: 'auth',
          message: 'The session expired',
          command: 'tool login',
          exitCode: 4,
        ),
      );

      final ended = await blockedStart();

      expect(ended.lastError?.blocker, EnvironmentBlocker.authentication);
      expect(ended.lastError?.command, 'tool login');
    });

    test('for a verb the definition did not declare interactive', () async {
      definition(interactive: const []);
      createNeedsSudo();

      await blockedStart();
    });

    test('for a verb other than the declared one', () async {
      definition(interactive: const ['reset']);
      createNeedsSudo();

      await blockedStart();
    });

    test('in a fork, where a stranger\'s branch could reach it', () async {
      definition();
      createNeedsSudo();
      final space = h.directory.spaces['space-1']!;
      h.directory.spaces['space-1'] = EnvironmentSpaceInfo(
        id: space.id,
        workspaceId: space.workspaceId,
        name: space.name,
        branch: space.branch,
        repos: space.repos,
        isFork: true,
      );
      h.admin = true;

      await blockedStart();
    });

    test('for a dependency, which no terminal can supply', () async {
      definition();
      h.tool['status'] = failed(1, error: missing);
      h.tool['create'] = failed(
        5,
        error: const EnvironmentError(
          code: 'docker',
          message: 'Docker is not running',
          exitCode: 5,
        ),
      );

      final ended = await blockedStart();

      expect(ended.lastError?.blocker, EnvironmentBlocker.dependency);
    });

    test('an ordinary failure still reads as one', () async {
      definition();
      h.tool['status'] = failed(1, error: missing);
      h.tool['create'] = failed(1, stderr: 'boom');

      final ended = await h.ensure(attended: true);

      expect(h.terminals.sessions, isEmpty);
      expect(ended.status, EnvironmentStatus.failed);
      final run = (await h.runs.forSpace('ws-a', 'space-1')).single;
      expect(run.status, EnvironmentRunStatus.failed);
    });
  });

  group('a blocked environment', () {
    setUp(() {
      definition();
      createNeedsSudo();
    });

    test('keeps the reason through a poll', () async {
      await h.ensure();
      h.now = h.now.add(const Duration(minutes: 6));

      await h.service.runMaintenance();

      expect(row().status, EnvironmentStatus.blocked);
      expect(row().lastError?.blocker, EnvironmentBlocker.input);
    });

    test('keeps it through a restart', () async {
      await h.ensure();

      await h.service.recover();

      expect(row().status, EnvironmentStatus.blocked);
    });

    test('starts again, attended, from where it stopped', () async {
      await h.ensure();

      final starting = h.ensure(attended: true);
      await waiting();

      expect(row().status, EnvironmentStatus.starting);
      expect(row().lastError, isNull);
      answer();
      expect((await starting).status, EnvironmentStatus.ready);
    });
  });

  group('recovery', () {
    test('a start interrupted on a terminal no longer names it', () async {
      definition();
      createNeedsSudo();
      unawaited(h.ensure(attended: true));
      await waiting();

      // A server that restarts mid-start reads the row as it was left.
      final left = row();
      final fresh = ServiceHarness(tempDir(addTearDown).path);
      addTearDown(() => fresh.service.stopListening());
      fresh.definitions.records.addAll(h.definitions.records);
      fresh.environments.rows[left.id] = left;
      await fresh.service.recover();

      final recovered = fresh.environments.rows[left.id]!;
      expect(recovered.status, EnvironmentStatus.failed);
      expect(recovered.lastError?.code, 'interrupted');
      expect(recovered.interactiveComponent, isNull);
      expect(recovered.components.single.sessionId, isNull);

      h.terminals.last.exit.complete(1);
    });
  });

  group('what a start says while it runs', () {
    EnvironmentCommandProgress line(Map<String, dynamic> json) =>
        EnvironmentCommandProgress(
          EnvironmentProgress.tryParseLine(jsonEncode(json))!,
        );

    test('steps land on the component, replaced by id', () async {
      definition();
      h.tool['status'] = failed(1, error: missing);
      h.tool['create'] = ok();
      h.runner.events = (call) => call.argv.contains('create')
          ? [
              line({
                'type': 'step',
                'id': 'images',
                'label': 'Pulling images',
                'state': 'running',
              }),
              line({
                'type': 'step',
                'id': 'db',
                'label': 'Restoring the database',
                'state': 'running',
              }),
              line({
                'type': 'step',
                'id': 'images',
                'label': 'Pulled 4 images',
                'state': 'succeeded',
              }),
              const EnvironmentCommandOutput('plain output'),
            ]
          : const [];
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('create')) {
          h.tool['status'] = ok(jsonEncode({'up': true}));
        }
      };

      await h.ensure();

      expect(
        [for (final step in tool().steps) '${step.label} (${step.state})'],
        // The command ended well, so the step it left under way did too.
        ['Pulled 4 images (succeeded)', 'Restoring the database (done)'],
      );
      final run = (await h.runs.forSpace('ws-a', 'space-1')).single;
      expect(run.output, contains('[step] Pulling images'));
      expect(run.output, contains('[step] Pulled 4 images (succeeded)'));
      expect(run.output, contains('plain output'));
    });

    test('one step that changes its words stays one step', () async {
      // A tool with a single spinner: the same id, a number, and a new label
      // for each thing it does.
      definition();
      h.tool['status'] = failed(1, error: missing);
      h.tool['create'] = ok();
      final during = <String>[];
      h.runner.events = (call) => call.argv.contains('create')
          ? [
              for (final label in [
                'Creating the environment',
                'Checking the base stack',
                'Starting the containers',
              ])
                line({
                  'type': 'step',
                  'id': 1,
                  'label': label,
                  'state': 'running',
                }),
            ]
          : const [];
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('create')) {
          await h.until(
            () => tool().currentStep?.label == 'Starting the containers',
          );
          during.addAll([
            for (final step in tool().steps)
              '${step.label} (${step.stepState.name})',
          ]);
          h.tool['status'] = ok(jsonEncode({'up': true}));
        }
      };

      await h.ensure();

      expect(during, ['Starting the containers (running)']);
      expect(
        [
          for (final step in tool().steps)
            '${step.label} (${step.stepState.name})',
        ],
        ['Starting the containers (done)'],
      );
      expect(tool().currentStep, isNull);
    });

    test('steps with no id follow each other', () async {
      definition();
      h.tool['status'] = failed(1, error: missing);
      h.tool['create'] = failed(1, stderr: 'no route to the registry');
      final during = <String>[];
      h.runner.events = (call) => call.argv.contains('create')
          ? [
              line({'type': 'step', 'label': 'Pulling images'}),
              line({'type': 'step', 'label': 'Starting the containers'}),
            ]
          : const [];
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('create')) {
          await h.until(() => tool().steps.length == 2);
          during.addAll([
            for (final step in tool().steps)
              '${step.label} (${step.stepState.name})',
          ]);
        }
      };

      await h.ensure();

      expect(during, [
        'Pulling images (done)',
        'Starting the containers (running)',
      ]);
      // The command failed with a step open: that is where it failed.
      expect(
        [
          for (final step in tool().steps)
            '${step.label} (${step.stepState.name})',
        ],
        ['Pulling images (done)', 'Starting the containers (failed)'],
      );
    });

    test('a warning stays on the environment, a note does not', () async {
      definition();
      h.tool['status'] = failed(1, error: missing);
      h.tool['create'] = ok();
      h.runner.events = (call) => call.argv.contains('create')
          ? [
              line({
                'type': 'note',
                'level': 'warn',
                'message': 'The marketplace service is off',
              }),
              line({'type': 'note', 'message': 'Reused a volume'}),
            ]
          : const [];
      h.runner.beforeAnswer = (call) async {
        if (call.argv.contains('create')) {
          h.tool['status'] = ok(jsonEncode({'up': true}));
        }
      };

      await h.ensure();

      expect(row().warnings, ['The marketplace service is off']);
    });

    test('a new start begins with no steps', () async {
      definition();
      h.tool['status'] = failed(1, error: missing);
      h.tool['create'] = failed(1, stderr: 'boom');
      h.runner.events = (call) => call.argv.contains('create')
          ? [
              line({'type': 'step', 'label': 'Pulling images'}),
            ]
          : const [];
      await h.ensure();
      expect(tool().steps, hasLength(1));

      h.runner.events = null;
      h.tool['status'] = ok(jsonEncode({'up': true}));
      await h.ensure();

      expect(tool().steps, isEmpty);
    });

    test('runs are watched: started, printing, ended', () async {
      definition();
      createNeedsSudo();
      final seen = <List<EnvironmentRun>>[];
      final subscription = h.service
          .watchRuns('ws-a', 'space-1')
          .listen(seen.add);
      addTearDown(subscription.cancel);
      await h.until(() => seen.isNotEmpty);
      expect(seen.single, isEmpty);

      final starting = h.ensure(attended: true);
      await waiting();
      await h.until(
        () => seen.last.isNotEmpty && seen.last.single.output.isNotEmpty,
      );
      expect(seen.last.single.status, EnvironmentRunStatus.running);
      expect(
        seen.last.single.output,
        contains('Adding the hostnames needs sudo'),
      );

      answer();
      await starting;
      await h.until(
        () => seen.last.single.status == EnvironmentRunStatus.succeeded,
      );
    });

    test('a poll does not overwrite a start in progress', () async {
      definition();
      createNeedsSudo();
      final starting = h.ensure(attended: true);
      await waiting();

      h.now = h.now.add(const Duration(minutes: 6));
      await h.service.runMaintenance();

      expect(tool().phase, EnvironmentComponentPhase.interactive);
      answer();
      await starting;
    });
  });
}
