import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/connection_descriptor.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/bootstrap/thin_client_boot.dart';
import 'package:control_center/core/server/server_startup_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [CcServerProcess] that never spawns anything: it reports [running] and
/// counts [stop] calls.
class _FakeProcess extends CcServerProcess {
  _FakeProcess({this.running = true})
    : super(executable: 'unused', args: const []);

  bool running;
  int stops = 0;

  @override
  bool get isRunning => running;

  @override
  Future<void> stop({Duration grace = const Duration(seconds: 5)}) async {
    stops++;
    running = false;
  }
}

class _ManualSupervisor extends ServerConnectionSupervisor {
  _ManualSupervisor()
    : super(
        descriptor: ConnectionDescriptor(
          serverId: 'local',
          serverName: 'Local',
          fingerprint: 'pin',
          paths: const [LoopbackPath(port: 9030)],
        ),
        deviceId: 'desktop',
        psk: 'unused',
      );

  final changes = StreamController<ServerConnectionStatus>.broadcast();

  @override
  Stream<ServerConnectionStatus> get status => changes.stream;

  @override
  Future<void> close() async {
    await changes.close();
    await super.close();
  }
}

void main() {
  setUp(() => serverStartupStatus.value = null);
  tearDown(() => serverStartupStatus.value = null);

  test('the local desktop device id is a stable pairing identity', () {
    expect(localDesktopDeviceId, 'desktop-thin-local');
  });

  test('quit-signal watch is idempotent and can be released', () async {
    final holder = LocalServerProcessHolder(
      CcServerProcess(executable: 'true', args: const []),
    );
    holder.watchQuitSignals();
    holder.watchQuitSignals();
    await holder.stopWatchingQuitSignals();
    await holder.stopWatchingQuitSignals();
  });

  group('LocalServerProcessHolder respawn', () {
    test('keeps a running child', () async {
      final first = _FakeProcess();
      final holder = LocalServerProcessHolder(first);
      var spawns = 0;

      final respawned = await holder.respawnIfExited(() async {
        spawns++;
        return _FakeProcess();
      });

      expect(respawned, isFalse);
      expect(spawns, 0);
      expect(holder.process, same(first));
    });

    test('replaces a child that exited', () async {
      final holder = LocalServerProcessHolder(_FakeProcess(running: false));
      final next = _FakeProcess();

      final respawned = await holder.respawnIfExited(() async => next);

      expect(respawned, isTrue);
      expect(holder.process, same(next));
    });

    test('reports a failed respawn and clears it on retry', () async {
      final holder = LocalServerProcessHolder(_FakeProcess(running: false));
      final failure = StateError('native preflight failed');

      await expectLater(
        holder.respawnIfExited(() async => throw failure),
        throwsA(same(failure)),
      );
      expect(serverStartupStatus.value?.phase, ServerStartupPhase.failed);
      expect(serverStartupStatus.value?.error, same(failure));

      final pending = Completer<CcServerProcess>();
      final retry = holder.respawnIfExited(() => pending.future);
      expect(serverStartupStatus.value?.phase, ServerStartupPhase.starting);
      pending.complete(_FakeProcess());
      expect(await retry, isTrue);
      expect(serverStartupStatus.value?.phase, ServerStartupPhase.connecting);
      await holder.shutDown();
    });

    test(
      'healthy local pings cannot clear a remote switch attempt or failure',
      () async {
        final holder = LocalServerProcessHolder(_FakeProcess());
        final supervisor = _ManualSupervisor();
        holder.watchConnection(supervisor);
        addTearDown(() async {
          await holder.shutDown();
          await supervisor.close();
        });
        for (final phase in [
          ServerStartupPhase.connecting,
          ServerStartupPhase.failed,
        ]) {
          final remote = ServerStartupStatus(
            phase: phase,
            error: 'remote refused',
          );
          serverStartupStatus.value = remote;
          supervisor.changes.add(
            const ServerConnectionStatus(
              phase: ServerConnectionPhase.connected,
            ),
          );
          await Future<void>.delayed(Duration.zero);
          expect(serverStartupStatus.value, same(remote));
        }
      },
    );

    test(
      'a superseded respawn cannot replace remote switch progress',
      () async {
        final holder = LocalServerProcessHolder(_FakeProcess(running: false));
        final pending = Completer<CcServerProcess>();
        final respawn = holder.respawnIfExited(() => pending.future);
        const remote = ServerStartupStatus(
          phase: ServerStartupPhase.connecting,
        );
        serverStartupStatus.value = remote;
        pending.complete(_FakeProcess());
        await respawn;
        expect(serverStartupStatus.value, same(remote));
        await holder.shutDown();
        expect(serverStartupStatus.value, same(remote));
      },
    );

    test('never spawns once shut down (a switch to remote)', () async {
      final first = _FakeProcess();
      final holder = LocalServerProcessHolder(first);
      await holder.shutDown();
      var spawns = 0;

      await expectLater(
        holder.respawnIfExited(() async {
          spawns++;
          return _FakeProcess();
        }),
        throwsStateError,
      );

      expect(holder.isShutDown, isTrue);
      expect(first.stops, 1);
      expect(spawns, 0);
    });

    test('stops a respawn that lands after the shutdown began', () async {
      final holder = LocalServerProcessHolder(_FakeProcess(running: false));
      final pending = Completer<CcServerProcess>();
      final straggler = _FakeProcess();

      final respawn = holder.respawnIfExited(() => pending.future);
      await holder.shutDown();
      pending.complete(straggler);

      await expectLater(respawn, throwsStateError);
      expect(straggler.stops, 1);
      expect(holder.process, isNot(same(straggler)));
      expect(serverStartupStatus.value?.phase, ServerStartupPhase.ready);
    });
  });

  group('LocalServerProcessHolder shutDown', () {
    test('stops the child after the first step', () async {
      final child = _FakeProcess();
      final holder = LocalServerProcessHolder(child);
      final order = <String>[];

      await holder.shutDown(
        first: () async {
          order.add('close client');
          expect(child.stops, 0);
        },
      );

      expect(order, ['close client']);
      expect(child.stops, 1);
    });

    test('stops the child even when the first step throws', () async {
      final child = _FakeProcess();
      final holder = LocalServerProcessHolder(child);

      await expectLater(
        holder.shutDown(first: () async => throw StateError('close failed')),
        throwsStateError,
      );

      expect(child.stops, 1);
      expect(holder.isShutDown, isTrue);
    });
  });
}
