import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:control_center/core/domain/value_objects/sandbox_handle.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';
import 'package:control_center/features/sandboxing/data/services/sandbox_session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake [SandboxPort] for testing [SandboxSessionManager].
class FakeSandboxPort implements SandboxPort {
  final Map<String, bool> aliveStatus = {};
  final List<SandboxSpec> launchedSpecs = [];
  final List<SandboxHandle> destroyedHandles = [];
  int launchCount = 0;

  SandboxHandle _handleForSpec(SandboxSpec spec) =>
      SandboxHandle(sessionId: spec.sessionId, backend: SandboxBackend.none);

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Future<SandboxBackendCapabilities> probe() async =>
      SandboxBackendCapabilities(backend: backend, available: true);

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async {
    launchCount++;
    launchedSpecs.add(spec);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final handle = _handleForSpec(spec);
    aliveStatus[handle.sessionId] = true;
    return handle;
  }

  @override
  Future<bool> isAlive(SandboxHandle handle) async =>
      aliveStatus[handle.sessionId] ?? false;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
  }) async => 0;

  @override
  Future<void> pause(SandboxHandle handle) async {}

  @override
  Future<void> resume(SandboxHandle handle) async {}

  @override
  Future<void> destroy(SandboxHandle handle) async {
    destroyedHandles.add(handle);
    aliveStatus.remove(handle.sessionId);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

SandboxSpec _spec(String sessionId) => SandboxSpec(
      sessionId: sessionId,
      workspaceId: 'ws1',
      bindMounts: const [],
      guestWorkdir: '/tmp/ws/$sessionId',
    );

void main() {
  group('SandboxSessionManager', () {
    late FakeSandboxPort sandbox;
    late SandboxSessionManager manager;

    setUp(() {
      sandbox = FakeSandboxPort();
      manager = SandboxSessionManager(sandbox);
    });

    test('ensure launches a new sandbox on first call', () async {
      final handle = await manager.ensure('s1', _spec('s1'));
      expect(handle.sessionId, 's1');
      expect(sandbox.launchCount, 1);
    });

    test('ensure returns existing handle when alive', () async {
      final h1 = await manager.ensure('s1', _spec('s1'));
      sandbox.aliveStatus[h1.sessionId] = true;
      final h2 = await manager.ensure('s1', _spec('s1'));
      expect(identical(h2, h1), isTrue);
      expect(sandbox.launchCount, 1);
    });

    test('ensure re-launches when existing handle is dead', () async {
      final h1 = await manager.ensure('s1', _spec('s1'));
      sandbox.aliveStatus[h1.sessionId] = false;
      final h2 = await manager.ensure('s1', _spec('s1'));
      expect(h2, isNot(same(h1)));
      expect(sandbox.launchCount, 2);
    });

    test('ensure re-launches when handle not in alive map', () async {
      final h1 = await manager.ensure('s1', _spec('s1'));
      sandbox.aliveStatus.remove(h1.sessionId);
      final h2 = await manager.ensure('s1', _spec('s1'));
      expect(h2, isNot(same(h1)));
      expect(sandbox.launchCount, 2);
    });

    test('ensure shares in-flight launch for same sessionId', () async {
      final slowSandbox = _SlowFakeSandboxPort();
      final mgr = SandboxSessionManager(slowSandbox);

      final futures = List.generate(5, (_) => mgr.ensure('s1', _spec('s1')));
      final handles = await Future.wait(futures);

      final ids = handles.map((h) => h.sessionId).toSet();
      expect(ids.length, 1);
      expect(slowSandbox.launchCount, 1);
    });

    test('independent sessionIds get their own handles', () async {
      final h1 = await manager.ensure('s1', _spec('s1'));
      final h2 = await manager.ensure('s2', _spec('s2'));
      expect(h1.sessionId, isNot(h2.sessionId));
      expect(sandbox.launchCount, 2);
    });

    test('peek returns handle for existing session', () async {
      final handle = await manager.ensure('s1', _spec('s1'));
      final peeked = manager.peek('s1');
      expect(peeked, same(handle));
    });

    test('peek returns null for unknown session', () {
      expect(manager.peek('nonexistent'), isNull);
    });

    test('destroy removes handle and calls sandbox.destroy', () async {
      await manager.ensure('s1', _spec('s1'));
      await manager.destroy('s1');

      expect(manager.peek('s1'), isNull);
      expect(sandbox.destroyedHandles.length, 1);
      expect(sandbox.destroyedHandles.first.sessionId, 's1');
    });

    test('destroy is no-op for unknown session', () async {
      await manager.destroy('nonexistent');
      expect(sandbox.destroyedHandles, isEmpty);
    });

    test('destroyAll removes all sessions', () async {
      await manager.ensure('s1', _spec('s1'));
      await manager.ensure('s2', _spec('s2'));
      await manager.ensure('s3', _spec('s3'));

      await manager.destroyAll();

      expect(manager.peek('s1'), isNull);
      expect(manager.peek('s2'), isNull);
      expect(manager.peek('s3'), isNull);
      expect(sandbox.destroyedHandles.length, 3);
    });

    test('destroyAll on empty is no-op', () async {
      await manager.destroyAll();
      expect(sandbox.destroyedHandles, isEmpty);
    });

    test('sandbox getter returns the port', () {
      expect(manager.sandbox, same(sandbox));
    });
  });
}

/// Slows down [launch] so concurrent calls can race.
class _SlowFakeSandboxPort extends FakeSandboxPort {
  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async {
    launchCount++;
    launchedSpecs.add(spec);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final handle = _handleForSpec(spec);
    aliveStatus[handle.sessionId] = true;
    return handle;
  }
}
