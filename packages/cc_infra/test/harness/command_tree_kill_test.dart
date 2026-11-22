@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:cc_infra/src/process/process_tree.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:test/test.dart';

/// A command's whole process tree dies with it: a command that starts a
/// grandchild (`sleep 300 &`, then waits) leaves no grandchild behind after a
/// `bash_kill`, a timeout or the end of its run (cap, stop, error), in the
/// background or the foreground, on the host and in the macOS sandbox.

/// Prints the grandchild's pid first, then waits on it.
const _spawnsGrandchild = r"sh -c 'sleep 300 & echo $!; wait'";

/// Whether [pid] names a live, non-zombie process.
bool _alive(int pid) {
  if (Process.runSync('kill', ['-0', '$pid']).exitCode != 0) {
    return false;
  }
  // Some hosts print no state column; a process that answers is alive then.
  final stat = '${Process.runSync('ps', ['-o', 'stat=', '-p', '$pid']).stdout}'
      .trim();
  return !stat.startsWith('Z');
}

Future<void> _until(bool Function() test, {String reason = ''}) async {
  for (var i = 0; i < 500 && !test(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(test(), isTrue, reason: reason);
}

/// The grandchild pid the command printed.
int? _grandchildIn(String output) {
  final m = RegExp(r'^\s*(\d+)\s*$', multiLine: true).firstMatch(output);
  return m == null ? null : int.parse(m.group(1)!);
}

Object _posixOnly() =>
    Platform.isWindows ? 'process groups and ps are POSIX' : false;

class _Provider extends LlmProviderPort {
  _Provider(this.script, {this.gate});

  final List<List<LlmEvent>> script;

  /// Awaited before every call after the first.
  final Future<void> Function()? gate;
  int calls = 0;

  @override
  String get displayName => 'S';
  @override
  String get defaultModel => 'm';
  @override
  Future<List<ProviderModel>> listModels() async => const [];
  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final i = calls < script.length ? calls : script.length - 1;
    calls++;
    if (i > 0) {
      await gate?.call();
    }
    yield* Stream.fromIterable(script[i]);
  }
}

List<LlmEvent> _bash(String id, String command) => [
  LlmToolUseDelta(
    id: id,
    name: 'bash',
    argumentsJson: jsonEncode({
      'command': command,
      'description': 'start a server',
      'run_in_background': true,
    }),
  ),
  const LlmDone(stopReason: LlmStopReason.toolUse),
];

void main() {
  late Directory dir;
  late HarnessToolContext ctx;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tree_kill_');
    ctx = HarnessToolContext(
      workingDirectory: dir.path,
      workspaceId: 'ws',
      conversationId: 'conv',
      agentId: 'agent',
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  SandboxedHarnessCommandRunner hostRunner() => SandboxedHarnessCommandRunner(
    mode: Mode.chat,
    networkEnabled: false,
    hostProcesses: const HostToolProcessLauncher(),
  );

  group('background', () {
    late BackgroundCommandRegistry registry;

    setUp(() => registry = BackgroundCommandRegistry());
    tearDown(() => registry.killAll());

    Future<(BackgroundCommand, int)> start(
      HarnessCommandRunner runner, {
      int? timeout,
    }) async {
      final bash = BashTool(runner, backgroundCommands: registry);
      final result = await bash.execute({
        'command': _spawnsGrandchild,
        'description': 'grandchild',
        'run_in_background': true,
        'timeout_seconds': ?timeout,
      }, ctx);
      expect(result.isError, isFalse, reason: result.content);
      final command = registry.live.last;
      await _until(
        () => _grandchildIn(command.output) != null,
        reason: 'the command printed its grandchild',
      );
      final grandchild = _grandchildIn(command.output)!;
      expect(_alive(grandchild), isTrue);
      return (command, grandchild);
    }

    test('bash_kill ends the grandchild too', () async {
      final (_, grandchild) = await start(hostRunner());
      final killed = await BashKillTool(
        registry,
      ).execute({'handle': 'b1'}, ctx);
      expect(killed.content, contains('b1 was killed'));
      expect(_alive(grandchild), isFalse);
    });

    test('a timeout ends the grandchild too', () async {
      final (command, grandchild) = await start(hostRunner(), timeout: 1);
      await command.settled.timeout(const Duration(seconds: 15));
      expect(command.status, BackgroundCommandStatus.timedOut);
      expect(_alive(grandchild), isFalse);
    });

    test('in the macOS sandbox, bash_kill ends the grandchild too', () async {
      final manager = SandboxManager(hiddenPaths: const []);
      addTearDown(manager.reset);
      final runner = SandboxedHarnessCommandRunner(
        mode: Mode.chat,
        networkEnabled: false,
        sandboxManager: manager,
        sandboxSessionId: 'tree-kill-test',
      );
      final (_, grandchild) = await start(runner);
      await BashKillTool(registry).execute({'handle': 'b1'}, ctx);
      expect(_alive(grandchild), isFalse);
    }, skip: Platform.isMacOS ? false : 'Seatbelt is macOS only');
  }, skip: _posixOnly());

  group('the end of the run', () {
    /// Runs the loop with a real `bash` on the host. The model's second call
    /// waits until the background command printed its grandchild; [cancel],
    /// when given, is cancelled once it has. Returns the grandchild's pid
    /// after the run ended.
    Future<int> runUntilEnd({
      required List<List<LlmEvent>> script,
      AgentLoopConfig config = const AgentLoopConfig(),
      CancellationTokenSource? cancel,
    }) async {
      final registry = BackgroundCommandRegistry();
      final bash = BashTool(hostRunner(), backgroundCommands: registry);
      bool printed() =>
          registry.commands.isNotEmpty &&
          _grandchildIn(registry.commands.first.output) != null;
      final events = <AgentLoopEvent>[];
      // The model's next turn waits until the test saw the grandchild alive:
      // a turn that ends the run at once (the error) must not race the check.
      final checked = Completer<void>();
      final done = const AgentLoopRunner()
          .run(
            history: [],
            userMessage: 'start the server',
            tools: [bash],
            provider: _Provider(
              script,
              gate: () async {
                await _until(printed, reason: 'grandchild printed');
                await checked.future;
              },
            ),
            config: config,
            context: ctx,
            cancel: cancel?.token,
          )
          .forEach(events.add);
      await _until(printed, reason: 'the command printed its grandchild');
      final pid = _grandchildIn(registry.commands.first.output)!;
      expect(_alive(pid), isTrue);
      checked.complete();
      if (cancel != null) {
        await _until(() => events.any((e) => e is LoopPark && e.parked));
        cancel.cancel();
      }
      await done.timeout(const Duration(seconds: 20));
      expect(events.last, isA<LoopDone>());
      return pid;
    }

    test('at the turn cap', () async {
      final pid = await runUntilEnd(
        script: [
          _bash('c1', _spawnsGrandchild),
          // Keeps the loop busy until the cap: a second turn of tool calls.
          _bash('c2', 'sleep 1'),
        ],
        config: const AgentLoopConfig(maxTurns: 2),
      );
      expect(_alive(pid), isFalse);
    });

    test('when the run is stopped', () async {
      final pid = await runUntilEnd(
        script: [
          _bash('c1', _spawnsGrandchild),
          [
            const LlmTextDelta('waiting'),
            const LlmDone(stopReason: LlmStopReason.endTurn),
          ],
        ],
        cancel: CancellationTokenSource(),
      );
      expect(_alive(pid), isFalse);
    });

    test('when the run ends on an error', () async {
      final pid = await runUntilEnd(
        script: [
          _bash('c1', _spawnsGrandchild),
          [const LlmError('bad request', code: 'invalid_request_error')],
        ],
      );
      expect(_alive(pid), isFalse);
    });
  }, skip: _posixOnly());

  group('foreground', () {
    test('a timeout ends the grandchild too', () async {
      int? grandchild;
      final out = StringBuffer();
      final result = await hostRunner().run(
        _spawnsGrandchild,
        workdir: dir.path,
        timeoutSeconds: 1,
        observer: HarnessCommandObserver(
          onOutput: (chunk) {
            out.write(chunk);
            grandchild ??= _grandchildIn(out.toString());
          },
        ),
      );
      expect(result.timedOut, isTrue);
      expect(grandchild, isNotNull);
      expect(_alive(grandchild!), isFalse);
    });

    test('a stop ends the grandchild too', () async {
      int? grandchild;
      final out = StringBuffer();
      final source = CancellationTokenSource();
      final result = await hostRunner().run(
        _spawnsGrandchild,
        workdir: dir.path,
        timeoutSeconds: 60,
        cancel: source.token,
        observer: HarnessCommandObserver(
          onOutput: (chunk) {
            out.write(chunk);
            grandchild ??= _grandchildIn(out.toString());
            if (grandchild != null) {
              source.cancel();
            }
          },
        ),
      );
      expect(result.stderr, contains('cancelled'));
      expect(_alive(grandchild!), isFalse);
    });

    test('a normal exit passes the exit code and output through', () async {
      final result = await hostRunner().run(
        'echo out; echo err >&2; exit 7',
        workdir: dir.path,
      );
      expect(result.exitCode, 7);
      expect(result.stdout, contains('out'));
      expect(result.stderr, contains('err'));
    });
  }, skip: _posixOnly());

  group('processTreeTargets', () {
    ProcessTableRow row(int pid, int ppid, int pgid, {int sess = 0}) =>
        (pid: pid, ppid: ppid, pgid: pgid, sess: sess, zombie: false);

    test('descendants and the groups they lead, never the server or its '
        'group', () {
      final rows = {
        for (final r in [
          row(100, 1, 100), // the server
          row(200, 100, 100), // the watcher, in the server's group
          row(300, 200, 300), // the command, leading its own group
          row(301, 300, 300), // its child
          row(302, 1, 300), // re-parented, still in the command's group
          row(400, 100, 100), // another child of the server
          row(500, 1, 500), // unrelated
        ])
          r.pid: r,
      };
      // The watcher is walked through, not signalled: it sits in the
      // server's group.
      expect(processTreeTargets(rows, [200], serverPid: 100), {300, 301, 302});
    });

    test('a session one of them holds (Linux gives the session id)', () {
      final rows = {
        for (final r in [
          row(100, 1, 100, sess: 50), // the server
          row(200, 100, 100, sess: 50), // the watcher
          row(300, 200, 300, sess: 300), // the command, after setsid
          row(500, 1, 501, sess: 300), // left its group, kept the session
          row(600, 1, 600, sess: 50), // the server's session: never by it
        ])
          r.pid: r,
      };
      expect(processTreeTargets(rows, [200], serverPid: 100), {300, 500});
    });

    test('a marked process that left the tree, and what it started', () {
      final rows = {
        for (final r in [
          row(100, 1, 100),
          row(600, 1, 600), // a daemon: own session, parent 1
          row(601, 600, 600),
          row(700, 1, 100), // marked, but in the server's group
        ])
          r.pid: r,
      };
      expect(
        processTreeTargets(rows, const [], serverPid: 100, marked: {600, 700}),
        {600, 601},
      );
    });

    test('zombies are already gone', () {
      final rows = {
        100: row(100, 1, 100),
        200: (pid: 200, ppid: 100, pgid: 200, sess: 0, zombie: true),
      };
      expect(processTreeTargets(rows, [200], serverPid: 100), isEmpty);
    });

    test('parses ps output', () {
      final rows = parseProcessTable(
        '  1 0 1 1 Ss\n 42 1 42 42 Z+\n 43 42 42 0\n',
      );
      expect(rows[1]!.ppid, 0);
      expect(rows[42]!.zombie, isTrue);
      expect(rows[42]!.sess, 42);
      expect(rows[43]!.pgid, 42);
    });

    test('finds the marker only as a whole variable', () {
      const out =
          '  10 /bin/sleep 300 HOME=/x CC_COMMAND_TREE=abc PATH=/bin\n'
          '  11 /bin/sleep 300 CC_COMMAND_TREE=abcd\n'
          '  12 /bin/echo CC_COMMAND_TREE=abc\n'
          '  13 /bin/sleep 1 XCC_COMMAND_TREE=abc\n';
      expect(parseMarkedProcesses(out, 'abc'), {10, 12});
    });
  });

  group('killProcessTree never signals what may not be ours', () {
    ProcessTableRow row(int pid, int ppid, int pgid) =>
        (pid: pid, ppid: ppid, pgid: pgid, sess: 0, zombie: false);
    final signals = <(int, ProcessSignal)>[];
    bool record(int pid, ProcessSignal signal) {
      signals.add((pid, signal));
      return true;
    }

    setUp(signals.clear);

    Future<void> kill(
      int root,
      List<ProcessTableRow> rows, {
      bool Function()? exited,
      Set<int> marked = const {},
      String? marker,
    }) => killProcessTree(
      root,
      grace: const Duration(milliseconds: 200),
      exited: exited,
      marker: marker,
      table: () async => {for (final r in rows) r.pid: r},
      markedReader: (_) async => marked,
      signal: record,
      serverPid: 100,
      warn: (_) {},
    );

    test('a seed that is not the server\'s child is refused', () async {
      await kill(200, [
        row(100, 1, 100),
        row(200, 999, 200), // pid 200 now belongs to someone else
        row(201, 200, 200),
      ]);
      expect(signals, isEmpty);
    });

    test('a root whose exit was seen is never signalled', () async {
      await kill(200, [
        row(100, 1, 100),
        row(200, 100, 100),
        row(300, 200, 300),
      ], exited: () => true);
      expect(signals, isEmpty);
    });

    test('the server and its group are never signalled', () async {
      await kill(200, [
        row(100, 1, 100),
        row(200, 100, 100), // the watcher, the server's own child and group
        row(300, 200, 300), // the command
        row(400, 200, 100), // a helper of the watcher, in the server's group
      ]);
      final pids = signals.map((s) => s.$1).toSet();
      expect(pids, {300});
      expect(pids, isNot(contains(100)));
    });

    test('with no process table, only the root, and no KILL once its exit '
        'is seen', () async {
      var exited = false;
      await killProcessTree(
        200,
        grace: const Duration(milliseconds: 50),
        exited: () => exited,
        table: () async => const {},
        signal: (pid, signal) {
          record(pid, signal);
          exited = true; // it died of the TERM and was reaped
          return true;
        },
        serverPid: 100,
      );
      expect(signals, [(200, ProcessSignal.sigterm)]);
    });

    test('with no process table and the exit seen, nothing', () async {
      await killProcessTree(
        200,
        exited: () => true,
        table: () async => const {},
        signal: record,
        serverPid: 100,
      );
      expect(signals, isEmpty);
    });

    test('after the exit, a marked daemon is still found', () async {
      await kill(
        200,
        [row(100, 1, 100), row(600, 1, 600)],
        exited: () => true,
        marked: {600},
        marker: 'abc',
      );
      expect(signals.map((s) => s.$1).toSet(), {600});
    });
  });

  group('the runner calls no kill for a command whose exit it saw', () {
    late List<bool> calls;
    late SandboxedHarnessCommandRunner runner;

    setUp(() {
      calls = [];
      runner = SandboxedHarnessCommandRunner(
        mode: Mode.chat,
        networkEnabled: false,
        hostProcesses: const HostToolProcessLauncher(),
        killTree: (pid, {required exited, marker}) async {
          calls.add(exited());
        },
      );
    });

    test('a cancel after the exit sends nothing', () async {
      final source = CancellationTokenSource();
      final result = await runner.run(
        'echo hi',
        workdir: dir.path,
        cancel: source.token,
      );
      expect(result.exitCode, 0);
      source.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, isEmpty);
    });

    test('a script\'s nested bash calls end without any kill', () async {
      // A script's nested calls share a token that is cancelled when the
      // script's call settles, after every command already exited.
      final settled = CancellationTokenSource();
      for (final command in ['echo one', 'echo two', 'true']) {
        final result = await runner.run(
          command,
          workdir: dir.path,
          cancel: settled.token,
        );
        expect(result.exitCode, 0);
      }
      settled.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, isEmpty);
    });

    test('a background command\'s run end still sweeps, as exited', () async {
      final source = CancellationTokenSource();
      await runner.run(
        'true',
        workdir: dir.path,
        cancel: source.token,
        observer: const HarnessCommandObserver(sweepAfterExit: true),
      );
      source.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, [true]);
    });
  }, skip: _posixOnly());

  group('a daemon that leaves its tree', () {
    late BackgroundCommandRegistry registry;

    setUp(() => registry = BackgroundCommandRegistry());
    tearDown(() => registry.killAll());

    Future<(BackgroundCommand, int)> start(String command) async {
      final bash = BashTool(hostRunner(), backgroundCommands: registry);
      final result = await bash.execute({
        'command': command,
        'description': 'daemon',
        'run_in_background': true,
      }, ctx);
      expect(result.isError, isFalse, reason: result.content);
      final c = registry.commands.last;
      await _until(
        () => _grandchildIn(c.output) != null,
        reason: 'the daemon printed its pid',
      );
      final daemon = _grandchildIn(c.output)!;
      expect(_alive(daemon), isTrue);
      // It left the command's parent chain, group and session.
      expect(
        '${Process.runSync('ps', ['-o', 'ppid=', '-p', '$daemon']).stdout}'
            .trim(),
        '1',
      );
      return (c, daemon);
    }

    test('bash_kill ends it', () async {
      final (_, daemon) = await start('$_daemonizes; sleep 300');
      await BashKillTool(registry).execute({'handle': 'b1'}, ctx);
      await _until(() => !_alive(daemon), reason: 'the daemon died');
    });

    test('the run end ends it after its command already exited', () async {
      final (command, daemon) = await start(_daemonizes);
      await command.settled.timeout(const Duration(seconds: 10));
      expect(command.status, BackgroundCommandStatus.exited);
      expect(_alive(daemon), isTrue, reason: 'an exit touches nothing');
      await registry.killAll();
      await _until(() => !_alive(daemon), reason: 'the daemon died');
    });
  }, skip: _daemonSkip());
}

Object _daemonSkip() => Platform.isWindows
    ? 'process groups and ps are POSIX'
    : Process.runSync('python3', ['-c', 'pass']).exitCode == 0
    ? false
    : 'needs python3';

/// A double fork through `setsid`: prints the daemon's pid, then the daemon
/// closes its output and sleeps, re-parented to pid 1 in a session of its
/// own. Python, because it keeps its environment where `ps -E` reads it (a
/// program that rewrites its process title, such as perl, does not: see the
/// report's "Not verified").
const _daemonizes =
    'python3 -c "import os,sys,time;os.fork() and sys.exit(0);os.setsid();'
    'os.fork() and sys.exit(0);print(os.getpid(),flush=True);os.close(1);'
    'os.close(2);time.sleep(300)"';
