@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/sandboxing/process_group_supervisor.dart';
import 'package:test/test.dart';

/// Real processes throughout: what is under test is how `/bin/sh` behaves.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('cc-supervisor-'));
  tearDown(() => dir.deleteSync(recursive: true));

  bool alive(int pid) =>
      Process.runSync('/bin/kill', ['-0', '$pid']).exitCode == 0;

  Future<void> until(bool Function() ready, {int seconds = 12}) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!ready()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition not reached in ${seconds}s');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Writes a command that starts a grandchild and reports its pid.
  String parentOfGrandchild({String trapTerm = ''}) {
    final file = File('${dir.path}/tree.sh')
      ..writeAsStringSync('''
#!/bin/sh
$trapTerm
/bin/sleep 300 &
echo \$! > "${dir.path}/grandchild"
echo \$\$ > "${dir.path}/child"
wait
''');
    Process.runSync('/bin/chmod', ['+x', file.path]);
    return file.path;
  }

  int pidFrom(String name) =>
      int.parse(File('${dir.path}/$name').readAsStringSync().trim());

  Future<Process> startSupervised(String executable, List<String> argv) {
    final wrapped = superviseProcessGroup(executable, argv);
    return Process.start(wrapped.executable, wrapped.argv);
  }

  bool reported(String name) => File('${dir.path}/$name').existsSync();

  test('stdin, stdout, stderr and the exit code pass through', () async {
    final process = await startSupervised('/bin/sh', [
      '-c',
      'read line; echo "got \$line"; echo oops >&2; exit 7',
    ]);
    final out = process.stdout.transform(utf8.decoder).join();
    final err = process.stderr.transform(utf8.decoder).join();

    process.stdin.writeln('hello');
    await process.stdin.close();

    expect(await process.exitCode, 7);
    expect(await out, 'got hello\n');
    expect(await err, 'oops\n');
  });

  test('closing stdin is what ends a command reading it', () async {
    final process = await startSupervised('/bin/cat', const []);
    final out = process.stdout.transform(utf8.decoder).join();

    process.stdin.writeln('line');
    await process.stdin.close();

    expect(await process.exitCode.timeout(const Duration(seconds: 5)), 0);
    expect(await out, 'line\n');
  });

  test('arguments are never re-read by the shell', () async {
    final process = await startSupervised('/bin/echo', [
      r'$(touch x); `y` "z"',
    ]);

    expect(
      await process.stdout.transform(utf8.decoder).join(),
      '\$(touch x); `y` "z"\n',
    );
  });

  test('stopping the watcher stops the grandchild too', () async {
    final process = await startSupervised(parentOfGrandchild(), const []);
    await until(() => reported('child'));
    final grandchild = pidFrom('grandchild');
    expect(alive(grandchild), isTrue);

    process.kill();

    await process.exitCode.timeout(const Duration(seconds: 5));
    await until(() => !alive(grandchild), seconds: 3);
  });

  test('a command ignoring TERM is killed', () async {
    final process = await startSupervised(
      parentOfGrandchild(trapTerm: "trap '' TERM"),
      const [],
    );
    await until(() => reported('child'));
    final child = pidFrom('child');

    process.kill();

    await until(() => !alive(child));
    await process.exitCode.timeout(const Duration(seconds: 5));
  });

  test('a normal exit leaves what the command started running', () async {
    final file = File('${dir.path}/daemon.sh')
      ..writeAsStringSync('''
#!/bin/sh
/bin/sleep 300 </dev/null >/dev/null 2>&1 &
echo \$! > "${dir.path}/daemon"
exit 0
''');
    Process.runSync('/bin/chmod', ['+x', file.path]);

    final process = await startSupervised(file.path, const []);

    expect(await process.exitCode.timeout(const Duration(seconds: 5)), 0);
    final daemon = pidFrom('daemon');
    addTearDown(() => Process.killPid(daemon, ProcessSignal.sigkill));
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(alive(daemon), isTrue);
  });

  test('a dead server takes the whole group with it', () async {
    // A stand-in for the server: starts the watcher, then dies by SIGKILL with
    // no chance to clean up, which is what a crash looks like.
    final tree = parentOfGrandchild();
    final script = File('${dir.path}/server.sh')
      ..writeAsStringSync(r'''
#!/bin/sh
"$@" </dev/null >/dev/null 2>&1 &
exec /bin/sleep 300
''');
    Process.runSync('/bin/chmod', ['+x', script.path]);
    final wrapped = superviseProcessGroup(tree, const []);
    final server = await Process.start(script.path, [
      wrapped.executable,
      ...wrapped.argv,
    ]);
    await until(() => reported('child'));
    final child = pidFrom('child');
    final grandchild = pidFrom('grandchild');

    server.kill(ProcessSignal.sigkill);

    await until(() => !alive(child) && !alive(grandchild));
  });
}
