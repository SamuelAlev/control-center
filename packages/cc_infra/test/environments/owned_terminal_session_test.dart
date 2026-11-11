@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_infra/src/environments/environment_process_supervisor.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/terminal_session_service.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

class _NoFilesystem implements WorkspaceFilesystemPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('owned sessions never touch the filesystem port');
}

DynamicLibrary? _openPty() {
  final home = Platform.environment['HOME'] ?? '';
  for (final path in [
    ?Platform.environment[ptyLibraryEnvVar],
    '$home/Library/Application Support/com.alev.control-center/libccpty.dylib',
    '$home/.local/share/control_center/libccpty.so',
  ]) {
    if (File(path).existsSync()) {
      return DynamicLibrary.open(path);
    }
  }
  return null;
}

/// The owner concept on a real PTY: these are the promises a fake can't check.
void main() {
  Pty.libraryResolver = _openPty;
  tearDownAll(() => Pty.libraryResolver = defaultPtyLibraryResolver);
  final skip = Pty.isAvailable ? false : 'libccpty is not built here';

  late Directory dir;
  late TerminalSessionService terminals;

  setUp(() {
    dir = tempDir(addTearDown);
    terminals = TerminalSessionService(
      manager: SandboxManager.test(),
      filesystem: _NoFilesystem(),
    );
    addTearDown(terminals.disposeAll);
  });

  Future<OwnedTerminalSession> spawn(
    String script, {
    void Function(List<int>)? onOutput,
    Map<String, String> environment = const {},
    String owner = 'environment:env-1/web',
  }) => terminals.spawnOwned(
    workspaceId: 'ws-1',
    spaceId: 'space-1',
    owner: owner,
    executable: '/bin/sh',
    arguments: ['-c', script],
    cwd: dir.path,
    environment: environment,
    onOutput: onOutput,
  );

  group('a person at a prompt', () {
    test('what printed before the tab attached still arrives', () async {
      final session = await spawn('printf "Password: "; sleep 1');
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final first = await terminals
          .output(
            workspaceId: 'ws-1',
            userId: 'ada',
            sessionId: session.sessionId,
          )
          .first;

      expect(String.fromCharCodes(first), contains('Password:'));
    }, skip: skip);

    test('an owned session keeps what is typed out of the trail', () async {
      final session = await spawn('read answer; sleep 1');

      await terminals.write(
        workspaceId: 'ws-1',
        userId: 'ada',
        sessionId: session.sessionId,
        data: 'hunter2'.codeUnits,
      );
      final sent = await terminals.write(
        workspaceId: 'ws-1',
        userId: 'ada',
        sessionId: session.sessionId,
        data: '\r'.codeUnits,
      );

      expect(sent.sent, isTrue);
      expect(sent.command, isNull);
    }, skip: skip);
  });

  group('spawnOwned', () {
    test('runs the command with its environment and cwd', () async {
      final output = <int>[];
      final session = await spawn(
        r'echo "$CC_ENV_NAME in $(pwd)"; exit 3',
        environment: const {'CC_ENV_NAME': 'shop'},
        onOutput: output.addAll,
      );
      expect(await session.exitCode, 3);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(String.fromCharCodes(output), contains('shop in ${dir.path}'));
    }, skip: skip);

    test('closing the tab leaves it running', () async {
      final session = await spawn('sleep 30');
      await terminals.kill(
        workspaceId: 'ws-1',
        userId: 'ada',
        sessionId: session.sessionId,
      );
      expect(terminals.ownerOf(session.sessionId), 'environment:env-1/web');
      expect(Process.killPid(session.pid, ProcessSignal.sigcont), isTrue);
      await terminals.killOwned(
        workspaceId: 'ws-1',
        sessionId: session.sessionId,
        owner: 'environment:env-1/web',
      );
      expect(terminals.ownerOf(session.sessionId), isNull);
    }, skip: skip);

    test('a tab can read it and type into it', () async {
      final session = await spawn(r'read line; echo "got $line"; sleep 5');
      final bytes = <int>[];
      final subscription = terminals
          .output(
            workspaceId: 'ws-1',
            userId: 'ada',
            sessionId: session.sessionId,
          )
          .listen(bytes.addAll);
      addTearDown(subscription.cancel);
      await terminals.write(
        workspaceId: 'ws-1',
        userId: 'ada',
        sessionId: session.sessionId,
        data: 'hello\n'.codeUnits,
      );
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!String.fromCharCodes(bytes).contains('got hello') &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(String.fromCharCodes(bytes), contains('got hello'));
    }, skip: skip);

    test('another owner can\'t end it', () async {
      final session = await spawn('sleep 30');
      await expectLater(
        terminals.killOwned(
          workspaceId: 'ws-1',
          sessionId: session.sessionId,
          owner: 'environment:env-2/web',
        ),
        throwsA(isA<ValidationException>()),
      );
    }, skip: skip);

    test('another workspace can\'t reach it', () async {
      final session = await spawn('sleep 30');
      await expectLater(
        terminals.killOwned(
          workspaceId: 'ws-2',
          sessionId: session.sessionId,
          owner: 'environment:env-1/web',
        ),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      await expectLater(
        terminals.kill(
          workspaceId: 'ws-2',
          userId: 'ada',
          sessionId: session.sessionId,
        ),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    }, skip: skip);

    test('its exit releases it', () async {
      final session = await spawn('exit 0');
      await session.exitCode;
      expect(terminals.ownerOf(session.sessionId), isNull);
      expect(
        terminals.sessionsOwnedBy(
          workspaceId: 'ws-1',
          ownerPrefix: 'environment:',
        ),
        isEmpty,
      );
    }, skip: skip);

    test('listed by owner prefix, within a workspace', () async {
      final session = await spawn('sleep 30');
      expect(
        terminals.sessionsOwnedBy(
          workspaceId: 'ws-1',
          ownerPrefix: 'environment:env-1/',
        ),
        [session.sessionId],
      );
      expect(
        terminals.sessionsOwnedBy(
          workspaceId: 'ws-2',
          ownerPrefix: 'environment:env-1/',
        ),
        isEmpty,
      );
    }, skip: skip);

    test('refuses an empty owner', () async {
      await expectLater(
        spawn('exit 0', owner: ''),
        throwsA(isA<ValidationException>()),
      );
    }, skip: skip);
  });

  group('supervisor on a real PTY', () {
    EnvironmentProcessSpec spec(
      List<String> argv, {
      EnvironmentReadyProbe? ready,
      EnvironmentRestartPolicy restart = EnvironmentRestartPolicy.never,
    }) => EnvironmentProcessSpec(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      environmentId: 'env-1',
      componentId: 'web',
      kind: EnvironmentSupervisedKind.process,
      argv: argv,
      workingDirectory: dir.path,
      stateDir: '${dir.path}/state',
      ready: ready,
      restart: restart,
    );

    EnvironmentProcessSupervisor supervisor() {
      final subject = EnvironmentProcessSupervisor(
        terminals: terminals,
        sigtermAfter: const Duration(milliseconds: 300),
        sigkillAfter: const Duration(milliseconds: 600),
        probeInterval: const Duration(milliseconds: 20),
      );
      addTearDown(subject.dispose);
      return subject;
    }

    test('a log line makes it ready; SIGINT reaches the group', () async {
      final subject = supervisor();
      final marker = '${dir.path}/child-alive';
      // Ready only once the child has shown it runs, so the check after stop
      // is about the child dying rather than never having started.
      final script =
          '(while true; do touch "$marker"; sleep 0.05; done) & '
          'while [ ! -f "$marker" ]; do sleep 0.01; done; '
          'echo listening; wait';
      await subject.start(
        spec([
          '/bin/sh',
          '-c',
          script,
        ], ready: const EnvironmentReadyProbe(logMatch: 'listening')),
      );
      await subject.waitReady('env-1', 'web');
      final group = subject.processOf('env-1', 'web')!.processGroup;
      expect(await subject.processTreeOf('env-1', 'web'), contains(group));

      await subject.stop('env-1', 'web');
      expect(subject.stateOf('env-1', 'web')?.state, 'stopped');
      expect(await const HostProcessGroups().members(group), isEmpty);
      File(marker).deleteSync();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(File(marker).existsSync(), isFalse, reason: 'the child went too');
      expect(File('${dir.path}/state/pids/web').existsSync(), isFalse);
    }, skip: skip);

    test('a process ignoring SIGINT and SIGTERM still goes', () async {
      final subject = supervisor();
      await subject.start(
        spec([
          '/bin/sh',
          '-c',
          "trap '' INT TERM; echo up; while true; do sleep 0.05; done",
        ], ready: const EnvironmentReadyProbe(logMatch: 'up')),
      );
      await subject.waitReady('env-1', 'web');
      final group = subject.processOf('env-1', 'web')!.processGroup;
      await subject.stop('env-1', 'web');
      expect(await const HostProcessGroups().members(group), isEmpty);
    }, skip: skip);

    test('a crash keeps its last words', () async {
      final subject = supervisor();
      await subject.start(spec(['/bin/sh', '-c', 'echo boom; exit 7']));
      await expectLater(
        subject.waitReady('env-1', 'web').then((_) async {
          await subject.states.firstWhere(
            (change) => change.state.state == 'failed',
          );
        }),
        completes,
      );
      final component = subject.stateOf('env-1', 'web')!;
      expect(component.lastExitCode, 7);
      expect(component.detail, contains('boom'));
    }, skip: skip);

    test('boot finds a real survivor', () async {
      final subject = supervisor();
      await subject.start(spec(['/bin/sh', '-c', 'echo up; sleep 30']));
      final group = subject.processOf('env-1', 'web')!.processGroup;
      final other = EnvironmentProcessSupervisor(
        terminals: terminals,
        reapGrace: const Duration(milliseconds: 100),
      );
      addTearDown(other.dispose);
      expect(await other.reapSurvivors('${dir.path}/state'), ['web']);
      expect(await const HostProcessGroups().members(group), isEmpty);
    }, skip: skip);
  });

  group('a verb that asks on a real terminal', () {
    const owner = 'environment:env-1/terminal';

    EnvironmentProcessSupervisor supervisor() {
      final subject = EnvironmentProcessSupervisor(terminals: terminals);
      addTearDown(subject.dispose);
      return subject;
    }

    Future<OwnedTerminalSession> ask(
      EnvironmentProcessSupervisor subject,
      String script, {
      void Function(List<int>)? onOutput,
    }) => subject.startInteractive(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      owner: owner,
      argv: ['/bin/sh', '-c', script],
      environment: const {'CC_ENV_INTERACTIVE': '1'},
      workingDirectory: dir.path,
      onOutput: onOutput,
    );

    Future<void> shows(List<int> bytes, String text) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!String.fromCharCodes(bytes).contains(text) &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(String.fromCharCodes(bytes), contains(text));
    }

    test(
      'the answer typed there reaches it, and its exit comes back',
      () async {
        final seen = <int>[];
        // A tool asking the way sudo does: at its terminal, not on a pipe.
        final session = await ask(
          supervisor(),
          r'test -t 0 || exit 9; test "$CC_ENV_INTERACTIVE" = 1 || exit 8; '
          r'printf "Password: "; read answer; test "$answer" = sesame',
          onOutput: seen.addAll,
        );
        await shows(seen, 'Password: ');

        await terminals.write(
          workspaceId: 'ws-1',
          userId: 'ada',
          sessionId: session.sessionId,
          data: 'sesame\n'.codeUnits,
        );

        expect(await session.exitCode, 0);
        expect(terminals.ownerOf(session.sessionId), isNull);
      },
      skip: skip,
    );

    test('a wrong answer is its own exit code', () async {
      final seen = <int>[];
      final session = await ask(
        supervisor(),
        r'printf "Password: "; read answer; test "$answer" = sesame || exit 7',
        onOutput: seen.addAll,
      );
      await shows(seen, 'Password: ');

      await terminals.write(
        workspaceId: 'ws-1',
        userId: 'ada',
        sessionId: session.sessionId,
        data: 'guess\n'.codeUnits,
      );

      expect(await session.exitCode, 7);
    }, skip: skip);

    test('ending it stops a tool still waiting for an answer', () async {
      final seen = <int>[];
      final subject = supervisor();
      final session = await ask(
        subject,
        'printf "Password: "; read answer',
        onOutput: seen.addAll,
      );
      await shows(seen, 'Password: ');

      await subject.stopInteractive(
        workspaceId: 'ws-1',
        sessionId: session.sessionId,
        owner: owner,
      );

      expect(
        await session.exitCode.timeout(const Duration(seconds: 5)),
        isNot(0),
      );
      expect(terminals.ownerOf(session.sessionId), isNull);
    }, skip: skip);
  });
}
