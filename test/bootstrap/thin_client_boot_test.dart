import 'dart:async';

import 'package:cc_infra/cc_infra.dart';
import 'package:control_center/bootstrap/thin_client_boot.dart';
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

void main() {
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
