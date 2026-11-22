import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:test/test.dart';

/// Runs commands as real processes (`/bin/sh -c`), streaming to the
/// observer and killing on cancel, the way the server's sandboxed runner
/// does, and remembers every process it started.
class _ProcessRunner implements HarnessCommandRunner {
  final List<Process> processes = [];
  String? lastParentToolCallId;

  @override
  Future<HarnessCommandResult> run(
    String command, {
    String? workdir,
    int timeoutSeconds = 120,
    Map<String, String>? env,
    CancellationToken? cancel,
    PersonWaitListener? personWait,
    String? parentToolCallId,
    HarnessCommandObserver? observer,
  }) async {
    lastParentToolCallId = parentToolCallId;
    final process = await Process.start('/bin/sh', [
      '-c',
      command,
    ], workingDirectory: workdir);
    processes.add(process);
    observer?.onStarted?.call();
    final out = StringBuffer();
    void hear(String chunk) {
      out.write(chunk);
      observer?.onOutput?.call(chunk);
    }

    final subs = [
      process.stdout.transform(utf8.decoder).listen(hear),
      process.stderr.transform(utf8.decoder).listen(hear),
    ];
    unawaited(
      cancel?.whenCancelled.then((_) => process.kill(ProcessSignal.sigkill)),
    );
    var timedOut = false;
    final code = await process.exitCode.timeout(
      Duration(seconds: timeoutSeconds),
      onTimeout: () {
        timedOut = true;
        process.kill(ProcessSignal.sigkill);
        return 124;
      },
    );
    for (final sub in subs) {
      await sub.asFuture<void>().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
    }
    return HarnessCommandResult(
      exitCode: code,
      stdout: out.toString(),
      stderr: '',
      timedOut: timedOut,
    );
  }
}

/// Whether [pid] names a live process.
bool _alive(int pid) => Process.runSync('kill', ['-0', '$pid']).exitCode == 0;

