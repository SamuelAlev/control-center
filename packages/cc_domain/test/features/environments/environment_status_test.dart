import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentStatus.canBecome', () {
    test('a teardown under way ends failed or gone, never back up', () {
      const from = EnvironmentStatus.destroying;
      expect(from.canBecome(EnvironmentStatus.gone), isTrue);
      expect(from.canBecome(EnvironmentStatus.failed), isTrue);
      for (final next in [
        EnvironmentStatus.ready,
        EnvironmentStatus.degraded,
        EnvironmentStatus.starting,
        EnvironmentStatus.stopped,
      ]) {
        expect(from.canBecome(next), isFalse, reason: next.wire);
      }
    });

    test('nothing comes up from a stop without starting first', () {
      for (final from in [
        EnvironmentStatus.stopping,
        EnvironmentStatus.stopped,
        EnvironmentStatus.gone,
      ]) {
        expect(from.canBecome(EnvironmentStatus.ready), isFalse);
        expect(from.canBecome(EnvironmentStatus.degraded), isFalse);
        expect(from.canBecome(EnvironmentStatus.destroying), isTrue);
      }
      expect(
        EnvironmentStatus.stopped.canBecome(EnvironmentStatus.starting),
        isTrue,
      );
    });

    test('a failed environment may recover on its own', () {
      expect(
        EnvironmentStatus.failed.canBecome(EnvironmentStatus.ready),
        isTrue,
      );
    });

    test('staying put is always allowed', () {
      for (final status in EnvironmentStatus.values) {
        expect(status.canBecome(status), isTrue);
      }
    });

    test('one waiting on a person can start again or go away', () {
      const from = EnvironmentStatus.blocked;
      expect(from.canBecome(EnvironmentStatus.starting), isTrue);
      expect(from.canBecome(EnvironmentStatus.destroying), isTrue);
    });
  });

  group('EnvironmentStatus', () {
    test('broken and waiting on a person both need someone', () {
      expect(
        EnvironmentStatus.values.where((status) => status.needsAttention),
        [EnvironmentStatus.failed, EnvironmentStatus.blocked],
      );
    });

    test('waiting on a person is neither busy nor running', () {
      expect(EnvironmentStatus.blocked.isBusy, isFalse);
      expect(EnvironmentStatus.blocked.isRunning, isFalse);
    });

    test('an unknown status reads as failed', () {
      expect(EnvironmentStatus.fromWire('blocked'), EnvironmentStatus.blocked);
      expect(EnvironmentStatus.fromWire('quantum'), EnvironmentStatus.failed);
    });
  });

  group('EnvironmentBlocker', () {
    test('the exit code says what a command waits for', () {
      expect(EnvironmentBlocker.ofExitCode(3), EnvironmentBlocker.input);
      expect(
        EnvironmentBlocker.ofExitCode(4),
        EnvironmentBlocker.authentication,
      );
      expect(EnvironmentBlocker.ofExitCode(5), EnvironmentBlocker.dependency);
      for (final code in [null, 0, 1, 2, 6, 130, -1]) {
        expect(EnvironmentBlocker.ofExitCode(code), isNull, reason: '$code');
      }
    });

    test('a terminal answers a prompt, not a sign-in or a dependency', () {
      expect(EnvironmentBlocker.input.answersOnTerminal, isTrue);
      expect(EnvironmentBlocker.authentication.answersOnTerminal, isFalse);
      expect(EnvironmentBlocker.dependency.answersOnTerminal, isFalse);
    });

    test('an error carries it through its exit code', () {
      const waiting = EnvironmentError(
        code: 'needs-sudo',
        message: 'Needs a password',
        exitCode: 3,
      );
      const broken = EnvironmentError(code: 'boom', message: 'Broke');
      expect(waiting.blocker, EnvironmentBlocker.input);
      expect(broken.blocker, isNull);
      expect(
        EnvironmentError.tryFromJson(waiting.toJson())?.blocker,
        EnvironmentBlocker.input,
      );
    });
  });

  group('EnvironmentProgress', () {
    test('reads a step with its id and state', () {
      final step = EnvironmentProgress.tryParseLine(
        ' {"type":"step","id":"db","label":"Starting the database",'
        '"state":"running"} ',
      )!;
      expect(step.isStep, isTrue);
      expect(step.key, 'db');
      expect(step.label, 'Starting the database');
      expect(step.state, 'running');
      expect(step.logLine, '[step] Starting the database');
    });

    test('a step with no id is told apart by its label', () {
      final step = EnvironmentProgress.tryParseLine(
        '{"type":"step","label":"Migrating","state":"done"}',
      )!;
      expect(step.key, 'Migrating');
      expect(step.logLine, '[step] Migrating (done)');
    });

    test('a counter names a step as well as a word does', () {
      final first = EnvironmentProgress.tryParseLine(
        '{"type":"step","id":1,"label":"Checking the base stack",'
        '"state":"running"}',
      )!;
      final again = EnvironmentProgress.tryParseLine(
        '{"type":"step","id":1,"label":"Starting the containers",'
        '"state":"running"}',
      )!;
      expect(first.id, '1');
      expect(again.key, first.key);
      expect(
        EnvironmentProgress.tryParseLine(
          '{"type":"step","id":"1","label":"Same step","state":"done"}',
        )!.key,
        first.key,
      );
    });

    test('a line of output wrapped in JSON is that line', () {
      final log = EnvironmentProgress.tryParseLine(
        '{"at":"2026-01-01T00:00:00Z","type":"log","stream":"stderr",'
        '"line":"Error response from daemon: token has expired"}',
      )!;
      expect(log.isLog, isTrue);
      expect(log.isStep, isFalse);
      expect(log.isWarning, isFalse);
      expect(log.logLine, 'Error response from daemon: token has expired');
      expect(EnvironmentProgress.tryParseLine('{"type":"log"}'), isNull);
    });

    test('tools spell a step\'s state their own way', () {
      for (final (wire, state) in [
        ('running', EnvironmentStepState.running),
        ('started', EnvironmentStepState.running),
        ('done', EnvironmentStepState.done),
        ('succeeded', EnvironmentStepState.done),
        ('ok', EnvironmentStepState.done),
        ('failed', EnvironmentStepState.failed),
        ('error', EnvironmentStepState.failed),
        ('queued', EnvironmentStepState.pending),
        ('queued', EnvironmentStepState.pending),
        // Announced with no state: it is what the tool does now.
        (null, EnvironmentStepState.running),
      ]) {
        expect(EnvironmentStepState.parse(wire), state, reason: '$wire');
      }
    });

    test('a note reads its message, and only a warning stays in sight', () {
      final warning = EnvironmentProgress.tryParseLine(
        '{"type":"note","level":"warn","message":"Cache is cold"}',
      )!;
      final note = EnvironmentProgress.tryParseLine(
        '{"type":"note","message":"Using port 3000"}',
      )!;
      expect(warning.isWarning, isTrue);
      expect(warning.isStep, isFalse);
      expect(warning.label, 'Cache is cold');
      expect(note.isWarning, isFalse);
      expect(note.logLine, '[note] Using port 3000');
    });

    test('anything else is plain output', () {
      for (final line in [
        'Compiling...',
        '{not json',
        '[1, 2]',
        '{"type":"error","message":"no"}',
        '{"label":"no type"}',
        '{"type":7}',
      ]) {
        expect(EnvironmentProgress.tryParseLine(line), isNull, reason: line);
      }
    });

    test('a step with nothing to tell it by is not a step', () {
      final step = EnvironmentProgress.tryParseLine('{"type":"step"}')!;
      expect(step.isStep, isFalse);
    });

    test('a stored step reads back', () {
      const step = EnvironmentProgress(
        type: 'step',
        id: 'db',
        label: 'Starting the database',
        state: 'done',
      );
      expect(EnvironmentProgress.tryFromJson(step.toJson()), step);
      expect(EnvironmentProgress.tryFromJson(const {'id': 'db'}), isNull);
    });
  });

  group('EnvironmentComponentState', () {
    EnvironmentComponentState tool({
      String state = 'starting',
      String? sessionId,
    }) => EnvironmentComponentState(
      id: 'stack',
      kind: 'cli',
      state: state,
      sessionId: sessionId,
    );

    EnvironmentProgress step(String id, String label, [String? state]) =>
        EnvironmentProgress(type: 'step', id: id, label: label, state: state);

    test('steps keep the order they first appeared in', () {
      final state = tool()
          .withStep(step('db', 'Database', 'running'))
          .withStep(step('web', 'Web', 'running'))
          .withStep(step('db', 'Database is up', 'done'));
      expect(
        [for (final item in state.steps) '${item.label}:${item.state}'],
        ['Database is up:done', 'Web:running'],
      );
    });

    test('a step that changes its words stays one step', () {
      var state = tool();
      for (final label in ['Creating', 'Pulling images', 'Starting']) {
        state = state.withStep(step('1', label, 'running'));
      }
      expect(state.steps.single.label, 'Starting');
      expect(state.currentStep?.label, 'Starting');
    });

    test('without an id, the next step ends the one before it', () {
      EnvironmentProgress unnamed(String label, String state) =>
          EnvironmentProgress(type: 'step', label: label, state: state);
      final state = tool()
          .withStep(unnamed('Pulling images', 'running'))
          .withStep(unnamed('Starting containers', 'running'))
          // The same step again is no next step.
          .withStep(unnamed('Starting containers', 'running'));
      expect(
        [for (final item in state.steps) '${item.label}:${item.state}'],
        ['Pulling images:done', 'Starting containers:running'],
      );
      expect(state.currentStep?.label, 'Starting containers');
    });

    test('named steps may run side by side', () {
      final state = tool()
          .withStep(step('db', 'Database', 'running'))
          .withStep(step('web', 'Web', 'running'));
      expect(
        [for (final item in state.steps) item.stepState],
        [EnvironmentStepState.running, EnvironmentStepState.running],
      );
      // The latest is the one to name.
      expect(state.currentStep?.label, 'Web');
    });

    test('a command that exits takes its open steps with it', () {
      final state = tool()
          .withStep(step('db', 'Database', 'done'))
          .withStep(step('web', 'Web', 'running'));
      expect(
        [
          for (final item in state.withStepsEnded(failed: false).steps)
            item.state,
        ],
        ['done', 'done'],
      );
      final failed = state.withStepsEnded(failed: true);
      expect([for (final item in failed.steps) item.state], ['done', 'failed']);
      expect(failed.currentStep, isNull);
      // Nothing under way: nothing to rewrite.
      expect(failed.withStepsEnded(failed: false), same(failed));
    });

    test('a step with nothing to tell it by changes nothing', () {
      final state = tool();
      expect(
        state.withStep(const EnvironmentProgress(type: 'step')),
        same(state),
      );
    });

    test('steps and the terminal session survive the wire', () {
      final state = tool(
        state: EnvironmentComponentPhase.interactive.wire,
        sessionId: 'session-1',
      ).withStep(step('db', 'Database', 'done'));
      expect(EnvironmentComponentState.fromJson(state.toJson()), state);
    });

    test('a copy can drop the session and the detail', () {
      final state = tool(sessionId: 'session-1').copyWith(detail: 'Waiting');
      expect(state.copyWith().sessionId, 'session-1');
      expect(state.copyWith().detail, 'Waiting');
      final cleared = state.copyWith(clearSessionId: true, clearDetail: true);
      expect(cleared.sessionId, isNull);
      expect(cleared.detail, isNull);
    });
  });

  group('SpaceEnvironment.interactiveComponent', () {
    SpaceEnvironment environment(List<EnvironmentComponentState> components) =>
        SpaceEnvironment(
          id: 'env-1',
          workspaceId: 'ws-1',
          spaceId: 'space-1',
          definitionId: 'def-1',
          name: 'fix-login',
          status: EnvironmentStatus.starting,
          components: components,
          createdBy: 'user:u',
          createdAt: DateTime.utc(2026),
          lastUsedAt: DateTime.utc(2026),
        );

    EnvironmentComponentState tool(String state, {String? sessionId}) =>
        EnvironmentComponentState(
          id: 'stack',
          kind: 'cli',
          state: state,
          sessionId: sessionId,
        );

    test('is the component a terminal waits on', () {
      final waiting = tool('interactive', sessionId: 'session-1');
      expect(
        environment([tool('ready'), waiting]).interactiveComponent,
        waiting,
      );
    });

    test('is nothing without a session to open', () {
      expect(environment([tool('interactive')]).interactiveComponent, isNull);
      expect(
        environment([
          tool('starting', sessionId: 'session-1'),
        ]).interactiveComponent,
        isNull,
      );
    });
  });

  group('SpaceEnvironment.startComponents', () {
    EnvironmentComponentState part(String id, String kind, String state) =>
        EnvironmentComponentState(id: id, kind: kind, state: state);

    test('are what a start goes through, in order', () {
      final environment = SpaceEnvironment(
        id: 'env-1',
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        definitionId: 'def-1',
        name: 'fix-login',
        status: EnvironmentStatus.starting,
        components: [
          part('stack', 'cli', 'starting'),
          part('seed', 'task', 'pending'),
          // Runs on request: this start has nothing for it.
          part('test', 'task', 'idle'),
          part('web', 'process', 'pending'),
          // Someone launches an app; a start never does.
          part('studio', 'app', 'closed'),
        ],
        createdBy: 'user:u',
        createdAt: DateTime.utc(2026),
        lastUsedAt: DateTime.utc(2026),
      );
      expect(
        [for (final component in environment.startComponents) component.id],
        ['stack', 'seed', 'web'],
      );
    });
  });

  group('EnvironmentError', () {
    test('keeps what the command last printed, over the wire too', () {
      const error = EnvironmentError(
        code: 'compose-failed',
        message: 'compose exited 1',
        exitCode: 1,
        output: 'pull access denied\ntoken has expired',
      );
      expect(EnvironmentError.tryFromJson(error.toJson()), error);
      expect(
        EnvironmentError.tryFromJson(const {'message': 'Broke'})?.output,
        isNull,
      );
    });
  });

  group('EnvironmentComponentPhase', () {
    test('every phase round-trips, an unknown one reads as null', () {
      for (final phase in EnvironmentComponentPhase.values) {
        expect(EnvironmentComponentPhase.tryParse(phase.wire), phase);
      }
      expect(EnvironmentComponentPhase.tryParse('quantum'), isNull);
    });

    test('live, up, failed and down are decided here', () {
      expect(EnvironmentComponentPhase.values.where((p) => p.isLive).toSet(), {
        EnvironmentComponentPhase.starting,
        EnvironmentComponentPhase.interactive,
        EnvironmentComponentPhase.running,
        EnvironmentComponentPhase.ready,
      });
      expect(
        EnvironmentComponentPhase.values.where((p) => p.isFailed).toSet(),
        {EnvironmentComponentPhase.failed, EnvironmentComponentPhase.crashed},
      );
      expect(EnvironmentComponentPhase.waiting.isUp, isFalse);
      expect(EnvironmentComponentPhase.closed.isDown, isTrue);
      // An idle task is not coming up and has not gone down: it is not part
      // of this.
      expect(EnvironmentComponentPhase.idle.isLive, isFalse);
      expect(EnvironmentComponentPhase.idle.isDown, isFalse);
    });
  });
}
