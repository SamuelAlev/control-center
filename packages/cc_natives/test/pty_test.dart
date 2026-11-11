@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

import 'helpers/dev_native_layout.dart';

/// Proves the vendored PTY native (`libccpty`) works inside a **plain Dart VM**
/// process — no Flutter engine — which is the make-or-break premise for running
/// the agent executor inside the `dart build cli` cc_server binary.
///
/// Build the native first: `scripts/natives/build_pty.sh`.
///
/// The DEFAULT resolver deliberately knows only `$CC_PTY_DYLIB` + the running
/// binary's own bundle layout — a leaf package cannot know a host's app-support
/// path, so every host injects a richer resolver (`cc_server` passes its data
/// dir). This test does the same, covering both dev install locations
/// `build_pty.sh` writes to, so a correctly built tree passes without the env
/// var. Same pattern as `native_directory_watcher_ffi_test.dart`.
void main() {
  Pty.libraryResolver = () => tryOpenFirst(
    devNativeCandidates(ptyLibraryBaseName, envVar: ptyLibraryEnvVar),
  );
  tearDownAll(() => Pty.libraryResolver = defaultPtyLibraryResolver);

  if (!Pty.isAvailable) {
    test('libccpty is built', () {
      fail(
        'libccpty not loadable. Run scripts/natives/build_pty.sh and/or set '
        r'$CC_PTY_DYLIB to the built dylib.',
      );
    }, skip: skipIfMissingInCi(false, 'libccpty is not built on CI runners'));
    return;
  }

  group('libccpty (headless PTY)', () {
    test('reports availability honestly', () {
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
        (Uint8List bytes) =>
            out.write(utf8.decode(bytes, allowMalformed: true)),
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
        (Uint8List bytes) =>
            out.write(utf8.decode(bytes, allowMalformed: true)),
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

  // What a long-lived host needs from every terminal it starts. Each of these
  // went wrong in the upstream native, a few times in a hundred or once per
  // terminal, which is why they run in rounds.
  group('a terminal in a long-lived host', () {
    Future<({int exit, String output})> run(
      String executable, {
      List<String> arguments = const [],
      String? workingDirectory,
    }) async {
      final pty = Pty.start(
        executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
      );
      final output = StringBuffer();
      final subscription = pty.output.listen(
        (bytes) => output.write(utf8.decode(bytes, allowMalformed: true)),
      );
      final exit = await pty.exitCode.timeout(const Duration(seconds: 20));
      // Read at once: what the child wrote is promised before its exit.
      final text = output.toString();
      await subscription.cancel();
      return (exit: exit, output: text);
    }

    test(
      'a kill right after the spawn ends the child, and only the child',
      () async {
        // Until it execs, the child is a copy of this process, handlers and
        // all: a signal landing there used to be reported to the host as its
        // own, while the child lived on.
        var heard = 0;
        final watch = ProcessSignal.sigterm.watch().listen((_) => heard++);
        addTearDown(watch.cancel);

        for (var round = 0; round < 60; round++) {
          final pty = Pty.start('/bin/sh', arguments: ['-c', 'sleep 30']);
          pty.kill();
          expect(
            await pty.exitCode.timeout(const Duration(seconds: 5)),
            -ProcessSignal.sigterm.signalNumber,
            reason: 'round $round',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(heard, 0);
      },
    );

    test('the last output arrives before the exit', () async {
      for (var round = 0; round < 60; round++) {
        final result = await run(
          '/bin/sh',
          arguments: ['-c', 'echo last-words-$round; exit 3'],
        );
        expect(result.exit, 3);
        expect(result.output, contains('last-words-$round'));
      }
    });

    test('a long output arrives whole', () async {
      final result = await run(
        '/bin/sh',
        arguments: ['-c', 'seq 1 50000; echo the-end; exit 5'],
      );
      expect(result.exit, 5);
      final lines = const LineSplitter().convert(result.output);
      expect(lines.where((line) => line.trim() == '50000'), hasLength(1));
      expect(lines.last.trim(), 'the-end');
    });

    test('a program that is not there exits 127 and says so', () async {
      final result = await run('/nonexistent/tool');
      expect(result.exit, 127);
      expect(result.output, contains('/nonexistent/tool'));
    });

    test('a working directory that is not there exits 126', () async {
      final result = await run(
        '/bin/sh',
        arguments: ['-c', 'echo ran-anyway'],
        workingDirectory: '/nonexistent/dir',
      );
      expect(result.exit, 126);
      expect(result.output, isNot(contains('ran-anyway')));
    });

    test('a descendant holding the terminal does not hold the exit', () async {
      final clock = Stopwatch()..start();
      final result = await run(
        '/bin/sh',
        arguments: ['-c', '(sleep 20 &); echo started; exit 0'],
      );
      expect(result.exit, 0);
      expect(result.output, contains('started'));
      expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('nothing stays open once a terminal ended', () async {
      final before = _terminalDescriptors();
      for (var round = 0; round < 20; round++) {
        await run('/bin/sh', arguments: ['-c', '(sleep 20 &); exit 0']);
      }
      // The reader lets go on its next look at a quiet terminal.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(_terminalDescriptors(), before);
    });

    test('input after the exit goes nowhere', () async {
      final pty = Pty.start('/bin/sh', arguments: ['-c', 'exit 0']);
      await pty.exitCode.timeout(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      pty
        ..write(Uint8List.fromList(utf8.encode('late\n')))
        ..resize(10, 10);
    });
    // Signals, descriptors and exec are the Unix native; ConPTY has its own.
  }, testOn: 'mac-os || linux');
}

/// How many terminal ends this process holds open.
int _terminalDescriptors() {
  if (Platform.isLinux) {
    var count = 0;
    for (final entry in Directory(
      '/proc/self/fd',
    ).listSync(followLinks: false)) {
      try {
        final target = Link(entry.path).targetSync();
        if (target == '/dev/ptmx' || target.startsWith('/dev/pts/')) {
          count++;
        }
      } on FileSystemException {
        // The listing's own descriptor, gone by now.
      }
    }
    return count;
  }
  final listing = Process.runSync('lsof', ['-p', '$pid']).stdout as String;
  return const LineSplitter()
      .convert(listing)
      .where((line) => line.contains('/dev/ptmx') || line.contains('/dev/ttys'))
      .length;
}