Future<void> _until(bool Function() test) async {
  for (var i = 0; i < 400 && !test(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(test(), isTrue, reason: 'condition never held');
}

void main() {
  late Directory dir;
  late _ProcessRunner runner;
  late BackgroundCommandRegistry registry;
  late InMemoryToolOutputStore store;
  late BashTool bash;
  late BashOutputTool output;
  late BashKillTool kill;
  late ToolOutputReadTool read;
  late List<String> notices;
  late HarnessToolContext ctx;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('background_bash_');
    runner = _ProcessRunner();
    store = InMemoryToolOutputStore();
    registry = BackgroundCommandRegistry(store: store)
      ..bindCallForms(
        toolFormsOver(
          callable: const [],
          scriptOnly: const ['bash_output', 'bash_kill'],
        ),
      );
    notices = [];
    registry.onNotice = (notice, _) => notices.add(notice);
    bash = BashTool(runner, backgroundCommands: registry);
    output = BashOutputTool(registry);
    kill = BashKillTool(registry);
    read = ToolOutputReadTool(store, backgroundCommands: registry);
    ctx = HarnessToolContext(
      workingDirectory: dir.path,
      workspaceId: 'ws',
      conversationId: 'conv',
      agentId: 'agent',
    );
  });

  tearDown(() async {
    await registry.killAll();
    dir.deleteSync(recursive: true);
  });

  Future<HarnessToolResult> start(String command, {int? timeout}) =>
      bash.execute({
        'command': command,
        'description': 'test command',
        'run_in_background': true,
        'timeout_seconds': ?timeout,
      }, ctx);

  test('the schema offers run_in_background and timeout_seconds', () {
    final props = bash.inputSchema['properties'] as Map;
    expect(props['run_in_background'], isA<Map>());
    expect(props['timeout_seconds'], isA<Map>());
  });

  test('returns at once with the handle and how to follow up', () async {
    final result = await start('sleep 5');
    expect(result.isError, isFalse);
    final handle = registry.byHandle('b1')!.outputHandle;
    expect(result.content, startsWith('Started background command b1'));
    expect(result.content, contains('read_output(handle: "$handle")'));
    expect(
      result.content,
      contains(
        'await tools.bash_output({handle: "b1"}) / '
        'await tools.bash_kill({handle: "b1"})',
      ),
    );
    expect(result.content, contains('killed after 10 min'));
    expect(registry.live, hasLength(1));
  });

  test('names bash_output and bash_kill in the form the run calls them in',
      () async {
    registry.bindCallForms((_) => ToolCallForm.direct);
    final direct = await start('sleep 5');
    expect(
      direct.content,
      contains(
        'Status or stop: bash_output({handle: "b1"}) / '
        'bash_kill({handle: "b1"})\n',
      ),
    );
    registry.bindCallForms(plainToolForm);
    final plain = await start('sleep 5');
    expect(
      plain.content,
      contains(
        'Status or stop: bash_output(handle: "b2") / bash_kill(handle: "b2")\n',
      ),
    );
  });

  test('the refusal past the live cap names bash_kill in the run\'s form',
      () async {
    for (var i = 0; i < BackgroundCommandRegistry.maxLiveCommands; i++) {
      await start('sleep 5');
    }
    final scripted = await start('sleep 5');
    expect(
      scripted.content,
      contains(
        'Wait for one to finish, or stop one with '
        '`await tools.bash_kill({handle})` from a `repl` script, then start '
        'this one.',
      ),
    );
    registry.bindCallForms((_) => ToolCallForm.direct);
    final direct = await start('sleep 5');
    expect(
      direct.content,
      contains(
        'Wait for one to finish, or stop one with `bash_kill({handle})`, '
        'then start this one.',
      ),
    );
  });

  test('exit: notice in the run\'s lane, full output stored', () async {
    await start('echo one; echo two; exit 3');
    final command = registry.byHandle('b1')!;
    await command.settled;
    expect(command.exitCode, 3);
    expect(notices.single, contains('finished with exit code 3'));
    expect(notices.single, contains('one\ntwo'));
    expect(
      notices.single,
      contains('read_output(handle: "${command.storedOutputHandle}")'),
    );
  });

  test('timeout: the command is killed and the notice says so', () async {
    await start('sleep 30', timeout: 1);
    final command = registry.byHandle('b1')!;
    final pid = runner.processes.single.pid;
    await command.settled.timeout(const Duration(seconds: 10));
    expect(command.status, BackgroundCommandStatus.timedOut);
    expect(notices.single, contains('timed out after 1 s and was killed'));
    expect(_alive(pid), isFalse);
  });

  test('bash_output pages new output; read_output pages it live', () async {
    await start(
      'echo first; while [ ! -f "${dir.path}/go" ]; do sleep 0.05; done; '
      'echo second',
    );
    final command = registry.byHandle('b1')!;
    await _until(() => command.output.contains('first'));

    final first = await output.execute({'handle': 'b1'}, ctx);
    expect(first.content, contains('b1 running for'));
    expect((first.structured! as Map)['new_output'], 'first\n');
    expect((first.structured! as Map)['status'], 'running');
    expect((first.structured! as Map)['exit_code'], isNull);

    final again = await output.execute({'handle': 'b1'}, ctx);
    expect(again.content, contains('No new output since the last check.'));

    // read_output serves the same live output by the command's handle.
    final live = await read.execute({'handle': command.outputHandle}, ctx);
    expect(live.isError, isFalse);
    expect(live.content, contains('output so far'));
    expect(live.content, contains('first'));

    File('${dir.path}/go').writeAsStringSync('');
    await command.settled;
    final last = await output.execute({'handle': 'b1'}, ctx);
    expect(last.content, contains('exited with code 0'));
    expect((last.structured! as Map)['new_output'], 'second\n');
    expect((last.structured! as Map)['exit_code'], 0);
  });

  test('bash_kill kills the process and no notice follows', () async {
    await start('sleep 30');
    final pid = runner.processes.single.pid;
    expect(_alive(pid), isTrue);
    final result = await kill.execute({'handle': 'b1'}, ctx);
    expect(result.content, contains('b1 was killed'));
    expect(_alive(pid), isFalse);
    expect(notices, isEmpty);
    final unknown = await kill.execute({'handle': 'b7'}, ctx);
    expect(unknown.isError, isTrue);
    expect(unknown.content, contains('Known handles: b1.'));
  });

  test('a fifth live command is refused', () async {
    for (var i = 0; i < 4; i++) {
      expect((await start('sleep 30')).isError, isFalse);
    }
    final fifth = await start('sleep 30');
    expect(fifth.isError, isTrue);
    expect(fifth.content, contains('b1, b2, b3, b4'));
    expect(runner.processes, hasLength(4));
  });

  test('the run\'s end kills every process', () async {
    await start('sleep 30');
    await start('sleep 30');
    final pids = runner.processes.map((p) => p.pid).toList();
    expect(pids.every(_alive), isTrue);
    await registry.killAll();
    expect(pids.any(_alive), isFalse);
  });

  group('already delivered (A10)', () {
    test(
      'bash_output and bash_kill say so once the notice reached the model',
      () async {
        await start('echo done; exit 4');
        await registry.byHandle('b1')!.settled;
        final before = await output.execute({'handle': 'b1'}, ctx);
        expect(before.content, isNot(contains('Already delivered')));
        registry.markNoticeDelivered('b1');
        final after = await output.execute({'handle': 'b1'}, ctx);
        expect(
          after.content,
          startsWith(
            'Already delivered in the exit notice.\nb1 exited with code 4',
          ),
        );
        final killed = await kill.execute({'handle': 'b1'}, ctx);
        expect(killed.isError, isFalse);
        expect(
          killed.content,
          startsWith(
            'Already delivered in the exit notice.\nb1 exited with code 4',
          ),
        );
        expect((killed.structured! as Map)['exit_code'], 4);
        expect((killed.structured! as Map)['status'], 'exited');
      },
    );

    test('bash_kill on a command that already ended is not an error', () async {
      await start('exit 0');
      await registry.byHandle('b1')!.settled;
      final result = await kill.execute({'handle': 'b1'}, ctx);
      expect(result.isError, isFalse);
      expect(result.content, contains('nothing to stop'));
      expect((result.structured! as Map)['exit_code'], 0);
    });
  });

  group('notify (A8)', () {
    test('an invalid or dangerous pattern starts nothing', () async {
      for (final bad in [
        '(unclosed',
        '(a+)+',
        '(.*a){12}',
        r'\w+\w+\w+!',
        'x' * 201,
      ]) {
        final result = await bash.execute({
          'command': 'sleep 5',
          'description': 'x',
          'run_in_background': true,
          'notify': bad,
        }, ctx);
        expect(result.isError, isTrue, reason: bad);
        expect(result.content, endsWith('Nothing was started.'));
        if (bad.length <= 200) {
          // The refusal says what the pattern language is.
          expect(result.content, contains('notify takes a simple pattern'));
        }
      }
      expect(runner.processes, isEmpty);
      expect(registry.commands, isEmpty);
    });

    test(
      'a real command\'s matching lines are delivered as [bN] lines',
      () async {
        final result = await bash.execute({
          'command':
              'echo starting; echo "listening on :3000"; '
              'while [ ! -f "${dir.path}/stop" ]; do sleep 0.05; done',
          'description': 'server',
          'run_in_background': true,
          'notify': 'listening on',
        }, ctx);
        expect(
          result.content,
          contains('Output lines matching notify are sent to you'),
        );
        await _until(() => registry.hasNotifyPending);
        final delivery = registry.takeNotifyDeliveries().single;
        expect(
          delivery.text,
          contains('>[b1] listening on :3000</wake-data id='),
        );
        expect(delivery.text, isNot(contains('starting')));
        expect(registry.byHandle('b1')!.isLive, isTrue);
        File('${dir.path}/stop').writeAsStringSync('');
        await registry.byHandle('b1')!.settled;
      },
    );

    test('the schema offers notify, bounded', () {
      final notify = (bash.inputSchema['properties'] as Map)['notify'] as Map;
      expect(notify['maxLength'], 200);
      expect(notify['description'], contains('need not poll'));
      expect(notify['description'], contains('one quantifier per branch'));
    });
  });

  group('scripts', () {
    test('a script may not start a background command', () {
      expect(
        bash.scriptArgumentRefusal({
          'command': 'sleep 5',
          'run_in_background': true,
        }),
        contains('must not outlive the script'),
      );
      expect(bash.scriptArgumentRefusal({'command': 'ls'}), isNull);
    });

    test('a nested call is refused even past the gate', () async {
      final result = await bash.execute({
        'command': 'sleep 5',
        'description': 'from a script',
        'run_in_background': true,
      }, ctx.withParentToolCallId('call_repl'));
      expect(result.isError, isTrue);
      expect(result.outcome, ToolOutcome.denied);
      expect(runner.processes, isEmpty);
    });

    test('bash_output and bash_kill are callable from scripts', () {
      expect(output.scriptCallable, isTrue);
      expect(kill.scriptCallable, isTrue);
    });

    test('their result notes name the keys a script receives', () async {
      await start('echo hi');
      await registry.byHandle('b1')!.settled;
      final checked = await output.execute({'handle': 'b1'}, ctx);
      for (final key in (checked.structured! as Map).keys) {
        expect(output.resultNote, contains('$key'));
      }
      await start('sleep 30');
      final killed = await kill.execute({'handle': 'b2'}, ctx);
      for (final key in (killed.structured! as Map).keys) {
        expect(kill.resultNote, contains('$key'));
      }
      final unknown = await output.execute({'handle': 'b9'}, ctx);
      expect(unknown.isError, isTrue);
    });
  });

  test('without a registry, run_in_background is refused', () async {
    final plain = BashTool(runner);
    final result = await plain.execute({
      'command': 'sleep 5',
      'description': 'x',
      'run_in_background': true,
    }, ctx);
    expect(result.isError, isTrue);
    expect(result.content, contains('not available'));
    expect(runner.processes, isEmpty);
  });

  group('compact', () {
    test('is a schema the loop handles, never a script call', () async {
      final tool = CompactTool();
      expect(tool.name, 'compact');
      expect(tool.scriptCallable, isFalse);
      final focus = (tool.inputSchema['properties'] as Map)['focus'] as Map;
      expect(focus['maxLength'], 1000);
      expect((await tool.execute({}, ctx)).isError, isTrue);
    });
  });
}
