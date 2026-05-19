@TestOn('!windows')
library;

import 'package:control_center/core/server/cc_server_process.dart';
import 'package:flutter_test/flutter_test.dart';

/// Supervisor tests for [CcServerProcess]. They drive a shell fake that mimics
/// the real `cc_server`'s stdout contract (the `cc_server ready on <host>:<port>`
/// line) without spawning a database — so the readiness parsing, endpoint
/// extraction, premature-exit handling, timeout, and clean shutdown are all
/// exercised deterministically. The real binary is proven end-to-end by
/// packages/cc_server_core/test/cc_server_e2e_test.dart.
CcServerProcess _sh(String script, {void Function(String, String)? onLog}) =>
    CcServerProcess(executable: 'sh', args: ['-c', script], onLog: onLog);

void main() {
  test('parses the ready line and exposes the bound loopback endpoint', () async {
    final lines = <String>[];
    final server = _sh(
      'echo "[info] cc_server ready on 127.0.0.1:54321 (data: /tmp, workspaces: 0)"; '
      'sleep 30',
      onLog: (level, message) => lines.add('$level: $message'),
    );

    final endpoint = await server.start();
    addTearDown(server.stop);

    expect(endpoint.host, '127.0.0.1');
    expect(endpoint.port, 54321);
    expect(endpoint.rpcUri, Uri.parse('ws://127.0.0.1:54321/rpc'));
    expect(server.isRunning, isTrue);
    expect(lines, contains(contains('cc_server ready on 127.0.0.1:54321')));
  });

  test('stop() terminates the child and resolves its exit code', () async {
    final server = _sh(
      'echo "cc_server ready on 127.0.0.1:9999"; sleep 30',
    );
    await server.start();

    await server.stop();

    expect(server.isRunning, isFalse);
    // The child was signalled; its exit code future has completed.
    expect(server.exitCode, isNull); // process handle cleared after stop()
  });

  test('isRunning flips to false when the child exits on its own after ready',
      () async {
    // Ready, then exit shortly after — a post-ready crash.
    final server = _sh(
      'echo "cc_server ready on 127.0.0.1:8001"; sleep 0.2; exit 0',
    );
    await server.start();
    expect(server.isRunning, isTrue);

    await server.exitCode; // wait for the child to die on its own
    // Let the exitCode listener run.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(server.isRunning, isFalse);
    await server.stop(); // idempotent / safe after self-exit
  });

  test('killSync() synchronously terminates the child (dispose path)', () async {
    final server = _sh('echo "cc_server ready on 127.0.0.1:7777"; sleep 30');
    final exit = await server.start();
    expect(exit.port, 7777);

    server.killSync(); // synchronous, as dispose() would call it
    final code = await server.exitCode;

    expect(code, isNot(0)); // killed, not a clean exit
    expect(server.isRunning, isFalse);
  });

  test('throws when the child exits before reporting readiness', () async {
    final server = _sh('echo "booting"; exit 3');

    await expectLater(
      server.start(),
      throwsA(isA<CcServerStartException>()),
    );
  });

  test('throws (and kills the child) when readiness times out', () async {
    final server = _sh('sleep 30'); // never prints the ready line

    await expectLater(
      server.start(timeout: const Duration(milliseconds: 300)),
      throwsA(isA<CcServerStartException>()),
    );
    expect(server.isRunning, isFalse);
  });

  test('rejects a double start', () async {
    final server = _sh('echo "cc_server ready on 127.0.0.1:7000"; sleep 30');
    await server.start();
    addTearDown(server.stop);

    expect(server.start, throwsStateError);
  });

  group('CcServerLauncher', () {
    test('serverArgs threads data-dir / port / bind', () {
      final args = CcServerLauncher.serverArgs(
        dataDir: '/data',
        port: 9030,
        bind: 'loopback',
      );
      expect(args, ['--data-dir', '/data', '--port', '9030', '--bind', 'loopback']);
    });

    test('fromBinary builds a supervisor for the given binary', () {
      final p = CcServerLauncher.fromBinary(
        binaryPath: '/opt/cc_server',
        dataDir: '/data',
        port: 0,
      );
      expect(p.executable, '/opt/cc_server');
      expect(p.args, contains('--data-dir'));
      expect(p.args, contains('/data'));
    });

    test('devRun runs the entry script through the Dart SDK', () {
      final p = CcServerLauncher.devRun(
        dartExecutable: '/sdk/dart',
        repoRoot: '/repo',
        dataDir: '/data',
      );
      expect(p.executable, '/sdk/dart');
      expect(p.args.first, 'run');
      expect(p.args[1], '/repo/apps/cc_server/bin/cc_server.dart');
      expect(p.workingDirectory, '/repo');
    });
  });
}
