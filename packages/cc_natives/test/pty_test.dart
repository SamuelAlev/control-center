@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

/// Proves the vendored PTY native (`libccpty`) works inside a **plain Dart VM**
/// process — no Flutter engine — which is the make-or-break premise for running
/// the agent executor inside the `dart build cli` cc_server binary.
///
/// Build the native first:  `scripts/natives/build_pty.sh build/natives`
/// then point the loader at it: `CC_PTY_DYLIB=build/natives/libccpty.dylib`.
/// `build_pty.sh` also installs to the app-support root, which the default
/// resolver finds, so the env var is only needed when running from a clean dir.
void main() {
  group('libccpty (headless PTY)', () {
    test('reports availability honestly', () {
      // If this is false the other tests can't run — surface why loudly.
      if (!Pty.isAvailable) {
        fail(
          'libccpty not loadable. Run scripts/natives/build_pty.sh and/or set '
          r'$CC_PTY_DYLIB to the built dylib.',
        );
      }
      expect(Pty.isAvailable, isTrue);
    });

    test('spawns a process and streams its stdout bytes', () async {
      final pty = Pty.start(
        '/bin/sh',
        arguments: ['-c', 'echo hello-from-pty'],
      );

      final out = StringBuffer();
      final done = Completer<void>();
      final sub = pty.output.listen(
        (Uint8List bytes) => out.write(utf8.decode(bytes, allowMalformed: true)),
        onDone: () {
          if (!done.isCompleted) {
            done.complete();
          }
        },
      );

      final exit = await pty.exitCode.timeout(const Duration(seconds: 10));
      await done.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {}, // stream close races exit; output is already buffered
      );
      await sub.cancel();

      expect(exit, 0, reason: 'sh -c echo should exit cleanly');
      expect(
        out.toString(),
        contains('hello-from-pty'),
        reason: 'PTY stdout must carry the echoed line back to Dart',
      );
    });

    test('writes to the pty and reads the echoed input back', () async {
      // `cat` echoes its stdin; a PTY also echoes typed input by default, so a
      // single write should come back to us. Then EOF (Ctrl-D) ends it.
      final pty = Pty.start('/bin/cat');

      final out = StringBuffer();
      final sub = pty.output.listen(
        (Uint8List bytes) => out.write(utf8.decode(bytes, allowMalformed: true)),
      );

      // Give the child a moment to come up, then send a line + EOF.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      pty.write(Uint8List.fromList(utf8.encode('ping-1234\n')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      pty.write(Uint8List.fromList([4])); // Ctrl-D (EOF)

      final exit = await pty.exitCode.timeout(const Duration(seconds: 10));
      await sub.cancel();

      expect(exit, isA<int>());
      expect(
        out.toString(),
        contains('ping-1234'),
        reason: 'cat over a PTY echoes the written input back on the master',
      );
    });

    test('reports a valid pid for the spawned process', () async {
      final pty = Pty.start('/bin/sh', arguments: ['-c', 'sleep 0.2']);
      expect(pty.pid, greaterThan(0));
      final exit = await pty.exitCode.timeout(const Duration(seconds: 10));
      expect(exit, 0);
    });
  });
}
