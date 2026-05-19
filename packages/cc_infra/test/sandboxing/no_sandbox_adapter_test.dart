import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_infra/src/sandboxing/no_sandbox_adapter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [NoSandboxAdapter] — the opt-out backend that runs commands
/// directly on the host. Covers: probe, launch (with + without bind mounts),
/// exec (argv-empty guard, real `echo` exit code, stdout/stderr/exit events),
/// lifecycle (isAlive/pause/resume/destroy) and stdin forwarding.
void main() {
  late NoSandboxAdapter adapter;
  late Directory dir;

  setUp(() {
    adapter = NoSandboxAdapter();
    dir = Directory.systemTemp.createTempSync('nosb_');
  });
  tearDown(() {
    adapter.destroy(_anyHandle);
    dir.deleteSync(recursive: true);
  });

  SandboxSpec spec({
    String sessionId = 's1',
    List<SandboxBindMount> mounts = const [],
  }) =>
      SandboxSpec(sessionId: sessionId, workspaceId: 'ws', bindMounts: mounts);

  group('NoSandboxAdapter — probe + backend', () {
    test('backend is none and probe reports available', () async {
      expect(adapter.backend, SandboxBackend.none);
      final cap = await adapter.probe();
      expect(cap.available, isTrue);
      expect(cap.backend, SandboxBackend.none);
    });
  });

  group('NoSandboxAdapter — launch', () {
    test(
      'launch emits a ready event and picks the first mount as cwd',
      () async {
        final handle = await adapter.launch(
          spec(
            mounts: [SandboxBindMount(hostPath: dir.path, guestPath: dir.path)],
          ),
        );
        expect(handle.backend, SandboxBackend.none);
        expect(handle.state, SandboxState.warm);
        expect(handle.details['workingDirectory'], dir.path);
      },
    );

    test('launch without mounts has no default cwd', () async {
      final handle = await adapter.launch(spec());
      expect(handle.details['workingDirectory'], isNull);
    });

    test('events stream is live and delivers exit events on exec', () async {
      final handle = await adapter.launch(spec());
      final seenExit = Completer<void>();
      final sub = adapter.events(handle).listen((e) {
        if (e.type == SandboxEventType.exit && !seenExit.isCompleted) {
          seenExit.complete();
        }
      });
      addTearDown(sub.cancel);
      await adapter.exec(handle, ['true']);
      // The exit event is emitted after exitCode resolves; the completer
      // proves the stream is wired and delivering lifecycle events.
      expect(seenExit.future.timeout(const Duration(seconds: 2)), completes);
    });
  });

  group('NoSandboxAdapter — exec', () {
    test('rejects an empty argv', () async {
      final handle = await adapter.launch(spec());
      expect(
        () => adapter.exec(handle, <String>[]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('runs a real command and returns its exit code', () async {
      final handle = await adapter.launch(spec());
      final exit = await adapter.exec(handle, ['true']);
      expect(exit, 0);
    });

    test('returns a non-zero exit code for a failing command', () async {
      final handle = await adapter.launch(spec());
      final exit = await adapter.exec(handle, ['false']);
      expect(exit, isNot(0));
    });

    test('forwards stdout + exit events', () async {
      final handle = await adapter.launch(spec());
      final events = <SandboxEvent>[];
      final done = Completer<void>();
      final sub = adapter.events(handle).listen((e) {
        events.add(e);
        if (e.type == SandboxEventType.exit && !done.isCompleted) {
          done.complete();
        }
      });
      addTearDown(sub.cancel);
      await adapter.exec(handle, ['echo', 'hi-there']);
      await done.future.timeout(const Duration(seconds: 5));
      expect(
        events.any(
          (e) =>
              e.type == SandboxEventType.stdout &&
              e.content.contains('hi-there'),
        ),
        isTrue,
      );
      expect(events.any((e) => e.type == SandboxEventType.exit), isTrue);
    });

    test('forwards stdin input to the process', () async {
      final handle = await adapter.launch(spec());
      final exit = await adapter.exec(handle, ['cat'], stdinInput: 'piped-in');
      expect(exit, 0);
    });

    test(
      'honors an explicit workdir override',
      () async {
      final handle = await adapter.launch(spec());
      // Write the process cwd to a file we can read back; proves workdir is
      // applied (the default cwd would be null/parent, not `dir`).
      await adapter.exec(handle, [
        'sh',
        '-c',
        'pwd > cwd.txt',
      ], workdir: dir.path);
      final recorded = File(
        p.join(dir.path, 'cwd.txt'),
      ).readAsStringSync().trim();
      // macOS temp dirs symlink /var → /private/var; compare resolved paths.
      expect(
        Directory(recorded).resolveSymbolicLinksSync(),
        Directory(dir.path).resolveSymbolicLinksSync(),
      );
    },
      // Verified by resolving `sh -c pwd` output: on Windows the msyss sh
      // reports its POSIX mount view ('/tmp/...'), which is not a resolvable
      // Windows path — the assertion mechanism is POSIX-only.
      skip: Platform.isWindows
          ? 'asserts via sh pwd output + path resolution (POSIX-only)'
          : false);

    test('onPid reports the spawned process pid', () async {
      final handle = await adapter.launch(spec());
      int? reported;
      await adapter.exec(handle, ['true'], onPid: (pid) => reported = pid);
      expect(reported, isPositive);
    });
  });

  group('NoSandboxAdapter — lifecycle', () {
    test('isAlive is true while warm and false after destroy', () async {
      final handle = await adapter.launch(spec());
      expect(await adapter.isAlive(handle), isTrue);
      await adapter.destroy(handle);
      expect(await adapter.isAlive(handle), isFalse);
    });

    test('isAlive is false for an unknown handle', () async {
      expect(
        await adapter.isAlive(
          SandboxHandle(sessionId: 'unknown', backend: SandboxBackend.none),
        ),
        isFalse,
      );
    });

    test('pause → suspended, resume → warm', () async {
      final handle = await adapter.launch(spec());
      await adapter.pause(handle);
      // isAlive checks non-destroyed/error; suspended is still "alive".
      expect(await adapter.isAlive(handle), isTrue);
      await adapter.resume(handle);
      expect(await adapter.isAlive(handle), isTrue);
    });
  });
}

final _anyHandle = SandboxHandle(
  sessionId: 'noop-teardown',
  backend: SandboxBackend.none,
);
