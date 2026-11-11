import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';
import 'helpers/environment_service_harness.dart';

void main() {
  late ServiceHarness h;

  setUp(() {
    h = ServiceHarness(tempDir(addTearDown).path);
    addTearDown(() => h.service.stopListening());
  });

  Matcher driverError(String code, [Object message = anything]) => throwsA(
    isA<EnvironmentDriverException>()
        .having((e) => e.error.code, 'code', code)
        .having((e) => e.error.message, 'message', message),
  );

  SpaceEnvironment row() => h.environments.rows.values.firstWhere(
    (item) => item.spaceId == 'space-1',
  );

  EnvironmentComponentState component(String id) =>
      row().components.firstWhere((item) => item.id == id);

  Map<String, dynamic> appJson({Map<String, dynamic> extra = const {}}) => {
    'kind': 'app',
    'id': 'desktop',
    'command': ['tool', 'open'],
    ...extra,
  };

  Future<void> launch({bool rebuild = false}) => h.service.launchApp(
    'ws-a',
    'space-1',
    'desktop',
    rebuild: rebuild,
    by: principal,
  );

  List<FakeTerminalSession> appSessions() => [
    for (final session in h.terminals.sessions)
      if (session.owner.endsWith('/desktop')) session,
  ];

  group('enabledWhen', () {
    Map<String, dynamic> withOption(List<Map<String, dynamic>> components) =>
        definitionJson(
          components,
          extra: {
            'options': [
              {'key': 'desktop', 'type': 'bool', 'default': false},
            ],
          },
        );

    test('an app that is off is refused', () async {
      h.store(
        withOption([
          webJson(),
          appJson(extra: {'enabledWhen': 'opt.desktop'}),
        ]),
      );
      await h.ensure();
      await expectLater(
        launch(),
        driverError('component-disabled', contains('enabledWhen')),
      );
      expect(appSessions(), isEmpty);
    });

    test('an app whose prepare task is off is refused', () async {
      h.store(
        withOption([
          webJson(),
          taskJson('build', ['manual'], extra: {'enabledWhen': 'opt.desktop'}),
          appJson(extra: {'prepare': 'build'}),
        ]),
      );
      await h.ensure();
      h.runner.calls.clear();
      await expectLater(
        launch(),
        driverError('component-disabled', contains('build')),
      );
      expect(h.commands, isEmpty);
      expect(appSessions(), isEmpty);
    });

    test('an app that is on launches', () async {
      h.store(
        withOption([
          webJson(),
          appJson(extra: {'enabledWhen': 'opt.desktop'}),
        ]),
      );
      await h.ensure(options: {'desktop': true});
      await launch();
      expect(appSessions(), hasLength(1));
    });
  });

  test('a launch decides on the row it finds under the lock', () async {
    h.store(
      definitionJson([
        webJson(),
        taskJson('build', ['manual']),
        appJson(extra: {'prepare': 'build'}),
      ]),
    );
    await h.ensure();
    final building = Completer<void>();
    final release = Completer<void>();
    h.runner.beforeAnswer = (call) async {
      if (call.argv.contains('build')) {
        building.complete();
        await release.future;
      }
    };
    // The first launch holds the lock while it builds; a stop queues behind
    // it, and a second launch reads the row while it still says ready.
    final first = launch();
    await building.future;
    final stopped = h.service.stop('ws-a', 'space-1', by: principal);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = expectLater(
      launch(rebuild: true),
      driverError('not-running'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    release.complete();
    await first;
    await stopped;
    await second;
    expect(appSessions(), hasLength(1));
    expect(appSessions().single.exit.isCompleted, isTrue);
  });

  group('a launcher that exits', () {
    test('keeps the app running until its group is gone', () async {
      h.appLaunchGrace = Duration.zero;
      h.store(definitionJson([webJson(), appJson()]));
      await h.ensure();
      await h.service.start(runRecovery: false);
      await launch();
      final launcher = appSessions().single;
      h.groups.groups[launcher.pid] = [launcher.pid + 1000];
      launcher.exit.complete(0);
      await h.until(() => component('desktop').sessionId == null);
      expect(component('desktop').state, 'running');
      expect(component('desktop').services.single['rig_id'], 'rig-window');

      // A second Launch finds it running.
      await launch();
      expect(appSessions(), hasLength(1));

      // Stop still reaches what the launcher left.
      final signalled = h.groups.onSignal;
      h.groups.onSignal = (group, signal) {
        signalled?.call(group, signal);
        h.groups.groups.remove(group);
      };
      await h.service.stopApp('ws-a', 'space-1', 'desktop', by: principal);
      expect(h.groups.signals, contains((launcher.pid, ProcessSignal.sigint)));
      await h.until(() => component('desktop').state == 'closed');
      expect(component('desktop').services, isEmpty);
    });

    test('with nothing left right after launch, it failed', () async {
      h.store(definitionJson([webJson(), appJson()]));
      await h.ensure();
      await h.service.start(runRecovery: false);
      await launch();
      appSessions().single
        ..print('no display\r\n')
        ..exit.complete(0);
      await h.until(() => component('desktop').state == 'failed');
      expect(component('desktop').detail, contains('right after launch'));
      expect(component('desktop').detail, contains('no display'));
      expect(component('desktop').services, isEmpty);
      expect(h.windows.closed, ['rig-window']);
    });
  });

  group('the viewer', () {
    setUp(() {
      h.appLaunchGrace = Duration.zero;
      h.store(definitionJson([webJson(), appJson()]));
    });

    for (final (name, code, phase) in [
      ('closes', 0, 'closed'),
      ('crashes', 139, 'crashed'),
    ]) {
      test('goes when the app $name', () async {
        await h.ensure();
        await h.service.start(runRecovery: false);
        await launch();
        expect(component('desktop').services, isNotEmpty);
        appSessions().single.exit.complete(code);
        await h.until(() => component('desktop').state == phase);
        expect(component('desktop').services, isEmpty);
        expect(h.windows.closed, ['rig-window']);
      });
    }

    test('that never opens leaves none behind', () async {
      await h.ensure();
      // What an earlier launch left, had its close never landed.
      final env = row();
      h.environments.rows[env.id] = env.copyWith(
        components: [
          for (final item in env.components)
            item.id == 'desktop'
                ? item.copyWith(
                    services: [
                      {'name': 'window', 'rig_id': 'rig-old'},
                    ],
                  )
                : item,
        ],
      );
      h.windows.openFailure = StateError('no window appeared');
      await launch();
      expect(appSessions(), hasLength(1));
      expect(component('desktop').services, isEmpty);
    });

    test('a relaunch clears the detail of the last failure', () async {
      h.appLaunchGrace = const Duration(seconds: 5);
      await h.ensure();
      await h.service.start(runRecovery: false);
      await launch();
      appSessions().single.exit.complete(1);
      await h.until(() => component('desktop').state == 'failed');
      await launch();
      await h.until(() => component('desktop').state == 'running');
      expect(component('desktop').detail, isNull);
      expect(component('desktop').sessionId, isNotNull);
    });
  });
}
