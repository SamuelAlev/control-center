@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/sandboxing/violation_monitor.dart';
import 'package:test/test.dart';

/// The `log stream` tap must never outlive the server that started it: an
/// orphaned tap stays a `logd` client forever, and they piled up by the
/// hundred. These run [SandboxViolationMonitor.tetherScript] with `sleep`
/// standing in for `log`, plus the real tap on macOS.
void main() {
  const tetherTimeout = Duration(seconds: 10);

  Future<bool> alive(int pid) async =>
      (await Process.run('/bin/kill', ['-0', '$pid'])).exitCode == 0;

  Future<void> expectGone(int pid) async {
    final deadline = DateTime.now().add(tetherTimeout);
    while (await alive(pid)) {
      if (DateTime.now().isAfter(deadline)) {
        fail('pid $pid outlived its tether');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// The pid of [parent]'s child named [name], once it has started.
  Future<int> childNamed(int parent, String name) async {
    final deadline = DateTime.now().add(tetherTimeout);
    while (true) {
      final found = await Process.run('/usr/bin/pgrep', [
        '-P',
        '$parent',
        '-x',
        name,
      ]);
      final pids = LineSplitter.split(
        found.stdout as String,
      ).where((l) => l.trim().isNotEmpty).map(int.parse).toList();
      if (pids.length == 1) {
        return pids.single;
      }
      if (DateTime.now().isAfter(deadline)) {
        fail('no single $name child of $parent: $pids');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<Process> tether(List<String> command) => Process.start('/bin/sh', [
    '-c',
    SandboxViolationMonitor.tetherScript,
    'sh',
    ...command,
  ]);

  group('tetherScript', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('cc_tether_test_');
    });

    tearDown(() async {
      await root.delete(recursive: true);
    });

    test('ends the child when its parent is SIGKILLed', () async {
      // A stand-in server: it holds the tether's stdin and is then killed
      // without any chance to clean up.
      final server = File('${root.path}/server.dart');
      await server.writeAsString(r'''
import 'dart:io';

Future<void> main(List<String> args) async {
  final tether = await Process.start(
    '/bin/sh',
    ['-c', args.single, 'sh', '/bin/sleep', '300'],
  );
  stdout.writeln(tether.pid);
  await stdout.flush();
  await tether.exitCode;
}
''');
      final parent = await Process.start(Platform.resolvedExecutable, [
        server.path,
        SandboxViolationMonitor.tetherScript,
      ]);
      unawaited(parent.stderr.drain<void>());
      final tetherPid = int.parse(
        await parent.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .first
            .timeout(const Duration(seconds: 60)),
      );
      final child = await childNamed(tetherPid, 'sleep');

      parent.kill(ProcessSignal.sigkill);
      await parent.exitCode;

      await expectGone(child);
      await expectGone(tetherPid);
    });

    test('ends the child when stdin closes, despite a later sibling', () async {
      final process = await tether(['/bin/sleep', '300']);
      // Started after the tether: had it inherited the tether's stdin
      // pipe, closing ours would never reach EOF.
      final sibling = await Process.start('/bin/sleep', ['300']);
      addTearDown(() => sibling.kill(ProcessSignal.sigkill));
      final child = await childNamed(process.pid, 'sleep');

      await process.stdin.close();

      // 128 + SIGTERM: the watcher killed the child, the tether passed it on.
      expect(await process.exitCode.timeout(tetherTimeout), 143);
      await expectGone(child);
      expect(await alive(sibling.pid), isTrue);
    });

    test('exits with the status of a child that ends by itself', () async {
      final process = await tether(['/bin/sh', '-c', 'exit 3']);
      addTearDown(process.stdin.close);

      expect(await process.exitCode.timeout(tetherTimeout), 3);
    });
  });

  group('SandboxViolationMonitor', () {
    test('close ends the log stream tap', () async {
      final monitor = await SandboxViolationMonitor.start();
      expect(monitor, isNotNull);
      final tap = await childNamed(monitor!.pid, 'log');

      await monitor.close();

      await expectGone(tap);
      await expectGone(monitor.pid);
    }, testOn: 'mac-os');
  });

  group('orphanedTapPids', () {
    const tap =
        '/usr/bin/log stream --style ndjson --predicate sender == "Sandbox" '
        'OR subsystem BEGINSWITH "com.apple.sandbox"';

    test('finds exact taps adopted by launchd', () {
      final ps = [
        '  101     1 $tap',
        '  102  4242 $tap',
        '  103     1 /usr/bin/log stream --style ndjson',
        '  104     1 /usr/bin/log show --predicate sender == "Sandbox"',
        '  105    11 $tap',
        '  106     1 $tap  ',
        'garbage',
        '',
      ].join('\n');

      expect(SandboxViolationMonitor.orphanedTapPids(ps), [101, 106]);
    });

    test('finds nothing in an empty listing', () {
      expect(SandboxViolationMonitor.orphanedTapPids(''), isEmpty);
    });
  });
}
