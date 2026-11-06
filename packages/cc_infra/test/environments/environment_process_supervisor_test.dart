import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_contract.dart';
import 'package:cc_infra/src/environments/environment_process_supervisor.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

void main() {
  late Directory dir;
  late String stateDir;
  late FakeTerminals terminals;
  late FakeGroups groups;
  late DateTime now;
  late bool hasGui;
  late Set<Uri> httpUp;
  late Map<Uri, int> httpStatus;
  late Set<int> tcpUp;
  late EnvironmentProcessSupervisor supervisor;

  EnvironmentProcessSupervisor build({
    Duration backoffStart = const Duration(milliseconds: 1),
    Duration backoffMax = const Duration(milliseconds: 4),
    Duration sigtermAfter = const Duration(milliseconds: 30),
    Duration sigkillAfter = const Duration(milliseconds: 60),
  }) => EnvironmentProcessSupervisor(
    terminals: terminals,
    groups: groups,
    binaryResolver: (name) async => '/usr/bin/$name',
    httpProbe: (uri) async =>
        httpStatus[uri] ?? (httpUp.contains(uri) ? 200 : null),
    tcpProbe: (host, port) async => tcpUp.contains(port),
    hasGuiSession: () => hasGui,
    now: () => now,
    backoffStart: backoffStart,
    backoffMax: backoffMax,
    sigtermAfter: sigtermAfter,
    sigkillAfter: sigkillAfter,
    probeInterval: const Duration(milliseconds: 1),
    exitPollInterval: const Duration(milliseconds: 1),
    reapGrace: const Duration(milliseconds: 1),
    logRingBytes: 4096,
  );

  setUp(() {
    dir = tempDir(addTearDown);
    stateDir = '${dir.path}/state';
    terminals = FakeTerminals();
    groups = FakeGroups();
    now = DateTime(2026);
    hasGui = true;
    httpUp = {};
    httpStatus = {};
    tcpUp = {};
    supervisor = build();
    addTearDown(() => supervisor.dispose());
  });

  EnvironmentProcessSpec spec({
    String environmentId = 'env-1',
    String componentId = 'web',
    EnvironmentSupervisedKind kind = EnvironmentSupervisedKind.process,
    List<String> argv = const ['pnpm', 'dev'],
    EnvironmentReadyProbe? ready,
    EnvironmentRestartPolicy restart = EnvironmentRestartPolicy.onFailure,
    bool isolateHome = false,
    Map<String, String> environment = const {'CC_ENV_NAME': 'shop'},
    String? cwd,
  }) => EnvironmentProcessSpec(
    workspaceId: 'ws-1',
    spaceId: 'space-1',
    environmentId: environmentId,
    componentId: componentId,
    kind: kind,
    argv: argv,
    workingDirectory: cwd ?? dir.path,
    stateDir: stateDir,
    environment: environment,
    label: 'Dev server',
    ready: ready,
    restart: restart,
    isolateHome: isolateHome,
  );

  String? state([String component = 'web', String env = 'env-1']) =>
      supervisor.stateOf(env, component)?.state;

  Future<void> until(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition not met');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  group('spawn', () {
    test('runs the command under its owner tag, not a shell', () async {
      await supervisor.start(spec());
      final session = terminals.last;
      expect(session.owner, 'environment:env-1/web');
      expect(session.executable, '/usr/bin/pnpm');
      expect(session.arguments, ['dev']);
      expect(session.cwd, dir.path);
      expect(session.environment['CC_ENV_NAME'], 'shop');
    });

    test('a shell command runs as bash -lc', () async {
      await supervisor.start(spec(argv: const ['bash', '-lc', 'x', 'bash']));
      expect(terminals.last.executable, '/usr/bin/bash');
      expect(terminals.last.arguments, ['-lc', 'x', 'bash']);
    });

    test('a second start of a running component does nothing', () async {
      await supervisor.start(spec());
      await supervisor.start(spec());
      expect(terminals.sessions, hasLength(1));
    });

    test('an unknown command is refused before any PTY exists', () async {
      supervisor = EnvironmentProcessSupervisor(
        terminals: terminals,
        groups: groups,
        binaryResolver: (_) async => null,
      );
      await expectLater(
        supervisor.start(spec()),
        throwsA(
          isA<EnvironmentDriverException>().having(
            (e) => e.error.code,
            'code',
            'command-not-found',
          ),
        ),
      );
      expect(terminals.sessions, isEmpty);
    });

    test('a missing directory is refused before any PTY exists', () async {
      await expectLater(
        supervisor.start(spec(cwd: '${dir.path}/gone')),
        throwsA(
          isA<EnvironmentDriverException>().having(
            (e) => e.error.code,
            'code',
            'cwd-missing',
          ),
        ),
      );
      expect(terminals.sessions, isEmpty);
    });

    test('a relative binary resolves against the worktree', () async {
      File('${dir.path}/editor').writeAsStringSync('');
      Directory('${dir.path}/target').createSync();
      File('${dir.path}/target/editor').writeAsStringSync('');
      await supervisor.start(spec(argv: const ['target/editor']));
      expect(terminals.last.executable, '${dir.path}/target/editor');
    });

    test('state carries the session and the label', () async {
      await supervisor.start(spec());
      final component = supervisor.stateOf('env-1', 'web')!;
      expect(component.sessionId, 'session-1');
      expect(component.label, 'Dev server');
      expect(component.kind, 'process');
    });
  });

  group('readiness', () {
    final url = Uri.parse('http://127.0.0.1:42000/');

    test('no probe is ready once started', () async {
      await supervisor.start(spec());
      await supervisor.waitReady('env-1', 'web');
      expect(state(), 'ready');
    });

    test('http waits for an answer below expectBelow', () async {
      await supervisor.start(
        spec(
          ready: EnvironmentReadyProbe(http: url.toString(), expectBelow: 400),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(state(), 'starting');
      httpStatus[url] = 503;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(state(), 'starting');
      httpStatus[url] = 302;
      await supervisor.waitReady('env-1', 'web');
      expect(state(), 'ready');
    });

    test('tcp waits for a connection', () async {
      await supervisor.start(
        spec(ready: const EnvironmentReadyProbe(tcp: '127.0.0.1:42001')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(state(), 'starting');
      tcpUp.add(42001);
      await supervisor.waitReady('env-1', 'web');
    });

    test('logMatch waits for a line, through terminal codes', () async {
      await supervisor.start(
        spec(ready: const EnvironmentReadyProbe(logMatch: r'listening on \d+')),
      );
      terminals.last.print('booting\r\n');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(state(), 'starting');
      terminals.last.print('\x1B[32mlistening on 42000\x1B[0m\r\n');
      await supervisor.waitReady('env-1', 'web');
    });

    test('a timeout fails it with the last lines', () async {
      await supervisor.start(
        spec(
          ready: EnvironmentReadyProbe(http: url.toString(), timeoutSeconds: 1),
        ),
      );
      terminals.last.print('port already in use\r\n');
      await expectLater(
        supervisor.waitReady('env-1', 'web'),
        throwsA(
          isA<EnvironmentDriverException>().having(
            (e) => e.error.message,
            'message',
            allOf(contains('Not ready'), contains('port already in use')),
          ),
        ),
      );
      expect(state(), 'failed');
    });

    test('rides through a crash on the way up', () async {
      await supervisor.start(
        spec(ready: EnvironmentReadyProbe(http: url.toString())),
      );
      final waiting = supervisor.waitReady('env-1', 'web');
      terminals.last.exit.complete(1);
      await until(() => terminals.sessions.length == 2);
      httpUp.add(url);
      await waiting;
      expect(state(), 'ready');
    });

    test('same component in two environments stay apart', () async {
      await supervisor.start(
        spec(ready: EnvironmentReadyProbe(http: url.toString())),
      );
      final other = Uri.parse('http://127.0.0.1:42032/');
      httpUp.add(other);
      await supervisor.start(
        spec(
          environmentId: 'env-2',
          ready: EnvironmentReadyProbe(http: other.toString()),
        ),
      );
      await supervisor.waitReady('env-2', 'web');
      expect(state('web', 'env-1'), 'starting');
      expect(state('web', 'env-2'), 'ready');
    });

    test('states say which environment they are about', () async {
      final changes = <String>[];
      supervisor.states.listen(
        (change) =>
            changes.add('${change.environmentId}:${change.state.state}'),
      );
      await supervisor.start(spec());
      await until(() => changes.contains('env-1:ready'));
      expect(changes, ['env-1:starting', 'env-1:ready']);
    });
  });

  group('restart policy', () {
    Future<void> crash(int count, {int code = 1}) async {
      for (var i = 0; i < count; i++) {
        final session = terminals.last;
        final before = terminals.sessions.length;
        session.exit.complete(code);
        await until(
          () => terminals.sessions.length > before || state() == 'failed',
        );
      }
    }

    test('on-failure backs off from 2 s to 60 s', () {
      final defaults = EnvironmentProcessSupervisor(terminals: terminals);
      addTearDown(defaults.dispose);
      expect(
        [for (var n = 0; n < 7; n++) defaults.backoffFor(n).inSeconds],
        [2, 4, 8, 16, 32, 60, 60],
      );
      expect(defaults.backoffFor(1000).inSeconds, 60);
    });

    test('defaults are five failures in ten minutes', () {
      final defaults = EnvironmentProcessSupervisor(terminals: terminals);
      addTearDown(defaults.dispose);
      expect(defaults.failureLimit, 5);
      expect(defaults.failureWindow, const Duration(minutes: 10));
      expect(defaults.sigtermAfter, const Duration(seconds: 10));
      expect(defaults.sigkillAfter, const Duration(seconds: 20));
      expect(defaults.logRingBytes, 2 * 1024 * 1024);
    });

    test('restarts, counting them', () async {
      await supervisor.start(spec());
      await crash(2);
      await until(() => state() == 'ready');
      expect(terminals.sessions, hasLength(3));
      expect(supervisor.stateOf('env-1', 'web')!.restarts, 2);
      expect(supervisor.stateOf('env-1', 'web')!.lastExitCode, 1);
    });

    test('a clean exit of a process counts as a failure', () async {
      await supervisor.start(spec());
      await crash(1, code: 0);
      expect(terminals.sessions, hasLength(2));
    });

    test('gives up on the fifth failure in the window', () async {
      await supervisor.start(spec());
      terminals.last.print('out of memory\r\n');
      await crash(5);
      await until(() => state() == 'failed');
      expect(terminals.sessions, hasLength(5));
      final component = supervisor.stateOf('env-1', 'web')!;
      expect(component.detail, contains('Gave up after 5 failures'));
      expect(component.detail, contains('out of memory'));
    });

    test('failures outside the window are forgotten', () async {
      await supervisor.start(spec());
      for (var i = 0; i < 8; i++) {
        now = now.add(const Duration(minutes: 4));
        await crash(1);
      }
      expect(state(), isNot('failed'));
      expect(terminals.sessions, hasLength(9));
    });

    test('always never gives up', () async {
      await supervisor.start(spec(restart: EnvironmentRestartPolicy.always));
      await crash(7);
      expect(terminals.sessions, hasLength(8));
    });

    test('never stays down', () async {
      await supervisor.start(spec(restart: EnvironmentRestartPolicy.never));
      terminals.last.exit.complete(0);
      await until(() => state() == 'failed');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(terminals.sessions, hasLength(1));
    });

    test('leftovers of the group are told to go before a restart', () async {
      await supervisor.start(spec());
      final pid = terminals.last.pid;
      await crash(1);
      expect(groups.signals, contains((pid, ProcessSignal.sigterm)));
    });

    test('exits are published', () async {
      final exits = <EnvironmentProcessExit>[];
      supervisor.exits.listen(exits.add);
      await supervisor.start(spec());
      await crash(1, code: 3);
      await until(() => exits.isNotEmpty);
      expect(exits.single.exitCode, 3);
      expect(exits.single.state, 'starting');
      expect(exits.single.environmentId, 'env-1');
    });

    test('a manual restart clears the failure history', () async {
      await supervisor.start(spec());
      await crash(4);
      await until(() => state() == 'ready');
      groups.onSignal = (group, signal) {
        if (!terminals.last.exit.isCompleted) {
          terminals.last.exit.complete(0);
        }
      };
      await supervisor.restart('env-1', 'web');
      groups.onSignal = null;
      await crash(4);
      await until(() => state() == 'ready');
      expect(state(), 'ready');
    });
  });

  group('stop', () {
    test('SIGINT to the group is enough for a well-behaved process', () async {
      await supervisor.start(spec());
      final session = terminals.last;
      groups.onSignal = (group, signal) => session.exit.complete(130);
      await supervisor.stop('env-1', 'web');
      expect(groups.signals, [(session.pid, ProcessSignal.sigint)]);
      expect(state(), 'stopped');
    });

    test('then SIGTERM, then SIGKILL, on schedule', () async {
      await supervisor.start(spec());
      final session = terminals.last;
      final watch = Stopwatch()..start();
      final at = <ProcessSignal, Duration>{};
      groups.onSignal = (group, signal) {
        at[signal] = watch.elapsed;
        if (signal == ProcessSignal.sigkill) {
          session.exit.complete(-9);
        }
      };
      await supervisor.stop('env-1', 'web');
      expect(groups.signals.map((signal) => signal.$2), [
        ProcessSignal.sigint,
        ProcessSignal.sigterm,
        ProcessSignal.sigkill,
      ]);
      expect(
        at[ProcessSignal.sigterm],
        greaterThanOrEqualTo(const Duration(milliseconds: 30)),
      );
      expect(
        at[ProcessSignal.sigkill],
        greaterThanOrEqualTo(const Duration(milliseconds: 60)),
      );
      expect(session.killed, isTrue);
    });

    test('waits for the whole group, not only the leader', () async {
      await supervisor.start(spec());
      final session = terminals.last;
      groups.groups[session.pid] = [session.pid + 1];
      groups.onSignal = (group, signal) {
        if (signal == ProcessSignal.sigint) {
          session.exit.complete(0);
        }
        if (signal == ProcessSignal.sigterm) {
          groups.groups.remove(group);
        }
      };
      await supervisor.stop('env-1', 'web');
      expect(groups.signals.map((signal) => signal.$2), [
        ProcessSignal.sigint,
        ProcessSignal.sigterm,
      ]);
    });

    test('a stopped process stays stopped', () async {
      await supervisor.start(spec());
      final session = terminals.last;
      groups.onSignal = (group, signal) => session.exit.complete(0);
      await supervisor.stop('env-1', 'web');
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(terminals.sessions, hasLength(1));
      expect(state(), 'stopped');
    });

    test('the respawn gate is asked before every restart', () async {
      final asked = <String>[];
      supervisor.respawnGate = (spec) async => asked.add(spec.componentId);
      await supervisor.start(spec());
      expect(asked, isEmpty);
      for (final count in [2, 3]) {
        terminals.last.exit.complete(1);
        await until(() => terminals.sessions.length == count);
      }
      expect(asked, ['web', 'web']);
    });

    test('a gate refusal keeps the process down', () async {
      supervisor.respawnGate = (spec) async => throw StateError('not admitted');
      await supervisor.start(spec());
      terminals.last.exit.complete(1);
      await until(() => state() == 'failed');
      expect(terminals.sessions, hasLength(1));
      expect(
        supervisor.stateOf('env-1', 'web')!.detail,
        contains('not admitted'),
      );
    });

    test('a stop while the gate decides leaves it stopped', () async {
      final decided = Completer<void>();
      var asked = false;
      supervisor.respawnGate = (spec) {
        asked = true;
        return decided.future;
      };
      await supervisor.start(spec());
      terminals.last.exit.complete(1);
      await until(() => asked);
      await supervisor.stop('env-1', 'web');
      decided.completeError(StateError('not admitted'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(terminals.sessions, hasLength(1));
      expect(state(), 'stopped');
    });

    test('a start while the gate decides is not spawned twice', () async {
      final decided = Completer<void>();
      var asked = false;
      supervisor.respawnGate = (spec) {
        asked = true;
        return decided.future;
      };
      await supervisor.start(spec());
      terminals.last.exit.complete(1);
      await until(() => asked);
      await supervisor.start(spec());
      decided.complete();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(terminals.sessions, hasLength(2));
    });

    test('a stop during backoff cancels the restart', () async {
      supervisor = build(
        backoffStart: const Duration(milliseconds: 20),
        backoffMax: const Duration(milliseconds: 20),
      );
      await supervisor.start(spec());
      terminals.last.exit.complete(1);
      await until(() => supervisor.stateOf('env-1', 'web')!.restarts == 1);
      await supervisor.stop('env-1', 'web');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(terminals.sessions, hasLength(1));
      expect(state(), 'stopped');
    });

    test('stopEnvironment goes in reverse', () async {
      await supervisor.start(spec(componentId: 'first'));
      await supervisor.start(spec(componentId: 'second'));
      groups.onSignal = (group, signal) {
        for (final session in terminals.sessions) {
          if (session.pid == group && !session.exit.isCompleted) {
            session.exit.complete(0);
          }
        }
      };
      await supervisor.stopEnvironment('env-1');
      expect(groups.signals.map((signal) => signal.$1), [
        terminals.sessions[1].pid,
        terminals.sessions[0].pid,
      ]);
    });

    test('stopping what was never started is fine', () async {
      await supervisor.stop('env-1', 'nope');
    });
  });

  group('pid files', () {
    String pidFile([String component = 'web']) => '$stateDir/pids/$component';

    test('written on spawn, removed on stop', () async {
      groups.startTimes[7000] = 'Fri Nov  6 10:00:00 2026';
      await supervisor.start(spec());
      final session = terminals.last;
      final json = jsonDecode(File(pidFile()).readAsStringSync()) as Map;
      expect(json['group'], session.pid);
      expect(json['startTime'], 'Fri Nov  6 10:00:00 2026');

      groups.onSignal = (group, signal) => session.exit.complete(0);
      await supervisor.stop('env-1', 'web');
      expect(File(pidFile()).existsSync(), isFalse);
    });

    void leaveBehind(int group, {String? startTime, String name = 'web'}) {
      File(pidFile(name))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({'group': group, 'startTime': startTime}),
        );
    }

    test('a survivor with the recorded start time is killed', () async {
      leaveBehind(4242, startTime: 'then');
      groups
        ..startTimes[4242] = 'then'
        ..groups[4242] = [4242];
      final reaped = await supervisor.reapSurvivors(stateDir);
      expect(reaped, ['web']);
      expect(groups.signals, [
        (4242, ProcessSignal.sigterm),
        (4242, ProcessSignal.sigkill),
      ]);
      expect(File(pidFile()).existsSync(), isFalse);
    });

    test('SIGTERM is enough when it works', () async {
      leaveBehind(4242, startTime: 'then');
      groups
        ..startTimes[4242] = 'then'
        ..groups[4242] = [4242]
        ..onSignal = (group, signal) => groups.groups.remove(group);
      await supervisor.reapSurvivors(stateDir);
      expect(groups.signals, [(4242, ProcessSignal.sigterm)]);
    });

    test('a reused pid is left alone', () async {
      leaveBehind(4242, startTime: 'then');
      groups
        ..startTimes[4242] = 'after the reboot'
        ..groups[4242] = [4242];
      expect(await supervisor.reapSurvivors(stateDir), isEmpty);
      expect(groups.signals, isEmpty);
      expect(File(pidFile()).existsSync(), isFalse);
    });

    test('a pid with no recorded start time is not trusted', () async {
      leaveBehind(4242);
      groups
        ..startTimes[4242] = 'whatever'
        ..groups[4242] = [4242];
      expect(await supervisor.reapSurvivors(stateDir), isEmpty);
      expect(groups.signals, isEmpty);
    });

    test('a group whose leader died still goes', () async {
      leaveBehind(4242, startTime: 'then');
      groups.groups[4242] = [4243];
      expect(await supervisor.reapSurvivors(stateDir), ['web']);
      expect(groups.signals.first, (4242, ProcessSignal.sigterm));
    });

    test('a group with nobody left is just cleaned up', () async {
      leaveBehind(4242, startTime: 'then');
      expect(await supervisor.reapSurvivors(stateDir), isEmpty);
      expect(File(pidFile()).existsSync(), isFalse);
    });

    test('a junk file is removed, not fatal', () async {
      File(pidFile())
        ..createSync(recursive: true)
        ..writeAsStringSync('not json');
      expect(await supervisor.reapSurvivors(stateDir), isEmpty);
      expect(File(pidFile()).existsSync(), isFalse);
    });

    test('no directory, nothing to do', () async {
      expect(await supervisor.reapSurvivors(stateDir), isEmpty);
    });

    test('dispose leaves processes and pid files for the next boot', () async {
      final other = build();
      await other.start(spec());
      await other.dispose();
      expect(File(pidFile()).existsSync(), isTrue);
      expect(terminals.last.killed, isFalse);
      expect(groups.signals, isEmpty);
    });
  });

  group('app', () {
    EnvironmentProcessSpec app({bool isolateHome = false}) => spec(
      componentId: 'desktop',
      kind: EnvironmentSupervisedKind.app,
      restart: EnvironmentRestartPolicy.never,
      isolateHome: isolateHome,
    );

    test('runs, and exit 0 is closed', () async {
      await supervisor.start(app());
      expect(state('desktop'), 'running');
      terminals.last.exit.complete(0);
      await until(() => state('desktop') == 'closed');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(terminals.sessions, hasLength(1));
      expect(groups.signals, isEmpty);
    });

    test('a crash shows its last lines and does not restart', () async {
      await supervisor.start(app());
      terminals.last.print('segfault at 0x0\r\n');
      terminals.last.exit.complete(-11);
      await until(() => state('desktop') == 'crashed');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(terminals.sessions, hasLength(1));
      final component = supervisor.stateOf('env-1', 'desktop')!;
      expect(component.detail, contains('segfault at 0x0'));
      expect(component.detail, contains('-11'));
    });

    test('a stopped app is closed', () async {
      await supervisor.start(app());
      final session = terminals.last;
      groups.onSignal = (group, signal) => session.exit.complete(0);
      await supervisor.stop('env-1', 'desktop');
      expect(state('desktop'), 'closed');
    });

    test('Launch after closing works', () async {
      await supervisor.start(app());
      terminals.last.exit.complete(0);
      await until(() => state('desktop') == 'closed');
      await supervisor.start(app());
      expect(terminals.sessions, hasLength(2));
      expect(state('desktop'), 'running');
    });

    test('refused on a headless server', () async {
      hasGui = false;
      await expectLater(
        supervisor.start(app()),
        throwsA(
          isA<EnvironmentDriverException>().having(
            (e) => e.error.code,
            'code',
            'no-gui-session',
          ),
        ),
      );
      expect(terminals.sessions, isEmpty);
    });

    test('boot restarts processes and never apps', () async {
      await supervisor.recover(stateDir: stateDir, specs: [spec(), app()]);
      expect(terminals.sessions.map((s) => s.owner), ['environment:env-1/web']);
    });

    test('isolate: home covers that process alone', () async {
      await supervisor.start(app(isolateHome: true));
      final environment = terminals.last.environment;
      final home = '$stateDir/home';
      expect(environment['HOME'], home);
      expect(environment['CFFIXED_USER_HOME'], home);
      expect(environment['XDG_CONFIG_HOME'], '$home/.config');
      expect(environment['XDG_DATA_HOME'], '$home/.local/share');
      expect(environment['XDG_STATE_HOME'], '$home/.local/state');
      expect(environment['XDG_CACHE_HOME'], '$home/.cache');
      expect(environment['XDG_RUNTIME_DIR'], '$home/.run');
      expect(Directory('$home/.config').existsSync(), isTrue);

      await supervisor.start(spec());
      expect(terminals.last.environment['HOME'], isNot(home));
      expect(
        terminals.last.environment.keys,
        isNot(contains('CFFIXED_USER_HOME')),
      );
    });
  });

  group('process ids', () {
    test('pid and group while running, null after', () async {
      expect(supervisor.processOf('env-1', 'web'), isNull);
      await supervisor.start(spec());
      final ids = supervisor.processOf('env-1', 'web')!;
      expect(ids.pid, terminals.last.pid);
      expect(ids.processGroup, terminals.last.pid);

      terminals.last.exit.complete(0);
      await until(() => supervisor.processOf('env-1', 'web') == null);
    });

    test('the tree is the whole group', () async {
      await supervisor.start(spec());
      final pid = terminals.last.pid;
      groups.groups[pid] = [pid, pid + 1, pid + 2];
      expect(await supervisor.processTreeOf('env-1', 'web'), [
        pid,
        pid + 1,
        pid + 2,
      ]);
    });

    test('no tree when nothing runs', () async {
      expect(await supervisor.processTreeOf('env-1', 'web'), isEmpty);
    });
  });

  group('logs', () {
    test('tail and persistence', () async {
      await supervisor.start(spec());
      terminals.last.print('one\r\ntwo\r\n');
      expect(
        await supervisor.logs(
          environmentId: 'env-1',
          componentId: 'web',
          stateDir: stateDir,
          tail: 1,
        ),
        ['two'],
      );
      terminals.last.exit.complete(1);
      await until(
        () =>
            File('$stateDir/logs/web.log').existsSync() &&
            File('$stateDir/logs/web.log').readAsStringSync().contains('two'),
      );
    });

    test('survive across restarts of the process', () async {
      await supervisor.start(spec());
      terminals.last.print('first run\r\n');
      terminals.last.exit.complete(1);
      await until(() => terminals.sessions.length == 2);
      terminals.last.print('second run\r\n');
      expect(
        await supervisor.logs(
          environmentId: 'env-1',
          componentId: 'web',
          stateDir: stateDir,
        ),
        ['first run', 'second run'],
      );
    });

    test('a last line with no newline is kept on exit', () async {
      await supervisor.start(spec(restart: EnvironmentRestartPolicy.never));
      terminals.last.print('fatal: no newline');
      terminals.last.exit.complete(1);
      await until(() => state() == 'failed');
      expect(
        supervisor.stateOf('env-1', 'web')!.detail,
        contains('fatal: no newline'),
      );
    });

    test('readable from disk when nothing is supervised', () async {
      Directory('$stateDir/logs').createSync(recursive: true);
      File('$stateDir/logs/web.log').writeAsStringSync('old\n');
      expect(
        await supervisor.logs(
          environmentId: 'env-1',
          componentId: 'web',
          stateDir: stateDir,
        ),
        ['old'],
      );
    });

    test('follow gives the tail, then what comes next', () async {
      await supervisor.start(spec());
      terminals.last.print('before\r\n');
      final lines = <String>[];
      final subscription = supervisor
          .followLogs('env-1', 'web', tail: 5)
          .listen(lines.add);
      await until(() => lines.contains('before'));
      terminals.last.print('after\r\n');
      await until(() => lines.contains('after'));
      await subscription.cancel();
    });
  });

  test('forget drops a component\'s entry', () async {
    await supervisor.start(spec());
    final session = terminals.last;
    groups.onSignal = (group, signal) => session.exit.complete(0);
    await supervisor.stopEnvironment('env-1');
    await supervisor.forget('env-1');
    expect(supervisor.stateOf('env-1', 'web'), isNull);
  });

  group('specs from components', () {
    EnvironmentContract contract() => EnvironmentContract(
      EnvironmentContractInput(
        name: 'fix-login',
        id: 'env-1',
        stateDir: stateDir,
        home: dir.path,
        branch: 'fix-login',
        spaceId: 'space-1',
        spaceName: 'Fix login',
        spaceKind: 'space',
        repos: [
          EnvironmentContractRepo(
            role: 'app',
            repoId: 'r',
            name: 'Shop',
            slug: 'shop',
            path: dir.path,
            sourcePath: '/src/shop',
          ),
        ],
        ports: const {'web': 42000},
      ),
    );

    test('a process expands argv, probes and PORT', () {
      final subject = EnvironmentProcessSpec.forProcess(
        component: ProcessEnvironmentComponent(
          id: 'web',
          label: 'Dev server',
          ports: const ['web'],
          command: EnvironmentCommand.fromJson([
            'pnpm',
            'dev',
            '--port',
            '{port.web}',
          ], path: 'command'),
          ready: const EnvironmentReadyProbe(
            http: 'http://127.0.0.1:{port.web}/',
          ),
          restart: EnvironmentRestartPolicy.always,
        ),
        contract: contract(),
        workspaceId: 'ws-1',
      );
      expect(subject.argv, ['pnpm', 'dev', '--port', '42000']);
      expect(subject.ready?.http, 'http://127.0.0.1:42000/');
      expect(subject.environment['PORT'], '42000');
      expect(subject.restart, EnvironmentRestartPolicy.always);
      expect(subject.owner, 'environment:env-1/web');
      expect(subject.workingDirectory, dir.path);
    });

    test('a shell process keeps its body as written', () {
      final subject = EnvironmentProcessSpec.forProcess(
        component: ProcessEnvironmentComponent(
          id: 'queue',
          command: ShellEnvironmentCommand('run {name}'),
        ),
        contract: contract(),
        workspaceId: 'ws-1',
      );
      expect(subject.argv, ['bash', '-lc', 'run {name}', 'bash']);
    });

    test('an app takes the app rules', () {
      final subject = EnvironmentProcessSpec.forApp(
        component: AppEnvironmentComponent(
          id: 'desktop',
          command: EnvironmentCommand.fromJson([
            'target/debug/editor',
          ], path: 'c'),
          isolateHome: true,
        ),
        contract: contract(),
        workspaceId: 'ws-1',
      );
      expect(subject.kind, EnvironmentSupervisedKind.app);
      expect(subject.restart, EnvironmentRestartPolicy.never);
      expect(subject.isolateHome, isTrue);
    });
  });
}
