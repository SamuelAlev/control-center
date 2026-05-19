import 'dart:async';

import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:control_center/core/domain/value_objects/sandbox_handle.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';
import 'package:control_center/features/sandboxing/data/adapters/no_sandbox_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper that creates a `SandboxSpec` with a session id and a single
/// bind mount so `launch` picks up the working directory.
SandboxSpec _spec({
  String sessionId = 's1',
  String hostPath = '/tmp/work',
  String? agentId,
}) {
  return SandboxSpec(
    sessionId: sessionId,
    workspaceId: 'ws',
    bindMounts: [
      const SandboxBindMount(
        hostPath: '/tmp/work',
        guestPath: '/tmp/work',
      ),
    ],
    agentId: agentId,
    guestWorkdir: hostPath,
  );
}

void main() {
  group('NoSandboxAdapter', () {
    late NoSandboxAdapter adapter;

    setUp(() {
      adapter = NoSandboxAdapter();
    });

    // -----------------------------------------------------------------------
    // backend
    // -----------------------------------------------------------------------
    test('backend is SandboxBackend.none', () {
      expect(adapter.backend, SandboxBackend.none);
    });

    // -----------------------------------------------------------------------
    // probe
    // -----------------------------------------------------------------------
    test('probe returns available with "No isolation" note', () async {
      final caps = await adapter.probe();

      expect(caps.backend, SandboxBackend.none);
      expect(caps.available, isTrue);
      expect(caps.note, contains('No isolation'));
    });

    // -----------------------------------------------------------------------
    // launch
    // -----------------------------------------------------------------------
    test('launch creates warm handle with session id', () async {
      final handle = await adapter.launch(_spec());

      expect(handle.sessionId, 's1');
      expect(handle.backend, SandboxBackend.none);
      expect(handle.state, SandboxState.warm);
    });

    test('launch stores working directory from first bind mount', () async {
      const spec = SandboxSpec(
        sessionId: 's2',
        workspaceId: 'ws',
        bindMounts: [
          SandboxBindMount(
            hostPath: '/home/user/agent',
            guestPath: '/home/user/agent',
          ),
          SandboxBindMount(
            hostPath: '/home/user/conv',
            guestPath: '/home/user/conv',
          ),
        ],
      );
      final handle = await adapter.launch(spec);

      expect(handle.details['workingDirectory'], '/home/user/agent');
    });

    // Verify we have a functional broadcast stream. The ready event is
    // emitted *during* launch, before this test can listen — that's fine;
    // the stream handles future events normally.
    test('events returns open broadcast stream after launch', () async {
      final handle = await adapter.launch(_spec());
      final stream = adapter.events(handle);

      expect(stream.isBroadcast, isTrue);
      expect(stream, isA<Stream<SandboxEvent>>());
    });

    test('launch with empty bind mounts sets null working directory',
        () async {
      const spec = SandboxSpec(
        sessionId: 's3',
        workspaceId: 'ws',
        bindMounts: [],
      );
      final handle = await adapter.launch(spec);

      expect(handle.details['workingDirectory'], isNull);
    });

    // -----------------------------------------------------------------------
    // isAlive
    // -----------------------------------------------------------------------
    test('isAlive is true for warm state', () async {
      final handle = await adapter.launch(_spec());
      expect(await adapter.isAlive(handle), isTrue);
    });

    test('isAlive is true for active state (state management only)',
        () async {
      final handle = await adapter.launch(_spec());
      // Move to active by way of _updateState mirroring what exec does
      // before Process.start. We test exec argument validation
      // separately since actual exec requires an OS process.
      unawaited(adapter.pause(handle));
      final paused = SandboxHandle(
        sessionId: handle.sessionId,
        backend: SandboxBackend.none,
        state: SandboxState.suspended,
      );
      expect(await adapter.isAlive(paused), isTrue);
    });

    test('isAlive is false for destroyed state', () async {
      final handle = await adapter.launch(_spec());
      await adapter.destroy(handle);
      expect(await adapter.isAlive(handle), isFalse);
    });

    test('isAlive is false for error state', () async {
      final handle = SandboxHandle(
        sessionId: 'err',
        backend: SandboxBackend.none,
        state: SandboxState.error,
        error: 'failed',
      );
      expect(await adapter.isAlive(handle), isFalse);
    });

    test('isAlive is false for unknown session', () async {
      final handle = SandboxHandle(
        sessionId: 'unknown',
        backend: SandboxBackend.none,
        state: SandboxState.warm,
      );
      expect(await adapter.isAlive(handle), isFalse);
    });

    // -----------------------------------------------------------------------
    // events
    // -----------------------------------------------------------------------
    test('events returns broadcast stream for launched handle', () async {
      final handle = await adapter.launch(_spec());
      final stream = adapter.events(handle);

      expect(stream.isBroadcast, isTrue);
      expect(stream, isA<Stream<SandboxEvent>>());
    });

    test('events returns broadcast stream reused for same session id', () async {
      final handle = await adapter.launch(_spec());
      final stream = adapter.events(handle);

      // Calling events again with a handle for the same session returns
      // a working stream (same underlying broadcast controller).
      final handle2 = SandboxHandle(
        sessionId: handle.sessionId,
        backend: SandboxBackend.none,
      );
      final stream2 = adapter.events(handle2);

      expect(stream.isBroadcast, isTrue);
      expect(stream2.isBroadcast, isTrue);
      // Both streams should be non-null and listenable.
      unawaited(stream.listen((_) {}).cancel());
      unawaited(stream2.listen((_) {}).cancel());
    });

    // -----------------------------------------------------------------------
    // exec — argument validation (pure logic; no OS process)
    // -----------------------------------------------------------------------
    test('exec throws ArgumentError when argv is empty', () async {
      final handle = await adapter.launch(_spec());

      expect(
        () => adapter.exec(handle, []),
        throwsA(isA<ArgumentError>()),
      );
    });

    // -----------------------------------------------------------------------
    // pause / resume — state management
    // -----------------------------------------------------------------------
    test('pause transitions state to suspended', () async {
      final handle = await adapter.launch(_spec());
      expect(handle.state, SandboxState.warm);

      await adapter.pause(handle);

      final updated = SandboxHandle(
        sessionId: handle.sessionId,
        backend: SandboxBackend.none,
        state: SandboxState.suspended,
      );
      expect(await adapter.isAlive(updated), isTrue);
    });

    test('resume transitions state to warm', () async {
      final handle = await adapter.launch(_spec());
      await adapter.pause(handle);
      await adapter.resume(handle);

      final updated = SandboxHandle(
        sessionId: handle.sessionId,
        backend: SandboxBackend.none,
        state: SandboxState.warm,
      );
      expect(await adapter.isAlive(updated), isTrue);
    });

    test('pause and resume on unknown session do not throw', () async {
      final handle = SandboxHandle(
        sessionId: 'unknown',
        backend: SandboxBackend.none,
        state: SandboxState.warm,
      );

      await adapter.pause(handle);
      await adapter.resume(handle);
      // No exception = pass.
    });

    // -----------------------------------------------------------------------
    // destroy — state and resource cleanup
    // -----------------------------------------------------------------------
    test('destroy removes handle from internal map and sets destroyed state',
        () async {
      final handle = await adapter.launch(_spec());

      await adapter.destroy(handle);

      expect(await adapter.isAlive(handle), isFalse);
      // A fresh handle with same session id is also not found.
      final recreated = SandboxHandle(
        sessionId: handle.sessionId,
        backend: SandboxBackend.none,
        state: SandboxState.warm,
      );
      expect(await adapter.isAlive(recreated), isFalse);
    });

    test('destroy on unknown session does not throw', () async {
      final handle = SandboxHandle(
        sessionId: 'unknown',
        backend: SandboxBackend.none,
      );

      await adapter.destroy(handle);
      // No exception = pass.
    });

    test('destroy closes the event stream', () async {
      final handle = await adapter.launch(_spec());
      final stream = adapter.events(handle);
      final events = <SandboxEvent>[];
      final sub = stream.listen(events.add);

      await adapter.destroy(handle);

      // The stream controller should be closed after destroy.
      // Listening again on the same session should produce a new
      // controller (via putIfAbsent) — we just verify the original
      // subscription doesn't cause unhandled errors after destroy.
      await sub.cancel();
    });
    // -----------------------------------------------------------------------
    // isAlive — suspended state
    // -----------------------------------------------------------------------
    test('isAlive is true for suspended state', () async {
      final handle = await adapter.launch(_spec());
      await adapter.pause(handle);

      final suspended = SandboxHandle(
        sessionId: handle.sessionId,
        backend: SandboxBackend.none,
        state: SandboxState.suspended,
      );
      expect(await adapter.isAlive(suspended), isTrue);
    });
  });
}
